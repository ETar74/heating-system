// src/lib/json.js
// Хелперы для работы с JSON-полями, хранимыми в SQLite как текст.
// Prisma не поддерживает тип Json в SQLite — сериализуем вручную.

// Преобразует объект/значение в строку для записи в БД (null -> null)
function serialize(value) {
  if (value === null || value === undefined) return null;
  if (typeof value === 'string') {
    // Уже строка — пробуем понять, не JSON ли это; не трогаем "сырые" строки.
    // Для простоты: если это валидный JSON — оставляем как есть, иначе не JSON.
    try {
      JSON.parse(value);
      return value;
    } catch {
      return value;
    }
  }
  return JSON.stringify(value);
}

// Преобразует значение из БД (строка/объект) в JS-объект
function deserialize(value) {
  if (value === null || value === undefined) return null;
  if (typeof value === 'object') return value; // уже объект
  try {
    const parsed = JSON.parse(value);
    return parsed;
  } catch {
    // Не JSON — возвращаем как строку
    return value;
  }
}

module.exports = { serialize, deserialize };