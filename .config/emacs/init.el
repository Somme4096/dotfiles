;;; init.el --- ef-themes + doom-leader + evil + magit + consult + org -*- lexical-binding: t; -*-

(defvar init-start-time (current-time))

;; ── Bootstrap ────────────────────────────────────────────────────
(setq package-archives
      '(("melpa" . "https://melpa.org/packages/")
        ("gnu"   . "https://elpa.gnu.org/packages/")))
(package-initialize)
(unless (package-installed-p 'use-package)
  (package-refresh-contents)
  (package-install 'use-package))
(require 'use-package)

;; ── Frame / UI ────────────────────────────────────────────────────
(set-face-attribute 'default nil
                    :height 130 :weight 'light :family "CommitMono Nerd Font")
(set-face-attribute 'bold nil :weight 'regular)
(set-face-attribute 'bold-italic nil :weight 'regular)
(setq standard-display-table (or standard-display-table (make-display-table)))
(set-display-table-slot standard-display-table 'truncation (make-glyph-code ?…))
(set-display-table-slot standard-display-table 'wrap       (make-glyph-code ?–))
(setq default-frame-alist
      '((height . 44) (width . 81)
        (left-fringe . 0) (right-fringe . 0)
        (internal-border-width . 32)
        (vertical-scroll-bars . nil)
        (bottom-divider-width . 0) (right-divider-width . 0)
        (undecorated-round . t)
        (ns-transparent-titlebar . t)
        (ns-appearance . dark)))
(modify-frame-parameters nil default-frame-alist)
(tool-bar-mode -1) (menu-bar-mode -1) (blink-cursor-mode -1)
(global-hl-line-mode 1) (pixel-scroll-precision-mode 1)
(icomplete-vertical-mode 1)
(setq-default pop-up-windows nil)
(setq ring-bell-function 'ignore
      select-enable-clipboard t)
(set-language-environment 'utf-8)

;; ── Icomplete ────────────────────────────────────────────────────
(setq tab-always-indent 'complete
      icomplete-delay-completions-threshold 0
      icomplete-compute-delay 0
      icomplete-show-matches-on-no-input t
      icomplete-hide-common-prefix nil
      icomplete-prospects-height 9
      icomplete-separator " . "
      icomplete-with-completion-tables t
      icomplete-in-buffer t
      icomplete-max-delay-chars 0
      icomplete-scroll t
      resize-mini-windows 'grow-only
      icomplete-matches-format nil)
(bind-key "TAB" #'icomplete-force-complete icomplete-minibuffer-map)
(bind-key "RET" #'icomplete-force-complete-and-exit icomplete-minibuffer-map)

;; ── Helper commands ──────────────────────────────────────────────
(defun my/quit ()
  (interactive)
  (cond ((region-active-p) (keyboard-quit))
        ((derived-mode-p 'completion-list-mode) (delete-completion-window))
        ((> (minibuffer-depth) 0) (abort-recursive-edit))
        (t (keyboard-quit))))
(defun my/kill-emacs ()
  (interactive)
  (condition-case nil (delete-frame)
    (error (save-buffers-kill-terminal))))
(defun my/make-frame () (interactive) (make-frame))
(defun my/find-inbox   () (interactive) (find-file "~/Documents/org/Inbox.org"))
(defun my/find-project () (interactive) (find-file "~/Documents/org/project.org"))
(defun my/find-archived () (interactive) (find-file "~/Documents/org/archived.org"))
(defun my/find-groceries () (interactive) (find-file "~/Documents/org/groceries.org"))
(defun my/find-study   () (interactive) (find-file "~/Documents/org/study.org"))
(defun my/org-commit ()
  (interactive)
  (let* ((default-directory (expand-file-name "~/Documents/org/"))
         (msg (format "Updated files: %s" (format-time-string "%Y-%m-%d %H:%M:%S"))))
    (call-process "git" nil nil nil "add" "--all")
    (call-process "git" nil nil nil "commit" "--all" "-m" msg)
    (when (fboundp 'magit-refresh) (magit-refresh))
    (message "Committed: %s" msg)))
(defun my/org-push ()
  (interactive)
  (let* ((default-directory (expand-file-name "~/Documents/org/"))
         (msg (format "Updated files: %s" (format-time-string "%Y-%m-%d %H:%M:%S"))))
    (call-process "git" nil nil nil "add" "--all")
    (call-process "git" nil nil nil "commit" "--all" "-m" msg)
    (call-process "git" nil nil nil "push")
    (when (fboundp 'magit-refresh) (magit-refresh))
    (message "Committed and pushed: %s" msg)))
(defun my/org-pull ()
  (interactive)
  (let ((default-directory (expand-file-name "~/Documents/org/"))
        (buf (get-buffer-create "*org-pull*")))
    (with-current-buffer buf (erase-buffer))
    (set-process-sentinel
     (start-process "org-pull" buf "git" "pull" "--rebase")
     (lambda (_p event)
       (message "org pull: %s" (string-trim event))))))

;; ── Global bindings ──────────────────────────────────────────────
(bind-key "C-x k"   #'kill-current-buffer)
(bind-key "C-x C-c" #'my/kill-emacs)
(bind-key "C-x C-r" #'recentf-open)
(bind-key "C-g"     #'my/quit)
(bind-key "M-n"     #'my/make-frame)
(bind-key "C-z"     nil)
(bind-key "<C-wheel-up>"   nil)
(bind-key "<C-wheel-down>" nil)
(cd "~/Documents/org/")
(recentf-mode 1)
(when (eq system-type 'darwin)
  (select-frame-set-input-focus (selected-frame))
  (setq mac-option-modifier nil
        ns-function-modifier 'super
        mac-right-command-modifier 'hyper
        mac-right-option-modifier 'alt
        mac-command-modifier 'meta))

;; ── Theme ────────────────────────────────────────────────────────
(use-package ef-themes
  :ensure t
  :init
  (setq modus-themes-mixed-fonts t
        modus-themes-italic-constructs t
        modus-themes-bold-constructs t
        modus-themes-disable-other-themes t)
  (ef-themes-take-over-modus-themes-mode 1)
  (modus-themes-load-theme 'ef-owl)
  :bind
  (("<f5>"   . modus-themes-rotate)
   ("C-<f5>" . modus-themes-select)
   ("M-<f5>" . ef-themes-load-random)))

;; ── Status line on top (nano style) ──────────────────────────────
(defface my-status-strong
  '((t (:inherit default :weight regular))) "")
(defface my-status-faded
  '((t (:inherit shadow))) "")
(defface my-status-default-i
  '((t (:inherit default :inverse-video t))) "")
(defface my-status-faded-i
  '((t (:inherit shadow :inverse-video t))) "")
(defface my-status-critical-i
  '((t (:inherit error :inverse-video t))) "")
(defface my-status-mode
  '((t (:inherit header-line))) "")

(defun my/refresh-status-line ()
  (set-face-attribute 'header-line nil
                      :background 'unspecified
                      :underline nil
                      :box `(:line-width 1 :color ,(face-background 'default))))
(my/refresh-status-line)
(add-hook 'modus-themes-after-load-theme-hook #'my/refresh-status-line)
(add-hook 'after-load-theme-hook #'my/refresh-status-line)

(setq-default mode-line-format nil)
(setq-default header-line-format
  '(:eval
    (let ((prefix (cond (buffer-read-only '("RO" . my-status-default-i))
                        ((buffer-modified-p) '("**" . my-status-critical-i))
                        (t '("RW" . my-status-faded-i))))
          (mode (concat "(" (downcase (cond ((consp mode-name) (car mode-name))
                                            ((stringp mode-name) mode-name)
                                            (t "unknown")))
                        " mode)"))
          (coords (format-mode-line "%c:%l ")))
      (list
       (propertize " " 'face (cdr prefix) 'display '(raise -0.25))
       (propertize (car prefix) 'face (cdr prefix))
       (propertize " " 'face (cdr prefix) 'display '(raise +0.25))
       (propertize (format-mode-line " %b ") 'face 'my-status-strong)
       (propertize mode 'face 'my-status-mode)
       (propertize " " 'display `(space :align-to (- right ,(length coords))))
       (propertize coords 'face 'my-status-faded)))))

;; ── Core packages (must come before general) ─────────────────────
(use-package evil
  :ensure t
  :init (setq evil-want-keybinding nil)
  :config (evil-mode 1))

;; ── Leader (general.el) ──────────────────────────────────────────
(defvar my-leader-map (make-sparse-keymap))
(dolist (map (list evil-normal-state-map
                   evil-visual-state-map
                   evil-motion-state-map))
  (when (keymapp map) (define-key map (kbd "SPC") my-leader-map)))

(use-package general
  :ensure t
  :config
  (general-create-definer my-leader-def
    :keymaps 'my-leader-map)
  (my-leader-def
    "SPC" '(find-file                :wk "find file")
    "/"   '(consult-grep             :wk "search")
    "b"   '(:ignore t :wk "buffer")
    "b b" '(consult-buffer           :wk "switch")
    "b k" '(kill-current-buffer      :wk "kill")
    "b r" '(revert-buffer            :wk "revert")
    "e"   '(:ignore t :wk "edit")
    "e q" '(query-replace            :wk "query-replace")
    "e l" '(org-cliplink             :wk "paste link")
    "g"   '(:ignore t :wk "git")
    "g g" '(magit-status             :wk "status")
    "g c" '(my/org-commit            :wk "commit")
    "g p" '(magit-pull               :wk "pull")
    "g P" '(my/org-push              :wk "push")
    "p"   '(:ignore t :wk "project")
    "p t" '(treemacs                 :wk "treemacs")
    "q"   '(:ignore t :wk "quick-file")
    "q i" '(my/find-inbox            :wk "inbox")
    "q p" '(my/find-project          :wk "project")
    "q a" '(my/find-archived         :wk "archived")
    "q s" '(my/find-study            :wk "study")
    "q g" '(my/find-groceries          :wk "groceries")
    "q A" '(org-agenda               :wk "agenda")
    "w"   '(:ignore t :wk "window")
    "w w" '(other-window             :wk "other")
    "w v" '(split-window-vertically  :wk "split ↓")
    "w s" '(split-window-horizontally :wk "split →")
    "w d" '(delete-window            :wk "delete")
    "w D" '(delete-other-windows     :wk "delete others"))
  (general-define-key :states 'normal :keymaps 'org-mode-map
    "TAB" #'org-cycle))

;; ── Core packages ────────────────────────────────────────────────
(use-package magit
  :ensure t)

(use-package which-key
  :ensure t
  :init (setq which-key-prefix-throttle 0.05
              which-key-idle-delay 0.1
              which-key-sort-order 'which-key-key-order-alpha)
  :config (which-key-mode 1))

(use-package treemacs
  :ensure t
  :config
  (setq treemacs-show-hidden-files t)
  (treemacs-follow-mode t)
  (treemacs-filewatch-mode t)
  (treemacs-project-follow-mode t))

(use-package consult
  :ensure t)

;; ── Org + nice-to-haves ──────────────────────────────────────────
(defun my/org-line-spacing ()
  (setq-local line-spacing 0.2))

(use-package org
  :ensure t
  :hook ((org-mode . org-indent-mode)
         (org-mode . my/org-line-spacing))
  :config
  (setq org-directory "~/Documents/org"
        org-default-notes-file "~/Documents/org/daily.org"
        org-agenda-files '("~/Documents/org/Inbox.org"
                           "~/Documents/org/project.org"
                           "~/Documents/org/archived.org"
                           "~/Documents/org/study.org")
        org-refile-targets '((org-agenda-files :maxlevel . 3))
        org-startup-folded 'content
        org-startup-indented nil
        org-blank-before-new-entry '((heading . nil) (plain-list-item . nil))
        org-todo-keywords
        '((sequence "TODO(t)" "DOING(d)" "IDEA(i)" "WAIT(w)" "ACTIVE(a)" "MEETING(m)"
                    "|"
                    "DONE(x)" "SUSPEND(s)" "CANCELLED(c)"))
        org-log-done 'time
        org-capture-templates
        '(("j" "Daily journal" entry
           (file "~/Documents/org/Inbox.org")
           "* %<%Y-%m-%d> %<%A>\n**** %U\n\n** Work log%?"))))

(use-package org-modern
  :ensure t
  :hook (org-mode . org-modern-mode))

(use-package org-appear
  :ensure t
  :hook (org-mode . org-appear-mode))

(use-package org-cliplink
  :ensure t)

(setq org-pretty-entities t
      org-pretty-entities-include-sub-superscripts t)

;; ── Org deadline/schedule notifications (appt) ───────────────────
(defun my/notify (title body)
  (pcase system-type
    ('darwin
     (start-process "my-notify" nil "osascript" "-e"
                    (format "display notification %S with title %S" body title)))
    ('gnu/linux
     (notifications-notify :title title :body body))
    (_
     (message "%s: %s" title body))))

(defun my/org-agenda-to-appt-refresh (&rest _args)
  (org-agenda-to-appt t))

(setq appt-message-warning-time 60)
(setq appt-display-interval 1)
(setq appt-disp-window-function
      (lambda (remaining _new-time msg)
        (my/notify (format "In %s minutes" remaining) msg)))
(advice-add 'appt-check :before #'my/org-agenda-to-appt-refresh)
(appt-activate t)
(org-agenda-to-appt t)

;; ── Startup benchmark ────────────────────────────────────────────
(let ((init-time (float-time (time-subtract (current-time) init-start-time)))
      (total-time (string-to-number (emacs-init-time "%f"))))
  (message (concat
    (propertize "Startup time: " 'face 'bold)
    (format "%.2fs " init-time)
    (propertize (format "(+ %.2fs system time)"
                        (- total-time init-time)) 'face 'shadow))))

;; ── Pull org repo on startup ─────────────────────────────────────
(my/org-pull)

(custom-set-variables
 ;; custom-set-variables was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 '(package-selected-packages nil))
(custom-set-faces
 ;; custom-set-faces was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 )
