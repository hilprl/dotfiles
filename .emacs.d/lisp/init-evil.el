;;; Evil

;;; TODO: helm-show-kill-ring behaves like Emacs when pasting whole lines, not like Vim.

;;; TODO: Make Evil commands react more dynamically with read-only text, like eshell, wdired.
;;; Add support for I, C, D, S, s, c*, d*, R, r.
;;; See https://github.com/emacs-evil/evil/issues/852.

;;; REVIEW: 'cw' fails on the last character of the line when \n does not terminate it.
;;; See https://github.com/emacs-evil/evil/issues/863.

;;; Several packages handle relative line numbering:
;;; - nlinum-relative: Seems slow as of May 2017.
;;; - linum-relative: integrates well but not with fringe string, must be a function.
;;; - relative-line-number: linum must be disabled before running this.
(when (require 'linum-relative nil t)
  ;; REVIEW: Current symbol is displayed on all lines when we run `occur', `set-variables',
  ;; `helm-occur', etc: https://github.com/coldnew/linum-relative/issues/40.
  (setq linum-relative-current-symbol "")
  (linum-relative-toggle))

(evil-mode 1)
(remove-hook 'evil-insert-state-exit-hook 'expand-abbrev)
;; (setq evil-want-abbrev-expand-on-insert-exit nil)
(setq undo-tree-mode-lighter "")

(setq evil-cross-lines t
      evil-move-beyond-eol t ; Especially useful for Edebug.
      evil-move-cursor-back nil
      evil-want-fine-undo t)

(setq-default evil-symbol-word-search t)

;;; Commenting.
;;; M-; comments next line in VISUAL. This is because of a different newline
;;; definition between Emacs and Vim.
;;; https://github.com/redguardtoo/evil-nerd-commenter: does not work well with
;;; motions and text objects, e.g. it cannot comment up without M--.
;;; `evil-commentary' is the way to go. We don't need an additional minor-mode though.
(when (require 'evil-commentary nil t)
  (evil-global-set-key 'normal "gc" 'evil-commentary)
  (evil-global-set-key 'normal "gy" 'evil-commentary-yank))

;;; Term mode should be in emacs state. It confuses 'vi' otherwise.
;;; Upstream will not change this:
;;; https://github.com/emacs-evil/evil/issues/854#issuecomment-309085267
(evil-set-initial-state 'term-mode 'emacs)

;;; For git commit, web edits and others.
;;; Since `with-editor-mode' is not a major mode, `evil-set-initial-state' cannot
;;; be used.
;;; This requires Eshell, shells and more.
(when (require 'with-editor nil t)
  (add-hook 'with-editor-mode-hook 'evil-insert-state))

;;; Go-to-definition.
;;; From https://emacs.stackexchange.com/questions/608/evil-map-keybindings-the-vim-way.
(evil-global-set-key
 'normal "gd"
 (lambda () (interactive)
   (evil-execute-in-emacs-state)
   (call-interactively (key-binding (kbd "M-.")))))

;;; Multiedit
(when (require 'evil-multiedit nil t)
  ;; iedit exits as soon as an Evil operator is pressed.
  ;; Replace iedit's default binding with multiedit to avoid confusions.
  (global-set-key (kbd "C-;") 'evil-multiedit-match-all)
  ;; REVIEW: Some bindings are missing:
  ;; See https://github.com/hlissner/evil-multiedit/issues/20.
  (evil-multiedit-default-keybinds))

;;; Change mode-line color by Evil state.
(setq evil-default-modeline-color (cons (face-background 'mode-line) (or (face-foreground 'mode-line) "black")))
(defun ambrevar/evil-color-modeline ()
  (let ((color (cond ((minibufferp) evil-default-modeline-color)
                     ((evil-insert-state-p) '("#006fa0" . "#ffffff")) ; 00bb00
                     ((evil-emacs-state-p)  '("#444488" . "#ffffff"))
                     (t evil-default-modeline-color))))
    (set-face-background 'mode-line (car color))
    (set-face-foreground 'mode-line (cdr color))))
(add-hook 'post-command-hook 'ambrevar/evil-color-modeline)
(setq evil-mode-line-format nil)

;;; Add defun text-object. TODO: Does not work for "around".
;;; https://github.com/emacs-evil/evil/issues/874
;;; See Evil-cleverparens?
(evil-define-text-object evil-a-defun (count &optional beg end type)
  "Select a defun."
  (evil-select-an-object 'evil-defun beg end type count))
(evil-define-text-object evil-inner-defun (count &optional beg end type)
  "Select inner defun."
  (evil-select-inner-object 'evil-defun beg end type count))
(define-key evil-outer-text-objects-map "d" 'evil-a-defun)
(define-key evil-inner-text-objects-map "d" 'evil-inner-defun)

;;; Without the hook, the Edebug keys (f, n, i, etc.) would get mixed up on initialization.
(add-hook 'edebug-mode-hook 'evil-normalize-keymaps)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Mode specific bindings.

;; Note: Config must be done before `require'-ing evil-collection.
(setq evil-collection-setup-minibuffer t
      evil-collection-term-sync-state-and-mode-p t)
(when (require 'evil-collection nil t)
  (evil-collection-init))

(with-eval-after-load 'elfeed
  ;; Custom
  (evil-define-key 'normal elfeed-search-mode-map
    (kbd "S-<return>") 'elfeed-search-show-entry
    (kbd "<return>") 'ambrevar/elfeed-visit-maybe-external)
  ;; (evil-define-key 'normal elfeed-show-mode-map
  ;;   (kbd "S-<return>") 'ambrevar/elfeed-visit-maybe-external)
  (evil-define-key 'normal elfeed-show-mode-map
    (kbd "q") 'ambrevar/elfeed-kill-entry))

;; Custom Helm
(with-eval-after-load 'helm
  (global-set-key (kbd "M-y") 'helm-show-kill-ring)
  (dolist (map (list helm-find-files-map helm-read-file-map))
    (ambrevar/define-keys map
                          "M-." 'helm-end-of-buffer
                          "M-," 'helm-beginning-of-buffer))
  ;; `helm-mark-or-exchange-rect' is not needed with Evil.
  (global-set-key (kbd "C-x C-x") 'helm-all-mark-rings))

;;; nXML
;;; TODO: Add to evil-collection?
(evil-define-key 'normal nxml-mode-map
  (kbd "C-j") 'nxml-forward-element
  (kbd "C-k") 'nxml-backward-element
  (kbd "M-j") 'nxml-forward-element ; Custom
  (kbd "M-k") 'nxml-backward-element ; Custom
  ">" 'nxml-down-element
  "<" 'nxml-backward-up-element)
(evil-define-key 'visual nxml-mode-map
  (kbd "C-j") 'nxml-forward-element
  (kbd "C-k") 'nxml-backward-element
  (kbd "M-j") 'nxml-forward-element ; Custom
  (kbd "M-k") 'nxml-backward-element ; Custom
  ">" 'nxml-down-element
  "<" 'nxml-backward-up-element)


(defun ambrevar/evil-mu4e (mode _mode-keymaps &rest _rest)
  (when (eq mode 'mu4e)
    (evil-define-key 'normal mu4e-main-mode-map
      "s" 'helm-mu)
    (evil-define-key 'normal mu4e-headers-mode-map
      ;; "r" 'mu4e-compose-reply
      "s" 'helm-mu
      ;; Custom
      "x" 'ambrevar/mu4e-mark-execute-all-no-confirm
      "d" 'ambrevar/mu4e-headers-move-to-trash)
    (evil-define-key 'visual mu4e-headers-mode-map
      "s" 'helm-mu
      ;; Custom
      "x" 'ambrevar/mu4e-mark-execute-all-no-confirm
      "d" 'ambrevar/mu4e-headers-move-to-trash)
    (evil-define-key 'normal mu4e-view-mode-map
      ;; "r" 'mu4e-compose-reply
      "s" 'helm-mu
      ;; Custom
      "d" 'ambrevar/mu4e-view-move-to-trash
      "x" 'ambrevar/mu4e-mark-execute-all-no-confirm)
    ;; (evil-define-key 'normal mu4e-compose-mode-map
    ;;   "gg" 'mu4e-compose-goto-top) ; TODO: Move this upstream?
    ))
(add-hook 'evil-collection-setup-hook 'ambrevar/evil-mu4e)

(with-eval-after-load 'mu4e-conversation
  ;; (evil-define-key 'normal mu4e-conversation-mode-map
  ;;   "zv" 'mu4e-conversation-toggle-view)
  (evil-define-key 'normal mu4e-conversation-linear-map
    "zv" 'mu4e-conversation-toggle-view)
  (evil-define-key 'normal mu4e-conversation-tree-map
    "zv" 'mu4e-conversation-toggle-view)
  (evil-define-key '(normal visual) mu4e-conversation-mode-map ; TODO: Does not work?
    "#" 'mu4e-conversation-toggle-hide-cited)
  (evil-define-key '(normal visual) mu4e-conversation-linear-map
    "q" 'mu4e~view-quit-buffer
    "[" 'mu4e-conversation-previous-message ; TODO: Don't override previous-unread.
    "]" 'mu4e-conversation-next-message)
  (evil-define-key '(normal visual) mu4e-conversation-tree-map
    "C" 'mu4e-compose-new
    "R" 'mu4e-compose-reply
    "p" 'mu4e-conversation-save-attachment
    "o" 'mu4e-conversation-open-attachment
    "cc" 'mu4e-compose-new
    "cr" 'mu4e-compose-reply
    "ce" 'mu4e-compose-edit
    "cf" 'mu4e-compose-forward
    "q" 'mu4e-conversation-quit))

(with-eval-after-load 'magit
  (when (require 'evil-magit nil t)
    (evil-magit-define-key evil-magit-state 'magit-mode-map "<" 'magit-section-up)
    ;; C-j/k is the default, M-j/k is more consistent with our customization for Helm.
    (evil-magit-define-key evil-magit-state 'magit-mode-map "M-j" 'magit-section-forward)
    (evil-magit-define-key evil-magit-state 'magit-mode-map "M-k" 'magit-section-backward)))

(with-eval-after-load 'org
  ;; Don't require evil-org before org is loaded.
  ;; Elfeed-link is loaded after org.
  (when (require 'evil-org nil t)
    ;; org-evil is not as polished as of May 2017.
    ;; See https://github.com/Somelauw/evil-org-mode/blob/master/doc/keythemes.org for inspiration.
    (add-hook 'org-mode-hook 'evil-org-mode)
    ;; No need for 'insert, 'todo 'heading.
    (evil-org-set-key-theme '(navigation textobjects additional shift))
    (defun ambrevar/evil-org-meta-return ()
      "Like `org-meta-return' but switch to insert mode."
      (interactive)
      (evil-insert 1)
      (org-meta-return))
    (evil-define-key 'normal evil-org-mode-map
      "^" 'org-up-element ; Evil-Magit-inspired. TODO: Suggest upstream.
      "<" 'org-up-element ; Custom
      ">" 'org-down-element ; Custom
      (kbd "M-<return>") 'ambrevar/evil-org-meta-return)
    (with-eval-after-load 'org-agenda
      (require 'evil-org-agenda)
      (evil-org-agenda-set-keys))))

(with-eval-after-load 'gnus (require 'init-evil-gnus))

;; EWW
(defun ambrevar/evil-eww (mode _mode-keymaps &rest _rest)
  (when (eq mode 'eww)
    (evil-define-key 'operator eww-mode-map
      "t" '(menu-item
            ""
            nil
            :filter (lambda (&optional _)
                      (when (memq evil-this-operator
                                  evil-collection-yank-operators)
                        (setq evil-inhibit-operator t)
                        #'ambrevar/eww-copy-page-title))))
    (evil-define-key 'normal eww-mode-map "O" 'ambrevar/eww-open-in-new-buffer)
    (evil-define-key 'normal eww-mode-map "[" 'ambrevar/eww-previous-url)
    (evil-define-key 'normal eww-mode-map "]" 'ambrevar/eww-next-url)))
(add-hook 'evil-collection-setup-hook 'ambrevar/evil-eww)

(with-eval-after-load 'helm-eww
  (evil-define-key '(insert normal) helm-eww-buffers-map (kbd "S-<return>") 'helm-buffer-switch-other-window)
  (evil-define-key '(insert normal) helm-eww-bookmarks-map (kbd "S-<return>") 'helm-buffer-switch-other-window))

(provide 'init-evil)
