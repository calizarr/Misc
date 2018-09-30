(use-package projectile
  :demand
  :init (setq projectile-use-git-grep t)
  :config (projectile-global-mode t)
  :bind (("s-f" . projectile-find-file)
         ("s-F" . projectile-grep)))
