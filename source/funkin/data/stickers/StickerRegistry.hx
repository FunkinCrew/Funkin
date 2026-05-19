package funkin.data.stickers;

import funkin.data.stickers.StickerData;
import funkin.ui.transition.stickers.StickerPack;
import funkin.ui.transition.stickers.ScriptedStickerPack;
import funkin.util.tools.ISingleton;
import funkin.data.DefaultRegistryImpl;

@:nullSafety
class StickerRegistry extends BaseRegistry<StickerPack, StickerData, StickerEntryParams> implements ISingleton implements DefaultRegistryImpl
{
  /**
   * The current version string for the sticker pack data format.
   * Handle breaking changes by incrementing this value
   * and adding migration to the `migrateStickerData()` function.
   */
  public static final STICKER_DATA_VERSION:thx.semver.Version = '1.0.0';

  public static final STICKER_DATA_VERSION_RULE:thx.semver.VersionRule = '1.0.x';

  public function new()
  {
    super({
      registryId: 'STICKER',
      dataFilePath: 'ui/loading/stickers/stickerpacks/',
      nestedEntries: false,
      versionRule: STICKER_DATA_VERSION_RULE
    });
  }

  public function fetchDefault():StickerPack
  {
    var stickerPack:Null<StickerPack> = fetchEntry(Constants.DEFAULT_STICKER_PACK);
    if (stickerPack == null) throw 'Default sticker pack was null! This should not happen!';
    return stickerPack;
  }

  /**
   * Parse and validate the JSON data and produce the corresponding data object.
   *
   * NOTE: Must be implemented on the implementation class.
   * @param contents The JSON as a string.
   * @param fileName An optional file name for error reporting.
   * @return The parsed data object.
   */
  public function parseEntryDataRaw(contents:String, ?fileName:String):Null<StickerData>
  {
    var parser = new json2object.JsonParser<StickerData>({ignoreUnknownVariables: false});
    parser.fromJson(contents, fileName);

    if (parser.errors.length > 0)
    {
      printErrors(parser.errors, fileName);
      return null;
    }
    return parser.value;
  }

  override function createScriptedEntry(clsName:String):StickerPack
  {
    return ScriptedStickerPack.scriptInit(clsName, 'unknown');
  }

  function getScriptedClassNames():Array<String>
  {
    return ScriptedStickerPack.listScriptClasses();
  }
}

typedef StickerEntryParams =
{
}
