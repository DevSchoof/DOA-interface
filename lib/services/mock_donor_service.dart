import '../models/models.dart';
import 'auth_service.dart';
import 'donor_service.dart';

class MockDonorService implements DonorService {
  final List<Donor> _donors = [];

  @override
  Future<Donor> registerDonor({
    required String userId,
    required PersonType personType,
    required String name,
    required String document,
    required String phone,
    required String address,
    required String city,
  }) async {
    await Future.delayed(const Duration(milliseconds: 500));

    if (personType == PersonType.unknown) {
      throw const AuthException('Selecione pessoa física ou jurídica.');
    }
    if (_donors.any((d) => d.document == document)) {
      throw const AuthException('Este documento já está cadastrado.');
    }

    final donor = Donor(
      id: 'd${_donors.length + 1}',
      userId: userId,
      personType: personType,
      name: name,
      document: document,
      phone: phone,
      address: address,
      city: city,
    );
    _donors.add(donor);
    return donor;
  }
}
