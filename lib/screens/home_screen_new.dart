import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1a1a1a),
      appBar: AppBar(
        title: Text(
          'PasswordWallet',
          style: GoogleFonts.inter(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color(0xFF2d2d2d),
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome Section
            Text(
              'สวัสดี!',
              style: GoogleFonts.inter(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'จัดการรหัสผ่านของคุณได้อย่างปลอดภัย',
              style: GoogleFonts.inter(fontSize: 16, color: Colors.white70),
            ),
            const SizedBox(height: 32),

            // Statistics Section
            Text(
              'สถิติ',
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    title: 'รหัสผ่านทั้งหมด',
                    count: '0',
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatCard(
                    title: 'รายการโปรด',
                    count: '0',
                    color: Colors.orange,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Quick Actions Section
            Text(
              'การดำเนินการ',
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                children: [
                  _buildActionCard(
                    icon: Icons.category,
                    title: 'หมวดหมู่',
                    subtitle: 'จัดกลุ่มรหัสผ่าน',
                    color: Colors.blue,
                    onTap: () {
                      // Navigate to categories
                    },
                  ),
                  _buildActionCard(
                    icon: Icons.add_circle,
                    title: 'เพิ่มรหัสผ่าน',
                    subtitle: 'สร้างรหัสผ่านใหม่',
                    color: Colors.green,
                    onTap: () {
                      // Navigate to add password
                    },
                  ),
                  _buildActionCard(
                    icon: Icons.favorite,
                    title: 'รายการโปรด',
                    subtitle: 'รหัสผ่านที่ใช้บ่อย',
                    color: Colors.red,
                    onTap: () {
                      // Navigate to favorites
                    },
                  ),
                  _buildActionCard(
                    icon: Icons.settings,
                    title: 'การตั้งค่า',
                    subtitle: 'ปรับแต่งแอป',
                    color: Colors.grey,
                    onTap: () {
                      // Navigate to settings
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Quick add password
        },
        backgroundColor: const Color(0xFF4CAF50),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String count,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2d2d2d),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            count,
            style: GoogleFonts.inter(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: GoogleFonts.inter(fontSize: 14, color: Colors.white70),
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF2d2d2d),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.3), width: 1),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 32),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: GoogleFonts.inter(fontSize: 12, color: Colors.white70),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
