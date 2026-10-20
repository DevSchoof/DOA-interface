import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../models/models.dart';
import '../providers/auth_provider.dart';
import '../services/auth_service.dart';
import '../services/donor_service.dart';
import '../utils/document_validator.dart';

class RegisterDonorScreen extends StatefulWidget {
  const RegisterDonorScreen({super.key});

  @override
  State<RegisterDonorScreen> createState() => _RegisterDonorScreenState();
}

class _RegisterDonorScreenState extends State<RegisterDonorScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _documentController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();

  PersonType _type = PersonType.individual;
  bool _isLoading = false;
  String? _error;

  bool get _isIndividual => _type == PersonType.individual;

  @override
  void dispose() {
    _nameController.dispose();
    _documentController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  String? _required(String? value, String message) =>
      (value == null || value.trim().isEmpty) ? message : null;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final service = context.read<DonorService>();
    final userId = context.read<AuthProvider>().user!.id;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      await service.registerDonor(
        userId: userId,
        personType: _type,
        name: _nameController.text.trim(),
        document: onlyDigits(_documentController.text),
        phone: onlyDigits(_phoneController.text),
        address: _addressController.text.trim(),
        city: _cityController.text.trim(),
      );
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cadastro de doador concluído.')),
      );
      context.pop();
    } on AuthException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Não foi possível cadastrar. Tente novamente.');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final documentLabel = _isIndividual ? 'CPF' : 'CNPJ';

    return Scaffold(
      appBar: AppBar(title: const Text('Cadastro de doador')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: SingleChildScrollView(
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
                        label: Text('Pessoa física'),
                      ),
                      ButtonSegment(
                        value: PersonType.company,
                        label: Text('Pessoa jurídica'),
                      ),
                    ],
                    selected: {_type},
                    onSelectionChanged: (selection) => setState(() {
                      _type = selection.first;
                      _documentController.clear();
                    }),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: _isIndividual
                          ? 'Nome completo'
                          : 'Razão social',
                      border: const OutlineInputBorder(),
                    ),
                    validator: (v) => _required(
                      v,
                      _isIndividual
                          ? 'Informe o nome.'
                          : 'Informe a razão social.',
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _documentController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: documentLabel,
                      hintText: _isIndividual
                          ? '000.000.000-00'
                          : '00.000.000/0000-00',
                      border: const OutlineInputBorder(),
                    ),
                    validator: (v) {
                      if (onlyDigits(v ?? '').isEmpty) {
                        return 'Informe o $documentLabel.';
                      }
                      final valid = _isIndividual
                          ? isValidCpf(v!)
                          : isValidCnpj(v!);
                      return valid ? null : '$documentLabel inválido.';
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'Telefone',
                      hintText: '(11) 99999-8888',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) {
                      final digits = onlyDigits(v ?? '');
                      if (digits.isEmpty) return 'Informe o telefone.';
                      if (digits.length < 10 || digits.length > 11) {
                        return 'Telefone inválido.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _addressController,
                    decoration: const InputDecoration(
                      labelText: 'Endereço',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) => _required(v, 'Informe o endereço.'),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _cityController,
                    decoration: const InputDecoration(
                      labelText: 'Cidade',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) => _required(v, 'Informe a cidade.'),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 16),
                    Text(
                      _error!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: _isLoading ? null : _submit,
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Cadastrar'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
