'use strict';

/**
 * Хэши устувори FNV-1a (64-бит) аз токени FCM.
 *
 * ҲАМОН алгоритми `DeviceService.fingerprint` дар барнома
 * (`lib/services/device_service.dart`). Барнома сабти дастгоҳро бо ҳамин ID
 * менависад, бинобар ин сервер бояд ҳамон ID-ро ҳисоб кунад — вагарна
 * ҳангоми бекор шудани токен сабти дастгоҳ дар рӯйхат мемонад ва корбар
 * дастгоҳе мебинад, ки дигар ҳељ огоҳӣ намегирад.
 *
 * Ду тарафро санҷишҳо якҷоя нигоҳ медоранд: ҳам `device_fingerprint.test.mjs`
 * ва ҳам `test/device_service_test.dart` ҳамон қиматҳои маълумро талаб мекунанд.
 */
const OFFSET_BASIS = 0xcbf29ce484222325n;
const PRIME = 0x100000001b3n;
const MASK = (1n << 64n) - 1n;

function deviceFingerprint(token) {
  let hash = OFFSET_BASIS;
  // `codeUnits`-и Dart — воҳидҳои UTF-16. Токени FCM ҳамеша ASCII аст, вале
  // барои мувофиқати пурра ҳамон тарзи хониш истифода мешавад.
  for (let i = 0; i < token.length; i++) {
    hash = (hash ^ BigInt(token.charCodeAt(i) & 0xff)) & MASK;
    hash = (hash * PRIME) & MASK;
  }
  return hash.toString(16).padStart(16, '0');
}

module.exports = { deviceFingerprint };
