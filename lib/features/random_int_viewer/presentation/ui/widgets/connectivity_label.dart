import 'package:clean_architecture_demo/features/connectivity/domain/entities/network_status.dart';
import 'package:material_ui/material_ui.dart';

class ConnectivityLabel extends StatelessWidget {
  final NetworkStatus networkStatus;

  const ConnectivityLabel(this.networkStatus, {super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final (label, color) = switch (networkStatus) {
      NetworkStatus.connected => ('CONNECTED', Colors.green),
      NetworkStatus.disconnected => ('DISCONNECTED', colorScheme.error),
      NetworkStatus.unknown => ('CHECKING', colorScheme.outline),
    };

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            label,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelMedium,
          ),
        ),
      ],
    );
  }
}
