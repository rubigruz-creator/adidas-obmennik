## 🗺️ КУСОЧНИЦА — Полная техническая карта проекта

***

# 📌 ЧАСТЬ 1: СЕРВЕР

## Провайдер и доступ

*   **Хостинг:** BeGet (VPS)
*   **IP-адрес:** `90.156.171.36`
*   **Домен:** `gazonbaza.ru`
*   **Доступ:** SSH через терминал
*   **Путь к домену:** `/home/rubi/web/gazonbaza.ru/`

## Операционная система

*   **ОС:** Ubuntu
*   **Пользователь:** `rubi`
*   **Группа:** `www-data` (для веб-сервера)

## Управление сервером

*   **Панель управления:** HestiaCP
*   **Расположение конфигов:** `/home/rubi/conf/web/gazonbaza.ru/`
*   **Связка:** Nginx (прокси) → Apache2 (порт 8080)

## Веб-сервер (Nginx)

*   **Конфиг:** `/home/rubi/conf/web/gazonbaza.ru/nginx.conf`
*   **Прокси на:** `http://90.156.171.36:8080`

## PHP

*   **Версия:** 8.1
*   **Конфиг:** `/etc/php/8.1/fpm/php.ini`
*   **Важные настройки для файлов:**
    ```ini
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

# 💾 ЧАСТЬ 2: БАЗА ДАННЫХ

Система
СУБД: MariaDB

База данных: avito_shop

Пользователь БД: api_user

Пароль: StrongPass123!

## Структура таблиц
### 1. users — пользователи
sql
id INT AUTO_INCREMENT PRIMARY KEY
phone VARCHAR(20) NOT NULL UNIQUE
password_hash VARCHAR(255) NOT NULL
nickname VARCHAR(50)
full_name VARCHAR(100)
position VARCHAR(100)
is_admin TINYINT(1) DEFAULT 0
created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
### 2. user_sessions — токены сессий
sql
id INT AUTO_INCREMENT PRIMARY KEY
user_id INT NOT NULL
api_token VARCHAR(64) NOT NULL UNIQUE
expires_at TIMESTAMP NOT NULL
created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
### 3. files — файлы
sql
id INT AUTO_INCREMENT PRIMARY KEY
user_id INT NOT NULL
original_name VARCHAR(255) NOT NULL
stored_name VARCHAR(255) NOT NULL
file_size INT NOT NULL
file_type VARCHAR(100)
is_public BOOLEAN DEFAULT FALSE
upload_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP
FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
### 4. api_keys — ключи API (устаревшая, не используется)
sql
id INT AUTO_INCREMENT PRIMARY KEY
api_key VARCHAR(64) NOT NULL UNIQUE
app_name VARCHAR(100) NOT NULL
is_active TINYINT(1) DEFAULT 1
created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP

# Полезные команды
bash
## Вход в MariaDB
sudo mariadb -u root -p
## Выбор базы
USE avito_shop;
## Показать таблицы
SHOW TABLES;
## Назначить админа

UPDATE users SET is_admin = 1 WHERE phone = '+71234567890';

# 📡 ЧАСТЬ 3: API ENDPOINTS

## Базовый URL
https://gazonbaza.ru (клиент использует IP 90.156.171.36 с заголовком Host: gazonbaza.ru)

## Эндпоинты

### 1. register.php — регистрация
Метод: POST

Заголовки: Content-Type: application/json, Host: gazonbaza.ru

Тело JSON: {"phone":"...","password":"...","nickname":"...","full_name":"...","position":"..."}

Ответ: {"status":"success","user_id":1}

### 2. login.php — вход
Метод: POST

Тело JSON: {"phone":"...","password":"..."}

Ответ: {"status":"success","api_token":"...","user":{"id":1,"nickname":"...","is_admin":0},"expires_at":"..."}

### 3. list_files.php — список файлов (с поиском)
Метод: GET

Заголовок: X-API-Token: токен, Host: gazonbaza.ru

Параметры: ?type=all|personal&search=запрос

Возвращает: список файлов с полями id, original_name, file_size, file_type, is_public, upload_date, owner_nickname, size_mb

### 4. upload.php — загрузка файла
Метод: POST

Заголовок: X-API-Token: токен, Host: gazonbaza.ru

Формат: multipart/form-data

Поля: file (файл), is_public (0/1)

Ответ: {"status":"success","file_id":2}

### 5. download.php — скачивание файла
Метод: GET

Заголовок: X-API-Token: токен, Host: gazonbaza.ru

Параметры: ?id=file_id

Возвращает: бинарные данные файла

### 6. delete.php — удаление файла
Метод: POST

Заголовок: X-API-Token: токен, Host: gazonbaza.ru

Параметры: ?id=file_id

Права: админ или владелец

Ответ: {"status":"success","message":"File deleted"}

### 7. rename.php — переименование файла
Метод: POST

Заголовок: X-API-Token: токен, Host: gazonbaza.ru, Content-Type: application/json

Тело JSON: {"id":file_id,"new_name":"новое имя"}

Права: админ или владелец

Ответ: {"status":"success","message":"File renamed successfully"}

### 8. toggle_visibility.php — переключение видимости
Метод: POST

Заголовок: X-API-Token: токен, Host: gazonbaza.ru, Content-Type: application/json

Тело JSON: {"id":file_id}

Права: админ или владелец

Ответ: {"status":"success","message":"Visibility toggled","data":{"id":file_id,"is_public":0|1}}

### 9. auth.php — проверка токена (включается в другие файлы)
php
$currentUser = authenticate($pdo);
// возвращает id, phone, nickname, full_name, position, is_admin


# 📱 ЧАСТЬ 4: FLUTTER-ПРИЛОЖЕНИЕ

## Технологии
Фреймворк: Flutter (Dart)

Минимальная версия SDK: ^3.0.0

Целевая платформа: Android (APK)

## Структура проекта

lib/
├── main.dart                 # Точка входа, обход SSL, запуск LoginScreen
├── screens/
│   ├── login_screen.dart     # Вход/регистрация
│   └── files_screen.dart     # Список файлов, загрузка, удаление, переименование, поиск
├── widgets/
│   └── file_pill.dart        # Виджет цветной пилюли
└── services/
    ├── api_service.dart      # Все запросы к серверу (IP + заголовок Host)
    └── auth_service.dart     # Работа с токеном (SharedPreferences)
## Зависимости (pubspec.yaml)
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
## Ключевые переменные
dart
static const String _baseUrl = 'https://90.156.171.36';  // IP сервера
static const String _host = 'gazonbaza.ru';               // Заголовок Host
## Особенности клиента
Используется IP-адрес с заголовком Host для обхода проблем DNS на эмуляторе

SSL-сертификат обходится через HttpOverrides в main.dart (для разработки)

Все запросы содержат заголовок Host: gazonbaza.ru

Хранение данных на клиенте (SharedPreferences)
api_token — токен авторизации

user_id — ID пользователя

user_nickname — ник

is_admin — права админа (0 или 1)

## Основной функционал

✅ Регистрация нового пользователя

✅ Вход по телефону/паролю

✅ Автоматическое сохранение токена

✅ Загрузка любых файлов (до 300 МБ)

✅ Выбор "Общий/Личный" при загрузке

✅ Фото из галереи и с камеры

✅ Скачивание файлов в папку Downloads

✅ Удаление файлов (свои или любые — для админа)

✅ Переименование файлов (владелец или админ)

✅ Переключение видимости файла (владелец или админ)

✅ Поиск файлов по имени

✅ Цветные пилюли с сортировкой (новые — крупнее)

## Сборка APK
bash
flutter clean
flutter pub get
flutter build apk --release
Выход: build/app/outputs/flutter-apk/app-release.apk

## Настройки Android (AndroidManifest.xml)
Добавлены:

<uses-permission android:name="android.permission.INTERNET"/>

<uses-permission android:name="android.permission.ACCESS_NETWORK_STATE"/>

android:usesCleartextTraffic="true"

# 📁 ЧАСТЬ 5: ХРАНИЛИЩЕ ФАЙЛОВ

## Расположение
/home/rubi/web/gazonbaza.ru/public_html/files/

## Права доступа
bash
chmod 755 /home/rubi/web/gazonbaza.ru/public_html/files
chown rubi:www-data /home/rubi/web/gazonbaza.ru/public_html/files
## Формат имени файла на сервере
{timestamp}_{random_hash}.{ext}
Пример: 1777896982_9340d91718633a02.txt

## Защита
Через Nginx настроен запрет прямого доступа к /files/

## Лимиты
Максимальный размер файла: 300 МБ

Настраивается в php.ini и в проверке upload.php

# 🔐 ЧАСТЬ 6: БЕЗОПАСНОСТЬ

## Авторизация
API-токен длиной 64 символа (bin2hex(random_bytes(32)))

Токен передаётся в заголовке: X-API-Token

Токен живёт 30 дней (expires_at)

Просроченные токены удаляются автоматически

## Пароли
Хранятся в БД в виде хэша: password_hash($password, PASSWORD_DEFAULT)

Проверка: password_verify($input, $hash)

## Права доступа
Обычный пользователь: управляет только своими файлами

Админ (is_admin = 1): управляет любыми файлами

Общие файлы (is_public = 1) видны всем

Личные файлы видны только владельцу

## Защита от прямого доступа
Папка /files/ закрыта через Nginx

Доступ к файлам только через download.php с проверкой токена

## CORS
Для всех PHP эндпоинтов добавлены заголовки:

php
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Headers: X-API-Token, Content-Type');

# 🧪 ЧАСТЬ 7: ТЕСТОВЫЕ ДАННЫЕ

Администратор
Телефон: 111111

Пароль: 111111

is_admin: 1

Обычный пользователь
Телефон: +79001234567

Пароль: (задан при регистрации)

is_admin: 0

## Тестовые команды
bash
### Получить токен
curl -X POST https://gazonbaza.ru/login.php \
  -H "Content-Type: application/json" \
  -d '{"phone":"111111","password":"111111"}'

### Загрузить файл
echo "Hello" > /tmp/test.txt
curl -X POST https://gazonbaza.ru/upload.php \
  -H "X-API-Token: ТОКЕН" \
  -F "file=@/tmp/test.txt" \
  -F "is_public=1"

### Поиск файлов
curl -X GET "https://gazonbaza.ru/list_files.php?type=all&search=test" \
  -H "X-API-Token: ТОКЕН"

### Переименовать
curl -X POST https://gazonbaza.ru/rename.php \
  -H "X-API-Token: ТОКЕН" \
  -H "Content-Type: application/json" \
  -d '{"id":10,"new_name":"new_name.jpg"}'

### Переключить видимость
curl -X POST https://gazonbaza.ru/toggle_visibility.php \
  -H "X-API-Token: ТОКЕН" \
  -H "Content-Type: application/json" \
  -d '{"id":10}'

# 🗺️ КАРТА ПРОЕКТА (для ИИ-агентов)

КОРЕНЬ ПРОЕКТА: /home/rubi/web/gazonbaza.ru/
│
├── public_html/               # Доступно из веба
│   ├── auth.php              # Проверка токена (включается)
│   ├── register.php          # Регистрация
│   ├── login.php             # Вход, выдача токена
│   ├── list_files.php        # Список файлов + поиск
│   ├── upload.php            # Загрузка файлов
│   ├── download.php          # Скачивание файлов
│   ├── delete.php            # Удаление файлов
│   ├── rename.php            # Переименование файлов
│   ├── toggle_visibility.php # Переключение общий/личный
│   ├── files/                # Хранилище файлов (закрыто через Nginx)
│   │   └── *.txt, *.jpg...
│   └── (старые резервные копии)
│
├── conf/web/gazonbaza.ru/    # Конфиги HestiaCP
│   ├── nginx.conf
│   └── apache2.conf
│
├── logs/                     # Логи домена
├── private/                  # Приватные файлы
└── stats/                    # Статистика

# 📋 БАЗЫ ДАННЫХ (схема)

avito_shop
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
│   └── upload_date
│
└── api_keys (устаревшая, можно удалить)
    ├── id
    ├── api_key
    ├── app_name
    ├── is_active
    └── created_at

# 🔄 АВТОРИЗАЦИЯ (Схема работы)

ПОЛЬЗОВАТЕЛЬ → register.php → СОЗДАЁТСЯ users

ПОЛЬЗОВАТЕЛЬ → login.php (телефон+пароль)

СЕРВЕР → password_verify() → Создаёт api_token → user_sessions

СЕРВЕР ← Возвращает {api_token, user{id,is_admin}}

КЛИЕНТ → Сохраняет token + userId + isAdmin в SharedPreferences

КЛИЕНТ → Все запросы с заголовками X-API-Token и Host

Эндпоинт → auth.php → Проверяет token → Возвращает currentUser

Если token просрочен: 401 Unauthorized

# 📝 ИСТОРИЯ ИЗМЕНЕНИЙ
v2.0 (текущая)
✅ Добавлено переименование файлов (rename.php + UI)

✅ Добавлен выбор "Общий/Личный" при загрузке

✅ Добавлено переключение видимости файла из меню

✅ Добавлен поиск файлов по имени

✅ Клиент переведён на IP с заголовком Host (фикс DNS эмулятора)

✅ Добавлен обход SSL для разработки

✅ Обновлён AndroidManifest (INTERNET, CleartextTraffic)

✅ Рефакторинг кода, удаление отладочных логов

✅ Обновлена документация

v1.0 (исходная)
Базовая регистрация/вход

Загрузка/скачивание/удаление файлов

Права администратора

Цветные пилюли файлов

text

---

## Итого:

✅ **Рефакторинг выполнен:**
- Убраны `print()` логи
- Очищены комментарии с кракозябрами
- Переменная `_searchController` стала `final`
- `catch` теперь показывает SnackBar пользователю вместо `print`

✅ **Документация обновлена:**
- Добавлены эндпоинты `rename.php`, `toggle_visibility.php`
- Обновлён `list_files.php` (параметр `search`)
- Обновлена структура Flutter-проекта
- Добавлена секция "Особенности клиента" (IP + Host + SSL)
- Добавлены тестовые curl-команды для новых функций
- Обновлена карта проекта
- Добавлена история изменений

Файлы чистые, документ полный! 🎉