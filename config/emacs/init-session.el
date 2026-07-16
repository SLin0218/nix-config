;;; init-session.el --- General edit sessions, magit, and project settings  -*- lexical-binding: t; -*-

;;; Commentary:
;;
;; 撤销历史树 (undo-tree)、环境变量恢复、Magit、Projectile 项目管理等会话级设置。
;;

;;; Code:

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
  :if (and (memq system-type '(darwin)) (display-graphic-p))  ; 仅在 GUI 模式下生效，避免终端/非交互模式下启动慢
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
;; 仅启用 Git 版本控制后端，避免在非 Git 目录（或上层目录）打开文件时因为向上逐级探测老旧 VCS 系统（如 SVN, CVS, RCS 等）导致的严重假死与卡顿。
(setq vc-handled-backends '(Git))

(defun auto-save-delete-trailing-whitespace-except-current-line ()
  "在自动保存前，删除除当前活动行以外的所有行尾空格."
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
;; (use-package projectile
;;   :init
;;   (projectile-mode +1)
;;   :config
;;   (if (string-equal system-type "darwin") (delete "WORKSPACE" projectile-project-root-files)))


(use-package magit
  :defer t
  :init
  (setq magit-auto-revert-mode nil))

;; 启用 Emacs 内置的高性能、纯异步文件变更监听（在 macOS 上使用系统的 FSEvents 机制）
;; 完美替代 magit-auto-revert 的功能，且完全不引入任何文件打开时的同步加载开销。
(global-auto-revert-mode 1)
(use-package diff-hl
  :hook ((prog-mode text-mode dired-mode) . diff-hl-mode)
  :config
  (add-hook 'magit-pre-refresh-hook 'diff-hl-magit-pre-refresh)
  (add-hook 'magit-post-refresh-hook 'diff-hl-magit-post-refresh)
  (diff-hl-margin-mode))

;;高亮光标处相同变量
(use-package symbol-overlay
  :bind
  ("M-i" . symbol-overlay-put)
  ("M-n" . symbol-overlay-jump-next)
  ("M-p" . symbol-overlay-jump-prev))

;; 最近打开的文件记录
(use-package recentf
  :init
  (recentf-mode 1)
  :config
  (setq recentf-max-saved-items 100
        recentf-exclude '("/tmp/" "/ssh:" "\\.git/" "/elpa/")))

;; 记住上次打开文件时的光标位置
(save-place-mode 1)

(provide 'init-session)
;;; init-session.el ends here
