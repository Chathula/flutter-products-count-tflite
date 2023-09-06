import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_pytorch/pigeon.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_pytorch/flutter_pytorch.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  XFile? _image;
  String? tfModel;
  String _item = '';
  int _itemsCount = 0;
  ModelObjectDetection? _objectModel;
  File? _detectedImage;
  List<ResultObjectDetection?> _objDetect = [];

  @override
  void initState() {
    super.initState();
    loadModal();
  }

  loadModal() async {
    ModelObjectDetection objectModel =
        await FlutterPytorch.loadObjectDetectionModel(
            "assets/yolov5/models/best.torchscript", 1, 640, 640,
            labelPath: "assets/yolov5/labels/labels.txt");
    setState(() {
      _objectModel = objectModel;
    });
  }

  void pickImage() async {
    final pickedFile = await ImagePicker()
        .pickImage(source: ImageSource.gallery, maxWidth: 640, maxHeight: 640);

    if (pickedFile != null) {
      setState(() {
        _image = pickedFile;
      });
      detectProducts(pickedFile);
    }
  }

  void detectProducts(XFile? file) async {
    if (file != null && _objectModel != null) {
      File image = File(file.path);

      List<ResultObjectDetection?> objDetect = await _objectModel!
          .getImagePrediction(await image.readAsBytes(),
              minimumScore: 0.1, IOUThershold: 0.3);

      if (objDetect != null) {
        String itemName = '';

        int objectCount = 0;

        // Define a confidence threshold
        double confidenceThreshold = 0.5;

        objDetect.forEach((element) {
          print({"score": element!.score, "className": element!.className});
        });

        for (var detection in objDetect) {
          if (detection!.score >= confidenceThreshold) {
            if (itemName == '') {
              itemName = detection.className ?? '';
            }
            objectCount++;
          }
        }

        print({"itemName": itemName});
        print({"_itemsCount": objectCount});

        setState(() {
          _item = itemName;
          _itemsCount = objectCount;
          _detectedImage = image;
          _objDetect = objDetect;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            _image != null
                ? Column(
                    children: <Widget>[
                      Container(
                        height: 400,
                        width: 350,
                        child: _objDetect!.isNotEmpty && _detectedImage != null
                            ? _objectModel!
                                .renderBoxesOnImage(_detectedImage!, _objDetect)
                            : const Text("Generating..."),
                      ),
                      Padding(
                        padding: EdgeInsets.only(top: 15),
                        child: Text(
                          _item != ''
                              ? "You have selected $_item and it has count of: $_itemsCount"
                              : 'Detecting...',
                          style: TextStyle(fontSize: 20),
                        ),
                      )
                    ],
                  )
                : const Placeholder(child: Text("No image selected"))
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: pickImage,
        tooltip: 'Pick image',
        child: const Icon(Icons.image),
      ),
    );
  }
}
