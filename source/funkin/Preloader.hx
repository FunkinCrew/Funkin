package funkin;

import flash.Lib;
import flash.display.Bitmap;
import flash.display.BitmapData;
import flash.display.Sprite;
import flixel.system.FlxBasePreloader;
import openfl.display.Sprite;
import funkin.util.CLIUtil;
import openfl.text.TextField;
import openfl.text.TextFormat;
import flixel.system.FlxAssets;

@:bitmap('art/preloaderArt.png')
class LogoImage extends BitmapData {}

class Preloader extends FlxBasePreloader
{
  public function new(MinDisplayTime:Float = 0, ?AllowedURLs:Array<String>)
  {
    super(MinDisplayTime, AllowedURLs);

    CLIUtil.resetWorkingDir(); // Bug fix for drag-and-drop.
  }

  var logo:Sprite;
  var _text:TextField;

  override function create():Void
  {
    this._width = Lib.current.stage.stageWidth;
    this._height = Lib.current.stage.stageHeight;

    _text = new TextField();
    _text.width = 500;
    _text.text = "Loading FNF";
    _text.defaultTextFormat = new TextFormat(FlxAssets.FONT_DEFAULT, 16, 0xFFFFFFFF);
    _text.embedFonts = true;
    _text.selectable = false;
    _text.multiline = false;
    _text.wordWrap = false;
    _text.autoSize = LEFT;
    _text.x = 2;
    _text.y = 2;
    addChild(_text);

    var ratio:Float = this._width / 2560; // This allows us to scale assets depending on the size of the screen.

    logo = new Sprite();
    logo.addChild(new Bitmap(new LogoImage(0, 0))); // Sets the graphic of the sprite to a Bitmap object, which uses our embedded BitmapData class.
    logo.scaleX = logo.scaleY = ratio;
    logo.x = ((this._width) / 2) - ((logo.width) / 2);
    logo.y = (this._height / 2) - ((logo.height) / 2);
    // addChild(logo); // Adds the graphic to the NMEPreloader's buffer.

    super.create();
  }

  override function update(Percent:Float):Void
  {
    _text.text = "FNF: " + Math.round(Percent * 100) + "%";

    super.update(Percent);
  }
}
