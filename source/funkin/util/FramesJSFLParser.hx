package funkin.util;

import openfl.Assets;

/**
 * See `funScripts/jsfl/frames.jsfl` for more information in the art repo/folder!
 * Homemade dipshit proprietary format to get simple animation info out of flash!
 * Pure convienience!
 */
@:nullSafety
class FramesJSFLParser
{
  public static function parse(path:String):Null<FramesJSFLInfo>
  {
    var text:String = Assets.getText(path);
    if (text == null)
    {
      trace('[ERROR] Could not load FramesJSFL data asset from path $path');
      return null;
    }

    var output:FramesJSFLInfo = {frames: []};

    var frames:Array<String> = text.split("\n");

    for (frame in frames)
    {
      var frameInfo:Array<String> = frame.split(" ");

      var x:Float = Std.parseFloat(frameInfo[0]);
      var y:Float = Std.parseFloat(frameInfo[1]);
      var alpha:Float = (frameInfo[2] != "undefined") ? Std.parseFloat(frameInfo[2]) : 100;

      var scaleX:Float = 1;
      var scaleY:Float = 1;

      if (frameInfo[3] != null) scaleX = Std.parseFloat(frameInfo[4]);
      if (frameInfo[4] != null) scaleY = Std.parseFloat(frameInfo[4]);

      var shit:FramesJSFLFrame =
        {
          x: x,
          y: y,
          alpha: alpha,
          scaleX: scaleX,
          scaleY: scaleY
        };
      output.frames.push(shit);
    }

    return output;
  }
}

typedef FramesJSFLInfo =
{
  var frames:Array<FramesJSFLFrame>;
}

typedef FramesJSFLFrame =
{
  var x:Float;
  var y:Float;
  var alpha:Float;
  var scaleX:Float;
  var scaleY:Float;
}
