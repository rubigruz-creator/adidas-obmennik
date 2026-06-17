# 🗺️ GitHub-карта проекта АДИДАС

## 📌 Репозиторий

**URL:** https://github.com/rubigruz-creator/adidas-obmennik
**Видимость:** Public
**Владелец:** rubigruz-creator

---

## 🌿 Ветки

main (стабильная)
├── v5.3 — Исправления: загрузка, превью, индикатор прогресса
├── v5.1 — Брендинг, PIN-код, Splash Screen
└── v5.0 — Социальные функции, уведомления

feature/web-version (разработка)
├── v5.3 — Исправления и стабилизация (текущая)
└── v5.2 — Веб-версия, кросс-платформенность, документация

---

## 📝 История коммитов

### Ветка: `main`

| # | Коммит | Описание |
|---|--------|----------|
| 1 | `Initial commit` | Исходный код v5.1 — Android-приложение |
| 2 | `Добавлены платформенные абстракции для Web-версии` | StorageService, platform_utils, service_locator |

### Ветка: `feature/web-version`

| # | Коммит | Описание | Файлы |
|---|--------|----------|-------|
| 1 | `Добавлены платформенные абстракции` | StorageService, Mobile/Web реализации, platform_utils | `lib/services/storage_service.dart`, `lib/services/platform_storage_mobile.dart`, `lib/services/platform_storage_web.dart`, `lib/services/service_locator.dart`, `lib/utils/platform_utils.dart` |
| 2 | `Адаптация api_service.dart под Web` | kIsWeb для upload/download, _downloadFileWeb | `lib/services/api_service.dart` |
| 3 | `Адаптация auth_service.dart под StorageService` | Замена FlutterSecureStorage на StorageService | `lib/services/auth_service.dart` |
| 4 | `Адаптация upload_operations.dart под Web` | kIsWeb для file_picker и image_picker | `lib/screens/upload_operations.dart` |
| 5 | `Сборка веб-версии и настройка Nginx` | Конфиг nginx.ssl.conf, base-href /app/ | `web/`, `nginx.ssl.conf` |
| 6 | `Исправление CORS` | Удалён cors.php и require_once из PHP, CORS через Nginx | `public_html/*.php`, `nginx.ssl.conf` |
| 7 | `Исправление прав доступа и деплой` | chown/chmod для web/, scp-загрузка | — |
| 8 | `Документация v5.2` | Project_map_5.2.md, user_guide.md, presentation.md, github_map.md | `docs/` |
| 9 | `Финальные правки веб-версии` | Исправление 403/500, редиректов, alias | `nginx.ssl.conf` |
| 10 | `Исправление загрузки файлов (v5.3)` | uploadFileBytes, без дублирования, Blob URL для скачивания | `lib/services/api_service.dart`, `lib/screens/upload_operations.dart`, `public_html/upload.php` |
| 11 | `Исправление превью изображений (v5.3)` | Image.network + заголовки, превью в сетке и меню | `lib/widgets/file_card.dart`, `lib/screens/file_operations.dart` |
| 12 | `Исправление индикатора прогресса (v5.3)` | Убран Timer, диалог с LinearProgressIndicator | `lib/screens/upload_operations.dart` |
| 13 | `Отключение PIN-кода в вебе и чистка кода (v5.3)` | main.dart, удаление uploadProgressTimer | `lib/main.dart`, `lib/screens/files_screen.dart` |
| 14 | `Документация v5.3` | Project_map_5.3.md, обновление github_map.md, промпт для агента | `docs/` |
| 15 | `Презентация на сервере` | presentation.html, location /presentation в Nginx | `docs/presentation.html`, `nginx.ssl.conf` |
| 16 | `Настройка сервера для больших файлов` | Таймауты Nginx, PHP 8.3, client_max_body_size | `nginx.ssl.conf`, `php.ini` |

---

## 📂 Структура репозитория

adidas-obmennik/
├── .git/
├── lib/                         # Исходный код Flutter
│   ├── main.dart                # 🆕 v5.3: PIN-код отключён в веб-версии
│   ├── screens/
│   │   ├── splash_screen.dart
│   │   ├── login_screen.dart
│   │   ├── files_screen.dart
│   │   ├── file_operations.dart # 🆕 v5.3: превью в меню, kIsWeb-проверки
│   │   ├── folder_operations.dart
│   │   ├── upload_operations.dart # 🆕 v5.3: uploadFileBytes, индикатор прогресса
│   │   ├── profile_screen.dart
│   │   └── lock_screen.dart
│   ├── widgets/
│   │   ├── file_card.dart       # 🆕 v5.3: превью в сетке (Image.network)
│   │   ├── file_list_tile.dart
│   │   ├── folder_card.dart
│   │   ├── folder_list_tile.dart
│   │   ├── file_icon.dart
│   │   ├── empty_state.dart
│   │   └── breadcrumb_chips.dart
│   ├── utils/
│   │   ├── app_config.dart
│   │   ├── format_file_size.dart
│   │   ├── format_date.dart
│   │   └── platform_utils.dart  # 🆕 v5.2
│   └── services/
│       ├── api_service.dart     # 🆕 v5.3: uploadFileBytes, _downloadFileWeb (Blob URL)
│       ├── auth_service.dart    # 🆕 v5.2: StorageService
│       ├── notification_service.dart
│       ├── websocket_service.dart
│       ├── storage_service.dart # 🆕 v5.2
│       ├── platform_storage_mobile.dart # 🆕 v5.2
│       ├── platform_storage_web.dart    # 🆕 v5.2
│       └── service_locator.dart        # 🆕 v5.2
├── assets/
│   ├── animations/adidas.json
│   └── logo/adidas_logo.svg
├── android/                     # Android-конфигурация
├── build/                       # Собранные файлы
│   ├── web/                     # 🆕 v5.2: Веб-сборка
│   └── app/outputs/flutter-apk/ # APK
├── web/                         # 🆕 v5.2: Веб-конфигурация
│   ├── index.html
│   └── manifest.json
├── docs/                        # 🆕 v5.2-v5.3: Документация
│   ├── Project_map_5.3.md       # 🆕 v5.3: Актуальная карта проекта
│   ├── Project_map_5.2.md       # v5.2: Предыдущая карта
│   ├── Project_map_5.1.md       # v5.1: Предыдущая карта
│   ├── web_version_guide.md     # v5.2: Документация веб-версии
│   ├── user_guide.md            # v5.2: Инструкция пользователя
│   ├── presentation.md          # v5.2: Презентация (текст)
│   ├── presentation.html        # 🆕 v5.3: HTML-презентация (12 слайдов)
│   ├── github_map.md            # 🆕 v5.3: Этот файл (обновлён)
│   └── ПРОМПТ ДЛЯ СЛЕДУЮЩЕГО ИИ-АГЕНТА (v5.3).md # 🆕 v5.3
├── pubspec.yaml
└── README.md

---

## 🔄 Workflow

### Разработка

```bash```
git checkout feature/web-version
# ... правки кода ...
flutter build web --base-href "/app/"
flutter build apk --release
git add .
git commit -m "Описание изменений"
git push origin feature/web-version
Деплой веб-версии
bash
# Компьютер (Windows PowerShell)
cd C:\Users\USER\my_api_app
flutter build web --base-href "/app/" --release
scp -r build/web/* rubi@90.156.171.36:/home/rubi/web/gazonbaza.ru/public_html/web/

# Сервер (SSH)
ssh root@90.156.171.36
chown -R rubi:www-data /home/rubi/web/gazonbaza.ru/public_html/web/
chmod -R 755 /home/rubi/web/gazonbaza.ru/public_html/web/
exit
Деплой APK
bash
cd C:\Users\USER\my_api_app
flutter build apk --release
# APK здесь:
# build/app/outputs/flutter-apk/app-release.apk
📊 Статус проекта
Компонент	Статус	Версия
Android-приложение	✅ Стабильно	v5.3
Веб-версия	✅ Стабильно	v5.3
Сервер (API + БД)	✅ Стабильно	v5.3
Документация	✅ Готово	v5.3
Презентация	✅ Готово	v5.3
Загрузка файлов	✅ Работает (Android + Web)	v5.3
Скачивание файлов	✅ Работает (Android + Web)	v5.3
Превью изображений	✅ Работает (сетка + меню)	v5.3
Индикатор прогресса	✅ Работает	v5.3
PIN-код	✅ Android / ⚠️ Отключён в Web	v5.3
🚀 Планы (v5.4+)
#	Задача	Приоритет
1	Множественная загрузка файлов	ВЫСОКИЙ
2	Множественная обработка (удаление, перемещение)	ВЫСОКИЙ
3	Аудит действий пользователя	СРЕДНИЙ
4	Drag-and-drop в веб-версии	НИЗКИЙ
5	Двухфакторная аутентификация	НИЗКИЙ
6	Шифрование файлов	НИЗКИЙ
✅ Итого документов в docs/
Файл	Содержание	Версия
Project_map_5.3.md	Полная карта проекта (актуальная)	v5.3
Project_map_5.2.md	Предыдущая карта проекта	v5.2
Project_map_5.1.md	Предыдущая карта проекта	v5.1
web_version_guide.md	Техническая документация веб-версии	v5.2
user_guide.md	Инструкция пользователя	v5.2
presentation.md	Презентация (текст)	v5.2
presentation.html	HTML-презентация (12 слайдов)	v5.3
github_map.md	GitHub-карта с историей коммитов	v5.3
ПРОМПТ ДЛЯ СЛЕДУЮЩЕГО ИИ-АГЕНТА (v5.3).md	Промпт для продолжения разработки	v5.3
Готово к коммиту! 🚀