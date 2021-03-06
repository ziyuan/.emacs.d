(defun with-sh (c) (concat ". ~/.bashrc;. ~/a; " c))
(setq compile-command (with-sh "buildgraehl forest-em"))
(setq compile-command (with-sh "HYPERGRAPH_DBG=6 LAZYK_DBG=10 test=Hypergraph/Best raccm Debug"))
(setq compile-command (with-sh "HYPERGRAPH_DBG=6 HGBEST_DBG=10 LAZYK_DBG=10 tests=Hypergraph/Best racm Debug"))
(when (string= system-name "LATTE")
  (setq inferior-octave-program "C:\\octave\\Octave3.6.1_gcc4.6.2\\bin\\octave.exe")
)
