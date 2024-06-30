package funkin.play.notes.modifier;

import funkin.play.notes.modifier.NotePath;

/**
 * Interface that describes how a note should move towards the strum
 */
interface NotePathModifier
{
  /**
   * Calculates the transform for the note/trail
   * @param time The delta of strumTime - songTime
   * @return NoteTransform
   */
  public function calculateTransform(time:Float):NoteTransform;
}
