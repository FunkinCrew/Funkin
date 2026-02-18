package funkin.ui.freeplay.components;

import flixel.FlxSprite;

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
    while (!Assets.exists(Paths.image('ui/freeplay/difficulty/$assetDiffId')))
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
    }

    // Check for an XML to use an animation instead of an image.
    if (Assets.exists(Paths.xml('ui/freeplay/difficulty/$assetDiffId')))
    {
      this.frames = Paths.getSparrowAtlas('ui/freeplay/difficulty/$assetDiffId');
      this.animation.addByPrefix('idle', 'idle0', 24, true);
      if (Preferences.flashingLights) this.animation.play('idle');
    }
    else
    {
      this.loadGraphic(Paths.image('ui/freeplay/difficulty/$assetDiffId'));
      trace('Loaded difficulty asset: freeplay/freeplay$assetDiffId (from $diffId)');
    }
  }
}
