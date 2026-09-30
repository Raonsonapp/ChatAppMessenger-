# Меъмории ChatApp

Ҳисоботи кӯтоҳ — то ҳар касе ки ба код дохил мешавад, донад чӣ дар куҷост.

## Экранҳо

Саҳифаи асосӣ `ChatListScreen` чор ҷадвал дорад дар `IndexedStack`:
`ChatsTab` · `StatusTab` · `CommunitiesTab` · `CallsTab`
(`lib/screens/tabs/`).

Чатҳо: `user_chat_screen` (шахсӣ), `group_chat_screen`, `community_chat_screen`,
`channel_screen`, `chat_detail_screen` (ёрдамчии AI).

Зангҳо: `call_screen` (шахсӣ, бо PiP), `group_call_screen`,
`incoming_call_screen`, `dial_pad_screen`, `schedule_call_screen`,
`favorites_screen`.

Танзимот: `lib/screens/settings/` — `settings_home_screen` (корти профил +
ҳамаи бандҳо), `account_settings_screen`, `linked_devices_screen`,
`privacy_settings_screen`, `notifications_settings_screen`,
`appearance_settings_screen`, `storage_settings_screen`,
`language_settings_screen`, `blocked_users_screen`, `help_screen`,
`about_screen`, `delete_account_screen`.

## Навигатсия

`Navigator` + `MaterialPageRoute`. **GoRouter нест.** Аниматсияи гузариш дар
`lib/theme/page_transitions.dart`.

## Идоракунии ҳолат

`ChangeNotifier` + нусхаҳои ягона (singleton). **Riverpod ва Bloc нест.**

Контроллерҳо: `themeController` · `localeController` · `wallpaperController` ·
`textScaleController` · `draftStore` · `chatThemeController` · `mediaSettings`.

Ҳама дар `main.dart` тавассути `Listenable.merge` ҷамъ мешаванд ва `AppScope`
(InheritedWidget) онҳоро ба ҳамаи экранҳо мерасонад. Ҳар `build()` бо
`AppScope.watch(context)` сар мешавад — бе он тағйири мавзӯъ ё забон дар
экрани кушода дида намешавад.

## Хизматҳои Firebase

- **Auth** — вуруд бо рақами телефон. Рамз тавассути боти Telegram меояд,
  сервер токени custom медиҳад (`server/otp-bot`).
- **Firestore** — ҳамаи маълумот. Кэши доимӣ фаъол.
- **FCM** — огоҳиҳо. Каналҳои Android дар `notification_service`.
- **Firebase Storage истифода намешавад.** Медиа дар **Cloudflare R2** аст;
  барнома аз сервер суроғаи presigned PUT мегирад (`lib/services/media_service`,
  `server/otp-bot/r2.js`).

## Сохтори маълумот

```
users/{uid}                     профил, blockedUsers, favorites, fcmTokens, username
users/{uid}/starred/{id}        паёмҳои ситорадор
users/{uid}/devices/{id}        дастгоҳҳои пайваст (платформа, нусха, фаъолият)
usernames/{name}                ягонагии @username → {uid}
conversations/{uidA_uidB}       чати шахсӣ + /messages
groups/{id}                     гурӯҳ + /messages
communities/{id}, channels/{id} ҷамъият ва канал + /messages
statuses/{uid}/items/{id}       навсозиҳо, 24 соат (expiresAt)
calls/{id}, scheduledCalls/{id} таърих ва зангҳои нақшашуда
reports/{id}                    шикоятҳо (танҳо навиштан)
linkPreviews/{hash}             кэши пешнамоиши ҳавола
```

## Системаи чат

Паёмҳо дар зерколлексияи `messages`. Модел — `lib/models/chat_message.dart`
(`deliveredTo`, `readBy`, `status`, `clientId`).
`message_status_service` тасдиқи расидан ва хонданро бо batch менависад.
Ҳубобҳо — `widgets/message_bubble.dart`: вокуниш, ҷавоб бо кашидан, таҳрир,
интихоби гурӯҳӣ, овоз, видео, пурсиш, пешнамоиши ҳавола.

## Системаи статус

`create_status_screen` → `statuses/{uid}/items`. Шакли матн дар
`models/status_style.dart` (12 замина, 4 ҳарф, 3 ҷойгиршавӣ) ҳамчун се рақам
нигоҳ дошта мешавад. Дидан — `status_viewer_screen`. Махфият —
`services/status_privacy.dart`.

## Системаи занг

Agora RTC. Токен аз сервер меояд (`agora_token_service` →
`server/otp-bot/agora.js`), uid ҳамеша **0** — token ва joinChannel бояд ҳамон
uid дошта бошанд.

`agora_engine_manager` муҳаррикро як нусха нигоҳ медорад ва пеш аз сохтани нав
кӯҳнаро озод мекунад — бе ин занги дуюм хатои `-17` медиҳад.

Сифати видео — `call_video_profile` (аз «Сарфаи трафик» вобаста).
Занги даромада: push-и **бе notification** (data-only) → `notification_service`
экрани пурраро мекушояд. Овози занг — `ringtone_service`.

## Системаи мавзӯъ

`app_theme.dart` — ду палитра (`darkPalette`, `lightPalette`), `AppColors`
ҳозираро нигоҳ медорад. `themeController` се ҳолат дорад: система/равшан/торик.
Намуди чат — `chat_theme_controller` (барои ҳар чат + намуди умумии
`__default__`). Замина — `wallpaper_controller`.

## Системаи медиа

Интихоб — `media_service`. Фишурдан — `compression_service` (аз «Сифати
медиа» вобаста). Боркунӣ ба R2. Кэши тасвир — `net_image` +
`cached_network_image`; он танзимоти «Боркунии худкор»-ро иҷро мекунад.
Нигоҳ доштан ба галерея — `media_download_service`.

## Санҷиш

- `flutter analyze` — 0 огоҳӣ
- `flutter test` — 52 санҷиш
- `node --test` дар `server/otp-bot` — 29 санҷиш
- Қоидаҳои Firestore дар эмулятори воқеӣ — 85 санҷиш
- `flutter build apk --release`

Ҳама дар `.github/workflows/build.yml` дар ҳар push иҷро мешаванд.

## Он чи ки ҳанӯз нест

Инҳо дидаву дониста сохта нашудаанд, то банди кор намекунанда пайдо нашавад:

- **Рамзгузории наздибанди (E2EE)** — нест. Гуфтани «ҳаст» хатарноктар аз
  набудани он мебуд.
- **Passkey, парол, почта, 2FA** — вуруд танҳо бо рақам ва рамзи Telegram аст.
- **ChatApp Plus** — системаи пардохт нест.
- **Иваз кардани иконкаи барнома** — дар Android `activity-alias` ва коди
  Kotlin талаб мекунад ва бе санҷиш дар дастгоҳи воқеӣ хатари онро дорад, ки
  иконка тамоман нопадид шавад.
- **Назорати волидайн** — нест.
