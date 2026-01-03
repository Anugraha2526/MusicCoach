class InstrumentItem {
  final int instrumentId;
  final String name;
  final String type;
  final String? imageUrl;
  final String createdAt;
  final String updatedAt;

  // Computed properties for UI compatibility
  String get id => type.toLowerCase();
  String get title => name;
  String get svgIcon => _getSvgIconForType(type);
  String get route => _getRouteForType(type);

  InstrumentItem({
    required this.instrumentId,
    required this.name,
    required this.type,
    this.imageUrl,
    required this.createdAt,
    required this.updatedAt,
  });

  // Factory constructor to create from JSON
  factory InstrumentItem.fromJson(Map<String, dynamic> json) {
    return InstrumentItem(
      instrumentId: json['instrument_id'] ?? json['id'] ?? 0,
      name: json['name'] ?? '',
      type: json['type'] ?? '',
      imageUrl: json['image_url'],
      createdAt: json['created_at'] ?? '',
      updatedAt: json['updated_at'] ?? '',
    );
  }

  // Map to JSON for API calls if needed
  Map<String, dynamic> toJson() {
    return {
      'instrument_id': instrumentId,
      'name': name,
      'type': type,
      'image_url': imageUrl,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  // Helper method to get SVG icon path based on type
  String _getSvgIconForType(String type) {
    final typeLower = type.toLowerCase();
    switch (typeLower) {
      case 'piano':
        return 'assets/icons/piano.svg';
      case 'guitar':
        return 'assets/icons/guitar.svg';
      case 'vocals':
      case 'vocal':
        return 'assets/icons/vocals.svg';
      case 'pitch':
        return 'assets/icons/pitch.svg';
      default:
        return 'assets/icons/piano.svg'; // default fallback
    }
  }

  // Helper method to get route based on type
  String _getRouteForType(String type) {
    final typeLower = type.toLowerCase();
    switch (typeLower) {
      case 'piano':
        return '/piano-lesson';
      case 'guitar':
        return '/guitar-tuner';
      case 'vocals':
      case 'vocal':
        return '/vocal-lesson';
      case 'pitch':
        return '/realtime-pitch-graph';
      default:
        return '/piano-lesson'; // default fallback
    }
  }
}
