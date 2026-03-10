import 'package:flutter/material.dart';
import '../../di/service_locator.dart';
import '../../domain/services/data_service.dart';

/// Demonstrates the wiring pattern: control → provider → notifyListeners → main content rebuilds.
///
/// Replace these placeholder fields with your app's domain-specific state.
/// Each setter calls notifyListeners() which triggers Consumer rebuilds.
class AppStateProvider extends ChangeNotifier {
  final DataService _dataService;

  AppStateProvider({DataService? dataService})
      : _dataService = dataService ?? serviceLocator<DataService>();

  // --- Data loading state ---
  bool _isLoading = false;
  String? _error;
  Map<String, dynamic> _data = {};

  bool get isLoading => _isLoading;
  String? get error => _error;
  Map<String, dynamic> get data => _data;

  Future<void> loadData() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _data = await _dataService.loadData();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // --- All 10 control types ---

  // 1. Text Input
  String _textInputValue = '';
  String get textInputValue => _textInputValue;
  void setTextInputValue(String value) {
    _textInputValue = value;
    notifyListeners();
  }

  // 2. Dropdown
  String _dropdownValue = 'Option A';
  String get dropdownValue => _dropdownValue;
  void setDropdownValue(String value) {
    _dropdownValue = value;
    notifyListeners();
  }

  // 3. Checkbox
  bool _checkboxValue = false;
  bool get checkboxValue => _checkboxValue;
  void setCheckboxValue(bool value) {
    _checkboxValue = value;
    notifyListeners();
  }

  // 4. Radio
  String _radioValue = 'Medium';
  String get radioValue => _radioValue;
  void setRadioValue(String value) {
    _radioValue = value;
    notifyListeners();
  }

  // 5. Toggle / Switch
  bool _toggleValue = true;
  bool get toggleValue => _toggleValue;
  void setToggleValue(bool value) {
    _toggleValue = value;
    notifyListeners();
  }

  // 6. Slider
  double _sliderValue = 50.0;
  double get sliderValue => _sliderValue;
  void setSliderValue(double value) {
    _sliderValue = value;
    notifyListeners();
  }

  // 7. Range Slider
  RangeValues _rangeSliderValue = const RangeValues(20, 80);
  RangeValues get rangeSliderValue => _rangeSliderValue;
  void setRangeSliderValue(RangeValues value) {
    _rangeSliderValue = value;
    notifyListeners();
  }

  // 8. Number Input (nullable = auto)
  double? _numberInputValue;
  double? get numberInputValue => _numberInputValue;
  void setNumberInputValue(double? value) {
    _numberInputValue = value;
    notifyListeners();
  }

  // 9. Searchable Input
  String _searchableInputValue = '';
  String get searchableInputValue => _searchableInputValue;
  void setSearchableInputValue(String value) {
    _searchableInputValue = value;
    notifyListeners();
  }

  // 10. Segmented Button
  String _segmentedValue = 'Week';
  String get segmentedValue => _segmentedValue;
  void setSegmentedValue(String value) {
    _segmentedValue = value;
    notifyListeners();
  }
}
