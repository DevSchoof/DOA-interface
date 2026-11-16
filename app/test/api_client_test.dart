import 'dart:convert';

import 'package:doa_interface/core/api_client.dart';
import 'package:doa_interface/models/models.dart';
import 'package:doa_interface/services/api_exception.dart';
import 'package:doa_interface/services/http/http_donation_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

http.Response _json(Object body, [int status = 200]) => http.Response.bytes(
  utf8.encode(jsonEncode(body)),
  status,
  headers: {'content-type': 'application/json'}, // sem charset, como o Spring envia
);

ApiClient _client(
  Future<http.Response> Function(http.Request) handler, {
  String? token,
  void Function()? onUnauthorized,
}) => ApiClient(
  baseUrl: 'http://api.test',
  tokenProvider: () => token,
  onUnauthorized: onUnauthorized,
  client: MockClient(handler),
);

void main() {
  group('ApiClient', () {
    test('envia o token no cabeçalho Authorization', () async {
      http.Request? sent;
      final api = _client((r) async {
        sent = r;
        return _json({'ok': true});
      }, token: 'abc');

      await api.get('/api/users/me');

      expect(sent!.headers['Authorization'], 'Bearer abc');
      expect(sent!.url.toString(), 'http://api.test/api/users/me');
    });

    test('ignora parâmetros nulos na query', () async {
      http.Request? sent;
      final api = _client((r) async {
        sent = r;
        return _json([]);
      });

      await api.get('/api/donations', query: {'radiusKm': 50, 'categoryId': null});

      expect(sent!.url.queryParameters, {'radiusKm': '50'});
    });

    test('traduz {message} da API e preserva acentos', () async {
      final api = _client((_) async => _json({'message': 'Já existe um usuário com este e-mail.'}, 409));

      expect(
        api.post('/api/auth/register', body: {}),
        throwsA(
          isA<ApiException>()
              .having((e) => e.message, 'message', 'Já existe um usuário com este e-mail.')
              .having((e) => e.statusCode, 'statusCode', 409),
        ),
      );
    });

    test('401 em rota protegida avisa a sessão expirada', () async {
      var called = 0;
      final api = _client((_) async => _json({'message': 'x'}, 401), onUnauthorized: () => called++);

      await expectLater(api.get('/api/donations/mine'), throwsA(isA<ApiException>()));
      expect(called, 1);
    });

    test('401 no login não é sessão expirada', () async {
      var called = 0;
      final api = _client((_) async => _json({'message': 'E-mail ou senha inválidos.'}, 401),
          onUnauthorized: () => called++);

      await expectLater(api.postPublic('/api/auth/login', body: {}), throwsA(isA<ApiException>()));
      expect(called, 0);
    });

    test('falha de conexão vira mensagem amigável', () async {
      final api = _client((_) async => throw http.ClientException('sem rede'));

      expect(
        api.get('/api/impact'),
        throwsA(isA<ApiException>().having((e) => e.message, 'message', contains('conectar'))),
      );
    });

    test('204 sem corpo devolve null', () async {
      final api = _client((_) async => http.Response('', 204));
      expect(await api.delete('/api/donations/1'), isNull);
    });
  });

  group('HttpDonationService', () {
    final donationJson = {
      'id': 10,
      'donorId': 1,
      'donorName': 'Maria Silva',
      'categoryId': 1,
      'categoryName': 'Frutas',
      'description': 'Laranjas',
      'quantity': 10.0,
      'unit': 'kg',
      'expiresAt': DateTime.now().add(const Duration(days: 2)).toIso8601String().substring(0, 10),
      'storageConditions': 'Ambiente',
      'status': 'AVAILABLE',
      'reservedById': null,
      'reservedByName': null,
      'reservedAt': null,
      'createdAt': '2026-10-25T09:30:00',
      'city': 'Bragança Paulista',
      'distanceKm': 3.1,
    };

    test('cria doação enviando categoryId numérico e data yyyy-MM-dd', () async {
      Map<String, dynamic>? body;
      final service = HttpDonationService(_client((r) async {
        body = jsonDecode(r.body) as Map<String, dynamic>;
        return _json(donationJson, 201);
      }));

      final donation = await service.createDonation(
        categoryId: '1',
        description: 'Laranjas',
        quantity: 10,
        unit: 'kg',
        expiresAt: DateTime(2026, 11, 2),
      );

      expect(body!['categoryId'], 1);
      expect(body!['expiresAt'], '2026-11-02');
      expect(donation.id, '10');
      expect(donation.categoryName, 'Frutas');
      expect(donation.distanceKm, 3.1);
      expect(donation.isPriority, isTrue); // vence em 2 dias
    });

    test('lista disponíveis com GPS e categoria na query', () async {
      Uri? url;
      final service = HttpDonationService(_client((r) async {
        url = r.url;
        return _json([donationJson]);
      }));

      final list = await service.listAvailable(
        categoryId: '3',
        radiusKm: 30,
        latitude: -22.95,
        longitude: -46.54,
      );

      expect(list, hasLength(1));
      expect(url!.queryParameters, {
        'categoryId': '3',
        'radiusKm': '30.0',
        'lat': '-22.95',
        'lng': '-46.54',
      });
    });

    test('envia a foto como multipart e devolve a URL completa', () async {
      http.Request? sent;
      final service = HttpDonationService(_client((r) async {
        sent = r;
        return _json({'url': '/api/photos/abc-123'}, 201);
      }, token: 't'));

      final url = await service.uploadPhoto(
        '10',
        bytes: [1, 2, 3],
        filename: 'foto.jpg',
      );

      expect(sent!.method, 'POST');
      expect(sent!.url.path, '/api/donations/10/photos');
      expect(sent!.headers['content-type'], startsWith('multipart/form-data'));
      expect(sent!.headers['Authorization'], 'Bearer t');
      expect(url, 'http://api.test/api/photos/abc-123');
    });

    test('doação traz as URLs das fotos completas', () {
      final d = Donation.fromJson({
        ...donationJson,
        'photoUrls': ['/api/photos/a', 'http://cdn/x.png'],
      });
      expect(d.photoUrls.first, endsWith('/api/photos/a'));
      expect(d.photoUrls.first, startsWith('http'));
      expect(d.photoUrls.last, 'http://cdn/x.png');
    });

    test('apaga foto pelo id no fim da URL', () async {
      http.Request? sent;
      final service = HttpDonationService(_client((r) async {
        sent = r;
        return http.Response('', 204);
      }));
      await service.deletePhoto('10', 'http://api.test/api/photos/abc-123');
      expect(sent!.method, 'DELETE');
      expect(sent!.url.path, '/api/donations/10/photos/abc-123');
    });
  });
}
