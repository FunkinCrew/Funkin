package funkin.play.cutscene.dialogue;

import flixel.FlxSprite;
import funkin.modding.events.ScriptEvent;
import flixel.graphics.frames.FlxFramesCollection;
import funkin.util.assets.FlxAnimationUtil;
import funkin.modding.IScriptedClass.IDialogueScriptedClass;

/**
 * The character sprite which displays during dialogue.
 *
 * Most conversations have two speakers, with one being flipped.
 */
class Speaker extends FlxSprite implements IDialogueScriptedClass
{
  /**
   * The internal ID for this speaker.
   */
  public final speakerId:String;

  /**
   * The full data for a speaker.
   */
  var speakerData:SpeakerData;

  /**
   * A readable name for this speaker.
   */
  public var speakerName(get, never):String;

  function get_speakerName():String
  {
    return speakerData.name;
  }

  /**
   * Offset the speaker's sprite by this much when playing each animation.
   */
  var animationOffsets:Map<String, Array<Float>> = new Map<String, Array<Float>>();

  /**
   * The current animation offset being used.
   */
  var animOffsets(default, set):Array<Float> = [0, 0];

  function set_animOffsets(value:Array<Float>):Array<Float>
  {
    if (animOffsets == null) animOffsets = [0, 0];
    if ((animOffsets[0] == value[0]) && (animOffsets[1] == value[1])) return value;

    var xDiff:Float = value[0] - animOffsets[0];
    var yDiff:Float = value[1] - animOffsets[1];

    this.x += xDiff;
    this.y += yDiff;

    return animOffsets = value;
  }

  /**
   * The offset of the speaker overall.
   */
  public var globalOffsets(default, set):Array<Float> = [0, 0];

  function set_globalOffsets(value:Array<Float>):Array<Float>
  {
    if (globalOffsets == null) globalOffsets = [0, 0];
    if (globalOffsets == value) return value;

    var xDiff:Float = value[0] - globalOffsets[0];
    var yDiff:Float = value[1] - globalOffsets[1];

    this.x += xDiff;
    this.y += yDiff;
    return globalOffsets = value;
  }

  public function new(speakerId:String)
  {
    super();

    this.speakerId = speakerId;
    this.speakerData = SpeakerDataParser.parseSpeakerData(this.speakerId);

    if (speakerData == null) throw 'Could not load speaker data for speaker ID "$speakerId"';
  }

  /**
   * Called when speaker is being created.
   * @param event The script event.
   */
  public function onCreate(event:ScriptEvent):Void
  {
    this.globalOffsets = [0, 0];
    this.x = 0;
    this.y = 0;
    this.alpha = 1;

    loadSpritesheet();
    loadAnimations();
  }

  function loadSpritesheet():Void
  {
    trace('[SPEAKER] Loading spritesheet ${speakerData.assetPath} for ${speakerId}');

    var tex:FlxFramesCollection = Paths.getSparrowAtlas(speakerData.assetPath);
    if (tex == null)
    {
      trace('Could not load Sparrow sprite: ${speakerData.assetPath}');
      return;
    }

    this.frames = tex;

    if (speakerData.isPixel)
    {
      this.antialiasing = false;
    }
    else
    {
      this.antialiasing = true;
    }

    this.flipX = speakerData.flipX;
    this.globalOffsets = speakerData.offsets;
    this.setScale(speakerData.scale);
  }

  /**
   * Set the sprite scale to the appropriate value.
   * @param scale
   */
  public function setScale(scale:Null<Float>):Void
  {
    if (scale == null) scale = 1.0;
    this.scale.x = scale;
    this.scale.y = scale;
    this.updateHitbox();
  }

  function loadAnimations():Void
  {
    trace('[SPEAKER] Loading ${speakerData.animations.length} animations for ${speakerId}');

    FlxAnimationUtil.addAtlasAnimations(this, speakerData.animations);

    for (anim in speakerData.animations)
    {
      if (anim.offsets == null)
      {
        setAnimationOffsets(anim.name, 0, 0);
      }
      else
      {
        setAnimationOffsets(anim.name, anim.offsets[0], anim.offsets[1]);
      }
    }

    var animNames:Array<String> = this.animation.getNameList();
    trace('[SPEAKER] Successfully loaded ${animNames.length} animations for ${speakerId}');
  }

  /**
   * @param name The name of the animation to play.
   * @param restart Whether to restart the animation if it is already playing.
   */
  public function playAnimation(name:String, restart:Bool = false):Void
  {
    var correctName:String = correctAnimationName(name);
    if (correctName == null) return;

    this.animation.play(correctName, restart, false, 0);

    applyAnimationOffsets(correctName);
  }

  public function getCurrentAnimation():String
  {
    if (this.animation == null || this.animation.curAnim == null) return "";
    return this.animation.curAnim.name;
  }

  /**
   * Ensure that a given animation exists before playing it.
   * Will gracefully check for name, then name with stripped suffixes, then 'idle', then fail to play.
   * @param name
   */
  function correctAnimationName(name:String):String
  {
    // If the animation exists, we're good.
    if (hasAnimation(name)) return name;

    trace('[BOPPER] Animation "$name" does not exist!');

    // Attempt to strip a `-alt` suffix, if it exists.
    if (name.lastIndexOf('-') != -1)
    {
      var correctName = name.substring(0, name.lastIndexOf('-'));
      trace('[BOPPER] Attempting to fallback to "$correctName"');
      return correctAnimationName(correctName);
    }
    else
    {
      if (name != 'idle')
      {
        trace('[BOPPER] Attempting to fallback to "idle"');
        return correctAnimationName('idle');
      }
      else
      {
        trace('[BOPPER] Failing animation playback.');
        return null;
      }
    }
  }

  public function hasAnimation(id:String):Bool
  {
    if (this.animation == null) return false;

    return this.animation.getByName(id) != null;
  }

  /**
   * Define the animation offsets for a specific animation.
   */
  public function setAnimationOffsets(name:String, xOffset:Float, yOffset:Float):Void
  {
    animationOffsets.set(name, [xOffset, yOffset]);
  }

  /**
   * Retrieve an apply the animation offsets for a specific animation.
   */
  function applyAnimationOffsets(name:String):Void
  {
    var offsets:Array<Float> = animationOffsets.get(name);
    if (offsets != null && !(offsets[0] == 0 && offsets[1] == 0))
    {
      this.animOffsets = offsets;
    }
    else
    {
      this.animOffsets = [0, 0];
    }
  }

  public function onDialogueStart(event:DialogueScriptEvent):Void {}

  public function onDialogueCompleteLine(event:DialogueScriptEvent):Void {}

  public function onDialogueLine(event:DialogueScriptEvent):Void {}

  public function onDialogueSkip(event:DialogueScriptEvent):Void {}

  public function onDialogueEnd(event:DialogueScriptEvent):Void {}

  public function onUpdate(event:UpdateScriptEvent):Void {}

  public function onDestroy(event:ScriptEvent):Void
  {
    frames = null;

    this.x = 0;
    this.y = 0;
    this.globalOffsets = [0, 0];
    this.alpha = 0;

    this.kill();
  }

  public function onScriptEvent(event:ScriptEvent):Void {}
}
