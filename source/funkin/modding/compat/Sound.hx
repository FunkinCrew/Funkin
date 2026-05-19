package funkin.modding.compat;

class Sound
{
  public static function cleanupSoundPath(path:String):String
  {
    return Paths.stripLibrary(path);
  }
}
