;;; telephone-line-segments.el --- Segments for Telephone Line

;; Copyright (C) 2015 Daniel Bordak

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
;; Segments for Telephone Line.
;; To create your own, look at the functions defined in telephone-line-utils.el

;;; Code:

(require 'telephone-line-utils)

(telephone-line-defsegment telephone-line-vc-segment
  vc-mode)

(telephone-line-defsegment telephone-line-process-segment
  mode-line-process)

(telephone-line-defsegment telephone-line-position-segment
  (if (eq major-mode 'paradox-menu-mode)
      mode-line-front-space  ;Paradox fills this with position info.
    mode-line-position))

(telephone-line-defsegment telephone-line-airline-position-segment
  (if (eq major-mode 'paradox-menu-mode)
      mode-line-front-space
    '((-3 "%p") " %4l:%3c")))

(telephone-line-defsegment telephone-line-misc-info-segment
  mode-line-misc-info)

(telephone-line-defsegment* telephone-line-buffer-segment
  `(""
    mode-line-mule-info
    mode-line-modified
    mode-line-client
    mode-line-remote
    mode-line-frame-identification
    ,(telephone-line-raw mode-line-buffer-identification t)))

(telephone-line-defsegment-plist telephone-line-major-mode-segment
  (let ((recursive-edit-help-echo "Recursive edit, type C-M-c to get out"))
    `((:propertize "%[" help-echo ,recursive-edit-help-echo)
      (:propertize ("" mode-name)
                   help-echo "Major mode\n\
mouse-1: Display major mode menu\n\
mouse-2: Show help for major mode\n\
mouse-3: Toggle minor modes"
                   mouse-face mode-line-highlight
                   local-map ,mode-line-major-mode-keymap)
      (:propertize "%]" help-echo ,recursive-edit-help-echo))))

(telephone-line-defsegment-plist telephone-line-minor-mode-segment
  `((:propertize ("" minor-mode-alist)
                 mouse-face mode-line-highlight
                 help-echo "Minor mode\n\
mouse-1: Display minor mode menu\n\
mouse-2: Show help for minor mode\n\
mouse-3: Toggle minor modes"
                 local-map ,mode-line-minor-mode-keymap)
    (:propertize "%n"
                 mouse-face mode-line-highlight
                 help-echo "mouse-2: Remove narrowing from buffer"
                 local-map ,(make-mode-line-mouse-map
                             'mouse-2 #'mode-line-widen))))

(telephone-line-defsegment* telephone-line-erc-modified-channels-segment
  (s-with erc-modified-channels-object
    s-trim (s-chop-suffix "]") (s-chop-prefix "[")))

(eval-after-load 'evil
  '(telephone-line-defsegment* telephone-line-evil-tag-segment
     (let ((tag
            (if (evil-visual-state-p)
                (cond
                 ((eq evil-visual-selection 'block)
                  (if telephone-line-evil-use-short-tag "VB"
                    "V-BLOCK"))
                 ((eq evil-visual-selection 'line)
                  (if telephone-line-evil-use-short-tag "VL"
                    "V-LINE"))
                 (t "VISUAL"))
              (upcase (symbol-name evil-state)))))
       (if telephone-line-evil-use-short-tag
           (s-left 2 tag)
         tag))))

(provide 'telephone-line-segments)
;;; telephone-line-segments.el ends here
