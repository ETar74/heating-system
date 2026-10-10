import { useState, useEffect } from 'react';
import api from '../api';
import './Settings.css';
import { canEditSettings } from '../utils/permissions';

function Settings() {
  const [settings, setSettings] = useState([]);
  const [loading, setLoading] = useState(true);
  const [message, setMessage] = useState({ type: '', text: '' });
  const [editMode, setEditMode] = useState({});
  const [originalValues, setOriginalValues] = useState({});
  const [deviceOnline, setDeviceOnline] = useState(true);
  const [lastSync, setLastSync] = useState(null);

  const user = JSON.parse(localStorage.getItem('user') || '{}');
  const canEdit = canEditSettings(user.role);

  useEffect(() => {
    loadSettings();
    loadDeviceStatus();

    //    10 
    const statusInterval = setInterval(loadDeviceStatus, 10000);

    return () => clearInterval(statusInterval);
  }, []);

  const loadDeviceStatus = async () => {
    try {
      const response = await api.get('/settings/can-edit');
      setDeviceOnline(response.data.canEdit);
      setLastSync(response.data.lastSync);
    } catch (error) {
      console.error('Error loading device status:', error);
      setDeviceOnline(false);
    }
  };

  const loadSettings = async () => {
    try {
      const response = await api.get('/settings');
      setSettings(response.data);
      const orig = {};
      response.data.forEach(s => { orig[s.key] = s.value; });
      setOriginalValues(orig);
    } catch (error) {
      console.error('Error loading settings:', error);
      showMessage('error', '  ');
    } finally {
      setLoading(false);
    }
  };

  const showMessage = (type, text) => {
    setMessage({ type, text });
    setTimeout(() => setMessage({ type: '', text: '' }), 3000);
  };

  const getParamValue = (key) => {
    const param = settings.find(s => s.key === key);
    return param ? param.value : '';
  };

  const startEdit = (key) => {
    if (!deviceOnline) {
      showMessage('error', '  :  ESP32 ');
      return;
    }
    setEditMode(prev => ({ ...prev, [key]: true }));
  };

  const cancelEdit = (key) => {
    setSettings(prev => prev.map(s =>
      s.key === key ? { ...s, value: originalValues[key] } : s
    ));
    setEditMode(prev => ({ ...prev, [key]: false }));
  };

  const saveParam = async (key, value) => {
    if (!deviceOnline) {
      showMessage('error', '  :  ESP32 ');
      return;
    }
    try {
      await api.put(`/settings/${key}`, { value });
      showMessage('success', '');
      setEditMode(prev => ({ ...prev, [key]: false }));
      setOriginalValues(prev => ({ ...prev, [key]: value }));
    } catch (error) {
      console.error('Error saving setting:', error);
      showMessage('error', ' ');
    }
  };

  const markAsEdited = (key, value) => {
    setSettings(prev => prev.map(s =>
      s.key === key ? { ...s, value: value } : s
    ));
  };

  const groups = [
  {
    name: '🏠 Помещение',
    description: 'Контроль температуры в доме. Целевая температура рассчитывается как среднее значение порога включения и выключения',
    params: [
      { key: 'room_temp_threshold_on', label: 'Порог включения', unit: '°C', type: 'number', step: 0.5 },
      { key: 'room_temp_threshold_off', label: 'Порог выключения', unit: '°C', type: 'number', step: 0.5 },
    ]
  },
  {
    name: ' Котёл',
    description: 'Защита от перегрева (охлаждение). Целевая температура рассчитывается как среднее значение порога включения и выключения',
    params: [
      { key: 'boiler_temp_threshold_on', label: 'Порог включения', unit: '°C', type: 'number', step: 1 },
      { key: 'boiler_temp_threshold_off', label: 'Порог выключения', unit: '°C', type: 'number', step: 1 },
    ]
  },
  {
    name: '💧 Тёплые полы',
    description: 'Температура тёплых полов. Целевая температура рассчитывается как среднее значение порога включения и выключения',
    params: [
      { key: 'floor_temp_threshold_on', label: 'Порог включения', unit: '°C', type: 'number', step: 1 },
      { key: 'floor_temp_threshold_off', label: 'Порог выключения', unit: '°C', type: 'number', step: 1 },
    ]
  },
  {
    name: '🔋 Теплоаккумулятор (электрокотёл)',
    description: 'Температура воды в теплоаккумуляторе. Целевая температура рассчитывается как среднее значение порога включения и выключения',
    params: [
      { key: 'accumulator_temp_threshold_on', label: 'Порог включения', unit: '°C', type: 'number', step: 1 },
      { key: 'accumulator_temp_threshold_off', label: 'Порог выключения', unit: '°C', type: 'number', step: 1 },
    ]
  },
  {
    name: '🌙 Режимы',
    description: 'Ночной и дневной режимы',
    params: [
      { key: 'night_start', label: 'Ночной режим начало', unit: '', type: 'time' },
      { key: 'night_end', label: 'Ночной режим конец', unit: '', type: 'time' },
    ]
  }
];

  if (loading) {
    return <div className="settings-page">...</div>;
  }

  return (
    <div className="settings-page">
      <div className="settings-header">
        <h1>Настройки</h1>
        <div className={`device-status-badge ${deviceOnline ? 'online' : 'offline'}`}>
          {deviceOnline ? 'ESP32 онлайн' : 'ESP32 оффлайн'}
        </div>
      </div>

      {/*     */}
      {!deviceOnline && (
        <div className="settings-lock-banner">
          🔒 <strong>Настройки заблокированы</strong>
          <div className="lock-banner-text">
             ESP32 .
            {lastSync
              ? `  : ${new Date(lastSync).toLocaleString('ru-RU')}`
              : '   .'}
          </div>
          <div className="lock-banner-hint">
                   .
          </div>
        </div>
      )}

      {message.text && (
        <div className={`message ${message.type}`}>
          {message.text}
        </div>
      )}

      <div className="settings-groups">
        {groups.map((group, groupIndex) => (
          <div key={groupIndex} className="settings-group">
            <div className="group-header">
              <h2>{group.name}</h2>
              <p className="group-description">{group.description}</p>
            </div>

            <table className="settings-table">
              <thead>
                <tr>
                  <th></th>
                  <th></th>
                  <th></th>
                </tr>
              </thead>
              <tbody>
                {group.params.map((param) => {
                  const value = getParamValue(param.key);
                  const isEditing = editMode[param.key];

                  return (
                    <tr key={param.key}>
                      <td className="param-label">
                        <div className="param-name">{param.label}</div>
                      </td>

                      <td className="param-value">
                        {isEditing && canEdit && deviceOnline ? (
                          <div className="param-edit-wrapper">
                            <input
                              type={param.type === 'time' ? 'time' : 'number'}
                              value={value}
                              step={param.step || 'any'}
                              onChange={(e) => markAsEdited(param.key, e.target.value)}
                              className="param-input"
                            />
                            {param.unit && <span className="param-unit-inline">{param.unit}</span>}
                          </div>
                        ) : (
                          <span className="param-display">
                            {value || ''}{param.unit ? ` ${param.unit}` : ''}
                          </span>
                        )}
                      </td>

                      <td className="param-actions">
                        {canEdit && deviceOnline ? (
                          isEditing ? (
                            <div className="action-buttons">
                              <button
                                className="btn-icon btn-save"
                                onClick={() => saveParam(param.key, value)}
                                title=""
                              >
                                💾                              </button>
                              <button
                                className="btn-icon btn-cancel"
                                onClick={() => cancelEdit(param.key)}
                                title=""
                              >
                                ❌                              </button>
                            </div>
                          ) : (
                            <button
                              className="btn-icon btn-edit"
                              onClick={() => startEdit(param.key)}
                              title=""
                            >
                              ✏️                            </button>
                          )
                        ) : !deviceOnline ? (
                          <span className="locked-indicator" title=":  ">
                            🔒                          </span>
                        ) : (
                          <span style={{ color: '#95a5a6', fontSize: '0.8rem' }}>
                             
                          </span>
                        )}
                      </td>
                    </tr>
                  );
                })}
              </tbody>
            </table>
          </div>
        ))}
      </div>
    </div>
  );
}

export default Settings;





