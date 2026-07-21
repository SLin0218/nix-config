;;; init-database.el --- Database clients and SQL editing  -*- lexical-binding: t; -*-

;;; Commentary:
;;
;; 数据库开发支持：
;; 1. 动态解析 ~/.myclirc 数据库连接配置。
;; 2. SQL 模式与自动格式化。
;; 3. Clutch 现代化交互式数据库客户端。
;;

;;; Code:

(require 'url-util)

;; 动态从 ~/.myclirc 自动解析并加载所有数据库连接配置
(defun my-load-db-connections-from-myclirc ()
  "Dynamically parse database connections from ~/.myclirc and set alists."
  (let ((file (expand-file-name "~/.myclirc"))
        (sql-conns nil)
        (clutch-conns nil))
    (when (file-readable-p file)
      (with-temp-buffer
        (insert-file-contents file)
        (goto-char (point-min))
        (when (re-search-forward "^\\[alias_dsn\\]" nil t)
          (forward-line 1)
          (let ((continue t))
            (while (and continue (not (eobp)))
              (let ((line (string-trim (buffer-substring-no-properties (line-beginning-position) (line-end-position)))))
                (cond
                 ((string-match-p "^\\[" line)
                  (setq continue nil))
                 ((or (string-empty-p line)
                      (string-match-p "^[#;]" line))
                  nil)
                 ((string-match "^\\([^#=; \t\n]+\\)[ \t]*=[ \t]*mysql://\\(?:\\([^:@/]+?\\)\\(?::\\(.*\\)\\)?@\\)?\\([^:@/ \t\n]+\\)\\(?::\\([0-9]+\\)\\)?\\(?:/\\([^? \t\n]*\\)\\)?$" line)
                  (let* ((name (match-string 1 line))
                         (user-raw (match-string 2 line))
                         (pass-raw (match-string 3 line))
                         (host (match-string 4 line))
                         (port-str (match-string 5 line))
                         (db-raw (match-string 6 line))
                         (user (or user-raw "root"))
                         (pass (and pass-raw (url-unhex-string pass-raw)))
                         (port (if port-str (string-to-number port-str) 3306))
                         (db (if (or (null db-raw) (string-empty-p db-raw)) nil db-raw)))
                    (push `(,name (sql-product 'mysql)
                                  (sql-user ,user)
                                  ,@(when pass `((sql-password ,pass)))
                                  ,@(when db `((sql-database ,db)))
                                  (sql-server ,host)
                                  (sql-port ,port))
                          sql-conns)
                    (push `(,name . (:backend mysql
                                              :host ,host
                                              :port ,port
                                              :user ,user
                                              ,@(when pass `(:password ,pass))
                                              ,@(when db `(:database ,db))))
                          clutch-conns)))))
              (forward-line 1))))))
    (setq sql-connection-alist (nreverse sql-conns))
    (setq clutch-connection-alist (nreverse clutch-conns))))

(my-load-db-connections-from-myclirc)

;; SQL 编辑模式
(use-package sql
  :defer t
  :bind (:map sql-mode-map
              ("C-c C-c" . sql-send-paragraph)
              ("C-c C-r" . sql-send-region)
              ("C-c C-s" . sql-show-sqli-buffer))
  :config
  (add-hook 'sql-interactive-mode-hook
            (lambda ()
              (toggle-truncate-lines t)
              (setq-local show-trailing-whitespace nil)))
  (setq sql-mysql-options '("--skip-ssl")))

(use-package sql-indent
  :hook (sql-mode . sql-indent-enable))

(use-package sqlformat
  :defer t
  :bind (:map sql-mode-map
              ("C-c C-f" . sqlformat-buffer))
  :init
  (setq sqlformat-command 'pgformatter))

;; Clutch 现代化交互式数据库客户端
(use-package mysql :ensure t)
(use-package clutch
  :ensure t
  :config
  (add-hook 'clutch-result-mode-hook (lambda () (display-line-numbers-mode -1)))
  (add-hook 'clutch-record-mode-hook (lambda () (display-line-numbers-mode -1)))
  (add-hook 'clutch-describe-mode-hook (lambda () (display-line-numbers-mode -1))))

(provide 'init-database)
;;; init-database.el ends here
