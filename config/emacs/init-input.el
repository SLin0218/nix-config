;;; init-input.el --- Input method and system modifier keys configuration  -*- lexical-binding: t; -*-

;;; Commentary:
;;
;; emacs-rime 中文输入法配置以及 macOS 系统按键映射。
;;

;;; Code:

;; Rime (emacs-rime) 输入法配置
(use-package rime
  :custom
  (default-input-method "rime")
  (rime-user-data-dir (if (eq system-type 'darwin) "~/Library/Rime" "~/.local/share/fcitx5/rime"))
  (rime-posframe-style 'horizontal)
  (rime-show-candidate 'posframe)
  :config
  (setq rime-disable-predicates
        '(rime-predicate-evil-mode-p)))

;; macOS 修饰键定义 (Command -> Meta, Option -> Super)
(when (eq system-type 'darwin)
  (setq mac-command-modifier 'meta
        mac-option-modifier 'super))

(provide 'init-input)
;;; init-input.el ends here
