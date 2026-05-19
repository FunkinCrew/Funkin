package funkin.modding.compat;

class AnimateAtlas
{
  public static function needsBackwardsCompat(path:String):Bool
  {
    return !path.startsWith('assets/gameplay/') && !path.contains('assets/ui/');
  }
}
