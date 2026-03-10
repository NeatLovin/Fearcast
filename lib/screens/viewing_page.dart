import 'package:flutter/material.dart';
import 'dart:async';
import '../utilities/constants.dart';
import '../services/jumpscare_services.dart';
import '../services/firestore_services.dart';
import 'package:permission_handler/permission_handler.dart';
import '../main.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class ViewingPage extends StatefulWidget {
  final String mode;
  final String posterPath;
  final int movieLength;
  final int movieId;

  const ViewingPage({super.key, required this.mode, required this.posterPath, required this.movieLength, required this.movieId}); 

  @override
  ViewingPageState createState() => ViewingPageState();
}

class ViewingPageState extends State<ViewingPage> {
  Timer? _timer;
  int _elapsedSeconds = 0;
  bool _isPlaying = false;
  bool isLoading = true;
  final JumpscareServices _jumpscareServices = JumpscareServices();
  final FirestoreServices _firestoreServices = FirestoreServices();
  List<Map<String, dynamic>> _jumpscares = [];
  int _nextJumpscareIndex = 0;
  String _userSound = 'calm_sound';
  int _notificationInterval = 10;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String? _userId = FirebaseAuth.instance.currentUser?.uid;
  Timer? _inactivityTimer;
  bool _isScreenBlack = false;
  bool _showSpoilers = true;
  String _userScarySound = 'scream_sound'; 

  @override
  void initState() {
    super.initState();
    _loadPreferences();
    _requestNotificationPermission();
    _fetchJumpscares();
    WakelockPlus.enable();
    if (_isPlaying) {
    _resetInactivityTimer();
    }
  }

  void _resetInactivityTimer() {
  _inactivityTimer?.cancel();

  if (_isPlaying) {
    _inactivityTimer = Timer(const Duration(seconds: 5), () {
      setState(() {
        _isScreenBlack = true; 
      });
    });
  }
}

  Future<void> _loadPreferences() async {
  if (_userId == null) return;

  final doc = await _firestore.collection('settings').doc(_userId).get();
  if (doc.exists) {
    setState(() {
      _userSound = doc['userFearfulSound'] ?? 'calm_sound';
      _notificationInterval = doc['notificationInterval'] ?? 10;
      _userScarySound = doc['userScarySound'] ?? 'scream_sound'; 
    });
  }
}

  Future<void> _requestNotificationPermission() async {
  final PermissionStatus status = await Permission.notification.request();

  if (status.isDenied) {
    Fluttertoast.showToast(
      msg: 'Notifications are disabled',
      toastLength: Toast.LENGTH_LONG,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: errorColor,
      textColor: secondaryColor,
      fontSize: 16.0,
    );
  } else if (status.isPermanentlyDenied) {
    Fluttertoast.showToast(
      msg: 'Notifications are permanently disabled. Open settings to enable it.',
      toastLength: Toast.LENGTH_LONG,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: errorColor,
      textColor: secondaryColor,
      fontSize: 16.0,
    );
    await openAppSettings();
  }
}

Future<void> _updateJumpscareScore(int index, int delta) async {
  final jumpscare = _jumpscares[index];
  final documentId = jumpscare['id'];

  await _jumpscareServices.updateScore(documentId, delta);

  await _fetchJumpscares();
}

Future<void> _showNotification() async {
  String channelId;
  String channelName;
  String sound;

  switch (_userSound) {
    case 'goofy_sound':
      channelId = 'goofy_channel';
      channelName = 'Goofy Notification';
      sound = 'goofy_sound';
      break;
    case 'groovy_sound':
      channelId = 'groovy_channel';
      channelName = 'Groovy Notification';
      sound = 'groovy_sound';
      break;
    default:
      channelId = 'calm_channel';
      channelName = 'Calm Notification';
      sound = 'calm_sound';
  }

  setState(() {
    _isScreenBlack = false;
  });
  if (_isPlaying) {
    _resetInactivityTimer(); 
  }

  await flutterLocalNotificationsPlugin.show(
    0,
    'Upcoming Jumpscare!',
    'Get ready, a jumpscare is coming soon!',
    NotificationDetails(
      android: AndroidNotificationDetails(
        channelId,
        channelName,
        channelDescription: 'Notifications for upcoming jumpscares',
        importance: Importance.high,
        priority: Priority.high,
        playSound: true,
        sound: RawResourceAndroidNotificationSound(sound),
        enableLights: true,
        color: errorColor,
      ),
    ),
  );
}


  Future<void> _fetchJumpscares() async {
    setState(() {
      isLoading = true;
    });
    _jumpscares = await _jumpscareServices.getJumpcaresByMovieId(widget.movieId);
    _jumpscares.sort((a, b) => a['timestamp'].compareTo(b['timestamp']));
    setState(() {
      _nextJumpscareIndex = _getNextJumpscareIndex();
      isLoading = false;
    });
  }

  bool _canAddJumpscare(String newTimestamp) {
    final int newTimeInSeconds = _parseTime(newTimestamp);

    for (var jumpscare in _jumpscares) {
      final int existingTimeInSeconds = _parseTime(jumpscare['timestamp']);
      if ((newTimeInSeconds - existingTimeInSeconds).abs() <= 5) {
        return false;
      }
    }

    return true;
  }

  int _getNextJumpscareIndex() {
    for (int i = 0; i < _jumpscares.length; i++) {
      if (_parseTime(_jumpscares[i]['timestamp']) > _elapsedSeconds) {
        return i;
      }
    }
    return _jumpscares.length;
  }

  int _parseTime(String time) {
    final parts = time.split(':').map(int.parse).toList();
    return parts[0] * 3600 + parts[1] * 60 + parts[2];
  }

  Future<void> _startTimer() async {
    await _jumpscareServices.logActivity(widget.movieId, 'watch');
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {

    setState(() {
      _elapsedSeconds++;
      _nextJumpscareIndex = _getNextJumpscareIndex();

      if (_elapsedSeconds >= widget.movieLength) {
        _stopTimer();
        _isPlaying = false;
        return;
      }

      if (_nextJumpscareIndex < _jumpscares.length) {
        final int jumpscareTime = _parseTime(_jumpscares[_nextJumpscareIndex]['timestamp']);
        final int timeUntilJumpscare = jumpscareTime - _elapsedSeconds;

        if (widget.mode == 'Fearful') {
          if (timeUntilJumpscare == _notificationInterval) {
            _showNotification();
          }
        } else {
          if (timeUntilJumpscare == 1) { 
            _playScarySound();
          }
        }
      }
    });
  });
}

void _playScarySound() {
  String channelId;
  String channelName;
  String sound;

  switch (_userScarySound) {
    case 'static_sound':
      channelId = 'static_channel';
      channelName = 'Static Notification';
      sound = 'static_sound';
      break;
    case 'creak_sound':
      channelId = 'creak_channel';
      channelName = 'Creak Notification';
      sound = 'creak_sound';
      break;
    default:
      channelId = 'scream_channel';
      channelName = 'Scream Notification';
      sound = 'scream_sound';
  }

  setState(() {
    _isScreenBlack = false;
  });
  if (_isPlaying) {
    _resetInactivityTimer();
  }

  flutterLocalNotificationsPlugin.show(
    0,
    'Scary Alert!',
    'Boo!',
    NotificationDetails(
      android: AndroidNotificationDetails(
        channelId,
        channelName,
        channelDescription: 'Amplify the scare',
        importance: Importance.high,
        priority: Priority.high,
        playSound: true,
        sound: RawResourceAndroidNotificationSound(sound),
        enableLights: true,
        color: errorColor,
      ),
    ),
  );
}


  void _updateElapsedSeconds(int newElapsedSeconds) {
    setState(() {
      _elapsedSeconds = newElapsedSeconds;
      _nextJumpscareIndex = _getNextJumpscareIndex();
      if (_elapsedSeconds >= widget.movieLength) {
        _stopTimer();
        _isPlaying = false;
      }
    });
  }

  void _stopTimer() {
    _timer?.cancel();
    _inactivityTimer?.cancel();
  }

  @override
  void dispose() {
    WakelockPlus.disable();
    _inactivityTimer?.cancel();
    _timer?.cancel();
    super.dispose();
  }

  String _formatTime(int totalSeconds) {
    final int hours = totalSeconds ~/ 3600;
    final int minutes = (totalSeconds % 3600) ~/ 60;
    final int seconds = totalSeconds % 60;
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  String _getRemainingTimeText() {
    if (_nextJumpscareIndex < _jumpscares.length) {
      final int remainingSeconds = (_parseTime(_jumpscares[_nextJumpscareIndex]['timestamp']) - _elapsedSeconds).clamp(0, widget.movieLength);
      return _formatTime(remainingSeconds);
    } else {
      return AppLocalizations.of(context)!.noMoreJumpscares;
    }
  }

  Color _getRemainingTimeColor() {
    return _nextJumpscareIndex < _jumpscares.length ? Colors.white : Colors.green;
  }

  void _showAddJumpscareDialog() {
  final TextEditingController descriptionController = TextEditingController();
  
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: errorColor, width: 2),
            boxShadow: [
              BoxShadow(
                color: errorColor.withOpacity(0.3),
                blurRadius: 10,
                spreadRadius: 2,
              ),
            ],
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                AppLocalizations.of(context)!.addJumpscare,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              Container(
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.white24),
                ),
                child: TextField(
                  controller: descriptionController,
                  maxLength: 100,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: AppLocalizations.of(context)!.enterBriefDescription,
                    hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    border: InputBorder.none,
                    counterStyle: const TextStyle(color: Colors.white54),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    child: Text(
                      AppLocalizations.of(context)!.cancel,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 16,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: () async {
                      final String newTimestamp = _formatTime(_elapsedSeconds);

                      if (!_canAddJumpscare(newTimestamp)) {
                        Fluttertoast.showToast(
                          msg: AppLocalizations.of(context)!.jumpscareTooClose,
                          toastLength: Toast.LENGTH_LONG,
                          gravity: ToastGravity.BOTTOM,
                          backgroundColor: errorColor,
                          textColor: secondaryColor,
                          fontSize: 16.0,
                        );
                        return;
                      }

                      String? username = await _firestoreServices.fetchUsername();
                      if (username == null) {
                        Fluttertoast.showToast(
                          msg: AppLocalizations.of(context)!.userNotFound,
                          toastLength: Toast.LENGTH_LONG,
                          gravity: ToastGravity.BOTTOM,
                          backgroundColor: errorColor,
                          textColor: secondaryColor,
                          fontSize: 16.0,
                        );
                        return;
                      }

                      await _jumpscareServices.addJumpscare(
                        widget.movieId,
                        descriptionController.text,
                        newTimestamp,
                      );

                      await _fetchJumpscares();

                      Fluttertoast.showToast(
                        msg: '${AppLocalizations.of(context)!.jumpscareAddedByUser} $username',
                        toastLength: Toast.LENGTH_LONG,
                        gravity: ToastGravity.BOTTOM,
                        backgroundColor: Colors.green,
                        textColor: secondaryColor,
                        fontSize: 16.0,
                      );
                      if (context.mounted) {
                        Navigator.of(context).pop();
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: errorColor,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      AppLocalizations.of(context)!.addd,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    },
  );
}

  @override
Widget build(BuildContext context) {
  final String remainingTime = _getRemainingTimeText();
  final Color remainingTimeColor = _getRemainingTimeColor();
  final String elapsedTime = _formatTime(_elapsedSeconds);

  return GestureDetector(
    onTap: () {
      if (_isPlaying) {
        setState(() {
          _isScreenBlack = false; 
        });
        _resetInactivityTimer();
      }
    },
    onPanDown: (_) {
      if (_isPlaying) {
        setState(() {
          _isScreenBlack = false;
        });
        _resetInactivityTimer();
      }
    },
    child: Scaffold(
      backgroundColor: _isScreenBlack ? Colors.black : null,
      appBar: _isScreenBlack
          ? null
          : AppBar(
              title: Text('${widget.mode} Mode'),
              backgroundColor: primaryColor,
              actions: [
                if (widget.mode == "Fearful")
                  Row(
                    children: [
                      Text(
                        _showSpoilers && widget.mode == "Fearful" 
                          ? AppLocalizations.of(context)!.hideSpoilers 
                          : AppLocalizations.of(context)!.showSpoilers,
                        style: TextStyle(color: Colors.white, fontSize: 16), 
                      ),
                      IconButton(
                        icon: Icon(
                          _showSpoilers && widget.mode == "Fearful" ? Icons.visibility : Icons.visibility_off,
                          color: Colors.white,
                        ),
                        onPressed: () {
                          setState(() {
                            _showSpoilers = !_showSpoilers;
                          });
                        },
                      ),
                    ],
                  ),
              ],
            ),
      body: _isScreenBlack
          ? Container() 
          : isLoading
              ? const Center(
                  child: CircularProgressIndicator(
                    color: errorColor,
                  ),
                )
              : SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Center(
                          child: Container(
                            height: 180,
                            width: 120,
                            decoration: BoxDecoration(
                              image: DecorationImage(
                                image: NetworkImage(
                                    'https://image.tmdb.org/t/p/w200${widget.posterPath}'),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            IconButton(
                              icon: Icon(Icons.replay_10, size: 32, color: Colors.white),
                              onPressed: () {
                                _updateElapsedSeconds(
                                    (_elapsedSeconds - 10).clamp(0, widget.movieLength));
                              },
                            ),
                            const SizedBox(width: 20),
                            IconButton(
                              icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow,
                                  size: 64, color: errorColor),
                              onPressed: () {
                                setState(() {
                                  if (_isPlaying) {
                                    _stopTimer();
                                  } else {
                                    _startTimer();
                                    _resetInactivityTimer();
                                  }
                                  _isPlaying = !_isPlaying;
                                });
                              },
                            ),
                            const SizedBox(width: 20),
                            IconButton(
                              icon: Icon(Icons.forward_10, size: 32, color: Colors.white),
                              onPressed: () {
                                setState(() {
                                  _elapsedSeconds =
                                      (_elapsedSeconds + 10).clamp(0, widget.movieLength);
                                });
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                      if (widget.mode == 'Fearful') ...[
                        Text(
                          AppLocalizations.of(context)!.nextJumpscare,
                          style: TextStyle(color: Colors.white70, fontSize: 16),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          remainingTime,
                          style: TextStyle(
                              color: remainingTimeColor,
                              fontSize: 24,
                              fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 40),
                        ElevatedButton.icon(
                          onPressed: _showAddJumpscareDialog,
                          icon: Icon(Icons.add, color: errorColor),
                          label: Text(
                            AppLocalizations.of(context)!.addJumpscare,
                            style: TextStyle(color: Colors.white, fontSize: 16),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.black,
                            side: BorderSide(color: errorColor),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                        const SizedBox(height: 40),
                      ],
                        Column(
                          children: [
                            Text(
                              '$elapsedTime / ${_formatTime(widget.movieLength)}',
                              style: TextStyle(color: Colors.white70, fontSize: 14),
                            ),
                            Stack(
                              children: [
                                SliderTheme(
                                  data: SliderTheme.of(context).copyWith(
                                    activeTrackColor: Colors.white,
                                    inactiveTrackColor: Colors.grey,
                                    thumbColor: errorColor,
                                    overlayColor: errorColor.withOpacity(0.2),
                                    thumbShape: const RoundSliderThumbShape(
                                        enabledThumbRadius: 8.0),
                                    overlayShape: const RoundSliderOverlayShape(
                                        overlayRadius: 16.0),
                                  ),
                                  child: Slider(
                                    value: _elapsedSeconds.toDouble(),
                                    min: 0,
                                    max: widget.movieLength.toDouble(),
                                    onChanged: (value) {
                                      _updateElapsedSeconds(value.toInt());
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        if (widget.mode == 'Fearful') ...[
                        ListView.builder(
                          shrinkWrap: true, 
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _jumpscares.length,
                          itemBuilder: (context, index) {
                            final jumpscare = _jumpscares[index];
                            final timestamp = jumpscare['timestamp'];
                            final description = jumpscare['description'];
                            final score = jumpscare['score'] ?? 1;
                            final userId = jumpscare['userId'];

                            return FutureBuilder<Map<String, String?>?>(
                              future: _firestoreServices.fetchUsernameById(userId),
                              builder: (context, snapshot) {
                                final userData = snapshot.data;
                                final username = userData?['username'] ?? 'Unknown';
                                final pfp = userData?['pfp'] ?? 'img/default-pfp.jpg';

                                return Card(
                                  color: Colors.black,
                                  margin: const EdgeInsets.symmetric(
                                      vertical: 8.0, horizontal: 16.0),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(50.0),
                                    side: BorderSide(color: errorColor, width: 1.0),
                                  ),
                                  child: InkWell(
                                    onTap: () {
                                      final int jumpToSeconds = _parseTime(timestamp);
                                      _updateElapsedSeconds(jumpToSeconds);
                                    },
                                    child: Padding(
                                      padding: const EdgeInsets.all(16.0),
                                      child: Column(
                                        children: [
                                          Text(
                                            timestamp,
                                            style: const TextStyle(
                                              color: errorColor,
                                              fontSize: 30,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            _showSpoilers
                                                ? description ?? AppLocalizations.of(context)!.noDescription
                                                : AppLocalizations.of(context)!.descriptionHidden,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 14,
                                            ),
                                          ),
                                          const SizedBox(height: 16),
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Row(
                                                children: [
                                                  IconButton(
                                                    icon: const Icon(Icons.thumb_up, color: Colors.green, size: 20),
                                                    onPressed: () => _updateJumpscareScore(index, 1),
                                                  ),
                                                  Text(
                                                    '$score',
                                                    style: const TextStyle(color: Colors.white, fontSize: 14),
                                                  ),
                                                  IconButton(
                                                    icon: const Icon(Icons.thumb_down, color: Colors.red, size: 20),
                                                    onPressed: () => _updateJumpscareScore(index, -1),
                                                  ),
                                                ],
                                              ),
                                              Text(
                                                '${AppLocalizations.of(context)!.addedBy} $username',
                                                style: const TextStyle(color: Colors.white, fontSize: 14),
                                              ),
                                              const SizedBox(width: 10),
                                              _firestoreServices.buildProfilePicture(pfp, 10),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                        ],
                      ],
                    ),
                  ),
                ),
    ));
}

}
