;;; init-prog.el --- Programming languages, LSP and code formatting  -*- lexical-binding: t; -*-

;;; Commentary:
;;
;; 编程语言环境支持：
;; 1. 项目管理 (project.el) 与 Tree-sitter (treesit-auto)。
;; 2. LSP (Eglot) 极其深度优化 (Java/JDTLS, Python/Pyright, Nix/Nixd)。
;; 3. 代码格式化 (Apheleia)、Flymake 语法检查及常规 Major Modes。
;;

;;; Code:

;; ---------------------------------------------------------------------------
;; 1. 项目管理 Project.el
;; ---------------------------------------------------------------------------
(use-package project
  :ensure nil
  :bind (:map project-prefix-map
              ("m" . project-compile))
  :config
  ;; 自定义项目根目录的识别标志
  (setq project-vc-extra-root-markers
        '("Makefile" "package.json" "go.mod" "Cargo.toml" "pyproject.toml" ".project" ".dir-locals.el"))

  ;; 忽略构建与依赖缓存目录
  (setq project-vc-ignores
        '("node_modules/" "elpa/" ".elp/" "target/" "dist/" "venv/" ".venv/"
          "build/" "bin/" ".gradle/" ".metadata/" ".settings/" ".idea/" ".vscode/"
          "__pycache__/" ".next/" ".nuxt/"))

  ;; 优化项目切换时的默认行为
  (setq project-switch-commands
        '((project-find-file "Find file" ?f)
          (project-find-regexp "Find regexp" ?g)
          (project-dired "Dired" ?d)
          (project-eshell "Eshell" ?e)))

  ;; 支持识别 .dir-locals.el 所在目录为项目根
  (defun my/project-try-dir-locals (dir)
    "Identify project roots containing .dir-locals.el."
    (let ((root (locate-dominating-file dir ".dir-locals.el")))
      (when root
        (cons 'transient (expand-file-name root)))))

  (add-to-list 'project-find-functions #'my/project-try-dir-locals))


;; ---------------------------------------------------------------------------
;; 2. Tree-sitter 语法解析支持
;; ---------------------------------------------------------------------------
(use-package treesit-auto
  :custom
  (treesit-auto-install 'prompt)
  :config
  ;; 启动时一次性构建 major-mode-remap-alist，实现 0 延迟打开文件
  (setq major-mode-remap-alist (treesit-auto--build-major-mode-remap-alist)))


;; ---------------------------------------------------------------------------
;; 3. LSP 客户端 Eglot 配置与深度集成
;; ---------------------------------------------------------------------------
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
  ;; 限制 Eglot 的文件监听，防止大项目下文件描述符被耗尽
  (setq eglot-ignored-server-capabilities '(:workspace/didChangeWatchedFiles))

  ;; 调高 GC 阈值至 64MB，优化大数据量 JSON 传输
  (add-hook 'eglot-managed-mode-hook (lambda () (setq gc-cons-threshold (* 64 1024 1024))))

  ;; 显式配置 Nix 与 Python 的 LSP 扩展
  (add-to-list 'eglot-server-programs '(nix-mode . ("nixd")))
  (add-to-list 'eglot-server-programs `((python-mode python-ts-mode) . ("pyright-langserver" "--stdio")))

  ;; 全局 LSP 工作区参数
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
                                       :contentProvider (:preferred "fernflower")))))

  ;; 自动为 JDTLS 下载调试适配器 plugin jar
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

  ;; 自动整合 Nix 注入的 JBRSDK 21 与 Lombok 的 JDTLS 启动定义
  (add-to-list 'eglot-server-programs
               `((java-mode java-ts-mode) .
                 ,(lambda (&rest _)
                    (let* ((project-root (project-root (project-current t)))
                           (cache-dir (expand-file-name (md5 project-root) "~/.cache/jdtls-workspace"))
                           (debug-jar (my/download-java-debug-adapter-if-missing))
                           (java-home (and (boundp 'nix-jbrsdk-path)
                                           nix-jbrsdk-path
                                           (file-directory-p nix-jbrsdk-path)
                                           nix-jbrsdk-path))
                           (java-bin (and java-home
                                          (expand-file-name "bin" java-home))))
                      (make-directory cache-dir t)
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

;; 纯 Emacs Lisp 拦截并解析 JDTLS 的 jdt:/ 和 jdt:// 协议，支持第三方依赖 Jar 查看
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


;; ---------------------------------------------------------------------------
;; 4. 代码格式化 (Apheleia) 与检查机制
;; ---------------------------------------------------------------------------
(use-package apheleia
  :config
  (apheleia-global-mode +1))

;; Emacs Lisp 实时语法错误检查
(add-hook 'emacs-lisp-mode-hook #'flymake-mode)

;; 括号自动闭合
(electric-pair-mode 1)


;; ---------------------------------------------------------------------------
;; 5. 常见语言 Major Modes
;; ---------------------------------------------------------------------------
(use-package markdown-mode
  :mode (("README\\.md\\'" . gfm-mode)
         ("\\.md\\'" . markdown-mode)
         ("\\.markdown\\'" . markdown-mode))
  :config
  (setq markdown-fontify-code-blocks-natively t))

(use-package nix-mode :defer t)
(use-package lua-mode :defer t)
(use-package yaml-mode :defer t)

(provide 'init-prog)
;;; init-prog.el ends here
