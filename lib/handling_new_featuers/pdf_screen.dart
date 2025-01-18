
import 'package:flutter/material.dart';
import 'package:flutter_cached_pdfview/flutter_cached_pdfview.dart';
import 'package:rounds/colors.dart';

import '../Network/SickModel.dart';

class PDFScreen extends StatelessWidget {
  Reports data;

  PDFScreen({ Key? key, required this.data}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        centerTitle: true,
        backgroundColor: teal,
        title: Text(data.reportTitle ?? ''),
      ),
      backgroundColor: Colors.grey[300],
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Center(
          child: PDF(
            enableSwipe: true,
            autoSpacing: false,
            pageFling: false,
          ).fromUrl(data.reportPdf ?? ''),
        ),
      ),
    );
  }
}
