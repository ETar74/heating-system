import { useState, useEffect } from 'react';
import api from '../api';
import './TemperatureSlider.css';

function TemperatureSlider() {
  const [currentTemp, setCurrentTemp] = useState(null);
  const [targetTemp, setTargetTemp] = useState(22.0);
  const [thresholdOn, setThresholdOn] = useState(21.5);
  const [thresholdOff, setThresholdOff] = useState(22.5);
  const [hysteresis, setHysteresis] = useState(0.5);
  const [isHeating, setIsHeating] = useState(false);
  const [loading, setLoading] = useState(true);

  // Диапазон слайдера
  const minTemp = 15;
  const maxTemp = 30;

  useEffect(() => {
    loadSettings();
    loadCurrentTemp();
    
    // Обновляем текущую температуру каждые 5 секунд
    const interval = setInterval(loadCurrentTemp, 5000);
    return () => clearInterval(interval);
  }, []);

  // Пересчитываем состояние отопления при изменении порогов
  useEffect(() => {
    if (currentTemp !== null) {
      setIsHeating(currentTemp < thresholdOn);
    }
  }, [currentTemp, thresholdOn, thresholdOff]);

  const loadSettings = async () => {
    try {
      const response = await api.get('/settings');
      const params = response.data;
      
      const target = params.find(p => p.key === 'room_target_temp');
      const on = params.find(p => p.key === 'room_threshold_on');
      const off = params.find(p => p.key === 'room_threshold_off');
      const hyst = params.find(p => p.key === 'room_hysteresis');
      
      if (target) setTargetTemp(parseFloat(target.value));
      if (on) setThresholdOn(parseFloat(on.value));
      if (off) setThresholdOff(parseFloat(off.value));
      if (hyst) {
        const hystValue = parseFloat(hyst.value);
        setHysteresis(hystValue);
        // Автоматически пересчитываем пороги на основе гистерезиса
        if (target) {
          const targetValue = parseFloat(target.value);
          setThresholdOn(targetValue - hystValue / 2);
          setThresholdOff(targetValue + hystValue / 2);
        }
      }
    } catch (error) {
      console.error('Error loading settings:', error);
    } finally {
      setLoading(false);
    }
  };

  const loadCurrentTemp = async () => {
    try {
      const response = await api.get('/telemetry/latest');
      const data = response.data;
      if (data.room_temp) {
        const temp = parseFloat(data.room_temp.value);
        setCurrentTemp(temp);
        setIsHeating(temp < thresholdOn);
      }
    } catch (error) {
      console.error('Error loading current temp:', error);
    }
  };

  // Вычисляем позиции для визуализации (в процентах)
  const tempRange = maxTemp - minTemp;
  const currentPos = currentTemp !== null 
    ? ((currentTemp - minTemp) / tempRange) * 100 
    : 0;
  const targetPos = ((targetTemp - minTemp) / tempRange) * 100;
  const thresholdOnPos = ((thresholdOn - minTemp) / tempRange) * 100;
  const thresholdOffPos = ((thresholdOff - minTemp) / tempRange) * 100;

  // Определяем цвет текущей температуры
  const getTempColor = () => {
    if (currentTemp === null) return '#95a5a6';
    if (currentTemp < thresholdOn) return '#3498db'; // Холодно - синий
    if (currentTemp > thresholdOff) return '#e74c3c'; // Жарко - красный
    return '#27ae60'; // Норма - зелёный
  };

  const getStatusText = () => {
    if (currentTemp === null) return '⏸️ Нет данных';
    if (currentTemp < thresholdOn) return '🔥 Нагрев';
    if (currentTemp > thresholdOff) return '❄️ Охлаждение';
    return '✅ Норма';
  };

  if (loading) {
    return (
      <div className="temp-slider-container">
        <div className="loading">Загрузка виджета...</div>
      </div>
    );
  }

  return (
    <div className="temp-slider-container">
      <div className="slider-header">
        <h3>🌡️ Температура помещения</h3>
        <div className={`heating-indicator ${isHeating ? 'active' : ''} ${currentTemp === null ? 'no-data' : ''}`}>
          {getStatusText()}
        </div>
      </div>

      {/* Текущая температура */}
      <div className="current-temp-display" style={{ color: getTempColor() }}>
        {currentTemp !== null ? `${currentTemp.toFixed(1)}°C` : '—'}
      </div>

      {/* Слайдер */}
      <div className="slider-track-container">
        <div className="slider-track">
          {/* Зона гистерезиса (зелёная) */}
          <div 
            className="hysteresis-zone"
            style={{
              left: `${thresholdOnPos}%`,
              width: `${thresholdOffPos - thresholdOnPos}%`
            }}
          />

          {/* Порог включения */}
          <div 
            className="threshold-marker threshold-on"
            style={{ left: `${thresholdOnPos}%` }}
            title={`Включение: ${thresholdOn}°C`}
          >
            <div className="marker-line" />
            <div className="marker-label">▼ {thresholdOn}°C</div>
          </div>

          {/* Порог выключения */}
          <div 
            className="threshold-marker threshold-off"
            style={{ left: `${thresholdOffPos}%` }}
            title={`Выключение: ${thresholdOff}°C`}
          >
            <div className="marker-line" />
            <div className="marker-label">▲ {thresholdOff}°C</div>
          </div>

          {/* Целевая температура */}
          <div 
            className="target-marker"
            style={{ left: `${targetPos}%` }}
            title={`Цель: ${targetTemp}°C`}
          >
            <div className="target-line" />
            <div className="target-label">🎯 {targetTemp}°C</div>
          </div>

          {/* Текущая температура (ползунок) */}
          {currentTemp !== null && (
            <div 
              className="current-marker"
              style={{ 
                left: `${currentPos}%`,
                backgroundColor: getTempColor()
              }}
            >
              <div className="current-indicator" />
            </div>
          )}
        </div>

        {/* Шкала */}
        <div className="slider-scale">
          {Array.from({ length: 7 }, (_, i) => {
            const temp = minTemp + (i * (tempRange / 6));
            const pos = (i / 6) * 100;
            return (
              <div 
                key={i} 
                className="scale-mark"
                style={{ left: `${pos}%` }}
              >
                {temp.toFixed(0)}°
              </div>
            );
          })}
        </div>
      </div>

      {/* Информация о параметрах */}
      <div className="slider-info">
        <div className="info-item">
          <span className="info-label">Гистерезис:</span>
          <span className="info-value">±{hysteresis}°C</span>
        </div>
        <div className="info-item">
          <span className="info-label">Диапазон работы:</span>
          <span className="info-value">{thresholdOn}°C — {thresholdOff}°C</span>
        </div>
        <div className="info-item">
          <span className="info-label">Цель:</span>
          <span className="info-value">{targetTemp}°C</span>
        </div>
      </div>
    </div>
  );
}

export default TemperatureSlider;