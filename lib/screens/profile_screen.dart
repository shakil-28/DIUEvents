import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;
  final _storage = FirebaseStorage.instance;

  final TextEditingController _bioController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _oldPasswordController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  File? _profileImage;
  String? _photoURL;
  bool _isEditingBio = false;
  bool _isEditingProfile = false;
  bool _isLoading = false;
  String _successMessage = '';
  String _errorMessage = '';

  List<Map<String, dynamic>> _joinedClubs = [];
  List<Map<String, dynamic>> _pendingClubs = [];
  bool _clubsLoading = true;

  User? get currentUser => _auth.currentUser;

  @override
  void initState() {
    super.initState();
    _loadProfile();
    _loadClubs();
  }

  @override
  void dispose() {
    _bioController.dispose();
    _phoneController.dispose();
    _oldPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    if (currentUser == null) return;
    try {
      final doc = await _firestore.collection('users').doc(currentUser!.uid).get();
      if (doc.exists) {
        final data = doc.data() ?? {};
        setState(() {
          _photoURL = data['photoURL'] ?? currentUser!.photoURL;
          _bioController.text = data['bio'] ?? '';
          _phoneController.text = data['phone'] ?? '';
        });
      } else {
        setState(() {
          _photoURL = currentUser!.photoURL;
        });
      }
    } catch (e) {
      debugPrint('Error loading profile: $e');
    }
  }

  Future<void> _loadClubs() async {
    if (currentUser == null) return;
    try {
      final userDoc = await _firestore.collection('users').doc(currentUser!.uid).get();
      final data = userDoc.data() ?? {};
      final selectedClubs = List<String>.from(data['selectedClubs'] ?? []);

      if (selectedClubs.isEmpty) {
        setState(() => _clubsLoading = false);
        return;
      }

      final clubsSnapshot = await _firestore
          .collection('users')
          .where(FieldPath.documentId, whereIn: selectedClubs)
          .where('role', isEqualTo: 'club')
          .get();

      final joined = <Map<String, dynamic>>[];
      final pending = <Map<String, dynamic>>[];

      for (final doc in clubsSnapshot.docs) {
        final clubData = doc.data();
        final members = List<String>.from(clubData['members'] ?? []);
        final requests = List<String>.from(clubData['memberRequests'] ?? []);

        if (members.contains(currentUser!.uid)) {
          joined.add({'id': doc.id, ...clubData});
        } else if (requests.contains(currentUser!.uid)) {
          pending.add({'id': doc.id, ...clubData});
        }
      }

      setState(() {
        _joinedClubs = joined;
        _pendingClubs = pending;
        _clubsLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading clubs: $e');
      setState(() => _clubsLoading = false);
    }
  }

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() => _profileImage = File(picked.path));
    }
  }

  Future<String?> _uploadImage(File image) async {
    try {
      final ref = _storage.ref().child('profile_images/${currentUser!.uid}.jpg');
      await ref.putFile(image);
      return await ref.getDownloadURL();
    } catch (e) {
      debugPrint('Upload failed: $e');
      return null;
    }
  }

  Future<void> _saveProfile() async {
    if (currentUser == null) return;
    setState(() { _isLoading = true; _successMessage = ''; _errorMessage = ''; });
    try {
      String? downloadURL = _photoURL;
      if (_profileImage != null) {
        downloadURL = await _uploadImage(_profileImage!);
      }
      if (downloadURL != null) {
        await _auth.currentUser?.updatePhotoURL(downloadURL);
      }
      await _firestore.collection('users').doc(currentUser!.uid).update({
        'photoURL': downloadURL ?? '',
        'phone': _phoneController.text.trim(),
      });
      setState(() {
        _photoURL = downloadURL;
        _isEditingProfile = false;
        _profileImage = null;
        _successMessage = 'Profile updated successfully!';
      });
    } catch (e) {
      setState(() => _errorMessage = 'Failed to update profile: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveBio() async {
    if (currentUser == null) return;
    try {
      await _firestore.collection('users').doc(currentUser!.uid).update({
        'bio': _bioController.text.trim(),
      });
      setState(() {
        _isEditingBio = false;
        _successMessage = 'Bio updated!';
      });
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) setState(() => _successMessage = '');
      });
    } catch (e) {
      setState(() => _errorMessage = 'Failed to update bio: $e');
    }
  }

  Future<void> _changePassword() async {
    final oldPass = _oldPasswordController.text.trim();
    final newPass = _newPasswordController.text.trim();
    final confirmPass = _confirmPasswordController.text.trim();

    if (newPass != confirmPass) {
      setState(() => _errorMessage = 'New password and confirm password do not match.');
      return;
    }
    if (newPass.length < 6) {
      setState(() => _errorMessage = 'Password must be at least 6 characters.');
      return;
    }
    if (oldPass.isEmpty) {
      setState(() => _errorMessage = 'Please enter your current password.');
      return;
    }

    setState(() { _isLoading = true; _successMessage = ''; _errorMessage = ''; });

    try {
      final cred = EmailAuthProvider.credential(
        email: currentUser!.email!,
        password: oldPass,
      );
      await currentUser!.reauthenticateWithCredential(cred);
      await currentUser!.updatePassword(newPass);
      setState(() {
        _successMessage = 'Password changed successfully!';
        _oldPasswordController.clear();
        _newPasswordController.clear();
        _confirmPasswordController.clear();
      });
    } on FirebaseAuthException catch (e) {
      setState(() => _errorMessage = e.message ?? 'Failed to change password');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _leaveClub(String clubId) async {
    if (currentUser == null) return;
    try {
      await _firestore.collection('users').doc(currentUser!.uid).update({
        'selectedClubs': FieldValue.arrayRemove([clubId]),
      });
      await _firestore.collection('users').doc(clubId).update({
        'members': FieldValue.arrayRemove([currentUser!.uid]),
        'memberRequests': FieldValue.arrayRemove([currentUser!.uid]),
      });
      await _loadClubs();
    } catch (e) {
      debugPrint('Leave club failed: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (currentUser == null) {
      return Scaffold(
        backgroundColor: const Color(0xFFF8F9FA),
        appBar: AppBar(title: const Text('Profile')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF0D0E11) : const Color(0xFFF8F9FA);
    final cardBg = isDark ? const Color(0xFF16181D) : Colors.white;
    final heading = isDark ? Colors.white : const Color(0xFF1A1D24);
    final sub = isDark ? const Color(0xFF6C727F) : const Color(0xFF8A92A6);
    final accent = isDark ? const Color(0xFF4C6FFF) : const Color(0xFF1A1D24);

    final displayName = currentUser?.displayName ?? currentUser?.email?.split('@')[0] ?? 'User';
    final email = currentUser?.email ?? '';

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        title: Text('My Profile', style: TextStyle(color: heading, fontWeight: FontWeight.w700)),
        centerTitle: true,
        iconTheme: IconThemeData(color: heading),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          if (currentUser == null) return;
          setState(() { _successMessage = ''; _errorMessage = ''; });
          await _loadProfile();
          await _loadClubs();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Success/Error Messages
              if (_successMessage.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle, size: 20, color: Colors.green),
                      const SizedBox(width: 8),
                      Expanded(child: Text(_successMessage, style: const TextStyle(color: Colors.green, fontWeight: FontWeight.w500))),
                    ],
                  ),
                ),
              if (_errorMessage.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error, size: 20, color: Colors.red),
                      const SizedBox(width: 8),
                      Expanded(child: Text(_errorMessage, style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w500))),
                    ],
                  ),
                ),

              // Profile Header Card
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: isDark ? Colors.black.withValues(alpha: 0.3) : Colors.black.withValues(alpha: 0.08),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Avatar with camera overlay
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        CircleAvatar(
                          radius: 55,
                          backgroundColor: isDark ? const Color(0xFF232732) : const Color(0xFFE9ECEF),
                          backgroundImage: _profileImage != null
                              ? FileImage(_profileImage!)
                              : (_photoURL != null && _photoURL!.isNotEmpty)
                                  ? NetworkImage(_photoURL!)
                                  : null,
                          child: (_profileImage == null && (_photoURL == null || _photoURL!.isEmpty))
                              ? Icon(Icons.person, size: 55, color: sub)
                              : null,
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: GestureDetector(
                            onTap: _pickImage,
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: accent,
                                shape: BoxShape.circle,
                                border: Border.all(color: cardBg, width: 3),
                              ),
                              child: const Icon(Icons.camera_alt, size: 18, color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Name & Email
                    const SizedBox(height: 16),
                    Text(
                      displayName,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: heading, fontSize: 22, fontWeight: FontWeight.w700, letterSpacing: -0.5),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      email,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: sub, fontSize: 14),
                    ),
                    const SizedBox(height: 20),
                    // Edit Profile Button
                    ElevatedButton.icon(
                      onPressed: _isEditingProfile ? (_isLoading ? null : _saveProfile) : () => setState(() => _isEditingProfile = true),
                      icon: _isLoading
                          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)))
                          : Icon(_isEditingProfile ? Icons.save_rounded : Icons.edit_rounded),
                      label: Text(_isEditingProfile ? 'Save Changes' : 'Edit Profile'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isEditingProfile ? Colors.green : accent,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Personal Info Section (when editing)
              if (_isEditingProfile) ...[
                _buildSectionTitle('Personal Information', heading),
                const SizedBox(height: 12),
                Container(
                  decoration: BoxDecoration(color: cardBg, borderRadius: BorderRadius.circular(16)),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      TextField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        decoration: InputDecoration(
                          labelText: 'Phone Number',
                          hintText: 'Enter your phone number',
                          prefixIcon: const Icon(Icons.phone_outlined, color: Colors.grey),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          filled: true,
                          fillColor: isDark ? const Color(0xFF1E222B) : Colors.grey.shade50,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _isLoading ? null : _saveProfile,
                        icon: _isLoading
                            ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)))
                            : const Icon(Icons.save_rounded),
                        label: const Text('Save Changes'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          minimumSize: const Size(double.infinity, 50),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],

              // Bio Section
              _buildSectionTitle('About Me', heading),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(color: cardBg, borderRadius: BorderRadius.circular(16)),
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    if (_isEditingBio)
                      TextField(
                        controller: _bioController,
                        maxLines: 4,
                        decoration: InputDecoration(
                          labelText: 'Tell us about yourself...',
                          hintText: 'Share your interests, hobbies, or anything...',
                          prefixIcon: const Icon(Icons.info_outline_rounded, color: Colors.grey),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          filled: true,
                          fillColor: isDark ? const Color(0xFF1E222B) : Colors.grey.shade50,
                        ),
                      )
                    else
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Text(
                          _bioController.text.isEmpty
                              ? 'No bio yet. Click edit to add one!'
                              : _bioController.text,
                          style: TextStyle(color: sub, fontSize: 15, height: 1.5),
                        ),
                      ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _isEditingBio ? _saveBio : () => setState(() => _isEditingBio = true),
                      icon: Icon(_isEditingBio ? Icons.save_rounded : Icons.edit_rounded),
                      label: Text(_isEditingBio ? 'Save Bio' : 'Edit Bio'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isDark ? const Color(0xFF7C3AED) : Colors.black,
                        foregroundColor: isDark ? Colors.white : Colors.white,
                        minimumSize: const Size(double.infinity, 48),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Joined Clubs Section
              _buildSectionTitle('Joined Clubs', heading),
              const SizedBox(height: 12),
              if (_clubsLoading)
                Container(
                  decoration: BoxDecoration(color: cardBg, borderRadius: BorderRadius.circular(16)),
                  padding: const EdgeInsets.all(24),
                  child: const Center(child: CircularProgressIndicator()),
                )
              else if (_joinedClubs.isEmpty)
                Container(
                  decoration: BoxDecoration(color: cardBg, borderRadius: BorderRadius.circular(16)),
                  padding: const EdgeInsets.all(24),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(Icons.groups_outlined, size: 48, color: sub.withValues(alpha: 0.5)),
                        const SizedBox(height: 12),
                        Text('You haven\'t joined any clubs yet.', style: TextStyle(color: sub, fontSize: 14)),
                      ],
                    ),
                  ),
                )
              else
                Container(
                  decoration: BoxDecoration(color: cardBg, borderRadius: BorderRadius.circular(16)),
                  child: Column(
                    children: _joinedClubs.map((club) {
                      final name = (club['name'] ?? club['fullName'] ?? 'Unknown Club') as String;
                      final logo = (club['logoUrl'] ?? '') as String;
                      final clubId = club['id'] as String?;
                      if (clubId == null) return const SizedBox.shrink();
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        child: Row(
                          children: [
                            if (logo.isNotEmpty)
                              CircleAvatar(
                                radius: 22,
                                backgroundColor: isDark ? const Color(0xFF232732) : const Color(0xFFE9ECEF),
                                child: ClipOval(
                                  child: Image.network(
                                    logo,
                                    width: 44,
                                    height: 44,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => Icon(Icons.groups_rounded, size: 22, color: accent),
                                  ),
                                ),
                              )
                            else
                              CircleAvatar(
                                child: Icon(Icons.groups_rounded, size: 22, color: accent),
                                radius: 22,
                              ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Text(
                                name,
                                style: TextStyle(color: heading, fontWeight: FontWeight.w600, fontSize: 15),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            TextButton(
                              onPressed: () => _leaveClub(clubId),
                              style: TextButton.styleFrom(foregroundColor: Colors.red, padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8)),
                              child: const Text('Leave', style: TextStyle(fontWeight: FontWeight.w600)),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),

              const SizedBox(height: 24),

              // Pending Club Requests Section
              if (_pendingClubs.isNotEmpty) ...[
                _buildSectionTitle('Pending Requests', heading),
                const SizedBox(height: 12),
                Container(
                  decoration: BoxDecoration(color: cardBg, borderRadius: BorderRadius.circular(16)),
                  child: Column(
                    children: _pendingClubs.map((club) {
                      final name = (club['name'] ?? club['fullName'] ?? 'Unknown Club') as String;
                      final logo = (club['logoUrl'] ?? '') as String;
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        child: Row(
                          children: [
                            if (logo.isNotEmpty)
                              CircleAvatar(
                                radius: 22,
                                backgroundColor: isDark ? const Color(0xFF232732) : const Color(0xFFE9ECEF),
                                child: ClipOval(
                                  child: Image.network(
                                    logo,
                                    width: 44,
                                    height: 44,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => Icon(Icons.groups_rounded, size: 22, color: accent),
                                  ),
                                ),
                              )
                            else
                              CircleAvatar(
                                child: Icon(Icons.pending_actions_rounded, size: 22, color: Colors.orange),
                                radius: 22,
                              ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Text(
                                name,
                                style: TextStyle(color: heading, fontWeight: FontWeight.w600, fontSize: 15),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.orange.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                'Pending',
                                style: TextStyle(color: Colors.orange, fontSize: 12, fontWeight: FontWeight.w600),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 24),
              ],

              // Change Password Section
              _buildSectionTitle('Security', heading),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(color: cardBg, borderRadius: BorderRadius.circular(16)),
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    TextField(
                      controller: _oldPasswordController,
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: 'Current Password',
                        hintText: 'Enter your current password',
                        prefixIcon: const Icon(Icons.lock_outline_rounded, color: Colors.grey),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        filled: true,
                        fillColor: isDark ? const Color(0xFF1E222B) : Colors.grey.shade50,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _newPasswordController,
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: 'New Password',
                        hintText: 'Enter new password (min 6 chars)',
                        prefixIcon: const Icon(Icons.lock_rounded, color: Colors.grey),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        filled: true,
                        fillColor: isDark ? const Color(0xFF1E222B) : Colors.grey.shade50,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _confirmPasswordController,
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: 'Confirm New Password',
                        hintText: 'Re-enter your new password',
                        prefixIcon: const Icon(Icons.lock_clock_rounded, color: Colors.grey),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        filled: true,
                        fillColor: isDark ? const Color(0xFF1E222B) : Colors.grey.shade50,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _isLoading ? null : _changePassword,
                      icon: _isLoading
                          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)))
                          : const Icon(Icons.lock_reset_rounded),
                      label: Text(_isLoading ? 'Changing...' : 'Change Password'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, Color color) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.w700, letterSpacing: -0.3),
      ),
    );
  }
}
