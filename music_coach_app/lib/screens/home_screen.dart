import 'package:flutter/material.dart';
import 'package:music_coach/services/auth_service.dart';
import 'package:music_coach/services/instrument_service.dart';
import 'package:music_coach/models/instrument_item.dart';
import 'package:music_coach/widgets/cached_instrument_image.dart';
import 'package:music_coach/services/progress_service.dart';
import 'package:music_coach/services/lesson_service.dart';

class HomeScreen extends StatefulWidget {
  final Function(String)? onLessonTap;

  const HomeScreen({super.key, this.onLessonTap});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<InstrumentItem> instruments = [];
  bool isLoading = true;
  String? errorMessage;
  String? username;
  int currentStreak = 0;

  // Dynamic progress maps
  Map<String, int> _totalLessonsMap = {};
  Map<String, int> _completedLessonsMap = {};

  // Color mapping for different instrument types
  final Map<String, Color> _colorMap = {
    'piano': const Color(0xFF00B4D8),
    'vocals': const Color(0xFF6C5CE7),
    'vocal': const Color(0xFF6C5CE7),
    'guitar': const Color(0xFF00D9A5),
    'pitch': const Color(0xFFFF006E),
  };

  // Description mapping for instruments (fallback)
  final Map<String, String> _descriptionMap = {
    'piano': 'Loading...',
    'vocals': 'Loading...',
    'vocal': 'Loading...',
    'guitar': 'Tune your guitar',
    'pitch': 'Real-time pitch',
  };

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    // Load user profile for username
    final profile = await AuthService.fetchProfile();
    if (profile != null) {
      setState(() {
        username = profile['username'];
        currentStreak = profile['current_streak'] ?? 0;
      });
    }

    // Load instruments
    try {
      final fetchedInstruments = await InstrumentService.fetchInstruments();
      
      // Load progress map
      final completedIds = await ProgressService.getCompletedLessons();
      Map<String, int> totalMap = {};
      Map<String, int> completedMap = {};

      for (var instrument in fetchedInstruments) {
        if (_hasProgressBar(instrument.type)) {
          try {
            final modules = await LessonService.fetchModules(instrumentType: instrument.type);
            int total = 0;
            int completedCount = 0;
            for (var module in modules) {
              total += module.lessons.length;
              for (var lesson in module.lessons) {
                if (completedIds.contains(lesson.id)) {
                  completedCount++;
                }
              }
            }
            totalMap[instrument.type] = total;
            completedMap[instrument.type] = completedCount;
          } catch (e) {
            print('Error fetching lessons for ${instrument.type}: $e');
          }
        }
      }

      setState(() {
        instruments = fetchedInstruments;
        _totalLessonsMap = totalMap;
        _completedLessonsMap = completedMap;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = 'Failed to load instruments. Please try again.';
        isLoading = false;
      });
    }
  }

  Color _getColorForType(String type) {
    return _colorMap[type.toLowerCase()] ?? const Color(0xFF00B4D8);
  }

  String _getDescriptionForType(String type) {
    if (_hasProgressBar(type)) {
      if (_totalLessonsMap.containsKey(type)) {
        return '${_totalLessonsMap[type]} Lessons';
      }
    }
    return _descriptionMap[type.toLowerCase()] ?? 'Lessons';
  }

  bool _hasProgressBar(String type) {
    final typeLower = type.toLowerCase();
    return typeLower == 'piano' || typeLower == 'vocals' || typeLower == 'vocal';
  }

  void _navigateToInstrument(InstrumentItem instrument) {
    final typeLower = instrument.type.toLowerCase();
    
    // For piano and vocals, switch to lessons tab in MainLayout
    if (typeLower == 'piano' || typeLower == 'vocals' || typeLower == 'vocal') {
      widget.onLessonTap?.call(instrument.type);
    } else {
      // For guitar and pitch, push a new route (will show back button)
      Navigator.pushNamed(context, instrument.route);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A1929),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome Section
              Text(
                username != null && username!.trim().isNotEmpty
                    ? 'Welcome back, ${username!.trim()}!'
                    : 'Welcome back,',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w400,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Continue your musical journey',
                style: TextStyle(
                  color: Color(0xFFB0BEC5),
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                ),
              ),
              const SizedBox(height: 24),

              // Current Streak Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20.0),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFF1744), Color(0xFFFF006E)],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Current Streak',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          currentStreak.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          currentStreak == 1 ? 'day in a row' : 'days in a row',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                    Image.asset(
                      'assets/icons/trophy.png',
                      width: 48,
                      height: 48,
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(
                          Icons.emoji_events,
                          color: Colors.white,
                          size: 48,
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Modes Section
              const Text(
                'Modes',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),

              // Instruments Grid
              if (isLoading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32.0),
                    child: CircularProgressIndicator(
                      color: Colors.white,
                    ),
                  ),
                )
              else if (errorMessage != null)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Column(
                      children: [
                        Text(
                          errorMessage!,
                          style: const TextStyle(color: Colors.red),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _loadData,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                )
              else
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    childAspectRatio: 0.85,
                  ),
                  itemCount: instruments.length,
                  itemBuilder: (context, index) {
                    final instrument = instruments[index];
                    final color = _getColorForType(instrument.type);
                    final description = _getDescriptionForType(instrument.type);
                    final hasProgress = _hasProgressBar(instrument.type);

                    double widthFactor = 0.0;
                    if (hasProgress && _totalLessonsMap.containsKey(instrument.type) && _totalLessonsMap[instrument.type]! > 0) {
                      widthFactor = (_completedLessonsMap[instrument.type] ?? 0) / _totalLessonsMap[instrument.type]!;
                    }

                    return _ModeCard(
                      instrument: instrument,
                      color: color,
                      description: description,
                      hasProgress: hasProgress,
                      progressFraction: widthFactor,
                      onTap: () => _navigateToInstrument(instrument),
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ModeCard extends StatelessWidget {
  final InstrumentItem instrument;
  final Color color;
  final String description;
  final bool hasProgress;
  final double progressFraction;
  final VoidCallback onTap;

  const _ModeCard({
    required this.instrument,
    required this.color,
    required this.description,
    required this.hasProgress,
    this.progressFraction = 0.0,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon
            CachedInstrumentImage(
              instrument: instrument,
              width: 48,
              height: 48,
              svgColor: color,
            ),
            const SizedBox(height: 12),
            // Name
            Text(
              instrument.name,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            // Description
            Text(
              description,
              style: const TextStyle(
                color: Color(0xFF94A3B8),
                fontSize: 12,
                fontWeight: FontWeight.w400,
              ),
            ),
            const Spacer(),
            // Progress Bar (only for piano and vocals)
            if (hasProgress)
              Container(
                height: 8,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: progressFraction.clamp(0.0, 1.0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(4),
                      boxShadow: [
                        BoxShadow(
                          color: color.withOpacity(0.5),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
