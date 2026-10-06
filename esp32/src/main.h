#ifndef MAIN_H
#define MAIN_H

#include <freertos/semphr.h> // Добавляем заголовок для FreeRTOS семафоров

// Глобальный семафор для защиты доступа к настройкам
extern SemaphoreHandle_t settingsMtx;

#endif // MAIN_H