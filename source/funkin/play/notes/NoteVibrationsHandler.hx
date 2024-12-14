package funkin.play.notes;

import funkin.util.HapticUtil;

/**
 * Handles vibrations on note presses.
 */
class NoteVibrationsHandler
{
  /**
   * Left note's status.
   */
  static var leftNoteStatus:NoteStatus = NoteStatus.isReleased;

  /**
   * Down note's status.
   */
  static var downNoteStatus:NoteStatus = NoteStatus.isReleased;

  /**
   * Up note's status.
   */
  static var upNoteStatus:NoteStatus = NoteStatus.isReleased;

  /**
   * Right note's status.
   */
  static var rightNoteStatus:NoteStatus = NoteStatus.isReleased;

  /**
   * An array of each note status.
   * Made for use in other classes.
   */
  public static final noteStatuses:Array<NoteStatus> = [leftNoteStatus, downNoteStatus, upNoteStatus, rightNoteStatus];

  /**
   * Note vibration's default amplitude.
   */
  static final defaultNoteAmplitude:Int = Math.ceil(Constants.MAX_VIBRATION_AMPLITUDE / 2);

  /**
   * An amplitude that is being decreased depending on how much notes are pressed right now.
   */
  static var stackingAmplitude:Int = defaultNoteAmplitude;

  /**
   * Checks if any note status is equal to NoteStatus.isJustPressed.
   * If yes, then vibration is being triggered, amplitude value is stacked depending on how much notes are pressed.
   */
  public static function tryNoteVibration():Void
  {
    for (currentNoteStatus in noteStatuses)
    {
      if (currentNoteStatus != NoteStatus.isJustPressed) continue;

      stackingAmplitude += Math.ceil(Constants.MAX_VIBRATION_AMPLITUDE / 8);

      if (stackingAmplitude > 255) stackingAmplitude = 255;
    }

    trace("amplitude: " + stackingAmplitude);

    if (stackingAmplitude > defaultNoteAmplitude) HapticUtil.vibrate(0, 10, stackingAmplitude);

    reset();
  }

  /**
   * Reset everything.
   */
  public static function reset():Void
  {
    for (currentNoteStatus in noteStatuses)
    {
      currentNoteStatus = NoteStatus.isReleased;
    }
    stackingAmplitude = defaultNoteAmplitude;
  }
}

/**
 * An abstract that represents the note status for NoteVibrationsHandler.
 */
enum abstract NoteStatus(Int)
{
  var isReleased = 0;
  var isJustPressed = 1;
  var isHoldNotePressed = 2;
}
