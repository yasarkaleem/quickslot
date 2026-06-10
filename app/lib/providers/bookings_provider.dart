import 'package:flutter/foundation.dart';
import '../models/booking.dart';
import '../models/view_state.dart';
import '../services/api_client.dart';

class BookingsProvider extends ChangeNotifier {
  final ApiClient _api;
  BookingsProvider(this._api);

  ViewState state = ViewState.idle;
  List<Booking> bookings = [];
  String? errorMessage;

  Future<void> loadBookings(int userId) async {
    state = ViewState.loading;
    errorMessage = null;
    notifyListeners();

    try {
      bookings = await _api.getUserBookings(userId);
      state = ViewState.success;
    } on NetworkException {
      errorMessage = 'No network connection';
      state = ViewState.error;
    } on ApiException catch (e) {
      errorMessage = e.message;
      state = ViewState.error;
    }
    notifyListeners();
  }

  // Returns the created Booking. Propagates SlotTakenException / ApiException
  // to the caller (the screen) so it can show the right message.
  Future<Booking> book(int venueId, String slotDatetime) {
    return _api.bookSlot(venueId, slotDatetime);
  }

  Future<void> cancel(int bookingId) async {
    await _api.cancelBooking(bookingId);
    bookings.removeWhere((b) => b.id == bookingId);
    notifyListeners();
  }
}
