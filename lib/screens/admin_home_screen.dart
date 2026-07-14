import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final TextEditingController _clubNameController = TextEditingController();
  final TextEditingController _clubDescriptionController =
      TextEditingController();
  final TextEditingController _clubEmailController = TextEditingController();
  final TextEditingController _clubPasswordController = TextEditingController();

  final TextEditingController _eventTitleController = TextEditingController();
  final TextEditingController _eventDescriptionController =
      TextEditingController();
  final TextEditingController _eventLocationController =
      TextEditingController();
  final TextEditingController _eventImageUrlController =
      TextEditingController();

  // Method to delete event
  Future<void> deleteEvent(String eventId) async {
    try {
      await _firestore.collection('events').doc(eventId).delete();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Event Deleted')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete event: $e')),
      );
    }
  }

  // Method to approve event
  Future<void> approveEvent(String eventId) async {
    await _firestore.collection('events').doc(eventId).update({
      'approved': true,
      'status': 'approved',
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Event Approved')),
    );
  }

  // Method to reject event
  Future<void> rejectEvent(String eventId) async {
    await _firestore.collection('events').doc(eventId).delete();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Event Rejected')),
    );
  }

  // Method to create new club
  Future<void> createNewClub() async {
    try {
      final UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: _clubEmailController.text,
        password: _clubPasswordController.text,
      );

      await _firestore.collection('users').doc(userCredential.user!.uid).set({
        'uid': userCredential.user!.uid,
        'name': _clubNameController.text,
        'description': _clubDescriptionController.text,
        'email': _clubEmailController.text,
        'logoUrl': '',
        'role': 'club',
        'members': [],
        'memberRequests': [],
        'createdAt': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Club Created Successfully')),
      );
      _clubNameController.clear();
      _clubDescriptionController.clear();
      _clubEmailController.clear();
      _clubPasswordController.clear();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to create club: $e')),
      );
    }
  }

  // Method to create new event
  Future<void> createNewEvent() async {
    try {
      await _firestore.collection('events').add({
        'title': _eventTitleController.text,
        'description': _eventDescriptionController.text,
        'location': _eventLocationController.text,
        'imageUrl': _eventImageUrlController.text,
        'startingTime': FieldValue.serverTimestamp(),
        'endTime': FieldValue.serverTimestamp(),
        'approved': true,
        'status': 'approved',
        'clubId': _auth.currentUser?.uid,
        'reactCount': 0,
        'interestedUsers': [],
        'lovedUsers': [],
        'restricted': false,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Event Created Successfully')),
      );
      _eventTitleController.clear();
      _eventDescriptionController.clear();
      _eventLocationController.clear();
      _eventImageUrlController.clear();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to create event: $e')),
      );
    }
  }

  // Method to display pending events
  Widget buildPendingEvents() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('events')
          .where('approved', isEqualTo: false)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const CircularProgressIndicator();
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Text('No pending events');
        }

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final event = snapshot.data!.docs[index];
            return Card(
              margin: const EdgeInsets.symmetric(vertical: 8),
              child: ListTile(
                leading:
                    event['imageUrl'] != null && event['imageUrl'].isNotEmpty
                        ? Image.network(event['imageUrl'],
                            width: 60, height: 60, fit: BoxFit.cover)
                        : const Icon(Icons.event),
                title: Text(event['title']),
                subtitle: Text(event['description']),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.check, color: Colors.green),
                      onPressed: () => approveEvent(event.id),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.red),
                      onPressed: () => rejectEvent(event.id),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.black),
                      onPressed: () => deleteEvent(event.id),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // Method to display list of clubs
  Widget buildClubsList() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('users')
          .where('role', isEqualTo: 'club')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const CircularProgressIndicator();
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Text('No clubs found');
        }

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final club = snapshot.data!.docs[index];
            return Card(
              margin: const EdgeInsets.symmetric(vertical: 8),
              child: ListTile(
                leading: club['logoUrl'] != null && club['logoUrl'].isNotEmpty
                    ? Image.network(club['logoUrl'], width: 40, height: 40)
                    : const Icon(Icons.group),
                title: Text(club['name'] ?? 'Unnamed Club'),
                subtitle: Text(club['email'] ?? ''),
              ),
            );
          },
        );
      },
    );
  }

  // UI for creating new club and event
  Widget buildClubCreationForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Create New Club',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        TextField(
          controller: _clubNameController,
          decoration: const InputDecoration(labelText: 'Club Name'),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _clubDescriptionController,
          decoration: const InputDecoration(labelText: 'Description'),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _clubEmailController,
          decoration: const InputDecoration(labelText: 'Email'),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _clubPasswordController,
          obscureText: true,
          decoration: const InputDecoration(labelText: 'Password'),
        ),
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: createNewClub,
          child: const Text('Create Club'),
        ),
      ],
    );
  }

  Widget buildEventCreationForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Create New Event',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        TextField(
          controller: _eventTitleController,
          decoration: const InputDecoration(labelText: 'Event Title'),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _eventDescriptionController,
          decoration: const InputDecoration(labelText: 'Event Description'),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _eventLocationController,
          decoration: const InputDecoration(labelText: 'Location'),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _eventImageUrlController,
          decoration: const InputDecoration(labelText: 'Event Image URL'),
        ),
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: createNewEvent,
          child: const Text('Create Event'),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        backgroundColor: Colors.indigo,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            buildClubCreationForm(),
            const SizedBox(height: 40),
            buildEventCreationForm(),
            const SizedBox(height: 40),
            const Text('Pending Event Approvals',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            buildPendingEvents(),
            const Divider(height: 40),
            const Text('All Registered Clubs',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            buildClubsList(),
          ],
        ),
      ),
    );
  }
}
