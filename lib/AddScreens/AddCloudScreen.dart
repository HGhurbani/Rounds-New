import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:rounds/Status/DoctorID.dart';
import 'package:rounds/colors.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:rounds/component.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'dart:io';

class AddCloudScreen extends StatefulWidget {
  final String? docId;
  final String fileTitle;
  final String fileUrl;

  AddCloudScreen({this.docId, required this.fileTitle, required this.fileUrl});

  @override
  _AddCloudScreen createState() => _AddCloudScreen();
}

class _AddCloudScreen extends State<AddCloudScreen> {
  final titleController = TextEditingController();
  bool error = false;
  late stt.SpeechToText _speech;
  bool _isListening = false;
  String _text = '';
  double _confidence = 1.0;
  bool isLoading = false;
  List<File> selectedFiles = [];

  @override
  void initState() {
    super.initState();
    titleController.text = widget.fileTitle ?? '';
    _speech = stt.SpeechToText();
  }

  Future<void> _listen() async {
    if (!_isListening) {
      bool available = await _speech.initialize(
        onStatus: (val) {
          if (val == 'done' || val == 'notListening') {
            setState(() => _isListening = false);
          }
        },
        onError: (val) {
          setState(() => _isListening = false);
        },
      );

      if (available) {
        setState(() => _isListening = true);

        String originalText = titleController.text;
        String newText = "";

        _speech.listen(
          onResult: (val) {
            String detectedWords = val.recognizedWords.trim();
            if (detectedWords.isNotEmpty && newText != detectedWords) {
              newText = detectedWords;
              titleController.text =
                  originalText + (newText.isEmpty ? "" : " " + newText);
            }
            if (val.hasConfidenceRating && val.confidence > 0) {
              _confidence = val.confidence;
            }
          },
          partialResults: true,
        );
      }
    } else {
      setState(() => _isListening = false);
      _speech.stop();
    }
  }

  Future<void> getFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.any,
      allowMultiple: true,
    );
    setState(() {
      selectedFiles = result?.paths.map((path) => File(path!)).toList() ?? [];
    });
  }

  void _showMessage(BuildContext context, String message,
      {bool isError = false}) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(isError ? "Error" : "Success"),
          content: Text(message),
          actions: [
            TextButton(
              child: Text("OK", style: TextStyle(color: teal)),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> uploadFiles(BuildContext context, String title) async {
    if (title.isEmpty) {
      _showMessage(context, "Please enter a title.", isError: true);
      return;
    }

    setState(() => isLoading = true);

    try {
      FirebaseFirestore firestore = FirebaseFirestore.instance;
      String currentUserId = await DoctorID().readID();
      DocumentSnapshot userSnapshot =
          await firestore.collection('doctors').doc(currentUserId).get();

      if (userSnapshot.exists) {
        Map<String, dynamic> data = userSnapshot.data() as Map<String, dynamic>;
        String shareId = data['share_id'] ?? '';

        if (shareId.isNotEmpty) {
          List<String> fileUrls = [];

          for (var file in selectedFiles) {
            String fileName =
                '${DateTime.now().millisecondsSinceEpoch}_${file.path.split('/').last}';
            firebase_storage.Reference ref = firebase_storage
                .FirebaseStorage.instance
                .ref()
                .child('cloud_files')
                .child(fileName);

            await ref.putFile(file);
            String fileUrl = await ref.getDownloadURL();
            fileUrls.add(fileUrl);
          }

          DocumentReference docRef = await firestore.collection('clouds').add({
            "file_title": title,
            "file_urls": fileUrls,
            "doctor_id": currentUserId,
            "share_id": shareId,
            "timestamp": FieldValue.serverTimestamp(),
          });

          String cloudId = docRef.id;
          await docRef.update({"cloudId": cloudId});

          Navigator.pop(context, "Cloud uploaded successfully");
        } else {
          _showMessage(context, "Share ID is empty", isError: true);
        }
      } else {
        _showMessage(context, "User data not found", isError: true);
      }
    } catch (e) {
      _showMessage(context, "Failed to upload cloud", isError: true);
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> editCloud(BuildContext context, String title) async {
    try {
      FirebaseFirestore firestore = FirebaseFirestore.instance;
      await firestore.collection('clouds').doc(widget.docId).update({
        "file_title": title,
      });

      Navigator.pop(context, "Cloud edited successfully");
    } catch (e) {
      _showMessage(context, "Failed to edit cloud", isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    double height = MediaQuery.of(context).size.height;

    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.docId == null ? 'Add Cloud' : 'Edit Cloud'),
          backgroundColor: teal,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              children: <Widget>[
                SizedBox(height: 100),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      width: width * 0.7,
                      child: defaultTextFormField(
                        controller: titleController,
                        hintText: "Cloud Title",
                      ),
                    ),
                    CircleAvatar(
                      radius: (width - (width * 0.8)) / 4,
                      backgroundColor: teal,
                      child: IconButton(
                        icon: Icon(
                            _isListening ? Icons.pause : Icons.mic_rounded),
                        onPressed: _listen,
                        color: white,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: height * 0.02),
                TextButton.icon(
                  onPressed: getFile,
                  icon: Icon(Icons.upload_file, color: Colors.deepOrange),
                  label:
                      Text("Upload any files", style: TextStyle(color: teal)),
                ),
                SizedBox(height: height * 0.02),
                Expanded(
                  child: ListView.builder(
                    itemCount: selectedFiles.length,
                    itemBuilder: (context, index) {
                      return ListTile(
                        leading: Icon(Icons.insert_drive_file, color: teal),
                        title: Text(selectedFiles[index].path.split('/').last),
                        trailing: IconButton(
                          icon: Icon(Icons.delete, color: Colors.red),
                          onPressed: () {
                            setState(() {
                              selectedFiles.removeAt(index);
                            });
                          },
                        ),
                      );
                    },
                  ),
                ),
                myButton(
                  width: width,
                  text: widget.docId == null ? "Add Cloud" : "Edit Cloud",
                  onPressed: () async {
                    widget.docId == null
                        ? uploadFiles(context, titleController.text)
                        : editCloud(context, titleController.text);
                  },
                ),
                if (isLoading)
                  Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(teal),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
