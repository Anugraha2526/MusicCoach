import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_audio_capture/flutter_audio_capture.dart';
import 'package:pitch_detector_dart/pitch_detector.dart';

class RealtimePitchGraphScreen extends StatefulWidget {
  final VoidCallback? onBackPressed;

  const RealtimePitchGraphScreen({super.key, this.onBackPressed});

  @override
  State<RealtimePitchGraphScreen> createState() => _RealtimePitchGraphScreenState();
}

class _RealtimePitchGraphScreenState extends State<RealtimePitchGraphScreen> with SingleTickerProviderStateMixin {
  
  final List<String> _noteNames = ['C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'Bb', 'B'];

  bool _isPlaying = false;
  Timer? _pollingTimer;
  
  // High density point tracking for smooth paths
  final List<double?> _pitchHistory = []; 
  final int maxPoints = 150;  
  
  final _audioCapture = FlutterAudioCapture();
  final _pitchDetector = PitchDetector(audioSampleRate: 44100, bufferSize: 4096);
  bool _micGranted = false;
  
  double? _currentMidiVal;
  double? _smoothedMidiVal;
  
  // Smoothly center the graph. 
  double _currentCenterMidi = 55.0; // Starts around G3 (Midi 55)

  late AnimationController _repaintController;

  @override
  void initState() {
    super.initState();
    for (int i = 0; i < maxPoints; i++) {
      _pitchHistory.add(null);
    }
    
    // 60 fps repaint for butter-smooth visual scrolling independent of polling logic
    _repaintController = AnimationController(
        vsync: this, duration: const Duration(seconds: 1))..repeat();
  }

  Future<void> _startListening() async {
    final status = await Permission.microphone.request();

    if (status != PermissionStatus.granted) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Microphone permission required for pitch detection')),
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
    if (!mounted || !_isPlaying) return;

    _pitchDetector.getPitchFromFloatBuffer(data).then((result) {
      if (!mounted || !_isPlaying) return;

      if (result.pitched && result.probability > 0.45 && result.pitch > 30) {
        final pitch = result.pitch;
        final double midiNote = 69 + 12 * (math.log(pitch / 440.0) / math.log(2));
        _currentMidiVal = midiNote;
      } else {
        _currentMidiVal = null;
      }
    });
  }

  Future<void> _stopListening() async {
    try {
      if (_micGranted) {
        await _audioCapture.stop();
      }
    } catch (_) {}
  }

  void _togglePlayPause() {
    setState(() {
      _isPlaying = !_isPlaying;
      if (_isPlaying) {
        // Clear history to start fresh
        _pitchHistory.clear();
        for (int i = 0; i < maxPoints; i++) {
          _pitchHistory.add(null);
        }
        _currentMidiVal = null;
        _smoothedMidiVal = null;
        
        _startTimer();
        _startListening();
      } else {
        _stopTimer();
        _stopListening();
        _currentMidiVal = null; 
        _smoothedMidiVal = null;
      }
    });
  }

  void _startTimer() {
    // High-frequency invisible polling pushed to array (~45 times a second). 
    // We do NOT call setState here to avoid laggy main thread locking.
    _pollingTimer = Timer.periodic(const Duration(milliseconds: 22), (timer) {
        
        if (_currentMidiVal != null) {
          if (_smoothedMidiVal == null) {
             _smoothedMidiVal = _currentMidiVal;
          } else {
             // Powerful EMA smoothing to wipe out pitch signal jitter
             _smoothedMidiVal = _smoothedMidiVal! + (_currentMidiVal! - _smoothedMidiVal!) * 0.15;
          }
        } else {
          _smoothedMidiVal = null;
        }

        _pitchHistory.add(_smoothedMidiVal);
        if (_pitchHistory.length > maxPoints) { 
          _pitchHistory.removeAt(0); 
        }
        
        // Let the painter gracefully handle drawing smoothly across these dense points
        
        double? targetCenter;
        if (_smoothedMidiVal != null) {
           targetCenter = _smoothedMidiVal!;
        } else {
           // Find last known value to continue centering on it
           for (int i = _pitchHistory.length - 1; i >= 0; i--) {
              if (_pitchHistory[i] != null) {
                  targetCenter = _pitchHistory[i]!;
                  break;
              }
           }
        }

        if (targetCenter != null) {
          final double diff = targetCenter - _currentCenterMidi;
          // Only adjust if out of deadzone
          if (diff.abs() > 1.0) {
              // Dynamic speed: faster when further away
              double speedFactor = 0.08 + (diff.abs() * 0.015);
              speedFactor = speedFactor.clamp(0.08, 0.4);
              _currentCenterMidi += diff * speedFactor;
          }
        }
    });
  }

  void _stopTimer() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
  }

  @override
  void dispose() {
    _repaintController.dispose();
    _stopTimer();
    _stopListening();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: widget.onBackPressed == null,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (widget.onBackPressed != null) {
          widget.onBackPressed!();
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF101424), 
        body: SafeArea(
          child: Column(
            children: [
              // Top Bar
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.white30, width: 1.5),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: IconButton(
                        padding: EdgeInsets.zero,
                        icon: const Icon(Icons.arrow_back, color: Colors.white70),
                        onPressed: () {
                          if (widget.onBackPressed != null) {
                            widget.onBackPressed!();
                          } else {
                            Navigator.of(context).maybePop();
                          }
                        },
                      ),
                    ),
                    const Expanded(
                      child: Center(
                        child: Text(
                          'Real- Time Pitch',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 44), 
                  ],
                ),
              ),
              
              // Note Lines and Graph Container
              Expanded(
                child: Container(
                  margin: const EdgeInsets.only(top: 16),
                  child: ClipRect(
                    child: AnimatedBuilder(
                      animation: _repaintController,
                      builder: (context, child) {
                        return CustomPaint(
                          painter: PitchGraphPainter(
                            centerMidi: _currentCenterMidi,
                            pitchHistory: _pitchHistory,
                            isPlaying: _isPlaying,
                            noteNames: _noteNames,
                            // Extremely smooth interpolation fraction
                            tickProgress: (_pollingTimer?.tick ?? 0) % 1.0, 
                          ),
                          child: const SizedBox.expand(),
                        );
                      }
                    ),
                  ),
                ),
              ),
              
              // Bottom Controls Section
              Container(
                height: 100,
                width: double.infinity,
                color: const Color(0xFF1B233C), 
                child: Center(
                  child: GestureDetector(
                    onTap: _togglePlayPause,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      width: 64,
                      height: 64,
                      decoration: const BoxDecoration(
                        color: Color(0xFFE93B81), 
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: _isPlaying
                            ? const Text(
                                '||',
                                style: TextStyle(
                                  color: Colors.black,
                                  fontSize: 24,
                                  fontWeight: FontWeight.w900,
                                ),
                              )
                            : const Text(
                                'Start',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class PitchGraphPainter extends CustomPainter {
  final double centerMidi;
  final List<double?> pitchHistory;
  final bool isPlaying;
  final List<String> noteNames;
  final double tickProgress; 

  PitchGraphPainter({
    required this.centerMidi,
    required this.pitchHistory,
    required this.isPlaying,
    required this.noteNames,
    required this.tickProgress,
  });

  String _midiToName(int midi) {
    int octave = (midi ~/ 12) - 1;
    String note = noteNames[midi % 12];
    return '$note$octave';
  }

  @override
  void paint(Canvas canvas, Size size) {
    final rightMargin = 40.0;
    final graphWidth = size.width - rightMargin;
    
    final double semitoneSpan = 21.0; 
    final int topMidi = (centerMidi + semitoneSpan / 2).ceil();
    final int bottomMidi = (centerMidi - semitoneSpan / 2).floor();
    final double semitoneHeight = size.height / semitoneSpan;

    final linePaint = Paint()
      ..color = Colors.white.withOpacity(0.12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.left,
    );

    // 1. Draw horizontal lines and note labels
    for (int midi = bottomMidi; midi <= topMidi; midi++) {
        final double y = ((centerMidi + semitoneSpan / 2) - midi) * semitoneHeight;

        canvas.drawLine(Offset(0, y), Offset(size.width, y), linePaint);

        textPainter.text = TextSpan(
          text: _midiToName(midi),
          style: TextStyle(
            color: Colors.white.withOpacity(0.5),
            fontSize: 12,
            fontWeight: FontWeight.w400,
          ),
        );
        textPainter.layout();
        textPainter.paint(canvas, Offset(graphWidth + 12, y - textPainter.height / 2));
    }

    // 2. Draw the pitch line as a smooth cubic Bezier curve
    final pathPaint = Paint()
      ..color = const Color(0xFFE93B81)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round;

    final graphPath = Path();
    
    // Calculate valid consecutive segments of lines 
    // to draw smooth splines without connecting across null gaps
    final List<List<Offset>> segments = [];
    List<Offset> currentSegment = [];
    
    final int pointCount = pitchHistory.length;
    final double dx = graphWidth / (pointCount - 1);
    
    Offset? lastValidOffset;

    for (int i = 0; i < pointCount; i++) {
      final double? val = pitchHistory[i];
      if (val != null) {
        final double y = ((centerMidi + semitoneSpan / 2) - val) * semitoneHeight;
        
        // Shift left continuously based on paint sub-frame
        double x = dx * i - (isPlaying ? (tickProgress * dx) : 0);
        if (x < 0) x = 0; 
        
        final pt = Offset(x, y);
        currentSegment.add(pt);
        lastValidOffset = pt;
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
    
    // Draw each contiguous non-null segment as a smooth spline
    for (var segment in segments) {
      if (segment.length == 1) {
         graphPath.moveTo(segment[0].dx, segment[0].dy);
         graphPath.lineTo(segment[0].dx + 1, segment[0].dy); // draw dot
      } else if (segment.length == 2) {
         graphPath.moveTo(segment[0].dx, segment[0].dy);
         graphPath.lineTo(segment[1].dx, segment[1].dy);
      } else {
         graphPath.moveTo(segment[0].dx, segment[0].dy);
         // Generate flawlessly smooth curves using quadratic midpoint approximations
         // This eliminates 90-degree jagged staircase angles
         for (int i = 0; i < segment.length - 1; i++) {
            final p0 = segment[i];
            final p1 = segment[i + 1];
            
            final midPoint = Offset((p0.dx + p1.dx) / 2, (p0.dy + p1.dy) / 2);
            
            if (i == 0) {
               graphPath.lineTo(midPoint.dx, midPoint.dy);
            } else {
               graphPath.quadraticBezierTo(p0.dx, p0.dy, midPoint.dx, midPoint.dy);
            }
         }
         // finish the line to the last actual point
         graphPath.lineTo(segment.last.dx, segment.last.dy);
      }
    }
    
    canvas.drawPath(graphPath, pathPaint);

    // 3. Draw the smoothly moving ball
    double leadY = size.height / 2;
    if (lastValidOffset != null) {
      leadY = lastValidOffset.dy;
    }

    final ballPaint = Paint()
      ..color = const Color(0xFFE93B81)
      ..style = PaintingStyle.fill;
      
    // Always draw a ball at the far right leading edge
    // Because we lerp paths and poll fast, this tracks beautifully
    canvas.drawCircle(Offset(graphWidth, leadY), 8.0, ballPaint);
  }

  @override
  bool shouldRepaint(covariant PitchGraphPainter oldDelegate) {
     return true; // Continuously redraw independently of point ticks for maximum fps
  }
}
