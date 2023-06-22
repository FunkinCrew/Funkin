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

    this.active = true;
  }

  function onAnimationFrame(name:String, frameNumber:Int, frameIndex:Int):Void {}

  function onAnimationFinished(name:String):Void
  {
    if (!isPlayer && name.startsWith('confirm'))
    {
      playStatic();
    }
  }

  override function update(elapsed:Float)
  {
    super.update(elapsed);

    centerOrigin();
  }

  function setup():Void
  {
    this.frames = Paths.getSparrowAtlas('StrumlineNotes');

    switch (this.direction)
    {
      case NoteDirection.LEFT:
        this.animation.addByIndices('static', 'left confirm', [6, 7], '', 24, false, false, false);
        this.animation.addByPrefix('press', 'left press', 24, false, false, false);
        this.animation.addByIndices('confirm', 'left confirm', [0, 1, 2, 3], '', 24, false, false, false);
        this.animation.addByIndices('confirm-hold', 'left confirm', [2, 3, 4, 5], '', 24, true, false, false);

      case NoteDirection.DOWN:
        this.animation.addByIndices('static', 'down confirm', [6, 7], '', 24, false, false, false);
        this.animation.addByPrefix('press', 'down press', 24, false, false, false);
        this.animation.addByIndices('confirm', 'down confirm', [0, 1, 2, 3], '', 24, false, false, false);
        this.animation.addByIndices('confirm-hold', 'down confirm', [2, 3, 4, 5], '', 24, true, false, false);

      case NoteDirection.UP:
        this.animation.addByIndices('static', 'up confirm', [6, 7], '', 24, false, false, false);
        this.animation.addByPrefix('press', 'up press', 24, false, false, false);
        this.animation.addByIndices('confirm', 'up confirm', [0, 1, 2, 3], '', 24, false, false, false);
        this.animation.addByIndices('confirm-hold', 'up confirm', [2, 3, 4, 5], '', 24, true, false, false);

      case NoteDirection.RIGHT:
        this.animation.addByIndices('static', 'right confirm', [6, 7], '', 24, false, false, false);
        this.animation.addByPrefix('press', 'right press', 24, false, false, false);
        this.animation.addByIndices('confirm', 'right confirm', [0, 1, 2, 3], '', 24, false, false, false);
        this.animation.addByIndices('confirm-hold', 'right confirm', [2, 3, 4, 5], '', 24, true, false, false);
    }

    this.antialiasing = true;

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

    if (getCurrentAnimation() == "confirm-hold") return;
    if (getCurrentAnimation() == "confirm")
    {
      if (isAnimationFinished())
      {
        this.playAnimation('confirm-hold', true, false);
      }
      return;
    }
    this.playAnimation('confirm', false, false);
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
