package funkin.play.cutscene.dialogue;

import flixel.addons.text.FlxTypeText;
import flixel.input.keyboard.FlxKey;

/**
 * An FlxTypeText that better accounts for text-wrapping,
 * by overriding the functions of insertBreakLines() to check the finished state.
 * Also fixes a bug where empty strings would make the typing never 'finish'.
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

  override public function start(?Delay:Float, ForceRestart:Bool = false, AutoErase:Bool = false, ?SkipKeys:Array<FlxKey>, ?Callback:Void->Void):Void
  {
    if (Delay != null)
    {
      delay = Delay;
    }

    _typing = true;
    _erasing = false;
    paused = false;
    _waiting = false;

    if (ForceRestart)
    {
      text = "";
      _length = 0;
    }

    autoErase = AutoErase;

    if (SkipKeys != null)
    {
      skipKeys = SkipKeys;
    }

    if (Callback != null)
    {
      completeCallback = Callback;
    }

    if (useDefaultSound)
    {
      loadDefaultSound();
    }

    // Autocomplete if the text is empty anyway. Why bother?
    if (_finalText.length == 0)
    {
      onComplete();
      return;
    }

    if (preWrapping)
    {
      insertBreakLines();
    }
  }

  override function insertBreakLines()
  {
    var saveText = text;

    // See what it looks like when it's finished typing.
    text = prefix + _finalText;
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
    text = saveText;
  }
}
