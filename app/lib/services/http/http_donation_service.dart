import '../../core/api_client.dart';
import '../../core/format.dart';
import '../../models/models.dart';
import '../donation_service.dart';

class HttpDonationService implements DonationService {
  final ApiClient _api;
  HttpDonationService(this._api);

  Donation _one(dynamic json) => Donation.fromJson(json as Map<String, dynamic>);
  List<Donation> _list(dynamic json) => (json as List).map(_one).toList();

  Map<String, Object?> _body({
    required String categoryId,
    required String description,
    required double quantity,
    required String unit,
    required DateTime expiresAt,
    String? storageConditions,
  }) => {
    'categoryId': int.parse(categoryId),
    'description': description,
    'quantity': quantity,
    'unit': unit,
    'expiresAt': toApiDate(expiresAt),
    'storageConditions': storageConditions,
  };

  @override
  Future<Donation> createDonation({
    required String categoryId,
    required String description,
    required double quantity,
    required String unit,
    required DateTime expiresAt,
    String? storageConditions,
  }) async => _one(
    await _api.post(
      '/api/donations',
      body: _body(
        categoryId: categoryId,
        description: description,
        quantity: quantity,
        unit: unit,
        expiresAt: expiresAt,
        storageConditions: storageConditions,
      ),
    ),
  );

  @override
  Future<Donation> updateDonation(
    String id, {
    required String categoryId,
    required String description,
    required double quantity,
    required String unit,
    required DateTime expiresAt,
    String? storageConditions,
  }) async => _one(
    await _api.put(
      '/api/donations/$id',
      body: _body(
        categoryId: categoryId,
        description: description,
        quantity: quantity,
        unit: unit,
        expiresAt: expiresAt,
        storageConditions: storageConditions,
      ),
    ),
  );

  @override
  Future<void> deleteDonation(String id) async {
    await _api.delete('/api/donations/$id');
  }

  @override
  Future<List<Donation>> listMine() async =>
      _list(await _api.get('/api/donations/mine'));

  @override
  Future<List<Donation>> listAvailable({
    String? categoryId,
    double radiusKm = 50,
    double? latitude,
    double? longitude,
  }) async => _list(
    await _api.get(
      '/api/donations',
      query: {
        'categoryId': categoryId,
        'radiusKm': radiusKm,
        'lat': latitude,
        'lng': longitude,
      },
    ),
  );

  @override
  Future<List<Donation>> listRequested() async =>
      _list(await _api.get('/api/donations/requested'));

  @override
  Future<Donation> getById(String id) async =>
      _one(await _api.get('/api/donations/$id'));

  @override
  Future<String> uploadPhoto(
    String donationId, {
    required List<int> bytes,
    required String filename,
  }) async {
    final json = await _api.upload(
      '/api/donations/$donationId/photos',
      bytes: bytes,
      filename: filename,
    );
    final url = (json as Map<String, dynamic>)['url'].toString();
    return url.startsWith('http') ? url : '${_api.baseUrl}$url';
  }

  @override
  Future<void> deletePhoto(String donationId, String photoUrl) async {
    final photoId = photoUrl.substring(photoUrl.lastIndexOf('/') + 1);
    await _api.delete('/api/donations/$donationId/photos/$photoId');
  }

  @override
  Future<Donation> requestDonation(String id) async =>
      _one(await _api.post('/api/donations/$id/request'));

  @override
  Future<Donation> cancelDonation(String id) async =>
      _one(await _api.put('/api/donations/$id/cancel'));

  @override
  Future<Donation> confirmDelivery(String id) async =>
      _one(await _api.post('/api/donations/$id/confirm-delivery'));
}
