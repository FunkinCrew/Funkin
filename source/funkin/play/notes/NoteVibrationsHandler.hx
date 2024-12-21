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
  var leftNoteStatus:NoteStatus;

  /**
   * Down note's status.
   */
  var downNoteStatus:NoteStatus;

  /**
   * Up note's status.
   */
  var upNoteStatus:NoteStatus;

  /**
   * Right note's status.
   */
  var rightNoteStatus:NoteStatus;

  /**
   * An array of each note status.
   * Made for use in other classes.
   */
  public var noteStatuses:Array<NoteStatus>;

  /**
   * Note vibration's default amplitude.
   */
  final defaultNoteAmplitude:Int = Math.ceil(Constants.MAX_VIBRATION_AMPLITUDE / 2);

  /**
   * Creates a new NoteVibrationsHandler instance.
   */
  public function new()
  {
    noteStatuses = [leftNoteStatus, downNoteStatus, upNoteStatus, rightNoteStatus];
  }

  /**
   * Checks if any note status is equal to NoteStatus.isJustPressed.
   * If yes, then vibration is being triggered, amplitude value is stacked depending on how much notes are pressed.
   */
  public function tryNoteVibration():Void
  {
    var stackingAmplitude:Int = defaultNoteAmplitude;

    for (currentNoteStatus in noteStatuses)
    {
      if (currentNoteStatus != NoteStatus.isJustPressed) continue;

      trace("Note Status is Just Pressed!");

      stackingAmplitude += Math.ceil(Constants.MAX_VIBRATION_AMPLITUDE / 8);

      if (stackingAmplitude > 255) stackingAmplitude = 255;
    }

    trace("amplitude: " + stackingAmplitude);

    if (stackingAmplitude > defaultNoteAmplitude) HapticUtil.vibrate(0, 10, stackingAmplitude);
  }
}

/**
 * An abstract that represents the note status for NoteVibrationsHandler.
 */
enum abstract NoteStatus(Int) from Int to Int
{
  var isReleased = 0;
  var isJustPressed = 1;
  var isHoldNotePressed = 2;
}
