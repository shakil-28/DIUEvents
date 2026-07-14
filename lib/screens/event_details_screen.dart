import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class EventDetailsScreen extends StatefulWidget {
  final String eventId;

  const EventDetailsScreen({super.key, required this.eventId});

  @override
  State<EventDetailsScreen> createState() => _EventDetailsScreenState();
}

class _EventDetailsScreenState extends State<EventDetailsScreen> {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  DocumentSnapshot? eventDoc;
  bool isLoading = true;
  bool isInterested = false;
  bool isLoved = false;
  int reactCount = 0;
  String _successMessage = '';
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadEventData();
  }

  Future<void> _loadEventData() async {
    try {
      eventDoc = await _firestore.collection('events').doc(widget.eventId).get();
      if (!mounted) return;

      if (eventDoc!.exists) {
        final data = (eventDoc!.data() as Map<String, dynamic>? ?? {});
        final List interestedUsers = List<String>.from(data['interestedUsers'] ?? []);
        final List lovedUsers = List<String>.from(data['lovedUsers'] ?? []);

        setState(() {
          isInterested = interestedUsers.contains(_auth.currentUser?.uid);
          isLoved = lovedUsers.contains(_auth.currentUser?.uid);
          reactCount = data['reactCount'] ?? lovedUsers.length;
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
          _errorMessage = 'Event not found.';
        });
      }
    } catch (e) {
      setState(() {
        isLoading = false;
        _errorMessage = 'Failed to load event details.';
      });
    }
  }

  Future<void> _toggleInterest() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    setState(() => isLoading = true);
    try {
      final ref = _firestore.collection('events').doc(widget.eventId);
      await _firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(ref);
        final data = snapshot.data()!;
        final List users = List<String>.from(data['interestedUsers'] ?? []);

        if (users.contains(uid)) {
          users.remove(uid);
        } else {
          users.add(uid);
        }

        transaction.update(ref, {'interestedUsers': users});
      });
      await _loadEventData();
    } catch (e) {
      setState(() => _errorMessage = 'Failed to update interest.');
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) setState(() => _errorMessage = '');
      });
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> _toggleLove() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    setState(() => isLoading = true);
    try {
      final ref = _firestore.collection('events').doc(widget.eventId);
      await _firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(ref);
        final data = snapshot.data()!;
        final List lovedUsers = List<String>.from(data['lovedUsers'] ?? []);
        final currentCount = data['reactCount'] ?? lovedUsers.length;

        if (lovedUsers.contains(uid)) {
          lovedUsers.remove(uid);
          transaction.update(ref, {
            'lovedUsers': lovedUsers,
            'reactCount': currentCount - 1,
          });
        } else {
          lovedUsers.add(uid);
          transaction.update(ref, {
            'lovedUsers': lovedUsers,
            'reactCount': currentCount + 1,
          });
        }
      });
      await _loadEventData();
    } catch (e) {
      setState(() => _errorMessage = 'Failed to update love.');
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) setState(() => _errorMessage = '');
      });
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  String _monthAbbr(int m) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[m - 1];
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF0D0E11) : const Color(0xFFF8F9FA);
    final cardBg = isDark ? const Color(0xFF16181D) : Colors.white;
    final heading = isDark ? Colors.white : const Color(0xFF1A1D24);
    final sub = isDark ? const Color(0xFF6C727F) : const Color(0xFF8A92A6);
    final accent = isDark ? const Color(0xFF4C6FFF) : const Color(0xFF1A1D24);

    final data = (eventDoc?.data() as Map<String, dynamic>? ?? {});
    final imageUrl = data['imageUrl'] ?? '';
    final category = data['category'] ?? 'Featured';

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        title: Text('Event Details', style: TextStyle(color: heading, fontWeight: FontWeight.w700)),
        centerTitle: true,
        iconTheme: IconThemeData(color: heading),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage.isNotEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 64, color: Colors.redAccent),
                      const SizedBox(height: 16),
                      Text(_errorMessage, style: TextStyle(color: sub, fontSize: 16)),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Go Back'),
                        style: ElevatedButton.styleFrom(backgroundColor: accent, minimumSize: const Size(200, 48)),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadEventData,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Success Message
                        if (_successMessage.isNotEmpty)
                          Container(
                            margin: const EdgeInsets.all(20),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.green.withOpacity(0.3)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.check_circle, size: 20, color: Colors.green),
                                const SizedBox(width: 8),
                                Expanded(child: Text(_successMessage, style: const TextStyle(color: Colors.green, fontWeight: FontWeight.w500))),
                              ],
                            ),
                          ),

                        // Error Message
                        if (_errorMessage.isNotEmpty && _errorMessage != 'Event not found.')
                          Container(
                            margin: const EdgeInsets.all(20),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.red.withOpacity(0.3)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.error, size: 20, color: Colors.red),
                                const SizedBox(width: 8),
                                Expanded(child: Text(_errorMessage, style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w500))),
                              ],
                            ),
                          ),


                        if (imageUrl.isNotEmpty)
                          ClipRRect(
                            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
                            child: Stack(
                              children: [
                                Image.network(
                                  imageUrl,
                                  width: double.infinity,
                                  height: 320,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Container(
                                    height: 320,
                                    color: isDark ? const Color(0xFF1E222B) : const Color(0xFFE9ECEF),
                                    child: const Icon(Icons.image_not_supported, size: 48, color: Colors.grey),
                                  ),
                                ),
                                // Category Badge
                                Positioned(
                                  top: 16,
                                  left: 16,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: isDark ? Colors.black.withOpacity(0.7) : Colors.white.withOpacity(0.9),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      category.toUpperCase(),
                                      style: TextStyle(
                                        color: isDark ? Colors.white : heading,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ),
                                ),
                                // Love Button Overlay
                                Positioned(
                                  top: 16,
                                  right: 16,
                                  child: GestureDetector(
                                    onTap: _toggleLove,
                                    child: Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: isDark ? Colors.black.withOpacity(0.7) : Colors.white.withOpacity(0.9),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        isLoved ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                                        color: isLoved ? Colors.red : sub,
                                        size: 24,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )
                        else
                          Container(
                            height: 320,
                            color: isDark ? const Color(0xFF1E222B) : const Color(0xFFE9ECEF),
                            child: const Center(child: Icon(Icons.event_available_rounded, size: 64, color: Colors.grey)),
                          ),

                        // Event Info Card
                        Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Title
                              Text(
                                data['title'] ?? 'Untitled Event',
                                style: TextStyle(color: heading, fontSize: 26, fontWeight: FontWeight.w800, letterSpacing: -0.5),
                              ),
                              const SizedBox(height: 16),

                              // Date & Time Info
                              Container(
                                decoration: BoxDecoration(color: cardBg, borderRadius: BorderRadius.circular(16)),
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  children: [
                                    Row(
                                      children: [
                                        Icon(Icons.calendar_today_rounded, size: 20, color: accent),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text('Date & Time', style: TextStyle(color: sub, fontSize: 13, fontWeight: FontWeight.w600)),
                                              const SizedBox(height: 2),
                                              if (data['startingTime'] != null)
                                                Text(
                                                  DateFormat('MMM d, yyyy').format((data['startingTime'] as Timestamp).toDate()),
                                                  style: TextStyle(color: heading, fontSize: 15, fontWeight: FontWeight.w700),
                                                ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    const Divider(height: 24),
                                    Row(
                                      children: [
                                        Icon(Icons.access_time_rounded, size: 20, color: accent),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text('Time', style: TextStyle(color: sub, fontSize: 13, fontWeight: FontWeight.w600)),
                                              const SizedBox(height: 2),
                                              if (data['startingTime'] != null && data['endTime'] != null)
                                                Text(
                                                  '${DateFormat('hh:mm a').format((data['startingTime'] as Timestamp).toDate())} - ${DateFormat('hh:mm a').format((data['endTime'] as Timestamp).toDate())}',
                                                  style: TextStyle(color: heading, fontSize: 15, fontWeight: FontWeight.w700),
                                                ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    const Divider(height: 24),
                                    Row(
                                      children: [
                                        Icon(Icons.location_on_rounded, size: 20, color: accent),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text('Location', style: TextStyle(color: sub, fontSize: 13, fontWeight: FontWeight.w600)),
                                              const SizedBox(height: 2),
                                              Text(
                                                data['location'] ?? 'TBA',
                                                style: TextStyle(color: heading, fontSize: 15, fontWeight: FontWeight.w700),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 24),

                              // Description
                              Text(
                                'Description',
                                style: TextStyle(color: heading, fontSize: 18, fontWeight: FontWeight.w700, letterSpacing: -0.3),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                decoration: BoxDecoration(color: cardBg, borderRadius: BorderRadius.circular(16)),
                                padding: const EdgeInsets.all(16),
                                child: Text(
                                  data['description'] ?? 'No description provided.',
                                  style: TextStyle(color: sub, fontSize: 15, height: 1.6),
                                ),
                              ),

                              const SizedBox(height: 24),

                              // Love Count
                              Row(
                                children: [
                                  Icon(Icons.favorite_rounded, size: 20, color: Colors.redAccent),
                                  const SizedBox(width: 8),
                                  Text(
                                    '$reactCount people love this event',
                                    style: TextStyle(color: sub, fontSize: 14, fontWeight: FontWeight.w500),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 24),

                              // Join Button
                              ElevatedButton.icon(
                                onPressed: isLoading ? null : _toggleInterest,
                                icon: Icon(isInterested ? Icons.check_circle_rounded : Icons.add_circle_outline_rounded),
                                label: Text(isInterested ? 'You\'re Joined' : 'Join This Event'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: isInterested ? Colors.green : accent,
                                  foregroundColor: Colors.white,
                                  minimumSize: const Size(double.infinity, 56),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
    );
  }
}
