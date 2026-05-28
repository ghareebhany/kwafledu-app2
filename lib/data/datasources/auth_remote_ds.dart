import 'package:dio/dio.dart';
import '../../core/constants/api_constants.dart';
import '../../core/errors/failures.dart';
import '../../core/network/dio_client.dart';
import '../../core/utils/secure_storage.dart';
import '../models/user_model.dart';
import 'dio_helpers.dart';

class AuthRemoteDataSource {
  AuthRemoteDataSource._();
  static final AuthRemoteDataSource instance = AuthRemoteDataSource._();

  Dio get _dio => DioClient.instance.dio;

  Future<UserModel> login(String username, String password) async {
    try {
      final res = await _dio.post(
        ApiConstants.loginEndpoint,
        data: {'username': username, 'password': password},
        options: Options(
          contentType: Headers.jsonContentType,
          extra: {'skipAuth': true},
        ),
      );
      final body = res.data as Map<String, dynamic>? ?? {};
      if (body.containsKey('code') && !body.containsKey('token')) {
        final msg    = body['message'] as String? ?? 'خطأ في تسجيل الدخول';
        final status = (body['data'] as Map?)?['status'] as int? ?? 401;
        throw ServerFailure(msg, statusCode: status);
      }
      if (body['token'] == null) {
        throw const ServerFailure('لم يتم إرسال رمز المصادقة من الخادم');
      }
      return UserModel.fromLoginJson(body);
    } on DioException catch (e) {
      return handleDioError(e);
    }
  }

  /// Fetches WP nonce, sets it on DioClient, and persists it to SecureStorage.
  /// Tutor LMS Pro /students/{id}/dashboard + /courses require X-WP-Nonce.
  /// Non-blocking — JWT alone may work on some configurations.
  Future<void> fetchNonce() async {
    try {
      final res = await _dio.get(ApiConstants.nonceEndpoint);
      final body = res.data;
      String? nonce;
      if (body is Map) {
        nonce = body['nonce'] as String? ??
            (body['data'] as Map?)?['nonce'] as String?;
      }
      if (nonce != null && nonce.isNotEmpty) {
        DioClient.instance.setNonce(nonce);
        await SecureStorageService.instance.saveNonce(nonce);
      }
    } catch (_) {
      // non-blocking — auth still works via JWT
    }
  }
}
