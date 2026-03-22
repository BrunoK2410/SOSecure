import '../models/sos_event.dart';
import '../services/firestore_service.dart';

class SosRepository {
  final FirestoreService _firestoreService;

  SosRepository(this._firestoreService);

  Stream<List<SosEvent>> getEventsStream(String userId) {
    return _firestoreService.getUserSosEventsStream(userId);
  }

  Future<void> addEvent(String userId, SosEvent event) async {
    await _firestoreService.addSosEvent(userId, event);
  }
}
