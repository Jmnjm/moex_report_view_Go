// Определение и кэширование XSLT-стиля для конкретного отчёта.
//
// Правильный источник стиля - не название папки, а сам XML-файл:
// биржа указывает нужный стиль в служебной инструкции в самом
// начале документа:
//
//	<?xml-stylesheet type="text/xsl" href="https://.../CUX07_....xslt"?>
//
// Разные отчёты могут ссылаться на разные стили - определяем стиль
// для каждого файла отдельно.
//
// Скачивание стиля - поход в интернет, поэтому делаем его один раз
// и кэшируем локальный файл в styles/. Если стиль с таким именем
// уже скачан - повторно в интернет не обращаемся
package main

import (
	"io"
	"net/http"
	"os"
	"path/filepath"
	"regexp"
	"strings"
)

const stylesDir = "styles"

// stylesheetHrefPattern ищет href="..." внутри инструкций
// <?xml-stylesheet ... ?> в начале XML-файла.
var stylesheetHrefPattern = regexp.MustCompile(`<\?xml-stylesheet[^>]*href="([^"]+)"`)

// extractStylesheetURL читает начало XML-файла и ищет https-ссылку
// на стиль. В файлах биржи таких инструкций обычно две: локальный
// путь вида C:\MICEX\XSLT\... (бесполезен на сервере) и https-ссылка
// на ftp.moex.com - используется именно вторая.
func extractStylesheetURL(xmlPath string) (string, error) {
	f, err := os.Open(xmlPath)
	if err != nil {
		return "", err
	}
	defer f.Close()

	// Инструкция всегда в самом начале файла - читаем только
	// первые 2000 байт, а не весь потенциально большой файл.
	buf := make([]byte, 2000)
	n, err := f.Read(buf)
	if err != nil && err != io.EOF {
		return "", err
	}
	head := string(buf[:n])

	matches := stylesheetHrefPattern.FindAllStringSubmatch(head, -1)
	for _, m := range matches {
		href := m[1]
		if strings.HasPrefix(href, "http://") || strings.HasPrefix(href, "https://") {
			return href, nil
		}
	}
	return "", nil // стиль не найден - не ошибка, а обычный случай
}

// ensureStyleCached проверяет, скачан ли уже стиль локально. Если
// да - просто возвращает путь. Если нет - скачивает один раз.
func ensureStyleCached(styleURL string) (string, error) {
	filename := filepath.Base(styleURL)
	localPath := filepath.Join(stylesDir, filename)

	if _, err := os.Stat(localPath); err == nil {
		return localPath, nil // уже скачан
	}

	resp, err := http.Get(styleURL)
	if err != nil {
		return "", err
	}
	defer resp.Body.Close()

	out, err := os.Create(localPath)
	if err != nil {
		return "", err
	}
	defer out.Close()

	if _, err := io.Copy(out, resp.Body); err != nil {
		return "", err
	}
	return localPath, nil
}
