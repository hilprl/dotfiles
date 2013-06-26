;;==============================================================================
;; TeX and LaTeX
;;==============================================================================

;; I find the default tex-mode and AucTeX quite disappointing. I'm using custom
;; functions for everything.

(defcustom tex-my-viewer "zathura --fork -s -x \"emacsclient --eval '(progn (switch-to-buffer  (file-name-nondirectory \"'\"'\"%{input}\"'\"'\")) (goto-line %{line}))'\""
  "PDF Viewer for TeX documents. You may want to fork the viewer
so that it detects when the same document is launched twice, and
persists when Emacs gets closed.

Simple command:

  zathura --fork

We can use

  emacsclient --eval '(progn (switch-to-buffer  (file-name-nondirectory \"%{input}\")) (goto-line %{line}))'

to reverse-search a pdf using SyncTeX. Note that the quotes and
double-quotes matter and must be escaped appropriately."
  :safe 'stringp)

(defcustom tex-my-compiler nil
  "[Local variable]

This is the name of the executable called upon TeX compilations.
Examples: pdftex, pdflatex, xetex, xelatex, luatex, lualatex...

If value is nil, the compiler will be tex-my-default-compiler for
TeX mode, and latex-my-default-compiler for LaTeX mode."
  :safe 'stringp)

(defcustom tex-my-masterfile nil
  "[Local variable]

The file that should be compiled."
  :safe 'stringp)

(defcustom tex-my-default-compiler "pdftex"
  "Default compiler for TeX mode. Used if tex-my-compiler is
empty."
  :safe 'stringp)

(defcustom latex-my-default-compiler "pdflatex"
  "Default compiler for LaTeX mode. Used if tex-my-compiler is
empty."
  :safe 'stringp)

(defcustom tex-my-compiler-options "-file-line-error-style -interaction nonstopmode -synctex=1"
  "The options to the tex compiler. Options are set between the
compiler name and the file name.

Interesting options:

* -file-line-error-style: change the style of error report to
   display file name and line first.

* -halt-on-error: default.

* -interaction <mode>: like -halt-on-error, you can set the way
   the compilers behave on errors. Possible values for <mode> are
   'batchmode', 'errorstopmode', 'nonstopmode' and 'scrollmode'.

* -shell-escape: allow the use of \write18{<external command>}
   from within TeX documents. This is a potential security issue.

* -synctex=1: enable SyncTeX support.

You may use file local variable for convenience:

% -*- tex-my-compiler-options: \"-shell-escape\"

Note that -shell-escape can also be toggled with universal
argument."
  :safe 'stringp)

(defcustom tex-my-startcommands ""
  "You can call a TeX compiler upon a string instead of a file.
This is actually useful if you want to customize your
compilation.

If this variable is not an empty string, the mandatory \" is
prepended and \\input\" is appended, so that the target file gets
read; otherwise the TeX compiler would stop there.

You may use it to act on the process, like the default behaviour:
  \\nonstopmode
which will continue the process whenever an error is
encountered. There is an command-line argument for that on most
compilers, that is is rarely useful.

If you use a color theme, or any conditional variable inside your
document, you may define it here:
  \\def\\myvar{mycontent}"
  :safe 'stringp)

(defun tex-my-compile ()
  "Use compile to process your TeX-based document. Use a prefix
argument to call the compiler along the '-shell-escape'
option. This will enable the use of '\write18{<external
command>}' from within TeX documents, which need to allow
external application to be called from TeX.

This may be useful for some features like GnuPlot support with TikZ.

WARNING: the -shell-escape option is a potential security issue."
  (interactive)
  (let (
        ;; Set compiler to be tex-my-compiler if not empty, or a default
        ;; compiler otherwise.
        (local-compiler
         (if (not tex-my-compiler)
             (cond
              ((string= "latex-mode" major-mode) latex-my-default-compiler)
              ((string= "plain-tex-mode" major-mode) tex-my-default-compiler)
              (t   (message "Warning: unknown major mode. Trying pdftex.") "pdftex"))
           tex-my-compiler))

        ;; Master file
        (local-master
         (if (not tex-my-masterfile)
             buffer-file-name
           tex-my-masterfile))

        ;; If tex-my-startcommands has some content, we make sure it is a string
        ;; that loads the file.
        (local-start-cmd
         (if (not (string= "" tex-my-startcommands))
             (concat "\"" tex-my-startcommands "\\input\"")))

        ;; Support of prefix argument to toggle -shell-escape.
        (local-shell-escape
         (if (equal current-prefix-arg '(4)) "-shell-escape" "")))

    (let (
          ;; Final command
          (local-compile-command
           (concat local-compiler " "  local-shell-escape " " tex-my-compiler-options " " local-start-cmd " \"" local-master "\"")))

      ;; (message local-compile-command) ;; Debug only.
      (save-buffer)
      (setq compilation-scroll-output t)
      (compile local-compile-command)

      ;; If no user interaction for 2 seconds, hide the compilation window.
      (sit-for 2)
      (delete-windows-on "*compilation*"))))


(defcustom tex-my-extension-list '("aux" "glg" "glo" "gls" "idx" "ilg" "ind" "lof" "log" "nav" "out" "snm" "synctex" "synctex.gz" "tns" "toc" "xdy")
  "List of known TeX exentsions. This list is used by 'tex-clean to purge all matching files."
  :safe 'listp)

(defun tex-clean ()
  "Remove all TeX temporary files. This command should be safe,
but there is no warranty."
  (interactive)
  (let (
        ;; Master file.
        (local-master
         (if (not tex-my-masterfile)
             buffer-file-name
           tex-my-masterfile)))

    (let (
          ;; File name without extension.
          (file
           (replace-regexp-in-string "tex" "" (file-name-nondirectory local-master))))

      ;; Concatate file name to list.
      (mapcar
       ;; Delete file if exist
       (lambda (argfile) (interactive)
         (when (and (file-exists-p argfile) (file-writable-p argfile))
           (delete-file argfile)
           (message "[%s] deleted." argfile)))
       (mapcar
        ;; Concat file name with extensions.
        (lambda (arg) (interactive) (concat file arg))
        tex-my-extension-list)))))

(defun tex-pdf-compress ()
  "PDF compressions might really strip down the PDF size. The
compression depends on the fonts used. Do not use this command if
your document embeds raster graphics."
  (interactive)
  (let (
        ;; Master file.
        (local-master
         (if (not tex-my-masterfile)
             buffer-file-name
           tex-my-masterfile)))

    (let (
          ;; Temp compressed file.
          (file-temp
           (concat (make-temp-name (concat "/tmp/" (file-name-nondirectory local-master))) ".pdf"))

          ;; File name with PDF extension.
          (file
           (replace-regexp-in-string "tex" "pdf" (file-name-nondirectory local-master))))

      (when (and (file-exists-p file) (file-writable-p file))
        (shell-command
         (concat  "gs -dBATCH -dNOPAUSE -q -sDEVICE=pdfwrite -sOutputFile=\"" file-temp "\" \"" file "\""))
        (rename-file file-temp file t)
        ))))

(defun tex-pdf-view ()
  "Call a PDF viewer for current buffer file. File name should be
properly escaped with double-quotes in case it has spaces."
  (interactive)
  (let (
        ;; Master file.
        (local-master
         (if (not tex-my-masterfile)
             buffer-file-name
           tex-my-masterfile)))

    (shell-command
     (concat tex-my-viewer
             " \""
             (replace-regexp-in-string "\.tex$" "\.pdf" (file-name-nondirectory local-master))
             "\" &" ))
    (delete-windows-on "*Async Shell Command*")))

(add-hook
 'tex-mode-hook
 (lambda ()
   (dolist (key '("\C-c\C-f" "\C-c\C-b"))
     (local-unset-key key))
   (local-set-key (kbd "C-c C-c") 'tex-my-compile)
   (local-set-key (kbd "C-c C-v") 'tex-pdf-view) ))