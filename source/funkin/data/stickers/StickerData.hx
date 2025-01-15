package funkin.data.stickers;

/**
 * A type definition for a sticker set.
 * It includes things like its name, the artist, and the stickers.
 * @see https://lib.haxe.org/p/json2object/
 */
typedef StickerData =
{
  /**
   * Semantic version of the sticker set data.
   */
  public var version:String;

  /**
   * Readable name of the sticker set.
   */
  public var name:String;

  /**
   * The asset key for this sticker set.
   */
  public var assetPath:String;

  /**
   * The artist of the sticker set.
   */
  public var artist:String;

  /**
   * The stickers in the set.
   */
  public var stickers:Map<String, Array<String>>;

  /**
   * The sticker packs in this set.
   */
  public var stickerPacks:Map<String, Array<String>>;
}
