package funkin.util;

import funkin.play.notes.NoteSprite;
import funkin.Conductor;

/**
 * A structure to hold the hit window values.
 * @param start The start time of the hit window.
 * @param center The center time of the hit window.
 * @param end The end time of the hit window.
 */
typedef HitWindow =
{
  public var start:Float;
  public var center:Float;
  public var end:Float;
}

/**
 * A structure to hold the result of a hit window check for botplay.
 * @param botplayHit True if the note was hit by botplay.
 * @param cont True if the game should continue after the hit.
 */
typedef HitWindowRes =
{
  public var botplayHit:Bool;
  public var cont:Bool;
}

/**
 * GRhythmUtil
 * A utility class for processing hit windows, and calculating the y-position of notes.
 */
class GRhythmUtil
{
  /**
   * Get the current hit window for a note.
   * @param note The note to get the hit window for.
   * @return A HitWindow object containing the start, center, and end times of the hit window.
   */
  public static function getHitWindow(note:NoteSprite):HitWindow
  {
    return {
      start: note.strumTime - Constants.HIT_WINDOW_MS,
      center: note.strumTime,
      end: note.strumTime + Constants.HIT_WINDOW_MS
    };
  }

  /**
   * Process the hit window for a note.
   * @param note The note to process.
   * @param isControlled True if the note is controlled by the player, false otherwise.
   * @return A HitWindowRes object containing the result of the hit window check.
   */
  public static function processWindow(note:NoteSprite, isControlled:Bool = true, ?inUseConductor:Conductor = null):HitWindowRes
  {
    if (inUseConductor == null) inUseConductor = Conductor.instance;

    var window:HitWindow = getHitWindow(note);

    var windowStart:Float = window.start;
    var windowCenter:Float = window.center;
    var windowEnd:Float = window.end;

    if (note.hasMissed || note.hasBeenHit)
    {
      return {botplayHit: false, cont: false };
    }

    // Treat notes as not in window if they are greater or less than the hit window
    if (inUseConductor.songPosition > windowEnd)
    {
      note.tooEarly = false;
      note.hasMissed = true;
      note.mayHit = false;
      if (note.holdNoteSprite != null) note.holdNoteSprite.missedNote = true;
      return {botplayHit: false, cont: true};
    }

    // Check if we're not being controlled (ie, botplay/opponent)
    if (!isControlled && inUseConductor.songPosition >= windowCenter)
      return {botplayHit: true, cont: true };

    if (note.holdNoteSprite != null) note.holdNoteSprite.missedNote = false;

    if (inUseConductor.songPosition >= windowStart)
    {
      note.tooEarly = false;
      note.hasMissed = false;
      note.mayHit = true;
      return {botplayHit: false, cont: true };
    }

    note.tooEarly = true;
    note.mayHit = false;
    note.hasMissed = false;

    return {botplayHit: false, cont: true };
  }
  /**
   * Get the y-position of a note based on its strum time.
   * @param strumTime The strum time of the note.
   * @param scrollSpeed The scroll speed of the strumline.
   * @param downscroll Whether the strumline is in downscroll mode.
   * @param conductorInUse The conductor to use for calculating the y-position.
   * @return The y-position of the note.
   */
  public static function getNoteY(strumTime:Float, scrollSpeed:Float, downscroll:Bool = false, ?conductorInUse:Conductor = null):Float
  {
    if (conductorInUse == null) conductorInUse = Conductor.instance;
    return Constants.PIXELS_PER_MS * (conductorInUse.getTimeWithDelta() - strumTime) * scrollSpeed * (downscroll ? 1 : -1);
  }
}
