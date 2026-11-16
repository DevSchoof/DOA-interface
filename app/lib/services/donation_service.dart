import '../models/models.dart';

abstract class DonationService {
  /// Doador: registra uma doação (status inicial: AVAILABLE).
  Future<Donation> createDonation({
    required String categoryId,
    required String description,
    required double quantity,
    required String unit,
    required DateTime expiresAt,
    String? storageConditions,
  });

  /// Doador: edita uma doação ainda disponível.
  Future<Donation> updateDonation(
    String id, {
    required String categoryId,
    required String description,
    required double quantity,
    required String unit,
    required DateTime expiresAt,
    String? storageConditions,
  });

  /// Doador: exclui (só AVAILABLE, CANCELLED ou EXPIRED).
  Future<void> deleteDonation(String id);

  /// Doador: minhas doações.
  Future<List<Donation>> listMine();

  /// Instituição aprovada: doações disponíveis das categorias que aceita,
  /// dentro do raio e por proximidade. [latitude]/[longitude] = GPS do aparelho.
  Future<List<Donation>> listAvailable({
    String? categoryId,
    double radiusKm = 50,
    double? latitude,
    double? longitude,
  });

  /// Instituição: doações que reservei ou recebi.
  Future<List<Donation>> listRequested();

  Future<Donation> getById(String id);

  /// Doador: anexa uma foto à doação (JPEG/PNG/WebP, até 5 MB, máx. 5 por doação).
  /// Retorna a URL completa da imagem.
  Future<String> uploadPhoto(String donationId, {required List<int> bytes, required String filename});

  /// Doador: remove uma foto (pela URL que a API devolveu).
  Future<void> deletePhoto(String donationId, String photoUrl);

  /// Instituição: reserva a doação (máximo de 5 ativas).
  Future<Donation> requestDonation(String id);

  /// Doador: cancela a doação (AVAILABLE ou RESERVED).
  Future<Donation> cancelDonation(String id);

  /// Instituição que reservou: confirma o recebimento (gera item de estoque).
  Future<Donation> confirmDelivery(String id);
}
