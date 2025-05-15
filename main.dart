import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() {
  runApp(CarRecognizerApp());
}

class CarRecognizerApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Auto-Erkennung',
      home: HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  File? _image;
  String _result = '';
  bool _loading = false;

  final picker = ImagePicker();

  Future<void> _getImage(ImageSource source) async {
    final pickedFile = await picker.pickImage(source: source);

    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
        _result = '';
      });
      _uploadImage(_image!);
    }
  }

  Future<void> _uploadImage(File image) async {
    setState(() {
      _loading = true;
    });

    final uri = Uri.parse('https://DEIN-BACKEND-URL/predict'); // Ändere das!

    var request = http.MultipartRequest('POST', uri);
    request.files.add(await http.MultipartFile.fromPath('file', image.path));

    try {
      final response = await request.send();
      final resBody = await response.stream.bytesToString();
      final decoded = json.decode(resBody);

      setState(() {
        _result = decoded['prediction'] ?? 'Keine Vorhersage erhalten';
      });
    } catch (e) {
      setState(() {
        _result = 'Fehler beim Hochladen: $e';
      });
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Auto-Erkennung'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            if (_image != null) Image.file(_image!, height: 200),
            SizedBox(height: 16),
            if (_loading)
              CircularProgressIndicator()
            else
              Column(
                children: [
                  ElevatedButton.icon(
                    icon: Icon(Icons.camera_alt),
                    label: Text('Foto aufnehmen'),
                    onPressed: () => _getImage(ImageSource.camera),
                  ),
                  ElevatedButton.icon(
                    icon: Icon(Icons.photo),
                    label: Text('Aus Galerie wählen'),
                    onPressed: () => _getImage(ImageSource.gallery),
                  ),
                ],
              ),
            SizedBox(height: 24),
            Text(
              _result,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
