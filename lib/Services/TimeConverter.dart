import 'package:intl/intl.dart';

class TimeConverter {
  // Map of normal timing to ramadan timing conversions based on the CSV
  static final Map<String, Map<String, String>> _mondayToThursdayConversions = {
    // Single slot timings
    '08:30-09:30': {'ramadan': '08:30-09:10'},
    '09:30-10:30': {'ramadan': '09:10-09:50'},
    '10:30-11:30': {'ramadan': '09:50-10:30'},
    '11:30-12:30': {'ramadan': '10:30-11:10'},
    '12:30-13:30': {'ramadan': '11:10-11:50'},
    '13:30-14:30': {'ramadan': '11:50-12:30'},
    '14:30-15:30': {'ramadan': '12:30-13:10'},
    '15:30-16:30': {'ramadan': '13:10-13:50'},
    '16:30-17:30': {'ramadan': '13:50-14:30'},
    '17:30-18:30': {'ramadan': '14:30-15:10'},
    '18:30-19:30': {'ramadan': '15:10-15:50'},
    '19:30-20:30': {'ramadan': '15:50-16:30'},
    '20:30-21:30': {'ramadan': '16:30-17:10'},
    // Two-slot timings
    '08:00-09:30': {'ramadan': '08:00-09:00'},
    '09:30-11:00': {'ramadan': '09:10-10:10'},
    '11:00-12:30': {'ramadan': '10:10-11:10'},
    '13:30-15:00': {'ramadan': '11:50-12:50'},
    '15:00-16:30': {'ramadan': '12:50-13:50'},
    '16:30-18:00': {'ramadan': '13:50-14:50'},
    '18:00-19:30': {'ramadan': '14:50-15:50'},
    '19:30-21:00': {'ramadan': '15:50-16:50'},
    '21:00-22:30': {'ramadan': '16:50-17:50'},
    // Three-slot timings
    '08:30-10:30': {'ramadan': '08:30-09:50'},
    '10:30-12:30': {'ramadan': '09:50-11:10'},
    '12:30-14:30': {'ramadan': '11:10-12:30'},
    '14:30-16:30': {'ramadan': '12:30-13:50'},
    '16:30-18:30': {'ramadan': '13:50-15:10'},
    '18:30-20:30': {'ramadan': '15:10-16:30'},
    '20:30-22:30': {'ramadan': '16:30-17:50'},
    // One-hour timings
    '09:00-10:00': {'ramadan': '08:50-09:30'},
    '10:00-11:00': {'ramadan': '09:30-10:10'},
    '11:00-12:00': {'ramadan': '10:10-10:50'},
    '12:00-13:00': {'ramadan': '10:50-11:30'},
    '13:00-14:00': {'ramadan': '11:30-12:10'},
    '14:00-15:00': {'ramadan': '12:10-12:50'},
    '15:00-16:00': {'ramadan': '12:50-13:30'},
    '16:00-17:00': {'ramadan': '13:30-14:10'},
    '17:00-18:00': {'ramadan': '14:10-14:50'},
    '18:00-19:00': {'ramadan': '14:50-15:30'},
    '19:00-20:00': {'ramadan': '15:30-16:10'},
    '20:00-21:00': {'ramadan': '16:10-16:50'},
    '21:00-22:00': {'ramadan': '16:50-17:30'},
  };

  static final Map<String, Map<String, String>> _fridayConversions = {
    '08:00-09:00': {'ramadan': '08:00-08:40'},
    '08:00-10:00': {'ramadan': '08:00-09:20'},
    '08:00-12:00': {'ramadan': '08:00-10:40'},
    '08:30-12:00': {'ramadan': '08:30-10:50'},
    '09:00-12:00': {'ramadan': '08:40-10:40'},
    '10:00-12:00': {'ramadan': '09:20-10:40'},
    '14:00-15:00': {'ramadan': '10:40-11:20'},
    '14:00-16:00': {'ramadan': '10:40-12:00'},
    '14:00-17:00': {'ramadan': '14:00-16:00'},
    '14:00-18:00': {'ramadan': '14:00-16:40'},
    '14:00-19:00': {'ramadan': '14:00-17:20'},
    '14:30-16:30': {'ramadan': '14:00-15:20'},
    '15:00-16:00': {'ramadan': '14:00-14:40'},
    '15:00-17:00': {'ramadan': '14:00-15:20'},
    '15:00-18:00': {'ramadan': '14:00-16:00'},
    '15:00-19:00': {'ramadan': '14:00-16:40'},
    '16:00-18:00': {'ramadan': '14:40-16:00'},
    '16:00-19:00': {'ramadan': '14:40-16:40'},
    '16:30-18:30': {'ramadan': '15:20-16:40'},
    '17:30-20:30': {'ramadan': '15:30-17:30'},
    '18:00-19:00': {'ramadan': '16:40-17:20'},
    '18:00-20:00': {'ramadan': '16:00-17:20'},
    '18:00-21:00': {'ramadan': '16:00-18:00'},
    '18:30-20:30': {'ramadan': '16:00-17:20'},
    '19:00-20:00': {'ramadan': '16:40-17:20'},
  };

  /// Converts a time slot to Ramadan timing
  ///
  /// [timeSlot] - The original time slot (e.g., "08:30-09:30")
  /// [isFriday] - Whether this is for a Friday class
  /// Returns the Ramadan timing or the original if no conversion exists
  static String convertToRamadan(String timeSlot, bool isFriday) {
    final conversions = isFriday
        ? _fridayConversions
        : _mondayToThursdayConversions;
    return conversions[timeSlot]?['ramadan'] ?? timeSlot;
  }

  /// Parses a time string (HH:mm) and returns DateTime for today
  static DateTime parseTime(String time) {
    final parts = time.split(':');
    final now = DateTime.now();
    return DateTime(
      now.year,
      now.month,
      now.day,
      int.parse(parts[0]),
      int.parse(parts[1]),
    );
  }

  /// Extracts start and end time from a time slot string
  static Map<String, DateTime> parseTimeSlot(String timeSlot) {
    final parts = timeSlot.split('-');
    return {'start': parseTime(parts[0]), 'end': parseTime(parts[1])};
  }

  /// Formats DateTime to HH:mm
  static String formatTime(DateTime time) {
    return DateFormat('HH:mm').format(time);
  }
}
