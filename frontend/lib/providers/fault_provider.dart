import 'package:flutter/material.dart';
import '../models/fault.dart';
import '../services/fault_service.dart';

class FaultProvider with ChangeNotifier {
  final FaultService _service = FaultService();
  
  List<Fault> _faults = [];
  bool _isLoading = false;
  String? _error;

  List<Fault> get faults => _faults;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchFaults() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _faults = await _service.getFaults();
      // Sort by newest first
      _faults.sort((a, b) => b.detectedAt.compareTo(a.detectedAt));
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> resolveFault(String id) async {
    try {
      final success = await _service.resolveFault(id);
      if (success) {
        final index = _faults.indexWhere((f) => f.id == id);
        if (index != -1) {
          _faults[index] = Fault(
            id: _faults[index].id,
            transformerId: _faults[index].transformerId,
            transformerName: _faults[index].transformerName,
            location: _faults[index].location,
            fuseId: _faults[index].fuseId,
            faultType: _faults[index].faultType,
            status: 'Resolved',
            detectedAt: _faults[index].detectedAt,
            resolvedAt: DateTime.now(),
          );
          notifyListeners();
        }
      }
      return success;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }
}
