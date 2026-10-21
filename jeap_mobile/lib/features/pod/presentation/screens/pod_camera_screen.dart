import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import '../../../../../../theme/app_theme.dart';
import 'package:jeap_mobile/features/tasks/models/delivery_task.dart';

class PodCameraScreen extends StatefulWidget {
  final DeliveryTask task;

  const PodCameraScreen({super.key, required this.task});

  @override
  State<PodCameraScreen> createState() => _PodCameraScreenState();
}

class _PodCameraScreenState extends State<PodCameraScreen> {
  CameraController? _controller;
  List<CameraDescription>? _cameras;
  bool _isInitialized = false;

  String? _awbPath;
  String? _parcelPath;
  int _currentStep = 1;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    _cameras = await availableCameras();
    if (_cameras != null && _cameras!.isNotEmpty) {
      _controller = CameraController(
        _cameras![0],
        ResolutionPreset.medium,
        enableAudio: false,
      );
      await _controller!.initialize();
      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _capturePhoto() async {
    if (_controller == null || !_controller!.value.isInitialized) return;

    final XFile photo = await _controller!.takePicture();
    setState(() {
      if (_currentStep == 1) {
        _awbPath = photo.path;
        _currentStep = 2;
      } else {
        _parcelPath = photo.path;
      }
    });
  }

  void _resetPhotos() {
    setState(() {
      _awbPath = null;
      _parcelPath = null;
      _currentStep = 1;
    });
  }

  void _submitPOD() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Uploading POD & Completing Delivery...')),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
            child: CircularProgressIndicator(color: AppTheme.jeapPurple)),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_currentStep == 1
            ? 'Step 1: Photo of AWB'
            : 'Step 2: Photo of Parcel/Recipient'),
        actions: [
          if (_awbPath != null || _parcelPath != null)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _resetPhotos,
            ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            color: Colors.black,
            width: double.infinity,
            child: Text(
              _currentStep == 1
                  ? 'Align the Airway Bill barcode within the box.'
                  : 'Capture house number or recipient receiving the item.',
              style: const TextStyle(color: Colors.white, fontSize: 13),
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            child: _parcelPath != null
                ? Image.file(File(_parcelPath!),
                    fit: BoxFit.cover, width: double.infinity)
                : _awbPath != null && _currentStep == 2
                    ? Stack(
                        children: [
                          CameraPreview(_controller!),
                          Positioned(
                            top: 10,
                            right: 10,
                            child: Container(
                              width: 80,
                              height: 100,
                              decoration: BoxDecoration(
                                  border: Border.all(
                                      color: Colors.green, width: 2)),
                              child: Image.file(File(_awbPath!),
                                  fit: BoxFit.cover),
                            ),
                          )
                        ],
                      )
                    : CameraPreview(_controller!),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.black,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                if (_parcelPath == null)
                  FloatingActionButton(
                    backgroundColor: AppTheme.jeapPurple,
                    onPressed: _capturePhoto,
                    child: const Icon(Icons.camera_alt, color: Colors.white),
                  )
                else
                  ElevatedButton(
                    onPressed: _submitPOD,
                    child: const Text('Confirm & Submit POD'),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
