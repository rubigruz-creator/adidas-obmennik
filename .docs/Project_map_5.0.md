📄 ОБНОВЛЁННЫЙ ФАЙЛ: Project_map_5.0.md
🗺️ КУСОЧНИЦА — Полная техническая карта проекта (v5.0)

📌 ЧАСТЬ 1: СЕРВЕР

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

💾 ЧАСТЬ 2: БАЗА ДАННЫХ

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

📡 ЧАСТЬ 3: API ENDPOINTS

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

🆕 НОВЫЕ ЭНДПОИНТЫ v5.0

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

📱 ЧАСТЬ 4: FLUTTER-ПРИЛОЖЕНИЕ (v5.0)

Технологии

Фреймворк: Flutter (Dart)

Минимальная версия SDK: ^3.0.0

Целевая платформа: Android (APK)

Новые зависимости (pubspec.yaml v5.0)
dependencies:
share_plus: ^7.2.1 # для кнопки "Поделиться"

Структура проекта (актуальная)
lib/
├── main.dart
├── screens/
│ ├── login_screen.dart
│ ├── files_screen.dart # Основной экран (расширен фильтрами и кнопкой камеры)
│ ├── file_operations.dart # Mixin: операции с файлами + shareFile()
│ ├── folder_operations.dart
│ ├── upload_operations.dart
│ └── profile_screen.dart
├── widgets/
│ ├── file_card.dart # Добавлен зелёный бейдж is_new
│ ├── file_list_tile.dart # Добавлен бейдж is_new
│ ├── folder_card.dart
│ ├── folder_list_tile.dart
│ ├── file_icon.dart
│ ├── empty_state.dart
│ ├── breadcrumb_chips.dart
│ ├── file_pill.dart (устаревший)
│ └── folder_pill.dart (устаревший)
├── utils/
│ ├── format_file_size.dart
│ └── format_date.dart
└── services/
├── api_service.dart # + getShareLink(), markFileViewed()
├── auth_service.dart
├── notification_service.dart
└── websocket_service.dart

⚡ КЛЮЧЕВЫЕ ИЗМЕНЕНИЯ И НОВЫЕ ВОЗМОЖНОСТИ v5.0

🧩 Улучшенный BottomSheet меню файла

Убран жёсткий отступ SafeArea.

Обёрнут в SingleChildScrollView, автоматически поднимается при появлении клавиатуры.

Все кнопки (Скачать, Переименовать, Переместить, Удалить, Поделиться) всегда доступны.

🔙 Кнопка «Назад» в подпапках

При входе в любую папку в AppBar появляется стрелка «Назад».

Поддерживается системная кнопка Back: возвращает на уровень выше, в корне — выход из приложения.

📸 Отдельная кнопка «Фото с камеры»

Синяя круглая кнопка в левом нижнем углу (диаметр 56dp, поднята на 46dp от низа).

Сразу открывает камеру, затем стандартные диалоги описания и видимости.

📊 Новые сортировки

По хозяину (owner_nickname, алфавитный порядок).

По типу (Общий/Личный — is_public).
Добавлены в меню сортировки AppBar.

🏷️ Фильтры атрибутов (в режиме поиска)

Вторая строка чипсов: «Свои», «Чужие», «Новые», «Просмотренные».

Взаимоисключающие пары (Свои/Чужие, Новые/Просмотренные), можно комбинировать.

🔵 Индикатор непросмотренных файлов (зелёный бейдж)

Новые файлы, которые текущий пользователь ещё не открывал, помечаются маленьким зелёным кружком в сетке и списке.

После открытия меню файла отметка «просмотрен» отправляется на сервер, бейдж исчезает.

Таблица user_file_views хранит просмотры.

📤 Кнопка «Поделиться»

Доступна в меню файла (BottomSheet), только для владельца или администратора.

Генерирует временную публичную ссылку (через get_share_link.php), открывает системное меню «Share» (WhatsApp, Telegram, почта и т.д.).

⚙️ Исправления и оптимизации

Хлебные крошки теперь корректно отображаются на любом уровне вложенности папок.

Устранена ошибка с возвращаемым типом folder_id при создании папки.

Миниатюры для .bmp исключены из-за отсутствия поддержки в стандартном PHP GD.

Метод getFolders() рекурсивно собирает все папки для построения полного пути.

Сборка APK

bash
flutter clean
flutter pub get
flutter build apk --release
APK: build/app/outputs/flutter-apk/app-release.apk

🔔 ЧАСТЬ 5: СЕРВИС УВЕДОМЛЕНИЙ (без изменений)

... (весь блок про WebSocket, порты, .env остаётся как в исходном документе)

🧪 ЧАСТЬ 6: ТЕСТОВЫЕ ДАННЫЕ (без изменений)

🧨 ИЗВЕСТНЫЕ ОГРАНИЧЕНИЯ / ВОЗМОЖНЫЕ ОШИБКИ (v5.0)

BMP-миниатюры – эскиз для .bmp не создаётся (возвращается ошибка), в интерфейсе показывается стандартная иконка.

SSL-сертификат – в режиме разработки обходится через HttpOverrides, на реальных устройствах сертификат должен быть валидным.

Публичные ссылки – время жизни 7 дней, после этого ссылка становится недействительной (требуется ручное продление или повторная генерация).

Дубликаты имён файлов – разрешены, каждый новый файл получает уникальное физическое имя, в папке может быть несколько файлов с одинаковым original_name.

WebSocket уведомления – push-уведомления о новых файлах получают только администраторы.

Фильтры «Новые/Просмотренные» – работают только при активном поиске и используют данные из user_file_views; если пользователь только вошёл и не открывал ни одного файла, все файлы будут считаться новыми.

Сортировка «По хозяину» – при отсутствии owner_nickname используется значение 'яяя', чтобы файлы без владельца уходили в конец списка.

Кнопка «Поделиться» – требует доработки на стороне получателя (public_download.php), если файл физически удалён с сервера, ссылка приведёт к ошибке 404.

Производительность – при большом количестве папок рекурсивный сбор всех папок (getFolders) может выполняться заметное время; рекомендуется добавить пагинацию в будущем.

📌 ПЛАНЫ НА БУДУЩЕЕ (v5.1+)

🎨 Установка оригинальных иконок приложения и логотипа.

🚀 Смена названия проекта.

🛡️ Экран приветствия (Splash Screen) и экран блокировки (пин-код).

🌐 Веб-версия приложения (Flutter Web или отдельный сайт).

📝 Инструкция для пользователей.

🔐 Дополнительная безопасность: шифрование на клиенте, двухфакторная аутентификация.

📦 Множественная загрузка файлов, drag-and-drop.

🧾 История действий пользователя (аудит).

📜 ИСТОРИЯ ВЕРСИЙ

v5.0 (текущая) — СОЦИАЛЬНЫЕ ФУНКЦИИ, УВЕДОМЛЕНИЯ И УЛУЧШЕНИЯ UI/UX
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

text

**Что дальше?**  
Вы можете скопировать этот текст в `Project_map_5.0.md` и использовать как актуальную документацию. Если потребуется добавить ещё деталей (например, скриншоты или уточнить серверные команды), дайте знать.  
Прототип готов к презентации! 🚀