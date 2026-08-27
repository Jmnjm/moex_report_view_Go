"""
Точка входа приложения

Даёт два интерфейса поверх одного и того же реестра отчётов (db.py):
1. Веб-страницы для сотрудников:
   GET  /              - список всех отчётов
   GET  /reports/{id}  - человекочитаемый вид одного отчёта (XSLT -> HTML)

2. REST API для других сервисов:
   GET  /api/reports        - список отчётов в JSON
   GET  /api/reports/{id}   - метаданные + сырой XML одного отчёта в JSON
"""

from fastapi import FastAPI, HTTPException
from fastapi.responses import HTMLResponse
from db import get_report, init_db, list_reports
from transform import render_report_html

app = FastAPI(title="MOEX Report Viewer")

@app.on_event("startup")
def on_startup():
    # Реестр должен существовать до первого запроса.
    init_db()

# --- Веб-интерфейс для пользователя ------------------------------------------------

@app.get("/", response_class=HTMLResponse)
def reports_list_page():
    reports = list_reports()
    rows = "".join(
        f"<tr><td>{r['id']}</td><td>{r['report_type']}</td>"
        f"<td>{r['filename']}</td><td>{r['added_at']}</td>"
        f"<td><a href='/reports/{r['id']}'>Открыть</a></td></tr>"
        for r in reports
    )
    return f"""
    <html><body>
        <h1>Отчёты Мосбиржи</h1>
        <table border="1" cellpadding="6">
            <tr><th>ID</th><th>Тип</th><th>Файл</th><th>Добавлен</th><th></th></tr>
            {rows}
        </table>
    </body></html>
    """


@app.get("/reports/{report_id}", response_class=HTMLResponse)
def report_page(report_id: int):
    report = get_report(report_id)
    if report is None:
        raise HTTPException(status_code=404, detail="Отчёт не найден")
    return render_report_html(report["file_path"], report["xslt_path"])

# --- REST API для других сервисов -------------------------------------------

@app.get("/api/reports")
def api_list_reports():
    reports = list_reports()
    return [dict(r) for r in reports]

@app.get("/api/reports/{report_id}")
def api_get_report(report_id: int):
    report = get_report(report_id)
    if report is None:
        raise HTTPException(status_code=404, detail="Отчёт не найден")

    with open(report["file_path"], "r", encoding="utf-8", errors="replace") as f:
        raw_xml = f.read()

    return {
        **dict(report),
        "raw_xml": raw_xml,
    }
