import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_doc_scanner/flutter_doc_scanner.dart';
import 'package:path_provider/path_provider.dart';

/// A physical document captured with the camera and saved as a PDF on disk.
class ScannedDocument {
  /// Absolute path to the persisted PDF inside the app's documents directory.
  final String path;

  /// File name (no directory) — used as the document's display name.
  final String fileName;

  /// Number of pages captured. 0 when the platform doesn't report a count.
  final int pageCount;

  /// Size of the saved PDF, in bytes.
  final int byteSize;

  const ScannedDocument({
    required this.path,
    required this.fileName,
    required this.pageCount,
    required this.byteSize,
  });

  /// Human-readable size, e.g. `1.2 MB` or `640 KB`.
  String get sizeLabel => formatFileSize(byteSize);
}

/// Thrown when scanning fails for a reason worth telling the user about — a
/// missing scanner module or an unreadable result. Backing out of the scanner
/// is not a failure: [DocumentScannerService.scan] returns null for that.
class DocumentScanException implements Exception {
  final String message;
  const DocumentScanException(this.message);
  @override
  String toString() => message;
}

/// Wraps the `flutter_doc_scanner` plugin, which scans physical documents with
/// Google ML Kit on Android and VisionKit on iOS.
///
/// Both run on-device through the system camera; there's no web or desktop
/// implementation, so [isSupported] is false there and the UI greys the action
/// out rather than offering something that can't run.
class DocumentScannerService {
  DocumentScannerService._();
  static final DocumentScannerService instance = DocumentScannerService._();

  /// Whether physical document scanning can run on this platform.
  bool get isSupported =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  /// Opens the camera scanner, then copies the resulting PDF into the app's
  /// documents directory so it outlives the system cache.
  ///
  /// Returns the saved [ScannedDocument], or null if the user backed out.
  /// Throws [DocumentScanException] on a real failure.
  Future<ScannedDocument?> scan({int pageLimit = 30}) async {
    if (!isSupported) {
      throw const DocumentScanException(
          'Document scanning is not available on this platform.');
    }

    final PdfScanResult? result;
    try {
      result = await FlutterDocScanner().getScannedDocumentAsPdf(page: pageLimit);
    } on DocScanException catch (e) {
      if (e.code == DocScanException.codeCancelled) return null;
      throw DocumentScanException(e.message);
    }

    if (result == null) return null; // Cancelled.
    return _persist(result);
  }

  Future<ScannedDocument> _persist(PdfScanResult result) async {
    final source = File(_toFilePath(result.pdfUri));
    if (!await source.exists()) {
      throw const DocumentScanException('The scanned file could not be read.');
    }

    final docsDir = await getApplicationDocumentsDirectory();
    final scansDir = Directory('${docsDir.path}/scanned_documents');
    if (!await scansDir.exists()) {
      await scansDir.create(recursive: true);
    }

    final fileName = 'Scan_${_timestamp()}.pdf';
    final saved = await source.copy('${scansDir.path}/$fileName');

    return ScannedDocument(
      path: saved.path,
      fileName: fileName,
      pageCount: result.pageCount,
      byteSize: await saved.length(),
    );
  }

  /// The plugin hands back a `file://` URI on Android and a bare path on iOS;
  /// normalise both to a filesystem path we can read.
  String _toFilePath(String uri) {
    final parsed = Uri.tryParse(uri);
    if (parsed != null && parsed.isScheme('file')) return parsed.toFilePath();
    return uri;
  }

  String _timestamp() {
    final now = DateTime.now();
    String two(int v) => v.toString().padLeft(2, '0');
    return '${now.year}${two(now.month)}${two(now.day)}_'
        '${two(now.hour)}${two(now.minute)}${two(now.second)}';
  }
}

/// Formats a byte count the way the rest of the app shows file sizes.
String formatFileSize(int bytes) {
  if (bytes < 1024) return '$bytes B';
  final kb = bytes / 1024;
  if (kb < 1024) return '${kb.toStringAsFixed(kb < 10 ? 1 : 0)} KB';
  final mb = kb / 1024;
  return '${mb.toStringAsFixed(mb < 10 ? 1 : 0)} MB';
}
