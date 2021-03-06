(autoload 'python-mode "python-mode" "Python Mode." t)
(require 'python-mode)
(add-to-list 'auto-mode-alist '("\\.py\\'" . python-mode))
(add-to-list 'interpreter-mode-alist '("python" . python-mode))
(setq py-keys (list
               (cons (kbd "S-<f10>") 'py-pychecker-run)
               (cons (kbd "<M-left>") 'py-shift-left)
               (cons (kbd "<M-right>") 'py-shift-right)
               ))
(defun define-py-keys ()
  (mapcar (lambda (c) (list 'py-mode-map (car c) (cdr c))) py-keys))
(define-py-keys)

(defun gr-python ()

  (interactive)
  ;;  (switch-to-buffer-other-window (apply 'make-comint py-which-bufname py-which-shell nil py-which-args))
  (make-local-variable 'comint-prompt-regexp)
  (make-local-variable 'font-lock-defaults)
  (setq comint-prompt-regexp "^python% \\|^> \\|^(pdb) "
        font-lock-defaults '(python-shell-font-lock-keywords t))
  (add-hook 'comint-output-filter-functions 'py-comint-output-filter-function)
  (set-syntax-table py-mode-syntax-table)
  (use-local-map py-shell-map)
  (local-set-key "\C-a" 'comint-bol)
  (local-set-key "\C-c\C-a" 'beginning-of-line)
  (python-mode)
  (mapcar (lambda (c) (local-set-key (car c) (cdr c))) py-keys)
  ;;(local-set-key (kbd "S-<f10>") 'py-pychecker-run))
  ;;  (define-py-keys)
  (font-lock-mode)
  (setq indent-tabs-mode nil)
  (setq python-indent 2)
  (setq python-indent-offset 2)
  (setq tab-width 2)
  )


(defun my-python-send-region (beg end)
  (interactive "r")
  (if (eq beg end)
      (python-send-region (point-at-bol) (point-at-eol))
    (python-send-region beg end)))

(defun my-python-send-region2 (&optional beg end)
  (interactive)
  (let ((beg (cond (beg)
                   ((region-active-p)
                    (region-beginning))
                   (t (line-beginning-position))))
        (end (cond (end)
                   ((region-active-p)
                    (copy-marker (region-end)))
                   (t (line-end-position)))))
    (python-send-region beg end)))

(require 'autopair)

(add-hook 'python-mode-hook
          #'(lambda ()
              (setq autopair-handle-action-fns
                    (list #'autopair-default-handle-action
                          #'autopair-python-triple-quote-action))))

(provide 'setup-python)
