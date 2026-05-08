📄 ОБНОВЛЁННЫЙ ФАЙЛ: Project_map_5.2.md
🗺️ АДИДАС: НАШ ОБМЕННИК — Полная техническая карта проекта (v5.2)

# 📌 ЧАСТЬ 1: СЕРВЕР (обновлён для веб-версии)

## Провайдер и доступ
- Хостинг: BeGet (VPS)
- IP-адрес: 90.156.171.36
- Домен: gazonbaza.ru
- Веб-приложение: https://gazonbaza.ru/app
- Доступ: SSH через терминал (root / rubi)
- Путь к домену: /home/rubi/web/gazonbaza.ru/

## Операционная система
- ОС: Ubuntu
- Пользователь: rubi
- Группа: www-data (для веб-сервера)
- Root-доступ: для правки конфигов Nginx

## Управление сервером
- Панель управления: HestiaCP
- Расположение конфигов: /home/rubi/conf/web/gazonbaza.ru/
- Связка: Nginx (прокси) → Apache2 (порт 8080)

Веб-сервер (Nginx) — ОБНОВЛЁН ДЛЯ ВЕБ-ВЕРСИИ
- HTTP-конфиг: /home/rubi/conf/web/gazonbaza.ru/nginx.conf
- SSL-конфиг: /home/rubi/conf/web/gazonbaza.ru/nginx.ssl.conf
- Прокси на: http://90.156.171.36:8080 (Apache)
- WebSocket прокси: /socket.io/ → http://127.0.0.1:3001
- 🆕 Веб-приложение: /app → alias /home/rubi/web/gazonbaza.ru/public_html/web/
- 🆕 CORS: заголовки удалены из PHP, обрабатываются на уровне Nginx (при необходимости)

PHP
- Версия: 8.1
- Конфиг: /etc/php/8.1/fpm/php.ini
- Важные настройки для файлов:
  - upload_max_filesize = 300M
  - post_max_size = 300M
  - max_execution_time = 600
  - memory_limit = 512M
- Перезагрузка: sudo systemctl restart php8.1-fpm
- 🆕 CORS: удалён файл cors.php и все require_once из PHP (обрабатывается Nginx)

## Пути к файлам проекта
- Корень сайта (public): /home/rubi/web/gazonbaza.ru/public_html/
- 🆕 Веб-приложение: /home/rubi/web/gazonbaza.ru/public_html/web/
- Логи: /var/log/apache2/domains/gazonbaza.ru.error.log
- Хранилище файлов: /home/rubi/web/gazonbaza.ru/public_html/files/
- Бэкапы: через HestiaCP

Nginx запрет прямого доступа к файлам
- В конфиг добавлено: /files/ → deny all; return 403;

# 💾 ЧАСТЬ 2: БАЗА ДАННЫХ (без изменений с v5.0)

## Система
- СУБД: MariaDB
- База данных: avito_shop
- Пользователь БД: api_user
- Пароль: StrongPass123!

## Структура таблиц

1. users — пользователи
- id INT AUTO_INCREMENT PRIMARY KEY
- phone VARCHAR(20) NOT NULL UNIQUE
- password_hash VARCHAR(255) NOT NULL
- nickname VARCHAR(50)
- full_name VARCHAR(100)
- position VARCHAR(100)
- is_admin TINYINT(1) DEFAULT 0
- created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP

2. user_sessions — токены сессий
- id INT AUTO_INCREMENT PRIMARY KEY
- user_id INT NOT NULL
- api_token VARCHAR(64) NOT NULL UNIQUE
- expires_at TIMESTAMP NOT NULL
- created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
- FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE

3. files — файлы
- id INT AUTO_INCREMENT PRIMARY KEY
- user_id INT NOT NULL
- original_name VARCHAR(255) NOT NULL
- stored_name VARCHAR(255) NOT NULL
- file_size INT NOT NULL
- file_type VARCHAR(100)
- is_public BOOLEAN DEFAULT FALSE
- folder_id INT DEFAULT NULL
- description TEXT DEFAULT NULL
- upload_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP
- FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
- FOREIGN KEY (folder_id) REFERENCES folders(id) ON DELETE SET NULL

4. folders — папки
- id INT AUTO_INCREMENT PRIMARY KEY
- user_id INT NOT NULL
- name VARCHAR(255) NOT NULL
- parent_id INT DEFAULT NULL
- created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
- FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
- FOREIGN KEY (parent_id) REFERENCES folders(id) ON DELETE CASCADE

5. api_keys — ключи API (устаревшая, не используется)
- id INT AUTO_INCREMENT PRIMARY KEY
- api_key VARCHAR(64) NOT NULL UNIQUE
- app_name VARCHAR(100) NOT NULL
- is_active TINYINT(1) DEFAULT 1
- created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP

6. share_links — временные публичные ссылки (v5.0)
- id INT AUTO_INCREMENT PRIMARY KEY
- file_id INT NOT NULL
- token VARCHAR(32) NOT NULL UNIQUE
- created_by INT NOT NULL
- expires_at TIMESTAMP NOT NULL
- created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
- FOREIGN KEY (file_id) REFERENCES files(id) ON DELETE CASCADE
- FOREIGN KEY (created_by) REFERENCES users(id) ON DELETE CASCADE

7. user_file_views — отметки о просмотре файлов (v5.0)
- id INT AUTO_INCREMENT PRIMARY KEY
- user_id INT NOT NULL
- file_id INT NOT NULL
- viewed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
- UNIQUE KEY unique_view (user_id, file_id)
- FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
- FOREIGN KEY (file_id) REFERENCES files(id) ON DELETE CASCADE

# 📡 ЧАСТЬ 3: API ENDPOINTS (без изменений с v5.0)

Базовый URL
- https://gazonbaza.ru (общий для мобильного и веб-приложения)
- 🆕 Веб-версия использует тот же домен — CORS не требуется

Все эндпоинты без изменений:
- register.php, login.php, list_files.php, upload.php, download.php
- delete.php, rename.php, toggle_visibility.php, profile.php
- create_folder.php, delete_folder.php, rename_folder.php, list_folders.php, move_file.php
- get_share_link.php, public_download.php, mark_viewed.php
- auth.php, json_input.php

# 📱 ЧАСТЬ 4: FLUTTER-ПРИЛОЖЕНИЕ (v5.2 — кросс-платформенное)

## Технологии
- Фреймворк: Flutter (Dart)
- Минимальная версия SDK: ^3.0.0
- Целевые платформы: Android (APK) + Web (HTML/JS)
- Репозиторий: https://github.com/rubigruz-creator/adidas-obmennik

## Актуальные зависимости (pubspec.yaml v5.2)

dependencies:
  flutter:
    sdk: flutter
  http: ^1.2.0
  image_picker: ^1.0.7
  file_picker: ^8.0.0
  permission_handler: ^11.3.1
  path_provider: ^2.1.2
  open_file: ^3.3.2
  shared_preferences: ^2.2.2
  cupertino_icons: ^1.0.8
  socket_io_client: ^2.0.3
  flutter_local_notifications: ^17.2.4
  intl: ^0.19.0
  cached_network_image: ^3.3.1
  share_plus: ^7.2.1
  lottie: ^2.7.0
  flutter_secure_storage: ^9.0.0
  flutter_svg: ^2.0.10+1
  crypto: ^3.0.3
  universal_html: ^2.2.4              # 🆕 Web-совместимость

## Структура проекта (v5.2)

text
lib/
├── main.dart
├── screens/
│   ├── splash_screen.dart
│   ├── login_screen.dart
│   ├── files_screen.dart
│   ├── file_operations.dart
│   ├── folder_operations.dart
│   ├── upload_operations.dart        # 🆕 Обновлён: kIsWeb для загрузки
│   ├── profile_screen.dart
│   └── lock_screen.dart
├── widgets/
│   ├── file_card.dart
│   ├── file_list_tile.dart
│   ├── folder_card.dart
│   ├── folder_list_tile.dart
│   ├── file_icon.dart
│   ├── empty_state.dart
│   ├── breadcrumb_chips.dart
│   ├── file_pill.dart (устаревший)
│   └── folder_pill.dart (устаревший)
├── utils/
│   ├── app_config.dart
│   ├── format_file_size.dart
│   ├── format_date.dart
│   └── platform_utils.dart            # 🆕 Утилита isWeb
└── services/
    ├── api_service.dart               # 🆕 Обновлён: kIsWeb для upload/download
    ├── auth_service.dart              # 🆕 Обновлён: StorageService
    ├── notification_service.dart
    ├── websocket_service.dart
    ├── storage_service.dart           # 🆕 Абстрактный интерфейс
    ├── platform_storage_mobile.dart   # 🆕 Мобильная реализация
    ├── platform_storage_web.dart      # 🆕 Веб-реализация
    └── service_locator.dart           # 🆕 Локатор сервисов

## Ресурсы

assets/animations/adidas.json

assets/logo/adidas_logo.svg

android/app/src/main/res/mipmap-*

🆕 web/ — собранная веб-версия

🆕 ЧАСТЬ 5: ВЕБ-ВЕРСИЯ (v5.2)

## Сборка и деплой

Локальная сборка: flutter build web --base-href "/app/"

Загрузка на сервер: scp -r build/web/* rubi@90.156.171.36:/home/rubi/web/gazonbaza.ru/public_html/web/

Права на сервере: chown -R rubi:www-data .../web/ && chmod -R 755 .../web/

URL: https://gazonbaza.ru/app

## Особенности веб-версии

Единая кодовая база с мобильным приложением

Платформенные проверки через kIsWeb

StorageService: SharedPreferences вместо FlutterSecureStorage

Upload: FilePicker + чтение байтов (kIsWeb)

Download: AnchorElement + Blob (браузерное скачивание)

WebSocket: socket_io_client с polling-транспортом

CORS: не требуется (тот же домен)

Права доступа: не требуются (браузер)

PIN-код: работает через SharedPreferences (менее безопасно)

# 🆕 ЧАСТЬ 6: GITHUB

## Репозиторий

URL: https://github.com/rubigruz-creator/adidas-obmennik

Видимость: Public

Ветки:

main — стабильная версия (Android v5.1)

feature/web-version — веб-версия (v5.2)

Документация: docs/ (карта проекта, инструкция, презентация)

# 📜 ИСТОРИЯ ВЕРСИЙ

v5.2 (текущая) — ВЕБ-ВЕРСИЯ И ДОКУМЕНТАЦИЯ
✅ Веб-версия на gazonbaza.ru/app
✅ Кросс-платформенный код (kIsWeb)
✅ StorageService с платформенными реализациями
✅ Загрузка/скачивание файлов в браузере
✅ Настроен Nginx для SPA (Flutter Web)
✅ Удалены CORS-заголовки из PHP
✅ GitHub-репозиторий
✅ Инструкция пользователя (docs/user_guide.md)
✅ Презентация для заказчика (docs/presentation.md)
✅ Обновлённая карта проекта (docs/Project_map_5.2.md)

v5.1 — БРЕНДИНГ, БЕЗОПАСНОСТЬ И ПОЛИРОВКА
✅ Смена названия на "АДИДАС", логотип в AppBar и на экранах.
✅ Splash Screen со свайпом и Lottie-анимацией.
✅ Экран блокировки с PIN-кодом (flutter_secure_storage).
✅ Исправление permissions для аудио, видео, APK.
✅ Обновлены иконки приложения (mipmap всех размеров).
✅ Улучшена цветовая схема в Material 3 (чёрный/красный).

v5.0 — СОЦИАЛЬНЫЕ ФУНКЦИИ, УВЕДОМЛЕНИЯ И УЛУЧШЕНИЯ UI/UX
✅ Кнопка «Поделиться», индикатор новых файлов, фильтры.
✅ FAB-кнопка камеры, улучшенные хлебные крошки.
✅ Серверные эндпоинты share_links, user_file_views.

v4.2 — ПРЕДПРОСМОТР, ОПИСАНИЯ И ОПТИМИЗАЦИЯ
v4.1 — ПЕРЕРАБОТКА UI
v4.0 — PUSH-УВЕДОМЛЕНИЯ
v3.1 — ПРОФИЛЬ И ПРОГРЕСС-БАРЫ
v3.0 — ПАПКИ И КАТЕГОРИИ
v2.0 — УЛУЧШЕНИЯ
v1.0 — БАЗОВАЯ ВЕРСИЯ

🚀 Проект готов к презентации. Веб-версия работает, мобильное приложение стабильно.

