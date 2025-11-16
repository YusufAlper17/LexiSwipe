import 'package:flutter/material.dart';
import '../services/text_to_speech_service.dart';

class TextToSpeechWidget extends StatefulWidget {
  const TextToSpeechWidget({Key? key}) : super(key: key);

  @override
  State<TextToSpeechWidget> createState() => _TextToSpeechWidgetState();
}

class _TextToSpeechWidgetState extends State<TextToSpeechWidget> {
  final TextToSpeechService _tts = TextToSpeechService();
  final TextEditingController _textController = TextEditingController();

  @override
  void dispose() {
    _textController.dispose();
    _tts.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          TextField(
            controller: _textController,
            decoration: const InputDecoration(
              labelText: 'İngilizce kelime veya cümle girin',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () {
              if (_textController.text.isNotEmpty) {
                _tts.speakWord(_textController.text);
              }
            },
            icon: const Icon(Icons.volume_up),
            label: const Text('Seslendir'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
} 