import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../legal_theme.dart';
import '../../bloc/blocs.dart';

/// A legal research destination the user can open in the in-app browser.
class ResearchSource {
  final String id;
  final String name;
  final String host;
  final String url;
  final String blurb;
  final String category;
  final String monogram;
  final Color color;
  final Color tint;

  const ResearchSource({
    required this.id,
    required this.name,
    required this.host,
    required this.url,
    required this.blurb,
    required this.category,
    required this.monogram,
    required this.color,
    required this.tint,
  });
}

/// The shelf of sources. Indian Kanoon leads because it is the broadest free
/// search; the rest cover statutes, apex-court judgments and commentary.
const List<ResearchSource> kResearchSources = [
  ResearchSource(
    id: 'indiankanoon',
    name: 'Indian Kanoon',
    host: 'indiankanoon.org',
    url: 'https://indiankanoon.org/',
    blurb: 'Search judgments, statutes and central & state legislation.',
    category: 'Case law',
    monogram: 'IK',
    color: Color(0xFF1463E0),
    tint: Color(0xFFE8F0FE),
  ),
  ResearchSource(
    id: 'indiacode',
    name: 'India Code',
    host: 'indiacode.nic.in',
    url: 'https://www.indiacode.nic.in/',
    blurb: 'The official repository of central and state Acts.',
    category: 'Statutes',
    monogram: 'IC',
    color: Color(0xFF1A8A4A),
    tint: Color(0xFFE8F5EE),
  ),
  ResearchSource(
    id: 'sci',
    name: 'Supreme Court of India',
    host: 'sci.gov.in',
    url: 'https://www.sci.gov.in/',
    blurb: 'Reportable judgments, cause lists and daily orders.',
    category: 'Judgments',
    monogram: 'SC',
    color: Color(0xFFC0392B),
    tint: Color(0xFFFCE8E8),
  ),
  ResearchSource(
    id: 'livelaw',
    name: 'LiveLaw',
    host: 'livelaw.in',
    url: 'https://www.livelaw.in/',
    blurb: 'Court reporting, analysis and legal commentary.',
    category: 'Legal news',
    monogram: 'LL',
    color: Color(0xFFE07A14),
    tint: Color(0xFFFFF4EC),
  ),
];

ResearchSource? researchSourceById(String? id) {
  if (id == null) return null;
  for (final s in kResearchSources) {
    if (s.id == id) return s;
  }
  return null;
}

class ResearchView extends StatelessWidget {
  const ResearchView({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      key: const ValueKey('research'),
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
      children: [
        const Text('Legal databases',
            style: TextStyle(
                fontSize: 18, fontWeight: FontWeight.w700, color: LegalTheme.ink)),
        const SizedBox(height: 18),
        ...kResearchSources.map((s) => _SourceCard(source: s)),
      ],
    );
  }
}

class _SourceCard extends StatelessWidget {
  final ResearchSource source;
  const _SourceCard({required this.source});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () =>
          context.read<NavigationBloc>().add(SourceSelected(source.id)),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: LegalTheme.cardDecoration(blur: 16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 48,
              height: 48,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: source.color,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                      color: source.color.withValues(alpha: 0.28),
                      blurRadius: 12,
                      offset: const Offset(0, 5))
                ],
              ),
              child: Text(
                source.monogram,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(source.name,
                      style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: LegalTheme.ink)),
                  const SizedBox(height: 3),
                  Text(source.blurb,
                      style: const TextStyle(
                          fontSize: 12.5,
                          height: 1.35,
                          fontWeight: FontWeight.w500,
                          color: LegalTheme.muted)),
                  const SizedBox(height: 11),
                  Row(
                    children: [
                      const Icon(Icons.language_rounded,
                          size: 13, color: LegalTheme.muted),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Text(source.host,
                            style: const TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                                color: LegalTheme.muted),
                            overflow: TextOverflow.ellipsis),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                            color: source.tint,
                            borderRadius: BorderRadius.circular(6)),
                        child: Text(source.category,
                            style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
                                color: source.color)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
