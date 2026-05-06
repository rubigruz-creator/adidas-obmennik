🔔 СИСТЕМА PUSH-УВЕДОМЛЕНИЙ «КУСОЧНИЦА»
Полная документация универсального WebSocket-сервиса (v1.0)
📋 Оглавление
Обзор архитектуры

Быстрый старт

Установка и настройка

API сервиса уведомлений

Интеграция с PHP

Интеграция с Flutter

Подключение к другим проектам

Мониторинг и отладка

Безопасность

Устранение неполадок

Обзор архитектуры
text
┌──────────────────────┐
│   Flutter Client     │
│  (Android APK)       │
│                      │
│  ┌────────────────┐  │
│  │WebSocketService│  │  wss://gazonbaza.ru/socket.io/
│  └────────┬───────┘  │
│           │           │
│  ┌────────┴───────┐  │
│  │NotificationSvc │  │  Локальные push-уведомления
│  └────────────────┘  │
└──────────────────────┘
           │
    🔒 Nginx прокси
           │
┌──────────────────────┐
│   VPS Server         │
│                      │
│  ┌────────────────┐  │
│  │ WebSocket Svc  │  │  Node.js + Socket.IO (порт 3001)
│  │  server.js     │  │
│  └──────┬─────────┘  │
│         │             │
│  ┌──────┴─────────┐  │
│  │ MariaDB        │  │  Проверка токенов
│  │ (user_sessions)│  │
│  └──────┬─────────┘  │
│         │             │
│  ┌──────┴─────────┐  │
│  │ PHP App        │  │  HTTP POST /notify
│  │ upload.php     │──┤
│  └────────────────┘  │
└──────────────────────┘
Ключевые компоненты:
WebSocket Server (Node.js + Socket.IO)

Принимает WebSocket-подключения от клиентов - Проверяет токены через MariaDB

Подписывает клиентов на персональные комнаты (user_{id})

Принимает HTTP-запросы от PHP через POST /notify

Пересылает уведомления клиентам в реальном времени

PHP Helper (notification_helper.php)

Функция sendNotification() — отправка одному пользователю

Функция notifyAdmins() — отправка всем администраторам

Функция notifyNewFile() — готовый шаблон для новых файлов

Flutter Client

WebSocketService — подключается при входе, отключается при выходе

NotificationService — показывает локальные push-уведомления

Автоматическое переподключение при обрыве связи

Быстрый старт
Проверка работоспособности
bash
# 1. Проверить статус сервиса
pm2 status

# 2. Проверить health check
curl https://gazonbaza.ru/notify-health

# 3. Отправить тестовое уведомление
curl -X POST http://localhost:3001/notify \
  -H "Content-Type: application/json" \
  -H "X-API-Key: Ku5ocHn1cA_Ch4ng3M3_2024" \
  -d '{"user_id":2,"title":"Тест","body":"Проверка"}'
Тестирование из PHP
bash
cd /home/rubi/web/gazonbaza.ru/public_html/
php -r "
require 'notification_helper.php';
\$pdo = new PDO('mysql:host=localhost;dbname=avito_shop', 'api_user', 'StrongPass123!');
echo json_encode(notifyNewFile(\$pdo, 99, 'test.pdf', 'TestUser'));
"
Установка и настройка
Требования
Node.js 18+ (установлен через nvm)

npm

MariaDB (уже есть на сервере)

Nginx (уже настроен)

Структура файлов
text
/home/rubi/websocket_service/
├── server.js                 # Основной сервер
├── package.json              # Зависимости
├── .env                      # Конфигурация
└── data/
    └── notifications.db      # SQLite база логов
Конфигурация (.env)
env
API_KEY=Ku5ocHn1cA_Ch4ng3M3_2024
DB_HOST=localhost
DB_USER=api_user
DB_PASSWORD=StrongPass123!
DB_NAME=avito_shop
PORT=3001
Управление через PM2
bash
# Запуск
pm2 start /home/rubi/websocket_service/server.js --name websocket-notify

# Статус
pm2 status

# Логи
pm2 logs websocket-notify

# Перезапуск
pm2 restart websocket-notify

# Остановка
pm2 stop websocket-notify

# Автозапуск при загрузке системы
pm2 startup
pm2 save
Nginx конфигурация
В /home/rubi/conf/web/gazonbaza.ru/nginx.ssl.conf:

nginx
location /socket.io/ {
    proxy_pass http://127.0.0.1:3001;
    proxy_http_version 1.1;
    proxy_set_header Upgrade $http_upgrade;
    proxy_set_header Connection "upgrade";
    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto $scheme;
    proxy_read_timeout 86400;
}

location /notify-health {
    proxy_pass http://127.0.0.1:3001/health;
    proxy_http_version 1.1;
    proxy_set_header Host $host;
}
API сервиса уведомлений
POST /notify — отправка уведомления
Защита: Требуется заголовок X-API-Key с секретным ключом.

Запрос:

json
{
  "user_id": 2,
  "title": "📎 Новый файл",
  "body": "Пользователь Ivan загрузил: отчет.pdf",
  "data": {
    "file_id": 123,
    "folder_id": 5,
    "action": "file_uploaded"
  }
}
Ответ:

json
{
  "status": "success",
  "message": "Notification sent",
  "receivers_count": 1
}
receivers_count — количество подключённых клиентов, получивших уведомление

Если клиент не в сети — уведомление не доставляется (не сохраняется)

GET /health — проверка работоспособности
Ответ:

json
{
  "status": "ok",
  "timestamp": "2026-05-06T12:00:00.000Z"
}
WebSocket события
Событие	Направление	Описание
connected	Сервер → Клиент	Подтверждение авторизации
notification	Сервер → Клиент	Входящее уведомление
ping	Клиент → Сервер	Проверка соединения
pong	Сервер → Клиент	Ответ на ping
Формат события notification:

json
{
  "title": "📎 Новый файл",
  "body": "Пользователь Ivan загрузил: отчет.pdf",
  "data": {
    "file_id": 123,
    "folder_id": 5
  },
  "timestamp": "2026-05-06T12:00:00.000Z"
}
Интеграция с PHP
Файл notification_helper.php
Находится в /home/rubi/web/gazonbaza.ru/public_html/notification_helper.php

Основные функции:

php
// Отправка уведомления конкретному пользователю
sendNotification($pdo, [
    'user_id' => 2,
    'title' => 'Заголовок',
    'body' => 'Текст уведомления',
    'data' => ['key' => 'value']
]);

// Отправка всем администраторам
notifyAdmins($pdo, 'Заголовок', 'Текст', ['data' => 'value']);

// Готовый шаблон для нового файла
notifyNewFile($pdo, $fileId, $fileName, $uploaderName, $folderId);

// Готовый шаблон для новой папки
notifyNewFolder($pdo, $folderId, $folderName, $creatorName);
Пример интеграции в upload.php
php
require_once __DIR__ . '/notification_helper.php';

// ... после сохранения файла ...
$uploaderName = $currentUser['nickname'] ?? 'Пользователь';
notifyAdmins($pdo, 
    '📎 Новый файл', 
    "{$uploaderName} загрузил(а): {$originalName}",
    ['file_id' => $fileId, 'folder_id' => $folderId, 'action' => 'file_uploaded']
);
Интеграция с Flutter
Зависимости (pubspec.yaml)
yaml
dependencies:
  socket_io_client: ^2.0.3
  flutter_local_notifications: ^17.2.4
  permission_handler: ^11.3.1
WebSocketService (синглтон)
dart
// Подключение после логина
WebSocketService().connect(apiToken);

// Отключение при выходе
WebSocketService().disconnect();
Особенности:

Автоматическое переподключение (до 100 попыток)

Интервал переподключения: 5 секунд

Токен передаётся в auth и extraHeaders

Используется Host: gazonbaza.ru для корректной маршрутизации

NotificationService (синглтон)
dart
// Инициализация (в main.dart)
final notificationService = NotificationService();
await notificationService.initialize();
await notificationService.requestPermission();

// Обработчик нажатия
NotificationService.onNotificationTap = (response) {
    // response.payload содержит строку с file_id и folder_id
};
AndroidManifest.xml
xml
<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
<uses-permission android:name="android.permission.INTERNET"/>
build.gradle.kts
kotlin
android {
    compileSdk = 36
    compileOptions {
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:1.2.2")
}
Подключение к другим проектам
Сервис уведомлений спроектирован как универсальный — его можно использовать для любых других проектов на этом же сервере.

Шаг 1: PHP-интеграция
Скопируйте notification_helper.php в новый проект:

php
require_once '/home/rubi/web/gazonbaza.ru/public_html/notification_helper.php';

// Отправка уведомления
sendNotification($pdo, [
    'user_id' => $userId,
    'title' => 'Событие',
    'body' => 'Описание события',
    'data' => ['project' => 'my_project', 'id' => 123]
]);
Шаг 2: Flutter-интеграция
Скопируйте websocket_service.dart и notification_service.dart в новый проект.

Изменения в WebSocketService:

URL подключения: wss://gazonbaza.ru

Path: /socket.io/

Заголовок Host: gazonbaza.ru

Всё остальное работает без изменений.

Шаг 3: Отправка уведомлений из любого языка
bash
# Bash
curl -X POST http://localhost:3001/notify \
  -H "X-API-Key: Ku5ocHn1cA_Ch4ng3M3_2024" \
  -H "Content-Type: application/json" \
  -d '{"user_id":1,"title":"Test","body":"Hello"}'
python
# Python
import requests
requests.post('http://localhost:3001/notify', 
    headers={'X-API-Key': 'Ku5ocHn1cA_Ch4ng3M3_2024'},
    json={'user_id': 1, 'title': 'Test', 'body': 'Hello'})
javascript
// Node.js
fetch('http://localhost:3001/notify', {
    method: 'POST',
    headers: {'X-API-Key': 'Ku5ocHn1cA_Ch4ng3M3_2024', 'Content-Type': 'application/json'},
    body: JSON.stringify({user_id: 1, title: 'Test', body: 'Hello'})
});
Мониторинг и отладка
Проверка статуса
bash
pm2 status
Просмотр логов (реального времени)
bash
pm2 logs websocket-notify
Просмотр логов (последние строки)
bash
pm2 logs websocket-notify --lines 50 --nostream
Проверка логов уведомлений в SQLite
bash
cd /home/rubi/websocket_service
sqlite3 data/notifications.db "SELECT * FROM notification_logs ORDER BY sent_at DESC LIMIT 10;"
Мониторинг через systemd (если настроен)
bash
journalctl -u websocket-notify -f
Безопасность
Секретный ключ API
Хранится в .env файле на сервере

В PHP: константа NOTIFICATION_API_KEY в notification_helper.php

Важно: Сменить ключ на уникальный: API_KEY=Ku5ocHn1cA_Ch4ng3M3_2024 → замените на свой

Проверка токенов
Сервер проверяет каждый WebSocket-токен через MariaDB

Используется подготовленный запрос: SELECT ... FROM user_sessions WHERE api_token = ? AND expires_at > NOW()

Невалидные токены отклоняются до установки соединения

Защита эндпоинта /notify
Доступен только с localhost:3001 (не exposed наружу)

Требует заголовок X-API-Key с секретным ключом

Без ключа возвращает 401 Unauthorized

Nginx
Проксирует только /socket.io/ — WebSocket-трафик

Health check через /notify-health

Прямой доступ к порту 3001 извне закрыт

Устранение неполадок
Проблема: Уведомления не приходят
Проверка:

bash
# 1. Сервис запущен?
pm2 status

# 2. Health check работает?
curl http://localhost:3001/health

# 3. PHP может достучаться?
cd /home/rubi/web/gazonbaza.ru/public_html/
php -r "require 'notification_helper.php'; ..."

# 4. Клиент подключён?
pm2 logs websocket-notify | grep "User connected"
Проблема: WebSocket не подключается из Flutter
Возможные причины:

Неправильный URL — используйте wss://90.156.171.36 с Host: gazonbaza.ru

Nginx не проксирует — проверьте nginx -t

Токен истёк — получите новый через login.php

Проблема: Сервис упал
bash
# Перезапуск
pm2 restart websocket-notify

# Проверить логи
pm2 logs websocket-notify --lines 20 --nostream
Проблема: receivers_count всегда 0
Это нормально, если клиент не подключён. Уведомление отправлено в комнату, но получателей нет — клиент получит его при следующем подключении только если реализовано сохранение офлайн-уведомлений (не реализовано в текущей версии).

Контакты и поддержка
Сервер: ssh rubi@90.156.171.36

Путь к сервису: /home/rubi/websocket_service/

Документация проекта: Project_map_4.md

Версия документации: 1.0
Дата: 2026-05-06
Автор: Команда разработки «Кусочница»