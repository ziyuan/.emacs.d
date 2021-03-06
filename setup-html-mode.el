(defun my-html-mode-hook ()
  (local-set-key [f7] 'my-sgml-validate-writeback)
                                        ;  (local-set-key [\C-f7] 'sgml-validate)
  (local-set-key [(control f7)] 'sgml-validate)
  (local-set-key "\C-c\C-c\C-c" 'my-code-tag)
  (local-set-key "\C-c\C-c\C-q" 'my-preformatted)
  (local-set-key "\C-c\C-cy" 'my-yank-code)
  )

(add-hook 'html-mode-hook 'my-html-mode-hook)

(provide 'setup-html-mode)
