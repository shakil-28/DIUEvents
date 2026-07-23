import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../club_dashboard_screen.dart';
import '../club_profile_screen.dart';
import '../../auth/auth.dart';
import 'package:flutter/material.dart';

import '../profile_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key, this.setThemeMode});

  final void Function(ThemeMode)? setThemeMode;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool isNotificationEnabled = true;
  bool isDarkMode = false;
  bool _isClubAdmin = false;
  String _clubName = '';
  final User? currentUser = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    // Deferred to didChangeDependencies
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final nowDark = Theme.of(context).brightness == Brightness.dark;
    if (isDarkMode != nowDark) {
      setState(() => isDarkMode = nowDark);
    }
    // Check if user is a club admin
    _checkClubAdmin();
  }

  Future<void> _checkClubAdmin() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (!mounted) return;
      if (doc.exists && doc.data()?['role'] == 'club') {
        setState(() {
          _isClubAdmin = true;
          _clubName = doc.data()?['name'] ?? 'Club';
        });
      }
    } catch (_) {}
  }

  void _toggleDarkMode(bool value) {
    setState(() => isDarkMode = value);
    widget.setThemeMode?.call(value ? ThemeMode.dark : ThemeMode.light);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? const Color(0xFF0D0E11) : const Color(0xFFF8F9FA);
    final sectionColor = isDark ? const Color(0xFF16181D) : Colors.white;
    final headingColor = isDark ? Colors.white : const Color(0xFF1A1D24);
    final subtitleColor = isDark ? const Color(0xFF8A92A6) : const Color(0xFF6C727F);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        elevation: 0,
        title: Text(
          'Settings',
          style: TextStyle(color: headingColor, fontSize: 20, fontWeight: FontWeight.w700, letterSpacing: -0.5),
        ),
        centerTitle: true,
        iconTheme: IconThemeData(color: headingColor),
      ),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        children: [
          // 1. User Profile Quick Header
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(color: sectionColor, borderRadius: BorderRadius.circular(20.0)),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: isDark ? const Color(0xFF232732) : const Color(0xFFE9ECEF),
                  backgroundImage: currentUser?.photoURL != null ? NetworkImage(currentUser!.photoURL!) : null,
                  child: currentUser?.photoURL == null ? Icon(Icons.person_rounded, size: 28, color: subtitleColor) : null,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(currentUser?.displayName ?? 'Event Explorer', style: TextStyle(color: headingColor, fontSize: 17, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 4),
                      Text(currentUser?.email ?? 'No email linked', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: subtitleColor, fontSize: 13)),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.edit_rounded, color: headingColor),
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen()));
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // 2. Preferences
          _buildSectionHeader('Preferences', subtitleColor),
          Container(
            decoration: BoxDecoration(color: sectionColor, borderRadius: BorderRadius.circular(20.0)),
            child: Column(
              children: [
                _buildToggleRow(icon: Icons.notifications_rounded, iconColor: Colors.blueAccent, title: 'Push Notifications', subtitle: 'Receive instant real-time event updates', value: isNotificationEnabled, onChanged: (val) => setState(() => isNotificationEnabled = val)),
                _buildDivider(isDark),
                _buildToggleRow(icon: Icons.dark_mode_rounded, iconColor: Colors.purpleAccent, title: 'Dark Display Mode', subtitle: 'Switch application color token space', value: isDarkMode, onChanged: _toggleDarkMode),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // 3. Account
          _buildSectionHeader('Account', subtitleColor),
          Container(
            decoration: BoxDecoration(color: sectionColor, borderRadius: BorderRadius.circular(20.0)),
            child: Column(
              children: [
                if (_isClubAdmin) ...[
                  _buildActionRow(
                    icon: Icons.dashboard_rounded,
                    iconColor: const Color(0xFF4C6FFF),
                    title: 'Club Dashboard',
                    headingColor: headingColor,
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ClubDashboardScreen(clubId: FirebaseAuth.instance.currentUser!.uid, clubName: _clubName))),
                  ),
                  _buildDivider(isDark),
                _buildActionRow(icon: Icons.business_rounded, iconColor: Colors.tealAccent, title: 'Club Profile', headingColor: headingColor, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ClubProfileScreen(clubId: FirebaseAuth.instance.currentUser!.uid)))),
              ],
              _buildActionRow(icon: Icons.person_outline_rounded, iconColor: Colors.tealAccent, title: 'My Profile', headingColor: headingColor, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen()))),
              _buildDivider(isDark),
              _buildActionRow(icon: Icons.lock_outline_rounded, iconColor: Colors.amberAccent, title: 'Change Password', headingColor: headingColor, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen()))),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // 4. Danger Zone
          _buildSectionHeader('Danger Zone', subtitleColor),
          Container(
            decoration: BoxDecoration(color: sectionColor, borderRadius: BorderRadius.circular(20.0)),
            child: Column(
              children: [
                _buildActionRow(icon: Icons.logout_rounded, iconColor: subtitleColor, title: 'Sign Out', headingColor: Colors.redAccent, showChevron: false, onTap: () => _showLogoutConfirmation(context)),
                _buildDivider(isDark),
                _buildActionRow(icon: Icons.delete_forever_rounded, iconColor: subtitleColor, title: 'Delete My Account', headingColor: subtitleColor, showChevron: false, onTap: () {}),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24.0),
            child: Text('v1.1.0 Stable Build', textAlign: TextAlign.center, style: TextStyle(color: subtitleColor.withValues(alpha: 0.6), fontSize: 12)),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String label, Color color) => Padding(padding: const EdgeInsets.only(left: 8, bottom: 8), child: Text(label.toUpperCase(), style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1)));
  Widget _buildDivider(bool isDark) => Divider(height: 1, thickness: 1, color: isDark ? Colors.white.withValues(alpha: 0.04) : Colors.black.withValues(alpha: 0.03));

  Widget _buildToggleRow({required IconData icon, required Color iconColor, required String title, required String subtitle, required bool value, required ValueChanged<bool> onChanged}) {
    return Padding(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), child: Row(children: [_buildIconFrame(icon, iconColor), const SizedBox(width: 14), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)), const SizedBox(height: 2), Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 12))])), CupertinoSwitch(value: value, activeColor: const Color(0xFF4C6FFF), onChanged: onChanged)]));
  }

  Widget _buildActionRow({required IconData icon, required Color iconColor, required String title, required Color headingColor, bool showChevron = true, required VoidCallback onTap}) {
    return InkWell(onTap: onTap, borderRadius: BorderRadius.circular(20), child: Padding(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14), child: Row(children: [_buildIconFrame(icon, iconColor), const SizedBox(width: 14), Expanded(child: Text(title, style: TextStyle(color: headingColor, fontSize: 15, fontWeight: FontWeight.w600))), if (showChevron) const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.grey)])));
  }

  Widget _buildIconFrame(IconData icon, Color color) => Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)), child: Icon(icon, size: 20, color: color));

  void _showLogoutConfirmation(BuildContext context) {
    showDialog(context: context, builder: (dialogContext) => AlertDialog(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)), title: const Text('Sign Out', style: TextStyle(fontWeight: FontWeight.w700)), content: const Text('Are you sure you want to log out?'), actions: [TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w600))), TextButton(onPressed: () async { Navigator.pop(dialogContext); await AuthService.signOut(context); }, child: const Text('Sign Out', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w700)))]));
  }
}
