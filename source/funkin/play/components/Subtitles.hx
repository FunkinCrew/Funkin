package funkin.play.components;

import flixel.group.FlxSpriteGroup;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.sound.FlxSound;
import flixel.FlxSprite;
import openfl.text.TextField;
import openfl.text.TextFormat;
import haxe.Json;

typedef SubtitlesData =
{
  locales:Array<Map<String, Array<SubtitlesLineData>>>
}

typedef SubtitlesLineData =
{
  time:Float,
  length:Float,
  line:String
}

/**
 * A Sprite Group for displaying in-game subtitles.
 */
class Subtitles extends FlxSpriteGroup
{
  public static final curLocale:String = 'english';

  var subtitleText:SubtitlesText;
  var background:FlxSprite;

  var subtitlesData:Array<SubtitlesLineData>;
  var assignedSound:FlxSound;

  public function new(y:Float = 0)
  {
    super(0, y);

    background = new FlxSprite(0, 0);
    background.alpha = 0.5;
    add(background);

    subtitleText = new SubtitlesText(0, 0, 20, Paths.font('vcr.ttf'));
    add(subtitleText);

    setText('', true);
  }

  override function update(elapsed:Float)
  {
    super.update(elapsed);

    if (assignedSound == null || subtitlesData == null) return;

    var foundValidLine:Bool = false;
    for (data in subtitlesData)
    {
      if (assignedSound.time >= data.time && assignedSound.time <= data.time + data.length)
      {
        setText(data.line);

        foundValidLine = true;
      }
    }

    if (!foundValidLine) setText('', true);
  }

  /**
   * A function which loads the subtitles.
   * @param filePath A path to the subtitles data file.
   * @param sound The sound to assign to the current subtitles.
   */
  public function assignSubtitles(filePath:String, sound:FlxSound):Void
  {
    trace(filePath);

    if (!Assets.exists(filePath) || sound == null) return;

    final data:SubtitlesData = Json.parse(Assets.getText(filePath));

    if (data == null) return;

    for (locale in data.locales)
    {
      final subtitlesLinesData = locale.get(curLocale);
      if (subtitlesLinesData != null)
      {
        subtitlesData = subtitlesLinesData;
        break;
      }
    }

    assignedSound = sound;
  }

  function setText(text:String, hide:Bool = false):Void
  {
    visible = !hide;

    subtitleText.text = text;

    background.makeGraphic(Math.ceil(subtitleText.width), Math.ceil(subtitleText.height), FlxColor.BLACK, true);

    screenCenter(X);
  }
}

/**
 * A slightly modified `FlxText` specifically for subtitles.
 */
class SubtitlesText extends FlxText
{
  public function new(x:Float = 0, y:Float = 0, size:Float, font:String)
  {
    super(x, y, 0, '', 20);

    this.font = font;
    this.size = size;
    this.alignment = FlxTextAlign.CENTER;
  }

  /**
   * Make it set the `htmlText` instead of `text` for properly working HTML text elements.
   */
  override function set_text(Text:String):String
  {
    text = Text;
    if (textField != null)
    {
      var ot:String = textField.htmlText;
      textField.htmlText = Text;
      _regen = (textField.htmlText != ot) || _regen;
    }
    return Text;
  }
}
