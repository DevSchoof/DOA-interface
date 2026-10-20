import '../models/models.dart';
import 'auth_service.dart';
import 'institution_service.dart';

class MockInstitutionService implements InstitutionService {
  final List<Institution> _institutions = [];

  @override
  Future<Institution> registerInstitution({
    required String userId,
    required String name,
    required String cnpj,
    required String phone,
    required String address,
    required String city,
    required double storageCapacity,
    double? latitude,
    double? longitude,
  }) async {
    await Future.delayed(const Duration(milliseconds: 500));

    if (storageCapacity <= 0) {
      throw const AuthException('A capacidade deve ser maior que zero.');
    }
    if (_institutions.any((i) => i.userId == userId)) {
      throw const AuthException(
        'Esta conta já possui uma instituição cadastrada.',
      );
    }
    if (_institutions.any((i) => i.cnpj == cnpj)) {
      throw const AuthException('Este CNPJ já está cadastrado.');
    }

    final institution = Institution(
      id: 'i${_institutions.length + 1}',
      userId: userId,
      name: name,
      cnpj: cnpj,
      phone: phone,
      address: address,
      city: city,
      latitude: latitude,
      longitude: longitude,
      storageCapacity: storageCapacity,
      status: InstitutionStatus.pending, // aguarda homologação (PB-007)
    );
    _institutions.add(institution);
    return institution;
  }

  @override
  Future<Institution?> findByUserId(String userId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    for (final institution in _institutions) {
      if (institution.userId == userId) return institution;
    }
    return null;
  }
}
