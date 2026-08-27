"""
Скрипт сканирования папки с отчётами.

Для каждого файла:
1. Если он уже есть в реестре (по пути) - пропускается полностью, без
   повторного разбора. Если стиль определялся уже - 
   заново не ищем при каждом запуске сканера.
2. Если файл новый - читаем из него, на какой стиль он ссылается
   (xslt_resolver.py), убеждаемся, что стиль скачан локально, и
   записываем в реестр оба пути: к XML и к его стилю.
"""

from pathlib import Path

from db import add_report, init_db, list_reports
from xslt_resolver import ensure_style_cached, extract_stylesheet_url

REPORTS_DIR = Path("reports")


def already_known_paths() -> set[str]:
    """Пути файлов, которые уже разобраны раньше - их ен трогаем."""
    return {row["file_path"] for row in list_reports()}


def scan() -> int:
    init_db()
    known = already_known_paths()
    added = 0

    for xml_file in REPORTS_DIR.rglob("*.xml"):
        file_path = str(xml_file)
        if file_path in known:
            continue  # уже в реестре — повторный разбор не нужен

        report_type = xml_file.parent.name

        style_url = extract_stylesheet_url(xml_file)
        xslt_path = ensure_style_cached(style_url) if style_url else None

        add_report(
            filename=xml_file.name,
            report_type=report_type,
            file_path=file_path,
            xslt_path=xslt_path,
        )
        added += 1

    return added


if __name__ == "__main__":
    count = scan()
    print(f"Добавлено новых файлов: {count}")
