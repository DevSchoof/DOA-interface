import '../models/models.dart';

abstract class InstitutionService {
  /// PB-006: cadastra a instituição com status Pendente.
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
  });

  /// Instituição do usuário, ou null se ainda não se cadastrou.
  Future<Institution?> findByUserId(String userId);

  /// PB-007 (admin): lista instituições, opcionalmente filtrando por status.
  Future<List<Institution>> listByStatus(InstitutionStatus? status);

  /// PB-007 (admin): aprova ou rejeita uma instituição pendente.
  Future<Institution> updateStatus(String id, InstitutionStatus status);
}
