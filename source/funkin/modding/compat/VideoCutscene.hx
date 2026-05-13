package funkin.modding.compat;

import funkin.play.cutscene.VideoCutscene.CutsceneType;
//
// ~PATHS~
//
import funkin.assets.Assets as Assets;
import funkin.assets.Paths.AssetPath;
import funkin.assets.Paths.AnimateAtlasAssetPathBuilder;
import funkin.assets.Paths.MusicAssetPathBuilder;
import funkin.assets.ValidatedPaths as Paths;

class VideoCutscene
{
  public static function play(assetPath:Dynamic, ?cutsceneType:CutsceneType = STARTING):Void
  {
    if (Std.isOfType(assetPath, AssetPath))
    {
      funkin.play.cutscene.VideoCutscene.play(assetPath, cutsceneType);
    }
    else if (Std.isOfType(assetPath, String))
    {
      var rawPath:String = haxe.io.Path.withoutExtension(assetPath).replace('assets/', '');
      var videoPath:AssetPath = Paths.video(rawPath);

      trace('Playing video cutscene at ${videoPath.toString()}');

      // Paths.video() has its own compat.
      funkin.play.cutscene.VideoCutscene.play(videoPath, cutsceneType);
    }
    else
    {
      funkin.play.cutscene.VideoCutscene.play(null);
    }
  }
}
