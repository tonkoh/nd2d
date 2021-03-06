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

package de.nulldesign.nd2d.materials {

    import com.adobe.utils.AGALMiniAssembler;

    import de.nulldesign.nd2d.geom.Face;
    import de.nulldesign.nd2d.geom.UV;
    import de.nulldesign.nd2d.geom.Vertex;
    import de.nulldesign.nd2d.utils.TextureHelper;

    import flash.display3D.Context3D;
    import flash.display3D.Context3DProgramType;
    import flash.display3D.Context3DVertexBufferFormat;
    import flash.utils.getTimer;

    public class Sprite2DDizzyMaterial extends Sprite2DMaterial {

        private const VERTEX_SHADER:String =
                "m44 op, va0, vc0   \n" + // vertex * clipspace
                "mov v0, va1		\n"; // copy uv

        private const FRAGMENT_SHADER:String =
                "mov ft0.xyzw, v0.xy                        \n" + // get interpolated uv coords
                "mul ft1, ft0, fc0.y                        \n" +
                "add ft1, ft1, fc0.x                        \n" +
                "cos ft1.y, ft1.w                           \n" +
                "sin ft1.x, ft1.z                           \n" +
                "mul ft1.xy, ft1.xy, fc0.zw                 \n" +
                "add ft0, ft0, ft1                          \n" +
                "tex ft0, ft0, fs0 <2d,clamp,linear,nomip>  \n" + // sample texture
                "mul ft0, ft0, fc1                          \n" + // mult with colorMultiplier
                "add ft0, ft0, fc2                          \n" + // mult with colorOffset
                "mov oc, ft0                                \n";

        private static var dizzyProgramData:ProgramData;

        public function Sprite2DDizzyMaterial(textureObject:Object) {
            super(textureObject);
        }

        override protected function prepareForRender(context:Context3D):Boolean {

            if(!texture && spriteSheet && spriteSheet.bitmapData) {
                texture = TextureHelper.generateTextureFromBitmap(context, spriteSheet.bitmapData, false);
            }

            if(!texture) {
                // can happen after a device loss
                return false;
            }

            context.setProgram(programData.program);
            context.setBlendFactors(blendMode.src, blendMode.dst);
            context.setTextureAt(0, texture);
            context.setVertexBufferAt(0, vertexBuffer, 0, Context3DVertexBufferFormat.FLOAT_2); // vertex
            context.setVertexBufferAt(1, vertexBuffer, 2, Context3DVertexBufferFormat.FLOAT_2); // uv

            refreshClipspaceMatrix();

            context.setProgramConstantsFromMatrix(Context3DProgramType.VERTEX, 0, clipSpaceMatrix, true);
            context.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT, 0, Vector.<Number>([ getTimer() * 0.002,
                                                                                                      8 * Math.PI,
                                                                                                      0.01,
                                                                                                      0.02 ]));

            context.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT, 1, Vector.<Number>([ colorTransform.redMultiplier, colorTransform.greenMultiplier, colorTransform.blueMultiplier, colorTransform.alphaMultiplier ]));

            var offsetFactor:Number = 1.0 / 255.0;
            context.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT, 2, Vector.<Number>([ colorTransform.redOffset * offsetFactor, colorTransform.greenOffset * offsetFactor, colorTransform.blueOffset * offsetFactor, colorTransform.alphaOffset * offsetFactor ]));


            return true;
        }

        override protected function clearAfterRender(context:Context3D):void {
            context.setTextureAt(0, null);
            context.setVertexBufferAt(0, null);
            context.setVertexBufferAt(1, null);
        }

        override public function handleDeviceLoss():void {
            super.handleDeviceLoss();
            dizzyProgramData = null;
        }

        override protected function addVertex(context:Context3D, buffer:Vector.<Number>, v:Vertex, uv:UV, face:Face):void {

            fillBuffer(buffer, v, uv, face, "PB3D_POSITION", 2);
            fillBuffer(buffer, v, uv, face, "PB3D_UV", 2);
        }

        override protected function initProgram(context:Context3D):void {
            if(!dizzyProgramData) {
                var vertexShaderAssembler:AGALMiniAssembler = new AGALMiniAssembler();
                vertexShaderAssembler.assemble(Context3DProgramType.VERTEX, VERTEX_SHADER);

                var colorFragmentShaderAssembler:AGALMiniAssembler = new AGALMiniAssembler();
                colorFragmentShaderAssembler.assemble(Context3DProgramType.FRAGMENT, FRAGMENT_SHADER);

                dizzyProgramData = new ProgramData(null, null, null, null);
                dizzyProgramData.numFloatsPerVertex = 4;
                dizzyProgramData.program = context.createProgram();
                dizzyProgramData.program.upload(vertexShaderAssembler.agalcode, colorFragmentShaderAssembler.agalcode);
            }

            programData = dizzyProgramData;
        }
    }
}
