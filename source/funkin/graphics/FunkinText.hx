package funkin.graphics;

import flixel.text.FlxText;

/**
 * An FlxText with additional functionality to replace the Font in case the current font doesn't have a character.
 */
class FunkinText extends FlxText
{
  /**
   * The Font to replace the Font that doesn't contain some characters with.
   */
  public static final REPLACEMENT_FONT:String = "Arial";

  /**
   * The Char Codes of the Sequences to ignore when checking whether or not a Font has a character.
   */
  public static final IGNORED_SEQUENCES:Array<Int> = ["\t".code, "\n".code, "\r".code];

  var availableFontCharCodes:Array<Int> = [];

  override function set_font(Font:String):String
  {
    super.set_font(Font);

    availableFontCharCodes = [];

    @:privateAccess
    {
      var fontObject = openfl.text._internal.TextEngine.findFont(_font);

      if (fontObject != null)
      {
        var data = fontObject.decompose();

        for (glyph in data.glyphs)
          availableFontCharCodes.push(glyph.char_code);
      }
    }

    checkAvailableChars();

    return Font;
  }

  override function set_text(Text:String):String
  {
    super.set_text(Text);
    checkAvailableChars();
    return Text;
  }

  function checkAvailableChars()
  {
    if (textField == null) return;

    // reset the format font
    _defaultFormat.font = _font;
    updateDefaultFormat();

    for (i in 0...text.length)
    {
      var charCode:Int = text.charCodeAt(i) ?? -1;

      if (!availableFontCharCodes.contains(charCode)
        && charCode != -1
        && !IGNORED_SEQUENCES.contains(charCode)) // replace the font with the REPLACEMENT_FONT
      {
        _defaultFormat.font = REPLACEMENT_FONT;
        updateDefaultFormat();
        break;
      }
    }
  }
}
