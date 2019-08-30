#|
 This file is a part of Alloy
 (c) 2019 Shirakumo http://tymoon.eu (shinmera@tymoon.eu)
 Author: Nicolas Hafner <shinmera@tymoon.eu>
|#

(in-package #:org.shirakumo.alloy.renderers.opengl)

;; Required GL state before ALLOY:RENDER call:
;;   (gl:enable :blend :stencil-test :line-smooth)
;;   (gl:disable :depth-test)
;;   (gl:stencil-func :always 1 #xFF)
;;   (gl:clear-stencil #x00)
;;   (gl:blend-func :src-alpha :one-minus-src-alpha)
;; If cull-face is enabled:
;;   (gl:front-face :ccw)
;;   (gl:cull-face :back)
;; The target being rendered to must have a color
;; and stencil attachment. A depth attachment is not
;; required, as all UI is drawn at Z 0.

;; alloy:allocate
;; alloy:deallocate
;; simple:text
;; simple:request-font
;; simple:request-image
(defgeneric bind (resource))
(defgeneric gl-name (resource))

(defgeneric make-shader (renderer &key vertex-shader fragment-shader))
(defgeneric (setf uniform) (value shader uniform))

(defgeneric make-vertex-buffer (renderer contents &key data-usage buffer-type))
(defgeneric update-vertex-buffer (buffer contents))

(defgeneric make-vertex-array (renderer bindings))
(defgeneric draw-vertex-array (array primitive-type count))