// lib/providers/culture_provider.dart
import 'package:flutter/material.dart';

import '../models/culture_subcategory.dart';
import '../models/culture_vendor.dart';
import '../services/culture_service.dart';

class CultureProvider extends ChangeNotifier {
  final CultureService _service = CultureService();

  List<CultureSubcategory> _subcategories = [];
  List<CultureVendor> _vendors = [];
  String _selectedSubcategorySlug = 'all';
  bool _isLoading = false;
  String? _error;

  List<CultureSubcategory> get subcategories =>
      List.unmodifiable(_subcategories);
  List<CultureVendor> get vendors => List.unmodifiable(_vendors);
  String get selectedSubcategorySlug => _selectedSubcategorySlug;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadInitial() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final subcategoryResult = await _service.fetchSubcategories();
    if (subcategoryResult['success'] == true) {
      _subcategories = List<CultureSubcategory>.from(
          subcategoryResult['subcategories'] ?? []);
    } else {
      _error = subcategoryResult['error']?.toString() ??
          'Failed to load culture subcategories';
    }

    await loadVendors();
    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadVendors({String? search}) async {
    final slug =
        _selectedSubcategorySlug == 'all' ? null : _selectedSubcategorySlug;
    final result =
        await _service.fetchVendors(subcategorySlug: slug, search: search);
    if (result['success'] == true) {
      _vendors = List<CultureVendor>.from(result['vendors'] ?? []);
      _error = null;
    } else {
      _vendors = [];
      _error = result['error']?.toString() ?? 'Failed to load culture vendors';
    }
    notifyListeners();
  }

  Future<void> selectSubcategory(String slug) async {
    if (_selectedSubcategorySlug == slug) return;
    _selectedSubcategorySlug = slug;
    _isLoading = true;
    notifyListeners();
    await loadVendors();
    _isLoading = false;
    notifyListeners();
  }
}
