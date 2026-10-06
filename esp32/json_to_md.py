import json
import sys
from datetime import datetime

def json_to_markdown(json_file, output_file):
    # Читаем JSON (даже если он в одну строку)
    with open(json_file, 'r', encoding='utf-8') as f:
        data = json.load(f)
    
    # Открываем MD файл для записи
    with open(output_file, 'w', encoding='utf-8') as md:
        md.write("# История чата Qwen\n\n")
        md.write(f"**Экспорт:** {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}\n\n")
        md.write("---\n\n")
        
        # Пробуем разные структуры JSON (зависит от API Qwen)
        messages = []
        
        # Вариант 1: messages в корне
        if isinstance(data, dict) and 'messages' in data:
            messages = data['messages']
        # Вариант 2: data.messages
        elif isinstance(data, dict) and 'data' in data and isinstance(data['data'], dict) and 'messages' in data['data']:
            messages = data['data']['messages']
        # Вариант 3: это прямо список сообщений
        elif isinstance(data, list):
            messages = data
        # Вариант 4: ищем вложенные ключи
        elif isinstance(data, dict):
            for key in ['conversation', 'history', 'chat', 'items']:
                if key in data:
                    if isinstance(data[key], list):
                        messages = data[key]
                        break
                    elif isinstance(data[key], dict) and 'messages' in data[key]:
                        messages = data[key]['messages']
                        break
        
        # Обрабатываем сообщения
        if messages:
            for i, msg in enumerate(messages, 1):
                # Определяем роль (user/assistant/system)
                role = msg.get('role', 'unknown')
                if role == 'user':
                    role_name = "👤 Вы"
                elif role == 'assistant':
                    role_name = "🤖 Qwen"
                elif role == 'system':
                    role_name = "⚙️ Система"
                else:
                    role_name = role.capitalize()
                
                # Получаем контент
                content = msg.get('content', '')
                if not content and 'text' in msg:
                    content = msg['text']
                
                # Получаем время (если есть)
                timestamp = msg.get('created_at', msg.get('timestamp', ''))
                if timestamp:
                    time_str = f" *{timestamp}*"
                else:
                    time_str = ""
                
                # Пишем в MD
                md.write(f"### {role_name}{time_str}\n\n")
                
                # Если контент - это код или обычный текст
                if '```' in content:
                    # Это уже отформатированный код
                    md.write(f"{content}\n\n")
                else:
                    # Экранируем спецсимволы и добавляем
                    md.write(f"{content}\n\n")
                
                md.write("---\n\n")
        
        md.write("\n**Конец чата**\n")
    
    print(f"✅ Успешно! Сохранено в {output_file}")
    print(f"📊 Всего сообщений: {len(messages) if messages else 0}")

# Использование
if __name__ == "__main__":
    json_file = "my_huge_chat.json"  # Ваш файл
    output_file = "my_chat.md"       # Итоговый MD файл
    json_to_markdown(json_file, output_file)