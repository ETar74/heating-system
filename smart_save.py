import os
import re
from datetime import datetime
import pyperclip


def fix_and_save():
    # 1. Читаем текст из буфера обмена (куда вы только что нажали Ctrl+C)
    text = pyperclip.paste()

    if not text or not text.strip():
        print(
            "Ошибка: Буфер обмена пуст! Сначала выделите текст в Qwen и нажмите Ctrl+C."
        )
        return

    # 2. Вырезаем слипшиеся цепочки номеров строк (123456789101112...)
    text = re.sub(r"\b1234567\d*\b", "", text)
    text = re.sub(r"(?<=[\n\s])12345678910[0-9]*", "", text)

    # 3. Вырезаем мусорные кнопки Qwen
    words = [
        "Скопировать код",
        "Скопировать",
        "Скачать",
        "copy",
        "download",
        "Copy code",
    ]
    for word in words:
        text = re.sub(rf"\b{word}\b", "", text, flags=re.IGNORECASE)

    # 4. ХАК ДЛЯ ПОСТРОЧНОГО РАЗБИЕНИЯ ТАБЛИЦ И СТРОК QWEN
    # Ищем места, где текст слипся перед спецсимволами, и принудительно переносим на новую строку
    text = re.sub(r"(🚀)", r"\n\n\1", text)
    text = re.sub(r"(✅)", r"\n\n\1", text)
    text = re.sub(r"(Тест \d+:)", r"\n\1", text)
    text = re.sub(r"\b(css|bash|python|html|javascript)\b", r"\n\n\1\n", text)

    # 5. Очищаем строки от остаточных одиночных цифр и лишних пробелов
    raw_lines = text.splitlines()
    clean_lines = []

    for line in raw_lines:
        line_str = line.strip()

        # Если строка — это просто забытый номер строки (цифра меньше 4 знаков), удаляем её
        if line_str.isdigit() and len(line_str) < 4:
            continue

        if line_str == "":
            if clean_lines and clean_lines[-1] != "":
                clean_lines.append("")
        else:
            clean_lines.append(line.rstrip())

    final_text = "\n".join(clean_lines).strip()

    # 6. Генерируем уникальное имя файла с датой и временем
    date_str = datetime.now().strftime("%Y-%m-%d_%H-%M")
    filename = f"chat_{date_str}.md"

    # 7. Определяем ТЕКУЩУЮ папку, где лежит этот файл .py
    current_dir = os.path.dirname(os.path.abspath(__file__))
    filepath = os.path.join(current_dir, filename)

    # 8. Записываем чистый построчный Markdown
    with open(filepath, "w", encoding="utf-8") as f:
        f.write(final_text)

    print(f" Успешно! Создан файл в текущей папке: {filename}")
    print("-" * 50)
    print("Содержимое файла (первые 500 символов):\n")
    print(final_text[:500])


if __name__ == "__main__":
    fix_and_save()
