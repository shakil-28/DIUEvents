import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../event_details_screen.dart';

class EventCard extends StatelessWidget {
  final DocumentSnapshot event;
  final String currentUserId;

  const EventCard({
    super.key,
    required this.event,
    required this.currentUserId,
  });

  /// Helper to safely parse date from dynamic value (Timestamp or String)
  DateTime? _parseDate(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final data = event.data() as Map<String, dynamic>? ?? {};
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    final DateTime? startTime = _parseDate(data['startingTime']);

    // Premium UI Theme design variables
    final cardBgColor = isDarkMode ? const Color(0xFF16181D) : Colors.white;
    final headingColor = isDarkMode ? Colors.white : const Color(0xFF1A1D24);
    final subtitleColor = isDarkMode ? const Color(0xFF9BA1B1) : const Color(0xFF6C727F);
    final shadowColor = isDarkMode ? Colors.black.withValues(alpha: 0.35) : Colors.black.withValues(alpha: 0.05);

    // Format fields for separate UI regions
    final String formattedTime = startTime != null ? DateFormat('h:mm a').format(startTime) : 'TBA';
    final String eventMonth = startTime != null ? DateFormat('MMM').format(startTime).toUpperCase() : '---';
    final String eventDay = startTime != null ? DateFormat('d').format(startTime) : '--';

    final List lovedUsers = List.from(data['lovedUsers'] ?? []);
    final bool isLoved = lovedUsers.contains(currentUserId);
    final int reactCount = data['reactCount'] ?? lovedUsers.length;

    final String imageUrl = data['imageUrl'] ?? '';
    final String title = data['title'] ?? 'Untitled Event';
    final String location = data['location'] ?? 'Location TBA';
    final String category = data['category'] ?? 'Featured';

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => EventDetailsScreen(eventId: event.id),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: cardBgColor,
          borderRadius: BorderRadius.circular(24.0),
          boxShadow: [
            BoxShadow(
              color: shadowColor,
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias, // Masks child layers safely inside decoration corners
        child: Stack(
          children: [
            // 1. Full-Bleed Media Presentation Layout
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AspectRatio(
                  aspectRatio: 16 / 10,
                  child: imageUrl.isNotEmpty
                      ? Image.network(
                          imageUrl,
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, progress) {
                            if (progress == null) return child;
                            return Container(
                              color: isDarkMode ? const Color(0xFF232732) : const Color(0xFFE9ECEF),
                              child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                            );
                          },
                          errorBuilder: (context, error, stackTrace) => _buildPlaceholder(isDarkMode),
                        )
                      : _buildPlaceholder(isDarkMode),
                ),

                // 2. Clear Information Content Block
                Padding(
                  padding: const EdgeInsets.all(18.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Subheading Category Tag Pill
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: isDarkMode ? Colors.white.withValues(alpha: 0.06) : const Color(0xFFF1F3F5),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          category.toUpperCase(),
                          style: TextStyle(
                            color: isDarkMode ? const Color(0xFFE9ECEF) : const Color(0xFF495057),
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.6,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Title
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: headingColor,
                          fontSize: 19,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.4,
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Time and Location Grid Columns
                      Row(
                        children: [
                          Icon(Icons.access_time_filled_rounded, size: 14, color: subtitleColor),
                          const SizedBox(width: 6),
                          Text(
                            formattedTime,
                            style: TextStyle(color: subtitleColor, fontSize: 13, fontWeight: FontWeight.w500),
                          ),
                          const SizedBox(width: 14),
                          Icon(Icons.location_on_rounded, size: 14, color: subtitleColor),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              location,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(color: subtitleColor, fontSize: 13, fontWeight: FontWeight.w500),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // 3. Premium Glassmorphic Floating Calendar Stamp
            Positioned(
              top: 14,
              left: 14,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.38),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.12), width: 1),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            eventDay,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              height: 1.1,
                            ),
                          ),
                          Text(
                            eventMonth,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // 4. Floating Glassmorphic Heart Reaction System
            Positioned(
              top: 14,
              right: 14,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.38),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.12), width: 1),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          GestureDetector(
                            onTap: () async {
                              final eventRef = FirebaseFirestore.instance.collection('events').doc(event.id);
                              await FirebaseFirestore.instance.runTransaction((transaction) async {
                                final snapshot = await transaction.get(eventRef);
                                final snapshotData = snapshot.data() ?? {};
                                final List currentLoved = List.from(snapshotData['lovedUsers'] ?? []);

                                if (currentLoved.contains(currentUserId)) {
                                  currentLoved.remove(currentUserId);
                                } else {
                                  currentLoved.add(currentUserId);
                                }

                                transaction.update(eventRef, {
                                  'lovedUsers': currentLoved,
                                  'reactCount': currentLoved.length,
                                });
                              });
                            },
                            child: Icon(
                              isLoved ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                              color: isLoved ? const Color(0xFFFF4A5A) : Colors.white,
                              size: 20,
                            ),
                          ),
                          if (reactCount > 0) ...[
                            const SizedBox(width: 6),
                            Text(
                              '$reactCount',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholder(bool isDarkMode) {
    return Container(
      color: isDarkMode ? const Color(0xFF232732) : const Color(0xFFE9ECEF),
      child: Center(
        child: Icon(
          Icons.event_available_rounded,
          size: 40,
          color: isDarkMode ? Colors.white24 : Colors.black26,
        ),
      ),
    );
  }
}