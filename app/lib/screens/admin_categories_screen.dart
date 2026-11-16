import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/async_loader.dart';
import '../core/presentation.dart';
import '../core/responsive.dart';
import '../core/state_views.dart';
import '../models/models.dart';
import '../services/api_exception.dart';
import '../services/category_service.dart';

/// Administrador: CRUD das categorias de alimento.
class AdminCategoriesScreen extends StatefulWidget {
  const AdminCategoriesScreen({super.key});

  @override
  State<AdminCategoriesScreen> createState() => _AdminCategoriesScreenState();
}

class _AdminCategoriesScreenState extends State<AdminCategoriesScreen> {
  int _version = 0;

  void _refresh() => setState(() => _version++);

  Future<void> _run(Future<void> Function() action, String okMessage) async {
    try {
      await action();
      if (!mounted) return;
      showSnack(context, okMessage);
      _refresh();
    } on ApiException catch (e) {
      if (mounted) showSnack(context, e.message);
    } catch (_) {
      if (mounted) showSnack(context, 'Não foi possível concluir. Tente novamente.');
    }
  }

  Future<void> _edit({FoodCategory? category}) async {
    final service = context.read<CategoryService>();
    final name = TextEditingController(text: category?.name ?? '');
    final description = TextEditingController(text: category?.description ?? '');
    var active = category?.active ?? true;

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: Text(category == null ? 'Nova categoria' : 'Editar categoria'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: name,
                autofocus: true,
                maxLength: 60,
                decoration: const InputDecoration(labelText: 'Nome'),
              ),
              TextField(
                controller: description,
                maxLength: 200,
                decoration: const InputDecoration(labelText: 'Descrição (opcional)'),
              ),
              if (category != null)
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Ativa'),
                  value: active,
                  onChanged: (v) => setLocal(() => active = v),
                ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Voltar')),
            FilledButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Salvar')),
          ],
        ),
      ),
    );
    final nameText = name.text.trim();
    final descText = description.text.trim();
    name.dispose();
    description.dispose();
    if (ok != true) return;
    if (nameText.isEmpty) {
      if (mounted) showSnack(context, 'Informe o nome da categoria.');
      return;
    }

    await _run(
      () async {
        if (category == null) {
          await service.create(name: nameText, description: descText.isEmpty ? null : descText);
        } else {
          await service.update(
            category.id,
            name: nameText,
            description: descText.isEmpty ? null : descText,
            active: active,
          );
        }
      },
      category == null ? 'Categoria criada.' : 'Categoria atualizada.',
    );
  }

  Future<void> _delete(FoodCategory category) async {
    final service = context.read<CategoryService>();
    final ok = await confirmDialog(
      context,
      title: 'Excluir categoria?',
      message: '"${category.name}" será removida. Se estiver em uso, desative-a em vez de excluir.',
      confirmLabel: 'Excluir',
    );
    if (ok) await _run(() => service.delete(category.id), 'Categoria excluída.');
  }

  @override
  Widget build(BuildContext context) {
    final service = context.read<CategoryService>();

    return Scaffold(
      appBar: AppBar(title: const Text('Categorias de alimento')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _edit(),
        icon: const Icon(Icons.add),
        label: const Text('Nova categoria'),
      ),
      body: ContentWidth(
        maxWidth: 700,
        child: AsyncLoader<List<FoodCategory>>(
          key: ValueKey(_version),
          load: () => service.list(includeInactive: true),
          builder: (context, categories, reload) => RefreshIndicator(
            onRefresh: reload,
            child: ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
              itemCount: categories.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, i) {
                final c = categories[i];
                return Card(
                  margin: EdgeInsets.zero,
                  child: ListTile(
                    leading: CircleAvatar(child: Icon(categoryIcon(c.name))),
                    title: Text(c.name),
                    subtitle: Text(
                      [
                        if (!c.active) 'Inativa',
                        if (c.description != null && c.description!.isNotEmpty) c.description!,
                      ].join(' · '),
                    ),
                    trailing: Wrap(
                      children: [
                        IconButton(
                          tooltip: 'Editar',
                          icon: const Icon(Icons.edit_outlined),
                          onPressed: () => _edit(category: c),
                        ),
                        IconButton(
                          tooltip: 'Excluir',
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () => _delete(c),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
