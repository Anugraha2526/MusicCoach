import re

with open(r'c:\Users\hp\Documents\Projects\Flutter\MusicProjectFYP\music_coach\music_coach_app\lib\screens\realtime_pitch_graph_screen.dart', 'r') as f:
    text = f.read()

# 1. Add imports
imports = """import 'package:pitch_detector_dart/pitch_detector.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:music_coach/config/api_config.dart';
import 'package:music_coach/services/auth_service.dart';
"""
text = text.replace("import 'package:pitch_detector_dart/pitch_detector.dart';", imports)

# 2. Add state vars
state_vars = """  late AnimationController _repaintController;
  
  bool _showHistory = false;
  List<double?> _fullSessionHistory = [];
  DateTime? _sessionStartTime;
  List<dynamic> _historyRecords = [];
  bool _isLoadingHistory = false;
"""
text = text.replace("  late AnimationController _repaintController;", state_vars)

# 3. Add API Methods
api_methods = """  Future<void> _fetchHistory() async {
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

  Future<void> _saveHistory() async {
    if (_fullSessionHistory.isEmpty || _sessionStartTime == null) return;
    final duration = DateTime.now().difference(_sessionStartTime!).inMilliseconds / 1000.0;
    if (duration < 2.0) return; // Ignore very short clicks
    
    final data = List<double?>.from(_fullSessionHistory);
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
      // Wait to fetch if currently showing history
      if (_showHistory) {
         _fetchHistory();
      }
    } catch (_) {}
  }

  void _togglePlayPause() {"""
text = text.replace("  void _togglePlayPause() {", api_methods)

# 4. Modify Toggle Logic
toggle_orig = """      if (_isPlaying) {
        // Clear history to start fresh
        _pitchHistory.clear();
        for (int i = 0; i < maxPoints; i++) {
          _pitchHistory.add(null);
        }
        _currentMidiVal = null;
        _smoothedMidiVal = null;"""
toggle_new = """      if (_isPlaying) {
        // Clear history to start fresh
        _pitchHistory.clear();
        for (int i = 0; i < maxPoints; i++) {
          _pitchHistory.add(null);
        }
        _fullSessionHistory.clear();
        _sessionStartTime = DateTime.now();
        _showHistory = false;
        _currentMidiVal = null;
        _smoothedMidiVal = null;"""
text = text.replace(toggle_orig, toggle_new)

text = text.replace("""        _stopListening();
        _currentMidiVal = null; 
        _smoothedMidiVal = null;
      }
    });
  }""", """        _stopListening();
        _currentMidiVal = null; 
        _smoothedMidiVal = null;
        _saveHistory();
      }
    });
  }""")

# 5. Add to full history collection
text = text.replace("""        _pitchHistory.add(_smoothedMidiVal);
        if (_pitchHistory.length > maxPoints) {""", """        _pitchHistory.add(_smoothedMidiVal);
        _fullSessionHistory.add(_smoothedMidiVal);
        if (_pitchHistory.length > maxPoints) {""")

# 6. Change top right button
text = text.replace("""                    const SizedBox(width: 44), 
                  ],
                ),""", """                    if (!_isPlaying)
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
                ),""")

# 7. Add ListView logic
text = text.replace("""              Expanded(
                child: Container(
                  margin: const EdgeInsets.only(top: 16),
                  child: ClipRect(""", """              Expanded(
                child: _showHistory
                  ? _buildHistoryList()
                  : Container(
                  margin: const EdgeInsets.only(top: 16),
                  child: ClipRect(""")

# 8. Add _buildHistoryList and StaticPainter methods
build_history = """  Widget _buildHistoryList() {
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

        return Card(
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
                    Text(
                      '${duration.toStringAsFixed(1)}s',
                      style: const TextStyle(color: Color(0xFFE93B81), fontWeight: FontWeight.bold),
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
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {"""

text = text.replace("  @override\n  Widget build(BuildContext context) {", build_history)

# 9. Define StaticPitchGraphPainter
static_painter = """
class StaticPitchGraphPainter extends CustomPainter {
  final List<double?> pitchHistory;
  final List<String> noteNames;

  StaticPitchGraphPainter({
    required this.pitchHistory,
    required this.noteNames,
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
    
    final rightMargin = 20.0;
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

        canvas.drawLine(Offset(0, y), Offset(size.width, y), linePaint);

        textPainter.text = TextSpan(
          text: _midiToName(midi),
          style: TextStyle(
            color: Colors.white.withOpacity(0.4),
            fontSize: 10,
            fontWeight: FontWeight.w400,
          ),
        );
        textPainter.layout();
        textPainter.paint(canvas, Offset(graphWidth + 4, y - textPainter.height / 2));
    }

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
"""
text = text + static_painter

with open(r'c:\Users\hp\Documents\Projects\Flutter\MusicProjectFYP\music_coach\music_coach_app\lib\screens\realtime_pitch_graph_screen.dart', 'w') as f:
    f.write(text)

print("SUCCESS")
