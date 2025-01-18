import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:rounds/colors.dart'; // تأكد من أن هذا الملف يحتوي على الألوان المستخدمة.

class NotificationsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Notifications'),
        backgroundColor: teal, // اللون الذي ترغب فيه
      ),
      body: StreamBuilder(
        stream: FirebaseFirestore.instance
            .collection('daily_rounds')
            .snapshots(), // الاستماع إلى التغييرات في جدول daily_rounds
        builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }

          // استخدم ListView لعرض الإشعارات
          var notifications = snapshot.data!.docs.map((doc) {
            var tasks = doc['tasks'] as List;
            List<Widget> taskNotifications = [];

            for (var task in tasks) {
              bool isCompleted = task['completed'];
              String taskName = task['task']; // الحصول على اسم المهمة

              // إضافة إشعار حسب حالة المهمة
              taskNotifications.add(
                Container(
                  margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius:
                        BorderRadius.circular(12), // حواف دائرية ناعمة
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.2),
                        spreadRadius: 2,
                        blurRadius: 6,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // جزء اليسار: عنوان المهمة وحالتها
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  isCompleted
                                      ? Icons.check_circle
                                      : Icons.error,
                                  color: isCompleted
                                      ? teal
                                      : Colors.deepOrangeAccent,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  isCompleted
                                      ? '$taskName completed'
                                      : '$taskName not completed',
                                  style: TextStyle(
                                    color: isCompleted
                                        ? teal
                                        : Colors.deepOrangeAccent,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 4),
                            Text(
                              isCompleted
                                  ? 'The task has been completed successfully.'
                                  : 'This task has not been completed yet.',
                              style: TextStyle(
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // الجزء الأيمن: أيقونة العين لفتح الديالوج
                      IconButton(
                        icon: Icon(Icons.remove_red_eye, color: teal),
                        onPressed: () async {
                          try {
                            // عند الضغط على الأيقونة، عرض الديالوج
                            await _showTaskDetailsDialog(
                                context, doc['patientId']);
                          } catch (e) {
                            print('Error when opening dialog: $e');
                          }
                        },
                      ),
                    ],
                  ),
                ),
              );
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: taskNotifications,
            );
          }).toList();

          return ListView(
            children: notifications,
          );
        },
      ),
    );
  }

  // دالة لعرض الديالوج مع تفاصيل الإشعار
  Future<void> _showTaskDetailsDialog(
      BuildContext context, dynamic patientId) async {
    try {
      String patientIdStr = patientId.toString(); // تحويل patientId إلى String
      debugPrint(
          'Fetching details for patientId: $patientIdStr'); // طباعة الـ patientId في الـ debug

      // جلب بيانات المريض باستخدام patientId
      var patientSnapshot = await FirebaseFirestore.instance
          .collection('patients')
          .where('id',
              isEqualTo:
                  int.parse(patientIdStr)) // التأكد من أن البيانات نوعها متطابق
          .get();

      debugPrint("Patient snapshot size: ${patientSnapshot.docs.length}");

      if (patientSnapshot.docs.isNotEmpty) {
        var patient = patientSnapshot.docs.first;
        String patientName = patient['name']; // اسم المريض
        debugPrint(
            'Patient found: $patientName'); // طباعة اسم المريض في الـ debug

        // جلب بيانات الطبيب من جدول daily_rounds
        var doctorSnapshot = await FirebaseFirestore.instance
            .collection('daily_rounds')
            .where('patientId', isEqualTo: int.parse(patientIdStr))
            .get();

        if (doctorSnapshot.docs.isNotEmpty) {
          var doctor = doctorSnapshot.docs.first;
          String doctorName = doctor['doctor_name']; // اسم الطبيب
          debugPrint(
              'Doctor found: $doctorName'); // طباعة اسم الطبيب في الـ debug

          // عرض الديالوج
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(16), // إضافة حواف دائرية للديالوج
                ),
                title: Row(
                  children: [
                    Icon(Icons.info_outline, color: teal), // أيقونة تعبيرية
                    SizedBox(width: 8),
                    Text(
                      'Task Details',
                      style:
                          TextStyle(color: teal, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.person,
                            color: Colors.deepOrangeAccent), // أيقونة الطبيب
                        SizedBox(width: 8),
                        Text(
                          'Doctor: $doctorName',
                          style: TextStyle(
                              color: teal, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                    SizedBox(height: 16),
                    Row(
                      children: [
                        Icon(Icons.medical_services,
                            color: Colors.deepOrangeAccent), // أيقونة المريض
                        SizedBox(width: 8),
                        Text(
                          'Patient: $patientName',
                          style: TextStyle(
                              color: teal, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop(); // إغلاق الديالوج
                    },
                    child: Text(
                      'Close',
                      style: TextStyle(
                          color: Colors.deepOrangeAccent,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              );
            },
          );
        } else {
          debugPrint("No doctor found for patientId: $patientIdStr");
        }
      } else {
        debugPrint("No patient found for patientId: $patientIdStr");
      }
    } catch (e) {
      debugPrint("Error occurred: $e");
      // إظهار رسالة خطأ للمستخدم في حالة حدوث خطأ
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Error'),
            content: Text('An error occurred while fetching data.'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(); // إغلاق الديالوج
                },
                child: Text('Close'),
              ),
            ],
          );
        },
      );
    }
  }
}
