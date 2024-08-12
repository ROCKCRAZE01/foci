import 'package:flutter/material.dart';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:audioplayers/audioplayers.dart';
import 'background_image.dart';
import 'shop.dart';
import 'collections.dart';
import 'data.dart';
import 'package:video_player/video_player.dart';
import 'package:flutter/services.dart';

class TimerApp extends StatefulWidget {
  const TimerApp({Key? key}) : super(key: key);

  @override
  _TimerAppState createState() => _TimerAppState();
}

class _TimerAppState extends State<TimerApp> with TickerProviderStateMixin {
  static int maxSeconds = 300; // Default timer duration
  int secondsRemaining = maxSeconds;
  late Timer _timer;
  late AnimationController _controller;
  late Animation<double> _animation;
  bool isRunning = false;
  bool wasAnimating = false;
  bool audioRunning = false;
  final TextEditingController _quoteController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  String userQuote = '';
  int tokens = 0;
  int tokens_gained = 0;
  static int inputtedtime = -1;
  late FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;
  late AudioPlayer _audioPlayer;
  BackgroundImage? _currentBackgroundImage = BackgroundImage(
      name: "Pomodoro Sea",
      imagePath: "assets/pomodoro sea.jpeg",
      price: 0,
      isVideo: false
  );
  VideoPlayerController? _controllerVideo;
  Future<void>? _initializeVideoPlayerFuture;
  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: Duration(seconds: secondsRemaining),
    );

    _animation = Tween(begin: 1.0, end: 0.0).animate(_controller)
      ..addListener(() {
        setState(() {});
      });

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.dismissed) {
        setState(() {
          wasAnimating = false;
          _controller.reset();
        });
      }
    });

    _loadTokens();
    _initializeNotifications();
    _audioPlayer = AudioPlayer();
    _loadCurrentBackground();
  }

  void _initializeNotifications() {
    const AndroidInitializationSettings initializationSettingsAndroid =
    AndroidInitializationSettings('@mipmap/ic_launcher');
    final InitializationSettings initializationSettings =
    InitializationSettings(android: initializationSettingsAndroid);
    flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
    flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }
  Future<void> _loadCurrentBackground() async {
    final prefs = await SharedPreferences.getInstance();
    String? imagePath = prefs.getString('currentBackground');
    if (imagePath != null) {
      setState(() {
        _currentBackgroundImage = backgroundImages.firstWhere(
              (image) => image.imagePath == imagePath,
          orElse: () => BackgroundImage(
            name: "Pomodoro Sea",
            imagePath: "assets/pomodoro sea.jpeg",
            price: 0,
            isVideo: true,
          ),
        );
      });
    } else {
      _currentBackgroundImage = BackgroundImage(
        name: "Pomodoro sea",
        imagePath: "assets/pomodoro sea.jpeg",
        price: 0,
        isVideo: true,
      );
    }
  }

  Future<void> _loadTokens() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      tokens = prefs.getInt('tokens') ?? 0;
    });
  }

  Future<void> _saveTokens() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('tokens', tokens);
  }

  Future<void> _playAudio() async {
    await _audioPlayer.setReleaseMode(ReleaseMode.loop); // Loop the audio
    await _audioPlayer.play(AssetSource('audio.mp3'));
  }

  Future<void> _stopAudio() async {
    await _audioPlayer.stop();
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    _saveCurrentBackground();
    _timer.cancel();
    _controllerVideo?.dispose();
    _controller.dispose();
    _quoteController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void startTimer() {
    if (isRunning) {
      _timer.cancel();
      isRunning = false;
      _controller.stop();
      _stopAudio();
      audioRunning = false;
    } else {
      isRunning = true;
      _playAudio();
      audioRunning = true;// Start playing the audio
      _timer = Timer.periodic(Duration(seconds: 1), (timer) {
        setState(() {
          if (secondsRemaining > 0) {
            secondsRemaining--;
            tokens_gained++;
            _saveTokens();
            _controller.duration = Duration(seconds: secondsRemaining);
            if (!_controller.isAnimating && !wasAnimating) {
              _controller.forward();
            }
          } else {
            timer.cancel();
            resetTimer();
            _showNotification(tokens_gained);
            tokens += tokens_gained;
            tokens_gained = 0;
            _stopAudio();
            audioRunning = false;// Stop the audio when the timer completes
          }
        });
      });
    }
  }

  void resetTimer() {
    setState(() {
      if (inputtedtime == -1){
        secondsRemaining = maxSeconds;}
      else {secondsRemaining = inputtedtime;}
      isRunning = false;
      wasAnimating = false;
      _controller.reset();
      _stopAudio();
      audioRunning = false;// Stop the audio when the timer is reset
    });
  }

  String get timerText {
    final minutes = secondsRemaining ~/ 60;
    final seconds = secondsRemaining % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  Future<void> _selectTime(BuildContext context) async {
    int selectedHours = secondsRemaining ~/ 60;
    int selectedMinutes = secondsRemaining % 60;

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Select Time'),
          content: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Flexible(
                child: TextField(
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(3)],
                  decoration: InputDecoration(
                    labelText: 'Minutes',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) {
                    int? parsedValue = int.tryParse(value);
                    selectedHours =
                    (parsedValue != null && parsedValue >= 0) ? parsedValue : 0;
                  },
                ),
              ),
              SizedBox(width: 10),
              Flexible(
                child: TextField(
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(2)],
                  decoration: InputDecoration(
                    labelText: 'Seconds',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) {
                    int? parsedValue = int.tryParse(value);
                    selectedMinutes =
                    (parsedValue != null && parsedValue >= 0) ? parsedValue : 0;
                  },
                ),
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
                setState(() {
                  secondsRemaining = (selectedHours * 60) + selectedMinutes;
                  inputtedtime = secondsRemaining;
                  _controller.duration = Duration(seconds: secondsRemaining);
                  if (isRunning) {
                    _controller.forward(from: 0.0);
                  }
                });
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _showNotification(int tokensEarned) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
    AndroidNotificationDetails(
      'timer_channel_id',
      'Timer Completed',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: false,
    );
    const NotificationDetails platformChannelSpecifics =
    NotificationDetails(android: androidPlatformChannelSpecifics);
    await flutterLocalNotificationsPlugin.show(
      0,
      'Timer Completed',
      'Congratulations! You have earned $tokensEarned tokens.',
      platformChannelSpecifics,
      payload: 'item x',
    );
  }
  // Function to apply the background image
  void _applyBackgroundImage(BackgroundImage image) {
    setState(() {
      _currentBackgroundImage = image;
      _saveCurrentBackground(); // Save selected background
      if (image.isVideo) {
        _controllerVideo?.dispose();
        _controllerVideo = VideoPlayerController.asset(image.imagePath);
        _initializeVideoPlayerFuture = _controllerVideo!.initialize().then((_) {
          setState(() {
            _controllerVideo!.play();
          });
        });
      } else {
        _controllerVideo?.dispose();
        _controllerVideo = null;
      }
    });
  }

  Future<void> _saveCurrentBackground() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('currentBackground', _currentBackgroundImage!.imagePath);
  }

// Function to save purchased images (using SharedPreferences for simplicity)
  void _savePurchasedImage(BackgroundImage image) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> purchasedImages = prefs.getStringList('purchasedImages') ?? [];
    if (!purchasedImages.contains(image.imagePath)) {
      purchasedImages.add(image.imagePath);
      await prefs.setStringList('purchasedImages', purchasedImages);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: () {
          _focusNode.unfocus();
        },
        child: Container(
          decoration:  BoxDecoration(
            image: _currentBackgroundImage!.isVideo
                ? DecorationImage(
              image: AssetImage(_currentBackgroundImage?.imagePath ?? "assets/pomodoro sea.jpeg"),
              fit: BoxFit.cover,
            )
                : DecorationImage(
              image: AssetImage(_currentBackgroundImage!.imagePath),
              fit: BoxFit.cover,
            ),
          ),
          child: Stack(
            children: [
              if (_currentBackgroundImage!.isVideo)
                VideoWidget(
                  videoPath: _currentBackgroundImage!.imagePath,
                ),
              Positioned(
                top: 50,
                right: 20,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    'Tokens: $tokens',
                    style: TextStyle(color: Colors.white, fontSize: 18),
                  ),
                ),
              ),
              Positioned(
                top: 170,
                left: 20,
                right: 20,
                child: TextField(
                  controller: _quoteController,
                  focusNode: _focusNode,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.6),
                    fontWeight: FontWeight.bold, // Make the text bold
                  ),
                  decoration: InputDecoration(
                    hintText: 'Anything in life worth achieving needs practice.',
                    hintStyle: TextStyle(color: Colors.white.withOpacity(0.6)),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.white.withOpacity(0.0)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.white.withOpacity(0.0)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Colors.transparent),
                    ),
                  ),
                  onChanged: (text) {
                    setState(() {
                      userQuote = text;
                    });
                  },
                ),
              ),
              Align(
                alignment: Alignment.center,
                child: GestureDetector(
                  onTap: () {
                    if (!isRunning) { // Check if the timer is not running
                      _selectTime(context);
                    }
                  },
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 200,
                        height: 200,
                        child: CircularProgressIndicator(
                          value: _animation.value,
                          strokeWidth: 3,
                          backgroundColor: Colors.white.withOpacity(0.1),
                          valueColor:
                          AlwaysStoppedAnimation<Color>(Colors.white.withOpacity(0.5)),
                        ),
                      ),
                      Text(
                        timerText,
                        style: const TextStyle(
                          fontSize: 48,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 200.0),
                  child: SizedBox(
                    width: 200,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white.withOpacity(0.3),
                        shadowColor: Colors.transparent,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () {
                        setState(() {
                          if (isRunning) {
                            _timer.cancel();
                            isRunning = false;
                            _controller.stop();
                            _stopAudio();
                            audioRunning = false;
                          } else {
                            isRunning = true;
                            _playAudio();
                            audioRunning = true;// Start playing the audio
                            _timer = Timer.periodic(Duration(seconds: 1), (timer) {
                              setState(() {
                                if (secondsRemaining > 0) {
                                  secondsRemaining--;
                                  tokens_gained++;
                                  _saveTokens();
                                  _controller.duration = Duration(seconds: secondsRemaining);
                                  if (!_controller.isAnimating && !wasAnimating) {
                                    _controller.forward();
                                  }
                                } else {
                                  timer.cancel();
                                  resetTimer();
                                  _showNotification(tokens_gained);
                                  tokens += tokens_gained;
                                  tokens_gained = 0;
                                  _stopAudio();
                                  audioRunning = false;// Stop the audio when the timer completes
                                }
                              });
                            });
                          }
                        });
                      },
                      child: Text(isRunning ? 'Pause' : 'Play'),
                    ),
                  ),
                ),
              ),
              Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 125.0),
                  child: SizedBox(
                    width: 200,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white.withOpacity(0.3),
                        shadowColor: Colors.transparent,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () {
                        setState(() {
                          if (isRunning) {
                            _timer.cancel();
                            isRunning = false;
                            _controller.stop();
                            resetTimer();
                            tokens_gained = 0;
                            _stopAudio();
                            audioRunning = false;
                          } else {
                            resetTimer();
                            tokens_gained = 0;
                            _stopAudio();
                            audioRunning = false;
                          }
                        });
                      },
                      child: Text('Cancel'),
                    ),
                  ),
                ),
              ),
              Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 50.0),
                  child: SizedBox(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white.withOpacity(0.3),
                        shadowColor: Colors.transparent,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () {
                        setState(() {
                          if (audioRunning) {
                            _stopAudio();
                            audioRunning = false;
                          } else {
                            _playAudio();
                            audioRunning = true;
                          }
                        });
                      },
                      child: Text(audioRunning ? 'Sound Off' : 'Sound On'),
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 45,
                left: 20,
                child: Column(
                  children: [
                    SizedBox(
                      width: 200,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white.withOpacity(0.3),
                          shadowColor: Colors.transparent,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ItemShopScreen(
                                tokens: tokens,
                                onPurchase: (purchasedImage) {
                                  // Handle successful purchase (update background, save to collections)
                                  _applyBackgroundImage(purchasedImage);
                                  _savePurchasedImage(purchasedImage);
                                  tokens -= purchasedImage.price;
                                },
                                onInsufficientBalance: () {
                                  // Show insufficient balance message
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text("Insufficient balance")),
                                  );
                                },
                                backgroundImages: backgroundImages,
                              ),
                            ),
                          );
                        },
                        child: Text("Item Shop"),
                      ),
                    ),
                    SizedBox(height: 10),
                    SizedBox(
                      width: 200,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white.withOpacity(0.3),
                          shadowColor: Colors.transparent,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => CollectionsScreen(
                              backgroundImages: backgroundImages,
                              onSelect: (image) {
                                _applyBackgroundImage(image);
                              },
                            ),
                            ),
                          );
                        },
                        child: Text("Collections"),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
class VideoWidget extends StatefulWidget {
  final String videoPath;

  const VideoWidget({Key? key, required this.videoPath}) : super(key: key);

  @override
  _VideoWidgetState createState() => _VideoWidgetState();
}

class _VideoWidgetState extends State<VideoWidget> {
  VideoPlayerController? _controller;
  Future<void>? _initializeVideoPlayerFuture;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  void _initializeVideo() {
    _controller?.dispose(); // Dispose of the previous controller, if any

    _controller = VideoPlayerController.asset(widget.videoPath)
      ..addListener(() {
        setState(() {}); // Update the UI when the video player state changes
      })
      ..setLooping(true);

    _initializeVideoPlayerFuture = _controller!.initialize().then((_) {
      _controller!.play();
    }).catchError((error) {
      print('Error initializing video player: $error');
    });
  }

  @override
  void didUpdateWidget(VideoWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.videoPath != widget.videoPath) {
      _initializeVideo(); // Re-initialize video player with the new video path
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _controller != null
        ? FutureBuilder(
      future: _initializeVideoPlayerFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          return SizedBox.expand(
            child: FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(
                width: _controller!.value.size.width,
                height: _controller!.value.size.height,
                child: AspectRatio(
                  aspectRatio: _controller!.value.aspectRatio,
                  child: VideoPlayer(_controller!),
                ),
              ),
            ),
          );
        } else {
          return Center(
            child: CircularProgressIndicator(
              color: Colors.white,
            ),
          );
        }
      },
    )
        : Center(
      child: CircularProgressIndicator(
        color: Colors.cyan,
      ),
    );
  }
}
