import 'package:freezed_annotation/freezed_annotation.dart';

part 'trip_dto.freezed.dart';
part 'trip_dto.g.dart';

@freezed
abstract class TripDto with _$TripDto {
  const factory TripDto({
    required String tripId,
    required String status,
    String? driverId,
    String? cancelledBy,
    String? cancelReason,
    String? errorCode,
    DateTime? proposedAt,
    DateTime? acceptedAt,
    DateTime? arrivedAt,
    DateTime? pickedUpAt,
    DateTime? completedAt,
    DateTime? cancelledAt,
    DateTime? failedAt,
  }) = _TripDto;

  factory TripDto.fromJson(Map<String, dynamic> json) =>
      _$TripDtoFromJson(json);
}
