import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import 'package:pytorch_mobile/pytorch_mobile.dart';
import 'package:pytorch_mobile/model.dart';

const List<String> list = <String>[
  'No Model',
  'International Model',
  'Local Model'
];

void main() => runApp(const MyApp());

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String _dropdownValue = list.first;
  Model? _imageModelIntl;
  Model? _imageModelGr;

  String? _imagePrediction;
  List? _prediction;
  Image? _image;
  bool _loading = false;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    loadModels();
  }

  Future clearImage() async {
    setState(() {
      _image = null;
      _imagePrediction = null;
    });
  }

  //load your model
  Future loadModels() async {
    String pathImageModelIntl = "assets/models/model_mobile_intl.pt";
    String pathImageModelGr = "assets/models/model_mobile_gr.pt";
    try {
      _imageModelIntl = await PyTorchMobile.loadModel(pathImageModelIntl);
      _imageModelGr = await PyTorchMobile.loadModel(pathImageModelGr);
    } on PlatformException {
      if (kDebugMode) {
        print("only supported for android and ios so far");
      }
    }
  }

  //run an image model
  Future runImageModel({bool? fromGallery}) async {
    if (_dropdownValue != 'No Model') {
      setState(() {
        _loading = true;
      });
      //pick a random image
      final XFile? imageFile = await _picker.pickImage(
          source:
              fromGallery != null ? ImageSource.gallery : ImageSource.camera,
          maxWidth: 244,
          maxHeight: 244);
      //get prediction
      _imagePrediction = _dropdownValue == 'International Model'
          ? await _imageModelIntl!.getImagePrediction(
              File(imageFile!.path), 224, 224, "assets/labels/labels_intl.csv",
              mean: [0.4638, 0.4725, 0.4687], std: [0.2699, 0.2706, 0.3018])
          : await _imageModelGr!.getImagePrediction(
              File(imageFile!.path), 224, 224, "assets/labels/labels_gr.csv",
              mean: [0.4638, 0.4725, 0.4687], std: [0.2699, 0.2706, 0.3018]);
      _imagePrediction = _imagePrediction?.replaceAll('_', ' ');
      setState(() {
        _image = Image.file(File(imageFile.path));
        _loading = false;
      });
    } else {}
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Spot the Spot'),
          backgroundColor: Colors.blueAccent,
        ),
        backgroundColor: Colors.white,
        body: ListView(
          children: <Widget>[
            Center(
              child: _loading
                  ? const Padding(
                      padding: EdgeInsets.fromLTRB(0, 200, 0, 10),
                      child: CircularProgressIndicator(),
                    )
                  : _image == null
                      ? const Padding(
                          padding: EdgeInsets.fromLTRB(0, 200, 0, 10),
                          child: Text("No image loaded"),
                        )
                      : Padding(
                          padding: const EdgeInsets.fromLTRB(0, 200, 0, 10),
                          child: _image!,
                        ),
            ),
            // _image == null ? const Text('No image selected.') : Image.file(_image!),
            Center(
              child: Visibility(
                visible: _imagePrediction != null,
                child: Text("$_imagePrediction"),
              ),
            ),
            Center(
                child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextButton(
                  onPressed: () => {runImageModel(fromGallery: true)},
                  child: const Icon(
                    Icons.image,
                    color: Colors.grey,
                  ),
                ),
                TextButton(
                  onPressed: () => {runImageModel()},
                  child: const Icon(
                    Icons.add_a_photo,
                    color: Colors.grey,
                  ),
                ),
                TextButton(
                  onPressed: clearImage,
                  child: const Icon(
                    Icons.clear,
                    color: Colors.grey,
                  ),
                ),
              ],
            )),
            Center(
              child: Visibility(
                visible: _prediction != null,
                child: Text(_prediction != null ? "${_prediction![0]}" : ""),
              ),
            ),
            Center(
              child: DropdownButton<String>(
                value: _dropdownValue,
                icon: const Icon(Icons.arrow_downward),
                elevation: 16,
                style: const TextStyle(color: Colors.deepPurple),
                underline: Container(
                  height: 2,
                  color: Colors.deepPurpleAccent,
                ),
                onChanged: (String? value) {
                  // This is called when the user selects an item.
                  setState(() {
                    _dropdownValue = value!;
                    _imagePrediction = null;
                    if (_dropdownValue == 'No Model') {
                      _image = null;
                    }
                    if (_dropdownValue == 'International Model') {
                      _image = Image.asset("assets/images/worldwide.webp");
                    }
                    if (_dropdownValue == 'Local Model') {
                      _image = Image.asset('assets/images/greece.jpg');
                    }
                  });
                },
                items: list.map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
              ),
            )
          ],
        ),
      ),
    );
  }
}
