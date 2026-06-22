import { Link, Outlet, useLocation } from 'react-router-dom';
import MobileMenu from './MobileMenu';
import './Layout.css';

function Layout({ user, onLogout }) {
  const location = useLocation();

  const isActive = (path) => location.pathname === path;

  return (
    <div className="layout">
      {/* Десктопное меню (скрыто на мобильных) */}
      <nav className="sidebar">
        <div className="sidebar-header">
          <h2>🔥 Отопление</h2>
          <div className="user-info">
            <div className="username">{user.username}</div>
            <div className="role">{user.role}</div>
          </div>
        </div>
        <ul className="nav-links">
          <li>
            <Link to="/" className={isActive('/') ? 'active' : ''}>
              📊 Главная
            </Link>
          </li>
          <li>
            <Link to="/settings" className={isActive('/settings') ? 'active' : ''}>
              ⚙️ Настройки
            </Link>
          </li>
          <li>
            <Link to="/events" className={isActive('/events') ? 'active' : ''}>
              📋 События
            </Link>
          </li>
            {user.role === 'ADMIN' && (
              <li>
                <Link to="/users" className={isActive('/users') ? 'active' : ''}>
                  👥 Пользователи
                </Link>
              </li>
            )}
            </ul>
        <button onClick={onLogout} className="logout-btn">
          🚪 Выйти
        </button>
      </nav>

      {/* Основной контент */}
      <div className="main-wrapper">
        {/* Мобильная шапка */}
        <header className="mobile-header">
          <h1>🔥 Отопление</h1>
          <MobileMenu user={user} onLogout={onLogout} />
        </header>

        <main className="main-content">
          <Outlet />
        </main>
      </div>
    </div>
  );
}

export default Layout;