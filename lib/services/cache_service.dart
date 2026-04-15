
// lib/services/cache_service.dart
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/listing.dart';

class CacheService {
  static const String _listingsKey = 'cached_listings';
  static const String _lastUpdatedKey = 'last_updated';
  static const Duration _cacheDuration = Duration(days: 7); // Cache expires after 7 days

  final SharedPreferences _prefs;

  CacheService(this._prefs);

  // Save listings to cache
  Future<void> saveListings(List<Listing> listings) async {
    try {
      final listingsJson = listings.map((l) => l.toJson()).toList();
      await _prefs.setString(_listingsKey, json.encode(listingsJson));
      await _prefs.setString(_lastUpdatedKey, DateTime.now().toIso8601String());
      print('✅ Listings cached: ${listings.length} items');
    } catch (e) {
      print('❌ Failed to cache listings: $e');
    }
  }

  // Load listings from cache
  Future<List<Listing>> loadListings() async {
    try {
      final listingsJsonString = _prefs.getString(_listingsKey);
      if (listingsJsonString == null) {
        print('📦 No cached listings found');
        return [];
      }

      final List<dynamic> listingsJson = json.decode(listingsJsonString);
      final listings = listingsJson.map((json) => Listing.fromJson(json)).toList();
      print('📦 Loaded ${listings.length} listings from cache');
      return listings;
    } catch (e) {
      print('❌ Failed to load cached listings: $e');
      return [];
    }
  }

  // Check if cache is valid (not expired)
  Future<bool> isCacheValid() async {
    final lastUpdatedStr = _prefs.getString(_lastUpdatedKey);
    if (lastUpdatedStr == null) return false;

    try {
      final lastUpdated = DateTime.parse(lastUpdatedStr);
      final isExpired = DateTime.now().difference(lastUpdated) > _cacheDuration;
      return !isExpired;
    } catch (e) {
      return false;
    }
  }

  // Check if cache exists
  Future<bool> hasCache() async {
    return _prefs.containsKey(_listingsKey);
  }

  // Clear cache
  Future<void> clearCache() async {
    await _prefs.remove(_listingsKey);
    await _prefs.remove(_lastUpdatedKey);
    print('🗑️ Cache cleared');
  }

  // Get cache info (for debugging)
  Future<Map<String, dynamic>> getCacheInfo() async {
    final hasCache = await this.hasCache();
    final isValid = await isCacheValid();
    final lastUpdatedStr = _prefs.getString(_lastUpdatedKey);
    
    return {
      'hasCache': hasCache,
      'isValid': isValid,
      'lastUpdated': lastUpdatedStr,
      'cacheDuration': _cacheDuration.inDays,
    };
  }
}