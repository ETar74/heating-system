import { useState, useEffect } from 'react';
import { events } from '../api';
import './Events.css';

function Events() {
  const [eventList, setEventList] = useState([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    loadEvents();
  }, []);

  const loadEvents = async () => {
    try {
      const response = await events.getAll(100);
      setEventList(response.data);
    } catch (error) {
      console.error('Error loading events:', error);
    } finally {
      setLoading(false);
    }
  };

  const getEventIcon = (type) => {
    const icons = {
      'INFO': 'ℹ️',
      'WARNING': '⚠️',
      'ERROR': '❌',
      'ALARM': '🚨'
    };
    return icons[type] || '📝';
  };

  const getEventClass = (type) => {
    return `event-${type.toLowerCase()}`;
  };

  if (loading) {
    return <div className="loading">Загрузка...</div>;
  }

  return (
    <div className="events-page">
      <div className="page-header">
        <h1>Журнал событий</h1>
        <button onClick={loadEvents}>🔄 Обновить</button>
      </div>

      <div className="events-table-container">
        <table className="events-table">
          <thead>
            <tr>
              <th className="col-number">№</th>
              <th>Дата</th>
              <th>Тип</th>
              <th>Сообщение</th>
            </tr>
          </thead>
          <tbody>
            {eventList.map((event, index) => (
              <tr key={event.id} className={getEventClass(event.eventType)}>
                <td className="col-number">{index + 1}</td>
                <td>{new Date(event.createdAt).toLocaleString('ru-RU')}</td>
                <td>
                  <span className="event-badge">
                    {getEventIcon(event.eventType)} {event.eventType}
                  </span>
                </td>
                <td>{event.message}</td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </div>
  );
}

export default Events;