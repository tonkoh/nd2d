/*
 * ND2D - A Flash Molehill GPU accelerated 2D engine
 *
 * Author: Lars Gerckens
 * Copyright (c) nulldesign 2011
 * Repository URL: http://github.com/nulldesign/nd2d
 * Getting started: https://github.com/nulldesign/nd2d/wiki
 *
 *
 * Licence Agreement
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 */

package de.nulldesign.nd2d.display {

    import de.nulldesign.nd2d.materials.BlendModePresets;
    import de.nulldesign.nd2d.utils.NodeBlendMode;

    import flash.display.Stage;
    import flash.display3D.Context3D;
    import flash.events.Event;
    import flash.events.EventDispatcher;
    import flash.events.MouseEvent;
    import flash.geom.ColorTransform;
    import flash.geom.Matrix3D;
    import flash.geom.Point;
    import flash.geom.Vector3D;

    /**
     * Dispatched when the scene is active and added to the stage.
     * @eventType flash.events.Event.ADDED_TO_STAGE
     */
    [Event(name="addedToStage", type="flash.events.Event")]

    /**
     * Dispatched when the scene inactive and removed from stage.
     * @eventType flash.events.Event.REMOVED_FROM_STAGE
     */
    [Event(name="removedFromStage", type="flash.events.Event")]

    /**
     * Dispatched when a user presses and releases the main button of the user's pointing device over the same Node2D.
     * @eventType flash.events.MouseEvent.CLICK
     */
    [Event(name="click", type="flash.events.MouseEvent")]

    /**
     * Dispatched when a user presses the pointing device button over an Node2D instance.
     * @eventType flash.events.MouseEvent.MOUSE_DOWN
     */
    [Event(name="mouseDown", type="flash.events.MouseEvent")]

    /**
     * Dispatched when a user moves the pointing device while it is over an Node2D.
     * @eventType flash.events.MouseEvent.MOUSE_MOVE
     */
    [Event(name="mouseMove", type="flash.events.MouseEvent")]

    /**
     * Dispatched when a user releases the pointing device button over an Node2D instance.
     * @eventType flash.events.MouseEvent.MOUSE_UP
     */
    [Event(name="mouseUp", type="flash.events.MouseEvent")]

    /**
     * Dispatched when the user moves a pointing device over an Node2D instance.
     * @eventType flash.events.MouseEvent.MOUSE_OVER
     */
    [Event(name="mouseOver", type="flash.events.MouseEvent")]

    /**
     * Dispatched when the user moves a pointing device away from an Node2D instance.
     * @eventType flash.events.MouseEvent.MOUSE_OUT
     */
    [Event(name="mouseOut", type="flash.events.MouseEvent")]

    /**
     * <p>Basic 2D object. All drawable objects must extend Node2D</p>
     * A Node2D has two methods that are called during rendering:
     * <ul>
     * <li>step - Update the node's position here</li>
     * <li>draw - Your rendering code goes here</li>
     * </ul>
     */

    public class Node2D extends EventDispatcher {

        /**
         * @private
         */
        public var localModelMatrix:Matrix3D = new Matrix3D();

        /**
         * @private
         */
        public var worldModelMatrix:Matrix3D = new Matrix3D();

        /**
         * @private
         */
        public var invalidateMatrix:Boolean = true;

        /**
         * @private
         */
        public var invalidateVisibility:Boolean = true;

        /**
         * @private
         */
        public var invalidateColors:Boolean = true;

        public var children:Vector.<Node2D> = new Vector.<Node2D>();
        public var parent:Node2D;

        public var vx:Number = 0.0;
        public var vy:Number = 0.0;

        public var blendMode:NodeBlendMode = BlendModePresets.NORMAL_PREMULTIPLIED_ALPHA;

        public var mouseEnabled:Boolean = false;

        public var timeSinceStartInSeconds:Number = 0.0;

        protected var stage:Stage;

        private var localMouse:Vector3D;
        private var mouseInNode:Boolean = false;
        private var localMouseMatrix:Matrix3D = new Matrix3D();

        /**
         * @private
         */
        protected var _width:Number;

        public function get width():Number {
            return Math.abs(_width * _scaleX);
        }

        public function set width(value:Number):void {
            scaleX = value / _width;
        }

        /**
         * @private
         */
        protected var _height:Number;

        public function get height():Number {
            return Math.abs(_height * _scaleY);
        }

        public function set height(value:Number):void {
            scaleY = value / _height;
        }

        protected var _visible:Boolean = true;

        public function get visible():Boolean {
            return _visible;
        }

        public function set visible(value:Boolean):void {
            if(visible != value) {
                _visible = value;
                invalidateVisibility = true;
            }
        }

        protected var _alpha:Number = 1.0;

        public function set alpha(value:Number):void {
            if(alpha != value) {
                _alpha = value;
                invalidateColors = true;
                visible = alpha > 0.0;
            }
        }

        public function get alpha():Number {
            return _alpha;
        }

        /**
         * @private
         */
        public var combinedColorTransform:ColorTransform = new ColorTransform();

        protected var _colorTransform:ColorTransform = new ColorTransform();

        public function get colorTransform():ColorTransform {
            return _colorTransform;
        }

        public function set colorTransform(value:ColorTransform):void {
            if(_colorTransform != value) {
                _colorTransform = value;
                invalidateColors = true;
            }
        }

        protected var _tint:Number = 0xFFFFFF;

        public function get tint():Number {
            return _tint;
        }

        public function set tint(value:Number):void {
            if(_tint != value) {
                _tint = value;

                var r:Number = (_tint >> 16) / 255.0;
                var g:Number = (_tint >> 8 & 255) / 255.0;
                var b:Number = (_tint & 255) / 255.0;

                colorTransform.redMultiplier = r;
                colorTransform.greenMultiplier = g;
                colorTransform.blueMultiplier = b;
                colorTransform.alphaMultiplier = 1.0;
                colorTransform.redOffset = 0;
                colorTransform.greenOffset = 0;
                colorTransform.blueOffset = 0;
                colorTransform.alphaOffset = 0;

                invalidateColors = true;
            }
        }

        protected var _scaleX:Number = 1.0;

        public function set scaleX(value:Number):void {
            if(scaleX != value) {
                _scaleX = value;
                invalidateMatrix = true;
            }
        }

        public function get scaleX():Number {
            return _scaleX;
        }

        protected var _scaleY:Number = 1.0;

        public function set scaleY(value:Number):void {
            if(scaleY != value) {
                _scaleY = value;
                invalidateMatrix = true;
            }
        }

        public function get scaleY():Number {
            return _scaleY;
        }

        protected var _x:Number = 0.0;

        public function set x(value:Number):void {
            if(x != value) {
                _x = value;
                position.x = x;
                invalidateMatrix = true;
            }
        }

        public function get x():Number {
            return _x;
        }

        protected var _y:Number = 0.0;

        public function set y(value:Number):void {
            if(y != value) {
                _y = value;
                position.y = y;
                invalidateMatrix = true;
            }
        }

        public function get y():Number {
            return _y;
        }

        protected var _position:Point = new Point(0.0, 0.0);

        public function get position():Point {
            return _position;
        }

        public function set position(value:Point):void {
            if(x != value.x || y != value.y) {
                _position.x = value.x;
                _position.y = value.y;
                x = _position.x;
                y = _position.y;
            }
        }

        protected var _pivot:Point = new Point(0.0, 0.0);

        public function get pivot():Point {
            return _pivot;
        }

        public function set pivot(value:Point):void {
            if(pivot.x != value.x || pivot.y != value.y) {
                _pivot.x = value.x;
                _pivot.y = value.y;
                invalidateMatrix = true;
            }
        }

        protected var _rotation:Number = 0.0;

        public function set rotation(value:Number):void {
            if(rotation != value) {
                _rotation = value;
                invalidateMatrix = true;
            }
        }

        public function get rotation():Number {
            return _rotation;
        }

        protected var _mouseX:Number = 0.0;

        public function get mouseX():Number {
            return _mouseX;
        }

        protected var _mouseY:Number = 0.0;

        public function get mouseY():Number {
            return _mouseY;
        }

        public function get numTris():uint {

            var tris:uint = 0;

            for(var i:int = 0; i < children.length; i++) {
                tris += children[i].numTris;
            }

            return tris;
        }

        public function get drawCalls():uint {

            var calls:uint = 0;

            for(var i:int = 0; i < children.length; i++) {
                calls += children[i].drawCalls;
            }

            return calls;
        }

        public function get numChildren():uint {
            return children.length;
        }

        public function Node2D() {
        }

        /**
         * @private
         */
        public function updateMatrix():void {
            invalidateMatrix = false;
            localModelMatrix.identity();
            localModelMatrix.appendTranslation(-pivot.x, -pivot.y, 0);
            localModelMatrix.appendScale(scaleX, scaleY, 1.0);
            localModelMatrix.appendRotation(rotation, Vector3D.Z_AXIS);
            localModelMatrix.appendTranslation(x, y, 0.0);
        }

        /**
         * @private
         */
        public function updateColors():void {

            invalidateColors = false;

            combinedColorTransform.redMultiplier = colorTransform.redMultiplier;
            combinedColorTransform.greenMultiplier = colorTransform.greenMultiplier;
            combinedColorTransform.blueMultiplier = colorTransform.blueMultiplier;
            combinedColorTransform.alphaMultiplier = colorTransform.alphaMultiplier;
            combinedColorTransform.redOffset = colorTransform.redOffset;
            combinedColorTransform.greenOffset = colorTransform.greenOffset;
            combinedColorTransform.blueOffset = colorTransform.blueOffset;
            combinedColorTransform.alphaOffset = colorTransform.alphaOffset;

            if(parent) {
                combinedColorTransform.concat(parent.combinedColorTransform);
            }

            for(var i:int = 0; i < children.length; i++) {
                children[i].updateColors();
            }
        }

        /**
         * @private
         */
        internal function processMouseEvents(mousePosition:Vector3D, mouseEventType:String, projectionMatrix:Matrix3D):void {

            if(mouseEnabled && mouseEventType) {
                // transform mousepos to local coordinate system
                localMouseMatrix.identity();
                localMouseMatrix.append(worldModelMatrix);
                localMouseMatrix.append(projectionMatrix);
                localMouseMatrix.invert();

                localMouse = localMouseMatrix.transformVector(mousePosition);
                localMouse.w = 1.0 / localMouse.w;
                localMouse.x /= localMouse.w;
                localMouse.y /= localMouse.w;
                localMouse.z /= localMouse.w;

                _mouseX = localMouse.x;
                _mouseY = localMouse.y;

                if(!isNaN(width) && !isNaN(height)) {

                    var oldMouseInNodeState:Boolean = mouseInNode;
                    mouseInNode = (mouseX >= -_width * 0.5 && mouseX <= _width * 0.5 && mouseY >= -_height * 0.5 && mouseY <= _height * 0.5);

                    if(mouseInNode) {
                        if(!oldMouseInNodeState) {
                            dispatchMouseEvent(MouseEvent.MOUSE_OVER);
                        }
                        dispatchMouseEvent(mouseEventType);
                    } else if(oldMouseInNodeState && !mouseInNode) {
                        dispatchMouseEvent(MouseEvent.MOUSE_OUT);
                    }
                }
            }

            for each(var child:Node2D in children) {
                child.processMouseEvents(mousePosition, mouseEventType, projectionMatrix);
            }
        }

        internal function setStageRef(value:Stage):void {

            if(stage != value) {

                if(value) {
                    stage = value;
                    dispatchEvent(new Event(Event.ADDED_TO_STAGE));
                } else {
                    dispatchEvent(new Event(Event.REMOVED_FROM_STAGE));
                    stage = value;
                }

                for each(var child:Node2D in children) {
                    child.setStageRef(value);
                }
            }
        }

        /**
         * @private
         */
        internal function stepNode(elapsed:Number):void {

            step(elapsed);

            for each(var child:Node2D in children) {
                child.timeSinceStartInSeconds = timeSinceStartInSeconds;
                child.stepNode(elapsed);
            }
        }

        public function handleDeviceLoss():void {
            for each(var child:Node2D in children) {
                child.handleDeviceLoss();
            }
            // extend in extended classes
        }

        /**
         * @private
         */
        internal function drawNode(context:Context3D, camera:Camera2D, parentMatrixChanged:Boolean):void {

            var myMatrixChanged:Boolean = false;

            if(!visible) {
                return;
            }

            if(invalidateColors) {
                updateColors();
            }

            if(invalidateMatrix) {
                updateMatrix();
                myMatrixChanged = true;
            }

            if(parentMatrixChanged || myMatrixChanged) {
                worldModelMatrix.identity();
                worldModelMatrix.append(localModelMatrix);

                if(parent) {
                    worldModelMatrix.append(parent.worldModelMatrix);
                }
            }

            draw(context, camera);

            for each(var child:Node2D in children) {
                child.drawNode(context, camera, myMatrixChanged);
            }
        }

        private function dispatchMouseEvent(mouseEventType:String):void {
            dispatchEvent(new MouseEvent(mouseEventType, true, false, localMouse.x, localMouse.y, null, false, false, false,
                                         (mouseEventType == MouseEvent.MOUSE_DOWN), 0));
        }

        protected function draw(context:Context3D, camera:Camera2D):void {
            // overwrite in extended classes
        }

        protected function step(elapsed:Number):void {
            // overwrite in extended classes
        }

        public function addChild(child:Node2D):Node2D {
            return addChildAt(child, children.length);
        }

        public function addChildAt(child:Node2D, idx:uint):Node2D {

            var existingIdx:int = getChildIndex(child);
            if(existingIdx != -1) {
                removeChildAt(existingIdx);
            }

            child.parent = this;
            child.setStageRef(stage);
            children.splice(idx, 0, child);
            return child;
        }

        public function removeChild(child:Node2D):void {

            var idx:int = children.indexOf(child);

            if(idx >= 0) {
                removeChildAt(idx);
            }
        }

        public function removeChildAt(idx:uint):void {
            if(idx < children.length) {
                children[idx].parent = null;
                children[idx].setStageRef(null);
                children.splice(idx, 1);
            }
        }

        public function getChildAt(idx:uint):Node2D {
            if(idx < children.length) {
                return children[idx];
            }

            return null;
        }

        public function getChildIndex(child:Node2D):int {
            return children.indexOf(child);
        }

        public function swapChildren(child1:Node2D, child2:Node2D):void {
            var idx1:uint = getChildIndex(child1);
            var idx2:uint = getChildIndex(child2);
            children[idx1] = child2;
            children[idx2] = child1;
        }

        public function removeAllChildren():void {
            while(children.length > 0) {
                removeChildAt(0);
            }
        }

        public function cleanUp():void {
            for each(var child:Node2D in children) {
                child.cleanUp();
            }
        }
    }
}