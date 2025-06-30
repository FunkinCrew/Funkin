package funkin.ui.story;

import flixel.addons.transition.FlxTransitionableState;
import flixel.FlxSprite;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
import funkin.audio.FunkinSound;
import funkin.data.story.level.LevelRegistry;
import funkin.data.song.SongRegistry;
import funkin.graphics.FunkinSprite;
import funkin.modding.events.ScriptEvent;
import funkin.modding.events.ScriptEventDispatcher;
import funkin.play.PlayStatePlaylist;
import funkin.play.song.Song;
import funkin.save.Save;
import funkin.save.Save.SaveScoreData;
import funkin.ui.mainmenu.MainMenuState;
import funkin.ui.MusicBeatState;
import funkin.ui.transition.LoadingState;
import funkin.ui.transition.stickers.StickerSubState;
import funkin.util.MathUtil;
import funkin.util.SwipeUtil;
import funkin.util.TouchUtil;
import openfl.utils.Assets;
import funkin.ui.FullScreenScaleMode;
#if FEATURE_DISCORD_RPC
import funkin.api.discord.DiscordClient;
#end

class StoryMenuState extends MusicBeatState
{
  static final DEFAULT_BACKGROUND_COLOR:FlxColor = FlxColor.fromString('#F9CF51');
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

  /**
   * List of available level IDs.
   */
  var levelList:Array<String> = [];

  var difficultySprites:Map<String, FlxSprite>;

  var stickerSubState:StickerSubState;

  static var rememberedLevelId:Null<String> = null;
  static var rememberedDifficulty:Null<String> = Constants.DEFAULT_DIFFICULTY;

  public function new(?stickers:StickerSubState = null)
  {
    super();

    if (stickers?.members != null)
    {
      stickerSubState = stickers;
    }
  }

  override function create():Void
  {
    super.create();

    levelList = LevelRegistry.instance.listSortedLevelIds();
    levelList = levelList.filter(function(id) {
      var levelData = LevelRegistry.instance.fetchEntry(id);
      if (levelData == null) return false;

      return levelData.isVisible();
    });
    if (levelList.length == 0) levelList = ['tutorial']; // Make sure there's at least one level to display.

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

    rememberSelection();

    updateData();

    levelTitles = new FlxTypedGroup<LevelTitle>();
    levelTitles.zIndex = 15;
    add(levelTitles);

    updateBackground();

    var black:FunkinSprite = new FunkinSprite(levelBackground.x, 0).makeSolidColor(FlxG.width, Std.int(400 + levelBackground.y), FlxColor.BLACK);
    black.zIndex = levelBackground.zIndex - 1;
    add(black);

    levelProps = new FlxTypedGroup<LevelProp>();
    levelProps.zIndex = 1000;
    add(levelProps);

    updateProps();

    tracklistText = new FlxText(FlxG.width * 0.05, levelBackground.x + levelBackground.height + 100, 0, "Tracks", 32);
    tracklistText.setFormat('VCR OSD Mono', 32);
    tracklistText.alignment = CENTER;
    tracklistText.color = 0xFFE55777;
    add(tracklistText);

    scoreText = new FlxText(Math.max(FullScreenScaleMode.gameNotchSize.x, 10), 10, 0, 'HIGH SCORE: 42069420');
    scoreText.setFormat('VCR OSD Mono', 32);
    scoreText.zIndex = 1000;
    add(scoreText);

    levelTitleText = new FlxText(Math.max((FlxG.width * 0.7), FlxG.width - FullScreenScaleMode.gameNotchSize.x), 10, 0, 'LEVEL 1');
    levelTitleText.setFormat('VCR OSD Mono', 32, FlxColor.WHITE, RIGHT);
    levelTitleText.alpha = 0.7;
    levelTitleText.zIndex = 1000;
    add(levelTitleText);

    buildLevelTitles();

    final useNotch:Bool = Math.max(35, FullScreenScaleMode.gameNotchSize.x) != 35;
    leftDifficultyArrow = new FlxSprite(FlxG.width - (useNotch ? (FullScreenScaleMode.gameNotchSize.x) + 410 : 410), 480);
    leftDifficultyArrow.frames = Paths.getSparrowAtlas('storymenu/ui/arrows');
    leftDifficultyArrow.animation.addByPrefix('idle', 'leftIdle0');
    leftDifficultyArrow.animation.addByPrefix('press', 'leftConfirm0');
    leftDifficultyArrow.animation.play('idle');
    add(leftDifficultyArrow);

    buildDifficultySprite(Constants.DEFAULT_DIFFICULTY);
    buildDifficultySprite();

    rightDifficultyArrow = new FlxSprite(FlxG.width - (useNotch ? FullScreenScaleMode.gameNotchSize.x * 1.5 : 35), leftDifficultyArrow.y);
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

    #if FEATURE_DISCORD_RPC
    // Updating Discord Rich Presence
    DiscordClient.instance.setPresence({state: 'In the Menus', details: null});
    #end

    #if mobile
    addBackButton(FlxG.width - 230, FlxG.height - 170, FlxColor.WHITE, goBack, 0.7);
    #end

    #if FEATURE_TOUCH_CONTROLS
    FlxG.touches.swipeThreshold.y = 100;
    #end
  }

  function rememberSelection():Void
  {
    if (rememberedLevelId != null)
    {
      currentLevelId = rememberedLevelId;
    }
    if (rememberedDifficulty != null)
    {
      currentDifficultyId = rememberedDifficulty;
    }
  }

  function playMenuMusic():Void
  {
    FunkinSound.playMusic('freakyMenu',
      {
        overrideExisting: true,
        restartTrack: false,
        // Continue playing this music between states, until a different music track gets played.
        persist: true
      });
  }

  function updateData():Void
  {
    currentLevel = LevelRegistry.instance.fetchEntry(currentLevelId);
    if (currentLevel == null) throw 'Could not fetch data for level: ${currentLevelId}';
    isLevelUnlocked = currentLevel == null ? false : currentLevel.isUnlocked();
  }

  function buildDifficultySprite(?diff:String):Void
  {
    if (diff == null) diff = currentDifficultyId;
    remove(difficultySprite);
    difficultySprite = difficultySprites.get(diff);
    if (difficultySprite == null)
    {
      difficultySprite = new FlxSprite(leftDifficultyArrow.x + leftDifficultyArrow.width + 10, leftDifficultyArrow.y);

      if (Assets.exists(Paths.file('images/storymenu/difficulties/${diff}.xml')))
      {
        difficultySprite.frames = Paths.getSparrowAtlas('storymenu/difficulties/${diff}');
        difficultySprite.animation.addByPrefix('idle', 'idle0', 24, true);
        if (Preferences.flashingLights) difficultySprite.animation.play('idle');
      }
      else
      {
        difficultySprite.loadGraphic(Paths.image('storymenu/difficulties/${diff}'));
      }

      difficultySprites.set(diff, difficultySprite);

      difficultySprite.x += (difficultySprites.get(Constants.DEFAULT_DIFFICULTY).width - difficultySprite.width) / 2;
    }
    difficultySprite.alpha = 0;

    difficultySprite.y = leftDifficultyArrow.y - 15;
    var targetY:Float = leftDifficultyArrow.y + 10;
    targetY -= (difficultySprite.height - difficultySprites.get(Constants.DEFAULT_DIFFICULTY).height) / 2;
    FlxTween.tween(difficultySprite, {y: targetY, alpha: 1}, 0.07);

    add(difficultySprite);
  }

  function buildLevelTitles():Void
  {
    levelTitles.clear();

    for (levelIndex in 0...levelList.length)
    {
      var levelId:String = levelList[levelIndex];
      var level:Level = LevelRegistry.instance.fetchEntry(levelId);
      if (level == null || !level.isVisible()) continue;

      // TODO: Readd lock icon if unlocked is false.

      var levelTitleItem:LevelTitle = new LevelTitle(0, Std.int(levelBackground.y + levelBackground.height + 10), level);
      levelTitleItem.targetY = ((levelTitleItem.height + 20) * levelIndex);
      levelTitleItem.screenCenter(X);
      levelTitles.add(levelTitleItem);
    }
  }

  override function update(elapsed:Float):Void
  {
    Conductor.instance.update();

    highScoreLerp = Std.int(MathUtil.snap(MathUtil.smoothLerpPrecision(highScoreLerp, highScore, elapsed, 0.307), highScore, 1));

    scoreText.text = 'LEVEL SCORE: ${Math.round(highScoreLerp)}';

    levelTitleText.text = currentLevel.getTitle();

    levelTitleText.x = FlxG.width - (levelTitleText.width + Math.max(10, FullScreenScaleMode.gameNotchSize.x)); // Right align.

    handleKeyPresses();

    super.update(elapsed);
  }

  function handleKeyPresses():Void
  {
    if (!exitingMenu)
    {
      if (!selectedLevel)
      {
        if (controls.UI_UP_P || SwipeUtil.swipeUp)
        {
          changeLevel(-1);
          changeDifficulty(0);
        }

        if (controls.UI_DOWN_P || SwipeUtil.swipeDown)
        {
          changeLevel(1);
          changeDifficulty(0);
        }

        #if !html5
        if (FlxG.mouse.wheel != 0)
        {
          changeLevel(-Math.round(FlxG.mouse.wheel));
        }
        #else
        if (FlxG.mouse.wheel < 0)
        {
          changeLevel(-Math.round(FlxG.mouse.wheel / 8));
        }
        else if (FlxG.mouse.wheel > 0)
        {
          changeLevel(-Math.round(FlxG.mouse.wheel / 8));
        }
        #end

        // TODO: Querying UI_RIGHT_P (justPressed) after UI_RIGHT always returns false. Fix it!
        if (controls.UI_RIGHT_P #if FEATURE_TOUCH_CONTROLS
          || (SwipeUtil.swipeRight && TouchUtil.touch != null && TouchUtil.touch.deltaViewY < 10 && TouchUtil.touch.deltaViewY > -10)
          || (TouchUtil.pressAction(rightDifficultyArrow, null, false)) #end)
        {
          #if FEATURE_TOUCH_CONTROLS
          @:privateAccess
          if (TouchUtil.touch != null
            && !TouchUtil.pressAction(rightDifficultyArrow, null, false)) TouchUtil.touch._startY = TouchUtil.touch.viewY;
          #end
          changeDifficulty(1);
        }

        if (controls.UI_LEFT_P #if FEATURE_TOUCH_CONTROLS
          || (SwipeUtil.swipeLeft && TouchUtil.touch != null && TouchUtil.touch.deltaViewY < 10 && TouchUtil.touch.deltaViewY > -10)
          || (TouchUtil.pressAction(leftDifficultyArrow, null, false)) #end)
        {
          #if FEATURE_TOUCH_CONTROLS
          @:privateAccess
          if (TouchUtil.touch != null
            && !TouchUtil.pressAction(leftDifficultyArrow, null, false)) TouchUtil.touch._startY = TouchUtil.touch.viewY;
          #end
          changeDifficulty(-1);
        }

        if (controls.UI_RIGHT #if FEATURE_TOUCH_CONTROLS || TouchUtil.overlaps(rightDifficultyArrow) #end)
        {
          rightDifficultyArrow.animation.play('press');
        }
        else
        {
          rightDifficultyArrow.animation.play('idle');
        }

        if (controls.UI_LEFT #if FEATURE_TOUCH_CONTROLS || TouchUtil.overlaps(leftDifficultyArrow) #end)
        {
          leftDifficultyArrow.animation.play('press');
        }
        else
        {
          leftDifficultyArrow.animation.play('idle');
        }
      }

      if (controls.ACCEPT)
      {
        selectLevel();
      }

      #if FEATURE_TOUCH_CONTROLS
      if (TouchUtil.justReleased && !TouchUtil.overlaps(leftDifficultyArrow) && !SwipeUtil.justSwipedAny)
      {
        for (i in 0...levelTitles.members.length)
        {
          final item = levelTitles.members[i];
          final selectedItem = levelTitles.members[levelList.indexOf(currentLevelId)];

          if (!TouchUtil.pressAction(item, null, false)) continue;

          (item == selectedItem) ? selectLevel() : changeLevel(i - levelList.indexOf(currentLevelId));
        }
      }
      #end
    }

    if (controls.BACK) goBack();
  }

  /**
   * Changes the selected level.
   * @param change +1 (down), -1 (up)
   */
  function changeLevel(change:Int = 0):Void
  {
    var currentIndex:Int = levelList.indexOf(currentLevelId);
    var prevIndex:Int = currentIndex;

    currentIndex += change;

    #if FEATURE_TOUCH_CONTROLS
    // Dont wrap around w/ touch.
    if (currentIndex < 0) currentIndex = 0;
    if (currentIndex >= levelList.length) currentIndex = levelList.length - 1;
    #else
    // Wrap around
    if (currentIndex < 0) currentIndex = levelList.length - 1;
    if (currentIndex >= levelList.length) currentIndex = 0;
    #end

    var previousLevelId:String = currentLevelId;
    currentLevelId = levelList[currentIndex];
    rememberedLevelId = currentLevelId;

    updateData();

    for (index in 0...levelTitles.members.length)
    {
      var item:LevelTitle = levelTitles.members[index];

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

    if (currentIndex != prevIndex) FunkinSound.playOnce(Paths.sound('scrollMenu'), 0.4);

    repositionTitles();
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
    // "For now, NO erect in story mode" -Dave

    var difficultyList:Array<String> = Constants.DEFAULT_DIFFICULTY_LIST;
    // Use this line to displays all difficulties
    // var difficultyList:Array<String> = currentLevel.getDifficulties();
    var currentIndex:Int = difficultyList.indexOf(currentDifficultyId);

    currentIndex += change;

    // Wrap around
    if (currentIndex < 0) currentIndex = difficultyList.length - 1;
    if (currentIndex >= difficultyList.length) currentIndex = 0;

    var hasChanged:Bool = currentDifficultyId != difficultyList[currentIndex];
    currentDifficultyId = difficultyList[currentIndex];
    rememberedDifficulty = currentDifficultyId;

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
      FunkinSound.playOnce(Paths.sound('scrollMenu'), 0.4);
      // Disable the funny music thing for now.
      // funnyMusicThing();
    }

    updateText();
    refresh();
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

    if (levelProps?.members != null && levelProps.members.length > 0)
    {
      // Dispatch event to props.
      for (prop in levelProps.members)
      {
        ScriptEventDispatcher.callEvent(prop, event);
      }
    }
  }

  function selectLevel():Void
  {
    if (!currentLevel.isUnlocked())
    {
      FunkinSound.playOnce(Paths.sound('cancelMenu'));
      return;
    }

    if (selectedLevel) return;

    selectedLevel = true;

    FunkinSound.playOnce(Paths.sound('confirmMenu'));

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
    PlayStatePlaylist.campaignDifficulty = currentDifficultyId;

    Highscore.talliesLevel = new funkin.Highscore.Tallies();

    new FlxTimer().start(1, function(tmr:FlxTimer) {
      FlxTransitionableState.skipNextTransIn = false;
      FlxTransitionableState.skipNextTransOut = false;

      var targetVariation:String = targetSong.getFirstValidVariation(PlayStatePlaylist.campaignDifficulty);

      LoadingState.loadPlayState(
        {
          targetSong: targetSong,
          targetDifficulty: PlayStatePlaylist.campaignDifficulty,
          targetVariation: targetVariation
        }, true);
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
          // cancels potential tween in progress, and tweens from there
          FlxTween.cancelTweensOf(levelBackground);
          FlxTween.color(levelBackground, 0.9, levelBackground.color, currentColor, {ease: FlxEase.quartOut});
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
    for (ind => prop in currentLevel.buildProps(levelProps.members))
    {
      prop.x += (FullScreenScaleMode.gameCutoutSize.x / 4);
      prop.zIndex = 1000;
      if (levelProps.members[ind] != prop) levelProps.replace(levelProps.members[ind], prop) ?? levelProps.add(prop);
    }

    refresh();
  }

  function updateText():Void
  {
    tracklistText.text = 'TRACKS\n\n';
    tracklistText.text += currentLevel.getSongDisplayNames(currentDifficultyId).join('\n');

    tracklistText.screenCenter(X);
    tracklistText.x -= (FlxG.width * 0.35);

    var levelScore:Null<SaveScoreData> = Save.instance.getLevelScore(currentLevelId, currentDifficultyId);
    highScore = levelScore?.score ?? 0;
    // levelScore.accuracy
  }

  function goBack():Void
  {
    if (exitingMenu || selectedLevel) return;

    exitingMenu = true;
    FlxG.switchState(() -> new MainMenuState());
    FunkinSound.playOnce(Paths.sound('cancelMenu'));
  }

  /**
   * Reposition titles based on the currently selected one.
   */
  function repositionTitles()
  {
    var currentIndex:Int = levelList.indexOf(currentLevelId);

    // The current item should be at y 480.
    levelTitles.members[currentIndex].targetY = 480;

    // Every item above it should be positioned in relation to the next item.
    if (currentIndex > 0)
    {
      for (i in 0...currentIndex)
      {
        var itemIndex:Int = currentIndex - 1 - i;
        var nextItem:LevelTitle = levelTitles.members[itemIndex + 1];
        levelTitles.members[itemIndex].targetY = nextItem.targetY - Math.max(levelTitles.members[itemIndex].height + 20, 125);
      }
    }

    // Every item below it should be positioned in relation to the previous item.
    if (currentIndex < levelTitles.members.length - 1)
    {
      for (i in (currentIndex + 1)...levelTitles.members.length)
      {
        var previousItem:LevelTitle = levelTitles.members[i - 1];
        levelTitles.members[i].targetY = previousItem.targetY + (previousItem.height + 20);
      }
    }
  }
}
