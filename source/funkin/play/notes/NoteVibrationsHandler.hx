package funkin.play.notes;

import funkin.util.HapticUtil;
import funkin.util.HapticUtil.HapticsMode;

/**
 * Handles vibrations on note presses.
 */
class NoteVibrationsHandler
{
  /**
   * Controls vibrations for all strumlines with `hasVibrations` enabled.
   * There should be only one of these.
   */
  public static var instance:NoteVibrationsHandler = new NoteVibrationsHandler();

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
   * Checks if any note statuses are equal to NoteStatus.isHoldNotePressed.
   * If yes, then vibration occurrs.
   * Amplitude stacks depending on how many hold notes are pressed.
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
   * Checks if any note statuses are equal to NoteStatus.isHoldNotePressed.
   * If yes, then vibration occurrs.
   * Amplitude stacks depending on how many hold notes are pressed.
   * @param holdNoteEnded The strumline that just had a hold note end, or null if not applicable.
   */
  public function tryHoldNoteVibration(?holdNoteEnded:Int):Void
  {
    if (strumlines == null || !HapticUtil.hapticsAvailable) return;

    var stackingAmplitude:Float = 0;

    for (strumline in strumlines)
    {
      if (strumline.hasVibrations && strumline.noteStatuses != null) for (i in 0...strumline.noteStatuses.length)
      {
        if (strumline.noteStatuses[i] != NoteStatus.holdConfirm && (holdNoteEnded == null || holdNoteEnded == i)) continue;

        @:privateAccess
        final amplitudeDivider:Float = Strumline.KEY_COUNT * (holdNoteEnded == i ? 1 : 2.5);
        stackingAmplitude += Constants.MAX_VIBRATION_AMPLITUDE / amplitudeDivider;
      }
    }

    if (stackingAmplitude > Constants.MAX_VIBRATION_AMPLITUDE) stackingAmplitude = Constants.MAX_VIBRATION_AMPLITUDE;

    if (stackingAmplitude > 0) HapticUtil.vibrate(0, 0.01, stackingAmplitude * 2.5, 1, [HapticsMode.ALL, HapticsMode.NOTES_ONLY]);

    for (strumline in strumlines)
    {
      if (strumline.hasVibrations && strumline.noteStatuses != null && holdNoteEnded != null) for (i in 0...strumline.noteStatuses.length)
      {
        if (strumline.noteStatuses[i] == NoteStatus.holdConfirm && holdNoteEnded == i) strumline.noteStatuses[i] = NoteStatus.pressed;
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
