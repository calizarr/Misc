;; Helm
(use-package helm
  :demand
  :ensure t
  :commands (helm-M-x helm-find-files)
  :bind (
         ("M-x" . helm-M-x)
         ("C-x C-f" . helm-find-files)
         ("C-x b" . helm-mini)
         ("M-y" . helm-show-kill-ring)
         )
  :init (require 'helm-config)
  :init
  (setq helm-autoresize-mode 1)
  :config (helm-mode 1))

(use-package dash
  :demand
  :ensure t
  )

(use-package helm-projectile
  :demand
  :ensure t
  :config (helm-projectile-on)
  )
