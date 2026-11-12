package funkin.play.cutscene.dialogue;

import flixel.FlxSprite;
import flixel.sound.FlxSound;
import funkin.data.IRegistryEntry;
import flixel.group.FlxSpriteGroup;
import funkin.group.FunkinGroup;
import funkin.group.FunkinGroup.FunkinSpriteGroup;
import flixel.graphics.frames.FlxFramesCollection;
import funkin.graphics.FunkinSprite;
import funkin.util.assets.FlxAnimationUtil;
import funkin.modding.events.ScriptEvent;
import funkin.audio.FunkinSound;
import funkin.modding.IScriptedClass.IDialogueScriptedClass;
import flixel.util.FlxColor;
import funkin.data.dialogue.DialogueBoxData;
import funkin.data.dialogue.DialogueBoxRegistry;
//
// ~PATHS~
//
import funkin.assets.Assets;
import funkin.assets.Assets.AssetType;
import funkin.assets.Paths.AnimateAtlasAssetPathBuilder;
import funkin.assets.Paths.AssetPath;
import funkin.assets.Paths.MusicAssetPathBuilder;
import funkin.assets.ValidatedPaths as Paths;

class DialogueBox extends FunkinSpriteGroup implements IDialogueScriptedClass implements IRegistryEntry<DialogueBoxData>
{
  public var dialogueBoxName(get, never):String;

  function get_dialogueBoxName():String
  {
    return _data.name ?? 'UNKNOWN';
  }

  /**
   * Offset the speaker's sprite by this much when playing each animation.
   */
  var animationOffsets:Map<String, Array<Float>> = new Map<String, Array<Float>>();

  /**
   * The position without offsets applied.
   */
  var originalPosition:Array<Float> = [0, 0];

  /**
   * The current animation offset being used.
   */
  var animOffsets(default, set):Array<Float> = [0, 0];

  function set_animOffsets(value:Array<Float>):Array<Float>
  {
    if (animOffsets == null) animOffsets = [0, 0];
    if (animOffsets == value) return value;

    this.x = globalOffsets[0] + originalPosition[0] + value[0];
    this.y = globalOffsets[1] + originalPosition[1] + value[1];

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

    this.screenCenter();

    originalPosition[0] = this.x;
    originalPosition[1] = this.y;

    this.x = value[0] + originalPosition[0] + animOffsets[0];
    this.localX = value[0] + originalPosition[0] + animOffsets[0];
    this.y = value[1] + originalPosition[1] + animOffsets[1];
    this.localY = value[1] + originalPosition[1] + animOffsets[1];

    return globalOffsets = value;
  }

  public function capturePosition():Array<Float>
  {
    return [originalPosition[0], originalPosition[1]];
  }

  public function restorePosition(position:Array<Float>):Void
  {
    if (position == null || position.length < 2) return;

    originalPosition[0] = position[0];
    originalPosition[1] = position[1];

    final newX:Float = globalOffsets[0] + originalPosition[0] + animOffsets[0];
    final newY:Float = globalOffsets[1] + originalPosition[1] + animOffsets[1];

    this.x = newX;
    this.localX = newX;
    this.y = newY;
    this.localY = newY;
  }

  var boxSprite:FlxSprite;
  var textDisplay:FunkinTypeText;
  var typingSounds:Array<FlxSound> = [];
  var _text:String = '';

  public var text(get, set):String;

  function get_text():String
  {
    return _text;
  }

  function set_text(value:String):String
  {
    _text = value ?? '';
    if (textDisplay != null)
    {
      textDisplay.prefix = '';
      textDisplay.resetText(_text);
      textDisplay.start();
    }
    return _text;
  }

  var _speed:Float = 1.0;

  public var speed(get, set):Float;

  function get_speed():Float
  {
    return _speed;
  }

  function set_speed(value:Float):Float
  {
    _speed = Math.max(0.0, value);
    if (textDisplay != null)
    {
      textDisplay.delay = _speed <= 0.0 ? 0.0 : 0.05 / _speed;
    }
    return _speed;
  }

  /**
   * Retrieve a list of all the asset paths required to load the speaker.
   *
   * If you have a scripted class which initializes sprites, or plays sounds or something,
   * make sure you add them here so they get cached in the loading screen.
   *
   * @param type The type of asset to query
   * @param entryId The speaker ID, used to look up the specific assets.
   * @param params The entry parameters, if any.
   * @return An array of asset paths, or empty if no assets of that type are required.
   */
  public static function queryAssets(type:funkin.assets.Assets.AssetType,
    entryId:String,
    ?params:DialogueBoxEntryParams):Array<funkin.assets.Paths.AssetPath>
  {
    var results:Array<funkin.assets.Paths.AssetPath> = [];

    var _data:Null<DialogueBoxData> = DialogueBox._fetchData(entryId);
    if (_data == null) return results;

    switch (type)
    {
      case IMAGE:
        results.push(funkin.assets.Paths.image(_data.assetPath));
      case XML:
        if (_data.animations.length > 0) results.push(funkin.assets.Paths.xml(_data.assetPath));
      default:
        // Nothing
    }

    return results;
  }

  public function new(id:String, ?params:Dynamic)
  {
    super();
    this.id = id;
    this._data = _fetchData(id);

    if (_data == null)
    {
      throw 'Could not parse dialogue box data for id: $id';
    }
  }

  public function onCreate(event:ScriptEvent):Void
  {
    this.x = 0;
    this.y = 0;
    this.globalOffsets = [0, 0];
    this.alpha = 1;

    loadSpritesheet();
    loadAnimations();

    loadText();
  }

  function loadSpritesheet():Void
  {
    if (this.boxSprite != null)
    {
      remove(this.boxSprite);
      this.boxSprite.kill();
      this.boxSprite.destroy();
      this.boxSprite = null;
    }

    this.animationOffsets = new Map<String, Array<Float>>();
    this.animOffsets = [0, 0];
    this.boxSprite = new FunkinSprite(0, 0);

    trace('[DIALOGUE BOX] Loading spritesheet ${_data.assetPath} for ${id}');

    var tex:Null<FlxFramesCollection> = null;
    try
    {
      tex = Paths.getSparrowAtlas(_data.assetPath);
    }
    catch (e)
    {
      trace('[DIALOGUE BOX] Sparrow atlas unavailable for ${_data.assetPath}; trying static image.');
    }

    if (tex != null)
    {
      this.boxSprite.frames = tex;
    }
    else
    {
      this.boxSprite.loadGraphic(Paths.image(_data.assetPath).toFlxGraphicAsset());
    }

    if (_data.isPixel)
    {
      this.boxSprite.antialiasing = false;
    }
    else
    {
      this.boxSprite.antialiasing = true;
    }

    this.boxSprite.flipX = _data.flipX;
    this.boxSprite.flipY = _data.flipY;
    this.globalOffsets = _data.offsets;
    this.setScale(_data.scale);

    add(this.boxSprite);
  }

  public function setTypingSounds(soundPaths:Array<String>):Void
  {
    if (textDisplay == null) return;

    for (sound in typingSounds)
    {
      if (sound != null) sound.destroy();
    }
    typingSounds = [];

    for (soundPath in soundPaths)
    {
      if (soundPath == null || soundPath == '') continue;

      var sound:Null<FunkinSound> = FunkinSound.load(Paths.sound(soundPath).toFlxSoundAsset(), 0.6);
      if (sound != null) typingSounds.push(sound);
    }

    textDisplay.sounds = typingSounds;
  }

  public function setText(newText:String, soundPaths:Array<String>):Void
  {
    setTypingSounds(soundPaths);
    text = newText;
  }

  public function appendText(newText:String, soundPaths:Array<String>):Void
  {
    if (textDisplay == null) return;
    setTypingSounds(soundPaths);

    var prefix:String = textDisplay.text ?? '';
    _text = prefix + (newText ?? '');
    textDisplay.prefix = prefix;
    textDisplay.resetText(newText ?? '');
    textDisplay.start();
  }

  public function skip():Void
  {
    textDisplay.skip();
  }

  /**
   * Reassign this to set a callback.
   */
  function onTypingComplete():Void
  {
    // No save navigation? :(
    if (typingCompleteCallback != null) typingCompleteCallback();
  }

  public var typingCompleteCallback:() -> Void;

  /**
   * Set the sprite scale to the appropriate value.
   *
   * @param scale The desired scale.
   */
  public function setScale(scale:Null<Float>):Void
  {
    if (scale == null) scale = 1.0;

    this.boxSprite.scale.x = scale;
    this.boxSprite.localScale.x = scale;
    this.boxSprite.scale.y = scale;
    this.boxSprite.localScale.y = scale;

    this.boxSprite.updateHitbox();
  }

  /**
   * Calls `kill()` on the group's members and then on the group itself.
   * You can revive this group later via `revive()` after this.
   */
  override public function kill():Void
  {
    super.kill();
  }

  override public function revive():Void
  {
    super.revive();

    this.x = 0;
    this.y = 0;
    this.globalOffsets = [0, 0];
    this.visible = true;
    this.alpha = 1.0;

    if (this.boxSprite != null)
    {
      this.boxSprite.visible = true;
      this.boxSprite.alpha = 1.0;
      this.boxSprite.flipX = _data.flipX;
      this.boxSprite.flipY = _data.flipY;
    }
    if (this.textDisplay != null)
    {
      this.textDisplay.visible = true;
      this.textDisplay.alpha = 1.0;
    }
  }

  function loadAnimations():Void
  {
    trace('[DIALOGUE BOX] Loading ${_data.animations.length} animations for ${id}');

    FlxAnimationUtil.addAtlasAnimations(this.boxSprite, _data.animations);

    for (anim in _data.animations)
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

    var animNames:Array<String> = this.boxSprite?.animation?.getNameList() ?? [];
    trace('[DIALOGUE BOX] Successfully loaded ${animNames.length} animations for ${id}');

    boxSprite.animation.onFrameChange.add(this.onAnimationFrame);
    boxSprite.animation.onFinish.add(this.onAnimationFinished);
  }

  /**
   * Called when an animation finishes.
   * @param name The name of the animation that just finished.
   */
  function onAnimationFinished(name:String):Void
  {
  }

  /**
   * Called when the current animation's frame changes.
   * @param name The name of the current animation.
   * @param frameNumber The number of the current frame.
   * @param frameIndex The index of the current frame.
   *
   * For example, if an animation was defined as having the indexes [3, 0, 1, 2],
   * then the first callback would have frameNumber = 0 and frameIndex = 3.
   */
  function onAnimationFrame(name:String = '', frameNumber:Int = -1, frameIndex:Int = -1):Void
  {
    // Do nothing by default.
    // This can be overridden by, for example, scripts,
    // or by calling `animationFrame.add()`.

    // Try not to do anything expensive here, it runs many times a second.
  }

  function loadText():Void
  {
    if (textDisplay != null)
    {
      remove(textDisplay);
      textDisplay.kill();
      textDisplay.destroy();
      textDisplay = null;
    }

    textDisplay = new FunkinTypeText(0, 0, 300, '', 32);
    textDisplay.fieldWidth = _data.text.width;
    textDisplay.setFormat(
      _data.text.fontFamily,
      _data.text.size,
      FlxColor.fromString(_data.text.color),
      LEFT,
      SHADOW,
      FlxColor.fromString(_data.text.shadowColor ?? '#00000000'),
      false
    );
    textDisplay.borderSize = _data.text.shadowWidth ?? 0;
    textDisplay.delay = _speed <= 0.0 ? 0.0 : 0.05 / _speed;

    textDisplay.completeCallback = onTypingComplete;

    textDisplay.x += _data.text.offsets[0];
    textDisplay.localX = textDisplay.x;
    textDisplay.y += _data.text.offsets[1];
    textDisplay.localY = textDisplay.y;

    add(textDisplay);
  }

  /**
   * @param name The name of the animation to play.
   * @param restart Whether to restart the animation if it is already playing.
   * @param reversed If true, play the animation backwards, from the last frame to the first.
   */
  public function playAnimation(name:String, restart:Bool = false, reversed:Bool = false):Void
  {
    var correctName:String = correctAnimationName(name);
    if (correctName == null) return;

    this.boxSprite.animation.play(correctName, restart, reversed, 0);

    applyAnimationOffsets(correctName);
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

    trace('[DIALOGUE BOX] Animation "$name" does not exist!');

    // Attempt to strip a `-alt` suffix, if it exists.
    if (name.lastIndexOf('-') != -1)
    {
      var correctName = name.substring(0, name.lastIndexOf('-'));
      trace('[DIALOGUE BOX] Attempting to fallback to "$correctName"');
      return correctAnimationName(correctName);
    }
    else
    {
      if (name != 'idle')
      {
        trace('[DIALOGUE BOX] Attempting to fallback to "idle"');
        return correctAnimationName('idle');
      }
      else
      {
        trace('[DIALOGUE BOX] Failing animation playback.');
        return null;
      }
    }
  }

  public function hasAnimation(id:String):Bool
  {
    if (this.boxSprite.animation == null) return false;

    return this.boxSprite.animation.getByName(id) != null;
  }

  /**
   * Returns the name of the animation that is currently playing.
   * If no animation is playing (usually this means the character is BROKEN!),
   *   returns an empty string to prevent NPEs.
   */
  public function getCurrentAnimation():String
  {
    if (this.boxSprite == null || this.boxSprite.animation == null || this.boxSprite.animation.curAnim == null) return '';
    return this.boxSprite.animation.curAnim.name;
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

  public function isAnimationFinished():Bool
  {
    return this.boxSprite?.animation?.finished ?? true;
  }

  /**
   * Whether the currently playing dialogue-box animation is looped.
   */
  public function isCurrentAnimationLooped():Bool
  {
    return this.boxSprite?.animation?.curAnim?.looped ?? false;
  }

  override public function toString():String
  {
    return 'DialogueBox($id)';
  }

  public function onDialogueStart(event:DialogueScriptEvent):Void
  {
  }

  public function onDialogueCompleteLine(event:DialogueScriptEvent):Void
  {
  }

  public function onDialogueLine(event:DialogueScriptEvent):Void
  {
  }

  public function onDialogueSkip(event:DialogueScriptEvent):Void
  {
  }

  public function onDialogueEnd(event:DialogueScriptEvent):Void
  {
    if (textDisplay != null) textDisplay.paused = true;
  }

  public function onUpdate(event:UpdateScriptEvent):Void
  {
  }

  public function onDestroy(event:ScriptEvent):Void
  {
    if (boxSprite != null) remove(boxSprite);
    boxSprite = null;
    if (textDisplay != null) remove(textDisplay);
    textDisplay = null;

    for (sound in typingSounds)
    {
      if (sound != null) sound.destroy();
    }
    typingSounds = [];

    this.clear();

    this.x = 0;
    this.y = 0;
    this.globalOffsets = [0, 0];
    this.alpha = 0;

    this.kill();
  }

  public function onScriptEvent(event:ScriptEvent):Void
  {
  }
}
