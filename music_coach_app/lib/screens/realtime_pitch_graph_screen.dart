import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_audio_capture/flutter_audio_capture.dart';
import 'package:pitch_detector_dart/pitch_detector.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:music_coach/config/api_config.dart';
import 'package:music_coach/services/auth_service.dart';


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
  
  bool _showHistory = false;
  List<double?> _fullSessionHistory = [];
  DateTime? _sessionStartTime;
  List<dynamic> _historyRecords = [];
  bool _isLoadingHistory = false;
  dynamic _selectedHistoryRecord;


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

  Future<void> _fetchHistory() async {
    setState(() => _isLoadingHistory = true);
    try {
      final token = await AuthService.getToken();
      if (token == null) return;
      final response = await http.get(
        Uri.parse('${ApiConfig.lessonsBase}/pitch-history/'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (response.statusCode == 200) {
        if (mounted) {
          setState(() {
            _historyRecords = jsonDecode(response.body);
          });
        }
      }
    } catch (_) {} finally {
      if (mounted) setState(() => _isLoadingHistory = false);
    }
  }

  Future<void> _deleteHistory(int id) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) return;
      final response = await http.delete(
        Uri.parse('${ApiConfig.lessonsBase}/pitch-history/$id/'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (response.statusCode == 204) {
        _fetchHistory();
      }
    } catch (_) {}
  }

  Future<void> _saveHistory() async {
    if (_fullSessionHistory.isEmpty || _sessionStartTime == null) return;
    final duration = DateTime.now().difference(_sessionStartTime!).inMilliseconds / 1000.0;
    if (duration < 2.0) return; // Ignore very short clicks
    
    var data = List<double?>.from(_fullSessionHistory);
    // Trim leading null gap before speaking, but retain 30 ticks (about 0.6s) as padding
    int firstValidIndex = data.indexWhere((val) => val != null);
    if (firstValidIndex != -1) {
      int startIndex = math.max(0, firstValidIndex - 30);
      if (startIndex > 0) {
        data = data.sublist(startIndex);
      }
    }
    
    try {
      final token = await AuthService.getToken();
      if (token == null) return;
      await http.post(
        Uri.parse('${ApiConfig.lessonsBase}/pitch-history/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'duration_seconds': duration,
          'pitch_data': data,
        }),
      );
      // Fetch latest so the list view is ready
      _fetchHistory();
    } catch (_) {}
  }

  void _togglePlayPause() {
    setState(() {
      _isPlaying = !_isPlaying;
      if (_isPlaying) {
        // If resuming or starting fresh
        if (_fullSessionHistory.isEmpty) {
          _pitchHistory.clear();
          for (int i = 0; i < maxPoints; i++) {
            _pitchHistory.add(null);
          }
          _sessionStartTime = DateTime.now();
        }
        _showHistory = false;
        _selectedHistoryRecord = null;
        
        _startTimer();
        _startListening();
      } else {
        // Pause logic (do not clear history or save)
        _stopTimer();
        _stopListening();
        _currentMidiVal = null; 
        _smoothedMidiVal = null;
      }
    });
  }

  Future<void> _stopAndSave() async {
    if (!_isPlaying && _fullSessionHistory.isEmpty) return; // already stopped & cleared

    _stopTimer();
    await _stopListening();
    
    setState(() {
      _isPlaying = false;
      _currentMidiVal = null; 
      _smoothedMidiVal = null;
    });

    await _saveHistory();

    setState(() {
      _showHistory = true;
      _selectedHistoryRecord = null;
      _fullSessionHistory.clear();
      _pitchHistory.clear();
      for (int i = 0; i < maxPoints; i++) {
        _pitchHistory.add(null);
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
        _fullSessionHistory.add(_smoothedMidiVal);
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

  Widget _buildHistoryList() {
    if (_isLoadingHistory) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFFE93B81)));
    }
    if (_historyRecords.isEmpty) {
      return const Center(
        child: Text('No history available yet.', style: TextStyle(color: Colors.white54)),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _historyRecords.length,
      itemBuilder: (context, index) {
        final record = _historyRecords[index];
        final double duration = record['duration_seconds'] ?? 0.0;
        final String dateStr = record['created_at'] ?? '';
        final DateTime? date = DateTime.tryParse(dateStr);
        final String formattedDate = date != null ? '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}' : 'Unknown';
        
        List<dynamic> rawData = record['pitch_data'] ?? [];
        List<double?> pitchData = [];
        for (var p in rawData) {
          if (p == null) {
             pitchData.add(null);
          } else if (p is num) {
             pitchData.add(p.toDouble());
          } else {
             pitchData.add(null);
          }
        }

        return GestureDetector(
          onTap: () {
             setState(() {
                _selectedHistoryRecord = record;
             });
          },
          child: Card(
            color: const Color(0xFF1B233C),
            margin: const EdgeInsets.only(bottom: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Session $formattedDate',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    Row(
                      children: [
                        Text(
                          '${duration.toStringAsFixed(1)}s',
                          style: const TextStyle(color: Color(0xFFE93B81), fontWeight: FontWeight.bold),
                        ),
                        IconButton(
                          padding: const EdgeInsets.only(left: 12),
                          constraints: const BoxConstraints(),
                          icon: const Icon(Icons.delete_outline, color: Colors.white30, size: 20),
                          onPressed: () {
                             if (record['id'] != null) {
                                _deleteHistory(record['id']);
                             }
                          },
                        ),
                      ],
                    ),
                  ],
                ),
                  const SizedBox(height: 12),
                  Container(
                    height: 120,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: const Color(0xFF101424),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ClipRect(
                      child: CustomPaint(
                        painter: StaticPitchGraphPainter(
                          pitchHistory: pitchData,
                          noteNames: _noteNames,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHistoryDetail() {
    if (_selectedHistoryRecord == null) return const SizedBox();
    
    List<dynamic> rawData = _selectedHistoryRecord['pitch_data'] ?? [];
    List<double?> pitchData = [];
    for (var p in rawData) {
      if (p == null) {
          pitchData.add(null);
      } else if (p is num) {
          pitchData.add(p.toDouble());
      } else {
          pitchData.add(null);
      }
    }
    
    // Calculate required width: e.g. 5 pixels per point for smooth panning 
    // or just let the painter figure it out but painter needs Size.
    // If pointCount is 1000, and 4 points per unit, width is 4000
    final pointCount = pitchData.length;
    final double desiredWidth = math.max(MediaQuery.of(context).size.width, pointCount * 8.0);
    
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white70),
                onPressed: () {
                  setState(() => _selectedHistoryRecord = null);
                },
              ),
              const Expanded(
                child: Text(
                  'Detailed View',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return Stack(
                children: [
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Container(
                      width: desiredWidth,
                      height: constraints.maxHeight,
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      child: CustomPaint(
                        painter: StaticPitchGraphPainter(
                          pitchHistory: pitchData,
                          noteNames: _noteNames,
                          showLabels: false,
                        ),
                      ),
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Container(
                      width: 40,
                      height: constraints.maxHeight,
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                          colors: [
                            Colors.transparent,
                            const Color(0xFF101424).withOpacity(0.8),
                            const Color(0xFF101424),
                          ]
                        )
                      ),
                      child: CustomPaint(
                        painter: StaticPitchGraphPainter(
                          pitchHistory: pitchData,
                          noteNames: _noteNames,
                          showLabels: true,
                          onlyLabels: true,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            }
          ),
        ),
      ],
    );
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
                    if (!_isPlaying)
                      IconButton(
                        icon: Icon(_showHistory ? Icons.close : Icons.history, color: Colors.white70),
                        onPressed: () {
                          setState(() {
                            _showHistory = !_showHistory;
                            if (_showHistory) _fetchHistory();
                          });
                        },
                      )
                    else
                      const SizedBox(width: 44), 
                  ],
                ),
              ),
              
              // Note Lines and Graph Container
              Expanded(
                child: _showHistory
                  ? (_selectedHistoryRecord != null ? _buildHistoryDetail() : _buildHistoryList())
                  : Container(
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
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (_fullSessionHistory.isNotEmpty || _isPlaying)
                      const SizedBox(width: 84), // Balance the stop button to keep Start perfectly centered
                    GestureDetector(
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
                              ? const Icon(Icons.pause, color: Colors.black, size: 28)
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
                    if (_fullSessionHistory.isNotEmpty || _isPlaying) ...[
                      const SizedBox(width: 20),
                      GestureDetector(
                        onTap: () {
                           _stopAndSave();
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            color: Colors.transparent, 
                            border: Border.all(color: Colors.white30, width: 2),
                            shape: BoxShape.circle,
                          ),
                          child: const Center(
                            child: Icon(Icons.stop, color: Colors.white, size: 28),
                          ),
                        ),
                      ),
                    ]
                  ],
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

class StaticPitchGraphPainter extends CustomPainter {
  final List<double?> pitchHistory;
  final List<String> noteNames;
  final bool showLabels;
  final bool onlyLabels;

  StaticPitchGraphPainter({
    required this.pitchHistory,
    required this.noteNames,
    this.showLabels = false,
    this.onlyLabels = false,
  });

  String _midiToName(int midi) {
    int octave = (midi ~/ 12) - 1;
    String note = noteNames[midi % 12];
    return '$note$octave';
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (pitchHistory.isEmpty) return;
    
    double minMidi = 127.0;
    double maxMidi = 0.0;
    
    for (var val in pitchHistory) {
      if (val != null) {
        if (val < minMidi) minMidi = val;
        if (val > maxMidi) maxMidi = val;
      }
    }
    
    if (minMidi > maxMidi) {
       // no valid pitches
       return; 
    }
    
    final int bottomMidi = (minMidi - 2).floor();
    final int topMidi = (maxMidi + 2).ceil();
    final double semitoneSpan = (topMidi - bottomMidi).toDouble();
    if (semitoneSpan == 0) return;
    
    final double semitoneHeight = size.height / semitoneSpan;
    
    final rightMargin = showLabels ? 25.0 : 0.0;
    final graphWidth = size.width - rightMargin;

    final linePaint = Paint()
      ..color = Colors.white.withOpacity(0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.left,
    );

    for (int midi = bottomMidi; midi <= topMidi; midi += 2) {
        final double y = size.height - ((midi - bottomMidi) * semitoneHeight);

        if (!onlyLabels) {
          canvas.drawLine(Offset(0, y), Offset(size.width, y), linePaint);
        }

        if (showLabels) {
          textPainter.text = TextSpan(
            text: _midiToName(midi),
            style: TextStyle(
              color: Colors.white.withOpacity(0.6),
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          );
          textPainter.layout();
          textPainter.paint(canvas, Offset(graphWidth + 2, y - textPainter.height / 2));
        }
    }

    if (onlyLabels) return;

    final pathPaint = Paint()
      ..color = const Color(0xFFE93B81)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round;

    final graphPath = Path();
    final List<List<Offset>> segments = [];
    List<Offset> currentSegment = [];
    
    final int pointCount = pitchHistory.length;
    final double dx = graphWidth / (pointCount > 1 ? pointCount - 1 : 1);

    for (int i = 0; i < pointCount; i++) {
      final double? val = pitchHistory[i];
      if (val != null) {
        final double y = size.height - ((val - bottomMidi) * semitoneHeight);
        final double x = dx * i;
        currentSegment.add(Offset(x, y));
      } else {
        if (currentSegment.isNotEmpty) {
          segments.add(currentSegment);
          currentSegment = [];
        }
      }
    }
    if (currentSegment.isNotEmpty) segments.add(currentSegment);
    
    for (var segment in segments) {
      if (segment.length == 1) {
         graphPath.moveTo(segment[0].dx, segment[0].dy);
         graphPath.lineTo(segment[0].dx + 1, segment[0].dy);
      } else if (segment.length == 2) {
         graphPath.moveTo(segment[0].dx, segment[0].dy);
         graphPath.lineTo(segment[1].dx, segment[1].dy);
      } else {
         graphPath.moveTo(segment[0].dx, segment[0].dy);
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
         graphPath.lineTo(segment.last.dx, segment.last.dy);
      }
    }
    
    canvas.drawPath(graphPath, pathPaint);
  }

  @override
  bool shouldRepaint(covariant StaticPitchGraphPainter oldDelegate) {
     return false; // Static drawing
  }
}
