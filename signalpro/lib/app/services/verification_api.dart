import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';
import 'package:signalpro/app/config/api_config.dart';
import 'package:signalpro/app/services/api_exception.dart';

String? _resolveApiUrl(String? value) {
  final normalized = value?.trim();
  if (normalized == null || normalized.isEmpty) {
    return null;
  }

  final parsed = Uri.tryParse(normalized);
  if (parsed != null && parsed.hasScheme) {
    return normalized;
  }

  return Uri.parse(ApiConfig.baseUrl).resolve(normalized).toString();
}

DateTime? _parseNullableDate(dynamic value) {
  if (value == null) {
    return null;
  }

  final parsed = DateTime.tryParse(value.toString());
  return parsed;
}

class VerificationStatusData {
  const VerificationStatusData({
    required this.userId,
    required this.status,
    required this.idDocumentUrl,
    required this.selfieDocumentUrl,
    required this.submittedAt,
    required this.reviewedAt,
    required this.reviewedByAdminId,
    required this.rejectionReason,
  });

  final int userId;
  final String status;
  final String? idDocumentUrl;
  final String? selfieDocumentUrl;
  final DateTime? submittedAt;
  final DateTime? reviewedAt;
  final int? reviewedByAdminId;
  final String? rejectionReason;

  bool get isApproved => status == 'approved';

  factory VerificationStatusData.fromJson(Map<String, dynamic> json) {
    return VerificationStatusData(
      userId: int.tryParse(json['user_id'].toString()) ?? 0,
      status: (json['status'] as String? ?? 'not_submitted')
          .trim()
          .toLowerCase(),
      idDocumentUrl: _resolveApiUrl(json['id_document_url'] as String?),
      selfieDocumentUrl: _resolveApiUrl(
        (json['selfie_document_url'] ?? json['address_document_url'])
            as String?,
      ),
      submittedAt: _parseNullableDate(json['submitted_at']),
      reviewedAt: _parseNullableDate(json['reviewed_at']),
      reviewedByAdminId: json['reviewed_by_admin_id'] == null
          ? null
          : int.tryParse(json['reviewed_by_admin_id'].toString()),
      rejectionReason: (json['rejection_reason'] as String?)?.trim(),
    );
  }
}

class VerificationApi {
  const VerificationApi({required Dio dio}) : _dio = dio;

  final Dio _dio;

  Future<MultipartFile> _toMultipartFile(XFile file) async {
    final bytes = await file.readAsBytes();
    if (bytes.isEmpty) {
      throw ApiException(
        'Selected document is empty. Please choose another file.',
      );
    }

    return MultipartFile.fromBytes(bytes, filename: file.name);
  }

  Future<VerificationStatusData> getStatus() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/users/verification/status',
      );
      return VerificationStatusData.fromJson(response.data ?? const {});
    } on DioException catch (error) {
      throw mapDioError(error);
    }
  }

  Future<VerificationStatusData> submitVerification({
    required XFile idDocument,
    required XFile selfieDocument,
  }) async {
    final formData = FormData.fromMap({
      'id_document': await _toMultipartFile(idDocument),
      'selfie_document': await _toMultipartFile(selfieDocument),
    });

    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/users/verification/submit',
        data: formData,
      );
      return VerificationStatusData.fromJson(response.data ?? const {});
    } on DioException catch (error) {
      throw mapDioError(error);
    }
  }
}
