#ifndef NEXTION_H
#define NEXTION_H

#include <Arduino.h>
#include "config.h"
#include "control.h"
#include "timekeeper.h"

class Nextion {
public:
    void begin();
    void update();

    void sendCommand(const char* cmd);
    bool hasCommand();
    String getCommand();
    void setPage(uint8_t page);

    void updateMainScreen();
    void updateSchemaScreen();
    void updateSettingsScreen();
    void updateCalibrationScreen();
    void updateTimeScreen();
    void updateScheduleScreen();
    void updateKeypadScreen();
    void updateQuickAccess();
    void updateStatusScreen();

    void handleKeypadInput(const String &key);

    // Публичные поля для расписания и клавиатуры
    uint8_t scheduleDevice = 0;

    struct {
        String inputBuffer;
        uint8_t targetDevice;
        uint8_t targetSlot;
        String templateText;
    } keypad;

    // Публичный метод для открытия клавиатуры из main.cpp
    void showKeypad(uint8_t device, uint8_t slot, const char* tmpl);
    void showSaveConfirmation();
    
private:
    void resetCache();
    void sendTextIfChanged(String &cached, const char* componentName, const char* newValue);
    void sendPicIfChanged(int8_t &cached, const char* componentName, int8_t newPic);
    void sendTempIfChanged(String &cached, const char* componentName, float value, bool valid);
    void formatDeviceStatus(char* buf, size_t bufSize, const char* prefix, bool state, const ManualOverride& mo);

    uint16_t getDateTimeColor();
    void updateDateTime(const char* componentName, String &cacheRef);

    unsigned long lastUpdate;
    uint8_t pumpFrames[4];
    uint8_t flowFrames[3];
    uint8_t flameFrame;
    uint8_t currentPage;

    struct {
        // Page 0
        String txt_rval, txt_fval, txt_oval, txt_aval, txt_bval;
        String txt_l1, txt_l2, txt_l3, txt_pumps, txt_online;
        String s_b, s_e, s_f, s_r;
        String datetime_cache;
        int8_t pic_pf = -1, pic_pr = -1, pic_pb = -1, pic_pe = -1, pic_flame = -1;
        int8_t datetime_color = -1;

        // Page 1
        String t_ta;
        String txt_ta, txt_tf, txt_tr;
        String datetime1_cache;
        int8_t img_b = -1, img_ta = -1;
        int8_t img_p1 = -1, img_p2 = -1, img_p3 = -1;
        int8_t img_f1 = -1, img_f2 = -1, img_f3 = -1;
        int8_t ph_l1 = -1, ph_l2 = -1, ph_l3 = -1;
        String st_e, st_p1, st_p2, st_p3;

        // Page 2
        String t_vbon, t_vbof, t_vfon, t_vfof;
        String t_vron, t_vrof, t_vaon, t_vaof, t_vtm;

        // Page 5
        String t_cnum;
        String c_v[5];
        String c_t[5];

        // Page 6
        String t_date, t_time;
        String t_year, t_month, t_day, t_hour, t_minute;
        int8_t ntp_status = -1;

        // Page 7: Расписание
        String t_cur_dev;
        String t_sch_en;
        String t_s[4];
        int8_t chk_state[4];
        int16_t bg_color[4];

        // Page 8: Клавиатура
        String keypad_input;
        String keypad_template;

        // Page 3
        String t_st_b, t_st_e, t_st_f, t_st_r;
        String t_tm_b, t_tm_e, t_tm_f, t_tm_r;
    } cache;
};

extern Nextion nextion;

#endif // NEXTION_H