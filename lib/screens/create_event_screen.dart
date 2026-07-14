import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

class CreateEventScreen extends StatefulWidget {
  const CreateEventScreen({super.key});

  @override
  State<CreateEventScreen> createState() => _CreateEventScreenState();
}

class _CreateEventScreenState extends State<CreateEventScreen> {
  final TextEditingController titleController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController locationController = TextEditingController();

  DateTime? startingTime;
  DateTime? endTime;
  File? selectedImage;
  bool restricted = false;

  bool isLoading = false;

  Future<void> pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);

    if (picked != null) {
      setState(() {
        selectedImage = File(picked.path);
      });
    }
  }

  Future<String> uploadImage(File imageFile) async {
    final fileName = const Uuid().v4();
    final ref =
        FirebaseStorage.instance.ref().child('event_images/$fileName.jpg');
    await ref.putFile(imageFile);
    return await ref.getDownloadURL();
  }

  Future<void> createEvent() async {
    final title = titleController.text.trim();
    final description = descriptionController.text.trim();
    final location = locationController.text.trim();
    final uid = FirebaseAuth.instance.currentUser!.uid;

    if (title.isEmpty ||
        description.isEmpty ||
        location.isEmpty ||
        startingTime == null ||
        endTime == null ||
        selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill all fields")),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      final imageUrl = await uploadImage(selectedImage!);
      final docRef = FirebaseFirestore.instance.collection('events').doc();

      await docRef.set({
        'title': title,
        'description': description,
        'location': location,
        'startingTime': startingTime,
        'endTime': endTime,
        'imageUrl': imageUrl,
        'createdAt': Timestamp.now(),
        'approved': false,
        'status': 'pending',
        'restricted': restricted,
        'clubId': uid,
        'interestedUsers': [],
        'lovedUsers': [],
        'reactCount': 0,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Event created successfully")),
      );

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to create event: $e")),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> pickDateTime(BuildContext context, bool isStart) async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now,
      lastDate: DateTime(2100),
    );

    if (date == null) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (time == null) return;

    final selectedDateTime = DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );

    setState(() {
      if (isStart) {
        startingTime = selectedDateTime;
      } else {
        endTime = selectedDateTime;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Create Event")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(labelText: "Event Title"),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(labelText: "Description"),
              maxLines: 3,
            ),
            const SizedBox(height: 10),
            TextField(
              controller: locationController,
              decoration: const InputDecoration(labelText: "Location"),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: Text(
                    startingTime == null
                        ? "Pick Starting Time"
                        : "Start: ${startingTime.toString()}",
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.calendar_today),
                  onPressed: () => pickDateTime(context, true),
                ),
              ],
            ),
            Row(
              children: [
                Expanded(
                  child: Text(
                    endTime == null
                        ? "Pick End Time"
                        : "End: ${endTime.toString()}",
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.calendar_today),
                  onPressed: () => pickDateTime(context, false),
                ),
              ],
            ),
            const SizedBox(height: 10),
            CheckboxListTile(
              value: restricted,
              onChanged: (val) {
                setState(() => restricted = val ?? false);
              },
              title: const Text("Restricted Event?"),
            ),
            const SizedBox(height: 10),
            selectedImage == null
                ? ElevatedButton.icon(
                    onPressed: pickImage,
                    icon: const Icon(Icons.image),
                    label: const Text("Pick Event Image"),
                  )
                : Image.file(selectedImage!, height: 150),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: isLoading ? null : createEvent,
              child: isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text("Create Event"),
            ),
          ],
        ),
      ),
    );
  }
}
