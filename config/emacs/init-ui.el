;;; init-ui.el --- Fonts, themes and UI configurations  -*- lexical-binding: t; -*-

;;; Commentary:
;;
;; 字体、主题、Doom-modeline、awesome-tab、vertico (minibuffer增强) 等界面美化配置。
;;

;;; Code:

(global-display-line-numbers-mode 1)     ;行号
(global-hl-line-mode 1)                  ;高亮当前光标行，有助于一眼识别当前聚焦窗口

(defvar slin/font-size 12
  "默认英文字体大小.")
(defvar slin/font-family "JetBrainsMono Nerd Font Mono"
  "默认英文字体族.")
(defvar slin/font-family-cjk "Maple Mono NF CN"
  "默认中文字体族.")

(cond ((eq system-type 'darwin) (setq slin/font-size 14)))

;; 全局字体设置
(defun load-font-setup (&optional frame)
  "根据当前 FRAME 设置默认英文字体与中文字体映射."
  (when (display-graphic-p frame)
    (with-selected-frame (or frame (selected-frame))
      (cond
       ((eq window-system 'pgtk)
        (set-face-attribute 'default nil :height (* slin/font-size 10) :family slin/font-family)
        (set-face-attribute 'fixed-pitch nil :height (* slin/font-size 10) :family slin/font-family))
       (t
        (let* ((font-size slin/font-size)
               (chinese-font slin/font-family-cjk)
               (english-font slin/font-family))
          ;; Set default font
          (set-frame-font (format "%s-%d" english-font font-size) nil t)
          ;; Set fixed-pitch font to match default
          (set-face-attribute 'fixed-pitch nil :family english-font :height (* font-size 10))
          ;; Set Chinese font for CJK characters
          (dolist (charset '(han kana bopomofo cjk-misc symbol))
            (set-fontset-font (frame-parameter nil 'font)
                              charset
                              (font-spec :family chinese-font)))))))))

(if (daemonp)
    (add-hook 'after-make-frame-functions #'load-font-setup)
  (load-font-setup))

;; org-table单独设置字体
(with-eval-after-load 'org
  (set-face-attribute 'org-table nil :family slin/font-family-cjk :height (* slin/font-size 10)))


;; 图标
(use-package all-the-icons)

;; dired图标
(use-package all-the-icons-dired
  :after (dired all-the-icons)
  :hook (dired-mode . all-the-icons-dired-mode))

;; 状态栏
(use-package doom-modeline
  :init (doom-modeline-mode 1)
  :config
  (setq doom-modeline-buffer-file-name-style 'truncate-nil))

;; 主题
(use-package catppuccin-theme
  :config
  (defvar slin/theme-loaded nil)
  (defun slin/load-theme-once (frame)
    (with-selected-frame frame
      (when (and (display-graphic-p frame)
                 (not slin/theme-loaded))
        (load-theme 'catppuccin :no-confirm)
        (setq slin/theme-loaded t))))
  (if (daemonp)
      (add-hook 'after-make-frame-functions #'slin/load-theme-once)
    (load-theme 'catppuccin :no-confirm)))

;; 层级对齐线
(use-package indent-bars
  :custom
  (indent-bars-no-descend-lists t) ; no extra bars in continued func arg lists
  (indent-bars-treesit-support t)
  (indent-bars-treesit-ignore-blank-lines-types '("module"))
  ;; Add other languages as needed
  (indent-bars-treesit-scope '((python function_definition class_definition for_statement
	                                   if_statement with_statement while_statement)))
  ;; Note: wrap may not be needed if no-descend-list is enough
  ;;(indent-bars-treesit-wrap '((python argument_list parameters ; for python, as an example
  ;;				      list list_comprehension
  ;;				      dictionary dictionary_comprehension
  ;;				      parenthesized_expression subscript)))
  :hook ((python-base-mode yaml-mode) . indent-bars-mode)
  :config
  (setq
   indent-bars-color '(highlight :face-bg t :blend 0.3)
   indent-bars-pattern " . . . . ." ; play with the number of dots for your usual font size
   ;;indent-bars-color-by-depth nil
   indent-bars-width-frac 0.25
   indent-bars-pad-frac 0.1))

;; minibuffer 增强
(use-package vertico
  :custom
  (vertico-count 13)
  (vertico-resize t)
  (vertico-cycle nil)
  :config
  (vertico-mode)
  (defvar +vertico-current-arrow t)
  (cl-defmethod vertico--format-candidate :around
    (cand prefix suffix index start &context ((and +vertico-current-arrow
                                                   (not (bound-and-true-p vertico-flat-mode)))
                                              (eql t)))
    (setq cand (cl-call-next-method cand prefix suffix index start))
    (if (bound-and-true-p vertico-grid-mode)
        (if (= vertico--index index)
            (concat #("▶" 0 1 (face vertico-current)) cand)
          (concat #("_" 0 1 (display " ")) cand))
      (if (= vertico--index index)
          (concat
           #(" " 0 1 (display (left-fringe right-triangle vertico-current)))
           cand)
        cand))))

;; minbuffer 相关条目说明注解
(use-package marginalia
  :config
  (marginalia-mode))

;; minibuffer自动补全图标
(use-package nerd-icons-completion
  :after marginalia
  :config
  (nerd-icons-completion-mode)
  (add-hook 'marginalia-mode-hook #'nerd-icons-completion-marginalia-setup))

(use-package colorful-mode
  :custom
  (colorful-use-prefix t)
  (colorful-only-strings 'only-prog)
  (css-fontify-colors nil)
  :hook ((css-mode html-mode emacs-lisp-mode) . colorful-mode)
  :config
  (add-to-list 'global-colorful-modes 'helpful-mode))

;; 自动将非活动窗口变暗，极易识别当前聚焦窗口
(use-package dimmer
  :custom
  (dimmer-fraction 0.4)                 ; 变暗系数，设为 0.4 让非活动窗口更暗
  :config
  (dimmer-mode 1))

(provide 'init-ui)
;;; init-ui.el ends here
