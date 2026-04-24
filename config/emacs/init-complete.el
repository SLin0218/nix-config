(use-package consult)

(use-package orderless
  :config
  (setq completion-styles '(orderless basic)
        orderless-component-separator "\\s-+"))

(use-package lua-mode)
(use-package yaml-mode)

(use-package tree-sitter
  :hook
  (lua-mode . tree-sitter-mode)
  (lua-mode . tree-sitter-hl-mode)
  (yaml-mode . tree-sitter-mode)
  (yaml-mode . tree-sitter-hl-mode)
  (java-mode . tree-sitter-mode)
  (java-mode . tree-sitter-hl-mode)
  :config
  (require 'tree-sitter-langs))

(use-package tree-sitter-langs)

(use-package yasnippet
  :config
  (yas-global-mode 1))

(use-package lsp-bridge
  :ensure nil
  :init
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

(provide 'init-complete)
