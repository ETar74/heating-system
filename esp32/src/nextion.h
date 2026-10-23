#ifndef NEXTION_H
#define NEXTION_H

#include <Arduino.h>
#include "config.h"
#include "control.h" // Для ManualOverride и других типов

// Структура для кэширования значений дисплея (чтобы не отправлять одно и то же)
struct NextionCache {
    String txt_rval, txt_fval, txt_oval, txt_aval, txt_bval;
    String txt_l1, txt_l2, txt_l3, txt_pumps, txt_online;
    String s_b, s_e, s_f, s_r;
    
    // 🆕 ДОБАВЛЕНО: переменные, используемые в updateSchemaScreen()
    String st_e, st_p1, st_p2, st_p3; 
    
    String datetime_cache, datetime1_cache;
    String t_ta, txt_ta, txt_tf, txt_tr;
    String t_vbon, t_vbof, t_vfon, t_vfof, t_vron, t_vrof, t_vaon, t_vaof, t_vtm;
    String t_cnum, c_v[5], c_t[5];
    String t_date, t_time, t_year, t_month, t_day, t_hour, t_minute;
    String t_cur_dev, t_sch_en, t_s[4];
    String keypad_input, keypad_template;
    String t_st_b, t_st_e, t_st_f, t_st_r, t_tm_b, t_tm_e, t_tm_f, t_tm_r;
    
    int8_t datetime_color = -1;
    int8_t pic_pf = -1, pic_pr = -1, pic_pb = -1, pic_pe = -1, pic_flame = -1;
    int8_t img_b = -1, img_ta = -1;
    int8_t img_p1 = -1, img_p2 = -1, img_p3 = -1;
    int8_t img_f1 = -1, img_f2 = -1, img_f3 = -1;
    int8_t ph_l1 = -1, ph_l2 = -1, ph_l3 = -1;
    int8_t ntp_status = -1;
    int8_t chk_state[4];
    int16_t bg_color[4];

    NextionCache() {
        for(int i = 0; i < 4; i++) { 
            chk_state[i] = -1; 
            bg_color[i] = -1; 
        }
    }
};

// Структура для состояния клавиатуры
struct KeypadState {
    uint8_t targetDevice = 0;
    uint8_t targetSlot = 0;
    String templateText = "";
};

class Nextion {
public:
    void begin();
    void update();
    bool hasCommand();
    String getCommand();
    void handleKeypadInput(const String &key); 
    void showKeypad(uint8_t device, uint8_t slot, const char* tmpl);
    void setPage(uint8_t page);
    void resetCache();

    // 🆕 ПУБЛИЧНЫЕ ПЕРЕМЕННЫЕ (нужны network.cpp для обновления экрана)
    uint8_t currentPage = 0;
    uint8_t scheduleDevice = 0;

private:
    unsigned long lastUpdate = 0;
    
    NextionCache cache;      // Экземпляр кэша
    KeypadState keypad;      // Экземпляр состояния клавиатуры
    String rxBuffer;         // Буфер для склеенных команд
    
    uint8_t pumpFrames[4] = {0, 0, 0, 0};
    uint8_t flowFrames[3] = {0, 0, 0};
    uint8_t flameFrame = 0;

    // Внутренние методы отправки
    void sendCommand(const char* cmd);
    void sendTextIfChanged(String &cached, const char* componentName, const char* newValue);
    void sendPicIfChanged(int8_t &cached, const char* componentName, int8_t newPic);
    void sendTempIfChanged(String &cached, const char* componentName, float value, bool valid);
    void formatDeviceStatus(char* buf, size_t bufSize, const char* prefix, bool state, const ManualOverride& mo);
    uint16_t getDateTimeColor();
    void updateDateTime(const char* componentName, String &cacheRef);
    String extractCommand(String &buf);

    // Методы обновления экранов
    void updateMainScreen();
    void updateSchemaScreen();
    void updateSettingsScreen();
    void updateCalibrationScreen();
    void updateTimeScreen();
    void updateScheduleScreen();
    void updateKeypadScreen();
    void updateQuickAccess();
    void updateStatusScreen();
};

extern Nextion nextion;

#endif // NEXTION_H