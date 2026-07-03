;;; init-complete.el --- Autocomplete and formatting configuration  -*- lexical-binding: t; -*-

;;; Commentary:
;;
;; 自动补全、LSP (Eglot)、代码格式化 (Apheleia) 以及相关依赖包的自动安装配置。
;;

;;; Code:

(use-package consult
  :config
  ;; 自定义 consult-buffer 数据源，区分用户打开的文件 Buffer 与系统只读/临时 Buffer
  (defvar consult-source-file-buffer
    `(:name "User Buffers"
            :narrow ?b
            :category buffer
            :face consult-buffer
            :history buffer-name-history
            :state ,#'consult--buffer-state
            :default t
            :items ,(lambda ()
                      (consult--buffer-query
                       :sort 'visibility
                       :as #'consult--buffer-pair
                       :predicate (lambda (buf)
                                    (let ((name (buffer-name buf)))
                                      (and (not (string-prefix-p " " name))
                                           (or (buffer-file-name buf)
                                               (and (not (string-prefix-p "*" name))
                                                    (not (string-prefix-p "magit" name)))))))))))

  (defvar consult-source-temp-buffer
    `(:name "System/Temp Buffers"
            :narrow ?s
            :category buffer
            :face consult-buffer
            :history buffer-name-history
            :state ,#'consult--buffer-state
            :items ,(lambda ()
                      (consult--buffer-query
                       :sort 'visibility
                       :as #'consult--buffer-pair
                       :predicate (lambda (buf)
                                    (let ((name (buffer-name buf)))
                                      (and (not (string-prefix-p " " name))
                                           (not (buffer-file-name buf))
                                           (or (string-prefix-p "*" name)
                                               (string-prefix-p "magit" name)))))))))

  (setq consult-buffer-sources
        (append
         '(consult-source-file-buffer
           consult-source-temp-buffer)
         (delq 'consult-source-recent-file
               (delq 'consult-source-buffer consult-buffer-sources))))

  (defun my/consult-kill-buffer ()
    "Kill a buffer, with grouping like `consult-buffer`."
    (interactive)
    (let ((sources (mapcar (lambda (src)
                             (let ((copy (copy-sequence (eval src))))
                               (plist-put copy :state nil)
                               (plist-put copy :action #'kill-buffer)
                               copy))
                           '(consult-source-file-buffer
                             consult-source-temp-buffer))))
      (consult--multi sources
                      :prompt "Kill buffer: "
                      :require-match t
                      :sort nil)))

  (consult-customize
   consult-ripgrep consult-git-grep consult-grep
   consult-find consult-locate))

(use-package orderless
  :config
  (setq completion-styles '(orderless basic)
        orderless-component-separator "\\s-+")
  ;; 优化 eglot 模糊匹配的性能，防止大项目下卡顿
  (setq completion-category-defaults nil
        completion-category-overrides '((eglot (styles orderless basic))
                                        (file (styles partial-completion)))))

(use-package lua-mode :defer t)
(use-package yaml-mode :defer t)


(use-package treesit-auto
  :custom
  ;; 第一次打开某种语言文件时，会弹窗提示是否自动下载该语言的 Tree-sitter 驱动，输入 y 即可
  (treesit-auto-install 'prompt)
  :config
  ;; 避免使用在每次打开文件时全局扫描所有语言（导致打开文件慢）的 global-treesit-auto-mode。
  ;; 改为在启动时一次性构建并设置内置的 major-mode-remap-alist，实现 0 延迟打开文件。
  (setq major-mode-remap-alist (treesit-auto--build-major-mode-remap-alist)))

(use-package yasnippet
  :config
  (yas-global-mode 1))

(use-package yasnippet-snippets
  :after yasnippet)

(use-package yasnippet-capf
  :after yasnippet)

(use-package eglot
  :hook
  ((python-mode python-ts-mode
                java-mode java-ts-mode
                lua-mode yaml-mode nix-mode) . eglot-ensure)
  :config
  ;; 显式配置 nix 语言服务器为 nixd
  (add-to-list 'eglot-server-programs
               '(nix-mode . ("nixd")))
  ;; 显式配置 python 语言服务器为 pyright-langserver
  (add-to-list 'eglot-server-programs
               `((python-mode python-ts-mode) . ("pyright-langserver" "--stdio")))
  ;; 开启 python 补全函数时自动带上括号 ()
  (setq-default eglot-workspace-configuration
                '((:pyright . (:python (:analysis (:completeFunctionParens t))))))
  ;; 显式配置 java 语言服务器 jdtls 的启动参数（加入 lombok 等参数）
  (add-to-list 'eglot-server-programs
               `((java-mode java-ts-mode) .
                 ("jdtls"
                  "--jvm-arg=-javaagent:/Users/lin/.local/share/nvim/mason/packages/jdtls/lombok.jar"
                  "--jvm-arg=-Djava.import.generatesMetadataFilesAtProjectRoot=false"
                  "--jvm-arg=-DDetectVMInstallationsJob.disabled=true"
                  "--jvm-arg=-Dfile.encoding=utf8"
                  "--jvm-arg=-XX:+UseParallelGC"
                  "--jvm-arg=-XX:GCTimeRatio=4"
                  "--jvm-arg=-XX:AdaptiveSizePolicyWeight=90"
                  "--jvm-arg=-Dsun.zip.disableMemoryMapping=true"
                  "--jvm-arg=-Xmx2G"
                  "--jvm-arg=-Xms100m"
                  "--jvm-arg=-Xlog:disable"
                  "--jvm-arg=-Daether.dependencyCollector.impl=bf"))))

;; 补全前端 Corfu
(use-package corfu
  :custom
  (corfu-auto t)                 ; 自动激活补全
  (corfu-auto-delay 0.0)         ; 零延迟，打字即弹（像 nvim-cmp 和 lsp-bridge 一样灵敏）
  (corfu-auto-prefix 1)          ; 输入 1 个字符就开始弹补全
  (corfu-cycle t)                ; 循环候选词
  (corfu-quit-no-match 'separator) ; 没匹配时配合 orderless 分隔符
  :init
  (global-corfu-mode)
  :config
  ;; 启用 Corfu 的侧边文档弹出（提供类似 lsp-bridge 的文档预览体验）
  (corfu-popupinfo-mode 1)
  (setq corfu-popupinfo-delay 0.3)
  ;; 不在普通的字符串 (String) 或注释 (Comment) 中自动弹出补全，防止如 print(" 后干扰打字
  ;; 但是如果当前输入看起来像是一个文件路径（以 /、./、../ 或 ~/ 开头），则依然允许弹出，方便文件路径补全
  (setq corfu-auto-skip-predicates
        (list (lambda ()
                (let ((state (syntax-ppss)))
                  (and (nth 8 state)
                       (not (string-match-p
                             "\\(?:/\\|\\./\\|\\.\\./\\|~/\\)[^/[:space:]\"']*$"
                             (buffer-substring-no-properties (nth 8 state) (point))))))))))

;; 补全源融合工具 Cape
(use-package cape
  :demand t
  :init
  ;; 默认添加基础的补全源
  (add-to-list 'completion-at-point-functions #'cape-file)
  (add-to-list 'completion-at-point-functions #'cape-dabbrev)
  :config
  ;; 允许输入 1 个字符时就补全上下文中的已有单词（默认是 2）
  (setq cape-dabbrev-min-length 1)
  ;; 只扫描当前编辑的 Buffer，不扫描其他不相干的打开文件
  (setq cape-dabbrev-check-other-buffers nil)
  ;; 当 eglot 启动后，把 LSP 补全与 yasnippet、当前 buffer 单词融合，在同一个弹出框中显示
  (defun my-eglot-capf ()
    (require 'cape)
    (require 'yasnippet-capf)
    (setq-local completion-at-point-functions
                (list #'cape-file
                      (cape-capf-super
                       #'eglot-completion-at-point
                       #'yasnippet-capf
                       #'cape-dabbrev))))
  (add-hook 'eglot-managed-mode-hook #'my-eglot-capf))

;; 图标美化工具 Kind Icon (媲美 Neovim LSP icons 效果)
(use-package kind-icon
  :after corfu
  :custom
  (kind-icon-default-face 'corfu-default) ; 继承 corfu 样式
  :config
  (add-to-list 'corfu-margin-formatters #'kind-icon-margin-formatter))

;; 代码格式化工具 Apheleia
(use-package apheleia
  :config
  (apheleia-global-mode +1))

(use-package markdown-mode :defer t)

(use-package nix-mode :defer t)

;; 开启 Emacs Lisp 的实时语法与错误检查（不用 LSP 也能画红线报错）
(add-hook 'emacs-lisp-mode-hook #'flymake-mode)

;; 开启括号、引号自动成对闭合
(electric-pair-mode 1)

(provide 'init-complete)
;;; init-complete.el ends here
