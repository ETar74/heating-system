import { useState, useEffect } from 'react';
import { users } from '../api';
import './Users.css';

function Users() {
  const [userList, setUserList] = useState([]);
  const [loading, setLoading] = useState(true);
  const [showForm, setShowForm] = useState(false);
  const [formData, setFormData] = useState({
    username: '',
    password: '',
    role: 'VIEWER',
    telegramId: ''
  });

  useEffect(() => {
    loadUsers();
  }, []);

  const loadUsers = async () => {
    try {
      const response = await users.getAll();
      setUserList(response.data);
    } catch (error) {
      console.error('Error loading users:', error);
    } finally {
      setLoading(false);
    }
  };

  const handleCreate = async (e) => {
    e.preventDefault();
    try {
      await users.create(formData);
      setShowForm(false);
      setFormData({ username: '', password: '', role: 'VIEWER', telegramId: '' });
      loadUsers();
    } catch (error) {
      alert('Ошибка создания пользователя: ' + (error.response?.data?.error || error.message));
    }
  };

  const handleDelete = async (id, username) => {
    if (!confirm(`Удалить пользователя ${username}?`)) return;
    
    try {
      await users.delete(id);
      loadUsers();
    } catch (error) {
      alert('Ошибка удаления: ' + (error.response?.data?.error || error.message));
    }
  };

  if (loading) {
    return <div className="loading">Загрузка...</div>;
  }

  return (
    <div className="users-page">
      <div className="page-header">
        <h1>Пользователи</h1>
        <button onClick={() => setShowForm(!showForm)}>
          {showForm ? '❌ Отмена' : '➕ Создать пользователя'}
        </button>
      </div>

      {showForm && (
        <div className="user-form">
          <h3>Новый пользователь</h3>
          <form onSubmit={handleCreate}>
            <div className="form-row">
              <input
                type="text"
                placeholder="Логин"
                value={formData.username}
                onChange={(e) => setFormData({ ...formData, username: e.target.value })}
                required
              />
              <input
                type="password"
                placeholder="Пароль"
                value={formData.password}
                onChange={(e) => setFormData({ ...formData, password: e.target.value })}
                required
              />
              <select
                value={formData.role}
                onChange={(e) => setFormData({ ...formData, role: e.target.value })}
              >
                <option value="ADMIN">ADMIN</option>
                <option value="OPERATOR">OPERATOR</option>
                <option value="VIEWER">VIEWER</option>
              </select>
              <input
                type="text"
                placeholder="Telegram ID (опционально)"
                value={formData.telegramId}
                onChange={(e) => setFormData({ ...formData, telegramId: e.target.value })}
              />
              <button type="submit">Создать</button>
            </div>
          </form>
        </div>
      )}

      {/* ДЕСКТОПНАЯ ТАБЛИЦА (скрыта на мобильных) */}
      <div className="users-table-container desktop-table">
        <table className="users-table">
          <thead>
            <tr>
              <th>ID</th>
              <th>Логин</th>
              <th>Роль</th>
              <th>Telegram ID</th>
              <th>Создан</th>
              <th>Действия</th>
            </tr>
          </thead>
          <tbody>
            {userList.map(user => (
              <tr key={user.id}>
                <td>{user.id}</td>
                <td>{user.username}</td>
                <td>
                  <span className={`role-badge role-${user.role.toLowerCase()}`}>
                    {user.role}
                  </span>
                </td>
                <td>{user.telegramId || '-'}</td>
                <td>{new Date(user.createdAt).toLocaleDateString('ru-RU')}</td>
                <td>
                  <button 
                    className="delete-btn"
                    onClick={() => handleDelete(user.id, user.username)}
                  >
                    ️ Удалить
                  </button>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>

      {/* МОБИЛЬНЫЕ КАРТОЧКИ (скрыты на десктопе) */}
      <div className="mobile-cards">
        {userList.map(user => (
          <div className="user-card" key={user.id}>
            {/* Шапка карточки: Логин + Роль + ID в одной строке */}
            <div className="user-card-header">
              <div className="user-login">
                {user.username}
                <span className={`role-badge role-${user.role.toLowerCase()}`}>
                  {user.role}
                </span>
                <span className="user-id-inline">ID: {user.id}</span>
              </div>
            </div>
            
            {/* Тело карточки: остальные данные */}
            <div className="user-card-body">
              <div className="user-info-row">
                <span className="info-label">ID:</span>
                <span className="info-value">{user.id}</span>
              </div>
              <div className="user-info-row">
                <span className="info-label">Telegram:</span>
                <span className="info-value">{user.telegramId || '-'}</span>
              </div>
              <div className="user-info-row">
                <span className="info-label">Создан:</span>
                <span className="info-value">
                  {new Date(user.createdAt).toLocaleDateString('ru-RU')}
                </span>
              </div>
            </div>

            {/* Подвал карточки: кнопки действий */}
            <div className="user-card-footer">
              <button 
                className="delete-btn"
                onClick={() => handleDelete(user.id, user.username)}
              >
                🗑️ Удалить
              </button>
            </div>
          </div>
        ))}
      </div>
    </div>
  );
}

export default Users;