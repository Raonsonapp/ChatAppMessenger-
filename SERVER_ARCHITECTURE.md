# ChatApp — тақсимоти серверҳо ва нақшаи хостинг

Ин ҳуҷҷат нақша аст; илова кардани он ягон сервер ё ҳисобро худкор намесозад ва secret-ҳоро интиқол намедиҳад.

## Қоидаи асосӣ

- Қисмҳои маҳаллӣ дар телефон мемонанд, то камтар ба шабака муроҷиат кунанд.
- Render ҳамчун сервери асосӣ боқӣ мемонад; ҳоло барои хидматҳои асосӣ сервери нав илова накунед, то endpoint-ҳо байни хостингҳо тақсим ва шикаста нашаванд.
- Функсияҳои сервериро танҳо баъди муайян кардани кори онҳо ва санҷиши тайёрӣ ба хидматҳои ҷудогона мекӯчонем.
- Ҳеҷ API key, Telegram bot token ё Firebase service-account JSON дар репозиторий ё APK нигоҳ дошта намешавад.

## Тақсимоти пешниҳодшуда

| Қисм | Ҷой | Сабаб / ёддошт |
|---|---|---|
| UI, аниматсияҳо, мавзӯъҳои 2D/3D, танзимоти маҳаллӣ | Телефони корбар | Ҳоҷат ба сервер нест |
| Плеери паёми овозӣ ва waveform, нигоҳдории кэши тарҷума | Телефони корбар | Барои кам кардани талабот ба сервер |
| Тарҷумаи offline-и забонҳои дастгиришуда | Google ML Kit дар телефон | Моделҳои лозима дар дастгоҳ бор карда мешаванд |
| Firebase Authentication, Firestore, FCM, Storage | Firebase | Хизматҳои идорашавандаи дода/паём; маҳдудиятҳо аз нақша ва квота вобастаанд |
| OTP бо Telegram ва endpoint-ҳои асосии backend-и ҳозира | Render (ҳоло) | Хидмати асосии Express бо secret-ҳо |
| Gemini transcription ва тарҷумаи серверӣ | Ҳоло Render; баъд метавонад ҷудо шавад | Калиди Gemini бояд танҳо дар environment-и сервер бошад |
| Зангҳои овозӣ/видеоӣ | Agora (агар фаъол бошад) | Медиа-стримро аз Express backend ҷудо нигоҳ доштан мумкин аст |
| Боркунии медиа, агар Cloudflare R2 истифода шавад | Cloudflare R2 | Объектҳоро дар сервери API нигоҳ надорем |
| API-и хурди оммавӣ ё webhook-и камҳаҷм (дар оянда) | Cloudflare Workers Free, танҳо баъди мувофиқ кардани код | Барои endpoint-ҳои кӯтоҳ; Node/Express-и ҳозираро бе порт кардан мустақим гузаронидан мумкин нест |
| Базаи иловагии Postgres (танҳо агар дар оянда воқеан лозим шавад) | Supabase Free | Дар бетаъхирӣ лоиҳаи иловагӣ накушоед; free project метавонад дар ғайрифаъолӣ pause шавад |

## Хостингҳои ройгон/озмоишӣ барои арзёбӣ

1. **Render Free** — барои web service-и ҳозира мувофиқ, вале пас аз 15 дақиқа бе ҳаракат хоб меравад ва дархости аввал метавонад тақрибан як дақиқа дер шавад.
2. **Koyeb Free Instance** — барои demo; 512 MB RAM ва 0.1 vCPU, ба сифр кам мешавад баъди 1 соат бе трафик. Барои production-и боэътимод мувофиқ нест.
3. **Cloudflare Workers Free** — барои API-и хурд/edge ва webhook; лимитҳои CPU/runtime доранд ва Express-и мавҷударо бояд алоҳида порт кард.
4. **Supabase Free** — базаи Postgres ва API барои маълумоти сохторӣ; лоиҳаи ғайрифаъол метавонад пас аз як ҳафта pause шавад.
5. **Firebase Spark** — барои маҳсулоти Firebase-и дохили квота, вале Cloud Functions ба Blaze вобаста аст; пеш аз фаъол кардан хароҷот/ҳисобро санҷед.
6. **Vercel Hobby Functions** — барои endpoint-ҳои мувофиқ, на ҳамчун нусхаи мустақими сервери доимии Express; лимитҳо дорад.

Ройгон будан маънои бе маҳдудият ё бе таъхир буданро надорад. Серверҳои бисёри free-tier метавонанд cold start, sleep ё quota дошта бошанд; тақсим кардан ба серверҳои зиёд худ аз худ серверро тез намекунад.

## Тартиби кӯчонидан

1. Render-ро нигоҳ дошта, аввал health endpoint, login/OTP, translate, transcribe ва upload-ро алоҳида санҷед.
2. Variable-ҳои зеринро аз dashboard-и Render ба password manager нигоҳ доред ва ба service-и нав дастӣ гузаронед: `TELEGRAM_BOT_TOKEN`, `FIREBASE_SERVICE_ACCOUNT_JSON`, `GEMINI_API_KEY`, калидҳои Agora ва R2, `OWNER_UID`, `TRANSLATE_*`.
3. Дар хостинги нав deploy кунед ва health check, auth, quotas ва logs-ро санҷед.
4. Танҳо баъди санҷиши муваффақ URL-и endpoint-и дахлдорро иваз кунед.
5. Render-ро то тасдиқи пурраи кор қатъ накунед.

## Қоидаи амният

Secret-ҳоро дар ин файл ё дигар файлҳои GitHub нагузоред. `.env` бояд дар `.gitignore` бошад. Агар secret пештар дар GitHub нашр шуда бошад, онро rotate/revoke кунед. Ҳамеша ҳаққи дастрасиро аз Firebase Auth ID token санҷед ва барои endpoint-ҳои AI quota гузоред.


## Инвентаризатсияи функсияҳо ва тарҳи камхарҷ (2026-10-17)

### Функсияҳое, ки аз коди дастрас тасдиқ шуданд

- Flutter UI: рӯйхати чатҳо, ҷустуҷӯ, статусҳо, ҷамоаҳо, зангҳо, бозор ва экранҳои танзимот дар сохтори `lib/` мавҷуданд. Мавҷуд будани файл кафолати он нест, ки ҳар тугма пурра кор мекунад — барои ин санҷиши функсионалӣ лозим аст.
- Паёмнависӣ ва додаҳои асосӣ: вобастагиҳои `firebase_auth`, `cloud_firestore`, `firebase_messaging` мавҷуданд; `firestore.rules` қоидаҳои дастрасӣ дорад.
- Тарҷума: `TranslateService` аввал тарҷумаи маҳаллии Google ML Kit-ро истифода мебарад барои забонҳои дастгиришаванда; барои забонҳо/хатогиҳои муайян ба `/api/translate` меравад.
- Транскрипсияи овоз: Flutter `VoiceTranscriptionService` ба `/api/transcribe` муроҷиат мекунад, аммо санҷиши `server/otp-bot/index.js` нишон дод, ки endpoint-и `/api/transcribe` дар он файл ҳоло мавҷуд нест. Ин defect аст ва бояд пеш аз эълони тайёрӣ ислоҳ шавад.
- AI Assistant-и умумӣ: дар роҳҳои маъмули `lib/screens/ai_assistant_screen.dart`, `lib/screens/ai_chat_screen.dart` ва `lib/services/ai_service.dart` файл ёфт нашуд. Ин далел танҳо маънои онро дорад, ки он бо ҳамин номҳо нест; бояд route/menu ва тамоми дарахти `lib/` пурратар ҷустуҷӯ шаванд.
- Render: сервис дар ҳисоб Live нишон дода шуд ва логҳо оғоз шудани Node.js, webhook-и Telegram ва санҷиши R2-ро нишон доданд. Ин танҳо маънои фаъол будани процессро дорад, на он ки ҳамаи endpoint-ҳо аз тарафи барнома санҷида шудаанд.

### Тарҳи беҳтарини базаҳо (маълумотро бе сабаб тақсим накун)

1. **Firebase Auth — як манбаи аслии identity.** Ҳисобҳо/UID-ҳоро ба базаи дигар нусхабардорӣ накун. Агар воридшавии Telegram OTP дар backend Firebase custom token созад, ҳамаи хизматҳо бояд ҳамон UID-ро қабул кунанд.
2. **Cloud Firestore — манбаи аслии чат ва маълумоти барнома.** Профилҳо, чатҳо, паёмҳо, гурӯҳҳо, статусҳо, ҷомеаҳо, танзимоти синхронӣ ва marketplace-ро дар ҳамин система нигоҳ дор, агар моделҳои ҳозира ҳаминро истифода баранд. Барои ҳар entity як манбаи аслӣ ва қоидаҳои security rules муайян карда шавад; маълумоти калон/медиа ба документи чат насупоред.
3. **Cloudflare R2 — танҳо объектҳо/файлҳои калон** (акс, видео, овоз), агар интегратсияи мавҷуда пурра тасдиқ шавад. Дар Firestore танҳо metadata ва URL/key-ро нигоҳ дор. Аз ду bucket-и монанд бидуни талабот истифода накун.
4. **Redis/KV — баъдтар, танҳо барои ҳолати кӯтоҳмуддат ё кэш** (rate limit, OTP-и интизор, cache). OTP-и ҳозира дар `Map`-и RAM нигоҳ дошта мешавад; ин барои як instance метавонад кор кунад, вале restart ҳамаи OTP-ҳои интизорро пок мекунад ва байни instance-ҳо ҳамоҳанг нест. Барои ислоҳ аввал Firestore TTL ё як KV/Redis-и арзони идорашаванда муқоиса шавад.
5. **Supabase/Postgres — ҳоло илова накун.** Вақте ки далели воқеӣ барои query-и relational/reporting лозим шавад, базаи алоҳида соз; вагарна duplicated source-of-truth, sync jobs, security policies ва хароҷоти иловагӣ пайдо мешаванд. Free project метавонад дар набудани фаъолияти кофӣ pause шавад.
6. **Firebase Storage — танҳо агар бо R2 иваз нашавад.** Ҳамзамон нигоҳ доштани ҳамон файлҳо дар Firebase Storage ва R2 арзиш ва мураккабиро зиёд мекунад. Аввал дақиқ кардан лозим, ки кадом service файлҳоро воқеан қабул мекунад.

### Тақсимоти сервер/хизматҳо дар марҳилаҳо

**Марҳилаи 0 — Audit (ҳоло):** маршрутҳо, services, Firestore collections/rules, Storage/R2 ва ҳар тугмаи нопурраро рӯйхат кун. Render-ро дигар накун.

**Марҳилаи 1 — Feature fixes:** аввал login/OTP, chat read/write, attachment, push notification, marketplace/status/community, calls, translation ва AI-ро ҳар кадом бо санҷиши алоҳида мустаҳкам кун. Transcription endpoint-и гумшударо ислоҳ кун. Барои AI экран ва service соз/пайваст кун, аммо API key-ро ба Flutter нагузор.

**Марҳилаи 2 — Backend service boundaries:**
- Render API A: Telegram OTP ва Firebase custom-token login (то иваз шудани нақшаи identity).
- Render API B (метавонад дертар ҷудо шавад): link preview, moderation/admin/Plus ва endpoint-ҳои махсуси серверӣ. Ҷудо кардан танҳо вақте, ки ҳар қисм config, health check, auth verification, rate limit ва logs-и мустақил дорад.
- Google Gemini API: аввал аз backend бо server-side key; танҳо баъди чен кардани истифода, latency ва хароҷот ҷудо карданашро фикр кун. Тарҷумаи ML Kit дар телефон мемонад.
- R2 ва Agora — хидматҳои берунаи махсус, на серверҳои Express-и иловагӣ.
- Cloudflare Workers — танҳо endpoint-и хурд, ки ба муҳити Workers порт карда шудааст; сервери Node.js-и ҳозираро бевосита он ҷо гузоштан мумкин нест.

**Марҳилаи 3 — Scale:** дар асоси метрикаҳо (latency, error rate, request count, Firestore reads/writes, storage egress, AI tokens) қарор гир. Аввал индексҳо, pagination, кэш, image/audio compression ва limiting; баъд server splitting. Нусхаҳои Firestore як база намесозанд ва зиёд кардани шумораи хостингҳо сабаби худкори тезшавӣ нест.

### Қоидаҳои меъморӣ

- Як entity — як database of record. Нусхаи кэш бояд равшан ҳамчун кэш муайян шавад ва rebuild кардан мумкин бошад.
- Ҳар API server-side Firebase ID token-ро тасдиқ кунад; танҳо доштани header кофӣ нест.
- Gemini/R2/Agora/Firebase Admin credentials танҳо дар Environment/secret manager бошанд.
- Ҳар endpoint бояд health-check ва интегратсионӣ-тест дошта бошад; deployment-и «Live» танҳо санҷиши оғозёбии процесс аст.
- Бе назорати хароҷот AI-и генеративиро барои ҳар refresh/keypress даъват накун: caching, quota per UID, max input/output ва таймаут лозим аст.
