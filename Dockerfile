# Используем официальный образ Node.js
FROM node:20-alpine

# Рабочая директория в контейнере
WORKDIR /app

# Копируем package.json и package-lock.json
COPY package*.json ./

# Устанавливаем зависимости
RUN npm install

# Копируем остальной код
COPY . .

# Генерируем Prisma Client
RUN npx prisma generate

# Открываем порт 3000
EXPOSE 3000

# Команда запуска
CMD ["npm", "run", "dev"]