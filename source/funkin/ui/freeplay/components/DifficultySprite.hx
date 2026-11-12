package funkin.ui.freeplay.components;

import flixel.FlxSprite;
//
// ~PATHS~
//
import funkin.assets.Assets;
import funkin.assets.Paths;

/**
 * The sprite for the difficulty
 */
@:nullSafety
class DifficultySprite extends FlxSprite
{
  public var difficultyId:String;

  /**
   * Query the assets required to display each difficulty in the Freeplay menu.
   *
   * @param type The type of asset to query
   * @param difficultyList The list of difficulties to query for assets.
   * @return An array of asset paths, or empty if no assets of that type are required.
   */
  public static function queryAssets(type:AssetType, difficultyList:Array<String>):Array<AssetPath>
  {
    var results:Array<Null<AssetPath>> = [];

    switch (type)
    {
      case IMAGE:
        results.append(difficultyList.map(diffId -> Paths.image('ui/freeplay/difficulty/$diffId')));
      case XML:
        results.append(difficultyList.map(diffId -> Paths.xml('ui/freeplay/difficulty/$diffId', false).orNull()).filterNull());
      default:
        // Nothing
    }

    return results.filterNull();
  }

  public function new(diffId:String)
  {
    super();

    this.difficultyId = diffId;

    var assetDiffId:String = diffId;
    var assetPath:AssetPath = Paths.image('ui/freeplay/difficulty/$assetDiffId');
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
      assetPath = Paths.image('ui/freeplay/difficulty/$assetDiffId');
    }

    // Check for an XML to use an animation instead of an image.
    var xmlAssetPath:AssetPath = assetPath.withAssetType(XML);
    if (xmlAssetPath.exists())
    {
      this.frames = Assets.getSparrowAtlas(assetPath);
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
