import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';

class OcrService {
  final TextRecognizer _textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
  final ImagePicker _picker = ImagePicker();

  Future<String?> pickAndRecognizeText() async {
    final image = await _picker.pickImage(source: ImageSource.gallery);
    if (image == null) return null;

    final inputImage = InputImage.fromFilePath(image.path);
    final recognizedText = await _textRecognizer.processImage(inputImage);

    final text = recognizedText.text;
    return text.isEmpty ? 'No text found in the image.' : text;
  }

  void dispose() {
    _textRecognizer.close();
  }
}
