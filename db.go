// Package main: работа с реестром отчётов в PostgreSQL
//
// Логика та же, что была в Python-версии: хранится не содержимое
// отчётов, а метаданные (тип, путь к файлу, путь к стилю) -
// даёт навигацию по отчётам без парсинга каждого файла
//
// Подключение идёт по адресу базы данных через переменную окружения
// DATABASE_URL — так адрес можно менять для локальной работы и для
// Docker, сам код не трогая.ъ
package main

import (
	"database/sql"
	"os"
	"time"

	_ "github.com/lib/pq" // драйвер PostgreSQL для database/sql
)

// Report — одна запись реестра. Аналог словаря, который в Python
// возвращал RealDictCursor: поля с именами, а не безымянный список
//
// json-теги нужны, чтобы в API поля назывались как в Python-версии
// (snake_case: report_type, а не ReportType) - иначе получатель
// JSON увидел бы другие имена ключей и другую структуру
type Report struct {
	ID         int       `json:"id"`
	Filename   string    `json:"filename"`
	ReportType string    `json:"report_type"`
	FilePath   string    `json:"file_path"`
	XSLTPath   *string   `json:"xslt_path"` // указатель: nil сериализуется как null, как None в Python
	AddedAt    time.Time `json:"added_at"`
}

// getDatabaseURL берёт адрес базы из переменной окружения, либо
// использует запасной адрес для локального запуска без Docker
func getDatabaseURL() string {
	if url := os.Getenv("DATABASE_URL"); url != "" {
		return url
	}
	return "postgres://moex_user:moex_pass@localhost:5432/moex_reports?sslmode=disable"
}

// getConnection открывает соединение с базой
func getConnection() (*sql.DB, error) {
	return sql.Open("postgres", getDatabaseURL())
}

// initDB создаёт таблицу реестра, если её ещё нет
func initDB(db *sql.DB) error {
	_, err := db.Exec(`
		CREATE TABLE IF NOT EXISTS reports (
			id SERIAL PRIMARY KEY,
			filename TEXT NOT NULL,
			report_type TEXT NOT NULL,
			file_path TEXT NOT NULL UNIQUE,
			xslt_path TEXT,
			added_at TIMESTAMP DEFAULT NOW()
		)
	`)
	return err
}

// addReport добавляет запись об отчёте. Если запись с таким
// file_path уже есть - ничего не делает (аналог
// ON CONFLICT DO NOTHING в Python-версии)
func addReport(db *sql.DB, filename, reportType, filePath, xsltPath string) error {
	_, err := db.Exec(`
		INSERT INTO reports (filename, report_type, file_path, xslt_path)
		VALUES ($1, $2, $3, $4)
		ON CONFLICT (file_path) DO NOTHING
	`, filename, reportType, filePath, nullIfEmpty(xsltPath))
	return err
}

// nullIfEmpty превращает пустую строку в NULL для базы данных -
// аналог xslt_path=None в Python, когда стиль не найден.
func nullIfEmpty(s string) interface{} {
	if s == "" {
		return nil
	}
	return s
}

// listReports возвращает все отчёты, от новых к старым
func listReports(db *sql.DB) ([]Report, error) {
	rows, err := db.Query(`SELECT id, filename, report_type, file_path, xslt_path, added_at FROM reports ORDER BY added_at DESC`)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var reports []Report
	for rows.Next() {
		var r Report
		var xsltPath sql.NullString // промежуточный тип для чтения из БД
		if err := rows.Scan(&r.ID, &r.Filename, &r.ReportType, &r.FilePath, &xsltPath, &r.AddedAt); err != nil {
			return nil, err
		}
		if xsltPath.Valid {
			r.XSLTPath = &xsltPath.String
		}
		reports = append(reports, r)
	}
	return reports, rows.Err()
}

// getReport находит один отчёт по id. Возвращает nil, если не найден
// (аналог return None в Python-версии)
func getReport(db *sql.DB, id int) (*Report, error) {
	var r Report
	var xsltPath sql.NullString
	err := db.QueryRow(`SELECT id, filename, report_type, file_path, xslt_path, added_at FROM reports WHERE id = $1`, id).
		Scan(&r.ID, &r.Filename, &r.ReportType, &r.FilePath, &xsltPath, &r.AddedAt)
	if err == sql.ErrNoRows {
		return nil, nil
	}
	if err != nil {
		return nil, err
	}
	if xsltPath.Valid {
		r.XSLTPath = &xsltPath.String
	}
	return &r, nil
}
