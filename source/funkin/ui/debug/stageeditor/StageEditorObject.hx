package funkin.ui.debug.stageeditor;

import funkin.data.animation.AnimationData;
import funkin.graphics.FunkinSprite;
import funkin.graphics.shaders.InverseDotsShader;

/**
 * Contains all the Logic needed for Stage Editor. Only for Stage Editor, as in the gameplay StageProps and Boppers will be used.
 */
class StageEditorObject extends FunkinSprite
{
  /**
   * The internal Name of the Object.
   */
  public var name:String = "Unnamed";

  public var selectedShader:InverseDotsShader;

  /**
   * What animation to play upon starting.
   */
  public var startingAnimation:String = "";

  public var animDatas:Map<String, AnimationData> = [];

  override public function new()
  {
    super();

    selectedShader = new InverseDotsShader(0);
    shader = selectedShader;
  }

  /**
   * Whether the Object is currently being modified in the Stage Editor.
   */
  public var isDebugged(default, set):Bool = true;

  function set_isDebugged(value:Bool):Bool
  {
    this.isDebugged = value;

    if (value == false) // plays upon starting yippee!!!
      playAnim(startingAnimation, true);
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

  public function playAnim(name:String, restart:Bool = false, reversed:Bool = false):Void
  {
    if (!animation.getNameList().contains(name)) return;

    animation.play(name, restart, reversed, 0);

    if (animDatas.exists(name)) offset.set(animDatas[name].offsets[0], animDatas[name].offsets[1]);
    else
      offset.set();
  }

  /**
   * On which beat should it dance?
   */
  public var danceEvery:Float = 0;

  /**
   * Internal, handles danceLeft and danceRight.
   */
  var _danced:Bool = true;

  public function dance(restart:Bool = false):Void
  {
    if (isDebugged) return;

    var idle = animation.getNameList().contains("idle");
    var dancing = animation.getNameList().contains("danceLeft") && animation.getNameList().contains("danceRight");

    if (!idle && !dancing) return;

    if (dancing)
    {
      if (_danced) playAnim("danceRight", restart);
      else
        playAnim("danceLeft", restart);

      _danced = !_danced;
    }
    else if (idle)
    {
      playAnim("idle", restart);
    }
  }

  public function addAnim(name:String, prefix:String, offsets:Array<Float>, indices:Array<Int>, frameRate:Int = 24, looped:Bool = true, flipX:Bool = false,
      flipY:Bool = false)
  {
    if (indices.length > 0) animation.addByIndices(name, prefix, indices, "", frameRate, looped, flipX, flipY);
    else
      animation.addByPrefix(name, prefix, frameRate, looped, flipX, flipY);

    if (animation.getNameList().contains(name)) // sometimes the animation doesnt add
    {
      animDatas.set(name,
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
