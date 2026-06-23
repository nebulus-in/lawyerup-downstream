import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:open_filex/open_filex.dart';
import '../legal_theme.dart';
import '../../bloc/legal_bloc.dart';
import '../../../models/legal_models.dart';
import 'legal_modals.dart';

class DetailHeader extends StatelessWidget {
  final VoidCallback onBack;
  final String title;
  final String subtitle;
  final Widget? leading;
  final Widget? trailing;

  const DetailHeader({
    super.key,
    required this.onBack,
    required this.title,
    required this.subtitle,
    this.leading,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      color: Colors.white,
      child: Row(
        children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onBack,
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                  color: const Color(0xFFF0F2F5),
                  borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.arrow_back, size: 16),
            ),
          ),
          const SizedBox(width: 12),
          if (leading != null) ...[leading!, const SizedBox(width: 12)],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w700),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                Text(subtitle,
                    style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: LegalTheme.muted)),
              ],
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

class FileItem extends StatelessWidget {
  final int caseId;
  final CaseFile file;
  const FileItem({super.key, required this.caseId, required this.file});

  /// Opens a locally stored document with the system viewer, surfacing a clear
  /// message when nothing can handle it.
  Future<void> _open(BuildContext context) async {
    final result = await OpenFilex.open(file.path!);
    if (result.type == ResultType.done || !context.mounted) return;
    final message = switch (result.type) {
      ResultType.noAppToOpen => 'No app on this device can open PDFs.',
      ResultType.fileNotFound => 'This document is no longer available.',
      ResultType.permissionDenied => 'Permission denied opening this document.',
      _ => "Couldn't open this document.",
    };
    LegalModals.snack(context, message);
  }

  @override
  Widget build(BuildContext context) {
    final openable = file.isLocal;
    final isLongPressed = context.select((LegalBloc bloc) => bloc.state.longPressedId == file.id);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: openable ? () => _open(context) : null,
      onLongPress: () async {
        HapticFeedback.mediumImpact();
        final bloc = context.read<LegalBloc>();
        bloc.add(LongPressedIdChanged(file.id));
        await LegalModals.showFileOptions(context, caseId, file);
        bloc.add(const LongPressedIdChanged(null));
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: LegalTheme.cardDecoration(
          border: isLongPressed ? Border.all(color: LegalTheme.blue, width: 2) : null,
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                  color: openable ? LegalTheme.blueBg : const Color(0xFFF0F2F5),
                  borderRadius: BorderRadius.circular(10)),
              child: Icon(
                  openable ? Icons.picture_as_pdf_rounded : Icons.description,
                  color: openable ? LegalTheme.blue : const Color(0xFFAAB2BF),
                  size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(file.name,
                      style: const TextStyle(
                          fontSize: 13.5, fontWeight: FontWeight.w600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  Text('${file.size} • ${file.date}',
                      style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: LegalTheme.muted)),
                ],
              ),
            ),
            if (openable)
              const Icon(Icons.open_in_new_rounded,
                  color: LegalTheme.muted, size: 16),
          ],
        ),
      ),
    );
  }
}
