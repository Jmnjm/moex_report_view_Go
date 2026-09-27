// Преобразование XML-отчёта в HTML через готовый XSLT-стиль биржи.
//
// В отличие от Python-версии (там lxml оборачивает системную
// libxslt напрямую), в Go нет зрелой встроенной библиотеки для
// XSLT. Поэтому вызываем внешнюю утилиту xsltproc как отдельный
// процесс - тот же движок libxslt, только вызванный явно, а не
// через библиотек. Биржа вроде в рекомендации своей так и предлагает делать
//
// Требование: в контейнере/системе должен быть установлен xsltproc
// (пакет libxslt-tools или аналог, в зависимости от дистрибутива).
package main

import (
	"bytes"
	"html"
	"os"
	"os/exec"
)

// renderReportHTML - если для отчёта есть xslt-стиль, применяет его
// через xsltproc и возвращает HTML. Если стиля нет, отдаёт исходный
// XML как экранированный текст (запасной вариант — иначе браузер
// попытается воспринять теги отчёта как HTML-разметку и покажет
// пустую страницу, у отчётов МБ почти все данные лежат в атрибутах
// тегов, а не в тексте между ними).
func renderReportHTML(xmlPath, xsltPath string) (string, error) {
	if xsltPath == "" {
		raw, err := os.ReadFile(xmlPath)
		if err != nil {
			return "", err
		}
		return "<pre>" + html.EscapeString(string(raw)) + "</pre>", nil
	}

	// xsltproc <стиль>.xsl <отчёт>.xml — печатает результат в stdout
	cmd := exec.Command("xsltproc", xsltPath, xmlPath)
	var out bytes.Buffer
	cmd.Stdout = &out
	cmd.Stderr = &out

	if err := cmd.Run(); err != nil {
		return "", err
	}
	return out.String(), nil
}
