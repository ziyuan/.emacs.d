

(defun my-code-mode-hook ()
  (show-paren-mode t)
  (local-set-key (kbd "<return>") 'newline-and-indent)
  (local-set-key (kbd "C-<return>") 'newline)
  (local-set-key (kbd "C-(") 'my-matching-paren)
  (make-local-variable 'dabbrev-case-fold-search)
  (setq dabbrev-case-fold-search nil)
  )

(add-hook 'coding-hooks 'my-code-mode-hook)

(set-coding-modes 'c js js2 c idl c++ cc java go)
(set-coding-modes 'lisp scheme lisp emacs-lisp lisp-interaction)
(set-coding-modes 'jvm java scala clojure tuareg)
(set-coding-modes 'ml ocaml ml haskell tuareg)
(set-coding-modes 'make make cmake makefile makefile-gmake jam fundamental)
(set-coding-modes 'doc LaTeX html)

(install-coding-hooks)
(provide 'setup-code-modes)
