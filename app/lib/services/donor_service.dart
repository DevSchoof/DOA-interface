import '../models/models.dart';

abstract class DonorService {
  /// PB-004: cadastro de doador pessoa física ou jurídica.
  /// Na API real o doador é o usuário do token; `userId` é ignorado.
  Future<Donor> registerDonor({
    required String userId,
    required PersonType personType,
    required String name,
    required String document,
    required String phone,
    required String address,
    required String city,
    double? latitude,
    double? longitude,
  });

  /// Perfil de doador do usuário logado, ou null se ainda não completou.
  Future<Donor?> getMine();

  /// Atualiza os dados editáveis do doador logado (tipo e documento não mudam).
  Future<Donor> updateMine({
    required String name,
    required String phone,
    required String address,
    required String city,
    double? latitude,
    double? longitude,
  });
}
