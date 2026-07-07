abstract class GpsDatasource {
  Stream<({double lat, double lng, double heading, double speed})> watchPosition();
  void dispose();
}
