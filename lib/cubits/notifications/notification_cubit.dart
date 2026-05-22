import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:minimumz/di/di.dart';
import 'package:minimumz/domain/repository/preference_repository.dart';
import 'package:minimumz/services/notification_service.dart';

class NotificationCubit extends Cubit<bool> {
  NotificationCubit() : super(getIt<PreferenceRepository>().notificationsEnabled);

  static NotificationCubit get instance => NotificationCubit();

  Future<void> setEnabled(bool value) async {
    await getIt<PreferenceRepository>().setNotificationsEnabled(value);
    emit(value);
    if (value) {
      await NotificationService.instance.registerToken();
    } else {
      await NotificationService.instance.clearToken();
    }
  }
}
