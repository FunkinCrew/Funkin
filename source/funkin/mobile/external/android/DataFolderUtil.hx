package funkin.mobile.external.android;

/**
 * A Utility class to manage the Application's Data folder on Android.
 */
@:unreflective
class DataFolderUtil
{
  #if android
  /**
   * Opens the data folder on an Android device using JNI.
   */
  public static function openDataFolder():Void
  {
    final openDataFolderJNI:Null<Dynamic> = JNIUtil.createStaticMethod('funkin/util/DataFolderUtil', 'openDataFolder', '(I)V');

    if (openDataFolderJNI != null)
    {
      openDataFolderJNI(CallbackUtil.DATA_FOLDER_CLOSED);
    }
  }
  #end
}
