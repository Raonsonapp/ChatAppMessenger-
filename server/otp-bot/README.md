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
   Service accounts → Generate new private key. Файли JSON-ро ба base64 табдил
   диҳед: `base64 -w0 service-account.json`.
3. Дар [railway.com](https://railway.com) лоиҳаи нав созед → "Deploy from GitHub
   repo" → ҳамин репозиторийро интихоб кунед, вале **Root Directory**-ро ба
   `server/otp-bot` танзим кунед (Railway дар танзимоти Service → Settings →
   Root Directory).
4. Дар Variables-и Railway ду тағйирёбандаро илова кунед:
   - `BOT_TOKEN` — токени BotFather
   - `FIREBASE_SERVICE_ACCOUNT_BASE64` — сатри base64-и қадами 2
5. Railway худкор deploy мекунад (Nixpacks Node-ро муайян мекунад, `npm start`
   иҷро мешавад). Пас аз deploy, URL-и хидматро (масалан
   `https://chatapp-otp-bot-production.up.railway.app`) нусхабардорӣ кунед.
6. Дар апп: `lib/config/otp_server_config.dart`-ро кушоед ва
   `otpServerBaseUrl`-ро ба ҳамон URL иваз кунед, ва `telegramBotUsername`-ро
   ба username-и боти сохтаатон (бе `@`).

## Санҷиши маҳаллӣ

```bash
cd server/otp-bot
cp .env.example .env   # BOT_TOKEN ва FIREBASE_SERVICE_ACCOUNT_BASE64-ро пур кунед
npm install
npm start
```

## Маҳдудият

Рамзҳо дар хотираи процесс (`Map` дар RAM) нигоҳ дошта мешаванд — агар сервер
рестарт шавад, рамзҳои дар интизор буда гум мешаванд (корбар бояд аз нав
дархост кунад). Барои миқёси калон, ин Map-ро ба Redis/Firestore иваз кунед.
