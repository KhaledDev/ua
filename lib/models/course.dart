class Course {
  final String id;
  final String name;
  final String timeSlot; // e.g., "08:30-09:30"
  final List<int> days; // 1=Monday, 2=Tuesday, ..., 7=Sunday
  final String? location;
  final String? instructor;

  Course({
    required this.id,
    required this.name,
    required this.timeSlot,
    required this.days,
    this.location,
    this.instructor,
  });

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'timeSlot': timeSlot,
      'days': days,
      'location': location,
      'instructor': instructor,
    };
  }

  // Create from JSON
  factory Course.fromJson(Map<String, dynamic> json) {
    return Course(
      id: json['id'] as String,
      name: json['name'] as String,
      timeSlot: json['timeSlot'] as String,
      days: List<int>.from(json['days'] as List),
      location: json['location'] as String?,
      instructor: json['instructor'] as String?,
    );
  }

  // Create a copy with optional field changes
  Course copyWith({
    String? id,
    String? name,
    String? timeSlot,
    List<int>? days,
    String? location,
    String? instructor,
  }) {
    return Course(
      id: id ?? this.id,
      name: name ?? this.name,
      timeSlot: timeSlot ?? this.timeSlot,
      days: days ?? this.days,
      location: location ?? this.location,
      instructor: instructor ?? this.instructor,
    );
  }

  String getDaysString() {
    const dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days.map((d) => dayNames[d - 1]).join(', ');
  }

  bool isToday() {
    final today = DateTime.now().weekday;
    return days.contains(today);
  }

  bool isFriday() {
    return days.contains(5); // Friday is 5
  }
}
