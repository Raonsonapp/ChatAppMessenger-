"""Idempotently add ChatApp Plus/icon/account translation keys and Flutter assets entry."""
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]

TRANSLATIONS = {
    "strings_tj.dart": [
        ("k643", "Иваз кардани логотипи барнома"),
        ("k644", "Яке аз 10 логотипро интихоб кунед. Ин нишонаи воқеии ChatApp дар экрани телефонро иваз мекунад."),
        ("k645", "Барои истифодаи логотипҳои иловагӣ ChatApp Plus фаъол бошад."),
        ("k646", "Эзоҳ: баъзе launcher-ҳои Android нишонаи навро баъди чанд лаҳза нишон медиҳанд."),
        ("k650", "Логотипи барнома иваз шуд. Агар фавран намоён нашавад, каме интизор шавед."),
        ("k651", "Логотип иваз нашуд. Барномаро нав карда, дубора кӯшиш кунед."),
        ("k652", "Илова кардани ҳисоб"),
        ("k653", "Калидҳои дастрасӣ"),
        ("k654", "Парол"),
        ("k655", "Суроғаи электронӣ"),
        ("k656", "Тасдиқи дуқадамӣ"),
        ("k657", "Огоҳиномаҳои амниятӣ"),
        ("k658", "Танзимоти таблиғоти Meta"),
        ("k659", "Ин хусусият ҳоло дар ChatApp пайваст нашудааст."),
        ("k660", "Барои барқарор кардани парол аввал суроғаи электрониро ба ҳисоб пайваст кунед."),
        ("k661", "ChatApp танзимоти таблиғоти Meta надорад."),
        ("k662", "Илова нашудааст"),
        ("k663", "Илова кардани суроға"),
        ("k664", "Суроғаи электрониро дуруст ворид кунед."),
        ("k665", "Парол бояд ҳадди ақал 6 аломат дошта бошад."),
        ("k666", "Суроға пайваст шуд. Почтаи электрониро барои тасдиқ санҷед."),
        ("k667", "Ин суроға аллакай ба ҳисоб пайваст шудааст."),
        ("k668", "Амалиёт иҷро нашуд. Дар танзимоти Firebase Email/Password-ро фаъол кунед ва дубора кӯшиш кунед."),
        ("k669", "Пайванди барқарор кардани парол ба почта фиристода шуд."),
        ("k670", "Стикерҳои махсус"),
        ("k671", "Оҳангҳои махсуси занг"),
        ("k672", "Танзими рӯйхати чатҳо"),
        ("k673", "Чатҳои иловагиро маҳкам кардан"),
        ("k674", "Ин имконият ҳоло омода нест. Он то пайваст шудани функсияи воқеӣ фаъол карда намешавад."),
        ("k675", "Иваз кардани рақами телефон"),
        ("k676", "Нав кардани логотипи барнома"),
        ("k678", "Иваз кардани рақами телефон ҳоло дастгирӣ намешавад; он тасдиқи нави рақамро талаб мекунад."),
    ],
    "strings_ru.dart": [
        ("k643", "Изменить значок приложения"),
        ("k644", "Выберите один из 10 значков. Он изменит настоящий значок ChatApp на главном экране телефона."),
        ("k645", "Для использования дополнительных значков требуется активный ChatApp Plus."),
        ("k646", "Примечание: некоторые лаунчеры Android обновляют значок с небольшой задержкой."),
        ("k650", "Значок приложения изменён. Если он не появился сразу, подождите немного."),
        ("k651", "Не удалось изменить значок. Перезапустите приложение и попробуйте снова."),
        ("k652", "Добавить аккаунт"),
        ("k653", "Ключи доступа"),
        ("k654", "Пароль"),
        ("k655", "Электронный адрес"),
        ("k656", "Двухэтапная проверка"),
        ("k657", "Уведомления безопасности"),
        ("k658", "Рекламные предпочтения Meta"),
        ("k659", "Эта функция пока не подключена в ChatApp."),
        ("k660", "Чтобы сбросить пароль, сначала привяжите электронный адрес к аккаунту."),
        ("k661", "В ChatApp нет настроек рекламы Meta."),
        ("k662", "Не добавлен"),
        ("k663", "Добавить адрес"),
        ("k664", "Введите корректный электронный адрес."),
        ("k665", "Пароль должен содержать не менее 6 символов."),
        ("k666", "Адрес привязан. Проверьте почту для подтверждения."),
        ("k667", "Этот адрес уже привязан к аккаунту."),
        ("k668", "Не удалось выполнить действие. Включите Email/Password в настройках Firebase и попробуйте снова."),
        ("k669", "Письмо для сброса пароля отправлено."),
        ("k670", "Эксклюзивные стикеры"),
        ("k671", "Особые мелодии звонка"),
        ("k672", "Настройка списков чатов"),
        ("k673", "Закрепление дополнительных чатов"),
        ("k674", "Эта возможность пока не готова и не будет включена до реализации настоящей функции."),
        ("k675", "Изменить номер телефона"),
        ("k676", "Обновить значок приложения"),
        ("k678", "Смена номера пока не поддерживается: для неё требуется повторное подтверждение номера."),
    ],
    "strings_en.dart": [
        ("k643", "Change app icon"),
        ("k644", "Choose one of 10 icons. This changes the actual ChatApp icon on your phone home screen."),
        ("k645", "An active ChatApp Plus subscription is required to use additional icons."),
        ("k646", "Note: some Android launchers may take a moment to refresh the icon."),
        ("k650", "App icon changed. If it does not appear immediately, wait a moment."),
        ("k651", "Could not change the icon. Reopen the app and try again."),
        ("k652", "Add account"),
        ("k653", "Passkeys"),
        ("k654", "Password"),
        ("k655", "Email address"),
        ("k656", "Two-step verification"),
        ("k657", "Security notifications"),
        ("k658", "Meta ad preferences"),
        ("k659", "This feature is not connected in ChatApp yet."),
        ("k660", "Link an email address to your account before resetting a password."),
        ("k661", "ChatApp does not have Meta ad preferences."),
        ("k662", "Not added"),
        ("k663", "Add email address"),
        ("k664", "Enter a valid email address."),
        ("k665", "Password must be at least 6 characters."),
        ("k666", "Email linked. Check your inbox to verify it."),
        ("k667", "This email is already linked to an account."),
        ("k668", "Could not complete this action. Enable Email/Password in Firebase settings and try again."),
        ("k669", "Password reset email sent."),
        ("k670", "Exclusive stickers"),
        ("k671", "Exclusive ringtones"),
        ("k672", "Manage chat lists"),
        ("k673", "Pin additional chats"),
        ("k674", "This feature is not ready yet and stays unavailable until the real functionality is implemented."),
        ("k675", "Change phone number"),
        ("k676", "Update app icon"),
        ("k678", "Changing the phone number is not supported yet because it requires a new number-verification flow."),
    ],
}

for filename, entries in TRANSLATIONS.items():
    path = ROOT / "lib" / "l10n" / filename
    text = path.read_text(encoding="utf-8")
    missing = [(key, value) for key, value in entries if f"'{key}':" not in text]
    if missing:
        closing = "\n};"
        if closing not in text:
            raise SystemExit(f"Cannot find map terminator in {path}")
        addition = "\n" + "\n".join(f"  '{key}': '{value}'," for key, value in missing) + closing
        text = text.replace(closing, addition, 1)
        path.write_text(text, encoding="utf-8")
        print(f"Added {len(missing)} keys to {filename}")
    else:
        print(f"Translation keys already present in {filename}")

pubspec = ROOT / "pubspec.yaml"
text = pubspec.read_text(encoding="utf-8")
asset_line = "    - assets/app_icons/"
if asset_line not in text:
    anchor = "    - assets/sounds/\n"
    if anchor not in text:
        raise SystemExit("Cannot find Flutter assets section in pubspec.yaml")
    text = text.replace(anchor, anchor + asset_line + "\n", 1)
    pubspec.write_text(text, encoding="utf-8")
    print("Added assets/app_icons/ to pubspec.yaml")
else:
    print("pubspec.yaml already includes assets/app_icons/")
