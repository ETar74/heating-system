// src/routes/ota.js
// /api/ota — управление прошивками ESP32

const express = require('express');
const crypto = require('crypto');
const fs = require('fs');
const path = require('path');
const { authenticateToken, requireRole } = require('../middleware/auth');

module.exports = function createOtaRoutes({ prisma, broadcast, uploadDir, upload, authenticateDevice }) {
  const router = express.Router();

  // 1. Загрузка новой прошивки (только ADMIN)
  router.post(
    '/upload',
    authenticateToken,
    requireRole('ADMIN'),
    upload.single('firmware'),
    async (req, res) => {
      try {
        if (!req.file) return res.status(400).json({ error: 'Файл не загружен' });

        const { version } = req.body;
        if (!version) {
          await fs.promises.unlink(req.file.path).catch(() => {});
          return res.status(400).json({ error: 'Не указана версия прошивки' });
        }

        const fileBuffer = fs.readFileSync(req.file.path);
        const md5Hash = crypto.createHash('md5').update(fileBuffer).digest('hex');
        const filesize = fileBuffer.length;

        const firmware = await prisma.firmware.create({
          data: {
            version,
            filename: req.file.filename,
            filesize,
            md5: md5Hash,
            uploadedBy: req.user.id,
          },
          include: { uploader: { select: { username: true } } },
        });

        await prisma.event.create({
          data: {
            eventType: 'INFO',
            message: `Прошивка v${version} загружена (${req.user.username})`,
          },
        });

        res.json({ success: true, firmware });
      } catch (error) {
        console.error('OTA Upload Error:', error);
        res.status(500).json({ error: error.message });
      }
    }
  );

  // 2. Список всех прошивок
  router.get('/status', authenticateToken, async (req, res) => {
    try {
      const firmwares = await prisma.firmware.findMany({
        orderBy: { uploadedAt: 'desc' },
        include: {
          uploader: { select: { username: true } },
          approver: { select: { username: true } },
        },
      });
      res.json(firmwares);
    } catch (error) {
      res.status(500).json({ error: error.message });
    }
  });

  // 3. Одобрить прошивку для обновления (только ADMIN)
  router.post('/approve/:id', authenticateToken, requireRole('ADMIN'), async (req, res) => {
    try {
      const firmwareId = parseInt(req.params.id, 10);

      const firmware = await prisma.firmware.update({
        where: { id: firmwareId },
        data: {
          approved: true,
          approvedAt: new Date(),
          approvedBy: req.user.id,
        },
      });

      await prisma.deviceCache.updateMany({
        data: { firmwareUpdatePending: true },
      });

      await prisma.event.create({
        data: {
          eventType: 'INFO',
          message: `Прошивка v${firmware.version} одобрена для обновления (${req.user.username})`,
        },
      });

      broadcast({ type: 'ota_approved', version: firmware.version });
      res.json({ success: true, message: 'Прошивка одобрена и отправлена на устройство' });
    } catch (error) {
      res.status(500).json({ error: error.message });
    }
  });

  // 4. Удалить прошивку (только ADMIN)
  router.delete('/firmware/:id', authenticateToken, requireRole('ADMIN'), async (req, res) => {
    try {
      const firmwareId = parseInt(req.params.id, 10);
      const firmware = await prisma.firmware.findUnique({ where: { id: firmwareId } });

      if (firmware) {
        const filePath = path.join(uploadDir, firmware.filename);
        if (fs.existsSync(filePath)) fs.unlinkSync(filePath);

        await prisma.firmware.delete({ where: { id: firmwareId } });

        await prisma.event.create({
          data: {
            eventType: 'INFO',
            message: `Прошивка v${firmware.version} удалена (${req.user.username})`,
          },
        });
      }

      res.json({ success: true, message: 'Прошивка удалена' });
    } catch (error) {
      res.status(500).json({ error: error.message });
    }
  });

  // 5. Скачивание файла прошивки (для ESP32; если задан ESP32_TOKEN — требует токен)
  router.get('/download/:id', authenticateDevice, async (req, res) => {
    try {
      const firmwareId = parseInt(req.params.id, 10);
      const firmware = await prisma.firmware.findUnique({ where: { id: firmwareId } });

      if (!firmware || !firmware.approved) {
        return res.status(404).json({ error: 'Firmware not found or not approved' });
      }

      const filePath = path.join(uploadDir, firmware.filename);
      if (!fs.existsSync(filePath)) {
        return res.status(404).json({ error: 'File not found on server' });
      }

      res.setHeader('Content-Type', 'application/octet-stream');
      res.setHeader('Content-Disposition', `attachment; filename="${firmware.filename}"`);
      res.sendFile(filePath);
    } catch (error) {
      res.status(500).json({ error: error.message });
    }
  });

  return router;
};