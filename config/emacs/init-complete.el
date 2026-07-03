;; -*- lexical-binding: t; -*-
(use-package consult)

(use-package orderless
  :config
  (setq completion-styles '(orderless basic)
        orderless-component-separator "\\s-+"))

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

(use-package lsp-bridge
  :load-path "~/.config/slin-emacs/site-lisp/lsp-bridge"
  :ensure nil
  :init
  (setq lexical-binding t)
  (setq lsp-bridge-jdtls-workspace-exclude
        '("target" "build" "node_modules" ".gradle"))
  (setq lsp-bridge-jdtls-auto-build nil)
  :custom
  (lsp-bridge-jdtls-jvm-args '("-javaagent:/Users/lin/.local/share/nvim/mason/packages/jdtls/lombok.jar"
                               "-Djava.import.generatesMetadataFilesAtProjectRoot=false"
                               "-DDetectVMInstallationsJob.disabled=true"
                               "-Dfile.encoding=utf8"
                               "-XX:+UseParallelGC"
                               "-XX:GCTimeRatio=4"
                               "-XX:AdaptiveSizePolicyWeight=90"
                               "-Dsun.zip.disableMemoryMapping=true"
                               "-Xmx2G"
                               "-Xms100m"
                               "-Xlog:disable"
                               "-Daether.dependencyCollector.impl=bf"))
  (lsp-bridge-python-lsp-server "pyright")
  :config
  (global-lsp-bridge-mode))

(use-package markdown-mode)

(use-package nix-mode)

(provide 'init-complete)
