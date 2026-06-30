import { useState } from 'react';
import { Link, useLocation } from 'react-router-dom';
import './MobileMenu.css';

function MobileMenu({ user, onLogout }) {
  const [isOpen, setIsOpen] = useState(false);
  const location = useLocation();

  const isActive = (path) => location.pathname === path;

  const toggleMenu = () => setIsOpen(!isOpen);
  const closeMenu = () => setIsOpen(false);

  const handleLinkClick = () => {
    closeMenu();
  };

  const handleLogout = () => {
    closeMenu();
    onLogout();
  };

  return (
    <>
      {/* Гамбургер-кнопка */}
      <button 
        className="hamburger-btn" 
        onClick={toggleMenu}
        aria-label="Открыть меню"
      >
        <span className={`hamburger-line ${isOpen ? 'open' : ''}`}></span>
        <span className={`hamburger-line ${isOpen ? 'open' : ''}`}></span>
        <span className={`hamburger-line ${isOpen ? 'open' : ''}`}></span>
      </button>

      {/* Затемнение фона */}
      {isOpen && (
        <div className="mobile-overlay" onClick={closeMenu}></div>
      )}

      {/* Выпадающее меню */}
      <div className={`mobile-menu ${isOpen ? 'open' : ''}`}>
        <div className="mobile-menu-header">
          <h2>🔥 Отопление</h2>
          <button 
            className="close-btn" 
            onClick={closeMenu}
            aria-label="Закрыть меню"
          >
            ✕
          </button>
        </div>

        <div className="mobile-user-info">
          <div className="username">{user?.username || 'Гость'}</div>
          <div className="role">{user?.role || 'Неизвестно'}</div>
        </div>

        <nav className="mobile-nav">
          <Link 
            to="/" 
            className={`mobile-link ${isActive('/') ? 'active' : ''}`}
            onClick={handleLinkClick}
          >
            📊 Главная
          </Link>
          <Link 
            to="/settings" 
            className={`mobile-link ${isActive('/settings') ? 'active' : ''}`}
            onClick={handleLinkClick}
          >
            ⚙️ Настройки
          </Link>
          <Link 
            to="/events" 
            className={`mobile-link ${isActive('/events') ? 'active' : ''}`}
            onClick={handleLinkClick}
          >
            📋 События
          </Link>
          {user?.role === 'ADMIN' && (
            <Link 
              to="/users" 
              className={`mobile-link ${isActive('/users') ? 'active' : ''}`}
              onClick={handleLinkClick}
            >
              👥 Пользователи
            </Link>
          )}
        </nav>

        <button 
          className="mobile-logout-btn"
          onClick={handleLogout}
        >
          🚪 Выйти
        </button>
      </div>
    </>
  );
}

export default MobileMenu;