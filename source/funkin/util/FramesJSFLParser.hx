package funkin.util;

import openfl.Assets;

/**
 * See `funScripts/jsfl/frames.jsfl` for more information in the art repo/folder!
 * Homemade dipshit proprietary format to get simple animation info out of flash!
 * Pure convienience!
 */
class FramesJSFLParser
{
  public static function parse(path:String):FramesJSFLInfo
  {
    var text:String = Assets.getText(path);

    // TODO: error handle if text is null

    var output:FramesJSFLInfo = {frames: []};

    var frames:Array<String> = text.split("\n");

    for (frame in frames)
    {
      var frameInfo:Array<String> = frame.split(" ");

      var x:Float = Std.parseFloat(frameInfo[0]);
      var y:Float = Std.parseFloat(frameInfo[1]);
      var alpha:Float = Std.parseFloat(frameInfo[2]);

      var shit:FramesJSFLFrame = {x: x, y: y, alpha: alpha};
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
}
