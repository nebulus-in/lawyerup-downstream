import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:open_filex/open_filex.dart';
import '../legal_theme.dart';
import '../../bloc/blocs.dart';
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

class SelectionHeader extends StatelessWidget {
  final int caseId;
  final List<int> selectedIds;
  final VoidCallback onClear;

  const SelectionHeader({
    super.key,
    required this.caseId,
    required this.selectedIds,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final count = selectedIds.length;
    final cases = context.select((CaseBloc bloc) => bloc.state.cases);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      color: LegalTheme.ink,
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            IconButton(
              onPressed: onClear,
              icon: const Icon(Icons.close, color: Colors.white),
              tooltip: 'Cancel selection',
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '$count Selected',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            if (count == 1)
              _HeaderAction(
                icon: Icons.drive_file_rename_outline_rounded,
                label: 'Rename',
                onTap: () {
                  final c = cases.firstWhere((c) => c.id == caseId);
                  final file = c.fileById(selectedIds.first);
                  if (file != null) {
                    LegalModals.showRenameFileModal(context, caseId, file);
                  }
                },
              ),
            _HeaderAction(
              icon: Icons.move_to_inbox_rounded,
              label: 'Move',
              onTap: () => LegalModals.showMoveFilesSheet(context, caseId, selectedIds),
            ),
            _HeaderAction(
              icon: Icons.delete_outline_rounded,
              label: 'Delete',
              onTap: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: Text('Delete $count items?'),
                    content: const Text('This action cannot be undone.'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text('CANCEL'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        child: const Text('DELETE', style: TextStyle(color: Colors.red)),
                      ),
                    ],
                  ),
                );
                if (confirm == true && context.mounted) {
                  context.read<FileBloc>().add(FilesDeleted(caseId, selectedIds));
                  LegalModals.snack(context, '$count documents deleted');
                }
              },
            ),
          ],
        ),
      ),
    );
  }

}

class _HeaderAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _HeaderAction({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(height: 2),
            Text(label, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600)),
          ],
        ),
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
    final isLongPressed = context.select((NavigationBloc bloc) => bloc.state.longPressedId == file.id);
    final isSelected = context.select((FileBloc bloc) => bloc.state.selectedFileIds.contains(file.id));
    final isMultiSelect = context.select((FileBloc bloc) => bloc.state.isMultiSelectMode);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        if (isMultiSelect) {
          context.read<FileBloc>().add(SelectionToggled(file.id));
        } else if (openable) {
          _open(context);
        }
      },
      onLongPress: () {
        HapticFeedback.mediumImpact();
        context.read<FileBloc>().add(SelectionToggled(file.id));
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: LegalTheme.cardDecoration(
          border: (isLongPressed || isSelected) ? Border.all(color: LegalTheme.blue, width: 2) : null,
        ),
        child: Row(
          children: [
            Stack(
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
                if (isSelected)
                  Positioned(
                    right: -2,
                    bottom: -2,
                    child: Container(
                      decoration: const BoxDecoration(
                        color: LegalTheme.blue,
                        shape: BoxShape.circle,
                      ),
                      padding: const EdgeInsets.all(2),
                      child: const Icon(Icons.check, color: Colors.white, size: 10),
                    ),
                  ),
              ],
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
            if (openable && !isMultiSelect)
              const Icon(Icons.open_in_new_rounded,
                  color: LegalTheme.muted, size: 16),
            if (isMultiSelect)
               Icon(
                 isSelected ? Icons.check_circle : Icons.radio_button_unchecked,
                 color: isSelected ? LegalTheme.blue : LegalTheme.muted,
                 size: 20,
               ),
          ],
        ),
      ),
    );
  }
}
