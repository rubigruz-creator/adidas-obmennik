🗺️ КУСОЧНИЦА — Полная техническая карта проекта (v4.0)
📌 ЧАСТЬ 1: СЕРВЕР
Провайдер и доступ
Хостинг: BeGet (VPS)

IP-адрес: 90.156.171.36

Домен: gazonbaza.ru

Доступ: SSH через терминал

Путь к домену: /home/rubi/web/gazonbaza.ru/

Операционная система
ОС: Ubuntu

Пользователь: rubi

Группа: www-data (для веб-сервера)

Управление сервером
Панель управления: HestiaCP

Расположение конфигов: /home/rubi/conf/web/gazonbaza.ru/

Связка: Nginx (прокси) → Apache2 (порт 8080)

Веб-сервер (Nginx)
Конфиг: /home/rubi/conf/web/gazonbaza.ru/nginx.conf

SSL-конфиг: /home/rubi/conf/web/gazonbaza.ru/nginx.ssl.conf

Прокси на: http://90.156.171.36:8080

WebSocket прокси: /socket.io/ → http://127.0.0.1:3001

PHP
Версия: 8.1

Конфиг: /etc/php/8.1/fpm/php.ini

Важные настройки для файлов:

ini
upload_max_filesize = 300M
post_max_size = 300M
max_execution_time = 600
memory_limit = 512M
Перезагрузка: sudo systemctl restart php8.1-fpm

Пути к файлам проекта
Корень сайта (public): /home/rubi/web/gazonbaza.ru/public_html/

Логи: /var/log/apache2/domains/gazonbaza.ru.error.log

Хранилище файлов: /home/rubi/web/gazonbaza.ru/public_html/files/

Бэкапы: через HestiaCP

Nginx запрет прямого доступа к файлам
В конфиг добавлено: /files/ → deny all; return 403;

💾 ЧАСТЬ 2: БАЗА ДАННЫХ
Система
СУБД: MariaDB

База данных: avito_shop

Пользователь БД: api_user

Пароль: StrongPass123!

Структура таблиц
1. users — пользователи
sql
id INT AUTO_INCREMENT PRIMARY KEY
phone VARCHAR(20) NOT NULL UNIQUE
password_hash VARCHAR(255) NOT NULL
nickname VARCHAR(50)
full_name VARCHAR(100)
position VARCHAR(100)
is_admin TINYINT(1) DEFAULT 0
created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
2. user_sessions — токены сессий
sql
id INT AUTO_INCREMENT PRIMARY KEY
user_id INT NOT NULL
api_token VARCHAR(64) NOT NULL UNIQUE
expires_at TIMESTAMP NOT NULL
created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
3. files — файлы
sql
id INT AUTO_INCREMENT PRIMARY KEY
user_id INT NOT NULL
original_name VARCHAR(255) NOT NULL
stored_name VARCHAR(255) NOT NULL
file_size INT NOT NULL
file_type VARCHAR(100)
is_public BOOLEAN DEFAULT FALSE
folder_id INT DEFAULT NULL
upload_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP
FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
FOREIGN KEY (folder_id) REFERENCES folders(id) ON DELETE SET NULL
4. folders — папки
sql
id INT AUTO_INCREMENT PRIMARY KEY
user_id INT NOT NULL
name VARCHAR(255) NOT NULL
parent_id INT DEFAULT NULL
created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
FOREIGN KEY (parent_id) REFERENCES folders(id) ON DELETE CASCADE
5. api_keys — ключи API (устаревшая, не используется)
sql
id INT AUTO_INCREMENT PRIMARY KEY
api_key VARCHAR(64) NOT NULL UNIQUE
app_name VARCHAR(100) NOT NULL
is_active TINYINT(1) DEFAULT 1
created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
Полезные команды
bash
# Вход в MariaDB
sudo mariadb -u root -p

# Выбор базы
USE avito_shop;

# Показать таблицы
SHOW TABLES;

# Назначить админа
UPDATE users SET is_admin = 1 WHERE phone = '111111';
📡 ЧАСТЬ 3: API ENDPOINTS
Базовый URL
https://gazonbaza.ru (клиент использует IP 90.156.171.36 с заголовком Host: gazonbaza.ru)

Существующие эндпоинты
1. register.php — регистрация
Метод: POST

Заголовки: Content-Type: application/json, Host: gazonbaza.ru

Тело: {"phone":"...","password":"...","nickname":"...","full_name":"...","position":"..."}

Ответ: {"status":"success","user_id":1}

2. login.php — вход
Метод: POST

Тело: {"phone":"...","password":"..."}

Ответ: {"status":"success","api_token":"...","user":{"id":1,"nickname":"...","is_admin":0},"expires_at":"..."}

3. list_files.php — список файлов и папок
Метод: GET

Заголовок: X-API-Token: токен, Host: gazonbaza.ru

Параметры: ?folder_id=1 (опционально), ?search=запрос

Ответ:

json
{
  "status": "success",
  "folders": [{"id":1,"name":"Папка","parent_id":null}],
  "files": [{"id":1,"original_name":"file.txt","folder_id":1}]
}
4. upload.php — загрузка файла
Метод: POST

Заголовок: X-API-Token: токен, Host: gazonbaza.ru

Формат: multipart/form-data

Поля: file (файл), is_public (0/1), folder_id (опционально)

Ответ: {"status":"success","file_id":2}

🔔 Уведомление: После загрузки автоматически отправляет push-уведомление всем администраторам через WebSocket-сервис

5. download.php — скачивание файла
Метод: GET

Заголовок: X-API-Token: токен, Host: gazonbaza.ru

Параметры: ?id=file_id

Возвращает: бинарные данные файла

6. delete.php — удаление файла
Метод: POST

Заголовки: X-API-Token: токен, Content-Type: application/json

Тело: {"id":file_id}

Права: админ или владелец

Ответ: {"status":"success","message":"File deleted"}

7. rename.php — переименование файла
Метод: POST

Заголовки: X-API-Token: токен, Content-Type: application/json

Тело: {"id":file_id,"new_name":"новое имя"}

Права: админ или владелец

Ответ: {"status":"success","message":"File renamed successfully"}

8. toggle_visibility.php — переключение видимости файла
Метод: POST

Заголовки: X-API-Token: токен, Content-Type: application/json

Тело: {"id":file_id}

Права: админ или владелец

Ответ: {"status":"success","message":"Visibility toggled","data":{"id":file_id,"is_public":0|1}}

9. profile.php — управление профилем (v3.1)
Метод: GET — получение данных

Метод: POST — обновление полей

Заголовки: X-API-Token: токен, Content-Type: application/json

Тело POST: {"nickname":"...","full_name":"...","position":"..."}

Права: только свой профиль (админ может редактировать чужие — опционально)

Ответ: {"status":"success","data":{"id":1,"phone":"...","nickname":"...","full_name":"...","position":"...","is_admin":0}}

Эндпоинты для папок (v3.0)
10. create_folder.php — создание папки
Метод: POST

Заголовки: X-API-Token: токен, Content-Type: application/json

Тело: {"name":"Новая папка","parent_id":null}

Ответ: {"status":"success","folder_id":1}

11. delete_folder.php — удаление папки
Метод: POST

Заголовки: X-API-Token: токен, Content-Type: application/json

Тело: {"id":1,"force":true}

Права: админ или владелец

Ответ: {"status":"success","message":"Folder deleted"}

12. rename_folder.php — переименование папки
Метод: POST

Заголовки: X-API-Token: токен, Content-Type: application/json

Тело: {"id":1,"new_name":"Новое имя"}

Права: админ или владелец

Ответ: {"status":"success","message":"Folder renamed"}

13. list_folders.php — список папок
Метод: GET

Заголовок: X-API-Token: токен

Параметры: ?parent_id=1 (опционально)

Ответ: {"status":"success","folders":[...]}

14. move_file.php — перемещение файла в папку
Метод: POST

Заголовки: X-API-Token: токен, Content-Type: application/json

Тело: {"file_id":123,"folder_id":1} (или "folder_id":null для корня)

Права: админ или владелец

Ответ: {"status":"success","message":"File moved"}

15. auth.php — проверка токена
php
$currentUser = authenticate($pdo);
// возвращает id, phone, nickname, full_name, position, is_admin
16. json_input.php — универсальный парсер входных данных (v4.0)
php
require_once __DIR__ . '/json_input.php';
$data = getInputData();
// Объединяет $_GET, $_POST и JSON из тела запроса
📱 ЧАСТЬ 4: FLUTTER-ПРИЛОЖЕНИЕ (v4.0)
Технологии
Фреймворк: Flutter (Dart)

Минимальная версия SDK: ^3.0.0

Целевая платформа: Android (APK)

Структура проекта
text
lib/
├── main.dart                 # Точка входа, обход SSL, инициализация уведомлений
├── screens/
│   ├── login_screen.dart     # Вход/регистрация, запуск WebSocket
│   ├── files_screen.dart     # Список файлов и папок, навигация, загрузка
│   └── profile_screen.dart   # Экран профиля
├── widgets/
│   ├── file_pill.dart        # Виджет цветной пилюли для файлов
│   └── folder_pill.dart      # Виджет папки
└── services/
    ├── api_service.dart      # Все запросы к серверу (IP + заголовок Host)
    ├── auth_service.dart     # Работа с токеном (SharedPreferences)
    ├── notification_service.dart  # Локальные push-уведомления (v4.0)
    └── websocket_service.dart     # WebSocket-клиент для уведомлений (v4.0)
Зависимости (pubspec.yaml)
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
  socket_io_client: ^2.0.3           # WebSocket (v4.0)
  flutter_local_notifications: ^17.2.4  # Локальные уведомления (v4.0)
Ключевые переменные
dart
static const String _baseUrl = 'https://90.156.171.36';  // IP сервера
static const String _host = 'gazonbaza.ru';               // Заголовок Host
Особенности клиента
Используется IP-адрес с заголовком Host для обхода проблем DNS на эмуляторе

SSL-сертификат обходится через HttpOverrides в main.dart (только для разработки)

Все запросы содержат заголовок Host: gazonbaza.ru

Хранение данных на клиенте (SharedPreferences):

api_token — токен авторизации

user_id — ID пользователя

user_nickname — ник

is_admin — права админа (0 или 1)

Основной функционал (v3.0)
✅ Регистрация нового пользователя
✅ Вход по телефону/паролю
✅ Автоматическое сохранение токена
✅ Загрузка любых файлов (до 300 МБ)
✅ Выбор "Общий/Личный" при загрузке
✅ Фото из галереи и с камеры
✅ Скачивание файлов в общедоступную папку Downloads
✅ Удаление файлов (свои или любые — для админа)
✅ Переименование файлов (владелец или админ)
✅ Переключение видимости файла (владелец или админ)
✅ Поиск файлов по имени
✅ Цветные пилюли с сортировкой (новые — крупнее)

Функционал папок (v3.0)
✅ Создание папок (иерархическая структура)
✅ Навигация по папкам (хлебные крошки, кнопка "Назад")
✅ Перемещение файлов между папками и в корень
✅ Переименование папок (долгое нажатие или меню)
✅ Удаление папок (с перемещением файлов в родительскую папку)
✅ Отображение папок и файлов в общем списке
✅ FloatingActionButton для быстрого создания папки

Функционал v3.1
✅ Редактирование профиля пользователя
✅ Прогресс-бары при загрузке/скачивании
✅ Проверка mounted во всех асинхронных операциях
✅ Отмена таймеров в dispose()

🔔 НОВЫЙ ФУНКЦИОНАЛ v4.0 — PUSH-УВЕДОМЛЕНИЯ
✅ WebSocket-сервер на Node.js + Socket.IO (порт 3001)
✅ Автоматическая отправка уведомлений администраторам при загрузке новых файлов
✅ Локальные push-уведомления на Android через flutter_local_notifications
✅ WebSocket-подключение при входе, отключение при выходе
✅ Автоматическое переподключение при обрыве связи
✅ Универсальный сервис — можно подключить к другим проектам
✅ Логирование уведомлений в SQLite на сервере

Сборка APK
bash
flutter clean
flutter pub get
flutter build apk --release
Выход: build/app/outputs/flutter-apk/app-release.apk

Настройки Android (AndroidManifest.xml)
xml
<uses-permission android:name="android.permission.INTERNET"/>
<uses-permission android:name="android.permission.ACCESS_NETWORK_STATE"/>
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" android:maxSdkVersion="28"/>
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" android:maxSdkVersion="32"/>
<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
android:usesCleartextTraffic="true"
📁 ЧАСТЬ 5: ХРАНИЛИЩЕ ФАЙЛОВ
Расположение
/home/rubi/web/gazonbaza.ru/public_html/files/

Права доступа
bash
chmod 755 /home/rubi/web/gazonbaza.ru/public_html/files
chown rubi:www-data /home/rubi/web/gazonbaza.ru/public_html/files
Формат имени файла на сервере
{timestamp}_{random_hash}.{ext}
Пример: 1777896982_9340d91718633a02.txt

Защита
Через Nginx настроен запрет прямого доступа к /files/

Лимиты
Максимальный размер файла: 300 МБ (настраивается в php.ini и в проверке upload.php)

🔐 ЧАСТЬ 6: БЕЗОПАСНОСТЬ
Авторизация
API-токен длиной 64 символа (bin2hex(random_bytes(32)))

Токен передаётся в заголовке: X-API-Token

Токен живёт 30 дней (expires_at)

Просроченные токены удаляются автоматически

Пароли
Хранятся в БД в виде хэша: password_hash($password, PASSWORD_DEFAULT)

Проверка: password_verify($input, $hash)

Права доступа
Обычный пользователь: управляет только своими файлами и папками

Админ (is_admin = 1): управляет любыми файлами и папками

Общие файлы (is_public = 1): видны всем

Личные файлы: видны только владельцу

Папки: пользователь видит только свои, админ — все

Защита от прямого доступа
Папка /files/ закрыта через Nginx

Доступ к файлам только через download.php с проверкой токена

CORS
Для всех PHP эндпоинтов добавлены заголовки:

php
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Headers: X-API-Token, Content-Type');
🔔 ЧАСТЬ 7: СЕРВИС УВЕДОМЛЕНИЙ (WebSocket) v4.0
Расположение
Сервер: /home/rubi/websocket_service/

База логов: /home/rubi/websocket_service/data/notifications.db (SQLite)

Логи: pm2 logs websocket-notify

Конфигурация
Порт: 3001 (localhost)

Секретный ключ API: в .env файле (API_KEY)

Nginx прокси: /socket.io/ → http://127.0.0.1:3001

API эндпоинты
POST /notify — отправка уведомления (защищён X-API-Key)

GET /health — проверка работоспособности

Интеграция с PHP
notification_helper.php — универсальные функции для отправки уведомлений

Автоматическая отправка при загрузке файлов в upload.php

Управление
bash
pm2 status
pm2 logs websocket-notify
pm2 restart websocket-notify
🧪 ЧАСТЬ 8: ТЕСТОВЫЕ ДАННЫЕ
Администратор
Телефон: 111111

Пароль: 111111

is_admin: 1

Обычный пользователь
Телефон: +79001234567

Пароль: задан при регистрации

is_admin: 0

Тестовые команды (curl)
Получить токен
bash
curl -X POST https://gazonbaza.ru/login.php \
  -H "Content-Type: application/json" \
  -d '{"phone":"111111","password":"111111"}'
Получить профиль
bash
curl -X GET https://gazonbaza.ru/profile.php \
  -H "X-API-Token: ТОКЕН"
Обновить профиль
bash
curl -X POST https://gazonbaza.ru/profile.php \
  -H "X-API-Token: ТОКЕН" \
  -H "Content-Type: application/json" \
  -d '{"nickname":"новыйник","position":"Team Lead"}'
Создать папку
bash
curl -X POST https://gazonbaza.ru/create_folder.php \
  -H "X-API-Token: ТОКЕН" \
  -H "Content-Type: application/json" \
  -d '{"name":"Тестовая папка"}'
Загрузить файл в папку
bash
echo "Hello" > /tmp/test.txt
curl -X POST https://gazonbaza.ru/upload.php \
  -H "X-API-Token: ТОКЕН" \
  -F "file=@/tmp/test.txt" \
  -F "is_public=1" \
  -F "folder_id=1"
Получить содержимое папки
bash
curl -X GET "https://gazonbaza.ru/list_files.php?folder_id=1" \
  -H "X-API-Token: ТОКЕН"
Переместить файл
bash
curl -X POST https://gazonbaza.ru/move_file.php \
  -H "X-API-Token: ТОКЕН" \
  -H "Content-Type: application/json" \
  -d '{"file_id":123,"folder_id":1}'
Переименовать папку
bash
curl -X POST https://gazonbaza.ru/rename_folder.php \
  -H "X-API-Token: ТОКЕН" \
  -H "Content-Type: application/json" \
  -d '{"id":1,"new_name":"Новое имя"}'
Удалить папку (с перемещением файлов)
bash
curl -X POST https://gazonbaza.ru/delete_folder.php \
  -H "X-API-Token: ТОКЕН" \
  -H "Content-Type: application/json" \
  -d '{"id":1,"force":true}'
Отправить тестовое уведомление
bash
curl -X POST http://localhost:3001/notify \
  -H "Content-Type: application/json" \
  -H "X-API-Key: Ku5ocHn1cA_Ch4ng3M3_2024" \
  -d '{"user_id":2,"title":"Тест","body":"Проверка уведомлений","data":{"test":true}}'
Проверить здоровье сервиса уведомлений
bash
curl https://gazonbaza.ru/notify-health
🗺️ КАРТА ПРОЕКТА
text
КОРЕНЬ ПРОЕКТА: /home/rubi/web/gazonbaza.ru/
│
├── public_html/               # Доступно из веба
│   ├── auth.php              # Проверка токена (включается)
│   ├── register.php          # Регистрация
│   ├── login.php             # Вход, выдача токена
│   ├── profile.php           # Управление профилем (v3.1)
│   ├── list_files.php        # Список файлов и папок + поиск
│   ├── upload.php            # Загрузка файлов + уведомления (v4.0)
│   ├── download.php          # Скачивание файлов
│   ├── delete.php            # Удаление файлов
│   ├── rename.php            # Переименование файлов
│   ├── toggle_visibility.php # Переключение общий/личный
│   ├── create_folder.php     # Создание папки
│   ├── delete_folder.php     # Удаление папки
│   ├── rename_folder.php     # Переименование папки
│   ├── list_folders.php      # Список папок
│   ├── move_file.php         # Перемещение файла
│   ├── json_input.php        # Парсер JSON (v4.0)
│   ├── notification_helper.php # Отправка уведомлений (v4.0)
│   ├── files/                # Хранилище файлов (закрыто через Nginx)
│   │   └── *.txt, *.jpg...
│   └── (старые резервные копии)
│
├── conf/web/gazonbaza.ru/    # Конфиги HestiaCP
│   ├── nginx.conf
│   ├── nginx.ssl.conf
│   └── apache2.conf
│
├── logs/                     # Логи домена
├── private/                  # Приватные файлы
└── stats/                    # Статистика

СЕРВИС УВЕДОМЛЕНИЙ:
/home/rubi/websocket_service/
│
├── server.js                 # Node.js + Socket.IO сервер
├── package.json
├── .env                      # API_KEY, настройки БД
└── data/
    └── notifications.db      # SQLite база логов
📋 СХЕМА БАЗЫ ДАННЫХ
text
avito_shop (MariaDB)
│
├── users
│   ├── id (PK)
│   ├── phone (UNIQUE)
│   ├── password_hash
│   ├── nickname
│   ├── full_name
│   ├── position
│   ├── is_admin (0/1)
│   └── created_at
│
├── user_sessions
│   ├── id (PK)
│   ├── user_id (FK → users.id)
│   ├── api_token (UNIQUE, 64)
│   ├── expires_at
│   └── created_at
│
├── files
│   ├── id (PK)
│   ├── user_id (FK → users.id)
│   ├── original_name
│   ├── stored_name
│   ├── file_size
│   ├── file_type
│   ├── is_public (0/1)
│   ├── folder_id (FK → folders.id)
│   └── upload_date
│
├── folders
│   ├── id (PK)
│   ├── user_id (FK → users.id)
│   ├── name
│   ├── parent_id (FK → folders.id)
│   └── created_at
│
└── api_keys (устаревшая)

notifications.db (SQLite)
│
└── notification_logs
    ├── id INTEGER PRIMARY KEY
    ├── user_id INTEGER
    ├── title TEXT
    ├── body TEXT
    ├── data TEXT (JSON)
    └── sent_at DATETIME DEFAULT CURRENT_TIMESTAMP
📝 ИСТОРИЯ ИЗМЕНЕНИЙ
v4.0 (текущая) — PUSH-УВЕДОМЛЕНИЯ 🔔
✅ Создан WebSocket-сервер на Node.js + Socket.IO (порт 3001)

✅ Настроен Nginx прокси для /socket.io/

✅ Сервис работает через PM2 с автозапуском

✅ Создан PHP helper notification_helper.php для отправки уведомлений

✅ Интеграция в upload.php — уведомления при загрузке файлов

✅ Flutter: WebSocketService + NotificationService

✅ Локальные push-уведомления на Android

✅ Автоподключение WebSocket при входе, отключение при выходе

✅ Создан json_input.php для универсального парсинга JSON

✅ Исправлены все PHP-эндпоинты для работы с JSON

✅ Скачивание файлов в общедоступную папку Downloads

v3.1 — ПРОФИЛЬ И ПРОГРЕСС-БАРЫ
✅ Добавлен эндпоинт profile.php (GET/POST)

✅ Реализовано редактирование профиля

✅ Добавлен экран ProfileScreen в Flutter

✅ Прогресс-бары при загрузке/скачивании файлов

✅ Исправлены ошибки setState после dispose

v3.0 — ПАПКИ И КАТЕГОРИИ
✅ Добавлена таблица folders в БД

✅ Созданы API-эндпоинты для папок

✅ Обновлён list_files.php

✅ В Flutter добавлен виджет FolderPill

✅ Навигация по папкам, хлебные крошки

v2.0 — УЛУЧШЕНИЯ
✅ Переименование файлов

✅ Выбор "Общий/Личный"

✅ Поиск файлов

✅ Клиент переведён на IP с заголовком Host

v1.0 — БАЗОВАЯ ВЕРСИЯ
✅ Регистрация/вход

✅ Загрузка/скачивание/удаление файлов

✅ Права администратора

Итого: Система полностью готова. Работает файлообменник с иерархическими папками, профилями пользователей, прогресс-барами и push-уведомлениями. 🎉