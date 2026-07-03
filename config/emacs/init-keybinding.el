;;; init-keybinding.el --- Evil and custom keybindings configuration  -*- lexical-binding: t; -*-

;;; Commentary:
;;
;; 自定义 Evil 键位、Rime 输入法、Avy、Ace-window 等快捷键与交互控制配置。
;;

;;; Code:

;;vim键位
(use-package evil
  :custom
  ;;使用undo-tree作为撤回系统
  (evil-undo-system 'undo-tree)
  (evil-want-C-u-scroll t)
  :init
  (setq evil-want-integration t) ;; This is optional since it's already set to t by default.
  (setq evil-want-keybinding nil)
  :config
  (dolist (mode '(dashboard-mode
  	              help-mode
  	              buffer-menu-mode
  	              package-menu-mode))
    (add-to-list 'evil-emacs-state-modes mode))
  (evil-set-leader '(normal visual) (kbd "SPC") nil)
  ;;file操作
  (evil-define-key 'normal 'global (kbd "<leader>fr") 'recentf-open)
  (evil-define-key 'normal 'global (kbd "<leader>ff") 'find-file)
  (evil-define-key 'normal 'global (kbd "<leader>fd") 'dired)
  (evil-define-key 'normal 'global (kbd "<leader>fj") 'dired-jump)
  ;;buffer操作
  (evil-define-key 'normal 'global (kbd "<leader>bb") 'consult-buffer)
  (evil-define-key 'normal 'global (kbd "<leader>bB") 'my/switch-to-star-buffers)
  (evil-define-key 'normal 'global (kbd "<leader>bk") 'kill-buffer)
  (evil-define-key 'normal 'global (kbd "<leader>bx") 'kill-current-buffer)
  (evil-define-key 'normal 'global (kbd "<leader>bs") 'save-buffer)
  ;;搜索操作 (Fuzzy Search)
  (evil-define-key 'normal 'global (kbd "<leader>sp") 'consult-ripgrep)
  (evil-define-key 'normal 'global (kbd "<leader>ss") 'consult-line)
  ;;jump
  (evil-define-key 'normal 'global (kbd "<leader>kk") 'evil-avy-goto-line-above)
  (evil-define-key 'normal 'global (kbd "<leader>jj") 'evil-avy-goto-line-below)
  (evil-define-key 'normal 'global (kbd "<leader>gg") 'evil-avy-goto-char-2)
  (evil-define-key 'normal 'global (kbd "<leader>gg") 'evil-avy-goto-char-2)
  ;;comment
  (evil-define-key '(normal visual) 'global (kbd "<leader>/") 'evilnc-comment-or-uncomment-lines)
  ;;window
  (evil-define-key 'normal 'global (kbd "<leader>ws") 'evil-window-split)
  (evil-define-key 'normal 'global (kbd "<leader>wv") 'evil-window-vsplit)
  (evil-define-key 'normal 'global (kbd "<leader>wl") 'evil-window-right)
  (evil-define-key 'normal 'global (kbd "<leader>wk") 'evil-window-up)
  (evil-define-key 'normal 'global (kbd "<leader>wj") 'evil-window-down)
  (evil-define-key 'normal 'global (kbd "<leader>wo") 'evil-window-down)

  (evil-define-key 'normal 'global (kbd "<leader>wh") 'evil-window-left)
  (evil-define-key 'normal 'global (kbd "<leader>wq") 'delete-window)
  (evil-define-key 'normal 'global (kbd "<leader>ww") 'delete-other-windows)
  ;;git diff-hl跳转
  (evil-define-key 'normal 'global (kbd "<leader>vn") 'diff-hl-next-hunk)
  (evil-define-key 'normal 'global (kbd "<leader>vp") 'diff-hl-previous-hunk)
  ;;flymake错误跳转
  (evil-define-key 'normal 'global (kbd "<leader>en") 'flymake-goto-next-error)
  (evil-define-key 'normal 'global (kbd "<leader>ep") 'flymake-goto-prev-error)
  ;;打开dired
  (evil-define-key 'normal 'global (kbd "<leader>dj") 'dired-jump)
  ;;打开magit
  (evil-define-key 'normal 'global (kbd "<leader>mg") 'magit)

  (evil-mode 1))

;; 修改粘贴快捷键
(global-set-key (kbd "M-v") 'yank)

;; evil相关扩展
(use-package evil-collection
  :after evil
  :config
  (evil-collection-init))

;;输入法配置
(use-package rime
  :custom
  (default-input-method "rime")
  (rime-user-data-dir (if (eq system-type 'darwin) "~/Library/Rime" "~/.local/share/fcitx5/rime"))
  (rime-show-candidate 'posframe)
  :config
  (if (eq system-type 'darwin)
      (setq rime-librime-root "/opt/homebrew")
    (setq rime-librime-root (shell-command-to-string "nix eval --raw nixpkgs#librime"))
    (setq rime-emacs-module-header-root (concat (shell-command-to-string "nix eval --raw nixpkgs#emacs-pgtk") "/include"))
    (setq rime-share-data-dir (concat (shell-command-to-string "nix eval --raw nixpkgs#brise") "/share/rime-data"))))

(when (eq system-type 'darwin)
  (setq mac-command-modifier 'meta
	    mac-option-modifier 'super))

;;快捷键提示
(use-package which-key
  :init (which-key-mode))

;;快速跳转
(use-package avy)

;;快速切换窗口
(use-package ace-window
  :bind (("C-x o" . ace-window)))

;; 注释
(use-package evil-nerd-commenter)

;; 多光标同步编辑 (evil-multiedit)
(use-package evil-multiedit
  :after evil
  :config
  (evil-multiedit-default-keybinds))

(provide 'init-keybinding)
;;; init-keybinding.el ends here
