package funkin.modding.compat;

import polymod.Polymod;
import funkin.data.JsonFile;
import funkin.util.SerializerUtil;

/**
 * Represents an old location for a registry's entries.
 * We should check these locations in case there's an outdated mod installed.
 */
typedef RegistryCompatPath =
{
  path:String,
  nestedEntries:Bool
}

/**
 * Utility functions for retrieving registry data, focused on providing compatibility with older versions.
 */
class RegistryData
{
  static final REGISTRY_COMPAT_PATHS:Map<String, Array<RegistryCompatPath>> = [
    'gameplay/dialogue/boxes/' => [
      {path: 'data/dialogue/boxes/', nestedEntries: false}
    ],
    'gameplay/dialogue/conversations/' => [
      {path: 'data/dialogue/conversations/', nestedEntries: false}
    ],
    'gameplay/dialogue/speakers/' => [
      {path: 'data/dialogue/speakers/', nestedEntries: false}
    ],
    'gameplay/playable-characters/' => [
      {path: 'data/players/', nestedEntries: false}
    ],
    'gameplay/characters/' => [
      {path: 'data/characters/', nestedEntries: false}
    ],
    'gameplay/stages/' => [
      {path: 'data/stages/', nestedEntries: false}
    ],
    'gameplay/songs/' => [
      {path: 'data/songs/', nestedEntries: true}
    ],
    'gameplay/notestyles/' => [
      {path: 'data/notestyles/', nestedEntries: false}
    ],
    'ui/freeplay/albums/' => [
      {path: 'data/ui/freeplay/albums/', nestedEntries: false}
    ],
    'ui/freeplay/styles/' => [
      {path: 'data/ui/freeplay/styles/', nestedEntries: false}
    ],
    'ui/loading/stickers/stickerpacks/' => [
      {path: 'data/stickerpacks/', nestedEntries: false}
    ],
    'ui/story-mode/levels/' => [
      {path: 'data/levels/', nestedEntries: false}
    ]
  ];
  static final REGISTRY_ASSET_BLACKLIST:Array<String> = ['Animation', 'spritemap1'];
  static final VALIDATE:Bool = false;

  /**
   * List the entry IDs for a given registry, taking into account old backwards-compatibility paths.
   *
   * @param dataFilePath The main path to check for data at.
   * @param suffix A suffix to the file path for the data files.
   * @param nestedEntries Whether entries are in `dataFilePath/id/id-suffix.json`, or just `dataFilePath/id-suffix.json`.
   * @return The list of available entries.
   */
  public static function listEntryIds(dataFilePath:String, suffix:String = '', nestedEntries:Bool = true):Array<String>
  {
    var result:Array<String> = [];

    var compatDataFilePaths:Array<RegistryCompatPath> = REGISTRY_COMPAT_PATHS.get(dataFilePath) ?? [];

    result.append(funkin.assets.Assets.listDataFilesInPath(dataFilePath, '${suffix == '' ? '' : '-$suffix'}.json', REGISTRY_ASSET_BLACKLIST, nestedEntries));

    for (compatDataFilePath in compatDataFilePaths)
    {
      result.append(funkin.assets.Assets.listDataFilesInPath(compatDataFilePath.path, '${suffix == '' ? '' : '-$suffix'}.json', REGISTRY_ASSET_BLACKLIST, compatDataFilePath.nestedEntries));
    }

    return result;
  }

  /**
   * Load the JSON data for a given registry entry ID.
   *
   * @param id The ID of the entry to load.
   * @param suffix The suffix of the filename to load.
   * @param dataFilePath The main directory where entries are located.
   * @param nestedEntries Whether entries are in `dataFilePath/id/id-suffix.json`, or just `dataFilePath/id-suffix.json`.
   * @return The loaded entry.
   */
  public static function loadEntryData(id:String, suffix:String, dataFilePath:String, nestedEntries:Bool = true):JsonFile
  {
    var compatDataFilePaths:Array<RegistryCompatPath> = REGISTRY_COMPAT_PATHS.get(dataFilePath) ?? [];

    var entryFilePath:funkin.assets.Paths.AssetPath = funkin.assets.Paths.json(nestedEntries ? '$dataFilePath$id/$id$suffix' : '$dataFilePath$id$suffix', VALIDATE);

    if (!funkin.assets.Assets.exists(entryFilePath.toString()))
    {
      // Check each compatDataFilePath to support older versions.
      for (path in compatDataFilePaths)
      {
        entryFilePath = funkin.assets.Paths.json(path.nestedEntries ? '${path.path}${id}/${id}${suffix}' : '${path.path}${id}${suffix}', VALIDATE);
        if (funkin.assets.Assets.exists(entryFilePath.toString())) break;
      }
    }

    if (!funkin.assets.Assets.exists(entryFilePath.toString()))
    {
      // Fallthrough if none of the paths exists.
      entryFilePath = funkin.assets.Paths.json(nestedEntries ? '$dataFilePath$id/$id$suffix' : '$dataFilePath$id$suffix', VALIDATE);
      throw 'Could not find file $entryFilePath';
    }

    var rawJson:String = funkin.assets.Assets.getText(entryFilePath).trim();
    rawJson = SerializerUtil.sanitizeJSON(rawJson);

    // JSON _merge Patches for the main path were applied automatically by Polymod.
    // Apply _merge Patches for compatibility paths.
    for (path in compatDataFilePaths)
    {
      var compatEntryFilePath = funkin.assets.Paths.json(path.nestedEntries ? '${path.path}${id}/${id}${suffix}' : '${path.path}${id}${suffix}', VALIDATE);

      rawJson = mergeJsonDataStr(compatEntryFilePath.toString(), rawJson);
    }

    return {
      fileName: entryFilePath.toString(),
      contents: rawJson
    };
  }

  /**
   * Use the given asset ID to apply _merge patches to the given base data.
   *
   * @param id The asset ID to use for patching (NOT the original ID!).
   * @param baseData The data to apply patches to.
   * @return The patched data.
   */
  public static function mergeJsonData(id:String, baseData:Dynamic):Dynamic
  {
    baseData ??= {};

    var baseDataStr:String = SerializerUtil.toJSON(baseData, false);

    var mergedDataStr:String = mergeJsonDataStr(id, baseDataStr);

    return SerializerUtil.fromJSON(mergedDataStr);
  }

  /**
   * Use the given asset ID to apply _merge patches to the given base data.
   *
   * @param id The asset ID to use for patching (NOT the original ID!).
   * @param baseDataStr The data to apply patches to, as a serialized string.
   * @return The patched data, as a serialized string.
   */
  public static function mergeJsonDataStr(id:String, baseDataStr:String = '{}'):String
  {
    // Fingering Polymod's deepest, sexiest parts while machine is running, don't try this at home kids!
    @:privateAccess
    var mergedStr:String = Polymod.assetLibrary.mergeAndAppendText(id, baseDataStr);

    return mergedStr;
  }
}
