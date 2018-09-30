
;; Added by Package.el.  This must come before configurations of
;; installed packages.  Don't delete this line.  If you don't want it,
;; just comment it out by adding a semicolon to the start of the line.
;; You may delete these explanatory comments.
;; (package-initialize)
;; (require 'package)
;; (add-to-list 'package-archives
;;              '("elpy" . "https://jorgenschaefer.github.io/packages/"))
;; (add-to-list 'package-archives '("melpa" . "http://melpa.org/packages/"))

;; (require 'exec-path-from-shell)
;; (when (memq window-system '(max ns x))
;;   (exec-path-from-shell-initialize))

;; (require 'pretty-mode)

;; Changing prompt to y/n instead of yes/no
(defalias 'yes-or-no-p 'y-or-n-p)

;; Comment out/in region, maybe?

(defun comment-or-uncomment-line-or-region ()
  "Comments or uncomments the current line or region."
  (interactive)
  (if (region-active-p)
      (comment-or-uncomment-region (region-beginning) (region-end))
    (comment-or-uncomment-region (line-beginning-position) (line-end-position))
    )
  )
(global-set-key (kbd "C-c ;") 'comment-or-uncomment-line-or-region)

;; Don't auto-fill paragraphs with spaces
(auto-fill-mode 0)

;; Always have line numbers
(global-linum-mode 1)

;;Show Parentheses!
(show-paren-mode t)

;; Removing annoying alarm bell.
(setq visible-bell 1)

;; Remove shell command echo
(defun my-comint-init ()
  (setq comint-process-echoes t))
(add-hook 'comint-mode-hook 'my-comint-init)

;; Adding calendar insert
(require 'calendar)
(defun insdate-insert-current-date (&optional omit-day-of-week-p)
  "Insert today's date using the current locale.
  With a prefix argument, the date is inserted without the day of
  the week."
  (interactive "P*")
  (insert (calendar-date-string (calendar-current-date) nil
                                omit-day-of-week-p)))
(global-set-key "\C-x\M-d" `insdate-insert-current-date)

(custom-set-variables
 ;; custom-set-variables was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 '(ansi-color-faces-vector
   [default default default italic underline success warning error])
 '(ansi-color-for-comint-mode t)
 '(ansi-color-names-vector
   ["#212526" "#ff4b4b" "#b4fa70" "#fce94f" "#729fcf" "#e090d7" "#8cc4ff" "#eeeeec"])
 '(company-quickhelp-color-background "#454e51")
 '(company-quickhelp-color-foreground "#fafaf9")
 '(custom-enabled-themes (quote (tango-dark)))
 '(desktop-save-mode nil)
 '(eide-custom-color-theme (quote dark))
 '(ensime-sbt-command "nil")
 '(ensime-startup-notification nil)
 '(package-selected-packages
   (quote
    (xahk-mode calfw vlf magit yasnippet-snippets dashboard company-quickhelp company-jedi ido-yes-or-no ido-vertical-mode ido-completing-read+ auto-complete neotree e2wm e2wm-R persp-projectile zoom pretty-mode elscreen doremi stan-mode dirtree fish-mode eimp dired+ expand-region smartparens popup-imenu goto-chg highlight-symbol flx-ido undo-tree projectile ensime elpy csv-mode use-package exec-path-from-shell)))
 '(pop-up-frames nil)
 '(sbt:prefer-nested-projects t)
 '(undo-outer-limit 999999999999999))
(custom-set-faces
 ;; custom-set-faces was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 '(default ((t (:family "Powerline Consolas" :foundry "outline" :slant normal :weight normal :height 113 :width normal))))
 '(company-quickhelp-color-background ((t (:background "#454e51"))))
 '(company-quickhelp-color-foreground ((t (:background "#394143"))))
 '(company-scrollbar-bg ((t (:background "#454e51"))))
 '(company-scrollbar-fg ((t (:background "#394143"))))
 '(company-tooltip ((t (:inherit default :background "#32393b"))))
 '(company-tooltip-common ((t (:inherit font-lock-constant-face))))
 '(company-tooltip-selection ((t (:inherit font-lock-function-name-face)))))

;; Dired-settings
(load-file "~/.emacs.d/dired-conf.el")

;; Elpy-settings
(load-file "~/.emacs.d/elpy-conf.el")

;; Scala-mode, sbt-mode, ensime-mode settings for Scala IDE also has some globals
(load-file "~/.emacs.d/ensime-conf.el")

;; persp-projectile
;; (load-file "~/.emacs.d/persp-projectile.el")

;; Removing emacs *-bars
(load-file "~/.emacs.d/remove-bars.el")

;; Adding neotree
(load-file "~/.emacs.d/neotree.el")

;; Adding ido settings
(load-file "~/.emacs.d/ido-conf.el")

;; Adding company-mode settings
(load-file "~/.emacs.d/company-conf.el")

;; Adding dashboard settings
(load-file "~/.emacs.d/dashboard-conf.el")

;; Magit and Git settings
(load-file "~/.emacs.d/git-conf.el")

;; Very Large Files settings
(load-file "~/.emacs.d/vlf-conf.el")

;; Calendar Framework
(load-file "~/.emacs.d/calf-conf.el")

;; Window Undo!
(when (fboundp 'winner-mode)
  (winner-mode 1))

(cond ((string-equal system-type "windows-nt") (load-file "~/.emacs.d/windows-conf.el"))
      ((string-equal system-type "cygwin") (load-file "~/.emacs.d/cygwin-conf.el"))
      (t (message "We only account for windows and cygwin right now"))
      )

(global-set-key (kbd "C-x p") (kbd "C-u -1 C-x o"))
(global-set-key [24 103] (quote magit-status))
