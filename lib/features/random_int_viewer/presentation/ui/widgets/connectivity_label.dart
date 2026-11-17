import 'package:flutter_clean_template/features/common/domain/entities/network_status.dart';
import 'package:material_ui/material_ui.dart';

class ConnectivityLabel extends StatelessWidget {
  /// `null` while the status has not been determined yet.
  final NetworkStatus? networkStatus;

  const ConnectivityLabel(this.networkStatus, {super.key});

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (networkStatus) {
      NetworkStatus.connected => ('CONNECTED', Colors.green),
      NetworkStatus.disconnected => ('DISCONNECTED', Colors.red),
      null => ('CHECKING', Colors.grey),
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
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w500, color: Colors.white, fontSize: 12),
        ),
      ],
    );
  }
}
