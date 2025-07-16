class Parameter {
  final String id;
  final String name;
  final double value;
  final double normalizedValue;
  final String text;
  final ParameterColor color;
  final double min;
  final double max;
  final double step;
  final String unit;
  final String category;
  final bool isActive;
  final DateTime lastUpdated;
  final int? index; // For VST parameter index

  Parameter({
    required this.id,
    required this.name,
    required this.value,
    required this.normalizedValue,
    required this.text,
    required this.color,
    this.min = 0.0,
    this.max = 1.0,
    this.step = 0.01,
    this.unit = '',
    this.category = '',
    this.isActive = true,
    DateTime? lastUpdated,
    this.index,
  }) : lastUpdated = lastUpdated ?? DateTime.now();

  Parameter copyWith({
    String? id,
    String? name,
    double? value,
    double? normalizedValue,
    String? text,
    ParameterColor? color,
    double? min,
    double? max,
    double? step,
    String? unit,
    String? category,
    bool? isActive,
    DateTime? lastUpdated,
    int? index,
  }) {
    return Parameter(
      id: id ?? this.id,
      name: name ?? this.name,
      value: value ?? this.value,
      normalizedValue: normalizedValue ?? this.normalizedValue,
      text: text ?? this.text,
      color: color ?? this.color,
      min: min ?? this.min,
      max: max ?? this.max,
      step: step ?? this.step,
      unit: unit ?? this.unit,
      category: category ?? this.category,
      isActive: isActive ?? this.isActive,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      index: index ?? this.index,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'value': value,
      'normalized_value': normalizedValue,
      'text': text,
      'color': color.toJson(),
      'min': min,
      'max': max,
      'step': step,
      'unit': unit,
      'category': category,
      'is_active': isActive,
      'last_updated': lastUpdated.toIso8601String(),
      'index': index,
    };
  }

  factory Parameter.fromJson(Map<String, dynamic> json) {
    return Parameter(
      id: json['id'] as String,
      name: json['name'] as String,
      value: (json['value'] as num?)?.toDouble() ?? 0.0,
      normalizedValue: (json['normalized_value'] as num?)?.toDouble() ?? 0.0,
      text: json['text'] as String? ?? '',
      color: json['rgbColor'] != null 
          ? ParameterColor.fromJson(json['rgbColor'] as Map<String, dynamic>)
          : const ParameterColor(r: 128, g: 128, b: 128),
      min: (json['min'] as num?)?.toDouble() ?? 0.0,
      max: (json['max'] as num?)?.toDouble() ?? 1.0,
      step: (json['step'] as num?)?.toDouble() ?? 0.01,
      unit: json['unit'] as String? ?? '',
      category: json['category'] as String? ?? '',
      isActive: json['is_active'] as bool? ?? true,
      lastUpdated: json['last_updated'] != null 
          ? DateTime.parse(json['last_updated'] as String)
          : DateTime.now(),
      index: json['index'] as int?,
    );
  }

  @override
  String toString() {
    return 'Parameter(id: $id, name: $name, value: $value, text: $text)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Parameter && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

class ParameterColor {
  final int r;
  final int g;
  final int b;

  const ParameterColor({
    required this.r,
    required this.g,
    required this.b,
  });

  Map<String, dynamic> toJson() {
    return {
      'r': r,
      'g': g,
      'b': b,
    };
  }

  factory ParameterColor.fromJson(Map<String, dynamic> json) {
    return ParameterColor(
      r: (json['r'] as num?)?.toInt() ?? 128,
      g: (json['g'] as num?)?.toInt() ?? 128,
      b: (json['b'] as num?)?.toInt() ?? 128,
    );
  }

  @override
  String toString() => 'ParameterColor(r: $r, g: $g, b: $b)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ParameterColor && 
           other.r == r && 
           other.g == g && 
           other.b == b;
  }

  @override
  int get hashCode => Object.hash(r, g, b);
} 