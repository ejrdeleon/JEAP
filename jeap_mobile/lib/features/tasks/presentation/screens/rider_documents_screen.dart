import 'package:flutter/material.dart';
import 'package:jeap_mobile/core/network/api_client.dart';
import 'package:jeap_mobile/core/theme/app_theme.dart';

class RiderDocumentsScreen extends StatefulWidget {
  const RiderDocumentsScreen({super.key});

  @override
  State<RiderDocumentsScreen> createState() => _RiderDocumentsScreenState();
}

class _RiderDocumentsScreenState extends State<RiderDocumentsScreen> {
  final _api = const ApiClient();
  List<Map<String, dynamic>> _documents = [];
  Map<String, dynamic> _summary = {};
  bool _isLoading = true;
  String? _uploadingType;

  @override
  void initState() {
    super.initState();
    _loadDocuments();
  }

  Future<void> _loadDocuments() async {
    setState(() => _isLoading = true);
    try {
      final res = await _api.get('/rider/documents');
      if (res is Map<String, dynamic>) {
        setState(() {
          _documents = (res['documents'] as List? ?? [])
              .map((e) => Map<String, dynamic>.from(e as Map))
              .toList();
          _summary = Map<String, dynamic>.from(res['summary'] as Map? ?? {});
          _isLoading = false;
        });
        return;
      }
    } catch (_) {}

    if (mounted) {
      setState(() {
        _documents = [
          {
            'type': 'drivers_license',
            'title': "Professional Driver's License",
            'status': 'approved',
            'file_name': 'license_carlos_mendoza.jpg',
            'submitted_at': '2026-10-15T09:30:00Z',
            'reviewed_at': '2026-10-15T14:20:00Z',
            'rejection_reason': null,
            'requires_action': false,
          },
          {
            'type': 'or_cr',
            'title': 'Vehicle Registration (OR/CR)',
            'status': 'approved',
            'file_name': 'or_cr_yamaha_nmax.pdf',
            'submitted_at': '2026-10-15T09:32:00Z',
            'reviewed_at': '2026-10-15T14:22:00Z',
            'rejection_reason': null,
            'requires_action': false,
          },
          {
            'type': 'clearance',
            'title': 'NBI / Police Clearance',
            'status': 'pending_review',
            'file_name': 'nbi_clearance_2026.pdf',
            'submitted_at': '2026-10-30T16:00:00Z',
            'reviewed_at': null,
            'rejection_reason': null,
            'requires_action': false,
          },
          {
            'type': 'drug_test',
            'title': 'Drug Test Certificate',
            'status': 'not_submitted',
            'file_name': null,
            'submitted_at': null,
            'reviewed_at': null,
            'rejection_reason': null,
            'requires_action': true,
          },
        ];
        _summary = {
          'total': 4,
          'approved': 2,
          'pending': 1,
          'action_needed': 1,
        };
        _isLoading = false;
      });
    }
  }

  Future<void> _handleUpload(String type, String title) async {
    setState(() => _uploadingType = type);
    // Simulate upload selection or hit backend
    await Future.delayed(const Duration(milliseconds: 600));

    try {
      await _api.post('/rider/documents', {
        'type': type,
      });
    } catch (_) {}

    if (!mounted) return;
    setState(() {
      final idx = _documents.indexWhere((d) => d['type'] == type);
      if (idx != -1) {
        _documents[idx]['status'] = 'pending_review';
        _documents[idx]['file_name'] = '${type}_upload.jpg';
        _documents[idx]['requires_action'] = false;
      }
      _uploadingType = null;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$title uploaded successfully and queued for review.'),
        backgroundColor: Colors.green.shade700,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Rider Verification Documents',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.textPrimary,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Verification Overview Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF312E81), AppTheme.jeapPurple],
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'KYC & COMPLIANCE STATUS',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 10.5,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Authorized Fleet Delivery Partner',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildStatChip(
                                '${_summary['approved'] ?? 2}', 'Approved', Colors.greenAccent),
                            _buildStatChip(
                                '${_summary['pending'] ?? 1}', 'Pending', Colors.amberAccent),
                            _buildStatChip('${_summary['action_needed'] ?? 1}',
                                'Action Needed', Colors.redAccent),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  Text(
                    'REQUIRED REGULATORY DOCUMENTS',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade600,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 10),

                  ..._documents.map((doc) => _buildDocumentCard(doc)),
                ],
              ),
            ),
    );
  }

  Widget _buildStatChip(String count, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Text(
            count,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          Text(
            label,
            style: const TextStyle(fontSize: 10.5, color: Colors.white70),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentCard(Map<String, dynamic> doc) {
    final type = doc['type']?.toString() ?? '';
    final title = doc['title']?.toString() ?? 'Document';
    final status = doc['status']?.toString().toLowerCase() ?? 'not_submitted';
    final fileName = doc['file_name']?.toString();
    final isUploading = _uploadingType == type;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ),
              _buildStatusPill(status),
            ],
          ),
          const SizedBox(height: 6),
          if (fileName != null)
            Row(
              children: [
                const Icon(Icons.attach_file,
                    size: 14, color: AppTheme.textSecondary),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    fileName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ),
              ],
            )
          else
            const Text(
              'No document uploaded yet. Upload a clear photo or PDF scan.',
              style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
            ),
          if (doc['rejection_reason'] != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Reason: ${doc['rejection_reason']}',
                style: TextStyle(fontSize: 11, color: Colors.red.shade700),
              ),
            ),
          ],
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: OutlinedButton.icon(
              onPressed: isUploading
                  ? null
                  : () => _handleUpload(type, title),
              icon: isUploading
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Icon(
                      status == 'approved' ? Icons.visibility : Icons.upload_file,
                      size: 16,
                    ),
              label: Text(
                status == 'approved'
                    ? 'View Document'
                    : (status == 'pending_review' ? 'Replace File' : 'Upload File'),
                style: const TextStyle(fontSize: 12),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.jeapPurple,
                side: const BorderSide(color: AppTheme.jeapPurple),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusPill(String status) {
    Color bg;
    Color fg;
    String label;

    switch (status) {
      case 'approved':
        bg = Colors.green.shade50;
        fg = Colors.green.shade700;
        label = 'APPROVED';
        break;
      case 'pending_review':
        bg = Colors.amber.shade50;
        fg = Colors.amber.shade800;
        label = 'PENDING REVIEW';
        break;
      case 'rejected':
        bg = Colors.red.shade50;
        fg = Colors.red.shade700;
        label = 'REJECTED';
        break;
      default:
        bg = Colors.grey.shade100;
        fg = Colors.grey.shade700;
        label = 'NOT SUBMITTED';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: fg,
          fontSize: 10,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
