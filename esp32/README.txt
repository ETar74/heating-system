esp32-heating/
├── platformio.ini
├── src/
│   ├── main.cpp          ← Точка входа, создание задач
│   ├── config.h          ← Пины, константы, настройки
│   ├── storage.h/cpp     ← Работа с NVS (настройки, адреса датчиков)
│   ├── sensors.h/cpp     ← Опрос DS18B20, калибровка
│   ├── control.h/cpp     ← Алгоритмы управления реле
│   ├── network.h/cpp     ← HTTP-клиент, связь с сервером
│   └── nextion.h/cpp     ← Интерфейс с экраном
└── include/
    └── README

!"#$%&'()*+,-./0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\]^_`abcdefghijklmnopqrstuvwxyz{|}~ЁАБВГДЕЖЗИЙКЛМНОПРСТУФХЦЧШЩЪЫЬЭЮЯабвгдежзийклмнопрстуфхцчшщъыьэюяё№
