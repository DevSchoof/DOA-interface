import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/format.dart';
import '../core/responsive.dart';
import '../core/state_views.dart';
import '../models/models.dart';
import '../providers/auth_provider.dart';
import '../providers/realtime_provider.dart';
import '../services/api_exception.dart';
import '../services/chat_service.dart';

/// RF12: chat entre o doador e a instituição que reservou a doação.
/// O histórico vem da API; as novas mensagens chegam pelo WebSocket.
class ChatScreen extends StatefulWidget {
  final String donationId;
  const ChatScreen({super.key, required this.donationId});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _input = TextEditingController();
  final _scroll = ScrollController();
  final List<ChatMessage> _messages = [];
  StreamSubscription<Map<String, dynamic>>? _subscription;
  bool _loading = true;
  bool _sending = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _subscription = context.read<RealtimeProvider>().events.listen((event) {
      if (event['type'] != 'chat') return;
      final message = ChatMessage.fromJson(event);
      if (message.donationId == widget.donationId) _add(message);
    });
    _loadHistory();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _loadHistory() async {
    final service = context.read<ChatService>();
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final history = await service.history(widget.donationId);
      if (!mounted) return;
      setState(() {
        for (final m in history) {
          if (!_messages.any((e) => e.id == m.id)) _messages.add(m);
        }
        _messages.sort((a, b) => a.sentAt.compareTo(b.sentAt));
      });
      _scrollToEnd();
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (_) {
      if (mounted) setState(() => _error = 'Não foi possível carregar a conversa.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  /// Evita duplicar: a mensagem enviada chega pela resposta da API e pelo WebSocket.
  void _add(ChatMessage message) {
    if (!mounted || _messages.any((m) => m.id == message.id)) return;
    setState(() => _messages.add(message));
    _scrollToEnd();
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _send() async {
    final text = _input.text.trim();
    if (text.isEmpty || _sending) return;
    final service = context.read<ChatService>();

    setState(() => _sending = true);
    try {
      final message = await service.send(widget.donationId, text);
      _input.clear();
      _add(message);
    } on ApiException catch (e) {
      if (mounted) showSnack(context, e.message);
    } catch (_) {
      if (mounted) showSnack(context, 'Não foi possível enviar a mensagem.');
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final myId = context.watch<AuthProvider>().user?.id;
    final connected = context.watch<RealtimeProvider>().isConnected;
    final theme = Theme.of(context);

    Widget body;
    if (_loading) {
      body = const Center(child: CircularProgressIndicator());
    } else if (_error != null) {
      body = ErrorView(message: _error!, onRetry: _loadHistory);
    } else if (_messages.isEmpty) {
      body = const EmptyState(
        icon: Icons.chat_bubble_outline,
        message: 'Nenhuma mensagem ainda. Combine aqui a retirada da doação.',
      );
    } else {
      body = ListView.builder(
        controller: _scroll,
        padding: const EdgeInsets.all(16),
        itemCount: _messages.length,
        itemBuilder: (context, i) =>
            _Bubble(message: _messages[i], mine: _messages[i].senderUserId == myId),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Conversa'),
        actions: [
          Tooltip(
            message: connected ? 'Tempo real ativo' : 'Reconectando...',
            child: Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Icon(
                Icons.circle,
                size: 12,
                color: connected ? theme.colorScheme.primary : theme.colorScheme.outline,
              ),
            ),
          ),
        ],
      ),
      body: ContentWidth(
        maxWidth: 700,
        child: Column(
          children: [
            Expanded(child: body),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _input,
                        maxLength: 1000,
                        minLines: 1,
                        maxLines: 4,
                        textCapitalization: TextCapitalization.sentences,
                        decoration: const InputDecoration(
                          hintText: 'Escreva uma mensagem',
                          counterText: '',
                          isDense: true,
                        ),
                        onSubmitted: (_) => _send(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton.filled(
                      tooltip: 'Enviar',
                      onPressed: _sending ? null : _send,
                      icon: _sending
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.send),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  final ChatMessage message;
  final bool mine;
  const _Bubble({required this.message, required this.mine});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bg = mine ? theme.colorScheme.primaryContainer : theme.colorScheme.surfaceContainerHighest;
    final fg = mine ? theme.colorScheme.onPrimaryContainer : theme.colorScheme.onSurface;
    final time = message.sentAt.toLocal();
    final hour = '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';

    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * 0.75),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(14)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!mine)
              Text(message.senderName, style: theme.textTheme.labelSmall?.copyWith(color: fg)),
            Text(message.content, style: TextStyle(color: fg)),
            const SizedBox(height: 2),
            Text(
              '${formatDate(time)} $hour',
              style: theme.textTheme.labelSmall?.copyWith(color: fg.withValues(alpha: 0.7)),
            ),
          ],
        ),
      ),
    );
  }
}
