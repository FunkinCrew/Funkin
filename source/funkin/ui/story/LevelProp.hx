package funkin.ui.story;

import funkin.play.stage.Bopper;
import funkin.util.assets.FlxAnimationUtil;
import funkin.data.story.level.LevelData.LevelPropData;

class LevelProp extends Bopper
{
  public var propData(default, set):Null<LevelPropData> = null;

  function set_propData(value:LevelPropData):LevelPropData
  {
    // Only reset the prop if the asset path has changed.
    if (propData == null || !(thx.Dynamics.equals(value, propData)))
    {
      this.propData = value;

      this.visible = this.propData != null;
      danceEvery = this.propData?.danceEvery ?? 1.0;

      applyData();
    }

    return this.propData;
  }

  public function new(propData:LevelPropData)
  {
    super(propData.danceEvery);
    this.propData = propData;
  }

  public function playConfirm():Void
  {
    if (hasAnimation('confirm')) playAnimation('confirm', true, true);
  }

  function applyData():Void
  {
    if (propData == null)
    {
      this.visible = false;
      return;
    }
    else
    {
      this.visible = true;
    }

    // Reset animation state.
    this.shouldAlternate = null;

    var isAnimated:Bool = propData.animations.length > 0;
    if (isAnimated)
    {
      // Initalize sprite frames.
      // Sparrow atlas only LEL.
      this.frames = Paths.getSparrowAtlas(propData.assetPath);
    }
    else
    {
      // Initalize static sprite.
      this.loadGraphic(Paths.image(propData.assetPath));

      // Disables calls to update() for a performance boost.
      this.active = false;
    }

    if (this.frames == null || this.frames.numFrames == 0)
    {
      trace('ERROR: Could not build texture for level prop (${propData.assetPath}).');
      return;
    }

    var scale:Float = propData.scale * (propData.isPixel ? 6 : 1);
    this.scale.set(scale, scale);
    this.antialiasing = !propData.isPixel;
    this.alpha = propData.alpha;
    this.x = propData.offsets[0];
    this.y = propData.offsets[1];

    FlxAnimationUtil.addAtlasAnimations(this, propData.animations);
    for (propAnim in propData.animations)
    {
      this.setAnimationOffsets(propAnim.name, propAnim.offsets[0], propAnim.offsets[1]);
    }

    this.dance();
    this.animation.paused = true;
  }

  public static function build(propData:Null<LevelPropData>):Null<LevelProp>
  {
    if (propData == null) return null;

    return new LevelProp(propData);
  }
}
