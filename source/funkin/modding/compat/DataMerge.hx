package funkin.modding.compat;

import polymod.Polymod;
import funkin.util.SerializerUtil;

class DataMerge
{
  public static function fetchEntryIdsFromFiles(baseDataFilePath:String, compatDataFilePaths:Array<String>):Array<String>
  {
    // compatDataFilePaths ??= [];
    return [];
  }

  public static function getMergedData(id:String, baseData:Dynamic):Dynamic
  {
    baseData ??= {};

    var baseDataStr:String = SerializerUtil.toJSON(baseData, false);

    return getMergedDataStr(id, baseDataStr);
  }

  public static function getMergedDataStr(id:String, baseDataStr:String = '{}'):String
  {
    // Fingering Polymod's deepest, sexiest parts while machine is running, don't try this at home kids!
    @:privateAccess
    var mergedStr:String = Polymod.assetLibrary.mergeAndAppendText(id, baseDataStr);

    return mergedStr;
  }
}
