#|
 This file is a part of Alloy
 (c) 2019 Shirakumo http://tymoon.eu (shinmera@tymoon.eu)
 Author: Nicolas Hafner <shinmera@tymoon.eu>
|#

(in-package #:org.shirakumo.alloy)

(defclass sidebar (structure)
  ())

(defmethod enter ((element layout-element) (structure sidebar) &key)
  (when (next-method-p) (call-next-method))
  (enter element (layout-element structure) :place :center))

(defmethod enter ((element focus-element) (structure sidebar) &key)
  (when (next-method-p) (call-next-method))
  (enter element (focus-element structure)))

(defmethod initialize-instance :after ((structure sidebar) &key layout focus focus-parent layout-parent (side :west))
  (let* ((opposite (ecase side
                     (:north :south)
                     (:east :west)
                     (:south :north)
                     (:west :east)))
         (frame (make-instance 'frame :padding (margins 0)))
         (focus-list (make-instance 'focus-list))
         (dragger (make-instance 'resizer :side opposite :data frame)))
    (enter dragger frame :place opposite)
    (finish-structure structure frame focus-list)
    (when layout
      (enter layout structure))
    (when focus
      (enter focus structure))
    (when layout-parent
      (enter frame layout-parent :place side))
    (when focus-parent
      (enter focus-list focus-parent :place side)
      (enter dragger focus-parent :place side))))

;; FIXME: reinitialize-instance
