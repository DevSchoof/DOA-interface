import '../models/models.dart';

abstract class ImpactService {
  /// Métricas do usuário logado (admin vê o consolidado).
  Future<ImpactSummary> getSummary();
}
