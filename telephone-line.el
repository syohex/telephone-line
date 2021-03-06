;;; telephone-line.el --- Rewrite of Powerline

;; Copyright (C) 2015 Daniel Bordak

;; Author: Daniel Bordak <dbordak@fastmail.fm>
;; URL: https://github.com/dbordak/telephone-line
;; Version: 0.1
;; Keywords: mode-line
;; Package-Requires: ((cl-lib "0.5") (memoize "1.0.1") (names "0.5") (s "1.9.0") (seq "1.8"))

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:
;;
;; Telephone Line is a library for customizing the mode-line that is
;; based on the Vim Powerline. Themes can be created by customizing
;; the telephone-line-lhs and telephone-line-rhs variables.
;;

;;; Code:

(require 'telephone-line-separators)
(require 'telephone-line-segments)

(require 'seq)
(require 's)

;;;###autoload
(define-namespace telephone-line-

(defface accent-active
  '((t (:background "grey22" :inherit mode-line)))
  "Accent face for mode-line."
  :group 'telephone-line)

(defface accent-inactive
  '((t (:background "grey11" :inherit mode-line-inactive)))
  "Accent face for inactive mode-line."
  :group 'telephone-line)

(defface evil-insert
  '((((class color))
     :background "green" :weight bold :inherit mode-line)
    (t (:weight bold)))
  "face to fontify evil insert state"
  :group 'telephone-line-evil)

(defface evil-normal
  '((((class color))
     :background "red" :weight bold :inherit mode-line)
    (t (:weight bold)))
  "face to fontify evil normal state"
  :group 'telephone-line-evil)

(defface evil-visual
  '((((class color))
     :background "orange" :weight bold :inherit mode-line)
    (t (:weight bold)))
  "face to fontify evil visual state"
  :group 'telephone-line-evil)

(defface evil-motion
  '((((class color))
     :background "blue" :weight bold :inherit mode-line)
    (t (:weight bold)))
  "face to fontify evil motion state"
  :group 'telephone-line-evil)

(defface evil-emacs
  '((((class color))
     :background "blue violet" :weight bold :inherit mode-line)
    (t (:weight bold)))
  "face to fontify evil emacs state"
  :group 'telephone-line-evil)

(defface evil-replace
  '((((class color))
     :background "black" :weight bold :inherit mode-line)
    (t (:weight bold)))
  "face to fontify evil replace state"
  :group 'telephone-line-evil)

(defface evil-operator
  '((((class color))
     :background "sky blue" :weight bold :inherit mode-line)
    (t (:weight bold)))
  "face to fontify evil replace state"
  :group 'telephone-line-evil)

(defcustom primary-left-separator (if (window-system)
                                      #'telephone-line-abs-left
                                    #'telephone-line-utf-8-filled-left)
  "The primary separator to use on the left-hand side."
  :group 'telephone-line
  :type 'function)

(defcustom primary-right-separator (if (window-system)
                                       #'telephone-line-abs-right
                                    #'telephone-line-utf-8-filled-right)
  "The primary separator to use on the right-hand side."
  :group 'telephone-line
  :type 'function)

(defcustom secondary-left-separator (if (window-system)
                                        #'telephone-line-abs-hollow-left
                                    #'telephone-line-utf-8-left)
  "The secondary separator to use on the left-hand side.

Secondary separators do not incur a background color change."
  :group 'telephone-line
  :type 'function)

(defcustom secondary-right-separator (if (window-system)
                                       #'telephone-line-abs-hollow-right
                                    #'telephone-line-utf-8-right)
  "The secondary separator to use on the right-hand side.

Secondary separators do not incur a background color change."
  :group 'telephone-line
  :type 'function)

:autoload
(defun fill (reserve &optional face)
  "Return RESERVE empty space on the right, optionally with a FACE." ;;TODO: Add face
  (propertize " "
              'display `((space :align-to (- (+ right right-fringe right-margin)
                                             ,reserve)))))

(defun -set-selected-window ()
  (when (not (minibuffer-window-active-p (frame-selected-window)))
    (setq selected-window (frame-selected-window))))

(add-hook 'window-configuration-change-hook #'-set-selected-window)
(defadvice select-window (after select-window activate) (-set-selected-window))

:autoload
(defun selected-window-active ()
  "Return whether the current window is active."
  (and (boundp 'selected-window)
       (eq selected-window (selected-window))))

(defun face-map (sym)
  "Return the face corresponding to SYM for the selected window's active state."
  (-face-map sym (selected-window-active)))

;;TODO: Custom alist
(defun -face-map (sym active)
  "Return the face corresponding to SYM for the given ACTIVE state."
  (cond ((eq sym 'evil) (evil-face active))
        ((eq sym 'accent) (if active 'telephone-line-accent-active
                            'telephone-line-accent-inactive))
        (active 'mode-line)
        (t 'mode-line-inactive)))

;;TODO: Custom alist
(defun opposite-face-sym (sym)
  "Return the 'opposite' of the given SYM."
  (cdr (assoc
        sym '((evil . nil)
              (accent . nil)
              (nil . accent)))))

(defun evil-face (active)
  "Return an appropriate face for the current evil mode, given whether the frame is ACTIVE."
  (cond ((not active) 'mode-line-inactive)
        ((not (boundp 'evil-state)) 'mode-line)
        (t (intern (concat "telephone-line-evil-" (symbol-name evil-state))))))

;;TODO: Clean this up
(defun -separator-generator (primary-sep)
  (lambda (acc e)
    (let ((cur-color-sym (car e))
          (prev-color-sym (cdr acc))
          (cur-subsegments (cdr e))
          (accumulated-segments (car acc)))

      (cons
       (if accumulated-segments
           (list*
            cur-subsegments ;New segment
            ;; Separator
            `(:eval (funcall #',primary-sep
                             (telephone-line-face-map ',prev-color-sym)
                             (telephone-line-face-map ',cur-color-sym)))
            accumulated-segments) ;Old segments
         (list cur-subsegments))
       cur-color-sym))))

(defun propertize-segment (pred face segment)
  (unless (s-blank? (s-trim (format-mode-line segment)))
    (if pred
        `(:propertize (" " ,segment " ") face ,face)
      `(" " ,segment " "))))

;;TODO: Clean this up
(defun add-subseparators (subsegments sep-func color-sym)
  (let* ((cur-face (face-map color-sym))
         (opposite-face (face-map (opposite-face-sym color-sym)))
         (subseparator (funcall sep-func cur-face opposite-face)))
    (propertize-segment
     color-sym cur-face
     (cdr (seq-mapcat
           (lambda (subseg)
             (when subseg
               (list subseparator subseg)))
           (mapcar (lambda (f) (funcall f cur-face))
                   subsegments))))))

;;TODO: Clean this up
(defun add-separators (segments primary-sep secondary-sep)
  "Interpolates SEGMENTS with PRIMARY-SEP and SECONDARY-SEP.

Primary separators are added at initialization.  Secondary
separators, as they are conditional, are evaluated on-the-fly."
  (car (seq-reduce
        (-separator-generator primary-sep)
        (mapcar (lambda (segment-pair)
                  (seq-let (color-sym &rest subsegments) segment-pair
                    (cons color-sym
                          `(:eval
                            (telephone-line-add-subseparators
                             ',subsegments #',secondary-sep ',color-sym)))))
                segments)
        '(nil . nil))))

(defun width (values num-separators)
  "Get the column-length of VALUES, with NUM-SEPARATORS interposed."
  (let ((base-width (string-width (format-mode-line values)))
        (separator-width (/ (telephone-line-separator-width)
                            (float (frame-char-width)))))
    (if window-system
        (+ base-width
           ;; Separators are (ceiling separator-width)-space strings,
           ;; but their actual width is separator-width. base-width
           ;; already includes the string width of those spaces, so we
           ;; need the difference.
           (* num-separators (- separator-width (ceiling separator-width))))
      base-width)))

(defcustom lhs '((accent . (telephone-line-vc-segment))
                 (nil    . (telephone-line-minor-mode-segment
                            telephone-line-buffer-segment)))
  "Left hand side segment alist."
  :type '(alist :key-type segment-color :value-type subsegment-list)
  :group 'telephone-line)

(defcustom rhs '((accent . (telephone-line-position-segment))
                 (nil    . (misc-info-segment
                            telephone-line-major-mode-segment)))
  "Right hand side segment alist."
  :type '(alist :key-type segment-color :value-type subsegment-list)
  :group 'telephone-line)

(defun -generate-mode-line-lhs ()
  (add-separators (seq-reverse lhs)
                  primary-left-separator
                  secondary-left-separator))

(defun -generate-mode-line-rhs ()
  (add-separators rhs
                  primary-right-separator
                  secondary-right-separator))

(defun -generate-mode-line ()
  `(,@(telephone-line--generate-mode-line-lhs)
    (:eval (telephone-line-fill
            (telephone-line-width
             ',(telephone-line--generate-mode-line-rhs)
             ,(- (length telephone-line-rhs) 1))))
    ,@(telephone-line--generate-mode-line-rhs)))

(defvar -default-mode-line mode-line-format)

:autoload
(defun disable ()
  "Revert to the default Emacs mode-line."
  (interactive)
  (setq-default mode-line-format -default-mode-line))

:autoload
(defun enable ()
  "Setup the default mode-line."
  (interactive)
  (setq-default mode-line-format `("%e" ,@(telephone-line--generate-mode-line))))

) ; End of namespace

(provide 'telephone-line)
;;; telephone-line.el ends here
