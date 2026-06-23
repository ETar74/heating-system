const express = require('express');
const router = express.Router();
const { requireRole } = require('../middleware/roleMiddleware');
// ... ваши импорты контроллеров ...

// Просмотр настроек (доступно всем авторизованным, если есть authMiddleware)
router.get('/', settingsController.getSettings);

// Изменение настроек (ТОЛЬКО ADMIN и OPERATOR)
router.put('/:key', requireRole('ADMIN', 'OPERATOR'), settingsController.updateSetting);

module.exports = router;