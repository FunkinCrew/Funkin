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
    if (!Preferences.vibration) return;

    var stackingAmplitude:Int = 0;

    for (currentNoteStatus in noteStatuses)
    {
      if (currentNoteStatus != NoteStatus.isJustPressed) continue;

      trace("Note is Just Pressed!");

      stackingAmplitude += Math.ceil(Constants.MAX_VIBRATION_AMPLITUDE / 4);
    }

    trace("amplitude: " + stackingAmplitude);

    if (stackingAmplitude > 0) HapticUtil.vibrate(0, 0.01, stackingAmplitude);
  }

  /**
   * Checks if any note status is equal to NoteStatus.isHoldNotePressed.
   * If yes, then vibration is being triggered, amplitude value is stacked depending on how much hold notes are pressed.
   */
  public function tryHoldNoteVibration():Void
  {
    if (!Preferences.vibration) return;

    var stackingAmplitude:Int = 0;

    for (currentNoteStatus in noteStatuses)
    {
      if (currentNoteStatus != NoteStatus.isHoldNotePressed) continue;

      trace("Hold Note is Pressed!");

      stackingAmplitude += Math.ceil(Constants.MAX_VIBRATION_AMPLITUDE / 4);

      if (stackingAmplitude > Constants.MAX_VIBRATION_AMPLITUDE) stackingAmplitude = Constants.MAX_VIBRATION_AMPLITUDE;
    }

    trace("amplitude: " + stackingAmplitude);

    if (stackingAmplitude > 0) HapticUtil.vibrate(0, 0.01, stackingAmplitude);
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
