// lib/screens/vendor/vendor_dashboard.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:convert';
import '../../providers/locale_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/booking_provider.dart';
import '../../providers/listing_provider.dart';
import '../../providers/event_provider.dart';
import '../../core/themes/color_palette.dart';
import '../../services/api_service.dart';
import '../../widgets/social_media_buttons.dart';
import '../../widgets/mountain_background.dart';
import '../auth/login_screen.dart';
import '../chat/chat_list_screen.dart';
import 'vendor_listings_screen.dart';
import 'vendor_bookings_screen.dart';
import 'vendor_analytics_screen.dart';
import 'vendor_events_screen.dart';
import 'vendor_reviews_screen.dart';

class VendorDashboard extends StatefulWidget {
  const VendorDashboard({super.key});

  @override
  State<VendorDashboard> createState() => _VendorDashboardState();
}

class _VendorDashboardState extends State<VendorDashboard>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);

    // Load vendor events when dashboard loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final eventProvider = Provider.of<EventProvider>(context, listen: false);
      final vendorUserId = authProvider.user?.userId ?? authProvider.user?.id;
      if (vendorUserId != null && vendorUserId.isNotEmpty) {
        eventProvider.fetchMyEvents(vendorUserId);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final locale = Provider.of<LocaleProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final bookingProvider = Provider.of<BookingProvider>(context);
    final listingProvider = Provider.of<ListingProvider>(context);
    final eventProvider = Provider.of<EventProvider>(context);

    final vendorUserId =
        authProvider.user?.userId?.toString() ?? authProvider.user?.id;

    final vendorListings = listingProvider.allListings
        .where((l) => l.vendorId == vendorUserId)
        .toList();

    final vendorBookings = bookingProvider.userBookings;

    // Calculate stats
    final totalListings = vendorListings.length;
    final totalBookings = vendorBookings.length;
    final totalEvents = eventProvider.myEvents.length;
    final completedBookings =
        vendorBookings.where((b) => b.status == 'completed').length;
    final pendingBookings =
        vendorBookings.where((b) => b.status == 'pending').length;
    final totalRevenue = vendorBookings
        .where((b) => b.status == 'completed')
        .fold(0.0, (sum, b) => sum + b.grandTotal);
    final primaryListing =
        vendorListings.isNotEmpty ? vendorListings.first : null;

    return MountainBackground(
      overlayOpacity: 0.25,
      child: Scaffold(
        appBar: AppBar(
          title:
              Text(locale.translate('Vendor Dashboard', 'Letlapa la Morekisi')),
          backgroundColor: ColorPalette.primaryGreen,
          foregroundColor: Colors.white,
          actions: [
            IconButton(
              icon: const Icon(Icons.language),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Select Language / Khetha Puo'),
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
              tooltip: 'Change Language',
            ),
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () {
                listingProvider.loadListings();
                bookingProvider.refresh();
                final vendorUserId =
                    authProvider.user?.userId ?? authProvider.user?.id;
                if (vendorUserId != null && vendorUserId.isNotEmpty) {
                  eventProvider.fetchMyEvents(vendorUserId);
                }
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(locale.translate(
                        'Data refreshed', 'Data e nchafatsoe')),
                    duration: const Duration(seconds: 2),
                  ),
                );
              },
              tooltip: 'Refresh Data',
            ),
            IconButton(
              icon: const Icon(Icons.logout),
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
                        style:
                            TextButton.styleFrom(foregroundColor: Colors.red),
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
                          builder: (context) => const LoginScreen()),
                      (route) => false,
                    );
                  }
                }
              },
              tooltip: 'Logout',
            ),
          ],
          bottom: TabBar(
            controller: _tabController,
            indicatorColor: Colors.white,
            tabs: [
              Tab(
                icon: const Icon(Icons.dashboard),
                text: locale.translate('Overview', 'Kakaretso'),
              ),
              Tab(
                icon: const Icon(Icons.list),
                text: locale.translate('Listings', 'Lintlha'),
              ),
              Tab(
                icon: const Icon(Icons.book_online),
                text: locale.translate('Bookings', 'Lipehelo'),
              ),
              Tab(
                icon: const Icon(Icons.analytics),
                text: locale.translate('Analytics', 'Lipalopalo'),
              ),
              // ✅ Events Tab
              Tab(
                icon: const Icon(Icons.event),
                text: locale.translate('Events', 'Liketsahalo'),
              ),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildOverviewTab(
                context,
                locale,
                totalListings,
                totalBookings,
                totalEvents,
                completedBookings,
                pendingBookings,
                totalRevenue,
                vendorBookings,
                authProvider,
                vendorListings,
                primaryListing),
            const VendorListingsScreen(),
            VendorBookingsScreen(vendorBookings: vendorBookings),
            VendorAnalyticsScreen(
                vendorBookings: vendorBookings, vendorListings: vendorListings),
            // ✅ Vendor Events Screen
            VendorEventsScreen(),
          ],
        ),
      ),
    );
  }

  Future<void> _showEditSocialLinksDialog(dynamic primaryListing) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final listingProvider =
        Provider.of<ListingProvider>(context, listen: false);
    final locale = Provider.of<LocaleProvider>(context, listen: false);

    final phoneController = TextEditingController(
      text: (primaryListing?.vendorPhone ?? '').toString(),
    );
    final emailController = TextEditingController(
      text: (primaryListing?.vendorEmail ?? authProvider.user?.email ?? '')
          .toString(),
    );
    final whatsappController = TextEditingController(
      text: (primaryListing?.vendorWhatsapp ?? '').toString(),
    );
    final facebookController = TextEditingController(
      text: (primaryListing?.vendorFacebook ?? '').toString(),
    );
    final instagramController = TextEditingController(
      text: (primaryListing?.vendorInstagram ?? '').toString(),
    );

    bool isSaving = false;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: Text(
                locale.translate(
                    'Edit Social Links', 'Fetola Dikamano tsa Sechaba'),
              ),
              content: SingleChildScrollView(
                child: SizedBox(
                  width: 460,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: phoneController,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(
                          labelText: 'Phone',
                          prefixIcon: Icon(Icons.phone),
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          labelText: 'Email',
                          prefixIcon: Icon(Icons.email),
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: whatsappController,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(
                          labelText: 'WhatsApp',
                          prefixIcon: Icon(Icons.chat),
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: facebookController,
                        decoration: const InputDecoration(
                          labelText: 'Facebook username/page',
                          prefixIcon: Icon(Icons.facebook),
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: instagramController,
                        decoration: const InputDecoration(
                          labelText: 'Instagram username',
                          prefixIcon: Icon(Icons.camera_alt),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed:
                      isSaving ? null : () => Navigator.pop(dialogContext),
                  child: Text(locale.translate('Cancel', 'Hlakola')),
                ),
                ElevatedButton(
                  onPressed: isSaving
                      ? null
                      : () async {
                          setStateDialog(() => isSaving = true);
                          try {
                            final response = await _apiService.patch(
                              '/vendors/social-links',
                              {
                                'business_phone': phoneController.text.trim(),
                                'business_email': emailController.text.trim(),
                                'whatsapp': whatsappController.text.trim(),
                                'facebook': facebookController.text.trim(),
                                'instagram': instagramController.text.trim(),
                              },
                            );

                            final body = json.decode(response.body);
                            if (response.statusCode == 200 &&
                                body['success'] == true) {
                              await listingProvider.loadListings();
                              if (mounted && dialogContext.mounted) {
                                Navigator.pop(dialogContext);
                                ScaffoldMessenger.of(this.context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      locale.translate(
                                        'Social links updated',
                                        'Dikamano tsa sechaba di ntlafaditswe',
                                      ),
                                    ),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                              }
                              return;
                            }

                            if (mounted) {
                              ScaffoldMessenger.of(this.context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    body['message']?.toString() ??
                                        'Failed to update social links',
                                  ),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          } catch (_) {
                            if (mounted) {
                              ScaffoldMessenger.of(this.context).showSnackBar(
                                const SnackBar(
                                  content:
                                      Text('Failed to update social links'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          } finally {
                            if (dialogContext.mounted) {
                              setStateDialog(() => isSaving = false);
                            }
                          }
                        },
                  child: isSaving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(locale.translate('Save', 'Boloka')),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildOverviewTab(
      BuildContext context,
      LocaleProvider locale,
      int totalListings,
      int totalBookings,
      int totalEvents,
      int completedBookings,
      int pendingBookings,
      double totalRevenue,
      List<dynamic> vendorBookings,
      AuthProvider authProvider,
      List<dynamic> vendorListings,
      dynamic primaryListing) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Welcome Card
          Card(
            elevation: 4,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    ColorPalette.primaryGreen,
                    ColorPalette.secondaryGreen
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    locale.translate('Welcome back,', 'Rea u amohela hape,'),
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    authProvider.user?.name ?? 'Vendor',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    locale.translate(
                      'Manage your listings, events, and track bookings',
                      'Laola lintlha, liketsahalo, le ho shebella lipehelo tsa hao',
                    ),
                    style: const TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Stats Grid
          Text(
            locale.translate('Quick Stats', 'Lipalopalo'),
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: isMobile ? 2 : 4,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.5,
            children: [
              _buildStatCard(
                title: locale.translate('Total Listings', 'Lintlha'),
                value: '$totalListings',
                icon: Icons.list_alt,
                color: Colors.blue,
              ),
              _buildStatCard(
                title:
                    locale.translate('Total Events', 'Liketsahalo'), // ✅ ADDED
                value: '$totalEvents',
                icon: Icons.event,
                color: Colors.deepPurple,
              ),
              _buildStatCard(
                title: locale.translate('Total Bookings', 'Lipehelo'),
                value: '$totalBookings',
                icon: Icons.book_online,
                color: Colors.green,
              ),
              _buildStatCard(
                title: locale.translate('Completed', 'Tse Felileng'),
                value: '$completedBookings',
                icon: Icons.check_circle,
                color: Colors.green,
              ),
              _buildStatCard(
                title: locale.translate('Pending', 'Tse Emaetseng'),
                value: '$pendingBookings',
                icon: Icons.pending,
                color: Colors.orange,
              ),
              _buildStatCard(
                title: locale.translate('Total Revenue', 'Lekeno'),
                value: 'M${totalRevenue.toStringAsFixed(0)}',
                icon: Icons.attach_money,
                color: Colors.purple,
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Revenue Chart
          Card(
            elevation: 2,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    locale.translate('Revenue Overview', 'Kakaretso ea Lekeno'),
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 200,
                    child: _buildRevenueChart(vendorBookings),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Quick Actions
          Text(
            locale.translate('Quick Actions', 'Liketso tse Potlakileng'),
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildActionCard(
                  icon: Icons.add_business,
                  label: locale.translate('Add Listing', 'Kenya Lintlha'),
                  color: Colors.green,
                  onTap: () {
                    _tabController.animateTo(1);
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildActionCard(
                  icon: Icons.add,
                  label: locale.translate(
                      'Add Event', 'Kenya Ketsahalo'), // ✅ ADDED
                  color: Colors.deepPurple,
                  onTap: () {
                    _tabController.animateTo(4); // Events tab
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildActionCard(
                  icon: Icons.book_online,
                  label: locale.translate('View Bookings', 'Bona Lipehelo'),
                  color: Colors.blue,
                  onTap: () {
                    _tabController.animateTo(2);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildActionCard(
                  icon: Icons.analytics,
                  label: locale.translate('View Analytics', 'Bona Lipalopalo'),
                  color: Colors.purple,
                  onTap: () {
                    _tabController.animateTo(3);
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildActionCard(
                  icon: Icons.message,
                  label: locale.translate('Messages', 'Melaetsa'),
                  color: Colors.orange,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ChatListScreen(),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),

          // Social Media & Contact Section
          const SizedBox(height: 24),
          Card(
            elevation: 2,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Connect With Customers',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Share your social media links to help customers reach you',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  // Social Media Buttons
                  SocialMediaButtons(
                    whatsapp: primaryListing?.vendorWhatsapp,
                    phone: primaryListing?.vendorPhone,
                    email:
                        primaryListing?.vendorEmail ?? authProvider.user?.email,
                    website: primaryListing?.vendorWebsite,
                    facebook: primaryListing?.vendorFacebook,
                    instagram: primaryListing?.vendorInstagram,
                    iconSize: 20,
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: () {
                      _showEditSocialLinksDialog(primaryListing);
                    },
                    icon: const Icon(Icons.edit, size: 16),
                    label: const Text('Edit Social Links'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Your Latest Listings Section
          const SizedBox(height: 24),
          Text(
            locale.translate(
                'Your Latest Listings', 'Lintlha tsa Hao tsa Morao-rao'),
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          if (vendorListings.isEmpty)
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                    'Your listings will appear here as soon as you add them.'),
              ),
            )
          else
            ...vendorListings.take(3).map((listing) {
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: ColorPalette.lightGreen,
                    child:
                        Icon(Icons.list_alt, color: ColorPalette.primaryGreen),
                  ),
                  title: Text(
                    listing.title,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                      '${listing.location} • M${listing.price.toStringAsFixed(0)}'),
                  trailing: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      listing.isAvailable ? 'Live' : 'Hidden',
                      style: const TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            Text(
              title,
              style: TextStyle(fontSize: 11, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(height: 8),
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Colors.grey[800]),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRevenueChart(List<dynamic> bookings) {
    // Group bookings by month
    final Map<int, double> monthlyRevenue = {};
    for (var booking in bookings) {
      if (booking.status == 'completed') {
        final month = booking.createdAt.month;
        monthlyRevenue[month] =
            (monthlyRevenue[month] ?? 0) + booking.grandTotal;
      }
    }

    final spots = List.generate(12, (index) {
      final month = index + 1;
      return FlSpot(index.toDouble(), monthlyRevenue[month] ?? 0);
    });

    return LineChart(
      LineChartData(
        gridData: const FlGridData(show: true),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                const months = [
                  'Jan',
                  'Feb',
                  'Mar',
                  'Apr',
                  'May',
                  'Jun',
                  'Jul',
                  'Aug',
                  'Sep',
                  'Oct',
                  'Nov',
                  'Dec'
                ];
                return Text(
                  months[value.toInt()],
                  style: const TextStyle(fontSize: 10),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                return Text('M${value.toInt()}',
                    style: const TextStyle(fontSize: 10));
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: true),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: ColorPalette.primaryGreen,
            barWidth: 3,
            dotData: const FlDotData(show: true),
            belowBarData: BarAreaData(
              show: true,
              color: ColorPalette.primaryGreen.withValues(alpha: 0.1),
            ),
          ),
        ],
      ),
    );
  }
}
