lines = open('frontend/src/pages/Settings.jsx', 'r', encoding='utf-8').readlines()
for i, line in enumerate(lines):
    if '<h1>?  </h1>' in line:
        lines[i] = line.replace('<h1>?  </h1>', '<h1>Настройки</h1>')
    if \"deviceOnline ? 'ESP32\" in line:
        indent = len(line) - len(line.lstrip())
        lines[i] = ' ' * indent + \"{deviceOnline ? 'ESP32 онлайн' : 'ESP32 оффлайн'}\\n\"
    if \"?? <strong>Настройки заблокированы</strong>\" in line:
        lines[i] = line.replace('?? <strong>Настройки заблокированы</strong>', '🔒 <strong>Настройки заблокированы</strong>')
open('frontend/src/pages/Settings.jsx', 'w', encoding='utf-8').write(''.join(lines))
