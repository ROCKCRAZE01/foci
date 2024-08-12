import 'package:flutter/material.dart';
import 'background_image.dart';
import 'package:video_player/video_player.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ItemShopScreen extends StatefulWidget {
  final int tokens;
  final Function(BackgroundImage) onPurchase;
  final Function() onInsufficientBalance;
  final List<BackgroundImage> backgroundImages;

  ItemShopScreen({
    required this.tokens,
    required this.onPurchase,
    required this.onInsufficientBalance,
    required this.backgroundImages,
  });

  @override
  _ItemShopScreenState createState() => _ItemShopScreenState();
}

class _ItemShopScreenState extends State<ItemShopScreen> {
  List<BackgroundImage> purchasedImages = [];
  List<VideoPlayerController?> videoControllers = [];

  @override
  void initState() {
    super.initState();
    _loadPurchasedImages();
    _initializeVideoControllers();
  }

  @override
  void dispose() {
    // Dispose all video controllers
    for (var controller in videoControllers) {
      controller?.dispose();
    }
    super.dispose();
  }

  void _initializeVideoControllers() {
    videoControllers = List<VideoPlayerController?>.filled(widget.backgroundImages.length, null);
    for (int i = 0; i < widget.backgroundImages.length; i++) {
      if (widget.backgroundImages[i].isVideo) {
        videoControllers[i] = VideoPlayerController.asset(widget.backgroundImages[i].imagePath)
          ..initialize().then((_) {
            setState(() {});
          }).catchError((error) {
            print('Error initializing video: ${widget.backgroundImages[i].imagePath}, Error: $error');
          });
      }
    }
  }

  void _loadPurchasedImages() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> imagePaths = prefs.getStringList('purchasedImages') ?? [];
    setState(() {
      purchasedImages = imagePaths.map((path) {
        return widget.backgroundImages.firstWhere((image) => image.imagePath == path);
      }).toList();
    });
  }

  void _savePurchasedImages() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> imagePaths = purchasedImages.map((image) => image.imagePath).toList();
    await prefs.setStringList('purchasedImages', imagePaths);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text(
          "Item Shop",
          style: TextStyle(color: Colors.white),
        ),
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: GridView.builder(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.8,
        ),
        itemCount: widget.backgroundImages.length,
        padding: EdgeInsets.all(8.0),
        itemBuilder: (context, index) {
          final image = widget.backgroundImages[index];
          final isPurchased = purchasedImages.contains(image);

          // Initialize VideoPlayerController for videos if not already initialized
          if (image.isVideo && videoControllers[index] == null) {
            videoControllers[index] = VideoPlayerController.asset(image.imagePath)
              ..initialize().then((_) {
                // Ensure the first frame is shown after the video is initialized
                setState(() {});
              }).catchError((error) {
                print('Error initializing video: ${image.imagePath}, Error: $error');
              });
          }

          return Card(
            color: Colors.grey[900],
            child: InkWell(
              onTap: () {
                if (widget.tokens >= image.price) {
                  if (isPurchased) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Item already purchased')),
                    );
                  } else {
                    widget.onPurchase(image);
                    setState(() {
                      purchasedImages.add(image);
                    });
                    _savePurchasedImages();
                    Navigator.pop(context); // Close the item shop after purchase
                  }
                } else {
                  widget.onInsufficientBalance();
                }
              },
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (image.isVideo && videoControllers[index] != null)
                    SizedBox(
                      height: 100,
                      width: double.infinity,
                      child: AspectRatio(
                        aspectRatio: videoControllers[index]!.value.aspectRatio,
                        child: VideoPlayer(videoControllers[index]!),
                      ),
                    ),
                  if (!image.isVideo)
                    Image.asset(
                      image.imagePath,
                      height: 100,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  SizedBox(height: 20),
                  Text(
                    image.name,
                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  Text(
                    "Price: ${image.price} tokens",
                    style: TextStyle(color: Colors.white),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
