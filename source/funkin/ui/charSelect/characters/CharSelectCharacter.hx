package funkin.ui.charSelect.characters;

import flixel.FlxCamera;
import flixel.graphics.frames.FlxFramesCollection;
import flixel.math.FlxPoint;
import funkin.data.animation.AnimationData;
import funkin.data.freeplay.player.PlayerData;
import funkin.graphics.FunkinCamera;
import funkin.graphics.FunkinSprite;
import funkin.modding.IScriptedClass.IBPMSyncedScriptedClass;
import funkin.modding.IScriptedClass.ICharacterSelectScriptedClass;
import funkin.modding.events.ScriptEvent;
import funkin.ui.charSelect.CharacterSelectState;
import funkin.util.assets.FlxAnimationUtil;
import funkin.vis.dsp.SpectralAnalyzer;

enum abstract CharacterAnimation(String) to String
{
  public var IDLE = 'idle';
  public var SELECT = 'select';
  public var DESELECT = 'deselect';
  public var DESELECT_HOLD = 'deselect-hold';
  public var UNLOCK = 'unlock';
  public var LOCKED = 'locked';
  public var SLIDEIN = 'slideIn';
  public var SLIDEIN_POINT = 'slideInPoint';
  public var SLIDEOUT = 'slideOut';
}

/**
 * This class is the actual character sprite in the Character Select screen.
 * Animations and textures are loaded here.
 */
@:nullSafety
class CharSelectCharacter extends FunkinSprite implements IBPMSyncedScriptedClass implements ICharacterSelectScriptedClass
{
  /**
   * The player ID of this character.
   */
  public var playerId:String = 'unknown';

  /**
   * The character type of this character.
   */
  public var characterType:CharacterSelectType = CharacterSelectType.PLAYER;

  /**
   * The current path of the character.
   */
  public var currentPath:String = '';

  /**
   * The data for this character.
   */
  var playerData:Null<PlayerCharSelectCharacterData>;

  /**
   * A map of animation offsets for this character.
   * TODO: Move animation offsets to `FunkinSprite`
   */
  var animationOffsetsList:Map<String, Array<Float>> = [];

  /**
   * The global offsets for the character.
   */
  var globalOffsets:Array<Float> = [0, 0];

  /**
   * The current animation offset for the character.
   * TODO: Move animation offsets to `FunkinSprite`
   */
  var currentAnimationOffset:Array<Float> = [0, 0];

  /**
   * Alias for `currentPath`.
   * Only here for backwards compatibility with mods.
   */
  @:deprecated('Use `this.currentPath` instead.')
  var currentGFPath(get, never):String;

  function get_currentGFPath():String
  {
    return currentPath;
  }

  public function new(playerId:String, x:Float, y:Float, characterType:CharacterSelectType, data:Null<PlayerCharSelectCharacterData>, visualizer:Bool = false)
  {
    super(x, y);

    this.playerId = playerId;
    this.characterType = characterType;

    this.playerData = data;

    this.enableVisualizer = visualizer;
    this.globalOffsets = data?.offsets ?? [0, 0];

    loadGraphics();
    loadAnimations();

    playAnimation(IDLE, true);

    animation.onFinish.add(onAnimationFinish);
  }

  /**
   * Plays an animation on this character.
   * @param name The name of the animation to play.
   * @param force Whether to force the animation to play if it's already playing.
   * @param reversed Whether to play the animation in reverse.
   * @param frame The frame to start the animation on.
   */
  public function playAnimation(name:String, force:Bool = false, reversed:Bool = false, frame:Int = 0):Void
  {
    if (currentPath.isBlank()) return;

    // We don't want anything to interrupt the slideOut animation outside of force
    if (getCurrentAnimation() == SLIDEOUT && !force) return;

    this.animation.play(name, force, reversed, frame);

    // Apply the offsets if possible.
    if (animationOffsetsList.get(name) != null && animationOffsetsList.get(name)?.length == 2)
    {
      var offsets:Array<Float> = animationOffsetsList.get(name) ?? [0, 0];
      currentAnimationOffset = offsets;
    }
    else
    {
      currentAnimationOffset = [0, 0];
    }
  }

  /**
   * Get the configuration for the texture atlas.
   *
   * @return The configuration for the texture atlas.
   */
  public function getAtlasSettings():funkin.graphics.FunkinSprite.AtlasSpriteSettings
  {
    return {
      swfMode: playerData?.atlasSettings?.swfMode ?? false,
      cacheOnLoad: playerData?.atlasSettings?.cacheOnLoad ?? false,
      filterQuality: cast playerData?.atlasSettings?.filterQuality ?? animate.FlxAnimateFrames.FilterQuality.MEDIUM,
      applyStageMatrix: playerData?.atlasSettings?.applyStageMatrix ?? true,
      useRenderTexture: playerData?.atlasSettings?.useRenderTexture ?? false
    }
  }

  function loadGraphics():Void
  {
    var firstAssetPath:Null<String> = playerData?.assetPath ?? null;

    if (firstAssetPath == null)
    {
      FlxG.log.warn('Could not load character "${playerId}" because no asset path was provided.');
      return;
    }

    var allAssetPaths:Array<String> = [firstAssetPath];

    trace('Loading character "${playerId}" with asset path "${firstAssetPath}"');

    for (animation in (playerData?.animations ?? []))
    {
      if (animation.assetPath != null && !allAssetPaths.contains(animation.assetPath))
      {
        allAssetPaths.push(animation.assetPath);
      }
    }

    switch (playerData?.renderType ?? 'animateatlas')
    {
      case 'animateatlas':
        this.loadTextureAtlas(allAssetPaths[0], getAtlasSettings());

      case 'sparrow':
        this.loadSparrow(allAssetPaths[0]);

      case 'packer':
        this.loadPacker(allAssetPaths[0]);

      case 'multisparrow':
        // For the multisparrow render type, we create a new frame collection instance and add all the frames from the asset path array.
        // This makes the base asset path's frame collection not receive any unnecessary frames from the other frame collections.
        @:nullSafety(Off)
        var framesCollection:FlxFramesCollection = new FlxFramesCollection(null, ATLAS, null);

        for (assetPath in allAssetPaths)
        {
          var assetFrames:FlxFramesCollection = Paths.getSparrowAtlas(assetPath);
          for (frame in assetFrames.frames) framesCollection.pushFrame(frame.copyTo());
        }

        this.frames = framesCollection;
    }

    this.currentPath = allAssetPaths[0];
  }

  function loadAnimations(?animations:Array<AnimationData>):Void
  {
    var animationData:Array<AnimationData> = animations ?? (playerData?.animations ?? PlayerCharSelectData.getDefaultAnimations(characterType));

    if (animationData == null || (animationData?.length ?? 0) == 0) return;

    if (this.isAnimate)
    {
      FlxAnimationUtil.addTextureAtlasAnimations(this, animationData);
    }
    else
    {
      FlxAnimationUtil.addAtlasAnimations(this, animationData);
    }

    for (animation in animationData)
    {
      animationOffsetsList.set(animation.name, animation.offsets ?? [0, 0]);
    }
  }

  override function getScreenPosition(?result:FlxPoint, ?camera:FlxCamera):FlxPoint
  {
    var output:FlxPoint = super.getScreenPosition(result, camera);
    output.x -= (currentAnimationOffset[0] - globalOffsets[0]);
    output.y -= (currentAnimationOffset[1] - globalOffsets[1]);

    // Small offset for mobile!
    output.x += CharacterSelectState.CUTOUT_SIZE;

    return output;
  }

  override function checkRenderTexture():Bool
  {
    // BF and Pico have an overlay blend on their deselect animation
    // We enable render texture here on devices that don't support KHR_blend_equation_advanced to save on performance
    if (!FunkinCamera.hasKhronosExtension)
    {
      if (getCurrentAnimation().startsWith('deselect'))
      {
        return true;
      }
    }

    return super.checkRenderTexture();
  }

  function onAnimationFinish(animationName:String):Void
  {
    if (hasAnimation(animationName + Constants.ANIMATION_HOLD_SUFFIX))
    {
      playAnimation(animationName + Constants.ANIMATION_HOLD_SUFFIX, true);
    }

    switch (animationName)
    {
      case SLIDEIN:
        if (hasAnimation(SLIDEIN_POINT))
        {
          playAnimation(SLIDEIN_POINT, true);
        }
        else
        {
          playAnimation(IDLE, true);
        }
      case SLIDEIN_POINT, LOCKED:
        playAnimation(IDLE, true);
      case UNLOCK:
        if (characterType == CharacterSelectType.LOCKED_PLAYER)
        {
          this.kill();
        }
        else
        {
          playAnimation(IDLE, true);
        }
      case SLIDEOUT:
        this.kill();
    }
  }

  public function onStepHit(event:SongTimeScriptEvent):Void
  {
  }

  public function onBeatHit(event:SongTimeScriptEvent):Void
  {
    if (getCurrentAnimation() == IDLE && (event.beat % (playerData?.danceEvery ?? 1.0) == 0) && isAnimationFinished())
    {
      playAnimation(IDLE, true);
    }
  }

  public function onScriptEvent(event:ScriptEvent):Void
  {
  }

  public function onCreate(event:ScriptEvent):Void
  {
    if (enableVisualizer && !initializedVisualizer && FlxG.sound.music != null)
    {
      @:privateAccess
      analyzer = new SpectralAnalyzer(FlxG.sound.music._channel.__audioSource, 7, 0.1);
      #if sys
      // On native it uses FFT stuff that isn't as optimized as the direct browser stuff we use on HTML5
      // So we want to manually change it!
      @:privateAccess
      // I don't know WHAT null-safety is complaining about here
      // - Abnormal
      @:nullSafety(Off)
      analyzer.fftN = 512;
      #end

      initializedVisualizer = true;
    }
  }

  public function onDestroy(event:ScriptEvent):Void
  {
  }

  public function onUpdate(event:UpdateScriptEvent):Void
  {
  }

  public function onCustom(event:CustomScriptEvent):Void
  {
  }

  public function onCharacterSelect(event:CharacterSelectScriptEvent):Void
  {
  }

  public function onCharacterDeselect(event:CharacterSelectScriptEvent):Void
  {
  }

  public function onCharacterConfirm(event:CharacterSelectScriptEvent):Void
  {
  }

  /**
   * DEPRECATED VISUALIZER CODE: WILL BE REMOVED IN A FUTURE UPDATE
   * ONLY HERE FOR BACKWARDS COMPATIBILITY
   */
  var analyzer:Null<SpectralAnalyzer>;

  var analyzerLevelsCache:Array<Bar> = new Array<Bar>();
  var initializedVisualizer:Bool = false;
  var enableVisualizer:Bool = false;

  override public function draw():Void
  {
    // Skip drawing if the asset path is blank
    // Prevents the HaxeFlixel logo from showing up at the top left
    if (currentPath.isBlank()) return;

    if (analyzer != null) drawFFT();

    super.draw();
  }

  function drawFFT():Void
  {
    if (analyzer != null)
    {
      analyzerLevelsCache = analyzer.getLevels(analyzerLevelsCache);
      var frame:Null<animate.internal.Frame> = this.timeline.getLayer('VIZ_bars')?.getFrameAtIndex(animation.curAnim.curFrame) ?? null;
      var elements:Array<animate.internal.elements.Element> = frame?.elements ?? [];
      var len:Int = cast Math.min(elements.length, 7);

      for (i in 0...len)
      {
        var animFrame:Int = (FlxG.sound.volume == 0 || FlxG.sound.muted) ? 0 : Math.round(analyzerLevelsCache[i].value * 12);

        animFrame = Math.floor(Math.min(12, animFrame));
        animFrame = Math.floor(Math.max(0, animFrame));

        animFrame = Std.int(Math.abs(animFrame - 12));

        var convertedSymbol = elements[i].toSymbolInstance();
        convertedSymbol.firstFrame = animFrame;

        elements[i] = convertedSymbol;
      }
    }
  }
}

enum CharacterSelectType
{
  PLAYER;
  GF;
  LOCKED_PLAYER;
}
