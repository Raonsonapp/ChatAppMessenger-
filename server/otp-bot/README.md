# ChatApp OTP Bot

Ин сервер барои воридшавии ChatApp бо рақами телефон тавассути Telegram истифода мешавад. Он инчунин endpoint-ҳои серверии тарҷума ва табдили овоз ба матнро таъмин мекунад. Калидҳои махфӣ бояд танҳо дар Environment-и хостинг бошанд.

## Deploy дар Render

1. Дар Telegram ба [@BotFather](https://t.me/BotFather) нависед, `/newbot`-ро иҷро кунед ва токени ботро нигоҳ доред.
2. Дар Firebase Console → Project Settings → Service accounts ба [Firebase service accounts](https://console.firebase.google.com/project/chatapp-57fb2/settings/serviceaccounts/adminsdk) равед ва private key-и JSON-ро гиред.
3. Дар [Render Dashboard](https://dashboard.render.com/) интихоб кунед: **New → Web Service** ва репозитории `Raonsonapp/ChatAppMessenger-`-ро пайваст кунед.
4. Дар танзимоти service:
   - **Runtime:** Docker
   - **Dockerfile Path:** `server/otp-bot/Dockerfile`
   - **Branch:** `main`
   - Агар Render Root Directory талаб кунад, онро ба `server/otp-bot` гузоред ва боварӣ ҳосил кунед, ки Dockerfile path ба ҳамин ҷой мувофиқ аст.
5. Дар **Environment** тағйирёбандаҳои зеринро илова кунед:
   - `TELEGRAM_BOT_TOKEN` — токени аз BotFather гирифташуда
   - `FIREBASE_SERVICE_ACCOUNT_JSON` — тамоми матни JSON-и private key
   - `GEMINI_API_KEY` — барои `/api/ai/chat`, `/api/transcribe` ва тарҷумаи серверӣ
   - `GEMINI_CHAT_MODEL` — ихтиёрӣ; пешфарз `gemini-2.5-flash`
   - `GEMINI_API_KEY` — инчунин барои тавлиди расм аз Gemini истифода мешавад
   - `XAI_API_KEY` — барои тавлиди расм ва видео аз Grok истифода мешавад
   - `GEMINI_IMAGE_MODEL` — ихтиёрӣ; пешфарз `gemini-2.5-flash-image`
   - `XAI_IMAGE_MODEL` — ихтиёрӣ; пешфарз `grok-imagine-image`
   - `XAI_VIDEO_MODEL` — ихтиёрӣ; пешфарз `grok-imagine-video-1.5`
   - `MEDIA_GENERATION_QUOTA_PER_HOUR` — лимити иловагии ChatApp барои ҳар корбар; аз 1 то 5, пешфарз 5
   - `IMAGE_GENERATION_ENDPOINT`, `VIDEO_GENERATION_ENDPOINT`, `MUSIC_GENERATION_ENDPOINT` ва калидҳои мувофиқ дигар барои image/video-и native-и Gemini/Grok лозим нестанд; мусиқӣ ҳанӯз провайдери алоҳида мехоҳад
   - `GEMINI_TRANSCRIBE_MODEL` — ихтиёрӣ; пешфарз `gemini-2.5-flash`
   - `GEMINI_TRANSLATE_MODEL` — ихтиёрӣ; барои тарҷума низ пешфарз `gemini-2.5-flash`
   - `TRANSLATE_ENDPOINT` ва `TRANSLATE_API_KEY` — танҳо агар тарҷумони алтернативии сервериро истифода баред
   - `AGORA_APP_ID` ва `AGORA_APP_CERTIFICATE` — агар зангҳои Agora фаъол бошанд
   - `OWNER_UID` — UID-и соҳиби барнома барои функсияҳои Plus; тафсилот дар `PLUS_SETUP.md`
   - тағйирёбандаҳои `R2_*` — агар боркунии media тавассути Cloudflare R2 истифода шавад
6. `Save, rebuild, and deploy`-ро интихоб кунед. Дар Render бояд public URL-и service пайдо шавад. Сервер бояд ба `process.env.PORT` ва host-и `0.0.0.0` гӯш кунад.
7. Дар `lib/config/otp_server_config.dart` қимати `baseUrl`-ро ба URL-и воқеии Render service гузоред ва `telegramBotUsername`-ро ба username-и воқеии бот иваз кунед.

## ChatAI

- `/api/ai/chat` ба Gemini тавассути `GEMINI_API_KEY` пайваст мешавад; ин endpoint бояд дар Render deploy шуда бошад.
- `/api/ai/generate/image` тавлиди native-и Gemini ё Grok-ро дастгирӣ мекунад; `provider`-ро ҳамчун `gemini` ё `grok` фиристед.
- `/api/ai/generate/video` ҳоло тавлиди native-и Grok Imagine Video-ро дастгирӣ мекунад; дархост то 15 сония маҳдуд аст.
- `/api/ai/generate/music` ҳанӯз тавлиди мусиқиро таъмин намекунад. Видеоҳои Grok метавонанд аудио дошта бошанд, аммо ин ба тавлиди мустақили мусиқӣ баробар нест.
- Лимити ChatApp (пешфарз 5 дархост дар як соат барои ҳар корбар) танҳо муҳофизати иловагӣ аст; лимити воқеии Gemini/xAI метавонад камтар бошад ва API метавонад пулакӣ бошад. Квотаи ройгони кафолатноки умумӣ вуҷуд надорад.
- Тавлиди видео вақти бештар мегирад; URL-и видео аз провайдер бармегардад ва давомнокии ниҳоӣ ба маҳдудиятҳои модели Grok вобаста аст.

## Амният

- Калидҳои API, Telegram token ва Firebase service-account JSON-ро ҳеҷ гоҳ ба GitHub, APK ё паёмҳои чат нагузоред.
- Агар калид тасодуфан дар репозитории ҷамъиятӣ нашр шавад, онро revoke/rotate кунед.
- Овози корбар ҳангоми истифодаи транскрипсияи Gemini ба Google фиристода мешавад; барнома пеш аз фиристодан бояд розигии корбарро гирад.

## Санҷиши маҳаллӣ

```bash
cd server/otp-bot
cp .env.example .env
npm install
npm start
```

Дар муҳити маҳаллӣ `.env`-ро пур кунед. Файли `.env`-ро ба GitHub commit накунед.

## Маҳдудият

Рамзҳои якдафъаина ҳоло дар хотираи процесс нигоҳ дошта мешаванд; баъди restart онҳо гум мешаванд. Барои истеҳсолот ва миқёси калон, нигоҳдории муваққатиро ба Redis ё Firestore кӯчонидан лозим аст.
