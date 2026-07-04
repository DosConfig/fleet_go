import 'package:flutter/material.dart';

import 'core/theme.dart';
import 'features/role_select/role_select_screen.dart';

class FleetGoApp extends StatelessWidget {
  const FleetGoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Fleet Go',
      theme: FleetGoTheme.light(),
      home: const RoleSelectScreen(),
    );
  }
}
