import 'package:flutter/material.dart';

import '../control/presentation/control_screen.dart';
import '../trip/presentation/screens/driver_screen.dart';
import '../trip/presentation/screens/passenger_screen.dart';

class RoleSelectScreen extends StatelessWidget {
  const RoleSelectScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Fleet Go', style: Theme.of(context).textTheme.headlineLarge),
            const SizedBox(height: 48),
            _RoleButton(icon: Icons.person, label: '승객', onTap: () => _push(context, const PassengerScreen())),
            const SizedBox(height: 16),
            _RoleButton(icon: Icons.drive_eta, label: '드라이버', onTap: () => _push(context, const DriverScreen())),
            const SizedBox(height: 16),
            _RoleButton(icon: Icons.monitor, label: '관제', onTap: () => _push(context, const ControlScreen())),
          ],
        ),
      ),
    );
  }

  void _push(BuildContext context, Widget screen) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
  }
}

class _RoleButton extends StatelessWidget {
  const _RoleButton({required this.icon, required this.label, required this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(onPressed: onTap, icon: Icon(icon), label: Text(label));
  }
}
