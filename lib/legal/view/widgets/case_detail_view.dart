import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../legal_theme.dart';
import '../../bloc/legal_bloc.dart';
import '../../../models/legal_models.dart';
import 'shared_widgets.dart';
import 'legal_modals.dart';

class CaseDetailView extends StatelessWidget {
  const CaseDetailView({super.key});

  @override
  Widget build(BuildContext context) {
    // Optimized rebuilds: only watch specific state parts
    final selectedCaseId = context.select((LegalBloc bloc) => bloc.state.selectedCaseId);
    final cases = context.select((LegalBloc bloc) => bloc.state.cases);
    
    final selectedCase = cases.firstWhere((c) => c.id == selectedCaseId);

    return Stack(
      key: const ValueKey('case_detail'),
      children: [
        Column(
          children: [
            DetailHeader(
              onBack: () => context.read<LegalBloc>().add(const CaseSelected(null)),
              title: selectedCase.name,
              subtitle: selectedCase.number,
              trailing: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                    color: LegalTheme.getCaseBg(selectedCase.type),
                    borderRadius: BorderRadius.circular(8)),
                child: Text(selectedCase.type,
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: LegalTheme.getCaseColor(selectedCase.type))),
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  _CaseOverviewCard(c: selectedCase),
                  const SizedBox(height: 22),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Categories (${selectedCase.categories.length})',
                          style: const TextStyle(
                              fontSize: 15, fontWeight: FontWeight.w700)),
                      GestureDetector(
                        onTap: () => LegalModals.showAddCategoryModal(context, selectedCase.id),
                        child: const Row(
                          children: [
                            Icon(Icons.add, color: LegalTheme.blue, size: 14),
                            SizedBox(width: 4),
                            Text('New Folder',
                                style: TextStyle(
                                    color: LegalTheme.blue,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ...selectedCase.categories
                      .map((cat) => _CategoryItem(cat: cat)),
                  if (selectedCase.uncategorizedFiles.isNotEmpty) ...[
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Text('Files',
                          style: TextStyle(
                              fontSize: 15, fontWeight: FontWeight.w700)),
                    ),
                    ...selectedCase.uncategorizedFiles
                        .map((file) => FileItem(file: file)),
                  ],
                  const SizedBox(height: 80),
                ],
              ),
            ),
          ],
        ),
        Positioned(
          bottom: 20,
          right: 20,
          child: FloatingActionButton(
            onPressed: () => context
                .read<LegalBloc>()
                .add(FileUploaded(selectedCase.id, null)),
            backgroundColor: LegalTheme.blue,
            child: const Icon(Icons.upload, color: Colors.white),
          ),
        )
      ],
    );
  }
}

class _CaseOverviewCard extends StatelessWidget {
  final Case c;
  const _CaseOverviewCard({required this.c});

  @override
  Widget build(BuildContext context) {
    final scheduled = c.isScheduled;
    final typeColor = LegalTheme.getCaseColor(c.type);

    return Container(
      decoration: LegalTheme.cardDecoration(radius: 20, blur: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 12, 12),
            child: Row(
              children: [
                Container(
                  width: 4,
                  height: 18,
                  decoration: BoxDecoration(
                      color: typeColor,
                      borderRadius: BorderRadius.circular(2)),
                ),
                const SizedBox(width: 10),
                const Text('Case details',
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: LegalTheme.ink)),
                const Spacer(),
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => LegalModals.showEditCaseModal(context, c),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(
                        color: LegalTheme.blueBg,
                        borderRadius: BorderRadius.circular(10)),
                    child: const Row(
                      children: [
                        Icon(Icons.edit_outlined, size: 14, color: LegalTheme.blue),
                        SizedBox(width: 5),
                        Text('Edit',
                            style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w700,
                                color: LegalTheme.blue)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: Colors.grey[100]),
          _FactRow(label: 'COURT', value: c.court),
          _FactDivider(),
          _FactRow(
            label: 'NEXT HEARING',
            value: scheduled ? c.hearing : 'Not scheduled',
            highlight: scheduled,
          ),
          _FactDivider(),
          _FactRow(label: 'CASE NO.', value: c.number),
          const SizedBox(height: 6),
        ],
      ),
    );
  }
}

class _FactRow extends StatelessWidget {
  final String label;
  final String value;
  final bool highlight;

  const _FactRow({
    required this.label,
    required this.value,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      child: Row(
        children: [
          SizedBox(
            width: 106,
            child: Text(label,
                style: const TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: LegalTheme.muted,
                    letterSpacing: 0.6)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(value,
                style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: highlight ? LegalTheme.blue : LegalTheme.ink)),
          ),
        ],
      ),
    );
  }
}

class _FactDivider extends StatelessWidget {
  const _FactDivider();

  @override
  Widget build(BuildContext context) {
    return Divider(
        height: 1, color: Colors.grey[100], indent: 16, endIndent: 16);
  }
}

class _CategoryItem extends StatelessWidget {
  final Category cat;
  const _CategoryItem({required this.cat});

  @override
  Widget build(BuildContext context) {
    final color = LegalTheme.getCategoryColor(cat.id);
    final bg = LegalTheme.getCategoryBg(cat.id);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => context.read<LegalBloc>().add(CategorySelected(cat.id)),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: LegalTheme.cardDecoration(),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                  color: bg, borderRadius: BorderRadius.circular(12)),
              child: Icon(Icons.folder, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(cat.name,
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w700)),
                  Text('${cat.docs} Documents',
                      style: const TextStyle(
                          fontSize: 12,
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
