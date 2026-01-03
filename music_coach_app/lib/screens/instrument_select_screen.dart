import 'package:flutter/material.dart';
import 'package:music_coach/services/auth_service.dart';
import 'package:music_coach/services/instrument_service.dart';
import 'package:music_coach/models/instrument_item.dart';
import 'package:music_coach/routes/app_routes.dart';
import 'package:music_coach/widgets/cached_instrument_image.dart';

class InstrumentSelectScreen extends StatefulWidget {
  const InstrumentSelectScreen({super.key});

  @override
  State<InstrumentSelectScreen> createState() => _InstrumentSelectScreenState();
}

class _InstrumentSelectScreenState extends State<InstrumentSelectScreen> {
  List<InstrumentItem> instruments = [];
  bool isLoading = true;
  String? errorMessage;

  // Color mapping for different instrument types
  final Map<String, Color> _colorMap = {
    'piano': const Color(0xFF00B4D8),
    'vocals': const Color(0xFF6C5CE7),
    'vocal': const Color(0xFF6C5CE7),
    'guitar': const Color(0xFF00D9A5),
    'pitch': const Color(0xFFFF006E),
  };

  @override
  void initState() {
    super.initState();
    _loadInstruments();
  }

  Future<void> _loadInstruments() async {
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

  Future<void> _handleInstrumentSelection(InstrumentItem instrument) async {
    await AuthService.completeOnboarding();
    await AuthService.saveSelectedInstrument(instrument.type.toLowerCase());
    await AuthService.setShowLessonsFirst(true);
    if (mounted) {
      Navigator.pushReplacementNamed(context, AppRoutes.main);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A1929), // Dark blue background
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Text(
                  'Choose Your Path',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 32),
                if (isLoading)
                  const CircularProgressIndicator(
                    color: Colors.white,
                  )
                else if (errorMessage != null)
                  Column(
                    children: [
                      Text(
                        errorMessage!,
                        style: const TextStyle(color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadInstruments,
                        child: const Text('Retry'),
                      ),
                    ],
                  )
                else
                  SizedBox(
                    width: 360,
                    child: GridView.builder(
                      shrinkWrap: true,
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: 24,
                        crossAxisSpacing: 24,
                        childAspectRatio: 1.0,
                      ),
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: instruments.length,
                      itemBuilder: (context, index) {
                        final instrument = instruments[index];
                        return _InstrumentCard(
                          color: _getColorForType(instrument.type),
                          instrument: instrument,
                          onTap: () => _handleInstrumentSelection(instrument),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _InstrumentCard extends StatelessWidget {
  final Color color;
  final InstrumentItem instrument;
  final VoidCallback onTap;

  const _InstrumentCard({
    required this.color,
    required this.instrument,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.4),
              blurRadius: 20,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Center(
          // Use database image_url if available, otherwise fallback to local SVG
          child: CachedInstrumentImage(
            instrument: instrument,
            width: 80,
            height: 80,
          ),
        ),
      ),
    );
  }

}
