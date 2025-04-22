package funkin.play.notes;

import funkin.play.notes.notestyle.NoteStyle;
import flixel.graphics.frames.FlxAtlasFrames;
import funkin.graphics.FunkinSprite;
import funkin.play.notes.NoteSprite;

/**
 * The actual receptor that you see on screen.
 */
class StrumlineNote extends FunkinSprite
{
  /**
   * Whether this strumline note is on the player's side or the opponent's side.
   */
  public var isPlayer(default, null):Bool;

  /**
   * The direction which this strumline note is facing.
   */
  public var direction(default, set):NoteDirection;

  function set_direction(value:NoteDirection):NoteDirection
  {
    this.direction = value;
    return this.direction;
  }

  /**
   * The Y Offset of the note.
   */
  public var yOffset:Float = 0.0;

  /**
   * Set this flag to `true` to disable performance optimizations that cause
   * the Strumline note sprite to ignore `velocity` and `acceleration`.
   */
  public var forceActive:Bool = false;

  /**
   * How long to continue the hold note animation after a note is pressed.
   */
  static final CONFIRM_HOLD_TIME:Float = 0.1;

  /**
   * How long the hold note animation has been playing after a note is pressed.
   */
  var confirmHoldTimer:Float = -1;

  public function new(noteStyle:NoteStyle, isPlayer:Bool, direction:NoteDirection)
  {
    super(0, 0);

    this.isPlayer = isPlayer;

    this.direction = direction;

    setup(noteStyle);

    this.animation.onFrameChange.add(onAnimationFrame);
    this.animation.onFinish.add(onAnimationFinished);

    // Must be true for animations to play.
    this.active = true;
  }

  function onAnimationFrame(name:String, frameNumber:Int, frameIndex:Int):Void
  {
    // Do nothing.
  }

  function onAnimationFinished(name:String):Void
  {
    // Run a timer before we stop playing the confirm animation.
    // On opponent, this prevent issues with hold notes.
    // On player, this allows holding the confirm key to fall back to press.
    if (name == 'confirm')
    {
      confirmHoldTimer = 0;
    }
  }

  override function update(elapsed:Float)
  {
    super.update(elapsed);

    centerOrigin();

    if (confirmHoldTimer >= 0)
    {
      confirmHoldTimer += elapsed;

      // Ensure the opponent stops holding the key after a certain amount of time.
      if (confirmHoldTimer >= CONFIRM_HOLD_TIME)
      {
        confirmHoldTimer = -1;
        playStatic();
      }
    }
  }

  function setup(noteStyle:NoteStyle):Void
  {
    if (noteStyle == null)
    {
      // If you get an exception on this line, check the debug console.
      // You probably have a parsing error in your note style's JSON file.
      throw "FATAL ERROR: Attempted to initialize PlayState with an invalid NoteStyle.";
    }

    noteStyle.applyStrumlineFrames(this);
    noteStyle.applyStrumlineAnimations(this, this.direction);

    var scale = noteStyle.getStrumlineScale();
    this.scale.set(scale, scale);
    this.updateHitbox();
    noteStyle.applyStrumlineOffsets(this);

    this.playStatic();
  }

  public function playAnimation(name:String = 'static', force:Bool = false, reversed:Bool = false, startFrame:Int = 0):Void
  {
    this.animation.play(name, force, reversed, startFrame);

    centerOffsets();
    centerOrigin();
  }

  public function playStatic():Void
  {
    this.active = (forceActive || isAnimationDynamic('static'));
    this.playAnimation('static', true);
  }

  public function playPress():Void
  {
    this.active = (forceActive || isAnimationDynamic('press'));
    this.playAnimation('press', true);
  }

  public function playConfirm():Void
  {
    this.active = (forceActive || isAnimationDynamic('confirm'));
    this.playAnimation('confirm', true);
  }

  public function isConfirm():Bool
  {
    return getCurrentAnimation().startsWith('confirm');
  }

  public function holdConfirm():Void
  {
    this.active = true;

    if (getCurrentAnimation() == "confirm-hold")
    {
      return;
    }
    else if (getCurrentAnimation() == "confirm")
    {
      if (isAnimationFinished())
      {
        this.confirmHoldTimer = -1;
        this.playAnimation('confirm-hold', false, false);
      }
    }
    else
    {
      this.playAnimation('confirm', false, false);
    }
  }

  /**
   * Returns the name of the animation that is currently playing.
   * If no animation is playing (usually this means the sprite is BROKEN!),
   *   returns an empty string to prevent NPEs.
   */
  public function getCurrentAnimation():String
  {
    if (this.animation == null || this.animation.curAnim == null) return "";
    return this.animation.curAnim.name;
  }

  public function isAnimationFinished():Bool
  {
    return this.animation.finished;
  }

  static final DEFAULT_OFFSET:Int = 13;

  /**
   * Adjusts the position of the sprite's graphic relative to the hitbox.
   */
  function fixOffsets():Void
  {
    // Automatically center the bounding box within the graphic.
    this.centerOffsets();

    if (getCurrentAnimation() == "confirm")
    {
      // Move the graphic down and to the right to compensate for
      // the "glow" effect on the strumline note.
      this.offset.x -= DEFAULT_OFFSET;
      this.offset.y -= DEFAULT_OFFSET;
    }
    else
    {
      this.centerOrigin();
    }
  }
}
