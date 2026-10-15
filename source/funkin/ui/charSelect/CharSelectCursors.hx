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
    cursorConfirmed.visible = false;
    add(cursorConfirmed);

    cursorDenied.frames = Paths.getSparrowAtlas('ui/character-select/interface/char-selector-denied');
    cursorDenied.animation.addByPrefix('idle', 'cursor DENIED instance 1', 24, false);
    cursorDenied.visible = false;
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
    cursorConfirmed.visible = true;
    cursorConfirmed.animation.play('idle', true);

    main.visible = lightBlue.visible = darkBlue.visible = false;
  }

  /**
   * Resets the denied cursor back to its default state.
   */
  public function resetDeny():Void
  {
    cursorDenied.visible = false;
  }

  /**
   * Plays the deny animation.
   */
  public function deny():Void
  {
    cursorDenied.visible = true;
    cursorDenied.animation.play('idle', true);
    cursorDenied.animation.onFinish.add((_) ->
    {
      cursorDenied.visible = false;
    });
  }

  /**
   * Undoes the confirm animation.
   */
  public function unconfirm():Void
  {
    cursorConfirmed.visible = false;
    main.visible = lightBlue.visible = darkBlue.visible = true;
  }

  /**
   * Snaps the cursors to the given position.
   * @param intendedPosition The position to snap to as a `FlxPoint`.
   */
  public function snapToLocation(intendedPosition:FlxPoint):Void
  {
    main.x = intendedPosition.x;
    main.y = intendedPosition.y;

    lightBlue.x = main.x;
    lightBlue.y = main.y;

    darkBlue.x = intendedPosition.x;
    darkBlue.y = intendedPosition.y;

    cursorConfirmed.x = main.x - 2;
    cursorConfirmed.y = main.y - 4;

    cursorDenied.x = main.x - 2;
    cursorDenied.y = main.y - 4;
  }

  /**
   * Lerps the cursors to the given position.
   * @param intendedPosition The position to lerp to as a `FlxPoint`.
   */
  public function lerpToLocation(intendedPosition:FlxPoint):Void
  {
    main.x = MathUtil.snap(MathUtil.smoothLerpPrecision(main.x, intendedPosition.x, FlxG.elapsed, 0.1), intendedPosition.x, 1);
    main.y = MathUtil.snap(MathUtil.smoothLerpPrecision(main.y, intendedPosition.y, FlxG.elapsed, 0.1), intendedPosition.y, 1);

    lightBlue.x = MathUtil.smoothLerpPrecision(lightBlue.x, main.x, FlxG.elapsed, 0.202);
    lightBlue.y = MathUtil.smoothLerpPrecision(lightBlue.y, main.y, FlxG.elapsed, 0.202);

    darkBlue.x = MathUtil.smoothLerpPrecision(darkBlue.x, intendedPosition.x, FlxG.elapsed, 0.404);
    darkBlue.y = MathUtil.smoothLerpPrecision(darkBlue.y, intendedPosition.y, FlxG.elapsed, 0.404);

    cursorConfirmed.x = main.x - 2;
    cursorConfirmed.y = main.y - 4;

    cursorDenied.x = main.x - 2;
    cursorDenied.y = main.y - 4;
  }
}
