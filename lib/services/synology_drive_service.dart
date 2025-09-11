import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class SynologyDriveService {
  String? _serverUrl;
  String? _username;
  String? _password;
  // Resolved, writable backup folder URL (absolute, no trailing filename)
  String? _backupFolderUrl;
  // Preferred File Station path for uploads (relative to NAS filesystem)
  // Try both personal drive and team folder paths
  static const List<String> _candidateFileStationPaths = [
    '/home/Drive/PasswordWallet_Backups', // Personal My Drive
    '/PasswordWallet_Backups', // Team Folder (if exists)
  ];

  static const String _keyServerUrl = 'synology_server_url';
  static const String _keyUsername = 'synology_username';
  static const String _keyPassword = 'synology_password';

  /// Load saved configuration
  Future<bool> loadConfiguration() async {
    final prefs = await SharedPreferences.getInstance();
    _serverUrl = prefs.getString(_keyServerUrl);
    _username = prefs.getString(_keyUsername);
    _password = prefs.getString(_keyPassword);

    return isConfigured;
  }

  /// Save configuration
  Future<void> saveConfiguration({
    required String serverUrl,
    required String username,
    required String password,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    // Use URL as provided by user (no automatic port changes)
    String url = serverUrl.trim();
    // Remove trailing slash if present for consistency
    if (url.endsWith('/')) {
      url = url.substring(0, url.length - 1);
    }

    await prefs.setString(_keyServerUrl, url);
    await prefs.setString(_keyUsername, username);
    await prefs.setString(_keyPassword, password);

    _serverUrl = url;
    _username = username;
    _password = password;
    _backupFolderUrl = null; // reset cached path when config changes
  }

  /// Get basic auth header
  Map<String, String> _getHeaders() {
    final credentials = base64Encode(utf8.encode('$_username:$_password'));
    return {
      'Authorization': 'Basic $credentials',
      'Content-Type': 'application/octet-stream',
      'User-Agent': 'PasswordWallet-Flutter/1.0',
    };
  }

  /// Test connection to Synology
  Future<Map<String, dynamic>> testConnection() async {
    try {
      if (!isConfigured) {
        return {'success': false, 'error': 'Not configured'};
      }

      // Validate URL format first
      Uri serverUri;
      try {
        serverUri = Uri.parse(_serverUrl!);
        if (!serverUri.hasScheme ||
            (!serverUri.isScheme('http') && !serverUri.isScheme('https'))) {
          return {
            'success': false,
            'error': 'Invalid URL format. Please use http:// or https://',
          };
        }
      } catch (e) {
        return {
          'success': false,
          'error': 'Invalid URL format: ${e.toString()}',
        };
      }

      // Try multiple connection methods
      try {
        // Method 1: Try basic server connection first
        final response = await http
            .get(serverUri, headers: _getHeaders())
            .timeout(const Duration(seconds: 10));

        // Method 2: If basic connection works, assume success (don't check WebDAV here)
        if (response.statusCode >= 200 && response.statusCode < 500) {
          return {'success': true, 'message': 'Synology connection successful'};
        } else {
          return {
            'success': false,
            'error': 'HTTP ${response.statusCode}: ${response.reasonPhrase}',
          };
        }
      } catch (e) {
        // Provide more specific error messages
        String errorMsg = 'Connection failed';

        if (e.toString().contains('SocketException')) {
          errorMsg =
              'Cannot reach server. Check:\n• Server URL (${_serverUrl!})\n• Network connection\n• Port ${serverUri.port} is open';
        } else if (e.toString().contains('TimeoutException')) {
          errorMsg = 'Connection timeout. Server may be slow or unreachable.';
        } else if (e.toString().contains('HandshakeException')) {
          errorMsg =
              'SSL/TLS error. Try using HTTP instead of HTTPS, or check certificate.';
        } else if (e.toString().contains('FormatException')) {
          errorMsg = 'Invalid server URL format.';
        } else {
          errorMsg = 'Connection error: ${e.toString()}';
        }

        return {'success': false, 'error': errorMsg};
      }
    } catch (e) {
      return {'success': false, 'error': 'Unexpected error: ${e.toString()}'};
    }
  }

  /// Create backup folder if not exists
  Future<void> _ensureBackupFolder() async {
    if (!isConfigured) throw Exception('Not configured');

    // Build a robust WebDAV base. If the URL already contains /webdav, don't append it again.
    final base = _serverUrl!;
    final hasDav = base.toLowerCase().contains('/webdav');
    final davBase = hasDav
        ? (base.endsWith('/') ? base.substring(0, base.length - 1) : base)
        : ('$base${base.endsWith('/') ? '' : '/'}webdav');

    // Candidate locations to create/use the backup folder
    final candidates = <String>[
      '$davBase/home/Drive/PasswordWallet_Backups/', // exact path from your NAS
      '$davBase/Drive/PasswordWallet_Backups/', // alternative path
      '$davBase/home/PasswordWallet_Backups/', // fallback path
      '$davBase/PasswordWallet_Backups/', // fallback at dav root
    ];

    // If we already resolved and validated earlier, short-circuit
    if (_backupFolderUrl != null) {
      return;
    }

    // Try each candidate: if exists -> use it; if 404 -> try MKCOL; if MKCOL 201/405 -> use it
    for (final folderPath in candidates) {
      try {
        final req = http.Request('PROPFIND', Uri.parse(folderPath))
          ..headers.addAll(_getHeaders())
          ..headers['Depth'] = '0';

        final client = http.Client();
        final streamed = await client.send(req);
        final res = await http.Response.fromStream(streamed);
        client.close();

        if (res.statusCode == 207 ||
            (res.statusCode >= 200 && res.statusCode < 300)) {
          _backupFolderUrl = folderPath;
          return;
        }

        if (res.statusCode == 404) {
          // Try to create the folder
          final mk = http.Request('MKCOL', Uri.parse(folderPath))
            ..headers.addAll(_getHeaders());
          final mkClient = http.Client();
          final mkStream = await mkClient.send(mk);
          final mkRes = await http.Response.fromStream(mkStream);
          mkClient.close();

          // 201 Created or 405 Method Not Allowed (already exists) are acceptable
          if (mkRes.statusCode == 201 ||
              mkRes.statusCode == 405 ||
              (mkRes.statusCode >= 200 && mkRes.statusCode < 300)) {
            _backupFolderUrl = folderPath;
            return;
          }
        }
      } catch (_) {
        // try next candidate
      }
    }

    // If no candidate worked, keep a sensible default (won't throw), upload will surface error
    _backupFolderUrl = '${davBase}/PasswordWallet_Backups/';

    try {
      // No-op: above logic already tried creating; this block remains for backward compatibility
    } catch (e) {
      print('Error ensuring backup folder: $e');
      // Don't throw - folder might exist or creation might not be needed
    }
  }

  /// Upload backup file
  Future<Map<String, dynamic>> uploadBackupData({
    required Uint8List fileData,
    required String fileName,
    Function(String)? onProgress,
  }) async {
    try {
      if (!isConfigured) {
        return {
          'success': false,
          'error': 'Not configured. Please set up Synology connection first.',
        };
      }

      onProgress?.call('Connecting to Synology...');

      // Test connection first
      final connectionTest = await testConnection();
      if (!connectionTest['success']) {
        return connectionTest;
      }

      onProgress?.call('Creating backup folder...');
      await _ensureBackupFolder();

      if (_backupFolderUrl == null) {
        return {
          'success': false,
          'error':
              'Could not determine backup folder URL. Please ensure WebDAV is enabled on your NAS.',
        };
      }

      onProgress?.call('Uploading file...');

      // Try File Station API first (most reliable method)
      final base = _backupFolderUrl!;
      final fileUrl = base.endsWith('/') ? '$base$fileName' : '$base/$fileName';

      String lastError = '';

      // Method 1: Try File Station API with SID (prioritized)
      try {
        // Login to obtain SID
        final sid = await _loginFileStation();
        if (sid == null) {
          throw Exception('File Station login failed');
        }

        final uploadUrl = Uri.parse(
          '${_serverUrl!}/webapi/entry.cgi',
        ).replace(queryParameters: {'_sid': sid});

        final request = http.MultipartRequest('POST', uploadUrl);

        // Add form fields for File Station API
        request.fields['api'] = 'SYNO.FileStation.Upload';
        request.fields['version'] = '2';
        request.fields['method'] = 'upload';
        request.fields['path'] = _candidateFileStationPaths.first;
        request.fields['create_parents'] = 'true';
        request.fields['overwrite'] = 'true';

        // Add file
        request.files.add(
          http.MultipartFile.fromBytes('file', fileData, filename: fileName),
        );

        final streamedResponse = await request.send();
        final response = await http.Response.fromStream(streamedResponse);

        if (response.statusCode >= 200 && response.statusCode < 300) {
          try {
            final jsonData = json.decode(response.body) as Map<String, dynamic>;
            if (jsonData['success'] == true) {
              onProgress?.call('Upload completed');
              return {
                'success': true,
                'message':
                    'Backup uploaded to Synology successfully (File Station API)',
                'fileName': fileName,
              };
            } else {
              throw Exception(
                'File Station API error: ${jsonData['error'] ?? 'Unknown error'}',
              );
            }
          } catch (jsonError) {
            // If JSON parsing fails but HTTP status is OK, assume success
            onProgress?.call('Upload completed');
            return {
              'success': true,
              'message':
                  'Backup uploaded to Synology successfully (File Station API)',
              'fileName': fileName,
            };
          }
        } else {
          throw Exception(
            'HTTP ${response.statusCode}: ${response.reasonPhrase}',
          );
        }
      } catch (e) {
        lastError = 'File Station API Exception: ${e.toString()}';
        onProgress?.call('File Station API failed, trying WebDAV PUT...');
      }

      // Method 2: Try WebDAV PUT
      try {
        final headers = _getHeaders();
        headers['Content-Type'] = 'application/octet-stream';

        final putRes = await http.put(
          Uri.parse(fileUrl),
          headers: headers,
          body: fileData,
        );

        if (putRes.statusCode >= 200 && putRes.statusCode < 300) {
          onProgress?.call('Upload completed');
          return {
            'success': true,
            'message': 'Backup uploaded to Synology successfully (WebDAV PUT)',
            'fileName': fileName,
          };
        }

        lastError =
            'PUT: HTTP ${putRes.statusCode} - ${putRes.reasonPhrase} to $fileUrl';

        // If 405 Method Not Allowed, try alternative method
        if (putRes.statusCode == 405) {
          onProgress?.call('PUT method not allowed, trying POST...');
        } else {
          onProgress?.call('PUT failed (${putRes.statusCode}), trying POST...');
        }
      } catch (e) {
        lastError = 'PUT Exception: ${e.toString()}';
        onProgress?.call('PUT failed, trying POST method...');
      }

      // Method 3: Try simple POST to WebDAV
      try {
        final postRes = await http.post(
          Uri.parse(fileUrl),
          headers: {
            'Authorization':
                'Basic ${base64Encode(utf8.encode('$_username:$_password'))}',
            'Content-Type': 'application/octet-stream',
          },
          body: fileData,
        );

        if (postRes.statusCode >= 200 && postRes.statusCode < 300) {
          onProgress?.call('Upload completed');
          return {
            'success': true,
            'message': 'Backup uploaded to Synology successfully (POST)',
            'fileName': fileName,
          };
        }
      } catch (e) {
        // All methods failed
      }

      // All upload methods failed
      return {
        'success': false,
        'error':
            'All upload methods failed.\n\nLast error: $lastError\n\nTarget URL: $fileUrl\n\nPlease check:\n1. WebDAV is enabled on Synology NAS\n2. User has write permission to shared folder\n3. Folder path is correct',
      };
    } catch (e) {
      return {'success': false, 'error': 'Upload failed: ${e.toString()}'};
    }
  }

  /// List backup files
  Future<Map<String, dynamic>> listBackupFiles() async {
    try {
      if (!isConfigured) {
        return {'success': false, 'error': 'Not configured'};
      }
      await _ensureBackupFolder();
      final folderPath =
          _backupFolderUrl ?? '${_serverUrl!}/webdav/PasswordWallet_Backups/';

      // Use PROPFIND to list directory contents
      final response = http.Request('PROPFIND', Uri.parse(folderPath))
        ..headers.addAll(_getHeaders())
        ..headers['Depth'] = '1'
        ..body = '''<?xml version="1.0"?>
<D:propfind xmlns:D="DAV:">
  <D:prop>
    <D:displayname/>
    <D:getcontentlength/>
    <D:getlastmodified/>
    <D:resourcetype/>
  </D:prop>
</D:propfind>''';

      final client = http.Client();
      final streamedResponse = await client.send(response);
      final result = await http.Response.fromStream(streamedResponse);
      client.close();

      if (result.statusCode >= 200 && result.statusCode < 300) {
        // Simple parsing - look for .crypt files
        final backupFiles = <Map<String, dynamic>>[];
        final responseBody = result.body;

        // Simple regex to find filenames ending with .crypt
        final filePattern = RegExp(
          r'<D:displayname>([^<]*\.crypt)</D:displayname>',
        );
        final matches = filePattern.allMatches(responseBody);

        for (final match in matches) {
          final fileName = match.group(1);
          if (fileName != null && fileName.isNotEmpty) {
            backupFiles.add({
              'name': fileName,
              'size': 0, // We'll skip size parsing for simplicity
              'modified': DateTime.now().toIso8601String(),
            });
          }
        }

        return {'success': true, 'files': backupFiles};
      } else {
        return {
          'success': false,
          'error': 'Failed to list files: HTTP ${result.statusCode}',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Failed to list files: ${e.toString()}',
      };
    }
  }

  /// Download backup file
  Future<Map<String, dynamic>> downloadBackupFile(String fileName) async {
    try {
      if (!isConfigured) {
        return {'success': false, 'error': 'Not configured'};
      }
      await _ensureBackupFolder();
      final base =
          _backupFolderUrl ?? '${_serverUrl!}/webdav/PasswordWallet_Backups/';
      final filePath = base.endsWith('/')
          ? '$base$fileName'
          : '$base/$fileName';
      final response = await http.get(
        Uri.parse(filePath),
        headers: _getHeaders(),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return {
          'success': true,
          'data': response.bodyBytes,
          'fileName': fileName,
        };
      } else {
        return {
          'success': false,
          'error':
              'Download failed: HTTP ${response.statusCode} - ${response.reasonPhrase}',
        };
      }
    } catch (e) {
      return {'success': false, 'error': 'Download failed: ${e.toString()}'};
    }
  }

  /// Check if configured
  bool get isConfigured =>
      _serverUrl != null &&
      _username != null &&
      _password != null &&
      _serverUrl!.isNotEmpty &&
      _username!.isNotEmpty &&
      _password!.isNotEmpty;

  /// Clear configuration
  Future<void> clearConfiguration() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyServerUrl);
    await prefs.remove(_keyUsername);
    await prefs.remove(_keyPassword);

    _serverUrl = null;
    _username = null;
    _password = null;
  }

  /// Get server info for display
  String get serverInfo => _serverUrl ?? 'Not configured';
  String get usernameInfo => _username ?? '';
}

extension _SynologyFileStationAuth on SynologyDriveService {
  /// Login to File Station API and return SID on success
  Future<String?> _loginFileStation() async {
    try {
      if (!isConfigured) return null;
      final base = _serverUrl!;
      final authUrl =
          Uri.parse(
            '${base}${base.endsWith('/') ? '' : '/'}webapi/auth.cgi',
          ).replace(
            queryParameters: {
              'api': 'SYNO.API.Auth',
              'version': '3',
              'method': 'login',
              'account': _username!,
              'passwd': _password!,
              'session': 'FileStation',
              'format': 'sid',
            },
          );

      final res = await http.get(authUrl).timeout(const Duration(seconds: 10));
      if (res.statusCode == 200) {
        try {
          final jsonData = json.decode(res.body) as Map<String, dynamic>;
          if (jsonData['success'] == true && jsonData['data'] != null) {
            final sid = jsonData['data']['sid'] as String?;
            return sid;
          }
        } catch (_) {
          // Failed to parse JSON response
        }
      }
    } catch (_) {}
    return null;
  }
}
