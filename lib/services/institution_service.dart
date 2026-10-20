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
}
