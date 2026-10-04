function CustomTooltip({ active, payload, label, targetParams = {}, paramInfo = {} }) {
  if (!active || !payload || !payload.length) return null;
  
  const dataPoint = payload[0]?.payload;
  
  // Формат даты и времени
  const date = dataPoint?.timestamp 
    ? new Date(dataPoint.timestamp).toLocaleString('ru-RU', {
        day: '2-digit',
        month: '2-digit',
        year: 'numeric',
        hour: '2-digit',
        minute: '2-digit',
        second: '2-digit'
      })
    : label;
  
  // Собираем все параметры, добавляем target и СОРТИРУЕМ по убыванию
  const allParams = Object.keys(dataPoint)
    .filter(key => key !== 'time' && key !== 'timestamp' && !key.includes('_target'))
    .map(key => ({
      key,
      value: dataPoint[key],
      target: targetParams[key],
      info: paramInfo[key] || { name: key, color: '#999' }
    }))
    .filter(item => item.value !== undefined)
    .sort((a, b) => b.value - a.value);
  
  return (
    <div style={{
      background: 'white',
      border: '2px solid #e0e0e0',
      borderRadius: '8px',
      padding: '12px',
      boxShadow: '0 4px 12px rgba(0,0,0,0.15)',
      minWidth: '260px',
      fontFamily: 'Segoe UI, sans-serif'
    }}>
      {/* Дата и время */}
      <div style={{
        fontWeight: 'bold',
        fontSize: '14px',
        color: '#2c3e50',
        marginBottom: '8px',
        paddingBottom: '8px',
        borderBottom: '1px solid #e0e0e0'
      }}>
        {date}
      </div>
      
      {/* Все параметры (отсортированы по убыванию) */}
      {allParams.map((param, index) => {
        // Проверка неисправного датчика (-127°C)
        const isFaulty = typeof param.value === 'number' && param.value <= -127;
        
        // Вычисляем дельту (только если датчик исправен)
        const delta = (!isFaulty && param.target !== undefined) 
          ? param.value - param.target 
          : null;
        const deltaSign = delta > 0 ? '+' : '';
        
        // Определяем цвет фона дельты
        let deltaBg, deltaColor, deltaBorder;
        if (delta !== null) {
          if (delta > 0.1) {
            // Превышение — красный
            deltaBg = 'rgba(231, 76, 60, 0.15)';
            deltaColor = '#c0392b';
            deltaBorder = '1px solid rgba(231, 76, 60, 0.4)';
          } else if (delta < -0.1) {
            // Недобор — синий
            deltaBg = 'rgba(52, 152, 219, 0.15)';
            deltaColor = '#2471a3';
            deltaBorder = '1px solid rgba(52, 152, 219, 0.4)';
          } else {
            // Норма (±0.1°C) — зелёный
            deltaBg = 'rgba(39, 174, 96, 0.15)';
            deltaColor = '#1e8449';
            deltaBorder = '1px solid rgba(39, 174, 96, 0.4)';
          }
        }
        
        return (
          <div key={index} style={{
            display: 'flex',
            alignItems: 'center',
            gap: '8px',
            margin: '6px 0',
            fontSize: '13px'
          }}>
            {/* Цветная точка (цвет = цвет линии) */}
            <div style={{
              width: '10px',
              height: '10px',
              borderRadius: '50%',
              backgroundColor: param.info.color,
              flexShrink: 0
            }}></div>
            
            {/* Название параметра */}
            <span style={{ 
              flex: 1, 
              color: '#34495e', 
              fontWeight: 500 
            }}>
              {param.info.name}:
            </span>
            
            {/* Значение + Дельта или Ошибка датчика */}
            <div style={{ textAlign: 'right', whiteSpace: 'nowrap' }}>
              {isFaulty ? (
                // 🔴 Неисправный датчик
                <span style={{ 
                  fontWeight: 700, 
                  color: '#c0392b', 
                  fontSize: '13px',
                  padding: '2px 6px',
                  borderRadius: '3px',
                  background: 'rgba(231, 76, 60, 0.15)',
                  border: '1px solid rgba(231, 76, 60, 0.4)'
                }}>
                  ⚠️ (Неисправен датчик)
                </span>
              ) : (
                <>
                  {/* Текущая температура */}
                  <span style={{ 
                    fontWeight: 700, 
                    color: '#2c3e50', 
                    fontSize: '14px' 
                  }}>
                    {typeof param.value === 'number' 
                      ? param.value.toFixed(1) 
                      : param.value}°C
                  </span>
                  
                  {/* Дельта в скобках (если есть target) */}
                  {delta !== null && (
                    <span style={{ 
                      fontWeight: 500, 
                      color: deltaColor,
                      fontSize: '12px',
                      marginLeft: '6px',
                      padding: '2px 6px',
                      borderRadius: '4px',
                      background: deltaBg,
                      border: deltaBorder
                    }}>
                      Δ ({deltaSign}{delta.toFixed(1)}°C)
                    </span>
                  )}
                </>
              )}
            </div>
          </div>
        );
      })}
    </div>
  );
}

export default CustomTooltip;