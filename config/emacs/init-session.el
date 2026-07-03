;; -*- lexical-binding: t; -*-

;;撤销 重新打开文件时记住之前改动
(use-package undo-tree
  :init
  (global-undo-tree-mode)
  :config
  (let ((hist-dir (expand-file-name "undo-tree-hist" user-emacs-directory)))
    (make-directory hist-dir t)
    (setq undo-tree-history-directory-alist `(("." . ,hist-dir))
          undo-tree-auto-save-history t)))

(use-package exec-path-from-shell
  :if (memq system-type '(darwin))  ; macOS 系统下总是生效，即使在 daemon 模式下
  :config
  (exec-path-from-shell-initialize)
  (exec-path-from-shell-copy-envs '("SSH_AUTH_SOCK" "GPG_TTY"))
  ;; 重新把 my-paths 加回去，防止被覆盖并且保证优先级
  (setenv "PATH" (concat my-paths-join ":" (getenv "PATH")))
  (setq exec-path (append (mapcar #'expand-file-name my-paths) exec-path)))

(setq auto-save-default nil)    ;关闭自动保存
(setq create-lockfiles nil)     ;关闭锁文件
(setq delete-old-versions t)    ;自动删除旧版本
(setq kept-new-versions 10)     ;保留最新的 10 个版本
(setq kept-old-versions 2)      ;保留最早的 2 个版本
(setq version-control t)        ;开启编号备份（即 filename.~1~, filename.~2~）
(setq backup-by-copying t)      ;复制备份，保护硬链接

(defun auto-save-delete-trailing-whitespace-except-current-line ()
  (interactive)
  (let ((begin (line-beginning-position))
        (end (point)))
    (save-excursion
      ;; 删除当前行以上的尾部空白
      (when (< (point-min) begin)
        (save-restriction
          (narrow-to-region (point-min) (1- begin))
          (delete-trailing-whitespace)))
      ;; 删除当前行以下的尾部空白
      (when (> (point-max) end)
        (save-restriction
          (narrow-to-region end (point-max))
          (delete-trailing-whitespace))))))

;;保存前删除末尾空格
(add-hook 'before-save-hook 'auto-save-delete-trailing-whitespace-except-current-line)

;;项目管理
(use-package projectile
  :init
  (projectile-mode +1)
  :config
  (if (string-equal system-type "darwin") (delete "WORKSPACE" projectile-project-root-files)))


;;git相关
(use-package magit)
(use-package diff-hl
  :config
  (add-hook 'magit-pre-refresh-hook 'diff-hl-magit-pre-refresh)
  (add-hook 'magit-post-refresh-hook 'diff-hl-magit-post-refresh)
  (add-hook 'dired-mode-hook 'diff-hl-dired-mode)
  (global-diff-hl-mode)
  (diff-hl-margin-mode
   ))

;;高亮光标处相同变量
(use-package symbol-overlay
  :bind
  ("M-i" . symbol-overlay-put)
  ("M-n" . symbol-overlay-jump-next)
  ("M-p" . symbol-overlay-jump-prev))

;; 记住上次打开文件时的光标位置
(save-place-mode 1)

(provide 'init-session)
