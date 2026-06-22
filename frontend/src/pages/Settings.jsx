import { useState, useEffect } from 'react';
import api from '../api';
import './Settings.css';

function Settings() {
  const [settings, setSettings] = useState([]);
  const [loading, setLoading] = useState(true);
  const [message, setMessage] = useState({ type: '', text: '' });
  const [editMode, setEditMode] = useState({});
  const [originalValues, setOriginalValues] = useState({});

  useEffect(() => {
    loadSettings();
  }, []);

  const loadSettings = async () => {
    try {
      const response = await api.get('/settings');
      setSettings(response.data);
      const orig = {};
      response.data.forEach(s => { orig[s.key] = s.value; });
      setOriginalValues(orig);
    } catch (error) {
      console.error('Error loading settings:', error);
      showMessage('error', 'Ошибка загрузки настроек');
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
    setEditMode(prev => ({ ...prev, [key]: true }));
  };

  const cancelEdit = (key) => {
    setSettings(prev => prev.map(s => 
      s.key === key ? { ...s, value: originalValues[key] } : s
    ));
    setEditMode(prev => ({ ...prev, [key]: false }));
  };

  const saveParam = async (key, value) => {
    try {
      await api.put(`/settings/${key}`, { value });
      showMessage('success', 'Сохранено');
      setEditMode(prev => ({ ...prev, [key]: false }));
      setOriginalValues(prev => ({ ...prev, [key]: value }));
    } catch (error) {
      console.error('Error saving setting:', error);
      showMessage('error', 'Ошибка сохранения');
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
      description: 'Контроль температуры в доме',
      params: [
        { key: 'room_temp_target', label: 'Целевая температура', unit: '°C', type: 'number', step: 0.5 },
        { key: 'room_temp_threshold_on', label: 'Порог включения', unit: '°C', type: 'number', step: 0.5 },
        { key: 'room_temp_threshold_off', label: 'Порог выключения', unit: '°C', type: 'number', step: 0.5 },
        { key: 'room_temp_hysteresis', label: 'Гистерезис', unit: '°C', type: 'number', step: 0.1 },
      ]
    },
    {
      name: '🔥 Котёл',
      description: 'Защита от перегрева (охлаждение)',
      params: [
        { key: 'boiler_temp_target', label: 'Целевая температура', unit: '°C', type: 'number', step: 1 },
        { key: 'boiler_temp_threshold_on', label: 'Порог включения', unit: '°C', type: 'number', step: 1 },
        { key: 'boiler_temp_threshold_off', label: 'Порог выключения', unit: '°C', type: 'number', step: 1 },
        { key: 'boiler_temp_hysteresis', label: 'Гистерезис', unit: '°C', type: 'number', step: 1 },
      ]
    },
    {
      name: '💧 Тёплые полы',
      description: 'Температура тёплых полов',
      params: [
        { key: 'floor_temp_target', label: 'Целевая температура', unit: '°C', type: 'number', step: 1 },
        { key: 'floor_temp_threshold_on', label: 'Порог включения', unit: '°C', type: 'number', step: 1 },
        { key: 'floor_temp_threshold_off', label: 'Порог выключения', unit: '°C', type: 'number', step: 1 },
        { key: 'floor_temp_hysteresis', label: 'Гистерезис', unit: '°C', type: 'number', step: 0.5 },
      ]
    },
    {
      name: '🔋 Теплоаккумулятор (электрокотёл)',
      description: 'Температура воды в теплоаккумуляторе',
      params: [
        { key: 'accumulator_temp_target', label: 'Целевая температура', unit: '°C', type: 'number', step: 1 },
        { key: 'accumulator_temp_threshold_on', label: 'Порог включения', unit: '°C', type: 'number', step: 1 },
        { key: 'accumulator_temp_threshold_off', label: 'Порог выключения', unit: '°C', type: 'number', step: 1 },
        { key: 'accumulator_temp_hysteresis', label: 'Гистерезис', unit: '°C', type: 'number', step: 1 },
      ]
    },
    {
      name: '🌙 Режимы',
      description: 'Ночной и дневной режимы',
      params: [
        { key: 'night_start', label: 'Ночной режим начало', unit: '', type: 'time' },
        { key: 'night_end', label: 'Ночной режим конец', unit: '', type: 'time' },
      ]
    },
  ];

  if (loading) {
    return <div className="settings-page">Загрузка...</div>;
  }

  return (
    <div className="settings-page">
      <div className="settings-header">
        <h1>⚙️ Настройки системы</h1>
      </div>

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
                  <th>Параметр</th>
                  <th>Значение</th>
                  <th>Действия</th>
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
                        {isEditing ? (
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
                            {value || '—'}{param.unit ? ` ${param.unit}` : ''}
                          </span>
                        )}
                      </td>
                      <td className="param-actions">
                        {isEditing ? (
                          <div className="action-buttons">
                            <button 
                              className="btn-icon btn-save"
                              onClick={() => saveParam(param.key, value)}
                              title="Сохранить"
                            >
                              💾
                            </button>
                            <button 
                              className="btn-icon btn-cancel"
                              onClick={() => cancelEdit(param.key)}
                              title="Отменить"
                            >
                              ❌
                            </button>
                          </div>
                        ) : (
                          <button 
                            className="btn-icon btn-edit"
                            onClick={() => startEdit(param.key)}
                            title="Редактировать"
                          >
                            ✏️
                          </button>
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