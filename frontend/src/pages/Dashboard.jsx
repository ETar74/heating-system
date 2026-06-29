import { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import { telemetry } from '../api';
import api from '../api';
import './Dashboard.css';
import TempWidget from '../components/TempWidget';

function Dashboard() {
  const navigate = useNavigate();
  const [data, setData] = useState({});
  const [device, setDevice] = useState({ online: false, name: 'Не настроено' });
  const [loading, setLoading] = useState(true);
  const [wsStatus, setWsStatus] = useState('disconnected');

  useEffect(() => {
    loadData();
    loadDeviceStatus();
    connectWebSocket();
  }, []);

  const loadData = async () => {
    try {
      const response = await telemetry.getLatest();
      setData(response.data);
    } catch (error) {
      console.error('Error loading telemetry:', error);
    } finally {
      setLoading(false);
    }
  };

  const loadDeviceStatus = async () => {
    try {
      const response = await api.get('/device/status');
      setDevice(response.data);
    } catch (error) {
      console.error('Error loading device status:', error);
    }
  };

  const connectWebSocket = () => {
    const ws = new WebSocket('ws://localhost:3000');
    
    ws.onopen = () => setWsStatus('connected');

    ws.onmessage = (event) => {
      const msg = JSON.parse(event.data);
      if (msg.type === 'telemetry_updated') {
        setData(prev => ({ ...prev, ...msg.data }));
      }
      if (msg.type === 'device_status_updated') {
        loadDeviceStatus();
      }
    };

    ws.onclose = () => {
      setWsStatus('disconnected');
      setTimeout(connectWebSocket, 5000);
    };

    return () => ws.close();
  };

  const formatLastSeen = (date) => {
    if (!date) return 'Нет данных';
    return new Date(date).toLocaleString('ru-RU');
  };

  const getValue = (key) => {
    return data[key] ? data[key].value : '—';
  };

  // Проверка неисправных датчиков (температура <= -127)
  const faultySensors = Object.entries(data)
    .filter(([key, val]) => {
      const temp = parseFloat(val?.value);
      return !isNaN(temp) && temp <= -127;
    })
    .map(([key]) => {
      const names = {
        room_temp: 'Помещение',
        boiler_temp: 'Котёл',
        floor_temp: 'Тёплый пол',
        accumulator_temp: 'Теплоаккумулятор',
        outdoor_temp: 'Улица'
      };
      return names[key] || key;
    });

  const openDetail = (paramKey) => {
    navigate(`/parameter/${paramKey}`);
  };

  if (loading) {
    return <div className="loading">Загрузка...</div>;
  }

  return (
    <div className="dashboard">
      {/* Шапка */}
      <div className="dashboard-header">
        <h1>Главная панель</h1>
        <div className={`ws-status ${wsStatus}`}>
          {wsStatus === 'connected' ? '🟢 Сервер: онлайн' : '🔴 Сервер: офлайн'}
        </div>
      </div>

      
      {/* ⚠️ Баннер неисправных датчиков */}
      {faultySensors.length > 0 && (
        <div className="sensor-warning-banner">
          ⚠️ <strong>Внимание:</strong> Неисправны датчики: {faultySensors.join(', ')}
        </div>
      )}

      {/* Устройство — маленькие карточки (size-sm) */}
      <div className="section">
        <h2 className="section-title">📡 Устройство</h2>
        <div className="cards-grid">
          <div className="card size-sm">
            <div className="card-icon">📡</div>
            <div className="card-title">ESP32</div>
            <div className="card-value">
              {device.online ? '🟢 ONLINE' : '🔴 OFFLINE'}
            </div>
          </div>

          <div className="card size-sm">
            <div className="card-icon">🕐</div>
            <div className="card-title">Последняя связь</div>
            <div className="card-value small">
              {formatLastSeen(device.lastSeen)}
            </div>
          </div>
        </div>
      </div>

      {/* Температуры — сетка 2×2 (НЕ ТРОГАЕМ) */}
      <div className="section">
        <h2 className="section-title">🌡️ Температуры</h2>
        <div className="widgets-grid-2x2">
          <div onClick={() => openDetail('accumulator_temp')}>
            <TempWidget
              paramKey="accumulator_temp"
              title="Теплоаккумулятор"
              subtitle="(электрокотёл)"
              icon=""
              unit="°C"
              min={40}
              max={90}
              accentColor="#4facfe"
            />
          </div>

          <div onClick={() => openDetail('boiler_temp')}>
            <TempWidget
              paramKey="boiler_temp"
              title="Котёл"
              icon="🔥"
              unit="°C"
              min={20}
              max={80}
              accentColor="#f5576c"
            />
          </div>

          <div onClick={() => openDetail('floor_temp')}>
            <TempWidget
              paramKey="floor_temp"
              title="Тёплые полы"
              icon=""
              unit="°C"
              min={15}
              max={60}
              accentColor="#43e97b"
            />
          </div>

          <div onClick={() => openDetail('room_temp')}>
            <TempWidget
              paramKey="room_temp"
              title="Помещение"
              icon=""
              unit="°C"
              min={15}
              max={30}
              accentColor="#667eea"
            />
          </div>
        </div>
      </div>

      {/* Улица — очень маленькая карточка (size-xs) */}
      <div className="section">
        <h2 className="section-title">🌤️ Улица</h2>
        <div className="outdoor-card card size-xs">
          <div className="outdoor-value">
            {getValue('outdoor_temp') !== '—' ? `${getValue('outdoor_temp')} °C` : '—'}
          </div>
          <div className="outdoor-label">Температура на улице</div>
        </div>
      </div>

      {/* Режим работы — маленькая карточка (size-sm) */}
      <div className="section">
        <h2 className="section-title">⚙️ Режим работы</h2>
        <div className="cards-grid">
          <div className="card size-sm clickable" onClick={() => openDetail('mode')}>
            <div className="card-icon">⚙️</div>
            <div className="card-title">Текущий режим</div>
            <div className="card-value">{getValue('mode')}</div>
          </div>
        </div>
      </div>

      {/* Система — обычные карточки (без модификатора) */}
      <div className="section">
        <h2 className="section-title">🔧 Система</h2>
        <div className="cards-grid">
          <div className="card clickable" onClick={() => openDetail('pressure')}>
            <div className="card-icon">🎯</div>
            <div className="card-title">Давление</div>
            <div className="card-value">
              {getValue('pressure') !== '—' ? `${getValue('pressure')} бар` : '—'}
            </div>
          </div>

          <div className="card clickable" onClick={() => openDetail('flow_rate')}>
            <div className="card-icon">💧</div>
            <div className="card-title">Расход</div>
            <div className="card-value">
              {getValue('flow_rate') !== '—' ? `${getValue('flow_rate')} л/мин` : '—'}
            </div>
          </div>
        </div>
      </div>

      {/* Инструменты — большая карточка (size-lg) */}
      <div className="section">
        <h2 className="section-title">📊 Инструменты</h2>
        <div className="cards-grid">
          <div className="card size-lg clickable" onClick={() => navigate('/compare')}>
            <div className="card-icon">📊</div>
            <div className="card-title">Сравнить параметры</div>
            <div className="card-value small">Графики нескольких параметров</div>
          </div>
        </div>
      </div>
    </div>
  );
}

export default Dashboard;