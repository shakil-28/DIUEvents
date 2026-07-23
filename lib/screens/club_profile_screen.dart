import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class ClubProfileScreen extends StatefulWidget {
  final String clubId;

  const ClubProfileScreen({super.key, required this.clubId});

  @override
  State<ClubProfileScreen> createState() => _ClubProfileScreenState();
}

class _ClubProfileScreenState extends State<ClubProfileScreen> {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;
  final _storage = FirebaseStorage.instance;

  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _currentPassCtrl = TextEditingController();
  final _newPassCtrl = TextEditingController();
  final _confirmPassCtrl = TextEditingController();

  String? _logoUrl;
  File? _imageFile;
  bool _isLoading = false;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _loadClubProfile();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _emailCtrl.dispose();
    _currentPassCtrl.dispose();
    _newPassCtrl.dispose();
    _confirmPassCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadClubProfile() async {
    try {
      final doc = await _firestore.collection('users').doc(widget.clubId).get();
      if (doc.exists && mounted) {
        final data = doc.data() ?? {};
        setState(() {
          _nameCtrl.text = data['name'] ?? '';
          _descCtrl.text = data['description'] ?? '';
          _emailCtrl.text = data['email'] ?? '';
          _logoUrl = data['logoUrl'];
        });
      }
    } catch (e) {
      debugPrint('Error loading club profile: $e');
    }
  }

  Future<void> _pickLogo() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked != null) setState(() => _imageFile = File(picked.path));
  }

  Future<String?> _uploadLogo(File image) async {
    try {
      final ref = _storage.ref().child('club_logos/${widget.clubId}.jpg');
      await ref.putFile(image);
      return await ref.getDownloadURL();
    } catch (e) {
      debugPrint('Upload failed: $e');
      return null;
    }
  }

  Future<void> _saveProfile() async {
    setState(() => _isLoading = true);
    try {
      String? logoUrl = _logoUrl;
      if (_imageFile != null) {
        logoUrl = await _uploadLogo(_imageFile!);
      }
      await _firestore.collection('users').doc(widget.clubId).update({
        'name': _nameCtrl.text.trim(),
        'description': _descCtrl.text.trim(),
        'logoUrl': logoUrl ?? '',
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Club profile updated')));
        setState(() {
          _isEditing = false;
          _imageFile = null;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _changePassword() async {
    final current = _currentPassCtrl.text.trim();
    final newPw = _newPassCtrl.text.trim();
    final confirm = _confirmPassCtrl.text.trim();

    if (newPw.isEmpty || current.isEmpty) {
      _showSnack('Please fill current password');
      return;
    }
    if (newPw.length < 6) {
      _showSnack('New password must be at least 6 characters');
      return;
    }
    if (newPw != confirm) {
      _showSnack('Passwords do not match');
      return;
    }

    setState(() => _isLoading = true);
    try {
      final user = _auth.currentUser;
      // Re-authenticate
      final cred = EmailAuthProvider.credential(
        email: user!.email!,
        password: current,
      );
      await user.reauthenticateWithCredential(cred);
      await user.updatePassword(newPw);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password changed successfully')));
        _currentPassCtrl.clear();
        _newPassCtrl.clear();
        _confirmPassCtrl.clear();
      }
    } on FirebaseAuthException catch (e) {
      String msg = e.message ?? 'Failed to change password';
      if (msg.contains('wrong-password') || msg.contains('invalid-credential')) {
        msg = 'Current password is incorrect';
      }
      _showSnack(msg);
    } catch (e) {
      _showSnack('Failed: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnack(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF0D0E11) : const Color(0xFFF8F9FA);
    final cardBg = isDark ? const Color(0xFF16181D) : Colors.white;
    final heading = isDark ? Colors.white : const Color(0xFF1A1D24);
    final sub = isDark ? const Color(0xFF6C727F) : const Color(0xFF8A92A6);
    final accent = isDark ? const Color(0xFF4C6FFF) : const Color(0xFF1A1D24);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        title: Text('Club Profile', style: TextStyle(color: heading, fontWeight: FontWeight.w700)),
        iconTheme: IconThemeData(color: heading),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Logo Section
            Container(
              decoration: BoxDecoration(color: cardBg, borderRadius: BorderRadius.circular(20)),
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Stack(
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: isDark ? const Color(0xFF232732) : const Color(0xFFE9ECEF),
                        backgroundImage: _imageFile != null
                            ? FileImage(_imageFile!)
                            : (_logoUrl != null && _logoUrl!.isNotEmpty ? NetworkImage(_logoUrl!) : null),
                        child: (_imageFile == null && (_logoUrl == null || _logoUrl!.isEmpty))
                            ? Icon(Icons.business_rounded, size: 40, color: accent)
                            : null,
                      ),
                      Positioned(
                        right: 0, bottom: 0,
                        child: GestureDetector(
                          onTap: _pickLogo,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(color: accent, shape: BoxShape.circle),
                            child: const Icon(Icons.camera_alt_rounded, size: 18, color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text('Club Logo', style: TextStyle(color: sub, fontSize: 13)),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Edit Name & Description
            _buildSectionTitle('Club Information', heading),
            Container(
              decoration: BoxDecoration(color: cardBg, borderRadius: BorderRadius.circular(16)),
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  TextField(
                    controller: _nameCtrl,
                    enabled: !_isLoading,
                    decoration: InputDecoration(
                      labelText: 'Club Name',
                      hintText: 'Enter club name',
                      prefixIcon: Icon(Icons.business_rounded, color: sub),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      filled: true,
                      fillColor: isDark ? const Color(0xFF1E222B) : Colors.grey.shade50,
                    ),
                    style: TextStyle(color: heading),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _descCtrl,
                    enabled: !_isLoading,
                    maxLines: 3,
                    decoration: InputDecoration(
                      labelText: 'Description',
                      hintText: 'Describe your club...',
                      prefixIcon: Icon(Icons.description_rounded, color: sub),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      filled: true,
                      fillColor: isDark ? const Color(0xFF1E222B) : Colors.grey.shade50,
                    ),
                    style: TextStyle(color: heading),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isLoading || !_isEditing ? null : _saveProfile,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: accent,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: _isLoading
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)))
                          : Text(_isEditing ? 'Save Changes' : 'Edit Club Info', style: const TextStyle(fontWeight: FontWeight.w600)),
                    ),
                  ),
                  if (!_isEditing) ...[
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () => setState(() => _isEditing = true),
                      child: Text('Edit', style: TextStyle(color: accent, fontWeight: FontWeight.w600)),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Password Section
            _buildSectionTitle('Security', heading),
            Container(
              decoration: BoxDecoration(color: cardBg, borderRadius: BorderRadius.circular(16)),
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  TextField(
                    controller: _currentPassCtrl,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: 'Current Password',
                      prefixIcon: Icon(Icons.lock_outline_rounded, color: sub),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      filled: true,
                      fillColor: isDark ? const Color(0xFF1E222B) : Colors.grey.shade50,
                    ),
                    style: TextStyle(color: heading),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _newPassCtrl,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: 'New Password (min 6 chars)',
                      prefixIcon: Icon(Icons.lock_rounded, color: sub),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      filled: true,
                      fillColor: isDark ? const Color(0xFF1E222B) : Colors.grey.shade50,
                    ),
                    style: TextStyle(color: heading),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _confirmPassCtrl,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: 'Confirm New Password',
                      prefixIcon: Icon(Icons.lock_clock_rounded, color: sub),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      filled: true,
                      fillColor: isDark ? const Color(0xFF1E222B) : Colors.grey.shade50,
                    ),
                    style: TextStyle(color: heading),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: _isLoading ? null : _changePassword,
                      icon: _isLoading
                          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)))
                          : const Icon(Icons.lock_reset_rounded, size: 20),
                      label: Text(_isLoading ? 'Changing...' : 'Change Password'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, Color color) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 10),
      child: Text(title, style: TextStyle(color: color, fontSize: 16, fontWeight: FontWeight.w700)),
    );
  }
}
