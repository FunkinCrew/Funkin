package funkin.ui.modmenu;

import flixel.FlxCamera;
import flixel.math.FlxPoint;
import funkin.data.animation.AnimationData;
import funkin.data.modmenu.ModMenuCharacterData;
import funkin.graphics.FunkinSprite;
import funkin.ui.FullScreenScaleMode;
import funkin.util.assets.FlxAnimationUtil;
import json2object.JsonParser;
import polymod.Polymod;
import polymod.PolymodAssets;
import flixel.addons.display.FlxRuntimeShader;

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
   * The character ID for this character.
   */
  public var currentCharacterId:String = '';

  /**
   * The mod ID of the mod that owns this character.
   */
  public var currentModId:String = '';

  /**
   * Whether or not this character is on the left side.
   */
  public var isGF:Bool = false;

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
   * The local offsets for the character.
   */
  var localOffsets:Array<Float> = [0, 0];

  /**
   * The current animation offset for the character.
   * TODO: Move animation offsets to `FunkinSprite`
   */
  var currentAnimationOffset:Array<Float> = [0, 0];

  var replaceColorShader:FlxRuntimeShader = null;

  function getRandomColor():Array<Float>
  {
    var r:Float = Math.random();
    var g:Float = Math.random();
    var b:Float = Math.random();
    return [r, g, b];
  }

  function applyShader():Void
  {
    if (currentCharacterId == 'pinhead')
    {
      if (replaceColorShader == null)
      {
        replaceColorShader = new FlxRuntimeShader(Assets.getText(Paths.frag("ui/shaders/replace-color")));
        replaceColorShader.setFloatArray("uTargetColor", [0, 1, 0.04]);
        replaceColorShader.setFloatArray("uReplaceColor", getRandomColor());
        replaceColorShader.setFloat("uThreshold", 0.12);
      }
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
  public function playAnimation(name:String, force:Bool = false, reversed:Bool = false, frame:Int = 0):Void
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
  }

  /**
   * Switches out the character's graphics.
   * @param characterId The new character ID to use.
   * @param modId The new mod ID to use.
   */
  public function switchCharacter(?characterId:String, modIds:Array<String>):Bool
  {
    if (characterId == null) characterId = currentCharacterId;
    if (characterId == currentCharacterId && modIds.contains(currentModId))
    {
      applyShader();
      return true;
    }

    var isPinhead:Bool = false;
    var modId:String = '';

    currentCharacterId = characterId;

    for (mod in modIds)
    {
      if (mod == ModMenuState.BASE_GAME_MOD_ID) continue;
      if (hasModdedAssets(mod))
      {
        modId = mod;
        break;
      }
    }

    trace(' MOD MENU '.bold().bg_orange() + ' Switching character to $characterId with mod $modId. Mods checked: $modIds');
    if (modId == '' && modIds.length > 1)
    {
      characterId = 'pinhead';
      isPinhead = true;
    }
    else if (modId == '' && modIds.length == 1)
    {
      characterId = StringTools.replace(characterId, 'mod-', '');
      isPinhead = true;
    }

    currentCharacterId = characterId;
    currentModId = modId;

    loadCharacterData();
    loadGraphics();
    loadAnimations();

    applyShader();
    return !isPinhead;
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
    var assetPath:String = Paths.json('ui/mods/characters/$currentCharacterId/Animation');
    @:privateAccess
    return Polymod.assetLibrary.checkDirectly(assetPath, modId);
  }

  function loadGraphics():Void
  {
    var assetPath:Null<String> = 'ui/mods/characters/$currentCharacterId';
    trace(' MOD MENU '.bold().bg_orange() + ' Loading graphics for $currentCharacterId with mod $currentModId. Asset path: $assetPath');
    switch (data?.renderType ?? 'animateatlas')
    {
      case 'animateatlas':
        this.loadTextureAtlas(assetPath, getAtlasSettings(), currentModId);

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

    this.globalOffsets = data?.offsets ?? [isGF ? 680 : 846, 120];
    this.localOffsets = data?.localOffsets ?? [0, 0];
    trace(' MOD MENU '.bold().bg_orange() + ' Character offsets: ' + globalOffsets + ', ' + localOffsets);
    this.scale.set(data?.scale ?? 0.7, data?.scale ?? 0.7);
  }

  function loadCharacterData():Void
  {
    data = null;

    var assetPath:String = Paths.json('ui/mods/characters/$currentCharacterId');
    var modExists:Bool = PolymodAssets.existsInMod(assetPath, currentModId);
    var tryBase = !modExists;

    if ((tryBase && !Assets.exists(assetPath)) || (!tryBase && !modExists))
    {
      trace(' MOD MENU '.bold().bg_orange() + ' No character data found for $currentCharacterId in mod $currentModId! (asset path: $assetPath)');
      return;
    }

    var jsonString:String = '';
    if (tryBase) jsonString = Assets.getText(assetPath);
    else
      jsonString = PolymodAssets.getTextFromMod(assetPath, currentModId);

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
    output.x -= (currentAnimationOffset[0] - (globalOffsets[0] + localOffsets[0]));
    output.y -= (currentAnimationOffset[1] - (globalOffsets[1] + localOffsets[1]));

    // Small offset for mobile!
    output.x += FullScreenScaleMode.gameCutoutSize.x / 2;

    return output;
  }
}
