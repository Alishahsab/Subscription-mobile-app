import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/format.dart';
import '../../../data/repositories/phones_repository.dart';
import '../../../data/sync/now_provider.dart';
import '../../notifications/push_service.dart';
import '../widgets/settings_page.dart';
import '../widgets/settings_ui.dart';

typedef _Phones = ({List<AdminPhone> phones, String? thisPhone});

void openPhonesScreen(BuildContext context) {
  Navigator.of(context, rootNavigator: true).push(MaterialPageRoute<void>(builder: (context) => const PhonesScreen()));
}

class PhonesScreen extends ConsumerStatefulWidget {
  const PhonesScreen({super.key});

  @override
  ConsumerState<PhonesScreen> createState() => _PhonesScreenState();
}

class _PhonesScreenState extends ConsumerState<PhonesScreen> {
  late Future<_Phones> _phones = _load();

  Future<_Phones> _load() async {
    final phones = await ref.read(phonesRepositoryProvider).load();
    final thisPhone = await PushService.instance.currentToken();
    return (phones: phones, thisPhone: thisPhone);
  }

  void _reload() => setState(() => _phones = _load());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SettingsPageHeader(title: 'Logged-in phones', subtitle: 'Phones that get admin notifications'),
            Expanded(
              child: FutureBuilder<_Phones>(
                future: _phones,
                builder: (context, snapshot) {
                  if (snapshot.hasError) return _LoadProblem(onRetry: _reload);
                  final data = snapshot.data;
                  if (data == null) return const Center(child: CircularProgressIndicator());
                  return _PhoneList(phones: data.phones, thisPhone: data.thisPhone);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PhoneList extends ConsumerWidget {
  const _PhoneList({required this.phones, required this.thisPhone});

  final List<AdminPhone> phones;
  final String? thisPhone;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = watchNow(ref);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
      children: [
        SettingsGroup(
          children: [
            if (phones.isEmpty) const SettingsRow(title: 'No phones yet', sub: 'Phones show up here after signing in to the app.'),
            for (final phone in phones)
              SettingsRow(
                title: phone.name ?? 'Unknown phone',
                sub: phone.token == thisPhone ? 'This phone' : 'Active ${timeAgo(phone.lastActiveAt, now)}',
              ),
          ],
        ),
      ],
    );
  }
}

class _LoadProblem extends StatelessWidget {
  const _LoadProblem({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Phones could not be loaded.'),
          const SizedBox(height: 8),
          TextButton(onPressed: onRetry, child: const Text('Try again')),
        ],
      ),
    );
  }
}
