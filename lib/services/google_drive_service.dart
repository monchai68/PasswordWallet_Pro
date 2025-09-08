import 'dart:io';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:http/http.dart' as http;

class GoogleDriveService {
  static const List<String> _scopes = [drive.DriveApi.driveFileScope];

  final GoogleSignIn _googleSignIn = GoogleSignIn(scopes: _scopes);

  GoogleSignInAccount? _currentUser;
  drive.DriveApi? _driveApi;

  // Check if user is already signed in
  bool get isSignedIn => _currentUser != null;

  // Get current user email
  String? get userEmail => _currentUser?.email;

  // Sign in to Google
  Future<Map<String, dynamic>> signIn() async {
    try {
      print('🔄 Starting Google Sign-In...');

      // Check if already signed in
      final currentUser = await _googleSignIn.signInSilently();
      if (currentUser != null) {
        print('✅ User already signed in silently: ${currentUser.email}');
        _currentUser = currentUser;

        final authHeaders = await currentUser.authHeaders;
        final authenticatedClient = GoogleAuthClient(authHeaders);
        _driveApi = drive.DriveApi(authenticatedClient);

        return {
          'success': true,
          'message': 'Already signed in to Google Drive',
          'email': currentUser.email,
        };
      }

      print('🔄 Starting interactive sign-in...');
      final GoogleSignInAccount? account = await _googleSignIn.signIn();

      if (account != null) {
        print('✅ Sign-in successful: ${account.email}');
        _currentUser = account;

        // Get auth headers
        print('🔄 Getting auth headers...');
        final authHeaders = await account.authHeaders;
        print('📋 Auth headers count: ${authHeaders.length}');

        if (authHeaders.isEmpty) {
          print('❌ No auth headers received');
          return {
            'success': false,
            'message': 'Failed to get authentication headers',
            'error': 'NO_AUTH_HEADERS',
          };
        }

        final authenticatedClient = GoogleAuthClient(authHeaders);
        _driveApi = drive.DriveApi(authenticatedClient);

        print('✅ Google Drive API client initialized');
        return {
          'success': true,
          'message': 'Successfully signed in to Google Drive',
          'email': account.email,
        };
      } else {
        print('❌ User cancelled sign in');
        return {
          'success': false,
          'message': 'User cancelled sign in',
          'error': 'USER_CANCELLED',
        };
      }
    } catch (e) {
      print('❌ Google Sign-in error: $e');

      // Parse specific error codes
      String errorMessage = 'Sign in failed';
      String errorCode = 'UNKNOWN_ERROR';

      if (e.toString().contains('ApiException: 10')) {
        errorCode = 'DEVELOPER_ERROR';
        errorMessage =
            'Configuration error. Please follow the checklist to resolve the issue.';
      } else if (e.toString().contains('ApiException: 12')) {
        errorCode = 'INVALID_ACCOUNT';
        errorMessage =
            'Invalid account or sign-in was cancelled. Ensure you are using a test account if in test mode.';
      } else if (e.toString().contains('ApiException: 7')) {
        errorCode = 'NETWORK_ERROR';
        errorMessage = 'Network error. Please check your internet connection.';
      } else if (e.toString().contains('sign_in_canceled')) {
        errorCode = 'USER_CANCELLED';
        errorMessage = 'Sign in was cancelled by user';
      }

      return {
        'success': false,
        'message': errorMessage,
        'error': errorCode,
        'details': e.toString(),
        'rawError': e.runtimeType.toString(),
      };
    }
  }

  // Sign out from Google
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    _currentUser = null;
    _driveApi = null;
  }

  // Upload backup file to Google Drive
  Future<Map<String, dynamic>> uploadBackupFile(String filePath) async {
    try {
      if (_driveApi == null) {
        return {'success': false, 'message': 'Not signed in to Google Drive'};
      }

      final file = File(filePath);
      if (!await file.exists()) {
        return {'success': false, 'message': 'Backup file not found'};
      }

      // Create file metadata
      final fileName = file.path.split('/').last;
      final driveFile = drive.File()
        ..name =
            'PasswordWallet_Backup_${DateTime.now().millisecondsSinceEpoch}_$fileName'
        ..description =
            'Password Wallet backup file created on ${DateTime.now()}'
        ..parents = await _getOrCreateBackupFolder();

      // Upload file
      final fileBytes = await file.readAsBytes();
      final media = drive.Media(
        Stream.fromIterable([fileBytes]),
        fileBytes.length,
      );

      final result = await _driveApi!.files.create(
        driveFile,
        uploadMedia: media,
      );

      return {
        'success': true,
        'message': 'Backup uploaded successfully to Google Drive',
        'fileId': result.id,
        'fileName': result.name,
      };
    } catch (e) {
      return {'success': false, 'message': 'Failed to upload backup: $e'};
    }
  }

  // Upload backup data directly (for automatic backups)
  Future<Map<String, dynamic>> uploadBackupData({
    required List<int> fileData,
    required String fileName,
  }) async {
    try {
      if (_driveApi == null) {
        return {'success': false, 'message': 'Not signed in to Google Drive'};
      }

      // Use a fixed filename
      const fixedFileName = 'wallet.crypt';

      // Check if file already exists and delete it
      await _deleteExistingBackupFile(fixedFileName);

      // Create file metadata with fixed name
      final driveFile = drive.File()
        ..name = fixedFileName
        ..description =
            'Password Wallet automatic backup updated on ${DateTime.now()}'
        ..parents = await _getOrCreateBackupFolder();

      // Upload file data
      final media = drive.Media(
        Stream.fromIterable([fileData]),
        fileData.length,
      );

      final result = await _driveApi!.files.create(
        driveFile,
        uploadMedia: media,
      );

      return {
        'success': true,
        'message':
            'Backup uploaded successfully to Google Drive as $fixedFileName',
        'fileId': result.id,
        'fileName': result.name,
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to upload automatic backup: $e',
      };
    }
  }

  // Get or create backup folder in Google Drive
  Future<List<String>> _getOrCreateBackupFolder() async {
    try {
      // Search for existing PasswordWallet folder
      final folderQuery =
          "name='PasswordWallet_Backups' and mimeType='application/vnd.google-apps.folder' and trashed=false";
      final folderList = await _driveApi!.files.list(q: folderQuery);

      if (folderList.files != null && folderList.files!.isNotEmpty) {
        return [folderList.files!.first.id!];
      }

      // Create new folder if it doesn't exist
      final folder = drive.File()
        ..name = 'PasswordWallet_Backups'
        ..mimeType = 'application/vnd.google-apps.folder'
        ..description = 'Password Wallet backup files';

      final createdFolder = await _driveApi!.files.create(folder);
      return [createdFolder.id!];
    } catch (e) {
      print('Error managing backup folder: $e');
      return []; // Upload to root folder if folder creation fails
    }
  }

  // List backup files from Google Drive
  Future<List<Map<String, dynamic>>> listBackupFiles() async {
    try {
      if (_driveApi == null) {
        return [];
      }

      final query = "name contains 'PasswordWallet_Backup_' and trashed=false";
      final fileList = await _driveApi!.files.list(
        q: query,
        orderBy: 'createdTime desc',
        pageSize: 50,
        $fields: 'files(id,name,createdTime,size,description)',
      );

      return fileList.files
              ?.map(
                (file) => {
                  'id': file.id,
                  'name': file.name,
                  'createdTime': file.createdTime?.toIso8601String(),
                  'size': file.size,
                  'description': file.description,
                },
              )
              .toList() ??
          [];
    } catch (e) {
      print('Error listing backup files: $e');
      return [];
    }
  }

  // Download backup file from Google Drive
  Future<Map<String, dynamic>> downloadBackupFile(
    String fileId,
    String localPath,
  ) async {
    try {
      if (_driveApi == null) {
        return {'success': false, 'message': 'Not signed in to Google Drive'};
      }

      final media =
          await _driveApi!.files.get(
                fileId,
                downloadOptions: drive.DownloadOptions.fullMedia,
              )
              as drive.Media;

      final file = File(localPath);
      final bytes = <int>[];

      await for (final chunk in media.stream) {
        bytes.addAll(chunk);
      }

      await file.writeAsBytes(bytes);

      return {
        'success': true,
        'message': 'Backup downloaded successfully',
        'filePath': localPath,
      };
    } catch (e) {
      return {'success': false, 'message': 'Failed to download backup: $e'};
    }
  }

  // Delete existing backup file if it exists
  Future<void> _deleteExistingBackupFile(String fileName) async {
    try {
      if (_driveApi == null) return;

      // Search for existing file with the same name
      final query = "name='$fileName' and trashed=false";
      final fileList = await _driveApi!.files.list(q: query);

      if (fileList.files != null && fileList.files!.isNotEmpty) {
        // Delete all files with the same name (in case there are duplicates)
        for (final file in fileList.files!) {
          if (file.id != null) {
            await _driveApi!.files.delete(file.id!);
            print('🗑️ Deleted existing backup file: ${file.name}');
          }
        }
      }
    } catch (e) {
      print('⚠️ Warning: Could not delete existing backup file: $e');
      // Don't throw error - just continue with upload
    }
  }
}

// Helper class for authenticated HTTP client
class GoogleAuthClient extends http.BaseClient {
  final Map<String, String> _headers;
  final http.Client _client = http.Client();

  GoogleAuthClient(this._headers);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    return _client.send(request..headers.addAll(_headers));
  }

  @override
  void close() {
    _client.close();
  }
}
