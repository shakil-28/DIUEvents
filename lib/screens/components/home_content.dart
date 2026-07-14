import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../components/search_bar.dart';
import '../event_details_screen.dart';
import '../profile_screen.dart';

class HomeContent extends StatefulWidget {
  const HomeContent({super.key});

  @override
  State<HomeContent> createState() => _HomeContentState();
}

class _HomeContentState extends State<HomeContent> {
  String _selectedCategory = 'All';
  bool _isRefreshing = false;
  String _greeting = '';
  Timer? _greetingTimer;

  final List<Map<String, dynamic>> _categories = const [
    {'label': 'All', 'icon': Icons.layers_rounded},
    {'label': 'Concerts', 'icon': Icons.music_note_rounded},
    {'label': 'Tech', 'icon': Icons.biotech_rounded},
    {'label': 'Sports', 'icon': Icons.sports_soccer_rounded},
    {'label': 'Arts', 'icon': Icons.palette_rounded},
  ];

  final ScrollController _scrollController = ScrollController();
  final ScrollController _carouselController = ScrollController();

  void _updateGreeting() {
    final hour = DateTime.now().hour;
    String greeting;
    if (hour < 12) {
      greeting = 'Good morning';
    } else if (hour < 17) {
      greeting = 'Good afternoon';
    } else {
      greeting = 'Good evening';
    }
    if (mounted && greeting != _greeting) {
      setState(() => _greeting = greeting);
    }
  }

  @override
  void initState() {
    super.initState();
    _updateGreeting();
    _greetingTimer = Timer.periodic(const Duration(minutes: 1), (_) => _updateGreeting());
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _carouselController.dispose();
    _greetingTimer?.cancel();
    super.dispose();
  }

  Future<void> _handleRefresh() async {
    setState(() => _isRefreshing = true);
    await FirebaseFirestore.instance
        .collection('events')
        .where('approved', isEqualTo: true)
        .orderBy('startingTime')
        .limit(1)
        .get();
    if (mounted) {
      setState(() => _isRefreshing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final User? currentUser = FirebaseAuth.instance.currentUser;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;

    final backgroundColor = isDarkMode ? const Color(0xFF0D0E11) : const Color(0xFFF8F9FA);
    final headingColor = isDarkMode ? Colors.white : const Color(0xFF1A1D24);
    final subtitleColor = isDarkMode ? const Color(0xFF6C727F) : const Color(0xFF8A92A6);
    final cardBgColor = isDarkMode ? const Color(0xFF16181D) : Colors.white;
    final accentColor = isDarkMode ? Colors.white : const Color(0xFF1A1D24);

    if (currentUser == null) {
      return Scaffold(
        backgroundColor: backgroundColor,
        body: Center(
          child: Text('User not logged in.', style: TextStyle(color: subtitleColor)),
        ),
      );
    }

    final displayName = currentUser.displayName ?? 'Explorer';

    return RefreshIndicator(
      onRefresh: _handleRefresh,
      color: isDarkMode ? Colors.white : Colors.black,
      backgroundColor: backgroundColor,
      displacement: 40,
      child: SafeArea(
        bottom: false,
        child: CustomScrollView(
          controller: _scrollController,
          physics: const BouncingScrollPhysics(),
          slivers: [
            // ===== FIXED HEADER =====
            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top Nav Bar
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        SvgPicture.asset(
                          'assets/images/logo.svg',
                          height: 28,
                          colorFilter: ColorFilter.mode(accentColor, BlendMode.srcIn),
                        ),
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const ProfileScreen()),
                            );
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: accentColor.withValues(alpha: 0.15), width: 2),
                            ),
                            child: CircleAvatar(
                              radius: 20,
                              backgroundColor: cardBgColor,
                              backgroundImage: currentUser.photoURL != null
                                  ? NetworkImage(currentUser.photoURL!)
                                  : null,
                              child: currentUser.photoURL == null
                                  ? Text(
                                      displayName.substring(0, 1).toUpperCase(),
                                      style: TextStyle(
                                        color: headingColor,
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    )
                                  : null,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Greeting
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _greeting,
                          style: TextStyle(color: subtitleColor, fontSize: 14),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          displayName,
                          style: TextStyle(
                            color: headingColor,
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          currentUser.email ?? '',
                          style: TextStyle(color: subtitleColor, fontSize: 13),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Search Bar
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: SearchTextField(),
                  ),

                  const SizedBox(height: 20),

                  // Category Pills
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: _categories.map((cat) {
                        final isSelected = _selectedCategory == cat['label'];
                        return Padding(
                          padding: const EdgeInsets.only(right: 10),
                          child: ChoiceChip(
                            showCheckmark: false,
                            avatar: Icon(
                              cat['icon'] as IconData,
                              size: 16,
                              color: isSelected
                                  ? (isDarkMode ? Colors.black : Colors.white)
                                  : subtitleColor,
                            ),
                            label: Text(cat['label'] as String),
                            selected: isSelected,
                            onSelected: (selected) {
                              setState(() {
                                _selectedCategory = cat['label'] as String;
                              });
                            },
                            labelStyle: TextStyle(
                              color: isSelected
                                  ? (isDarkMode ? Colors.black : Colors.white)
                                  : headingColor,
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                              fontSize: 13,
                            ),
                            selectedColor: headingColor,
                            backgroundColor: cardBgColor,
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                              side: BorderSide(
                                color: isSelected
                                    ? Colors.transparent
                                    : accentColor.withValues(alpha: 0.08),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),

                  const SizedBox(height: 28),
                ],
              ),
            ),

            // ===== SCROLLABLE EVENTS SECTION =====
            SliverToBoxAdapter(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('events')
                    .where('approved', isEqualTo: true)
                    .orderBy('startingTime')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return _buildErrorState(subtitleColor);
                  }

                  if (snapshot.connectionState == ConnectionState.waiting && !_isRefreshing) {
                    return _buildLoadingState(headingColor, subtitleColor);
                  }

                  final allEvents = snapshot.data?.docs ?? [];

                  final filteredEvents = _selectedCategory == 'All'
                      ? allEvents
                      : allEvents.where((doc) {
                          final data = doc.data() as Map<String, dynamic>?;
                          return data != null && data['category'] == _selectedCategory;
                        }).toList();

                  final featuredEvents = filteredEvents.take(4).toList();
                  final weekendEvents = filteredEvents.where((doc) {
                    final data = doc.data() as Map<String, dynamic>?;
                    if (data == null || !data.containsKey('startingTime')) return false;
                    final date = (data['startingTime'] as Timestamp).toDate();
                    return date.weekday == DateTime.friday ||
                        date.weekday == DateTime.saturday ||
                        date.weekday == DateTime.sunday;
                  }).take(4).toList();

                  final exploreMoreEvents = filteredEvents.skip(4).toList();

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ===== FEATURED: Large Horizontal Cards =====
                      if (featuredEvents.isNotEmpty) ...[
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "Featured Events",
                                style: TextStyle(
                                  color: headingColor,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: -0.4,
                                ),
                              ),
                              TextButton(
                                onPressed: () {},
                                child: Text(
                                  "See All",
                                  style: TextStyle(
                                    color: accentColor,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          height: 300,
                          child: ListView.builder(
                            controller: _carouselController,
                            scrollDirection: Axis.horizontal,
                            physics: const BouncingScrollPhysics(),
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            itemCount: featuredEvents.length,
                            itemBuilder: (context, index) {
                              return Padding(
                                padding: EdgeInsets.only(
                                  right: index == featuredEvents.length - 1 ? 20 : 14,
                                ),
                                child: SizedBox(
                                  width: screenWidth * 0.72,
                                  child: _FeaturedCard(
                                    event: featuredEvents[index],
                                    currentUserId: currentUser.uid,
                                    isDarkMode: isDarkMode,
                                    accentColor: accentColor,
                                    cardBgColor: cardBgColor,
                                    headingColor: headingColor,
                                    subtitleColor: subtitleColor,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 32),
                      ],

                      // ===== WEEKEND: Grid of Compact Cards =====
                      if (weekendEvents.isNotEmpty) ...[
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20.0),
                          child: Text(
                            "Happening This Weekend",
                            style: TextStyle(
                              color: headingColor,
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.4,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                              childAspectRatio: 0.85,
                            ),
                            itemCount: weekendEvents.length,
                            itemBuilder: (context, index) {
                              return _WeekendCard(
                                event: weekendEvents[index],
                                currentUserId: currentUser.uid,
                                isDarkMode: isDarkMode,
                                cardBgColor: cardBgColor,
                                headingColor: headingColor,
                                subtitleColor: subtitleColor,
                                accentColor: accentColor,
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 32),
                      ],

                      // ===== DISCOVER MORE: Clean Vertical List =====
                      if (exploreMoreEvents.isNotEmpty) ...[
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20.0),
                          child: Text(
                            "Discover More",
                            style: TextStyle(
                              color: headingColor,
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.4,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: exploreMoreEvents.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              return _CompactEventCard(
                                event: exploreMoreEvents[index],
                                currentUserId: currentUser.uid,
                                isDarkMode: isDarkMode,
                                cardBgColor: cardBgColor,
                                headingColor: headingColor,
                                subtitleColor: subtitleColor,
                                accentColor: accentColor,
                              );
                            },
                          ),
                        ),
                      ],

                      const SizedBox(height: 100),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(Color textColor) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 48, color: Colors.redAccent),
          const SizedBox(height: 16),
          Text('Error loading events', style: TextStyle(color: textColor)),
        ],
      ),
    );
  }

  Widget _buildLoadingState(Color headingColor, Color subtitleColor) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(headingColor)),
          const SizedBox(height: 16),
          Text('Loading events...', style: TextStyle(color: subtitleColor)),
        ],
      ),
    );
  }
}

// ===== FEATURED CARD — Large horizontal card =====
class _FeaturedCard extends StatelessWidget {
  final DocumentSnapshot event;
  final String currentUserId;
  final bool isDarkMode;
  final Color accentColor;
  final Color cardBgColor;
  final Color headingColor;
  final Color subtitleColor;

  const _FeaturedCard({
    required this.event,
    required this.currentUserId,
    required this.isDarkMode,
    required this.accentColor,
    required this.cardBgColor,
    required this.headingColor,
    required this.subtitleColor,
  });

  DateTime? _parseDate(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final data = event.data() as Map<String, dynamic>? ?? {};
    final startTime = _parseDate(data['startingTime']);
    final imageUrl = data['imageUrl'] ?? '';
    final title = data['title'] ?? 'Untitled Event';
    final location = data['location'] ?? 'Location TBA';
    final category = data['category'] ?? 'Featured';

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
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: isDarkMode ? Colors.black.withValues(alpha: 0.3) : Colors.black.withValues(alpha: 0.08),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image
              Expanded(
                flex: 3,
                child: Stack(
                  children: [
                    imageUrl.isNotEmpty
                        ? Image.network(
                            imageUrl,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            errorBuilder: (_, __, ___) => Container(
                              color: isDarkMode ? const Color(0xFF232732) : const Color(0xFFE9ECEF),
                              child: const Icon(Icons.image_not_supported, size: 40),
                            ),
                          )
                        : Container(
                            color: isDarkMode ? const Color(0xFF232732) : const Color(0xFFE9ECEF),
                            child: const Icon(Icons.event_available_rounded, size: 40),
                          ),
                    // Category badge
                    Positioned(
                      top: 12,
                      left: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: isDarkMode ? Colors.black.withValues(alpha: 0.6) : Colors.white.withValues(alpha: 0.9),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          category.toUpperCase(),
                          style: TextStyle(
                            color: isDarkMode ? Colors.white : headingColor,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),
                    // Date badge
                    Positioned(
                      top: 12,
                      right: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: isDarkMode ? Colors.black.withValues(alpha: 0.6) : Colors.white.withValues(alpha: 0.9),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (startTime != null)
                              Text(
                                '${startTime.day}',
                                style: const TextStyle(
                                  color: Colors.black,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            if (startTime != null)
                              Text(
                                _monthAbbr(startTime.month),
                                style: TextStyle(
                                  color: subtitleColor,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Info
              Expanded(
                flex: 2,
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: headingColor,
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(Icons.location_on, size: 13, color: subtitleColor),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  location,
                                  style: TextStyle(color: subtitleColor, fontSize: 12),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      // Love count
                      Row(
                        children: [
                          Icon(Icons.favorite, size: 14, color: Colors.redAccent),
                          const SizedBox(width: 4),
                          Text(
                            '${data['reactCount'] ?? 0} people love this',
                            style: TextStyle(color: subtitleColor, fontSize: 11),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _monthAbbr(int m) {
    const months = ['JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN', 'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC'];
    return months[m - 1];
  }
}

// ===== WEEKEND CARD — Compact square-ish card =====
class _WeekendCard extends StatelessWidget {
  final DocumentSnapshot event;
  final String currentUserId;
  final bool isDarkMode;
  final Color cardBgColor;
  final Color headingColor;
  final Color subtitleColor;
  final Color accentColor;

  const _WeekendCard({
    required this.event,
    required this.currentUserId,
    required this.isDarkMode,
    required this.cardBgColor,
    required this.headingColor,
    required this.subtitleColor,
    required this.accentColor,
  });

  DateTime? _parseDate(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final data = event.data() as Map<String, dynamic>? ?? {};
    final startTime = _parseDate(data['startingTime']);
    final imageUrl = data['imageUrl'] ?? '';
    final title = data['title'] ?? 'Untitled Event';
    final location = data['location'] ?? 'TBA';
    final category = data['category'] ?? 'Event';

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
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: isDarkMode ? Colors.black.withValues(alpha: 0.25) : Colors.black.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image
              AspectRatio(
                aspectRatio: 1,
                child: Stack(
                  children: [
                    imageUrl.isNotEmpty
                        ? Image.network(imageUrl, fit: BoxFit.cover, width: double.infinity)
                        : Container(
                            color: isDarkMode ? const Color(0xFF232732) : const Color(0xFFE9ECEF),
                            child: const Icon(Icons.event_available_rounded, size: 32),
                          ),
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: isDarkMode ? Colors.black.withValues(alpha: 0.6) : Colors.white.withValues(alpha: 0.9),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          category.toUpperCase(),
                          style: TextStyle(
                            color: isDarkMode ? Colors.white : headingColor,
                            fontSize: 8,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Info
              Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: headingColor,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (startTime != null)
                      Row(
                        children: [
                          Icon(Icons.access_time, size: 11, color: subtitleColor),
                          const SizedBox(width: 3),
                          Text(
                            '${startTime.day} ${_monthAbbr(startTime.month)}',
                            style: TextStyle(color: subtitleColor, fontSize: 10),
                          ),
                        ],
                      ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(Icons.location_on, size: 11, color: subtitleColor),
                        const SizedBox(width: 3),
                        Expanded(
                          child: Text(
                            location,
                            style: TextStyle(color: subtitleColor, fontSize: 10),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
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

  String _monthAbbr(int m) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[m - 1];
  }
}

// ===== COMPACT VERTICAL CARD — Simple list card =====
class _CompactEventCard extends StatelessWidget {
  final DocumentSnapshot event;
  final String currentUserId;
  final bool isDarkMode;
  final Color cardBgColor;
  final Color headingColor;
  final Color subtitleColor;
  final Color accentColor;

  const _CompactEventCard({
    required this.event,
    required this.currentUserId,
    required this.isDarkMode,
    required this.cardBgColor,
    required this.headingColor,
    required this.subtitleColor,
    required this.accentColor,
  });

  DateTime? _parseDate(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final data = event.data() as Map<String, dynamic>? ?? {};
    final startTime = _parseDate(data['startingTime']);

    final imageUrl = data['imageUrl'] ?? '';
    final title = data['title'] ?? 'Untitled Event';
    final location = data['location'] ?? 'TBA';

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
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: isDarkMode ? Colors.black.withValues(alpha: 0.25) : Colors.black.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Thumbnail
            ClipRRect(
              borderRadius: const BorderRadius.horizontal(left: Radius.circular(16)),
              child: imageUrl.isNotEmpty
                  ? Image.network(
                      imageUrl,
                      width: 100,
                      height: 90,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        width: 100,
                        height: 90,
                        color: isDarkMode ? const Color(0xFF232732) : const Color(0xFFE9ECEF),
                        child: const Icon(Icons.image_not_supported),
                      ),
                    )
                  : Container(
                      width: 100,
                      height: 90,
                      color: isDarkMode ? const Color(0xFF232732) : const Color(0xFFE9ECEF),
                      child: const Icon(Icons.event_available_rounded),
                    ),
            ),
            // Info
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: headingColor,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(Icons.calendar_today, size: 12, color: subtitleColor),
                        const SizedBox(width: 4),
                        if (startTime != null)
                          Text(
                            '${startTime.day} ${_monthAbbr(startTime.month)}',
                            style: TextStyle(color: subtitleColor, fontSize: 11),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.location_on, size: 12, color: subtitleColor),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            location,
                            style: TextStyle(color: subtitleColor, fontSize: 11),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
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
}

// We need to import EventDetailsScreen — it's in the parent directory
