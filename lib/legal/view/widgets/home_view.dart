import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../legal_theme.dart';
import '../../bloc/blocs.dart';
import '../../../models/legal_models.dart';
import '../../../services/document_scanner_service.dart';
import '../../../services/docx_to_pdf_service.dart';
import 'legal_modals.dart';

class HomeView extends StatelessWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      key: const ValueKey('home'),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      children: const [
        Padding(
          padding: EdgeInsets.only(top: 12, bottom: 8),
          child: Text('Upcoming Hearings',
              style: TextStyle(
                  fontSize: 15, fontWeight: FontWeight.w700, color: LegalTheme.ink)),
        ),
        _HearingsCard(),
        SizedBox(height: 16),
        _QuickActions(),
        SizedBox(height: 16),
        _SearchButton(),
        Padding(
          padding: EdgeInsets.only(top: 14, bottom: 8),
          child: Text('Recent Documents',
              style: TextStyle(
                  fontSize: 15, fontWeight: FontWeight.w700, color: LegalTheme.ink)),
        ),
        _RecentDocs(),
        SizedBox(height: 20),
      ],
    );
  }
}

class _HearingsCard extends StatelessWidget {
  const _HearingsCard();

  @override
  Widget build(BuildContext context) {
    final upcoming = context.select((CaseBloc bloc) => bloc.state.upcomingHearings);

    if (upcoming.isEmpty) {
      return Container(
        decoration: LegalTheme.cardDecoration(radius: 20, blur: 16, opacity: 0.07),
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
        child: const Center(
          child: Text('No upcoming hearings',
              style: TextStyle(
                  fontSize: 12.5, color: LegalTheme.muted, fontWeight: FontWeight.w600)),
        ),
      );
    }

    final rows = <Widget>[];
    for (var i = 0; i < upcoming.length; i++) {
      if (i > 0) {
        rows.add(Divider(
            height: 1, color: Colors.grey[100], indent: 16, endIndent: 16));
      }
      rows.add(_HearingRow(c: upcoming[i]));
    }

    final content = Column(mainAxisSize: MainAxisSize.min, children: rows);
    final body = upcoming.length > 3
        ? ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 252),
            child: SingleChildScrollView(child: content),
          )
        : content;

    return Container(
      decoration: LegalTheme.cardDecoration(radius: 20, blur: 16, opacity: 0.07),
      clipBehavior: Clip.antiAlias,
      child: body,
    );
  }
}

class _HearingRow extends StatelessWidget {
  final Case c;
  const _HearingRow({required this.c});

  @override
  Widget build(BuildContext context) {
    final date = c.hearingDate ?? LegalTheme.today;
    final month = LegalTheme.monthAbbr[date.month - 1].toUpperCase();
    final day = '${date.day}';
    final color = LegalTheme.getCaseColor(c.type);
    final bg = LegalTheme.getCaseBg(c.type);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration:
                BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(month,
                    style: TextStyle(
                        fontSize: 9, fontWeight: FontWeight.w700, color: color)),
                Text(day,
                    style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: color,
                        height: 1.1)),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(c.name,
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w700, color: LegalTheme.ink),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                Text('${LegalTheme.weekdayName(date.weekday).substring(0, 3)} · ${c.court}',
                    style: const TextStyle(
                        fontSize: 11,
                        color: LegalTheme.muted,
                        fontWeight: FontWeight.w500)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
            decoration:
                BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
            child: Text(c.type,
                style: TextStyle(
                    fontSize: 10.5, fontWeight: FontWeight.w700, color: color)),
          ),
        ],
      ),
    );
  }
}

class _QuickActions extends StatelessWidget {
  const _QuickActions();

  @override
  Widget build(BuildContext context) {
    final canScan = DocumentScannerService.instance.isSupported;

    return Row(
      children: [
        _ActionChip(
          icon: Icons.center_focus_weak,
          label: 'Scan Doc',
          enabled: canScan,
          onTap: () {
            if (!canScan) {
              LegalModals.snack(
                  context, 'Scanning is available on Android and iOS.');
              return;
            }
            final caseState = context.read<CaseBloc>().state;
            LegalModals.showCasePicker(
              context,
              caseState,
              title: 'Scan to case',
              subtitle: 'Choose where the scanned document is filed',
              emptyText: 'Create a case first to file your scan.',
              onPick: (c) => LegalModals.scanInto(context, caseId: c.id),
            );
          },
        ),
        const SizedBox(width: 9),
        _ActionChip(
          icon: Icons.text_fields,
          label: 'OCR Text',
          onTap: () => LegalModals.startOcr(context),
        ),
        const SizedBox(width: 9),
        _ActionChip(
          icon: Icons.picture_as_pdf,
          label: 'To PDF',
          onTap: () async {
            final result = await DocxToPdfService.pickDocx();
            if (result == null || result.files.isEmpty) return;
            final file = result.files.first;
            final bytes = file.bytes ??
                (file.path != null
                    ? await File(file.path!).readAsBytes()
                    : null);
            if (!context.mounted) return;
            if (bytes != null) {
              LegalModals.showDocxToPdfModal(context, bytes, file.name);
            } else {
              LegalModals.snack(context, 'Could not read document.');
            }
          },
        ),
        const SizedBox(width: 9),
        _ActionChip(
          icon: Icons.folder_open,
          label: 'Case Files',
          onTap: () => context.read<NavigationBloc>().add(const TabChanged('cases')),
        ),
      ],
    );
  }
}

class _ActionChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool enabled;

  const _ActionChip({
    required this.icon,
    required this.label,
    required this.onTap,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Opacity(
          opacity: enabled ? 1 : 0.45,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: LegalTheme.cardDecoration(),
            child: Column(
              children: [
                Icon(icon,
                    color: enabled ? LegalTheme.blue : LegalTheme.muted,
                    size: 20),
                const SizedBox(height: 6),
                Text(label,
                    style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: LegalTheme.ink),
                    textAlign: TextAlign.center),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SearchButton extends StatelessWidget {
  const _SearchButton();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        final caseState = context.read<CaseBloc>().state;
        LegalModals.showSearch(context, caseState);
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: LegalTheme.blue,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
                color: LegalTheme.blue.withValues(alpha: 0.32),
                blurRadius: 24,
                offset: const Offset(0, 10))
          ],
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search, color: Colors.white, size: 17),
            SizedBox(width: 10),
            Text('Search Documents',
                style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Colors.white)),
          ],
        ),
      ),
    );
  }
}

class _RecentDocs extends StatelessWidget {
  const _RecentDocs();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: LegalTheme.cardDecoration(radius: 20, blur: 16, opacity: 0.07),
      child: Column(
        children: [
          _RecentDocRow(
              title: 'Complaint_SmithJohnson.pdf',
              subtitle: 'Smith v. Johnson · 2.4 MB',
              date: 'Jun 21',
              bg: Colors.red[50]!,
              color: Colors.red),
          Divider(height: 1, color: Colors.grey[100], indent: 16, endIndent: 16),
          _RecentDocRow(
              title: 'Witness_Statement_OCR.pdf',
              subtitle: 'Mehta v. State Bank · 890 KB',
              date: 'Jun 20',
              bg: Colors.green[50]!,
              color: Colors.green),
          Divider(height: 1, color: Colors.grey[100], indent: 16, endIndent: 16),
          _RecentDocRow(
              title: 'Court_Order_2024CV0847.pdf',
              subtitle: 'Smith v. Johnson · 1.1 MB',
              date: 'Jun 18',
              bg: Colors.blue[50]!,
              color: Colors.blue),
        ],
      ),
    );
  }
}

class _RecentDocRow extends StatelessWidget {
  final String title;
  final String subtitle;
  final String date;
  final Color bg;
  final Color color;

  const _RecentDocRow({
    required this.title,
    required this.subtitle,
    required this.date,
    required this.bg,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration:
                BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10)),
            child: Icon(Icons.description, color: color, size: 17),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: LegalTheme.ink),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                Text(subtitle,
                    style: const TextStyle(fontSize: 11, color: LegalTheme.muted)),
              ],
            ),
          ),
          Text(date,
              style: const TextStyle(
                  fontSize: 10.5,
                  color: Color(0xFFB0B8C4),
                  fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
