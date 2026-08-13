import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'db_service.dart';
import 'helpers.dart';

class QrScannerScreen extends StatefulWidget {
  final String studentUid;
  const QrScannerScreen({Key? key, required this.studentUid}) : super(key: key);

  @override
  _QrScannerScreenState createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen> {
  final DbService _dbService = DbService();
  final MobileScannerController _cameraController = MobileScannerController();
  bool _isScanning = true;

  void _onDetect(BarcodeCapture capture) async {
    if (!_isScanning) return;

    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isEmpty || barcodes.first.rawValue == null) return;

    setState(() => _isScanning = false);
    String rawPayload = barcodes.first.rawValue!;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      await _dbService.markStudentAttendance(
        scannedPayload: rawPayload,
        studentUid: widget.studentUid,
      );

      if (mounted) {
        Navigator.pop(context);
        UIHelpers.showSnackBar(context, "Attendance Marked Successfully!");
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        UIHelpers.showSnackBar(context, e.toString(), isError: true);

        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) setState(() => _isScanning = true);
        });
      }
    }
  }

  @override
  void dispose() {
    _cameraController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan QR Code'),
        backgroundColor: Colors.blue.shade900,
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          MobileScanner(controller: _cameraController, onDetect: _onDetect),
          ColorFiltered(
            colorFilter: ColorFilter.mode(
              Colors.black.withOpacity(0.6),
              BlendMode.srcOut,
            ),
            child: Stack(
              children: [
                Container(
                  decoration: const BoxDecoration(color: Colors.transparent),
                ),
                Align(
                  alignment: Alignment.center,
                  child: Container(
                    height: 250,
                    width: 250,
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Align(
            alignment: Alignment.center,
            child: Container(
              height: 250,
              width: 250,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.blue.shade400, width: 4),
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
          const Positioned(
            bottom: 60,
            left: 20,
            right: 20,
            child: Text(
              'Align the QR code within the highlighted frame to check-in.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.bold,
                shadows: [Shadow(blurRadius: 4, color: Colors.black)],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
