import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../legal_theme.dart';
import '../../bloc/legal_bloc.dart';
import '../../../models/legal_models.dart';
import 'legal_modals.dart';

class CasesListView extends StatelessWidget {
  const CasesListView({super.key});

  @override
  Widget build(BuildContext context) {
    final cases = context.select((LegalBloc bloc) => bloc.state.cases);

    return ListView(
      key: const ValueKey('cases_list'),
      padding: const EdgeInsets.all(20),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('All Cases',
                style: TextStyle(
                    fontSize: 18, fontWeight: FontWeight.w700, color: LegalTheme.ink)),
            GestureDetector(
              onTap: () => LegalModals.showNewCaseModal(context),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: LegalTheme.blue,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                        color: LegalTheme.blue.withOpacity(0.2),
                        blurRadius: 10,
                        offset: const Offset(0, 4))
                  ],
                ),
                child: const Row(
                  children: [
                    Icon(Icons.add, color: Colors.white, size: 14),
                    SizedBox(width: 4),
                    Text('New Case',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ...cases.map((c) => _CaseItem(c: c)),
      ],
    );
  }
}

class _CaseItem extends StatelessWidget {
  final Case c;
  const _CaseItem({required this.c});

  @override
  Widget build(BuildContext context) {
    final isLongPressed = context.select((LegalBloc bloc) => bloc.state.longPressedId == c.id);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => context.read<LegalBloc>().add(CaseSelected(c.id)),
      onLongPress: () async {
        HapticFeedback.mediumImpact();
        final bloc = context.read<LegalBloc>();
        bloc.add(LongPressedIdChanged(c.id));
        await LegalModals.showCaseOptions(context, c);
        bloc.add(const LongPressedIdChanged(null));
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: LegalTheme.cardDecoration(
          blur: 16,
          border: isLongPressed ? Border.all(color: LegalTheme.blue, width: 2) : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(c.name,
                          style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: LegalTheme.ink)),
                      Text(c.number,
                          style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: LegalTheme.muted)),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                      color: LegalTheme.getCaseBg(c.type), borderRadius: BorderRadius.circular(6)),
                  child: Text(c.type,
                      style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          color: LegalTheme.getCaseColor(c.type))),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.description, color: LegalTheme.muted, size: 14),
                const SizedBox(width: 4),
                Text('${c.docs} Docs',
                    style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: LegalTheme.muted)),
                Container(
                    width: 4,
                    height: 4,
                    margin: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: const BoxDecoration(
                        color: Color(0xFFD9E0EA), shape: BoxShape.circle)),
                const Icon(Icons.calendar_today, color: LegalTheme.muted, size: 14),
                const SizedBox(width: 4),
                Text(c.hearing,
                    style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: LegalTheme.muted)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
