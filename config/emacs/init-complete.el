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

(defun my-eglot-ensure-safe ()
  "仅在关联了真实物理文件，且非后台高亮等临时上下文 (non-essential) 时，才启动 Eglot LSP."
  (when (and buffer-file-name
             (not non-essential)
             (not (string-match-p "eglot-jdtls-sources" buffer-file-name)))
    (eglot-ensure)))

(use-package eglot
  :hook
  ((python-mode python-ts-mode
                java-mode java-ts-mode
                lua-mode yaml-mode nix-mode) . my-eglot-ensure-safe)
  :config
  ;; 限制 Eglot 的文件监听，防止大项目下文件描述符被耗尽而报错 (no file descriptor left)
  (setq eglot-ignored-server-capabilities '(:workspace/didChangeWatchedFiles))

  ;; 调高 GC 阈值至 64MB，防止大数据量 JSON 传输触发频繁垃圾回收
  (add-hook 'eglot-managed-mode-hook (lambda () (setq gc-cons-threshold (* 64 1024 1024))))

  ;; 显式配置 nix 语言服务器为 nixd
  (add-to-list 'eglot-server-programs
               '(nix-mode . ("nixd")))
  ;; 显式配置 python 语言服务器为 pyright-langserver
  (add-to-list 'eglot-server-programs
               `((python-mode python-ts-mode) . ("pyright-langserver" "--stdio")))
  ;; 开启 python 补全函数时自动带上括号 () 并优化 Java (jdtls) 的全局配置
  (setq-default eglot-workspace-configuration
                '((:pyright . (:python (:analysis (:completeFunctionParens t))))
                  (:java . (:autobuild (:enabled t)
                                       :maxConcurrentBuilds 1
                                       :import (:resourceFilters ["node_modules" "\\.git" "build" "bin" "target" "dist" ".gradle" ".metadata" ".settings" ".project" ".classpath"]
                                                                 :maven (:offline (:enabled :json-false) :downloadSources t)
                                                                 :gradle (:offline (:enabled :json-false) :downloadSources t))
                                       :configuration (:updateBuildConfiguration "automatic")
                                       :referencesCodeLens (:enabled :json-false)
                                       :implementationsCodeLens (:enabled :json-false)
                                       :completion (:favoriteStaticMembers ["org.junit.Assert.*" "org.mockito.Mockito.*"] :importOrder ["java" "javax" "org" "com"])
                                       :eclipse (:downloadSources t)
                                       :contentProvider (:preferred "fernflower")))
                  ))

  (defun my/download-java-debug-adapter-if-missing ()
    "Download vscode-java-debug plugin jar if it is not present in cache."
    (let* ((debug-dir (expand-file-name "~/.config/emacs/.cache/java-debug"))
           (jar-pattern (expand-file-name "com.microsoft.java.debug.plugin-*.jar" debug-dir))
           (existing-jars (file-expand-wildcards jar-pattern)))
      (if existing-jars
          (car existing-jars)
        (make-directory debug-dir t)
        (let* ((version "0.53.0")
               (jar-name (format "com.microsoft.java.debug.plugin-%s.jar" version))
               (target-file (expand-file-name jar-name debug-dir))
               (url (format "https://repo1.maven.org/maven2/com/microsoft/java/com.microsoft.java.debug.plugin/%s/%s"
                            version jar-name)))
          (message "Downloading vscode-java-debug-adapter jar from maven...")
          (url-copy-file url target-file t)
          (message "Download finished: %s" target-file)
          target-file))))


  (use-package project
    :ensure nil ; project.el 是内置的，不需要额外下载
    :bind (:map project-prefix-map
                ("m" . project-compile)) ; 绑定快捷键 C-x p m 快速编译
    :config
    ;; 1. 自定义项目根目录的识别标志，增加了 .dir-locals.el 标志
    (setq project-vc-extra-root-markers
          '("Makefile" "package.json" "go.mod" "Cargo.toml" "pyproject.toml" ".project" ".dir-locals.el"))

    ;; 2. 忽略特定的文件夹，避免全局搜索时卡顿 (添加了大量的缓存与编译目录)
    (setq project-vc-ignores
          '("node_modules/" "elpa/" ".elp/" "target/" "dist/" "venv/" ".venv/"
            "build/" "bin/" ".gradle/" ".metadata/" ".settings/" ".idea/" ".vscode/"
            "__pycache__/" ".next/" ".nuxt/"))

    ;; 3. 优化项目切换时的行为：切换项目时直接打开文件列表
    (setq project-switch-commands
          '((project-find-file "Find file" ?f)
            (project-find-regexp "Find regexp" ?g)
            (project-dired "Dired" ?d)
            (project-eshell "Eshell" ?e)))

    ;; 4. 注册自定义的 .dir-locals.el 项目识别逻辑到 project-find-functions
    (defun my/project-try-dir-locals (dir)
      "Identify project roots containing .dir-locals.el."
      (let ((root (locate-dominating-file dir ".dir-locals.el")))
        (when root
          (cons 'transient (expand-file-name root)))))

    (add-to-list 'project-find-functions #'my/project-try-dir-locals))

  ;; 显式配置 java 语言服务器 jdtls 的启动参数（加入 lombok 等参数，并进行全方位性能优化）
  (add-to-list 'eglot-server-programs
               `((java-mode java-ts-mode) .
                 ,(lambda (&rest _)
                    (let* ((project-root (project-root (project-current t)))
                           (cache-dir (expand-file-name (md5 project-root) "~/.cache/jdtls-workspace"))
                           (debug-jar (my/download-java-debug-adapter-if-missing))
                           ;; 使用 Nix 注入的 JBRSDK 21 路径作为 Java Home
                           (java-home (and (boundp 'nix-jbrsdk-path)
                                           nix-jbrsdk-path
                                           (file-directory-p nix-jbrsdk-path)
                                           nix-jbrsdk-path))
                           (java-bin (and java-home
                                          (expand-file-name "bin" java-home))))
                      (make-directory cache-dir t)
                      ;; 强行将 Java 21 的 bin 目录放置在 PATH 环境变量与 Emacs 内部 exec-path 的最前面，
                      ;; 确保 jdtls wrapper 脚本优先采用 Java 21，消灭 JDK 版本不一致 Warning
                      (let ((process-environment (if (not (string-empty-p java-home))
                                                     (cons (format "JAVA_HOME=%s" java-home)
                                                           (cons (format "PATH=%s:%s" java-bin (getenv "PATH"))
                                                                 process-environment))
                                                   process-environment))
                            (exec-path (if java-bin
                                           (cons java-bin exec-path)
                                         exec-path)))
                        `("jdtls"
                          "-data" ,cache-dir
                          "--jvm-arg=-javaagent:/Users/lin/.local/share/nvim/mason/packages/jdtls/lombok.jar"
                          "--jvm-arg=-Djava.import.generatesMetadataFilesAtProjectRoot=false"
                          "--jvm-arg=-DDetectVMInstallationsJob.disabled=true"
                          "--jvm-arg=-Dfile.encoding=utf8"
                          "--jvm-arg=-XX:+UseG1GC"
                          "--jvm-arg=-XX:+UseStringDeduplication"
                          "--jvm-arg=-Dsun.zip.disableMemoryMapping=true"
                          "--jvm-arg=-Dlog.level=WARNING"
                          "--jvm-arg=-Xmx4G"
                          "--jvm-arg=-Xms4G"
                          "--jvm-arg=-Xlog:disable"
                          "--jvm-arg=-Daether.dependencyCollector.impl=bf"
                          :initializationOptions
                          (:extendedClientCapabilities (:classFileContentsSupport t)
                                                       ,@(when debug-jar `(:bundles [,debug-jar]))
                                                       :settings (:java ,(or (cdr (assoc :java eglot-workspace-configuration))
                                                                             '(:autobuild (:enabled t)
                                                                                          :maxConcurrentBuilds 1
                                                                                          :import (:resourceFilters ["node_modules" "\\.git" "build" "bin" "target" "dist" ".gradle" ".metadata" ".settings" ".project" ".classpath"]
                                                                                                                    :maven (:offline (:enabled :json-false) :downloadSources t)
                                                                                                                    :gradle (:offline (:enabled :json-false) :downloadSources t))
                                                                                          :configuration (:updateBuildConfiguration "automatic")
                                                                                          :referencesCodeLens (:enabled :json-false)
                                                                                          :implementationsCodeLens (:enabled :json-false)
                                                                                          :eclipse (:downloadSources t)
                                                                                          :contentProvider (:preferred "fernflower"))))))))))))

;; 纯 Emacs Lisp 拦截并解析 JDTLS 的 jdt:/ 和 jdt:// 协议，实现依赖 jar 跳转定义
(with-eval-after-load 'eglot
  (defun +eglot/jdtls-uri-to-path (uri)
    "Support Eclipse jdtls `jdt:/' and `jdt://' uri scheme by fetching content."
    (when (string-prefix-p "jdt:" uri)
      (let ((server (eglot-current-server)))
        (when server
          (let* ((md5-hash (md5 uri))
                 (class-name (if (string-match "/\\([^/?]+\\)\\(?:\\.class\\|\\.java\\)" uri)
                                 (match-string 1 uri)
                               "UnknownClass"))
                 (filename (format "%s_%s.java" class-name md5-hash))
                 (source-dir (expand-file-name "eglot-jdtls-sources" (temporary-file-directory)))
                 (source-file (expand-file-name filename source-dir)))
            (unless (file-directory-p source-dir)
              (make-directory source-dir t))
            (unless (file-readable-p source-file)
              (let ((content (jsonrpc-request server
                                              :java/classFileContents
                                              (list :uri uri))))
                (with-temp-file source-file
                  (insert content))))
            source-file)))))

  (advice-add (if (fboundp 'eglot-uri-to-path) 'eglot-uri-to-path 'eglot--uri-to-path)
              :around
              (lambda (orig-fn uri &rest args)
                (or (+eglot/jdtls-uri-to-path uri)
                    (apply orig-fn uri args)))))

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

(use-package markdown-mode
  :mode (("README\\.md\\'" . gfm-mode)
         ("\\.md\\'" . markdown-mode)
         ("\\.markdown\\'" . markdown-mode))
  :config
  ;; 开启代码块内原生语法高亮
  (setq markdown-fontify-code-blocks-natively t))

(use-package nix-mode :defer t)

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
                 ;; Stop at another section
                 ((string-match-p "^\\[" line)
                  (setq continue nil))
                 ;; Skip comments and empty lines
                 ((or (string-empty-p line)
                      (string-match-p "^[#;]" line))
                  nil)
                 ;; Parse connection line
                 ((string-match "^\\([^#=; \t\n]+\\)[ \t]*=[ \t]*mysql://\\(?:\\([^:@/]+?\\)\\(?::\\(.*\\)\\)?@\\)?\\([^:@/ \t\n]+\\)\\(?::\\([0-9]+\\)\\)?\\(?:/\\([^? \t\n]*\\)\\)?$" line)
                  (let* ((name (match-string 1 line))
                         (user-raw (match-string 2 line))
                         (pass-raw (match-string 3 line))
                         (host (match-string 4 line))
                         (port-str (match-string 5 line))
                         (db-raw (match-string 6 line))
                         ;; Process extracted match strings
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

(require 'url-util)
(my-load-db-connections-from-myclirc)

(use-package sql
  :defer t
  :bind (:map sql-mode-map
              ("C-c C-c" . sql-send-paragraph)
              ("C-c C-r" . sql-send-region)
              ("C-c C-s" . sql-show-sqli-buffer))
  :config
  ;; 优化 SQL 交互窗口 (SQLi) 体验
  (add-hook 'sql-interactive-mode-hook
            (lambda ()
              (toggle-truncate-lines t)
              (setq-local show-trailing-whitespace nil)))

  ;; 解决 MySQL/MariaDB 连接时的 SSL/TLS 自签名证书报错问题
  (setq sql-mysql-options '("--skip-ssl")))

(use-package sql-indent
  :hook (sql-mode . sql-indent-enable))

(use-package sqlformat
  :defer t
  :bind (:map sql-mode-map
              ("C-c C-f" . sqlformat-buffer))
  :init
  ;; 默认格式化器使用 pgformatter，也可以根据喜好设为 'sqlfluff
  (setq sqlformat-command 'pgformatter))

;; 开启 Emacs Lisp 的实时语法与错误检查（不用 LSP 也能画红线报错）
(add-hook 'emacs-lisp-mode-hook #'flymake-mode)

;; 开启括号、引号自动成对闭合
(electric-pair-mode 1)

;; 现代化交互式数据库客户端 Clutch
(use-package mysql :ensure t)
(use-package clutch
  :ensure t
  :config
  ;; 禁用结果、记录与详情缓冲区的行号显示，让表格布局更加整齐
  (add-hook 'clutch-result-mode-hook (lambda () (display-line-numbers-mode -1)))
  (add-hook 'clutch-record-mode-hook (lambda () (display-line-numbers-mode -1)))
  (add-hook 'clutch-describe-mode-hook (lambda () (display-line-numbers-mode -1))))

;; 优化代码跳转 (xref) 体验：
;; 1. 不弹出单独的 *xref* 窗口，直接在 minibuffer (Vertico) 中进行选择。
;; 2. 若只有一条数据，则不弹窗，直接跳转过去。
;; 3. 多条数据时在 Minibuffer 展现，并在上面窗口实时显示预览（在列表中移动时自动预览目标代码位置）。
;; 4. 仅显示相对于项目根目录的 “路径:行号”（例如 src/main.rs:12），过滤掉长长的具体代码内容。
(use-package xref
  :ensure nil
  :config
  (defun my/consult-xref--candidates (xrefs)
    (let ((root (and (project-current) (project-root (project-current)))))
      (mapcar (lambda (xref)
                (let* ((loc (xref-item-location xref))
                       (group (and loc (xref-location-group loc)))
                       (group-rel (if (and root group) (file-relative-name group root) group))
                       (line (and loc (xref-location-line loc)))
                       ;; 格式化为：行号:相对路径，例如 12:src/main.rs
                       (cand (if line
                                 (format "%s:%s" line (or group-rel "unknown"))
                               (or group-rel "unknown"))))
                  (add-text-properties
                   0 1 `(consult-xref ,xref) cand)
                  cand))
              xrefs)))

  (defun my/consult-xref (fetcher &optional alist)
    (require 'consult)
    (require 'consult-xref)
    (let* ((real-xrefs (if (functionp fetcher) (funcall fetcher) fetcher))
           (candidates (my/consult-xref--candidates real-xrefs))
           (display (alist-get 'display-action alist)))
      (unless candidates
        (user-error "No xref locations"))
      (xref-pop-to-location
       (if (cdr candidates)
           (consult--read
            candidates
            :command #'my/consult-xref
            :prompt "Go to xref: "
            :history 'consult-xref--history
            :require-match t
            :sort nil
            :category 'consult-xref
            ;; 去掉 :group 属性以取消 Vertico 的分组标题（防止同一项显示两行）
            :state
            (when-let* ((fun (pcase display
                               ('frame nil)
                               ('window #'switch-to-buffer-other-window)
                               (_ #'switch-to-buffer))))
              (consult-xref--preview fun))
            :lookup (apply-partially #'consult--lookup-prop 'consult-xref))
         (get-text-property 0 'consult-xref (car candidates)))
       display)))

  (setq xref-show-definitions-function #'my/consult-xref)
  (setq xref-show-xrefs-function #'my/consult-xref))

(use-package dape
  :defer t
  :init
  ;; 定义 Java 热重载 (Hot Code Replace) 触发函数
  (defun my/dape-java-hot-code-replace ()
    "Trigger Hot Code Replace (redefineClasses) for all active Java debugging sessions in Dape."
    (interactive)
    (if-let ((connections (and (fboundp 'dape--live-connections) (dape--live-connections))))
        (dolist (conn connections)
          (message "Triggering Java Hot Code Replace for connection: %s" conn)
          (dape-request conn "redefineClasses" nil
                        (lambda (_conn error)
                          (if error
                              (message "Hot Code Replace failed: %s" (plist-get error :message))
                            (message "Hot Code Replace succeeded!")))))
      (message "No active Dape debug session.")))

  ;; 保存 Java 文件时自动触发热代码替换
  (defun my/dape-java-hot-code-replace-on-save ()
    "Automatically trigger hot code replace after save for Java buffers when debugging."
    (when (and (derived-mode-p 'java-mode 'java-ts-mode)
               (fboundp 'dape--live-connections)
               (dape--live-connections))
      ;; 延迟 1.2 秒执行，留给 jdtls/eglot 足够时间编译生成新的 class 文件
      (run-with-idle-timer 1.2 nil
                           (lambda ()
                             (when (dape--live-connections)
                               (dolist (conn (dape--live-connections))
                                 (dape-request conn "redefineClasses" nil
                                               (lambda (_conn error)
                                                 (if error
                                                     (message "Java HCR auto-reload failed: %s" (plist-get error :message))
                                                   (message "Java HCR auto-reload success!"))))))))))

  (add-hook 'after-save-hook #'my/dape-java-hot-code-replace-on-save)

  :config
  ;; 注册本地 Spring Boot 的远程附加调试配置 (Attach)
  (add-to-list 'dape-configs
               `(attach-springboot
                 modes (java-mode java-ts-mode)
                 ensure (lambda (config)
                          (unless (and (featurep 'eglot) (eglot-current-server))
                            (user-error "No eglot instance active in buffer %s" (current-buffer))))
                 fn (lambda (config)
                      (if-let* ((server (eglot-current-server))
                                (port (eglot-execute-command server "vscode.java.startDebugSession" nil)))
                          (thread-first
                            config
                            (plist-put 'port port))
                        (user-error "Failed to start debug session via JDTLS")))
                 :type "java"
                 :request "attach"
                 :hostName "localhost"
                 :port 5005)))

(provide 'init-complete)
;;; init-complete.el ends here
