package funkin;

import flixel.FlxSprite;
import flixel.FlxState;
import flixel.graphics.FlxGraphic;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.math.FlxMath;
import flixel.math.FlxPoint;
import flixel.math.FlxRect;
import flixel.system.FlxAssets.FlxGraphicAsset;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import funkin.play.PlayState;
import funkin.shaderslmfao.ScreenWipeShader;
import haxe.Json;
import haxe.format.JsonParser;
import lime.math.Rectangle;
import lime.utils.Assets;
import openfl.filters.ShaderFilter;

class CoolUtil
{
  public static function coolBaseLog(base:Float, fin:Float):Float
  {
    return Math.log(fin) / Math.log(base);
  }

  public static function coolTextFile(path:String):Array<String>
  {
    var daList:Array<String> = [];

    var swagArray:Array<String> = Assets.getText(path).trim().split('\n');

    for (item in swagArray)
    {
      // comment support in the quick lil text formats??? using //
      if (!item.trim().startsWith('//')) daList.push(item);
    }

    for (i in 0...daList.length)
    {
      daList[i] = daList[i].trim();
    }

    return daList;
  }

  public static function numberArray(max:Int, ?min = 0):Array<Int>
  {
    var dumbArray:Array<Int> = [];
    for (i in min...max)
    {
      dumbArray.push(i);
    }
    return dumbArray;
  }

  static var oldCamPos:FlxPoint = new FlxPoint();
  static var oldMousePos:FlxPoint = new FlxPoint();

  /**
   * Used to be for general camera middle click dragging, now generalized for any click and drag type shit!
   * Listen I don't make the rules here
   * @param target what you want to be dragged, defaults to CAMERA SCROLL
   * @param jusPres the "justPressed", should be a button of some sort
   * @param pressed the "pressed", which should be the same button as `jusPres`
   */
  public static function mouseCamDrag(?target:FlxPoint, ?jusPres:Bool, ?pressed:Bool):Void
  {
    if (target == null) target = FlxG.camera.scroll;

    if (jusPres == null) jusPres = FlxG.mouse.justPressedMiddle;

    if (pressed == null) pressed = FlxG.mouse.pressedMiddle;

    if (jusPres)
    {
      oldCamPos.set(target.x, target.y);
      oldMousePos.set(FlxG.mouse.screenX, FlxG.mouse.screenY);
    }

    if (pressed)
    {
      target.x = oldCamPos.x - (FlxG.mouse.screenX - oldMousePos.x);
      target.y = oldCamPos.y - (FlxG.mouse.screenY - oldMousePos.y);
    }
  }

  public static function mouseWheelZoom():Void
  {
    if (FlxG.mouse.wheel != 0) FlxG.camera.zoom += FlxG.mouse.wheel * (0.1 * FlxG.camera.zoom);
  }

  /**
    Lerps camera, but accountsfor framerate shit?
    Right now it's simply for use to change the followLerp variable of a camera during update
    TODO LATER MAYBE:
      Actually make and modify the scroll and lerp shit in it's own function
      instead of solely relying on changing the lerp on the fly
   */
  public static function camLerpShit(lerp:Float):Float
  {
    return lerp * (FlxG.elapsed / (1 / 60));
  }

  public static function coolSwitchState(state:FlxState, transitionTex:String = "shaderTransitionStuff/coolDots", time:Float = 2)
  {
    var screenShit:FlxSprite = new FlxSprite().loadGraphic(Paths.image("shaderTransitionStuff/coolDots"));
    var screenWipeShit:ScreenWipeShader = new ScreenWipeShader();

    screenWipeShit.funnyShit.input = screenShit.pixels;
    FlxTween.tween(screenWipeShit, {daAlphaShit: 1}, time,
      {
        ease: FlxEase.quadInOut,
        onComplete: function(twn) {
          screenShit.destroy();
          FlxG.switchState(new MainMenuState());
        }
      });
    FlxG.camera.setFilters([new ShaderFilter(screenWipeShit)]);
  }

  /**
   * Just saves the json with some default values hehe
   * @param json 
   * @return String
   */
  public static inline function jsonStringify(data:Dynamic):String
  {
    return Json.stringify(data, null, "\t");
  }

  /**
   * Hashlink json encoding fix for some wacky bullshit
   * https://github.com/HaxeFoundation/haxe/issues/6930#issuecomment-384570392
   */
  public static function coolJSON(fileData:String)
  {
    var cont = fileData;
    function is(n:Int, what:Int)
      return cont.charCodeAt(n) == what;
    return JsonParser.parse(cont.substr(if (is(0, 65279)) /// looks like a HL target, skipping only first character here:
      1 else if (is(0, 239) && is(1, 187) && is(2, 191)) /// it seems to be Neko or PHP, start from position 3:
      3 else /// all other targets, that prepare the UTF string correctly
      0));
  }

  /*
   * frame dependant lerp kinda lol
   */
  public static function coolLerp(base:Float, target:Float, ratio:Float):Float
  {
    return base + camLerpShit(ratio) * (target - base);
  }
}
