import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'event_details_screen.dart';

class ClubEventsScreen extends StatefulWidget {
  final String clubId;

  const ClubEventsScreen({super.key, required this.clubId});

  @override
  State<ClubEventsScreen> createState() => _ClubEventsScreenState();
}

class _ClubEventsScreenState extends State<ClubEventsScreen> {
  // Edit form controllers
  late TextEditingController _editTitleCtrl;
  late TextEditingController _editDescCtrl;
  late TextEditingController _editLocCtrl;
  DateTime? _editStart;
  DateTime? _editEnd;
  String? _editingEventId;

  @override
  void initState() {
    super.initState();
    _editTitleCtrl = TextEditingController();
    _editDescCtrl = TextEditingController();
    _editLocCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _editTitleCtrl.dispose();
    _editDescCtrl.dispose();
    _editLocCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadEventData(String eventId) async {
    try {
      final doc = await FirebaseFirestore.instance.collection('events').doc(eventId).get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>? ?? {};
        setState(() {
          _editTitleCtrl.text = data['title'] ?? '';
          _editDescCtrl.text = data['description'] ?? '';
          _editLocCtrl.text = data['location'] ?? '';
          _editStart = data['startingTime'] != null ? (data['startingTime'] as Timestamp).toDate() : null;
          _editEnd = data['endTime'] != null ? (data['endTime'] as Timestamp).toDate() : null;
          _editingEventId = eventId;
        });
        _showEditDialog();
      }
    } catch (e) {
      debugPrint('Error loading event: $e');
    }
  }

  void _showEditDialog() {
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (dialogCtx, setDlgState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text('Edit Event', style: TextStyle(fontWeight: FontWeight.w700)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: _editTitleCtrl, decoration: const InputDecoration(labelText: 'Title')),
                const SizedBox(height: 12),
                TextField(controller: _editDescCtrl, maxLines: 3, decoration: const InputDecoration(labelText: 'Description')),
                const SizedBox(height: 12),
                TextField(controller: _editLocCtrl, decoration: const InputDecoration(labelText: 'Location')),
                const SizedBox(height: 16),
                InkWell(
                  onTap: () async {
                    final date = await showDatePicker(context: dialogCtx, initialDate: _editStart ?? DateTime.now(), firstDate: DateTime.now(), lastDate: DateTime(2100));
                    if (date == null) return;
                    final time = await showTimePicker(context: dialogCtx, initialTime: TimeOfDay.fromDateTime(_editStart ?? DateTime.now()));
                    if (time == null) return;
                    setDlgState(() => _editStart = DateTime(date.year, date.month, date.day, time.hour, time.minute));
                  },
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), color: Colors.grey.shade100),
                    child: Row(children: [Icon(Icons.calendar_today_rounded, size: 20, color: Colors.grey), const SizedBox(width: 8), Expanded(child: Text(_editStart != null ? 'Start: ${_editStart!.day}/${_editStart!.month}/$_editStart!.year ${_formatTime(_editStart!)}' : 'Pick Start Time', style: const TextStyle(color: Colors.grey)))]),
                  ),
                ),
                const SizedBox(height: 8),
                InkWell(
                  onTap: () async {
                    final date = await showDatePicker(context: dialogCtx, initialDate: _editEnd ?? DateTime.now(), firstDate: DateTime.now(), lastDate: DateTime(2100));
                    if (date == null) return;
                    final time = await showTimePicker(context: dialogCtx, initialTime: TimeOfDay.fromDateTime(_editEnd ?? DateTime.now()));
                    if (time == null) return;
                    setDlgState(() => _editEnd = DateTime(date.year, date.month, date.day, time.hour, time.minute));
                  },
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), color: Colors.grey.shade100),
                    child: Row(children: [Icon(Icons.access_time_rounded, size: 20, color: Colors.grey), const SizedBox(width: 8), Expanded(child: Text(_editEnd != null ? 'End: ${_editEnd!.day}/${_editEnd!.month}/$_editEnd!.year ${_formatTime(_editEnd!)}' : 'Pick End Time', style: const TextStyle(color: Colors.grey)))]),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                try {
                  await FirebaseFirestore.instance.collection('events').doc(_editingEventId).update({
                    'title': _editTitleCtrl.text.trim(),
                    'description': _editDescCtrl.text.trim(),
                    'location': _editLocCtrl.text.trim(),
                    'startingTime': _editStart != null ? Timestamp.fromDate(_editStart!) : FieldValue.delete(),
                    'endTime': _editEnd != null ? Timestamp.fromDate(_editEnd!) : FieldValue.delete(),
                  });
                  if (ctx.mounted) {
                    ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('Event updated')));
                    Navigator.pop(ctx);
                  }
                } catch (e) {
                  if (ctx.mounted) {
                    ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text('Failed: $e')));
                  }
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteEvent(BuildContext context, String eventId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Event'),
        content: const Text('Are you sure? This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete', style: TextStyle(color: Colors.redAccent))),
        ],
      ),
    );
    if (confirmed == true) {
      try {
        await FirebaseFirestore.instance.collection('events').doc(eventId).delete();
        if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Event deleted')));
      } catch (e) {
        if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF0D0E11) : const Color(0xFFF8F9FA);
    final cardBg = isDark ? const Color(0xFF16181D) : Colors.white;
    final heading = isDark ? Colors.white : const Color(0xFF1A1D24);
    final sub = isDark ? const Color(0xFF6C727F) : const Color(0xFF8A92A6);

    return RefreshIndicator(
      onRefresh: () => Future.delayed(const Duration(milliseconds: 500)),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Your Events', style: TextStyle(color: heading, fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),

            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('events')
                  .where('clubId', isEqualTo: widget.clubId)
                  .orderBy('startingTime', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator()));
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(child: Padding(padding: const EdgeInsets.all(40), child: Column(children: [Icon(Icons.event_busy_rounded, size: 64, color: sub.withValues(alpha: 0.4)), const SizedBox(height: 12), Text('No events yet', style: TextStyle(color: sub, fontSize: 15))], crossAxisAlignment: CrossAxisAlignment.center)));
                }

                return Column(
                  children: snapshot.data!.docs.map((doc) {
                    final data = doc.data() as Map<String, dynamic>? ?? {};
                    final isApproved = data['approved'] == true;
                    final imageUrl = data['imageUrl'] ?? '';
                    final title = data['title'] ?? 'Untitled';
                    final location = data['location'] ?? 'TBA';
                    final startTime = data['startingTime'] != null ? (data['startingTime'] as Timestamp).toDate() : null;
                    final endTime = data['endTime'] != null ? (data['endTime'] as Timestamp).toDate() : null;

                    return GestureDetector(
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => EventDetailsScreen(eventId: doc.id))),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(color: cardBg, borderRadius: BorderRadius.circular(16)),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Banner image
                            if (imageUrl.isNotEmpty)
                              ClipRRect(borderRadius: const BorderRadius.vertical(top: Radius.circular(16)), child: Image.network(imageUrl, height: 140, width: double.infinity, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(height: 140, color: isDark ? const Color(0xFF1E222B) : const Color(0xFFE9ECEF))))
                            else
                              Container(height: 140, color: isDark ? const Color(0xFF1E222B) : const Color(0xFFE9ECEF), child: const Center(child: Icon(Icons.event_available_rounded, size: 40, color: Colors.grey))),

                            Padding(
                              padding: const EdgeInsets.all(14),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(child: Text(title, style: TextStyle(color: heading, fontWeight: FontWeight.w700, fontSize: 16), maxLines: 1, overflow: TextOverflow.ellipsis)),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(color: isApproved ? Colors.green.withValues(alpha: 0.12) : Colors.orange.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)),
                                        child: Text(isApproved ? 'Live' : 'Pending', style: TextStyle(color: isApproved ? Colors.green : Colors.orange, fontSize: 11, fontWeight: FontWeight.w600)),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Row(children: [Icon(Icons.calendar_today_rounded, size: 14, color: sub), const SizedBox(width: 4), Expanded(child: Text(startTime != null ? '${startTime.day} ${_monthAbbr(startTime.month)}, ${startTime.year}' : 'Date TBD', style: TextStyle(color: sub, fontSize: 12)))]),
                                  const SizedBox(height: 4),
                                  Row(children: [Icon(Icons.location_on_rounded, size: 14, color: sub), const SizedBox(width: 4), Expanded(child: Text(location, style: TextStyle(color: sub, fontSize: 12)))]),
                                  const SizedBox(height: 10),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      TextButton.icon(
                                        onPressed: () => _loadEventData(doc.id),
                                        icon: const Icon(Icons.edit_rounded, size: 16),
                                        label: const Text('Edit', style: TextStyle(fontSize: 13)),
                                      ),
                                      const SizedBox(width: 8),
                                      TextButton.icon(
                                        onPressed: () => _deleteEvent(context, doc.id),
                                        icon: const Icon(Icons.delete_outline_rounded, size: 16),
                                        label: const Text('Delete', style: TextStyle(fontSize: 13, color: Colors.redAccent)),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  String _monthAbbr(int m) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[m - 1];
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m${dt.hour >= 12 ? "PM" : "AM"}';
  }
}
