import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ClubMembersScreen extends StatefulWidget {
  final String clubId;

  const ClubMembersScreen({super.key, required this.clubId});

  @override
  State<ClubMembersScreen> createState() => _ClubMembersScreenState();
}

class _ClubMembersScreenState extends State<ClubMembersScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _searchCtrl.addListener(() {
      setState(() => _searchQuery = _searchCtrl.text.trim().toLowerCase());
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _approveMember(String memberId) async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(widget.clubId).update({
        'members': FieldValue.arrayUnion([memberId]),
        'memberRequests': FieldValue.arrayRemove([memberId]),
      });
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Member approved')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
    }
  }

  Future<void> _rejectMember(String memberId) async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(widget.clubId).update({
        'memberRequests': FieldValue.arrayRemove([memberId]),
      });
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Request rejected')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
    }
  }

  Future<void> _removeMember(String memberId) async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(widget.clubId).update({
        'members': FieldValue.arrayRemove([memberId]),
      });
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Member removed')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
    }
  }

  Future<Map<String, dynamic>> _getUserInfo(String uid) async {
    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      final data = doc.data() ?? {};
      return {'name': data['fullName'] ?? data['name'] ?? 'Unknown', 'photoURL': data['photoURL'] ?? ''};
    } catch (_) {
      return {'name': uid.substring(0, 6), 'photoURL': ''};
    }
  }

  Widget _buildMemberTile({required String name, String? photoUrl, required List<Widget> actions}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF16181D) : Colors.white;
    final heading = isDark ? Colors.white : const Color(0xFF1A1D24);
    final sub = isDark ? const Color(0xFF6C727F) : const Color(0xFF8A92A6);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(color: cardBg, borderRadius: BorderRadius.circular(14)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: CircleAvatar(
          radius: 22,
          backgroundColor: isDark ? const Color(0xFF232732) : const Color(0xFFE9ECEF),
          backgroundImage: photoUrl != null && photoUrl.isNotEmpty ? NetworkImage(photoUrl) : null,
          child: (photoUrl == null || photoUrl.isEmpty) ? Icon(Icons.person_rounded, size: 22, color: sub) : null,
        ),
        title: Text(name, style: TextStyle(color: heading, fontWeight: FontWeight.w600, fontSize: 14)),
        trailing: Row(mainAxisSize: MainAxisSize.min, children: actions),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF0D0E11) : const Color(0xFFF8F9FA);
    final heading = isDark ? Colors.white : const Color(0xFF1A1D24);
    final sub = isDark ? const Color(0xFF6C727F) : const Color(0xFF8A92A6);
    final accent = isDark ? const Color(0xFF4C6FFF) : const Color(0xFF1A1D24);

    return Scaffold(
      backgroundColor: bg,
      body: Column(
        children: [
          // Stats bar + search
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildMiniStat(Icons.people_rounded, 'Members', StreamBuilder<int>(
                    stream: FirebaseFirestore.instance.collection('users').doc(widget.clubId).snapshots().map((d) => (d.data()?['members'] as List?)?.length ?? 0),
                    builder: (_, s) => Text(s.hasData ? '${s.data}' : '-', style: TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.w700, fontSize: 18)),
                  )),
                  _buildMiniStat(Icons.pending_rounded, 'Requests', StreamBuilder<int>(
                    stream: FirebaseFirestore.instance.collection('users').doc(widget.clubId).snapshots().map((d) => (d.data()?['memberRequests'] as List?)?.length ?? 0),
                    builder: (_, s) => Text(s.hasData ? '${s.data}' : '-', style: TextStyle(color: Colors.orange, fontWeight: FontWeight.w700, fontSize: 18)),
                  )),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _searchCtrl,
                decoration: InputDecoration(
                  hintText: 'Search members...',
                  prefixIcon: Icon(Icons.search_rounded, color: sub),
                  suffixIcon: _searchQuery.isNotEmpty ? IconButton(icon: const Icon(Icons.clear_rounded), onPressed: () => _searchCtrl.clear()) : null,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                  filled: true,
                  fillColor: isDark ? const Color(0xFF16181D) : Colors.grey.shade100,
                ),
                style: TextStyle(color: heading),
              ),
            ]),
          ),

          TabBar(
            controller: _tabController,
            indicatorColor: accent,
            labelColor: accent,
            unselectedLabelColor: sub,
            tabs: const [Tab(text: 'Members'), Tab(text: 'Requests')],
          ),

          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [_buildMembersList(heading, sub), _buildPendingRequests(heading, sub)],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStat(IconData icon, String label, Widget valueWidget) {
    return Row(children: [Icon(icon, size: 18, color: Colors.grey), const SizedBox(width: 6), valueWidget, const SizedBox(width: 8), Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13))]);
  }

  // ─── Members List with search filter ─────────────────────────
  Widget _buildMembersList(Color heading, Color sub) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(widget.clubId).snapshots(),
      builder: (context, snap) {
        if (!snap.hasData) return const Center(child: CircularProgressIndicator());
        final data = snap.data?.data() as Map<String, dynamic>? ?? {};
        final members = List<String>.from(data['members'] ?? []);

        if (members.isEmpty) {
          return Center(child: Padding(padding: const EdgeInsets.all(40), child: Column(children: [Icon(Icons.people_outline_rounded, size: 64, color: heading.withValues(alpha: 0.3)), const SizedBox(height: 12), Text('No members yet', style: TextStyle(color: heading.withValues(alpha: 0.5)))], crossAxisAlignment: CrossAxisAlignment.center)));
        }

        return RefreshIndicator(
          onRefresh: () => Future.delayed(const Duration(milliseconds: 500)),
          child: FutureBuilder<List<Map<String, dynamic>>>(
            future: _fetchAllUserInfo(members),
            builder: (context, futureSnap) {
              if (!futureSnap.hasData) return const Center(child: CircularProgressIndicator());
              final userInfos = futureSnap.data!;
              final searchTerm = _searchQuery;
              final filtered = searchTerm.isEmpty
                  ? userInfos
                  : userInfos.where((u) => u['name'].toString().toLowerCase().contains(searchTerm)).toList();

              if (filtered.isEmpty) {
                return Center(child: Padding(padding: const EdgeInsets.all(40), child: Column(children: [Icon(Icons.search_off_rounded, size: 48, color: sub), const SizedBox(height: 8), Text('No results for "$searchTerm"', style: TextStyle(color: sub))], crossAxisAlignment: CrossAxisAlignment.center)));
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: filtered.length,
                itemBuilder: (context, index) {
                  final uid = filtered[index]['uid'];
                  return _buildMemberTile(
                    name: filtered[index]['name'],
                    photoUrl: filtered[index]['photoURL'],
                    actions: [
                      TextButton.icon(onPressed: () => _removeMember(uid), icon: const Icon(Icons.person_remove_rounded, size: 18), label: const Text('Remove', style: TextStyle(fontSize: 12, color: Colors.redAccent))),
                    ],
                  );
                },
              );
            },
          ),
        );
      },
    );
  }

  Future<List<Map<String, dynamic>>> _fetchAllUserInfo(List<String> uids) async {
    return Future.wait(uids.map((uid) async {
      final info = await _getUserInfo(uid);
      return {'uid': uid, 'name': info['name'], 'photoURL': info['photoURL']};
    }));
  }

  // ─── Pending Requests with search filter ──────────────────────
  Widget _buildPendingRequests(Color heading, Color sub) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(widget.clubId).snapshots(),
      builder: (context, snap) {
        if (!snap.hasData) return const Center(child: CircularProgressIndicator());
        final data = snap.data?.data() as Map<String, dynamic>? ?? {};
        final requests = List<String>.from(data['memberRequests'] ?? []);

        if (requests.isEmpty) {
          return Center(child: Padding(padding: const EdgeInsets.all(40), child: Column(children: [Icon(Icons.inbox_rounded, size: 64, color: heading.withValues(alpha: 0.3)), const SizedBox(height: 12), Text('No pending requests', style: TextStyle(color: heading.withValues(alpha: 0.5)))], crossAxisAlignment: CrossAxisAlignment.center)));
        }

        return RefreshIndicator(
          onRefresh: () => Future.delayed(const Duration(milliseconds: 500)),
          child: FutureBuilder<List<Map<String, dynamic>>>(
            future: _fetchAllUserInfo(requests),
            builder: (context, futureSnap) {
              if (!futureSnap.hasData) return const Center(child: CircularProgressIndicator());
              final userInfos = futureSnap.data!;
              final searchTerm = _searchQuery;
              final filtered = searchTerm.isEmpty
                  ? userInfos
                  : userInfos.where((u) => u['name'].toString().toLowerCase().contains(searchTerm)).toList();

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: filtered.length,
                itemBuilder: (context, index) {
                  final uid = filtered[index]['uid'];
                  return _buildMemberTile(
                    name: filtered[index]['name'],
                    photoUrl: filtered[index]['photoURL'],
                    actions: [
                      IconButton(onPressed: () => _approveMember(uid), icon: const Icon(Icons.check_circle_rounded, color: Colors.green, size: 24), tooltip: 'Approve'),
                      IconButton(onPressed: () => _rejectMember(uid), icon: const Icon(Icons.close_rounded, color: Colors.redAccent, size: 24), tooltip: 'Reject'),
                    ],
                  );
                },
              );
            },
          ),
        );
      },
    );
  }
}
