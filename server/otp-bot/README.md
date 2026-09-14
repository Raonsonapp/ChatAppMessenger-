# ChatApp OTP Bot

Ин сервер SMS-и Firebase-ро иваз мекунад: корбар боти Telegram-ро оғоз мекунад,
рақами телефони худро мубодила мекунад, ва бот дар ҳамон чат рамзи 6-рақама
мефиристад. Апп он рамзро тавассути `/api/otp/verify` тасдиқ мекунад ва дар
ҷавоб як Firebase custom token мегирад, то `signInWithCustomToken`-ро истифода
барад (Firestore/Storage/Agora ҳамчунон бо ҳамон Firebase Auth UID кор мекунанд).

## Насб дар Railway

1. **Боти Telegram созед**: дар Telegram ба [@BotFather](https://t.me/BotFather)
   нависед, `/newbot`-ро иҷро кунед, ном ва username диҳед — токенро нигоҳ доред.
2. **Service Account-и Firebase**: Firebase Console → Project Settings →
   [Service accounts](https://console.firebase.google.com/project/chatapp-57fb2/settings/serviceaccounts/adminsdk)
   → "Generate new private key" — файли `.json` боргирӣ мешавад.
3. Дар [railway.com](https://railway.com) лоиҳаи нав созед → "Deploy from GitHub
   repo" → ҳамин репозиторийро интихоб кунед. **ҲАТМӢ:** дар Service →
   Settings → Source → **Root Directory**-ро ба `server/otp-bot` танзим кунед.
   Бе ин, Railway решаи репозиторий (лоиҳаи Flutter)-ро build карданӣ мешавад
   ва бо хатогӣ мешиканад, чунки дар он ҷо `package.json` нест.
4. Дар Variables-и Railway ду тағйирёбандаро илова кунед:
   - `TELEGRAM_BOT_TOKEN` — токени BotFather
   - `FIREBASE_SERVICE_ACCOUNT_JSON` — тамоми матни файли JSON-и қадами 2-ро
     АЙНАН нусхабардорӣ карда дар ин ҷо часпонед (якҷоя бо `{` ва `}`).
     Base64 лозим нест — Railway қиматҳои бисёрхаттаро қабул мекунад.
5. Railway худкор deploy мекунад — тавассути `Dockerfile`-и ҳамин папка
   (Settings → Build → Builder: Dockerfile). Пас аз deploy, дар Settings →
   Networking → "Generate Domain" домен созед, target port-ро `3000` гузоред.
6. Дар апп: `lib/config/otp_server_config.dart`-ро кушоед ва `baseUrl`-ро ба
   ҳамон домен иваз кунед, ва `telegramBotUsername`-ро ба username-и боти
   сохтаатон (бе `@`).

> Эзоҳ: Railway "Config as Code"-ро (`railway.json`) аз кор мебарорад ва
> хидматҳои нав онро истифода бурда наметавонанд, бинобар ин ҳамаи танзимот
> дастӣ дар UI-и Railway гузошта мешаванд.

## Санҷиши маҳаллӣ

```bash
cd server/otp-bot
cp .env.example .env   # TELEGRAM_BOT_TOKEN ва FIREBASE_SERVICE_ACCOUNT_JSON-ро пур кунед
npm install
npm start
```

## Маҳдудият

Рамзҳо дар хотираи процесс (`Map` дар RAM) нигоҳ дошта мешаванд — агар сервер
рестарт шавад, рамзҳои дар интизор буда гум мешаванд (корбар бояд аз нав
дархост кунад). Барои миқёси калон, ин Map-ро ба Redis/Firestore иваз кунед.
