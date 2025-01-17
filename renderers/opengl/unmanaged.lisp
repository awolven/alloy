#|
 This file is a part of Alloy
 (c) 2019 Shirakumo http://tymoon.eu (shinmera@tymoon.eu)
 Author: Nicolas Hafner <shinmera@tymoon.eu>
|#

(in-package #:org.shirakumo.alloy.renderers.opengl)

(defmethod view-size ((renderer renderer))
  (let ((data (gl:get-integer :viewport 4)))
    (alloy:px-size (aref data 2) (aref data 3))))

(defstruct (gl-resource (:copier NIL) (:predicate NIL))
  (name 0 :type (unsigned-byte 32)))

(defmethod gl-name ((resource gl-resource))
  (gl-resource-name resource))

(defstruct (vbo (:constructor make-vbo (name type)) (:include gl-resource) (:copier NIL) (:predicate NIL))
  (type :array-buffer))

(defstruct (vao (:constructor make-vao (name type)) (:include gl-resource) (:copier NIL) (:predicate NIL))
  (type :arrays))

(defstruct (program (:constructor make-program (name)) (:include gl-resource) (:copier NIL) (:predicate NIL)))

(defmethod bind ((program program))
  (gl:use-program (gl-resource-name program)))

(defstruct (texture (:constructor make-tex (name)) (:include gl-resource) (:copier NIL) (:predicate NIL)))

(defmethod bind ((texture texture))
  (gl:active-texture :texture0)
  (gl:bind-texture :texture-2d (gl-resource-name texture)))

(defmethod make-shader ((renderer renderer) &key vertex-shader fragment-shader)
  (let ((vert (gl:create-shader :vertex-shader))
        (frag (gl:create-shader :fragment-shader))
        (prog (gl:create-program)))
    (flet ((make (name source)
             (gl:shader-source name (format NIL "#version 330 core~%~a" source))
             (gl:compile-shader name)
             (unless (gl:get-shader name :compile-status)
               (error "Failed to compile: ~%~a~%Shader source:~%~a"
                      (gl:get-shader-info-log name) source))))
      (make vert vertex-shader)
      (make frag fragment-shader)
      (gl:attach-shader prog vert)
      (gl:attach-shader prog frag)
      (gl:link-program prog)
      (gl:detach-shader prog vert)
      (gl:detach-shader prog frag)
      (unless (gl:get-program prog :link-status)
        (error "Failed to link: ~%~a"
               (gl:get-program-info-log prog)))
      (make-program prog))))

(defmethod (setf uniform) (value (program program) uniform)
  (let ((location (gl:get-uniform-location (gl-resource-name program) uniform)))
    (etypecase value
      (vector
       (cffi:with-pointer-to-vector-data (data value)
         (%gl:uniform-matrix-3fv location 1 T data)))
      (single-float
       (%gl:uniform-1f location value))
      (colored:color
       (%gl:uniform-4f location (colored:r value) (colored:g value) (colored:b value) (colored:a value)))
      (alloy:point
       (%gl:uniform-2f location (alloy:pxx value) (alloy:pxy value)))
      (alloy:size
       (%gl:uniform-2f location (alloy:pxw value) (alloy:pxh value)))))
  value)

(defmethod make-vertex-buffer ((renderer renderer) (contents vector) &key (buffer-type :array-buffer) data-usage)
  (let ((name (gl:gen-buffer)))
    (gl:bind-buffer buffer-type name)
    (cffi:with-pointer-to-vector-data (data contents)
      (%gl:buffer-data buffer-type (* (length contents) 4) data data-usage))
    (gl:bind-buffer buffer-type 0)
    (make-vbo name buffer-type)))

(defmethod make-vertex-buffer ((renderer renderer) (size integer) &key (buffer-type :array-buffer) data-usage)
  (let ((name (gl:gen-buffer)))
    (gl:bind-buffer buffer-type name)
    (%gl:buffer-data buffer-type (* size 4) (cffi:null-pointer) data-usage)
    (gl:bind-buffer buffer-type 0)
    (make-vbo name buffer-type)))

(defmethod update-vertex-buffer ((buffer vbo) contents)
  (gl:bind-buffer (vbo-type buffer) (gl-resource-name buffer))
  (cffi:with-pointer-to-vector-data (data contents)
    (%gl:buffer-data (vbo-type buffer) (* (length contents) 4) data :stream-draw))
  (gl:bind-buffer (vbo-type buffer) 0)
  buffer)

(defmethod make-vertex-array ((renderer renderer) bindings)
  (let ((name (gl:gen-vertex-array))
        (type :arrays)
        (i 0))
    (gl:bind-vertex-array name)
    (dolist (binding bindings)
      (cond ((listp binding)
             (destructuring-bind (buffer &key (size 3) (stride 0) (offset 0)) binding
               (gl:bind-buffer :array-buffer (gl-resource-name buffer))
               (gl:vertex-attrib-pointer i size :float NIL stride offset)
               (gl:enable-vertex-attrib-array i)
               (incf i)))
            (T
             (gl:bind-buffer :element-array-buffer (gl-resource-name binding))
             (setf type :elements))))
    (gl:bind-vertex-array 0)
    (make-vao name type)))

(defmethod draw-vertex-array ((array vao) primitive-type offset count)
  (gl:bind-vertex-array (gl-resource-name array))
  (ecase (vao-type array)
    (:arrays (%gl:draw-arrays primitive-type offset count))
    (:elements (%gl:draw-elements primitive-type count :unsigned-int offset)))
  (gl:bind-vertex-array 0)
  array)

(defmethod make-texture ((renderer renderer) width height data &key (channels 4) (filtering :linear))
  (let* ((format (ecase channels (1 :r) (2 :rg) (3 :rgb) (4 :rgba)))
         (name (gl:gen-texture)))
    (gl:bind-texture :texture-2d name)
    (gl:tex-image-2d :texture-2d 0 format width height 0 format :unsigned-byte data)
    (gl:tex-parameter :texture-2d :texture-wrap-s :clamp-to-border)
    (gl:tex-parameter :texture-2d :texture-wrap-t :clamp-to-border)
    (gl:tex-parameter :texture-2d :texture-min-filter filtering)
    (gl:tex-parameter :texture-2d :texture-mag-filter filtering)
    (gl:bind-texture :texture-2d 0)
    (make-tex name)))
