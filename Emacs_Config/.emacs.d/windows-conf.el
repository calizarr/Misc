;; (setq shell-file-name "D:/cygwin64/bin/bash")
;; (setq explicit-shell-file-name shell-file-name)
;; (setq explicit-bash-args '("--login"))

;; (defun cygwin-shell ()
;;   "Run cygwin bash in shell mode."
;;   (interactive)
;;   (let ((explicit-shell-file-name "D:/cygwin64/bin/bash"))
;;     (call-interactively 'shell)))

(defun my-bash-on-windows-shell ()
  (interactive)
  (let ((explicit-shell-file-name "C:/Windows/System32/bash.exe"))
    (shell)))

(defun set-prompt ()
  (interactive)
  (comint-send-string "*shell*" "export PS1='\\u@\\h:\\w\\$ '\n")
  )

(setq w32-pass-apps-to-system nil)
(setq w32-apps-modifier 'hyper) ; Menu/App key

(define-key function-key-map (kbd "<f13>") 'event-apply-super-modifier)
(message "We have loaded the GNU Emacs specific windows configurations!")
