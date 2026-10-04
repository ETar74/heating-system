import { useState, useEffect, useRef } from 'react';
import { useNavigate } from 'react-router-dom';
import { telemetry, commands } from '../api';
import api, { WS_URL } from '../api';
import './Dashboard.css';
import TempWidget from '../components/TempWidget';
import { canControlDevices } from '../utils/permissions';

function Dashboard() {
  const navigate = useNavigate();
  const [data, setData] = useState({});
  const [device, setDevice] = useState({ online: false, name: 'Не настроено' });
  const [loading, setLoading] = useState(true);
  const [wsStatus, setWsStatus] = useState('disconnected');
  const [pending, setPending] = useState({}); // { [command]: true } — команды в очереди

  const wsRef = useRef(null);
  const reconnectTimer = useRef(null);

  const user = JSON.parse(localStorage.getItem('user') || '{}');
  const canControl = canControlDevices(user.role);

  useEffect(() => {
    loadData();
    loadDeviceStatus();
    connectWebSocket();

    // Резервное поллинговое обновление раз в минуту (основной источник — WebSocket)
    const refreshInterval = setInterval(() => {
      loadData();
      loadDeviceStatus();
    }, 60000);

    return () => {
      clearInterval(refreshInterval);
      // Корректно закрываем сокет и отменяем реконнект при размонтировании
      if (reconnectTimer.current) clearTimeout(reconnectTimer.current);
      reconnectTimer.current = null;
      if (wsRef.current) {
        wsRef.current.onclose = null;
        wsRef.current.close();
        wsRef.current = null;
      }
    };
    // eslint-disable-next-line react-hooks/exhaustive-deps
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
    const token = localStorage.getItem('token');
    const ws = new WebSocket(`${WS_URL}/?token=${encodeURIComponent(token || '')}`);
    wsRef.current = ws;

    ws.onopen = () => setWsStatus('connected');

    ws.onmessage = (event) => {
      try {
        const msg = JSON.parse(event.data);

        if (msg.type === 'telemetry_updated' && msg.data) {
          setData(prev => ({ ...prev, ...msg.data }));
        }

        if (msg.type === 'device_sync') {
          // Обновлённая телеметрия + статусы от устройства
          if (msg.telemetry) {
            const now = new Date().toISOString();
            setData(prev => {
              const next = { ...prev };
              for (const [k, v] of Object.entries(msg.telemetry)) {
                next[k] = { value: v, timestamp: now };
              }
              return next;
            });
          }
          loadDeviceStatus();
          setPending({});
        }

        if (msg.type === 'device_status_updated') {
          loadDeviceStatus();
          setPending({});
        }
      } catch (err) {
        console.error('WS parse error:', err);
      }
    };

    ws.onclose = () => {
      setWsStatus('disconnected');
      // Не подключаемся повторно, если компонент уже размонтирован
      if (wsRef.current === ws) {
        reconnectTimer.current = setTimeout(connectWebSocket, 5000);
      }
    };

    ws.onerror = () => {
      ws.close();
    };
  };

  const sendCommand = async (command) => {
    try {
      setPending(prev => ({ ...prev, [command]: true }));
      await commands.send(command);
    } catch (error) {
      setPending(prev => {
        const next = { ...prev };
        delete next[command];
        return next;
      });
    }
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

  // Получить фазы
  const getPhases = () => {
    const phases = data.phases?.value;
    if (!phases) return { L1: false, L2: false, L3: false };
    return {
      L1: phases.L1 || false,
      L2: phases.L2 || false,
      L3: phases.L3 || false
    };
  };

  const phases = getPhases();
  const phasesOk = phases.L1 && phases.L2 && phases.L3;
  const phasesLost = [
    !phases.L1 && 'L1',
    !phases.L2 && 'L2',
    !phases.L3 && 'L3'
  ].filter(Boolean);

  // Объединить все предупреждения
  const allWarnings = [];
  if (faultySensors.length > 0) {
    allWarnings.push(`Неисправны датчики: ${faultySensors.join(', ')}`);
  }
  if (phasesLost.length > 0) {
    allWarnings.push(`Потеря фаз: ${phasesLost.join(', ')}`);
  }

  const openDetail = (paramKey) => {
    navigate(`/parameter/${paramKey}`);
  };

  if (loading) {
    return <div className="loading">Загрузка...</div>;
  }

  // Заглушка при полном отсутствии связи с ESP32
  const noDeviceData = !device.online && !device.lastSeen;
  
  if (noDeviceData) {
    return (
      <div className="dashboard">
        <div className="dashboard-header">
          <h1>Главная панель</h1>
        </div>
        <div className="device-offline-stub">
          <div className="stub-icon">📡</div>
          <h2>Устройство не подключено</h2>
          <p>ESP32 ещё не зарегистрирован в системе.</p>
          <p className="stub-hint">
            После первого подключения устройства здесь появятся данные телеметрии.
          </p>
        </div>
      </div>
    );
  }

  // Подготовка списка устройств для отображения (+ команды управления)
  const deviceStatus = device.deviceStatus || {};
  const deviceList = [
    { key: 'boiler', label: '🔥 Насос ТТ котёла', status: deviceStatus.boiler, onCmd: 'boiler_on', offCmd: 'boiler_off' },
    { key: 'elec_boiler', label: '⚡ Электрокотёл', status: deviceStatus.elec_boiler, onCmd: 'elec_boiler_on', offCmd: 'elec_boiler_off' },
    { key: 'floor_pump', label: '💧 Насос тёплого пола', status: deviceStatus.floor_pump, onCmd: 'floor_pump_on', offCmd: 'floor_pump_off' },
    { key: 'radiator_pump', label: '💧 Насос радиаторов', status: deviceStatus.radiator_pump, onCmd: 'radiator_pump_on', offCmd: 'radiator_pump_off' }
  ];

  return (
    <div className="dashboard">
      {/* Шапка */}
      <div className="dashboard-header">
        <h1>Главная панель</h1>
        <div className={`ws-status ${wsStatus}`}>
          {wsStatus === 'connected' ? '🟢 Сервер: онлайн' : '🔴 Сервер: офлайн'}
        </div>
      </div>

      
      {/* ⚠️ Общий баннер всех предупреждений */}
      {allWarnings.length > 0 && (
        <div className="warning-banner">
          ⚠️ <strong>Внимание:</strong>
          <ul className="warning-list">
            {allWarnings.map((warning, idx) => (
              <li key={idx}>{warning}</li>
            ))}
          </ul>
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
            <div className="card-icon"></div>
            <div className="card-title">Последняя связь</div>
            <div className="card-value small">
              {formatLastSeen(device.lastSeen)}
            </div>
          </div>

          {/* ⚡ Карточка фаз — всегда показывается */}
          <div className={`card size-sm ${!phasesOk ? 'card-phases-error' : ''}`}>
            <div className="card-icon">⚡</div>
            <div className="card-title">Фазы</div>
            <div className="phases-indicators">
              <span className={`phase-indicator ${phases.L1 ? 'phase-ok' : 'phase-lost'}`}>
                L1
              </span>
              <span className={`phase-indicator ${phases.L2 ? 'phase-ok' : 'phase-lost'}`}>
                L2
              </span>
              <span className={`phase-indicator ${phases.L3 ? 'phase-ok' : 'phase-lost'}`}>
                L3
              </span>
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
              accentColor="#4facfe"
            />
          </div>

          <div onClick={() => openDetail('boiler_temp')}>
            <TempWidget
              paramKey="boiler_temp"
              title="Котёл"
              icon="🔥"
              unit="°C"
              accentColor="#f5576c"
            />
          </div>

          <div onClick={() => openDetail('floor_temp')}>
            <TempWidget
              paramKey="floor_temp"
              title="Тёплые полы"
              icon=""
              unit="°C"
              accentColor="#43e97b"
            />
          </div>

          <div onClick={() => openDetail('room_temp')}>
            <TempWidget
              paramKey="room_temp"
              title="Помещение"
              icon=""
              unit="°C"
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

      {/* Режим работы — статусы устройств */}
      <div className="section">
        <h2 className="section-title">⚙️ Режим работы</h2>
        <div className="cards-grid">
          <div className="card size-lg">
            <div className="card-title">Состояние устройств</div>
            <div className="device-status-list">
              {deviceList.map(d => {
                const isOn = d.status === 'on';
                const cmd = isOn ? d.offCmd : d.onCmd;
                return (
                  <div key={d.key} className="device-status-item">
                    <span className="device-name">{d.label}</span>
                    <span className={`device-badge ${isOn ? 'on' : 'off'}`}>
                      {isOn ? '🟢 ВКЛ' : '🔴 ВЫКЛ'}
                    </span>
                    {canControl && (
                      <button
                        className={`device-toggle-btn ${isOn ? 'turn-off' : 'turn-on'}`}
                        disabled={!!pending[cmd]}
                        onClick={() => sendCommand(cmd)}
                        title={isOn ? 'Выключить' : 'Включить'}
                      >
                        {pending[cmd] ? '⏳' : (isOn ? 'Выкл' : 'Вкл')}
                      </button>
                    )}
                  </div>
                );
              })}
            </div>
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