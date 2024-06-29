package funkin.play.notes.modifier;

/**
 * Class that contains a `NotePathModifier`
 */
class NotePath
{
  /**
   * The `NotePathModifier` to use
   */
  public var modifier(default, set):NotePathModifier;

  function set_modifier(value:NotePathModifier):NotePathModifier
  {
    if (value == null)
    {
      return this.modifier;
    }

    this.modifier = value;

    return this.modifier;
  }

  public function new()
  {
    this.reset();
  }

  /**
   * Calculates the transform for the note/trail
   * @param time The delta of strumTime - songTime
   * @param scrollSpeed The scrollSpeed
   * @param targetPositionX Target x position
   * @param targetPositionY Target y position
   * @return NoteTransform
   */
  public function calculateTransform(time:Float, scrollSpeed:Float, targetPositionX:Float, targetPositionY:Float):NoteTransform
  {
    var transform:NoteTransform = new NoteTransform(targetPositionX, targetPositionY);

    final downscrollSign:Float = (Preferences.downscroll ? -1.0 : 1.0);

    final modifierTransform:NoteTransform = this.modifier.calculateTransform(time);

    transform.x += modifierTransform.x * Constants.PIXELS_PER_MS * scrollSpeed;
    transform.y += modifierTransform.y * Constants.PIXELS_PER_MS * scrollSpeed * downscrollSign;

    return transform;
  }

  /**
   * Use default modifier
   */
  public function reset():Void
  {
    this.modifier = new DirectionalPathModifier(0.0);
  }
}

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

/**
 * Abstract class that contains note transform data
 */
class NoteTransformRaw
{
  /**
   * X position
   */
  public var x:Float;

  /**
   * Y position
   */
  public var y:Float;

  public function new(x:Float, y:Float)
  {
    this.x = x;
    this.y = y;
  }
}

@:forward
abstract NoteTransform(NoteTransformRaw) from NoteTransformRaw to NoteTransformRaw
{
  public function new(x:Float, y:Float)
  {
    this = new NoteTransformRaw(x, y);
  }

  @:op(A + B)
  public function op_add(other:NoteTransform):NoteTransform
  {
    return new NoteTransform(this.x + other.x, this.y + other.y);
  }

  @:op(A - B)
  public function op_sub(other:NoteTransform):NoteTransform
  {
    return new NoteTransform(this.x - other.x, this.y - other.y);
  }

  @:op(A * B)
  public function op_mul(other:NoteTransform):NoteTransform
  {
    return new NoteTransform(this.x * other.x, this.y * other.y);
  }

  @:op(A / B)
  public function op_div(other:NoteTransform):NoteTransform
  {
    return new NoteTransform(this.x / other.x, this.y / other.y);
  }
}
