package funkin.ui.modmenu;

import flixel.FlxCamera;
import flixel.addons.display.FlxRuntimeShader;
import flixel.math.FlxPoint;
import flixel.util.FlxColor;
import funkin.data.animation.AnimationData;
import funkin.data.modmenu.ModMenuCharacterData;
import funkin.graphics.FunkinSprite;
import funkin.ui.FullScreenScaleMode;
import funkin.util.assets.FlxAnimationUtil;
import json2object.JsonParser;
import haxe.io.Path;
import polymod.Polymod;

using StringTools;

enum abstract CharacterAnimation(String) to String
{
  public var IDLE = 'idle';
  public var ELECTROCUTED = 'electrocuted';
  public var CRISPY = 'crispy';
  public var CRISPY_LOOP = 'crispy-loop';
}

/**
 * A character sprite in the mod menu.
 * Can swap out its graphics with a mod's own texture atlas.
 *
 * Mostly copied code from `CharSelectCharacter` :) - Abnormal
 */
class ModMenuCharacter extends FunkinSprite
{
  /**
   * The initial position of the character.
   */
  public var initialPosition:FlxPoint = FlxPoint.get();

  /**
   * The character ID for this character.
   */
  public var currentCharacterId:String = '';

  /**
   * The mod ID of the mod that owns this character.
   */
  public var currentModId:String = '';

  /**
   * The previous mod ID for this character.
   */
  public var previousModId:String = '';

  /**
   * The asset path for the current character.
   */
  public var currentAssetPath:String = '';

  /**
   * The asset path for the previous character.
   */
  public var previousAssetPath:String = '';

  /**
   * Whether or not this character is on the left side.
   */
  public var isGF:Bool = false;

  /**
   * Whether or not this character is Pinhead.
   */
  public var isPinhead:Bool = false;

  /**
   * Whether the character has custom wire animations.
   */
  public var hasCustomWires:Bool = false;

  /**
   * The mod menu has 2 variants of the foreground wires:
   * 1. The regular one, used for BF and GF.
   * 2. The small one, used for Pinhead.
   *
   * If `true`, the small wire will be used.
   */
  public var useSmallWire:Bool = false;

  /**
   * The offsets for the character's smoke trail.
   * Used during the crispy animation.
   */
  public var smokeOffsets:Array<Float> = [];

  /**
   * The scale of the character's smoke trail.
   * Used during the crispy animation.
   */
  public var smokeScale:Array<Float> = [];

  /**
   * The starting frame of the character's idle animation.
   * Used when the mod menu is first opened.
   */
  public var startingIdleFrame:Int = 0;

  /**
   * The data for this character.
   */
  var data:Null<ModMenuCharacterData> = null;

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
   * Used for iterating through multiple modded assets.
   */
  var shortestIndex:Int = 0;

  /**
   * The shader used to replace the Pinhead colors.
   */
  var replaceColorShader:FlxRuntimeShader = null;

  /**
   * The current color used for Pinhead.
   */
  var pinheadColor:Array<Float> = [];

  /**
   * Whether or not the starting idle frame has been used.
   */
  var playedStartingFrame:Bool = false;

  /**
   * @return Gets a random color for Pinhead.
   */
  public function getRandomColor():Array<Float>
  {
    var hue:Float = Math.random() * 360;
    var sat:Float = (75 + Math.random() * 5) / 240;
    var lum:Float = (80 + Math.random() * 79) / 240;
    var color:FlxColor = FlxColor.fromHSL(hue, sat, lum);
    return [color.redFloat, color.greenFloat, color.blueFloat];
  }

  /**
   * Sets the color for Pinhead.
   * @param color The color to set as an array of RGB values.
   */
  public function setPinheadColor(color:Array<Float>):Void
  {
    pinheadColor = color;
    if (replaceColorShader != null)
    {
      replaceColorShader.setFloatArray('uReplaceColor', pinheadColor);
      trace(' MOD MENU '.bold().bg_orange() + ' Setting pinhead color to $pinheadColor');
    }
  }

  /**
   * Pastel-ify the Pinhead colors for the electrocuted animation.
   */
  public function setLightningPinhead():Void
  {
    pinheadColor[0] = Math.min(pinheadColor[0] * 1.8, 1);
    pinheadColor[1] = Math.min(pinheadColor[1] * 1.8, 1);
    pinheadColor[2] = Math.min(pinheadColor[2] * 1.8, 1);
  }

  /**
   * Applies the color shader for Pinhead.
   */
  public function applyShader():Void
  {
    if (currentCharacterId == 'pinhead')
    {
      if (replaceColorShader == null)
      {
        replaceColorShader = new FlxRuntimeShader(Assets.getText(Paths.frag('replace-color')));
        replaceColorShader.setFloatArray('uTargetColor', [0, 1, 0.04]);
        replaceColorShader.setFloat('uThreshold', 0.12);
      }

      setPinheadColor(getRandomColor());
      shader = replaceColorShader;
    }
    else
    {
      shader = null;
      replaceColorShader = null;
    }
  }

  public function new(x:Float = 0, y:Float = 0, characterId:String = '', gf:Bool = false)
  {
    super(x, y);

    this.initialPosition.set(x, y);

    if (characterId == '') characterId = 'pinhead';
    applyShader();

    this.currentCharacterId = characterId;
    this.isGF = gf;

    loadCharacterData();
    loadGraphics();
    loadAnimations();

    playAnimation(IDLE, true);

    animation.onFinish.add((name:String) ->
    {
      if (name == CRISPY && hasAnimation(CRISPY_LOOP))
      {
        playAnimation(CRISPY_LOOP, true);
      }
    });
  }

  /**
   * Return the array of default animations for this character.
   * @return The array of default animations.
   */
  public static function getDefaultAnimations():Array<AnimationData>
  {
    return [
      {
        name: 'idle',
        prefix: 'idle'
      },
      {
        name: 'electrocuted',
        prefix: 'electrocuted',
        looped: true
      },
      {
        name: 'crispy',
        prefix: 'crispy'
      },
      {
        name: 'crispy-loop',
        prefix: 'crispy loop',
        looped: true
      }
    ];
  }

  /**
   * Plays an animation on this character.
   * @param name The name of the animation to play.
   * @param force Whether to force the animation to play if it's already playing.
   * @param reversed Whether to play the animation in reverse.
   * @param frame The frame to start the animation on.
   */
  public function playAnimation(name:CharacterAnimation, force:Bool = false, reversed:Bool = false, frame:Int = 0):Void
  {
    if ((getCurrentAnimation() == CRISPY && name != CRISPY_LOOP) && !force) return;

    if (name == IDLE && startingIdleFrame > 0 && !playedStartingFrame)
    {
      frame = startingIdleFrame;
      playedStartingFrame = true;
    }

    if (name == ELECTROCUTED)
    {
      setLightningPinhead();

      var targetAnimation = animation.getByName(name);
      frame = FlxG.random.int(0, Std.int(Math.max(0, (targetAnimation?.numFrames ?? 1) - 1)));

      if (ModMenuState.instance?.dropShadowCharacters != null)
      {
        ModMenuState.instance.dropShadowCharacters.renderer.blacklistSprite(this);
      }
    }
    else
    {
      if (ModMenuState.instance?.dropShadowCharacters != null)
      {
        ModMenuState.instance.dropShadowCharacters.renderer.whitelistSprite(this);
      }
    }

    this.animation.play(name, force, reversed, frame);

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
   * Prepares the character for switching.
   * @param characterId The new character ID to use.
   * @param modId The new mod ID to use.
   * @param modIds The mod IDs to check for the character.
   */
  public function prepareToSwitch(?characterId:String, modIds:Array<String>):Void
  {
    if (!isGF) shortestIndex = 0;

    if (characterId == null) characterId = currentCharacterId;

    isPinhead = false;

    var modId:String = '';

    currentCharacterId = characterId;

    var i:Int = 0;
    for (mod in modIds)
    {
      if (mod == ModMenuState.BASE_GAME_MOD_ID)
      {
        i++;
        continue;
      }

      if (hasModdedAssets(mod))
      {
        shortestIndex = i;

        modId = mod;
        break;
      }

      i++;
    }

    trace(' MOD MENU '.bold().bg_orange() + ' Preparing to switch to character to $characterId with mod $modId. Mods checked: $modIds');

    if (modId == '' && modIds.length > 1)
    {
      characterId = 'pinhead';
      modId = 'basegame';
      isPinhead = true;
    }
    else if (modId == '' && modIds.length == 1)
    {
      characterId = StringTools.replace(characterId, 'mod-', '');
    }

    previousModId = currentModId;

    currentCharacterId = characterId;
    currentModId = modId;
  }

  /**
   * Switches out the character.
   * Call this AFTER `prepareToSwitch()`
   */
  public function switchCharacter():Void
  {
    trace(' MOD MENU '.bold().bg_orange() + ' Switched to character $currentCharacterId with mod $currentModId.');

    loadCharacterData();
    loadGraphics();
    loadAnimations();

    hasCustomWires = data?.hasCustomWires ?? false;
    useSmallWire = data?.useSmallWire ?? false;

    applyShader();

    if (this.applyStageMatrix)
    {
      this.setPosition(0, 0);
    }
    else
    {
      this.setPosition(initialPosition.x, initialPosition.y);
    }

    smokeOffsets = data?.smokeOffsets ?? [0, 0];
    smokeScale = data?.smokeScale ?? [0.5, 0.5];
    startingIdleFrame = isGF ? data?.startingFrame?.gf ?? 0 : data?.startingFrame?.bf ?? 0;
  }

  /**
   * Get the configuration for the texture atlas.
   * @return The configuration for the texture atlas.
   */
  public function getAtlasSettings():AtlasSpriteSettings
  {
    return {
      swfMode: data?.atlasSettings?.swfMode ?? false,
      cacheOnLoad: data?.atlasSettings?.cacheOnLoad ?? false,
      filterQuality: cast data?.atlasSettings?.filterQuality ?? animate.FlxAnimateFrames.FilterQuality.MEDIUM,
      applyStageMatrix: data?.atlasSettings?.applyStageMatrix ?? false,
      useRenderTexture: data?.atlasSettings?.useRenderTexture ?? false
    }
  }

  function hasModdedAssets(modId:String):Bool
  {
    var assetPath:String = Paths.file('images/ui/mods/characters/$currentCharacterId/Animation.json');
    return modAssetExists(assetPath, modId);
  }

  static function resolveModAssetPath(assetPath:String, modId:String):Null<String>
  {
    if (modId == null || modId.length == 0) return null;

    var fileSystem = Polymod.getFileSystem();
    if (fileSystem == null) return null;

    var metadata = fileSystem.getMetadataById(modId);
    if (metadata == null) return null;

    var relativePath = assetPath;
    var assetsIndex = relativePath.indexOf('assets/');
    if (assetsIndex >= 0) relativePath = relativePath.substring(assetsIndex + 'assets/'.length);
    return Path.join([metadata.modPath, relativePath]);
  }

  static function modAssetExists(assetPath:String, modId:String):Bool
  {
    var resolvedPath = resolveModAssetPath(assetPath, modId);
    return resolvedPath != null && Polymod.getFileSystem()?.exists(resolvedPath) == true;
  }

  static function getModAssetText(assetPath:String, modId:String):Null<String>
  {
    var resolvedPath = resolveModAssetPath(assetPath, modId);
    return resolvedPath == null ? null : Polymod.getFileSystem()?.getFileContent(resolvedPath);
  }

  function loadGraphics():Void
  {
    var modId:String = currentModId;
    if (modId == 'basegame') modId = '';

    previousAssetPath = currentAssetPath;

    var assetPath:Null<String> = 'ui/mods/characters/$currentCharacterId';
    if (assetPath == previousAssetPath)
    {
      return;
    }

    currentAssetPath = assetPath;

    trace(' MOD MENU '.bold().bg_orange() + ' Loading graphics for $currentCharacterId with mod $modId. Asset path: $assetPath');

    switch (data?.renderType ?? 'animateatlas')
    {
      case 'animateatlas':
        this.loadTextureAtlas(assetPath, null, getAtlasSettings());

      case 'sparrow':
        this.loadSparrow(assetPath);

      case 'packer':
        this.loadPacker(assetPath);
    }
  }

  function loadAnimations():Void
  {
    var animationData:Array<AnimationData> = data?.animations ?? getDefaultAnimations();
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

    this.globalOffsets = data?.offsets ?? [0, 0];
    this.scale.set(data?.scale ?? 0.7, data?.scale ?? 0.7);

    trace(' MOD MENU '.bold().bg_orange() + ' Character offsets: ' + globalOffsets);
  }

  function loadCharacterData():Void
  {
    data = null;

    var modId:String = currentModId;
    if (modId == 'basegame') modId = '';

    var assetPath:String = Paths.file('images/ui/mods/characters/$currentCharacterId.json');
    var modExists:Bool = modAssetExists(assetPath, modId);
    var tryBase = !modExists;

    if ((tryBase && !Assets.exists(assetPath)) || (!tryBase && !modExists))
    {
      trace(' MOD MENU '.bold().bg_orange() + ' No character data found for $currentCharacterId in mod $modId! (asset path: $assetPath)');
      return;
    }

    var jsonString:String = '';
    if (tryBase)
    {
      jsonString = Assets.getText(assetPath);
    }
    else
    {
      jsonString = getModAssetText(assetPath, modId) ?? '';
    }

    var errors:Array<json2object.Error> = [];
    var parser:JsonParser<ModMenuCharacterData> = new JsonParser<ModMenuCharacterData>(errors, null, json2object.Error.ErrorType.NONE, false);
    parser.fromJson(jsonString, assetPath);

    if (errors.length > 0)
    {
      trace(' MOD MENU '.bold().bg_orange() + ' Failed to parse character data! (asset path: $assetPath)');
      for (error in errors) funkin.data.DataError.printError(error);
    }
    else
    {
      data = parser.value;
    }
  }

  override function getScreenPosition(?result:FlxPoint, ?camera:FlxCamera):FlxPoint
  {
    var output:FlxPoint = super.getScreenPosition(result, camera);

    output.x -= currentAnimationOffset[0] - globalOffsets[0];
    output.y -= currentAnimationOffset[1] - globalOffsets[1];

    return output;
  }
}
