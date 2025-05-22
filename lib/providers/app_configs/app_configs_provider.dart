import 'dart:io';
import 'package:circle_sync/services/secure_storage_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'app_configs_provider.g.dart';

@riverpod
SecureStorageService secureStorageService(Ref ref) {
  return SecureStorageService.instance;
}

/// A generic FutureProvider.family that reads a value from secure storage for a given key
/// and listens for changes on that key.
final secureStorageDataProvider =
    FutureProvider.family<String?, String>((ref, key) async {
  final secureStorage = ref.watch(secureStorageServiceProvider);

  // Watch for changes on the specific key.
  ref.watch(
    // We use autoDispose to avoid keeping unused streams alive.
    StreamProvider.autoDispose<void>((ref) => secureStorage.onKeyChanged(key)),
  );

  final value = await secureStorage.readData(key);
  return value;
});

// Now, create your individual providers using the family provider.

// For keys that don't need additional transformation, simply use the family instance.
final getMobileNumberProvider = secureStorageDataProvider('mobileNumber');
final getPasswordProvider = secureStorageDataProvider('password');
final getLoginTokenProvider = secureStorageDataProvider('loginToken');
final getFullNameProvider = secureStorageDataProvider('fullName');
final getIcNumberProvider = secureStorageDataProvider('idNumber');
final getMydidSessionId = secureStorageDataProvider('sessionId');
final getLatitudeProvider = secureStorageDataProvider('currentLat');
final getAccountBalanceProvider = secureStorageDataProvider('accountBalance');
final getLongitudeProvider = secureStorageDataProvider('currentLng');
final getWorkflowRunId = secureStorageDataProvider('currentWorkflowRunId');
final getOnfidoSDKToken = secureStorageDataProvider('onfidoSDKToken');
final getUserPinProvider = secureStorageDataProvider('userPin');
final getSpentLimitDailyProvider = secureStorageDataProvider('spentLimitDaily');
final getIsLoggedInProvider = secureStorageDataProvider('isLoggedIn');

final getUsernameProvider = secureStorageDataProvider('name');
final getEmailProvider = secureStorageDataProvider('email');
final getUserIdProvider = secureStorageDataProvider('userId');
final getOneSignalIdProvider = secureStorageDataProvider('oneSignalId');

// Global message notifier remains unchanged.
class GlobalMessageNotifier extends StateNotifier<String?> {
  GlobalMessageNotifier() : super(null);

  void setMessage(String message) {
    clearMessage();
    state = message;
  }

  void clearMessage() {
    state = null;
  }
}

final globalMessageNotifier =
    StateNotifierProvider.autoDispose<GlobalMessageNotifier, String?>(
        (ref) => GlobalMessageNotifier());

class BaseLoadingNotifier extends StateNotifier<bool> {
  BaseLoadingNotifier() : super(false);

  void setLoading(bool isLoading) {
    state = false;
    state = isLoading;
  }
}

final baseLoadingNotifier =
    StateNotifierProvider.autoDispose<BaseLoadingNotifier, bool>(
        (ref) => BaseLoadingNotifier());
