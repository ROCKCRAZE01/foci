import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'background_image.dart';
import 'package:video_player/video_player.dart';

class CollectionsScreen extends StatefulWidget {
  final List<BackgroundImage> backgroundImages;
  final Function(BackgroundImage) onSelect;

  CollectionsScreen({
    required this.backgroundImages,
    required this.onSelect,
  });

  @override
  _CollectionsScreenState createState() => _CollectionsScreenState();
}

class _CollectionsScreenState extends State<CollectionsScreen> {
  List<BackgroundImage> purchasedImages = [];
  List<VideoPlayerController?> videoControllers = [];

  @override
  void initState() {
    super.initState();
    _loadPurchasedImages();
  }

  @override
  void dispose() {
    // Dispose all video controllers
    for (var controller in videoControllers) {
      controller?.dispose();
    }
    super.dispose();
  }

  void _loadPurchasedImages() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> imagePaths = prefs.getStringList('purchasedImages') ?? [];
    setState(() {
      purchasedImages = imagePaths
          .map((path) => widget.backgroundImages.firstWhere((image) => image.imagePath == path))
          .toList();
      // Initialize videoControllers list with null values
      videoControllers = List<VideoPlayerController?>.filled(purchasedImages.length, null);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text(
          "Collections",
          style: TextStyle(color: Colors.white),
        ),
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: GridView.builder(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.8,
        ),
        itemCount: purchasedImages.length,
        padding: EdgeInsets.all(8.0),
        itemBuilder: (context, index) {
          final image = purchasedImages[index];

          // Initialize VideoPlayerController for videos if not already initialized
          if (image.isVideo && videoControllers[index] == null) {
            videoControllers[index] = VideoPlayerController.asset(image.imagePath)
              ..initialize().then((_) {
                // Ensure the first frame is shown after the video is initialized
                setState(() {});
              });
          }

          return Card(
            color: Colors.grey[900],
            child: InkWell(
              onTap: () {
                widget.onSelect(image);
                Navigator.pop(context);
                // Return the selected image
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
                  SizedBox(height: 8),
                  Text(
                    image.name,
                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
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
