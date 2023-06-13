package funkin;

import flixel.FlxSprite;
import flixel.graphics.frames.FlxAtlasFrames;
import funkin.play.PlayState;

class GitarooPause extends MusicBeatState
{
  var replayButton:FlxSprite;
  var cancelButton:FlxSprite;

  var replaySelect:Bool = false;

  var previousParams:PlayStateParams;

  public function new(previousParams:PlayStateParams):Void
  {
    super();

    this.previousParams = previousParams;
  }

  override function create():Void
  {
    if (FlxG.sound.music != null) FlxG.sound.music.stop();

    var bg:FlxSprite = new FlxSprite().loadGraphic(Paths.image('pauseAlt/pauseBG'));
    add(bg);

    var bf:FlxSprite = new FlxSprite(0, 30);
    bf.frames = Paths.getSparrowAtlas('pauseAlt/bfLol');
    bf.animation.addByPrefix('lol', "funnyThing", 13);
    bf.animation.play('lol');
    add(bf);
    bf.screenCenter(X);

    replayButton = new FlxSprite(FlxG.width * 0.28, FlxG.height * 0.7);
    replayButton.frames = Paths.getSparrowAtlas('pauseAlt/pauseUI');
    replayButton.animation.addByPrefix('selected', 'bluereplay', 0, false);
    replayButton.animation.appendByPrefix('selected', 'yellowreplay');
    replayButton.animation.play('selected');
    add(replayButton);

    cancelButton = new FlxSprite(FlxG.width * 0.58, replayButton.y);
    cancelButton.frames = Paths.getSparrowAtlas('pauseAlt/pauseUI');
    cancelButton.animation.addByPrefix('selected', 'bluecancel', 0, false);
    cancelButton.animation.appendByPrefix('selected', 'cancelyellow');
    cancelButton.animation.play('selected');
    add(cancelButton);

    changeThing();

    super.create();
  }

  override function update(elapsed:Float):Void
  {
    if (controls.UI_LEFT_P || controls.UI_RIGHT_P) changeThing();

    if (controls.ACCEPT)
    {
      if (replaySelect)
      {
        FlxG.switchState(new PlayState(previousParams));
      }
      else
      {
        FlxG.switchState(new MainMenuState());
      }
    }

    super.update(elapsed);
  }

  function changeThing():Void
  {
    replaySelect = !replaySelect;

    if (replaySelect)
    {
      cancelButton.animation.curAnim.curFrame = 0;
      replayButton.animation.curAnim.curFrame = 1;
    }
    else
    {
      cancelButton.animation.curAnim.curFrame = 1;
      replayButton.animation.curAnim.curFrame = 0;
    }
  }
}
