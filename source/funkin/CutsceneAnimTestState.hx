package funkin;

import flixel.FlxSprite;
import flixel.FlxState;
import flixel.addons.display.FlxGridOverlay;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.math.FlxPoint;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import openfl.Assets;
import openfl.display.BitmapData;
import openfl.display.MovieClip;
import openfl.display.Timeline;
import openfl.geom.Matrix;
import openfl.geom.Rectangle;

class CutsceneAnimTestState extends FlxState
{
  var cutsceneGroup:CutsceneCharacter;

  var curSelected:Int = 0;
  var debugTxt:FlxText;

  var funnySprite:FlxSprite = new FlxSprite();
  var clip:MovieClip;

  public function new()
  {
    super();

    var gridBG:FlxSprite = FlxGridOverlay.create(10, 10);
    gridBG.scrollFactor.set(0.5, 0.5);
    add(gridBG);

    debugTxt = new FlxText(900, 20, 0, "", 20);
    debugTxt.color = FlxColor.BLUE;
    add(debugTxt);

    clip = Assets.getMovieClip("tanky:");
    // clip.x = FlxG.width/2;
    // clip.y = FlxG.height/2;
    FlxG.stage.addChild(clip);

    var swagShit:MovieClip = Assets.getMovieClip('tankBG:');
    // swagShit.scaleX = 5;

    FlxG.stage.addChild(swagShit);
    swagShit.gotoAndStop(13);

    var swfMountain = new BitmapData(FlxG.width, FlxG.height, true, 0x00000000);
    swfMountain.draw(swagShit, swagShit.transform.matrix);

    var mountains:FlxSprite = new FlxSprite().loadGraphic(swfMountain);
    // add(mountains);

    FlxG.stage.removeChild(swagShit);

    funnySprite.x = FlxG.width / 2;
    funnySprite.y = FlxG.height / 2;
    add(funnySprite);
  }

  override function update(elapsed:Float)
  {
    super.update(elapsed);

    // jam sprite into top left corner
    var drawMatrix:Matrix = clip.transform.matrix;
    var bounds:Rectangle = clip.getBounds(null);
    drawMatrix.tx = -bounds.x;
    drawMatrix.ty = -bounds.y;
    // make bitmapdata only as big as it needs to be
    var funnyBmp:BitmapData = new BitmapData(Math.ceil(bounds.width), Math.ceil(bounds.height), true, 0x00000000);
    funnyBmp.draw(clip, drawMatrix, true);
    funnySprite.loadGraphic(funnyBmp);
    // jam sprite back into place lol
    funnySprite.offset.x = -bounds.x;
    funnySprite.offset.y = -bounds.y;
  }
}
