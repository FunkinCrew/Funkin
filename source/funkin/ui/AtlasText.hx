package funkin.ui;

import funkin.assets.FunkinAssetCache;
import flixel.FlxSprite;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.group.FlxSpriteGroup.FlxTypedSpriteGroup;
import flixel.util.FlxStringUtil;
//
// ~PATHS~
//
import funkin.assets.Assets;
import funkin.assets.ValidatedPaths as Paths;

/**
 * AtlasText is an improved version of Alphabet and FlxBitmapText.
 * It supports animations on the letters, and is less buggy than Alphabet.
 */
@:nullSafety
class AtlasText extends FlxTypedSpriteGroup<AtlasChar>
{
  static var fonts:Map<AtlasFont, AtlasFontData> = new Map<AtlasFont, AtlasFontData>();
  static var casesAllowed:Map<AtlasFont, Case> = new Map<AtlasFont, Case>();

  /**
   * The text being displayed by this AtlasText.
   */
  public var text(default, set):String = '';

  var font:AtlasFontData = new AtlasFontData(AtlasFont.DEFAULT);

  /**
   * The atlas frames used by this AtlasText.
   */
  public var atlas(get, never):Null<FlxAtlasFrames>;

  inline function get_atlas():Null<FlxAtlasFrames> return font.atlas;

  /**
   * The available casings that can be displayed by the current font.
   */
  public var caseAllowed(get, never):Case;

  inline function get_caseAllowed():Case return font.caseAllowed;

  /**
   * The max height of the characters in this AtlasText's font.
   */
  public var maxHeight(get, never):Float;

  inline function get_maxHeight():Float return font.maxHeight;

  public function new(x = 0.0,
    y = 0.0,
    text:String = '',
    fontName:AtlasFont = AtlasFont.DEFAULT)
  {
    super(x, y);

    var fontToUse = fonts[fontName];
    if (fontToUse == null || !fontToUse.isValid())
    {
      fontToUse = new AtlasFontData(fontName);
      fonts[fontName] = fontToUse;
      this.font = fontToUse;
    }
    else
    {
      this.font = fontToUse;
    }

    this.text = text;
  }

  function set_text(value:String):String
  {
    value ??= '';

    var caseValue:String = restrictCase(value);
    var caseText:String = restrictCase(this.text);

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

    if (value == '') return this.text;

    appendTextCased(caseValue);
    return this.text;
  }

  /**
   * Adds new characters, without needing to redraw the previous characters
   * @param str The text to add.
   * @throws String if `text` is null.
   */
  public function appendText(str:String):Void
  {
    if (str == null) throw 'cannot append null';
    if (str == '') return;

    this.text += str;
  }

  /**
   * Converts all characters to fit the font's `allowedCase`.
   * @param str
   */
  function restrictCase(str:String):String
  {
    return switch (caseAllowed)
    {
      case Both:
        str;
      case Upper:
        str.toUpperCase();
      case Lower:
        str.toLowerCase();
    }
  }

  /**
   * Adds new text on top of the existing text. Helper for other methods; DOESN'T CHANGE `this.text`.
   * @param str The text to add, assumed to match the font's `caseAllowed`.
   */
  function appendTextCased(str:String):Void
  {
    if (atlas == null) return;

    var charCount:Int = group.countLiving();
    var xPos:Float = 0;
    var yPos:Float = 0;
    // `countLiving` returns -1 if group is empty
    if (charCount == -1)
    {
      charCount = 0;
    }
    else if (charCount > 0)
    {
      var lastChar:AtlasChar = group.members[charCount - 1];
      xPos = lastChar.x + lastChar.width - x;
      yPos = lastChar.y + lastChar.height - maxHeight - y;
    }

    for (splitStr in str.split(''))
    {
      switch (splitStr)
      {
        case ' ':
          xPos += 40;
        case '\n':
          xPos = 0;
          yPos += maxHeight;
        case char:
          var charSprite:AtlasChar;
          if (group.members.length <= charCount)
          {
            charSprite = new AtlasChar(atlas, char);
          }
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

  /**
   * @return The width of this AtlasText, in pixels.
   */
  public function getWidth():Int
  {
    if (atlas == null) return 0;

    var width:Int = 0;
    for (char in this.text.split(''))
    {
      switch (char)
      {
        case ' ':
          width += 40;
        case '\n':
          // no width for newline character
        case char:
          var sprite = new AtlasChar(atlas, char);
          sprite.revive();
          sprite.char = char;
          sprite.alpha = 1;
          width += Std.int(sprite.width);
      }
    }
    return width;
  }

  override function toString():String
  {
    return 'InputItem, ' + FlxStringUtil.getDebugString([
      LabelValuePair.weak('x', x),
      LabelValuePair.weak('y', y),
      LabelValuePair.weak('text', text)
    ]);
  }
}

/**
 * A sprite representing a single character in an `AtlasText`.
 */
@:nullSafety
class AtlasChar extends FlxSprite
{
  /**
   * XML animation prefixes for symbols and special characters.
   */
  static final CHAR_PREFIXES:Map<String, String> = [
    '&' => '-andpersand-',
    // TODO: Do multi-flag characters work?
    '😠' => '-angry faic-',
    "'" => '-apostraphie-',
    '\\' => '-back slash-',
    ',' => '-comma-',
    '-' => '-dash-',
    '↓' => '-down arrow-', // U+2193
    '”' => '-end quote-', // U+0022
    '!' => '-exclamation point-', // U+0021
    '/' => '-forward slash-', // U+002F
    '>' => '-greater than-', // U+003E
    '♥' => '-heart-', // U+2665
    '♡' => '-heart-',
    '←' => '-left arrow-', // U+2190
    '<' => '-less than-', // U+003C
    '*' => '-multiply x-',
    '.' => '-period-', // U+002E
    '?' => '-question mark-',
    '→' => '-right arrow-', // U+2192
    '“' => '-start quote-',
    '↑' => '-up arrow-' // U+2191
  ];

  /**
   * Which character in the font we are using
   */
  public var char(default, set):String = '';

  public function new(x = 0.0, y = 0.0, atlas:FlxAtlasFrames, char:String)
  {
    super(x, y);
    this.frames = atlas;
    this.char = char;
  }

  function set_char(value:String):String
  {
    if (this.char == value) return this.char;

    animation.addByPrefix('anim', getAnimPrefix(value), 24);
    if (animation.exists('anim')) animation.play('anim');

    updateHitbox();

    this.char = value;
    return this.char;
  }

  function getAnimPrefix(c:String):String
  {
    var prefix = CHAR_PREFIXES.get(c);
    if (prefix != null) return prefix;

    // Default to the character itself.
    return c;
  }
}

/**
 * Represents a cached AtlasText font.
 */
@:nullSafety
private class AtlasFontData
{
  /**
   * The split up graphic for the art.
   */
  public var atlas:Null<FlxAtlasFrames>;

  /**
   * The maximum height of the characters in this font.
   */
  public var maxHeight:Float = 0.0;

  /**
   * What casings are available for this font.
   */
  public var caseAllowed:Case = Both;

  /**
   * The name of the font.
   */
  public var name:AtlasFont;

  public function new(name:AtlasFont)
  {
    this.name = name;
    build();
  }

  /**
   * Load the font data from the assets.
   */
  function build():Void
  {
    atlas = Assets.getSparrowAtlas(Paths.image('ui/fonts/${name}'));

    if (atlas == null)
    {
      FlxG.log.warn('Could not find font atlas for font "${name}".');
      return;
    }

    var containsUpper:Bool = false;
    var containsLower:Bool = false;

    final UPPER_CHAR:EReg = ~/^[A-Z]\d+$/;
    final LOWER_CHAR:EReg = ~/^[a-z]\d+$/;

    for (frame in atlas.frames)
    {
      maxHeight = Math.max(maxHeight, frame.frame.height);

      if (!containsUpper) containsUpper = UPPER_CHAR.match(frame.name);
      if (!containsLower) containsLower = LOWER_CHAR.match(frame.name);
    }

    if (containsUpper != containsLower) caseAllowed = containsUpper ? Upper : Lower;
  }

  /**
   * @return `true` if this font is still valid, and its graphics are properly cached.
   *   `false` if the font is no longer valid and needs to be rebuilt.
   */
  public function isValid():Bool
  {
    return atlas != null && FunkinAssetCache.instance.validateFramesCollection(atlas);
  }
}

/**
 * The allowed casings of the font.
 * Only upper case, only lower case, or both.
 */
enum Case
{
  Both;
  Upper;
  Lower;
}

/**
 * A list of AtlasFonts available in the base game.
 */
enum abstract AtlasFont(String) from String to String
{
  public var DEFAULT = 'default';
  public var BOLD = 'bold';
  public var FREEPLAY_CLEAR = 'freeplay-clear';
}
