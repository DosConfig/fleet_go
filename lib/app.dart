import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/di/auth_providers.dart';
import 'core/theme.dart';
import 'features/auth/presentation/login_screen.dart';
import 'features/role_select/role_select_screen.dart';

class FleetGoApp extends ConsumerWidget {
  const FleetGoApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    return MaterialApp(
      title: 'Fleet Go',
      theme: FleetGoTheme.light(),
      home: authState.when(
        data: (user) =>
            user != null ? const RoleSelectScreen() : const LoginScreen(),
        loading: () =>
            const Scaffold(body: Center(child: CircularProgressIndicator())),
        error: (_, _) => const LoginScreen(),
      ),
    );
  }
}
