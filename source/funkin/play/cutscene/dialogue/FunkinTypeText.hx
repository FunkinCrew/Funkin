package funkin.play.cutscene.dialogue;

import flixel.addons.text.FlxTypeText;

/**
 * An FlxTypeText that accounts for text-wrapping in advance,
 * by overriding the functions of resetText() to check the finished state.
 * Avoids words starting on one line and continuing in the next.
 */
class FunkinTypeText extends FlxTypeText
{
  public var preWrapping:Bool = true;

  public function new(X:Float, Y:Float, Width:Int, Text:String, Size:Int = 8, EmbeddedFont:Bool = true, CheckWrapping:Bool = true)
  {
    super(X, Y, Width, "", Size, EmbeddedFont);
    _finalText = Text;
    preWrapping = CheckWrapping;
  }

  override public function resetText(Text:String):Void
  {
    _finalText = Text;

    if (preWrapping)
    {
      text = prefix + Text;
      var prefixLength:Null<Int> = prefix.length;
      var split:String = '';

      // trace('Breaking apart text lines...');

      for (i in 0...textField.numLines)
      {
        var curLine = textField.getLineText(i);
        // trace('now at line $i, curLine: $curLine');
        if (prefixLength >= curLine.length)
        {
          prefixLength -= curLine.length;
        }
        else if (prefixLength != null)
        {
          split += curLine.substr(prefixLength);
          prefixLength = null;
        }
        else
        {
          split += '\n' + curLine;
        }
        // trace('now at line $i, split: $split');
      }

      _finalText = split;
    }

    text = prefix;
    _typing = false;
    _erasing = false;
    paused = false;
    _waiting = false;
    _length = 0;
  }
}
