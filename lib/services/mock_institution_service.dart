import '../models/models.dart';
import 'auth_service.dart';
import 'institution_service.dart';

class MockInstitutionService implements InstitutionService {
  /// [withSampleData] cria instituições de exemplo para demonstração.
  MockInstitutionService({bool withSampleData = true}) {
    if (withSampleData) _institutions.addAll(_sampleData);
  }

  final List<Institution> _institutions = [];

  static const _sampleData = [
    Institution(
      id: 's1',
      userId: 'seed1',
      name: 'Banco de Alimentos Central',
      cnpj: '10000000000100',
      phone: '1133334444',
      address: 'Av. Brasil, 1000',
      city: 'São Paulo',
      storageCapacity: 800,
    ),
    Institution(
      id: 's2',
      userId: 'seed2',
      name: 'Cozinha Solidária Vila Nova',
      cnpj: '20000000000100',
      phone: '11988887777',
      address: 'Rua das Flores, 25',
      city: 'Guarulhos',
      storageCapacity: 250,
    ),
    Institution(
      id: 's3',
      userId: 'seed3',
      name: 'Associação Mesa Farta',
      cnpj: '30000000000100',
      phone: '11977776666',
      address: 'Rua Nova, 80',
      city: 'Osasco',
      storageCapacity: 400,
      status: InstitutionStatus.approved,
    ),
    Institution(
      id: 's4',
      userId: 'seed4',
      name: 'Instituto Esperança Viva',
      cnpj: '40000000000100',
      phone: '11966665555',
      address: 'Rua do Sol, 9',
      city: 'Santo André',
      storageCapacity: 120,
      status: InstitutionStatus.rejected,
    ),
  ];

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

  @override
  Future<List<Institution>> listByStatus(InstitutionStatus? status) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return _institutions
        .where((i) => status == null || i.status == status)
        .toList();
  }

  @override
  Future<Institution> updateStatus(String id, InstitutionStatus status) async {
    await Future.delayed(const Duration(milliseconds: 300));

    if (status != InstitutionStatus.approved &&
        status != InstitutionStatus.rejected) {
      throw const AuthException('Status inválido para homologação.');
    }
    final index = _institutions.indexWhere((i) => i.id == id);
    if (index == -1) {
      throw const AuthException('Instituição não encontrada.');
    }
    final current = _institutions[index];
    if (current.status != InstitutionStatus.pending) {
      throw const AuthException(
        'Só é possível homologar instituições pendentes.',
      );
    }
    final updated = Institution(
      id: current.id,
      userId: current.userId,
      name: current.name,
      cnpj: current.cnpj,
      phone: current.phone,
      address: current.address,
      city: current.city,
      latitude: current.latitude,
      longitude: current.longitude,
      storageCapacity: current.storageCapacity,
      status: status,
    );
    _institutions[index] = updated;
    return updated;
  }
}
