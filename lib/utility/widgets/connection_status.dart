import 'package:flutter/cupertino.dart' hide ConnectionState;
import 'package:hugeicons/hugeicons.dart';
import 'package:messagyre_client/utility/widgets/gymnase_mark.dart';
import 'package:messagyre_client/configuration/app_colors.dart';
import 'package:messagyre_client/configuration/app_strings.dart';
import 'package:messagyre_client/services/network_service.dart';
import 'package:messagyre_client/utility/wrappers/custom_icon.dart';

class ConnectionStatus extends StatefulWidget {
  const ConnectionStatus({super.key});

  @override
  State<ConnectionStatus> createState() => _ConnectionStatusState();
}

class _ConnectionStatusState extends State<ConnectionStatus> {
  final network = NetworkService();

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: network.connectionState,
      builder: (context, connectionState, _) => (connectionState != ConnectionState.Connected || network.isLocalhost)
          ? Row(
              spacing: 8,
              children: [
                Text(
                  network.isLocalhost ? AppStrings.connectedToLocalhost : AppStrings.connecting,
                  style: TextStyle(color: network.isLocalhost ? AppColors.red : AppColors.secondaryText.adaptTo(context)),
                ),
                network.isLocalhost
                    ? CustomIcon(icon: HugeIcons.strokeRoundedAlert02, color: AppColors.red, size: 20, strokeWidth: 1.5)
                    : GymnaseLoader(size: 18),
              ],
            )
          : SizedBox.shrink(),
    );
  }
}
