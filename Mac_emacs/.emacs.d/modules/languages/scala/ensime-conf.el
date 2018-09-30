;; modes
;; (electric-indent-mode 0)

;; ENSIME Packge 
(use-package ensime
  :ensure t
  :pin melpa-stable
  :init
  ;; (setq ensime-search-interface 'helm)
  )

;; SBT-Mode package
(use-package sbt-mode
  :pin melpa-stable)

;; Scala-Mode package
(use-package scala-mode
  :pin melpa-stable)

(require 'ensime)

;; (use-package flx-ido
;;   :demand
;;   :init
;;   (setq
;;    ido-enable-flex-matching t
;;    ;; C-d to open directories
;;    ;; C-f to revert to find-file
;;    ido-show-dot-for-dired nil
;;    ido-enable-dot-prefix t)
;;   :config
;;   (ido-mode 1)
;;   (ido-everywhere 1)
;;   (flx-ido-mode 1))

(use-package highlight-symbol
  :diminish highlight-symbol-mode
  :commands highlight-symbol
  :bind ("s-h" . highlight-symbol))

(use-package goto-chg
  :commands goto-last-change
  ;; complementary to
  ;; C-x r m / C-x r l
  ;; and C-<space> C-<space> / C-u C-<space>
  :bind (("C-." . goto-last-change)
         ("C-," . goto-last-change-reverse)))

(use-package popup-imenu
  :commands popup-imenu
  :bind ("M-i" . popup-imenu))

(use-package yasnippet
  :diminish yas-minor-mode
  :commands yas-minor-mode
  :config (yas-reload-all))

(use-package smartparens
  :diminish smartparens-mode
  :commands
  smartparens-strict-mode
  smartparens-mode
  sp-restrict-to-pairs-interactive
  sp-local-pair
  :init
  (setq sp-interactive-dwim t)
  :config
  (require 'smartparens-config)
  (sp-use-smartparens-bindings)

  (sp-pair "(" ")" :wrap "C-(") ;; how do people live without this?
  (sp-pair "[" "]" :wrap "s-[") ;; C-[ sends ESC
  (sp-pair "{" "}" :wrap "C-{")

  ;; WORKAROUND https://github.com/Fuco1/smartparens/issues/543
  (bind-key "C-<left>" nil smartparens-mode-map)
  (bind-key "C-<right>" nil smartparens-mode-map)

  (bind-key "s-<delete>" 'sp-kill-sexp smartparens-mode-map)
  (bind-key "s-<backspace>" 'sp-backward-kill-sexp smartparens-mode-map))

(defun contextual-backspace ()
  "Hungry whitespace or delete word depending on context."
  (interactive)
  (if (looking-back "[[:space:]\n]\\{2,\\}" (- (point) 2))
      (while (looking-back "[[:space:]\n]" (- (point) 1))
        (delete-char -1))
    (cond
     ((and (boundp 'smartparens-strict-mode)
           smartparens-strict-mode)
      (sp-backward-kill-word 1))
     ((and (boundp 'subword-mode) 
           subword-mode)
      (subword-backward-kill 1))
     (t
      (backward-kill-word 1)))))

(global-set-key (kbd "C-<backspace>") 'contextual-backspace)

(sp-local-pair 'scala-mode "(" nil :post-handlers '(("||\n[i]" "RET")))
(sp-local-pair 'scala-mode "{" nil :post-handlers '(("||\n[i]" "RET") ("| " "SPC")))

(defun sp-restrict-c (sym)
  "Smartparens restriction on `SYM' for C-derived parenthesis."
  (sp-restrict-to-pairs-interactive "{([" sym))

(bind-key "s-<delete>" (sp-restrict-c 'sp-kill-sexp) scala-mode-map)
(bind-key "s-<backspace>" (sp-restrict-c 'sp-backward-kill-sexp) scala-mode-map)
(bind-key "s-<home>" (sp-restrict-c 'sp-beginning-of-sexp) scala-mode-map)
(bind-key "s-<end>" (sp-restrict-c 'sp-end-of-sexp) scala-mode-map)

(bind-key "s-{" 'sp-rewrap-sexp smartparens-mode-map)

(use-package expand-region
  :commands 'er/expand-region
  :bind ("C-=" . er/expand-region))

(require 'ensime-expand-region)
(require 'ensime-vars)
(require 'ensime-eldoc)

(add-hook 'scala-mode-hook
          (lambda ()
            (show-paren-mode)
            (smartparens-mode)
            (yas-minor-mode)
            ;; (git-gutter-mode)
            (company-mode)
            (ensime-mode)
            (scala-mode:goto-start-of-code)))

;; When entering ensime-mode, consider also the snippets in the
;; snippet table "scala-mode"
(add-hook 'ensime-mode-hook
          #'(lambda ()
              (yas-activate-extra-mode 'scala-mode)))

;; (require 'dirtree)

;; (add-to-list 'exec-path "/usr/local/bin")

;; (require 'ansi-color)
;; (defun display-ansi-colors ()
;;   (interactive)
;;   (let ((inhibit-read-only t))
;;     (ansi-color-apply-on-region (point-min) (point-max))))

;; Adding ,.sc files to scala mode
(add-to-list 'auto-mode-alist '("\\.\\(scala\\|sc\\|sbt\\)\\'" . scala-mode))

(defun ensime-router (subcmd)
  (interactive)
  "Execute the sbt `run' command for the project."
  (sbt:command (concat "run " subcmd)))

(defun ensime-sbt-do-run-main (&optional args)
  (interactive)
  (let* ((impl-class
            (or (ensime-top-level-class-closest-to-point)
                (return (message "Could not find top-level class"))))
     (cleaned-class (replace-regexp-in-string "<empty>\\." "" impl-class))
     (command (concat "ensimeRunMain" " " cleaned-class)))
    (setq last-main command)
    (sbt:command (concat command args))))

(defun ensime-sbt-do-run-last-main ()
  (interactive)
  (sbt:command last-main))

(defvar last-main nil "last called main method")
