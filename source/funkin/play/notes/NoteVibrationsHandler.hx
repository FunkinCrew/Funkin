package funkin.play.notes;

import funkin.util.HapticUtil;
import funkin.util.HapticUtil.HapticsMode;

/**
 * Handles vibrations on note presses.
 */
class NoteVibrationsHandler
{
  /**
   * An array of each strumline this NoteVibrationsHandler reads from.
   */
  public var strumlines:Array<Strumline>;

  /**
   * Creates a new NoteVibrationsHandler instance.
   */
  public function new()
  {
    strumlines = [];
  }

  /**
   * Checks if any note status is equal to NoteStatus.isJustPressed.
   * If yes, then vibration is triggered.
   * Amplitude value is stacked depending on how many notes are pressed.
   */
  public function tryNoteVibration():Void
  {
    if (strumlines == null || !HapticUtil.hapticsAvailable) return;

    var stackingAmplitude:Float = 0;

    for (strumline in strumlines)
    {
      if (strumline.hasVibrations && strumline.noteStatuses != null) for (currentNoteStatus in strumline.noteStatuses)
      {
        if (currentNoteStatus != NoteStatus.confirm) continue;

        @:privateAccess
        stackingAmplitude += Constants.MAX_VIBRATION_AMPLITUDE / Strumline.KEY_COUNT;
      }
    }

    if (stackingAmplitude > Constants.MAX_VIBRATION_AMPLITUDE) stackingAmplitude = Constants.MAX_VIBRATION_AMPLITUDE;

    if (stackingAmplitude > 0) HapticUtil.vibrate(0, 0.01, stackingAmplitude * 2.5, 1, [HapticsMode.ALL, HapticsMode.NOTES_ONLY]);
  }

  /**
   * Checks if any note status is equal to NoteStatus.isHoldNotePressed.
   * If yes, then vibration is triggered.
   * Amplitude value is stacked depending on how many hold notes are pressed.
   */
  public function tryHoldNoteVibration(holdNoteEnded:Bool = false):Void
  {
    if (strumlines == null || !HapticUtil.hapticsAvailable) return;

    var stackingAmplitude:Float = 0;

    for (strumline in strumlines)
    {
      if (strumline.hasVibrations && strumline.noteStatuses != null) for (currentNoteStatus in strumline.noteStatuses)
      {
        if (currentNoteStatus != NoteStatus.holdConfirm) continue;

        @:privateAccess
        final amplitudeDivider:Float = Strumline.KEY_COUNT * (holdNoteEnded ? 1 : 2.5);
        stackingAmplitude += Constants.MAX_VIBRATION_AMPLITUDE / amplitudeDivider;
      }
    }

    if (stackingAmplitude > Constants.MAX_VIBRATION_AMPLITUDE) stackingAmplitude = Constants.MAX_VIBRATION_AMPLITUDE;

    if (stackingAmplitude > 0) HapticUtil.vibrate(0, 0.01, stackingAmplitude * 2.5, 1, [HapticsMode.ALL, HapticsMode.NOTES_ONLY]);

    for (strumline in strumlines)
    {
      if (strumline.hasVibrations && strumline.noteStatuses != null) for (currentNoteStatus in strumline.noteStatuses)
      {
        if (currentNoteStatus == NoteStatus.holdConfirm && holdNoteEnded) currentNoteStatus = NoteStatus.pressed;
      }
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
