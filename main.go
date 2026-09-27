// Точка входа приложения.
//
// Даёт два интерфейса поверх одного и того же реестра отчётов:
//
//  1. Веб-страницы для сотрудников:
//     GET  /              - список всех отчётов
//     GET  /reports/{id}  - человекочитаемый вид отчёта (XSLT -> HTML)
//
//  2. REST API для других сервисов:
//     GET  /api/reports        - список отчётов в JSON
//     GET  /api/reports/{id}   - метаданные + сырой XML отчёта в JSON
package main

import (
	"database/sql"
	"encoding/json"
	"fmt"
	"log"
	"net/http"
	"os"
	"strconv"
	"strings"
)

var db *sql.DB

func main() {
	var err error
	db, err = getConnection()
	if err != nil {
		log.Fatalf("не удалось подключиться к базе: %v", err)
	}
	defer db.Close()

	// Реестр должен существовать до первого запроса.
	if err := initDB(db); err != nil {
		log.Fatalf("не удалось создать таблицу реестра: %v", err)
	}

	// Аналог "python scan_reports.py && uvicorn ...." из Dockerfile -
	// сканируем при старте, до того как начать принимать запросы
	added, err := scan(db)
	if err != nil {
		log.Printf("ошибка сканирования: %v", err)
	} else {
		fmt.Printf("Добавлено новых файлов: %d\n", added)
	}

	http.HandleFunc("/", reportsListPage)
	http.HandleFunc("/reports/", reportPage)
	http.HandleFunc("/api/reports", apiListReports)
	http.HandleFunc("/api/reports/", apiGetReport)

	log.Println("Uvicorn-аналог запущен на http://0.0.0.0:8000")
	log.Fatal(http.ListenAndServe(":8000", nil))
}

// --- Веб-интерфейс для полльзователей -------------------------------------------------

func reportsListPage(w http.ResponseWriter, r *http.Request) {
	reports, err := listReports(db)
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	var rows strings.Builder
	for _, rep := range reports {
		fmt.Fprintf(&rows,
			"<tr><td>%d</td><td>%s</td><td>%s</td><td>%s</td><td><a href='/reports/%d'>Открыть</a></td></tr>",
			rep.ID, rep.ReportType, rep.Filename, rep.AddedAt.Format("2006-01-02 15:04:05"), rep.ID,
		)
	}

	fmt.Fprintf(w, `<html><body>
		<h1>Отчёты Мосбиржи</h1>
		<table border="1" cellpadding="6">
			<tr><th>ID</th><th>Тип</th><th>Файл</th><th>Добавлен</th><th></th></tr>
			%s
		</table>
	</body></html>`, rows.String())
}

func reportPage(w http.ResponseWriter, r *http.Request) {
	id, err := extractID(r.URL.Path, "/reports/")
	if err != nil {
		http.Error(w, "неверный id", http.StatusBadRequest)
		return
	}

	report, err := getReport(db, id)
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}
	if report == nil {
		http.Error(w, "Отчёт не найден", http.StatusNotFound)
		return
	}

	xsltPath := ""
	if report.XSLTPath != nil {
		xsltPath = *report.XSLTPath
	}
	htmlOut, err := renderReportHTML(report.FilePath, xsltPath)
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}
	fmt.Fprint(w, htmlOut)
}

// --- REST API для других сервисов -------------------------------------------

func apiListReports(w http.ResponseWriter, r *http.Request) {
	reports, err := listReports(db)
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(reports)
}

func apiGetReport(w http.ResponseWriter, r *http.Request) {
	id, err := extractID(r.URL.Path, "/api/reports/")
	if err != nil {
		http.Error(w, "неверный id", http.StatusBadRequest)
		return
	}

	report, err := getReport(db, id)
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}
	if report == nil {
		http.Error(w, "Отчёт не найден", http.StatusNotFound)
		return
	}

	rawXML, err := os.ReadFile(report.FilePath)
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	// Встраиваем Report как есть (его json-теги уже дают нужные
	// имена полей) и добавляем raw_xml отдельным полем - не нужно
	// вручную дублировать каждое поле, как было раньше.
	type reportWithXML struct {
		Report
		RawXML string `json:"raw_xml"`
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(reportWithXML{Report: *report, RawXML: string(rawXML)})
}

// extractID достаёт числовой id из пути вида "/reports/5" - в Go
// нет встроенного роутинга с параметрами {id}, как в FastAPI,
// поэтому парсим URL вручную
func extractID(path, prefix string) (int, error) {
	idStr := strings.TrimPrefix(path, prefix)
	return strconv.Atoi(idStr)
}
