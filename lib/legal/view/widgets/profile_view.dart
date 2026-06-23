import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../legal_theme.dart';
import '../../bloc/blocs.dart';

class ProfileView extends StatelessWidget {
  const ProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    final cases = context.select((CaseBloc bloc) => bloc.state.cases);
    final activeCases = cases.length;
    final totalDocs = cases.fold<int>(0, (sum, c) => sum + c.docs);
    final hearings = cases.where((c) => c.isScheduled).length;

    return ListView(
      key: const ValueKey('profile'),
      padding: const EdgeInsets.all(20),
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: LegalTheme.cardDecoration(radius: 20, blur: 16),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [LegalTheme.blue, Color(0xFF3D82F0)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Center(
                      child: Text('AC',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w800)),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Alex Carter',
                            style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                                color: LegalTheme.ink)),
                        const SizedBox(height: 2),
                        const Text('Litigation Attorney · Carter & Associates',
                            style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w500,
                                color: LegalTheme.muted)),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                              color: LegalTheme.blueBg,
                              borderRadius: BorderRadius.circular(6)),
                          child: const Text('Bar No. NY-184320',
                              style: TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w700,
                                  color: LegalTheme.blue)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  _ProfileStat(value: '$activeCases', label: 'Active Cases'),
                  const _StatDivider(),
                  _ProfileStat(value: '$totalDocs', label: 'Documents'),
                  const _StatDivider(),
                  _ProfileStat(value: '$hearings', label: 'Hearings'),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        const _SectionLabel(text: 'ACCOUNT'),
        _SettingsGroup(rows: [
          _SettingRow(
            icon: Icons.person_outline,
            title: 'Personal details',
            subtitle: 'Name, bar number, contact',
            onTap: () {},
          ),
          _SettingRow(
            icon: Icons.notifications_none,
            title: 'Notifications',
            subtitle: 'Hearing reminders & alerts',
            onTap: () {},
          ),
          _SettingRow(
            icon: Icons.cloud_outlined,
            title: 'Storage & sync',
            subtitle: '12.4 GB of 50 GB used',
            onTap: () {},
          ),
        ]),
        const SizedBox(height: 16),
        const _SectionLabel(text: 'PREFERENCES'),
        _SettingsGroup(rows: [
          _SettingRow(
            icon: Icons.lock_outline,
            title: 'Security & privacy',
            subtitle: 'Passcode, biometrics',
            onTap: () {},
          ),
          _SettingRow(
            icon: Icons.help_outline,
            title: 'Help & support',
            subtitle: 'Guides and contact',
            onTap: () {},
          ),
        ]),
        const SizedBox(height: 16),
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => _confirmSignOut(context),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: LegalTheme.cardDecoration(opacity: 0.05, blur: 12, dy: 3),
            child: const Row(
              children: [
                Icon(Icons.logout, color: Color(0xFFE03A1E), size: 19),
                SizedBox(width: 12),
                Text('Sign out',
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFFE03A1E))),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  void _confirmSignOut(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Sign out?',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
        content: const Text(
            "You'll need to sign in again to access your cases and documents.",
            style: TextStyle(fontSize: 13.5, color: Color(0xFF4B5563))),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel',
                style: TextStyle(
                    color: LegalTheme.muted, fontWeight: FontWeight.w600)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
            },
            child: const Text('Sign out',
                style: TextStyle(
                    color: Color(0xFFE03A1E), fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}

class _ProfileStat extends StatelessWidget {
  final String value;
  final String label;

  const _ProfileStat({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(value,
              style: const TextStyle(
                  fontSize: 20, fontWeight: FontWeight.w800, color: LegalTheme.ink)),
          const SizedBox(height: 2),
          Text(label,
              style: const TextStyle(
                  fontSize: 11, fontWeight: FontWeight.w500, color: LegalTheme.muted)),
        ],
      ),
    );
  }
}

class _StatDivider extends StatelessWidget {
  const _StatDivider();

  @override
  Widget build(BuildContext context) {
    return Container(width: 1, height: 32, color: const Color(0xFFEEF1F5));
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(text,
          style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: LegalTheme.muted,
              letterSpacing: 0.8)),
    );
  }
}

class _SettingsGroup extends StatelessWidget {
  final List<Widget> rows;
  const _SettingsGroup({required this.rows});

  @override
  Widget build(BuildContext context) {
    final children = <Widget>[];
    for (var i = 0; i < rows.length; i++) {
      children.add(rows[i]);
      if (i != rows.length - 1) {
        children.add(Divider(
            height: 1, color: Colors.grey[100], indent: 56, endIndent: 16));
      }
    }
    return Container(
      decoration: LegalTheme.cardDecoration(opacity: 0.05, blur: 12, dy: 3),
      child: Column(children: children),
    );
  }
}

class _SettingRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _SettingRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                  color: LegalTheme.field, borderRadius: BorderRadius.circular(8)),
              child: Icon(icon, size: 16, color: LegalTheme.blue),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: LegalTheme.ink)),
                  Text(subtitle,
                      style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w500,
                          color: LegalTheme.muted)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: LegalTheme.muted, size: 18),
          ],
        ),
      ),
    );
  }
}
