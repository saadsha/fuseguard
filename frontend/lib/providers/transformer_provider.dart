import 'package:flutter/material.dart';
import '../models/transformer.dart';
import '../services/transformer_service.dart';

class TransformerProvider with ChangeNotifier {
  final TransformerService _service = TransformerService();
  
  List<Transformer> _transformers = [];
  List<String> _externallyAcceptedJobs = [];
  bool _isLoading = false;
  String? _error;

  List<Transformer> get transformers => _transformers;
  List<String> get externallyAcceptedJobs => _externallyAcceptedJobs;
  bool get isLoading => _isLoading;
  String? get error => _error;

  int get totalTransformers => _transformers.length;
  int get totalFuses => _transformers.fold(0, (sum, t) => sum + t.fuses.length);
  int get totalActiveFaults => _transformers.fold(0, (sum, t) => sum + t.blownFusesCount);

  Future<void> fetchTransformers() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _transformers = await _service.getTransformers();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Called via WebSocket when a transformer updates
  void updateTransformerLocally(Transformer updatedTransformer) {
    final index = _transformers.indexWhere((t) => t.id == updatedTransformer.id);
    if (index != -1) {
      _transformers[index] = updatedTransformer;
    } else {
      _transformers.add(updatedTransformer);
    }
    
    // If it recovered, we could optionally remove it from accepted jobs,
    // but typically a fault status check handles UI presence anyway.
    if (updatedTransformer.blownFusesCount == 0 && _externallyAcceptedJobs.contains(updatedTransformer.id)) {
      _externallyAcceptedJobs.remove(updatedTransformer.id);
    }

    notifyListeners();
  }

  void markJobExternallyAccepted(String transformerId) {
    if (!_externallyAcceptedJobs.contains(transformerId)) {
      _externallyAcceptedJobs.add(transformerId);
      notifyListeners();
    }
  }
  
  Future<bool> addTransformer(Map<String, dynamic> data) async {
     try {
         final newTransformer = await _service.createTransformer(data);
         _transformers.add(newTransformer);
         notifyListeners();
         return true;
     } catch (e) {
         _error = e.toString();
         notifyListeners();
         return false;
     }
  }

  Future<bool> updateTransformer(String id, Map<String, dynamic> data) async {
      try {
          final updatedTransformer = await _service.updateTransformer(id, data);
          final index = _transformers.indexWhere((t) => t.id == updatedTransformer.id);
          if (index != -1) {
              _transformers[index] = updatedTransformer;
              notifyListeners();
          }
          return true;
      } catch (e) {
          _error = e.toString();
          notifyListeners();
          return false;
      }
  }

  Future<bool> deleteTransformer(String id) async {
      try {
          await _service.deleteTransformer(id);
          _transformers.removeWhere((t) => t.id == id);
          notifyListeners();
          return true;
      } catch (e) {
          _error = e.toString();
          notifyListeners();
          return false;
      }
  }
}
