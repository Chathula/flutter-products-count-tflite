import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:tflite_v2/tflite_v2.dart';

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

  @override
  void initState() {
    print('init state');
    super.initState();
    initTFLite();
  }

  initTFLite() async {
    print('init tflite');

    await Tflite.loadModel(
        model: "assets/model2/model2.tflite",
        labels: "assets/model2/labelmap.txt",
        numThreads: 1, // defaults to 1
        isAsset:
            true, // defaults to true, set to false to load resources outside assets
        useGpuDelegate:
            false // defaults to false, set to true to use GPU delegate
        );
  }

  void pickImage() async {
    final pickedFile =
        await ImagePicker().pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _image = pickedFile;
      });
      detectProducts(pickedFile);
    }
  }

  void detectProducts(XFile? file) async {
    if (file != null) {
      var recognitions = await Tflite.detectObjectOnImage(
          path: File(file.path).path, // required
          model: "SSDMobileNet",
          imageMean: 127.5,
          imageStd: 127.5,
          threshold: 0.4, // defaults to 0.1
          numResultsPerClass: 100, // defaults to 5
          asynch: true);

      print(recognitions);

      if (recognitions != null) {
        setState(() {
          _item = '';
          _itemsCount = 0;
        });

        recognitions.forEach((element) {
          setState(() {
            if (element['confidenceInClass'] > 0.50) {
              _item = element['detectedClass'];
              _itemsCount++;
            }
          });
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
                      Image.file(File(_image!.path)),
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
