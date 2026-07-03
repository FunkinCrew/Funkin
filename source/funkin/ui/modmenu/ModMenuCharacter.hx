package funkin.ui.modmenu;

import flixel.FlxCamera;
import flixel.math.FlxPoint;
import funkin.data.animation.AnimationData;
import funkin.data.modmenu.ModMenuCharacterData;
import funkin.graphics.FunkinSprite;
import funkin.ui.FullScreenScaleMode;
import funkin.util.assets.FlxAnimationUtil;
import json2object.JsonParser;
import polymod.PolymodAssets;

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
   * The current animation offset for the character.
   * TODO: Move animation offsets to `FunkinSprite`
   */
  var currentAnimationOffset:Array<Float> = [0, 0];

  public function new(x:Float = 0, y:Float = 0, characterId:String = '')
  {
    super(x, y);

    this.currentCharacterId = characterId;

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
  public function switchCharacter(?characterId:String, modId:String):Void
  {
    if (characterId == null) characterId = currentCharacterId;
    if (characterId == currentCharacterId && modId == currentModId) return;

    currentCharacterId = characterId;
    currentModId = modId;

    loadCharacterData();
    loadGraphics();
    loadAnimations();
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
      applyStageMatrix: data?.atlasSettings?.applyStageMatrix ?? true,
      useRenderTexture: data?.atlasSettings?.useRenderTexture ?? false
    }
  }

  function loadGraphics():Void
  {
    var assetPath:Null<String> = 'ui/mods/characters/$currentCharacterId';

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

    this.globalOffsets = data?.offsets ?? [0, 0];
    this.scale.set(data?.scale ?? 1, data?.scale ?? 1);
  }

  function loadCharacterData():Void
  {
    data = null;

    var assetPath:String = Paths.json('ui/mods/characters/$currentCharacterId');
    if (!PolymodAssets.existsInMod(assetPath, currentModId))
    {
      return;
    }

    var jsonString:String = PolymodAssets.getTextFromMod(assetPath, currentModId);
    var parser:JsonParser<ModMenuCharacterData> = new JsonParser<ModMenuCharacterData>({
      ignoreUnknownVariables: false
    });
    parser.fromJson(jsonString, assetPath);

    if (parser.errors.length > 0)
    {
      trace(' MOD MENU '.bold().bg_orange() + ' Failed to parse character data!');
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
    output.x -= (currentAnimationOffset[0] - globalOffsets[0]);
    output.y -= (currentAnimationOffset[1] - globalOffsets[1]);

    // Small offset for mobile!
    output.x += FullScreenScaleMode.gameCutoutSize.x / 2;

    return output;
  }
}
