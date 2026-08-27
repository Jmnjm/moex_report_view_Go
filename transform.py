"""
Преобразование XML-отчёта в HTML через готовый XSLT-стиль биржи.

По фидбэку: "свой парсер содержимого не пишу - биржа уже
поставляет XSLT-стиль для каждого отчёта, задача - применить
его на сервере (аналог команды xsltproc, но средствами Python/lxml)
и отдать результат пользователю в браузере."
"""

from html import escape

from lxml import etree


def render_report_html(xml_path: str, xslt_path: str | None) -> str:
    """
    Если для отчёта есть xslt-стиль - применяем его и возвращаем HTML.
    Если стиля нет - отдаём исходный XML как текст (  запасной вариант,
    чтобы пользователь всё равно мог посмотреть содержимое).

    Важно: когда просто показываем "сырой" XML, нужно экранировать
    символы < и >, иначе браузер попытается воспринять теги отчёта
    как настоящую HTML-разметку и ничего не покажет (у отчётов МБ
    почти все данные лежат в атрибутах тегов, а не в тексте между
    ними, поэтому "пустые" на вид теги без экранирования дают
    пустую страницу).
    """
    xml_doc = etree.parse(xml_path)

    if not xslt_path:
        raw_xml = etree.tostring(xml_doc, pretty_print=True, encoding="unicode")
        return f"<pre>{escape(raw_xml)}</pre>"

    xslt_doc = etree.parse(xslt_path)
    transform = etree.XSLT(xslt_doc)
    result = transform(xml_doc)
    return str(result)
