(persp-mode)
(require 'persp-projectile)
(define-key projectile-mode-map (kbd "s-x") 'projectile-persp-switch-project)
(define-key projectile-mode-map (kbd "s-s") 'persp-switch)
