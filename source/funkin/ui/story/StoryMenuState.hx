package funkin.ui.story;

import funkin.save.Save;
import funkin.save.Save.SaveScoreData;
import openfl.utils.Assets;
import flixel.addons.transition.FlxTransitionableState;
import flixel.FlxSprite;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.text.FlxText;
import flixel.addons.transition.FlxTransitionableState;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
import funkin.data.level.LevelRegistry;
import funkin.modding.events.ScriptEvent;
import funkin.modding.events.ScriptEventDispatcher;
import funkin.play.PlayState;
import funkin.play.PlayStatePlaylist;
import funkin.play.song.Song;
import funkin.data.song.SongData.SongMusicData;
import funkin.data.song.SongRegistry;

class StoryMenuState extends MusicBeatState
{
  static final DEFAULT_BACKGROUND_COLOR:FlxColor = FlxColor.fromString("#F9CF51");
  static final BACKGROUND_HEIGHT:Int = 400;

  var currentDifficultyId:String = 'normal';

  var currentLevelId:String = 'tutorial';
  var currentLevel:Level;
  var isLevelUnlocked:Bool;
  var currentLevelTitle:LevelTitle;

  var highScore:Int = 42069420;
  var highScoreLerp:Int = 12345678;

  var exitingMenu:Bool = false;
  var selectedLevel:Bool = false;

  var displayingModdedLevels:Bool = false;

  //
  // RENDER OBJECTS
  //

  /**
   * The title of the level at the top.
   */
  var levelTitleText:FlxText;

  /**
   * The score text at the top.
   */
  var scoreText:FlxText;

  /**
   * The mode text at the top-middle.
   */
  var modeText:FlxText;

  /**
   * The list of songs on the left.
   */
  var tracklistText:FlxText;

  /**
   * The titles of the levels in the middle.
   */
  var levelTitles:FlxTypedGroup<LevelTitle>;

  /**
   * The props in the center.
   */
  var levelProps:FlxTypedGroup<LevelProp>;

  /**
   * The background behind the props.
   */
  var levelBackground:FlxSprite;

  /**
   * The left arrow of the difficulty selector.
   */
  var leftDifficultyArrow:FlxSprite;

  /**
   * The right arrow of the difficulty selector.
   */
  var rightDifficultyArrow:FlxSprite;

  /**
   * The text of the difficulty selector.
   */
  var difficultySprite:FlxSprite;

  var difficultySprites:Map<String, FlxSprite>;

  var stickerSubState:StickerSubState;

  public function new(?stickers:StickerSubState = null)
  {
    super();

    if (stickers != null)
    {
      stickerSubState = stickers;
    }
  }

  override function create():Void
  {
    super.create();

    difficultySprites = new Map<String, FlxSprite>();

    transIn = FlxTransitionableState.defaultTransIn;
    transOut = FlxTransitionableState.defaultTransOut;

    playMenuMusic();

    if (stickerSubState != null)
    {
      this.persistentUpdate = true;
      this.persistentDraw = true;

      openSubState(stickerSubState);
      stickerSubState.degenStickers();
    }

    persistentUpdate = persistentDraw = true;

    updateData();

    // Explicitly define the background color.
    this.bgColor = FlxColor.BLACK;

    levelTitles = new FlxTypedGroup<LevelTitle>();
    levelTitles.zIndex = 15;
    add(levelTitles);

    updateBackground();

    var black:FlxSprite = new FlxSprite(levelBackground.x, 0).makeGraphic(FlxG.width, Std.int(400 + levelBackground.y), FlxColor.BLACK);
    black.zIndex = levelBackground.zIndex - 1;
    add(black);

    levelProps = new FlxTypedGroup<LevelProp>();
    levelProps.zIndex = 1000;
    add(levelProps);

    updateProps();

    tracklistText = new FlxText(FlxG.width * 0.05, levelBackground.x + levelBackground.height + 100, 0, "Tracks", 32);
    tracklistText.setFormat("VCR OSD Mono", 32);
    tracklistText.alignment = CENTER;
    tracklistText.color = 0xFFe55777;
    add(tracklistText);

    scoreText = new FlxText(10, 10, 0, 'HIGH SCORE: 42069420');
    scoreText.setFormat("VCR OSD Mono", 32);
    scoreText.zIndex = 1000;
    add(scoreText);

    modeText = new FlxText(10, 10, 0, 'Base Game Levels [TAB to switch]');
    modeText.setFormat("VCR OSD Mono", 32);
    modeText.screenCenter(X);
    modeText.visible = hasModdedLevels();
    modeText.zIndex = 1000;
    add(modeText);

    levelTitleText = new FlxText(FlxG.width * 0.7, 10, 0, 'LEVEL 1');
    levelTitleText.setFormat("VCR OSD Mono", 32, FlxColor.WHITE, RIGHT);
    levelTitleText.alpha = 0.7;
    levelTitleText.zIndex = 1000;
    add(levelTitleText);

    buildLevelTitles();

    leftDifficultyArrow = new FlxSprite(levelTitles.members[0].x + levelTitles.members[0].width + 10, levelTitles.members[0].y + 10);
    leftDifficultyArrow.frames = Paths.getSparrowAtlas('storymenu/ui/arrows');
    leftDifficultyArrow.animation.addByPrefix('idle', 'leftIdle0');
    leftDifficultyArrow.animation.addByPrefix('press', 'leftConfirm0');
    leftDifficultyArrow.animation.play('idle');
    add(leftDifficultyArrow);

    buildDifficultySprite();

    rightDifficultyArrow = new FlxSprite(difficultySprite.x + difficultySprite.width + 10, leftDifficultyArrow.y);
    rightDifficultyArrow.frames = leftDifficultyArrow.frames;
    rightDifficultyArrow.animation.addByPrefix('idle', 'rightIdle0');
    rightDifficultyArrow.animation.addByPrefix('press', 'rightConfirm0');
    rightDifficultyArrow.animation.play('idle');
    add(rightDifficultyArrow);

    add(difficultySprite);

    updateText();
    changeDifficulty();
    changeLevel();
    refresh();

    #if discord_rpc
    // Updating Discord Rich Presence
    DiscordClient.changePresence("In the Menus", null);
    #end
  }

  function playMenuMusic():Void
  {
    if (FlxG.sound.music == null || !FlxG.sound.music.playing)
    {
      var freakyMenuMetadata:Null<SongMusicData> = SongRegistry.instance.parseMusicData('freakyMenu');
      if (freakyMenuMetadata != null)
      {
        Conductor.mapTimeChanges(freakyMenuMetadata.timeChanges);
      }

      FlxG.sound.playMusic(Paths.music('freakyMenu/freakyMenu'), 0);
      FlxG.sound.music.fadeIn(4, 0, 0.7);
    }
  }

  function updateData():Void
  {
    currentLevel = LevelRegistry.instance.fetchEntry(currentLevelId);
    isLevelUnlocked = currentLevel == null ? false : currentLevel.isUnlocked();
  }

  function buildDifficultySprite():Void
  {
    remove(difficultySprite);
    difficultySprite = difficultySprites.get(currentDifficultyId);
    if (difficultySprite == null)
    {
      difficultySprite = new FlxSprite(leftDifficultyArrow.x + leftDifficultyArrow.width + 10, leftDifficultyArrow.y);

      if (Assets.exists(Paths.file('images/storymenu/difficulties/${currentDifficultyId}.xml')))
      {
        difficultySprite.frames = Paths.getSparrowAtlas('storymenu/difficulties/${currentDifficultyId}');
        difficultySprite.animation.addByPrefix('idle', 'idle0', 24, true);
        difficultySprite.animation.play('idle');
      }
      else
      {
        difficultySprite.loadGraphic(Paths.image('storymenu/difficulties/${currentDifficultyId}'));
      }

      difficultySprites.set(currentDifficultyId, difficultySprite);

      difficultySprite.x += (difficultySprites.get('normal').width - difficultySprite.width) / 2;
    }
    difficultySprite.alpha = 0;

    difficultySprite.y = leftDifficultyArrow.y - 15;
    var targetY:Float = leftDifficultyArrow.y + 10;
    targetY -= (difficultySprite.height - difficultySprites.get('normal').height) / 2;
    FlxTween.tween(difficultySprite, {y: targetY, alpha: 1}, 0.07);

    add(difficultySprite);
  }

  function buildLevelTitles():Void
  {
    levelTitles.clear();

    var levelIds:Array<String> = displayingModdedLevels ? LevelRegistry.instance.listModdedLevelIds() : LevelRegistry.instance.listBaseGameLevelIds();
    if (levelIds.length == 0) levelIds = ['tutorial']; // Make sure there's at least one level to display.

    for (levelIndex in 0...levelIds.length)
    {
      var levelId:String = levelIds[levelIndex];
      var level:Level = LevelRegistry.instance.fetchEntry(levelId);
      if (level == null) continue;

      var levelTitleItem:LevelTitle = new LevelTitle(0, Std.int(levelBackground.y + levelBackground.height + 10), level);
      levelTitleItem.targetY = ((levelTitleItem.height + 20) * levelIndex);
      levelTitleItem.screenCenter(X);
      levelTitles.add(levelTitleItem);
    }
  }

  function switchMode(moddedLevels:Bool):Void
  {
    displayingModdedLevels = moddedLevels;
    buildLevelTitles();

    changeLevel(999999); // Jump past the end of the list to the beginning.
    changeDifficulty(0);
  }

  override function update(elapsed:Float)
  {
    Conductor.update();

    highScoreLerp = Std.int(CoolUtil.coolLerp(highScoreLerp, highScore, 0.5));

    scoreText.text = 'LEVEL SCORE: ${Math.round(highScoreLerp)}';

    modeText.text = displayingModdedLevels ? 'Mods [TAB to switch]' : 'Base Game [TAB to switch]';
    modeText.screenCenter(X);

    levelTitleText.text = currentLevel.getTitle();
    levelTitleText.x = FlxG.width - (levelTitleText.width + 10); // Right align.

    handleKeyPresses();

    super.update(elapsed);
  }

  function handleKeyPresses():Void
  {
    if (!exitingMenu)
    {
      if (!selectedLevel)
      {
        if (controls.UI_UP_P)
        {
          changeLevel(-1);
          changeDifficulty(0);
        }

        if (controls.UI_DOWN_P)
        {
          changeLevel(1);
          changeDifficulty(0);
        }

        if (controls.UI_RIGHT)
        {
          rightDifficultyArrow.animation.play('press');
        }
        else
        {
          rightDifficultyArrow.animation.play('idle');
        }

        if (controls.UI_LEFT)
        {
          leftDifficultyArrow.animation.play('press');
        }
        else
        {
          leftDifficultyArrow.animation.play('idle');
        }

        if (controls.UI_RIGHT_P)
        {
          changeDifficulty(1);
        }

        if (controls.UI_LEFT_P)
        {
          changeDifficulty(-1);
        }

        if (FlxG.keys.justPressed.TAB && modeText.visible)
        {
          switchMode(!displayingModdedLevels);
        }
      }

      if (controls.ACCEPT)
      {
        selectLevel();
      }
    }

    if (controls.BACK && !exitingMenu && !selectedLevel)
    {
      FlxG.sound.play(Paths.sound('cancelMenu'));
      exitingMenu = true;
      FlxG.switchState(new MainMenuState());
    }
  }

  function hasModdedLevels():Bool
  {
    return LevelRegistry.instance.listModdedLevelIds().length > 0;
  }

  /**
   * Changes the selected level.
   * @param change +1 (down), -1 (up)
   */
  function changeLevel(change:Int = 0):Void
  {
    var levelList:Array<String> = displayingModdedLevels ? LevelRegistry.instance.listModdedLevelIds() : LevelRegistry.instance.listBaseGameLevelIds();
    if (levelList.length == 0) levelList = ['tutorial'];

    var currentIndex:Int = levelList.indexOf(currentLevelId);

    currentIndex += change;

    // Wrap around
    if (currentIndex < 0) currentIndex = levelList.length - 1;
    if (currentIndex >= levelList.length) currentIndex = 0;

    var previousLevelId:String = currentLevelId;
    currentLevelId = levelList[currentIndex];

    updateData();

    for (index in 0...levelTitles.members.length)
    {
      var item:LevelTitle = levelTitles.members[index];

      item.targetY = (index - currentIndex) * 120 + 480;

      if (index == currentIndex)
      {
        currentLevelTitle = item;
        item.alpha = 1.0;
      }
      else
      {
        item.alpha = 0.6;
      }
    }

    updateText();
    updateBackground(previousLevelId);
    updateProps();
    refresh();
  }

  /**
   * Changes the selected difficulty.
   * @param change +1 (right) to increase difficulty, -1 (left) to decrease difficulty
   */
  function changeDifficulty(change:Int = 0):Void
  {
    var difficultyList:Array<String> = currentLevel.getDifficulties();
    var currentIndex:Int = difficultyList.indexOf(currentDifficultyId);

    currentIndex += change;

    // Wrap around
    if (currentIndex < 0) currentIndex = difficultyList.length - 1;
    if (currentIndex >= difficultyList.length) currentIndex = 0;

    var hasChanged:Bool = currentDifficultyId != difficultyList[currentIndex];
    currentDifficultyId = difficultyList[currentIndex];

    if (difficultyList.length <= 1)
    {
      leftDifficultyArrow.visible = false;
      rightDifficultyArrow.visible = false;
    }
    else
    {
      leftDifficultyArrow.visible = true;
      rightDifficultyArrow.visible = true;
    }

    if (hasChanged)
    {
      buildDifficultySprite();
      funnyMusicThing();
    }
  }

  final FADE_OUT_TIME:Float = 1.5;

  function funnyMusicThing():Void
  {
    if (currentDifficultyId == "nightmare")
    {
      FlxG.sound.music.fadeOut(FADE_OUT_TIME, 0.0);
    }
    else
    {
      FlxG.sound.music.fadeOut(FADE_OUT_TIME, 1.0);
    }
  }

  public override function dispatchEvent(event:ScriptEvent):Void
  {
    // super.dispatchEvent(event) dispatches event to module scripts.
    super.dispatchEvent(event);

    if (levelProps != null && levelProps.length > 0)
    {
      // Dispatch event to props.
      for (prop in levelProps)
      {
        ScriptEventDispatcher.callEvent(prop, event);
      }
    }
  }

  function selectLevel()
  {
    if (!currentLevel.isUnlocked())
    {
      FlxG.sound.play(Paths.sound('cancelMenu'));
      return;
    }

    if (selectedLevel) return;

    selectedLevel = true;

    FlxG.sound.play(Paths.sound('confirmMenu'));

    currentLevelTitle.isFlashing = true;

    for (prop in levelProps.members)
    {
      prop.playConfirm();
    }

    Paths.setCurrentLevel(currentLevel.id);

    PlayStatePlaylist.playlistSongIds = currentLevel.getSongs();
    PlayStatePlaylist.isStoryMode = true;
    PlayStatePlaylist.campaignScore = 0;

    var targetSongId:String = PlayStatePlaylist.playlistSongIds.shift();

    var targetSong:Song = SongRegistry.instance.fetchEntry(targetSongId);

    PlayStatePlaylist.campaignId = currentLevel.id;
    PlayStatePlaylist.campaignTitle = currentLevel.getTitle();

    if (targetSong != null)
    {
      // Load and cache the song's charts.
      // TODO: Do this in the loading state.
      targetSong.cacheCharts(true);
    }

    new FlxTimer().start(1, function(tmr:FlxTimer) {
      FlxTransitionableState.skipNextTransIn = false;
      FlxTransitionableState.skipNextTransOut = false;

      LoadingState.loadAndSwitchState(new PlayState(
        {
          targetSong: targetSong,
          targetDifficulty: currentDifficultyId,
        }), true);
    });
  }

  function updateBackground(?previousLevelId:String = ''):Void
  {
    if (levelBackground == null || previousLevelId == '')
    {
      // Build a new background and display it immediately.
      levelBackground = currentLevel.buildBackground();
      levelBackground.x = 0;
      levelBackground.y = 56;
      levelBackground.zIndex = 100;
      levelBackground.alpha = 1.0; // Not hidden.
      add(levelBackground);
    }
    else
    {
      var previousLevel = LevelRegistry.instance.fetchEntry(previousLevelId);

      if (currentLevel.isBackgroundSimple() && previousLevel.isBackgroundSimple())
      {
        var previousColor:FlxColor = previousLevel.getBackgroundColor();
        var currentColor:FlxColor = currentLevel.getBackgroundColor();
        if (previousColor != currentColor)
        {
          // Both the previous and current level were simple backgrounds.
          // Fade between colors directly, rather than fading one background out and another in.
          FlxTween.color(levelBackground, 0.4, previousColor, currentColor);
        }
        else
        {
          // Do no fade at all if the colors aren't different.
        }
      }
      else
      {
        // Either the previous or current level has a complex background.
        // We need to fade the old background out and the new one in.

        // Reference the old background and fade it out.
        var oldBackground:FlxSprite = levelBackground;
        FlxTween.tween(oldBackground, {alpha: 0.0}, 0.6,
          {
            ease: FlxEase.linear,
            onComplete: function(_) {
              remove(oldBackground);
            }
          });

        // Build a new background and fade it in.
        levelBackground = currentLevel.buildBackground();
        levelBackground.x = 0;
        levelBackground.y = 56;
        levelBackground.alpha = 0.0; // Hidden to start.
        levelBackground.zIndex = 100;
        add(levelBackground);

        FlxTween.tween(levelBackground, {alpha: 1.0}, 0.6,
          {
            ease: FlxEase.linear
          });
      }
    }
  }

  function updateProps():Void
  {
    levelProps.clear();
    for (prop in currentLevel.buildProps())
    {
      prop.zIndex = 1000;
      levelProps.add(prop);
    }

    refresh();
  }

  function updateText():Void
  {
    tracklistText.text = 'TRACKS\n\n';
    tracklistText.text += currentLevel.getSongDisplayNames(currentDifficultyId).join('\n');

    tracklistText.screenCenter(X);
    tracklistText.x -= FlxG.width * 0.35;

    var levelScore:Null<SaveScoreData> = Save.get().getLevelScore(currentLevelId, currentDifficultyId);
    highScore = levelScore?.score ?? 0;
    // levelScore.accuracy
  }
}
