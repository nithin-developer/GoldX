import 'dart:typed_data';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:signalpro/app/localization/app_localizations.dart';
import 'package:signalpro/app/services/api_exception.dart';
import 'package:signalpro/app/services/auth_scope.dart';
import 'package:signalpro/app/services/verification_api.dart';
import 'package:signalpro/app/theme/app_colors.dart';
import 'package:signalpro/app/widgets/auth_language_switcher.dart';

class VerificationPage extends StatefulWidget {
  const VerificationPage({required this.onApproved, super.key});

  final Future<void> Function() onApproved;

  @override
  State<VerificationPage> createState() => _VerificationPageState();
}

class _VerificationPageState extends State<VerificationPage> {
  final ImagePicker _imagePicker = ImagePicker();

  VerificationApi? _verificationApi;
  VerificationStatusData? _verificationStatus;

  XFile? _idDocument;
  XFile? _selfieDocument;

  Uint8List? _idDocumentPreviewBytes;
  Uint8List? _selfieDocumentPreviewBytes;

  bool _isLoadingStatus = true;
  bool _isSubmitting = false;
  bool _isPickingId = false;
  bool _isPickingSelfie = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _verificationApi ??= VerificationApi(
      dio: AuthScope.of(context).apiClient.dio,
    );

    if (_isLoadingStatus) {
      _loadVerificationStatus();
    }
  }

  Future<void> _loadVerificationStatus() async {
    try {
      final status = await _verificationApi!.getStatus();
      if (!mounted) {
        return;
      }

      setState(() => _verificationStatus = status);

      if (status.isApproved) {
        await widget.onApproved();
      }
    } on ApiException catch (error) {
      _showMessage(error.message);
    } finally {
      if (mounted) {
        setState(() => _isLoadingStatus = false);
      }
    }
  }

  Future<void> _pickIdDocument() async {
    if (_isPickingId || _isSubmitting) {
      return;
    }

    setState(() => _isPickingId = true);

    try {
      final selected = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 60,
        maxWidth: 1080,
        maxHeight: 1080,
      );

      if (!mounted) {
        return;
      }

      if (selected == null) {
        return;
      }

      final previewBytes = await selected.readAsBytes();
      if (!mounted) {
        return;
      }

      setState(() {
        _idDocument = selected;
        _idDocumentPreviewBytes = previewBytes;
      });
    } finally {
      if (mounted) {
        setState(() => _isPickingId = false);
      }
    }
  }

  Future<void> _pickSelfieDocument() async {
    if (_isPickingSelfie || _isSubmitting) {
      return;
    }

    setState(() => _isPickingSelfie = true);

    try {
      final selected = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 60,
        maxWidth: 1080,
        maxHeight: 1080,
      );

      if (!mounted) {
        return;
      }

      if (selected == null) {
        return;
      }

      final previewBytes = await selected.readAsBytes();
      if (!mounted) {
        return;
      }

      setState(() {
        _selfieDocument = selected;
        _selfieDocumentPreviewBytes = previewBytes;
      });
    } finally {
      if (mounted) {
        setState(() => _isPickingSelfie = false);
      }
    }
  }

  Future<void> _submitVerification() async {
    final l10n = context.l10n;
    final status = _verificationStatus?.status;

    if (status == 'pending') {
      _showMessage(l10n.tr('Your verification request is under review.'));
      return;
    }

    if (_idDocument == null || _selfieDocument == null) {
      _showMessage(l10n.tr('Please upload both required documents.'));
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final response = await _verificationApi!.submitVerification(
        idDocument: _idDocument!,
        selfieDocument: _selfieDocument!,
      );

      if (!mounted) {
        return;
      }

      setState(() => _verificationStatus = response);
      await AuthScope.of(context).reloadUser();
      _showMessage(
        l10n.tr('Documents submitted successfully. Await admin review.'),
      );
    } on ApiException catch (error) {
      _showMessage(error.message);
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  void _showMessage(String message) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'approved':
        return AppColors.success;
      case 'pending':
        return AppColors.highlight;
      case 'rejected':
        return AppColors.danger;
      default:
        return AppColors.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final status = _verificationStatus?.status ?? 'not_submitted';
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.background,
              AppColors.surfaceSoft,
              AppColors.backgroundSecondary,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: AnimatedPadding(
              duration: const Duration(milliseconds: 260),
              curve: Curves.easeOut,
              padding: EdgeInsets.only(bottom: bottomInset > 0 ? 8 : 0),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return ScrollConfiguration(
                    behavior: const MaterialScrollBehavior().copyWith(
                      scrollbars: false,
                      dragDevices: <PointerDeviceKind>{
                        PointerDeviceKind.touch,
                        PointerDeviceKind.mouse,
                        PointerDeviceKind.stylus,
                        PointerDeviceKind.unknown,
                      },
                    ),
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(
                        parent: AlwaysScrollableScrollPhysics(),
                      ),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: constraints.maxHeight,
                        ),
                        child: IntrinsicHeight(
                          child: Column(
                            children: [
                              const Align(
                                alignment: AlignmentDirectional.centerEnd,
                                child: AuthLanguageSwitcher(),
                              ),
                              const Spacer(),
                              const Center(
                                child: Image(
                                  image: AssetImage('assets/logo.png'),
                                  width: 200,
                                ),
                              ),
                              const SizedBox(height: 20),
                              TweenAnimationBuilder<double>(
                                duration: const Duration(milliseconds: 500),
                                curve: Curves.easeOutCubic,
                                tween: Tween<double>(begin: 20, end: 0),
                                builder: (context, offsetY, child) {
                                  return Transform.translate(
                                    offset: Offset(0, offsetY),
                                    child: AnimatedOpacity(
                                      duration: const Duration(
                                        milliseconds: 500,
                                      ),
                                      opacity: 1,
                                      child: child,
                                    ),
                                  );
                                },
                                child: ConstrainedBox(
                                  constraints: const BoxConstraints(
                                    maxWidth: 460,
                                  ),
                                  child: Container(
                                    padding: const EdgeInsets.all(22),
                                    decoration: BoxDecoration(
                                      color: AppColors.surface.withValues(
                                        alpha: 0.88,
                                      ),
                                      borderRadius: BorderRadius.circular(28),
                                      border: Border.all(
                                        color: AppColors.border,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: AppColors.primary.withValues(
                                            alpha: 0.10,
                                          ),
                                          blurRadius: 30,
                                          spreadRadius: -10,
                                        ),
                                      ],
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Center(
                                          child: Text(
                                            l10n.tr('Account Verification'),
                                            style: const TextStyle(
                                              fontSize: 32,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Center(
                                          child: Text(
                                            l10n.tr(
                                              'Upload your documents to activate dashboard access.',
                                            ),
                                            textAlign: TextAlign.center,
                                            style: const TextStyle(
                                              color: AppColors.textSecondary,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 12),
                                        Container(
                                          width: double.infinity,
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 10,
                                          ),
                                          decoration: BoxDecoration(
                                            color: AppColors.surfaceSoft
                                                .withValues(alpha: 0.65),
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                            border: Border.all(
                                              color: AppColors.border
                                                  .withValues(alpha: 0.60),
                                            ),
                                          ),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                l10n.tr('Upload instructions'),
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.w700,
                                                  color: AppColors.textPrimary,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                l10n.tr(
                                                  'Allowed formats: JPG, JPEG, PNG, WEBP.',
                                                ),
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                  color:
                                                      AppColors.textSecondary,
                                                ),
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                l10n.tr(
                                                  'Use images less than 2MB for best results (maximum 4MB per file).',
                                                ),
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                  color:
                                                      AppColors.textSecondary,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(height: 16),
                                        Wrap(
                                          alignment: WrapAlignment.center,
                                          spacing: 8,
                                          runSpacing: 8,
                                          children: [
                                            Chip(
                                              label: Text(
                                                l10n.tr(
                                                  'Status: {status}',
                                                  params: {
                                                    'status': status
                                                        .toUpperCase(),
                                                  },
                                                ),
                                              ),
                                              backgroundColor: _statusColor(
                                                status,
                                              ).withValues(alpha: 0.15),
                                              side: BorderSide(
                                                color: _statusColor(
                                                  status,
                                                ).withValues(alpha: 0.45),
                                              ),
                                            ),
                                            if (_verificationStatus
                                                    ?.submittedAt !=
                                                null)
                                              Chip(
                                                label: Text(
                                                  l10n.tr(
                                                    'Submitted for review',
                                                  ),
                                                ),
                                                backgroundColor:
                                                    AppColors.surfaceSoft,
                                              ),
                                          ],
                                        ),
                                        if (_verificationStatus
                                                    ?.rejectionReason !=
                                                null &&
                                            _verificationStatus!
                                                .rejectionReason!
                                                .isNotEmpty) ...[
                                          const SizedBox(height: 12),
                                          Container(
                                            width: double.infinity,
                                            padding: const EdgeInsets.all(12),
                                            decoration: BoxDecoration(
                                              color: AppColors.danger
                                                  .withValues(alpha: 0.10),
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                              border: Border.all(
                                                color: AppColors.danger
                                                    .withValues(alpha: 0.25),
                                              ),
                                            ),
                                            child: Text(
                                              l10n.tr(
                                                'Rejection reason: {reason}',
                                                params: {
                                                  'reason': _verificationStatus!
                                                      .rejectionReason!,
                                                },
                                              ),
                                              style: const TextStyle(
                                                color: AppColors.danger,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                        ],
                                        const SizedBox(height: 18),
                                        _UploadTile(
                                          title: l10n.tr(
                                            'ID DOCUMENT (PASSPORT / LICENSE)',
                                          ),
                                          hint: l10n.tr(
                                            'Upload clear front-side document image',
                                          ),
                                          fileName: _idDocument?.name,
                                          previewBytes: _idDocumentPreviewBytes,
                                          isBusy: _isPickingId,
                                          onTap: _pickIdDocument,
                                        ),
                                        const SizedBox(height: 12),
                                        _UploadTile(
                                          title: l10n.tr(
                                            'SELFIE / USER PICTURE',
                                          ),
                                          hint: l10n.tr(
                                            'Upload a clear selfie or live face picture',
                                          ),
                                          fileName: _selfieDocument?.name,
                                          previewBytes:
                                              _selfieDocumentPreviewBytes,
                                          isBusy: _isPickingSelfie,
                                          onTap: _pickSelfieDocument,
                                        ),
                                        const SizedBox(height: 18),
                                        SizedBox(
                                          width: double.infinity,
                                          height: 52,
                                          child: ElevatedButton(
                                            onPressed:
                                                (_isSubmitting ||
                                                    _isLoadingStatus ||
                                                    status == 'pending' ||
                                                    status == 'approved')
                                                ? null
                                                : _submitVerification,
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor:
                                                  AppColors.primary,
                                              foregroundColor:
                                                  AppColors.background,
                                              disabledBackgroundColor:
                                                  AppColors.surfaceSoft,
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(14),
                                              ),
                                            ),
                                            child: _isSubmitting
                                                ? const SizedBox(
                                                    width: 18,
                                                    height: 18,
                                                    child: CircularProgressIndicator(
                                                      strokeWidth: 2,
                                                      valueColor:
                                                          AlwaysStoppedAnimation<
                                                            Color
                                                          >(
                                                            AppColors
                                                                .background,
                                                          ),
                                                    ),
                                                  )
                                                : Text(
                                                    l10n.tr(
                                                      'Submit Verification Documents',
                                                    ),
                                                    style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.w700,
                                                    ),
                                                  ),
                                          ),
                                        ),
                                        const SizedBox(height: 10),
                                        Align(
                                          alignment:
                                              AlignmentDirectional.center,
                                          child: TextButton.icon(
                                            onPressed: _isLoadingStatus
                                                ? null
                                                : _loadVerificationStatus,
                                            icon: _isLoadingStatus
                                                ? const SizedBox(
                                                    width: 14,
                                                    height: 14,
                                                    child:
                                                        CircularProgressIndicator(
                                                          strokeWidth: 2,
                                                        ),
                                                  )
                                                : const Icon(
                                                    Icons.refresh_rounded,
                                                    size: 18,
                                                  ),
                                            label: Text(
                                              l10n.tr('Refresh Status'),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Align(
                                          alignment:
                                              AlignmentDirectional.center,
                                          child: TextButton(
                                            onPressed: _isSubmitting
                                                ? null
                                                : () => AuthScope.of(
                                                    context,
                                                  ).logout(),
                                            child: Text(
                                              l10n.tr('Logout'),
                                              style: const TextStyle(
                                                color: AppColors.textSecondary,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              const Spacer(),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  _Foot(
                                    text: l10n.tr(
                                      '\u00A9 {year} GoldX. All rights reserved.',
                                      params: <String, String>{
                                        'year': DateTime.now().year.toString(),
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _UploadTile extends StatelessWidget {
  const _UploadTile({
    required this.title,
    required this.hint,
    required this.fileName,
    required this.previewBytes,
    required this.isBusy,
    required this.onTap,
  });

  final String title;
  final String hint;
  final String? fileName;
  final Uint8List? previewBytes;
  final bool isBusy;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final hasFile = fileName != null && fileName!.trim().isNotEmpty;
    final hasPreview = previewBytes != null && previewBytes!.isNotEmpty;

    return InkWell(
      onTap: isBusy ? null : onTap,
      borderRadius: BorderRadius.circular(14),
      child: Ink(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: hasFile
                ? AppColors.success.withValues(alpha: 0.35)
                : AppColors.border.withValues(alpha: 0.65),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: hasFile
                    ? AppColors.success.withValues(alpha: 0.15)
                    : AppColors.surfaceSoft,
                borderRadius: BorderRadius.circular(10),
              ),
              child: hasPreview
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.memory(
                        previewBytes!,
                        fit: BoxFit.cover,
                        gaplessPlayback: true,
                      ),
                    )
                  : Icon(
                      hasFile ? Icons.check_rounded : Icons.upload_file_rounded,
                      color: hasFile ? AppColors.success : AppColors.textMuted,
                    ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 11,
                      letterSpacing: 1.1,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    hasFile ? fileName! : hint,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: hasFile
                          ? AppColors.textPrimary
                          : AppColors.textSecondary,
                      fontWeight: hasFile ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
            if (isBusy)
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textMuted,
              ),
          ],
        ),
      ),
    );
  }
}

class _Foot extends StatelessWidget {
  const _Foot({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 10,
        color: AppColors.textMuted,
        letterSpacing: 1,
      ),
    );
  }
}
