import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/course.dart';
import '../Services/course_storage.dart';
import '../Services/TimeConverter.dart';
import '../Services/notification_service.dart';
import 'add_course_screen.dart';

class HomeScreen extends StatefulWidget {
  final Function(ThemeMode)? onThemeChanged;

  const HomeScreen({super.key, this.onThemeChanged});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Course> _courses = [];
  bool _isRamadanMode = false;
  bool _isLoading = true;

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

  Future<void> _toggleRamadanMode(bool value) async {
    try {
      await CourseStorage.setRamadanMode(value);
      await NotificationService.rescheduleAllNotifications();
      setState(() {
        _isRamadanMode = value;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              value ? 'Ramadan timings enabled' : 'Normal timings enabled',
            ),
          ),
        );
      }
    } catch (e) {
      print('Error toggling Ramadan mode: $e');
      // Still update the UI even if notifications fail (e.g., on web)
      setState(() {
        _isRamadanMode = value;
      });
    }
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
      await NotificationService.cancelCourseNotifications(course);
      await CourseStorage.deleteCourse(course.id);
      await _loadData();
    }
  }

  String _getDisplayTimeSlot(Course course) {
    if (_isRamadanMode) {
      return TimeConverter.convertToRamadan(course.timeSlot, course.isFriday());
    }
    return course.timeSlot;
  }

  List<Course> _getTodaysCourses() {
    final today = DateTime.now().weekday;
    return _courses.where((c) => c.days.contains(today)).toList()..sort((a, b) {
      final aTime = TimeConverter.parseTimeSlot(
        _getDisplayTimeSlot(a),
      )['start']!;
      final bTime = TimeConverter.parseTimeSlot(
        _getDisplayTimeSlot(b),
      )['start']!;
      return aTime.compareTo(bTime);
    });
  }

  Course? _getNextClass() {
    final todaysCourses = _getTodaysCourses();
    final now = DateTime.now();

    for (final course in todaysCourses) {
      final times = TimeConverter.parseTimeSlot(_getDisplayTimeSlot(course));
      final endTime = times['end']!;

      if (now.isBefore(endTime)) {
        return course;
      }
    }
    return null;
  }

  String _getTimeUntil(DateTime targetTime) {
    final now = DateTime.now();
    final difference = targetTime.difference(now);

    if (difference.isNegative) {
      return 'In progress';
    }

    final hours = difference.inHours;
    final minutes = difference.inMinutes.remainder(60);

    if (hours > 0) {
      return 'in ${hours}h ${minutes}m';
    } else {
      return 'in ${minutes}m';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('University Courses'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) async {
              if (value == 'permissions') {
                await NotificationService.requestPermissions();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Notification permissions updated'),
                    ),
                  );
                }
              } else if (value == 'theme') {
                _showThemeDialog();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'theme',
                child: Row(
                  children: [
                    Icon(Icons.palette),
                    SizedBox(width: 8),
                    Text('Theme'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'permissions',
                child: Row(
                  children: [
                    Icon(Icons.notifications),
                    SizedBox(width: 8),
                    Text('Notification Permissions'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Ramadan mode toggle
                Card(
                  margin: const EdgeInsets.all(16),
                  child: SwitchListTile(
                    title: const Text('Ramadan Timings'),
                    subtitle: Text(
                      _isRamadanMode
                          ? 'Using shortened Ramadan schedule'
                          : 'Using normal schedule',
                    ),
                    value: _isRamadanMode,
                    onChanged: _toggleRamadanMode,
                    secondary: const Icon(Icons.schedule),
                  ),
                ),

                // Next class card
                if (_getNextClass() != null) _buildNextClassCard(),

                // Today's schedule
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Row(
                    children: [
                      const Text(
                        "Today's Schedule",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        DateFormat('EEEE, MMM d').format(DateTime.now()),
                        style: TextStyle(color: Colors.grey[600], fontSize: 14),
                      ),
                    ],
                  ),
                ),

                // Courses list
                Expanded(
                  child: _courses.isEmpty
                      ? Center(
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
                              const SizedBox(height: 8),
                              Text(
                                'Tap + to add your first course',
                                style: TextStyle(color: Colors.grey[500]),
                              ),
                            ],
                          ),
                        )
                      : _getTodaysCourses().isEmpty
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
                                'No classes today!',
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
                          itemCount: _getTodaysCourses().length,
                          itemBuilder: (context, index) {
                            final course = _getTodaysCourses()[index];
                            return _buildCourseCard(course);
                          },
                        ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push<bool>(
            context,
            MaterialPageRoute(builder: (context) => const AddCourseScreen()),
          );
          if (result == true) {
            await _loadData();
          }
        },
        child: const Icon(Icons.add),
      ),
      drawer: _buildDrawer(),
    );
  }

  Widget _buildNextClassCard() {
    final nextClass = _getNextClass();
    if (nextClass == null) return const SizedBox.shrink();

    final timeSlot = _getDisplayTimeSlot(nextClass);
    final times = TimeConverter.parseTimeSlot(timeSlot);
    final startTime = times['start']!;
    final endTime = times['end']!;
    final now = DateTime.now();

    final isInProgress = now.isAfter(startTime) && now.isBefore(endTime);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: isInProgress ? Colors.green[50] : Colors.blue[50],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isInProgress ? 'Current Class' : 'Next Class',
              style: TextStyle(
                fontSize: 12,
                color: isInProgress ? Colors.green[700] : Colors.blue[700],
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              nextClass.name,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  Icons.access_time,
                  size: 16,
                  color: isInProgress ? Colors.green[700] : Colors.blue[700],
                ),
                const SizedBox(width: 4),
                Text(
                  '$timeSlot • ${isInProgress ? 'In progress' : _getTimeUntil(startTime)}',
                  style: TextStyle(
                    color: isInProgress ? Colors.green[700] : Colors.blue[700],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            if (nextClass.location != null) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(
                    Icons.location_on,
                    size: 16,
                    color: isInProgress ? Colors.green[700] : Colors.blue[700],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    nextClass.location!,
                    style: TextStyle(
                      color: isInProgress
                          ? Colors.green[700]
                          : Colors.blue[700],
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCourseCard(Course course) {
    final timeSlot = _getDisplayTimeSlot(course);
    final times = TimeConverter.parseTimeSlot(timeSlot);
    final startTime = times['start']!;
    final endTime = times['end']!;
    final now = DateTime.now();

    final isInProgress = now.isAfter(startTime) && now.isBefore(endTime);
    final isPast = now.isAfter(endTime);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () async {
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
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 4,
                height: 60,
                decoration: BoxDecoration(
                  color: isInProgress
                      ? Colors.green
                      : isPast
                      ? Colors.grey
                      : Colors.blue,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      course.name,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isPast ? Colors.grey : null,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          size: 14,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          timeSlot,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    if (course.location != null) ...[
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(
                            Icons.location_on,
                            size: 14,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            course.location!,
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () => _deleteCourse(course),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(color: Theme.of(context).primaryColor),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Icon(Icons.school, size: 48, color: Colors.white),
                SizedBox(height: 8),
                Text(
                  'All Courses',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          if (_courses.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('No courses yet'),
            )
          else
            ..._courses.map((course) {
              return ListTile(
                title: Text(course.name),
                subtitle: Text(
                  '${course.getDaysString()} • ${_getDisplayTimeSlot(course)}',
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.edit),
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
                ),
                onTap: () async {
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
              );
            }),
        ],
      ),
    );
  }

  void _showThemeDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Choose Theme'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.brightness_5),
              title: const Text('Light'),
              onTap: () {
                widget.onThemeChanged?.call(ThemeMode.light);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.brightness_2),
              title: const Text('Dark'),
              onTap: () {
                widget.onThemeChanged?.call(ThemeMode.dark);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.brightness_auto),
              title: const Text('System'),
              onTap: () {
                widget.onThemeChanged?.call(ThemeMode.system);
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }
}
