# Используем официальный образ Node.js
FROM node:20-alpine

# Рабочая директория
WORKDIR /app

# Копируем package.json
COPY package*.json ./

# Устанавливаем зависимости
RUN npm install

# Копируем остальной код
COPY . .

# Открываем порт 5173
EXPOSE 5173

# Команда запуска
CMD ["npm", "run", "dev", "--", "--host"]