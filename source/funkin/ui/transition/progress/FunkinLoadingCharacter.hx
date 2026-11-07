package funkin.ui.transition.progress;

import funkin.assets.FunkinAssetCache;
import funkin.data.loading.LoadingCharacterData;
import funkin.graphics.FunkinSprite;

/**
 * The character sprite that appears in the loading screen.
 *
 * TODO: Consolidate this with `ModMenuCharacter`, and `CharSelectCharacter`!
 * They all share similar functionality which can be reduced.
 * - Abnormal
 */
// @:nullSafety
class FunkinLoadingCharacter extends FunkinSprite
{
  /**
   * The default animation this character plays.
   */
  public static final DEFAULT_ANIMATION:String = 'idle';

  /**
   * The default animation prefix this character uses.
   */
  public static final DEFAULT_ANIMATION_PREFIX:String = 'run';

  var data:Null<LoadingCharacterData> = null;
  var offsets:Array<Float> = [0, 0];

  public function new()
  {
    super();
  }

  /**
   * Loads the specified character from a parsed data structure.
   * @param newData The new character data to load.
   * @param graphicPath The path to the character's graphic.
   * @param modId The ID of the mod that this character belongs to.
   */
  public function loadCharacter(newData:LoadingCharacterData, graphicPath:String, modId:String):Void
  {
    data = newData;

    visible = false;
    var onAtlasLoaded = () ->
    {
      if (this.graphic != null) FunkinAssetCache.instance.permaCacheFlxGraphic(graphicPath, this.graphic);
      scale.set(data.scale, data.scale);
      updateHitbox();

      visible = true;

      this.setPosition(FlxG.width - (this.width + data.offsets[0]), FlxG.height - (this.height + data.offsets[1]));
      this.animation.addByPrefix(DEFAULT_ANIMATION, DEFAULT_ANIMATION_PREFIX, 24);
      this.animation.play(DEFAULT_ANIMATION);
    }

    #if html5
    loadAtlasAsync(graphicPath, 'sparrow', null, modId).onComplete((_sprite:FunkinSprite) -> onAtlasLoaded()).onError((error:Dynamic) ->
    {
      trace(' FUNKIN LOADING CHARACTER '.bold().bg_orange() + ' Failed to load $graphicPath from mod $modId: $error');
      loadSparrow('ui/loading/characters/bf/bf', '');
      onAtlasLoaded();
    });
    #else
    try
    {
      loadSparrow(graphicPath, modId);
    }
    catch (error:Dynamic)
    {
      trace(' FUNKIN LOADING CHARACTER '.bold().bg_orange() + ' Failed to load $graphicPath from mod $modId: ${Std.string(error)}');
      loadSparrow('ui/loading/characters/bf/bf', '');
    }

    onAtlasLoaded();
    #end
  }
}
