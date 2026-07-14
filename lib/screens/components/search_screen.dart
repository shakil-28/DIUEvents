import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../components/search_bar.dart'; // Point to your newly modernized SearchTextField file
import '../components/event_card.dart';  // Point to your newly modernized EventCard file

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  final String _currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose(); // FIXED: Removed the accidental '.override'
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    // Theme Tokens
    final backgroundColor = isDarkMode ? const Color(0xFF0D0E11) : const Color(0xFFF8F9FA);
    final headingColor = isDarkMode ? Colors.white : const Color(0xFF1A1D24);
    final subtitleColor = isDarkMode ? const Color(0xFF6C727F) : const Color(0xFF8A92A6);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        elevation: 0,
        title: Text(
          'Explore Events',
          style: TextStyle(
            color: headingColor,
            fontSize: 20,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
          ),
        ),
        centerTitle: true,
        iconTheme: IconThemeData(color: headingColor),
      ),
      body: Column(
        children: [
          // Modern Search Input Component
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
            child: SearchTextField(
              controller: _searchController,
              onChanged: (query) {
                setState(() {
                  _searchQuery = query.toLowerCase().trim();
                });
              },
              onClear: () {
                setState(() {
                  _searchQuery = '';
                });
              },
            ),
          ),

          // Dynamic Result Canvas Feed
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('events')
                  .where('approved', isEqualTo: true)
                  .orderBy('startingTime', descending: false)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Error parsing canvas: ${snapshot.error}',
                      style: const TextStyle(color: Colors.redAccent),
                    ),
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(headingColor),
                    ),
                  );
                }

                final rawDocs = snapshot.data?.docs ?? [];

                // Perform semantic local sub-query filtering
                final matchingEvents = rawDocs.where((event) {
                  final data = event.data() as Map<String, dynamic>? ?? {};
                  final title = (data['title'] ?? '').toString().toLowerCase();
                  final location = (data['location'] ?? '').toString().toLowerCase();
                  final category = (data['category'] ?? '').toString().toLowerCase();

                  return title.contains(_searchQuery) || 
                         location.contains(_searchQuery) ||
                         category.contains(_searchQuery);
                }).toList();

                if (matchingEvents.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search_off_rounded,
                          size: 48,
                          color: subtitleColor.withValues(alpha: 0.5),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _searchQuery.isEmpty 
                              ? 'No live events discovered yet.' 
                              : 'No matches found for "$_searchQuery"',
                          textAlign: TextAlign.center, // FIXED: Changed from 'Center' to 'TextAlign.center'
                          style: TextStyle(
                            color: subtitleColor,
                            fontSize: 15,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(24.0, 12.0, 24.0, 40.0),
                  itemCount: matchingEvents.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 20.0),
                      child: EventCard(
                        event: matchingEvents[index],
                        currentUserId: _currentUserId,
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}