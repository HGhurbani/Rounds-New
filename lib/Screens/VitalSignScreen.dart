import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rounds/Network/DoctorSicksModel.dart';
import 'package:rounds/AddScreens/AddVitalSigns.dart';
import 'package:rounds/Details/VitalSignDetailsScreen.dart';
import 'package:share/share.dart';
import '../colors.dart';

class VitalSignScreen extends StatefulWidget {
  final String patientId;
  final DoctorSicks patient;

  const VitalSignScreen(
      {Key? key, required this.patientId, required this.patient})
      : super(key: key);

  @override
  _VitalSignScreenState createState() => _VitalSignScreenState();
}

class _VitalSignScreenState extends State<VitalSignScreen> {
  FirebaseFirestore firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Vital Signs'),
      ),
      body: _buildTabContent('add-vital-sign'),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AddVitalSignScreen(
                'Vital Sign',
                0,
                "",
                "",
                "",
                "",
                0,
                "",
                "",
                widget.patient,
              ),
            ),
          );
        },
        backgroundColor: teal,
        child: Icon(
          Icons.add,
          color: white,
        ),
      ),
    );
  }

  Widget _buildTabContent(String action) {
    return StreamBuilder(
      stream: firestore
          .collection('vital_sign')
          .where('sick_id', isEqualTo: widget.patient.id)
          .snapshots(),
      builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (snapshot.data!.docs.isEmpty) {
          return Center(
              child: Text('No Vital Signs Added',
                  style: TextStyle(color: teal, fontWeight: FontWeight.bold)));
        }

        return ListView.builder(
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            var doc = snapshot.data!.docs[index];
            return Container(
              margin: EdgeInsets.symmetric(vertical: 16, horizontal: 16),
              padding: EdgeInsets.only(left: 20, bottom: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.3),
                    spreadRadius: 2,
                    blurRadius: 5,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      PopupMenuButton<String>(
                        itemBuilder: (BuildContext context) =>
                            <PopupMenuEntry<String>>[
                          PopupMenuItem<String>(
                            value: 'share',
                            child: Row(
                              children: [
                                Icon(Icons.share),
                                SizedBox(width: 8),
                                Text('Share'),
                              ],
                            ),
                          ),
                          PopupMenuItem<String>(
                            value: 'edit',
                            child: Row(
                              children: [
                                Icon(Icons.edit, color: Colors.blue),
                                SizedBox(width: 8),
                                Text('Edit'),
                              ],
                            ),
                          ),
                          PopupMenuItem<String>(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(Icons.delete, color: Colors.red),
                                SizedBox(width: 8),
                                Text('Delete'),
                              ],
                            ),
                          ),
                          PopupMenuItem<String>(
                            value: 'see_more',
                            child: Row(
                              children: [
                                Icon(Icons.remove_red_eye_outlined,
                                    color: teal),
                                SizedBox(width: 8),
                                Text('See more'),
                              ],
                            ),
                          ),
                        ],
                        onSelected: (String value) {
                          switch (value) {
                            case 'see_more':
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => VitalSignDetailScreen(
                                    data: doc.data() as Map<String,
                                        dynamic>, // تحويل النوع هنا
                                  ),
                                ),
                              );
                              break;
                            case 'share':
                              _shareData(doc);
                              break;
                            case 'edit':
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => AddVitalSignScreen(
                                    (doc.data() as Map<String, dynamic>?)
                                                ?.containsKey('temperature') ==
                                            true
                                        ? doc['temperature']
                                        : '',
                                    1, // Changed to 1 to indicate edit mode
                                    (doc.data() as Map<String, dynamic>?)
                                                ?.containsKey('heart_rate') ==
                                            true
                                        ? doc['heart_rate']
                                        : '',
                                    (doc.data() as Map<String, dynamic>?)
                                                ?.containsKey(
                                                    'respiratary_rate') ==
                                            true
                                        ? doc['respiratary_rate']
                                        : '',
                                    (doc.data() as Map<String, dynamic>?)
                                                ?.containsKey(
                                                    'blood_pressure') ==
                                            true
                                        ? doc['blood_pressure']
                                        : '',
                                    (doc.data() as Map<String, dynamic>?)
                                                ?.containsKey('blood_suger') ==
                                            true
                                        ? doc['blood_suger']
                                        : '',
                                    index,
                                    (doc.data() as Map<String, dynamic>?)
                                                ?.containsKey('others') ==
                                            true
                                        ? doc['others']
                                        : '',
                                    widget.patient.id.toString(),
                                    widget.patient,
                                    doc.id,
                                  ),
                                ),
                              );
                              break;
                            case 'delete':
                              showDialog(
                                context: context,
                                builder: (BuildContext context) {
                                  return AlertDialog(
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(15.0),
                                    ),
                                    title: Text('Confirm Deletion',
                                        style: TextStyle(
                                            color: Colors.deepOrangeAccent,
                                            fontWeight: FontWeight.bold)),
                                    content: Text(
                                        'Are you sure you want to delete this item?'),
                                    actions: [
                                      TextButton(
                                        onPressed: () {
                                          Navigator.of(context).pop();
                                        },
                                        child: Text('Cancel',
                                            style: TextStyle(color: teal)),
                                      ),
                                      TextButton(
                                        onPressed: () {
                                          Navigator.of(context).pop();
                                          deleteDocument(doc.id);
                                        },
                                        child: Text('Delete',
                                            style: TextStyle(
                                                color:
                                                    Colors.deepOrangeAccent)),
                                      ),
                                    ],
                                  );
                                },
                              );
                              break;
                          }
                        },
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Text('Hearts Rate: ',
                          style: TextStyle(
                              color: teal, fontWeight: FontWeight.bold)),
                      Text(
                        (doc.data() as Map<String, dynamic>?)
                                    ?.containsKey('heart_rate') ==
                                true
                            ? '${doc['heart_rate']}'
                            : 'N/A',
                        style: TextStyle(color: Colors.black),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Text('Respiratory Rate: ',
                          style: TextStyle(
                              color: teal, fontWeight: FontWeight.bold)),
                      Text(
                        (doc.data() as Map<String, dynamic>?)
                                    ?.containsKey('respiratary_rate') ==
                                true
                            ? '${doc['respiratary_rate']}'
                            : 'N/A',
                        style: TextStyle(color: Colors.black),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Text('Temperature: ',
                          style: TextStyle(
                              color: teal, fontWeight: FontWeight.bold)),
                      Text(
                        (doc.data() as Map<String, dynamic>?)
                                    ?.containsKey('temperature') ==
                                true
                            ? '${doc['temperature']}'
                            : 'N/A',
                        style: TextStyle(color: Colors.black),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  final CollectionReference collection =
      FirebaseFirestore.instance.collection('vital_sign');

  Future<void> deleteDocument(String documentId) async {
    try {
      await collection.doc(documentId).delete();
      print('Document deleted successfully!');
    } catch (e) {
      print('Error deleting document: $e');
    }
  }

  void _shareData(DocumentSnapshot documentSnapshot) {
    var data = documentSnapshot.data() as Map<String, dynamic>?;

    String text = 'Vital Sign Data:\n'
        'Date: ${data?.containsKey('date') == true ? data!['date'] : 'N/A'}\n'
        'Heart Rate: ${data?.containsKey('heart_rate') == true ? data!['heart_rate'] : 'N/A'}\n'
        'Respiratory Rate: ${data?.containsKey('respiratary_rate') == true ? data!['respiratary_rate'] : 'N/A'}\n'
        'Temperature: ${data?.containsKey('temperature') == true ? data!['temperature'] : 'N/A'}\n'
        'Result: ${data?.containsKey('result') == true ? data!['result'] : 'N/A'}\n'
        'Normal Value: ${data?.containsKey('normal_value') == true ? data!['normal_value'] : 'N/A'}';

    Share.share(text);
  }
}
