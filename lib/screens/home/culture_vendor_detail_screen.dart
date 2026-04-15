// lib/screens/home/culture_vendor_detail_screen.dart
import 'package:flutter/material.dart';
import '../../models/culture_vendor.dart';
import '../../services/social_service.dart';
import 'listing_detail_screen.dart';

class CultureVendorDetailScreen extends StatelessWidget {
  final CultureVendor vendor;

  const CultureVendorDetailScreen({
    super.key,
    required this.vendor,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(vendor.name),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (vendor.linkedListingId != null)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 14),
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ListingDetailScreen(
                            listingId: vendor.linkedListingId!),
                      ),
                    );
                  },
                  icon: const Icon(Icons.photo_library),
                  label: const Text('View Portfolio, Products & Services'),
                ),
              ),
            _sectionTitle('Products / Services'),
            const SizedBox(height: 8),
            _sectionBody(vendor.productRange),
            const SizedBox(height: 18),
            _sectionTitle('Location'),
            const SizedBox(height: 8),
            _sectionBody(
                vendor.location.isEmpty ? 'Not specified' : vendor.location),
            const SizedBox(height: 18),
            _sectionTitle('Contact'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: vendor.contacts.isEmpty
                  ? [const Text('No contacts available')]
                  : vendor.contacts.map((contact) {
                      return OutlinedButton.icon(
                        onPressed: () async {
                          try {
                            await SocialService.callPhone(contact);
                          } catch (_) {
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Could not open dialer'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        },
                        icon: const Icon(Icons.call, size: 16),
                        label: Text(contact),
                      );
                    }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
    );
  }

  Widget _sectionBody(String value) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
      ),
      child: Text(value),
    );
  }
}
