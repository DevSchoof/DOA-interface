import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../services/auth_service.dart';
import '../providers/institution_provider.dart';
import '../utils/document_validator.dart';

class RegisterInstitutionScreen extends StatefulWidget {
  const RegisterInstitutionScreen({super.key});

  @override
  State<RegisterInstitutionScreen> createState() =>
      _RegisterInstitutionScreenState();
}

class _RegisterInstitutionScreenState extends State<RegisterInstitutionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _cnpjController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _capacityController = TextEditingController();

  bool _isLoading = false;
  String? _error;

  @override
  void dispose() {
    _nameController.dispose();
    _cnpjController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _capacityController.dispose();
    super.dispose();
  }

  String? _required(String? value, String message) =>
      (value == null || value.trim().isEmpty) ? message : null;

  double? _parseCapacity(String? value) =>
      double.tryParse((value ?? '').trim().replaceAll(',', '.'));

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final provider = context.read<InstitutionProvider>();
    final userId = context.read<AuthProvider>().user!.id;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      await provider.register(
        userId: userId,
        name: _nameController.text.trim(),
        cnpj: onlyDigits(_cnpjController.text),
        phone: onlyDigits(_phoneController.text),
        address: _addressController.text.trim(),
        city: _cityController.text.trim(),
        storageCapacity: _parseCapacity(_capacityController.text)!,
      );
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Instituição cadastrada. Aguarde a homologação.'),
        ),
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
    return Scaffold(
      appBar: AppBar(title: const Text('Cadastro de instituição')),
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
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Nome da instituição',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) => _required(v, 'Informe o nome.'),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _cnpjController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'CNPJ',
                      hintText: '00.000.000/0000-00',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) {
                      if (onlyDigits(v ?? '').isEmpty) {
                        return 'Informe o CNPJ.';
                      }
                      return isValidCnpj(v!) ? null : 'CNPJ inválido.';
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
                      labelText: 'Endereço da sede',
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
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _capacityController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Capacidade de armazenamento',
                      helperText: 'Capacidade volumétrica (ex.: 500)',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) {
                      final n = _parseCapacity(v);
                      if (n == null) return 'Informe um número.';
                      if (n <= 0)
                        return 'A capacidade deve ser maior que zero.';
                      return null;
                    },
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
