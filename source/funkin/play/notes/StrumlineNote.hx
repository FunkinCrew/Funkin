package funkin.play.notes;

import flixel.graphics.frames.FlxAtlasFrames;
import flixel.FlxSprite;
import funkin.play.notes.NoteSprite;

/**
 * The actual receptor that you see on screen.
 */
class StrumlineNote extends FlxSprite
{
  public var isPlayer(default, null):Bool;

  public var direction(default, set):NoteDirection;

  var confirmHoldTimer:Float = -1;

  static final CONFIRM_HOLD_TIME:Float = 0.1;

  public function updatePosition(parentNote:NoteSprite)
  {
    this.x = parentNote.x;
    this.x += parentNote.width / 2;
    this.x -= this.width / 2;

    this.y = parentNote.y;
    this.y += parentNote.height / 2;
  }

  function set_direction(value:NoteDirection):NoteDirection
  {
    this.direction = value;
    setup();
    return this.direction;
  }

  public function new(isPlayer:Bool, direction:NoteDirection)
  {
    super(0, 0);

    this.isPlayer = isPlayer;

    this.direction = direction;

    this.animation.callback = onAnimationFrame;
    this.animation.finishCallback = onAnimationFinished;

    // Must be true for animations to play.
    this.active = true;
  }

  function onAnimationFrame(name:String, frameNumber:Int, frameIndex:Int):Void {}

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

  function setup():Void
  {
    this.frames = Paths.getSparrowAtlas('noteStrumline');

    switch (this.direction)
    {
      case NoteDirection.LEFT:
        this.animation.addByPrefix('static', 'staticLeft0', 24, false, false, false);
        this.animation.addByPrefix('press', 'pressLeft0', 24, false, false, false);
        this.animation.addByPrefix('confirm', 'confirmLeft0', 24, false, false, false);
        this.animation.addByPrefix('confirm-hold', 'confirmHoldLeft0', 24, true, false, false);

      case NoteDirection.DOWN:
        this.animation.addByPrefix('static', 'staticDown0', 24, false, false, false);
        this.animation.addByPrefix('press', 'pressDown0', 24, false, false, false);
        this.animation.addByPrefix('confirm', 'confirmDown0', 24, false, false, false);
        this.animation.addByPrefix('confirm-hold', 'confirmHoldDown0', 24, true, false, false);

      case NoteDirection.UP:
        this.animation.addByPrefix('static', 'staticUp0', 24, false, false, false);
        this.animation.addByPrefix('press', 'pressUp0', 24, false, false, false);
        this.animation.addByPrefix('confirm', 'confirmUp0', 24, false, false, false);
        this.animation.addByPrefix('confirm-hold', 'confirmHoldUp0', 24, true, false, false);

      case NoteDirection.RIGHT:
        this.animation.addByPrefix('static', 'staticRight0', 24, false, false, false);
        this.animation.addByPrefix('press', 'pressRight0', 24, false, false, false);
        this.animation.addByPrefix('confirm', 'confirmRight0', 24, false, false, false);
        this.animation.addByPrefix('confirm-hold', 'confirmHoldRight0', 24, true, false, false);
    }

    this.setGraphicSize(Std.int(Strumline.STRUMLINE_SIZE * 1.55));
    this.updateHitbox();
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
    this.active = false;
    this.playAnimation('static', true);
  }

  public function playPress():Void
  {
    this.active = true;
    this.playAnimation('press', true);
  }

  public function playConfirm():Void
  {
    this.active = true;
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
