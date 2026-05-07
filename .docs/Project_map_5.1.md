
📄 ОБНОВЛЁННЫЙ ФАЙЛ: Project_map_5.1.md  
🗺️ АДИДАС: НАШ ОБМЕННИК — Полная техническая карта проекта (v5.1)

📌 ЧАСТЬ 1: СЕРВЕР (без изменений с v5.0)

Провайдер и доступ
- Хостинг: BeGet (VPS)
- IP-адрес: 90.156.171.36
- Домен: gazonbaza.ru
- Доступ: SSH через терминал
- Путь к домену: /home/rubi/web/gazonbaza.ru/

Операционная система
- ОС: Ubuntu
- Пользователь: rubi
- Группа: www-data (для веб-сервера)

Управление сервером
- Панель управления: HestiaCP
- Расположение конфигов: /home/rubi/conf/web/gazonbaza.ru/
- Связка: Nginx (прокси) → Apache2 (порт 8080)

Веб-сервер (Nginx)
- Конфиг: /home/rubi/conf/web/gazonbaza.ru/nginx.conf
- SSL-конфиг: /home/rubi/conf/web/gazonbaza.ru/nginx.ssl.conf
- Прокси на: http://90.156.171.36:8080
- WebSocket прокси: /socket.io/ → http://127.0.0.1:3001

PHP
- Версия: 8.1
- Конфиг: /etc/php/8.1/fpm/php.ini
- Важные настройки для файлов:
  - upload_max_filesize = 300M
  - post_max_size = 300M
  - max_execution_time = 600
  - memory_limit = 512M
- Перезагрузка: sudo systemctl restart php8.1-fpm

Пути к файлам проекта
- Корень сайта (public): /home/rubi/web/gazonbaza.ru/public_html/
- Логи: /var/log/apache2/domains/gazonbaza.ru.error.log
- Хранилище файлов: /home/rubi/web/gazonbaza.ru/public_html/files/
- Бэкапы: через HestiaCP

Nginx запрет прямого доступа к файлам
- В конфиг добавлено: /files/ → deny all; return 403;

💾 ЧАСТЬ 2: БАЗА ДАННЫХ (без изменений с v5.0)

Система
- СУБД: MariaDB
- База данных: avito_shop
- Пользователь БД: api_user
- Пароль: StrongPass123!

Структура таблиц

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

Полезные команды
```bash
# Вход в MariaDB
sudo mariadb -u root -p

# Выбор базы
USE avito_shop;

# Показать таблицы
SHOW TABLES;

# Назначить админа
UPDATE users SET is_admin = 1 WHERE phone = '111111';
📡 ЧАСТЬ 3: API ENDPOINTS (без изменений с v5.0)

Базовый URL
https://gazonbaza.ru (клиент использует IP 90.156.171.36 с заголовком Host: gazonbaza.ru)

Существующие эндпоинты (без изменений, если не указано)

register.php — регистрация
Метод: POST
Заголовки: Content-Type: application/json, Host: gazonbaza.ru
Тело: {"phone":"...","password":"...","nickname":"...","full_name":"...","position":"..."}
Ответ: {"status":"success","user_id":1}

login.php — вход
Метод: POST
Тело: {"phone":"...","password":"..."}
Ответ: {"status":"success","api_token":"...","user":{"id":1,"nickname":"...","is_admin":0},"expires_at":"..."}

list_files.php — список файлов и папок (ОБНОВЛЁН v5.0)
Метод: GET
Заголовок: X-API-Token: токен, Host: gazonbaza.ru
Параметры: ?folder_id=1 (опционально), ?search=запрос
Ответ:
{
"status": "success",
"folders": [{"id":1,"name":"Папка","parent_id":null}],
"files": [{"id":1,"original_name":"file.txt","folder_id":1,"description":"Описание файла","is_new":true|false}]
}
Поле is_new (boolean) добавлено для отметки непросмотренных файлов текущим пользователем.

upload.php — загрузка файла
Метод: POST
Заголовок: X-API-Token: токен, Host: gazonbaza.ru
Формат: multipart/form-data
Поля: file (файл), is_public (0/1), folder_id (опционально), description (опционально, до 300 символов)
Ответ: {"status":"success","file_id":2}
🔔 Уведомление: После загрузки автоматически отправляет push-уведомление всем администраторам через WebSocket-сервис

download.php — скачивание файла (ИСПРАВЛЕН v5.0)
Метод: GET
Заголовок: X-API-Token: токен, Host: gazonbaza.ru
Параметры: ?id=file_id, ?thumbnail=1 (опционально, для эскизов изображений 200px)
Возвращает: бинарные данные файла или JPEG-эскиз.
⚠️ Эскизы для .bmp больше не поддерживаются (возвращает ошибку).

delete.php — удаление файла (без изменений)

rename.php — переименование файла (без изменений)

toggle_visibility.php — переключение видимости файла (без изменений)

profile.php — управление профилем (без изменений)

Эндпоинты для папок (без изменений):

create_folder.php

delete_folder.php

rename_folder.php

list_folders.php

move_file.php

auth.php — проверка токена (без изменений)
json_input.php — универсальный парсер входных данных (без изменений)

🆕 НОВЫЕ ЭНДПОИНТЫ v5.0 (остаются актуальными)

get_share_link.php — создание временной публичной ссылки на файл
Метод: POST
Заголовки: X-API-Token: токен, Content-Type: application/json
Тело: {"file_id": 123}
Права: владелец файла или админ
Ответ: {"status":"success","share_url":"https://gazonbaza.ru/public_download.php?token=abc123"}
Срок действия ссылки — 7 дней.

public_download.php — скачивание файла по публичной ссылке (без авторизации)
Метод: GET
Параметры: ?token=abc123
Возвращает: бинарные данные файла или 404/400 при неверном/истекшем токене.

mark_viewed.php — отметка о просмотре файла пользователем
Метод: POST
Заголовки: X-API-Token: токен, Content-Type: application/json
Тело: {"file_id": 123}
Действие: добавляет запись в user_file_views (игнорирует дубликат).
Ответ: {"status":"success","message":"File marked as viewed"}

📱 ЧАСТЬ 4: FLUTTER-ПРИЛОЖЕНИЕ (v5.1 – текущий релиз)

Технологии

Фреймворк: Flutter (Dart)

Минимальная версия SDK: ^3.0.0

Целевая платформа: Android (APK)

Актуальные зависимости (pubspec.yaml v5.1)

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
  lottie: ^2.7.0                      # анимация логотипа
  flutter_secure_storage: ^9.0.0      # хранение PIN-кода
  flutter_svg: ^2.0.10+1              # SVG-логотип
  crypto: ^3.0.3                      # хеширование PIN-кода
Структура проекта (актуальная)

text
lib/
├── main.dart
├── screens/
│   ├── splash_screen.dart        # новый экран приветствия со свайпом
│   ├── login_screen.dart         # обновлён логотип и брендинг
│   ├── files_screen.dart         # основной экран (логотип в AppBar, брендинг)
│   ├── file_operations.dart      # mixin: операции с файлами + исправлены permissions
│   ├── folder_operations.dart
│   ├── upload_operations.dart
│   ├── profile_screen.dart       # добавлен блок управления PIN-кодом
│   └── lock_screen.dart          # новый экран блокировки с PIN-кодом
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
│   ├── app_config.dart           # константы бренда (название, подзаголовок)
│   ├── format_file_size.dart
│   └── format_date.dart
└── services/
    ├── api_service.dart
    ├── auth_service.dart
    ├── notification_service.dart
    └── websocket_service.dart
Ресурсы

assets/animations/adidas.json – Lottie-анимация для Splash Screen и Lock Screen

assets/logo/adidas_logo.svg – векторный логотип для AppBar

android/app/src/main/res/mipmap-* – набор иконок приложения

⚡ КЛЮЧЕВЫЕ ИЗМЕНЕНИЯ И НОВЫЕ ВОЗМОЖНОСТИ v5.1

🎨 Брендинг «АДИДАС»

Название приложения изменено на "АДИДАС", подзаголовок "наш обменник".

В AppBar основного экрана отображается фирменный SVG-логотип (слева).

Экран входа получил анимированный логотип Lottie и стилизован в чёрно-красной гамме.

Добавлена константа AppConfig для единообразного использования названий.

🛡️ Экран приветствия (Splash Screen)

При запуске отображается Splash Screen с белым радиальным фоном и циклической Lottie-анимацией логотипа.

Переход на следующий экран происходит только после большого свайпа снизу вверх.

После свайпа пользователь попадает на основной экран (если уже авторизован) или на экран входа.

🔐 Экран блокировки (PIN-код)

В профиле можно установить/изменить/удалить PIN-код (4–6 цифр).

PIN хранится в зашифрованном виде через flutter_secure_storage (хеш SHA-256).

При возврате приложения из фона (если PIN задан) появляется Lock Screen с анимацией логотипа и полем ввода.

Неверный PIN отклоняется, правильный – разблокирует приложение.

🔧 Исправление прав доступа (Permissions)

Добавлены разрешения READ_MEDIA_AUDIO, READ_MEDIA_VIDEO, READ_MEDIA_IMAGES, REQUEST_INSTALL_PACKAGES.

Метод _requestPermissions в file_operations.dart динамически запрашивает права в зависимости от типа скачиваемого файла:

APK → запрос установки из неизвестных источников.

Аудио → Permission.audio

Видео → Permission.videos

Изображения → Permission.photos

После предоставления прав файлы открываются стандартными средствами (OpenFile), APK – через системный установщик.

🎨 Оригинальные иконки приложения

Иконка приложения заменена на фирменный логотип (все плотности mipmap сгенерированы).

Инструкция по добавлению иконок через Android Studio (Image Asset) или вручную через rsvg-convert приведена в документации.

✨ Улучшения UI/UX

AppBar: логотип в левом углу, кнопки действий всегда видны, при поиске отображается строка поиска с возможностью сброса.

Кнопка камеры изменена на красную (фирменный цвет), FAB-кнопка главного меню также красная.

Устранено переполнение Row в AppBar, оптимизированы отступы и шрифты.

Тёмная тема использует палитру Adidas (чёрный, красный акцент, тёмно-серые поверхности).

📌 ВАЖНЫЕ ТЕХНИЧЕСКИЕ ДЕТАЛИ

Все изменения обратно совместимы с серверной частью v5.0.

Splash Screen: файл splash_screen.dart использует GestureDetector и анимированный контейнер для свайпа, переход выполняется через обычный MaterialPageRoute, чтобы не терять тему.

Lock Screen: файл lock_screen.dart вызывается через WidgetsBindingObserver в main.dart, проверяет хеш PIN из flutter_secure_storage.

При обновлении pubspec.yaml необходимо выполнить flutter clean && flutter pub get && flutter build apk --release.

Если приложение не устанавливается на Android, проверить AndroidManifest.xml и build.gradle.kts (namespace, minSdk).

🧨 ИЗВЕСТНЫЕ ОГРАНИЧЕНИЯ / ВОЗМОЖНЫЕ ОШИБКИ (v5.1)

BMP-миниатюры: эскиз для .bmp не создаётся (возвращается ошибка), в интерфейсе показывается стандартная иконка.

SSL-сертификат: в режиме разработки обходится через HttpOverrides, на реальных устройствах сертификат должен быть валидным.

Публичные ссылки: время жизни 7 дней, после этого ссылка становится недействительной (требуется ручное продление или повторная генерация).

Дубликаты имён файлов: разрешены, каждый новый файл получает уникальное физическое имя, в папке может быть несколько файлов с одинаковым original_name.

WebSocket уведомления: push-уведомления о новых файлах получают только администраторы.

Фильтры «Новые/Просмотренные»: работают только при активном поиске и используют данные из user_file_views; если пользователь только вошёл и не открывал ни одного файла, все файлы будут считаться новыми.

Сортировка «По хозяину»: при отсутствии owner_nickname используется значение 'яяя', чтобы файлы без владельца уходили в конец списка.

Кнопка «Поделиться»: требует доработки на стороне получателя (public_download.php), если файл физически удалён с сервера, ссылка приведёт к ошибке 404.

Производительность: при большом количестве папок рекурсивный сбор всех папок (getFolders) может выполняться заметное время; рекомендуется добавить пагинацию в будущем.

Установка APK: на Android 8+ может потребоваться отдельное разрешение "Неизвестные источники", приложение запрашивает его через Permission.requestInstallPackages, но в некоторых оболочках может не сработать.

Открытие аудио/видео: на Android 13+ запрашивается доступ к медиа, при отказе файл не откроется.

📌 ПЛАНЫ НА БУДУЩЕЕ (v5.2+)

🌐 Веб-версия приложения (Flutter Web или отдельный сайт).

📝 Инструкция для пользователей.

🛡️ Дополнительная безопасность: шифрование на клиенте, двухфакторная аутентификация.

📦 Множественная загрузка файлов, drag-and-drop.

🧾 История действий пользователя (аудит).

🔔 Расширенные уведомления (для всех пользователей).

🎨 Анимации переходов и микроанимации.

📜 ИСТОРИЯ ВЕРСИЙ

v5.1 (текущая) — БРЕНДИНГ, БЕЗОПАСНОСТЬ И ПОЛИРОВКА
✅ Смена названия на "АДИДАС", логотип в AppBar и на экранах.
✅ Splash Screen со свайпом и Lottie-анимацией.
✅ Экран блокировки с PIN-кодом (flutter_secure_storage).
✅ Исправление permissions для аудио, видео, APK.
✅ Обновлены иконки приложения (mipmap всех размеров).
✅ Улучшена цветовая схема в Material 3 (чёрный/красный).
✅ Исправлены ошибки переполнения в AppBar, оптимизирован UI.

v5.0 — СОЦИАЛЬНЫЕ ФУНКЦИИ, УВЕДОМЛЕНИЯ И УЛУЧШЕНИЯ UI/UX
✅ Кнопка «Поделиться» с генерацией временных публичных ссылок.
✅ Индикатор непросмотренных файлов (зелёный бейдж).
✅ Фильтры «Свои», «Чужие», «Новые», «Просмотренные».
✅ Сортировка по хозяину и по типу (общий/личный).
✅ Отдельная FAB-кнопка для камеры в левом нижнем углу.
✅ Кнопка «Назад» в AppBar при навигации по папкам.
✅ Исправлены хлебные крошки на всех уровнях вложенности.
✅ Улучшенный BottomSheet меню файла (скролл, клавиатура).
✅ Исправление thumbnail для BMP, ошибка типа folder_id.
✅ Рекурсивный сбор всех папок в getFolders().
✅ Добавлены таблицы share_links и user_file_views.
✅ Серверные эндпоинты get_share_link, public_download, mark_viewed.

v4.2 — ПРЕДПРОСМОТР, ОПИСАНИЯ И ОПТИМИЗАЦИЯ
v4.1 — ПЕРЕРАБОТКА UI
v4.0 — PUSH-УВЕДОМЛЕНИЯ
v3.1 — ПРОФИЛЬ И ПРОГРЕСС-БАРЫ
v3.0 — ПАПКИ И КАТЕГОРИИ
v2.0 — УЛУЧШЕНИЯ
v1.0 — БАЗОВАЯ ВЕРСИЯ

🚀 Прототип проекта готов. Далее — веб-версия, инструкция и подготовка к презентации заказчику.