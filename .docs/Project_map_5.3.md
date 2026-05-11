 🗺️ АДИДАС: НАШ ОБМЕННИК — Полная техническая карта проекта (v5.3)

# 📌 ЧАСТЬ 1: СЕРВЕР

## Провайдер и доступ
- Хостинг: BeGet (VPS)
- IP-адрес: 90.156.171.36
- Домен: gazonbaza.ru
- Веб-приложение: https://gazonbaza.ru/app
- Презентация: https://gazonbaza.ru/presentation
- Доступ: SSH через терминал (root / rubi)
- Путь к домену: /home/rubi/web/gazonbaza.ru/

## Операционная система
- ОС: Ubuntu 24.04.4 LTS
- Пользователь: rubi
- Группа: www-data (для веб-сервера)
- Root-доступ: для правки конфигов Nginx

## Управление сервером
- Панель управления: HestiaCP / BeGet CP
- Расположение конфигов: /home/rubi/conf/web/gazonbaza.ru/
- Связка: Nginx (прокси) → Apache2 (порт 8443)

Веб-сервер (Nginx) — ОБНОВЛЁН ДЛЯ ВЕБ-ВЕРСИИ
- HTTP-конфиг: /home/rubi/conf/web/gazonbaza.ru/nginx.conf
- SSL-конфиг: /home/rubi/conf/web/gazonbaza.ru/nginx.ssl.conf
- Основной конфиг: /etc/nginx/conf.d/domains/gazonbaza.ru.ssl.conf
- Прокси на: https://90.156.171.36:8443 (Apache)
- WebSocket прокси: /socket.io/ → http://127.0.0.1:3001
- Веб-приложение: /app → alias /home/rubi/web/gazonbaza.ru/public_html/web/
- Презентация: /presentation → alias /home/rubi/web/gazonbaza.ru/public_html/presentation/
- Таймауты: proxy_read_timeout 600s, proxy_send_timeout 600s
- client_max_body_size 300m
- proxy_request_buffering off

PHP
- Версия: 8.3
- Конфиг: /etc/php/8.3/fpm/php.ini
- Важные настройки для файлов:
  - upload_max_filesize = 300M
  - post_max_size = 300M
  - max_execution_time = 300
  - max_input_time = 300
  - memory_limit = 512M
- Перезагрузка: systemctl restart php8.3-fpm

## Пути к файлам проекта
- Корень сайта (public): /home/rubi/web/gazonbaza.ru/public_html/
- Веб-приложение: /home/rubi/web/gazonbaza.ru/public_html/web/
- Презентация: /home/rubi/web/gazonbaza.ru/public_html/presentation/
- Логи: /var/log/apache2/domains/gazonbaza.ru.error.log
- Логи Nginx: /var/log/nginx/error.log
- Хранилище файлов: /home/rubi/web/gazonbaza.ru/public_html/files/
- Бэкапы: через HestiaCP

# 💾 ЧАСТЬ 2: БАЗА ДАННЫХ (без изменений)

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

5. share_links — временные публичные ссылки (v5.0)
- id INT AUTO_INCREMENT PRIMARY KEY
- file_id INT NOT NULL
- token VARCHAR(32) NOT NULL UNIQUE
- created_by INT NOT NULL
- expires_at TIMESTAMP NOT NULL
- created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
- FOREIGN KEY (file_id) REFERENCES files(id) ON DELETE CASCADE
- FOREIGN KEY (created_by) REFERENCES users(id) ON DELETE CASCADE

6. user_file_views — отметки о просмотре файлов (v5.0)
- id INT AUTO_INCREMENT PRIMARY KEY
- user_id INT NOT NULL
- file_id INT NOT NULL
- viewed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
- UNIQUE KEY unique_view (user_id, file_id)
- FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
- FOREIGN KEY (file_id) REFERENCES files(id) ON DELETE CASCADE

# 📡 ЧАСТЬ 3: API ENDPOINTS (без изменений)

Базовый URL
- https://gazonbaza.ru (общий для мобильного и веб-приложения)

Все эндпоинты:
- register.php, login.php, list_files.php, upload.php, download.php
- delete.php, rename.php, toggle_visibility.php, profile.php
- create_folder.php, delete_folder.php, rename_folder.php, list_folders.php, move_file.php
- get_share_link.php, public_download.php, mark_viewed.php
- auth.php, json_input.php, notification_helper.php

## Исправления в upload.php (v5.3)
- ✅ Убран дублирующий INSERT (файлы больше не дублируются в БД)
- ✅ Переменные $isPublic, $folderId, $description определяются до использования
- ✅ Добавлено поле description в INSERT-запрос

# 📱 ЧАСТЬ 4: FLUTTER-ПРИЛОЖЕНИЕ (v5.3 — кросс-платформенное)

## Технологии
- Фреймворк: Flutter (Dart)
- Минимальная версия SDK: ^3.0.0
- Целевые платформы: Android (APK) + Web (HTML/JS)
- Репозиторий: https://github.com/rubigruz-creator/adidas-obmennik

## Актуальные зависимости (pubspec.yaml v5.3)

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
  universal_html: ^2.2.4              # Web-совместимость

## Структура проекта (v5.3)

lib/
├── main.dart
├── screens/
│   ├── splash_screen.dart
│   ├── login_screen.dart
│   ├── files_screen.dart
│   ├── file_operations.dart          # 🆕 v5.3: Превью в меню файла, kIsWeb-проверки
│   ├── folder_operations.dart
│   ├── upload_operations.dart        # 🆕 v5.3: uploadFileBytes, индикатор прогресса
│   ├── profile_screen.dart
│   └── lock_screen.dart
├── widgets/
│   ├── file_card.dart                # 🆕 v5.3: Превью в сетке через Image.network
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
│   └── platform_utils.dart
└── services/
    ├── api_service.dart               # 🆕 v5.3: uploadFileBytes, _downloadFileWeb (Blob URL)
    ├── auth_service.dart
    ├── notification_service.dart
    ├── websocket_service.dart
    ├── storage_service.dart
    ├── platform_storage_mobile.dart
    ├── platform_storage_web.dart
    └── service_locator.dart

## Ресурсы

assets/animations/adidas.json

assets/logo/adidas_logo.svg

android/app/src/main/res/mipmap-*

web/ — собранная веб-версия

# 🆕 ЧАСТЬ 5: ВЕБ-ВЕРСИЯ (v5.3)

## Сборка и деплой

Локальная сборка: flutter build web --base-href "/app/" --release

Загрузка на сервер: scp -r build/web/* rubi@90.156.171.36:/home/rubi/web/gazonbaza.ru/public_html/web/

Права на сервере:
  ssh root@90.156.171.36
  chown -R rubi:www-data /home/rubi/web/gazonbaza.ru/public_html/web
  chmod -R 755 /home/rubi/web/gazonbaza.ru/public_html/web

URL: https://gazonbaza.ru/app

## Особенности веб-версии (v5.3)

Единая кодовая база с мобильным приложением

Платформенные проверки через kIsWeb

StorageService: SharedPreferences вместо FlutterSecureStorage

Upload: ApiService.uploadFileBytes (байты напрямую, без временных файлов)

Download: AnchorElement + Blob URL (браузерное скачивание)

WebSocket: socket_io_client с polling-транспортом

CORS: не требуется (тот же домен)

Права доступа: не требуются (браузер)

PIN-код: отключён в main.dart для веб-версии

# 🆕 ЧАСТЬ 6: ИСПРАВЛЕНИЯ В v5.3

## ✅ Исправления загрузки файлов
- Убран дублирующий INSERT в upload.php (файлы больше не дублируются)
- Добавлен метод ApiService.uploadFileBytes для загрузки из байтов
- UploadOperations.uploadFileBytes — прямая передача байтов без File
- Диалог загрузки с индикатором прогресса (LinearProgressIndicator)
- Автоматическое закрытие диалога после успешной загрузки
- Убрано зацикливание индикатора (удалён Timer)
- Оптимизирована загрузка для веба (без Directory.systemTemp)

## ✅ Превью (эскизы) изображений
- file_card.dart: превью в режиме Сетка через Image.network + заголовки авторизации
- file_operations.dart: превью в меню файла через Image.network
- Правильные заголовки X-API-Token и Host для thumbnail URL
- Обработка ошибок загрузки превью (errorBuilder)

## ✅ Скачивание файлов
- Исправлен _downloadFileWeb — используется Blob URL вместо base64
- Убрано зацикливание скачивания (флаг isDownloading, кнопка "Закрыть" вместо "Повторить")
- Добавлена проверка Content-Type ответа
- Логирование процесса скачивания

## ✅ Исправления на сервере
- PHP 8.3: настроены max_execution_time, memory_limit, post_max_size
- Nginx: добавлены таймауты proxy_read_timeout, client_max_body_size
- Nginx: добавлен location /presentation для презентации
- Настроен автозапуск сервисов (systemctl enable)

## ✅ Презентация
- Создан HTML-файл презентации с 12 слайдами
- Размещена на https://gazonbaza.ru/presentation
- Слайды: проблема, решение, архитектура, мобильное приложение, веб-версия, брендинг, дорожная карта, масштабирование, преимущества, заключение
- Управление: стрелки, клики, точки навигации

# 🆕 ЧАСТЬ 7: GITHUB

## Репозиторий

URL: https://github.com/rubigruz-creator/adidas-obmennik

Видимость: Public

Ветки:

main — стабильная версия (Android v5.1)

feature/web-version — веб-версия (v5.2-v5.3)

Документация: docs/ (карта проекта, инструкция, презентация)

# 📜 ИСТОРИЯ ВЕРСИЙ

v5.3 (текущая) — ИСПРАВЛЕНИЯ И СТАБИЛИЗАЦИЯ
✅ Исправлено дублирование файлов при загрузке
✅ Исправлен индикатор прогресса загрузки (без зацикливания)
✅ Включены превью изображений (сетка + меню)
✅ Исправлено скачивание файлов в веб-версии
✅ Убран пин-код в веб-версии
✅ Оптимизирована загрузка байтов (без временных файлов)
✅ Настроены таймауты сервера для больших файлов
✅ Презентация на gazonbaza.ru/presentation
✅ Иконки и assets с правильными правами

v5.2 — ВЕБ-ВЕРСИЯ И ДОКУМЕНТАЦИЯ
✅ Веб-версия на gazonbaza.ru/app
✅ Кросс-платформенный код (kIsWeb)
✅ StorageService с платформенными реализациями
✅ Загрузка/скачивание файлов в браузере
✅ Настроен Nginx для SPA (Flutter Web)
✅ GitHub-репозиторий
✅ Инструкция пользователя (docs/user_guide.md)
✅ Презентация для заказчика (docs/presentation.md)
✅ Обновлённая карта проекта (docs/Project_map_5.2.md)

v5.1 — БРЕНДИНГ, БЕЗОПАСНОСТЬ И ПОЛИРОВКА
✅ Смена названия на "АДИДАС", логотип в AppBar и на экранах
✅ Splash Screen со свайпом и Lottie-анимацией
✅ Экран блокировки с PIN-кодом (flutter_secure_storage)
✅ Исправление permissions для аудио, видео, APK
✅ Обновлены иконки приложения (mipmap всех размеров)
✅ Улучшена цветовая схема в Material 3 (чёрный/красный)

v5.0 — СОЦИАЛЬНЫЕ ФУНКЦИИ, УВЕДОМЛЕНИЯ И УЛУЧШЕНИЯ UI/UX
✅ Кнопка «Поделиться», индикатор новых файлов, фильтры
✅ FAB-кнопка камеры, улучшенные хлебные крошки
✅ Серверные эндпоинты share_links, user_file_views

v4.2 — ПРЕДПРОСМОТР, ОПИСАНИЯ И ОПТИМИЗАЦИЯ
v4.1 — ПЕРЕРАБОТКА UI
v4.0 — PUSH-УВЕДОМЛЕНИЯ
v3.1 — ПРОФИЛЬ И ПРОГРЕСС-БАРЫ
v3.0 — ПАПКИ И КАТЕГОРИИ
v2.0 — УЛУЧШЕНИЯ
v1.0 — БАЗОВАЯ ВЕРСИЯ

# 🔜 ПЛАНЫ НА БУДУЩЕЕ

## Задача 1: Множественная обработка файлов
- Множественная загрузка (выбор нескольких файлов)
- Групповое удаление (чекбоксы, долгое нажатие)
- Групповое перемещение в папку
- Индивидуальный прогресс для каждого файла
- Обработка частичных ошибок

## Задача 2: Аудит действий
- Таблица audit_log в MariaDB (id, user_id, action, file_id, details JSON, created_at)
- Серверный эндпоинт audit_log.php (только для админов)
- Логирование: загрузка, удаление, скачивание, переименование, перемещение, изменение видимости, вход/выход
- Экран "История" в приложении (доступен только админам)
- Фильтры по пользователю, действию, дате

## Задача 3: Drag-and-drop в веб-версии
- Захват файлов из проводника
- Визуальная подсветка зоны
- Интеграция с uploadFileBytes

## Задача 4: Двухфакторная аутентификация
## Задача 5: Шифрование файлов

🚀 Проект готов к презентации. Веб-версия работает, мобильное приложение стабильно.