package funkin.play.notes.notesound;

/*
 * Any new hit sound should generally be added here.
 * The string is used to identify the sound in the user's settings, as well as in the game's asset folder.
 * Syntax: `SoundName = "soundFileName"`
 */
abstract NoteSoundType(String) from String to String
{
  public static inline var None:String = ""; // Special case
  public static inline var PingPong:String = "pingPong";
  public static inline var PoolBall:String = "poolBall";
  public static inline var VineBoom:String = "vineBoom";
}
