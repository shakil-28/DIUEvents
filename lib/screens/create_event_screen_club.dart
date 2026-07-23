import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

class CreateEventScreenClub extends StatefulWidget {
  const CreateEventScreenClub({super.key});

  @override
  State<CreateEventScreenClub> createState() => _CreateEventScreenClubState();
}

class _CreateEventScreenClubState extends State<CreateEventScreenClub> {
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _locCtrl = TextEditingController();

  DateTime? _startTime;
  DateTime? _endTime;
  File? _imageFile;
  bool _restricted = false;
  bool _isLoading = false;

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked != null) setState(() => _imageFile = File(picked.path));
  }

  Future<String> _uploadImage(File image) async {
    final ref = FirebaseStorage.instance.ref().child('event_images/${const Uuid().v4()}.jpg');
    await ref.putFile(image);
    return await ref.getDownloadURL();
  }

  Future<void> _pickDateTime(BuildContext context, bool isStart) async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );
    if (date == null) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (time == null) return;

    final dt = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    setState(() {
      if (isStart) _startTime = dt; else _endTime = dt;
    });
  }

  Future<void> _create() async {
    final title = _titleCtrl.text.trim();
    final desc = _descCtrl.text.trim();
    final loc = _locCtrl.text.trim();
    final uid = FirebaseAuth.instance.currentUser!.uid;

    if (title.isEmpty || desc.isEmpty || loc.isEmpty || _startTime == null || _endTime == null) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill all fields')));
      return;
    }
    if (_imageFile == null) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please pick an image')));
      return;
    }

    setState(() => _isLoading = true);
    try {
      final imageUrl = await _uploadImage(_imageFile!);
      await FirebaseFirestore.instance.collection('events').add({
        'title': title,
        'description': desc,
        'location': loc,
        'imageUrl': imageUrl,
        'startingTime': Timestamp.fromDate(_startTime!),
        'endTime': Timestamp.fromDate(_endTime!),
        'createdAt': FieldValue.serverTimestamp(),
        'approved': false,
        'status': 'pending',
        'restricted': _restricted,
        'clubId': uid,
        'interestedUsers': [],
        'lovedUsers': [],
        'reactCount': 0,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Event created! Visible after approval.')));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _locCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF0D0E11) : Colors.white;
    final cardBg = isDark ? const Color(0xFF16181D) : const Color(0xFFF8F9FA);
    final heading = isDark ? Colors.white : const Color(0xFF1A1D24);
    final sub = isDark ? const Color(0xFF6C727F) : const Color(0xFF8A92A6);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(title: const Text('Create Event')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          TextField(
            controller: _titleCtrl,
            decoration: InputDecoration(labelText: 'Event Title', labelStyle: TextStyle(color: sub), filled: true, fillColor: cardBg, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
            style: TextStyle(color: heading),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _descCtrl,
            maxLines: 4,
            decoration: InputDecoration(labelText: 'Description', labelStyle: TextStyle(color: sub), filled: true, fillColor: cardBg, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
            style: TextStyle(color: heading),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _locCtrl,
            decoration: InputDecoration(labelText: 'Location', labelStyle: TextStyle(color: sub), filled: true, fillColor: cardBg, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
            style: TextStyle(color: heading),
          ),
          const SizedBox(height: 16),
          // Start time
          InkWell(
            onTap: () => _pickDateTime(context, true),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: cardBg, borderRadius: BorderRadius.circular(12)),
              child: Row(children: [
                Icon(Icons.calendar_today_rounded, size: 20, color: heading.withValues(alpha: 0.5)),
                const SizedBox(width: 12),
                Expanded(child: Text(_startTime != null ? 'Start: ${_formatDt(_startTime!)}' : 'Select Start Time', style: TextStyle(color: _startTime != null ? heading : sub))),
              ]),
            ),
          ),
          const SizedBox(height: 12),
          // End time
          InkWell(
            onTap: () => _pickDateTime(context, false),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: cardBg, borderRadius: BorderRadius.circular(12)),
              child: Row(children: [
                Icon(Icons.access_time_rounded, size: 20, color: heading.withValues(alpha: 0.5)),
                const SizedBox(width: 12),
                Expanded(child: Text(_endTime != null ? 'End: ${_formatDt(_endTime!)}' : 'Select End Time', style: TextStyle(color: _endTime != null ? heading : sub))),
              ]),
            ),
          ),
          const SizedBox(height: 16),
          // Image picker
          GestureDetector(
            onTap: _pickImage,
            child: Container(
              height: 180,
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: sub.withValues(alpha: 0.3)),
              ),
              child: _imageFile != null
                  ? ClipRRect(borderRadius: BorderRadius.circular(16), child: Image.file(_imageFile!, fit: BoxFit.cover))
                  : const Center(
                      child: Column(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.add_a_photo_rounded, size: 48, color: Colors.grey), SizedBox(height: 8), Text('Tap to pick event image', style: TextStyle(color: Colors.grey))]),
                    ),
            ),
          ),
          const SizedBox(height: 16),
          // Restricted toggle
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: _restricted,
            onChanged: (v) => setState(() => _restricted = v ?? false),
            title: Text('Restricted event', style: TextStyle(color: heading, fontWeight: FontWeight.w600)),
            subtitle: Text('Only members can see this event', style: TextStyle(color: sub)),
          ),
          const SizedBox(height: 24),
          // Submit button
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _create,
              style: ElevatedButton.styleFrom(backgroundColor: heading, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Create Event'),
            ),
          ),
        ]),
      ),
    );
  }

  String _formatDt(DateTime dt) {
    final h = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
    final m = dt.minute.toString().padLeft(2, '0');
    return '${dt.day}/${dt.month}/$h:$m${dt.hour >= 12 ? "PM" : "AM"}';
  }
}
