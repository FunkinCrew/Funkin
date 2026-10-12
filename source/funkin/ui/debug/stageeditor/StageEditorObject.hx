package funkin.ui.debug.stageeditor;

#if FEATURE_STAGE_EDITOR
import flixel.graphics.frames.FlxFramesCollection;
import funkin.data.animation.AnimationData;
import funkin.play.stage.Bopper;
import funkin.util.assets.FlxAnimationUtil;
import funkin.graphics.shaders.InverseDotsShader;
import funkin.ui.debug.stageeditor.StageEditorState.StageEditorAssetFile;

/**
 * Contains all the Logic needed for Stage Editor. Only for Stage Editor, as in the gameplay StageProps and Boppers will be used.
 */
class StageEditorObject extends Bopper
{
  /**
   * The files used on this asset that will be saved later.
   */
  public var usedFiles:Array<StageEditorAssetFile> = [];

  public var selectedShader:InverseDotsShader;

  /**
   * What animation to play upon starting.
   */
  public var startingAnimation:String = "";

  /**
   * Stored list of animation data for easier exports.
   */
  public var animationDatas:Map<String, AnimationData> = [];

  override public function new()
  {
    super();

    selectedShader = new InverseDotsShader(0);
    shader = selectedShader;
  }

  override function set_frames(frames:FlxFramesCollection)
  {
    // Remove files associated with this sprite when resetting its frames.
    usedFiles.resize(0);

    // Since animations get reset when changing frames, we also have to reset the animation data stored.
    animationDatas.clear();
    startingAnimation = '';

    return super.set_frames(frames);
  }

  override function destroy()
  {
    // Destroy the frame collection to prevent multiple texture atlas objects using the same frame collection instance.
    this.frames.destroy();

    super.destroy();
  }

  /**
   * Whether the Object is currently being modified in the Stage Editor.
   */
  public var isDebugged(default, set):Bool = true;

  function set_isDebugged(value:Bool):Bool
  {
    this.isDebugged = value;

    if (!value)
    {
      update_shouldAlternate(); // Update the alternating animation now in case the animation list was changed.
      playAnimation(startingAnimation, true);
    }
    else
    {
      if (animation.curAnim != null) animation.stop();
    }

    return value;
  }

  public function addAnimation(data:AnimationData)
  {
    if (this.isAnimate)
    {
      FlxAnimationUtil.addTextureAtlasAnimation(this, data);
    }
    else
    {
      FlxAnimationUtil.addAtlasAnimation(this, data);
    }

    setAnimationOffsets(data.name, data.offsets[0], data.offsets[1]);
    animationDatas.set(data.name, data);
  }
}
#end
