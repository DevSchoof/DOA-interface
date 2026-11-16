import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../core/async_loader.dart';
import '../core/format.dart';
import '../core/presentation.dart';
import '../core/responsive.dart';
import '../core/state_views.dart';
import '../core/validators.dart';
import '../models/models.dart';
import '../services/api_exception.dart';
import '../services/category_service.dart';
import '../services/donation_service.dart';
import '../widgets/donation_photos.dart';

class _FormData {
  final List<FoodCategory> categories;
  final Donation? donation;
  const _FormData(this.categories, this.donation);
}

/// CSU03: cadastrar doação. Com [donation] (ou [donationId]), edita uma existente.
class DonationFormScreen extends StatelessWidget {
  final Donation? donation;
  final String? donationId;

  const DonationFormScreen({super.key, this.donation, this.donationId});

  bool get _editing => donation != null || donationId != null;

  @override
  Widget build(BuildContext context) {
    final categories = context.read<CategoryService>();
    final donations = context.read<DonationService>();

    return Scaffold(
      appBar: AppBar(title: Text(_editing ? 'Editar doação' : 'Nova doação')),
      body: ContentWidth(
        maxWidth: 600,
        child: AsyncLoader<_FormData>(
          load: () async {
            final list = await categories.list();
            final current = donation ??
                (donationId != null ? await donations.getById(donationId!) : null);
            return _FormData(list, current);
          },
          builder: (context, data, _) =>
              _DonationForm(categories: data.categories, donation: data.donation),
        ),
      ),
    );
  }
}

class _DonationForm extends StatefulWidget {
  final List<FoodCategory> categories;
  final Donation? donation;
  const _DonationForm({required this.categories, this.donation});

  @override
  State<_DonationForm> createState() => _DonationFormState();
}

class _DonationFormState extends State<_DonationForm> {
  static const _units = ['kg', 'un', 'L'];
  static const _storages = ['Ambiente', 'Refrigerado', 'Congelado'];

  final _formKey = GlobalKey<FormState>();
  late final _description = TextEditingController(text: widget.donation?.description);
  late final _quantity = TextEditingController(
    text: widget.donation == null
        ? ''
        : formatQuantity(widget.donation!.quantity, '').trim().replaceAll(',', '.'),
  );
  late final _date = TextEditingController(
    text: widget.donation == null ? '' : formatDate(widget.donation!.expiresAt),
  );

  late final List<FoodCategory> _categories = _withCurrent();
  late String? _categoryId = widget.donation?.categoryId ??
      (_categories.isEmpty ? null : _categories.first.id);
  late String _unit = widget.donation?.unit ?? 'kg';
  late String _storage = _storages.contains(widget.donation?.storageConditions)
      ? widget.donation!.storageConditions!
      : 'Ambiente';
  late DateTime? _expiresAt = widget.donation?.expiresAt;
  bool _loading = false;
  String? _error;

  static const _maxPhotos = 5;
  final _picker = ImagePicker();

  /// Fotos já salvas na doação (ao editar) e fotos novas, ainda não enviadas.
  late final List<String> _savedPhotos = [...?widget.donation?.photoUrls];
  final List<_PendingPhoto> _newPhotos = [];

  int get _photoCount => _savedPhotos.length + _newPhotos.length;

  bool get _editing => widget.donation != null;

  /// Ao editar, mantém a categoria atual na lista mesmo que tenha sido desativada.
  List<FoodCategory> _withCurrent() {
    final list = [...widget.categories];
    final d = widget.donation;
    if (d != null && !list.any((c) => c.id == d.categoryId)) {
      list.add(FoodCategory(id: d.categoryId, name: d.categoryName));
    }
    return list;
  }

  @override
  void dispose() {
    _description.dispose();
    _quantity.dispose();
    _date.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final initial = _expiresAt != null && !_expiresAt!.isBefore(today)
        ? _expiresAt!
        : today.add(const Duration(days: 3));
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: today,
      lastDate: today.add(const Duration(days: 365 * 3)),
      helpText: 'Validade do alimento',
    );
    if (picked != null && mounted) {
      setState(() {
        _expiresAt = picked;
        _date.text = formatDate(picked);
      });
    }
  }

  Future<void> _addPhoto() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Tirar foto'),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Escolher da galeria'),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source == null) return;
    try {
      // maxWidth/imageQuality reduzem o arquivo (fotos de câmera passam de 5 MB)
      final file = await _picker.pickImage(
        source: source,
        maxWidth: 1600,
        imageQuality: 80,
      );
      if (file == null) return;
      final bytes = await file.readAsBytes();
      if (mounted) setState(() => _newPhotos.add(_PendingPhoto(file.name, bytes)));
    } catch (_) {
      if (mounted) showSnack(context, 'Não foi possível acessar a câmera ou a galeria.');
    }
  }

  Future<void> _removeSaved(String url) async {
    final service = context.read<DonationService>();
    try {
      await service.deletePhoto(widget.donation!.id, url);
      if (mounted) setState(() => _savedPhotos.remove(url));
    } on ApiException catch (e) {
      if (mounted) showSnack(context, e.message);
    }
  }

  /// Envia as fotos novas. Devolve a mensagem do primeiro erro (ou null se tudo certo).
  Future<String?> _uploadNewPhotos(String donationId) async {
    final service = context.read<DonationService>();
    String? error;
    for (final photo in _newPhotos) {
      try {
        final name = photo.name.isEmpty ? 'foto.jpg' : photo.name;
        await service.uploadPhoto(donationId, bytes: photo.bytes, filename: name);
      } on ApiException catch (e) {
        error ??= e.message;
      } catch (e) {
        error ??= e.toString();
      }
    }
    return error;
  }

  Widget _photosSection(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Fotos ($_photoCount/$_maxPhotos)', style: theme.textTheme.titleSmall),
        const SizedBox(height: 4),
        Text(
          'Uma boa foto ajuda a instituição a decidir. A primeira será a capa.',
          style: theme.textTheme.bodySmall,
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 96,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              for (final url in _savedPhotos)
                _Thumb(
                  onRemove: _loading ? null : () => _removeSaved(url),
                  child: NetworkPhoto(url),
                ),
              for (final file in _newPhotos)
                _Thumb(
                  onRemove: _loading ? null : () => setState(() => _newPhotos.remove(file)),
                  child: Image.memory(file.bytes, fit: BoxFit.cover),
                ),
              if (_photoCount < _maxPhotos)
                InkWell(
                  onTap: _loading ? null : _addPhoto,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: 96,
                    decoration: BoxDecoration(
                      border: Border.all(color: theme.colorScheme.outline),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.add_a_photo_outlined),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final service = context.read<DonationService>();
    final quantity = double.parse(_quantity.text.replaceAll(',', '.'));

    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final Donation saved;
      if (_editing) {
        saved = await service.updateDonation(
          widget.donation!.id,
          categoryId: _categoryId!,
          description: _description.text.trim(),
          quantity: quantity,
          unit: _unit,
          expiresAt: _expiresAt!,
          storageConditions: _storage,
        );
      } else {
        saved = await service.createDonation(
          categoryId: _categoryId!,
          description: _description.text.trim(),
          quantity: quantity,
          unit: _unit,
          expiresAt: _expiresAt!,
          storageConditions: _storage,
        );
      }
      final photoError = await _uploadNewPhotos(saved.id);
      if (!mounted) return;
      showSnack(
        context,
        photoError != null
            ? 'Doação salva, mas a foto não subiu: $photoError'
            : (_editing ? 'Doação atualizada!' : 'Doação cadastrada!'),
      );
      context.pop(true);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (_) {
      if (mounted) setState(() => _error = 'Não foi possível salvar. Tente novamente.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DropdownButtonFormField<String>(
              initialValue: _categoryId,
              // isExpanded: dá largura limitada aos itens (eles usam Flexible/ellipsis)
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Categoria do alimento'),
              items: [
                for (final c in _categories)
                  DropdownMenuItem(
                    value: c.id,
                    child: Row(
                      // min: o Row encolhe ao conteúdo, então não exige largura finita
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(categoryIcon(c.name), size: 20),
                        const SizedBox(width: 8),
                        Flexible(child: Text(c.name, overflow: TextOverflow.ellipsis)),
                      ],
                    ),
                  ),
              ],
              validator: (v) => v == null ? 'Escolha a categoria.' : null,
              onChanged: (v) => setState(() => _categoryId = v),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _description,
              textCapitalization: TextCapitalization.sentences,
              maxLength: 120,
              decoration: const InputDecoration(
                labelText: 'Descrição',
                helperText: 'Ex.: Caixas de tomate, pães do dia',
              ),
              validator: (v) => validateRequired(v, 'Descreva o alimento.'),
            ),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    controller: _quantity,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'Quantidade'),
                    validator: (v) {
                      final value = double.tryParse((v ?? '').replaceAll(',', '.'));
                      return (value == null || value <= 0)
                          ? 'Informe uma quantidade válida.'
                          : null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _unit,
                    decoration: const InputDecoration(labelText: 'Unidade'),
                    items: [
                      for (final u in _units) DropdownMenuItem(value: u, child: Text(u)),
                    ],
                    onChanged: (v) {
                      if (v != null) setState(() => _unit = v);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _date,
              readOnly: true,
              onTap: _pickDate,
              decoration: const InputDecoration(
                labelText: 'Validade',
                suffixIcon: Icon(Icons.calendar_month),
              ),
              validator: (_) => _expiresAt == null ? 'Informe a validade.' : null,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _storage,
              decoration: const InputDecoration(labelText: 'Condições de armazenamento'),
              items: [
                for (final s in _storages) DropdownMenuItem(value: s, child: Text(s)),
              ],
              onChanged: (v) {
                if (v != null) setState(() => _storage = v);
              },
            ),
            const SizedBox(height: 20),
            _photosSection(context),
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
                  : Text(_editing ? 'Salvar alterações' : 'Cadastrar doação'),
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: _loading ? null : () => context.pop(),
              child: const Text('Cancelar'),
            ),
          ],
        ),
      ),
    );
  }
}

class _Thumb extends StatelessWidget {
  final Widget child;
  final VoidCallback? onRemove;
  const _Thumb({required this.child, required this.onRemove});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(right: 8),
    child: SizedBox(
      width: 96,
      child: Stack(
        fit: StackFit.expand,
        children: [
          ClipRRect(borderRadius: BorderRadius.circular(12), child: child),
          Positioned(
            top: 2,
            right: 2,
            child: InkWell(
              onTap: onRemove,
              child: const CircleAvatar(
                radius: 12,
                backgroundColor: Colors.black54,
                child: Icon(Icons.close, size: 14, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

/// Foto escolhida e ainda não enviada (os bytes ficam em memória até salvar a doação).
class _PendingPhoto {
  final String name;
  final Uint8List bytes;
  const _PendingPhoto(this.name, this.bytes);
}
