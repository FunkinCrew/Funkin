package animateatlas;
import flixel.util.FlxDestroyUtil;
import openfl.geom.Rectangle;
import flixel.math.FlxPoint;
import flixel.math.FlxRect;
import openfl.Assets;
import haxe.Json;
import openfl.display.BitmapData;
import animateatlas.JSONData.AtlasData;
import animateatlas.JSONData.AnimationData;
import animateatlas.displayobject.SpriteAnimationLibrary;
import animateatlas.displayobject.SpriteMovieClip;
import flixel.graphics.FlxGraphic;
import flixel.graphics.frames.FlxFramesCollection;
import flixel.graphics.frames.FlxFrame;
class AtlasFrameMaker extends FlxFramesCollection{


        //public static var widthoffset:Int = 0;
        //public static var heightoffset:Int = 0;
        //public static var excludeArray:Array<String>;
         /**
	
	 * Creates Frames from TextureAtlas(very early and broken ok) Originally made for FNF HD by Smokey and Rozebud
	 *
	 * @param   key                 The file path.
	 * @param   _excludeArray       Use this to only create selected animations. Keep null to create all of them.
	 *
	 */

        public static function construct(key:String,?_excludeArray:Array<String> = null):FlxFramesCollection{

               // widthoffset = _widthoffset;
               // heightoffset = _heightoffset;
               
               

                var frameCollection:FlxFramesCollection;
                var frameArray:Array<Array<FlxFrame>> = [];
                var animationData:AnimationData = Json.parse(Assets.getText(key + "/Animation.json"));
                var atlasData:AtlasData = Json.parse(Assets.getText(key + "/spritemap.json"));
                var bitmapData:BitmapData = Assets.getBitmapData(key + "/spritemap.png");
                var ss = new SpriteAnimationLibrary(animationData, atlasData, bitmapData);
                var t = ss.createAnimation();
                if(_excludeArray == null){
                _excludeArray = t.getFrameLabels();
                }
                frameCollection = new FlxFramesCollection(FlxGraphic.fromBitmapData(bitmapData),FlxFrameCollectionType.IMAGE);

                
                for(x in t.getFrameLabels()){

                        frameArray.push(getFramesArray(t, x,_excludeArray));


                }

                for(x in frameArray){
                        for(y in x){
                                frameCollection.pushFrame(y);
                        }
                }
                
                return frameCollection;

        }

        @:noCompletion static function getFramesArray(t:SpriteMovieClip,animation:String,_excludeArray:Array<String>):Array<FlxFrame>
        {
                var sizeInfo:Rectangle = new Rectangle(0,0);
                t.currentLabel = animation;
                var bitMapArray:Array<BitmapData> = [];
                var daFramez:Array<FlxFrame> = [];
                var firstPass = true;
                var frameSize:FlxPoint = new FlxPoint(0,0);

                for (i in t.getFrame(animation)...t.numFrames){
                        t.currentFrame = i;
                        if (t.currentLabel == animation){
                                if (_excludeArray.contains(animation)){
                                        sizeInfo = t.getBounds(t);

                                        var bitmapShit:BitmapData = new BitmapData(
                                        Std.int(sizeInfo.width + Math.abs(sizeInfo.x)),Std.int(sizeInfo.height +Math.abs(sizeInfo.y)),true,0);

                                        bitmapShit.draw(t,null,null,null,null,true);
                                        bitMapArray.push(bitmapShit);
                                        
                                        if (firstPass){
                                        frameSize.set(bitmapShit.width,bitmapShit.height);
                                        firstPass = false;
                                        }
                                }
                        }
                        else break;
                }
                
                for (i in 0...bitMapArray.length){
                        var b = FlxGraphic.fromBitmapData(bitMapArray[i]);
                        var theFrame = new FlxFrame(b);
                        theFrame.parent = b;
                        theFrame.name = animation + i;
                        theFrame.sourceSize.set(frameSize.x,frameSize.y);
                        theFrame.frame = new FlxRect(0, 0, bitMapArray[i].width, bitMapArray[i].height);
                        daFramez.push(theFrame);
                        
                        //trace(daFramez);
                }
                return daFramez;
        }

        /*public static function renderTest(key:String, animation:String, ?frame:Int = 0):Void
        {
                var animationData:AnimationData = Json.parse(Assets.getText(key + "/Animation.json"));
                var atlasData:AtlasData = Json.parse(Assets.getText(key + "/spritemap.json"));
                var bitmapData:BitmapData = Assets.getBitmapData(key + "/spritemap.png");
                var ss = new SpriteAnimationLibrary(animationData, atlasData, bitmapData);
                var t = ss.createAnimation();
                var bitMapArray:Array<BitmapData> = [];

                for (i in 0...t.numFrames){
                        t.currentFrame = i;
                        if (t.currentLabel == animation){
                        //trace(t.currentFrame);
                        var bitmapShit:BitmapData = new BitmapData(Std.int(t.width),Std.int(t.height),true,0);
                        //bitmapShit.drawWithQuality(t,null,null,null,null,true);
                        bitmapShit.draw(t, new Matrix(1, 0, 0, 1, t.width/2, t.height/2), null, null, null, false);
                        bitMapArray.push(bitmapShit);
                        }
                }

                saveImage(bitMapArray[frame]);

        }

        public static function saveImage(bitmapData:BitmapData)
        {
                var b:ByteArray = new ByteArray();
                b = bitmapData.encode(bitmapData.rect, new PNGEncoderOptions(true), b);
                new FileDialog().save(b, "png", null, "file");
        }
        */


        
        

}
