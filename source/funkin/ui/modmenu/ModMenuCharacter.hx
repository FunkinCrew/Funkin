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
import polymod.PolymodAssets;

using StringTools;

enum abstract CharacterAnimation(String) to String
{
  public var IDLE = 'idle';
  public var ELECTROCUTED = 'electrocuted';
  public var CRISPY = 'crispy';
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
   * Layer name for the wire on Pinhead.
   */
  static final PINHEAD_WIRE_LAYER_NAME:String = 'WIRE';

  /**
   * The character ID for this character.
   */
  public var currentCharacterId:String = '';

  /**
   * The previous character ID for this character.
   */
  public var previousCharacterId:String = '';

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
   * The list of modded assets for this character.
   */
  public var jsons:Array<String> = [];

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
        replaceColorShader = new FlxRuntimeShader(Assets.getText(Paths.frag('ui/shaders/replace-color')));
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

    if (characterId == '') characterId = 'pinhead';
    applyShader();

    this.currentCharacterId = characterId;
    this.isGF = gf;

    loadCharacterData();
    loadGraphics();
    loadAnimations();

    playAnimation(IDLE, true);
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

    if (name == ELECTROCUTED)
    {
      setLightningPinhead();
    }
  }

  /**
   * Switches out the character's graphics.
   * @param characterId The new character ID to use.
   * @param modId The new mod ID to use.
   * @param modIds The mod IDs to check for the character.
   *
   * @return Whether or not the new character is Pinhead...???
   */
  public function switchCharacter(?characterId:String, modIds:Array<String>):Bool
  {
    if (!isGF) shortestIndex = 0;
    if (characterId == null) characterId = currentCharacterId;
    if (characterId == currentCharacterId && modIds.contains(currentModId)) return true;

    var isPinhead:Bool = false;
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
        if (i > shortestIndex)
        {
          if (!isGF)
          {
            shortestIndex = i;
          }
          else
          {
            modId = '';
            break;
          }
        }
        modId = mod;
        break;
      }
      i++;
    }

    trace(' MOD MENU '.bold().bg_orange() + ' Switching character to $characterId with mod $modId. Mods checked: $modIds');

    if (modId == '' && modIds.length > 1) // No modded assets found, but multiple mods are loaded, so show pinhead
    {
      characterId = 'pinhead';
      modId = 'basegame';
      isPinhead = true;
    }
    else if (modId == '' && modIds.length == 1) // No mods but base game, so show BF/GF
    {
      characterId = StringTools.replace(characterId, 'mod-', '');
    }
    else
    {
      @:privateAccess
      if (!isGF) jsons = PolymodAssets.listInMod(modId, TEXT);
    }

    previousCharacterId = currentCharacterId;
    previousModId = currentModId;

    currentCharacterId = characterId;
    currentModId = modId;

    loadCharacterData();
    loadGraphics();
    loadAnimations();

    applyShader();

    if (isPinhead)
    {
      this.library.timeline.getLayer(PINHEAD_WIRE_LAYER_NAME).visible = isGF;
    }

    return !isPinhead;
  }

  /**
   * Get the configuration for the texture atlas.
   * @return The configuration for the texture atlas.
   */
  public function getAtlasSettings():AtlasSpriteSettings
  {
    // Pinhead needs to be unique in the cache because of layer editing
    var isUnique:Bool = currentCharacterId == 'pinhead';

    return {
      swfMode: data?.atlasSettings?.swfMode ?? false,
      cacheOnLoad: data?.atlasSettings?.cacheOnLoad ?? false,
      filterQuality: cast data?.atlasSettings?.filterQuality ?? animate.FlxAnimateFrames.FilterQuality.MEDIUM,
      applyStageMatrix: data?.atlasSettings?.applyStageMatrix ?? false,
      useRenderTexture: data?.atlasSettings?.useRenderTexture ?? false,
      uniqueInCache: isUnique
    }
  }

  function hasModdedAssets(modId:String):Bool
  {
    var assetPath:String = Paths.json('ui/mods/characters/$currentCharacterId/Animation');
    @:privateAccess
    return PolymodAssets.existsInMod(assetPath, modId);
  }

  function loadGraphics():Void
  {
    var modId:String = currentModId;
    if (modId == 'basegame') modId = '';

    previousAssetPath = currentAssetPath;

    var assetPath:Null<String> = 'ui/mods/characters/$currentCharacterId';
    if (assetPath == previousAssetPath)
    {
      // No need to load any new assets.
      return;
    }

    currentAssetPath = assetPath;

    trace(' MOD MENU '.bold().bg_orange() + ' Loading graphics for $currentCharacterId with mod $modId. Asset path: $assetPath');

    switch (data?.renderType ?? 'animateatlas')
    {
      case 'animateatlas':
        this.loadTextureAtlas(assetPath, getAtlasSettings(), modId, jsons);

      // BF and GF by default use animate atlases
      // We can ignore the mod IDs for the sparrow and packer render types, since
      // only animate atlas exports exist in base game
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

    var assetPath:String = Paths.json('ui/mods/characters/$currentCharacterId');
    var modExists:Bool = PolymodAssets.existsInMod(assetPath, modId);
    var tryBase = !modExists;

    if ((tryBase && !Assets.exists(assetPath)) || (!tryBase && !modExists))
    {
      trace(' MOD MENU '.bold().bg_orange() + ' No character data found for $currentCharacterId in mod $modId! (asset path: $assetPath)');
      return;
    }

    var jsonString:String = '';
    if (tryBase) jsonString = Assets.getText(assetPath);
    else
      jsonString = PolymodAssets.getTextFromMod(assetPath, modId);

    var parser:JsonParser<ModMenuCharacterData> = new JsonParser<ModMenuCharacterData>({
      ignoreUnknownVariables: false
    });
    parser.fromJson(jsonString, assetPath);

    if (parser.errors.length > 0)
    {
      trace(' MOD MENU '.bold().bg_orange() + ' Failed to parse character data! (asset path: $assetPath)');
      for (error in parser.errors) funkin.data.DataError.printError(error);
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

    // Small offset for mobile!
    output.x += FullScreenScaleMode.gameCutoutSize.x / 2;

    return output;
  }
}
