import 'dart:io';

import 'package:path_provider/path_provider.dart';

import 'document_scanner_service.dart'
    show fileTimestamp, formatFileSize, uniqueFilePath;

/// A file fetched from the web and saved into the app's documents directory.
class DownloadedFile {
  /// Absolute path to the saved file.
  final String path;

  /// File name (no directory) — used as the document's display name.
  final String fileName;

  /// Size of the saved file, in bytes.
  final int byteSize;

  const DownloadedFile({
    required this.path,
    required this.fileName,
    required this.byteSize,
  });

  String get sizeLabel => formatFileSize(byteSize);
}

/// Thrown when a download fails for a reason worth telling the user about.
class DownloadException implements Exception {
  final String message;
  const DownloadException(this.message);
  @override
  String toString() => message;
}

/// A download the browser handed off, captured at intercept time and carried
/// through the save-to-case flow. [headers] forwards the WebView's cookies and
/// User-Agent so the fetch is authenticated the same way the page was, and
/// [suggestedName] preserves the extension worked out from the download
/// listener's headers in case the response itself reveals none.
class PendingDownload {
  final String url;
  final String suggestedName;
  final String sourceHost;
  final Map<String, String> headers;

  const PendingDownload({
    required this.url,
    required this.suggestedName,
    required this.sourceHost,
    this.headers = const {},
  });
}

/// Downloads files that the in-app browser would otherwise hand off to the
/// system, so they can be filed straight into a case folder.
class DownloadService {
  DownloadService._();
  static final DownloadService instance = DownloadService._();

  /// File types we treat as downloads when a link points at them. Kept to
  /// documents and archives so ordinary image and page links still open inline.
  static const Set<String> downloadableExtensions = {
    'pdf', 'doc', 'docx', 'xls', 'xlsx', 'ppt', 'pptx',
    'txt', 'rtf', 'csv', 'odt', 'ods', 'odp', 'epub',
    'zip', 'rar', '7z',
  };

  /// Whether [url]'s path ends in a type we should capture rather than load.
  static bool looksDownloadable(String url) {
    final ext = _extensionOf(Uri.tryParse(url));
    return ext != null && downloadableExtensions.contains(ext);
  }

  /// A friendly name to preview before the file is fetched (the saved name may
  /// differ once the server's headers are read). When the browser's download
  /// listener hands us a `Content-Disposition` header or MIME type, we use them
  /// so generated, extension-less URLs still preview a sensible name.
  static String suggestFileName(
    String url, {
    String? contentDisposition,
    String? mimetype,
  }) {
    final fromHeader = _filenameFromDisposition(contentDisposition);
    if (fromHeader != null && fromHeader.isNotEmpty) {
      return _sanitize(fromHeader);
    }
    final uri = Uri.tryParse(url);
    var name = _lastSegment(uri);
    if (name.isEmpty) name = 'download';
    if (!name.contains('.')) {
      final ext = _extensionForMime(mimetype);
      if (ext != null) name = '$name.$ext';
    }
    return _sanitize(name);
  }

  /// Fetches [url] and writes it into `documents/downloads`, returning the saved
  /// file. Throws [DownloadException] on any failure worth surfacing.
  ///
  /// [headers] forwards request headers — notably the WebView's `Cookie` and
  /// `User-Agent` — so files gated behind the page's session download just as
  /// they would in the browser. [fallbackName] is the intercept-time name; it is
  /// used to keep the right extension when neither the response nor the URL
  /// carry one.
  ///
  /// [onProgress] is called as bytes arrive with the running total and the full
  /// size when the server reports it (null when it doesn't).
  Future<DownloadedFile> download(
    String url, {
    Map<String, String> headers = const {},
    String? fallbackName,
    void Function(int received, int? total)? onProgress,
  }) async {
    final uri = Uri.tryParse(url);
    if (uri == null || !uri.hasScheme) {
      throw const DownloadException("That download link isn't valid.");
    }

    final userAgent = headers['User-Agent'] ?? headers['user-agent'];
    final client = HttpClient()
      ..connectionTimeout = const Duration(seconds: 20)
      ..userAgent = (userAgent != null && userAgent.isNotEmpty)
          ? userAgent
          : 'Mozilla/5.0 (Android) UnsettledLegal';

    try {
      final request = await client.getUrl(uri);
      headers.forEach((name, value) {
        // The User-Agent is already on the client; the rest (Cookie, …) ride on
        // the request so the server sees the same session as the WebView.
        if (name.toLowerCase() == 'user-agent' || value.isEmpty) return;
        request.headers.set(name, value);
      });
      final response = await request.close();
      if (response.statusCode != HttpStatus.ok) {
        throw DownloadException(
            'The server returned status ${response.statusCode}.');
      }

      final docsDir = await getApplicationDocumentsDirectory();
      final downloadsDir = Directory('${docsDir.path}/downloads');
      if (!await downloadsDir.exists()) {
        await downloadsDir.create(recursive: true);
      }

      final name = _resolveName(uri, response, fallbackName);
      final target = File(uniqueFilePath(downloadsDir.path, name));

      final total = response.contentLength >= 0 ? response.contentLength : null;
      var received = 0;
      onProgress?.call(0, total);
      // Counting via map keeps addStream's back-pressure while reporting bytes.
      final counted = response.map((chunk) {
        received += chunk.length;
        onProgress?.call(received, total);
        return chunk;
      });

      final sink = target.openWrite();
      try {
        await sink.addStream(counted);
        await sink.flush();
      } catch (_) {
        await sink.close();
        if (await target.exists()) await target.delete();
        throw const DownloadException(
            'The download stopped partway through. Try again.');
      }
      await sink.close();

      return DownloadedFile(
        path: target.path,
        fileName: name,
        byteSize: await target.length(),
      );
    } on SocketException {
      throw const DownloadException(
          "Couldn't reach the server. Check your connection and try again.");
    } on HttpException {
      throw const DownloadException('The download failed. Try again.');
    } finally {
      client.close();
    }
  }

  /// Picks a name from the Content-Disposition header, then the URL, then the
  /// intercept-time [fallbackName], always ensuring a sensible extension is kept.
  String _resolveName(
      Uri uri, HttpClientResponse response, String? fallbackName) {
    final fromHeader =
        _filenameFromDisposition(response.headers.value('content-disposition'));
    if (fromHeader != null && fromHeader.isNotEmpty) {
      return _sanitize(fromHeader);
    }

    final fromUrl = _lastSegment(uri);
    if (fromUrl.contains('.')) return _sanitize(fromUrl);

    // The intercept-time name already carries the extension the download
    // listener reported, so prefer it whenever the response and URL give us
    // nothing with one.
    if (fallbackName != null && fallbackName.contains('.')) {
      return _sanitize(fallbackName);
    }

    // Last resort: build a base name and bolt on an extension from the MIME type.
    final base = fromUrl.isNotEmpty
        ? fromUrl
        : (fallbackName != null && fallbackName.isNotEmpty
            ? fallbackName
            : 'Download_${fileTimestamp()}');
    final ext = _extensionForMime(response.headers.contentType?.mimeType);
    return _sanitize(ext == null ? base : '$base.$ext');
  }

  static String _lastSegment(Uri? uri) {
    if (uri == null) return '';
    final segment = uri.pathSegments
        .lastWhere((s) => s.trim().isNotEmpty, orElse: () => '');
    if (segment.isEmpty) return '';
    try {
      return Uri.decodeComponent(segment);
    } catch (_) {
      return segment;
    }
  }

  static String? _extensionOf(Uri? uri) {
    final segment = _lastSegment(uri).toLowerCase();
    final dot = segment.lastIndexOf('.');
    if (dot < 0 || dot == segment.length - 1) return null;
    return segment.substring(dot + 1);
  }

  static String? _filenameFromDisposition(String? header) {
    if (header == null) return null;
    final extended =
        RegExp(r"""filename\*\s*=\s*[^']*''([^;]+)""", caseSensitive: false)
            .firstMatch(header);
    if (extended != null) {
      try {
        return Uri.decodeComponent(extended.group(1)!.trim());
      } catch (_) {/* fall through */}
    }
    final plain =
        RegExp(r'''filename\s*=\s*"?([^";]+)"?''', caseSensitive: false)
            .firstMatch(header);
    return plain?.group(1)?.trim();
  }

  static String? _extensionForMime(String? mime) {
    switch (mime) {
      case 'application/pdf':
        return 'pdf';
      case 'application/msword':
        return 'doc';
      case 'application/vnd.openxmlformats-officedocument.wordprocessingml.document':
        return 'docx';
      case 'application/vnd.ms-excel':
        return 'xls';
      case 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet':
        return 'xlsx';
      case 'text/plain':
        return 'txt';
      case 'text/csv':
        return 'csv';
      case 'application/zip':
        return 'zip';
      default:
        return null;
    }
  }

  /// Strips directory separators and characters that are awkward in file names.
  static String _sanitize(String name) {
    final cleaned =
        name.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_').trim();
    return cleaned.isEmpty ? 'Download_${fileTimestamp()}' : cleaned;
  }
}
