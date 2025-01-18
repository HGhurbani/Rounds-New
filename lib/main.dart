import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:rounds/UserLogin/Login.dart';
import '../SplashScreen.dart'; // تحديث المسار إذا كان مختلفًا
import 'package:rounds/Screens/HomeScreen.dart';
import 'package:rounds/colors.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(); // تهيئة Firebase

  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        fontFamily: 'Poppins',
        primaryColor: teal,
        scaffoldBackgroundColor: Colors.white,
        appBarTheme: AppBarTheme(
          color: teal, // لون شريط التطبيق
          centerTitle: true,
          iconTheme: IconThemeData(
            color: Colors.white, // لون أيقونات الـ AppBar
          ),
          titleTextStyle: TextStyle(
            color: Colors.white, // لون النصوص داخل الـ AppBar
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        popupMenuTheme: PopupMenuThemeData(
          color: Colors.grey[50], // تغيير اللون الخلفي للقائمة المنسدلة
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20), // منحنيات للقائمة المنسدلة
          ),
        ),
      ),

      routes: {
        '/home': (context) => HomeScreen(), // تعريف صفحة HomeScreen
        '/login': (context) => Login(), // تعريف صفحة Login
      },

      debugShowCheckedModeBanner: false,
      home: SplashScreen(), // استخدام صفحة البداية كصفحة رئيسية
    );
  }
}
