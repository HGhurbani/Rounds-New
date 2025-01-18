import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:speech_to_text/speech_to_text.dart'
    as stt; // استيراد مكتبة تحويل الصوت إلى نص
import '../colors.dart';

class MorningMeetingPage extends StatefulWidget {
  @override
  _MorningMeetingPageState createState() => _MorningMeetingPageState();
}

class _MorningMeetingPageState extends State<MorningMeetingPage> {
  late stt.SpeechToText _speech;
  bool _isListening = false;
  String _spokenText = '';

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
  }

  // دالة لبدء التسجيل الصوتي
  void _startListening(TextEditingController controller) async {
    bool available = await _speech.initialize();
    if (available) {
      setState(() {
        _isListening = true;
      });
      _speech.listen(onResult: (result) {
        setState(() {
          _spokenText = result.recognizedWords;
          controller.text = _spokenText;
        });
      });
    }
  }

  // دالة لإيقاف التسجيل الصوتي
  void _stopListening() {
    _speech.stop();
    setState(() {
      _isListening = false;
    });
  }

  // دالة لإظهار الديالوج لإضافة البيانات
  void _showAddDialog(String section) {
    TextEditingController controller = TextEditingController();
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            mainAxisSize: MainAxisSize
                .min, // لتقليل حجم العنوان بحيث يتناسب مع محتوى الدايلوج
            children: [
              Icon(Icons.add_circle, color: teal),
              SizedBox(width: 8),
              Text(
                'Add $section Data',
                style: TextStyle(
                    fontSize: 14), // يمكنك تخصيص حجم الخط هنا بما يناسب
              ),
            ],
          ),
          content: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  decoration:
                      InputDecoration(hintText: 'Enter $section details'),
                ),
              ),
              IconButton(
                icon: Icon(
                  _isListening ? Icons.stop : Icons.mic,
                  color: _isListening ? Colors.deepOrange : Colors.teal,
                ),
                onPressed: () {
                  if (_isListening) {
                    _stopListening();
                  } else {
                    _startListening(controller);
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                setState(() {
                  // رفع البيانات إلى Firebase
                  FirebaseFirestore.instance
                      .collection('morning_meeting')
                      .doc(section)
                      .collection('entries')
                      .add({
                    'data': controller.text,
                    'timestamp': FieldValue.serverTimestamp(),
                  });
                });
                Navigator.of(context).pop();
              },
              child: Text(
                'Add',
                style: TextStyle(color: teal),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(
                'Cancel',
                style: TextStyle(color: Colors.deepOrangeAccent),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showDeleteDialog(String section, String docId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Confirm Deletion'),
          content: Text('Are you sure you want to delete this item?'),
          actions: [
            TextButton(
              onPressed: () {
                // حذف البيانات من Firebase
                FirebaseFirestore.instance
                    .collection('morning_meeting')
                    .doc(section)
                    .collection('entries')
                    .doc(docId)
                    .delete();
                Navigator.of(context).pop();
              },
              child: Text('Delete'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  // دالة لعرض البيانات المدخلة مع ميزة عرض المزيد/عرض أقل
  Widget _buildSection(String section, IconData icon) {
    bool showMore = false; // حالة عرض المزيد
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 1,
        color: Colors.grey[50],
        child: ListTile(
          contentPadding: EdgeInsets.all(16),
          leading: Icon(icon, color: teal),
          title: Text(section,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          subtitle: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('morning_meeting')
                .doc(section)
                .collection('entries')
                .orderBy('timestamp', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return CircularProgressIndicator();
              }

              var items = snapshot.data!.docs
                  .map((doc) => doc['data'] as String)
                  .toList();
              bool hasMoreThan3 = items.length > 2;
              List<Widget> listWidgets =
                  items.take(showMore ? items.length : 2).map((item) {
                var docId = snapshot.data!.docs[items.indexOf(item)].id;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(item, style: TextStyle(color: Colors.black54)),
                      IconButton(
                        icon: Icon(Icons.delete, color: Colors.red),
                        onPressed: () {
                          // إظهار دايلوج تأكيد الحذف
                          _showDeleteDialog(section, docId);
                        },
                      ),
                    ],
                  ),
                );
              }).toList();

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ...listWidgets,
                  if (hasMoreThan3)
                    TextButton(
                      onPressed: () {
                        _showAllDataDialog(section);
                      },
                      child: Text(
                        'View All Data',
                        style: TextStyle(color: teal),
                      ),
                    ),
                ],
              );
            },
          ),
          trailing: IconButton(
            icon: Icon(Icons.add, color: Colors.deepOrange),
            onPressed: () => _showAddDialog(section),
          ),
        ),
      ),
    );
  }

  // دالة لإظهار دايلوج عرض كل البيانات
  void _showAllDataDialog(String section) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('All $section Data'),
          content: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('morning_meeting')
                .doc(section)
                .collection('entries')
                .orderBy('timestamp', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return CircularProgressIndicator();
              }

              var items = snapshot.data!.docs
                  .map((doc) => doc['data'] as String)
                  .toList();
              return SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: items.map((item) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                      child:
                          Text(item, style: TextStyle(color: Colors.black54)),
                    );
                  }).toList(),
                ),
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(
                'Close',
                style: TextStyle(color: Colors.deepOrangeAccent),
              ),
            ),
            TextButton(
              onPressed: () {
                _shareData(section);
              },
              child: Text(
                'Share',
                style: TextStyle(color: teal),
              ),
            ),
          ],
        );
      },
    );
  }

  // دالة لمشاركة البيانات
  void _shareData(String section) {
    FirebaseFirestore.instance
        .collection('morning_meeting')
        .doc(section)
        .collection('entries')
        .get()
        .then((snapshot) {
      List<String> data =
          snapshot.docs.map((doc) => doc['data'] as String).toList();
      String sharedText = 'All data from $section:\n\n${data.join("\n")}\n';

      // مشاركة البيانات عبر التطبيقات المتاحة
      Share.share(sharedText);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Morning Meeting'),
        backgroundColor: teal,
      ),
      body: ListView(
        padding: EdgeInsets.all(16),
        children: [
          _buildSection('Admission', Icons.access_alarm),
          _buildSection('ER Consultations', Icons.healing),
          _buildSection('Word Consultations', Icons.assignment_ind),
          _buildSection('Incidents', Icons.report),
          _buildSection('ICU Patients', Icons.medical_services),
          _buildSection('OR', Icons.local_hospital),
          _buildSection('Procedures', Icons.build),
        ],
      ),
    );
  }
}
