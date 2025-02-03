import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TimerDetails extends StatefulWidget {
  final int time;
  const TimerDetails({super.key, required this.time});

  @override
  State<TimerDetails> createState() => _TimerDetailsState();
}

class _TimerDetailsState extends State<TimerDetails> {
  DateTime? _startTime, _endTime; // Nullable variables to avoid late initialization error
  Timer? _timer;
  Duration _remainingTime = Duration.zero;
  bool _isTimerRunning = false;
  bool _isPaused = false;
  FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  @override
  void initState() {
    super.initState();
    _initializeNotifications();
    _loadTimerState();
  }

  Future<void> _initializeNotifications() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    final initializationSettings = InitializationSettings(android: androidSettings);

    await flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  Future<void> _loadTimerState() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? start = prefs.getString("start_time");
    String? end = prefs.getString("end_time");
    bool? running = prefs.getBool("timer_running");

    if (start != null && end != null && running == true) {
      _startTime = DateTime.parse(start);
      _endTime = DateTime.parse(end);
      _updateRemainingTime();
      _startCountdown();
    } else {
      _startTime = DateTime.now();
      _endTime = _startTime!.add(Duration(seconds: widget.time));
      _updateRemainingTime();
    }
  }

  Future<void> _saveTimerState() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    if (_startTime != null && _endTime != null) {
      await prefs.setString("start_time", _startTime!.toIso8601String());
      await prefs.setString("end_time", _endTime!.toIso8601String());
      await prefs.setBool("timer_running", _isTimerRunning);
    }
  }

  void _startTimer() {
    if (_isTimerRunning && !_isPaused) return;

    setState(() {
      if (_isPaused) {
        _endTime = DateTime.now().add(_remainingTime);
      } else {
        _startTime = DateTime.now();
        _endTime = _startTime!.add(Duration(seconds: widget.time));
      }
      _isTimerRunning = true;
      _isPaused = false;
    });

    _saveTimerState();
    _startCountdown();
  }

  void _pauseTimer() {
    if (!_isTimerRunning) return;

    setState(() {
      _isPaused = true;
      _isTimerRunning = false;
    });

    _timer?.cancel();
    _saveTimerState();
  }

  void _startCountdown() {
    _timer?.cancel();
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() => _updateRemainingTime());
      if (_remainingTime.inSeconds <= 0) {
        _timer?.cancel();
        _showNotification('Timer Finished', 'The timer has completed.');
      }
    });
  }

  void _updateRemainingTime() {
    DateTime now = DateTime.now();
    if (_endTime != null && _endTime!.isAfter(now)) {
      _remainingTime = _endTime!.difference(now);
    } else {
      _remainingTime = Duration.zero;
    }
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
                    _buildTimeBox("Starting", _startTime),
                    SizedBox(height: 10),
                    _buildTimeBox("Ending", _isTimerRunning ? _endTime : null),
                    SizedBox(height: 40),
                    _buildTimeBox("Now", _formatTime(_remainingTime)),
                  ],
                ),
              ],
            ),
            SizedBox(height: 50),
            ElevatedButton(
              onPressed: _isTimerRunning ? _pauseTimer : _startTimer,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
              ),
              child: Text(
                _isTimerRunning ? "Pause Timer" : "Start Timer",
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeBox(String label, dynamic value) {
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
            value is DateTime ? value.toString().substring(11, 16) : value.toString(),
            style: TextStyle(color: label == "Now" ? Colors.black : Colors.white),
          ),
        ],
      ),
    );
  }
}
