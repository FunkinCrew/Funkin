package funkin.play.notes.modifier;

import funkin.play.notes.modifier.NotePath;
import flixel.math.FlxMath;

/**
 * Modifier that makes the note move along a straight line
 * The direction is set by `angle`
 */
class DirectionalPathModifier implements NotePathModifier
{
  /**
   * The direction of the path (in radians)
   */
  public var angle:Float;

  public function new(angle:Float)
  {
    this.angle = angle;
  }

  /**
   * Calculate the path using `direction`
   * @param time The delta of strumTime - songTime
   * @return NoteTransform
   */
  public function calculateTransform(time:Float):NoteTransform
  {
    final xMult:Float = FlxMath.fastSin(angle);
    final yMult:Float = FlxMath.fastCos(angle);
    return new NoteTransform(time * xMult, time * yMult);
  }
}
