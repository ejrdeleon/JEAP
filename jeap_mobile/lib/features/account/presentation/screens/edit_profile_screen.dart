import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:jeap_mobile/core/storage/auth_session.dart';
import 'package:jeap_mobile/core/theme/app_theme.dart';
import 'package:jeap_mobile/core/widgets/jeap_app_bar.dart';
import 'package:jeap_mobile/core/widgets/primary_button.dart';
import 'package:jeap_mobile/features/auth/services/auth_service.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final AuthService _authService = AuthService();
  final ImagePicker _picker = ImagePicker();

  String? _avatarUrl;
  File? _pendingImage;
  bool _loading = false;
  bool _uploadingPhoto = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  void _loadProfile() {
    final cached = AuthSession.instance.currentUser;
    if (cached != null) {
      _applyUserData(cached);
    }
    _authService.me().then((u) {
      if (!mounted || u == null) return;
      setState(() => _applyUserData(u));
    });
  }

  void _applyUserData(Map<String, dynamic> u) {
    _firstNameCtrl.text = (u['first_name'] ?? '').toString();
    _lastNameCtrl.text = (u['last_name'] ?? '').toString();
    _phoneCtrl.text = (u['phone'] ?? '').toString();
    _avatarUrl = u['avatar_url']?.toString();
  }

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _showPhotoSourceSheet() async {
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const Text(
                'Change Profile Photo',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              ListTile(
                leading: const Icon(Icons.photo_camera_outlined,
                    color: AppTheme.jeapPurple),
                title: const Text('Take a photo'),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined,
                    color: AppTheme.jeapPurple),
                title: const Text('Choose from gallery'),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImage(ImageSource.gallery);
                },
              ),
              if (_avatarUrl != null || _pendingImage != null)
                ListTile(
                  leading: const Icon(Icons.visibility_outlined,
                      color: AppTheme.textSecondary),
                  title: const Text('View current photo'),
                  onTap: () {
                    Navigator.pop(ctx);
                    _viewCurrentPhoto();
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picked = await _picker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 80,
      );
      if (picked == null || !mounted) return;

      final file = File(picked.path);
      setState(() => _pendingImage = file);
      await _confirmAndUpload(file);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to pick photo: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  Future<void> _confirmAndUpload(File file) async {
    final shouldUpload = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Update Profile Photo'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipOval(
              child: Image.file(
                file,
                width: 120,
                height: 120,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Set this photo as your profile picture?',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.jeapPurple,
            ),
            child: const Text('Upload'),
          ),
        ],
      ),
    );

    if (shouldUpload != true || !mounted) {
      setState(() => _pendingImage = null);
      return;
    }

    setState(() => _uploadingPhoto = true);
    final result = await _authService.updateProfilePhoto(file.path);
    if (!mounted) return;

    setState(() {
      _uploadingPhoto = false;
      _pendingImage = null;
      if (result.success && result.user != null) {
        _avatarUrl = result.user!['avatar_url']?.toString();
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result.message),
        backgroundColor:
            result.success ? AppTheme.statusGreen : Colors.redAccent,
      ),
    );
  }

  void _viewCurrentPhoto() {
    showDialog<void>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: _pendingImage != null
                  ? Image.file(_pendingImage!, fit: BoxFit.contain)
                  : (_avatarUrl != null && _avatarUrl!.isNotEmpty)
                      ? Image.network(_avatarUrl!, fit: BoxFit.contain)
                      : Container(
                          width: 200,
                          height: 200,
                          color: Colors.white,
                          child: const Icon(Icons.person,
                              size: 100, color: AppTheme.textSecondary),
                        ),
            ),
            const SizedBox(height: 12),
            IconButton(
              icon: const Icon(Icons.close, color: Colors.white, size: 28),
              onPressed: () => Navigator.pop(ctx),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    final result = await _authService.updateProfile({
      'first_name': _firstNameCtrl.text.trim(),
      'last_name': _lastNameCtrl.text.trim(),
      'phone': _phoneCtrl.text.trim(),
    });
    if (!mounted) return;
    setState(() => _loading = false);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(result.message),
      backgroundColor: result.success ? AppTheme.statusGreen : Colors.redAccent,
    ));
    if (result.success) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final initials =
        '${_firstNameCtrl.text.trim().isNotEmpty ? _firstNameCtrl.text.trim()[0] : ''}'
                '${_lastNameCtrl.text.trim().isNotEmpty ? _lastNameCtrl.text.trim()[0] : ''}'
            .toUpperCase();

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: const JeapAppBar(),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Edit Profile',
                    style:
                        TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),

                // Centered Profile Photo Editor
                Center(
                  child: Column(
                    children: [
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color:
                                    AppTheme.jeapPurple.withValues(alpha: .2),
                                width: 3,
                              ),
                            ),
                            child: ClipOval(
                              child: _pendingImage != null
                                  ? Image.file(
                                      _pendingImage!,
                                      width: 100,
                                      height: 100,
                                      fit: BoxFit.cover,
                                    )
                                  : (_avatarUrl != null &&
                                          _avatarUrl!.isNotEmpty)
                                      ? Image.network(
                                          _avatarUrl!,
                                          width: 100,
                                          height: 100,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) =>
                                              _initialsAvatar(initials),
                                        )
                                      : _initialsAvatar(initials),
                            ),
                          ),
                          if (_uploadingPhoto)
                            Container(
                              width: 100,
                              height: 100,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.black.withValues(alpha: .45),
                              ),
                              child: const Center(
                                child: CircularProgressIndicator(
                                  strokeWidth: 3,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white),
                                ),
                              ),
                            ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Material(
                              color: AppTheme.jeapPurple,
                              shape: const CircleBorder(),
                              elevation: 2,
                              child: InkWell(
                                customBorder: const CircleBorder(),
                                onTap: _uploadingPhoto
                                    ? null
                                    : _showPhotoSourceSheet,
                                child: const Padding(
                                  padding: EdgeInsets.all(8),
                                  child: Icon(
                                    Icons.camera_alt,
                                    color: Colors.white,
                                    size: 18,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      TextButton.icon(
                        onPressed:
                            _uploadingPhoto ? null : _showPhotoSourceSheet,
                        icon: const Icon(Icons.photo_camera,
                            size: 16, color: AppTheme.jeapPurple),
                        label: Text(
                          _avatarUrl != null ? 'Change Photo' : 'Add Photo',
                          style: const TextStyle(
                            color: AppTheme.jeapPurple,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                _field('First Name *', _firstNameCtrl),
                const SizedBox(height: 14),
                _field('Last Name *', _lastNameCtrl),
                const SizedBox(height: 14),
                _field('Contact Number *', _phoneCtrl,
                    keyboardType: TextInputType.phone),
                const SizedBox(height: 28),
                PrimaryButton(
                    label: 'SAVE CHANGES', onPressed: _save, loading: _loading),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _initialsAvatar(String initials) {
    return Container(
      color: AppTheme.jeapPurple.withValues(alpha: .15),
      child: Center(
        child: Text(
          initials.isNotEmpty ? initials : 'JE',
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: AppTheme.jeapPurple,
          ),
        ),
      ),
    );
  }

  Widget _field(String label, TextEditingController ctrl,
      {TextInputType? keyboardType}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
        const SizedBox(height: 6),
        TextFormField(
          controller: ctrl,
          keyboardType: keyboardType,
          decoration: InputDecoration(hintText: label.replaceAll(' *', '')),
          validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
        ),
      ],
    );
  }
}
