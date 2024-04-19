package funkin.play;

/**
 * Manages playback of multiple songs in a row.
 *
 * TODO: Add getters/setters for all these properties to validate them.
 */
@:nullSafety
class PlayStatePlaylist
{
  /**
   * Whether the game is currently in Story Mode. If false, we are in Free Play Mode.
   */
  public static var isStoryMode:Bool = false;

  /**
   * The loist of upcoming songs to be played.
   * When the user completes a song in Story Mode, the first entry in this list is played.
   * When this list is empty, move to the Results screen instead.
   */
  public static var playlistSongIds:Array<String> = [];

  /**
   * The cumulative score for all the songs in the playlist.
   */
  public static var campaignScore:Int = 0;

  /**
   * The title of this playlist, for example `Week 4` or `Weekend 1`
   */
  public static var campaignTitle:String = 'UNKNOWN';

  /**
   * The internal ID of the current playlist, for example `week4` or `weekend-1`.
   * @default `null`, used when no playlist is loaded
   */
  public static var campaignId:Null<String> = null;

  public static var campaignDifficulty:String = Constants.DEFAULT_DIFFICULTY;

  /**
   * Resets the playlist to its default state.
   */
  public static function reset():Void
  {
    isStoryMode = false;
    playlistSongIds = [];
    campaignScore = 0;
    campaignTitle = 'UNKNOWN';
    campaignId = null;
    campaignDifficulty = Constants.DEFAULT_DIFFICULTY;
  }
}
