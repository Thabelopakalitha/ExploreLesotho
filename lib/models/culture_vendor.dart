// lib/data/models/culture_vendor.dart
class CultureVendor {
  final String id;
  final String name;
  final String productRange;
  final String location;
  final List<String> contacts;
  final List<String> subcategories;
  final List<String> subcategorySlugs;
  final String? linkedListingId;
  final String? sourceDocument;

  const CultureVendor({
    required this.id,
    required this.name,
    required this.productRange,
    required this.location,
    required this.contacts,
    required this.subcategories,
    required this.subcategorySlugs,
    this.linkedListingId,
    this.sourceDocument,
  });

  factory CultureVendor.fromJson(Map<String, dynamic> json) {
    return CultureVendor(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      productRange: json['productRange']?.toString() ?? '',
      location: json['location']?.toString() ?? '',
      contacts: (json['contacts'] as List?)
              ?.map((item) => item.toString())
              .where((item) => item.trim().isNotEmpty)
              .toList() ??
          const [],
      subcategories: (json['subcategories'] as List?)
              ?.map((item) => item.toString())
              .toList() ??
          const [],
      subcategorySlugs: (json['subcategorySlugs'] as List?)
              ?.map((item) => item.toString())
              .toList() ??
          const [],
      linkedListingId: json['linkedListingId']?.toString(),
      sourceDocument: json['sourceDocument']?.toString(),
    );
  }
}
