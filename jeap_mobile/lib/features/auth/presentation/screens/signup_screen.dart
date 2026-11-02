import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:jeap_mobile/core/theme/app_theme.dart';
import 'package:jeap_mobile/core/widgets/jeap_app_bar.dart';
import 'package:jeap_mobile/core/widgets/primary_button.dart';
import 'package:jeap_mobile/features/auth/models/registration_data.dart';
import 'package:jeap_mobile/features/auth/presentation/screens/confirm_details_screen.dart';

// ---------------------------------------------------------------------------
// PSGC-style dependent address data
// ---------------------------------------------------------------------------
const _addressData = {
  'Metro Manila': {
    'Quezon City': ['Batasan Hills', 'Commonwealth', 'Diliman', 'Fairview'],
    'Manila': ['Binondo', 'Ermita', 'Malate', 'Paco', 'Sampaloc'],
    'Makati': ['Bel-Air', 'Forbes Park', 'Poblacion', 'San Lorenzo'],
    'Taguig': ['BGC', 'Hagonoy', 'Ligid-Tipas', 'Ususan'],
  },
  'Laguna': {
    'Santa Cruz': ['Barangay 1', 'Barangay 2', 'Barangay 3', 'Barangay 4'],
    'Los Baños': ['Anos', 'Bagong Silang', 'Bambang', 'Batong Malake'],
    'Lumban': ['Barangay 1', 'Barangay 2', 'Caliraya', 'Lewin'],
    'Pagsanjan': ['Anibong', 'Barangay 1', 'Ibaba', 'Ilaya'],
  },
  'Cavite': {
    'Bacoor': ['Bayanan', 'Habay', 'Ligas', 'Molino'],
    'Dasmariñas': ['Burol', 'Paliparan', 'Salawag', 'Sampaloc'],
    'Imus': ['Alapan', 'Buhay na Tubig', 'Malagasang', 'Tanzang Luma'],
  },
  'Batangas': {
    'Batangas City': ['Balagtas', 'Cuta', 'Kumintang Ibaba', 'Pallocan'],
    'Lipa': ['Anilao', 'Balintawak', 'Banaybanay', 'Dagatan'],
    'Tanauan': ['Ambulong', 'Bagbag', 'Cale', 'Gonzales'],
  },
};

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _scrollController = ScrollController();

  // Personal info
  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _middleInitialCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _mobileCtrl = TextEditingController();
  final _dobCtrl = TextEditingController();
  final _ageCtrl = TextEditingController();
  String? _gender;

  // Address — dropdown
  String? _province;
  String? _city;
  String? _barangay;

  // Address — manual
  final _houseNumberCtrl = TextEditingController();
  final _streetCtrl = TextEditingController();
  final _subdivisionCtrl = TextEditingController();
  final _buildingUnitCtrl = TextEditingController();
  final _otherDetailsCtrl = TextEditingController();
  final _zipCtrl = TextEditingController();

  // ID
  File? _idImage;

  // Password
  final _passwordCtrl = TextEditingController();
  final _confirmPasswordCtrl = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _agreedToTerms = false;

  static const _genders = ['Male', 'Female', 'Prefer not to say'];

  List<String> get _provinces => _addressData.keys.toList();
  List<String> get _cities =>
      _province != null ? _addressData[_province]!.keys.toList() : [];
  List<String> get _barangays => (_province != null && _city != null)
      ? _addressData[_province]![_city]!
      : [];

  bool get _hasUnsavedChanges =>
      _firstNameCtrl.text.isNotEmpty ||
      _lastNameCtrl.text.isNotEmpty ||
      _middleInitialCtrl.text.isNotEmpty ||
      _emailCtrl.text.isNotEmpty ||
      _mobileCtrl.text.isNotEmpty ||
      _dobCtrl.text.isNotEmpty ||
      _province != null ||
      _city != null ||
      _barangay != null ||
      _houseNumberCtrl.text.isNotEmpty ||
      _streetCtrl.text.isNotEmpty ||
      _zipCtrl.text.isNotEmpty ||
      _idImage != null ||
      _passwordCtrl.text.isNotEmpty;

  @override
  void dispose() {
    _scrollController.dispose();
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _middleInitialCtrl.dispose();
    _emailCtrl.dispose();
    _mobileCtrl.dispose();
    _dobCtrl.dispose();
    _ageCtrl.dispose();
    _houseNumberCtrl.dispose();
    _streetCtrl.dispose();
    _subdivisionCtrl.dispose();
    _buildingUnitCtrl.dispose();
    _otherDetailsCtrl.dispose();
    _zipCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmPasswordCtrl.dispose();
    super.dispose();
  }

  Future<bool> _showDiscardDialog() async {
    if (!_hasUnsavedChanges) return true;
    final discard = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Discard Changes?'),
        content: const Text(
          'You have unsaved information on this form. Leaving will discard your registration progress.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Keep Editing'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Discard'),
          ),
        ],
      ),
    );
    return discard ?? false;
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final eighteenYearsAgo = DateTime(now.year - 18, now.month, now.day);
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2000, 1, 1),
      firstDate: DateTime(1920),
      lastDate: eighteenYearsAgo,
      helpText: 'Select Birthday (Must be at least 18 years old)',
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(primary: AppTheme.jeapPurple),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      _dobCtrl.text =
          '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
      final age = _calculateAge(picked);
      _ageCtrl.text = age.toString();
    }
  }

  int _calculateAge(DateTime dob) {
    final now = DateTime.now();
    int age = now.year - dob.year;
    if (now.month < dob.month ||
        (now.month == dob.month && now.day < dob.day)) {
      age--;
    }
    return age;
  }

  Future<void> _pickIdImage() async {
    final picker = ImagePicker();
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.borderColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined,
                  color: AppTheme.jeapPurple),
              title: const Text('Take a Photo'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined,
                  color: AppTheme.jeapPurple),
              title: const Text('Choose from Gallery'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (source == null) return;
    final picked = await picker.pickImage(source: source, imageQuality: 85);
    if (picked == null) return;

    final file = File(picked.path);
    final sizeInBytes = await file.length();
    // Maximum document upload size is 5 MB (5,242,880 bytes)
    if (sizeInBytes > 5 * 1024 * 1024) {
      if (mounted) {
        _showError('The uploaded file exceeds the 5 MB maximum size limit.');
      }
      return;
    }

    if (mounted) {
      setState(() => _idImage = file);
    }
  }

  void _handleContinue() {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please fix the errors before continuing.')),
      );
      return;
    }
    if (_gender == null) {
      _showError('Please select your gender.');
      return;
    }
    if (_province == null || _city == null || _barangay == null) {
      _showError('Please complete your address (Province, City, Barangay).');
      return;
    }
    if (_idImage == null) {
      _showError('Please upload a valid ID (front side).');
      return;
    }
    if (!_agreedToTerms) {
      _showError('Please agree to the Terms & Conditions.');
      return;
    }

    final rawPhone = _mobileCtrl.text.replaceAll(RegExp(r'[\s\-]'), '');
    final normalizedPhone = rawPhone.startsWith('09')
        ? '+63${rawPhone.substring(1)}'
        : rawPhone;

    final data = RegistrationData(
      firstName: _firstNameCtrl.text.trim(),
      lastName: _lastNameCtrl.text.trim(),
      middleInitial: _middleInitialCtrl.text.trim().isNotEmpty
          ? _middleInitialCtrl.text.trim()
          : null,
      email: _emailCtrl.text.trim(),
      mobileNumber: normalizedPhone,
      dateOfBirth: _dobCtrl.text.isNotEmpty ? _dobCtrl.text.trim() : null,
      age: _ageCtrl.text.isNotEmpty ? int.tryParse(_ageCtrl.text) : null,
      gender: _gender!,
      province: _province!,
      city: _city!,
      barangay: _barangay!,
      houseNumber: _houseNumberCtrl.text.trim(),
      street: _streetCtrl.text.trim(),
      subdivision: _subdivisionCtrl.text.trim().isNotEmpty
          ? _subdivisionCtrl.text.trim()
          : null,
      buildingUnit: _buildingUnitCtrl.text.trim().isNotEmpty
          ? _buildingUnitCtrl.text.trim()
          : null,
      otherDetails: _otherDetailsCtrl.text.trim().isNotEmpty
          ? _otherDetailsCtrl.text.trim()
          : null,
      zipCode: _zipCtrl.text.trim(),
      idImagePath: _idImage!.path,
      password: _passwordCtrl.text,
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ConfirmDetailsScreen(registrationData: data),
      ),
    );
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_hasUnsavedChanges,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final discard = await _showDiscardDialog();
        if (discard && context.mounted) {
          Navigator.pop(context);
        }
      },
      child: Scaffold(
        backgroundColor: AppTheme.backgroundColor,
        appBar: const JeapAppBar(),
        body: SafeArea(
          child: GestureDetector(
            onTap: () => FocusScope.of(context).unfocus(),
            behavior: HitTestBehavior.opaque,
            child: SingleChildScrollView(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),
                    const Text('Sign Up',
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textSecondary)),
                    const SizedBox(height: 4),
                    const Text('Create your JEAP account',
                        style:
                            TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text('Fill in your details to get started.',
                              style: TextStyle(
                                  fontSize: 12, color: AppTheme.textSecondary)),
                        ),
                        Text('Step 1 of 2',
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.jeapPurple)),
                      ],
                    ),
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: const LinearProgressIndicator(
                        value: 0.5,
                        minHeight: 6,
                        backgroundColor: AppTheme.borderColor,
                        color: AppTheme.jeapPurple,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // ── PERSONAL INFORMATION ──────────────────────────
                    const _SectionLabel('PERSONAL INFORMATION'),
                    const SizedBox(height: 12),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: _field(
                            'Last Name *',
                            _lastNameCtrl,
                            hint: 'Dela Cruz',
                            textCapitalization: TextCapitalization.words,
                            maxLength: 50,
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) {
                                return 'Last name is required';
                              }
                              final trimmed = v.trim();
                              if (trimmed.length < 2 || trimmed.length > 50) {
                                return 'Must be 2–50 characters';
                              }
                              if (!RegExp(r"^[\p{L}\s\-'\.]+$", unicode: true)
                                  .hasMatch(trimmed)) {
                                return 'Letters only';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _field(
                            'First Name *',
                            _firstNameCtrl,
                            hint: 'Juan',
                            textCapitalization: TextCapitalization.words,
                            maxLength: 50,
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) {
                                return 'First name is required';
                              }
                              final trimmed = v.trim();
                              if (trimmed.length < 2 || trimmed.length > 50) {
                                return 'Must be 2–50 characters';
                              }
                              if (!RegExp(r"^[\p{L}\s\-'\.]+$", unicode: true)
                                  .hasMatch(trimmed)) {
                                return 'Letters only';
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 90,
                          child: _field(
                            'M.I.',
                            _middleInitialCtrl,
                            hint: 'A',
                            maxLength: 2,
                            required: false,
                            textCapitalization: TextCapitalization.characters,
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z]')),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _dropdown('Sex *', _gender, _genders,
                              (v) => setState(() => _gender = v)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _field(
                      'E-mail *',
                      _emailCtrl,
                      hint: 'juan@example.com',
                      keyboardType: TextInputType.emailAddress,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'Email is required';
                        }
                        final emailRegex =
                            RegExp(r'^[\w\-.]+@[\w\-]+\.[a-zA-Z]{2,}$');
                        if (!emailRegex.hasMatch(v.trim())) {
                          return 'Enter a valid email address';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    _field(
                      'Contact Number *',
                      _mobileCtrl,
                      hint: '09XXXXXXXXX or +639XXXXXXXXX',
                      keyboardType: TextInputType.phone,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[0-9+]')),
                      ],
                      maxLength: 13,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'Contact number is required';
                        }
                        final clean = v.replaceAll(RegExp(r'[\s\-]'), '');
                        if (!RegExp(r'^(09|\+639)\d{9}$').hasMatch(clean)) {
                          return 'Enter valid PH mobile (09XXXXXXXXX or +639XXXXXXXXX)';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: _field(
                            'Birthday *',
                            _dobCtrl,
                            hint: 'YYYY-MM-DD',
                            readOnly: true,
                            onTap: _pickDate,
                            suffixIcon: const Icon(Icons.calendar_today,
                                size: 18, color: AppTheme.textSecondary),
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) {
                                return 'Birthday is required';
                              }
                              final age = int.tryParse(_ageCtrl.text);
                              if (age == null || age < 18) {
                                return 'Must be at least 18 years old';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        SizedBox(
                          width: 80,
                          child: _field('Age', _ageCtrl,
                              hint: '—', readOnly: true, required: false),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // ── ADDRESS — DROPDOWN ────────────────────────────
                    const _SectionLabel('ADDRESS'),
                    const SizedBox(height: 4),
                    const Text('Select your location',
                        style:
                            TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                    const SizedBox(height: 12),
                    _dropdown('Province *', _province, _provinces, (v) {
                      setState(() {
                        _province = v;
                        _city = null;
                        _barangay = null;
                      });
                    }),
                    const SizedBox(height: 12),
                    _dropdown(
                      'Municipality / City *',
                      _city,
                      _cities,
                      _province == null
                          ? null
                          : (v) {
                              setState(() {
                                _city = v;
                                _barangay = null;
                              });
                            },
                    ),
                    const SizedBox(height: 12),
                    _dropdown(
                      'Barangay *',
                      _barangay,
                      _barangays,
                      _city == null
                          ? null
                          : (v) => setState(() => _barangay = v),
                    ),
                    const SizedBox(height: 16),
                    const Text('Manual Address',
                        style:
                            TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                    const SizedBox(height: 8),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: _field(
                            'House No. *',
                            _houseNumberCtrl,
                            hint: '123',
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _field(
                            'Street *',
                            _streetCtrl,
                            hint: 'Main Street',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _field('Subdivision / Village', _subdivisionCtrl,
                        hint: 'e.g. Sunrise Village', required: false),
                    const SizedBox(height: 12),
                    _field('Building / Unit / Floor', _buildingUnitCtrl,
                        hint: 'e.g. Unit 4B, 2nd Floor', required: false),
                    const SizedBox(height: 12),
                    _field('Other Address Details', _otherDetailsCtrl,
                        hint: 'Landmark, notes, etc.', required: false),
                    const SizedBox(height: 12),
                    _field(
                      'ZIP Code *',
                      _zipCtrl,
                      hint: '4000',
                      keyboardType: TextInputType.number,
                      maxLength: 4,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'ZIP code is required';
                        }
                        if (!RegExp(r'^\d{4}$').hasMatch(v.trim())) {
                          return 'Enter valid 4-digit ZIP code';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),

                    // ── IDENTIFICATION ────────────────────────────────
                    const _SectionLabel('IDENTIFICATION'),
                    const SizedBox(height: 4),
                    const Text('Upload a valid government-issued ID (front side, max 5 MB).',
                        style:
                            TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                    const SizedBox(height: 12),
                    _IdUploadWidget(
                      image: _idImage,
                      onPick: _pickIdImage,
                      onRemove: () => setState(() => _idImage = null),
                    ),
                    const SizedBox(height: 24),

                    // ── ACCOUNT SECURITY ──────────────────────────────
                    const _SectionLabel('ACCOUNT SECURITY'),
                    const SizedBox(height: 12),
                    _field(
                      'Password *',
                      _passwordCtrl,
                      hint: '••••••••',
                      obscure: _obscurePassword,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                          size: 20,
                        ),
                        onPressed: () =>
                            setState(() => _obscurePassword = !_obscurePassword),
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) {
                          return 'Password is required';
                        }
                        if (v.length < 8) {
                          return 'At least 8 characters';
                        }
                        if (!RegExp(r'[A-Z]').hasMatch(v)) {
                          return 'Include at least one uppercase letter';
                        }
                        if (!RegExp(r'[a-z]').hasMatch(v)) {
                          return 'Include at least one lowercase letter';
                        }
                        if (!RegExp(r'[0-9]').hasMatch(v)) {
                          return 'Include at least one number';
                        }
                        if (!RegExp(r'[!@#\$%^&*(),.?":{}|<>\-_=+\/\[\]~]').hasMatch(v)) {
                          return 'Include at least one special character';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'At least 8 characters with uppercase, lowercase, number, and special character.',
                      style:
                          TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                    ),
                    const SizedBox(height: 12),
                    _field(
                      'Confirm Password *',
                      _confirmPasswordCtrl,
                      hint: '••••••••',
                      obscure: _obscureConfirm,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureConfirm
                              ? Icons.visibility_off
                              : Icons.visibility,
                          size: 20,
                        ),
                        onPressed: () =>
                            setState(() => _obscureConfirm = !_obscureConfirm),
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) {
                          return 'Please confirm your password';
                        }
                        if (v != _passwordCtrl.text) {
                          return 'Passwords do not match';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Checkbox(
                          value: _agreedToTerms,
                          activeColor: AppTheme.jeapPurple,
                          onChanged: (v) =>
                              setState(() => _agreedToTerms = v ?? false),
                        ),
                        const Expanded(
                          child: Padding(
                            padding: EdgeInsets.only(top: 12),
                            child: Text(
                                'I agree to the Terms & Conditions and Privacy Policy.',
                                style: TextStyle(fontSize: 12)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    PrimaryButton(label: 'CONTINUE', onPressed: _handleContinue),
                    const SizedBox(height: 28),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _field(
    String label,
    TextEditingController ctrl, {
    String? hint,
    TextInputType? keyboardType,
    bool obscure = false,
    bool readOnly = false,
    bool required = true,
    int? maxLength,
    TextCapitalization textCapitalization = TextCapitalization.none,
    List<TextInputFormatter>? inputFormatters,
    VoidCallback? onTap,
    Widget? suffixIcon,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
        const SizedBox(height: 6),
        TextFormField(
          controller: ctrl,
          keyboardType: keyboardType,
          obscureText: obscure,
          readOnly: readOnly,
          onTap: onTap,
          maxLength: maxLength,
          textCapitalization: textCapitalization,
          inputFormatters: inputFormatters,
          buildCounter: maxLength != null
              ? (_, {required currentLength, required isFocused, maxLength}) =>
                  null
              : null,
          decoration: InputDecoration(hintText: hint, suffixIcon: suffixIcon),
          validator: validator ??
              (v) {
                if (required && (v == null || v.trim().isEmpty)) {
                  return 'Required';
                }
                return null;
              },
        ),
      ],
    );
  }

  Widget _dropdown(
    String label,
    String? value,
    List<String> options,
    ValueChanged<String?>? onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          initialValue: value,
          isExpanded: true,
          decoration: InputDecoration(
            hintText: onChanged == null
                ? 'Select ${label.replaceAll(' *', '').toLowerCase()} first'
                : 'Select ${label.replaceAll(' *', '').toLowerCase()}',
          ),
          items: options
              .map((o) => DropdownMenuItem(
                  value: o,
                  child: Text(o, overflow: TextOverflow.ellipsis, maxLines: 1)))
              .toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }
}

// ── ID Upload Widget ─────────────────────────────────────────────────────────
class _IdUploadWidget extends StatelessWidget {
  final File? image;
  final VoidCallback onPick;
  final VoidCallback onRemove;

  const _IdUploadWidget(
      {required this.image, required this.onPick, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    if (image != null) {
      return Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(AppTheme.buyerRadius),
            child: Image.file(image!,
                width: double.infinity, height: 180, fit: BoxFit.cover),
          ),
          Positioned(
            top: 8,
            right: 8,
            child: GestureDetector(
              onTap: onRemove,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(
                    color: Colors.black54, shape: BoxShape.circle),
                child: const Icon(Icons.close, color: Colors.white, size: 18),
              ),
            ),
          ),
          Positioned(
            bottom: 8,
            right: 8,
            child: GestureDetector(
              onTap: onPick,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.jeapPurple,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text('Replace',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600)),
              ),
            ),
          ),
        ],
      );
    }

    return GestureDetector(
      onTap: onPick,
      child: Container(
        width: double.infinity,
        height: 140,
        decoration: BoxDecoration(
          color: AppTheme.inputFill,
          borderRadius: BorderRadius.circular(AppTheme.buyerRadius),
          border:
              Border.all(color: AppTheme.borderColor, style: BorderStyle.solid),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.upload_file_outlined,
                size: 36, color: AppTheme.jeapPurple),
            SizedBox(height: 8),
            Text('Tap to upload valid ID',
                style: TextStyle(
                    fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
            SizedBox(height: 4),
            Text('JPG, PNG accepted (Max 5 MB)',
                style: TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(text,
        style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: AppTheme.jeapPurple,
            letterSpacing: 0.5));
  }
}
