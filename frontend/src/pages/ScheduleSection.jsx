// import { useState, useEffect } from 'react';
// import api from '../api';

// const DEVICE_NAMES = [
//     { id: 0, name: 'Котел ТТ' },
//     { id: 1, name: 'Электрокотел' },
//     { id: 2, name: 'Теплые полы' },
//     { id: 3, name: 'Радиатор' }
// ];

// const STORAGE_KEY = 'schedule_cache_v1';

// function ScheduleSection({ deviceOnline, showMessage }) {
//     const [sd, setSd] = useState({});
//     const [dev, setDev] = useState(0);
//     const [ld, setLd] = useState(false);
//     const [sav, setSav] = useState(false);
//     const [se, setSe] = useState(() => 
//         Array.from({length:4}, () => ({enabled:false, startH:'', startM:'', endH:'', endM:''}))
//     );
//     const [dirty, setDirty] = useState(false);
    
//     // 🆕 НОВОЕ: Локальный state для inline-сообщения "Расписание сохранено"
//     const [saveMsg, setSaveMsg] = useState(null);

//     // === 1. ЗАГРУЗКА ТОЛЬКО ПРИ МОНТАЖЕ КОМПОНЕНТА ===
//     useEffect(() => { 
//         loadSchedule(); 
//     }, []);

//     async function loadSchedule() {
//         try {
//             setLd(true);
//             console.log('[1] Запрос расписания с сервера...');
//             const r = await api.get('/device/schedule');
//             const arr = r.data.schedule || [];
//             const obj = {};
//             arr.forEach(s => obj[s.deviceId] = s);
            
//             localStorage.setItem(STORAGE_KEY, JSON.stringify(obj));
            
//             setSd(obj);
//             console.log('[2] Сервер ответил, устройств в кэше:', Object.keys(obj).length);
            
//             if (arr.length === 0) {
//                 await api.post('/device/schedule/request');
//                 showMessage('info', 'Запросил расписание с ESP32...');
//             }
//         } catch (error) {
//             console.error('[X] Ошибка загрузки:', error);
//             const cached = localStorage.getItem(STORAGE_KEY);
//             if (cached) {
//                 setSd(JSON.parse(cached));
//                 showMessage('warning', 'Показаны данные из кэша (сервер недоступен)');
//             } else {
//                 showMessage('error', 'Не удалось загрузить расписание');
//             }
//         } finally {
//             setLd(false);
//         }
//     }

//     // === 2. ОБНОВЛЕНИЕ ПОЛЕЙ ФОРМЫ ПРИ СМЕНЕ УСТРОЙСТВА ИЛИ ДАННЫХ ===
//     useEffect(() => {
//         if (dirty) {
//             console.log('[3] Пропуск обновления формы: есть несохраненные изменения (dirty=true)');
//             return;
//         }
        
//         const dd = sd[dev];
//         if (dd && dd.slots) {
//             console.log('[3] Обновление формы для устройства', dev);
//             setSe(dd.slots.map(s => ({
//                 enabled: Boolean(s.enabled),
//                 startH: String(s.startH).padStart(2, '0'),
//                 startM: String(s.startM).padStart(2, '0'),
//                 endH: String(s.endH).padStart(2, '0'),
//                 endM: String(s.endM).padStart(2, '0')
//             })));
//         }
//     }, [dev, sd, dirty]);

//     // === СЛУШАТЕЛЬ WEBSOCKET ОБНОВЛЕНИЙ ===
//     useEffect(() => {
//         const handleWsUpdate = (event) => {
//             const { deviceId, slots } = event.detail;
//             console.log(`[Schedule] 🚀 Received WebSocket update for device ${deviceId}`);
            
//             const updatedSd = { ...sd, [deviceId]: { deviceId, slots } };
//             setSd(updatedSd);
//             localStorage.setItem(STORAGE_KEY, JSON.stringify(updatedSd));
            
//             // 🆕 ИЗМЕНЕНО: вместо showMessage используем локальный state
//             setSaveMsg('Расписание обновлено в реальном времени!');
//         };

//         window.addEventListener('ws:schedule:updated', handleWsUpdate);
        
//         return () => {
//             window.removeEventListener('ws:schedule:updated', handleWsUpdate);
//         };
//     }, [sd]); // 🆕 Убран showMessage из зависимостей

//     // 🆕 НОВОЕ: Автоскрытие сообщения через 5 секунд
//     useEffect(() => {
//         if (saveMsg) {
//             const timer = setTimeout(() => {
//                 setSaveMsg(null);
//             }, 5000);
//             return () => clearTimeout(timer);
//         }
//     }, [saveMsg]);

//     // === 3. СОХРАНЕНИЕ (ИСПРАВЛЕННАЯ ВЕРСИЯ) ===
//     async function saveSchedule() {
//         if (!deviceOnline) {
//             showMessage('error', 'ESP32 недоступен.');
//             return;
//         }
        
//         try {
//             setSav(true);
            
//             const slots = se.map(s => ({
//                 enabled: s.enabled,
//                 startH: parseInt(s.startH) || 0,
//                 startM: parseInt(s.startM) || 0,
//                 endH: parseInt(s.endH) || 0,
//                 endM: parseInt(s.endM) || 0
//             }));

//             const payload = { deviceId: dev, slots };
//             console.log('[Schedule] Saving:', payload);
            
//             await api.post('/device/schedule/save', payload);
            
//             setSd(prev => ({ ...prev, [dev]: { deviceId: dev, slots } }));
            
//             const updatedSd = { ...sd, [dev]: { deviceId: dev, slots } };
//             localStorage.setItem(STORAGE_KEY, JSON.stringify(updatedSd));
            
//             setDirty(false);
            
//             // 🆕 ИЗМЕНЕНО: устанавливаем локальный state вместо showMessage
//             setSaveMsg('Расписание сохранено! ESP32 применит в течение 5 сек.');
//             console.log('[Schedule] Save successful, cached to localStorage');
            
//         } catch (error) {
//             console.error('[Schedule] Save error:', error);
//             showMessage('error', error.response?.data?.error || 'Ошибка сохранения');
//         } finally {
//             setSav(false);
//         }
//     }

//     // === 4. ОБРАБОТЧИКИ ВВОДА ===
//     const hc = (i, f, v) => {
//         setSe(p => p.map((s, x) => x === i ? { ...s, [f]: v } : s));
//         setDirty(true);
//         setSaveMsg(null); // 🆕 НОВОЕ: скрываем сообщение при изменении формы
//     };
    
//     const ht = (i, c) => {
//         setSe(p => p.map((s, x) => x === i ? { ...s, enabled: c } : s));
//         setDirty(true);
//         setSaveMsg(null); // 🆕 НОВОЕ: скрываем сообщение при изменении формы
//     };

//     const handleDeviceChange = (e) => {
//         const newDev = parseInt(e.target.value);
//         if (dirty) {
//             if (!window.confirm('Есть несохраненные изменения. Переключить устройство? Данные будут потеряны.')) return;
//         }
//         setDev(newDev);
//         setDirty(false);
//         setSaveMsg(null); // 🆕 НОВОЕ: скрываем сообщение при смене устройства
//     };

//     // === 5. РЕНДЕР ===
//     const rsr = (idx) => {
//         const s = se[idx];
//         const hv = s.startH || s.startM || s.endH || s.endM;
//         return (
//             <tr key={idx} className={hv ? '' : 'schedule-row-empty'}>
//                 <td className='col-slot'>Слот {idx + 1}</td>
//                 <td className='col-toggle'>
//                     <label className='slot-toggle-label'>
//                         <input type='checkbox' checked={s.enabled} onChange={(e) => ht(idx, e.target.checked)} disabled={!deviceOnline} />
//                         <span>{s.enabled ? 'Вкл' : 'Выкл'}</span>
//                     </label>
//                 </td>
//                 <td className='col-from'>
//                     <div className='time-input-group'>
//                         <input type='number' min='0' max='23' placeholder='ЧЧ' value={s.startH} onChange={(e) => hc(idx, 'startH', e.target.value)} disabled={!deviceOnline} className='time-input time-hour' />
//                         <span>:</span>
//                         <input type='number' min='0' max='59' placeholder='ММ' value={s.startM} onChange={(e) => hc(idx, 'startM', e.target.value)} disabled={!deviceOnline} className='time-input time-minute' />
//                     </div>
//                 </td>
//                 <td className='col-to'>
//                     <div className='time-input-group'>
//                         <input type='number' min='0' max='23' placeholder='ЧЧ' value={s.endH} onChange={(e) => hc(idx, 'endH', e.target.value)} disabled={!deviceOnline} className='time-input time-hour' />
//                         <span>:</span>
//                         <input type='number' min='0' max='59' placeholder='ММ' value={s.endM} onChange={(e) => hc(idx, 'endM', e.target.value)} disabled={!deviceOnline} className='time-input time-minute' />
//                     </div>
//                 </td>
//             </tr>
//         );
//     };

//     return (
//         <div className='settings-schedule-section'>
//             {/* 🆕 ИЗМЕНЕННЫЙ ЗАГОЛОВОК: два inline-сообщения в одной строке */}
//             <h2 style={{margin: '0 0 1rem 0', color: '#2c3e50', fontSize: '1.25rem'}}>
//                 Управление расписанием
                
//                 {/* Красное сообщение "Несохраненные изменения" */}
//                 {dirty && (
//                     <span style={{
//                         color: '#e74c3c', 
//                         fontSize: '0.8rem', 
//                         marginLeft: '0.5rem',
//                         fontWeight: 'normal'
//                     }}> 
//                         ● Несохраненные изменения
//                     </span>
//                 )}
                
//                 {/* 🆕 НОВОЕ: Зелёное сообщение "Расписание сохранено" */}
//                 {saveMsg && !dirty && (
//                     <span style={{
//                         color: '#27ae60', 
//                         fontSize: '0.8rem', 
//                         marginLeft: '0.5rem',
//                         fontWeight: 'normal'
//                     }}>
//                         ● {saveMsg}
//                     </span>
//                 )}
//             </h2>
            
//             {ld && Object.keys(sd).length === 0 ? (
//                 <div className='schedule-loading'>Загружаю с сервера...</div>
//             ) : (
//                 <>
//                     <div className='schedule-device-selector'>
//                         <select value={dev} onChange={handleDeviceChange} className='schedule-device-select'>
//                             {DEVICE_NAMES.map(d => <option key={d.id} value={d.id}>{d.name}</option>)}
//                         </select>
//                     </div>
//                     <table className='schedule-table'>
//                         <thead>
//                             <tr>
//                                 <th className='col-slot'>Слот</th>
//                                 <th className='col-toggle'>Вкл/Выкл</th>
//                                 <th className='col-from'>Часы от</th>
//                                 <th className='col-to'>Часы до</th>
//                             </tr>
//                         </thead>
//                         <tbody>{Array.from({length: 4}, (_, i) => rsr(i))}</tbody>
//                     </table>
//                     <button onClick={saveSchedule} disabled={!deviceOnline || sav} className='schedule-save-btn'>
//                         {sav ? 'Сохранение...' : 'Сохранить все'}
//                     </button>
//                     {!deviceOnline && <div className='schedule-offline-warning'>ESP32 недоступен.</div>}
//                 </>
//             )}
//         </div>
//     );
// }

import { useState, useEffect } from 'react';
import api from '../api';

const DEVICE_NAMES = [
    { id: 0, name: 'Котел ТТ' },
    { id: 1, name: 'Электрокотел' },
    { id: 2, name: 'Теплые полы' },
    { id: 3, name: 'Радиатор' }
];

const STORAGE_KEY = 'schedule_cache_v1';

const LIMITS = { startH: 23, startM: 59, endH: 23, endM: 59 };
const FIELD_NAMES = {
    startH: 'часы нач.',
    startM: 'мин. нач.',
    endH: 'часы кон.',
    endM: 'мин. кон.'
};

function ScheduleSection({ deviceOnline, showMessage }) {
    const [sd, setSd] = useState({});
    const [dev, setDev] = useState(0);
    const [ld, setLd] = useState(false);
    const [sav, setSav] = useState(false);
    const [se, setSe] = useState(() =>
        Array.from({ length: 4 }, () => ({ enabled: false, startH: '', startM: '', endH: '', endM: '' }))
    );
    const [dirty, setDirty] = useState(false);

    const [msg, setMsg] = useState(null);

    useEffect(() => { loadSchedule(); }, []);

    async function loadSchedule() {
        try {
            setLd(true);
            console.log('[1] Запрос расписания с сервера...');
            const r = await api.get('/device/schedule');
            const arr = r.data.schedule || [];
            const obj = {};
            arr.forEach(s => obj[s.deviceId] = s);

            localStorage.setItem(STORAGE_KEY, JSON.stringify(obj));
            setSd(obj);
            console.log('[2] Сервер ответил, устройств в кэше:', Object.keys(obj).length);

            if (arr.length === 0) {
                await api.post('/device/schedule/request');
                showMessage('info', 'Запросил расписание с ESP32...');
            }
        } catch (error) {
            console.error('[X] Ошибка загрузки:', error);
            const cached = localStorage.getItem(STORAGE_KEY);
            if (cached) {
                setSd(JSON.parse(cached));
                showMessage('warning', 'Показаны данные из кэша (сервер недоступен)');
            } else {
                showMessage('error', 'Не удалось загрузить расписание');
            }
        } finally {
            setLd(false);
        }
    }

    useEffect(() => {
        if (dirty) {
            console.log('[3] Пропуск: есть несохраненные изменения');
            return;
        }
        const dd = sd[dev];
        if (dd && dd.slots) {
            console.log('[3] Обновление формы для устройства', dev);
            setSe(dd.slots.map(s => ({
                enabled: Boolean(s.enabled),
                startH: String(s.startH ?? '').padStart(2, '0'),
                startM: String(s.startM ?? '').padStart(2, '0'),
                endH: String(s.endH ?? '').padStart(2, '0'),
                endM: String(s.endM ?? '').padStart(2, '0')
            })));
        }
    }, [dev, sd, dirty]);

    useEffect(() => {
        const handleWsUpdate = (event) => {
            const { deviceId, slots } = event.detail;
            console.log(`[Schedule] 🚀 WS update for device ${deviceId}`);
            const updated = { ...sd, [deviceId]: { deviceId, slots } };
            setSd(updated);
            localStorage.setItem(STORAGE_KEY, JSON.stringify(updated));
            setMsg({ type: 'ok', text: 'Обновлено в реальном времени' });
        };
        window.addEventListener('ws:schedule:updated', handleWsUpdate);
        return () => window.removeEventListener('ws:schedule:updated', handleWsUpdate);
    }, [sd]);

    useEffect(() => {
        if (!msg) return;
        const t = setTimeout(() => setMsg(null), msg.type === 'err' ? 8000 : 5000);
        return () => clearTimeout(t);
    }, [msg]);

    const sanitize = (v) => String(v).replace(/\D/g, '').slice(0, 2);

    const blockNonDigit = (e) => {
        if (e.key.length === 1 && !/[0-9]/.test(e.key)) e.preventDefault();
    };

    const isBad = (field, v) => {
        if (v === '') return false;
        const n = parseInt(v, 10);
        return isNaN(n) || n < 0 || n > LIMITS[field];
    };

    const clampField = (idx, field) => {
        setSe(p => p.map((s, x) => {
            if (x !== idx || s[field] === '') return s;
            let n = parseInt(s[field], 10);
            if (isNaN(n)) n = 0;
            if (n < 0) n = 0;
            if (n > LIMITS[field]) n = LIMITS[field];
            return { ...s, [field]: String(n).padStart(2, '0') };
        }));
    };

    function validateSlots() {
        const errs = [];
        se.forEach((s, i) => {
            const filled = s.startH !== '' || s.startM !== '' || s.endH !== '' || s.endM !== '';
            const full = s.startH !== '' && s.startM !== '' && s.endH !== '' && s.endM !== '';

            if (!filled) {
                if (s.enabled) errs.push(`Слот ${i + 1}: время не указано`);
                return;
            }
            if (!full) { errs.push(`Слот ${i + 1}: заполните все 4 поля`); return; }

            Object.keys(LIMITS).forEach(f => {
                const n = parseInt(s[f], 10);
                if (isNaN(n) || n < 0 || n > LIMITS[f]) {
                    errs.push(`Слот ${i + 1}: ${FIELD_NAMES[f]} ≤ ${LIMITS[f]}`);
                }
            });
        });
        return errs;
    }

    async function saveSchedule() {
        if (!deviceOnline) { showMessage('error', 'ESP32 недоступен.'); return; }

        const errs = validateSlots();
        if (errs.length) {
            setMsg({ type: 'err', text: errs[0] + (errs.length > 1 ? ` (+${errs.length - 1})` : '') });
            return;
        }

        try {
            setSav(true);

            const slots = se.map(s => ({
                enabled: Boolean(s.enabled),
                startH: parseInt(s.startH, 10) || 0,
                startM: parseInt(s.startM, 10) || 0,
                endH: parseInt(s.endH, 10) || 0,
                endM: parseInt(s.endM, 10) || 0
            }));

            const payload = { deviceId: dev, slots };
            console.log('[Schedule] Saving:', payload);

            await api.post('/device/schedule/save', payload);

            setSd(prev => ({ ...prev, [dev]: { deviceId: dev, slots } }));
            localStorage.setItem(STORAGE_KEY, JSON.stringify({ ...sd, [dev]: { deviceId: dev, slots } }));
            setDirty(false);
            setMsg({ type: 'ok', text: 'Сохранено! ESP32 применит за 5 сек.' });
            console.log('[Schedule] Save successful');

        } catch (error) {
            console.error('[Schedule] Save error:', error);
            setMsg({ type: 'err', text: error.response?.data?.error || 'Ошибка сохранения' });
        } finally {
            setSav(false);
        }
    }

    const hc = (i, f, v) => {
        const clean = sanitize(v);
        setSe(p => p.map((s, x) => x === i ? { ...s, [f]: clean } : s));
        setDirty(true);
        setMsg(null);
    };

    const ht = (i, c) => {
        setSe(p => p.map((s, x) => x === i ? { ...s, enabled: c } : s));
        setDirty(true);
        setMsg(null);
    };

    const handleDeviceChange = (e) => {
        const newDev = parseInt(e.target.value, 10);
        if (dirty) {
            if (!window.confirm('Есть несохраненные изменения. Переключить устройство? Данные будут потеряны.')) return;
        }
        setDev(newDev);
        setDirty(false);
        setMsg(null);
    };

    const timeCell = (idx, hF, mF) => {
        const s = se[idx];
        return (
            <div className='sched-time'>
                <input
                    type='text'
                    inputMode='numeric'
                    autoComplete='off'
                    maxLength={2}
                    placeholder='ЧЧ'
                    value={s[hF]}
                    onChange={(e) => hc(idx, hF, e.target.value)}
                    onBlur={() => clampField(idx, hF)}
                    onKeyDown={blockNonDigit}
                    disabled={!deviceOnline}
                    className={`sched-inp${isBad(hF, s[hF]) ? ' bad' : ''}`}
                />
                <span className='sched-colon'>:</span>
                <input
                    type='text'
                    inputMode='numeric'
                    autoComplete='off'
                    maxLength={2}
                    placeholder='ММ'
                    value={s[mF]}
                    onChange={(e) => hc(idx, mF, e.target.value)}
                    onBlur={() => clampField(idx, mF)}
                    onKeyDown={blockNonDigit}
                    disabled={!deviceOnline}
                    className={`sched-inp${isBad(mF, s[mF]) ? ' bad' : ''}`}
                />
            </div>
        );
    };

    const rsr = (idx) => {
        const s = se[idx];
        const empty = !(s.startH || s.startM || s.endH || s.endM);
        return (
            <tr key={idx} className={empty ? 'sched-empty' : ''}>
                <td className='col-slot'>{idx + 1}</td>
                <td className='col-toggle'>
                    <label className='sched-toggle'>
                        <input
                            type='checkbox'
                            checked={s.enabled}
                            onChange={(e) => ht(idx, e.target.checked)}
                            disabled={!deviceOnline}
                        />
                        <span>{s.enabled ? 'Вкл' : 'Выкл'}</span>
                    </label>
                </td>
                <td className='col-from'>{timeCell(idx, 'startH', 'startM')}</td>
                <td className='col-to'>{timeCell(idx, 'endH', 'endM')}</td>
            </tr>
        );
    };

    // 🆕 СТИЛИ В СТИЛЕ КАРТОЧКИ ПОРОГОВ (как на фото)
    const styles = `
        .sched-compact{--bad-bg:#fde7eb;--txt:#2c3e50;--line:#e8ecf1;--muted:#8a97a5}
        .sched-compact .sched-toolbar{display:flex;align-items:center;gap:8px;flex-wrap:wrap;margin-bottom:4px}
        .sched-compact .schedule-device-select{padding:4px 8px;font-size:.85rem;max-width:190px}
        .sched-compact .schedule-save-btn{padding:5px 16px;font-size:.82rem}
        .sched-compact .sched-offline{color:#e74c3c;font-size:.78rem}

        /* Таблица: только горизонтальные разделители, без сетки */
        .sched-compact .schedule-table{width:100%;border-collapse:collapse;table-layout:fixed}
        .sched-compact .schedule-table th,
        .sched-compact .schedule-table td{
            padding:7px 8px;border:none;border-bottom:1px solid var(--line);
            vertical-align:middle;text-align:center
        }
        .sched-compact .schedule-table thead th{
            background:transparent;color:var(--muted);font-weight:600;
            font-size:.72rem;text-transform:uppercase;letter-spacing:.04em;
            border-bottom:1px solid #dfe4ea
        }
        .sched-compact .col-slot{width:56px;color:var(--muted);font-weight:600;font-size:.95rem}
        .sched-compact .col-toggle{width:96px}
        .sched-compact .sched-empty td{color:#b2bec3}

        .sched-time{display:inline-flex;align-items:center;gap:3px;justify-content:center}

        /* Поля времени: без рамок, шрифт как у значений температуры */
        .sched-inp{
            width:36px;height:26px;padding:0 2px;
            text-align:center;
            font-family:inherit;font-weight:600;font-size:1rem;color:var(--txt);
            border:none;border-radius:0;background:transparent
        }
        .sched-inp::placeholder{color:#c3ccd6;font-weight:400}
        .sched-inp:focus{outline:none;background:#eef4fb}
        /* Невалидное значение — розовый фон за значением */
        .sched-inp.bad{background:var(--bad-bg);color:#c0392b}
        .sched-inp:disabled{color:#95a5a6;background:transparent}

        .sched-colon{color:var(--txt);font-weight:600;font-size:1rem}

        .sched-toggle{display:inline-flex;align-items:center;gap:5px;cursor:pointer;user-select:none}
        .sched-toggle input{margin:0;cursor:pointer;width:15px;height:15px}
        .sched-toggle span{font-weight:600;font-size:.95rem;color:var(--txt)}

        /* страховка: если где-то останется type=number — стрелочки скрыты */
        .sched-compact input[type=number]::-webkit-outer-spin-button,
        .sched-compact input[type=number]::-webkit-inner-spin-button{-webkit-appearance:none;margin:0}
        .sched-compact input[type=number]{-moz-appearance:textfield;appearance:textfield}
    `;

    return (
        <div className='settings-schedule-section sched-compact'>
            <style>{styles}</style>

            <h2 style={{
                margin: '0 0 .5rem 0', color: '#2c3e50', fontSize: '1.1rem',
                display: 'flex', alignItems: 'baseline', gap: '8px',
                flexWrap: 'wrap', minHeight: '1.5rem'
            }}>
                <span>Управление расписанием</span>

                {msg ? (
                    <span style={{
                        color: msg.type === 'err' ? '#e74c3c' : '#27ae60',
                        fontSize: '.78rem', fontWeight: 'normal'
                    }}>
                        ● {msg.text}
                    </span>
                ) : dirty ? (
                    <span style={{ color: '#e74c3c', fontSize: '.78rem', fontWeight: 'normal' }}>
                        ● Несохраненные изменения
                    </span>
                ) : null}
            </h2>

            {ld && Object.keys(sd).length === 0 ? (
                <div className='schedule-loading'>Загружаю с сервера...</div>
            ) : (
                <>
                    <div className='sched-toolbar'>
                        <select value={dev} onChange={handleDeviceChange} className='schedule-device-select'>
                            {DEVICE_NAMES.map(d => <option key={d.id} value={d.id}>{d.name}</option>)}
                        </select>

                        <button onClick={saveSchedule} disabled={!deviceOnline || sav} className='schedule-save-btn'>
                            {sav ? 'Сохранение...' : 'Сохранить все'}
                        </button>

                        {!deviceOnline && <span className='sched-offline'>● ESP32 недоступен</span>}
                    </div>

                    <table className='schedule-table'>
                        <thead>
                            <tr>
                                <th className='col-slot'>Слот</th>
                                <th className='col-toggle'>Вкл/Выкл</th>
                                <th className='col-from'>Начало</th>
                                <th className='col-to'>Конец</th>
                            </tr>
                        </thead>
                        <tbody>{Array.from({ length: 4 }, (_, i) => rsr(i))}</tbody>
                    </table>
                </>
            )}
        </div>
    );
}

export default ScheduleSection;