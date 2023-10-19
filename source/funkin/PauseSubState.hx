package funkin;

import funkin.play.PlayStatePlaylist;
import flixel.FlxSprite;
import flixel.addons.transition.FlxTransitionableState;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.sound.FlxSound;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import funkin.play.PlayState;
import funkin.data.song.SongRegistry;

class PauseSubState extends MusicBeatSubState
{
  var grpMenuShit:FlxTypedGroup<Alphabet>;

  final pauseOptionsBase:Array<String> = [
    'Resume',
    'Restart Song',
    'Change Difficulty',
    'Toggle Practice Mode',
    'Exit to Menu'
  ];
  final pauseOptionsCharting:Array<String> = ['Resume', 'Restart Song', 'Exit to Chart Editor'];

  final pauseOptionsDifficultyBase:Array<String> = ['BACK'];

  var pauseOptionsDifficulty:Array<String> = []; // AUTO-POPULATED

  var menuItems:Array<String> = [];
  var curSelected:Int = 0;

  var pauseMusic:FlxSound;

  var practiceText:FlxText;

  var exitingToMenu:Bool = false;
  var bg:FlxSprite;
  var metaDataGrp:FlxTypedGroup<FlxSprite>;

  var isChartingMode:Bool;

  public function new(isChartingMode:Bool = false)
  {
    super();

    this.isChartingMode = isChartingMode;

    menuItems = this.isChartingMode ? pauseOptionsCharting : pauseOptionsBase;
    var difficultiesInVariation = PlayState.instance.currentSong.listDifficulties(PlayState.instance.currentChart.variation);
    trace('DIFFICULTIES: ${difficultiesInVariation}');

    pauseOptionsDifficulty = difficultiesInVariation.map(function(item:String):String {
      return item.toUpperCase();
    }).concat(pauseOptionsDifficultyBase);

    if (PlayStatePlaylist.campaignId == 'week6')
    {
      pauseMusic = new FlxSound().loadEmbedded(Paths.music('breakfast-pixel'), true, true);
    }
    else
    {
      pauseMusic = new FlxSound().loadEmbedded(Paths.music('breakfast'), true, true);
    }
    pauseMusic.volume = 0;
    pauseMusic.play(false, FlxG.random.int(0, Std.int(pauseMusic.length / 2)));

    FlxG.sound.list.add(pauseMusic);

    bg = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
    bg.alpha = 0;
    bg.scrollFactor.set();
    add(bg);

    metaDataGrp = new FlxTypedGroup<FlxSprite>();
    add(metaDataGrp);

    var levelInfo:FlxText = new FlxText(20, 15, 0, '', 32);
    if (PlayState.instance.currentChart != null)
    {
      levelInfo.text += '${PlayState.instance.currentChart.songName} - ${PlayState.instance.currentChart.songArtist}';
    }
    levelInfo.scrollFactor.set();
    levelInfo.setFormat(Paths.font('vcr.ttf'), 32);
    levelInfo.updateHitbox();
    metaDataGrp.add(levelInfo);

    var levelDifficulty:FlxText = new FlxText(20, 15 + 32, 0, '', 32);
    levelDifficulty.text += PlayState.instance.currentDifficulty.toTitleCase();
    levelDifficulty.scrollFactor.set();
    levelDifficulty.setFormat(Paths.font('vcr.ttf'), 32);
    levelDifficulty.updateHitbox();
    metaDataGrp.add(levelDifficulty);

    var deathCounter:FlxText = new FlxText(20, 15 + 64, 0, '', 32);
    deathCounter.text = 'Blue balled: ${PlayState.instance.deathCounter}';
    FlxG.watch.addQuick('totalNotesHit', Highscore.tallies.totalNotesHit);
    FlxG.watch.addQuick('totalNotes', Highscore.tallies.totalNotes);
    deathCounter.scrollFactor.set();
    deathCounter.setFormat(Paths.font('vcr.ttf'), 32);
    deathCounter.updateHitbox();
    metaDataGrp.add(deathCounter);

    practiceText = new FlxText(20, 15 + 64 + 32, 0, 'PRACTICE MODE', 32);
    practiceText.scrollFactor.set();
    practiceText.setFormat(Paths.font('vcr.ttf'), 32);
    practiceText.updateHitbox();
    practiceText.x = FlxG.width - (practiceText.width + 20);
    practiceText.visible = PlayState.instance.isPracticeMode;
    metaDataGrp.add(practiceText);

    levelDifficulty.alpha = 0;
    levelInfo.alpha = 0;
    deathCounter.alpha = 0;

    levelInfo.x = FlxG.width - (levelInfo.width + 20);
    levelDifficulty.x = FlxG.width - (levelDifficulty.width + 20);
    deathCounter.x = FlxG.width - (deathCounter.width + 20);

    FlxTween.tween(bg, {alpha: 0.6}, 0.4, {ease: FlxEase.quartInOut});
    FlxTween.tween(levelInfo, {alpha: 1, y: 20}, 0.4, {ease: FlxEase.quartInOut, startDelay: 0.3});
    FlxTween.tween(levelDifficulty, {alpha: 1, y: levelDifficulty.y + 5}, 0.4, {ease: FlxEase.quartInOut, startDelay: 0.5});
    FlxTween.tween(deathCounter, {alpha: 1, y: deathCounter.y + 5}, 0.4, {ease: FlxEase.quartInOut, startDelay: 0.7});

    grpMenuShit = new FlxTypedGroup<Alphabet>();
    add(grpMenuShit);

    regenMenu();

    // cameras = [FlxG.cameras.list[FlxG.cameras.list.length - 1]];
  }

  function regenMenu():Void
  {
    while (grpMenuShit.members.length > 0)
    {
      grpMenuShit.remove(grpMenuShit.members[0], true);
    }

    for (i in 0...menuItems.length)
    {
      var songText:Alphabet = new Alphabet(0, (70 * i) + 30, menuItems[i], true, false);
      songText.isMenuItem = true;
      songText.targetY = i;
      grpMenuShit.add(songText);
    }

    curSelected = 0;
    changeSelection();
  }

  override function update(elapsed:Float):Void
  {
    if (pauseMusic.volume < 0.5) pauseMusic.volume += 0.01 * elapsed;

    super.update(elapsed);

    handleInputs();
  }

  function handleInputs():Void
  {
    var upP = controls.UI_UP_P;
    var downP = controls.UI_DOWN_P;
    var accepted = controls.ACCEPT;

    #if debug
    // to pause the game and get screenshots easy, press H on pause menu!
    if (FlxG.keys.justPressed.H)
    {
      bg.visible = !bg.visible;
      grpMenuShit.visible = !grpMenuShit.visible;
      metaDataGrp.visible = !metaDataGrp.visible;
    }
    #end

    if (!exitingToMenu)
    {
      if (upP)
      {
        changeSelection(-1);
      }
      if (downP)
      {
        changeSelection(1);
      }

      var androidPause:Bool = false;

      #if android
      androidPause = FlxG.android.justPressed.BACK;
      #end

      if (androidPause) close();

      if (accepted)
      {
        var daSelected:String = menuItems[curSelected];

        switch (daSelected)
        {
          case 'Resume':
            close();

          case 'Change Difficulty':
            menuItems = pauseOptionsDifficulty;
            regenMenu();

          case 'Toggle Practice Mode':
            PlayState.instance.isPracticeMode = true;
            practiceText.visible = PlayState.instance.isPracticeMode;

          case 'Restart Song':
            PlayState.instance.needsReset = true;
            close();

          case 'Exit to Menu':
            exitingToMenu = true;
            PlayState.instance.deathCounter = 0;

            for (item in grpMenuShit.members)
            {
              item.targetY = -3;
              item.alpha = 0.6;
            }

            FlxTransitionableState.skipNextTransIn = true;
            FlxTransitionableState.skipNextTransOut = true;

            if (PlayStatePlaylist.isStoryMode)
            {
              openSubState(new funkin.ui.StickerSubState(null, STORY));
            }
            else
            {
              openSubState(new funkin.ui.StickerSubState(null, FREEPLAY));
            }

          case 'Exit to Chart Editor':
            this.close();
            if (FlxG.sound.music != null) FlxG.sound.music.pause(); // Don't reset song position!
            PlayState.instance.close(); // This only works because PlayState is a substate!

          case 'BACK':
            menuItems = this.isChartingMode ? pauseOptionsCharting : pauseOptionsBase;
            regenMenu();

          default:
            if (pauseOptionsDifficulty.contains(daSelected))
            {
              PlayState.instance.currentSong = SongRegistry.instance.fetchEntry(PlayState.instance.currentSong.id.toLowerCase());

              // Reset campaign score when changing difficulty
              // So if you switch difficulty on the last song of a week you get a really low overall score.
              PlayStatePlaylist.campaignScore = 0;
              PlayStatePlaylist.campaignDifficulty = daSelected.toLowerCase();
              PlayState.instance.currentDifficulty = PlayStatePlaylist.campaignDifficulty;

              PlayState.instance.needsReset = true;

              close();
            }
            else
            {
              trace('[WARN] Unhandled pause menu option: ${daSelected}');
            }
        }
      }

      if (FlxG.keys.justPressed.J)
      {
        // for reference later!
        // PlayerSettings.player1.controls.replaceBinding(Control.LEFT, Keys, FlxKey.J, null);
      }
    }
  }

  override function destroy():Void
  {
    pauseMusic.destroy();

    super.destroy();
  }

  function changeSelection(change:Int = 0):Void
  {
    FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);

    curSelected += change;

    if (curSelected < 0) curSelected = menuItems.length - 1;
    if (curSelected >= menuItems.length) curSelected = 0;

    for (index => item in grpMenuShit.members)
    {
      item.targetY = index - curSelected;

      item.alpha = 0.6;

      if (item.targetY == 0)
      {
        item.alpha = 1;
      }
    }
  }
}
