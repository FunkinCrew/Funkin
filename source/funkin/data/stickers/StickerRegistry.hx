package funkin.data.stickers;

import funkin.data.stickers.StickerData;
import funkin.ui.transition.stickers.StickerPack;
import funkin.ui.transition.stickers.ScriptedStickerPack;

@:nullSafety
class StickerRegistry extends BaseRegistry<StickerPack, StickerData, StickerEntryParams, 'stickerpacks'>
{
  /**
   * The current version string for the sticker pack data format.
   * Handle breaking changes by incrementing this value
   * and adding migration to the `migrateStickerData()` function.
   */
  public static final STICKER_DATA_VERSION:thx.semver.Version = '1.0.0';

  public static final STICKER_DATA_VERSION_RULE:thx.semver.VersionRule = '1.0.x';

  public static final instance:StickerRegistry = new StickerRegistry();

  public function new()
  {
    super('STICKER', STICKER_DATA_VERSION_RULE);
  }

  public function fetchDefault():StickerPack
  {
    var stickerPack:Null<StickerPack> = fetchEntry(Constants.DEFAULT_STICKER_PACK);
    if (stickerPack == null) throw 'Default sticker pack was null! This should not happen!';
    return stickerPack;
  }
}

typedef StickerEntryParams = {}
