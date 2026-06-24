import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter/services.dart' show rootBundle;
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_native_html_to_pdf/flutter_native_html_to_pdf.dart';

import 'document_scanner_service.dart' show formatFileSize, uniqueFilePath;

/// A DOCX rendered to PDF and saved into the app's documents directory, so the
/// converted document outlives the preview and can be reopened from a case.
class ConvertedPdf {
  /// Absolute path to the saved PDF.
  final String path;

  /// File name (no directory) — used as the document's display name.
  final String fileName;

  /// Size of the saved PDF, in bytes.
  final int byteSize;

  const ConvertedPdf({
    required this.path,
    required this.fileName,
    required this.byteSize,
  });

  String get sizeLabel => formatFileSize(byteSize);
}

class DocxToPdfService {
  static Future<FilePickerResult?> pickDocx() async {
    return await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['docx'],
      withData: true,
    );
  }

  /// The bundled mammoth.js source, loaded once from assets. Inlined into the
  /// preview HTML so conversion never depends on the network or a CDN — loading
  /// a remote `<script src>` into a baseUrl-less WebView document is blocked by
  /// Android's null-origin policy, which left the converter hanging forever.
  static Future<String> loadMammothJs() =>
      rootBundle.loadString('assets/js/mammoth.browser.min.js');

  static String generateHtml(Uint8List docxBytes, {required String mammothJs}) {
    final base64Docx = base64Encode(docxBytes);
    return '''
<!DOCTYPE html>
<html>
<head>
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <script>$mammothJs</script>
    <style>
        body { font-family: sans-serif; padding: 20px; line-height: 1.6; color: #1e293b; }
        img { max-width: 100%; height: auto; border-radius: 8px; margin: 10px 0; }
        table { border-collapse: collapse; width: 100%; margin: 15px 0; }
        th, td { border: 1px solid #e2e8f0; padding: 10px; text-align: left; }
        th { background-color: #f8fafc; font-weight: 600; }
        h1, h2, h3, h4, h5, h6 { margin-top: 1.5em; margin-bottom: 0.5em; color: #0f172a; }
        p { margin-bottom: 1em; }
        .loading { text-align: center; margin-top: 50px; font-size: 16px; color: #64748b; font-weight: 500; }
        
        /* Print styles */
        @media print {
            body { padding: 0; color: #000; }
            .loading { display: none; }
        }
    </style>
</head>
<body>
    <div id="loading" class="loading">Converting document...</div>
    <div id="content"></div>

    <script>
        function convert() {
            var base64 = "$base64Docx";
            var binary_string = window.atob(base64);
            var len = binary_string.length;
            var bytes = new Uint8Array(len);
            for (var i = 0; i < len; i++) {
                bytes[i] = binary_string.charCodeAt(i);
            }
            
            mammoth.convertToHtml({arrayBuffer: bytes.buffer})
                .then(function(result) {
                    document.getElementById("loading").style.display = "none";
                    document.getElementById("content").innerHTML = result.value;
                    if (window.flutter_inappwebview) {
                        // Hand the converted body to Dart now, while it lives in
                        // JS. Reading it back later via evaluateJavascript is
                        // unreliable: Android's WebView truncates large return
                        // values, and an image-bearing DOCX inlines megabytes of
                        // base64 here.
                        window.flutter_inappwebview.callHandler('onConversionComplete', result.value);
                    }
                })
                .catch(function(err) {
                    document.getElementById("loading").innerHTML = "Error: " + err.message;
                    if (window.flutter_inappwebview) {
                        window.flutter_inappwebview.callHandler('onConversionError', String(err && err.message ? err.message : err));
                    }
                });
        }

        // Surface anything that escapes the promise chain (e.g. a parse error
        // thrown synchronously) so Dart never waits on a dead conversion.
        window.onerror = function(message) {
            if (window.flutter_inappwebview) {
                window.flutter_inappwebview.callHandler('onConversionError', String(message));
            }
        };

        // Use a small timeout to let the UI render the loading state first
        setTimeout(convert, 100);
    </script>
</body>
</html>
''';
  }

  /// Wraps the already-converted document body (the `#content` innerHTML pulled
  /// out of the preview WebView) in a self-contained, script-free HTML document.
  /// This is what gets rendered to PDF, so it carries no network dependencies —
  /// mammoth has already run by this point.
  static String buildPrintableHtml(String contentHtml) {
    return '''
<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8">
    <style>
        body { font-family: sans-serif; padding: 24px; line-height: 1.6; color: #1e293b; }
        img { max-width: 100%; height: auto; }
        table { border-collapse: collapse; width: 100%; margin: 15px 0; }
        th, td { border: 1px solid #e2e8f0; padding: 10px; text-align: left; }
        th { background-color: #f8fafc; font-weight: 600; }
        h1, h2, h3, h4, h5, h6 { margin-top: 1.5em; margin-bottom: 0.5em; color: #0f172a; }
        p { margin-bottom: 1em; }
    </style>
</head>
<body>
$contentHtml
</body>
</html>
''';
  }

  /// Renders [contentHtml] to a PDF and persists it under
  /// `documents/converted_pdfs`, returning the saved [ConvertedPdf]. The on-disk
  /// path lets the document be reopened later, the same way scans and downloads
  /// are kept. [originalName] is the picked DOCX name; its extension is swapped
  /// for `.pdf`.
  static Future<ConvertedPdf> generateAndSave({
    required String contentHtml,
    required String originalName,
  }) async {
    // flutter_native_html_to_pdf renders the HTML through the platform's native
    // PDF engine (Android's print framework / iOS UIPrintPageRenderer). It can
    // stall if the underlying renderer never reports back, so we cap it.
    debugPrint('DOCX→PDF: rendering ${contentHtml.length} chars to PDF…');
    final pdfBytes = await HtmlToPdfConverter()
        .convertHtmlToPdfBytes(html: buildPrintableHtml(contentHtml))
        .timeout(const Duration(seconds: 30), onTimeout: () {
      throw TimeoutException(
          'PDF rendering timed out — the HTML renderer did not respond.');
    });
    debugPrint('DOCX→PDF: rendered ${pdfBytes.length} bytes');

    final docsDir = await getApplicationDocumentsDirectory();
    final pdfDir = Directory('${docsDir.path}/converted_pdfs');
    if (!await pdfDir.exists()) {
      await pdfDir.create(recursive: true);
    }

    final path = uniqueFilePath(pdfDir.path, _pdfNameFor(originalName));
    final target = File(path);
    await target.writeAsBytes(pdfBytes, flush: true);

    return ConvertedPdf(
      path: target.path,
      fileName: path.split('/').last,
      byteSize: await target.length(),
    );
  }

  /// Maps a picked document name onto the converted PDF's name: a `.docx`
  /// extension is swapped for `.pdf`, and a `.pdf` is left alone.
  static String _pdfNameFor(String originalName) {
    final lower = originalName.toLowerCase();
    if (lower.endsWith('.docx')) {
      return '${originalName.substring(0, originalName.length - 5)}.pdf';
    }
    if (lower.endsWith('.pdf')) return originalName;
    return '$originalName.pdf';
  }
}
