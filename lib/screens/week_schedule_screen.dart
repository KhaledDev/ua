import 'package:flutter/material.dart';
import '../models/course.dart';
import '../Services/course_storage.dart';
import '../Services/TimeConverter.dart';
import 'components/course_tile.dart';
import 'add_course_screen.dart';

class WeekScheduleScreen extends StatefulWidget {
  const WeekScheduleScreen({super.key});

  @override
  State<WeekScheduleScreen> createState() => _WeekScheduleScreenState();
}

class _WeekScheduleScreenState extends State<WeekScheduleScreen>
    with SingleTickerProviderStateMixin {
  List<Course> _courses = [];
  bool _isRamadanMode = false;
  bool _isLoading = true;
  late TabController _tabController;

  final List<String> _dayNames = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 7, vsync: this);
    // Set initial tab to today
    final today = DateTime.now().weekday;
    _tabController.index = today - 1;
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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

  List<Course> _getCoursesForDay(int weekday) {
    return _courses
        .where((c) => c.days.contains(weekday))
        .toList()
      ..sort((a, b) {
        final aTime = TimeConverter.parseTimeSlot(
          _getDisplayTimeSlot(a),
        )['start']!;
        final bTime = TimeConverter.parseTimeSlot(
          _getDisplayTimeSlot(b),
        )['start']!;
        return aTime.compareTo(bTime);
      });
  }

  Course? _getCurrentClass(int weekday) {
    final dayCourses = _getCoursesForDay(weekday);
    final now = DateTime.now();

    for (final course in dayCourses) {
      final times = TimeConverter.parseTimeSlot(_getDisplayTimeSlot(course));
      final startTime = times['start']!;
      final endTime = times['end']!;

      if (now.isAfter(startTime) && now.isBefore(endTime)) {
        return course;
      }
    }
    return null;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Week Schedule'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: _dayNames.map((day) => Tab(text: day)).toList(),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: List.generate(7, (index) {
                final weekday = index + 1;
                final dayCourses = _getCoursesForDay(weekday);
                final currentClass = _getCurrentClass(weekday);

                return Column(
                  children: [
                    // Current class indicator
                    if (currentClass != null)
                      Container(
                        margin: const EdgeInsets.all(16),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.green[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.green[300]!),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.play_circle_filled,
                                color: Colors.green[700]),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Current Class',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.green[700],
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    currentClass.name,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    _getDisplayTimeSlot(currentClass),
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.green[700],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                    // Courses list
                    Expanded(
                      child: dayCourses.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.free_breakfast,
                                    size: 64,
                                    color: Colors.grey[400],
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'No classes on ${_dayNames[index]}',
                                    style: TextStyle(
                                      fontSize: 18,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              itemCount: dayCourses.length,
                              itemBuilder: (context, courseIndex) {
                                final course = dayCourses[courseIndex];
                                final timeSlot = _getDisplayTimeSlot(course);
                                final times =
                                    TimeConverter.parseTimeSlot(timeSlot);
                                final startTime = times['start']!;
                                final endTime = times['end']!;
                                final now = DateTime.now();

                                final isInProgress = now.isAfter(startTime) &&
                                    now.isBefore(endTime);
                                final isPast = now.isAfter(endTime);

                                return CourseTile(
                                  course: course,
                                  displayTimeSlot: timeSlot,
                                  isInProgress: isInProgress,
                                  isPast: isPast,
                                  onTap: () async {
                                    final result = await Navigator.push<bool>(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            AddCourseScreen(course: course),
                                      ),
                                    );
                                    if (result == true) {
                                      await _loadData();
                                    }
                                  },
                                  onDelete: () => _deleteCourse(course),
                                );
                              },
                            ),
                    ),
                  ],
                );
              }),
            ),
    );
  }
}
