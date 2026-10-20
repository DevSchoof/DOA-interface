import 'package:doa_interface/models/models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final json = {
    'id': 7,
    'userId': 3,
    'name': 'ONG Esperança',
    'cnpj': '11222333000181',
    'phone': '11999998888',
    'address': 'Rua A, 10',
    'city': 'São Paulo',
    'latitude': -23.55,
    'longitude': -46.63,
    'storageCapacity': 500,
    'status': 'APPROVED',
  };

  test('fromJson converte ids numéricos, capacidade e status', () {
    final i = Institution.fromJson(json);
    expect(i.id, '7');
    expect(i.userId, '3');
    expect(i.storageCapacity, 500.0);
    expect(i.status, InstitutionStatus.approved);
    expect(i.isApproved, isTrue);
  });

  test('status desconhecido ou ausente vira unknown', () {
    expect(
      Institution.fromJson({...json, 'status': 'EM_ANALISE'}).status,
      InstitutionStatus.unknown,
    );
    expect(
      Institution.fromJson({...json, 'status': null}).status,
      InstitutionStatus.unknown,
    );
  });

  test('toJson usa camelCase e enum em maiúsculas', () {
    final map = Institution.fromJson(json).toJson();
    expect(map['status'], 'APPROVED');
    expect(map['userId'], '3');
    expect(map['storageCapacity'], 500.0);
  });
}
