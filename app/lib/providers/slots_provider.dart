import 'package:flutter/foundation.dart';
import '../models/slot.dart';
import '../models/view_state.dart';
import '../services/api_client.dart';

class SlotsProvider extends ChangeNotifier {
  final ApiClient _api;
  SlotsProvider(this._api);

  ViewState state = ViewState.idle;
  List<Slot> slots = [];
  String? errorMessage;

  Future<void> load(int venueId, String date) async {
    state = ViewState.loading;
    errorMessage = null;
    notifyListeners();

    try {
      slots = await _api.getSlots(venueId, date);
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
}
