;; -*- lexical-binding: t; -*-
(global-display-line-numbers-mode 1)     ;行号

(defvar slin/font-size 12)
(defvar slin/font-family "JetBrainsMono Nerd Font Mono")
(defvar slin/font-family-cjk "Maple Mono NF CN")

(cond ((eq system-type 'darwin) (setq slin/font-size 16)))

;; 全局字体设置
(defun load-font-setup (&optional frame)
  (when (display-graphic-p frame)
    (with-selected-frame (or frame (selected-frame))
      (cond
       ((eq window-system 'pgtk)
        (set-face-attribute 'default nil :height (* slin/font-size 10) :family slin/font-family))
       (t
        (let* ((font-size slin/font-size)
               (chinese-font slin/font-family-cjk)
               (english-font slin/font-family))
          ;; Set default font
          (set-frame-font (format "%s-%d" english-font font-size) nil t)
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

;; 标签栏
(use-package awesome-tab
  :load-path "~/.config/slin-emacs/site-lisp/awesome-tab"
  :ensure nil
  :config
  (setq awesome-tab-height (* slin/font-size 10))
  (setq awesome-tab-cycle-scope 'tabs)
  (setq awesome-tab-dark-active-bar-color (catppuccin-color 'base))
  (setq awesome-tab-dark-selected-foreground-color (catppuccin-color 'teal))
  (if (daemonp)
      (add-hook 'after-make-frame-functions
                (lambda (frame)
                  (with-selected-frame frame
                    (unless (display-graphic-p frame)
                      (setq awesome-tab-display-icon nil)
                      (setq frame-background-mode 'dark)))))
    (when (not (display-graphic-p))
      (setq awesome-tab-display-icon nil)
      (setq frame-background-mode 'dark)))
  (defun awesome-tab-hide-tab (x)
    (let ((name (format "%s" x)))
      (or
       (string-prefix-p "*" name)
       (string-prefix-p " *" name)
       (string-prefix-p "diary" name)
       (string-prefix-p "*Compile-Log*" name)
       (string-prefix-p "*epc" name)
       (string-prefix-p "*helm" name)
       (string-prefix-p "*lsp" name)
       (and (string-prefix-p "magit" name)
            (not (file-name-extension name)))
       )))
  (set-face-attribute 'tab-line nil :inherit 'default)
  (set-face-attribute 'awesome-tab-unselected-face nil :foreground (catppuccin-color 'base) :distant-foreground (catppuccin-color 'base))
  (awesome-tab-mode t))

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
  :config
  (global-colorful-mode t)
  (add-to-list 'global-colorful-modes 'helpful-mode))

(use-package treemacs
  :bind (("C-x C-n" . treemacs))
  :config
  (setq treemacs-indentation 1)
  (setq treemacs-collapse-dirs 2)
  (setq treemacs-width-is-initially-locked t)
  (setq treemacs-follow-after-init t)
  (setq treemacs-width (* slin/font-size 5)))

(use-package treemacs-nerd-icons
  :after treemacs
  :config
  (treemacs-load-theme "nerd-icons"))

(use-package treemacs-icons-dired
  :hook (dired-mode . treemacs-icons-dired-enable-once))

(use-package treemacs-projectile
  :after (treemacs projectile)
  :config
  (treemacs-project-follow-mode t) )

(use-package treemacs-magit
  :after (treemacs magit))

(provide 'init-ui)
