import 'dart:async';
import 'dart:typed_data';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_soloud/flutter_soloud.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_audio_capture/flutter_audio_capture.dart';
import 'package:pitch_detector_dart/pitch_detector.dart';
import 'guitar_headstock.dart';

({String note, double cents}) _frequencyToNote(double freq) {
  if (freq <= 0) return (note: '--', cents: 0.0);
  const noteNames = ['C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B'];
  final semitones = 12 * (math.log(freq / 440.0) / math.log(2));
  final roundedSemitones = semitones.round();
  final cents = (semitones - roundedSemitones) * 100;
  final midiNote = 69 + roundedSemitones;
  final noteName = noteNames[midiNote % 12];
  return (note: noteName, cents: cents);
}

class GuitarTunerScreen extends StatefulWidget {
  final VoidCallback? onBackPressed;

  const GuitarTunerScreen({super.key, this.onBackPressed});

  @override
  State<GuitarTunerScreen> createState() => _GuitarTunerScreenState();
}

class _GuitarTunerScreenState extends State<GuitarTunerScreen>
    with SingleTickerProviderStateMixin {
  late SoLoud _soloud;
  final Map<int, AudioSource> _noteSources = {};
  SoundHandle? _currentSoundHandle;
  final List<String> _notes = ['E2', 'A2', 'D3', 'G3', 'B3', 'E4'];
  final List<double> _frequencies = [
    82.41,  // E2
    110.00, // A2
    146.83, // D3
    196.00, // G3
    246.94, // B3
    329.63, // E4
  ];

  final _audioCapture = FlutterAudioCapture();
  final _pitchDetector = PitchDetector(audioSampleRate: 44100, bufferSize: 4096);

  double _currentPitch = 0.0;
  String _detectedNote = '--';
  double _cents = 0.0;
  double _smoothCents = 0.0;



  int _selectedStringIndex = 0;
  bool _isTuned = false;
  DateTime? _stableStartTime;

  late AnimationController _needleController;
  static const double _smoothFactor = 0.25;

  bool _micGranted = false;

  @override
  void initState() {
    super.initState();
    _initAudioPlayers();

    _needleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat();

    _needleController.addListener(_smoothTick);

    _startListening();
  }

  void _smoothTick() {
    final newSmooth = _smoothCents + (_cents - _smoothCents) * _smoothFactor;
    if ((newSmooth - _smoothCents).abs() > 0.05) {
      setState(() => _smoothCents = newSmooth);
    }
  }

  Future<void> _initAudioPlayers() async {
    try {
      _soloud = SoLoud.instance;
      if (!_soloud.isInitialized) {
        await _soloud.init(bufferSize: 512);
      }
      for (int i = 0; i < 6; i++) {
        _noteSources[i] = await _soloud.loadAsset(
          'assets/audio/guitar_notes/${_notes[i]}.wav',
          mode: LoadMode.memory,
        );
      }
    } catch (e) {
      debugPrint('SoLoud init error: $e');
    }
  }

  Future<void> _startListening() async {
    final status = await Permission.microphone.request();

    if (status != PermissionStatus.granted) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Microphone permission required for tuner')),
        );
      }
      return;
    }
    if (mounted) setState(() => _micGranted = true);

    try {
      final initialized = await _audioCapture.init();
      if (initialized != true) return;

      await _audioCapture.start(
        _processAudio,
        (error) => debugPrint('Audio Capture Error: $error'),
        sampleRate: 44100,
        bufferSize: 4096,
      );
    } catch (e) {
      debugPrint('Error starting audio capture: $e');
    }
  }

  void _processAudio(Float32List data) {
    if (!mounted) return;

    _pitchDetector.getPitchFromFloatBuffer(data).then((result) {
      if (!mounted) return;

      if (result.pitched && result.probability > 0.45 && result.pitch > 30) {
        final pitch = result.pitch;
        final info = _frequencyToNote(pitch);

        final targetFreq = _frequencies[_selectedStringIndex];
        final centsFromTarget = 1200 * (math.log(pitch / targetFreq) / math.log(2));
        final clampedCents = centsFromTarget.clamp(-50.0, 50.0);

        setState(() {
          _currentPitch = pitch;
          _detectedNote = info.note;
          _cents = clampedCents;
        });

        _updateTuningState(clampedCents);
      }
    });
  }

  void _updateTuningState(double cents) {
    if (cents.abs() < 3.0) {
      _stableStartTime ??= DateTime.now();
      if (DateTime.now().difference(_stableStartTime!).inSeconds >= 2) {
        if (!_isTuned) setState(() => _isTuned = true);
      }
    } else {
      _stableStartTime = null;
      if (_isTuned && cents.abs() > 5.0) {
        setState(() => _isTuned = false);
      }
    }
  }

  Future<void> _stopListening() async {
    await _audioCapture.stop();
  }

  @override
  void dispose() {
    _needleController.removeListener(_smoothTick);
    _needleController.dispose();
    _stopListening();
    for (final source in _noteSources.values) {
      _soloud.disposeSource(source);
    }
    try {
      _soloud.deinit();
    } catch (_) {}
    super.dispose();
  }

  void _playNote(int index) async {
    setState(() {
      _selectedStringIndex = index;
      _isTuned = false;
      _stableStartTime = null;
      _cents = 0.0;
      _smoothCents = 0.0;
    });

    if (_currentSoundHandle != null) {
      try {
        _soloud.stop(_currentSoundHandle!);
      } catch (_) {}
    }

    if (_noteSources.containsKey(index)) {
      _currentSoundHandle = await _soloud.play(_noteSources[index]!, volume: 1.0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: widget.onBackPressed == null,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        widget.onBackPressed?.call();
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF0A1929),
        appBar: AppBar(
          backgroundColor: const Color(0xFF0A1929),
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () {
              if (widget.onBackPressed != null) {
                widget.onBackPressed!();
              } else {
                Navigator.of(context).maybePop();
              }
            },
          ),
          title: const Text('Guitar Tuner',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
          centerTitle: true,
        ),
        body: Column(
          children: [
            // ── Tuner Display ────────────────────────────────────────────────
            Expanded(
              flex: 5,
              child: _buildTunerDisplay(),
            ),
            // ── Guitar Headstock ─────────────────────────────────────────────
            Expanded(
              flex: 5,
              child: GuitarHeadstock(
                activeStringIndex: _selectedStringIndex,
                tunedStringIndex: _isTuned ? _selectedStringIndex : null,
                onStringSelected: _playNote,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTunerDisplay() {
    final needlePos = (_smoothCents / 50.0).clamp(-1.0, 1.0);
    final isInTune = _smoothCents.abs() < 5.0 && _currentPitch > 0;

    final stringLabel = _notes[_selectedStringIndex];

    Color accentColor;
    if (_currentPitch <= 0) {
      accentColor = Colors.white38;
    } else if (isInTune) {
      accentColor = const Color(0xFF4CAF50);
    } else if (_smoothCents < 0) {
      accentColor = const Color(0xFF42A5F5);
    } else {
      accentColor = const Color(0xFFEF5350);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: [
          // ── Target string label ─────────────────────────────────────────
          Text(
            stringLabel,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 4),

          // ── Detected note name ──────────────────────────────────────────
          Text(
            _currentPitch > 0 ? _detectedNote : '--',
            style: TextStyle(
              color: accentColor,
              fontSize: 52,
              fontWeight: FontWeight.bold,
              height: 1.0,
            ),
          ),

          // ── Cent offset ─────────────────────────────────────────────────
          Text(
            _currentPitch > 0
                ? (_smoothCents >= 0
                    ? '+${_smoothCents.toStringAsFixed(0)} ¢'
                    : '${_smoothCents.toStringAsFixed(0)} ¢')
                : '0 ¢',
            style: TextStyle(
              color: accentColor.withOpacity(0.85),
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),

          const SizedBox(height: 6),

          // ── Needle arc ──────────────────────────────────────────────────
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: CustomPaint(
                painter: TunerNeedlePainter(
                  value: needlePos,
                  isInTune: isInTune && _currentPitch > 0,
                  accentColor: accentColor,
                ),
                child: const SizedBox.expand(),
              ),
            ),
          ),

          // ── Flat / Sharp labels ─────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('♭ Flat',
                    style: TextStyle(color: Colors.blueAccent.withOpacity(0.7), fontSize: 12)),
                if (isInTune && _currentPitch > 0)
                  const Text('IN TUNE ✓',
                      style: TextStyle(
                          color: Color(0xFF4CAF50),
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5)),
                Text('Sharp ♯',
                    style: TextStyle(color: Colors.redAccent.withOpacity(0.7), fontSize: 12)),
              ],
            ),
          ),

          // ── Mic not granted warning ─────────────────────────────────────
          if (!_micGranted)
            const Padding(
              padding: EdgeInsets.only(top: 4),
              child: Text('🎤 Tap allow to enable mic',
                  style: TextStyle(color: Colors.orange, fontSize: 11)),
            ),


          const SizedBox(height: 4),
        ],
      ),
    );
  }
}

class TunerNeedlePainter extends CustomPainter {
  final double value;
  final bool isInTune;
  final Color accentColor;

  TunerNeedlePainter({
    required this.value,
    required this.isInTune,
    required this.accentColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final cx = w / 2;
    final pivotY = h + h * 0.3;

    final tickPaint = Paint()
      ..color = Colors.white24
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;

    for (int i = -5; i <= 5; i++) {
      final tickFrac = i / 5.0;
      final maxAngle = 30 * math.pi / 180;
      final angle = tickFrac * maxAngle;
      final tickLen = i == 0 ? 18.0 : (i.abs() == 5 ? 14.0 : 9.0);
      final lineLen = (pivotY - 0).toDouble();

      final endX = cx + lineLen * math.sin(angle);
      final endY = pivotY - lineLen * math.cos(angle);

      final dx = endX - cx;
      final dy = endY - pivotY;
      final mag = math.sqrt(dx * dx + dy * dy);
      final ndx = dx / mag;
      final ndy = dy / mag;

      canvas.drawLine(
        Offset(endX - ndx * tickLen, endY - ndy * tickLen),
        Offset(endX, endY),
        tickPaint..color = i == 0 ? Colors.white54 : Colors.white24,
      );
    }

    final arcRadius = (pivotY - h * 0.1).toDouble();
    final arcRect = Rect.fromCircle(
        center: Offset(cx, pivotY), radius: arcRadius);
    final maxAngle = 30 * math.pi / 180;
    canvas.drawArc(
      arcRect,
      -math.pi / 2 - maxAngle,
      maxAngle * 2,
      false,
      Paint()
        ..color = Colors.white12
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0,
    );

    final currentAngle = value * maxAngle;
    final needleLen = pivotY - h * 0.05;

    final tipX = cx + needleLen * math.sin(currentAngle);
    final tipY = pivotY - needleLen * math.cos(currentAngle);

    canvas.drawLine(
      Offset(cx, pivotY),
      Offset(tipX, tipY),
      Paint()
        ..color = accentColor
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round,
    );

    canvas.drawCircle(
      Offset(cx, pivotY),
      5,
      Paint()..color = accentColor,
    );

    canvas.drawCircle(
      Offset(tipX, tipY),
      isInTune ? 9 : 6,
      Paint()..color = accentColor,
    );
  }

  @override
  bool shouldRepaint(TunerNeedlePainter old) =>
      old.value != value || old.isInTune != isInTune || old.accentColor != accentColor;
}
