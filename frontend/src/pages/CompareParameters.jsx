import { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import { LineChart, Line, XAxis, YAxis, CartesianGrid, Tooltip, Legend, ResponsiveContainer } from 'recharts';
import { telemetry } from '../api';
import './CompareParameters.css';

function CompareParameters() {
  const navigate = useNavigate();
  const [data, setData] = useState([]);
  const [loading, setLoading] = useState(true);
  const [period, setPeriod] = useState(24);
  
  // Параметры для сравнения
  const [selectedParams, setSelectedParams] = useState([
    'room_temp',
    'outdoor_temp'
  ]);

  // Информация о параметрах
  const paramInfo = {
    'room_temp': { name: 'Помещение', color: '#e74c3c', unit: '°C' },
    'outdoor_temp': { name: 'Улица', color: '#3498db', unit: '°C' },
    'boiler_temp': { name: 'Котёл', color: '#e67e22', unit: '°C' },
    'floor_temp': { name: 'Тёплый пол', color: '#9b59b6', unit: '°C' }
  };

  useEffect(() => {
    loadHistory();
  }, [selectedParams, period]);

  const loadHistory = async () => {
    setLoading(true);
    try {
      // Загружаем историю для всех выбранных параметров
      const promises = selectedParams.map(async (param) => {
        const response = await telemetry.getHistory({
          parameter: param,
          hours: period
        });
        return { param, data: response.data };
      });

      const results = await Promise.all(promises);

      // Объединяем данные по времени
      const merged = {};
      
      results.forEach(({ param, data }) => {
        data.forEach(item => {
          const timeKey = new Date(item.timestamp).getTime();
          const timeLabel = new Date(item.timestamp).toLocaleTimeString('ru-RU', {
            hour: '2-digit',
            minute: '2-digit'
          });

          if (!merged[timeKey]) {
            merged[timeKey] = { time: timeLabel, timestamp: timeKey };
          }
          
          merged[timeKey][param] = parseFloat(item.value);
        });
      });

      // Сортируем по времени
      const sorted = Object.values(merged).sort((a, b) => a.timestamp - b.timestamp);
      
      setData(sorted);
    } catch (error) {
      console.error('Error loading history:', error);
    } finally {
      setLoading(false);
    }
  };

  // Переключение выбора параметра
  const toggleParam = (param) => {
    setSelectedParams(prev => {
      if (prev.includes(param)) {
        // Убираем параметр (но оставляем минимум один)
        if (prev.length > 1) {
          return prev.filter(p => p !== param);
        }
        return prev;
      } else {
        // Добавляем параметр
        return [...prev, param];
      }
    });
  };

  return (
    <div className="compare-parameters">
      <div className="detail-header">
        <button className="back-btn" onClick={() => navigate('/')}>
          ← Назад
        </button>
        <h1>Сравнение параметров</h1>
      </div>

      {/* Выбор параметров */}
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

      {/* Переключатель периода */}
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

      {/* График */}
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
              <XAxis
                dataKey="time"
                stroke="#7f8c8d"
                style={{ fontSize: '12px' }}
              />
              <YAxis
                stroke="#7f8c8d"
                style={{ fontSize: '12px' }}
                unit="°C"
              />
              <Tooltip
                contentStyle={{
                  backgroundColor: 'white',
                  border: '1px solid #ddd',
                  borderRadius: '5px'
                }}
              />
              <Legend />
              {selectedParams.map(param => (
                <Line
                  key={param}
                  type="monotone"
                  dataKey={param}
                  name={paramInfo[param].name}
                  stroke={paramInfo[param].color}
                  strokeWidth={2}
                  dot={{ fill: paramInfo[param].color, r: 2 }}
                  activeDot={{ r: 5 }}
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