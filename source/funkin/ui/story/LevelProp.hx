package funkin.ui.story;

import funkin.play.stage.Bopper;
import funkin.util.assets.FlxAnimationUtil;
import funkin.data.level.LevelData;

class LevelProp extends Bopper
{
  public function new(danceEvery:Int)
  {
    super(danceEvery);
  }

  public function playConfirm():Void
  {
    playAnimation('confirm', true, true);
  }

  public static function build(propData:LevelPropData):Null<LevelProp>
  {
    var isAnimated:Bool = propData.animations.length > 0;
    var prop:LevelProp = new LevelProp(propData.danceEvery);

    if (isAnimated)
    {
      // Initalize sprite frames.
      // Sparrow atlas only LEL.
      prop.frames = Paths.getSparrowAtlas(propData.assetPath);
    }
    else
    {
      // Initalize static sprite.
      prop.loadGraphic(Paths.image(propData.assetPath));

      // Disables calls to update() for a performance boost.
      prop.active = false;
    }

    if (prop.frames == null || prop.frames.numFrames == 0)
    {
      trace('ERROR: Could not build texture for level prop (${propData.assetPath}).');
      return null;
    }

    var scale:Float = propData.scale * (propData.isPixel ? 6 : 1);
    prop.scale.set(scale, scale);
    prop.antialiasing = !propData.isPixel;
    prop.alpha = propData.alpha;
    prop.x = propData.offsets[0];
    prop.y = propData.offsets[1];

    FlxAnimationUtil.addAtlasAnimations(prop, propData.animations);
    for (propAnim in propData.animations)
    {
      prop.setAnimationOffsets(propAnim.name, propAnim.offsets[0], propAnim.offsets[1]);
    }

    prop.dance();
    prop.animation.paused = true;

    return prop;
  }
}
