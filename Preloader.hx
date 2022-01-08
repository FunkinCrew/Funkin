package;
 
import flixel.system.FlxBasePreloader;
import flash.display.Bitmap;
import flash.display.BitmapData;
import flash.display.Sprite;
import flash.Lib;
 
class Preloader extends FlxBasePreloader
{
    public function new(MinDisplayTime:Float=6, ?AllowedURLs:Array<String>) 
    {
        super(MinDisplayTime, AllowedURLs);
    }
     
    var logo:Sprite;
     
    override function create():Void 
    {
        this._width = Lib.current.stage.stageWidth;
        this._height = Lib.current.stage.stageHeight;
         
        var ratio:Float = this._width / 2560; //This allows us to scale assets depending on the size of the screen.
         
        logo = new Sprite();
        logo.addChild(new Bitmap(BitmapData.fromFile(Sys.getCwd() + "assets/shared/images/preloaderArt.png"))); //Sets the graphic of the sprite to a Bitmap object, which uses our embedded BitmapData class.
        logo.scaleX = logo.scaleY = ratio / 2;
        logo.x = ((this._width) / 2) - ((logo.width) / 2);
        logo.y = (this._height / 2) - ((logo.height) / 2);
        addChild(logo); //Adds the graphic to the NMEPreloader's buffer.
         
        super.create();
    }
     
    override function update(Percent:Float):Void 
    {
        logo.alpha = 0.3 + Percent;

        logo.scaleX = logo.scaleY = 0.5 * (0.3 + Percent);
        logo.x = ((this._width) / 2) - ((logo.width) / 2);
        logo.y = (this._height / 2) - ((logo.height) / 2);
        
        super.update(Percent);
    }
}