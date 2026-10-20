import 'package:doa_interface/models/models.dart';
import 'package:doa_interface/services/auth_service.dart';
import 'package:doa_interface/services/mock_institution_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late MockInstitutionService service;

  setUp(() => service = MockInstitutionService());

  test('lista apenas pendentes quando filtrado', () async {
    final pending = await service.listByStatus(InstitutionStatus.pending);
    expect(pending, isNotEmpty);
    expect(pending.every((i) => i.status == InstitutionStatus.pending), isTrue);
  });

  test('sem filtro lista todas', () async {
    final all = await service.listByStatus(null);
    expect(all.length, 4);
  });

  test('aprovar tira a instituição da lista de pendentes', () async {
    final before = await service.listByStatus(InstitutionStatus.pending);
    final updated = await service.updateStatus(
      before.first.id,
      InstitutionStatus.approved,
    );
    final after = await service.listByStatus(InstitutionStatus.pending);

    expect(updated.status, InstitutionStatus.approved);
    expect(after.length, before.length - 1);
  });

  test('não homologa instituição que não está pendente', () async {
    final approved = await service.listByStatus(InstitutionStatus.approved);
    expect(
      service.updateStatus(approved.first.id, InstitutionStatus.rejected),
      throwsA(isA<AuthException>()),
    );
  });

  test('rejeita status inválido e id inexistente', () async {
    expect(
      service.updateStatus('s1', InstitutionStatus.suspended),
      throwsA(isA<AuthException>()),
    );
    expect(
      service.updateStatus('nao-existe', InstitutionStatus.approved),
      throwsA(isA<AuthException>()),
    );
  });
}
