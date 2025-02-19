package funkin.ui.debug.char.animate;

import flixel.util.FlxSignal.FlxTypedSignal;
import flxanimate.FlxAnimate;
import flxanimate.FlxAnimate.Settings;
import flxanimate.frames.FlxAnimateFrames;
import flixel.graphics.frames.FlxFrame;
import flixel.system.FlxAssets.FlxGraphicAsset;
import openfl.display.BitmapData;
import flixel.math.FlxPoint;
import flxanimate.animate.FlxKeyFrame;
import funkin.ui.debug.char.handlers.CharCreatorStartupWizard;

/**
 * Literally just a copy of FlxAtlasSprite, but without the check for empty stuff. This was due to character creator requiring input of any file on the computer. I hate it here.
 */
class CharSelectAtlasSprite extends FlxAnimate
{
  static final SETTINGS:Settings =
    {
      // ?ButtonSettings:Map<String, flxanimate.animate.FlxAnim.ButtonSettings>,
      FrameRate: 24.0,
      Reversed: false,
      // ?OnComplete:Void -> Void,
      ShowPivot: false,
      Antialiasing: true,
      ScrollFactor: null,
      // Offset: new FlxPoint(0, 0), // This is just FlxSprite.offset
    };

  /**
   * Signal dispatched when an animation advances to the next frame.
   */
  public var onAnimationFrame:FlxTypedSignal<String->Int->Void> = new FlxTypedSignal();

  /**
   * Signal dispatched when a non-looping animation finishes playing.
   */
  public var onAnimationComplete:FlxTypedSignal<String->Void> = new FlxTypedSignal();

  var currentAnimation:String;

  var canPlayOtherAnims:Bool = true;

  public function new(x:Float, y:Float, ?zipBytes:haxe.io.Bytes = null, ?assetPath:String = null, ?settings:Settings)
  {
    if (settings == null) settings = SETTINGS;

    super(x, y, assetPath, settings);

    if (assetPath == null && zipBytes != null) loadFromZip(zipBytes);

    if (assetPath != null || zipBytes != null) initSymbols();
  }

  public function loadFromZip(zip:haxe.io.Bytes)
  {
    var animData:String = "";
    var spritemapArray:Array<String> = [];
    var imageMap:Map<String, BitmapData> = [];

    var zipFiles = funkin.util.FileUtil.readZIPFromBytes(zip);
    if (zipFiles.length == 0) return;

    for (file in zipFiles)
    {
      if (file.fileName.indexOf("/") != -1) file.fileName = haxe.io.Path.withoutDirectory(file.fileName);

      if (file.fileName.indexOf("Animation.json") != -1) animData = CharCreatorUtil.normalizeJSONText(file.data.toString());

      if (file.fileName.startsWith("spritemap")
        && file.fileName.endsWith(".json")) spritemapArray.push(CharCreatorUtil.normalizeJSONText(file.data.toString()));
      if (file.fileName.startsWith("spritemap")
        && file.fileName.endsWith(".png")) imageMap.set(file.fileName, BitmapData.fromBytes(file.data));
    }

    if (animData == "" || spritemapArray.length == 0 || imageMap.keys().array().length == 0) return;

    this.loadSeparateAtlas(animData, CharSelectAnimateFrames.fromTextureAtlas(spritemapArray, imageMap));

    initSymbols();
  }

  public function initSymbols()
  {
    if (this.frames == null || this.anim == null) return;

    onAnimationComplete.add(cleanupAnimation);

    // This defaults the sprite to play the first animation in the atlas,
    // then pauses it. This ensures symbols are intialized properly.
    this.anim.play('');
    this.anim.pause();

    this.anim.onComplete.add(_onAnimationComplete);
    this.anim.onFrame.add(_onAnimationFrame);
  }

  /**
   * @return A list of all the animations this sprite has available.
   */
  public function listAnimations():Array<String>
  {
    if (this.frames == null || this.anim == null) return [];

    var mainSymbol = this.anim.symbolDictionary[this.anim.stageInstance.symbol.name];
    if (mainSymbol == null)
    {
      FlxG.log.error('FlxAtlasSprite does not have its main symbol!');
      return [];
    }
    return mainSymbol.getFrameLabels().map(keyFrame -> keyFrame.name).filterNull();
  }

  /**
   * @param id A string ID of the animation.
   * @return Whether the animation was found on this sprite.
   */
  public function hasAnimation(id:String):Bool
  {
    if (this.frames == null || this.anim == null) return false;
    return getLabelIndex(id) != -1 || anim.symbolDictionary.exists(id);
  }

  /**
   * @return The current animation being played.
   */
  public function getCurrentAnimation():String
  {
    if (this.frames == null || this.anim == null) return "";
    return this.currentAnimation;
  }

  var _completeAnim:Bool = false;

  var fr:FlxKeyFrame = null;

  public var curFrame(get, never):Int;
  public var totalFrames(get, never):Int;

  public var looping:Bool = false;
  public var ignoreExclusionPref:Array<String> = [];

  /**
   * Plays an animation.
   * @param id A string ID of the animation to play.
   * @param restart Whether to restart the animation if it is already playing.
   * @param ignoreOther Whether to ignore all other animation inputs, until this one is done playing
   * @param loop Whether to loop the animation
   * @param startFrame The frame to start the animation on
   * NOTE: `loop` and `ignoreOther` are not compatible with each other!
   */
  public function playAnimation(id:String, restart:Bool = false, ignoreOther:Bool = false, loop:Bool = false, startFrame:Int = 0):Void
  {
    if (this.frames == null || this.anim == null) return;

    // Skip if not allowed to play animations.
    if ((!canPlayOtherAnims))
    {
      if (this.currentAnimation == id && restart) {}
      else if (ignoreExclusionPref != null && ignoreExclusionPref.length > 0)
      {
        var detected:Bool = false;
        for (entry in ignoreExclusionPref)
        {
          if (StringTools.startsWith(id, entry))
          {
            detected = true;
            break;
          }
        }
        if (!detected) return;
      }
      else
        return;
    }

    if (anim == null) return;

    if (id == null || id == '') id = this.currentAnimation;

    if (this.currentAnimation == id && !restart)
    {
      if (!anim.isPlaying)
      {
        if (fr != null) anim.curFrame = fr.index + startFrame;
        else
          anim.curFrame = startFrame;

        // Resume animation if it's paused.
        anim.resume();
      }

      return;
    }
    else if (!hasAnimation(id))
    {
      // Skip if the animation doesn't exist
      trace('Animation ' + id + ' not found');
      return;
    }

    this.currentAnimation = id;
    anim.onComplete.removeAll();
    anim.onComplete.add(function() {
      _onAnimationComplete();
    });

    looping = loop;

    // Prevent other animations from playing if `ignoreOther` is true.
    if (ignoreOther) canPlayOtherAnims = false;

    // Move to the first frame of the animation.
    // goToFrameLabel(id);
    // trace('Playing animation $id');
    if ((id == null || id == "") || this.anim.symbolDictionary.exists(id) || (this.anim.getByName(id) != null))
    {
      this.anim.play(id, restart, false, startFrame);

      this.currentAnimation = anim.curSymbol.name;

      fr = null;
    }
    // Only call goToFrameLabel if there is a frame label with that name. This prevents annoying warnings!
    if (getFrameLabelNames().indexOf(id) != -1)
    {
      goToFrameLabel(id);
      fr = anim.getFrameLabel(id);
      anim.curFrame += startFrame;
    }
  }

  function get_curFrame()
  {
    return (frames != null ? (anim?.curFrame ?? 0) : 0) - (fr?.index ?? 0);
  }

  function get_totalFrames()
  {
    return fr?.duration ?? (frames != null ? anim?.length ?? 0 : 0);
  }

  override public function update(elapsed:Float)
  {
    super.update(elapsed);
  }

  /**
   * Returns true if the animation has finished playing.
   * Never true if animation is configured to loop.
   */
  public function isAnimationFinished():Bool
  {
    if (this.frames == null || this.anim == null) return false;
    return this.anim.finished;
  }

  /**
   * Returns true if the animation has reached the last frame.
   * Can be true even if animation is configured to loop.
   */
  public function isLoopComplete():Bool
  {
    if (this.frames == null || this.anim == null) return false;
    if (this.anim == null) return false;
    if (!this.anim.isPlaying) return false;

    if (fr != null) return (anim.reversed && anim.curFrame < fr.index || !anim.reversed && anim.curFrame >= (fr.index + fr.duration));

    return (anim.reversed && anim.curFrame == 0 || !(anim.reversed) && (anim.curFrame) >= (anim.length - 1));
  }

  /**
   * Stops the current animation.
   */
  public function stopAnimation():Void
  {
    if (this.frames == null || this.anim == null) return;
    if (this.currentAnimation == null) return;

    this.anim.removeAllCallbacksFrom(getNextFrameLabel(this.currentAnimation));

    goToFrameIndex(0);
  }

  function addFrameCallback(label:String, callback:Void->Void):Void
  {
    if (this.frames == null || this.anim == null) return;
    var frameLabel = this.anim.getFrameLabel(label);
    frameLabel.add(callback);
  }

  function goToFrameLabel(label:String):Void
  {
    if (this.frames == null || this.anim == null) return;
    this.anim.goToFrameLabel(label);
  }

  function getFrameLabelNames(?layer:haxe.extern.EitherType<Int, String> = null)
  {
    if (this.frames == null || this.anim == null) return [];
    var labels = this.anim.getFrameLabels(layer);
    var array = [];
    for (label in labels)
    {
      array.push(label.name);
    }

    return array;
  }

  function getNextFrameLabel(label:String):String
  {
    if (this.frames == null || this.anim == null) return "";
    return listAnimations()[(getLabelIndex(label) + 1) % listAnimations().length];
  }

  function getLabelIndex(label:String):Int
  {
    if (this.frames == null || this.anim == null) return -1;
    return listAnimations().indexOf(label);
  }

  function goToFrameIndex(index:Int):Void
  {
    if (this.frames == null || this.anim == null) return;
    this.anim.curFrame = index;
  }

  public function cleanupAnimation(_:String):Void
  {
    if (this.frames == null || this.anim == null) return;

    canPlayOtherAnims = true;
    // this.currentAnimation = null;
    this.anim.pause();
  }

  function _onAnimationFrame(frame:Int):Void
  {
    if (this.frames == null || this.anim == null) return;

    if (currentAnimation != null)
    {
      onAnimationFrame.dispatch(currentAnimation, frame);

      if (isLoopComplete())
      {
        anim.pause();
        _onAnimationComplete();

        if (looping)
        {
          anim.curFrame = (fr != null) ? fr.index : 0;
          anim.resume();
        }
        else if (fr != null && anim.curFrame != anim.length - 1)
        {
          anim.curFrame--;
        }
      }
    }
  }

  function _onAnimationComplete():Void
  {
    if (this.frames == null || this.anim == null) return;

    if (currentAnimation != null)
    {
      onAnimationComplete.dispatch(currentAnimation);
    }
    else
    {
      onAnimationComplete.dispatch('');
    }
  }

  var prevFrames:Map<Int, FlxFrame> = [];

  public function replaceFrameGraphic(index:Int, ?graphic:FlxGraphicAsset):Void
  {
    if (this.frames == null || this.anim == null) return;

    if (graphic == null || !Assets.exists(graphic))
    {
      var prevFrame:Null<FlxFrame> = prevFrames.get(index);
      if (prevFrame == null) return;

      prevFrame.copyTo(frames.getByIndex(index));
      return;
    }

    var prevFrame:FlxFrame = prevFrames.get(index) ?? frames.getByIndex(index).copyTo();
    prevFrames.set(index, prevFrame);

    var frame = FlxG.bitmap.add(graphic).imageFrame.frame;
    frame.copyTo(frames.getByIndex(index));

    // Additional sizing fix.
    @:privateAccess
    if (true)
    {
      var frame = frames.getByIndex(index);
      frame.tileMatrix[0] = prevFrame.frame.width / frame.frame.width;
      frame.tileMatrix[3] = prevFrame.frame.height / frame.frame.height;
    }
  }

  public function getBasePosition():Null<FlxPoint>
  {
    // var stagePos = new FlxPoint(anim.stageInstance.matrix.tx, anim.stageInstance.matrix.ty);
    var instancePos = new FlxPoint(anim?.curInstance?.matrix?.tx ?? 0, anim?.curInstance?.matrix?.ty ?? 0);
    var firstElement = anim?.curSymbol?.timeline?.get(0)?.get(0)?.get(0);
    if (firstElement == null) return instancePos;
    var firstElementPos = new FlxPoint(firstElement.matrix.tx, firstElement.matrix.ty);

    return instancePos + firstElementPos;
  }

  public function getPivotPosition():Null<FlxPoint>
  {
    if (this.frames == null || this.anim == null) return null;
    return anim?.curInstance?.symbol?.transformationPoint;
  }

  public override function destroy():Void
  {
    for (prevFrameId in prevFrames.keys())
    {
      replaceFrameGraphic(prevFrameId, null);
    }

    super.destroy();
  }
}
