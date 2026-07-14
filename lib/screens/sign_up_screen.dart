import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:multi_select_flutter/multi_select_flutter.dart';

import 'components/basicTextField.dart';
import 'components/fullnametextfield.dart';
import 'home_screen.dart';

class SignUpScreen extends StatefulWidget {
  // Made nullable so it can open directly from any onboarding/email navigation node
  final User? user;

  const SignUpScreen({super.key, this.user});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _departmentController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _studentIdController = TextEditingController();

  bool _isNotificationEnabled = true;
  bool _isLoading = false;

  List<Map<String, dynamic>> _clubs = [];
  List<String> _selectedClubs = [];

  @override
  void initState() {
    super.initState();
    _loadClubs();
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _departmentController.dispose();
    _phoneController.dispose();
    _studentIdController.dispose();
    super.dispose();
  }

  Future<void> _loadClubs() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'club')
          .get();
      
      if (!mounted) return;
      
      setState(() {
        _clubs = snapshot.docs
            .map((doc) {
              final data = doc.data();
              return {
                'id': doc.id,
                'name': data.containsKey('name') ? data['name'] : doc.id,
              };
            })
            .toList();
      });
    } catch (e) {
      debugPrint('Error loading clubs: $e');
    }
  }

  Future<void> _sendClubRequests(String uid) async {
    final batch = FirebaseFirestore.instance.batch();
    
    for (String clubId in _selectedClubs) {
      final clubRef = FirebaseFirestore.instance.collection('users').doc(clubId);
      batch.update(clubRef, {
        'memberRequests': FieldValue.arrayUnion([uid])
      });
    }
    
    await batch.commit();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    // Resolve the current user if widget.user wasn't passed directly by the parent router
    final activeUser = widget.user ?? FirebaseAuth.instance.currentUser;
    
    if (activeUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Authentication session expired. Please sign in again.')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(activeUser.uid)
          .set({
        'uid': activeUser.uid,
        'email': activeUser.email,
        'fullName': _fullNameController.text.trim(),
        'department': _departmentController.text.trim(),
        'phone': _phoneController.text.trim(),
        'studentId': _studentIdController.text.trim(),
        'role': 'student',
        'notifications': _isNotificationEnabled,
        'selectedClubs': _selectedClubs,
        'registeredEvents': [],
        'bio': '',
        'photoURL': '',
        'createdAt': Timestamp.now(),
      });

      await _sendClubRequests(activeUser.uid);

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving profile: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator.adaptive())
            : Center(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: EdgeInsets.symmetric(
                    horizontal: mediaQuery.size.width * 0.06,
                    vertical: 24.0,
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // App Brand Header Block
                        Center(
                          child: SvgPicture.asset(
                            'assets/images/logo.svg',
                            height: mediaQuery.size.height * 0.07,
                            fit: BoxFit.contain,
                          ),
                        ),
                        SizedBox(height: mediaQuery.size.height * 0.03),
                        Text(
                          'Complete Profile',
                          style: theme.textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF1A1A1A),
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 6.0),
                        Text(
                          'Fill in your academic and communication parameters to finalize registration.',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: const Color(0xFF757575),
                          ),
                        ),
                        SizedBox(height: mediaQuery.size.height * 0.04),

                        // Input Group Configuration
                        FullNameTextField(controller: _fullNameController),
                        const SizedBox(height: 18),
                        CustomTextField(
                          controller: _departmentController,
                          labelText: 'Department',
                          hintText: 'Enter your department',
                          keyboardType: TextInputType.text,
                          textInputAction: TextInputAction.next,
                          validator: (value) => value == null || value.trim().isEmpty
                              ? 'Please enter your department'
                              : null,
                        ),
                        const SizedBox(height: 18),
                        CustomTextField(
                          controller: _phoneController,
                          labelText: 'Phone Number',
                          hintText: 'Enter your phone number',
                          keyboardType: TextInputType.phone,
                          textInputAction: TextInputAction.next,
                          validator: (value) => value == null || value.trim().isEmpty
                              ? 'Please enter your phone number'
                              : null,
                        ),
                        const SizedBox(height: 18),
                        CustomTextField(
                          controller: _studentIdController,
                          labelText: 'Student ID',
                          hintText: 'e.g., 221-15-5579',
                          keyboardType: TextInputType.text,
                          textInputAction: TextInputAction.done,
                          validator: (value) => value == null || value.trim().isEmpty
                              ? 'Please enter your student ID'
                              : null,
                        ),
                        const SizedBox(height: 24),

                        // Interactive Multi-Select Club Component
                        Text(
                          'Join University Clubs',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF1A1A1A),
                          ),
                        ),
                        const SizedBox(height: 8),
                        MultiSelectDialogField(
                          items: _clubs
                              .map((club) => MultiSelectItem(club['id'], club['name']))
                              .toList(),
                          title: const Text('Select Associated Clubs'),
                          separateSelectedItems: true,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12.0),
                            border: Border.all(color: const Color(0xFFE0E0E0)),
                          ),
                          buttonIcon: const Icon(Icons.arrow_drop_down, color: Color(0xFF757575)),
                          selectedColor: const Color(0xFF1A1A1A),
                          selectedItemsTextStyle: const TextStyle(color: Colors.white),
                          unselectedColor: const Color(0xFFF5F5F5),
                          buttonText: const Text(
                            'Choose clubs to request membership...',
                            style: TextStyle(color: Color(0xFF757575), fontSize: 14),
                          ),
                          onConfirm: (selectedValues) {
                            setState(() {
                              _selectedClubs = List<String>.from(selectedValues);
                            });
                          },
                        ),
                        const SizedBox(height: 24),

                        // Elegant Segmented Push Notification Toggle Block
                        Text(
                          'Push Notifications',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF1A1A1A),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12.0),
                            border: Border.all(color: const Color(0xFFE0E0E0)),
                          ),
                          child: SwitchListTile.adaptive(
                            title: const Text(
                              'Receive immediate event alerts',
                              style: TextStyle(fontSize: 14, color: Color(0xFF424242)),
                            ),
                            value: _isNotificationEnabled,
                            activeColor: const Color(0xFF1A1A1A),
                            onChanged: (bool value) {
                              setState(() {
                                _isNotificationEnabled = value;
                              });
                            },
                          ),
                        ),
                        SizedBox(height: mediaQuery.size.height * 0.05),

                        // Action Submission Surface
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton(
                            onPressed: _saveProfile,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1A1A1A),
                              foregroundColor: Colors.white,
                              elevation: 2.0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12.0),
                              ),
                            ),
                            child: const Text(
                              'Save Profile & Finish',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
      ),
    );
  }
}