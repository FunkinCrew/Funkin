package funkin.ui;

import flixel.FlxSprite;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.group.FlxSpriteGroup.FlxTypedSpriteGroup;
import flixel.util.FlxStringUtil;

/**
 * AtlasText is an improved version of Alphabet and FlxBitmapText.
 * It supports animations on the letters, and is less buggy than Alphabet.
 */
@:nullSafety
class AtlasText extends FlxTypedSpriteGroup<AtlasChar>
{
  static var fonts = new Map<AtlasFont, AtlasFontData>();
  static var casesAllowed = new Map<AtlasFont, Case>();

  public var text(default, set):String = "";

  var font:AtlasFontData = new AtlasFontData(AtlasFont.DEFAULT);

  public var atlas(get, never):FlxAtlasFrames;

  inline function get_atlas()
    return font.atlas;

  public var caseAllowed(get, never):Case;

  inline function get_caseAllowed()
    return font.caseAllowed;

  public var maxHeight(get, never):Float;

  inline function get_maxHeight()
    return font.maxHeight;

  public function new(x = 0.0, y = 0.0, text:String = "", fontName:AtlasFont = AtlasFont.DEFAULT)
  {
    if (!fonts.exists(fontName)) fonts[fontName] = new AtlasFontData(fontName);
    font = fonts[fontName] ?? new AtlasFontData(fontName);

    super(x, y);

    this.text = text;
  }

  function set_text(value:String)
  {
    if (value == null) value = "";

    var caseValue = restrictCase(value);
    var caseText = restrictCase(this.text);

    this.text = value;
    if (caseText == caseValue) return value; // cancel redraw

    if (caseValue.indexOf(caseText) == 0)
    {
      // new text is just old text with additions at the end, append the difference
      appendTextCased(caseValue.substr(caseText.length));
      return this.text;
    }

    value = caseValue;

    group.kill();

    if (value == "") return this.text;

    appendTextCased(caseValue);
    return this.text;
  }

  /**
   * Adds new characters, without needing to redraw the previous characters
   * @param text The text to add.
   * @throws String if `text` is null.
   */
  public function appendText(text:String)
  {
    if (text == null) throw "cannot append null";

    if (text == "") return;

    this.text = this.text + text;
  }

  /**
   * Converts all characters to fit the font's `allowedCase`.
   * @param text
   */
  function restrictCase(text:String)
  {
    return switch (caseAllowed)
    {
      case Both: text;
      case Upper: text.toUpperCase();
      case Lower: text.toLowerCase();
    }
  }

  /**
   * Adds new text on top of the existing text. Helper for other methods; DOESN'T CHANGE `this.text`.
   * @param text The text to add, assumed to match the font's `caseAllowed`.
   */
  function appendTextCased(text:String)
  {
    var charCount = group.countLiving();
    var xPos:Float = 0;
    var yPos:Float = 0;
    // `countLiving` returns -1 if group is empty
    if (charCount == -1) charCount = 0;
    else if (charCount > 0)
    {
      var lastChar = group.members[charCount - 1];
      xPos = lastChar.x + lastChar.width - x;
      yPos = lastChar.y + lastChar.height - maxHeight - y;
    }

    var splitValues = text.split("");
    for (i in 0...splitValues.length)
    {
      switch (splitValues[i])
      {
        case " ":
          {
            xPos += 40;
          }
        case "\n":
          {
            xPos = 0;
            yPos += maxHeight;
          }
        case char:
          {
            var charSprite:AtlasChar;
            if (group.members.length <= charCount) charSprite = new AtlasChar(atlas, char);
            else
            {
              charSprite = group.members[charCount];
              charSprite.revive();
              charSprite.char = char;
              charSprite.alpha = 1; // gets multiplied when added
            }
            charSprite.x = xPos;
            charSprite.y = yPos + maxHeight - charSprite.height;
            add(charSprite);

            xPos += charSprite.width;
            charCount++;
          }
      }
    }
  }

  public function getWidth():Int
  {
    var width = 0;
    for (char in this.text.split(""))
    {
      switch (char)
      {
        case " ":
          {
            width += 40;
          }
        case "\n":
          {}
        case char:
          {
            var sprite = new AtlasChar(atlas, char);
            sprite.revive();
            sprite.char = char;
            sprite.alpha = 1;
            width += Std.int(sprite.width);
          }
      }
    }
    return width;
  }

  override function toString()
  {
    return "InputItem, " + FlxStringUtil.getDebugString([
      LabelValuePair.weak("x", x),
      LabelValuePair.weak("y", y),
      LabelValuePair.weak("text", text)
    ]);
  }
}

class AtlasChar extends FlxSprite
{
  public var char(default, set):String;

  public function new(x = 0.0, y = 0.0, atlas:FlxAtlasFrames, char:String)
  {
    super(x, y);
    frames = atlas;
    this.char = char;
  }

  function set_char(value:String)
  {
    if (this.char != value)
    {
      var prefix = getAnimPrefix(value);
      animation.addByPrefix('anim', prefix, 24);
      if (animation.exists('anim'))
      {
        animation.play('anim');
      }
      else
      {
        // trace('Could not find animation for char "' + value + '"');
      }
      updateHitbox();
    }

    return this.char = value;
  }

  function getAnimPrefix(char:String)
  {
    return switch (char)
    {
      case '&': return '-andpersand-';
      case "😠": '-angry faic-'; // TODO: Do multi-flag characters work?
      case "'": '-apostraphie-';
      case "\\": '-back slash-';
      case ",": '-comma-';
      case '-': '-dash-';
      case '↓': '-down arrow-'; // U+2193
      case "”": '-end quote-'; // U+0022
      case "!": '-exclamation point-'; // U+0021
      case "/": '-forward slash-'; // U+002F
      case '>': '-greater than-'; // U+003E
      case '♥': '-heart-'; // U+2665
      case '♡': '-heart-';
      case '←': '-left arrow-'; // U+2190
      case '<': '-less than-'; // U+003C
      case "*": '-multiply x-';
      case '.': '-period-'; // U+002E
      case "?": '-question mark-';
      case '→': '-right arrow-'; // U+2192
      case "“": '-start quote-';
      case '↑': '-up arrow-'; // U+2191

      // Default to getting the character itself.
      default: char;
    }
  }
}

@:nullSafety
private class AtlasFontData
{
  static public var upperChar = ~/^[A-Z]\d+$/;
  static public var lowerChar = ~/^[a-z]\d+$/;

  public var atlas:FlxAtlasFrames;
  public var maxHeight:Float = 0.0;
  public var caseAllowed:Case = Both;

  public function new(name:AtlasFont)
  {
    var fontName:String = name;
    atlas = Paths.getSparrowAtlas('fonts/${fontName.toLowerCase()}');
    if (atlas == null)
    {
      FlxG.log.warn('Could not find font atlas for font "${fontName}".');
      return;
    }

    atlas.parent.destroyOnNoUse = false;
    atlas.parent.persist = true;

    var containsUpper = false;
    var containsLower = false;

    for (frame in atlas.frames)
    {
      maxHeight = Math.max(maxHeight, frame.frame.height);

      if (!containsUpper) containsUpper = upperChar.match(frame.name);

      if (!containsLower) containsLower = lowerChar.match(frame.name);
    }

    if (containsUpper != containsLower) caseAllowed = containsUpper ? Upper : Lower;
  }
}

enum Case
{
  Both;
  Upper;
  Lower;
}

enum abstract AtlasFont(String) from String to String
{
  var DEFAULT = "default";
  var BOLD = "bold";
  var FREEPLAY_CLEAR = "freeplay-clear";
}
