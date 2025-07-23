import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:order_management_system/features/auth/presentation/providers/auth_provider.dart';

class ClientVerificationPage extends ConsumerStatefulWidget {
  const ClientVerificationPage({super.key});
  @override
  ConsumerState<ClientVerificationPage> createState() =>
      _ClientVerificationPageState();
}

class _ClientVerificationPageState
    extends ConsumerState<ClientVerificationPage> {
  final ctrl = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authStateProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Enter Invite Code')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            TextField(
              controller: ctrl,
              decoration: const InputDecoration(
                labelText: 'Invite code',
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => ref
                  .read(authStateProvider.notifier)
                  .verifyClientCode(ctrl.text),
              child: const Text('Verify'),
            ),
            if (auth.error == null)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Text(
                  auth.error.toString(),
                  style: const TextStyle(color: Colors.red),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
