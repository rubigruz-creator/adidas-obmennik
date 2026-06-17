🗺️ АДИДАС: НАШ ОБМЕННИК — Полная техническая карта проекта (v5.5)
📌 ЧАСТЬ 1: СЕРВЕР
Провайдер и доступ
Хостинг: BeGet (VPS)

IP-адрес: 90.156.171.36

Домен: gazonbaza.ru

Веб-приложение: https://gazonbaza.ru/app

Презентация: https://gazonbaza.ru/presentation

Доступ: SSH через терминал (root / rubi)

Путь к домену: /home/rubi/web/gazonbaza.ru/

Операционная система
ОС: Ubuntu 24.04.4 LTS

Пользователь: rubi

Группа: www-data (для веб-сервера)

Root-доступ: для правки конфигов Nginx

Управление сервером
Панель управления: HestiaCP / BeGet CP

Расположение конфигов: /home/rubi/conf/web/gazonbaza.ru/

Связка: Nginx (прокси) → Apache2 (порт 8443)

Веб-сервер (Nginx)
HTTP-конфиг: /home/rubi/conf/web/gazonbaza.ru/nginx.conf

SSL-конфиг: /home/rubi/conf/web/gazonbaza.ru/nginx.ssl.conf

Основной конфиг: /etc/nginx/conf.d/domains/gazonbaza.ru.ssl.conf

Прокси на: https://90.156.171.36:8443 (Apache)

WebSocket прокси: /socket.io/ → http://127.0.0.1:3001

Веб-приложение: /app → alias /home/rubi/web/gazonbaza.ru/public_html/web/

Презентация: /presentation → alias /home/rubi/web/gazonbaza.ru/public_html/presentation/

Таймауты: proxy_read_timeout 600s, proxy_send_timeout 600s

client_max_body_size 300m

proxy_request_buffering off

PHP
Версия: 8.3

Конфиг: /etc/php/8.3/fpm/php.ini

Важные настройки для файлов:

upload_max_filesize = 300M

post_max_size = 300M

max_execution_time = 300

max_input_time = 300

memory_limit = 512M

Перезагрузка: systemctl restart php8.3-fpm

Пути к файлам проекта
Корень сайта (public): /home/rubi/web/gazonbaza.ru/public_html/

Веб-приложение: /home/rubi/web/gazonbaza.ru/public_html/web/

Презентация: /home/rubi/web/gazonbaza.ru/public_html/presentation/

Логи: /var/log/apache2/domains/gazonbaza.ru.error.log

Логи Nginx: /var/log/nginx/error.log

Хранилище файлов: /home/rubi/web/gazonbaza.ru/public_html/files/

Бэкапы: через HestiaCP

💾 ЧАСТЬ 2: БАЗА ДАННЫХ
Система
СУБД: MariaDB

База данных: avito_shop

Пользователь БД: api_user

Пароль: StrongPass123!

Структура таблиц
1. users — пользователи
Поле	Тип	Описание
id	INT AUTO_INCREMENT PRIMARY KEY	
phone	VARCHAR(20) NOT NULL UNIQUE	
password_hash	VARCHAR(255) NOT NULL	
nickname	VARCHAR(50)	
full_name	VARCHAR(100)	
position	VARCHAR(100)	
is_admin	TINYINT(1) DEFAULT 0	
created_at	TIMESTAMP DEFAULT CURRENT_TIMESTAMP	
2. user_sessions — токены сессий
Поле	Тип	Описание
id	INT AUTO_INCREMENT PRIMARY KEY	
user_id	INT NOT NULL	FOREIGN KEY → users(id)
api_token	VARCHAR(64) NOT NULL UNIQUE	
expires_at	TIMESTAMP NOT NULL	
created_at	TIMESTAMP DEFAULT CURRENT_TIMESTAMP	
3. files — файлы
Поле	Тип	Описание
id	INT AUTO_INCREMENT PRIMARY KEY	
user_id	INT NOT NULL	FOREIGN KEY → users(id)
original_name	VARCHAR(255) NOT NULL	
stored_name	VARCHAR(255) NOT NULL	
file_size	INT NOT NULL	
file_type	VARCHAR(100)	
is_public	BOOLEAN DEFAULT FALSE	
folder_id	INT DEFAULT NULL	FOREIGN KEY → folders(id)
description	TEXT DEFAULT NULL	
upload_date	TIMESTAMP DEFAULT CURRENT_TIMESTAMP	
4. folders — папки
Поле	Тип	Описание
id	INT AUTO_INCREMENT PRIMARY KEY	
user_id	INT NOT NULL	FOREIGN KEY → users(id)
name	VARCHAR(255) NOT NULL	
parent_id	INT DEFAULT NULL	FOREIGN KEY → folders(id)
created_at	TIMESTAMP DEFAULT CURRENT_TIMESTAMP	
5. share_links — временные публичные ссылки (v5.0)
Поле	Тип	Описание
id	INT AUTO_INCREMENT PRIMARY KEY	
file_id	INT NOT NULL	FOREIGN KEY → files(id)
token	VARCHAR(32) NOT NULL UNIQUE	
created_by	INT NOT NULL	FOREIGN KEY → users(id)
expires_at	TIMESTAMP NOT NULL	
created_at	TIMESTAMP DEFAULT CURRENT_TIMESTAMP	
6. user_file_views — отметки о просмотре файлов (v5.0)
Поле	Тип	Описание
id	INT AUTO_INCREMENT PRIMARY KEY	
user_id	INT NOT NULL	FOREIGN KEY → users(id)
file_id	INT NOT NULL	FOREIGN KEY → files(id)
viewed_at	TIMESTAMP DEFAULT CURRENT_TIMESTAMP	
UNIQUE KEY	unique_view (user_id, file_id)	
📡 ЧАСТЬ 3: API ENDPOINTS
Базовый URL
https://gazonbaza.ru (общий для мобильного и веб-приложения)

Все эндпоинты:
register.php, login.php, list_files.php, upload.php, download.php

delete.php, rename.php, toggle_visibility.php, profile.php

create_folder.php, delete_folder.php, rename_folder.php, list_folders.php, move_file.php

move_folder.php 🆕 v5.5 — перемещение папки в другую папку или корень

get_share_link.php, public_download.php, mark_viewed.php

auth.php, json_input.php, notification_helper.php

Исправления в upload.php (v5.3)
✅ Убран дублирующий INSERT (файлы больше не дублируются в БД)

✅ Переменные 
i
s
P
u
b
l
i
c
,
isPublic,folderId, $description определяются до использования

✅ Добавлено поле description в INSERT-запрос

Новый эндпоинт: move_folder.php (v5.5)
Принимает: folder_id, target_folder_id (null = корень)

Проверка прав: админ или владелец папки

Защита от рекурсии: нельзя переместить папку в саму себя или потомка

Возвращает: {"status": "success"} / {"status": "error", "message": "..."}

📱 ЧАСТЬ 4: FLUTTER-ПРИЛОЖЕНИЕ (v5.5 — кросс-платформенное)
Технологии
Фреймворк: Flutter (Dart)

Минимальная версия SDK: ^3.0.0

Целевые платформы: Android (APK) + Web (HTML/JS)

Репозиторий: https://github.com/rubigruz-creator/adidas-obmennik (Public)

Ветки:

main — стабильная версия Android (v5.1)

feature/web-version — веб-версия и документация (v5.2–v5.5)

Актуальные зависимости (pubspec.yaml v5.5)
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
  universal_html: ^2.2.4              # Web-совместимость
Структура проекта (v5.5)
text
lib/
├── main.dart
├── screens/
│   ├── splash_screen.dart
│   ├── login_screen.dart
│   ├── files_screen.dart              # 🆕 v5.5: Режим выбора, групповые удаление/перемещение, динамический AppBar
│   ├── file_operations.dart           # v5.3: Превью в меню файла, kIsWeb-проверки
│   ├── folder_operations.dart
│   ├── upload_operations.dart         # v5.4: Множественная загрузка (UploadTask, MultiUploadDialog)
│   ├── profile_screen.dart
│   └── lock_screen.dart
├── widgets/
│   ├── file_card.dart                 # 🆕 v5.5: Чекбокс для режима выбора, isSelected-подсветка
│   ├── file_list_tile.dart            # 🆕 v5.5: Чекбокс для режима выбора, выделение строки
│   ├── folder_card.dart               # 🆕 v5.5: Чекбокс для режима выбора, isSelected-подсветка
│   ├── folder_list_tile.dart          # 🆕 v5.5: Чекбокс для режима выбора
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
    ├── api_service.dart               # 🆕 v5.5: Добавлен метод moveFolder()
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

🖥️ ЧАСТЬ 5: ВЕБ-ВЕРСИЯ (v5.5)
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

🆕 ЧАСТЬ 6: НОВОЕ В v5.5 — МНОЖЕСТВЕННАЯ ОБРАБОТКА ФАЙЛОВ
✅ Реализовано: Режим выбора и групповые операции
6.1 Режим выбора (Selection Mode)
Вход: долгое нажатие (Android) / правый клик мыши (Web) на файле или папке

Выбор нескольких: тап/клик по элементам добавляет/снимает выделение

Визуальная индикация:

Чекбокс в круге (grid-режим) или круглый индикатор (list-режим)

Синяя обводка карточки у выбранных элементов

Подсветка фона в list-режиме

Автовыход: при снятии выделения с последнего элемента режим выключается

6.2 Динамический AppBar
Заголовок: «Выбрано: N» (обновляется при изменении выбора)

Кнопка «Удалить» (корзина) — групповая операция

Кнопка «Переместить» (folder_move) — групповая операция

Кнопка «Отмена» (крестик) — выход из режима выбора

FAB скрывается в режиме выбора

6.3 Групповое удаление
Диалог подтверждения с указанием количества элементов

Последовательное удаление файлов через ApiService.deleteFile

Последовательное удаление папок через ApiService.deleteFolder

SnackBar с результатом: «Удалено: N» или «Удалено: N, ошибок: M»

Автоматический выход из режима выбора после завершения

6.4 Групповое перемещение
Диалог выбора целевой папки (с поддержкой «Корень»)

Выбранные папки исключаются из списка доступных (защита от рекурсии)

Последовательное перемещение файлов через ApiService.moveFile

Последовательное перемещение папок через ApiService.moveFolder

SnackBar с результатом

Автоматический выход из режима выбора после завершения

6.5 Затронутые файлы
Файл	Изменения
lib/screens/files_screen.dart	Добавлены: isSelectionMode, selectedItemIds, методы enterSelectionMode(), exitSelectionMode(), toggleSelection(), _deleteSelected(), _moveSelected(), динамический _buildAppBar(). Обновлены buildGridView(), buildListView() с передачей параметров выбора в виджеты.
lib/widgets/file_card.dart	Добавлены параметры: isSelectionMode, isSelected. Чекбокс в левом верхнем углу, синяя обводка при выборе, зелёный индикатор скрывается в режиме выбора.
lib/widgets/file_list_tile.dart	Добавлены параметры: isSelectionMode, isSelected. Круглый чекбокс вместо иконки файла в режиме выбора, подсветка фона.
lib/widgets/folder_card.dart	Добавлены параметры: isSelectionMode, isSelected. Чекбокс и обводка аналогично FileCard.
lib/widgets/folder_list_tile.dart	Добавлены параметры: isSelectionMode, isSelected. Круглый чекбокс вместо иконки папки.
lib/services/api_service.dart	Добавлен метод moveFolder() для перемещения папок.
public_html/move_folder.php	🆕 Новый серверный скрипт для перемещения папок с защитой от рекурсии.
6.6 Обратная совместимость
Все одиночные операции (скачать, переименовать, поделиться, удалить, переместить) полностью сохранены

Обычный тап/клик на файл → меню (как в v5.4)

Обычный тап/клик на папку → вход в папку

FAB-меню, поиск, сортировка — без изменений

🆕 ЧАСТЬ 7: НОВОЕ В v5.4 — МНОЖЕСТВЕННАЯ ЗАГРУЗКА ФАЙЛОВ (СОХРАНЕНО)
✅ Реализовано ранее
Выбор нескольких файлов через FilePicker.platform.pickFiles(allowMultiple: true)

Диалог очереди загрузки (MultiUploadDialog) с индивидуальным прогрессом

Общие настройки: видимость и описание для всех файлов

Кнопка отмены для каждого файла и «Отменить всё»

Автоматическое обновление списка после завершения

Классы: UploadTask, MultiUploadDialog, MultiUploadDialogState

📜 ЧАСТЬ 8: ИСТОРИЯ ВЕРСИЙ
v5.5 (текущая) — МНОЖЕСТВЕННАЯ ОБРАБОТКА ФАЙЛОВ
✅ Режим выбора: долгое нажатие / правый клик

✅ Чекбоксы на карточках файлов и папок (grid + list)

✅ Динамический AppBar с количеством выбранных элементов

✅ Групповое удаление (файлы + папки) с подтверждением

✅ Групповое перемещение (файлы + папки) с выбором целевой папки

✅ Защита от рекурсии при перемещении папок

✅ Новый API-метод: moveFolder

✅ Новый серверный скрипт: move_folder.php

✅ Обратная совместимость со всеми одиночными операциями

✅ Кросс-платформенность: Android (APK) + Web

v5.4 — МНОЖЕСТВЕННАЯ ЗАГРУЗКА
✅ Множественная загрузка файлов через FilePicker (allowMultiple: true)

✅ Диалог очереди загрузки с индивидуальным прогрессом

✅ Кнопки отмены для каждого файла и «Отменить всё»

✅ Общие настройки видимости и описания для группы файлов

✅ Классы UploadTask, MultiUploadDialog, MultiUploadDialogState

✅ Автоматическое обновление списка после завершения

✅ Обратная совместимость с одиночной загрузкой

v5.3 — ИСПРАВЛЕНИЯ И СТАБИЛИЗАЦИЯ
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

v5.1 — БРЕНДИНГ, БЕЗОПАСНОСТЬ И ПОЛИРОВКА
✅ Смена названия на «АДИДАС», логотип в AppBar и на экранах

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
⚠️ ИЗВЕСТНЫЕ ОШИБКИ И УРОКИ (v5.5)
Tree-shaking вырезает приватные классы (_UploadTask, _MultiUploadDialog). Все классы, используемые в другом контексте, должны быть публичными.

PowerShell съедает символ $ в heredoc-строках. Лучше заменять код через VSCode.

uploadFileBytesWithProgress не работает — не отправляет тело запроса. Использовать uploadFileBytes без реального прогресса.

Локальный запуск через localhost вызывает CORS-ошибки. Тестировать на production-домене.

Веб-сборка только на локальном ПК — на сервере нет Flutter SDK. Сборка → scp на сервер.

🔜 ПЛАНЫ НА БУДУЩЕЕ
🧾 Задача 2: Аудит действий пользователя (следующий этап)
Таблица audit_log в MariaDB:

id, user_id, action, file_id, folder_id, details (JSON), created_at

Серверный эндпоинт audit_log.php (только для админов)

Логирование действий: загрузка, удаление, скачивание, переименование, перемещение, изменение видимости, вход/выход

Экран «История» в приложении (доступен только админам)

Фильтры по пользователю, действию, дате

📋 Остальные задачи
Задача 3: Drag-and-drop в веб-версии

Задача 4: Двухфакторная аутентификация

Задача 5: Шифрование файлов

Задача 6: Исправление uploadFileBytesWithProgress (реальный прогресс)

🚀 Статус v5.5
Множественная обработка файлов реализована и протестирована:

✅ Режим выбора с чекбоксами (Android: долгое нажатие, Web: правый клик)

✅ Групповое удаление файлов и папок

✅ Групповое перемещение файлов и папок

✅ Динамический AppBar с кнопками действий

✅ Защита от рекурсии при перемещении папок

✅ Протестировано на Android (APK) и Web (gazonbaza.ru/app)

✅ Обратная совместимость сохранена

Проект готов к следующему этапу — аудит действий пользователя.