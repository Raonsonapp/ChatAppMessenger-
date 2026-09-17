# Санҷиши қоидаҳои Firestore

`firestore.rules` пеш аз фиристодан ба лоиҳаи воқеӣ дар эмулятор санҷида
мешавад. Сабаб содда аст: қоидаи нодуруст на танҳо бегонаро манъ мекунад,
балки метавонад хомӯшона дархости худи барномаро бишканад. Масалан, версияи
аввали қоидаҳо ба бинанда иҷозат намедод, ки худашро ба `viewedBy` илова
кунад — яъне «кӣ навсозиро дид» тамоман кор намекард. Ин санҷиш маҳз ҳамон
хатогиро ёфт.

## Иҷро

```bash
mkdir rulestest && cd rulestest
npm init -y
npm install firebase-tools @firebase/rules-unit-testing firebase
cp ../firestore.rules .
cat > firebase.json <<'JSON'
{
  "firestore": { "rules": "firestore.rules" },
  "emulators": { "firestore": { "port": 8181 }, "ui": { "enabled": false } }
}
JSON
cp ../test/firestore_rules/rules.test.mjs .
npx firebase emulators:start --only firestore --project demo-chatapp &
FIRESTORE_EMULATOR_HOST=127.0.0.1:8181 node rules.test.mjs
```

Санҷиш ду чизро тафтиш мекунад:

1. **Ҳар дархосте, ки барнома мефиристад, кор мекунад** — аз ҷумла шаклҳои
   дархост (`participants array-contains`, `calleeId ==`), нав кардани
   `unread`, зерколлексияи `starred` ва илова кардан ба `viewedBy`.
2. **Корбари бегона ба чат, профил, гурӯҳ, канал, навсозӣ ва занги дигарон
   дастрасӣ надорад.**
