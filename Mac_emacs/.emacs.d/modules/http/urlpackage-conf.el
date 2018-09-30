(require 'json)

(defun read-file (filename)
  (save-excursion
    (let ((new (get-buffer-create filename)) (current (current-buffer)))
      (switch-to-buffer new)
      (insert-file-contents filename)
      (mark-whole-buffer)
      (let ((contents (buffer-substring (mark) (point))))
        (kill-buffer new)
        (switch-to-buffer current)
        contents))))


(defun buffer-search-replace (pattern replace string)
  (with-temp-buffer
    (insert string)
    (goto-char (point-min))
    (while (search-forward pattern nil t)
      (replace-match replace))
    (buffer-string)))

(defun http-post-file (url file auth)
  "Send ARGS as a POST request."
  (let ((url-request-method "POST")
        (url-request-extra-headers
         `(("Content-Type" . "application/json")
           ("Authorization" . ,auth)))
        (url-request-data (read-file file)))
    (url-retrieve url 'my-switch-to-url-buffer)))

(defun http-get-no-query (url auth)
  "Send GET request to url"
  (let ((url-request-method "GET")
        (url-request-extra-headers
         `(("Content-Type" . "application/json")
           ("Authorization" . ,auth))))
    (url-retrieve url 'my-switch-to-url-buffer)))

(defun http-post-data (url data auth)
    "Send ARGS as a POST request."
  (let ((url-request-method "POST")
        (url-request-extra-headers
         `(("Content-Type" . "application/json")
           ("Authorization" . ,auth)))
        (url-request-data data))
    (url-retrieve url 'my-switch-to-url-buffer)))

(defun genome-service-http-get (url auth &optional id chrid)
  "Send ARGS as a GET request"
  (let ((url-request-method "GET")
        (url-request-extra-headers
         `(("Content-Type" . "application/json")
           ("Authorization" . ,auth)))
        (newurl
         (cond ((and id chrid) (progn (setq url (buffer-search-replace "{id}" id url))
                                      (buffer-search-replace "{chrid}" chrid url)))
               (id (buffer-search-replace "{id}" id url))
               (t `,url))))
    (url-retrieve newurl 'my-switch-to-url-buffer)))

(defun my-switch-to-url-buffer (status)
  "Switch to the buffer returned by `url-retrieve`.
The buffer contains the raw HTTP response sent by the server."
  (switch-to-buffer (current-buffer)))

(defun join-url (host endpoint)
  "Return a concatenated string of the host and endpoint"
  (string-join `(,host ,endpoint) "/"))
