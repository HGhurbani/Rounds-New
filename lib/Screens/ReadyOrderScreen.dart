import 'package:flutter_share/flutter_share.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:rounds/AddScreens/AddReadyOrderScreen.dart';
import 'package:rounds/Status/DoctorID.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rounds/colors.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
// إضافة هذه السطر
import '../Network/DoctorDataModel.dart';

class ReadyOrderScreen extends StatefulWidget {
  @override
  _ReadyOrderScreenState createState() => _ReadyOrderScreenState();
}

class _ReadyOrderScreenState extends State<ReadyOrderScreen> {
  String userId = '';
  late DoctorData doctor;
  late stt.SpeechToText _speech;
  bool _isListeningTitle = false;
  TextEditingController titleController = TextEditingController();
  TextEditingController descController = TextEditingController();
  TextEditingController searchController =
      TextEditingController(); // Search controller for filtering orders
  String searchQuery = '';

  @override
  void initState() {
    super.initState();
    loadUserId();
    _speech = stt.SpeechToText();
  }

  void _listen(TextEditingController controller, bool isListening,
      Function updateState) async {
    if (!isListening) {
      bool available = await _speech.initialize();
      if (available) {
        setState(() => updateState(true));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Listening... Please start speaking.')),
        );
        _speech.listen(
          onResult: (val) => setState(() {
            controller.text += " ${val.recognizedWords}";
          }),
        );
      }
    } else {
      setState(() => updateState(false));
      _speech.stop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Stopped listening. Tap the mic to continue.')),
      );
    }
  }

  void loadUserId() async {
    try {
      String doctorId = await DoctorID().readID();
      DocumentSnapshot userSnapshot = await FirebaseFirestore.instance
          .collection('doctors')
          .doc(doctorId)
          .get();

      if (userSnapshot.exists) {
        setState(() {
          userId = userSnapshot.get('share_id');
        });
      } else {
        print('User not found in doctors collection.');
      }
    } catch (e) {
      print('Error loading user ID: $e');
    }
  }

  void deleteOrder(String orderId) {
    FirebaseFirestore.instance
        .collection('orders')
        .doc(orderId)
        .delete()
        .then((value) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15.0), // حواف مربعة ناعمة
            ),
            title: Text(
              'Success',
              style: TextStyle(color: teal), // لون النص للعنوان
            ),
            content: Text(
              'Order deleted successfully',
              style: TextStyle(color: Colors.black), // لون النص للمحتوى
            ),
            actions: <Widget>[
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text(
                  'OK',
                  style: TextStyle(color: teal), // لون النص للزر
                ),
              ),
            ],
          );
        },
      );
    }).catchError((error) {
      print("Failed to delete order: $error");
      Fluttertoast.showToast(
        msg: "Failed to delete order",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.deepOrangeAccent,
        textColor: Colors.white,
      );
    });
  }

  void shareOrder(String title, String description) async {
    try {
      await FlutterShare.share(
        title: 'Ready Orders',
        text: 'Title: $title\nDescription: $description',
        chooserTitle: 'Share Order',
      );
    } catch (e) {
      print('Error sharing order: $e');
      Fluttertoast.showToast(
        msg: "Failed to share order",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.grey,
        textColor: Colors.white,
      );
    }
  }

  void showOrderDetailsDialog(String title, String description) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.0),
          ),
          child: Container(
            padding: EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment:
                  CrossAxisAlignment.center, // توسيط العناصر بشكل أفقي
              children: [
                Text(
                  title,
                  style: TextStyle(
                      fontSize: 20.0, // حجم الخط للعنوان الفعلي
                      color: teal,
                      fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center, // توسيط النص داخل العنصر
                ),
                SizedBox(height: 8.0),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 15.0, // حجم الخط للوصف الفعلي
                    color: Colors.deepOrangeAccent,
                  ),
                  textAlign: TextAlign.center, // توسيط النص داخل العنصر
                ),
                SizedBox(height: 20.0),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context); // إغلاق الدايلوج
                  },
                  style: ButtonStyle(
                    shape: WidgetStateProperty.all<RoundedRectangleBorder>(
                      RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20.0), // حواف أنعم
                      ),
                    ),
                    backgroundColor: WidgetStateProperty.all<Color>(
                        Colors.deepOrangeAccent), // لون الخلفية
                    padding: WidgetStateProperty.all<EdgeInsetsGeometry>(
                        EdgeInsets.all(12.0)), // التباعد الداخلي
                  ),
                  child: Container(
                    width: double.infinity, // لجعل الزر على عرض الدايلوج
                    alignment: Alignment.center, // لتوسيط النص داخل الزر
                    child: Text(
                      'Close',
                      style: TextStyle(
                        fontSize: 16.0, // حجم النص
                        fontWeight: FontWeight.bold, // سمك النص
                        color: Colors.white, // لون النص
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: Text('Ready Orders'),
          actions: [],
        ),
        floatingActionButton: FloatingActionButton(
          backgroundColor: teal,
          onPressed: () {
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => AddReadyOrderScreen("", "", null)));
          },
          child: Icon(
            Icons.add,
            color: white,
          ),
        ),
        body: userId.isEmpty
            ? Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: TextField(
                      controller: searchController,
                      decoration: InputDecoration(
                        labelText: 'Search...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30.0),
                        ),
                        suffixIcon: Icon(Icons.search),
                      ),
                      onChanged: (value) {
                        setState(() {
                          searchQuery =
                              value.toLowerCase(); // Update search query
                        });
                      },
                    ),
                  ),
                  Expanded(
                    child: StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('orders')
                          .where('share_id', isEqualTo: userId)
                          .snapshots(),
                      builder: (BuildContext context,
                          AsyncSnapshot<QuerySnapshot> snapshot) {
                        if (snapshot.hasError) {
                          return Center(
                              child: Text('Error: ${snapshot.error}'));
                        }

                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return Center(child: CircularProgressIndicator());
                        }

                        var orders = snapshot.data!.docs.where((doc) {
                          var orderData = doc.data();

                          if (orderData is Map<String, dynamic>) {
                            // التحقق من أن orderData هو Map
                            return (orderData['order_title']
                                        ?.toString()
                                        .toLowerCase()
                                        .contains(searchQuery) ??
                                    false) ||
                                (orderData['order_text']
                                        ?.toString()
                                        .toLowerCase()
                                        .contains(searchQuery) ??
                                    false);
                          }

                          return false; // في حالة كانت orderData ليست من النوع الصحيح
                        }).toList();

                        if (orders.isEmpty) {
                          return Center(
                              child: Text(
                            'No Orders Found',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: teal,
                            ),
                          ));
                        }

                        return GridView.builder(
                          physics: BouncingScrollPhysics(),
                          padding: EdgeInsets.all(8),
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                          ),
                          itemCount: orders.length,
                          itemBuilder: (context, index) {
                            var order = orders[index].data();
                            return GestureDetector(
                              onTap: () {
                                if (order is Map<String, dynamic>) {
                                  showOrderDetailsDialog(
                                    order['order_text'] ??
                                        '', // استخدام قيمة افتراضية إذا كانت null
                                    order['order_title'] ??
                                        '', // استخدام قيمة افتراضية إذا كانت null
                                  );
                                } else {
                                  // إذا كانت order ليست من النوع Map<String, dynamic>
                                  print('Invalid order data');
                                }
                              },
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Card(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16.0),
                                  ),
                                  color: Colors.grey[50],
                                  elevation: 1,
                                  child: Column(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceEvenly,
                                    children: <Widget>[
                                      Padding(
                                        padding: const EdgeInsets.all(18.0),
                                        child: Text(
                                          (order is Map<String, dynamic>)
                                              ? (order['order_text'] ?? '')
                                              : '', // إذا كانت order من النوع Map<String, dynamic>
                                          style: TextStyle(
                                            color: teal,
                                            fontSize: 18,
                                            fontWeight: FontWeight.w600,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      Padding(
                                          padding: const EdgeInsets.only(
                                              right: 18.0, left: 18.0),
                                          child: Text(
                                            (order is Map<String, dynamic>)
                                                ? (order['order_title'] ?? '')
                                                : '', // التحقق من النوع وتوفير قيمة افتراضية إذا كانت null
                                            style: TextStyle(
                                              color: Colors.deepOrangeAccent,
                                              fontSize: 14,
                                            ),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            textAlign: TextAlign.center,
                                          )),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: <Widget>[
                                          Container(),
                                          PopupMenuButton<String>(
                                            onSelected: (value) {
                                              if (value == 'edit') {
                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (context) =>
                                                        AddReadyOrderScreen(
                                                      (order is Map<String,
                                                              dynamic>)
                                                          ? order['order_text']
                                                          : '', // التحقق من النوع واستخدام قيمة افتراضية إذا كانت null
                                                      (order is Map<String,
                                                              dynamic>)
                                                          ? order['order_title']
                                                          : '', // التحقق من النوع واستخدام قيمة افتراضية إذا كانت null
                                                      orders[index].id,
                                                    ),
                                                  ),
                                                );
                                              } else if (value == 'delete') {
                                                showDialog(
                                                  context: context,
                                                  builder:
                                                      (BuildContext context) {
                                                    return Dialog(
                                                      shape:
                                                          RoundedRectangleBorder(
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(10.0),
                                                      ),
                                                      child: Container(
                                                        padding: EdgeInsets.all(
                                                            20.0),
                                                        child: Column(
                                                          mainAxisSize:
                                                              MainAxisSize.min,
                                                          children: [
                                                            Text(
                                                              'Confirm Delete',
                                                              style: TextStyle(
                                                                fontSize: 20.0,
                                                                color: teal,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                              ),
                                                            ),
                                                            SizedBox(
                                                                height: 20.0),
                                                            Text(
                                                              'Are you sure you want to delete this order?',
                                                              style: TextStyle(
                                                                fontSize: 16.0,
                                                              ),
                                                            ),
                                                            SizedBox(
                                                                height: 20.0),
                                                            Row(
                                                              mainAxisAlignment:
                                                                  MainAxisAlignment
                                                                      .end,
                                                              children: [
                                                                TextButton(
                                                                  onPressed:
                                                                      () {
                                                                    Navigator.of(
                                                                            context)
                                                                        .pop();
                                                                  },
                                                                  child: Text(
                                                                    'Cancel',
                                                                    style:
                                                                        TextStyle(
                                                                      color: Colors
                                                                          .black87,
                                                                    ),
                                                                  ),
                                                                ),
                                                                SizedBox(
                                                                    width:
                                                                        10.0),
                                                                TextButton(
                                                                  onPressed:
                                                                      () {
                                                                    if (order is Map<
                                                                        String,
                                                                        dynamic>) {
                                                                      deleteOrder(
                                                                          order[
                                                                              'orderId']);
                                                                      Navigator.of(
                                                                              context)
                                                                          .pop();
                                                                    } else {
                                                                      // التعامل مع الخطأ أو التحقق من النوع
                                                                      print(
                                                                          "order is not a Map<String, dynamic>");
                                                                    }
                                                                  },
                                                                  child: Text(
                                                                    'Delete',
                                                                    style:
                                                                        TextStyle(
                                                                      color: Colors
                                                                          .red,
                                                                    ),
                                                                  ),
                                                                ),
                                                              ],
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                    );
                                                  },
                                                );
                                              } else if (value == 'share') {
                                                if (order
                                                    is Map<String, dynamic>) {
                                                  shareOrder(
                                                    order['order_title'],
                                                    order['order_text'],
                                                  );
                                                } else {
                                                  print(
                                                      "Order is not a Map<String, dynamic>");
                                                }
                                              }
                                            },
                                            itemBuilder:
                                                (BuildContext context) {
                                              return [
                                                PopupMenuItem(
                                                  value: 'edit',
                                                  child: Row(
                                                    children: [
                                                      Icon(Icons.edit,
                                                          color: Colors.blue),
                                                      SizedBox(width: 8),
                                                      Text('Edit'),
                                                    ],
                                                  ),
                                                ),
                                                PopupMenuItem(
                                                  value: 'delete',
                                                  child: Row(
                                                    children: [
                                                      Icon(Icons.delete,
                                                          color: Colors.red),
                                                      SizedBox(width: 8),
                                                      Text('Delete'),
                                                    ],
                                                  ),
                                                ),
                                                PopupMenuItem(
                                                  value: 'share',
                                                  child: Row(
                                                    children: [
                                                      Icon(Icons.share,
                                                          color: Colors.black),
                                                      SizedBox(width: 8),
                                                      Text('Share'),
                                                    ],
                                                  ),
                                                ),
                                              ];
                                            },
                                            child: Icon(Icons.more_vert,
                                                color: Colors.grey),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
