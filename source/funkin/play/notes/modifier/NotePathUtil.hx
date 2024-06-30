package funkin.play.notes.modifier;

/**
 * Class that contains util functions
 */
class NotePathUtil
{
  /**
   * Calculates the transform for the note/trail
   * @param modifier The modifier to use
   * @param time The delta of strumTime - songTime
   * @param scrollSpeed The scrollSpeed
   * @param targetPositionX Target x position
   * @param targetPositionY Target y position
   * @return NoteTransform
   */
  public static function calculatePath(modifier:NotePathModifier, time:Float, scrollSpeed:Float, targetPositionX:Float, targetPositionY:Float):NoteTransform
  {
    var transform:NoteTransform = new NoteTransform(targetPositionX, targetPositionY);

    final downscrollSign:Float = (Preferences.downscroll ? -1.0 : 1.0);

    final modifierTransform:NoteTransform = modifier.calculateTransform(time);

    transform.x += modifierTransform.x * Constants.PIXELS_PER_MS * scrollSpeed;
    transform.y += modifierTransform.y * Constants.PIXELS_PER_MS * scrollSpeed * downscrollSign;

    return transform;
  }

  /**
   * Retrieve all currently rendered notes
   * This assumes that player and opponent strumlines are initialized
   * @return Array<NoteSprite>
   */
  public static function getNotes():Array<NoteSprite>
  {
    var notes:Array<NoteSprite> = PlayState.instance.playerStrumline.notes.members.concat(PlayState.instance.opponentStrumline.notes.members);
    return notes.filter(function(note:NoteSprite) {
      return note != null;
    });
  }
}
