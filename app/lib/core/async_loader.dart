import 'package:flutter/material.dart';

import '../services/api_exception.dart';
import 'state_views.dart';

/// Carrega dados assíncronos e trata loading, erro (com "tentar de novo") e
/// conteúdo. O builder recebe `reload` para atualizar a tela depois de uma ação.
class AsyncLoader<T> extends StatefulWidget {
  final Future<T> Function() load;
  final Widget Function(
    BuildContext context,
    T data,
    Future<void> Function() reload,
  )
  builder;

  const AsyncLoader({super.key, required this.load, required this.builder});

  @override
  State<AsyncLoader<T>> createState() => _AsyncLoaderState<T>();
}

class _AsyncLoaderState<T> extends State<AsyncLoader<T>> {
  late Future<T> _future = widget.load();

  Future<void> _reload() async {
    setState(() {
      _future = widget.load();
    });
    try {
      await _future;
    } catch (_) {
      // o erro aparece no FutureBuilder
    }
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<T>(
    future: _future,
    builder: (context, snapshot) {
      if (snapshot.connectionState != ConnectionState.done) {
        return const Center(child: CircularProgressIndicator());
      }
      if (snapshot.hasError) {
        final error = snapshot.error;
        return ErrorView(
          message: error is ApiException
              ? error.message
              : 'Não foi possível carregar. Tente novamente.',
          onRetry: _reload,
        );
      }
      return widget.builder(context, snapshot.data as T, _reload);
    },
  );
}
