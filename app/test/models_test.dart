import 'package:doa_interface/models/models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Institution.fromJson lê as categorias aceitas (N:N)', () {
    final i = Institution.fromJson({
      'id': 1,
      'userId': 3,
      'name': 'Casa Esperança',
      'cnpj': '11222333000181',
      'address': 'Av. Brasil, 500',
      'city': 'Bragança Paulista',
      'areaOfActivity': 'Cestas básicas',
      'storageCapacityKg': 800,
      'status': 'APPROVED',
      'rejectionReason': null,
      'latitude': -22.94,
      'longitude': -46.53,
      'categories': [
        {'id': 1, 'name': 'Frutas'},
        {'id': 2, 'name': 'Padaria'},
      ],
    });

    expect(i.status, InstitutionStatus.approved);
    expect(i.categories.map((c) => c.name), ['Frutas', 'Padaria']);
    expect(i.latitude, -22.94);
  });

  test('StockItem avisa ao atingir 80% da validade', () {
    final now = DateTime.now();
    final nearExpiry = StockItem(
      id: '1',
      categoryName: 'Grãos',
      description: 'Feijão',
      quantity: 10,
      unit: 'kg',
      receivedAt: now.subtract(const Duration(days: 9)),
      expiresAt: now.add(const Duration(days: 1)),
    );
    final fresh = StockItem(
      id: '2',
      categoryName: 'Grãos',
      description: 'Arroz',
      quantity: 10,
      unit: 'kg',
      receivedAt: now.subtract(const Duration(days: 1)),
      expiresAt: now.add(const Duration(days: 99)),
    );

    expect(nearExpiry.isNearExpiry, isTrue);
    expect(fresh.isNearExpiry, isFalse);
  });

  test('ChatMessage.fromJson serve para a API e para o evento do WebSocket', () {
    final m = ChatMessage.fromJson({
      'type': 'chat',
      'id': 5,
      'donationId': 8,
      'senderUserId': 2,
      'senderName': 'Maria Silva',
      'content': 'Olá!',
      'sentAt': '2026-10-25T11:00:00',
    });

    expect(m.donationId, '8');
    expect(m.senderUserId, '2');
  });
}
