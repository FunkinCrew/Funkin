package ;
 
import flixel.system.FlxBasePreloader;
import openfl.display.Sprite;
import flash.text.Font;
import flash.text.TextField;
import flash.text.TextFormat;
import flash.display.Bitmap;
import flash.display.BitmapData;
import flash.display.BlendMode;
import flash.display.Sprite;
import flash.Lib;
import flixel.FlxG;
 
@:bitmap("assets/images/preloaderArt.png") class LogoImage extends BitmapData { }
 
class Preloader extends FlxBasePreloader
{
    #if !js
    public function new(MinDisplayTime:Float=5, ?AllowedURLs:Array<String>) 
    {
        super(MinDisplayTime, AllowedURLs);
    }
     
    var logo:Sprite;
     
    override function create():Void 
    {
        this._width = Lib.current.stage.stageWidth;
        this._height = Lib.current.stage.stageHeight;
         
        var ratio:Float = this._width / 800; //This allows us to scale assets depending on the size of the screen.
         
        logo = new Sprite();
        logo.addChild(new Bitmap(new LogoImage(0,0))); //Sets the graphic of the sprite to a Bitmap object, which uses our embedded BitmapData class.
        logo.scaleX = logo.scaleY = ratio;
        logo.x = ((this._width) / 2) - ((logo.width) / 2);
        logo.y = (this._height / 2) - ((logo.height) / 2);
        addChild(logo); //Adds the graphic to the NMEPreloader's buffer.
         
        super.create();
    }
     
    override function update(Percent:Float):Void 
    {
        if (Percent < 0.1)
        {
            logo.alpha = 0;
        }
        else if (Percent < 0.25)
        {
            logo.alpha = 0;
        }
        else if (Percent < 0.5)
        {
            logo.alpha = 1;
         }
        else if ((Percent > 0.75) && (Percent < 0.9))
        {
            logo.alpha = 0;
        }
        else if (Percent > 0.9)
        {
            logo.alpha = 1;
        }

        super.update(Percent);
    }
    #end
}