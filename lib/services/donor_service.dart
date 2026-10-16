import '../models/models.dart';

abstract class DonorService {
  /// PB-004: cadastro de doador pessoa física ou jurídica.
  Future<Donor> registerDonor({
    required String userId,
    required PersonType personType,
    required String name,
    required String document,
    required String phone,
    required String address,
    required String city,
  });
}
