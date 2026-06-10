import 'package:dio/dio.dart';
import '../models/venue.dart';
import '../models/slot.dart';
import '../models/booking.dart';

// ── Typed exceptions ──────────────────────────────────────────────────────────

class SlotTakenException implements Exception {
  const SlotTakenException();
}

class ApiException implements Exception {
  final int statusCode;
  final String message;
  const ApiException(this.statusCode, this.message);
}

class NetworkException implements Exception {
  const NetworkException();
}

// ── Client ────────────────────────────────────────────────────────────────────

class ApiClient {
  final Dio _dio;

  // getToken is called on every request so the interceptor always sends the
  // current token without requiring ApiClient to be recreated after login.
  ApiClient({required String baseUrl, required String? Function() getToken})
      : _dio = Dio(BaseOptions(baseUrl: baseUrl)) {
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        final token = getToken();
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
    ));
  }

  // ── Auth ──────────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> login(String email, String password) async {
    final res = await _send(
      () => _dio.post('/auth/login', data: {'email': email, 'password': password}),
    );
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> register(String email, String password) async {
    final res = await _send(
      () => _dio.post('/auth/register', data: {'email': email, 'password': password}),
    );
    return res.data as Map<String, dynamic>;
  }

  // ── Venues / Slots / Bookings ─────────────────────────────────────────────

  Future<List<Venue>> getVenues() async {
    final res = await _send(() => _dio.get('/venues'));
    return (res.data as List).map((e) => Venue.fromJson(e)).toList();
  }

  Future<List<Slot>> getSlots(int venueId, String date) async {
    final res = await _send(
      () => _dio.get('/venues/$venueId/slots', queryParameters: {'date': date}),
    );
    return (res.data as List).map((e) => Slot.fromJson(e)).toList();
  }

  Future<Booking> bookSlot(int venueId, String slotDatetime) async {
    final res = await _send(
      () => _dio.post('/bookings', data: {
        'venue_id': venueId,
        'slot_datetime': slotDatetime,
      }),
    );
    return Booking.fromJson(res.data as Map<String, dynamic>);
  }

  Future<List<Booking>> getUserBookings(int userId) async {
    final res = await _send(() => _dio.get('/users/$userId/bookings'));
    return (res.data as List).map((e) => Booking.fromJson(e)).toList();
  }

  Future<void> cancelBooking(int bookingId) async {
    await _send(() => _dio.delete('/bookings/$bookingId'));
  }

  // Single error-mapping choke point — every public method goes through here.
  Future<Response<dynamic>> _send(
      Future<Response<dynamic>> Function() call) async {
    try {
      return await call();
    } on DioException catch (e) {
      if (e.response?.statusCode == 409) throw const SlotTakenException();
      if (e.response != null) {
        final body = e.response!.data;
        final msg = (body is Map ? body['error'] : null) ?? 'Request failed';
        throw ApiException(e.response!.statusCode!, msg as String);
      }
      throw const NetworkException();
    }
  }
}
