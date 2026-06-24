const express = require('express');
const router = express.Router();
const settingsController = require('../controllers/settingsController');
const { requireRole } = require('../middleware/roleMiddleware');  // ← ДОБАВИТЬ

router.get('/', settingsController.getSettings);
router.put('/:key', requireRole('ADMIN', 'OPERATOR'), settingsController.updateSetting);  // ← ЗАЩИТА

module.exports = router;