import { useState } from 'react';
import { Link, useLocation } from 'react-router-dom';
import './MobileMenu.css';

function MobileMenu({ user, onLogout }) {
  const [isOpen, setIsOpen] = useState(false);
  const location = useLocation();

  const isActive = (path) => location.pathname === path;

  const toggleMenu = () => {
    setIsOpen(!isOpen);
  };

  const closeMenu = () => {
    console.log('Menu clicked, isOpen:', isOpen);////qqqqqq
    setIsOpen(false);
  };

  return (
    <div className="mobile-menu-container">
      {/* Гамбургер-кнопка */}
      <button className="hamburger-btn" onClick={toggleMenu} aria-label="Меню">
        <span className={`hamburger-line ${isOpen ? 'open' : ''}`}></span>
        <span className={`hamburger-line ${isOpen ? 'open' : ''}`}></span>
        <span className={`hamburger-line ${isOpen ? 'open' : ''}`}></span>
      </button>

      {/* Выпадающее меню */}
      <div className={`mobile-menu ${isOpen ? 'open' : ''}`}>
        <div className="mobile-menu-header">
          <h2>🔥 Отопление</h2>
          <button className="close-btn" onClick={closeMenu}>
            ✕
          </button>
        </div>

        <div className="mobile-user-info">
          <div className="username">{user.username}</div>
          <div className="role">{user.role}</div>
        </div>

        <nav className="mobile-nav">
          <Link
            to="/"
            className={`mobile-link ${isActive('/') ? 'active' : ''}`}
            onClick={closeMenu}
          >
            📊 Главная
          </Link>
          <Link
            to="/settings"
            className={`mobile-link ${isActive('/settings') ? 'active' : ''}`}
            onClick={closeMenu}
          >
            ⚙️ Настройки
          </Link>
          <Link
            to="/events"
            className={`mobile-link ${isActive('/events') ? 'active' : ''}`}
            onClick={closeMenu}
          >
            📋 События
          </Link>
          {user.role === 'ADMIN' && (
            <Link
              to="/users"
              className={`mobile-link ${isActive('/users') ? 'active' : ''}`}
              onClick={closeMenu}
            >
              👥 Пользователи
            </Link>
          )}
        </nav>

        <button className="mobile-logout-btn" onClick={onLogout}>
          🚪 Выйти
        </button>
      </div>

      {/* Затемнение фона */}
      {isOpen && <div className="mobile-overlay" onClick={closeMenu}></div>}
    </div>
  );
}

export default MobileMenu;