import 'package:flutter/foundation.dart';
import 'storage_service.dart';
import 'platform_storage_mobile.dart';
import 'platform_storage_web.dart';

StorageService get storageService {
  if (kIsWeb) {
    return WebStorageService();
  } else {
    return MobileStorageService();
  }
}
