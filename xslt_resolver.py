"""
Определение и кэширование XSLT-стиля для конкретного отчёта.

Правильный источник стиля - сам XML-файл(до этого название папки):
биржа указывает нужный стиль в
служебной инструкции в самом начале документа:

    <?xml-stylesheet type="text/xsl" href="https://.../CUX07_....xslt"?>

Разные отчёты могут ссылаться на разные стили - поэтому определять
стиль приходиться для каждого файла отдельно, а не одним и тем же файлом
на весь тип рынка.

Скачивание стиля - поход в интернет, поэтому делаем его один раз и
кэшируем локальный файл в styles/. Если стиль с таким именем уже
скачан - повторно в интернет не ходим.
"""

import re
from pathlib import Path
from urllib.request import urlretrieve

STYLES_DIR = Path("styles")
STYLES_DIR.mkdir(exist_ok=True)


def extract_stylesheet_url(xml_path: Path) -> str | None:
    """
    Читаем начало XML-файла и ищет инструкцию xml-stylesheet.

    "В файлах биржи таких инструкций обычно две: локальный путь вида
    C:\\MICEX\\XSLT\\... (актуален только на компьютере с
    предустановленным ПО биржи) и https-ссылка на ftp.moex.com" —
    я могу использовать только вторую, она доступна для скачивания.

    Читаем как обычный текст (а не через XML-парсер), потому что
    processing instruction стоит до корневого тега - некоторые
    парсеры её игнорируют при обычном разборе дерева элементов.
    """
    with open(xml_path, "r", encoding="utf-8", errors="replace") as f:
        head = f.read(2000)  # инструкции всегда в самом начале файла

    hrefs = re.findall(r'<\?xml-stylesheet[^>]*href="([^"]+)"', head)
    for href in hrefs:
        if href.startswith("http://") or href.startswith("https://"):
            return href
    return None


def ensure_style_cached(style_url: str) -> str:
    """
    Если стиль уже скачан локально - просто возвращает путь к нему.
    Если нет - скачивает один раз и сохраняет под собственным именем
    (берём его из самого URL, чтобы разные стили не конфликтовали).
    """
    filename = style_url.rsplit("/", 1)[-1]
    local_path = STYLES_DIR / filename

    if not local_path.exists():
        urlretrieve(style_url, local_path)

    return str(local_path)
