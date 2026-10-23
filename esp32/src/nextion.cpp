#include "nextion.h"
#include "sensors.h"
#include "network.h"
#include "timekeeper.h"

Nextion nextion;

void Nextion::begin() {
    Serial2.begin(NEXTION_BAUD, SERIAL_8N1, NEXTION_RX, NEXTION_TX);
    lastUpdate = 0;
    currentPage = 0;
    for (int i = 0; i < 4; i++) pumpFrames[i] = 0;
    for (int i = 0; i < 3; i++) flowFrames[i] = 0;
    flameFrame = 0;
    resetCache();
    Serial.println("[Nextion] Initialized on Serial2");
}

void Nextion::resetCache() {
    // Сбрасываем только числовые поля (цвета, картинки, чекбоксы)
    // Строковые поля синхронизируются автоматически через sendTextIfChanged
    
    cache.datetime_color = -1;
    cache.pic_pf = -1; cache.pic_pr = -1; cache.pic_pb = -1;
    cache.pic_pe = -1; cache.pic_flame = -1;
    cache.img_b = -1; cache.img_ta = -1;
    cache.img_p1 = -1; cache.img_p2 = -1; cache.img_p3 = -1;
    cache.img_f1 = -1; cache.img_f2 = -1; cache.img_f3 = -1;
    cache.ph_l1 = -1; cache.ph_l2 = -1; cache.ph_l3 = -1;
    cache.ntp_status = -1;
    
    for (int i = 0; i < 4; i++) {
        cache.chk_state[i] = -1;
        cache.bg_color[i] = -1;
    }
    
    // Строки НЕ сбрасываем — sendTextIfChanged сам синхронизирует
    // при следующем update(), сравнивая cached с актуальным значением
}

void Nextion::sendCommand(const char* cmd) {
    Serial2.print(cmd);
    Serial2.write(0xff);
    Serial2.write(0xff);
    Serial2.write(0xff);
}

void Nextion::sendTextIfChanged(String &cached, const char* componentName, const char* newValue) {
    String val = String(newValue);
    if (cached != val) {
        cached = val;
        char cmd[80];
        snprintf(cmd, sizeof(cmd), "%s.txt=\"%s\"", componentName, newValue);
        sendCommand(cmd);
    }
}

void Nextion::sendPicIfChanged(int8_t &cached, const char* componentName, int8_t newPic) {
    if (cached != newPic) {
        cached = newPic;
        char cmd[64];
        snprintf(cmd, sizeof(cmd), "%s.pic=%d", componentName, newPic);
        sendCommand(cmd);
    }
}

void Nextion::sendTempIfChanged(String &cached, const char* componentName, float value, bool valid) {
    char buf[8];
    if (valid) snprintf(buf, sizeof(buf), "%.1f", value);
    else       snprintf(buf, sizeof(buf), "---");
    sendTextIfChanged(cached, componentName, buf);
}

void Nextion::formatDeviceStatus(char* buf, size_t bufSize, const char* prefix, bool state, const ManualOverride& mo) {
    const char* stTxt = state ? "ВКЛ" : "ВЫКЛ";
    if (mo.active) {
        unsigned long now = millis();
        unsigned long remaining = (now < mo.expiresAt) ? (mo.expiresAt - now) / 1000 : 0;
        snprintf(buf, bufSize, "%s:%s РУЧН %lus", prefix, stTxt, (unsigned long)remaining);
    } else {
        snprintf(buf, bufSize, "%s:%s АВТО", prefix, stTxt);
    }
}

// ===== Цвет фона времени в зависимости от возраста синхронизации =====
uint16_t Nextion::getDateTimeColor() {
    float ageHours = timekeeper.getLastSyncAgeHours();
    if (ageHours < 6.0)      return 0x87F0;  // Светло-зелёный
    if (ageHours < 168.0)    return 0xFFE0;  // Светло-жёлтый (7 дней)
    return 0xFCE0;                          // Светло-красный
}

// ===== Обновление времени и даты на экране =====
void Nextion::updateDateTime(const char* componentName, String &cacheRef) {
    String newTime = timekeeper.formatDateTime();
    if (cacheRef != newTime) {
        cacheRef = newTime;
        char cmd[64];
        snprintf(cmd, sizeof(cmd), "%s.txt=\"%s\"", componentName, newTime.c_str());
        sendCommand(cmd);
    }
    uint16_t newColor = getDateTimeColor();
    // Сравниваем только младший байт — этого достаточно для детекции смены цвета
    if (cache.datetime_color != (int8_t)(newColor & 0xFF)) {
        cache.datetime_color = (int8_t)(newColor & 0xFF);
        char cmd[32];
        snprintf(cmd, sizeof(cmd), "%s.bco=%d", componentName, newColor);
        sendCommand(cmd);
    }
}

void Nextion::setPage(uint8_t page) {
    if (page != currentPage) {
        currentPage = page;
        resetCache();
        Serial.printf("[Nextion] Page changed to %d\n", page);
    }
}

void Nextion::update() {
    if (millis() - lastUpdate < NEXTION_UPDATE_INTERVAL) return;
    lastUpdate = millis();

    // // 🛑 ЛОГИРОВАНИЕ: какую страницу обновляем
    // static uint8_t lastLoggedPage = 255;
    // if (currentPage != lastLoggedPage) {
    //     Serial.printf("[Nextion] update() -> page %d\n", currentPage);
    //     lastLoggedPage = currentPage;
    // }


    switch (currentPage) {
        case 0: updateMainScreen();     break;
        case 1: updateSchemaScreen();   break;
        case 2: updateSettingsScreen(); break;
        case 3: updateQuickAccess();    break;
        case 4: updateStatusScreen();   break;
        case 5: updateCalibrationScreen(); break;
        case 6: updateTimeScreen();     break;
        case 7: updateScheduleScreen(); break;
        case 8: updateKeypadScreen(); break;
        default:
            Serial.printf("[Nextion] ERROR: unknown page %d\n", currentPage);
            break;
    }
}

// ===== Page 0: ГЛАВНАЯ =====
void Nextion::updateMainScreen() {
    char buf[32];
    SensorData d = sensors.getData();
    DeviceStates st = control.getStates();

    sendTempIfChanged(cache.txt_rval, "t_rval", d.room,        d.room_valid);
    sendTempIfChanged(cache.txt_fval, "t_fval", d.floor,       d.floor_valid);
    sendTempIfChanged(cache.txt_oval, "t_oval", d.outdoor,     d.outdoor_valid);
    sendTempIfChanged(cache.txt_aval, "t_aval", d.accumulator, d.accumulator_valid);
    sendTempIfChanged(cache.txt_bval, "t_bval", d.boiler,      d.boiler_valid);

    auto updatePump = [&](const char* name, uint8_t idx, bool on, int8_t &cachedPic) {
        int8_t newPic = on ? (pumpFrames[idx] = (pumpFrames[idx] + 1) % 3) : 3;
        sendPicIfChanged(cachedPic, name, newPic);
    };
    updatePump("pic_pf", 0, st.floor_pump, cache.pic_pf);
    updatePump("pic_pr", 1, st.radiator_pump, cache.pic_pr);
    updatePump("pic_pb", 2, st.boiler, cache.pic_pb);
    updatePump("pic_pe", 3, st.elec_boiler, cache.pic_pe);

    int8_t flamePic = st.boiler ? (flameFrame = (flameFrame + 1) % 4) : 4;
    sendPicIfChanged(cache.pic_flame, "pic_flame", flamePic);

    sendTextIfChanged(cache.txt_l1, "t_l1", control.phaseL1 ? "L1 OK" : "L1 ERR");
    sendTextIfChanged(cache.txt_l2, "t_l2", control.phaseL2 ? "L2 OK" : "L2 ERR");
    sendTextIfChanged(cache.txt_l3, "t_l3", control.phaseL3 ? "L3 OK" : "L3 ERR");

    int pumpsOn = st.boiler + st.elec_boiler + st.floor_pump + st.radiator_pump;
    snprintf(buf, sizeof(buf), "%d/4", pumpsOn);
    sendTextIfChanged(cache.txt_pumps, "t_pumps", buf);

    // Состояния устройств с префиксами
    sendTextIfChanged(cache.s_b, "s_b", st.boiler         ? "ТТ:ВКЛ" : "ТТ:ВЫКЛ");
    sendTextIfChanged(cache.s_e, "s_e", st.elec_boiler    ? "ЭК:ВКЛ" : "ЭК:ВЫКЛ");
    sendTextIfChanged(cache.s_f, "s_f", st.floor_pump     ? "ТП:ВКЛ" : "ТП:ВЫКЛ");
    sendTextIfChanged(cache.s_r, "s_r", st.radiator_pump  ? "РД:ВКЛ" : "РД:ВЫКЛ");

    sendTextIfChanged(cache.txt_online, "t_online", network.isConnected() ? "ON" : "OFF");

    // Дата и время с цветовой индикацией NTP
    updateDateTime("t_datetime", cache.datetime_cache);
}

// ===== Page 1: СХЕМА =====
void Nextion::updateSchemaScreen() {
    char statusBuf[48];
    SensorData d = sensors.getData();
    DeviceStates st = control.getStates();

    bool boilerHot = d.boiler_valid      && (d.boiler      > FLOW_HOT_BOILER_MIN);
    bool taHot     = d.accumulator_valid && (d.accumulator > FLOW_HOT_TA_MIN);

    // СЛОЙ 1: большие картинки
    int8_t boilerPic = boilerHot ? 10 : 9;
    int8_t taPic     = st.elec_boiler ? 12 : 11;

    bool bChanged  = (boilerPic != cache.img_b);
    bool taChanged = (taPic     != cache.img_ta);

    sendPicIfChanged(cache.img_b,  "img_b",  boilerPic);
    sendPicIfChanged(cache.img_ta, "img_ta", taPic);

    if (bChanged)  { sendCommand("vis p5,0"); sendCommand("vis p5,1"); cache.t_ta = ""; }
    if (taChanged) { cache.txt_ta = ""; cache.st_e = ""; }

    // СЛОЙ 2: тексты поверх больших картинок
    sendTempIfChanged(cache.t_ta, "t_ta", d.boiler, d.boiler_valid);
    sendTempIfChanged(cache.txt_ta, "txt_ta", d.accumulator, d.accumulator_valid);

    formatDeviceStatus(statusBuf, sizeof(statusBuf), "ЭК", st.elec_boiler, st.elec_boiler_mo);
    sendTextIfChanged(cache.st_e, "st_e", statusBuf);

    sendTempIfChanged(cache.txt_tf, "txt_tf", d.floor, d.floor_valid);

    formatDeviceStatus(statusBuf, sizeof(statusBuf), "Н1", st.boiler, st.boiler_mo);
    sendTextIfChanged(cache.st_p1, "st_p1", statusBuf);

    // СЛОЙ 3: насосы и потоки
    auto updatePump = [&](const char* name, uint8_t idx, bool on, int8_t &cachedPic) {
        int8_t newPic = on ? (pumpFrames[idx] = (pumpFrames[idx] + 1) % 3) : 3;
        sendPicIfChanged(cachedPic, name, newPic);
    };
    updatePump("img_p1", 0, st.boiler,        cache.img_p1);
    updatePump("img_p2", 1, st.floor_pump,    cache.img_p2);
    updatePump("img_p3", 2, st.radiator_pump, cache.img_p3);

    auto updateFlow = [&](const char* name, uint8_t idx, bool vertical, bool hotFlow, int8_t &cachedPic) {
        int8_t newPic;
        if (hotFlow) {
            flowFrames[idx] = (flowFrames[idx] + 1) % 3;
            newPic = (vertical ? 17 : 13) + flowFrames[idx];
        } else {
            newPic = vertical ? 20 : 16;
        }
        sendPicIfChanged(cachedPic, name, newPic);
    };
    updateFlow("img_f1", 0, false, st.boiler && boilerHot,    cache.img_f1);
    updateFlow("img_f2", 1, true,  st.floor_pump && taHot,    cache.img_f2);
    updateFlow("img_f3", 2, true,  st.radiator_pump && taHot, cache.img_f3);

    // СЛОЙ 4: остальные тексты
    sendTempIfChanged(cache.txt_tr, "txt_tr", d.room, d.room_valid);

    formatDeviceStatus(statusBuf, sizeof(statusBuf), "Н2", st.floor_pump, st.floor_pump_mo);
    sendTextIfChanged(cache.st_p2, "st_p2", statusBuf);

    formatDeviceStatus(statusBuf, sizeof(statusBuf), "Н3", st.radiator_pump, st.radiator_pump_mo);
    sendTextIfChanged(cache.st_p3, "st_p3", statusBuf);

    // СЛОЙ 5: индикаторы фаз (21 = зелёный, 22 = красный)
    sendPicIfChanged(cache.ph_l1, "ph_l1", control.phaseL1 ? 21 : 22);
    sendPicIfChanged(cache.ph_l2, "ph_l2", control.phaseL2 ? 21 : 22);
    sendPicIfChanged(cache.ph_l3, "ph_l3", control.phaseL3 ? 21 : 22);

    // СЛОЙ 6: дата и время с цветовой индикацией
    updateDateTime("t_datetime1", cache.datetime1_cache);
}

// ===== Page 2: НАСТРОЙКИ =====
void Nextion::updateSettingsScreen() {
    char buf[32];
    SystemSettings s = control.settings;

    snprintf(buf, sizeof(buf), "%.1f", s.boiler_threshold_on);  sendTextIfChanged(cache.t_vbon, "t_vbon", buf);
    snprintf(buf, sizeof(buf), "%.1f", s.boiler_threshold_off); sendTextIfChanged(cache.t_vbof, "t_vbof", buf);
    snprintf(buf, sizeof(buf), "%.1f", s.floor_threshold_on);   sendTextIfChanged(cache.t_vfon, "t_vfon", buf);
    snprintf(buf, sizeof(buf), "%.1f", s.floor_threshold_off);  sendTextIfChanged(cache.t_vfof, "t_vfof", buf);
    snprintf(buf, sizeof(buf), "%.1f", s.room_target_on);       sendTextIfChanged(cache.t_vron, "t_vron", buf);
    snprintf(buf, sizeof(buf), "%.1f", s.room_target_off);      sendTextIfChanged(cache.t_vrof, "t_vrof", buf);
    snprintf(buf, sizeof(buf), "%.1f", s.TA_target_on);         sendTextIfChanged(cache.t_vaon, "t_vaon", buf);
    snprintf(buf, sizeof(buf), "%.1f", s.TA_target_off);        sendTextIfChanged(cache.t_vaof, "t_vaof", buf);
    snprintf(buf, sizeof(buf), "%d",   s.manual_timeout);       sendTextIfChanged(cache.t_vtm,  "t_vtm",  buf);
}

// ===== Page 5: КАЛИБРОВКА =====
void Nextion::updateCalibrationScreen() {
    char buf[24];
    static const char* vn[5] = { "c_v0", "c_v1", "c_v2", "c_v3", "c_v4" };
    static const char* tn[5] = { "c_t0", "c_t1", "c_t2", "c_t3", "c_t4" };

    snprintf(buf, sizeof(buf), "На шине: %d", sensors.getBusCount());
    sendTextIfChanged(cache.t_cnum, "t_cnum", buf);

    for (int r = 0; r < 5; r++) {
        int8_t idx = sensors.getRoleBusIndex(r);
        if (idx >= 0) snprintf(buf, sizeof(buf), "№%d", idx);
        else          snprintf(buf, sizeof(buf), "---");
        sendTextIfChanged(cache.c_v[r], vn[r], buf);

        if (idx >= 0) {
            float t = sensors.getBusTemp(idx);
            snprintf(buf, sizeof(buf), "%.1f", t);
        } else {
            snprintf(buf, sizeof(buf), "--.-");
        }
        sendTextIfChanged(cache.c_t[r], tn[r], buf);
    }
}

// ===== Page 6: ДАТА И ВРЕМЯ =====
void Nextion::updateTimeScreen() {
    char buf[16];
    DateTime dt = timekeeper.getDateTime();

    sendTextIfChanged(cache.t_date, "t_date", timekeeper.formatDate().c_str());
    sendTextIfChanged(cache.t_time, "t_time", timekeeper.formatTime().c_str());

    snprintf(buf, sizeof(buf), "%04d", dt.year);
    sendTextIfChanged(cache.t_year, "t_year", buf);

    snprintf(buf, sizeof(buf), "%02d", dt.month);
    sendTextIfChanged(cache.t_month, "t_month", buf);

    snprintf(buf, sizeof(buf), "%02d", dt.day);
    sendTextIfChanged(cache.t_day, "t_day", buf);

    snprintf(buf, sizeof(buf), "%02d", dt.hour);
    sendTextIfChanged(cache.t_hour, "t_hour", buf);

    snprintf(buf, sizeof(buf), "%02d", dt.minute);
    sendTextIfChanged(cache.t_minute, "t_minute", buf);

    int8_t newStatus = timekeeper.isSynced() ? 1 : 0;
    if (cache.ntp_status != newStatus) {
        cache.ntp_status = newStatus;
        sendCommand(newStatus ? "t_ntp.txt=\"NTP OK\"" : "t_ntp.txt=\"NTP ---\"");
    }
}

// ===== Page 7: РАСПИСАНИЕ =====

void Nextion::updateScheduleScreen() {
    char buf[64];
    char cmd[64];
    char compName[8];
    
    if (scheduleDevice >= DEVICE_COUNT) return;
    
    DeviceSchedule &sched = control.settings.schedule[scheduleDevice];

    static const char* devNamesASCII[4] = { "TT", "EK", "TP", "RD" };
    sendTextIfChanged(cache.t_cur_dev, "t_cur_dev", devNamesASCII[scheduleDevice]);
    delay(10);

    DateTime now = timekeeper.getDateTime();
    uint16_t currentMinutes = now.hour * 60 + now.minute;

    for (int i = 0; i < 4; i++) {
        TimeSlot &slot = sched.slots[i];

        snprintf(compName, sizeof(compName), "t_s%d", i);
        
        if (slot.startH == 0 && slot.startM == 0 && slot.endH == 0 && slot.endM == 0) {
            snprintf(buf, sizeof(buf), "%d. --:-- - --:--", i + 1);
        } else {
            snprintf(buf, sizeof(buf), "%d. %02d:%02d - %02d:%02d",
                     i + 1, slot.startH, slot.startM, slot.endH, slot.endM);
        }
        sendTextIfChanged(cache.t_s[i], compName, buf);
        delay(10); // Задержка после каждой команды текста

        int8_t newChk = slot.enabled ? 1 : 0;
        if (cache.chk_state[i] != newChk) {
            cache.chk_state[i] = newChk;
            snprintf(cmd, sizeof(cmd), "c%d.val=%d", i, newChk);
            sendCommand(cmd);
            delay(15); // Увеличенная задержка
        }

        uint16_t bgColor;
        if (!slot.enabled) {
            bgColor = 0xC618;
        } else {
            uint16_t startMin = slot.startH * 60 + slot.startM;
            uint16_t endMin   = slot.endH * 60 + slot.endM;
            bool inInterval = (startMin < endMin)
                ? (currentMinutes >= startMin && currentMinutes < endMin)
                : (currentMinutes >= startMin || currentMinutes < endMin);
            bgColor = inInterval ? 0x87F0 : 0xFFFF;
        }
        if (cache.bg_color[i] != (int16_t)bgColor) {
            cache.bg_color[i] = (int16_t)bgColor;
            snprintf(cmd, sizeof(cmd), "t_s%d.bco=%d", i, bgColor);
            sendCommand(cmd);
            delay(15); // Увеличенная задержка
        }
    }
}
// void Nextion::updateScheduleScreen() {
//     char buf[64];
//     char cmd[64];
//     char compName[8];
    
//     if (scheduleDevice >= DEVICE_COUNT) return;
    
//     DeviceSchedule &sched = control.settings.schedule[scheduleDevice];

//     // 🛑 УБРАЛИ кириллицу из devNames!
//     // Теперь отправляем только ASCII-идентификаторы
//     static const char* devNamesASCII[4] = { "TT", "EK", "TP", "RD" };
//     sendTextIfChanged(cache.t_cur_dev, "t_cur_dev", devNamesASCII[scheduleDevice]);

//     DateTime now = timekeeper.getDateTime();
//     uint16_t currentMinutes = now.hour * 60 + now.minute;

//     for (int i = 0; i < 4; i++) {
//         TimeSlot &slot = sched.slots[i];

//         snprintf(compName, sizeof(compName), "t_s%d", i);
        
//         // 🛑 ТОЛЬКО ASCII: цифры, двоеточия, дефисы, пробелы
//         if (slot.startH == 0 && slot.startM == 0 && slot.endH == 0 && slot.endM == 0) {
//             snprintf(buf, sizeof(buf), "%d. --:-- - --:--", i + 1);
//         } else {
//             snprintf(buf, sizeof(buf), "%d. %02d:%02d - %02d:%02d",
//                      i + 1, slot.startH, slot.startM, slot.endH, slot.endM);
//         }
//         sendTextIfChanged(cache.t_s[i], compName, buf);

//         // Checkbox
//         int8_t newChk = slot.enabled ? 1 : 0;
//         if (cache.chk_state[i] != newChk) {
//             cache.chk_state[i] = newChk;
//             snprintf(cmd, sizeof(cmd), "c%d.val=%d", i, newChk);
//             sendCommand(cmd);
//             delay(10);
//         }

//         // Цвет фона
//         uint16_t bgColor;
//         if (!slot.enabled) {
//             bgColor = 0xC618;
//         } else {
//             uint16_t startMin = slot.startH * 60 + slot.startM;
//             uint16_t endMin   = slot.endH * 60 + slot.endM;
//             bool inInterval = (startMin < endMin)
//                 ? (currentMinutes >= startMin && currentMinutes < endMin)
//                 : (currentMinutes >= startMin || currentMinutes < endMin);
//             bgColor = inInterval ? 0x87F0 : 0xFFFF;
//         }
//         if (cache.bg_color[i] != (int16_t)bgColor) {
//             cache.bg_color[i] = (int16_t)bgColor;
//             snprintf(cmd, sizeof(cmd), "t_s%d.bco=%d", i, bgColor);
//             sendCommand(cmd);
//             delay(10);
//         }
//     }
// }

// ===== Page 8: КЛАВИАТУРА =====
// СТАЛО (хорошо - только при изменении):
void Nextion::updateKeypadScreen() {
    // Ничего не отправляем в цикле.
    // Данные отправляются только в handleKeypadInput() при нажатии клавиш
    // и в showKeypad() при открытии клавиатуры.
    // Пустая функция, чтобы не спамить.
}
// void Nextion::updateKeypadScreen() {
//     // Эта функция вызывается автоматически при обновлении Page 8.
//     // Принудительная отправка уже делается в handleKeypadInput(),
//     // поэтому здесь только страховка на случай, если страница открылась сама.
//     char cmd[80];
//     snprintf(cmd, sizeof(cmd), "t_input.txt=\"%s\"", cache.keypad_input.c_str());
//     sendCommand(cmd);
//     snprintf(cmd, sizeof(cmd), "t_template.txt=\"%s\"", cache.keypad_template.c_str());
//     sendCommand(cmd);
// }

// ===== Открытие клавиатуры =====
void Nextion::showKeypad(uint8_t device, uint8_t slot, const char* tmpl) {
    keypad.targetDevice = device;
    keypad.targetSlot = slot;
    keypad.templateText = String(tmpl);

    // Читаем текущее время из настроек
    TimeSlot &s = control.settings.schedule[device].slots[slot];
    char timeBuf[32];
    if (s.startH == 0 && s.startM == 0 && s.endH == 0 && s.endM == 0) {
        // Интервал пустой — открываем пустое поле
        cache.keypad_input = "";
    } else {
        // Формируем строку "ЧЧ:ММ-ЧЧ:ММ"
        snprintf(timeBuf, sizeof(timeBuf), "%02d:%02d-%02d:%02d",
                 s.startH, s.startM, s.endH, s.endM);
        cache.keypad_input = String(timeBuf);
    }
    cache.keypad_template = String(tmpl);

    // Переключаем страницу
    sendCommand("page 8");
    currentPage = 8;

    // Принудительно отправляем шаблон и поле ввода
    char cmd[80];
    snprintf(cmd, sizeof(cmd), "t_template.txt=\"%s\"", tmpl);
    sendCommand(cmd);
    snprintf(cmd, sizeof(cmd), "t_input.txt=\"%s\"", cache.keypad_input.c_str());
    sendCommand(cmd);

    Serial.printf("[Nextion] Keypad opened: device=%d slot=%d input='%s' template='%s'\n",
                  device, slot, cache.keypad_input.c_str(), tmpl);
}

// ===== Обработка нажатий клавиатуры =====
void Nextion::handleKeypadInput(const String &key) {
    // Отладка: показываем, что пришло
    Serial.printf("[Nextion] Keypad key received: '%s'\n", key.c_str());
    
    if (!key.startsWith("key_")) {
        Serial.printf("[Nextion] Invalid keypad key: '%s'\n", key.c_str());
        return;
    }
    
    String action = key.substring(4);
    Serial.printf("[Nextion] Keypad action: '%s'\n", action.c_str());
    
    bool changed = false;

    if (action.length() == 1 && isDigit(action.charAt(0))) {
        // Цифра 0-9
        if (cache.keypad_input.length() < 11) {
            cache.keypad_input += action;
            changed = true;
            Serial.printf("[Nextion] Added digit: '%s'\n", action.c_str());
        }
    }
    else if (action == "dash") {
        if (cache.keypad_input.length() < 11) { 
            cache.keypad_input += "-"; 
            changed = true;
            Serial.println("[Nextion] Added dash");
        }
    }
    else if (action == "space") {
        if (cache.keypad_input.length() < 11) { 
            cache.keypad_input += " "; 
            changed = true;
            Serial.println("[Nextion] Added space");
        }
    }
    else if (action == "colon") {
        if (cache.keypad_input.length() < 11) { 
            cache.keypad_input += ":"; 
            changed = true;
            Serial.println("[Nextion] Added colon");
        }
    }
    else if (action == "back") {
        // Backspace — удаляем последний символ
        if (cache.keypad_input.length() > 0) {
            cache.keypad_input.remove(cache.keypad_input.length() - 1);
            changed = true;
            Serial.printf("[Nextion] Backspace! Input now: '%s'\n", cache.keypad_input.c_str());
        } else {
            Serial.println("[Nextion] Backspace on empty input");
        }
    }
    else if (action == "clear") {
        Serial.println("[Nextion] Clear pressed!");
        control.clearSlot(keypad.targetDevice, keypad.targetSlot);
        // Очищаем поле ввода, но НЕ выходим из клавиатуры
        cache.keypad_input = "";
        sendCommand("t_input.txt=\"\"");
        return;
    }
    else if (action == "ok") {
        char work[16];
        strncpy(work, cache.keypad_input.c_str(), sizeof(work) - 1);
        work[sizeof(work) - 1] = '\0';
        
        uint8_t sH, sM, eH, eM;
        int parsed = sscanf(work, "%hhu:%hhu-%hhu:%hhu", &sH, &sM, &eH, &eM);
        
        if (parsed == 4 && sH < 24 && sM < 60 && eH < 24 && eM < 60) {
            control.setSlotTime(keypad.targetDevice, keypad.targetSlot, sH, sM, eH, eM);
            Serial.printf("[Nextion] Saved: %02d:%02d-%02d:%02d\n", sH, sM, eH, eM);
        } else {
            Serial.printf("[Nextion] Bad input: '%s'\n", work);
        }
        
        sendCommand("page 7");
        currentPage = 7;
        delay(200);        // 200 мс достаточно (было 300-500)
        resetCache();
        Serial.println("[Nextion] Keypad OK");
        return;
    }
//     else if (action == "ok") {
//         Serial.printf("[Nextion] OK START, stack free: %u\n", 
//                       uxTaskGetStackHighWaterMark(NULL));
        
//         // парсинг (char-based)...
//         char work[16];
//         strncpy(work, cache.keypad_input.c_str(), sizeof(work) - 1);
//         work[sizeof(work) - 1] = '\0';
        
//         uint8_t sH, sM, eH, eM;
//         int parsed = sscanf(work, "%hhu:%hhu-%hhu:%hhu", &sH, &sM, &eH, &eM);
        
//         if (parsed == 4 && sH < 24 && sM < 60 && eH < 24 && eM < 60) {
//             control.setSlotTime(keypad.targetDevice, keypad.targetSlot, sH, sM, eH, eM);
//             Serial.printf("[Nextion] Saved: %02d:%02d-%02d:%02d\n", sH, sM, eH, eM);
//         }
        
//         Serial.printf("[Nextion] BEFORE resetCache, stack free: %u\n", 
//                       uxTaskGetStackHighWaterMark(NULL));
        
//         sendCommand("page 7");
//         currentPage = 7;
//         delay(300);
//         //resetCache();   // 🛑 ВОТ ЗДЕСЬ стек проседает на 4-6 КБ!
        
//         Serial.printf("[Nextion] AFTER resetCache, stack free: %u\n", 
//                       uxTaskGetStackHighWaterMark(NULL));
        
//         Serial.println("[Nextion] OK: DONE");
//         return;
//     }

            else if (action == "cancel") {
                sendCommand("page 7");
                currentPage = 7;
                delay(200);
                resetCache();
                Serial.println("[Nextion] Keypad cancelled");
                return;
            }
//     else if (action == "cancel") {
//         Serial.println("[Nextion] Cancel pressed!");
        
//         sendCommand("page 7"); 
//         Serial2.flush(); // 🛑 Ждем отправки
//         currentPage = 7;
        
//         delay(300); // 🛑 Увеличили до 300 мс
        
//         resetCache();
//         return;
//     }
//     else {
//         Serial.printf("[Nextion] Unknown keypad action: '%s'\n", action.c_str());
//         return;
//     }

    // Обновляем поле ввода на экране
    if (changed) {
        char cmd[64];
        snprintf(cmd, sizeof(cmd), "t_input.txt=\"%s\"", cache.keypad_input.c_str());
        sendCommand(cmd);
        Serial.printf("[Nextion] Sent to Nextion: '%s'\n", cache.keypad_input.c_str());
    }
}

// ===== Page 3: БЫСТРЫЙ ДОСТУП =====
void Nextion::updateQuickAccess() {
    char statusBuf[32];
    char timerBuf[16];
    DeviceStates st = control.getStates();

    auto updateDevice = [&](String &stCache, String &tmCache,
                            const char* stName, const char* tmName,
                            uint8_t deviceId, bool state) {
        const char* stTxt = state ? "ВКЛ" : "ВЫКЛ";
        if (control.isManualActive(deviceId)) {
            snprintf(statusBuf, sizeof(statusBuf), "%s РУЧН", stTxt);
            snprintf(timerBuf, sizeof(timerBuf), "%lus", (unsigned long)control.getManualRemaining(deviceId));
        } else {
            snprintf(statusBuf, sizeof(statusBuf), "%s АВТО", stTxt);
            snprintf(timerBuf, sizeof(timerBuf), "--");
        }
        sendTextIfChanged(stCache, stName, statusBuf);
        sendTextIfChanged(tmCache, tmName, timerBuf);
    };

    updateDevice(cache.t_st_b, cache.t_tm_b, "t_st_b", "t_tm_b", DEV_BOILER,        st.boiler);
    updateDevice(cache.t_st_e, cache.t_tm_e, "t_st_e", "t_tm_e", DEV_ELEC_BOILER,   st.elec_boiler);
    updateDevice(cache.t_st_f, cache.t_tm_f, "t_st_f", "t_tm_f", DEV_FLOOR_PUMP,    st.floor_pump);
    updateDevice(cache.t_st_r, cache.t_tm_r, "t_st_r", "t_tm_r", DEV_RADIATOR_PUMP, st.radiator_pump);
}

// ===== Page 4: СТАТУС (TODO) =====
void Nextion::updateStatusScreen() {
    // TODO
}

bool Nextion::hasCommand() {
    return Serial2.available() > 0 || rxBuffer.length() > 0;
}
// Извлекает ОДНУ команду из буфера, оставляя остаток
String Nextion::extractCommand(String &buf) {
    if (buf.length() == 0) return "";
    
    // Массив всех известных команд с фиксированной длиной
    static const char* commands[] = {
        "pg0", "pg1", "pg2", "pg3", "pg4", "pg5", "pg6", "pg7", "pg8",
        "key_ok", "key_cancel", "key_clear", "key_colon", "key_dash",
        "key_back", "key_space",
        "key_0", "key_1", "key_2", "key_3", "key_4",
        "key_5", "key_6", "key_7", "key_8", "key_9",
        "sch_dev_0", "sch_dev_1", "sch_dev_2", "sch_dev_3",
        "sch_chk_0", "sch_chk_1", "sch_chk_2", "sch_chk_3",
        "sch_edit_0", "sch_edit_1", "sch_edit_2", "sch_edit_3",
        "sch_save",
        "manual_boiler_on", "manual_boiler_off",
        "manual_elec_on", "manual_elec_off",
        "manual_floor_on", "manual_floor_off",
        "manual_room_on", "manual_room_off",
        "manual_radiator_on", "manual_radiator_off",
        "manual_rad_on", "manual_rad_off",
        "emergency_stop",
        "cal_scan", "cal_save", "calibrate",
        "save_set",
        "inc_bon", "inc_bof", "inc_fon", "inc_fof",
        "inc_ron", "inc_rof", "inc_aon", "inc_aof", "inc_tm",
        "dec_bon", "dec_bof", "dec_fon", "dec_fof",
        "dec_ron", "dec_rof", "dec_aon", "dec_aof", "dec_tm",
        "time_min_inc", "time_min_dec",
        "time_hour_inc", "time_hour_dec",
        "time_day_inc", "time_day_dec",
        "time_mon_inc", "time_mon_dec",
        "time_year_inc", "time_year_dec",
        "time_sync_ntp", "time_save",
        NULL
    };
    
    // Сначала ищем точное совпадение с известной командой
    for (int i = 0; commands[i] != NULL; i++) {
        int len = strlen(commands[i]);
        if (buf.startsWith(commands[i])) {
            String cmd = buf.substring(0, len);
            buf = buf.substring(len);  // Остаток остаётся в буфере
            return cmd;
        }
    }
    
    // Команды с переменной длиной: cal_inc_N, cal_dec_N
    if (buf.startsWith("cal_inc_") || buf.startsWith("cal_dec_")) {
        int end = 8;  // "cal_inc_" = 8 символов
        while (end < buf.length() && isDigit(buf[end])) end++;
        String cmd = buf.substring(0, end);
        buf = buf.substring(end);
        return cmd;
    }
    
    // assign N M
    if (buf.startsWith("assign ")) {
        int end = 7;
        while (end < buf.length() && (isDigit(buf[end]) || buf[end] == ' ')) end++;
        String cmd = buf.substring(0, end);
        buf = buf.substring(end);
        return cmd;
    }
    
    // Неизвестная команда — берём до 20 символов
    int end = min(20, (int)buf.length());
    String cmd = buf.substring(0, end);
    buf = buf.substring(end);
    return cmd;
}

String Nextion::getCommand() {
    while (Serial2.available()) {
        char c = Serial2.read();
        
        if (c == '\n' || c == '\r') {
            if (rxBuffer.length() > 0) {
                String cmd = rxBuffer;
                rxBuffer = "";
                return cmd;
            }
            continue;
        }
        
        if ((uint8_t)c == 0xFF) continue;
        
        if (c >= 32 && c <= 126) {
            rxBuffer += c;
        }
    }
    
    if (rxBuffer.length() > 0) {
        return extractCommand(rxBuffer);
    }
    
    return "";
}