# 🗺️ GitHub-карта проекта АДИДАС

## 📌 Репозиторий

**URL:** https://github.com/rubigruz-creator/adidas-obmennik
**Видимость:** Public
**Владелец:** rubigruz-creator

---

## 🌿 Ветки
main (стабильная)
├── v5.1 — Брендинг, PIN-код, Splash Screen
└── v5.0 — Социальные функции, уведомления

feature/web-version (разработка)
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

---

## 📂 Структура репозитория
adidas-obmennik/
├── .git/
├── lib/ # Исходный код Flutter
│ ├── main.dart
│ ├── screens/
│ │ ├── splash_screen.dart
│ │ ├── login_screen.dart
│ │ ├── files_screen.dart
│ │ ├── file_operations.dart
│ │ ├── folder_operations.dart
│ │ ├── upload_operations.dart # 🆕 kIsWeb
│ │ ├── profile_screen.dart
│ │ └── lock_screen.dart
│ ├── widgets/
│ │ ├── file_card.dart
│ │ ├── file_list_tile.dart
│ │ ├── folder_card.dart
│ │ ├── folder_list_tile.dart
│ │ ├── file_icon.dart
│ │ ├── empty_state.dart
│ │ └── breadcrumb_chips.dart
│ ├── utils/
│ │ ├── app_config.dart
│ │ ├── format_file_size.dart
│ │ ├── format_date.dart
│ │ └── platform_utils.dart # 🆕
│ └── services/
│ ├── api_service.dart # 🆕 kIsWeb
│ ├── auth_service.dart # 🆕 StorageService
│ ├── notification_service.dart
│ ├── websocket_service.dart
│ ├── storage_service.dart # 🆕
│ ├── platform_storage_mobile.dart # 🆕
│ ├── platform_storage_web.dart # 🆕
│ └── service_locator.dart # 🆕
├── assets/
│ ├── animations/adidas.json
│ └── logo/adidas_logo.svg
├── android/ # Android-конфигурация
├── build/ # Собранные файлы
│ ├── web/ # 🆕 Веб-сборка
│ └── app/outputs/flutter-apk/ # APK
├── web/ # 🆕 Веб-конфигурация
│ ├── index.html
│ └── manifest.json
├── docs/ # 🆕 Документация
│ ├── Project_map_5.2.md # Карта проекта
│ ├── web_version_guide.md # Документация веб-версии
│ ├── user_guide.md # Инструкция пользователя
│ ├── presentation.md # Презентация
│ └── github_map.md # Этот файл
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
# Компьютер
scp -r build/web/* rubi@90.156.171.36:/home/rubi/web/gazonbaza.ru/public_html/web/

# Сервер
ssh root@90.156.171.36
chown -R rubi:www-data /home/rubi/web/gazonbaza.ru/public_html/web/
chmod -R 755 /home/rubi/web/gazonbaza.ru/public_html/web/
Деплой APK
bash
# APK здесь:
# build/app/outputs/flutter-apk/app-release.apk

## 📊 Статус проекта
Компонент	Статус	Версия
Android-приложение	✅ Стабильно	v5.1
Веб-версия	✅ Работает	v5.2
Сервер (API + БД)	✅ Стабильно	v5.0
Документация	✅ Готово	v5.2
Презентация	✅ Готово	v5.2
Загрузка файлов (веб)	⚠️ В процессе	Исправляется

## 🚀 Планы
Исправить загрузку файлов в веб-версии

Добавить drag-and-drop в веб-версии

Множественная загрузка файлов

Аудит действий пользователя

Двухфакторная аутентификация

---

## ✅ Итого создано 3 документа:

| Файл | Содержание |
|------|------------|
| `docs/Project_map_5.2.md` | Полная карта проекта (обновлённая) |
| `docs/web_version_guide.md` | Техническая документация веб-версии |
| `docs/github_map.md` | GitHub-карта с историей коммитов |

Все файлы лежат в папке `docs/` твоего проекта. Их можно коммитить в GitHub!

```powershell```
cd C:\Users\USER\my_api_app
git add docs/
git commit -m "Документация v5.2: карта проекта, веб-версия, GitHub"
git push origin feature/web-version

🚀 Готово!