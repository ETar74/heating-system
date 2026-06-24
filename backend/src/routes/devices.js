const express = require('express');
const router = express.Router();
const { requireRole } = require('../middleware/roleMiddleware'); // ← Импорт защиты
const deviceController = require('../controllers/deviceController'); // ← Ваш контроллер

// 1. Чтение статусов устройств (доступно всем авторизованным)
// (предполагаем, что authMiddleware уже добавлен глобально или здесь)
router.get('/status', deviceController.getStatus);

// 2. Управление котлом (ТОЛЬКО ADMIN и OPERATOR)
router.post('/boiler/on',  requireRole('ADMIN', 'OPERATOR'), deviceController.boilerOn);
router.post('/boiler/off', requireRole('ADMIN', 'OPERATOR'), deviceController.boilerOff);

// 3. Управление насосами (ТОЛЬКО ADMIN и OPERATOR)
router.post('/pumps/floor/on',  requireRole('ADMIN', 'OPERATOR'), deviceController.floorPumpOn);
router.post('/pumps/floor/off', requireRole('ADMIN', 'OPERATOR'), deviceController.floorPumpOff);
router.post('/pumps/radiators/on',  requireRole('ADMIN', 'OPERATOR'), deviceController.radiatorPumpOn);
router.post('/pumps/radiators/off', requireRole('ADMIN', 'OPERATOR'), deviceController.radiatorPumpOff);

// 4. Управление электрокотлом в ТА (ТОЛЬКО ADMIN и OPERATOR)
router.post('/accumulator/elec-boiler/on',  requireRole('ADMIN', 'OPERATOR'), deviceController.elecBoilerOn);
router.post('/accumulator/elec-boiler/off', requireRole('ADMIN', 'OPERATOR'), deviceController.elecBoilerOff);

module.exports = router;