package funkin.ui.title;

/**
 * After about 2 minutes of inactivity on the title screen,
 * the game will enter the Attract state, as a reference to physical arcade machines.
 *
 * In the current version, this just plays the Kickstarter trailer, but this can be changed to
 * gameplay footage, a generic game trailer, or something more elaborate.
 */
class AttractState extends MusicBeatState
{
  static final ATTRACT_VIDEO_PATH:String = Paths.videos('kickstarterTrailer.mp4');

  public override function create():Void {}

  /**
   * When the attraction state ends (after the video ends or the user presses any button),
   * switch immediately to the title screen.
   */
  function onAttractEnd():Void
  {
    FlxG.switchState(new TitleState());
  }
}
