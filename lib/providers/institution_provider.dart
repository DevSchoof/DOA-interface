import 'package:flutter/foundation.dart';

import '../models/models.dart';
import '../services/institution_service.dart';

/// Guarda a instituição do usuário logado e avisa as telas quando muda.
class InstitutionProvider extends ChangeNotifier {
  InstitutionProvider(this._service);

  final InstitutionService _service;

  Institution? _institution;
  String? _userId;
  bool _isLoading = false;

  Institution? get institution => _institution;
  bool get isLoading => _isLoading;

  /// Carrega a instituição do usuário (recarrega se o usuário mudou).
  Future<void> load(String userId) async {
    if (_userId != userId) {
      _userId = userId;
      _institution = null;
    }
    _isLoading = true;
    notifyListeners();
    try {
      final found = await _service.findByUserId(userId);
      if (_userId == userId) _institution = found;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Institution> register({
    required String userId,
    required String name,
    required String cnpj,
    required String phone,
    required String address,
    required String city,
    required double storageCapacity,
  }) async {
    final created = await _service.registerInstitution(
      userId: userId,
      name: name,
      cnpj: cnpj,
      phone: phone,
      address: address,
      city: city,
      storageCapacity: storageCapacity,
    );
    _userId = userId;
    _institution = created;
    notifyListeners();
    return created;
  }
}
