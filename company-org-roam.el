;;; company-org-roam.el --- Company backend for Org-roam

;; Copyright © 2020 Jethro Kuan <jethrokuan95@gmail.com>

;; Author: Jethro Kuan <jethrokuan95@gmail.com>
;; URL: https://github.com/jethrokuan/org-roam
;; Keywords: org-mode, roam, convenience
;; Version: 1.0.0-rc1
;; Package-Requires: ((emacs "26.1") (company "0.9.0"))

;; This file is NOT part of GNU Emacs.

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 3, or (at your option)
;; any later version.
;;
;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs; see the file COPYING.  If not, write to the
;; Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
;; Boston, MA 02110-1301, USA.

;;; Commentary:

;; `company-org-roam' is a `company' completion backend for Org-roam.
;; To use it, add `company-org-roam' to `company-backends':

;;     (require 'company-org-roam)
;;     (company-org-roam-init)

;;; Code:

(require 'cl-lib)
(require 'company)
(require 'org-roam)

(defgroup company-org-roam nil
  "Company completion backend for Org-roam."
  :prefix "company-org-roam-"
  :group 'org-roam)

(defun company-org-roam--post-completion (candidate)
  "`company-org-roam' backend's post completion handling.
CANDIDATE is the returned string.

This function deletes the candidate, and replaces it with an Org link."
  (let* ((completions (org-roam--get-title-path-completions))
         (path (cdr (assoc candidate completions)))
         (current-file-path (-> (or (buffer-base-buffer)
                                    (current-buffer))
                                (buffer-file-name)
                                (file-truename)
                                (file-name-directory))))
    (delete-region (- (point) (length candidate)) (point))
    (insert (format "[[file:%s][%s]]"
                    (file-relative-name path current-file-path)
                    candidate))))

(defun company-org-roam--filter-candidates (prefix candidates)
  "Filter CANDIDATES that start with PREFIX.
The string match is case-insensitive."
  (-filter (lambda (candidate)
             (s-starts-with-p prefix candidate t)) candidates))

(defun company-org-roam--get-candidates (prefix)
  "Get the candidates for PREFIX."
  (->> (org-roam-sql [:select [titles] :from titles])
       (-flatten)
       (company-org-roam--filter-candidates prefix)))

;;;###autoload
(defun company-org-roam (command &optional arg &rest _)
  "Define a company backend for Org-roam.
COMMAND, ARG are as per the documentation of `company-backends'."
  (interactive (list 'interactive))
  (cl-case command
    (interactive (company-begin-backend #'company-org-roam))
    (prefix
     (and
      (bound-and-true-p org-roam-mode)
      (or (company-grab-symbol) 'stop)))
    (candidates
     (company-org-roam--get-candidates arg))
    (post-completion (company-org-roam--post-completion arg))))

(defun company-org-roam--init ()
  "Install `company-org-roam' as a `company-backend' in Org-roam files."
  (when (org-roam--org-roam-file-p (buffer-base-buffer))
    (push 'company-org-roam
          company-backends)))

;;;###autoload
(defun company-org-roam-init ()
  "Injects `company-org-roam' as a completion backend."
  (interactive)
  (add-hook 'org-mode-hook
            #'company-org-roam--init))

(provide 'company-org-roam)

;;; company-org-roam.el ends here
