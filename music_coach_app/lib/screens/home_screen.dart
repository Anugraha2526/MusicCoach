import 'package:flutter/material.dart';
import 'package:music_coach/services/auth_service.dart';
import 'package:music_coach/services/instrument_service.dart';
import 'package:music_coach/models/instrument_item.dart';
import 'package:music_coach/widgets/cached_instrument_image.dart';

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

  // Color mapping for different instrument types
  final Map<String, Color> _colorMap = {
    'piano': const Color(0xFF00B4D8),
    'vocals': const Color(0xFF6C5CE7),
    'vocal': const Color(0xFF6C5CE7),
    'guitar': const Color(0xFF00D9A5),
    'pitch': const Color(0xFFFF006E),
  };

  // Description mapping for instruments
  final Map<String, String> _descriptionMap = {
    'piano': '15 Lessons',
    'vocals': '15 Lessons',
    'vocal': '15 Lessons',
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
      });
    }

    // Load instruments
    try {
      final fetchedInstruments = await InstrumentService.fetchInstruments();
      setState(() {
        instruments = fetchedInstruments;
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
              const Text(
                'Welcome back,',
                style: TextStyle(
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
                        const Text(
                          '5',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'days in a row',
                          style: TextStyle(
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

                    return _ModeCard(
                      instrument: instrument,
                      color: color,
                      description: description,
                      hasProgress: hasProgress,
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
  final VoidCallback onTap;

  const _ModeCard({
    required this.instrument,
    required this.color,
    required this.description,
    required this.hasProgress,
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
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFF334155),
                  borderRadius: BorderRadius.circular(2),
                ),
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: 0.4, // 40% progress (static for now)
                  child: Container(
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(2),
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
