package funkin.ui.transition.loading;

import flixel.addons.transition.Transition as FlxTransition;
import funkin.ui.transition.Transition.TransitionTarget;
import funkin.ui.transition.Transition.TransitionParams;
import flixel.group.FlxSpriteGroup.FlxTypedSpriteGroup;
import flixel.util.FlxColor;
import funkin.ui.transition.stickers.StickerSprite;
import funkin.ui.transition.stickers.StickerPack;
import funkin.ui.transition.StickerTransition;
import funkin.data.stickers.StickerRegistry;
import funkin.assets.Paths.AssetPath;
import funkin.assets.Assets.AssetType;

using Lambda;
using StringTools;

/**
 * Parameters used to construct the StickerLoadingState.
 */
typedef StickerLoadingStateParams =
{
  /**
   * What sticker pack to use.
   */
  ?stickerPack:String,
  /**
   * If stickers already exist, remove them to transition to the next state.
   * If stickers don't exist, leave null to add them.
   */
  ?oldStickers:Array<StickerSprite>,
}

/**
 * A loading state which displays the stickers from a sticker transition.
 */
@:nullSafety
class StickerLoadingState extends LoadingState
{
  /**
   * The sticker sprites to display.
   */
  public var grpStickers:FlxTypedSpriteGroup<StickerSprite>;

  public final stickerPackId:String;
  var stickerPack:StickerPack;

  /**
   * Retrieve a list of all the asset paths required for this state.
   *
   * @param type The type of asset to query
   * @param stickerPackId The ID for the sticker pack to load assets for.
   * @return An array of asset paths, or empty if no assets of that type are required.
   */
  public static function queryAssets(type:AssetType, stickerPackId:String):Array<AssetPath>
  {
    //TODO: maybe just change classes that call this to call StickerTransition instead 
    return StickerTransition.queryAssets(type, stickerPackId);
  }

  public function new(target:TransitionTarget,
    transParams:TransitionParams,
    stickerParams:StickerLoadingStateParams):Void
  {
    super(FlxColor.GREEN, target, transParams);

    this.grpStickers = new FlxTypedSpriteGroup<StickerSprite>();

    this.stickerPackId = stickerParams.stickerPack ?? Constants.DEFAULT_STICKER_PACK;
    this.stickerPack = StickerRegistry.instance.fetchEntry(this.stickerPackId) ?? StickerRegistry.instance.fetchDefault();

    @:nullSafety(Off)
    {
      transIn = null;
      transOut = null;
    }

    cancelParentUpdate = false;
  }

  override public function create():Void
  {
    super.create();
    add(this.grpStickers);
    // makes the stickers on the most recent camera, which is more often than not... a UI camera!!
    // this.grpStickers.cameras = FlxG.cameras.list;
  }

  /**
   * Create an FlxTransition matching the stickers used by this sticker state.
   * @return The transition to use.
   */
  public function buildTransition():FlxTransition
  {
    return new StickerTransition({
      stickerSpriteGroup: this.grpStickers,
      stickerPack: this.stickerPackId
    });
  }

  override public function update(elapsed:Float):Void
  {
    super.update(elapsed);
  }

  var switchingState:Bool = false;

  override public function close():Void
  {
    if (switchingState) return;
    super.close();
  }

  override public function destroy():Void
  {
    if (switchingState) return;
    // Prevent the sticker group from being destroyed, since it's being reused.
    remove(this.grpStickers);
    super.destroy();
  }
}
