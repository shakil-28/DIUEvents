import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../auth/auth.dart';
import 'create_event_screen_club.dart';
import 'club_events_screen.dart';
import 'club_members_screen.dart';
import 'club_profile_screen.dart';

class ClubDashboardScreen extends StatefulWidget {
  final String clubId;
  final String clubName;
  final void Function(ThemeMode)? setThemeMode;

  const ClubDashboardScreen({
    super.key,
    required this.clubId,
    required this.clubName,
    this.setThemeMode,
  });

  @override
  State<ClubDashboardScreen> createState() => _ClubDashboardScreenState();
}

class _ClubDashboardScreenState extends State<ClubDashboardScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _totalMembers = 0;
  int _pendingRequests = 0;
  int _totalEvents = 0;
  int _approvedEvents = 0;
  int _upcomingEvents = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadStats();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadStats() async {
    try {
      final userId = widget.clubId;

      // Members + requests
      final membersSnap = await FirebaseFirestore.instance.collection('users').doc(userId).get();
      if (membersSnap.exists) {
        final data = membersSnap.data() ?? {};
        final members = List<String>.from(data['members'] ?? []);
        final requests = List<String>.from(data['memberRequests'] ?? []);
        setState(() {
          _totalMembers = members.length;
          _pendingRequests = requests.length;
        });
      }

      // Events stream for stats
      final eventsStream = FirebaseFirestore.instance
          .collection('events')
          .where('clubId', isEqualTo: userId)
          .snapshots();

      eventsStream.listen((snapshot) {
        if (!mounted) return;
        final nowTs = Timestamp.now();
        int approvedCount = 0;
        int upcomingCount = 0;
        for (var doc in snapshot.docs) {
          final d = doc.data() as Map<String, dynamic>;
          if (d['approved'] == true) approvedCount++;
          if (d['startingTime'] is Timestamp && (d['startingTime'] as Timestamp).compareTo(nowTs) > 0) {
            upcomingCount++;
          }
        }
        setState(() {
          _totalEvents = snapshot.docs.length;
          _approvedEvents = approvedCount;
          _upcomingEvents = upcomingCount;
          _isLoading = false;
        });
      });
    } catch (e) {
      debugPrint('Error loading stats: $e');
      setState(() => _isLoading = false);
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
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(widget.clubName, style: TextStyle(color: heading, fontSize: 18, fontWeight: FontWeight.w800)),
          Text('Club Dashboard', style: TextStyle(color: sub, fontSize: 12)),
        ]),
        centerTitle: false,
        actions: [
          IconButton(
            icon: Icon(Icons.edit_rounded, color: accent),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => ClubProfileScreen(clubId: widget.clubId)));
            },
            tooltip: 'Edit Club Profile',
          ),
          IconButton(
            icon: Icon(Icons.add_circle_outline_rounded, color: accent),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CreateEventScreenClub())),
            tooltip: 'Create Event',
          ),
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert_rounded, color: heading),
            onSelected: (v) {
              if (v == 'logout') AuthService.signOut(context);
            },
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'logout', child: Text('Sign Out', style: TextStyle(color: Colors.redAccent))),
            ],
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: accent,
          indicatorWeight: 3,
          labelColor: accent,
          unselectedLabelColor: sub,
          tabs: const [
            Tab(text: 'Overview', icon: Icon(Icons.bar_chart_rounded, size: 20)),
            Tab(text: 'Events', icon: Icon(Icons.event_rounded, size: 20)),
            Tab(text: 'Members', icon: Icon(Icons.people_rounded, size: 20)),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildOverviewTab(cardBg, heading, sub, accent),
                ClubEventsScreen(clubId: widget.clubId),
                ClubMembersScreen(clubId: widget.clubId),
              ],
            ),
    );
  }

  Widget _buildOverviewTab(Color cardBg, Color heading, Color sub, Color accent) {
    return RefreshIndicator(
      onRefresh: _loadStats,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Welcome back! \ud83d\udc4b',
              style: TextStyle(color: heading, fontSize: 22, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 4),
            Text(
              "Here's what's happening with your club.",
              style: TextStyle(color: sub, fontSize: 14),
            ),
            const SizedBox(height: 24),

            // Stats Grid 2x2
            Row(children: [
              Expanded(child: _buildStatCard(Icons.group_rounded, Colors.blueAccent, '$_totalMembers', 'Members', cardBg, heading, sub)),
              const SizedBox(width: 12),
              Expanded(child: _buildStatCard(Icons.check_circle_rounded, Colors.green, '$_approvedEvents', 'Live Events', cardBg, heading, sub)),
            ]),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: _buildStatCard(Icons.schedule_rounded, Colors.orange, '$_upcomingEvents', 'Upcoming', cardBg, heading, sub)),
              const SizedBox(width: 12),
              Expanded(child: _buildStatCard(Icons.pending_actions_rounded, Colors.purple, '$_pendingRequests', 'Requests', cardBg, heading, sub)),
            ]),
            const SizedBox(height: 24),

            // Quick Actions
            Text('Quick Actions', style: TextStyle(color: heading, fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            _buildQuickAction(Icons.add_circle_rounded, 'Create New Event', accent, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CreateEventScreenClub()))),
            _buildQuickAction(Icons.person_add_rounded, 'Manage Members', Colors.green, () => _tabController.animateTo(2)),
            _buildQuickAction(Icons.assignment_rounded, "Pending Requests ($_pendingRequests)", Colors.orange, () { if (_pendingRequests > 0) _tabController.animateTo(2); }),
            _buildQuickAction(Icons.edit_rounded, 'Club Profile', Colors.teal, () => Navigator.push(context, MaterialPageRoute(builder: (_) => ClubProfileScreen(clubId: widget.clubId)))),
            const SizedBox(height: 24),

            // Recent Activity
            Text('Recent Activity', style: TextStyle(color: heading, fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('events')
                  .where('clubId', isEqualTo: widget.clubId)
                  .orderBy('createdAt', descending: true)
                  .limit(5)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.all(24),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(Icons.inbox_rounded, size: 48, color: sub.withValues(alpha: 0.5)),
                          const SizedBox(height: 8),
                          Text('No events yet', style: TextStyle(color: sub, fontSize: 14)),
                        ],
                      ),
                    ),
                  );
                }
                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    final doc = snapshot.data!.docs[index];
                    final data = doc.data() as Map<String, dynamic>? ?? {};
                    final isApproved = data['approved'] == true;
                    final eventDate = data['startingTime'] != null ? (data['startingTime'] as Timestamp).toDate() : null;
                    final dateStr = eventDate != null ? '${eventDate.day} ${_monthAbbr(eventDate.month)} ${eventDate.year}' : 'TBD';
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(color: cardBg, borderRadius: BorderRadius.circular(14)),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: isApproved ? Colors.green.withValues(alpha: 0.12) : Colors.orange.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            isApproved ? Icons.check_circle_rounded : Icons.schedule_rounded,
                            color: isApproved ? Colors.green : Colors.orange,
                            size: 20,
                          ),
                        ),
                        title: Text(
                          data['title'] ?? 'Untitled',
                          style: TextStyle(color: heading, fontWeight: FontWeight.w600, fontSize: 14),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(dateStr, style: TextStyle(color: sub, fontSize: 12)),
                        trailing: Chip(
                          label: Text(
                            isApproved ? 'Live' : 'Pending',
                            style: TextStyle(color: isApproved ? Colors.green : Colors.orange, fontSize: 11, fontWeight: FontWeight.w600),
                          ),
                          backgroundColor: isApproved ? Colors.green.withValues(alpha: 0.1) : Colors.orange.withValues(alpha: 0.1),
                          side: BorderSide.none,
                          visualDensity: VisualDensity.compact,
                        ),
                      ),
                    );
                  },
                );
              },
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(IconData icon, Color iconColor, String value, String label, Color cardBg, Color heading, Color sub) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: cardBg, borderRadius: BorderRadius.circular(16)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: iconColor.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, size: 22, color: iconColor),
        ),
        const SizedBox(height: 12),
        Text(value, style: TextStyle(color: heading, fontSize: 24, fontWeight: FontWeight.w800)),
        Text(label, style: TextStyle(color: sub, fontSize: 12, fontWeight: FontWeight.w500)),
      ]),
    );
  }

  Widget _buildQuickAction(IconData icon, String label, Color color, VoidCallback onTap) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF16181D) : Colors.white;
    final heading = isDark ? Colors.white : const Color(0xFF1A1D24);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(color: cardBg, borderRadius: BorderRadius.circular(14)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, size: 20, color: color),
        ),
        title: Text(label, style: TextStyle(color: heading, fontWeight: FontWeight.w600, fontSize: 14)),
        trailing: const Icon(Icons.chevron_right_rounded, size: 20, color: Colors.grey),
        onTap: onTap,
      ),
    );
  }

  String _monthAbbr(int m) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[m - 1];
  }
}
