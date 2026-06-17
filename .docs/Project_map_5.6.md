@"
# 🗺️ АДИДАС: НАШ ОБМЕННИК — Полная техническая карта проекта (v5.6)

## 📌 ЧАСТЬ 1: СЕРВЕР

### Провайдер и доступ
- **Хостинг:** BeGet (VPS)
- **IP-адрес:** 90.156.171.36
- **Домен:** gazonbaza.ru
- **Веб-приложение:** https://gazonbaza.ru/app
- **Презентация:** https://gazonbaza.ru/presentation
- **Доступ:** SSH через терминал (root / rubi)
- **Путь к домену:** /home/rubi/web/gazonbaza.ru/

### Операционная система
- **ОС:** Ubuntu 24.04.4 LTS
- **Пользователь:** rubi
- **Группа:** www-data (для веб-сервера)
- **Root-доступ:** для правки конфигов Nginx

### Управление сервером
- **Панель управления:** HestiaCP / BeGet CP
- **Расположение конфигов:** /home/rubi/conf/web/gazonbaza.ru/
- **Связка:** Nginx (прокси) → Apache2 (порт 8443)

### Веб-сервер (Nginx)
- **HTTP-конфиг:** /home/rubi/conf/web/gazonbaza.ru/nginx.conf
- **SSL-конфиг:** /home/rubi/conf/web/gazonbaza.ru/nginx.ssl.conf
- **Основной конфиг:** /etc/nginx/conf.d/domains/gazonbaza.ru.ssl.conf
- **Прокси на:** https://90.156.171.36:8443 (Apache)
- **WebSocket прокси:** /socket.io/ → http://127.0.0.1:3001
- **Веб-приложение:** /app → alias /home/rubi/web/gazonbaza.ru/public_html/web/
- **Презентация:** /presentation → alias /home/rubi/web/gazonbaza.ru/public_html/presentation/
- **Таймауты:** proxy_read_timeout 600s, proxy_send_timeout 600s
- **client_max_body_size** 300m
- **proxy_request_buffering** off

### PHP
- **Версия:** 8.3
- **Конфиг:** /etc/php/8.3/fpm/php.ini
- **Важные настройки для файлов:**
  - upload_max_filesize = 300M
  - post_max_size = 300M
  - max_execution_time = 300
  - max_input_time = 300
  - memory_limit = 512M
- **Перезагрузка:** systemctl restart php8.3-fpm

### Пути к файлам проекта
- **Корень сайта (public):** /home/rubi/web/gazonbaza.ru/public_html/
- **Веб-приложение:** /home/rubi/web/gazonbaza.ru/public_html/web/
- **Презентация:** /home/rubi/web/gazonbaza.ru/public_html/presentation/
- **Логи:** /var/log/apache2/domains/gazonbaza.ru.error.log
- **Логи Nginx:** /var/log/nginx/error.log
- **Хранилище файлов:** /home/rubi/web/gazonbaza.ru/public_html/files/
- **Бэкапы:** через HestiaCP

---

## 💾 ЧАСТЬ 2: БАЗА ДАННЫХ

### Система
- **СУБД:** MariaDB
- **База данных:** avito_shop
- **Пользователь БД:** api_user
- **Пароль:** StrongPass123!

### Структура таблиц

#### 1. users — пользователи
| Поле | Тип | Описание |
|------|-----|----------|
| id | INT AUTO_INCREMENT PRIMARY KEY | |
| phone | VARCHAR(20) NOT NULL UNIQUE | |
| password_hash | VARCHAR(255) NOT NULL | |
| nickname | VARCHAR(50) | |
| full_name | VARCHAR(100) | |
| position | VARCHAR(100) | |
| is_admin | TINYINT(1) DEFAULT 0 | |
| created_at | TIMESTAMP DEFAULT CURRENT_TIMESTAMP | |

#### 2. user_sessions — токены сессий
| Поле | Тип | Описание |
|------|-----|----------|
| id | INT AUTO_INCREMENT PRIMARY KEY | |
| user_id | INT NOT NULL | FOREIGN KEY → users(id) |
| api_token | VARCHAR(64) NOT NULL UNIQUE | |
| expires_at | TIMESTAMP NOT NULL | |
| created_at | TIMESTAMP DEFAULT CURRENT_TIMESTAMP | |

#### 3. files — файлы
| Поле | Тип | Описание |
|------|-----|----------|
| id | INT AUTO_INCREMENT PRIMARY KEY | |
| user_id | INT NOT NULL | FOREIGN KEY → users(id) |
| original_name | VARCHAR(255) NOT NULL | |
| stored_name | VARCHAR(255) NOT NULL | |
| file_size | INT NOT NULL | |
| file_type | VARCHAR(100) | |
| is_public | BOOLEAN DEFAULT FALSE | |
| folder_id | INT DEFAULT NULL | FOREIGN KEY → folders(id) |
| description | TEXT DEFAULT NULL | |
| upload_date | TIMESTAMP DEFAULT CURRENT_TIMESTAMP | |

#### 4. folders — папки
| Поле | Тип | Описание |
|------|-----|----------|
| id | INT AUTO_INCREMENT PRIMARY KEY | |
| user_id | INT NOT NULL | FOREIGN KEY → users(id) |
| name | VARCHAR(255) NOT NULL | |
| parent_id | INT DEFAULT NULL | FOREIGN KEY → folders(id) |
| created_at | TIMESTAMP DEFAULT CURRENT_TIMESTAMP | |

#### 5. share_links — временные публичные ссылки (v5.0)
| Поле | Тип | Описание |
|------|-----|----------|
| id | INT AUTO_INCREMENT PRIMARY KEY | |
| file_id | INT NOT NULL | FOREIGN KEY → files(id) |
| token | VARCHAR(32) NOT NULL UNIQUE | |
| created_by | INT NOT NULL | FOREIGN KEY → users(id) |
| expires_at | TIMESTAMP NOT NULL | |
| created_at | TIMESTAMP DEFAULT CURRENT_TIMESTAMP | |

#### 6. user_file_views — отметки о просмотре файлов (v5.0)
| Поле | Тип | Описание |
|------|-----|----------|
| id | INT AUTO_INCREMENT PRIMARY KEY | |
| user_id | INT NOT NULL | FOREIGN KEY → users(id) |
| file_id | INT NOT NULL | FOREIGN KEY → files(id) |
| viewed_at | TIMESTAMP DEFAULT CURRENT_TIMESTAMP | |
| UNIQUE KEY | unique_view (user_id, file_id) | |

#### 7. audit_log — аудит действий пользователей 🆕 v5.6
| Поле | Тип | Описание |
|------|-----|----------|
| id | INT AUTO_INCREMENT PRIMARY KEY | |
| user_id | INT NOT NULL | FOREIGN KEY → users(id) |
| action | VARCHAR(50) NOT NULL | Тип действия |
| file_id | INT DEFAULT NULL | FOREIGN KEY → files(id) |
| folder_id | INT DEFAULT NULL | FOREIGN KEY → folders(id) |
| details | JSON DEFAULT NULL | Детали в JSON |
| ip_address | VARCHAR(45) DEFAULT NULL | IP-адрес |
| created_at | TIMESTAMP DEFAULT CURRENT_TIMESTAMP | |

**Индексы:** idx_user_id, idx_action, idx_created_at, idx_file_id, idx_folder_id

**SQL-миграция:**
```sql
CREATE TABLE IF NOT EXISTS audit_log (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    action VARCHAR(50) NOT NULL,
    file_id INT DEFAULT NULL,
    folder_id INT DEFAULT NULL,
    details JSON DEFAULT NULL,
    ip_address VARCHAR(45) DEFAULT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id),
    INDEX idx_user_id (user_id),
    INDEX idx_action (action),
    INDEX idx_created_at (created_at),
    INDEX idx_file_id (file_id),
    INDEX idx_folder_id (folder_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
📡 ЧАСТЬ 3: API ENDPOINTS
Базовый URL
https://gazonbaza.ru (общий для мобильного и веб-приложения)

Авторизация
Все эндпоинты (кроме login.php и register.php) используют заголовок X-API-Token (не Authorization: Bearer).

Все эндпоинты:
Файл	Назначение	Логирование v5.6
register.php	Регистрация	-
login.php	Вход	✅ login
list_files.php	Список файлов и папок	-
upload.php	Загрузка файла	✅ upload
download.php	Скачивание файла (+ миниатюры)	✅ download
delete.php	Удаление файла	✅ delete
delete_folder.php	Удаление папки	✅ delete_folder
rename.php	Переименование файла	✅ rename
rename_folder.php	Переименование папки	✅ rename_folder
move_file.php	Перемещение файла	✅ move
move_folder.php	Перемещение папки (v5.5)	✅ move_folder
create_folder.php	Создание папки	✅ create_folder
toggle_visibility.php	Изменение видимости файла	✅ toggle_visibility
get_share_link.php	Создание публичной ссылки	✅ share
public_download.php	Скачивание по публичной ссылке	-
mark_viewed.php	Отметка о просмотре	-
profile.php	Профиль пользователя	-
audit_log.php 🆕	Просмотр логов (только админ)	-
log_action.php 🆕	Хелпер логирования (подключаемый)	-
Вспомогательные файлы:
auth.php — проверка токена (X-API-Token), возвращает пользователя

json_input.php — получение JSON из тела запроса

notification_helper.php — отправка push-уведомлений админам

Новый эндпоинт: audit_log.php (v5.6)
Метод: GET

Параметры: user_id, action, date_from, date_to, limit, offset

Доступ: только администратор (is_admin = 1)

Ответ: {"success":true,"data":[...],"total":N,"limit":50,"offset":0}

JOIN: с таблицей users для получения nickname

Логирование действий (v5.6)
Хелпер: log_action.php — функция logAudit($pdo, $userId, $action, $fileId, $folderId, $details)

Формат details (JSON):

Для файлов: {"file_name": "...", "file_size": ...}

Для папок: {"folder_name": "..."}

Для перемещения: {"file_name": "...", "from_folder": "...", "to_folder": "..."}

Для переименования: {"old_name": "...", "new_name": "..."}

IP-адрес: $_SERVER['REMOTE_ADDR']

Логирование асинхронное — не замедляет основные операции

Исправления в upload.php (v5.3)
✅ Убран дублирующий INSERT (файлы больше не дублируются в БД)

✅ Переменные $isPublic, $folderId, $description определяются до использования

✅ Добавлено поле description в INSERT-запрос

Новый эндпоинт: move_folder.php (v5.5)
Принимает: folder_id, target_folder_id (null = корень)

Проверка прав: админ или владелец папки

Защита от рекурсии: нельзя переместить папку в саму себя или потомка

Возвращает: {"status": "success"} / {"status": "error", "message": "..."}

📱 ЧАСТЬ 4: FLUTTER-ПРИЛОЖЕНИЕ (v5.6 — кросс-платформенное)
Технологии
Фреймворк: Flutter (Dart)

Минимальная версия SDK: ^3.0.0

Целевые платформы: Android (APK) + Web (HTML/JS)

Репозиторий: https://github.com/rubigruz-creator/adidas-obmennik (Public)

Ветки:

main — стабильная версия Android (v5.1)

feature/web-version — веб-версия и документация (v5.2–v5.6)

Актуальные зависимости (pubspec.yaml v5.6)
yaml
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
  universal_html: ^2.2.4
Структура проекта (v5.6)
text
lib/
├── main.dart
├── screens/
│   ├── splash_screen.dart
│   ├── login_screen.dart
│   ├── files_screen.dart              # v5.5: Режим выбора, групповые удаление/перемещение, динамический AppBar
│   ├── file_operations.dart           # v5.3: Превью в меню файла, kIsWeb-проверки
│   ├── folder_operations.dart
│   ├── upload_operations.dart         # v5.4: Множественная загрузка (UploadTask, MultiUploadDialog)
│   ├── profile_screen.dart            # v5.6: Кнопка «История действий» для админов
│   ├── lock_screen.dart
│   └── audit_log_screen.dart          # 🆕 v5.6: Экран истории действий (только для админов)
├── widgets/
│   ├── file_card.dart                 # v5.5: Чекбокс для режима выбора, isSelected-подсветка
│   ├── file_list_tile.dart            # v5.5: Чекбокс для режима выбора, выделение строки
│   ├── folder_card.dart               # v5.5: Чекбокс для режима выбора, isSelected-подсветка
│   ├── folder_list_tile.dart          # v5.5: Чекбокс для режима выбора
│   ├── file_icon.dart
│   ├── empty_state.dart
│   └── breadcrumb_chips.dart
├── utils/
│   ├── app_config.dart
│   ├── format_file_size.dart
│   ├── format_date.dart
│   └── platform_utils.dart
└── services/
    ├── api_service.dart               # v5.6: Добавлены методы moveFolder(), getAuditLog()
    ├── auth_service.dart
    ├── notification_service.dart
    ├── websocket_service.dart
    ├── storage_service.dart
    ├── platform_storage_mobile.dart
    ├── platform_storage_web.dart
    └── service_locator.dart
Ресурсы
assets/animations/adidas.json

assets/logo/adidas_logo.svg

android/app/src/main/res/mipmap-*

web/ — собранная веб-версия

🖥️ ЧАСТЬ 5: ВЕБ-ВЕРСИЯ (v5.6)
Сборка и деплой
powershell
# Локальная сборка (ПК, PowerShell)
cd C:\Users\USER\my_api_app
flutter build web --base-href "/app/"

# Загрузка на сервер (ПК)
scp -r build/web/* rubi@90.156.171.36:/home/rubi/web/gazonbaza.ru/public_html/web/

# Права на сервере
ssh rubi@90.156.171.36 "chown -R rubi:rubi /home/rubi/web/gazonbaza.ru/public_html/web && chmod -R 755 /home/rubi/web/gazonbaza.ru/public_html/web"
URL: https://gazonbaza.ru/app

Сборка APK
powershell
cd C:\Users\USER\my_api_app
flutter build apk --release
# APK: build/app/outputs/flutter-apk/app-release.apk
Особенности веб-версии
Единая кодовая база с мобильным приложением

Платформенные проверки через kIsWeb

StorageService: SharedPreferences вместо FlutterSecureStorage

Upload: ApiService.uploadFileBytes (байты напрямую, без временных файлов)

Download: AnchorElement + Blob URL (браузерное скачивание)

WebSocket: socket_io_client с polling-транспортом

CORS: не требуется (тот же домен)

Права доступа: не требуются (браузер)

PIN-код: отключён в main.dart для веб-версии

Режим выбора: активируется правым кликом мыши на файле/папке

🆕 ЧАСТЬ 6: НОВОЕ В v5.6 — АУДИТ ДЕЙСТВИЙ ПОЛЬЗОВАТЕЛЯ
✅ Реализовано: Система логирования всех действий
6.1 Серверная часть
Таблица audit_log — 8 полей, 6 индексов

Хелпер log_action.php — функция logAudit() для унифицированного логирования

Эндпоинт audit_log.php — просмотр логов с фильтрацией и пагинацией

Логирование в 12 скриптах: login, upload, download, delete, delete_folder, rename, rename_folder, move_file, move_folder, create_folder, toggle_visibility, get_share_link

6.2 Flutter-приложение
Метод ApiService.getAuditLog() — запрос к audit_log.php с параметрами фильтрации

Экран audit_log_screen.dart — история действий с:

Бесконечным скроллом (по 50 записей)

Pull-to-refresh

Фильтрами по типу действия (FilterChip)

Фильтрами по дате (диапазон)

Иконками и цветами для каждого типа действия

Отображением: пользователь (nickname), действие, детали, дата, IP

Кнопка «История действий» в профиле (только для админов, is_admin == 1)

6.3 Типы логируемых действий
action	Иконка	Цвет	Описание
login	login	🟢 зелёный	Вход пользователя
upload	upload_file	🔵 синий	Загрузка файла
download	download	🔷 индиго	Скачивание файла
delete	delete	🔴 красный	Удаление файла
delete_folder	delete_outline	🔴 красный	Удаление папки
rename	drive_file_rename_outline	🟠 оранжевый	Переименование файла
rename_folder	drive_file_rename_outline	🟠 оранжевый	Переименование папки
move	move_up	🟣 фиолетовый	Перемещение файла
move_folder	move_up	🟣 фиолетовый	Перемещение папки
create_folder	create_new_folder	🟢 бирюзовый	Создание папки
toggle_visibility	visibility	🟡 жёлтый	Изменение видимости
share	share	🟦 голубой	Создание публичной ссылки
6.4 Затронутые файлы (v5.6)
Файл	Действие
public_html/log_action.php	🆕 Создан — хелпер логирования
public_html/audit_log.php	🆕 Создан — эндпоинт просмотра логов
public_html/login.php	✏️ Добавлено логирование входа
public_html/upload.php	✏️ Добавлено логирование загрузки
public_html/download.php	✏️ Добавлено логирование скачивания
public_html/delete.php	✏️ Добавлено логирование удаления файла
public_html/delete_folder.php	✏️ Добавлено логирование удаления папки
public_html/rename.php	✏️ Добавлено логирование переименования
public_html/rename_folder.php	✏️ Добавлено логирование переименования папки
public_html/move_file.php	✏️ Добавлено логирование перемещения файла
public_html/move_folder.php	✏️ Добавлено логирование перемещения папки
public_html/create_folder.php	✏️ Добавлено логирование создания папки
public_html/toggle_visibility.php	✏️ Добавлено логирование изменения видимости
public_html/get_share_link.php	✏️ Добавлено логирование создания ссылки
lib/services/api_service.dart	✏️ Добавлен метод getAuditLog()
lib/screens/audit_log_screen.dart	🆕 Создан — экран истории
lib/screens/profile_screen.dart	✏️ Добавлена кнопка «История действий»
SQL-миграция	🆕 Создана таблица audit_log
🆕 ЧАСТЬ 7: НОВОЕ В v5.5 — МНОЖЕСТВЕННАЯ ОБРАБОТКА ФАЙЛОВ (СОХРАНЕНО)
Режим выбора (Selection Mode)
Вход: долгое нажатие (Android) / правый клик мыши (Web)

Выбор нескольких: тап/клик по элементам

Визуальная индикация: чекбоксы, синяя обводка, подсветка фона

Автовыход: при снятии выделения с последнего элемента

Динамический AppBar
Заголовок: «Выбрано: N»

Кнопки: «Удалить», «Переместить», «Отмена»

FAB скрывается в режиме выбора

Групповые операции
Удаление: диалог подтверждения → последовательное удаление → SnackBar

Перемещение: диалог выбора папки → последовательное перемещение → SnackBar

Защита от рекурсии при перемещении папок

Затронутые файлы (v5.5)
Файл	Изменения
lib/screens/files_screen.dart	Режим выбора, групповые операции, динамический AppBar
lib/widgets/file_card.dart	Чекбокс, синяя обводка
lib/widgets/file_list_tile.dart	Чекбокс, подсветка фона
lib/widgets/folder_card.dart	Чекбокс, обводка
lib/widgets/folder_list_tile.dart	Чекбокс
lib/services/api_service.dart	Метод moveFolder()
public_html/move_folder.php	🆕 Новый скрипт
🆕 ЧАСТЬ 8: НОВОЕ В v5.4 — МНОЖЕСТВЕННАЯ ЗАГРУЗКА (СОХРАНЕНО)
Выбор нескольких файлов через FilePicker.platform.pickFiles(allowMultiple: true)

Диалог очереди загрузки с индивидуальным прогрессом

Общие настройки: видимость и описание для всех файлов

Кнопка отмены для каждого файла и «Отменить всё»

Классы: UploadTask, MultiUploadDialog, MultiUploadDialogState

Автоматическое обновление списка после завершения

📜 ЧАСТЬ 9: ИСТОРИЯ ВЕРСИЙ
v5.6 (текущая) — АУДИТ ДЕЙСТВИЙ ПОЛЬЗОВАТЕЛЯ
✅ Таблица audit_log в MariaDB (8 полей, 6 индексов)

✅ Хелпер log_action.php для унифицированного логирования

✅ Эндпоинт audit_log.php с фильтрами и пагинацией

✅ Логирование в 12 PHP-скриптах

✅ Экран «История действий» (только для админов)

✅ Бесконечный скролл, pull-to-refresh, фильтры

✅ Метод ApiService.getAuditLog()

✅ Кнопка «История» в профиле админа

✅ Протестировано на Android (APK) и Web

v5.5 — МНОЖЕСТВЕННАЯ ОБРАБОТКА ФАЙЛОВ
✅ Режим выбора с чекбоксами

✅ Групповое удаление и перемещение

✅ Динамический AppBar

✅ Защита от рекурсии

✅ moveFolder() + move_folder.php

v5.4 — МНОЖЕСТВЕННАЯ ЗАГРУЗКА
✅ Множественная загрузка через FilePicker

✅ Диалог очереди с прогрессом

✅ Кнопки отмены

v5.3 — ИСПРАВЛЕНИЯ И СТАБИЛИЗАЦИЯ
✅ Исправлено дублирование файлов

✅ Превью изображений

✅ Исправлено скачивание в вебе

✅ Таймауты сервера

v5.2 — ВЕБ-ВЕРСИЯ И ДОКУМЕНТАЦИЯ
✅ Веб-версия на gazonbaza.ru/app

✅ Кросс-платформенный код (kIsWeb)

✅ StorageService

v5.1 — БРЕНДИНГ, БЕЗОПАСНОСТЬ
✅ Логотип, Splash Screen, PIN-код

✅ Material 3, чёрно-красная гамма

v5.0 — СОЦИАЛЬНЫЕ ФУНКЦИИ
✅ Поделиться, индикатор новых файлов, фильтры

v4.2 — ПРЕДПРОСМОТР И ОПТИМИЗАЦИЯ
v4.1 — ПЕРЕРАБОТКА UI
v4.0 — PUSH-УВЕДОМЛЕНИЯ
v3.1 — ПРОФИЛЬ И ПРОГРЕСС-БАРЫ
v3.0 — ПАПКИ И КАТЕГОРИИ
v2.0 — УЛУЧШЕНИЯ
v1.0 — БАЗОВАЯ ВЕРСИЯ
⚠️ ИЗВЕСТНЫЕ ОШИБКИ И УРОКИ (v5.6)
BOM в PHP-файлах ломает JSON. PowerShell Out-File по умолчанию добавляет BOM в UTF-8 файлы. Все PHP-файлы должны быть в кодировке UTF-8 without BOM. Проверка: head -1 file.php | xxd | head -1 — должно начинаться с 3c3f (без efbbbf).

PowerShell съедает символ $ в heredoc-строках. Лучше заменять код через VSCode или экранировать через backtick.

uploadFileBytesWithProgress не работает — не отправляет тело запроса. Использовать uploadFileBytes без реального прогресса.

Локальный запуск через localhost вызывает CORS-ошибки. Тестировать на production-домене.

Веб-сборка только на локальном ПК — на сервере нет Flutter SDK. Сборка → scp на сервер.

В веб-версии долгое нажатие не работает — использовать правый клик мыши (onSecondaryTap) для входа в режим выбора.

Tree-shaking вырезает приватные классы. Все классы, используемые в другом контексте, должны быть публичными.

Авторизация через X-API-Token, не через Authorization: Bearer. auth.php ищет заголовок X-API-Token.

Icons.delete_folder недоступна в некоторых версиях Flutter — использовать Icons.delete_outline.

Функция formatRelativeDate (не formatDate) в format_date.dart.

🔜 ПЛАНЫ НА БУДУЩЕЕ
🎨 Улучшение UI — правка цветов и размеров деталей (следующий этап)

🔄 Drag-and-drop в веб-версии

🔐 Двухфакторная аутентификация

🔒 Шифрование файлов

📊 Исправление uploadFileBytesWithProgress (реальный прогресс)

👥 Список пользователей для фильтра в audit_log

🚫 logout.php — эндпоинт для логирования выхода

🚀 Статус v5.6
Аудит действий пользователя реализован и протестирован:

✅ Таблица audit_log создана и работает

✅ 12 PHP-скриптов логируют действия

✅ Эндпоинт audit_log.php с фильтрацией и пагинацией

✅ Экран «История действий» в Flutter (Android + Web)

✅ Доступ только для администраторов

✅ Бесконечный скролл, pull-to-refresh, фильтры

✅ Иконки и цвета для каждого типа действия

✅ Протестировано на Android (APK) и Web (gazonbaza.ru/app)

✅ Обратная совместимость сохранена

Проект готов к следующему этапу — улучшение UI приложения и веб-версии.
"@ | Out-File -FilePath "C:\Users\USER\my_api_app\docs\Project_map_5.6.md" -Encoding UTF8

text

---

## ✅ Документация обновлена!

Файл создан: `C:\Users\USER\my_api_app\docs\Project_map_5.6.md`

**Что добавлено:**
- 🆕 Таблица `audit_log` (структура, SQL-миграция)
- 🆕 Эндпоинты `audit_log.php` и `log_action.php`
- 🆕 Таблица логирования по всем скриптам
- 🆕 Структура Flutter: `audit_log_screen.dart`, обновлённые `api_service.dart` и `profile_screen.dart`
- 🆕 Секция v5.6 в истории версий
- ⚠️ Обновлён список известных ошибок (BOM, X-API-Token, formatRelativeDate, Icons.delete_folder)
- 🎨 Планы: улучшение UI

Готов к улучшению UI! Показывай, какие цвета и размеры нужно поправить 🎨