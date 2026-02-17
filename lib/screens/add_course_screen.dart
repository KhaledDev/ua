import 'package:flutter/material.dart';
import '../models/course.dart';
import '../Services/course_storage.dart';
import '../Services/notification_service.dart';
import '../widgets/khaled_dev_watermark.dart';

class AddCourseScreen extends StatefulWidget {
  final Course? course; // For editing existing courses

  const AddCourseScreen({super.key, this.course});

  @override
  State<AddCourseScreen> createState() => _AddCourseScreenState();
}

class _AddCourseScreenState extends State<AddCourseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _locationController = TextEditingController();
  final _instructorController = TextEditingController();

  String? _selectedTimeSlot;
  final Set<int> _selectedDays = {};

  // Common time slots based on the CSV
  final List<String> _timeSlots = [
    '08:00-09:00',
    '08:00-09:30',
    '08:00-10:00',
    '08:00-12:00',
    '08:30-09:30',
    '08:30-10:30',
    '08:30-12:00',
    '09:00-10:00',
    '09:00-12:00',
    '09:30-10:30',
    '09:30-11:00',
    '10:00-11:00',
    '10:00-12:00',
    '10:30-11:30',
    '10:30-12:30',
    '11:00-12:00',
    '11:00-12:30',
    '11:30-12:30',
    '12:00-13:00',
    '12:30-13:30',
    '12:30-14:30',
    '13:00-14:00',
    '13:30-14:30',
    '13:30-15:00',
    '14:00-15:00',
    '14:00-16:00',
    '14:00-17:00',
    '14:00-18:00',
    '14:00-19:00',
    '14:30-15:30',
    '14:30-16:30',
    '15:00-16:00',
    '15:00-16:30',
    '15:00-17:00',
    '15:00-18:00',
    '15:00-19:00',
    '15:30-16:30',
    '16:00-17:00',
    '16:00-18:00',
    '16:00-19:00',
    '16:30-17:30',
    '16:30-18:00',
    '16:30-18:30',
    '17:00-18:00',
    '17:30-18:30',
    '17:30-20:30',
    '18:00-19:00',
    '18:00-19:30',
    '18:00-20:00',
    '18:00-21:00',
    '18:30-19:30',
    '18:30-20:30',
    '19:00-20:00',
    '19:30-20:30',
    '19:30-21:00',
    '20:00-21:00',
    '20:30-21:30',
    '20:30-22:30',
    '21:00-22:00',
    '21:00-22:30',
  ];

  final List<String> _dayNames = [
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
    'Sun',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.course != null) {
      _nameController.text = widget.course!.name;
      _locationController.text = widget.course!.location ?? '';
      _instructorController.text = widget.course!.instructor ?? '';
      _selectedTimeSlot = widget.course!.timeSlot;
      _selectedDays.addAll(widget.course!.days);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _locationController.dispose();
    _instructorController.dispose();
    super.dispose();
  }

  Future<void> _saveCourse() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedTimeSlot == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a time slot')),
        );
        return;
      }

      if (_selectedDays.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select at least one day')),
        );
        return;
      }

      final course = Course(
        id:
            widget.course?.id ??
            DateTime.now().millisecondsSinceEpoch.toString(),
        name: _nameController.text.trim(),
        timeSlot: _selectedTimeSlot!,
        days: _selectedDays.toList()..sort(),
        location: _locationController.text.trim().isEmpty
            ? null
            : _locationController.text.trim(),
        instructor: _instructorController.text.trim().isEmpty
            ? null
            : _instructorController.text.trim(),
      );

      if (widget.course == null) {
        await CourseStorage.addCourse(course);
      } else {
        await CourseStorage.updateCourse(course);
        await NotificationService.cancelCourseNotifications(widget.course!);
      }

      await NotificationService.scheduleCourseNotifications(course);

      if (mounted) {
        Navigator.pop(context, true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.course == null ? 'Add Course' : 'Edit Course'),
        actions: [
          IconButton(icon: const Icon(Icons.check), onPressed: _saveCourse),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Course Name',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.book),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a course name';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _selectedTimeSlot,
              decoration: const InputDecoration(
                labelText: 'Time Slot',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.access_time),
              ),
              items: _timeSlots.map((slot) {
                return DropdownMenuItem(value: slot, child: Text(slot));
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedTimeSlot = value;
                });
              },
            ),
            const SizedBox(height: 16),
            const Text(
              'Days',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: List.generate(7, (index) {
                final day = index + 1;
                final isSelected = _selectedDays.contains(day);
                return FilterChip(
                  label: Text(_dayNames[index]),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _selectedDays.add(day);
                      } else {
                        _selectedDays.remove(day);
                      }
                    });
                  },
                );
              }),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _locationController,
              decoration: const InputDecoration(
                labelText: 'Location (optional)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.location_on),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _instructorController,
              decoration: const InputDecoration(
                labelText: 'Instructor (optional)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _saveCourse,
              icon: const Icon(Icons.save),
              label: Text(
                widget.course == null ? 'Add Course' : 'Update Course',
              ),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(16),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const KhaledDevWatermark(),
    );
  }
}
