(require 'package)
(add-to-list 'package-archives '("melpa" . "https://melpa.org/packages/") t)
(package-initialize)

(unless (package-installed-p 'use-package)
  (package-refresh-contents)
  (package-install 'use-package))

(use-package json-mode :ensure t)
(use-package yaml-mode :ensure t)
(use-package csv-mode :ensure t)

(use-package company
  :ensure t
  :config
  (add-hook 'after-init-hook 'global-company-mode)
  (setq company-idle-delay 0)
  (setq company-minimum-prefix-length 1))

(use-package emmet-mode
  :ensure t
  :config
  (add-hook 'sgml-mode-hook 'emmet-mode)
  (add-hook 'css-mode-hook 'emmet-mode))

(use-package js2-mode
  :ensure t
  :mode "\\.js\\'")

(defun setup-tide-mode ()
  (interactive)
  ;;  (setq tide-tsserver-process-environment '("TSS_LOG=-level verbose -file /tmp/tss.log"))
  (tide-setup)
  (if (file-exists-p (concat tide-project-root "node_modules/typescript/bin/tsserver"))
    (setq tide-tsserver-executable "node_modules/typescript/bin/tsserver"))
  (flycheck-mode +1)
  (setq flycheck-check-syntax-automatically '(save mode-enabled))
  (eldoc-mode +1)
  (tide-hl-identifier-mode +1)
  (setq tide-format-options '(:indentSize 2 :tabSize 2 :insertSpaceAfterFunctionKeywordForAnonymousFunctions t :placeOpenBraceOnNewLineForFunctions nil))
  (local-set-key (kbd "C-c d") 'tide-documentation-at-point)
  (company-mode +1)
  (setq company-minimum-prefix-length 1))

(use-package tide
  :ensure t
  :config
  (progn
    (company-mode +1)
    ;; aligns annotation to the right hand side
    (setq company-tooltip-align-annotations t)
    (add-hook 'typescript-mode-hook #'setup-tide-mode)
    (add-to-list 'auto-mode-alist '("\\.ts\\'" . typescript-mode))))

;; use web-mode + tide-mode for javascript instead
(use-package js2-mode
  :ensure t
  :config
  (progn
    (add-hook 'js2-mode-hook #'setup-tide-mode)
    ;; configure javascript-tide checker to run after your default javascript checker
    (setq js2-basic-offset 2)
    (flycheck-add-next-checker 'javascript-eslint 'javascript-tide 'append)
    (add-to-list 'interpreter-mode-alist '("node" . js2-mode))
    (add-to-list 'auto-mode-alist '("\\.js\\'" . js2-mode))))

;; (add-to-list 'interpreter-mode-alist '("node" . js2-mode))

(use-package json-mode
  :ensure t
  :config
  (progn
    (flycheck-add-mode 'json-jsonlint 'json-mode)
    (add-hook 'json-mode-hook 'flycheck-mode)
    (setq js-indent-level 2)
    (add-to-list 'auto-mode-alist '("\\.json" . json-mode))))

(use-package web-mode
  :ensure t
  :config
  (progn
    (add-to-list 'auto-mode-alist '("\\.tsx\\'" . web-mode))
    (add-to-list 'auto-mode-alist '("\\.js"     . web-mode))
    (add-to-list 'auto-mode-alist '("\\.html"   . web-mode))
    ;; this magic incantation fixes highlighting of jsx syntax in .js files
    (setq web-mode-content-types-alist
          '(("jsx" . "\\.js[x]?\\'")))
    (add-hook 'web-mode-hook
              (lambda ()
                (setq web-mode-code-indent-offset 2)
                (when (string-equal "tsx" (file-name-extension buffer-file-name))
                  (setup-tide-mode))
                (when (string-equal "jsx" (file-name-extension buffer-file-name))
                  (setup-tide-mode))
                (when (string-equal "js" (file-name-extension buffer-file-name))
                  (progn
                    (setup-tide-mode)
                    (with-eval-after-load 'flycheck
                      (flycheck-add-mode 'typescript-tslint 'web-mode)
                      (flycheck-add-mode 'javascript-tide 'web-mode))))))))

(use-package prettier-js
  :ensure t
  :after (rjsx-mode)
  :hook (rjsx-mode . prettier-js-mode))

(use-package undo-tree
  :ensure t
  :bind (("C-x /" . undo-tree-visualize))
  :config
  (unbind-key "C-b" undo-tree-visualizer-mode-map)
  (global-undo-tree-mode t)
  :custom
  (undo-tree-visualizer-diff t)
  (undo-tree-visualizer-timestamps t)
  (undo-tree-visualizer-relative t))

(use-package evil
  :ensure t
  :init
  (setq evil-search-module 'evil-search)
  (setq evil-ex-complete-emacs-commands nil)
  (setq evil-vsplit-window-right t)
  (setq evil-split-window-below t)
  (setq evil-shift-round nil)
  (setq evil-want-fine-undo t)
  (setq evil-want-keybinding nil) ;; required for evil-collection
  :config
  (evil-set-undo-system 'undo-tree)
  (evil-mode 1))

  ;; Example of how to map a evil normal mode command
  ;; (define-key evil-normal-state-map (kbd ", w") 'evil-window-vsplit))

;; Adds compatibility with Magit and other things
(use-package evil-collection
  :ensure t
  :config
  (evil-collection-init))


;; Surround
(use-package evil-surround
  :ensure t
  :config
  (global-evil-surround-mode 1))


;; Org Agenda
(use-package evil-org
  :ensure t
  :after org
  :hook (org-mode . (lambda () evil-org-mode))
  :config
  (require 'evil-org-agenda)
  (evil-org-agenda-set-keys))

(electric-pair-mode 1)

(use-package org
  :config
  ;; add a src block with C-c C-, s
  (add-to-list 'org-structure-template-alist '("s" . "src"))
  (global-set-key (kbd "C-c c") 'org-capture)
  (setq org-default-notes-file "~/.notes.org")
  (setq org-agenda-files '("~/.notes.org")))

(use-package org-roam
  :ensure t
  :bind (("C-c n l" . org-roam-buffer-toggle)
         ("C-c n f" . org-roam-node-find)
         ("C-c n i" . org-roam-node-insert)
         ("C-c n c" . org-roam-capture))
  :config
  (org-roam-db-autosync-mode)jj)

;; Capture templates taken from https://jethrokuan.github.io/org-roam-guide/
(setq org-roam-capture-templates
      '(("m" "main" plain "%?"
	 :if-new (file+head "main/${slug}.org"
			    "#+title: ${title}\n")
	 :immediate-finish t
	 :unnarrowed t)
	("r" "reference" plain "%?"
	 :if-new
	 (file+head "reference/${title}.org" "#+title: ${title}\n")
	 :immetiate-finish t
	 :unnarrowed t)
	("i" "idea" plain "%?"
	 :if-new
	 (file+head "ideas/${title}.org" "#+title: ${title}\n#+filetags: :idea:\ne")
	 :immetiate-finish t
	 :unnarrowed t)
	("t" "tag" plain "%?"
	 :if-new
	 (file+head "ideas/${title}.org" "#+title: ${title}\n#+filetags: :tag:\ne")
	 :immetiate-finish t
	 :unnarrowed t)
	("a" "article" plain "%?"
	 :if-new
	 (file+head "articles/${title}.org"
		    "#+title: ${title}\n#+filetags: :article:\ne")
	 :immediate-finish t
	 :unnarrowed t)))

(require 'org-roam)
(cl-defmethod org-roam-node-type ((node org-roam-node))
  "Return the TYPE of NODE."
  (condition-case nil
      (file-name-nondirectory
       (directory-file-name
	(file-name-directory
	 (file-relative-name (org-roam-node-file node) org-roam-directory))))
    (error "")))


(global-set-key (kbd "C-c n c") 'org-roam-capture)

(setq org-roam-node-display-template
      (concat "${type:15} ${title:*} " (propertize "${tags:10}" 'face 'org-tag)))

(defun me/tag-as-draft ()
  (org-roam-tag-add '("draft")))

(add-hook 'org-roam-capture-new-node-hook #'me/tag-as-draft)

(use-package org-roam-ui
  :ensure t
  :after org-roam
  :hook (after-init . org-roam-ui-mode)
  :config
  (setq org-roam-ui-sync-theme t
        org-roam-ui-follow t
        org-roam-ui-update-on-save t
        org-roam-ui-open-on-start t))

(require 'org)
(setq org-src-window-setup "current-window")

(use-package magit
  :ensure t)

;; We need ex-gfm for github-flavored-markdown export
(use-package ox-gfm
   :ensure t)

(defun gh-issue-new-url (project title body)
  (concat "https://github.com/"
          project
          "/issues/new?title="
          (url-hexify-string title)
          "&body="
          (url-hexify-string body)))

(defun gh-issue-new-browse (project title body)
  (browse-url (gh-issue-new-url project title body)))

(defun gh-issue-get-project ()
  (org-entry-get (point) "GH-PROJECT" t))

(defun gh-issue-create ()
  (interactive)
  (gh-issue-new-browse (gh-issue-get-project)
                       (org-get-heading)
                       (org-export-as 'gfm t)))

(use-package counsel
  :ensure t
  :config
  (ivy-mode 1)
  (setq ivy-use-virtual-buffers t)
  (setq ivy-count-format "(%d/%d) "))

(load-theme 'wombat)

(when window-system (add-hook 'prog-mode-hook 'hl-line-mode))

(when window-system
  (use-package pretty-mode
    :ensure t
    :config
    (global-pretty-mode t)))

(setq-default
 inhibit-startup-message t
 visible-bell t
 vc-follow-symlinks t
 indent-tabs-mode nil
 native-comp-async-report-warnings-errors nil)

(setq ring-bell-function 'ignore)

(use-package async
  :ensure t
  :init (dired-async-mode 1))

(use-package exwm
  :ensure t
  :config
    (require 'exwm-config)
    (exwm-config-default) ;; we don't need to get fancy here
    (setq exwm-workspace-number 3) ;; going with 3 only because I have 3 displays

    ;; Uncle Dave said that this was the best way to set global keybinds
    ;; The `s` in the keybinds is the Super key, if you aren't already hip to that
    (exwm-input-set-key (kbd "s-r") #'exwm-reset)


    ;; i3 style mod-n workspace switching, it also creates them so be careful with that
    (dotimes (i 10)
      (exwm-input-set-key (kbd (format "s-%d" i))
                          `(lambda ()
                             (interactive)
                             (exwm-workspace-switch-create ,i))))



    ;; this little bit will make sure that XF86 keys work in exwm buffers as well
    (dolist (k '(XF86AudioLowerVolume
                 XF86AudioRaiseVolume
                 XF86PowerOff
                 XF86AudioMute
                 XF86AudioPlajy
                 XF86AudioStop
                 XF86AudioPrev
                 XF86AudioNext
                 XF86ScreenSaver
                 XF68Back
                 XF86Forward
                 Scroll_Lock
                 print
                 ?\C-w
                 ?\C-l ;; Some custom prefix keys as well
                 ?\C-b
                 ?\C-a))
    (cl-pushnew k exwm-input-prefix-keys)))

(defun media/vol-up ()
    (interactive)
    (start-process-shell-command "volume-up" nil "pactl set-sink-volume @DEFAULT_SINK@ +10%"))

(defun media/vol-down ()
    (interactive)
    (start-process-shell-command "volume-down" nil "pactl set-sink-volume @DEFAULT_SINK@ -10%"))

(defun media/vol-set ()
  (interactive)
  (start-process "volume-set" nil "pactl" "set-sink-volume" "@DEFAULT_SINK@" (read-string "Set volume (%): ")))

(defun media/vol-mute ()
  (interactive)
  (start-process "volume-set" nil "pactl" "set-sink-volume" "0" "0%"))


(exwm-input-set-key (kbd "<XF86AudioRaiseVolume>") #'media/vol-up)
(exwm-input-set-key (kbd "<XF86AudioLowerVolume>") #'media/vol-down)
(exwm-input-set-key (kbd "<XF86AudioMute>") #'media/vol-mute)

(global-set-key (kbd "s-j") 'windmove-down)
(global-set-key (kbd "s-k") 'windmove-up)
(global-set-key (kbd "s-h") 'windmove-left)
(global-set-key (kbd "s-l") 'windmove-down)

;; Allow resizing with mouse, of non-floating windows.
(setq window-divider-default-bottom-width 2
      window-divider-default-right-width 2)

(window-divider-mode)

(require 'exwm-randr)
(exwm-randr-enable)

;; This part's only going to work for my setup

(defun me/nicer-xrandr-nonsense (command)
  (start-process-shell-command "xrandr" nil command))

(add-hook 'exwm-randr-screen-change-hook
      (lambda ()
	;; script from arandr
	;; I tried to move it to a separate file but then my WM exploded
	(me/nicer-xrandr-nonsense (concat
				   "xrandr "
				   "--output eDP-1 --primary --mode 1920x1200 --pos 1440x1952 --rotate normal "
				   "--output DP-1 --off " ;; These --off lines might not matter
				   "--output DP-2 --off " 
				   "--output DP-3 --off "
				   "--output DP-1-1 --off "
				   "--output DP-1-2 --mode 2560x1440 --pos 1440x512 --rotate normal "
				   "--output DP-1-3 --mode 2560x1440 --pos 0x0 --rotate left"))))

;; Now we have to tell exwm which workspaces to put to each output
(setq exwm-randr-workspace-output-plist '(0 "eDP-1" 1 "DP-1-2" 2 "DP-1-3"))

;; In case of laptop disconnection
(defun me/workspaces-lost-on-ghost-monitors ()
  (setq exwm-randr-workspace-output-plist '(0 "eDP-1" 1 "eDP-1" 2 "eDP-1")))

;; Lets have some nice keybinds as well
(global-set-key (kbd "s-b") #'exwm-workspace-switch-to-buffer)

(exwm-enable)

(use-package dmenu
 :ensure t
 :bind
   ("s-SPC" . 'dmenu))

(defun exwm-async-run (name)
  (interactive)
  (start-process name nil name))

;; I had to do it.. don't worry I've got the theme set to high contrast
;; Also using the vim plugin in vscode for maximum nonsense
(defun me/vscode-in-emacs ()
  (interactive)
  (exwm-async-run "code"))


(global-set-key (kbd "s-+") #'me/vscode-in-emacs)

(global-set-key (kbd "C-x C-b") 'ibuffer)

(global-set-key (kbd "C-x c") 'compile)
(global-set-key (kbd "C-x C-r") 'recompile)
