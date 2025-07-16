package funkin.play.notes;

import funkin.util.HapticUtil;
import funkin.util.HapticUtil.HapticsMode;

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
    if (noteStatuses == null || !HapticUtil.hapticsAvailable) return;

    var stackingAmplitude:Float = 0;

    for (currentNoteStatus in noteStatuses)
    {
      if (currentNoteStatus != NoteStatus.confirm) continue;

      stackingAmplitude += Constants.MAX_VIBRATION_AMPLITUDE / 4;
    }

    if (stackingAmplitude > Constants.MAX_VIBRATION_AMPLITUDE) stackingAmplitude = Constants.MAX_VIBRATION_AMPLITUDE;

    if (stackingAmplitude > 0) HapticUtil.vibrate(0, 0.01, stackingAmplitude * 2.5, 1, [HapticsMode.ALL, HapticsMode.NOTES_ONLY]);
  }

  /**
   * Checks if any note status is equal to NoteStatus.isHoldNotePressed.
   * If yes, then vibration is being triggered, amplitude value is stacked depending on how much hold notes are pressed.
   */
  public function tryHoldNoteVibration(holdNoteEnded:Bool = false):Void
  {
    if (noteStatuses == null || !HapticUtil.hapticsAvailable) return;

    var stackingAmplitude:Float = 0;

    for (currentNoteStatus in noteStatuses)
    {
      if (currentNoteStatus != NoteStatus.holdConfirm) continue;

      final amplitudeDivider:Float = holdNoteEnded ? 4 : 10;
      stackingAmplitude += Constants.MAX_VIBRATION_AMPLITUDE / amplitudeDivider;
    }

    if (stackingAmplitude > Constants.MAX_VIBRATION_AMPLITUDE) stackingAmplitude = Constants.MAX_VIBRATION_AMPLITUDE;

    if (stackingAmplitude > 0) HapticUtil.vibrate(0, 0.01, stackingAmplitude * 2.5, 1, [HapticsMode.ALL, HapticsMode.NOTES_ONLY]);

    for (currentNoteStatus in noteStatuses)
    {
      if (currentNoteStatus == NoteStatus.holdConfirm && holdNoteEnded) currentNoteStatus == NoteStatus.pressed;
    }
  }
}

/**
 * An abstract that represents the note status for NoteVibrationsHandler.
 */
enum abstract NoteStatus(Int) from Int to Int
{
  var idle = 0;
  var pressed = 1;
  var confirm = 2;
  var holdConfirm = 3;
}
