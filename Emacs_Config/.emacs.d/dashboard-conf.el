;; Dashboard
(use-package page-break-lines
  :demand
  :ensure t)

(setq dashboard-banner-logo-title "Welcome back Cesar!")

(setq dashboard-items '((recents  . 5)
                        (bookmarks . 5)
                        (projects . 5)
                        (agenda . 5)
                        (registers . 5)))

(use-package dashboard
  :demand
  :ensure t
  :config (dashboard-setup-startup-hook))
