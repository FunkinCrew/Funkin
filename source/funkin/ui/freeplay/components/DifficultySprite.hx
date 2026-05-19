package funkin.ui.freeplay.components;

import flixel.FlxSprite;
//
// ~PATHS~
//
import funkin.assets.Assets as Assets;
import funkin.assets.Paths.AssetPath;
import funkin.assets.Paths.AnimateAtlasAssetPathBuilder;
import funkin.assets.Paths.MusicAssetPathBuilder;
import funkin.assets.ValidatedPaths as Paths;

/**
 * The sprite for the difficulty
 */
@:nullSafety
class DifficultySprite extends FlxSprite
{
  public var difficultyId:String;

  public function new(diffId:String)
  {
    super();

    this.difficultyId = diffId;

    var assetDiffId:String = diffId;
    var assetPath:AssetPath = funkin.assets.Paths.image('ui/freeplay/difficulty/$assetDiffId');
    while (!assetPath.exists())
    {
      // Remove the last suffix of the difficulty id until we find an asset or there are no more suffixes.
      var assetDiffIdParts:Array<String> = assetDiffId.split('-');
      assetDiffIdParts.pop();
      if (assetDiffIdParts.length == 0)
      {
        trace('Could not find difficulty asset: ui/freeplay/difficulty/$diffId (from $diffId)');
        return;
      };
      assetDiffId = assetDiffIdParts.join('-');
      assetPath = funkin.assets.Paths.image('ui/freeplay/difficulty/$assetDiffId');
    }

    // Check for an XML to use an animation instead of an image.
    var xmlAssetPath:AssetPath = assetPath.withAssetType(XML);
    if (xmlAssetPath.exists())
    {
      this.frames = funkin.assets.Assets.getSparrowAtlas(assetPath);
      this.animation.addByPrefix('idle', 'idle0', 24, true);
      if (Preferences.flashingLights) this.animation.play('idle');
    }
    else
    {
      this.loadGraphic(assetPath.toFlxGraphicAsset());
      trace('Loaded difficulty asset: ${assetPath.toString()} (from $diffId)');
    }
  }
}
