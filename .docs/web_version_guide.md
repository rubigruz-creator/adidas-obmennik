# 🌐 АДИДАС: Веб-версия — Техническая документация (v5.2)

## 📌 Обзор

Веб-версия корпоративного файлообменника «АДИДАС» доступна по адресу:
**https://gazonbaza.ru/app**

Разработана на Flutter Web в единой кодовой базе с Android-приложением.

---

## 🏗️ Архитектура
Браузер (Chrome, Firefox, Safari)
↕ HTTPS
Nginx (gazonbaza.ru)
├── /app → Flutter Web (статический SPA)
└── /* → Apache2 (PHP API)
↕
MariaDB (avito_shop)

text

### Ключевые отличия от мобильной версии

| Компонент | Android | Web |
|-----------|---------|-----|
| Хранилище токенов | FlutterSecureStorage | SharedPreferences |
| Хранилище PIN | FlutterSecureStorage (SHA-256) | SharedPreferences |
| Права доступа | Динамический запрос | Не требуются |
| Выбор файлов | FilePicker (путь) | FilePicker (bytes) |
| Скачивание | Сохранение в Downloads | Blob + AnchorElement |
| Уведомления | Локальные Android | Web Notifications API |
| Камера | Нативная | Браузерный API |

---

## 📂 Структура веб-файлов
/home/rubi/web/gazonbaza.ru/public_html/web/
├── index.html # Точка входа SPA
├── main.dart.js # Скомпилированный Dart
├── flutter_bootstrap.js # Загрузчик Flutter
├── flutter.js # Flutter Web runtime
├── flutter_service_worker.js # Service Worker (PWA)
├── manifest.json # Web App Manifest
├── favicon.png # Иконка сайта
├── version.json # Версия сборки
├── .last_build_id # Идентификатор сборки
├── assets/ # Ресурсы приложения
│ ├── assets/animations/ # Lottie-анимации
│ ├── assets/logo/ # SVG-логотип
│ ├── packages/ # Пакетные ресурсы
│ └── FontManifest.json # Шрифты
├── canvaskit/ # CanvasKit (WebGL рендер)
└── icons/ # PWA-иконки


---

## 🔧 Сборка и деплой

### Локальная сборка

```bash```
cd /путь/к/проекту
flutter clean
flutter pub get
flutter build web --base-href "/app/"
Загрузка на сервер
bash

### Загрузка файлов
scp -r build/web/* rubi@90.156.171.36:/home/rubi/web/gazonbaza.ru/public_html/web/

### На сервере — права
ssh root@90.156.171.36
chown -R rubi:www-data /home/rubi/web/gazonbaza.ru/public_html/web/
chmod -R 755 /home/rubi/web/gazonbaza.ru/public_html/web/

## ⚙️ Конфигурация Nginx
Блок в /home/rubi/conf/web/gazonbaza.ru/nginx.ssl.conf:

nginx
location /app {
    alias /home/rubi/web/gazonbaza.ru/public_html/web;
    index index.html;
    try_files $uri /app/index.html;
}
Важно:

Без слеша в location /app и alias

try_files должен корректно обрабатывать SPA-роутинг

Все API-запросы идут на https://gazonbaza.ru/* (CORS не нужен)

# 🔄 Платформенные абстракции
StorageService (lib/services/)
dart
// Абстрактный интерфейс
abstract class StorageService {
  Future<String?> getString(String key);
  Future<void> setString(String key, String value);
  Future<void> remove(String key);
}

// Мобильная реализация (flutter_secure_storage)
class MobileStorageService implements StorageService { ... }

// Веб-реализация (shared_preferences)
class WebStorageService implements StorageService { ... }

// Локатор
StorageService get storageService => kIsWeb ? WebStorageService() : MobileStorageService();
Загрузка файлов (api_service.dart)
dart
if (kIsWeb) {
  final bytes = await file.readAsBytes();
  request.files.add(http.MultipartFile.fromBytes('file', bytes, filename: fileName));
} else {
  request.files.add(await http.MultipartFile.fromPath('file', file.path, filename: fileName));
}
Скачивание файлов (api_service.dart)
dart
if (kIsWeb) {
  _downloadFileWeb(response.bodyBytes, fileName);
} else {
  await _saveFileAndroid(response.bodyBytes, fileName);
}

// Веб-реализация
static void _downloadFileWeb(Uint8List bytes, String fileName) {
  final base64 = base64Encode(bytes);
  final anchor = html.AnchorElement(
    href: 'data:application/octet-stream;base64,$base64',
  )
    ..setAttribute('download', fileName)
    ..click();
}

# 🚨 Известные ограничения
Ограничение	Описание	Решение
PIN-код	Хранится в SharedPreferences (менее безопасно)	Предупреждение в интерфейсе
Загрузка больших файлов	Браузер может ограничивать память	Файлы до 300 МБ
Камера	Не все браузеры поддерживают	Chrome/Firefox/Safari
WebSocket	Используется polling (не нативный WebSocket)	socket_io_client
Service Worker	Кеширование может мешать обновлениям	Жёсткая перезагрузка Ctrl+Shift+R

# 🧪 Тестирование
Проверка CORS
bash
curl -X OPTIONS https://gazonbaza.ru/login.php \
  -H "Origin: https://gazonbaza.ru" \
  -H "Access-Control-Request-Method: POST" -I
Ожидаемый ответ: HTTP/2 204

Проверка статики
bash
curl -I https://gazonbaza.ru/app/index.html
Ожидаемый ответ: HTTP/2 200

Логи ошибок
bash
tail -50 /var/log/apache2/domains/gazonbaza.ru.error.log | grep -i "app\|web"

# 📞 Поддержка
При проблемах с веб-версией:

Проверить логи Nginx/Apache

Проверить права на папку /web/

Проверить base href в index.html

Очистить кеш браузера (Ctrl+Shift+R)

Пересобрать и загрузить заново

---

