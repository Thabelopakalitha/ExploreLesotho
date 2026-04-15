// lib/screens/home/tourist_dashboard.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/themes/color_palette.dart';
import '../../providers/auth_provider.dart';
import '../../providers/booking_provider.dart';
import '../../providers/culture_provider.dart';
import '../../providers/listing_provider.dart';
import '../../providers/locale_provider.dart';
import '../../providers/notification_provider.dart';
import '../../providers/test_chat_provider.dart';
import '../../utils/responsive_layout.dart';
import '../../widgets/culture_vendor_card.dart';
import '../../widgets/listing_card.dart';
import '../../widgets/mountain_background.dart';
import '../../widgets/offline_indicator.dart';
import '../../widgets/upcoming_events_widget.dart';
import '../auth/login_screen.dart';
import '../bookings/my_bookings_screen.dart';
import '../chat/chat_list_screen.dart';
import '../events/events_screen.dart';
import '../notifications/wishlist_notifications_screen.dart';
import 'culture_vendor_detail_screen.dart';
import 'listing_detail_screen.dart';
import 'wishlist_screen.dart';

class TouristDashboard extends StatefulWidget {
  const TouristDashboard({super.key});

  @override
  State<TouristDashboard> createState() => _TouristDashboardState();
}

class _TouristDashboardState extends State<TouristDashboard> {
  int _selectedIndex = 0;
  final TextEditingController _searchController = TextEditingController();

  final List<String> _categories = [
    'All',
    'Accommodation',
    'Tour',
    'Experience',
    'Culture',
    'Adventure',
  ];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ListingProvider>(context, listen: false).loadListings();
      Provider.of<CultureProvider>(context, listen: false).loadInitial();
      Provider.of<BookingProvider>(context, listen: false).refresh();
      Provider.of<TestChatProvider>(context, listen: false).loadConversations();
    });
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final listingProvider =
        Provider.of<ListingProvider>(context, listen: false);
    final cultureProvider =
        Provider.of<CultureProvider>(context, listen: false);
    listingProvider.search(_searchController.text);
    if (listingProvider.selectedCategory == 'Culture') {
      cultureProvider.loadVendors(search: _searchController.text);
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    switch (index) {
      case 1:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const WishlistScreen()),
        ).then((_) => setState(() => _selectedIndex = 0));
        break;
      case 2:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const MyBookingsScreen(),
          ),
        );
        break;
      case 3:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const TouristEventsScreen(),
          ),
        );
        break;
      case 4:
        _showAccountSheet();
        break;
    }
  }

  void _showAccountSheet() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final locale = Provider.of<LocaleProvider>(context, listen: false);

    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: CircleAvatar(
                    backgroundColor: ColorPalette.primaryGreen,
                    child: Text(
                      _getUserInitial(authProvider.user?.name),
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  title: Text(authProvider.user?.name ?? 'User'),
                  subtitle: Text(authProvider.user?.email ?? ''),
                ),
                ListTile(
                  leading: const Icon(Icons.book_online_outlined),
                  title: Text(
                      locale.translate('My Bookings', 'Lipeheletso Tsa Ka')),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      this.context,
                      MaterialPageRoute(
                          builder: (_) => const MyBookingsScreen()),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.language),
                  title:
                      Text(locale.translate('Change Language', 'Fetola Puo')),
                  onTap: () {
                    Navigator.pop(context);
                    showDialog(
                      context: this.context,
                      builder: (_) => AlertDialog(
                        title: Text(
                            locale.translate('Select Language', 'Khetha Puo')),
                        content: Consumer<LocaleProvider>(
                          builder: (_, localeProvider, __) {
                            final isEnglish =
                                localeProvider.locale.languageCode == 'en';
                            return Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                ListTile(
                                  title: const Text('English'),
                                  trailing: isEnglish
                                      ? const Icon(Icons.check,
                                          color: Colors.green)
                                      : null,
                                  onTap: () async {
                                    await localeProvider.setLocale('en');
                                    if (mounted) Navigator.pop(this.context);
                                  },
                                ),
                                ListTile(
                                  title: const Text('Sesotho'),
                                  trailing: !isEnglish
                                      ? const Icon(Icons.check,
                                          color: Colors.green)
                                      : null,
                                  onTap: () async {
                                    await localeProvider.setLocale('st');
                                    if (mounted) Navigator.pop(this.context);
                                  },
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.logout, color: Colors.red),
                  title: Text(locale.translate('Logout', 'Tswa')),
                  onTap: () async {
                    Navigator.pop(context);
                    await authProvider.logout();
                    if (!mounted) return;
                    Navigator.pushAndRemoveUntil(
                      this.context,
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                      (route) => false,
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _getUserInitial(String? name) {
    final trimmed = name?.trim() ?? '';
    if (trimmed.isEmpty) return 'U';
    return trimmed[0].toUpperCase();
  }

  String _getTranslatedCategory(String category, LocaleProvider locale) {
    final translations = {
      'All': ('All', 'Kakaretso'),
      'Accommodation': ('Accommodation', 'Libaka Tsa Boroko'),
      'Tour': ('Tour', 'Tsa Bohahlauli'),
      'Experience': ('Experience', 'Litsebo'),
      'Culture': ('Culture', 'Setso'),
      'Adventure': ('Adventure', 'Boiketlo'),
    };

    final pair = translations[category] ?? (category, category);
    return locale.translate(pair.$1, pair.$2);
  }

  String _getTranslatedCultureType(String type, LocaleProvider locale) {
    const translations = {
      'All': ('All Types', 'Mefuta Eohle'),
      'Crafts': ('Crafts', 'Mesebetsi ea Matsoho'),
      'Music': ('Music', 'Mmino'),
      'Dance': ('Dance', 'Motjeko'),
      'Art': ('Art', 'Bonono'),
      'Food Heritage': ('Food Heritage', 'Lefa la Lijo'),
      'Storytelling': ('Storytelling', 'Pale tsa Setso'),
      'History': ('History', 'Nalane'),
      'Traditional Wear': ('Traditional Wear', 'Liaparo tsa Setso'),
      'Architecture': ('Architecture', 'Meaho ea Setso'),
      'Spiritual Heritage': ('Spiritual Heritage', 'Lefa la Moea'),
      'Festival': ('Festival', 'Mokete'),
    };
    final pair = translations[type] ?? (type, type);
    return locale.translate(pair.$1, pair.$2);
  }

  IconData _cultureTypeIcon(String type) {
    switch (type) {
      case 'Crafts':
        return Icons.handyman;
      case 'Music':
        return Icons.music_note;
      case 'Dance':
        return Icons.nightlife;
      case 'Art':
        return Icons.palette;
      case 'Food Heritage':
        return Icons.restaurant;
      case 'Storytelling':
        return Icons.menu_book;
      case 'History':
        return Icons.history_edu;
      case 'Traditional Wear':
        return Icons.checkroom;
      case 'Architecture':
        return Icons.architecture;
      case 'Spiritual Heritage':
        return Icons.temple_buddhist;
      case 'Festival':
        return Icons.celebration;
      default:
        return Icons.category;
    }
  }

  Color _cultureTypeColor(String type) {
    switch (type) {
      case 'Crafts':
        return Colors.brown;
      case 'Music':
        return Colors.deepPurple;
      case 'Dance':
        return Colors.pink;
      case 'Art':
        return Colors.indigo;
      case 'Food Heritage':
        return Colors.deepOrange;
      case 'Storytelling':
        return Colors.blueGrey;
      case 'History':
        return Colors.teal;
      case 'Traditional Wear':
        return Colors.cyan;
      case 'Architecture':
        return Colors.blue;
      case 'Spiritual Heritage':
        return Colors.green;
      case 'Festival':
        return Colors.orange;
      default:
        return ColorPalette.darkGreen;
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final listingProvider = Provider.of<ListingProvider>(context);
    final cultureProvider = Provider.of<CultureProvider>(context);
    final bookingProvider = Provider.of<BookingProvider>(context);
    final notificationProvider = Provider.of<NotificationProvider>(context);
    final locale = Provider.of<LocaleProvider>(context);

    TestChatProvider? chatProvider;
    try {
      chatProvider = Provider.of<TestChatProvider>(context, listen: false);
    } catch (_) {
      chatProvider = null;
    }

    final isMobile = ResponsiveLayout.isMobile(context);
    final fontSize = ResponsiveLayout.getFontSize(context);
    final padding = ResponsiveLayout.getPadding(context);
    final gridCrossAxisCount = ResponsiveLayout.getGridCrossAxisCount(context);
    final isOverview = listingProvider.selectedCategory == 'All';
    final isCultureView = listingProvider.selectedCategory == 'Culture';
    final activeResultCount = isCultureView
        ? cultureProvider.vendors.length
        : listingProvider.listings.length;
    final activeError =
        isCultureView ? cultureProvider.error : listingProvider.error;
    final activeLoading =
        isCultureView ? cultureProvider.isLoading : listingProvider.isLoading;

    return MountainBackground(
      overlayOpacity: 0.08,
      child: Scaffold(
        body: SafeArea(
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Column(
                  children: [
                    const OfflineIndicator(),
                    _buildHeader(
                      context: context,
                      authProvider: authProvider,
                      bookingProvider: bookingProvider,
                      listingProvider: listingProvider,
                      notificationProvider: notificationProvider,
                      locale: locale,
                      chatProvider: chatProvider,
                      isMobile: isMobile,
                      fontSize: fontSize,
                      padding: padding,
                    ),
                    Padding(
                      padding: padding.copyWith(top: 0, bottom: 12),
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: locale.translate(
                            'Search destinations...',
                            'Batla mehloli...',
                          ),
                          prefixIcon: Icon(
                            Icons.search,
                            size: ResponsiveLayout.getIconSize(context),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: Colors.white.withValues(alpha: 0.9),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: isMobile ? 12 : 16,
                          ),
                          suffixIcon: _searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear),
                                  onPressed: () {
                                    _searchController.clear();
                                  },
                                )
                              : null,
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(
                              color: Colors.grey[300] ?? Colors.grey,
                              width: 1,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: const BorderSide(
                              color: ColorPalette.primaryGreen,
                              width: 2,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: padding.copyWith(top: 0, bottom: 12),
                      child: _buildDiscoverHero(
                        locale: locale,
                        isOverview: isOverview,
                        listingCount: activeResultCount,
                        fontSize: fontSize,
                      ),
                    ),
                    Padding(
                      padding: padding.copyWith(top: 0, bottom: 10),
                      child: _buildSectionHeading(
                        title: isOverview
                            ? locale.translate(
                                'Browse by Category', 'Batla ka Sehlopha')
                            : _getTranslatedCategory(
                                listingProvider.selectedCategory,
                                locale,
                              ),
                        subtitle: isOverview
                            ? locale.translate(
                                'Pick the kind of experience you want today.',
                                'Khetha mofuta oa boiphihlelo boo u bo batlang kajeno.',
                              )
                            : locale.translate(
                                'Showing places matched to your selected category.',
                                'Ho bonts\'a libaka tse tsamaellanang le sehlopha seo u se khethileng.',
                              ),
                      ),
                    ),
                    SizedBox(
                      height: isMobile ? 48 : 56,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: padding.copyWith(top: 0, bottom: 0),
                        itemCount: _categories.length,
                        itemBuilder: (context, index) {
                          final category = _categories[index];
                          final isSelected =
                              listingProvider.selectedCategory == category;

                          return Padding(
                            padding: const EdgeInsets.only(right: 12),
                            child: FilterChip(
                              label: Text(
                                _getTranslatedCategory(category, locale),
                                style: TextStyle(
                                  fontSize: isMobile ? 13 : 15,
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.w500,
                                ),
                              ),
                              selected: isSelected,
                              onSelected: (_) {
                                listingProvider.filterByCategory(category);
                                if (category == 'Culture') {
                                  cultureProvider.loadInitial();
                                }
                              },
                              backgroundColor:
                                  Colors.white.withValues(alpha: 0.7),
                              selectedColor: ColorPalette.primaryGreen,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                                side: BorderSide(
                                  color: isSelected
                                      ? ColorPalette.primaryGreen
                                      : Colors.grey[300] ?? Colors.grey,
                                  width: 1.5,
                                ),
                              ),
                              labelStyle: TextStyle(
                                color:
                                    isSelected ? Colors.white : Colors.black87,
                              ),
                              padding: EdgeInsets.symmetric(
                                horizontal: isMobile ? 12 : 16,
                                vertical: isMobile ? 8 : 10,
                              ),
                              elevation: isSelected ? 4 : 1,
                              shadowColor: ColorPalette.primaryGreen
                                  .withValues(alpha: 0.3),
                            ),
                          );
                        },
                      ),
                    ),
                    if (isCultureView)
                      Padding(
                        padding: padding.copyWith(top: 8, bottom: 6),
                        child: SizedBox(
                          height: 44,
                          child: ListView(
                            scrollDirection: Axis.horizontal,
                            children: [
                              ...[
                                const {'name': 'All Types', 'slug': 'all'},
                                ...cultureProvider.subcategories
                                    .map((subcategory) => {
                                          'name': subcategory.name,
                                          'slug': subcategory.slug,
                                        }),
                              ].map((item) {
                                final type = item['name']!;
                                final slug = item['slug']!;
                                final selected =
                                    cultureProvider.selectedSubcategorySlug ==
                                        slug;
                                return Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: ChoiceChip(
                                    label: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          _cultureTypeIcon(type),
                                          size: 15,
                                          color: selected
                                              ? Colors.white
                                              : _cultureTypeColor(type),
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          _getTranslatedCultureType(
                                              type, locale),
                                          style: TextStyle(
                                            color: selected
                                                ? Colors.white
                                                : _cultureTypeColor(type),
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                    selected: selected,
                                    onSelected: (_) {
                                      cultureProvider.selectSubcategory(slug);
                                    },
                                    selectedColor: _cultureTypeColor(type),
                                    backgroundColor:
                                        _cultureTypeColor(type).withValues(
                                      alpha: 0.12,
                                    ),
                                    side: BorderSide(
                                      color: _cultureTypeColor(type)
                                          .withValues(alpha: 0.35),
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(18),
                                    ),
                                  ),
                                );
                              }),
                            ],
                          ),
                        ),
                      ),
                    if (isOverview) ...[
                      const SizedBox(height: 12),
                      const UpcomingEventsWidget(),
                      const SizedBox(height: 16),
                    ],
                    Padding(
                      padding: padding.copyWith(top: 0, bottom: 12),
                      child: _buildResultsHeader(
                        context: context,
                        locale: locale,
                        listingProvider: listingProvider,
                        cultureProvider: cultureProvider,
                        fontSize: fontSize,
                      ),
                    ),
                    if (activeError != null)
                      Padding(
                        padding: padding.copyWith(top: 0, bottom: 12),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: ColorPalette.warningYellow
                                .withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: ColorPalette.warningYellow
                                  .withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(
                                Icons.wifi_off_rounded,
                                color: ColorPalette.darkGreen,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      locale.translate(
                                        'Live listings could not be loaded',
                                        'Lintlha tse phelang ha lia khonahala ho laeloa',
                                      ),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: ColorPalette.textPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      activeError,
                                      style: TextStyle(
                                        color: Colors.grey[700],
                                        fontSize: fontSize - 3,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              if (activeLoading)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (activeResultCount == 0)
                SliverFillRemaining(
                  hasScrollBody: true,
                  child: SingleChildScrollView(
                    padding: padding,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: MediaQuery.of(context).size.height * 0.48,
                      ),
                      child: _buildEmptyState(
                        context: context,
                        locale: locale,
                        listingProvider: listingProvider,
                        cultureProvider: cultureProvider,
                        fontSize: fontSize,
                      ),
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: padding,
                  sliver: SliverGrid(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: gridCrossAxisCount,
                      childAspectRatio: isMobile ? 0.7 : 0.8,
                      crossAxisSpacing: isMobile ? 8 : 12,
                      mainAxisSpacing: isMobile ? 8 : 12,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        if (isCultureView) {
                          final vendor = cultureProvider.vendors[index];
                          return CultureVendorCard(
                            vendor: vendor,
                            onTap: () {
                              if (vendor.linkedListingId != null &&
                                  vendor.linkedListingId!.isNotEmpty) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => ListingDetailScreen(
                                      listingId: vendor.linkedListingId!,
                                    ),
                                  ),
                                );
                                return;
                              }

                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      CultureVendorDetailScreen(vendor: vendor),
                                ),
                              );
                            },
                          );
                        }

                        final listing = listingProvider.listings[index];
                        return ListingCard(
                          listing: listing,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ListingDetailScreen(
                                  listingId: listing.id.toString(),
                                ),
                              ),
                            );
                          },
                        );
                      },
                      childCount: isCultureView
                          ? cultureProvider.vendors.length
                          : listingProvider.listings.length,
                    ),
                  ),
                ),
            ],
          ),
        ),
        bottomNavigationBar: isMobile
            ? BottomNavigationBar(
                type: BottomNavigationBarType.fixed,
                currentIndex: _selectedIndex,
                onTap: _onItemTapped,
                items: const [
                  BottomNavigationBarItem(
                    icon: Icon(Icons.home),
                    label: 'Home',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.favorite),
                    label: 'Wishlist',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.book_online),
                    label: 'Bookings',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.event),
                    label: 'Events',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.person),
                    label: 'Profile',
                  ),
                ],
              )
            : null,
      ),
    );
  }

  Widget _buildDiscoverHero({
    required LocaleProvider locale,
    required bool isOverview,
    required int listingCount,
    required double fontSize,
  }) {
    final title = isOverview
        ? locale.translate(
            'Discover Lesotho Better', 'Fumana Lesotho ka Botle bo Fetang')
        : locale.translate('Filtered Discovery', 'Patlo e Hloekisitsoeng');
    final subtitle = isOverview
        ? locale.translate(
            'Curated places, real events, and trusted local experiences.',
            'Libaka tse hlophisitsoeng, liketsahalo tsa nnete, le maeto a tshepahalang.',
          )
        : locale.translate(
            'You are now exploring a focused category view.',
            'U se u shebile pono e shebaneng le sehlopha se le seng.',
          );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: 0.95),
            ColorPalette.lightGreen.withValues(alpha: 0.88),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.65),
        ),
        boxShadow: [
          BoxShadow(
            color: ColorPalette.darkGreen.withValues(alpha: 0.08),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: fontSize + 3,
                    fontWeight: FontWeight.w800,
                    color: ColorPalette.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: fontSize - 2,
                    color: ColorPalette.textSecondary,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: ColorPalette.darkGreen,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '$listingCount',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  locale.translate('Live', 'Phela'),
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeading({
    required String title,
    required String subtitle,
  }) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 40,
          decoration: BoxDecoration(
            color: ColorPalette.primaryGreen,
            borderRadius: BorderRadius.circular(99),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  shadows: [
                    Shadow(
                      color: Colors.black54,
                      blurRadius: 6,
                      offset: Offset(0, 1),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.white70,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildResultsHeader({
    required BuildContext context,
    required LocaleProvider locale,
    required ListingProvider listingProvider,
    required CultureProvider cultureProvider,
    required double fontSize,
  }) {
    final activeCategory = listingProvider.selectedCategory;
    String? selectedCulture;
    if (cultureProvider.selectedSubcategorySlug != 'all') {
      for (final subcategory in cultureProvider.subcategories) {
        if (subcategory.slug == cultureProvider.selectedSubcategorySlug) {
          selectedCulture = subcategory.name;
          break;
        }
      }
    }

    final cultureSuffix =
        (activeCategory == 'Culture' && selectedCulture != null)
            ? ' • $selectedCulture'
            : '';
    final resultsCount = activeCategory == 'Culture'
        ? cultureProvider.vendors.length
        : listingProvider.listings.length;
    final categoryLabel = (activeCategory == 'All'
            ? locale.translate('Overview', 'Kakaretso')
            : _getTranslatedCategory(activeCategory, locale)) +
        cultureSuffix;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.88),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: ColorPalette.primaryGreen.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.place_rounded,
                    color: ColorPalette.primaryGreen,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$resultsCount ${locale.translate('places found', 'libaka tse fumane')}',
                        style: TextStyle(
                          fontSize: fontSize,
                          color: ColorPalette.textPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        categoryLabel,
                        style: const TextStyle(
                          color: ColorPalette.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.84),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.5),
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.tune_rounded,
                size: ResponsiveLayout.getIconSize(context) - 2,
                color: ColorPalette.darkGreen,
              ),
              const SizedBox(width: 6),
              Text(
                locale.translate('Filtered', 'E Hloekisitsoe'),
                style: TextStyle(
                  fontSize: fontSize - 2,
                  color: ColorPalette.darkGreen,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState({
    required BuildContext context,
    required LocaleProvider locale,
    required ListingProvider listingProvider,
    required CultureProvider cultureProvider,
    required double fontSize,
  }) {
    final hasQuery = _searchController.text.trim().isNotEmpty;
    final hasCategory = listingProvider.selectedCategory != 'All';
    final isCulture = listingProvider.selectedCategory == 'Culture';

    final title = isCulture
        ? locale.translate(
            'No culture vendors match this filter',
            'Ha ho barekisi ba setso ba tsamaellanang le sefefo sena',
          )
        : hasQuery || hasCategory
            ? locale.translate(
                'No places match this filter',
                'Ha ho libaka tse tsamaellanang le patlo ena',
              )
            : locale.translate(
                'No live listings yet',
                'Ha ho lintlha tse phelang hajoale',
              );

    final subtitle = isCulture
        ? locale.translate(
            'Try another culture subtype or search term to discover more vendors.',
            'Leka mofuta o mong oa setso kapa lentsoe le leng la patlo ho fumana barekisi ba bang.',
          )
        : hasQuery || hasCategory
            ? locale.translate(
                'Try another category or clear your search to see more results.',
                'Leka sehlopha se seng kapa u hlakole patlo ho bona tse ling.',
              )
            : locale.translate(
                'Listings from registered users will appear here once they are available.',
                'Lintlha tse tsoang ho basebelisi ba ngolisitsoeng li tla hlaha mona ha li se li fumaneha.',
              );

    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 480),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.92),
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 22,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 78,
              height: 78,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    ColorPalette.lightGreen,
                    ColorPalette.primaryLight.withValues(alpha: 0.6),
                  ],
                ),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.travel_explore_rounded,
                size: 36,
                color: ColorPalette.darkGreen,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: fontSize + 3,
                fontWeight: FontWeight.w800,
                color: ColorPalette.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: fontSize - 2,
                color: ColorPalette.textSecondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 20),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              alignment: WrapAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: () {
                    _searchController.clear();
                    listingProvider.filterByCategory('All');
                    listingProvider.search('');
                    cultureProvider.selectSubcategory('all');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ColorPalette.primaryGreen,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 18, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  icon: const Icon(Icons.refresh_rounded),
                  label: Text(
                    locale.translate('Reset Filters', 'Hlophisa Botjha'),
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: () {
                    if (isCulture) {
                      cultureProvider.loadInitial();
                    } else {
                      listingProvider.loadListings();
                    }
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: ColorPalette.darkGreen,
                    side: BorderSide(
                      color: ColorPalette.primaryGreen.withValues(alpha: 0.3),
                    ),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 18, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  icon: const Icon(Icons.cloud_sync_rounded),
                  label: Text(locale.translate('Try Again', 'Leka Hape')),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader({
    required BuildContext context,
    required AuthProvider authProvider,
    required BookingProvider bookingProvider,
    required ListingProvider listingProvider,
    required NotificationProvider notificationProvider,
    required LocaleProvider locale,
    required TestChatProvider? chatProvider,
    required bool isMobile,
    required double fontSize,
    required EdgeInsets padding,
  }) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.black.withValues(alpha: 0.18),
            ColorPalette.darkGreen.withValues(alpha: 0.28),
          ],
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: isMobile ? 18 : 24,
            backgroundColor: ColorPalette.primaryGreen,
            child: Text(
              authProvider.user?.name[0] ?? 'U',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: isMobile ? 14 : 16,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome back,',
                  style: TextStyle(
                    fontSize: fontSize - 2,
                    color: Colors.white70,
                  ),
                ),
                Text(
                  authProvider.user?.name ?? 'Explorer',
                  style: TextStyle(
                    fontSize: fontSize,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_none, color: Colors.white),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.black.withValues(alpha: 0.22),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const WishlistNotificationsScreen(),
                    ),
                  );
                },
                tooltip: 'Notifications',
              ),
              if (notificationProvider.unreadCount > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      '${notificationProvider.unreadCount}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          Stack(
            children: [
              IconButton(
                icon:
                    const Icon(Icons.chat_bubble_outline, color: Colors.white),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.black.withValues(alpha: 0.22),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ChatListScreen(),
                    ),
                  );
                },
                tooltip: 'Messages',
              ),
              if (chatProvider != null && chatProvider.totalUnread > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      '${chatProvider.totalUnread}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            style: IconButton.styleFrom(
              backgroundColor: Colors.black.withValues(alpha: 0.22),
            ),
            onPressed: () {
              listingProvider.loadListings();
              bookingProvider.refresh();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    locale.translate('Data refreshed', 'Data e nchafatsoe'),
                  ),
                  duration: const Duration(seconds: 2),
                ),
              );
            },
            tooltip: locale.translate('Refresh', 'Nchafatsa'),
          ),
          IconButton(
            icon: const Icon(Icons.language, color: Colors.white),
            style: IconButton.styleFrom(
              backgroundColor: Colors.black.withValues(alpha: 0.22),
            ),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text(
                    locale.translate('Select Language', 'Khetha Puo'),
                  ),
                  content: Consumer<LocaleProvider>(
                    builder: (context, localeProvider, child) {
                      final isEnglish =
                          localeProvider.locale.languageCode == 'en';
                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ListTile(
                            title: const Text('English'),
                            trailing: isEnglish
                                ? const Icon(Icons.check, color: Colors.green)
                                : null,
                            onTap: () async {
                              await localeProvider.setLocale('en');
                              if (context.mounted) Navigator.pop(context);
                            },
                          ),
                          ListTile(
                            title: const Text('Sesotho'),
                            trailing: !isEnglish
                                ? const Icon(Icons.check, color: Colors.green)
                                : null,
                            onTap: () async {
                              await localeProvider.setLocale('st');
                              if (context.mounted) Navigator.pop(context);
                            },
                          ),
                        ],
                      );
                    },
                  ),
                ),
              );
            },
            tooltip: locale.translate('Change Language', 'Fetola Puo'),
          ),
          IconButton(
            icon: Icon(
              Icons.favorite_border,
              color: Colors.white,
              size: ResponsiveLayout.getIconSize(context),
            ),
            style: IconButton.styleFrom(
              backgroundColor: Colors.black.withValues(alpha: 0.22),
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const WishlistScreen(),
                ),
              );
            },
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onSelected: (value) {
              if (value == 'bookings') {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const MyBookingsScreen(),
                  ),
                );
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'bookings',
                child: Row(
                  children: [
                    Icon(Icons.book_online),
                    SizedBox(width: 8),
                    Text('My Bookings'),
                  ],
                ),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            style: IconButton.styleFrom(
              backgroundColor: Colors.black.withValues(alpha: 0.22),
            ),
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Logout'),
                  content: const Text('Are you sure you want to logout?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.red,
                      ),
                      child: const Text('Logout'),
                    ),
                  ],
                ),
              );

              if (confirm == true) {
                await authProvider.logout();
                if (context.mounted) {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const LoginScreen(),
                    ),
                    (route) => false,
                  );
                }
              }
            },
            tooltip: 'Logout',
          ),
        ],
      ),
    );
  }
}
