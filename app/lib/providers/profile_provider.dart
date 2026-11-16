import 'package:flutter/foundation.dart';

import '../models/models.dart';
import '../services/donor_service.dart';
import '../services/institution_service.dart';

/// Guarda o perfil (doador ou instituição) do usuário logado. As telas usam
/// para saber se o cadastro está completo e se a instituição foi aprovada.
class ProfileProvider extends ChangeNotifier {
  final DonorService _donors;
  final InstitutionService _institutions;

  ProfileProvider(this._donors, this._institutions);

  User? _user;
  bool _loading = false;
  Donor? _donor;
  Institution? _institution;

  bool get isLoading => _loading;
  Donor? get donor => _donor;
  Institution? get institution => _institution;

  bool get hasProfile => _donor != null || _institution != null;
  bool get isInstitutionApproved =>
      _institution?.status == InstitutionStatus.approved;

  /// Chamado pelo ProxyProvider sempre que a sessão muda.
  void sync(User? user) {
    if (user?.id == _user?.id) return;
    _user = user;
    _donor = null;
    _institution = null;
    _loading = user != null;
    // Adia a notificação: sync roda durante o build.
    Future.microtask(() {
      if (user == null) {
        notifyListeners();
      } else {
        refresh();
      }
    });
  }

  Future<void> refresh() async {
    final user = _user;
    if (user == null) return;

    _loading = true;
    notifyListeners();
    try {
      Donor? donor;
      Institution? institution;
      if (user.role == UserRole.donor) donor = await _donors.getMine();
      if (user.role == UserRole.institution) {
        institution = await _institutions.getMine();
      }
      if (_user?.id != user.id) return; // trocou de usuário no meio do caminho
      _donor = donor;
      _institution = institution;
    } catch (_) {
      // mantém sem perfil; a tela oferece completar o cadastro
    } finally {
      if (_user?.id == user.id) {
        _loading = false;
        notifyListeners();
      }
    }
  }
}
