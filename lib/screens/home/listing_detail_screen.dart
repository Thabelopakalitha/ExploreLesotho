// lib/screens/home/listing_detail_screen.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/review.dart';
import '../../providers/listing_provider.dart';
import '../../providers/review_provider.dart';
import '../../providers/locale_provider.dart';
import '../../services/social_service.dart';
import '../../widgets/review_card.dart';
import '../../widgets/social_media_buttons.dart';
import '../../core/themes/color_palette.dart';
import '../../widgets/custom_button.dart';
import '../bookings/booking_screen.dart';

class ListingDetailScreen extends StatefulWidget {
  final String listingId;

  const ListingDetailScreen({super.key, required this.listingId});

  @override
  State<ListingDetailScreen> createState() => _ListingDetailScreenState();
}

class _ListingDetailScreenState extends State<ListingDetailScreen> {
  @override
  void initState() {
    super.initState();
    final reviewProvider = Provider.of<ReviewProvider>(context, listen: false);
    reviewProvider.fetchReviewsForListing(widget.listingId);
  }

  @override
  Widget build(BuildContext context) {
    final locale = Provider.of<LocaleProvider>(context);
    final listingProvider = Provider.of<ListingProvider>(context);

    final listing = listingProvider.getListingById(widget.listingId);

    if (listing == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text(
              locale.translate('Listing Details', 'Lintlha Tse Felletseng')),
          backgroundColor: ColorPalette.primaryGreen,
          foregroundColor: Colors.white,
        ),
        body: Center(
          child: Text(
              locale.translate('Listing not found', 'Lintlha ha li fumanehe')),
        ),
      );
    }

    final hasContactInfo = (listing.vendorPhone?.trim().isNotEmpty ?? false) ||
        (listing.vendorEmail?.trim().isNotEmpty ?? false) ||
        (listing.vendorWebsite?.trim().isNotEmpty ?? false) ||
        (listing.vendorFacebook?.trim().isNotEmpty ?? false) ||
        (listing.vendorInstagram?.trim().isNotEmpty ?? false) ||
        (listing.vendorWhatsapp?.trim().isNotEmpty ?? false);
    final hasBookingHost = (listing.vendorId?.trim().isNotEmpty ?? false) &&
        (listing.vendorName?.trim().isNotEmpty ?? false);
    final portfolioImages = _collectPortfolioImages(listing);
    final videoLinks = _collectVideoLinks(listing);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: ColorPalette.primaryGreen,
            foregroundColor: Colors.white,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(listing.title),
              background: Container(
                color: ColorPalette.primaryGreen.withValues(alpha: 0.3),
                child: listing.imageUrl != null && listing.imageUrl!.isNotEmpty
                    ? _buildListingImage(listing.imageUrl!)
                    : const Center(
                        child: Icon(Icons.image, size: 64, color: Colors.white),
                      ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                const SizedBox(height: 16),
                // Location
                Row(
                  children: [
                    Icon(Icons.location_on, color: Colors.grey[600], size: 16),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        listing.location +
                            (listing.district != null
                                ? ', ${listing.district}'
                                : ''),
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Host info
                if (listing.vendorName != null)
                  Row(
                    children: [
                      Icon(Icons.person, color: Colors.grey[600], size: 16),
                      const SizedBox(width: 4),
                      Text(
                        'Hosted by ${listing.vendorName}',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                const SizedBox(height: 16),
                // Price
                Row(
                  children: [
                    Text(
                      listing.formattedPrice,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: ColorPalette.primaryGreen,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      listing.priceUnit ?? '/night',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Rating
                if (listing.rating != null)
                  Row(
                    children: [
                      const Icon(Icons.star, color: Colors.amber, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        listing.rating!.toStringAsFixed(1),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      if (listing.reviewCount != null) ...[
                        const SizedBox(width: 4),
                        Text(
                          '(${listing.reviewCount} reviews)',
                          style:
                              TextStyle(color: Colors.grey[600], fontSize: 14),
                        ),
                      ],
                    ],
                  ),
                const SizedBox(height: 24),
                if (portfolioImages.isNotEmpty || videoLinks.isNotEmpty) ...[
                  Text(
                    locale.translate('Portfolio', 'Pokello ya Mesebetsi'),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (portfolioImages.isNotEmpty)
                    SizedBox(
                      height: 210,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: portfolioImages.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 10),
                        itemBuilder: (context, index) {
                          final image = portfolioImages[index];
                          return InkWell(
                            onTap: () => _showImagePreview(image),
                            borderRadius: BorderRadius.circular(14),
                            child: Container(
                              width: 250,
                              clipBehavior: Clip.antiAlias,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(14),
                                color: Colors.grey[100],
                              ),
                              child: _buildListingImage(image),
                            ),
                          );
                        },
                      ),
                    ),
                  if (videoLinks.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: List.generate(videoLinks.length, (index) {
                        final link = videoLinks[index];
                        return ActionChip(
                          avatar: const Icon(Icons.play_circle_fill, size: 18),
                          label: Text('Video ${index + 1}'),
                          onPressed: () async {
                            try {
                              await SocialService.launchWebsite(link);
                            } catch (_) {
                              if (!mounted) return;
                              ScaffoldMessenger.of(this.context).showSnackBar(
                                const SnackBar(
                                  content:
                                      Text('Could not open this video link'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          },
                        );
                      }),
                    ),
                  ],
                  const SizedBox(height: 24),
                ],

                // Description
                Text(
                  locale.translate('Description', 'Tlhaloso'),
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  listing.description,
                  style: const TextStyle(fontSize: 16, height: 1.5),
                ),
                const SizedBox(height: 24),

                // ========== CONTACT & SOCIAL MEDIA SECTION ==========
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          locale.translate(
                              'Contact Host', 'Ikopanye le Moamoheli'),
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 12),
                        if (hasContactInfo)
                          SocialMediaButtons(
                            whatsapp:
                                listing.vendorWhatsapp ?? listing.vendorPhone,
                            phone: listing.vendorPhone,
                            email: listing.vendorEmail,
                            website: listing.vendorWebsite,
                            facebook: listing.vendorFacebook,
                            instagram: listing.vendorInstagram,
                            iconSize: 24,
                          )
                        else
                          Text(
                            locale.translate(
                              'Host contact details are not available yet.',
                              'Lintlha tsa ho ikopanya le moamoheli ha li eo hajoale.',
                            ),
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                // ========== END CONTACT & SOCIAL MEDIA SECTION ==========

                const SizedBox(height: 24),

                // ========== REVIEWS SECTION ==========
                Text(
                  locale.translate('Reviews', 'Maikutlo'),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),

                Consumer<ReviewProvider>(
                  builder: (context, reviewProvider, child) {
                    final reviews =
                        reviewProvider.getReviewsForListing(widget.listingId);
                    final averageRating = reviewProvider
                        .getAverageRatingForListing(widget.listingId);
                    final reviewCount = reviews.length;

                    if (reviewCount == 0) {
                      return _buildEmptyReviews();
                    }

                    return Column(
                      children: [
                        // Rating Summary Card
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    children: [
                                      Text(
                                        averageRating.toStringAsFixed(1),
                                        style: const TextStyle(
                                          fontSize: 32,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: List.generate(5, (index) {
                                          return Icon(
                                            index < averageRating
                                                ? Icons.star
                                                : Icons.star_border,
                                            size: 16,
                                            color: Colors.amber[700],
                                          );
                                        }),
                                      ),
                                      Text(
                                        '$reviewCount review${reviewCount > 1 ? 's' : ''}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  width: 1,
                                  height: 60,
                                  color: Colors.grey[300],
                                ),
                                Expanded(
                                  child: Column(
                                    children: [
                                      _buildRatingBar(5, reviews),
                                      _buildRatingBar(4, reviews),
                                      _buildRatingBar(3, reviews),
                                      _buildRatingBar(2, reviews),
                                      _buildRatingBar(1, reviews),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Reviews List
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: reviews.length,
                          itemBuilder: (context, index) {
                            final review = reviews[index];
                            return ReviewCard(
                              review: review,
                              onHelpful: () =>
                                  reviewProvider.markHelpful(review.id),
                              onReport: () => _showReportDialog(review),
                            );
                          },
                        ),
                      ],
                    );
                  },
                ),
                // ========== END REVIEWS SECTION ==========

                const SizedBox(height: 32),
                // Book button
                CustomButton(
                  onPressed: () {
                    if (!hasBookingHost) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            locale.translate(
                              'This listing is missing host booking details.',
                              'Lintlha tsa ho behela ho moamoheli ha lia phethahala.',
                            ),
                          ),
                        ),
                      );
                      return;
                    }

                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => BookingScreen(
                          listingId: listing.id,
                          listingTitle: listing.title,
                          vendorId: listing.vendorId!,
                          vendorName: listing.vendorName!,
                          pricePerNight: listing.price,
                          listingCategory: listing.category,
                          priceUnit: listing.priceUnit,
                          additionalDetails: listing.additionalDetails,
                        ),
                      ),
                    );
                  },
                  text: hasBookingHost
                      ? locale.translate('Book Now', 'Behla Hona Joale')
                      : locale.translate(
                          'Booking Unavailable', 'Ho Buka Ha ho Fumanehe'),
                ),
                const SizedBox(height: 32),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListingImage(String imageUrl) {
    if (imageUrl.startsWith('data:image')) {
      final parts = imageUrl.split(',');
      if (parts.length == 2) {
        return Image.memory(
          base64Decode(parts[1]),
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => const Center(
            child: Icon(Icons.image, size: 64, color: Colors.white),
          ),
        );
      }
    }

    return Image.network(
      imageUrl,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        return const Center(
          child: Icon(Icons.image, size: 64, color: Colors.white),
        );
      },
    );
  }

  List<String> _collectPortfolioImages(dynamic listing) {
    final images = <String>[];
    if (listing.imageUrl != null &&
        listing.imageUrl!.toString().trim().isNotEmpty) {
      images.add(listing.imageUrl!.toString());
    }
    if (listing.images != null) {
      for (final img in listing.images!) {
        final value = img.toString().trim();
        if (value.isNotEmpty && !images.contains(value)) {
          images.add(value);
        }
      }
    }
    return images;
  }

  List<String> _collectVideoLinks(dynamic listing) {
    final raw = listing.additionalDetails?['videoLinks'];
    if (raw is List) {
      return raw
          .map((e) => e.toString().trim())
          .where((e) => e.isNotEmpty)
          .toList();
    }
    if (raw is String) {
      return raw
          .split(RegExp(r'[\n,]'))
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
    }
    return <String>[];
  }

  void _showImagePreview(String imageUrl) {
    showDialog<void>(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: const EdgeInsets.all(20),
        child: Stack(
          children: [
            Positioned.fill(child: _buildListingImage(imageUrl)),
            Positioned(
              top: 6,
              right: 6,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper Methods
  Widget _buildEmptyReviews() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Icon(
              Icons.rate_review_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No reviews yet',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Be the first to review this place!',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRatingBar(int stars, List<Review> reviews) {
    final count =
        reviews.where((r) => r.rating >= stars && r.rating < stars + 1).length;
    final percentage = reviews.isEmpty ? 0 : (count / reviews.length) * 100;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(
            width: 30,
            child: Text(
              '$stars★',
              style: const TextStyle(fontSize: 12),
            ),
          ),
          Expanded(
            child: LinearProgressIndicator(
              value: percentage / 100,
              backgroundColor: Colors.grey[200],
              color: Colors.amber[700],
              minHeight: 6,
            ),
          ),
          SizedBox(
            width: 40,
            child: Text(
              '${percentage.toStringAsFixed(0)}%',
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey[600],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showReportDialog(Review review) {
    final locale = Provider.of<LocaleProvider>(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(locale.translate('Report Review', 'Tlaleha Maikutlo')),
        content: Text(locale.translate(
            'Are you sure you want to report this review?',
            'Na u na le bonnete ba hore u batla ho tlaleha maikutlo aa?')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(locale.translate('Cancel', 'Hlakola')),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(locale.translate(
                      'Review reported. Thank you for helping keep our community safe.',
                      'Maikutlo a tlalehiloe. Re leboha ho thusa ho boloka sechaba sa rona se sireletsehile.')),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: Text(locale.translate('Report', 'Tlaleha')),
          ),
        ],
      ),
    );
  }
}
