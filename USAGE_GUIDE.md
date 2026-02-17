# University Course Time App

A Flutter mobile app to help you manage your university course schedule with support for Ramadan timing adjustments and smart notifications.

## Features

✅ **Easy Course Management**

- Add courses with name, time slot, days, location, and instructor
- Edit or delete existing courses
- Comprehensive list of time slots based on university schedule

✅ **Ramadan Timing Toggle**

- One-tap toggle between normal and Ramadan timings
- Automatic time conversion based on the university schedule
- Separate conversions for Friday classes

✅ **Smart Notifications**

- Get reminded 30 minutes before class starts
- Get reminded 15 minutes before class starts
- Notifications automatically adjust when toggling Ramadan mode

✅ **Today's Schedule**

- See all your classes for today at a glance
- Highlighted "Next Class" card showing your upcoming class
- Visual indicators for current, upcoming, and past classes

✅ **All Courses View**

- Drawer menu showing all your courses
- Quick access to edit any course
- See which days each course occurs

## Screenshots

[Coming soon]

## Getting Started

### Prerequisites

- Flutter SDK (3.11.0 or higher)
- Android Studio / Xcode for mobile development
- A physical device or emulator

### Installation

1. Clone the repository:

```bash
cd ua
```

2. Install dependencies:

```bash
flutter pub get
```

3. Run the app:

```bash
flutter run
```

## Usage

### Adding a Course

1. Tap the **+** button on the home screen
2. Fill in the course details:
   - **Course Name** (required)
   - **Time Slot** (required) - Select from dropdown
   - **Days** (required) - Select one or more days
   - **Location** (optional)
   - **Instructor** (optional)
3. Tap the checkmark or "Add Course" button

### Toggling Ramadan Mode

1. On the home screen, you'll see a "Ramadan Timings" switch at the top
2. Toggle it on to use Ramadan schedule
3. All course times will automatically adjust
4. Notifications will be rescheduled for the new times

### Managing Courses

- **Edit**: Tap on any course card or use the drawer menu
- **Delete**: Tap the delete icon on a course card
- **View All**: Open the drawer (swipe from left or tap menu icon)

### Notifications

The app will automatically:

- Request notification permissions on first launch
- Schedule notifications for all your courses
- Send reminders 30 minutes and 15 minutes before each class
- Update notifications when you add, edit, or delete courses
- Reschedule all notifications when toggling Ramadan mode

If notifications aren't working:

1. Open the app menu (three dots in top right)
2. Select "Request Notification Permissions"
3. Grant permissions in your device settings

## How Ramadan Timing Works

The app uses a comprehensive conversion table based on your university's official Ramadan schedule:

- **Monday to Thursday**: Standard weekday conversions
- **Friday**: Special Friday schedule conversions
- **Time slots**: Covers all common time slots from the CSV data

The conversion automatically handles:

- Single slot classes (1 hour)
- Double slot classes (1.5-2 hours)
- Triple slot classes (2-3 hours)
- Long classes (3-4 hours)

## Project Structure

```
lib/
├── main.dart                    # App entry point
├── models/
│   └── course.dart             # Course data model
├── Services/
│   ├── TimeConverter.dart      # Ramadan timing conversion logic
│   ├── course_storage.dart     # Local storage for courses
│   └── notification_service.dart # Push notification management
└── screens/
    ├── home_screen.dart        # Main screen with today's schedule
    └── add_course_screen.dart  # Add/edit course screen
```

## Dependencies

- `flutter_local_notifications`: For course reminders
- `shared_preferences`: For storing courses locally
- `intl`: For date/time formatting
- `timezone`: For scheduling notifications

## Permissions

### Android

- `POST_NOTIFICATIONS`: To send notifications
- `SCHEDULE_EXACT_ALARM`: To schedule exact notifications
- `USE_EXACT_ALARM`: Alternative alarm permission
- `RECEIVE_BOOT_COMPLETED`: To restore notifications after device restart
- `VIBRATE`: To vibrate on notifications

### iOS

- Alert, Badge, and Sound permissions requested at runtime

## Future Enhancements

- [ ] Week view calendar
- [ ] Export/import schedule
- [ ] Custom notification sound
- [ ] Widget for home screen
- [ ] Dark mode
- [ ] Multiple profiles (for different semesters)
- [ ] Class notes and assignments
- [ ] Attendance tracker

## Troubleshooting

**Notifications not working?**

- Make sure you granted notification permissions
- Check that battery optimization is disabled for the app
- On Android 13+, POST_NOTIFICATIONS permission is required

**Wrong times showing?**

- Verify Ramadan mode is toggled correctly
- Check that you selected the correct time slot when adding the course

**App crashes on startup?**

- Run `flutter clean` and `flutter pub get`
- Make sure you're using Flutter 3.11.0 or higher

## License

This project is for educational purposes.

## Contributing

Feel free to submit issues and pull requests!

## Support

For questions or issues, please open an issue on GitHub.
