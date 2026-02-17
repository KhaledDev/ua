import 'package:flutter/material.dart';
import '../models/course.dart';
import '../Services/course_storage.dart';
import '../Services/TimeConverter.dart';
import 'add_course_screen.dart';

class TimetableScreen extends StatefulWidget {
  const TimetableScreen({super.key});

  @override
  State<TimetableScreen> createState() => _TimetableScreenState();
}

class _TimetableScreenState extends State<TimetableScreen> {
  List<Course> _courses = [];
  bool _isRamadanMode = false;
  bool _isLoading = true;

  final List<String> _dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final courses = await CourseStorage.loadCourses();
    final ramadanMode = await CourseStorage.isRamadanMode();
    setState(() {
      _courses = courses;
      _isRamadanMode = ramadanMode;
      _isLoading = false;
    });
  }

  String _getDisplayTimeSlot(Course course) {
    if (_isRamadanMode) {
      return TimeConverter.convertToRamadan(
        course.timeSlot,
        course.isFriday(),
      );
    }
    return course.timeSlot;
  }

  /// Generates a list of time slots from all courses
  List<String> _generateTimeSlots() {
    final Set<String> slotSet = {};
    for (final course in _courses) {
      slotSet.add(_getDisplayTimeSlot(course));
    }
    final slots = slotSet.toList();
    slots.sort((a, b) {
      final aStart = TimeConverter.parseTimeSlot(a)['start']!;
      final bStart = TimeConverter.parseTimeSlot(b)['start']!;
      return aStart.compareTo(bStart);
    });
    return slots;
  }

  /// Gets courses for a specific day and time slot
  List<Course> _getCoursesForSlot(int weekday, String timeSlot) {
    return _courses.where((course) {
      final displaySlot = _getDisplayTimeSlot(course);
      return course.days.contains(weekday) && displaySlot == timeSlot;
    }).toList();
  }

  Future<void> _deleteCourse(Course course) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Course'),
        content: Text('Are you sure you want to delete ${course.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await CourseStorage.deleteCourse(course.id);
      await _loadData();
    }
  }

  void _showCourseDetails(Course course) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(course.name),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Time: ${_getDisplayTimeSlot(course)}'),
            if (course.location != null) Text('Location: ${course.location}'),
            if (course.instructor != null)
              Text('Instructor: ${course.instructor}'),
            Text('Days: ${course.getDaysString()}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final result = await Navigator.push<bool>(
                context,
                MaterialPageRoute(
                  builder: (context) => AddCourseScreen(course: course),
                ),
              );
              if (result == true) {
                await _loadData();
              }
            },
            child: const Text('Edit'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _deleteCourse(course);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Full Timetable')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final timeSlots = _generateTimeSlots();

    if (timeSlots.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Full Timetable')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.school,
                size: 64,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 16),
              Text(
                'No courses yet',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Full Timetable'),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth > 600;
          final cellWidth = isWide
              ? (constraints.maxWidth - 100) / 7
              : constraints.maxWidth / 7;

          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header row with day names
                  Container(
                    height: 50,
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                      border: Border(
                        bottom: BorderSide(
                          color: Colors.grey[300]!,
                          width: 1,
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 100,
                          child: Center(
                            child: Text(
                              'Time',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: isWide ? 14 : 12,
                              ),
                            ),
                          ),
                        ),
                        ...List.generate(7, (index) {
                          return Container(
                            width: cellWidth,
                            decoration: BoxDecoration(
                              border: Border(
                                left: BorderSide(
                                  color: Colors.grey[300]!,
                                  width: 1,
                                ),
                              ),
                            ),
                            child: Center(
                              child: Text(
                                _dayNames[index],
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: isWide ? 14 : 12,
                                ),
                              ),
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                  // Time slot rows
                  ...timeSlots.map((timeSlot) {
                    return Container(
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: Colors.grey[300]!,
                            width: 1,
                          ),
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Time label
                          Container(
                            width: 100,
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Theme.of(context)
                                  .primaryColor
                                  .withValues(alpha: 0.05),
                              border: Border(
                                right: BorderSide(
                                  color: Colors.grey[300]!,
                                  width: 1,
                                ),
                              ),
                            ),
                            child: Center(
                              child: Text(
                                timeSlot,
                                style: TextStyle(
                                  fontSize: isWide ? 12 : 10,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                          // Day columns
                          ...List.generate(7, (dayIndex) {
                            final weekday = dayIndex + 1;
                            final courses = _getCoursesForSlot(weekday, timeSlot);

                            return Container(
                              width: cellWidth,
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                border: Border(
                                  left: BorderSide(
                                    color: Colors.grey[300]!,
                                    width: 1,
                                  ),
                                ),
                              ),
                              child: courses.isEmpty
                                  ? const SizedBox.shrink()
                                  : Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      children: courses.map((course) {
                                        final now = DateTime.now();
                                        final times = TimeConverter.parseTimeSlot(
                                          _getDisplayTimeSlot(course),
                                        );
                                        final startTime = times['start']!;
                                        final endTime = times['end']!;
                                        final isInProgress = now.isAfter(
                                                startTime) &&
                                            now.isBefore(endTime);

                                        return GestureDetector(
                                          onTap: () => _showCourseDetails(course),
                                          child: Container(
                                            margin: const EdgeInsets.only(
                                              bottom: 2,
                                            ),
                                            padding: const EdgeInsets.all(6),
                                            decoration: BoxDecoration(
                                              color: isInProgress
                                                  ? Colors.green[100]
                                                  : Theme.of(context)
                                                      .primaryColor
                                                      .withValues(alpha: 0.1),
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                              border: Border.all(
                                                color: isInProgress
                                                    ? Colors.green[700]!
                                                    : Theme.of(context)
                                                        .primaryColor
                                                        .withValues(alpha: 0.3),
                                                width: 1,
                                              ),
                                            ),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  course.name,
                                                  style: TextStyle(
                                                    fontSize: isWide ? 11 : 9,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                  maxLines: 2,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                                if (course.location != null &&
                                                    isWide)
                                                  Text(
                                                    course.location!,
                                                    style: TextStyle(
                                                      fontSize: 9,
                                                      color: Colors.grey[700],
                                                    ),
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                              ],
                                            ),
                                          ),
                                        );
                                      }).toList(),
                                    ),
                            );
                          }),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
