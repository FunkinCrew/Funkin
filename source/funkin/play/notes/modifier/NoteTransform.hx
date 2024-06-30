package funkin.play.notes.modifier;

/**
 * Class that contains note transform data
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

/**
 * Wrapper for `NoteTransformRaw`
 */
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
