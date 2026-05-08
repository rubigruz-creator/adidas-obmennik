mindmap
  root((АДИДАС<br>Корпоративный файлообменник))
    Сервер BeGet VPS
      Ubuntu
      HestiaCP
      Nginx
        HTTP/HTTPS
        Прокси на Apache2:8080
        WebSocket /socket.io/ → :3001
        Статика /app → Flutter Web
        Запрет /files/
      Apache2 (mod_php)
        PHP 8.1
          upload_max_filesize=300M
          post_max_size=300M
          max_execution_time=600
          memory_limit=512M
      MariaDB
        БД: avito_shop
        Пользователи: api_user (StrongPass123!)
        Таблицы
          users
          user_sessions
          files
          folders
          share_links
          user_file_views
          api_keys (устар.)
      Файловое хранилище
        /public_html/files/
        Загрузки через API
      Логи
        /var/log/apache2/domains/gazonbaza.ru.error.log

    Приложения
      Android (APK)
        Flutter SDK 3.0+
        Зависимости
          lottie, flutter_svg, secure_storage
          http, file_picker, image_picker
          permission_handler, open_file
          socket_io_client, share_plus
          cached_network_image, crypto
        Экраны
          Splash Screen (Lottie-анимация)
          Login Screen (брендинг)
          Files Screen (основной)
          Profile Screen (PIN-код)
          Lock Screen (защита)
        Миксины
          FileOperations (CRUD + права)
          FolderOperations
          UploadOperations (kIsWeb)
        Сервисы
          ApiService (REST)
          AuthService (StorageService)
          NotificationService
          WebSocketService
      Web (Flutter Web)
        Домен https://gazonbaza.ru/app
        Те же экраны/логика
        Адаптация kIsWeb
          Upload: bytes
          Download: Blob
          Storage: SharedPreferences
          PIN: менее безопасен
        Nginx: location /app → статика
        Сборка: flutter build web --base-href /app/

    API Endpoints
      Авторизация
        register.php
        login.php
        auth.php
      Файлы
        list_files.php (is_new)
        upload.php (уведомление админам)
        download.php (thumbnail .bmp)
        delete.php
        rename.php
        toggle_visibility.php
        move_file.php
        get_share_link.php (7 дней)
        public_download.php
        mark_viewed.php
      Папки
        create_folder.php
        delete_folder.php
        rename_folder.php
        list_folders.php
      Профиль
        profile.php
      Вспомогательные
        json_input.php
        cors.php (удалён, CORS через Nginx)

    Пользователи
      Роли
        Пользователь
        Администратор
      Действия
        Регистрация
        Вход/Выход
        Управление файлами/папками
        Публичные ссылки
        Уведомления (admins)
      Безопасность
        Хеширование паролей
        Токены сессий (user_sessions)
        PIN-код (SHA-256)

    Документация
      Project_map_5.2.md (тех.карта)
      web_version_guide.md
      github_map.md
      user_guide.md (инструкция)
      presentation.md (презентация)
      mental_map.md (эта карта)