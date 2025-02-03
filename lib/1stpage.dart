import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class TimerDetails extends StatefulWidget {
  final int time; // Duration for the timer in seconds
  const TimerDetails({super.key, required this.time, required String timerId});

  @override
  State<TimerDetails> createState() => _TimerDetailsState();
}

class _TimerDetailsState extends State<TimerDetails> {
  DateTime? _startTime, _endTime;
  Timer? _timer;
  Duration _remainingTime = Duration.zero;
  bool _isTimerRunning = false;
  FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  @override
  void initState() {
    super.initState();
    _initializeNotifications();
  }

  Future<void> _initializeNotifications() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    final initializationSettings = InitializationSettings(android: androidSettings);

    await flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  void _startTimer() {
    if (_isTimerRunning) return;  // Avoid starting if already running

    setState(() {
      _startTime = DateTime.now(); // Set the current time when the timer starts
      _endTime = _startTime!.add(Duration(seconds: widget.time)); // Calculate the end time
      _remainingTime = Duration(seconds: widget.time); // Set the remaining time to the initial duration
      _isTimerRunning = true; // Timer is running
    });

    _startCountdown();

    // Show a "Timer is running" notification when the timer starts
    _showNotification('Timer is Running', 'The timer has started.');
  }

  void _startCountdown() {
    _timer?.cancel();  // Cancel any previous timer
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {
        _updateRemainingTime();  // Update the remaining time on every tick
      });

      // Stop the timer and show a completion notification when time reaches zero
      if (_remainingTime.inSeconds <= 0) {
        _timer?.cancel();
        _showNotification('Timer Finished', 'The timer has completed.');
      }
    });
  }

  void _updateRemainingTime() {
    setState(() {
      DateTime now = DateTime.now();
      if (_endTime != null && _endTime!.isAfter(now)) {
        _remainingTime = _endTime!.difference(now);
      } else {
        _remainingTime = Duration.zero;
      }
    });
  }

  Future<void> _showNotification(String title, String body) async {
    const androidDetails = AndroidNotificationDetails(
      'timer_channel',
      'Timer Notifications',
      importance: Importance.high,
      priority: Priority.high,
    );
    const notificationDetails = NotificationDetails(android: androidDetails);
    await flutterLocalNotificationsPlugin.show(0, title, body, notificationDetails);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _formatTime(Duration duration) {
    return "${duration.inMinutes.toString().padLeft(2, '0')}:${(duration.inSeconds % 60).toString().padLeft(2, '0')}";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        centerTitle: true,
        title: Text("Work Timer", style: TextStyle(color: Colors.white)),
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: Icon(Icons.arrow_back_ios, color: Colors.white),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 250,
                  height: 250,
                  child: CircularProgressIndicator(
                    value: _isTimerRunning
                        ? _remainingTime.inSeconds / widget.time
                        : 1.0,
                    color: Colors.white,
                    strokeWidth: 5,
                  ),
                ),
                Column(
                  children: [
                    // Time Box for "Starting"
                    _buildTimeBox("Starting", _startTime ?? Duration.zero),
                    SizedBox(height: 10),
                    // Time Box for "Ending"
                    _buildTimeBox(
                      "Ending",
                      _endTime ?? Duration.zero, // Initially will show 00:00
                    ),
                    SizedBox(height: 40),
                    // Time Box for "Now"
                    _buildTimeBox("Now", _remainingTime),
                  ],
                ),
              ],
            ),
            SizedBox(height: 50),
            ElevatedButton(
              onPressed: _isTimerRunning ? null : _startTimer,  // Disable if the timer is already running
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
              ),
              child: Text(
                _isTimerRunning ? "Timer Running" : "Start Timer",  // Change text depending on the timer state
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper method to build the time display boxes
  Widget _buildTimeBox(String label, dynamic value) {
    String formattedTime = "00:00";  // Default time format

    if (value is DateTime) {
      // If the value is DateTime (for start and end time)
      formattedTime = DateFormat.jm().format(value);  // Format as time (12-hour)
    } else if (value is Duration) {
      // If the value is Duration (for remaining time)
      formattedTime = _formatTime(value);
    }

    return Container(
      width: 150,
      height: 50,
      decoration: BoxDecoration(
        color: label == "Starting"
            ? Colors.green
            : (label == "Ending" ? Colors.red : Colors.white),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label, style: TextStyle(color: label == "Now" ? Colors.black : Colors.white)),
          Text(
            formattedTime,
            style: TextStyle(color: label == "Now" ? Colors.black : Colors.white),
          ),
        ],
      ),
    );
  }
}