"""
Реестр отчётов в PostgreSQL.

Логика та же, что была на SQLite: храним не содержимое отчётов,
а метаданные (тип, путь к файлу, путь к стилю) — это и даёт
навигацию по отчётам без парсинга каждого файла.

Отличие от SQLite-версии: подключение идёт не к локальному файлу,
а по адресу базы данных, который передаётся через переменную
окружения DATABASE_URL. Так удобно, потому что этот адрес будет
разным локально и в Docker — сам код менять не придётся.
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
