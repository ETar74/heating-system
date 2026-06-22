import { useState, useEffect } from 'react';
import { useParams, useNavigate } from 'react-router-dom';
import { LineChart, Line, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer } from 'recharts';
import { telemetry } from '../api';
import './ParameterDetail.css';

function ParameterDetail() {
  const { paramKey } = useParams();
  const navigate = useNavigate();
  const [history, setHistory] = useState([]);
  const [loading, setLoading] = useState(true);
  const [period, setPeriod] = useState(24);
  const [currentValue, setCurrentValue] = useState('—');

  // Названия параметров на русском
  const paramNames = {
    'room_temp': 'Температура помещения',
    'outdoor_temp': 'Температура улицы',
    'boiler_temp': 'Температура котла',
    'floor_temp': 'Температура тёплого пола',
    'mode': 'Режим работы'
  };

  // Единицы измерения
  const paramUnits = {
    'room_temp': '°C',
    'outdoor_temp': '°C',
    'boiler_temp': '°C',
    'floor_temp': '°C',
    'mode': ''
  };

  // Цвета для графиков
  const paramColors = {
    'room_temp': '#e74c3c',
    'outdoor_temp': '#3498db',
    'boiler_temp': '#e67e22',
    'floor_temp': '#9b59b6',
    'mode': '#27ae60'
  };

  useEffect(() => {
    loadHistory();
  }, [paramKey, period]);

  const loadHistory = async () => {
    setLoading(true);
    try {
      const response = await telemetry.getHistory({
        parameter: paramKey,
        hours: period
      });

      // Форматируем данные для графика
      const formatted = response.data.map(item => ({
        time: new Date(item.timestamp).toLocaleTimeString('ru-RU', {
          hour: '2-digit',
          minute: '2-digit'
        }),
        value: parseFloat(item.value) || item.value
      }));

      setHistory(formatted);

      // Текущее значение — последнее в списке
      if (formatted.length > 0) {
        const last = formatted[formatted.length - 1];
        setCurrentValue(last.value);
      } else {
        setCurrentValue('—');
      }
    } catch (error) {
      console.error('Error loading history:', error);
    } finally {
      setLoading(false);
    }
  };

  const isNumeric = !isNaN(parseFloat(currentValue));
  const unit = paramUnits[paramKey] || '';
  const color = paramColors[paramKey] || '#3498db';
  const name = paramNames[paramKey] || paramKey;

  return (
    <div className="parameter-detail">
      <div className="detail-header">
        <button className="back-btn" onClick={() => navigate('/')}>
          ← Назад
        </button>
        <h1>{name}</h1>
      </div>

      {/* Текущее значение */}
      <div className="current-value-card">
        <div className="current-label">Текущее значение</div>
        <div className="current-number" style={{ color }}>
          {isNumeric ? `${currentValue}${unit}` : currentValue}
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
        ) : history.length === 0 ? (
          <div className="no-data">
            Нет данных за выбранный период
          </div>
        ) : isNumeric ? (
          <ResponsiveContainer width="100%" height={400}>
            <LineChart data={history}>
              <CartesianGrid strokeDasharray="3 3" stroke="#ecf0f1" />
              <XAxis
                dataKey="time"
                stroke="#7f8c8d"
                style={{ fontSize: '12px' }}
              />
              <YAxis
                stroke="#7f8c8d"
                style={{ fontSize: '12px' }}
                unit={unit}
              />
              <Tooltip
                contentStyle={{
                  backgroundColor: 'white',
                  border: '1px solid #ddd',
                  borderRadius: '5px'
                }}
              />
              <Line
                type="monotone"
                dataKey="value"
                stroke={color}
                strokeWidth={2}
                dot={{ fill: color, r: 3 }}
                activeDot={{ r: 6 }}
              />
            </LineChart>
          </ResponsiveContainer>
        ) : (
          // Для нечисловых параметров (например, режим) — список последних значений
          <div className="text-history">
            <h3>Последние значения:</h3>
            <ul>
              {history.slice(-20).reverse().map((item, index) => (
                <li key={index}>
                  <span className="time">{item.time}</span>
                  <span className="value">{item.value}</span>
                </li>
              ))}
            </ul>
          </div>
        )}
      </div>
    </div>
  );
}

export default ParameterDetail;