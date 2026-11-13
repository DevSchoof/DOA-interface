import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/async_loader.dart';
import '../core/format.dart';
import '../core/responsive.dart';
import '../core/state_views.dart';
import '../core/validators.dart';
import '../models/models.dart';
import '../providers/auth_provider.dart';
import '../providers/profile_provider.dart';
import '../services/api_exception.dart';
import '../services/donor_service.dart';
import '../services/category_service.dart';
import '../services/institution_service.dart';
import '../services/location_service.dart';
import '../widgets/category_chips.dart';
import '../widgets/location_field.dart';
import '../widgets/pill.dart';

/// Cadastro complementar (PB-004 para doador; instituição fica em análise).
/// Se o perfil já existe, mostra os dados em modo leitura e permite editar.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _editing = false;

  void _setEditing(bool value) => setState(() => _editing = value);

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final role = user?.role;
    final profile = context.watch<ProfileProvider>();

    final Widget body;
    if (profile.isLoading) {
      body = const Center(child: CircularProgressIndicator());
    } else if (profile.donor != null) {
      body = _editing
          ? _DonorEditForm(
              donor: profile.donor!,
              onDone: () => _setEditing(false),
            )
          : _DonorSummary(
              donor: profile.donor!,
              email: user?.email,
              onEdit: () => _setEditing(true),
            );
    } else if (profile.institution != null) {
      body = _editing
          ? _InstitutionEditForm(
              institution: profile.institution!,
              onDone: () => _setEditing(false),
            )
          : _InstitutionSummary(
              institution: profile.institution!,
              email: user?.email,
              onEdit: () => _setEditing(true),
            );
    } else if (role == UserRole.institution) {
      final categories = context.read<CategoryService>();
      body = AsyncLoader<List<FoodCategory>>(
        load: categories.list,
        builder: (context, list, _) => _InstitutionForm(categories: list),
      );
    } else if (role == UserRole.donor) {
      body = const _DonorForm();
    } else {
      body = const EmptyState(
        icon: Icons.person_outline,
        message: 'Este perfil não precisa de cadastro complementar.',
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_editing ? 'Editar cadastro' : 'Meu cadastro'),
        leading: _editing
            ? IconButton(
                icon: const Icon(Icons.close),
                tooltip: 'Cancelar edição',
                onPressed: () => _setEditing(false),
              )
            : null,
      ),
      body: ContentWidth(maxWidth: 600, child: body),
    );
  }
}

// ---------- formulários ----------

class _DonorForm extends StatefulWidget {
  const _DonorForm();

  @override
  State<_DonorForm> createState() => _DonorFormState();
}

class _DonorFormState extends State<_DonorForm> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _document = TextEditingController();
  final _phone = TextEditingController();
  final _address = TextEditingController();
  final _city = TextEditingController();
  PersonType _type = PersonType.individual;
  bool _loading = false;
  String? _error;
  GeoPoint? _point;

  bool get _isCompany => _type == PersonType.company;

  @override
  void dispose() {
    for (final c in [_name, _document, _phone, _address, _city]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final service = context.read<DonorService>();
    final profile = context.read<ProfileProvider>();
    final userId = context.read<AuthProvider>().user!.id;

    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await service.registerDonor(
        userId: userId,
        personType: _type,
        name: _name.text.trim(),
        document: onlyDigits(_document.text),
        phone: onlyDigits(_phone.text),
        address: _address.text.trim(),
        city: _city.text.trim(),
        latitude: _point?.latitude,
        longitude: _point?.longitude,
      );
      await profile.refresh();
      if (!mounted) return;
      showSnack(context, 'Cadastro concluído. Você já pode doar!');
      context.go('/home');
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (_) {
      if (mounted) setState(() => _error = 'Não foi possível salvar. Tente novamente.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    padding: const EdgeInsets.all(24),
    child: Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SegmentedButton<PersonType>(
            segments: const [
              ButtonSegment(
                value: PersonType.individual,
                icon: Icon(Icons.person),
                label: Text('Pessoa física'),
              ),
              ButtonSegment(
                value: PersonType.company,
                icon: Icon(Icons.business),
                label: Text('Empresa'),
              ),
            ],
            selected: {_type},
            onSelectionChanged: (s) => setState(() {
              _type = s.first;
              _document.clear();
            }),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _name,
            textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(
              labelText: _isCompany ? 'Razão social' : 'Nome completo',
            ),
            validator: (v) => validateRequired(v, 'Informe o nome.'),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _document,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: _isCompany ? 'CNPJ' : 'CPF',
              helperText: 'Somente números',
            ),
            validator: (v) {
              final digits = onlyDigits(v ?? '');
              if (digits.isEmpty) return 'Informe o documento.';
              final ok = _isCompany ? isValidCnpj(digits) : isValidCpf(digits);
              return ok ? null : (_isCompany ? 'CNPJ inválido.' : 'CPF inválido.');
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _phone,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(labelText: 'Telefone (com DDD)'),
            validator: (v) {
              final digits = onlyDigits(v ?? '');
              return (digits.length == 10 || digits.length == 11)
                  ? null
                  : 'Informe DDD + número.';
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _address,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(labelText: 'Endereço'),
            validator: (v) => validateRequired(v, 'Informe o endereço.'),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _city,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(labelText: 'Cidade'),
            validator: (v) => validateRequired(v, 'Informe a cidade.'),
          ),
          const SizedBox(height: 16),
          LocationField(onChanged: (p) => _point = p),
          if (_error != null) ...[
            const SizedBox(height: 16),
            Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ],
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _loading ? null : _submit,
            child: _loading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Salvar cadastro'),
          ),
        ],
      ),
    ),
  );
}

class _InstitutionForm extends StatefulWidget {
  final List<FoodCategory> categories;
  const _InstitutionForm({required this.categories});

  @override
  State<_InstitutionForm> createState() => _InstitutionFormState();
}

class _InstitutionFormState extends State<_InstitutionForm> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _cnpj = TextEditingController();
  final _address = TextEditingController();
  final _city = TextEditingController();
  final _area = TextEditingController();
  final _capacity = TextEditingController();
  bool _loading = false;
  String? _error;
  GeoPoint? _point;
  Set<String> _categoryIds = {};

  @override
  void dispose() {
    for (final c in [_name, _cnpj, _address, _city, _area, _capacity]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_categoryIds.isEmpty) {
      setState(() => _error = 'Escolha ao menos uma categoria de alimento.');
      return;
    }
    final service = context.read<InstitutionService>();
    final profile = context.read<ProfileProvider>();

    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await service.registerInstitution(
        name: _name.text.trim(),
        cnpj: onlyDigits(_cnpj.text),
        address: _address.text.trim(),
        city: _city.text.trim(),
        areaOfActivity: _area.text.trim(),
        storageCapacityKg: double.parse(_capacity.text.replaceAll(',', '.')),
        categoryIds: _categoryIds.toList(),
        latitude: _point?.latitude,
        longitude: _point?.longitude,
      );
      await profile.refresh();
      if (!mounted) return;
      showSnack(context, 'Cadastro enviado para análise.');
      context.go('/home');
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (_) {
      if (mounted) setState(() => _error = 'Não foi possível enviar. Tente novamente.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    padding: const EdgeInsets.all(24),
    child: Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            controller: _name,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(labelText: 'Nome da instituição'),
            validator: (v) => validateRequired(v, 'Informe o nome.'),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _cnpj,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'CNPJ',
              helperText: 'Somente números',
            ),
            validator: (v) {
              final digits = onlyDigits(v ?? '');
              if (digits.isEmpty) return 'Informe o CNPJ.';
              return isValidCnpj(digits) ? null : 'CNPJ inválido.';
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _address,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(labelText: 'Endereço'),
            validator: (v) => validateRequired(v, 'Informe o endereço.'),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _city,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(labelText: 'Cidade'),
            validator: (v) => validateRequired(v, 'Informe a cidade.'),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _area,
            decoration: const InputDecoration(
              labelText: 'Área de atuação',
              helperText: 'Ex.: cestas básicas, refeições comunitárias',
            ),
            validator: (v) => validateRequired(v, 'Informe a área de atuação.'),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _capacity,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Capacidade de armazenamento (kg)',
            ),
            validator: (v) {
              final value = double.tryParse((v ?? '').replaceAll(',', '.'));
              return (value == null || value <= 0)
                  ? 'Informe uma capacidade válida.'
                  : null;
            },
          ),
          const SizedBox(height: 20),
          Text(
            'Categorias de alimento que a instituição aceita',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 8),
          CategoryChips(
            categories: widget.categories,
            selected: _categoryIds,
            onChanged: (ids) => setState(() => _categoryIds = ids),
          ),
          const SizedBox(height: 20),
          LocationField(onChanged: (p) => _point = p),
          if (_error != null) ...[
            const SizedBox(height: 16),
            Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ],
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _loading ? null : _submit,
            child: _loading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Enviar para análise'),
          ),
        ],
      ),
    ),
  );
}

// ---------- edição ----------

Widget _saveButton(bool loading, VoidCallback onPressed, String label) =>
    FilledButton(
      onPressed: loading ? null : onPressed,
      child: loading
          ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Text(label),
    );

class _DonorEditForm extends StatefulWidget {
  final Donor donor;
  final VoidCallback onDone;
  const _DonorEditForm({required this.donor, required this.onDone});

  @override
  State<_DonorEditForm> createState() => _DonorEditFormState();
}

class _DonorEditFormState extends State<_DonorEditForm> {
  final _formKey = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.donor.name);
  late final _phone = TextEditingController(text: widget.donor.phone);
  late final _address = TextEditingController(text: widget.donor.address);
  late final _city = TextEditingController(text: widget.donor.city);
  GeoPoint? _point;
  bool _loading = false;
  String? _error;

  bool get _isCompany => widget.donor.personType == PersonType.company;

  @override
  void dispose() {
    for (final c in [_name, _phone, _address, _city]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final service = context.read<DonorService>();
    final profile = context.read<ProfileProvider>();
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await service.updateMine(
        name: _name.text.trim(),
        phone: onlyDigits(_phone.text),
        address: _address.text.trim(),
        city: _city.text.trim(),
        // mantém a localização anterior se o usuário não capturou outra
        latitude: _point?.latitude ?? widget.donor.latitude,
        longitude: _point?.longitude ?? widget.donor.longitude,
      );
      if (!mounted) return;
      // Sai do modo edição antes do refresh: ele recarrega o perfil e
      // desmonta este formulário.
      widget.onDone();
      showSnack(context, 'Cadastro atualizado.');
      await profile.refresh();
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (_) {
      if (mounted) setState(() => _error = 'Não foi possível salvar. Tente novamente.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    padding: const EdgeInsets.all(24),
    child: Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'O tipo de pessoa e o documento não podem ser alterados.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 16),
          TextFormField(
            initialValue:
                '${_isCompany ? 'CNPJ' : 'CPF'}: ${formatDocument(widget.donor.document ?? '')}',
            enabled: false,
            decoration: const InputDecoration(labelText: 'Documento'),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _name,
            textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(
              labelText: _isCompany ? 'Razão social' : 'Nome completo',
            ),
            validator: (v) => validateRequired(v, 'Informe o nome.'),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _phone,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(labelText: 'Telefone (com DDD)'),
            validator: (v) {
              final digits = onlyDigits(v ?? '');
              return (digits.length == 10 || digits.length == 11)
                  ? null
                  : 'Informe DDD + número.';
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _address,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(labelText: 'Endereço'),
            validator: (v) => validateRequired(v, 'Informe o endereço.'),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _city,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(labelText: 'Cidade'),
            validator: (v) => validateRequired(v, 'Informe a cidade.'),
          ),
          const SizedBox(height: 16),
          LocationField(onChanged: (p) => _point = p),
          if (_error != null) ...[
            const SizedBox(height: 16),
            Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ],
          const SizedBox(height: 24),
          _saveButton(_loading, _submit, 'Salvar alterações'),
          const SizedBox(height: 8),
          TextButton(
            onPressed: _loading ? null : widget.onDone,
            child: const Text('Cancelar'),
          ),
        ],
      ),
    ),
  );
}

class _InstitutionEditForm extends StatefulWidget {
  final Institution institution;
  final VoidCallback onDone;
  const _InstitutionEditForm({required this.institution, required this.onDone});

  @override
  State<_InstitutionEditForm> createState() => _InstitutionEditFormState();
}

class _InstitutionEditFormState extends State<_InstitutionEditForm> {
  final _formKey = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.institution.name);
  late final _address = TextEditingController(text: widget.institution.address);
  late final _city = TextEditingController(text: widget.institution.city);
  late final _area = TextEditingController(text: widget.institution.areaOfActivity);
  late final _capacity = TextEditingController(
    text: widget.institution.storageCapacityKg.toString().replaceAll('.', ','),
  );
  GeoPoint? _point;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    for (final c in [_name, _address, _city, _area, _capacity]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final service = context.read<InstitutionService>();
    final profile = context.read<ProfileProvider>();
    final wasRejected = widget.institution.status == InstitutionStatus.rejected;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await service.updateMine(
        name: _name.text.trim(),
        address: _address.text.trim(),
        city: _city.text.trim(),
        areaOfActivity: _area.text.trim(),
        storageCapacityKg: double.parse(_capacity.text.replaceAll(',', '.')),
        latitude: _point?.latitude ?? widget.institution.latitude,
        longitude: _point?.longitude ?? widget.institution.longitude,
      );
      if (!mounted) return;
      widget.onDone();
      showSnack(
        context,
        wasRejected ? 'Cadastro reenviado para análise.' : 'Cadastro atualizado.',
      );
      await profile.refresh();
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (_) {
      if (mounted) setState(() => _error = 'Não foi possível salvar. Tente novamente.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    padding: const EdgeInsets.all(24),
    child: Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'O CNPJ não pode ser alterado. As categorias aceitas são editadas na tela anterior.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 16),
          TextFormField(
            initialValue: 'CNPJ: ${formatDocument(widget.institution.cnpj)}',
            enabled: false,
            decoration: const InputDecoration(labelText: 'CNPJ'),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _name,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(labelText: 'Nome da instituição'),
            validator: (v) => validateRequired(v, 'Informe o nome.'),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _address,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(labelText: 'Endereço'),
            validator: (v) => validateRequired(v, 'Informe o endereço.'),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _city,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(labelText: 'Cidade'),
            validator: (v) => validateRequired(v, 'Informe a cidade.'),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _area,
            decoration: const InputDecoration(labelText: 'Área de atuação'),
            validator: (v) => validateRequired(v, 'Informe a área de atuação.'),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _capacity,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Capacidade de armazenamento (kg)',
            ),
            validator: (v) {
              final value = double.tryParse((v ?? '').replaceAll(',', '.'));
              return (value == null || value <= 0)
                  ? 'Informe uma capacidade válida.'
                  : null;
            },
          ),
          const SizedBox(height: 16),
          LocationField(onChanged: (p) => _point = p),
          if (_error != null) ...[
            const SizedBox(height: 16),
            Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ],
          const SizedBox(height: 24),
          _saveButton(
            _loading,
            _submit,
            widget.institution.status == InstitutionStatus.rejected
                ? 'Salvar e reenviar para análise'
                : 'Salvar alterações',
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: _loading ? null : widget.onDone,
            child: const Text('Cancelar'),
          ),
        ],
      ),
    ),
  );
}

// ---------- modo leitura ----------

class _Row extends StatelessWidget {
  final String label;
  final String value;
  const _Row(this.label, this.value);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 130,
          child: Text(label, style: Theme.of(context).textTheme.bodySmall),
        ),
        Expanded(child: Text(value)),
      ],
    ),
  );
}

class _DonorSummary extends StatelessWidget {
  final Donor donor;
  final String? email;
  final VoidCallback onEdit;
  const _DonorSummary({required this.donor, this.email, required this.onEdit});

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(24),
    children: [
      Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _Row(
                'Tipo',
                donor.personType == PersonType.company
                    ? 'Pessoa jurídica'
                    : 'Pessoa física',
              ),
              if (email != null) _Row('E-mail', email!),
              _Row('Nome', donor.name),
              _Row('Documento', formatDocument(donor.document ?? '')),
              _Row('Telefone', donor.phone),
              _Row('Endereço', donor.address),
              _Row('Cidade', donor.city),
            ],
          ),
        ),
      ),
      const SizedBox(height: 12),
      FilledButton.icon(
        onPressed: onEdit,
        icon: const Icon(Icons.edit),
        label: const Text('Editar cadastro'),
      ),
    ],
  );
}

class _InstitutionSummary extends StatelessWidget {
  final Institution institution;
  final String? email;
  final VoidCallback onEdit;
  const _InstitutionSummary({
    required this.institution,
    this.email,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(24),
    children: [
      Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: InstitutionStatusPill(institution.status),
              ),
              const SizedBox(height: 8),
              if (email != null) _Row('E-mail', email!),
              _Row('Nome', institution.name),
              _Row('CNPJ', formatDocument(institution.cnpj)),
              _Row('Endereço', institution.address),
              _Row('Cidade', institution.city),
              _Row('Área de atuação', institution.areaOfActivity),
              _Row(
                'Capacidade',
                formatQuantity(institution.storageCapacityKg, 'kg'),
              ),
              _Row(
                'Categorias aceitas',
                institution.categories.map((c) => c.name).join(', '),
              ),
              if (institution.rejectionReason != null)
                _Row('Justificativa', institution.rejectionReason!),
            ],
          ),
        ),
      ),
      const SizedBox(height: 12),
      FilledButton.icon(
        onPressed: onEdit,
        icon: const Icon(Icons.edit),
        label: Text(
          institution.status == InstitutionStatus.rejected
              ? 'Corrigir e reenviar para análise'
              : 'Editar cadastro',
        ),
      ),
      const SizedBox(height: 8),
      OutlinedButton.icon(
        onPressed: () => showDialog<void>(
          context: context,
          builder: (_) => _CategoriesDialog(institution: institution),
        ),
        icon: const Icon(Icons.tune),
        label: const Text('Alterar categorias aceitas'),
      ),
    ],
  );
}

/// Altera o conjunto de categorias que a instituição aceita (lado N:N).
class _CategoriesDialog extends StatefulWidget {
  final Institution institution;
  const _CategoriesDialog({required this.institution});

  @override
  State<_CategoriesDialog> createState() => _CategoriesDialogState();
}

class _CategoriesDialogState extends State<_CategoriesDialog> {
  late Set<String> _selected = widget.institution.categories.map((c) => c.id).toSet();
  bool _saving = false;

  Future<void> _save() async {
    if (_selected.isEmpty) {
      showSnack(context, 'A instituição precisa aceitar ao menos uma categoria.');
      return;
    }
    final service = context.read<InstitutionService>();
    final profile = context.read<ProfileProvider>();
    final navigator = Navigator.of(context);

    setState(() => _saving = true);
    try {
      await service.updateCategories(_selected.toList());
      await profile.refresh();
      navigator.pop();
    } on ApiException catch (e) {
      if (mounted) showSnack(context, e.message);
    } catch (_) {
      if (mounted) showSnack(context, 'Não foi possível salvar. Tente novamente.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final service = context.read<CategoryService>();
    return AlertDialog(
      title: const Text('Categorias aceitas'),
      content: SizedBox(
        width: 420,
        child: AsyncLoader<List<FoodCategory>>(
          load: service.list,
          builder: (context, list, _) => SingleChildScrollView(
            child: CategoryChips(
              categories: list,
              selected: _selected,
              onChanged: (ids) => setState(() => _selected = ids),
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(),
          child: const Text('Voltar'),
        ),
        FilledButton(
          onPressed: _saving ? null : _save,
          child: const Text('Salvar'),
        ),
      ],
    );
  }
}
