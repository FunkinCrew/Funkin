package funkin.ui.charSelect;

import flixel.math.FlxPoint;
import funkin.graphics.FunkinSprite;
import funkin.group.FunkinGroup;
import funkin.util.MathUtil;
import openfl.display.BlendMode;
import flixel.tweens.FlxTween;

/**
 * A `FunkinGroup` that hold the cursors for the Character Select screen.
 */
@:nullSafety
class CharSelectCursors extends FunkinGroup<FunkinSprite>
{
  /**
   * The main cursor sprite for this class.
   */
  public var main:FunkinSprite;

  /**
   * The cursor's target position.
   * Changing this will move the cursor to whatever position is set.
   */
  public var targetPosition:FlxPoint = FlxPoint.get(0, 0);

  /**
   * A multiplication factor for the cursor's position.
   */
  final CURSOR_LERP_FACTOR:Float = 110;

  /**
   * Additional offsets for the cursor's position.
   */
  final CURSOR_OFFSETS:FlxPoint = FlxPoint.get(-16, -51);

  var lightBlue:FunkinSprite;
  var darkBlue:FunkinSprite;
  var cursorConfirmed:FunkinSprite;
  var cursorDenied:FunkinSprite;

  public function new()
  {
    super();

    darkBlue = new FunkinSprite(0, 0);
    lightBlue = new FunkinSprite(0, 0);
    main = new FunkinSprite(0, 0);

    cursorConfirmed = new FunkinSprite(0, 0);
    cursorDenied = new FunkinSprite(0, 0);

    darkBlue.loadGraphic(Paths.image('ui/character-select/interface/char-selector'));
    lightBlue.loadGraphic(Paths.image('ui/character-select/interface/char-selector'));
    main.loadGraphic(Paths.image('ui/character-select/interface/char-selector'));

    darkBlue.color = 0xFF3C74F7;
    lightBlue.color = 0xFF3EBBFF;
    main.color = 0xFFFFFF00;

    FlxTween.color(main, 0.2, 0xFFFFFF00, 0xFFFFCC00, {
      type: PINGPONG
    });

    darkBlue.blend = BlendMode.SCREEN;
    lightBlue.blend = BlendMode.SCREEN;

    add(darkBlue);
    add(lightBlue);
    add(main);

    cursorConfirmed.frames = Paths.getSparrowAtlas('ui/character-select/interface/char-selector-confirm');
    cursorConfirmed.animation.addByPrefix('idle', 'cursor ACCEPTED instance 1', 24, true);
    cursorConfirmed.localVisible = false;
    add(cursorConfirmed);

    cursorDenied.frames = Paths.getSparrowAtlas('ui/character-select/interface/char-selector-denied');
    cursorDenied.animation.addByPrefix('idle', 'cursor DENIED instance 1', 24, false);
    cursorDenied.localVisible = false;
    add(cursorDenied);

    scrollFactor.set();
  }

  override public function update(elapsed:Float):Void
  {
    super.update(elapsed);

    if (CharacterSelectState.instance != null)
    {
      lerpToIndex(CharacterSelectState.instance.currentSelection);
    }
  }

  /**
   * Snaps the cursors to the given index.
   * @param index The index to snap to as a `Int`.
   */
  public function snapToIndex(index:Int):Void
  {
    setLocationFromIndex(index);
    snapToLocation(targetPosition);
  }

  /**
   * Lerps the cursors to the given index.
   * @param index The index to lerp to as a `Int`.
   */
  public function lerpToIndex(index:Int):Void
  {
    setLocationFromIndex(index);
    lerpToLocation(targetPosition);
  }

  function setLocationFromIndex(index:Int):Void
  {
    var slotsPerPage:Int = CharacterSelectState.SLOTS_PER_PAGE;
    var slotsPerRow:Int = CharacterSelectState.SLOTS_PER_ROW;

    var pageRow:Int = ((index % slotsPerPage) % slotsPerRow) - 1;
    var pageColumn:Int = Math.floor((index % slotsPerPage) / slotsPerRow) - 1;

    targetPosition.x = ((CURSOR_LERP_FACTOR * pageRow) + (FlxG.width / 2) - main.width / 2) + CURSOR_OFFSETS.x;
    targetPosition.y = ((CURSOR_LERP_FACTOR * pageColumn) + (FlxG.height / 2) - main.height / 2) + CURSOR_OFFSETS.y;
  }

  /**
   * Plays the confirm animation.
   */
  public function confirm():Void
  {
    cursorConfirmed.localVisible = true;
    cursorConfirmed.animation.play('idle', true);

    main.localVisible = lightBlue.localVisible = darkBlue.localVisible = false;
  }

  /**
   * Resets the denied cursor back to its default state.
   */
  public function resetDeny():Void
  {
    cursorDenied.localVisible = false;
  }

  /**
   * Plays the deny animation.
   */
  public function deny():Void
  {
    cursorDenied.localVisible = true;
    cursorDenied.animation.play('idle', true);
    cursorDenied.animation.onFinish.add((_) ->
    {
      cursorDenied.localVisible = false;
    });
  }

  /**
   * Undoes the confirm animation.
   */
  public function unconfirm():Void
  {
    cursorConfirmed.localVisible = false;
    main.localVisible = lightBlue.localVisible = darkBlue.localVisible = true;
  }

  /**
   * Snaps the cursors to the given position.
   * @param intendedPosition The position to snap to as a `FlxPoint`.
   */
  public function snapToLocation(intendedPosition:FlxPoint):Void
  {
    main.localX = intendedPosition.x;
    main.localY = intendedPosition.y;

    lightBlue.localX = main.localX;
    lightBlue.localY = main.localY;

    darkBlue.localX = intendedPosition.x;
    darkBlue.localY = intendedPosition.y;

    cursorConfirmed.localX = main.localX - 2;
    cursorConfirmed.localY = main.localY - 4;

    cursorDenied.localX = main.localX - 2;
    cursorDenied.localY = main.localY - 4;
  }

  /**
   * Lerps the cursors to the given position.
   * @param intendedPosition The position to lerp to as a `FlxPoint`.
   */
  public function lerpToLocation(intendedPosition:FlxPoint):Void
  {
    main.localX = MathUtil.snap(MathUtil.smoothLerpPrecision(main.localX, intendedPosition.x, FlxG.elapsed, 0.1), intendedPosition.x, 1);
    main.localY = MathUtil.snap(MathUtil.smoothLerpPrecision(main.localY, intendedPosition.y, FlxG.elapsed, 0.1), intendedPosition.y, 1);

    lightBlue.localX = MathUtil.smoothLerpPrecision(lightBlue.localX, main.localX, FlxG.elapsed, 0.202);
    lightBlue.localY = MathUtil.smoothLerpPrecision(lightBlue.localY, main.localY, FlxG.elapsed, 0.202);

    darkBlue.localX = MathUtil.smoothLerpPrecision(darkBlue.localX, intendedPosition.x, FlxG.elapsed, 0.404);
    darkBlue.localY = MathUtil.smoothLerpPrecision(darkBlue.localY, intendedPosition.y, FlxG.elapsed, 0.404);

    cursorConfirmed.localX = main.localX - 2;
    cursorConfirmed.localY = main.localY - 4;

    cursorDenied.localX = main.localX - 2;
    cursorDenied.localY = main.localY - 4;
  }
}
