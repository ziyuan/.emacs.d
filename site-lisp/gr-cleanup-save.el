;;; minor mode for stripping extra whitespace, tabs->spaces, indent on save
;;; author: Jonathan Graehl (graehl@gmail.com)

(defun gr-install-hook (h f &optional append local)
  (remove-hook h f local)
  (add-hook h f append local))

(defcustom gr-cleanup-save-except-modes '(calc-mode dired-mode)
  "A list of modes in which `gr-cleanup-save-mode' should not be activated." :type '(symbol) :group 'gr-cleanup-save)
(defcustom make-modes nil
  "A list of modes in which `gr-cleanup-untabify' and `gr-cleanup-indent' should not be activated." :type '(symbol) :group 'gr-cleanup-save)
(defcustom gr-cleanup-skip-compress-whitespace-modes '(fundamental-mode change-log-mode)
  "A list of modes in which `gr-cleanup-compress-whitespace' should not be activated." :type '(symbol) :group 'gr-cleanup-save)
(defcustom gr-cleanup-save-max-spaces 1 "after initial hanging indent, replace > this many whitespace chars with this many spaces" :type 'integer :group 'gr-cleanup-save)
(defcustom gr-cleanup-never-indent t "never automatically indent buffer when saving (this is often slow)" :type 'boolean :group 'gr-cleanup-save)
(defcustom gr-cleanup-never-compress t "never compress extra spaces when saving (this is often VERY slow)" :type 'boolean :group 'gr-cleanup-save)
(defcustom gr-cleanup-never-untabify nil "never untabify when saving (this is often slow)" :type 'boolean :group 'gr-cleanup-save)
(setq gr-cleanup-never-untabify nil)
(defcustom gr-cleanup-buffer-excessive-newlines 3 "if not nil or 0, replace excessive newlines with this many" :type 'integer :group 'gr-cleanup-save)
(defcustom gr-cleanup-compress-whitespace-fast t "use simple regex rather than syntax tables - may affect comments/strings" :type 'boolean :group 'gr-cleanup-save)
(defvar make-modes '(conf-mode conf-unix-mode makefile-gmake-mode makefile-mode fundamental-mode) "skip indent on cleanup for these modes")

(defun gr-cleanup-skip-save-p () (member major-mode gr-cleanup-save-except-modes))
(defun gr-cleanup-skip-indent-p () (or gr-cleanup-never-indent (member major-mode make-modes)))
(defun gr-cleanup-skip-untabify-p () (or gr-cleanup-never-untabify (gr-cleanup-skip-indent-p)))
(defun gr-cleanup-skip-compress-whitespace-p () (or gr-cleanup-never-compress (member major-mode gr-cleanup-skip-compress-whitespace-modes)))

(defvar gr-cleanup-save-hook nil
  "Called when `gr-cleanup-save-mode' is turned on.")

(defun gr-cleanup-ok-mode () (not (member major-mode gr-cleanup-save-except-modes)))

(defun gr-cleanup-enabled ()
  (and (gr-cleanup-ok-mode)))
                                        ;gr-cleanup-save-mode
(defun gr-cleanup-save-maybe ()
  ""
  (interactive)
  (message "gr-cleanup-save-maybe?")
  (when (gr-cleanup-enabled) (gr-cleanup-buffer-save)))

;;;###autoload
(defun turn-on-gr-cleanup-save-mode ()
  "Turn on `gr-cleanup-save-mode'"
  (interactive)
  (gr-install-hook 'before-save-hook 'gr-cleanup-save-maybe) ;; before-save-hook
  (when (gr-cleanup-ok-mode)
    (loop for h in gr-cleanup-save-hook do (funcall h))
    (gr-cleanup-save-mode +1)))

;;;###autoload
(defun turn-off-gr-cleanup-save-mode ()
  "Turn off `gr-cleanup-save-mode'"
  (interactive)
  (remove-hook 'before-save-hook 'gr-cleanup-save-maybe)
  (when (gr-cleanup-ok-mode)
    (gr-cleanup-save-mode -1)))

;;;###autoload
(define-globalized-minor-mode gr-cleanup-save-global-mode
  gr-cleanup-save-mode
  turn-on-gr-cleanup-save-mode)

;;;###autoload
(define-minor-mode gr-cleanup-save-mode
  "Wrap the buffer text with adaptive filling."
  :init-value nil
  :lighter " CS"
  )


;;; impl:


;; The regexp "\\s-+$" is too general, since form feeds (\n), carriage
;; returns (\r), and form feeds/page breaks (C-l) count as whitespace in
;; some syntaxes even though they serve a functional purpose in the file.
(defconst whitespace-regexp "[ \t]+$"
  "Regular expression which matches trailing whitespace.")

;; Match two or more trailing newlines at the end of the buffer; all but
;; the first newline will be deleted.
(defconst whitespace-eob-newline-regexp "\n\n+\\'"
  "Regular expression which matches newlines at the end of the buffer.")

(defun delete-trailing-newlines () "delete extra end-of-buffer newlines"
  (interactive)
  (save-excursion
    (goto-char (point-min))
    (and (re-search-forward whitespace-eob-newline-regexp nil t)
         (delete-region (1+ (match-beginning 0)) (match-end 0)))))


(defconst excessive-newlines-regexp "\n\n\n\n+" "regexp to replace")
(defconst excessive-newlines-replacement "\n" "replacement")
(defconst excessive-newlines-replacement-n 3 "use this may repetitions of excessive-newlines-replacement")
(defun excessive-newlines-compress (&optional nrepl)
  "replace excessive-newlines-regexp with nrepl newlines in the whole buffer"
  (interactive "p")
  (message "compress blank lines...")
  (when (eq nrepl nil) (setq nrepl excessive-newlines-replacement-n))
  (while (re-search-forward excessive-newlines-regexp (point-max) t)
    (delete-region (match-beginning 0) (match-end 0))
    (dotimes (i nrepl) (insert excessive-newlines-replacement))))

(defun gr-indent-buffer-maybe () "indent whole buffer!"
  (interactive)
  (when (not (gr-cleanup-skip-indent-p))
    (gr-indent-buffer)))

(defun gr-indent-buffer () "indent whole buffer!"
  (interactive)
  (message "indent...")
  (widen)
  (indent-region (point-min) (point-max) nil))

(defun gr-buffer-contains-substring (string)
  (save-excursion
    (save-match-data
      (goto-char (point-min))
      (search-forward string nil t))))

(defun gr-untabify-buffer ()
  (interactive)
  (when (not (gr-cleanup-skip-untabify-p))
    (message "untabify...")
    (when (gr-buffer-contains-substring "\t")
      (untabify (point-min) (point-max)))))

;; this is fast but will mess with comments and string constants (may be surprising)
(defun gr-compress-whitespace-fast-impl (&optional over)
  "starting from line-initial non-space char (after hanging indent), replace more than [over] spaces in the line or region. operates only on ascii space. if line is all spaces, no change. note: this doesn't skip string constants. [limit] is eol by DEFAULT"
  (interactive)
  (when (eq nil over) (setq over gr-cleanup-save-max-spaces))
  (let* ((maxsp (make-string over ? )) (repl (concat "\\b" maxsp " +")))
    (replace-regexp repl maxsp)))

;; this is very slow but should skip comments and strings.
(defun gr-compress-whitespace-impl (&optional over)
  "starting from line-initial non-space char (after hanging indent), replace more than [over] spaces in the line or region. operates only on ascii space. if line is all spaces, no change. note: this doesn't skip string constants. [limit] is eol by DEFAULT"
  (interactive)
  (when (eq nil over) (setq over gr-cleanup-save-max-spaces))
  (let ((maxsp (make-string over ? )) (ndel 0) (limit (point-at-eol)) s (col (current-column)))
    (backward-to-indentation 0)
    (loop until (>= (point) limit)
          do (skip-syntax-forward "^\s" limit)
          until (>= (point) limit)
          do (setq s (point))
          do (skip-syntax-forward "\s" limit)
          until (>= (point) limit)
          do (let ((ex (- (point) s over)))
               (when (> over 0)
                 (setq ndel (+ ndel over))
                 (delete-region s (point))
                 (setq limit (point-at-eol))
                 (insert maxsp))))
    (move-to-column col)
    ndel
    ))

(defun gr-compress-whitespace-impl (&optional over)
  (interactive)
  (when (eq nil over) (setq over gr-cleanup-save-max-spaces))
  (goto-char (point-min))
  (if gr-cleanup-compress-whitespace-fast
      (gr-compress-whitespace-fast-impl)
    (loop do (gr-compress-whitespace-line-impl over)
          while (= 0 (forward-line))
          )))

(defun gr-narrow-dwim-buffer ()
  (interactive)
  (if (region-active-p)
      (narrow-to-region (region-beginning) (region-end))
    (widen)))

(defun gr-narrow-dwim-line ()
  (interactive)
  (if (region-active-p)
      (narrow-to-region (region-beginning) (region-end))
    (narrow-to-region (point-at-bol) (point-at-eol))))

(defun gr-compress-whitespace-line (&optional over)
  "region if active, else line"
  (interactive)
  (save-excursion
    (save-restriction
      (gr-narrow-dwim-line)
      (gr-compress-whitespace-impl over))))

(defun gr-compress-whitespace-buffer (&optional over)
  "region if active, else buffer"
  (interactive)
  (message "compressing spaces...")
  (save-excursion
    (save-restriction
      (gr-narrow-dwim-buffer)
      (gr-compress-whitespace-impl over))))

(defmacro gr-safe-wrap (&rest body)
  `(unwind-protect
       (let (retval)
         (condition-case ex
             (setq retval (progn ,@body))
           ('error
            (message (format "Caught exception: [%s]" ex))
            (setq retval (cons 'exception (list ex)))))
         retval)))


(defun gr-cleanup-always ()
  (interactive)
  (save-excursion
    (gr-untabify-buffer)
    (gr-indent-buffer)
    (gr-compress-whitespace-buffer)
    (excessive-newlines-compress)
    (message "gr-cleanup done.")))

(defun gr-cleanup-buffer-impl ()
  "Perform a bunch of operations on the whitespace content of a buffer."
  (interactive)
  (gr-safe-wrap
   (gr-indent-buffer-maybe)
   (gr-untabify-buffer)
   (unless (or (= 0 gr-cleanup-buffer-excessive-newlines) (eq nil gr-cleanup-buffer-excessive-newlines))
     (excessive-newlines-compress gr-cleanup-buffer-excessive-newlines))
   (delete-trailing-whitespace)
   (delete-trailing-newlines)
   (if (gr-cleanup-skip-compress-whitespace-p)
       (message (format "skipping whitespace compression for mode %s" major-mode))
     (gr-compress-whitespace-impl))
   ))

(defun gr-cleanup-buffer-save ()
  "gr-cleanup-buffer catching errors"
  (message "cleaning up buffer on save (catching errors) ...")
  (save-excursion
    (gr-cleanup-buffer-impl)))
(defun gr-cleanup-buffer ()
  "Perform a bunch of operations on the whitespace content of a buffer."
  (interactive)
  (with-whole-buffer (gr-cleanup-buffer-impl)))


(provide 'gr-cleanup-save)
