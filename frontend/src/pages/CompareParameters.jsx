import { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import { 
  LineChart, Line, XAxis, YAxis, CartesianGrid, 
  Tooltip, Legend, ResponsiveContainer, ReferenceLine 
} from 'recharts';
import CustomTooltip from '../components/CustomTooltip';
import { telemetry, settings } from '../api';
import './CompareParameters.css';

function CompareParameters() {
  const navigate = useNavigate();
  const [data, setData] = useState([]);
  const [loading, setLoading] = useState(true);
  const [period, setPeriod] = useState(24);
  
  const [selectedParams, setSelectedParams] = useState([
    'room_temp',
    'outdoor_temp'
  ]);

  const [targetParams, setTargetParams] = useState({});  // ← Для target

const paramInfo = {
  'room_temp': { name: 'Помещение', color: '#e74c3c', unit: '°C' },
  'outdoor_temp': { name: 'Улица', color: '#3498db', unit: '°C' },
  'boiler_temp': { name: 'Котёл', color: '#e67e22', unit: '°C' },
  'floor_temp': { name: 'Тёплый пол', color: '#9b59b6', unit: '°C' },
  'accumulator_temp': { name: 'Теплоаккумулятор', color: '#27ae60', unit: '°C' }
};

  useEffect(() => {
    loadHistory();
    loadTargetSettings();  // ← Загрузить target
  }, [selectedParams, period]);

  const loadTargetSettings = async () => {
    try {
      const response = await settings.getAll();
      const targets = {};
      
      response.data.forEach(param => {
        if (param.key.includes('_target')) {
          const paramName = param.key.replace('_target', '');
          targets[paramName] = parseFloat(param.value);
        }
      });
      
      console.log('🎯 Target settings:', targets);
      setTargetParams(targets);
    } catch (error) {
      console.error('Error loading targets:', error);
    }
  };

  const loadHistory = async () => {
    setLoading(true);
    try {
      const promises = selectedParams.map(async (param) => {
        const response = await telemetry.getHistory({
          parameter: param,
          hours: period
        });
        return { param, data: response.data };
      });

      const results = await Promise.all(promises);

      // Группируем по 5-секундным интервалам (частота опроса ESP32)
      const merged = {};
      
      results.forEach(({ param, data }) => {
        data.forEach(item => {
          const date = new Date(item.timestamp);
          // Округляем до 5 секунд
          const timeKey = Math.floor(date.getTime() / 5000) * 5000;
          
          if (!merged[timeKey]) {
            merged[timeKey] = { timestamp: timeKey };
          }
          
          merged[timeKey][param] = parseFloat(item.value);
        });
      });

      // Сортируем по времени
      const sorted = Object.values(merged).sort((a, b) => a.timestamp - b.timestamp);
      
      console.log('📊 Data points:', sorted.length);
      console.log('📊 Time range:', 
        new Date(sorted[0]?.timestamp).toLocaleString(), 
        '→', 
        new Date(sorted[sorted.length - 1]?.timestamp).toLocaleString()
      );
      
      setData(sorted);
    } catch (error) {
      console.error('Error loading history:', error);
    } finally {
      setLoading(false);
    }
  };

  const toggleParam = (param) => {
    setSelectedParams(prev => {
      if (prev.includes(param)) {
        if (prev.length > 1) {
          return prev.filter(p => p !== param);
        }
        return prev;
      } else {
        return [...prev, param];
      }
    });
  };

  // Функция для расчёта границ суток в диапазоне данных
  const getDayBoundaries = () => {
    if (data.length === 0) return [];
    
    const firstTimestamp = data[0].timestamp;
    const lastTimestamp = data[data.length - 1].timestamp;
    
    // Находим начало первых суток (00:00:00)
    const firstDate = new Date(firstTimestamp);
    const firstDayStart = new Date(firstDate);
    firstDayStart.setHours(0, 0, 0, 0);
    
    // Если первая точка уже после полуночи — начинаем со следующих суток
    const startTimestamp = firstTimestamp > firstDayStart.getTime()
      ? firstDayStart.getTime() + 24 * 60 * 60 * 1000
      : firstDayStart.getTime();
    
    const boundaries = [];
    let current = startTimestamp;
    
    // Собираем все полуночи в диапазоне
    while (current <= lastTimestamp) {
      boundaries.push(current);
      current += 24 * 60 * 60 * 1000; // +1 сутки
    }
    
    return boundaries;
  };

  const dayBoundaries = getDayBoundaries();

  return (
    <div className="compare-parameters">
      <div className="detail-header">
        <button className="back-btn" onClick={() => navigate('/')}>
          ← Назад
        </button>
        <h1>Сравнение параметров</h1>
      </div>

      <div className="param-selector">
        <h3>Выберите параметры для сравнения:</h3>
        <div className="checkbox-group">
          {Object.entries(paramInfo).map(([key, info]) => (
            <label key={key} className="checkbox-label">
              <input
                type="checkbox"
                checked={selectedParams.includes(key)}
                onChange={() => toggleParam(key)}
              />
              <span className="color-dot" style={{ backgroundColor: info.color }}></span>
              {info.name}
            </label>
          ))}
        </div>
      </div>

      <div className="period-selector">
        <button
          className={period === 1 ? 'active' : ''}
          onClick={() => setPeriod(1)}
        >
          1 час
        </button>
        <button
          className={period === 6 ? 'active' : ''}
          onClick={() => setPeriod(6)}
        >
          6 часов
        </button>
        <button
          className={period === 24 ? 'active' : ''}
          onClick={() => setPeriod(24)}
        >
          24 часа
        </button>
        <button
          className={period === 168 ? 'active' : ''}
          onClick={() => setPeriod(168)}
        >
          7 дней
        </button>
      </div>

      <div className="chart-container">
        {loading ? (
          <div className="loading">Загрузка...</div>
        ) : data.length === 0 ? (
          <div className="no-data">
            Нет данных за выбранный период
          </div>
        ) : (
          <ResponsiveContainer width="100%" height={500}>
            <LineChart data={data}>
              <CartesianGrid strokeDasharray="3 3" stroke="#ecf0f1" />
              
              {/* Ось X — только время */}
              <XAxis
                dataKey="timestamp"
                type="number"
                scale="time"
                domain={['dataMin', 'dataMax']}
                stroke="#7f8c8d"
                style={{ fontSize: '12px' }}
                tickFormatter={(timestamp) => {
                  return new Date(timestamp).toLocaleTimeString('ru-RU', {
                    hour: '2-digit',
                    minute: '2-digit'
                  });
                }}
                tickCount={8}
                tick={{ fontSize: 11 }}
              />
              
              <YAxis
                stroke="#7f8c8d"
                style={{ fontSize: '12px' }}
                unit="°C"
              />
              
                {/* Вертикальные линии границ суток */}
                {dayBoundaries.map((timestamp, index) => {
                  const date = new Date(timestamp);
                  const dateLabel = date.toLocaleDateString('ru-RU', {
                    day: '2-digit',
                    month: '2-digit'
                  });
                  
                  return (
                    <ReferenceLine
                      key={`day-${index}`}
                      x={timestamp}
                      stroke="#bdc3c7"
                      strokeDasharray="3 3"
                      strokeWidth={1}
                      label={{
                        value: dateLabel,
                        position: 'insideTopLeft',  // ← изменили позицию
                        fill: '#95a5a6',
                        fontSize: 11,
                        fontWeight: 500
                      }}
                    />
                  );
                })}
              
                {/* Горизонтальные пунктирные линии target */}
                {selectedParams.map(param => {
                  const targetValue = targetParams[param];
                  if (!targetValue) return null;
                  
                  return (
                    <ReferenceLine
                      key={`${param}_target`}
                      y={targetValue}
                      stroke={paramInfo[param].color}
                      strokeDasharray="5 5"
                      strokeWidth={1.5}
                      label={{
                        value: `${paramInfo[param].name}: ${targetValue}°C`,
                        position: 'right',
                        fill: paramInfo[param].color,
                        fontSize: 11,
                        fontWeight: 500
                      }}
                    />
                  );
                })}

              <Tooltip 
                content={
                  <CustomTooltip 
                    targetParams={targetParams}
                    paramInfo={paramInfo}
                  />
                }
              />
              <Legend />
              
              {/* Линии параметров */}
              {selectedParams.map(param => (
                <Line
                  key={param}
                  type="monotone"
                  dataKey={param}
                  name={paramInfo[param].name}
                  stroke={paramInfo[param].color}
                  strokeWidth={2}
                  dot={false}
                  activeDot={{ r: 5 }}
                  connectNulls={true}
                />
              ))}
            </LineChart>
          </ResponsiveContainer>
        )}
      </div>
    </div>
  );
}

export default CompareParameters;