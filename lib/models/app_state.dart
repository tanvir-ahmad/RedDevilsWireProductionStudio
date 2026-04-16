enum StudioStatus {
  idle,
  scripting,
  voicing,
  baking,
}

class ProductionLog {
  final String message;
  final DateTime timestamp;

  ProductionLog(this.message) : timestamp = DateTime.now();
}

class NewsStory {
  final String title;
  final String body;
  final DateTime timestamp;

  NewsStory({
    required this.title,
    required this.body,
  }) : timestamp = DateTime.now();
}

class OptimizationData {
  final List<String> titles;
  final String description;
  final List<String> keywords;
  final List<String> hashtags;

  OptimizationData({
    required this.titles,
    required this.description,
    required this.keywords,
    required this.hashtags,
  });

  factory OptimizationData.fromJson(Map<String, dynamic> json) {
    List<String> parseList(dynamic val) {
      if (val == null) return [];
      if (val is List) return List<String>.from(val.map((e) => e.toString()));
      if (val is String) return [val];
      return [];
    }

    return OptimizationData(
      titles: parseList(json['titles']),
      description: json['description']?.toString() ?? "",
      keywords: parseList(json['keywords']),
      hashtags: parseList(json['hashtags']),
    );
  }

  factory OptimizationData.empty() {
    return OptimizationData(titles: [], description: "", keywords: [], hashtags: []);
  }

  bool get isEmpty => titles.isEmpty && description.isEmpty;
}
