import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_audio_capture/flutter_audio_capture.dart';
import 'package:pitch_detector_dart/pitch_detector.dart';

class VocalPitchCalibrationScreen extends StatefulWidget {
  final Function(double) onCalibrationComplete;

  const VocalPitchCalibrationScreen({
    super.key,
    required this.onCalibrationComplete,
  });

  @override
  State<VocalPitchCalibrationScreen> createState() => _VocalPitchCalibrationScreenState();
}

enum CalibrationState { intro, listening, finished }

class _VocalPitchCalibrationScreenState extends State<VocalPitchCalibrationScreen> with SingleTickerProviderStateMixin {
  CalibrationState _state = CalibrationState.intro;
  final _audioCapture = FlutterAudioCapture();
  final _pitchDetector = PitchDetector(audioSampleRate: 44100, bufferSize: 4096);
  
  bool _micGranted = false;
  double? _currentMidiVal;
  double? _smoothedMidiVal;
  
  Timer? _pollingTimer;
  Timer? _countdownTimer;
  
  bool _hasStartedSpeaking = false;
  int _listenSecondsLeft = 3;
  
  final List<double> _pitchHistory = [];
  final List<double?> _visualHistory = [];
  final int _maxVisualPoints = 100;
  
  double? _finalAveragePitch;
  
  late AnimationController _repaintController;

  @override
  void initState() {
    super.initState();
    _repaintController = AnimationController(
        vsync: this, duration: const Duration(seconds: 1))..repeat();
  }

  @override
  void dispose() {
    _repaintController.dispose();
    _stopListening();
    _stopTimers();
    super.dispose();
  }

  void _stopTimers() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
    _countdownTimer?.cancel();
    _countdownTimer = null;
  }

  Future<void> _requestMic() async {
    final status = await Permission.microphone.request();
    if (status == PermissionStatus.granted) {
      _micGranted = true;
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Microphone permission required for calibration')),
      );
    }
  }

  void _startCalibration() async {
    await _requestMic();
    if (!_micGranted) return;

    setState(() {
      _state = CalibrationState.listening;
      _hasStartedSpeaking = false;
      _listenSecondsLeft = 3;
      _pitchHistory.clear();
      _visualHistory.clear();
      for (int i = 0; i < _maxVisualPoints; i++) _visualHistory.add(null);
      _currentMidiVal = null;
      _smoothedMidiVal = null;
    });

    try {
      final initialized = await _audioCapture.init();
      if (initialized != true) return;

      await _audioCapture.start(
        _processAudio,
        (error) => debugPrint('Audio Capture Error: $error'),
        sampleRate: 44100,
        bufferSize: 4096,
      );

      _startTimers();
    } catch (e) {
      debugPrint('Error starting audio capture: $e');
    }
  }

  void _processAudio(Float32List data) {
    if (!mounted || _state != CalibrationState.listening) return;

    _pitchDetector.getPitchFromFloatBuffer(data).then((result) {
      if (!mounted || _state != CalibrationState.listening) return;

      if (result.pitched && result.probability > 0.45 && result.pitch > 30) {
        final double midiNote = 69 + 12 * (math.log(result.pitch / 440.0) / math.log(2));
        _currentMidiVal = midiNote;
        
        if (!_hasStartedSpeaking) {
          _hasStartedSpeaking = true;
          _startCountdown();
        }
      } else {
        _currentMidiVal = null;
      }
    });
  }

  void _startTimers() {
    _pollingTimer = Timer.periodic(const Duration(milliseconds: 30), (timer) {
      if (_currentMidiVal != null) {
        if (_smoothedMidiVal == null) {
          _smoothedMidiVal = _currentMidiVal;
        } else {
          _smoothedMidiVal = _smoothedMidiVal! + (_currentMidiVal! - _smoothedMidiVal!) * 0.2;
        }
        if (_hasStartedSpeaking) {
          _pitchHistory.add(_currentMidiVal!); // Keep raw for average
        }
      } else {
        _smoothedMidiVal = null;
      }

      _visualHistory.add(_smoothedMidiVal);
      if (_visualHistory.length > _maxVisualPoints) {
        _visualHistory.removeAt(0);
      }
    });
  }

  void _startCountdown() {
    _listenSecondsLeft = 3;
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        if (_listenSecondsLeft > 1) {
          _listenSecondsLeft--;
        } else {
          _listenSecondsLeft = 0;
          _finishCalibration();
        }
      });
    });
  }

  Future<void> _stopListening() async {
    try {
      if (_micGranted) {
        await _audioCapture.stop();
      }
    } catch (_) {}
  }

  void _finishCalibration() async {
    _stopTimers();
    await _stopListening();

    if (_pitchHistory.isNotEmpty) {
      // Calculate average Hz
      // convert MIDI back to Hz to average? Or just average MIDI.
      // Easiest is average MIDI, then convert to typical pitch value.
      double sum = 0;
      for (var p in _pitchHistory) sum += p;
      double avgMidi = sum / _pitchHistory.length;
      _finalAveragePitch = avgMidi;
    } else {
      _finalAveragePitch = null;
    }

    setState(() {
      _state = CalibrationState.finished;
    });
  }

  String _midiToName(double midi) {
    List<String> notes = ['C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'Bb', 'B'];
    int m = midi.round();
    int noteIndex = m % 12;
    int octave = (m ~/ 12) - 1;
    return '${notes[noteIndex]}$octave';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A1929),
      body: SafeArea(
        child: _buildContent(),
      ),
    );
  }

  Widget _buildContent() {
    switch (_state) {
      case CalibrationState.intro:
        return Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.mic, size: 60, color: Color(0xFFE93B81)),
                const SizedBox(height: 24),
                const Text(
                  'Find Your Natural Pitch',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  'To start singing your lessons comfortably, we need to find your natural speaking pitch.',
                  style: TextStyle(fontSize: 16, color: Colors.white.withOpacity(0.8), height: 1.5),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 48),
                ElevatedButton(
                  onPressed: _startCalibration,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE93B81),
                    padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  ),
                  child: const Text('Continue', style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        );

      case CalibrationState.listening:
        return Stack(
          children: [
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _repaintController,
                builder: (context, _) {
                  return CustomPaint(
                    painter: SimplePitchCurvePainter(
                      history: _visualHistory,
                    ),
                  );
                },
              ),
            ),
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _hasStartedSpeaking ? 'Listening... $_listenSecondsLeft' : 'Say "Hello" in your normal voice',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white.withOpacity(_hasStartedSpeaking ? 0.8 : 1.0)),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
        );

      case CalibrationState.finished:
        String pitchText = _finalAveragePitch != null 
            ? 'Your average pitch is ${_midiToName(_finalAveragePitch!)}'
            : 'We couldn\'t detect your pitch clearly.';

        return Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _finalAveragePitch != null ? Icons.check_circle : Icons.error_outline,
                  size: 60,
                  color: _finalAveragePitch != null ? Colors.greenAccent : Colors.orangeAccent
                ),
                const SizedBox(height: 24),
                Text(
                  pitchText,
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 48),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TextButton(
                      onPressed: _startCalibration,
                      child: const Text('Try Again', style: TextStyle(color: Colors.white70, fontSize: 16)),
                    ),
                    const SizedBox(width: 24),
                    ElevatedButton(
                      onPressed: () {
                        // Pass pitch in Hz if it exists, otherwise pass a default
                        double hz = 440.0;
                        if (_finalAveragePitch != null) {
                          hz = 440.0 * math.pow(2.0, (_finalAveragePitch! - 69.0) / 12.0).toDouble();
                        }
                        widget.onCalibrationComplete(hz);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFE93B81),
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                      ),
                      child: const Text('Continue', style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
    }
  }
}

class SimplePitchCurvePainter extends CustomPainter {
  final List<double?> history;

  SimplePitchCurvePainter({required this.history});

  @override
  void paint(Canvas canvas, Size size) {
    if (history.isEmpty) return;

    final paint = Paint()
      ..color = const Color(0xFFE93B81)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final double stepX = size.width / history.length;
    final List<List<Offset>> segments = [];
    List<Offset> currentSegment = [];

    // Map MIDI roughly from 40 to 80
    double minMidi = 40.0;
    double maxMidi = 80.0;

    for (int i = 0; i < history.length; i++) {
      final double? val = history[i];
      if (val != null) {
        double normalized = (val - minMidi) / (maxMidi - minMidi);
        normalized = normalized.clamp(0.0, 1.0);
        double y = size.height - (normalized * size.height);
        double x = i * stepX;
        currentSegment.add(Offset(x, y));
      } else {
        if (currentSegment.isNotEmpty) {
          segments.add(currentSegment);
          currentSegment = [];
        }
      }
    }
    if (currentSegment.isNotEmpty) {
      segments.add(currentSegment);
    }

    final path = Path();
    for (var seg in segments) {
      if (seg.length == 1) {
        path.moveTo(seg[0].dx, seg[0].dy);
        path.lineTo(seg[0].dx + 1, seg[0].dy);
      } else if (seg.length > 1) {
        path.moveTo(seg[0].dx, seg[0].dy);
        for (int i = 1; i < seg.length; i++) {
          path.lineTo(seg[i].dx, seg[i].dy);
        }
      }
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant SimplePitchCurvePainter oldDelegate) => true;
}
