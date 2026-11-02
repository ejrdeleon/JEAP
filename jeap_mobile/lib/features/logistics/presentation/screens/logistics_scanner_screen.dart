import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:jeap_mobile/core/theme/app_theme.dart';
import 'package:jeap_mobile/features/logistics/models/logistics_parcel.dart';
import 'package:jeap_mobile/features/logistics/presentation/screens/scan_result_screen.dart';
import 'package:jeap_mobile/features/logistics/services/logistics_service.dart';

class LogisticsScannerScreen extends StatefulWidget {
  const LogisticsScannerScreen({super.key});

  @override
  State<LogisticsScannerScreen> createState() => _LogisticsScannerScreenState();
}

class _LogisticsScannerScreenState extends State<LogisticsScannerScreen> {
  final LogisticsService _service = LogisticsService();
  final TextEditingController _manualController = TextEditingController();

  CameraController? _cameraController;
  bool _cameraInitialized = false;
  bool _flashOn = false;
  bool _searching = false;
  String? _errorMessage;

  final List<String> _quickTestBarcodes = [
    'JEPLGN1001IN',
    'JEPLGN1002SRT',
    'JEPLGN1003DSP',
    'JEPLGN1006DSP',
  ];

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isNotEmpty) {
        final backCamera = cameras.firstWhere(
          (c) => c.lensDirection == CameraLensDirection.back,
          orElse: () => cameras.first,
        );
        _cameraController = CameraController(
          backCamera,
          ResolutionPreset.medium,
          enableAudio: false,
        );
        await _cameraController!.initialize();
        if (mounted) {
          setState(() => _cameraInitialized = true);
        }
      }
    } catch (_) {
      // Camera not available in test or simulator; graceful fallback to visual viewfinder
    }
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _manualController.dispose();
    super.dispose();
  }

  Future<void> _toggleFlash() async {
    if (_cameraController != null && _cameraController!.value.isInitialized) {
      try {
        final next = !_flashOn;
        await _cameraController!.setFlashMode(
          next ? FlashMode.torch : FlashMode.off,
        );
        setState(() => _flashOn = next);
      } catch (_) {
        setState(() => _flashOn = !_flashOn);
      }
    } else {
      setState(() => _flashOn = !_flashOn);
    }
  }

  Future<void> _handleLookup(String code) async {
    final trimmed = code.trim();
    if (trimmed.isEmpty) return;

    setState(() {
      _searching = true;
      _errorMessage = null;
    });

    final parcel = await _service.getParcel(trimmed);
    if (!mounted) return;

    setState(() => _searching = false);

    if (parcel != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ScanResultScreen(parcel: parcel),
        ),
      );
    } else {
      // Demo fallback if parcel lookup doesn't exist
      final demoParcel = LogisticsParcel(
        trackingNumber: trimmed.startsWith('JP-') ? trimmed : 'JP-$trimmed',
        orderNumber: 'ORD-2026-${trimmed.replaceAll(RegExp(r'[^0-9]'), '')}',
        status: 'AT_SORTING_CENTER',
        recipientName: 'Maria Santos',
        recipientPhone: '0917-123-4567',
        destinationAddress: 'Brgy. Poblacion, Santa Cruz, Laguna 4009',
        originHub: 'JEAP Central Warehouse (Santa Cruz, Laguna)',
        itemsCount: 2,
        totalAmount: 1450.00,
        paymentMethod: 'Cash on Delivery (COD)',
        createdAt: DateTime.now().toIso8601String(),
        allowedActions: const ['sort', 'dispatch', 'transfer'],
      );

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ScanResultScreen(parcel: demoParcel),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text(
          'Parcel Scanner',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
        ),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            tooltip: 'Flashlight Toggle',
            icon: Icon(
              _flashOn ? Icons.flash_on : Icons.flash_off,
              color: _flashOn ? Colors.amber : Colors.white70,
            ),
            onPressed: _toggleFlash,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Camera preview if available, else stylized viewfinder background
                  if (_cameraInitialized &&
                      _cameraController != null &&
                      _cameraController!.value.isInitialized)
                    SizedBox.expand(
                      child: CameraPreview(_cameraController!),
                    )
                  else
                    Container(
                      width: double.infinity,
                      color: Colors.grey.shade900,
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.qr_code_scanner,
                              size: 72,
                              color: AppTheme.jeapPurple.withValues(alpha: 0.7),
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'Align Barcode or QR Code within frame',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  // Semi-transparent scan viewfinder frame
                  Container(
                    width: 250,
                    height: 250,
                    decoration: BoxDecoration(
                      border: Border.all(color: AppTheme.jeapPurple, width: 2.5),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.jeapPurple.withValues(alpha: 0.15),
                          blurRadius: 16,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Stack(
                      children: [
                        Positioned(
                          top: 0,
                          left: 0,
                          child: Container(
                            width: 24,
                            height: 24,
                            decoration: const BoxDecoration(
                              border: Border(
                                top: BorderSide(color: Colors.amber, width: 4),
                                left: BorderSide(color: Colors.amber, width: 4),
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          top: 0,
                          right: 0,
                          child: Container(
                            width: 24,
                            height: 24,
                            decoration: const BoxDecoration(
                              border: Border(
                                top: BorderSide(color: Colors.amber, width: 4),
                                right: BorderSide(color: Colors.amber, width: 4),
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          left: 0,
                          child: Container(
                            width: 24,
                            height: 24,
                            decoration: const BoxDecoration(
                              border: Border(
                                bottom: BorderSide(color: Colors.amber, width: 4),
                                left: BorderSide(color: Colors.amber, width: 4),
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            width: 24,
                            height: 24,
                            decoration: const BoxDecoration(
                              border: Border(
                                bottom: BorderSide(color: Colors.amber, width: 4),
                                right: BorderSide(color: Colors.amber, width: 4),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Searching overlay
                  if (_searching)
                    Container(
                      color: Colors.black54,
                      child: const Center(
                        child: CircularProgressIndicator(color: Colors.white),
                      ),
                    ),
                ],
              ),
            ),

            // Quick barcode testing chips for seamless test workflows
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: const Color(0xFF0F172A),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Quick Test Barcodes:',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: _quickTestBarcodes.map((code) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: ActionChip(
                            backgroundColor: const Color(0xFF334155),
                            side: BorderSide(
                              color: AppTheme.jeapPurple.withValues(alpha: 0.5),
                            ),
                            label: Text(
                              code,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10.5,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            onPressed: () {
                              _manualController.text = code;
                              _handleLookup(code);
                            },
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),

            // Bottom manual entry sheet
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Color(0xFF1E293B),
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Manual Tracking Number Entry',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _manualController,
                          style: const TextStyle(color: Colors.white, fontSize: 13),
                          decoration: InputDecoration(
                            hintText: 'e.g. JEPLGN1001IN or ORD-001',
                            hintStyle: const TextStyle(color: Colors.white38, fontSize: 12),
                            filled: true,
                            fillColor: Colors.black26,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: Colors.grey.shade700),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(color: AppTheme.jeapPurple),
                            ),
                          ),
                          onSubmitted: _handleLookup,
                        ),
                      ),
                      const SizedBox(width: 10),
                      SizedBox(
                        width: 110,
                        height: 48,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.jeapPurple,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          onPressed: () => _handleLookup(_manualController.text),
                          child: const Text(
                            'Lookup',
                            maxLines: 1,
                            softWrap: false,
                            overflow: TextOverflow.visible,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (_errorMessage != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      _errorMessage!,
                      style: const TextStyle(color: Colors.redAccent, fontSize: 11),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
