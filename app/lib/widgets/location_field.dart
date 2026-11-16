import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/state_views.dart';
import '../services/api_exception.dart';
import '../services/location_service.dart';

/// Botão que captura a posição do aparelho (GPS) para os cadastros.
class LocationField extends StatefulWidget {
  final ValueChanged<GeoPoint?> onChanged;
  const LocationField({super.key, required this.onChanged});

  @override
  State<LocationField> createState() => _LocationFieldState();
}

class _LocationFieldState extends State<LocationField> {
  GeoPoint? _point;
  bool _loading = false;

  Future<void> _capture() async {
    final service = context.read<LocationService>();
    setState(() => _loading = true);
    try {
      final point = await service.current();
      if (!mounted) return;
      setState(() => _point = point);
      widget.onChanged(point);
    } on ApiException catch (e) {
      if (mounted) showSnack(context, e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        OutlinedButton.icon(
          onPressed: _loading ? null : _capture,
          icon: _loading
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Icon(_point == null ? Icons.my_location : Icons.check_circle),
          label: Text(
            _point == null ? 'Usar minha localização' : 'Localização salva · atualizar',
          ),
        ),
        const SizedBox(height: 4),
        Text(
          _point == null
              ? 'Opcional. Usada para calcular a distância até as doações.'
              : 'Capturada: ${_point!.latitude.toStringAsFixed(5)}, '
                    '${_point!.longitude.toStringAsFixed(5)}',
          style: theme.textTheme.bodySmall,
        ),
      ],
    );
  }
}
