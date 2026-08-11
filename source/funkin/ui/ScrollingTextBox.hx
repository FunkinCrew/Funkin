package funkin.ui;

import flixel.math.FlxRect;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.util.FlxDestroyUtil;
import funkin.group.FunkinGroup.FunkinSpriteGroup;

/**
 * A text box that scrolls its text if it is too long to fit in the box.
 */
class ScrollingTextBox extends FunkinSpriteGroup
{
  /**
   * How fast the text creeps to the left, in pixels per second.
   */
  public var scrollSpeed:Float = 34;

  /**
   * How much space sits between the end of the text and where it starts over.
   */
  public var loopGap:Float = 48;

  /**
   * How long the text sits at the start before it sets off again.
   */
  public var holdTime:Float = 1.4;

  /**
   * The width of the visible window.
   */
  public var boxWidth(default, null):Float;

  /**
   * The height of the visible window.
   */
  public var boxHeight(default, null):Float;

  /**
   * Whether the text is allowed to move. Turning it off puts it back at the start.
   */
  public var scrolling(default, set):Bool = false;

  function set_scrolling(value:Bool):Bool
  {
    if (scrolling && !value) resetScroll();

    scrolling = value;
    return scrolling;
  }

  /**
   * The text on show. It is always kept on one line, however long it is.
   */
  public var text(default, set):String = '';

  function set_text(value:String):String
  {
    if (value == null) value = '';
    if (text == value) return text;

    text = value;
    rebuild();

    return text;
  }

  var fontPath:String;
  var fontSize:Int;
  var textColor:FlxColor;

  var line:Null<FlxText> = null;
  var lineClip:Null<FlxRect> = null;

  /**
   * A second copy of the text, trailing the first one, so the text can come back around
   * from the right instead of the box going empty.
   */
  var lineRepeat:Null<FlxText> = null;

  var repeatClip:Null<FlxRect> = null;

  /**
   * How far the text has been dragged to the left, in pixels.
   */
  var scrollOffset:Float = 0;

  /**
   * How long the text has left to sit still before it sets off.
   */
  var holdTimer:Float = 0;

  public function new(boxWidth:Float, boxHeight:Float, fontPath:String, fontSize:Int, textColor:FlxColor = FlxColor.WHITE)
  {
    super();

    this.boxWidth = boxWidth;
    this.boxHeight = boxHeight;
    this.fontPath = fontPath;
    this.fontSize = fontSize;
    this.textColor = textColor;
  }

  override public function update(elapsed:Float):Void
  {
    if (scrolling) advanceScroll(elapsed);

    layoutLine();

    super.update(elapsed);
  }

  override public function destroy():Void
  {
    clearLine();

    super.destroy();
  }

  function rebuild():Void
  {
    clearLine();

    if (text == '') return;

    line = makeLine();
    lineClip = FlxRect.get(0, 0, boxWidth, boxHeight);
    setChildClipRect(line, lineClip);

    lineRepeat = makeLine();
    repeatClip = FlxRect.get(0, 0, boxWidth, boxHeight);
    setChildClipRect(lineRepeat, repeatClip);

    resetScroll();
    layoutLine();
  }

  function makeLine():FlxText
  {
    var copy:FlxText = new FlxText(0, 0, 0, text);
    copy.setFormat(fontPath, fontSize, textColor);
    copy.scrollFactor.copyFrom(scrollFactor);

    @:privateAccess
    copy.regenGraphic();

    add(copy);

    return copy;
  }

  function clearLine():Void
  {
    if (line != null)
    {
      setChildClipRect(line, null);
      remove(line);
      line.destroy();
      line = null;
    }

    if (lineRepeat != null)
    {
      setChildClipRect(lineRepeat, null);
      remove(lineRepeat);
      lineRepeat.destroy();
      lineRepeat = null;
    }

    lineClip = FlxDestroyUtil.put(lineClip);
    repeatClip = FlxDestroyUtil.put(repeatClip);
  }

  function resetScroll():Void
  {
    scrollOffset = 0;
    holdTimer = holdTime;
  }

  function advanceScroll(elapsed:Float):Void
  {
    if (line == null) return;

    if (line.frameWidth <= boxWidth)
    {
      scrollOffset = 0;
      return;
    }

    if (holdTimer > 0)
    {
      holdTimer -= elapsed;
      return;
    }

    scrollOffset += scrollSpeed * elapsed;

    // One full lap puts the trailing copy exactly where the text started, so it can sit there again.
    if (scrollOffset >= line.frameWidth + loopGap)
    {
      scrollOffset = 0;
      holdTimer = holdTime;
    }
  }

  /**
   * Lays out both copies of the text and their clipping rectangles based on the current scroll offset.
   */
  function layoutLine():Void
  {
    if (line == null || lineClip == null) return;

    layoutCopy(line, lineClip, -scrollOffset);

    if (lineRepeat == null || repeatClip == null) return;

    if (line.frameWidth <= boxWidth) lineRepeat.localVisible = false;
    else
      layoutCopy(lineRepeat, repeatClip, -scrollOffset + line.frameWidth + loopGap);
  }

  /**
   * Lays out a single copy of the text and its clipping rectangle based on the current scroll offset.
   */
  function layoutCopy(copy:FlxText, clip:FlxRect, position:Float):Void
  {
    var left:Float = Math.max(0, position);
    var right:Float = Math.min(boxWidth, position + copy.frameWidth);

    copy.localX = position;

    clip.x = Math.min(left - position, Math.max(0, copy.frameWidth - 1));
    clip.y = 0;
    clip.width = right - left;
    clip.height = Math.min(boxHeight, copy.frameHeight);

    copy.localVisible = clip.width >= 1 && clip.height >= 1;

    if (clip.width < 1) clip.width = 1;
    if (clip.height < 1) clip.height = 1;
  }
}
