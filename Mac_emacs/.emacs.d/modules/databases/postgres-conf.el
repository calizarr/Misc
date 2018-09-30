;; (setq sql-connection-alist
;;       '((genome-service-dev
;;          (sql-product 'postgres)
;;          (sql-port 15432)
;;          (sql-server "localhost")
;;          (sql-user "inariuserdev")
;;          (sql-database "refgenome"))
;;         ))


;; (defun psql-genome-service-dev ()
;;   (interactive)
;;   (psql-connect 'postgres 'genome-service-dev))

;; (defun psql-connect (product connection)
;;   ;; load the password
;;   (require 'psql
  
;;   ;; remember to set the sql-product, otherwise, it will fail for the first time
;;   ;; you call the function
;;   (setq sql-product product)
;;   (sql-connect connection))
