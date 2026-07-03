;;; init-complete.el --- Autocomplete and formatting configuration  -*- lexical-binding: t; -*-

;;; Commentary:
;;
;; 自动补全、LSP (Eglot)、代码格式化 (Apheleia) 以及相关依赖包的自动安装配置。
;;

;;; Code:

(use-package consult)

(use-package orderless
  :config
  (setq completion-styles '(orderless basic)
        orderless-component-separator "\\s-+")
  ;; 优化 eglot 模糊匹配的性能，防止大项目下卡顿
  (setq completion-category-defaults nil
        completion-category-overrides '((eglot (styles orderless basic)))))

(use-package lua-mode)
(use-package yaml-mode)


(use-package treesit-auto
  :custom
  ;; 第一次打开某种语言文件时，会弹窗提示是否自动下载该语言的 Tree-sitter 驱动，输入 y 即可
  (treesit-auto-install 'prompt)
  :config
  ;; 自动将传统的主模式（如 java-mode）重定向到内置的原生 ts 模式（如 java-ts-mode）
  (global-treesit-auto-mode))

(use-package yasnippet
  :config
  (yas-global-mode 1))

(use-package yasnippet-snippets
  :after yasnippet)

(use-package eglot
  :hook
  ((python-mode python-ts-mode
                java-mode java-ts-mode
                lua-mode yaml-mode nix-mode) . eglot-ensure)
  :config
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

;; 确保新添加的包已安装，防止 package-list 过期导致安装失败
(dolist (pkg '(corfu cape apheleia yasnippet-capf kind-icon yasnippet-snippets))
  (unless (package-installed-p pkg)
    (unless package-archive-contents
      (package-refresh-contents))
    (package-install pkg)))

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
  ;; 不在字符串 (String) 或注释 (Comment) 中自动弹出补全，防止如 print(" 后干扰打字
  (setq corfu-auto-skip-predicates
        (list (lambda ()
                (nth 8 (syntax-ppss))))))

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
                (list (cape-capf-super
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

(use-package markdown-mode)

(use-package nix-mode)

;; 开启 Emacs Lisp 的实时语法与错误检查（不用 LSP 也能画红线报错）
(add-hook 'emacs-lisp-mode-hook #'flymake-mode)

;; 开启括号、引号自动成对闭合
(electric-pair-mode 1)

(provide 'init-complete)
;;; init-complete.el ends here
