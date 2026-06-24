import 'package:flutter/foundation.dart' show listEquals, ValueListenable;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../legal_theme.dart';
import '../../bloc/blocs.dart';
import '../../../models/legal_models.dart';
import '../../../services/document_scanner_service.dart';
import '../../../services/download_service.dart';
import '../../../services/ocr_service.dart';

class LegalModals {
  static void showCasePicker(
    BuildContext context,
    CaseState state, {
    required String title,
    required String subtitle,
    required void Function(Case) onPick,
    bool Function(Case)? where,
    String? Function(Case)? trailingHint,
    String emptyText = 'No cases available yet.',
  }) {
    final cases =
        where == null ? state.cases : state.cases.where(where).toList();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (modalContext) => Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
        decoration: LegalTheme.sheetDecoration,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            grabber(),
            const SizedBox(height: 14),
            Text(title,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            Text(subtitle,
                style: const TextStyle(
                    fontSize: 12.5,
                    color: LegalTheme.muted,
                    fontWeight: FontWeight.w500)),
            const SizedBox(height: 16),
            if (cases.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(emptyText,
                    style: const TextStyle(fontSize: 13.5, color: LegalTheme.muted)),
              )
            else
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: cases.map((c) {
                    final hint = trailingHint?.call(c);
                    return GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () {
                        Navigator.pop(modalContext);
                        onPick(c);
                      },
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                            color: LegalTheme.field,
                            borderRadius: BorderRadius.circular(14)),
                        child: Row(
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                  color: LegalTheme.getCaseBg(c.type),
                                  borderRadius: BorderRadius.circular(10)),
                              child: Icon(Icons.folder,
                                  color: LegalTheme.getCaseColor(c.type), size: 18),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(c.name,
                                      style: const TextStyle(
                                          fontSize: 13.5,
                                          fontWeight: FontWeight.w700,
                                          color: LegalTheme.ink)),
                                  Text(c.number,
                                      style: const TextStyle(
                                          fontSize: 11.5, color: LegalTheme.muted)),
                                ],
                              ),
                            ),
                            if (hint != null) ...[
                              Text(hint,
                                  style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: LegalTheme.muted)),
                              const SizedBox(width: 8),
                            ],
                            const Icon(Icons.chevron_right, color: LegalTheme.muted, size: 18),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
          ],
        ),
      ),
    );
  }

  static void showSearch(BuildContext context, CaseState state) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalContext) => _SearchSheet(
        cases: state.cases,
        onOpenCase: (caseId) {
          final navBloc = context.read<NavigationBloc>();
          Navigator.pop(modalContext);
          navBloc.add(const TabChanged('cases'));
          navBloc.add(CaseSelected(caseId));
        },
      ),
    );
  }

  static void showNewCaseModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalContext) => _NewCaseModalContent(
        onSave: (name, number, court, type, folders) {
          context.read<CaseBloc>().add(CaseCreated(
                name: name,
                number: number,
                court: court,
                type: type,
                folders: folders,
              ));
          Navigator.pop(modalContext);
        },
      ),
    );
  }

  static void showEditCaseModal(BuildContext context, Case c) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalContext) => _EditCaseModalContent(
        original: c,
        onSave: (name, number, court, type, hearing) {
          context.read<CaseBloc>().add(CaseUpdated(
                caseId: c.id,
                name: name,
                number: number,
                court: court,
                type: type,
                hearing: hearing,
              ));
          Navigator.pop(modalContext);
          snack(context, 'Case details updated');
        },
      ),
    );
  }

  static void showAddCategoryModal(BuildContext context, int caseId) {
    final controller = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalContext) => Padding(
        padding:
            EdgeInsets.only(bottom: MediaQuery.of(modalContext).viewInsets.bottom),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: LegalTheme.sheetDecoration,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Add Category',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
              const SizedBox(height: 20),
              _buildInput('CATEGORY NAME', 'e.g. Discovery Documents', controller),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  context
                      .read<CategoryBloc>()
                      .add(CategoryAdded(caseId, controller.text));
                  Navigator.pop(modalContext);
                  snack(context, 'Folder created');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: LegalTheme.blue,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text('Save Category',
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static void showRenameCategoryModal(BuildContext context, int caseId, Category cat) {
    final controller = TextEditingController(text: cat.name);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalContext) => Padding(
        padding:
            EdgeInsets.only(bottom: MediaQuery.of(modalContext).viewInsets.bottom),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: LegalTheme.sheetDecoration,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Rename Folder',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
              const SizedBox(height: 20),
              _buildInput('FOLDER NAME', 'e.g. Evidence', controller),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  context
                      .read<CategoryBloc>()
                      .add(CategoryRenamed(caseId, cat.id, controller.text));
                  Navigator.pop(modalContext);
                  snack(context, 'Folder renamed');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: LegalTheme.blue,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text('Save Changes',
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static void showRenameFileModal(BuildContext context, int caseId, CaseFile file) {
    final controller = TextEditingController(text: file.name);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalContext) => Padding(
        padding:
            EdgeInsets.only(bottom: MediaQuery.of(modalContext).viewInsets.bottom),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: LegalTheme.sheetDecoration,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Rename Document',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
              const SizedBox(height: 20),
              _buildInput('DOCUMENT NAME', 'e.g. Witness_Statement.pdf', controller),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  context
                      .read<FileBloc>()
                      .add(FileRenamed(caseId, file.id, controller.text));
                  Navigator.pop(modalContext);
                  snack(context, 'Document renamed');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: LegalTheme.blue,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text('Save Changes',
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Offers the two ways to add a document — scan a physical one, or upload an
  /// existing file. [destinationLabel] names where it lands (a case or folder).
  static void showAddDocumentSheet(
    BuildContext context, {
    required int caseId,
    String? categoryName,
    required String destinationLabel,
  }) {
    final canScan = DocumentScannerService.instance.isSupported;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (modalContext) => Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
        decoration: LegalTheme.sheetDecoration,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            grabber(),
            const SizedBox(height: 14),
            const Text('Add document',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            Text('Add to $destinationLabel',
                style: const TextStyle(
                    fontSize: 12.5,
                    color: LegalTheme.muted,
                    fontWeight: FontWeight.w500)),
            const SizedBox(height: 16),
            _DocActionRow(
              icon: Icons.document_scanner_rounded,
              accent: LegalTheme.blue,
              accentBg: LegalTheme.blueBg,
              title: 'Scan document',
              subtitle: canScan
                  ? 'Capture pages with the camera and save as PDF'
                  : 'Available on Android and iOS',
              enabled: canScan,
              onTap: () {
                Navigator.pop(modalContext);
                scanInto(context, caseId: caseId, categoryName: categoryName);
              },
            ),
            const SizedBox(height: 10),
            _DocActionRow(
              icon: Icons.upload_file_rounded,
              accent: const Color(0xFF1A8A4A),
              accentBg: const Color(0xFFE8F5EE),
              title: 'Upload file',
              subtitle: 'Add a document already on your device',
              enabled: true,
              onTap: () {
                Navigator.pop(modalContext);
                context.read<FileBloc>().add(FileUploaded(caseId, categoryName));
                snack(context, 'File uploaded');
              },
            ),
          ],
        ),
      ),
    );
  }

  static Future<void> showCaseOptions(BuildContext context, Case c) async {
    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (modalContext) => Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
        decoration: LegalTheme.sheetDecoration,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            grabber(),
            const SizedBox(height: 14),
            Text(c.name,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            Text(c.number,
                style: const TextStyle(
                    fontSize: 12.5,
                    color: LegalTheme.muted,
                    fontWeight: FontWeight.w500)),
            const SizedBox(height: 16),
            _OptionRow(
              icon: Icons.edit_outlined,
              label: 'Edit details',
              onTap: () {
                Navigator.pop(modalContext);
                showEditCaseModal(context, c);
              },
            ),
            _OptionRow(
              icon: Icons.delete_outline_rounded,
              label: 'Delete case',
              isDestructive: true,
              onTap: () {
                Navigator.pop(modalContext);
                context.read<CaseBloc>().add(CaseDeleted(c.id));
                snack(context, 'Case deleted');
              },
            ),
          ],
        ),
      ),
    );
  }

  static Future<void> showCategoryOptions(BuildContext context, int caseId, Category cat) async {
    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (modalContext) => Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
        decoration: LegalTheme.sheetDecoration,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            grabber(),
            const SizedBox(height: 14),
            Text(cat.name,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            const Text('Folder options',
                style: TextStyle(
                    fontSize: 12.5,
                    color: LegalTheme.muted,
                    fontWeight: FontWeight.w500)),
            const SizedBox(height: 16),
            _OptionRow(
              icon: Icons.drive_file_rename_outline_rounded,
              label: 'Rename folder',
              onTap: () {
                Navigator.pop(modalContext);
                showRenameCategoryModal(context, caseId, cat);
              },
            ),
            _OptionRow(
              icon: Icons.delete_outline_rounded,
              label: 'Delete folder',
              subtitle: 'Files inside will move to uncategorized',
              isDestructive: true,
              onTap: () {
                Navigator.pop(modalContext);
                context.read<CategoryBloc>().add(CategoryDeleted(caseId, cat.id));
                snack(context, 'Folder deleted');
              },
            ),
          ],
        ),
      ),
    );
  }

  static void showMoveFilesSheet(BuildContext context, int caseId, List<int> fileIds) {
    final cases = context.read<CaseBloc>().state.cases;
    final c = cases.firstWhere((c) => c.id == caseId);
    final count = fileIds.length;
    final noun = count == 1 ? 'Document' : '$count documents';

    showFolderPicker(
      context,
      c,
      title: 'Move ${count == 1 ? 'document' : '$count documents'}',
      subtitle: 'Select a destination folder in ${c.name}',
      onPick: (categoryName) {
        context.read<FileBloc>().add(FilesMoved(caseId, fileIds, categoryName));
        snack(context, '$noun moved to ${categoryName ?? 'General'}');
      },
    );
  }

  /// Bottom sheet listing a case's folders — the uncategorized bucket first,
  /// then each category — and reports the chosen folder to [onPick]. [onPick]
  /// receives null for the uncategorized bucket and the category name otherwise.
  /// The sheet is dismissed before [onPick] runs.
  static void showFolderPicker(
    BuildContext context,
    Case c, {
    required String title,
    required String subtitle,
    required void Function(String? categoryName) onPick,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (modalContext) {
        void pick(String? categoryName) {
          Navigator.pop(modalContext);
          onPick(categoryName);
        }

        return Container(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
          decoration: LegalTheme.sheetDecoration,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              grabber(),
              const SizedBox(height: 14),
              Text(title,
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              Text(subtitle,
                  style: const TextStyle(
                      fontSize: 12.5,
                      color: LegalTheme.muted,
                      fontWeight: FontWeight.w500)),
              const SizedBox(height: 16),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    GestureDetector(
                      onTap: () => pick(null),
                      child: const _FolderPickerItem(
                          name: 'General (Uncategorized)'),
                    ),
                    ...c.categories.map((cat) => GestureDetector(
                          onTap: () => pick(cat.name),
                          child: _FolderPickerItem(name: cat.name),
                        )),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Launches the scanner and files the resulting PDF into [caseId] (optionally
  /// under [categoryName]). The scanner UI lives in a separate activity, so we
  /// grab the bloc and messenger up front — [context] may rebuild while the
  /// camera is open.
  static Future<void> scanInto(
    BuildContext context, {
    required int caseId,
    String? categoryName,
  }) async {
    final fileBloc = context.read<FileBloc>();
    final messenger = ScaffoldMessenger.of(context);
    try {
      final doc = await DocumentScannerService.instance.scan();
      if (doc == null) return; // Cancelled — nothing to say.
      fileBloc.add(DocumentScanned(caseId, categoryName, doc));
      _snack(
        messenger,
        doc.pageCount > 0
            ? 'Document scanned · ${doc.pageCount} '
                '${doc.pageCount == 1 ? 'page' : 'pages'} saved'
            : 'Document scanned and saved',
      );
    } on DocumentScanException catch (e) {
      _snack(messenger, e.message);
    }
  }

  static Future<void> startOcr(BuildContext context) async {
    final ocrService = OcrService();
    try {
      final text = await ocrService.pickAndRecognizeText();
      if (text != null && context.mounted) {
        showOcrResult(context, text);
      }
    } finally {
      ocrService.dispose();
    }
  }

  static void showOcrResult(BuildContext context, String text) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalContext) => Container(
        height: MediaQuery.of(context).size.height * 0.75,
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
        decoration: LegalTheme.sheetDecoration,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            grabber(),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Extracted Text',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                IconButton(
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: text));
                    snack(context, 'Text copied to clipboard');
                  },
                  icon: const Icon(Icons.copy_rounded, color: LegalTheme.blue),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: LegalTheme.field,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: SingleChildScrollView(
                  child: Text(
                    text,
                    style: const TextStyle(
                      fontSize: 14,
                      color: LegalTheme.ink,
                      height: 1.5,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(modalContext),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 50),
                      side: const BorderSide(color: LegalTheme.page),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    child: const Text('Done',
                        style: TextStyle(
                            color: LegalTheme.ink,
                            fontWeight: FontWeight.w700)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(modalContext);
                      _pickCaseAndFolderForOcr(context, text);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: LegalTheme.blue,
                      minimumSize: const Size(0, 50),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    child: const Text('Save to Case',
                        style: TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static void _pickCaseAndFolderForOcr(BuildContext context, String text) {
    final caseState = context.read<CaseBloc>().state;
    showCasePicker(
      context,
      caseState,
      title: 'Save OCR result',
      subtitle: 'Select a case to save this extracted text',
      onPick: (c) {
        if (c.categories.isEmpty) {
          context.read<FileBloc>().add(OcrTextSaved(
                caseId: c.id,
                text: text,
                fileName: 'OCR_Result_${DateTime.now().millisecondsSinceEpoch}.txt',
              ));
          snack(context, 'Text saved to ${c.name}');
        } else {
          _pickFolderForOcr(context, c, text);
        }
      },
    );
  }

  static void _pickFolderForOcr(BuildContext context, Case c, String text) {
    showFolderPicker(
      context,
      c,
      title: 'Select Folder',
      subtitle: 'Save to ${c.name}',
      onPick: (categoryName) {
        final isGeneral = categoryName == null;
        context.read<FileBloc>().add(OcrTextSaved(
              caseId: c.id,
              categoryName: categoryName,
              text: text,
              fileName: isGeneral
                  ? 'OCR_Result_${DateTime.now().millisecondsSinceEpoch}.txt'
                  : 'OCR_Result_$categoryName.txt',
            ));
        snack(context, 'Text saved to ${isGeneral ? c.name : categoryName}');
      },
    );
  }

  /// Shown when the in-app browser catches a download. Frames the captured file
  /// before routing it into a case folder. [download.suggestedName] is a preview
  /// — the saved name may differ once the server's headers are read.
  static void showSaveDownloadSheet(
    BuildContext context,
    PendingDownload download,
  ) {
    final suggestedName = download.suggestedName;
    final sourceHost = download.sourceHost;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (modalContext) => Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        decoration: LegalTheme.sheetDecoration,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            grabber(),
            const SizedBox(height: 14),
            const Text('Save this download',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            const Text('Keep this file with your case documents.',
                style: TextStyle(
                    fontSize: 12.5,
                    color: LegalTheme.muted,
                    fontWeight: FontWeight.w500)),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                  color: LegalTheme.field,
                  borderRadius: BorderRadius.circular(14)),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                        color: LegalTheme.blueBg,
                        borderRadius: BorderRadius.circular(12)),
                    child: Icon(_fileGlyph(suggestedName),
                        color: LegalTheme.blue, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(suggestedName,
                            style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: LegalTheme.ink),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            const Icon(Icons.language_rounded,
                                size: 12, color: LegalTheme.muted),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text('from $sourceHost',
                                  style: const TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w600,
                                      color: LegalTheme.muted),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(modalContext);
                _pickCaseAndFolderForDownload(context, download);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: LegalTheme.blue,
                elevation: 0,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              child: const Text('Choose case folder',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 4),
            Center(
              child: TextButton(
                onPressed: () => Navigator.pop(modalContext),
                child: const Text('Not now',
                    style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        color: LegalTheme.muted)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static void _pickCaseAndFolderForDownload(
      BuildContext context, PendingDownload download) {
    final caseState = context.read<CaseBloc>().state;
    showCasePicker(
      context,
      caseState,
      title: 'Save to a case',
      subtitle: 'Choose where to file this download',
      onPick: (c) {
        if (c.categories.isEmpty) {
          _runDownload(context,
              caseId: c.id,
              categoryName: null,
              destination: c.name,
              download: download);
        } else {
          _pickFolderForDownload(context, c, download);
        }
      },
    );
  }

  static void _pickFolderForDownload(
      BuildContext context, Case c, PendingDownload download) {
    showFolderPicker(
      context,
      c,
      title: 'Select folder',
      subtitle: 'Save to ${c.name}',
      onPick: (categoryName) => _runDownload(context,
          caseId: c.id,
          categoryName: categoryName,
          destination: categoryName ?? c.name,
          download: download),
    );
  }

  /// Fetches the file and files it into the chosen destination, showing a
  /// progress dialog and a result snack. The dialog and messenger are resolved
  /// up front because the picker sheets are gone by the time this runs.
  static Future<void> _runDownload(
    BuildContext context, {
    required int caseId,
    required String? categoryName,
    required String destination,
    required PendingDownload download,
  }) async {
    final messenger = ScaffoldMessenger.of(context);
    final fileBloc = context.read<FileBloc>();
    final navigator = Navigator.of(context, rootNavigator: true);
    final progress =
        ValueNotifier<_DownloadProgress>(const _DownloadProgress(0, null));

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) =>
          _DownloadingDialog(destination: destination, progress: progress),
    );

    try {
      final file = await DownloadService.instance.download(
        download.url,
        headers: download.headers,
        fallbackName: download.suggestedName,
        onProgress: (received, total) =>
            progress.value = _DownloadProgress(received, total),
      );
      navigator.pop();
      fileBloc.add(FileDownloaded(caseId, categoryName, file));
      _snack(messenger, 'Saved ${file.fileName} to $destination');
    } on DownloadException catch (e) {
      navigator.pop();
      _snack(messenger, e.message);
    } catch (_) {
      navigator.pop();
      _snack(messenger, "Couldn't save the download. Try again.");
    } finally {
      progress.dispose();
    }
  }

  static IconData _fileGlyph(String name) {
    final lower = name.toLowerCase();
    if (lower.endsWith('.pdf')) return Icons.picture_as_pdf_rounded;
    if (lower.endsWith('.zip') ||
        lower.endsWith('.rar') ||
        lower.endsWith('.7z')) {
      return Icons.folder_zip_rounded;
    }
    if (lower.endsWith('.xls') ||
        lower.endsWith('.xlsx') ||
        lower.endsWith('.csv')) {
      return Icons.table_chart_rounded;
    }
    return Icons.description_rounded;
  }

  static Widget grabber() {
    return Center(
      child: Container(
        width: 40,
        height: 4,
        decoration: BoxDecoration(
            color: const Color(0xFFE2E6EC),
            borderRadius: BorderRadius.circular(2)),
      ),
    );
  }

  static void snack(BuildContext context, String message) =>
      _snack(ScaffoldMessenger.of(context), message);

  /// Shows a snack from a [ScaffoldMessengerState] captured earlier — used when
  /// the originating widget (e.g. a bottom sheet) is gone by the time the
  /// message is ready, as with the document scanner's async result.
  static void _snack(ScaffoldMessengerState messenger, String message) {
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(message,
            style: const TextStyle(fontWeight: FontWeight.w600)),
        behavior: SnackBarBehavior.floating,
        backgroundColor: LegalTheme.ink,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 2),
      ));
  }

  static Widget _buildInput(String label, String hint, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w600, color: LegalTheme.muted)),
          const SizedBox(height: 6),
          TextField(
            controller: controller,
            decoration: InputDecoration(
              hintText: hint,
              filled: true,
              fillColor: const Color(0xFFF8F9FC),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: LegalTheme.page)),
              enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: LegalTheme.page)),
            ),
          ),
        ],
      ),
    );
  }

  /// Opens a sheet to pick a month and year using standard iOS/Android style scroll wheel picker columns.
  static void showMonthYearPicker(
    BuildContext context, {
    required DateTime initialDate,
    required DateTime minDate,
    required DateTime maxDate,
    required void Function(DateTime) onSelected,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (modalContext) => _MonthYearWheelPickerSheet(
        initialDate: initialDate,
        minDate: minDate,
        maxDate: maxDate,
        onSelected: (date) {
          Navigator.pop(modalContext);
          onSelected(date);
        },
      ),
    );
  }
}

class _MonthYearWheelPickerSheet extends StatefulWidget {
  final DateTime initialDate;
  final DateTime minDate;
  final DateTime maxDate;
  final ValueChanged<DateTime> onSelected;

  const _MonthYearWheelPickerSheet({
    required this.initialDate,
    required this.minDate,
    required this.maxDate,
    required this.onSelected,
  });

  @override
  State<_MonthYearWheelPickerSheet> createState() => _MonthYearWheelPickerSheetState();
}

class _MonthYearWheelPickerSheetState extends State<_MonthYearWheelPickerSheet> {
  late FixedExtentScrollController _monthController;
  late FixedExtentScrollController _yearController;
  late List<int> _years;
  late int _selectedMonthIndex;
  late int _selectedYearIndex;

  @override
  void initState() {
    super.initState();
    _years = [];
    for (var y = widget.minDate.year; y <= widget.maxDate.year; y++) {
      _years.add(y);
    }

    final initMonth = widget.initialDate.month;
    final initYear = widget.initialDate.year;

    _selectedMonthIndex = initMonth - 1;
    _selectedYearIndex = _years.indexOf(initYear);
    if (_selectedYearIndex == -1) _selectedYearIndex = 0;

    _monthController = FixedExtentScrollController(initialItem: _selectedMonthIndex);
    _yearController = FixedExtentScrollController(initialItem: _selectedYearIndex);
  }

  @override
  void dispose() {
    _monthController.dispose();
    _yearController.dispose();
    super.dispose();
  }

  void _confirm() {
    final year = _years[_selectedYearIndex];
    final month = _selectedMonthIndex + 1;
    var targetDate = DateTime(year, month);

    if (targetDate.isBefore(widget.minDate)) {
      targetDate = widget.minDate;
    } else if (targetDate.isAfter(widget.maxDate)) {
      targetDate = widget.maxDate;
    }

    widget.onSelected(targetDate);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
      decoration: LegalTheme.sheetDecoration,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          LegalModals.grabber(),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Select Date',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 2),
                  const Text('Scroll columns to choose month and year',
                      style: TextStyle(fontSize: 12.5, color: LegalTheme.muted, fontWeight: FontWeight.w500)),
                ],
              ),
              GestureDetector(
                onTap: _confirm,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: LegalTheme.blue,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text(
                    'Done',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13.5),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 180,
            child: Row(
              children: [
                // Year picker
                Expanded(
                  child: ListWheelScrollView.useDelegate(
                    controller: _yearController,
                    itemExtent: 38,
                    perspective: 0.006,
                    diameterRatio: 1.2,
                    physics: const FixedExtentScrollPhysics(),
                    onSelectedItemChanged: (index) {
                      setState(() => _selectedYearIndex = index);
                    },
                    childDelegate: ListWheelChildBuilderDelegate(
                      childCount: _years.length,
                      builder: (context, index) {
                        final active = _selectedYearIndex == index;
                        return Center(
                          child: Text(
                            '${_years[index]}',
                            style: TextStyle(
                              fontSize: active ? 16.5 : 14.5,
                              fontWeight:
                              active ? FontWeight.w700 : FontWeight.w500,
                              color: active
                                  ? LegalTheme.blue
                                  : LegalTheme.ink.withValues(alpha: 0.5),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),

                Container(
                  width: 1,
                  height: 140,
                  color: LegalTheme.page,
                ),

                // Month picker
                Expanded(
                  child: ListWheelScrollView.useDelegate(
                    controller: _monthController,
                    itemExtent: 38,
                    perspective: 0.006,
                    diameterRatio: 1.2,
                    physics: const FixedExtentScrollPhysics(),
                    onSelectedItemChanged: (index) {
                      setState(() => _selectedMonthIndex = index);
                    },
                    childDelegate: ListWheelChildBuilderDelegate(
                      childCount: 12,
                      builder: (context, index) {
                        final active = _selectedMonthIndex == index;
                        return Center(
                          child: Text(
                            LegalTheme.monthFull[index],
                            style: TextStyle(
                              fontSize: active ? 16.5 : 14.5,
                              fontWeight:
                              active ? FontWeight.w700 : FontWeight.w500,
                              color: active
                                  ? LegalTheme.blue
                                  : LegalTheme.ink.withValues(alpha: 0.5),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OptionRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? subtitle;
  final bool isDestructive;
  final VoidCallback onTap;

  const _OptionRow({
    required this.icon,
    required this.label,
    this.subtitle,
    this.isDestructive = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = isDestructive ? const Color(0xFFE03A1E) : LegalTheme.ink;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w600, color: color)),
                  if (subtitle != null)
                    Text(subtitle!,
                        style: const TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w500,
                            color: LegalTheme.muted)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FolderPickerItem extends StatelessWidget {
  final String name;
  const _FolderPickerItem({required this.name});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
          color: LegalTheme.field, borderRadius: BorderRadius.circular(14)),
      child: Row(
        children: [
          const Icon(Icons.folder_rounded, color: LegalTheme.muted, size: 20),
          const SizedBox(width: 12),
          Text(name,
              style: const TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w700, color: LegalTheme.ink)),
          const Spacer(),
          const Icon(Icons.chevron_right, color: LegalTheme.muted, size: 18),
        ],
      ),
    );
  }
}

/// Download progress snapshot. [total] is null until (or unless) the server
/// reports a content length, which switches the bar to indeterminate.
class _DownloadProgress {
  final int received;
  final int? total;
  const _DownloadProgress(this.received, this.total);

  /// Completed fraction in [0, 1], or null while the total is unknown — which
  /// switches the progress bar to indeterminate.
  double? get fraction =>
      (total != null && total! > 0) ? (received / total!).clamp(0.0, 1.0) : null;

  /// Caption shown under the bar, with the percentage derived from [fraction]
  /// so the ratio has a single source of truth.
  String get label {
    final f = fraction;
    if (f != null) {
      return '${(f * 100).round()}% · '
          '${formatFileSize(received)} of ${formatFileSize(total!)}';
    }
    if (received > 0) return '${formatFileSize(received)} downloaded';
    return 'Starting…';
  }
}

class _DownloadingDialog extends StatelessWidget {
  final String destination;
  final ValueListenable<_DownloadProgress> progress;

  const _DownloadingDialog(
      {required this.destination, required this.progress});

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: SizedBox(
          width: 280,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(22, 22, 22, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                          color: LegalTheme.blueBg,
                          borderRadius: BorderRadius.circular(11)),
                      child: const Icon(Icons.download_rounded,
                          color: LegalTheme.blue, size: 19),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Saving download',
                              style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  color: LegalTheme.ink)),
                          const SizedBox(height: 2),
                          Text('Filing into $destination…',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: LegalTheme.muted)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                ValueListenableBuilder<_DownloadProgress>(
                  valueListenable: progress,
                  builder: (context, p, _) => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: p.fraction,
                          minHeight: 6,
                          backgroundColor: LegalTheme.page,
                          valueColor:
                              const AlwaysStoppedAnimation(LegalTheme.blue),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(p.label,
                          style: const TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              color: LegalTheme.muted)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DocActionRow extends StatelessWidget {
  final IconData icon;
  final Color accent;
  final Color accentBg;
  final String title;
  final String subtitle;
  final bool enabled;
  final VoidCallback onTap;

  const _DocActionRow({
    required this.icon,
    required this.accent,
    required this.accentBg,
    required this.title,
    required this.subtitle,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final row = Opacity(
      opacity: enabled ? 1 : 0.55,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
            color: LegalTheme.field, borderRadius: BorderRadius.circular(14)),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                  color: enabled ? accentBg : const Color(0xFFECEEF2),
                  borderRadius: BorderRadius.circular(12)),
              child: Icon(icon,
                  color: enabled ? accent : LegalTheme.muted, size: 21),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: LegalTheme.ink)),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w500,
                          color: LegalTheme.muted)),
                ],
              ),
            ),
            if (enabled)
              const Icon(Icons.chevron_right, color: LegalTheme.muted, size: 18)
            else
              const Icon(Icons.lock_outline_rounded,
                  color: LegalTheme.muted, size: 16),
          ],
        ),
      ),
    );

    if (!enabled) return row;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: row,
    );
  }
}

class _NewCaseModalContent extends StatefulWidget {
  final void Function(String name, String number, String court, String type, List<String> folders) onSave;

  const _NewCaseModalContent({required this.onSave});

  @override
  State<_NewCaseModalContent> createState() => _NewCaseModalContentState();
}

class _NewCaseModalContentState extends State<_NewCaseModalContent> {
  final _nameController = TextEditingController();
  final _numberController = TextEditingController();
  final _courtController = TextEditingController();
  final _folderInput = TextEditingController();

  String selectedType = 'CIVIL';
  late List<String> _folders = LegalTheme.foldersForType(selectedType);

  @override
  void dispose() {
    _nameController.dispose();
    _numberController.dispose();
    _courtController.dispose();
    _folderInput.dispose();
    super.dispose();
  }

  bool get _isDefaultSet =>
      listEquals(LegalTheme.foldersForType(selectedType), _folders);

  void _selectType(String type) {
    setState(() {
      final untouched = _isDefaultSet;
      selectedType = type;
      if (untouched) _folders = LegalTheme.foldersForType(type);
    });
  }

  void _removeFolder(String name) => setState(() => _folders.remove(name));
  void _resetFolders() => setState(() => _folders = LegalTheme.foldersForType(selectedType));

  void _addFolder() {
    final name = _folderInput.text.trim();
    if (name.isEmpty) return;
    final exists = _folders.any((f) => f.toLowerCase() == name.toLowerCase());
    _folderInput.clear();
    if (exists) return;
    setState(() => _folders.add(name));
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 24,
          right: 24,
          top: 24),
      decoration: LegalTheme.sheetDecoration,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Create New Case',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close)),
              ],
            ),
            const SizedBox(height: 20),
            LegalModals._buildInput('CASE NAME', 'e.g. Doe v. Roe', _nameController),
            LegalModals._buildInput('CASE NUMBER', 'e.g. 2026-CV-001', _numberController),
            LegalModals._buildInput('COURT', 'e.g. District Court, NY', _courtController),
            const Text('CASE TYPE',
                style: TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w600, color: LegalTheme.muted)),
            const SizedBox(height: 8),
            _CaseTypeSelector(selected: selectedType, onSelect: _selectType),
            const SizedBox(height: 22),
            _buildFoldersSection(),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () =>
                  widget.onSave(_nameController.text, _numberController.text, _courtController.text, selectedType, List<String>.from(_folders)),
              style: ElevatedButton.styleFrom(
                backgroundColor: LegalTheme.blue,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              child: Text(
                  _folders.isEmpty
                      ? 'Create Case'
                      : 'Create Case · ${_folders.length} '
                          '${_folders.length == 1 ? 'folder' : 'folders'}',
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildFoldersSection() {
    final typeLabel =
        '${selectedType[0]}${selectedType.substring(1).toLowerCase()}';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('CASE FOLDERS (${_folders.length})',
                style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: LegalTheme.muted)),
            const Spacer(),
            if (!_isDefaultSet)
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _resetFolders,
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.refresh_rounded, size: 13, color: LegalTheme.blue),
                    SizedBox(width: 3),
                    Text('Reset',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: LegalTheme.blue)),
                  ],
                ),
              ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          'Suggested for $typeLabel cases. Remove any you don’t need or '
          'add your own - you can change these later.',
          style: const TextStyle(
              fontSize: 11.5,
              height: 1.35,
              fontWeight: FontWeight.w500,
              color: LegalTheme.muted),
        ),
        const SizedBox(height: 12),
        if (_folders.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
            decoration: BoxDecoration(
              color: const Color(0xFFF8F9FC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: LegalTheme.page),
            ),
            child: const Text(
                'No folders - the case starts empty. Add one below.',
                style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                    color: LegalTheme.muted)),
          )
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (var i = 0; i < _folders.length; i++)
                _folderChip(_folders[i], i),
          ],
          ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF8F9FC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: LegalTheme.page),
                ),
                child: TextField(
                  controller: _folderInput,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _addFolder(),
                  decoration: const InputDecoration(
                    hintText: 'Add a folder…',
                    isCollapsed: true,
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 14, vertical: 15),
                    border: InputBorder.none,
                    hintStyle: TextStyle(color: LegalTheme.muted, fontSize: 14),
                  ),
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w600),
                ),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _addFolder,
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: LegalTheme.blue,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.add_rounded,
                    color: Colors.white, size: 22),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _folderChip(String name, int index) {
    final colors = LegalTheme.folderPalette[index % LegalTheme.folderPalette.length];
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 7, 8, 7),
      decoration: BoxDecoration(
        color: colors[1],
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.folder_rounded, size: 15, color: colors[0]),
          const SizedBox(width: 6),
          Text(name,
              style: const TextStyle(
                  fontSize: 12.5, fontWeight: FontWeight.w700, color: LegalTheme.ink)),
          const SizedBox(width: 6),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => _removeFolder(name),
            child: Icon(Icons.close_rounded,
                size: 14, color: colors[0].withValues(alpha: 0.7)),
          ),
        ],
      ),
    );
  }
}

class _EditCaseModalContent extends StatefulWidget {
  final Case original;
  final void Function(String name, String number, String court, String type,
      String hearing) onSave;

  const _EditCaseModalContent({required this.original, required this.onSave});

  @override
  State<_EditCaseModalContent> createState() => _EditCaseModalContentState();
}

class _EditCaseModalContentState extends State<_EditCaseModalContent> {
  late final TextEditingController _name;
  late final TextEditingController _number;
  late final TextEditingController _court;
  late String _type;
  DateTime? _hearing;

  @override
  void initState() {
    super.initState();
    final c = widget.original;
    _name = TextEditingController(text: c.name);
    _number =
        TextEditingController(text: c.number == 'Pending' ? '' : c.number);
    _court = TextEditingController(text: c.court == 'TBD' ? '' : c.court);
    _type = _caseTypes.contains(c.type) ? c.type : 'CIVIL';
    _hearing = c.hearingDate;
  }

  @override
  void dispose() {
    _name.dispose();
    _number.dispose();
    _court.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 24,
          right: 24,
          top: 24),
      decoration: LegalTheme.sheetDecoration,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Edit case details',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close)),
              ],
            ),
            const SizedBox(height: 12),
            LegalModals._buildInput('CASE NAME', 'e.g. Doe v. Roe', _name),
            LegalModals._buildInput('CASE NUMBER', 'e.g. 2026-CV-001', _number),
            LegalModals._buildInput('COURT', 'e.g. District Court, NY', _court),
            _dateField(
              label: 'NEXT HEARING (OPTIONAL)',
              placeholder: 'Set a hearing date',
              value: _hearing == null ? null : Case.formatHearing(_hearing!),
              onPick: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _hearing ?? DateTime(2026, 6, 22),
                  firstDate: DateTime(2000),
                  lastDate: DateTime(2100),
                );
                if (picked != null) setState(() => _hearing = picked);
              },
              onClear: () => setState(() => _hearing = null),
            ),
            const Text('CASE TYPE',
                style: TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w600, color: LegalTheme.muted)),
            const SizedBox(height: 8),
            _CaseTypeSelector(
                selected: _type,
                onSelect: (type) => setState(() => _type = type)),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => widget.onSave(
                _name.text.trim(),
                _number.text.trim(),
                _court.text.trim(),
                _type,
                _hearing == null ? '-' : Case.formatHearing(_hearing!),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: LegalTheme.blue,
                minimumSize: const Size(double.infinity, 50),
                shape:
                    RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: const Text('Save changes',
                  style:
                      TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _dateField({
    required String label,
    required String placeholder,
    required String? value,
    required VoidCallback onPick,
    required VoidCallback onClear,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w600, color: LegalTheme.muted)),
          const SizedBox(height: 6),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onPick,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 15),
              decoration: BoxDecoration(
                color: const Color(0xFFF8F9FC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: LegalTheme.page),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today_outlined,
                      size: 16, color: LegalTheme.muted),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      value ?? placeholder,
                      style: TextStyle(
                        fontSize: 15,
                        color: value == null ? LegalTheme.muted : LegalTheme.ink,
                      ),
                    ),
                  ),
                  if (value != null)
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: onClear,
                      child: const Icon(Icons.close, size: 16, color: LegalTheme.muted),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DocHit {
  final String name;
  final String size;
  final String date;
  final String caseName;
  final int caseId;
  const _DocHit(this.name, this.size, this.date, this.caseName, this.caseId);
}

class _SearchSheet extends StatefulWidget {
  final List<Case> cases;
  final void Function(int caseId) onOpenCase;

  const _SearchSheet({required this.cases, required this.onOpenCase});

  @override
  State<_SearchSheet> createState() => _SearchSheetState();
}

class _SearchSheetState extends State<_SearchSheet> {
  final _controller = TextEditingController();
  String _query = '';
  late final List<_DocHit> _all;

  @override
  void initState() {
    super.initState();
    _all = [
      for (final c in widget.cases)
        for (final f in c.allFiles)
          _DocHit(f.name, f.size, f.date, c.name, c.id),
    ];
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final q = _query.trim().toLowerCase();
    final results = q.isEmpty
        ? _all
        : _all
            .where((h) =>
                h.name.toLowerCase().contains(q) ||
                h.caseName.toLowerCase().contains(q))
            .toList();

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        height: MediaQuery.of(context).size.height * 0.82,
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
        decoration: LegalTheme.sheetDecoration,
        child: Column(
          children: [
            LegalModals.grabber(),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                  color: LegalTheme.field, borderRadius: BorderRadius.circular(14)),
              child: Row(
                children: [
                  const Icon(Icons.search, color: LegalTheme.muted, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      autofocus: true,
                      onChanged: (v) => setState(() => _query = v),
                      decoration: const InputDecoration(
                        hintText: 'Search documents and cases',
                        border: InputBorder.none,
                        isCollapsed: true,
                        contentPadding: EdgeInsets.symmetric(vertical: 14),
                        hintStyle: TextStyle(color: LegalTheme.muted, fontSize: 14),
                      ),
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                  ),
                  if (_query.isNotEmpty)
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () {
                        _controller.clear();
                        setState(() => _query = '');
                      },
                      child: const Icon(Icons.close, color: LegalTheme.muted, size: 18),
                    ),
                ],
              ),
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(
                    '${results.length} ${results.length == 1 ? 'result' : 'results'}',
                    style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: LegalTheme.muted)),
              ),
            ),
            Expanded(
              child: results.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.search_off,
                              color: Color(0xFFCBD2DC), size: 40),
                          const SizedBox(height: 12),
                          Text('No documents match "$_query"',
                              style: const TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF6B7280))),
                          const SizedBox(height: 4),
                          const Text('Try a different name or case',
                              style: TextStyle(fontSize: 12, color: LegalTheme.muted)),
                        ],
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.only(bottom: 20),
                      itemCount: results.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final hit = results[index];
                        return GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () => widget.onOpenCase(hit.caseId),
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                                color: LegalTheme.field,
                                borderRadius: BorderRadius.circular(14)),
                            child: Row(
                              children: [
                                Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(10)),
                                  child: const Icon(Icons.description,
                                      color: LegalTheme.blue, size: 18),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(hit.name,
                                          style: const TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w700,
                                              color: LegalTheme.ink),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis),
                                      const SizedBox(height: 2),
                                      Text(
                                          '${hit.caseName} · ${hit.size} · ${hit.date}',
                                          style: const TextStyle(
                                              fontSize: 11, color: LegalTheme.muted),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis),
                                    ],
                                  ),
                                ),
                                const Icon(Icons.chevron_right,
                                    color: LegalTheme.muted, size: 18),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

const _caseTypes = ['CIVIL', 'CRIMINAL', 'FAMILY', 'CORPORATE'];

class _CaseTypeSelector extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onSelect;

  const _CaseTypeSelector({required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _caseTypes.map((type) {
        final active = selected == type;
        return GestureDetector(
          onTap: () => onSelect(type),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: active ? LegalTheme.blueBg : const Color(0xFFF0F2F5),
              border: Border.all(
                  color: active ? LegalTheme.blue : Colors.transparent,
                  width: 1.5),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              type,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: active ? FontWeight.w700 : FontWeight.w600,
                color: active ? LegalTheme.blue : LegalTheme.muted,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
