package funkin.ui.debug.playtest;

#if sys
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.tweens.FlxTween;
import funkin.util.file.FNFCUtil;
import funkin.play.song.Song;
import funkin.graphics.FunkinSprite;
import funkin.graphics.FunkinCamera;
import funkin.ui.debug.playtest.ChartPlaytestMenuButton;
import funkin.ui.debug.playtest.ChartPlaytestMenuButton.ChartPlaytestMenuButtonListToggle;
#if NO_FEATURE_TOUCH_CONTROLS
import funkin.input.Cursor;
#end

/**
 * When playtesting from an FNFC file, we display a debug UI to choose a difficulty first.
 */
class ChartPlaytestMenu extends MusicBeatState
{
  var filePath:String;

  var songName:FlxText;
  var variationButton:ChartPlaytestMenuButtonListToggle;
  var difficultyButton:ChartPlaytestMenuButtonListToggle;
  var playtestButton:ChartPlaytestMenuButton;

  var currentVariation:String;
  var currentDifficulty:String;

  var playtestCam:FunkinCamera;

  public function new(filePath:String)
  {
    final targetSong:Song = FNFCUtil.loadSongFromFNFCPath(filePath);

    super();

    FlxG.state.persistentDraw = true;
    FlxG.state.persistentUpdate = false;

    playtestCam = new FunkinCamera('playtestCam');
    playtestCam.bgColor = 0x0;
    // playtestCam.alpha = 0;
    FlxG.cameras.add(playtestCam, false);

    var blackBG:FunkinSprite = new FunkinSprite(0, 0);
    blackBG.makeSolidColor(FlxG.width * 3, FlxG.height * 3, FlxColor.BLACK);
    blackBG.scrollFactor.set();
    blackBG.alpha = 0.4;
    blackBG.cameras = [playtestCam];
    add(blackBG);

    this.filePath = filePath;

    songName = new FlxText(0, FlxG.height * 0.1, 0, 'Loaded Song: ${targetSong.songName}',
      30).setFormat(Paths.font('vcr.ttf'), 50, FlxColor.WHITE, FlxTextAlign.CENTER);
    songName.screenCenter(X);
    songName.cameras = [playtestCam];
    add(songName);

    variationButton = new ChartPlaytestMenuButtonListToggle(0, FlxG.height * 0.55, "Variation", targetSong.variations, function(value:String) {
      currentVariation = value;
      variationButton.screenCenter(X);
    });
    variationButton.screenCenter(X);
    variationButton.cameras = [playtestCam];
    add(variationButton);

    difficultyButton = new ChartPlaytestMenuButtonListToggle(0, FlxG.height * 0.45, "Difficulty",
      targetSong.listDifficulties(null, targetSong.variations, true, true), function(value:String) {
        currentDifficulty = value;
        difficultyButton.screenCenter(X);
    });
    difficultyButton.screenCenter(X);
    difficultyButton.cameras = [playtestCam];
    add(difficultyButton);

    playtestButton = new ChartPlaytestMenuButton(0, FlxG.height * 0.8, "Playtest Song", function() {
      try
      {
        FNFCUtil.playSongFromFNFCPath(filePath, currentDifficulty, currentVariation);
      }
      catch (e)
      {
        lime.app.Application.current.window.alert('$e', 'Could Not Playtest Chart');
      }
    });
    playtestButton.screenCenter(X);
    playtestButton.cameras = [playtestCam];
    add(playtestButton);

    FlxTween.tween(playtestCam, {alpha: 1}, 0.5);

    #if NO_FEATURE_TOUCH_CONTROLS
    Cursor.show();
    #end
  }
}
#end
