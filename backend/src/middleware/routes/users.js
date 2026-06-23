const express = require('express');
const router = express.Router();
const { requireRole } = require('../middleware/roleMiddleware');
// ... ваши импорты контроллеров ...

router.get('/', requireRole('ADMIN'), usersController.getAll);
router.post('/', requireRole('ADMIN'), usersController.create);
router.put('/:id', requireRole('ADMIN'), usersController.update);
router.delete('/:id', requireRole('ADMIN'), usersController.delete);

module.exports = router;