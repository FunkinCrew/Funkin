package funkin.ui.debug.stageeditor.components;

import funkin.data.animation.AnimationData;
import funkin.graphics.FunkinSprite;
import funkin.graphics.shaders.InverseDotsShader;

@:nullSafety
class StageEditorObject extends FunkinSprite
{
  /**
   * The internal name of this object.
   */
  public var name:String = 'Unnamed';

  /**
   * The shader applied to this object.
   */
  public var selectedShader:InverseDotsShader;

  /**
   * The animation this object starts with.
   */
  public var startingAnimation:String = '';

  /**
   * A map of animation names to their data.
   */
  public var animData:Map<String, AnimationData> = [];

  /**
   * The object plays the dance animation once every `danceEvery` beats.
   * Set to 0 to disable idle animation.
   * Supports up to 0.25 precision.
   * @default 0.0 on props, 1.0 on characters
   */
  public var danceEvery:Float = 0.0;

  /**
   * Whether the bopper should dance left and right.
   * - If true, alternate playing `danceLeft` and `danceRight`.
   * - If false, play `idle` every time.
   */
  public var shouldAlternate(get, never):Bool;

  function get_shouldAlternate():Bool
  {
    return this.animation.getByName("danceLeft") != null;
  }

  /**
   * Whether to play `danceRight` next iteration.
   * Only used when `shouldAlternate` is true.
   */
  var hasDanced:Bool = false;

  override public function new(?x:Float = 0, ?y:Float = 0)
  {
    super(x, y);

    selectedShader = new InverseDotsShader(0);
    shader = selectedShader;
  }

  public var isDebugged(default, set):Bool = true;

  function set_isDebugged(value:Bool):Bool
  {
    this.isDebugged = value;

    if (value == false) playAnimation(startingAnimation, true);
    else
    {
      if (animation.curAnim != null)
      {
        animation.stop();
        offset.set();
        updateHitbox();
      }
    }

    return value;
  }

  public function playAnimation(name:String, restart:Bool = false, reversed:Bool = false):Void
  {
    if (!animation.getNameList().contains(name)) return;

    animation.play(name, restart, reversed, 0);

    if (animData.exists(name) && animData[name] != null)
    {
      var data = animData[name];
      if (data != null && data.offsets != null) offset.set(data.offsets[0], data.offsets[1]);
    }
    else offset.set();
  }

  public function dance(restart:Bool = false):Void
  {
    if (isDebugged) return;

    var idle = animation.getNameList().contains('idle');
    var dancing = animation.getNameList().contains('danceLeft') && animation.getNameList().contains('danceRight');

    if (!idle && !dancing) return;

    if (shouldAlternate)
    {
      if (hasDanced) playAnimation('danceRight', restart);
      else playAnimation('danceLeft', restart);

      hasDanced = !hasDanced;
    }
    else playAnimation('idle', restart);
  }

  public function addAnimation(name:String, prefix:String, offsets:Array<Float>, indices:Array<Int>, frameRate:Int = 24, looped:Bool = true, flipX:Bool = false, flipY:Bool = false):Void
  {
    if (indices.length > 0) animation.addByIndices(name, prefix, indices, "", frameRate, looped, flipX, flipY);
    else animation.addByPrefix(name, prefix, frameRate, looped, flipX, flipY);

    if (animation.getNameList().contains(name))
    {
      animData.set(name,
        {
          name: name,
          prefix: prefix,
          offsets: offsets,
          looped: looped,
          frameRate: frameRate,
          flipX: flipX,
          flipY: flipY,
          frameIndices: indices
        });
    }
  }
}
