## 🗺️ КУСОЧНИЦА — Полная техническая карта проекта

* * *

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

*   **Версия:** 8.1 (проверить `php -v`)
    
*   **Конфиг:** `/etc/php/8.1/fpm/php.ini`
    
*   **Важные настройки для файлов:**
    
    ini
    
    upload\_max\_filesize \= 300M
    post\_max\_size \= 300M
    max\_execution\_time \= 600
    memory\_limit \= 512M
    
*   **Перезагрузка:** `sudo systemctl restart php8.1-fpm`
    

## Пути к файлам проекта

*   **Корень сайта (public):** `/home/rubi/web/gazonbaza.ru/public_html/`
    
*   **Логи:** `/var/log/apache2/domains/gazonbaza.ru.error.log`
    
*   **Хранилище файлов:** `/home/rubi/web/gazonbaza.ru/public_html/files/`
    
*   **Бэкапы:** через HestiaCP
    

## Nginx запрет прямого доступа к файлам

В конфиг добавлено: `/files/` → `deny all; return 403;`

* * *

# 💾 ЧАСТЬ 2: БАЗА ДАННЫХ

## Система

*   **СУБД:** MariaDB
    
*   **База данных:** `avito_shop`
    
*   **Пользователь БД:** `api_user`
    
*   **Пароль:** `StrongPass123!`
    

## Структура таблиц

### 1\. `users` — пользователи

sql

id INT AUTO\_INCREMENT PRIMARY KEY
phone VARCHAR(20) NOT NULL UNIQUE
password\_hash VARCHAR(255) NOT NULL
nickname VARCHAR(50)
full\_name VARCHAR(100)
position VARCHAR(100)
is\_admin TINYINT(1) DEFAULT 0
created\_at TIMESTAMP DEFAULT CURRENT\_TIMESTAMP

### 2\. `user_sessions` — токены сессий

sql

id INT AUTO\_INCREMENT PRIMARY KEY
user\_id INT NOT NULL
api\_token VARCHAR(64) NOT NULL UNIQUE
expires\_at TIMESTAMP NOT NULL
created\_at TIMESTAMP DEFAULT CURRENT\_TIMESTAMP
FOREIGN KEY (user\_id) REFERENCES users(id) ON DELETE CASCADE

### 3\. `files` — файлы

sql

id INT AUTO\_INCREMENT PRIMARY KEY
user\_id INT NOT NULL
original\_name VARCHAR(255) NOT NULL
stored\_name VARCHAR(255) NOT NULL
file\_size INT NOT NULL
file\_type VARCHAR(100)
is\_public BOOLEAN DEFAULT FALSE
upload\_date TIMESTAMP DEFAULT CURRENT\_TIMESTAMP
FOREIGN KEY (user\_id) REFERENCES users(id) ON DELETE CASCADE

### 4\. `api_keys` — ключи API (старая таблица, не используется активно)

sql

id INT AUTO\_INCREMENT PRIMARY KEY
api\_key VARCHAR(64) NOT NULL UNIQUE
app\_name VARCHAR(100) NOT NULL
is\_active TINYINT(1) DEFAULT 1
created\_at TIMESTAMP DEFAULT CURRENT\_TIMESTAMP

## Полезные команды

bash

\# Вход в MariaDB
sudo mariadb \-u root \-p
\# Выбор базы
USE avito\_shop;
\# Показать таблицы
SHOW TABLES;
\# Назначить админа
UPDATE users SET is\_admin \= 1 WHERE phone \= '+71234567890';

* * *

# 📡 ЧАСТЬ 3: API ENDPOINTS

## Базовый URL

`https://gazonbaza.ru`

## Эндпоинты

### 1\. `register.php` — регистрация

*   **Метод:** POST
    
*   **Заголовки:** `Content-Type: application/json`
    
*   **Тело JSON:**
    

json

{
  "phone": "+71234567890",
  "password": "123456",
  "nickname": "user123",
  "full\_name": "Иван Иванов",
  "position": "Менеджер"
}

*   **Ответ:** `{"status":"success","user_id":1}`
    

### 2\. `login.php` — вход

*   **Метод:** POST
    
*   **Тело JSON:** `{"phone":"...","password":"..."}`
    
*   **Ответ:**
    

json

{
  "status":"success",
  "api\_token":"...",
  "user":{"id":1,"nickname":"...","is\_admin":0}
}

### 3\. `list_files.php` — список файлов

*   **Метод:** GET
    
*   **Заголовок:** `X-API-Token: токен`
    
*   **Параметры:** `?type=all` или `?type=personal`
    
*   **Возвращает:** список файлов с полями `id, original_name, file_size, file_type, is_public, upload_date, owner_nickname, size_mb`
    

### 4\. `upload.php` — загрузка файла

*   **Метод:** POST
    
*   **Заголовок:** `X-API-Token: токен`
    
*   **Формат:** `multipart/form-data`
    
*   **Поля:** `file` (файл), `is_public` (0/1)
    
*   **Ответ:** `{"status":"success","file_id":2}`
    

### 5\. `download.php` — скачивание файла

*   **Метод:** GET
    
*   **Заголовок:** `X-API-Token: токен`
    
*   **Параметры:** `?id=file_id`
    
*   **Возвращает:** бинарные данные файла
    

### 6\. `delete.php` — удаление файла

*   **Метод:** POST
    
*   **Заголовок:** `X-API-Token: токен`
    
*   **Параметры:** `?id=file_id` или POST `id`
    
*   **Права:** админ или владелец
    
*   **Ответ:** `{"status":"success","message":"File deleted"}`
    

### 7\. `auth.php` — проверка токена (включается в другие файлы)

php

$currentUser \= authenticate($pdo);
// возвращает id, phone, nickname, full\_name, position, is\_admin

* * *

# 📱 ЧАСТЬ 4: FLUTTER-ПРИЛОЖЕНИЕ

## Технологии

*   **Фреймворк:** Flutter (Dart)
    
*   **Минимальная версия SDK:** `^3.0.0`
    
*   **Целевая платформа:** Android (APK)
    

## Структура проекта

lib/
├── main.dart                 # Точка входа, запускает LoginScreen
├── screens/
│   ├── login\_screen.dart     # Вход/регистрация
│   └── files\_screen.dart     # Список файлов, загрузка, удаление
├── widgets/
│   └── file\_pill.dart        # Виджет цветной пилюли
└── services/
    ├── api\_service.dart      # Все запросы к серверу
    └── auth\_service.dart     # Работа с токеном (SharedPreferences)

## Зависимости (`pubspec.yaml`)

yaml

dependencies:
  flutter:
    sdk: flutter
  http: ^1.2.0
  image\_picker: ^1.0.7
  file\_picker: ^8.0.0
  permission\_handler: ^11.3.1
  path\_provider: ^2.1.2
  open\_file: ^3.3.2
  shared\_preferences: ^2.2.2

## Ключевые переменные

dart

final String \_baseUrl \= 'https://gazonbaza.ru';
final String \_apiToken \= '...'; // получается при логине

## Хранение данных на клиенте (SharedPreferences)

*   `api_token` — токен авторизации
    
*   `user_id` — ID пользователя
    
*   `user_nickname` — ник
    
*   `is_admin` — права админа (0 или 1)
    

## Основной функционал

*   ✅ Регистрация нового пользователя
    
*   ✅ Вход по телефону/паролю
    
*   ✅ Автоматическое сохранение токена
    
*   ✅ Загрузка любых файлов (до 300 МБ)
    
*   ✅ Фото из галереи и с камеры
    
*   ✅ Скачивание файлов в папку Downloads
    
*   ✅ Удаление файлов (свои или любые — для админа)
    
*   ✅ Цветные пилюли с сортировкой (новые — крупнее)
    

## Сборка APK

bash

flutter clean
flutter pub get
flutter build apk \--release

**Выход:** `build/app/outputs/flutter-apk/app-release.apk`

* * *

# 📁 ЧАСТЬ 5: ХРАНИЛИЩЕ ФАЙЛОВ

## Расположение

`/home/rubi/web/gazonbaza.ru/public_html/files/`

## Права доступа

bash

chmod 755 /home/rubi/web/gazonbaza.ru/public\_html/files
chown rubi:www-data /home/rubi/web/gazonbaza.ru/public\_html/files

## Формат имени файла на сервере

`{timestamp}_{random_hash}.{ext}`  
Пример: `1777896982_9340d91718633a02.txt`

## Защита

Через Nginx настроен запрет прямого доступа к `/files/`

## Лимиты

*   Максимальный размер файла: 300 МБ
    
*   Настраивается в `php.ini` и в проверке `upload.php`
    

* * *

# 🔐 ЧАСТЬ 6: БЕЗОПАСНОСТЬ

## Авторизация

*   API-токен длиной 64 символа (`bin2hex(random_bytes(32))`)
    
*   Токен передаётся в заголовке: `X-API-Token`
    
*   Токен живёт 30 дней (`expires_at`)
    
*   Просроченные токены удаляются автоматически
    

## Пароли

*   Хранятся в БД в виде хэша: `password_hash($password, PASSWORD_DEFAULT)`
    
*   Проверка: `password_verify($input, $hash)`
    

## Права доступа

*   Обычный пользователь: удаляет только свои файлы
    
*   Админ (`is_admin = 1`): удаляет любые файлы
    
*   Общие файлы (`is_public = 1`) видны всем
    
*   Личные файлы видны только владельцу
    

## Защита от прямого доступа

*   Папка `/files/` закрыта через Nginx
    
*   Доступ к файлам только через `download.php` с проверкой токена
    

## CORS

Для всех PHP эндпоинтов добавлены заголовки:

php

header('Access-Control-Allow-Origin: \*');
header('Access-Control-Allow-Headers: X-API-Token, Content-Type');

* * *

# 🧪 ЧАСТЬ 7: ТЕСТОВЫЕ ДАННЫЕ

## Администратор

*   **Телефон:** `111111`
    
*   **Пароль:** `password` (после сброса)
    
*   **is\_admin:** 1
    

## Обычный пользователь

*   **Телефон:** `+79001234567`
    
*   **Пароль:** (задан при регистрации)
    
*   **is\_admin:** 0
    

## Тестовый файл

bash

Download

echo "Hello Kusotschnitsa" \> /tmp/test.txt
curl \-X POST https://gazonbaza.ru/upload.php \\
  \-H "X-API-Token: ТОКЕН" \\
  \-F "file=@/tmp/test.txt" \\
  \-F "is\_public=1"

* * *

# 🗺️ КАРТА ПРОЕКТА (для ИИ-агентов)

Download

КОРЕНЬ ПРОЕКТА: /home/rubi/web/gazonbaza.ru/
│
├── public\_html/               # Доступно из веба
│   ├── api.php               # \[устаревший\] Товары, API-ключи
│   ├── auth.php              # Проверка токена (включается)
│   ├── register.php          # Регистрация
│   ├── login.php             # Вход, выдача токена
│   ├── list\_files.php        # Список файлов
│   ├── upload.php            # Загрузка файлов
│   ├── download.php          # Скачивание файлов
│   ├── delete.php            # Удаление файлов
│   ├── files/                # Хранилище файлов (закрыто через Nginx)
│   │   └── \*.txt, \*.jpg...
│   └── (старые резервные копии)
│
├── conf/web/gazonbaza.ru/    # Конфиги HestiaCP
│   ├── nginx.conf
│   └── apache2.conf
│
├── logs/                     # Логи домена
│
├── private/                  # Приватные файлы
│
└── stats/                    # Статистика

* * *

# 📋 БАЗЫ ДАННЫХ (схема)

avito\_shop
│
├── users
│   ├── id (PK)
│   ├── phone (UNIQUE)
│   ├── password\_hash
│   ├── nickname
│   ├── full\_name
│   ├── position
│   ├── is\_admin (0/1)
│   └── created\_at
│
├── user\_sessions
│   ├── id (PK)
│   ├── user\_id (FK → users.id)
│   ├── api\_token (UNIQUE, 64)
│   ├── expires\_at
│   └── created\_at
│
├── files
│   ├── id (PK)
│   ├── user\_id (FK → users.id)
│   ├── original\_name
│   ├── stored\_name
│   ├── file\_size
│   ├── file\_type
│   ├── is\_public (0/1)
│   └── upload\_date
│
└── api\_keys (устаревшая, можно удалить)
    ├── id
    ├── api\_key
    ├── app\_name
    ├── is\_active
    └── created\_at

* * *

# 🔄 АВТОРИЗАЦИЯ (Схема работы)

1\. ПОЛЬЗОВАТЕЛЬ → register.php → СОЗДАЁТСЯ users
2\. ПОЛЬЗОВАТЕЛЬ → login.php (телефон+пароль)
3\. СЕРВЕР → password\_verify() → Создаёт api\_token → user\_sessions
4\. СЕРВЕР ← Возвращает {api\_token, user{id,is\_admin}}
5\. КЛИЕНТ → Сохраняет token + userId + isAdmin в SharedPreferences
6\. КЛИЕНТ → Все запросы с заголовком X-API-Token
7\. Эндпоинт → auth.php → Проверяет token → Возвращает currentUser
8\. Если token просрочен: 401 Unauthorized

* * *