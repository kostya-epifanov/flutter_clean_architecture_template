import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_clean_template/core/extensions/connectivity_result.dart';

class ConnectivityLabel extends StatelessWidget {
  final ConnectivityResult connectivityResult;

  const ConnectivityLabel(
    this.connectivityResult, {
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: connectivityResult.color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          connectivityResult.status,
          style: const TextStyle(
            fontWeight: FontWeight.w500,
            color: Colors.white,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}
