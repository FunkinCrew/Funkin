package funkin.play.components;

import flixel.group.FlxSpriteGroup;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.sound.FlxSound;
import flixel.FlxSprite;
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

class Subtitles extends FlxSpriteGroup
{
  public static final curLocale:String = 'english';

  var subtitleText:FlxText;
  var background:FlxSprite;

  var subtitlesData:Array<SubtitlesLineData>;
  var assignedSound:FlxSound;

  public function new(y:Float = 0)
  {
    super(0, y);

    background = new FlxSprite(0, 0);
    background.alpha = 0.5;
    add(background);

    subtitleText = new FlxText(0, 0, 0, '', 20).setFormat(Paths.font('vcr.ttf'), 30, FlxColor.WHITE, FlxTextAlign.CENTER);
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
