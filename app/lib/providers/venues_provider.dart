import 'package:flutter/foundation.dart';
import '../models/venue.dart';
import '../models/view_state.dart';
import '../services/api_client.dart';

class VenuesProvider extends ChangeNotifier {
  final ApiClient _api;
  VenuesProvider(this._api);

  ViewState state = ViewState.idle;
  List<Venue> venues = [];
  String? errorMessage;

  Future<void> loadVenues() async {
    state = ViewState.loading;
    errorMessage = null;
    notifyListeners();

    try {
      venues = await _api.getVenues();
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
