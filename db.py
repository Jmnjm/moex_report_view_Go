"""
Реестр отчётов в PostgreSQL

Хранятся метаданные (тип, путь к файлу, путь к стилю) 
- даём навигацию по отчётам без парсинга каждого файла. 
Подключение идёт по адресу базы данных, который передаёт через
переменную окружения DATABASE_URL 
- адрес можно менять для локальной работы и для Docker, не трогая сам код
"""

import os
import psycopg2
import psycopg2.extras

DATABASE_URL = os.environ.get(
    "DATABASE_URL",
    "postgresql://moex_user:moex_pass@localhost:5432/moex_reports",
)
def get_connection():
    conn = psycopg2.connect(DATABASE_URL)
    return conn

def init_db() -> None:
    """Создаёт таблицу реестра, если её ещё нет."""
    conn = get_connection()
    with conn.cursor() as cur:
        cur.execute(
            """
            CREATE TABLE IF NOT EXISTS reports (
                id SERIAL PRIMARY KEY,
                filename TEXT NOT NULL,
                report_type TEXT NOT NULL,
                file_path TEXT NOT NULL UNIQUE,
                xslt_path TEXT,
                added_at TIMESTAMP DEFAULT NOW()
            )
            """
        )
    conn.commit()
    conn.close()

def add_report(filename: str, report_type: str, file_path: str, xslt_path):
    conn = get_connection()
    with conn.cursor() as cur:
        cur.execute(
            """
            INSERT INTO reports (filename, report_type, file_path, xslt_path)
            VALUES (%s, %s, %s, %s)
            ON CONFLICT (file_path) DO NOTHING
            """,
            (filename, report_type, file_path, xslt_path),
        )
    conn.commit()
    conn.close()

def list_reports():
    conn = get_connection()
    with conn.cursor(cursor_factory=psycopg2.extras.RealDictCursor) as cur:
        cur.execute("SELECT * FROM reports ORDER BY added_at DESC")
        rows = cur.fetchall()
    conn.close()
    return rows

def get_report(report_id: int):
    conn = get_connection()
    with conn.cursor(cursor_factory=psycopg2.extras.RealDictCursor) as cur:
        cur.execute("SELECT * FROM reports WHERE id = %s", (report_id,))
        row = cur.fetchone()
    conn.close()
    return row
