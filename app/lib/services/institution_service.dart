import '../models/models.dart';

abstract class InstitutionService {
  /// Cadastro da instituição do usuário logado (fica PENDING até o admin aprovar).
  /// [categoryIds]: ao menos uma categoria aceita (N:N).
  Future<Institution> registerInstitution({
    required String name,
    required String cnpj,
    required String address,
    required String city,
    required String areaOfActivity,
    required double storageCapacityKg,
    required List<String> categoryIds,
    double? latitude,
    double? longitude,
  });

  /// Instituição do usuário logado, ou null se ainda não completou.
  Future<Institution?> getMine();

  /// Atualiza os dados da instituição logada. Se estava REJEITADA, volta para
  /// análise (reenvio após correção). CNPJ e categorias não mudam aqui.
  Future<Institution> updateMine({
    required String name,
    required String address,
    required String city,
    required String areaOfActivity,
    required double storageCapacityKg,
    double? latitude,
    double? longitude,
  });

  /// Troca o conjunto de categorias que a instituição aceita.
  Future<Institution> updateCategories(List<String> categoryIds);

  /// Admin: lista por status.
  Future<List<Institution>> listByStatus(InstitutionStatus status);

  /// Admin: aprova o cadastro.
  Future<Institution> approve(String id);

  /// Admin: rejeita o cadastro com justificativa.
  Future<Institution> reject(String id, String reason);
}
