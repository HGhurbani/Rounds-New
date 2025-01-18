import 'package:connectivity/connectivity.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:rounds/Screens/ReadyOrderScreen.dart';
import 'package:rounds/Screens/HomeScreen.dart';
import 'package:rounds/colors.dart';
import 'package:rounds/component.dart';
import 'package:rounds/Status/DoctorID.dart';

class AddReadyOrderScreen extends StatefulWidget {
  final String title;
  final String description;
  final String? orderId;

  AddReadyOrderScreen(this.title, this.description, this.orderId);

  @override
  _AddReadyOrderScreen createState() => _AddReadyOrderScreen();
}

class _AddReadyOrderScreen extends State<AddReadyOrderScreen> {
  final titleController = TextEditingController();
  final textController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool isUploading = false;
  late stt.SpeechToText _speech;
  bool isListeningTitle = false;
  bool isListeningDesc = false;

  @override
  void initState() {
    super.initState();
    titleController.text = widget.title;
    textController.text = widget.description;
    _speech = stt.SpeechToText();
    _speech.statusListener = (status) {
      if (status == 'done' || status == 'notListening') {
        setState(() {
          isListeningTitle = false;
          isListeningDesc = false;
        });
      }
    };
  }

  Future<void> showDialogMessage(BuildContext context, String title,
      String message, VoidCallback? onPressed) async {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15.0),
          ),
          title: Text(title, style: TextStyle(color: teal)),
          content: SingleChildScrollView(
            child: ListBody(children: [Text(message)]),
          ),
          actions: [
            TextButton(
              child: Text('OK', style: TextStyle(color: teal)),
              onPressed: onPressed,
            ),
          ],
        );
      },
    );
  }

  Future<void> uploadOrder(
      BuildContext context, String title, String description) async {
    if (title.isEmpty || description.isEmpty) return;

    try {
      String doctorId = await DoctorID().readID();
      String shareId = await _getDoctorShareId(doctorId);

      DocumentReference orderRef = await _firestore.collection('orders').add({
        'order_title': title,
        'order_text': description,
        'doctor_id': doctorId,
        'share_id': shareId,
        'timestamp': FieldValue.serverTimestamp(),
      });

      String orderId = orderRef.id;
      await orderRef.update({'orderId': orderId});

      await showDialogMessage(
          context, 'Success', 'Order has been uploaded successfully!', () {
        Navigator.pushReplacement(context,
            MaterialPageRoute(builder: (context) => ReadyOrderScreen()));
      });
    } catch (e) {
      print("Exception caught: $e");
      showDialogMessage(context, 'Error', 'Something went wrong.', null);
    }
  }

  Future<void> editOrder(
      BuildContext context, String title, String description) async {
    try {
      await _firestore.collection('orders').doc(widget.orderId).update({
        'order_title': title,
        'order_text': description,
      });

      await showDialogMessage(
          context, 'Success', 'Order has been updated successfully!', () {
        Navigator.pushReplacement(context,
            MaterialPageRoute(builder: (context) => ReadyOrderScreen()));
      });
    } catch (e) {
      print("Exception caught: $e");
      showDialogMessage(context, 'Error', 'Something went wrong.', null);
    }
  }

  Future<String> _getDoctorShareId(String doctorId) async {
    DocumentSnapshot doctorSnapshot =
        await _firestore.collection('doctors').doc(doctorId).get();
    if (doctorSnapshot.exists) {
      return (doctorSnapshot.data() as Map<String, dynamic>)['share_id'] ?? '';
    } else {
      throw Exception('Doctor document not found');
    }
  }

  Future<bool> checkInternetConnection() async {
    var connectivityResult = await (Connectivity().checkConnectivity());
    return connectivityResult == ConnectivityResult.mobile ||
        connectivityResult == ConnectivityResult.wifi;
  }

  Future<void> _listenSpeech(
      TextEditingController controller, bool isTitle) async {
    bool available = await _speech.initialize();
    if (available) {
      setState(() {
        if (isTitle)
          isListeningTitle = true;
        else
          isListeningDesc = true;
      });
      _speech.listen(onResult: (result) {
        setState(() {
          controller.text = result.recognizedWords;
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.orderId == null
            ? 'Add selected procedure orders'
            : 'Edit selected procedure orders'),
        elevation: 0,
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Container(
                  width: width * 0.75,
                  child: defaultTextFormField(
                      controller: titleController, hintText: 'Procedure name'),
                ),
                CircleAvatar(
                  radius: (width - (width * 0.8)) / 4,
                  backgroundColor:
                      isListeningTitle ? Colors.deepOrangeAccent : teal,
                  child: IconButton(
                    icon: Icon(
                        isListeningTitle
                            ? Icons.pause
                            : Icons.mic_none_outlined,
                        color: white),
                    onPressed: () {
                      _listenSpeech(titleController, true);
                    },
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Container(
                  width: width * 0.75,
                  child: defaultTextFormField(
                      controller: textController,
                      hintText: 'Orders',
                      typingType: TextInputType.multiline),
                ),
                CircleAvatar(
                  radius: (width - (width * 0.8)) / 4,
                  backgroundColor:
                      isListeningDesc ? Colors.deepOrangeAccent : teal,
                  child: IconButton(
                    icon: Icon(
                        isListeningDesc ? Icons.pause : Icons.mic_none_outlined,
                        color: white),
                    onPressed: () {
                      _listenSpeech(textController, false);
                    },
                  ),
                ),
              ],
            ),
          ),
          myButton(
            width: width,
            onPressed: () async {
              bool internet = await checkInternetConnection();
              if (internet) {
                setState(() {
                  isUploading = true;
                });
                widget.orderId == null
                    ? uploadOrder(
                        context, titleController.text, textController.text)
                    : editOrder(
                        context, titleController.text, textController.text);
              } else {
                showDialogMessage(context, 'Connection Error',
                    'Please check your internet connection.', null);
              }
            },
            text: isUploading
                ? 'Uploading'
                : (widget.orderId == null ? 'Add' : 'Update'),
          ),
        ],
      ),
    );
  }
}
