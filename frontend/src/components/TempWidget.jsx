import { useState, useEffect } from 'react';
import api from '../api';
import './TempWidget.css';

function TempWidget({ paramKey, title, subtitle, icon, unit = '°C', min = 15, max = 30, accentColor = '#3498db' }) {
  const [currentValue, setCurrentValue] = useState(null);
  const [targetValue, setTargetValue] = useState(null);
  const [thresholdOn, setThresholdOn] = useState(null);
  const [thresholdOff, setThresholdOff] = useState(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);

  useEffect(() => {
    loadSettings();
    loadCurrentValue();
    
    const interval = setInterval(loadCurrentValue, 5000);
    return () => clearInterval(interval);
  }, [paramKey]);

  const loadSettings = async () => {
    console.log(`🔧 [${paramKey}] Loading settings...`);
    try {
      const response = await api.get('/settings');
      console.log(`🔧 [${paramKey}] Response status:`, response.status);
      console.log(`🔧 [${paramKey}] Response data:`, response.data);
      
      const params = response.data;
      
      if (!Array.isArray(params)) {
        console.error(`❌ [${paramKey}] Settings is not an array:`, params);
        setError('Неверный формат настроек');
        return;
      }
      
      const target = params.find(p => p.key === `${paramKey}_target`);
      const on = params.find(p => p.key === `${paramKey}_threshold_on`);
      const off = params.find(p => p.key === `${paramKey}_threshold_off`);
      
      console.log(`🔧 [${paramKey}] Found target:`, target);
      console.log(`🔧 [${paramKey}] Found threshold_on:`, on);
      console.log(`🔧 [${paramKey}] Found threshold_off:`, off);
      
      if (target) setTargetValue(parseFloat(target.value));
      if (on) setThresholdOn(parseFloat(on.value));
      if (off) setThresholdOff(parseFloat(off.value));
    } catch (error) {
      console.error(`❌ [${paramKey}] Error loading settings:`, error);
      console.error(`❌ [${paramKey}] Error response:`, error.response);
      console.error(`❌ [${paramKey}] Error status:`, error.response?.status);
      console.error(`❌ [${paramKey}] Error data:`, error.response?.data);
      setError(`Ошибка: ${error.response?.status || error.message}`);
    }
  };

  const loadCurrentValue = async () => {
    console.log(`🔧 [${paramKey}] Loading current value...`);
    try {
      const response = await api.get('/telemetry/latest');
      console.log(`🔧 [${paramKey}] Telemetry response status:`, response.status);
      console.log(`🔧 [${paramKey}] Telemetry response data:`, response.data);
      
      const data = response.data;
      
      if (!data || typeof data !== 'object') {
        console.warn(`⚠️ [${paramKey}] Invalid telemetry data:`, data);
        return;
      }
      
      console.log(`🔧 [${paramKey}] Looking for key:`, paramKey);
      console.log(`🔧 [${paramKey}] Found value:`, data[paramKey]);
      
      if (data[paramKey]) {
        const value = parseFloat(data[paramKey].value);
        console.log(`✅ [${paramKey}] Current value:`, value);
        setCurrentValue(value);
        setError(null);
      } else {
        console.warn(`⚠️ [${paramKey}] No data found for key:`, paramKey);
        console.warn(`⚠️ [${paramKey}] Available keys:`, Object.keys(data));
      }
    } catch (error) {
      console.error(`❌ [${paramKey}] Error loading current value:`, error);
      console.error(`❌ [${paramKey}] Error response:`, error.response);
      console.error(`❌ [${paramKey}] Error status:`, error.response?.status);
      console.error(`❌ [${paramKey}] Error data:`, error.response?.data);
      setError(`Ошибка: ${error.response?.status || error.message}`);
    } finally {
      setLoading(false);
    }
  };

  // Вычисляем позиции в процентах
  const range = max - min;
  const currentPos = currentValue !== null 
    ? Math.max(0, Math.min(100, ((currentValue - min) / range) * 100)) 
    : null;
  const targetPos = targetValue !== null 
    ? ((targetValue - min) / range) * 100 
    : null;
  const thresholdOnPos = thresholdOn !== null 
    ? ((thresholdOn - min) / range) * 100 
    : null;
  const thresholdOffPos = thresholdOff !== null 
    ? ((thresholdOff - min) / range) * 100 
    : null;

  // Проверка неисправности датчика
  const isSensorFaulty = currentValue !== null && currentValue <= -127;

  // Цвет текущего значения
  const getValueColor = () => {
    if (currentValue === null) return '#95a5a6';
    if (isSensorFaulty) return '#e74c3c'; // 🔴 Красный при неисправности
    if (thresholdOn !== null && currentValue < thresholdOn) return '#3498db';
    if (thresholdOff !== null && currentValue > thresholdOff) return '#e74c3c';
    return '#27ae60';
  };

  const hasThresholds = thresholdOn !== null && thresholdOff !== null;

  if (loading) {
    return (
      <div className="temp-widget">
        <div className="widget-loading">Загрузка...</div>
      </div>
    );
  }

  if (error) {
    return (
      <div className="temp-widget">
        <div className="widget-header">
          <div className="widget-title">
            <span className="widget-icon">{icon}</span>
            <div className="widget-title-text">
              <span>{title}</span>
              {subtitle && <span className="widget-subtitle">{subtitle}</span>}
            </div>
          </div>
        </div>
        <div className="widget-error" style={{ color: '#e74c3c', padding: '1rem', textAlign: 'center' }}>
          {error}
        </div>
      </div>
    );
  }

  return (
    <div className="temp-widget" style={{ borderLeftColor: accentColor }}>
      {/* Заголовок */}
      <div className="widget-header">
        <div className="widget-title">
          <span className="widget-icon">{icon}</span>
          <span>{title}</span>
        </div>
        <div className="widget-value" style={{ color: getValueColor() }}>
          {isSensorFaulty ? (
            <span title="Датчик неисправен">⚠️ ОШИБКА</span>
          ) : (
            currentValue !== null ? `${currentValue.toFixed(1)}${unit}` : '—'
          )}
        </div>
      </div>

      {/* Слайдер-трек */}
      <div className="widget-track-wrapper">
        <div className="widget-track">
          {/* Зона гистерезиса */}
          {hasThresholds && (
            <div 
              className="widget-hysteresis-zone"
              style={{
                left: `${thresholdOnPos}%`,
                width: `${thresholdOffPos - thresholdOnPos}%`
              }}
            />
          )}

          {/* Порог включения */}
          {thresholdOnPos !== null && (
            <div 
              className="widget-threshold widget-threshold-on"
              style={{ left: `${thresholdOnPos}%` }}
              title={`Вкл: ${thresholdOn}${unit}`}
            >
              <div className="widget-threshold-line" />
              <div className="widget-threshold-label">{thresholdOn}</div>
            </div>
          )}

          {/* Порог выключения */}
          {thresholdOffPos !== null && (
            <div 
              className="widget-threshold widget-threshold-off"
              style={{ left: `${thresholdOffPos}%` }}
              title={`Выкл: ${thresholdOff}${unit}`}
            >
              <div className="widget-threshold-line" />
              <div className="widget-threshold-label">{thresholdOff}</div>
            </div>
          )}

          {/* Цель */}
          {targetPos !== null && (
            <div 
              className="widget-target"
              style={{ left: `${targetPos}%` }}
              title={`Цель: ${targetValue}${unit}`}
            >
              <div className="widget-target-line" />
            </div>
          )}

          {/* Текущее значение */}
          {currentPos !== null && (
            <div 
              className="widget-current"
              style={{ 
                left: `${currentPos}%`,
                backgroundColor: getValueColor()
              }}
            >
              <div className="widget-current-dot" />
            </div>
          )}
        </div>

        {/* Мини-шкала */}
        <div className="widget-scale">
          <span>{min}{unit}</span>
          <span>{((min + max) / 2).toFixed(0)}{unit}</span>
          <span>{max}{unit}</span>
        </div>
      </div>

      {/* Информация о порогах */}
      {hasThresholds && (
        <div className="widget-info">
          <div className="widget-info-item">
            <span className="widget-info-label">Вкл:</span>
            <span className="widget-info-value" style={{ color: '#3498db' }}>{thresholdOn}{unit}</span>
          </div>
          <div className="widget-info-item">
            <span className="widget-info-label">Цель:</span>
            <span className="widget-info-value" style={{ color: '#9b59b6' }}>{targetValue}{unit}</span>
          </div>
          <div className="widget-info-item">
            <span className="widget-info-label">Выкл:</span>
            <span className="widget-info-value" style={{ color: '#e74c3c' }}>{thresholdOff}{unit}</span>
          </div>
        </div>
      )}

      {/* ⚠️ Предупреждение о неисправном датчике */}
      {isSensorFaulty && (
        <div className="widget-warning">
          ⚠️ Датчик неисправен ({currentValue}°C)
        </div>
      )}
    </div>
  );
}

export default TempWidget;