import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

class VoiceService {
  static final VoiceService instance = VoiceService._init();
  factory VoiceService() => instance;
  VoiceService._init();

  final FlutterTts _tts = FlutterTts();
  final stt.SpeechToText _speech = stt.SpeechToText();

  bool _isTtsInitialized = false;
  bool _isSttInitialized = false;
  bool _isListening = false;

  bool get isListening => _isListening;

  Future<void> init() async {
    await initTts();
  }

  Future<void> initTts() async {
    if (_isTtsInitialized) return;
    try {
      if (!kIsWeb && (Platform.isWindows || Platform.isAndroid || Platform.isIOS || Platform.isMacOS)) {
        await _tts.setLanguage('en-IN');
        await _tts.setSpeechRate(0.5);
        await _tts.setPitch(1.0);
        await _tts.setVolume(1.0);
      }
      _isTtsInitialized = true;
    } catch (_) {
      // Fallback for platform limitations
      try {
        await _tts.setLanguage('en-US');
        _isTtsInitialized = true;
      } catch (_) {}
    }
  }

  Future<void> speak(String text) async {
    await initTts();
    try {
      // Clean markdown tags so speech sounds natural
      final cleanText = text
          .replaceAll(RegExp(r'\*\*|__|[\*#_`]'), '')
          .replaceAll(RegExp(r'\[.*?\]\(.*?\)'), '')
          .trim();
      if (cleanText.isNotEmpty) {
        await _tts.speak(cleanText);
      }
    } catch (_) {}
  }

  Future<void> stopSpeaking() async {
    try {
      await _tts.stop();
    } catch (_) {}
  }

  Future<bool> initSpeech() async {
    if (_isSttInitialized) return true;
    try {
      _isSttInitialized = await _speech.initialize(
        onError: (err) {
          _isListening = false;
        },
        onStatus: (status) {
          if (status == 'done' || status == 'notListening') {
            _isListening = false;
          }
        },
      );
      return _isSttInitialized;
    } catch (_) {
      _isSttInitialized = false;
      return false;
    }
  }

  Future<void> startListening({
    required Function(String text) onResult,
    required VoidCallback onDone,
  }) async {
    final available = await initSpeech();
    if (!available) {
      onDone();
      return;
    }

    try {
      _isListening = true;
      await _speech.listen(
        onResult: (result) {
          onResult(result.recognizedWords);
          if (result.finalResult) {
            _isListening = false;
            onDone();
          }
        },
        listenOptions: stt.SpeechListenOptions(
          listenMode: stt.ListenMode.confirmation,
          cancelOnError: true,
          partialResults: true,
        ),
      );
    } catch (_) {
      _isListening = false;
      onDone();
    }
  }

  Future<void> stopListening() async {
    try {
      await _speech.stop();
      _isListening = false;
    } catch (_) {}
  }
}
