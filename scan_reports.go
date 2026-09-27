// Сканирование папки с отчётами.
//
// Для каждого файла:
//  1. Если он уже есть в реестре (по пути) - пропускаем полностью,
//     БЕЗ повторного разбора.
//  2. Если файл новый - читаем из него, на какой стиль он
//     ссылается, кэшируем стиль локально, записываем в реестр оба
//     пути: к XML и к его стилю.
package main

import (
	"database/sql"
	"log"
	"path/filepath"
)

const reportsDir = "reports"

// alreadyKnownPaths - множество путей файлов, уже разобранных
// раньше. В Go нет встроенного типа "множество", используем
// map[string]bool как стандартную замену
func alreadyKnownPaths(db *sql.DB) (map[string]bool, error) {
	reports, err := listReports(db)
	if err != nil {
		return nil, err
	}
	known := make(map[string]bool)
	for _, r := range reports {
		known[r.FilePath] = true
	}
	return known, nil
}

// scan обходит reportsDir, добавляет новые файлы в реестр.
// Возвращает количество добавленных файлов
func scan(db *sql.DB) (int, error) {
	known, err := alreadyKnownPaths(db)
	if err != nil {
		return 0, err
	}

	added := 0

	// Glob вместо Walk: нам нужны только файлы вида reports/<тип>/*.xml,
	// не произвольная глубина вложенности
	matches, err := filepath.Glob(filepath.Join(reportsDir, "*", "*.xml"))
	if err != nil {
		return 0, err
	}

	for _, xmlFile := range matches {
		if known[xmlFile] {
			continue // уже в реестре - повторный разбор не нужен
		}

		reportType := filepath.Base(filepath.Dir(xmlFile))

		styleURL, err := extractStylesheetURL(xmlFile)
		if err != nil {
			log.Printf("не удалось прочитать %s: %v", xmlFile, err)
			continue
		}

		var xsltPath string
		if styleURL != "" {
			xsltPath, err = ensureStyleCached(styleURL)
			if err != nil {
				log.Printf("не удалось скачать стиль для %s: %v", xmlFile, err)
				// продолжаем без стиля - как в Python-версии,
				// отчёт всё равно будет показан текстом
			}
		}

		if err := addReport(db, filepath.Base(xmlFile), reportType, xmlFile, xsltPath); err != nil {
			return added, err
		}
		added++
	}

	return added, nil
}
