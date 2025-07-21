package funkin.play;

import flixel.FlxState;
import funkin.ui.story.StoryMenuState;
import funkin.data.freeplay.player.PlayerRegistry;
import flixel.addons.transition.FlxTransitionableState;
import flixel.FlxG;
import flixel.group.FlxSpriteGroup.FlxTypedSpriteGroup;
import flixel.math.FlxMath;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import funkin.audio.FunkinSound;
import funkin.data.song.SongRegistry;
import funkin.ui.freeplay.FreeplayState;
import funkin.graphics.FunkinSprite;
import funkin.play.cutscene.VideoCutscene;
import funkin.ui.AtlasText;
import flixel.util.FlxTimer;
import funkin.ui.MusicBeatSubState;
import funkin.util.HapticUtil;
import funkin.ui.FullScreenScaleMode;
import funkin.ui.transition.stickers.StickerSubState;
import funkin.util.SwipeUtil;
import funkin.util.TouchUtil;
#if FEATURE_MOBILE_ADVERTISEMENTS
import funkin.mobile.util.AdMobUtil;
#end

/**
 * Parameters for initializing the PauseSubState.
 */
typedef PauseSubStateParams =
{
  /**
   * Which mode to start in. Dictates what entries are displayed.
   */
  ?mode:PauseMode,
};

/**
 * The menu displayed when the Play State is paused.
 */
class PauseSubState extends MusicBeatSubState
{
  // ===============
  // Constants
  // ===============

  /**
   * Pause menu entries for when the game is paused during a song.
   */
  static final PAUSE_MENU_ENTRIES_STANDARD:Array<PauseMenuEntry> = [
    {text: 'Resume', callback: resume},
    {text: 'Restart Song', callback: restartPlayState},
    {text: 'Change Difficulty', callback: switchMode.bind(_, Difficulty)},
    {text: 'Enable Practice Mode', callback: enablePracticeMode, filter: () -> !(PlayState.instance?.isPracticeMode ?? false)},
    {text: 'Exit to Menu', callback: quitToMenu},
  ];

  /**
   * Pause menu entries for when the game is paused in the Chart Editor preview.
   */
  static final PAUSE_MENU_ENTRIES_CHARTING:Array<PauseMenuEntry> = [
    {text: 'Resume', callback: resume},
    {text: 'Restart Song', callback: restartPlayState},
    {text: 'Return to Chart Editor', callback: quitToChartEditor},
  ];

  /**
   * Pause menu entries for when the user selects "Change Difficulty".
   */
  static final PAUSE_MENU_ENTRIES_DIFFICULTY:Array<PauseMenuEntry> = [
    {text: 'Back', callback: switchMode.bind(_, Standard)}
    // Other entries are added dynamically.
  ];

  /**
   * Pause menu entries for when the game is paused during a video cutscene.
   */
  static final PAUSE_MENU_ENTRIES_VIDEO_CUTSCENE:Array<PauseMenuEntry> = [
    {text: 'Resume', callback: resume},
    {text: 'Skip Cutscene', callback: skipVideoCutscene},
    {text: 'Restart Cutscene', callback: restartVideoCutscene},
    {text: 'Exit to Menu', callback: quitToMenu},
  ];

  /**
   * Pause menu entries for when the game is paused during a conversation.
   */
  static final PAUSE_MENU_ENTRIES_CONVERSATION:Array<PauseMenuEntry> = [
    {text: 'Resume', callback: resume},
    {text: 'Skip Dialogue', callback: skipConversation},
    {text: 'Restart Dialogue', callback: restartConversation},
    {text: 'Exit to Menu', callback: quitToMenu},
  ];

  /**
   * Duration for the music to fade in when the pause menu is opened.
   */
  static final MUSIC_FADE_IN_TIME:Float = 5;

  /**
   * The final volume for the music when the pause menu is opened.
   */
  static final MUSIC_FINAL_VOLUME:Float = 0.75;

  static final CHARTER_FADE_DELAY:Float = 15.0;

  static final CHARTER_FADE_DURATION:Float = 0.75;

  /**
   * Defines which pause music to use.
   */
  public static var musicSuffix:String = '';

  /**
   * Reset the pause configuration to the default.
   */
  public static function reset():Void
  {
    musicSuffix = '';
  }

  // ===============
  // Status Variables
  // ===============

  /**
   * Disallow input until transitions are complete!
   * This prevents the pause menu from immediately closing when opened, among other things.
   */
  public var allowInput:Bool = true;

  // If this is true, it means we are frame 1 of our substate.
  var justOpened:Bool = true;

  /**
   * The entries currently displayed in the pause menu.
   */
  var currentMenuEntries:Array<PauseMenuEntry>;

  /**
   * The index of `currentMenuEntries` that is currently selected.
   */
  var currentEntry:Int = 0;

  /**
   * The mode that the pause menu is currently in.
   */
  var currentMode:PauseMode;

  // ===============
  // Graphics Variables
  // ===============

  #if mobile
  /**
   * The pause button for the game, only appears in Mobile targets. Shows up breifly to finish the pause animation.
   */
  var pauseButton:FunkinSprite;

  /**
   * The pause circle for the game, only appears in Mobile targets. Shows up breifly to finish the pause animation.
   */
  var pauseCircle:FunkinSprite;
  #end

  /**
   * The placeholder sprite displayed when an advertisement fails to load or display.
   */
  // var failedAdPlaceHolder:FunkinSprite;

  /**
   * The semi-transparent black background that appears when the game is paused.
   */
  var background:FunkinSprite;

  /**
   * The metadata displayed in the top right.
   */
  var metadata:FlxTypedSpriteGroup<FlxText>;

  /**
   * A text object that displays the current practice mode status.
   */
  var metadataPractice:FlxText;

  /**
   * A text object that displays the current death count.
   */
  var metadataDeaths:FlxText;

  /**
   * A text object which displays the current song's artist.
   * Fades to the charter after a period before fading back.
   */
  var metadataArtist:FlxText;

  /**
   * A text object that displays the current global offset.
   */
  var offsetText:FlxText;

  /**
   * A text object that displays information about the current global offset.
   */
  var offsetTextInfo:FlxText;

  /**
   * The actual text objects for the menu entries.
   */
  var menuEntryText:FlxTypedSpriteGroup<AtlasText>;

  // ===============
  // Audio Variables
  // ===============
  var pauseMusic:FunkinSound;

  // ===============
  // Constructor
  // ===============

  public function new(?params:PauseSubStateParams)
  {
    super();
    this.currentMode = params?.mode ?? Standard;
  }

  // ===============
  // Lifecycle Functions
  // ===============

  /**
   * Called when the state is first loaded.
   */
  public override function create():Void
  {
    // Add banner ad when game is state is first loaded.
    #if FEATURE_MOBILE_ADVERTISEMENTS
    // extension.admob.Admob.onEvent.add(onBannerEvent);

    AdMobUtil.addBanner(extension.admob.AdmobBannerSize.BANNER, extension.admob.AdmobBannerAlign.TOP_LEFT);
    #end

    super.create();

    startPauseMusic();

    buildBackground();

    buildMetadata();

    regenerateMenu();

    transitionIn();

    startCharterTimer();
  }

  /**
   * Called every frame.
   * @param elapsed The time elapsed since the last frame, in seconds.
   */
  public override function update(elapsed:Float):Void
  {
    super.update(elapsed);

    handleInputs();
  }

  /**
   * Called when the state is closed.
   */
  public override function destroy():Void
  {
    // #if FEATURE_MOBILE_ADVERTISEMENTS
    // extension.admob.Admob.onEvent.remove(onBannerEvent);
    // #end
    super.destroy();
    charterFadeTween.cancel();
    charterFadeTween = null;
    dataFadeTimer.cancel();
    dataFadeTimer = null;
    hapticTimer.cancel();
    hapticTimer = null;
    pauseMusic.stop();
  }

  // ===============
  // Initialization Functions
  // ===============

  /*#if FEATURE_MOBILE_ADVERTISEMENTS
    function onBannerEvent(event:extension.admob.AdmobEvent):Void
    {
      if (event.name.indexOf('BANNER') == -1) return;

      if (event.errorCode != null && event.errorDescription != null)
      {
        if (failedAdPlaceHolder == null || members.indexOf(failedAdPlaceHolder) == -1)
        {
          var scale:Float = Math.min(FlxG.stage.stageWidth / FlxG.width, FlxG.stage.stageHeight / FlxG.height);

          #if android
          scale = Math.max(scale, 1);
          #else
          scale = Math.min(scale, 1);
          #end

          failedAdPlaceHolder = new FunkinSprite(0, 0);
          failedAdPlaceHolder.makeSolidColor(Math.floor(320 * scale), Math.floor(50 * scale), FlxColor.RED);
          failedAdPlaceHolder.updateHitbox();
          failedAdPlaceHolder.screenCenter(X);
          failedAdPlaceHolder.scrollFactor.set(0, 0);
          add(failedAdPlaceHolder);
        }
      }
      else if (failedAdPlaceHolder != null && members.indexOf(failedAdPlaceHolder) != -1)
      {
        remove(failedAdPlaceHolder);
      }
    }
    #end */
  /**
   * Play the pause music.
   */
  function startPauseMusic():Void
  {
    var pauseMusicPath:String = Paths.music('breakfast$musicSuffix/breakfast$musicSuffix');
    pauseMusic = FunkinSound.load(pauseMusicPath, true, true);

    if (pauseMusic == null)
    {
      FlxG.log.warn('Could not play pause music: ${pauseMusicPath} does not exist!');
    }

    // Start playing at a random point in the song.
    pauseMusic.play(false, FlxG.random.int(0, Std.int(pauseMusic.length / 2)));
    pauseMusic.fadeIn(MUSIC_FADE_IN_TIME, 0, MUSIC_FINAL_VOLUME);
  }

  /**
   * Render the semi-transparent black background.
   */
  function buildBackground():Void
  {
    // Using state.bgColor causes bugs!
    background = new FunkinSprite(0, 0);
    background.makeSolidColor(camera.width, camera.height, FlxColor.BLACK);
    background.alpha = 0.0;
    background.scrollFactor.set(0, 0);
    background.updateHitbox();
    add(background);

    #if mobile
    pauseButton = FunkinSprite.createSparrow(0, 0, "pauseButton");
    pauseButton.animation.addByIndices('idle', 'pause', [0], "", 24, false);
    pauseButton.animation.addByIndices('hold', 'pause', [5], "", 24, false);
    pauseButton.animation.addByIndices('confirm', 'pause', [
      6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32
    ], "", 24, false);
    pauseButton.scale.set(0.8, 0.8);
    pauseButton.updateHitbox();
    pauseButton.animation.play("confirm");
    pauseButton.setPosition((FlxG.width - pauseButton.width) - 35, 35);

    pauseCircle = FunkinSprite.create(0, 0, 'pauseCircle');
    pauseCircle.scale.set(0.84, 0.8);
    pauseCircle.updateHitbox();
    pauseCircle.x = ((pauseButton.x + (pauseButton.width / 2)) - (pauseCircle.width / 2));
    pauseCircle.y = ((pauseButton.y + (pauseButton.height / 2)) - (pauseCircle.height / 2));
    pauseCircle.alpha = 0.1;

    add(pauseCircle);
    add(pauseButton);
    #end
  }

  /**
   * Render the metadata in the top right.
   */
  function buildMetadata():Void
  {
    metadata = new FlxTypedSpriteGroup<FlxText>();
    metadata.scrollFactor.set(0, 0);
    add(metadata);

    var metadataSong:FlxText = new FlxText(20,
      #if mobile (PlayState.instance?.isPracticeMode ?? false) ? camera.height - 185 : camera.height - 155 #else 15 #end,
      camera.width - Math.max(40, funkin.ui.FullScreenScaleMode.gameNotchSize.x), 'Song Name');
    metadataSong.setFormat(Paths.font('vcr.ttf'), 32, FlxColor.WHITE, FlxTextAlign.RIGHT);
    if (PlayState.instance?.currentChart != null)
    {
      metadataSong.text = '${PlayState.instance.currentChart.songName}';
    }
    metadataSong.scrollFactor.set(0, 0);
    metadata.add(metadataSong);

    metadataArtist = new FlxText(20, metadataSong.y + 32, camera.width - Math.max(40, funkin.ui.FullScreenScaleMode.gameNotchSize.x),
      'Artist: ${Constants.DEFAULT_ARTIST}');
    metadataArtist.setFormat(Paths.font('vcr.ttf'), 32, FlxColor.WHITE, FlxTextAlign.RIGHT);
    if (PlayState.instance?.currentChart != null)
    {
      metadataArtist.text = 'Artist: ${PlayState.instance.currentChart.songArtist}';
    }
    metadataArtist.scrollFactor.set(0, 0);
    metadata.add(metadataArtist);

    var metadataDifficulty:FlxText = new FlxText(20, metadataArtist.y + 32, camera.width - Math.max(40, funkin.ui.FullScreenScaleMode.gameNotchSize.x),
      'Difficulty: ');
    metadataDifficulty.setFormat(Paths.font('vcr.ttf'), 32, FlxColor.WHITE, FlxTextAlign.RIGHT);
    if (PlayState.instance?.currentDifficulty != null)
    {
      metadataDifficulty.text += PlayState.instance.currentDifficulty.replace('-', ' ').toTitleCase();
    }
    metadataDifficulty.scrollFactor.set(0, 0);
    metadata.add(metadataDifficulty);

    metadataDeaths = new FlxText(20, metadataDifficulty.y + 32, camera.width - Math.max(40, funkin.ui.FullScreenScaleMode.gameNotchSize.x),
      '${PlayState.instance?.deathCounter} Blue Balls');
    metadataDeaths.setFormat(Paths.font('vcr.ttf'), 32, FlxColor.WHITE, FlxTextAlign.RIGHT);
    metadataDeaths.scrollFactor.set(0, 0);
    metadata.add(metadataDeaths);

    metadataPractice = new FlxText(20, metadataDeaths.y + 32, camera.width - Math.max(40, funkin.ui.FullScreenScaleMode.gameNotchSize.x), 'PRACTICE MODE');
    metadataPractice.setFormat(Paths.font('vcr.ttf'), 32, FlxColor.WHITE, FlxTextAlign.RIGHT);
    metadataPractice.visible = PlayState.instance?.isPracticeMode ?? false;
    metadataPractice.scrollFactor.set(0, 0);
    metadata.add(metadataPractice);

    // Right side
    offsetText = new FlxText(20, metadataSong.y - 12, (camera.width + 10) - Math.max(40, funkin.ui.FullScreenScaleMode.gameNotchSize.x),
      'Global Offset: ${Preferences.globalOffset ?? 0}ms');
    offsetText.setFormat(Paths.font('vcr.ttf'), 16, FlxColor.WHITE, FlxTextAlign.RIGHT);
    offsetText.scrollFactor.set(0, 0);

    offsetTextInfo = new FlxText(20, offsetText.y + 16, (camera.width + 10) - Math.max(40, funkin.ui.FullScreenScaleMode.gameNotchSize.x),
      'Hold SHIFT-UP/DOWN,\nto change the offset.');
    offsetTextInfo.setFormat(Paths.font('vcr.ttf'), 16, FlxColor.WHITE, FlxTextAlign.RIGHT);
    offsetTextInfo.scrollFactor.set(0, 0);

    offsetText.y = FlxG.height - (offsetText.height + offsetText.height + 40);
    offsetTextInfo.y = offsetText.y + offsetText.height + 4;

    #if !mobile
    metadata.add(offsetText);
    metadata.add(offsetTextInfo);
    #end

    metadataArtist.alpha = 0;
    metadataPractice.alpha = 0;
    metadataSong.alpha = 0;
    metadataDifficulty.alpha = 0;
    metadataDeaths.alpha = 0;
    offsetText.alpha = 0;
    offsetTextInfo.alpha = 0;

    updateMetadataText();
  }

  var charterFadeTween:Null<FlxTween> = null;

  function startCharterTimer():Void
  {
    charterFadeTween = FlxTween.tween(metadataArtist, {alpha: 0.0}, CHARTER_FADE_DURATION,
      {
        startDelay: CHARTER_FADE_DELAY,
        ease: FlxEase.quartOut,
        onComplete: (_) -> {
          if (PlayState.instance?.currentChart != null)
          {
            metadataArtist.text = 'Charter: ${PlayState.instance.currentChart.charter ?? 'Unknown'}';
          }
          else
          {
            metadataArtist.text = 'Charter: ${Constants.DEFAULT_CHARTER}';
          }

          FlxTween.tween(metadataArtist, {alpha: 1.0}, CHARTER_FADE_DURATION,
            {
              ease: FlxEase.quartOut,
              onComplete: (_) -> {
                startArtistTimer();
              }
            });
        }
      });
  }

  function startArtistTimer():Void
  {
    charterFadeTween = FlxTween.tween(metadataArtist, {alpha: 0.0}, CHARTER_FADE_DURATION,
      {
        startDelay: CHARTER_FADE_DELAY,
        ease: FlxEase.quartOut,
        onComplete: (_) -> {
          if (PlayState.instance?.currentChart != null)
          {
            metadataArtist.text = 'Artist: ${PlayState.instance.currentChart.songArtist}';
          }
          else
          {
            metadataArtist.text = 'Artist: ${Constants.DEFAULT_ARTIST}';
          }

          FlxTween.tween(metadataArtist, {alpha: 1.0}, CHARTER_FADE_DURATION,
            {
              ease: FlxEase.quartOut,
              onComplete: (_) -> {
                startCharterTimer();
              }
            });
        }
      });
  }

  var dataFadeTimer = new FlxTimer();
  var hapticTimer = new FlxTimer();

  /**
   * Perform additional animations to transition the pause menu in when it is first displayed.
   */
  function transitionIn():Void
  {
    FlxTween.tween(background, {alpha: 0.6}, 0.8, {ease: FlxEase.quartOut});

    #if mobile
    HapticUtil.vibrate(0, 0.05, 0.5);

    pauseButton.animation.play("confirm");
    pauseCircle.scale.set(0.84 * 1.4, 0.8 * 1.4);
    pauseCircle.alpha = 0.4;
    FlxTween.tween(pauseCircle.scale, {x: 0.84 * 0.8, y: 0.8 * 0.8}, 0.4, {ease: FlxEase.backInOut});
    FlxTween.tween(pauseCircle, {alpha: 0}, 0.6, {ease: FlxEase.quartOut});

    hapticTimer.start(0.2, function(_) {
      HapticUtil.vibrate(0, 0.01, 0.5);
    });

    dataFadeTimer.start(0.3, function(_) {
      transitionMetadataIn();
      FlxTween.tween(pauseButton, {alpha: 0}, 0.6, {ease: FlxEase.quartOut});
    });
    #else
    transitionMetadataIn();
    #end
  }

  function transitionMetadataIn():Void
  {
    // Animate each element a little bit downwards.
    var delay:Float = 0.1;
    for (child in metadata.members)
    {
      FlxTween.tween(child, {alpha: 1, y: #if mobile child.y - 5 #else child.y + 5 #end}, 1.8, {ease: FlxEase.quartOut, startDelay: delay});
      delay += 0.1;
    }
  }

  // ===============
  // Input Handling
  // ===============
  var fastOffset:Bool = false;
  var lastOffsetPress:Float = 0;

  /**
   * Process user inputs every frame.
   */
  function handleInputs():Void
  {
    if (!allowInput) return;

    // Doing this just so it'd look better i guess.
    final upP:Bool = controls.UI_UP_P;
    final downP:Bool = controls.UI_DOWN_P;

    #if !mobile
    final up:Bool = controls.UI_UP;
    final down:Bool = controls.UI_DOWN;
    var offset:Int = Preferences.globalOffset ?? 0;
    if (FlxG.keys.pressed.SHIFT && (up || down))
    {
      lastOffsetPress += FlxG.elapsed;
      if (!fastOffset)
      {
        // If the last offset press was more than 0.5 seconds ago, reset the fast offset.
        if (lastOffsetPress > 0.5)
        {
          fastOffset = true;
          lastOffsetPress = 0;
        }

        if (upP || downP)
        {
          offset += (upP || up) ? 1 : -1;

          offsetText.text = 'Global Offset: ${offset}ms';
        }
      }
      else
      {
        offset += (upP || up) ? 1 : -1;

        offsetText.text = 'Global Offset: ${offset}ms';
      }

      if (offset > 1500) offset = 1500;
      if (offset < -1500) offset = -1500;

      Preferences.globalOffset = offset;

      return;
    }
    else
    {
      // Reset the fast offset if the user is not holding SHIFT.
      fastOffset = false;
      lastOffsetPress = 0;
    }
    #end

    if (upP)
    {
      changeSelection(-1);
    }
    if (downP)
    {
      changeSelection(1);
    }

    #if FEATURE_TOUCH_CONTROLS
    if (!SwipeUtil.justSwipedAny && !justOpened && currentMenuEntries.length > 0)
    {
      for (i in 0...menuEntryText.members.length)
      {
        if (!TouchUtil.pressAction(menuEntryText.members[i], camera, false)) continue;

        if (i == currentEntry)
        {
          currentMenuEntries[currentEntry].callback(this);
          HapticUtil.vibrate(0, 0.05, 1);
          break;
        }

        changeSelection(i - currentEntry);
        HapticUtil.vibrate(0, 0.01, 0.5);

        break;
      }
    }
    #end

    if (controls.ACCEPT && currentMenuEntries.length > 0)
    {
      currentMenuEntries[currentEntry].callback(this);
    }
    else if (controls.PAUSE && !justOpened)
    {
      resume(this);
    }
    // we only want justOpened to be true for 1 single frame, when we first get into the pause menu substate
    justOpened = false;
    #if FEATURE_DEBUG_FUNCTIONS
    // to pause the game and get screenshots easy, press H on pause menu!
    if (FlxG.keys.justPressed.H)
    {
      var visible = !metadata.visible;
      metadata.visible = visible;
      menuEntryText.visible = visible;
      background.visible = visible;
      this.bgColor = visible ? 0x99000000 : 0x00000000; // 60% or fully transparent black
    }
    #end
  }

  /**
   * Move the current selection up or down.
   * @param change The amount to change the selection by, with sign indicating direction.
   */
  function changeSelection(change:Int = 0):Void
  {
    var prevEntry:Int = currentEntry;
    currentEntry += change;

    if (#if FEATURE_TOUCH_CONTROLS !funkin.mobile.input.ControlsHandler.usingExternalInputDevice #else false #end)
    {
      if (currentEntry < 0) currentEntry = 0;
      if (currentEntry >= currentMenuEntries.length) currentEntry = currentMenuEntries.length - 1;
    }
    else
    {
      if (currentEntry < 0) currentEntry = currentMenuEntries.length - 1;
      if (currentEntry >= currentMenuEntries.length) currentEntry = 0;
    }

    if (currentEntry != prevEntry) FunkinSound.playOnce(Paths.sound('scrollMenu'), 0.4);

    for (entryIndex in 0...currentMenuEntries.length)
    {
      var isCurrent:Bool = entryIndex == currentEntry;

      var entry:PauseMenuEntry = currentMenuEntries[entryIndex];
      var text:AtlasText = entry.sprite;

      // Set the transparency.
      text.alpha = isCurrent ? 1.0 : 0.6;

      #if mobile
      // Set the position.
      if (isCurrent && currentEntry != prevEntry)
      {
        FlxTween.globalManager.cancelTweensOf(text);
        text.x = 165;
        FlxTween.tween(text, {x: 150}, 0.2, {ease: FlxEase.backInOut});
      }
      #else
      var targetX = FlxMath.remapToRange((entryIndex - currentEntry), 0, 1, 0, 1.3) * 20 + Math.max(90, funkin.ui.FullScreenScaleMode.gameNotchSize.x);
      var targetY = FlxMath.remapToRange((entryIndex - currentEntry), 0, 1, 0, 1.3) * 120 + (camera.height * 0.48);
      FlxTween.globalManager.cancelTweensOf(text);
      FlxTween.tween(text, {x: targetX, y: targetY}, 0.33, {ease: FlxEase.quartOut});
      #end
    }
  }

  // ===============
  // Menu Functions
  // ===============

  /**
   * Clear the current menu entries and regenerate them based on the current mode.
   * @param targetMode Optionally specify a mode to switch to before regenerating the menu.
   */
  function regenerateMenu(?targetMode:PauseMode):Void
  {
    // If targetMode is null, keep the current mode.
    if (targetMode == null) targetMode = this.currentMode;

    var previousMode:PauseMode = this.currentMode;
    this.currentMode = targetMode;

    resetSelection();
    chooseMenuEntries();
    clearAndAddMenuEntries();
    updateMetadataText();
    changeSelection();
  }

  /**
   * Reset the current selection to the first entry.
   */
  function resetSelection():Void
  {
    this.currentEntry = 0;
  }

  /**
   * Select which menu entries to display based on the current mode.
   */
  function chooseMenuEntries():Void
  {
    // Choose the correct menu entries.
    // NOTE: We clone the arrays to prevent modifications to the arrays from affecting the original.
    switch (this.currentMode)
    {
      case PauseMode.Standard:
        currentMenuEntries = PAUSE_MENU_ENTRIES_STANDARD.clone();
      case PauseMode.Charting:
        currentMenuEntries = PAUSE_MENU_ENTRIES_CHARTING.clone();
      case PauseMode.Difficulty:
        // Prepend the difficulties.
        var entries:Array<PauseMenuEntry> = [];
        if (PlayState.instance.currentChart != null)
        {
          var difficultiesInVariation = PlayState.instance.currentSong.listDifficulties(PlayState.instance.currentChart.variation, true);
          trace('DIFFICULTIES: ${difficultiesInVariation}');
          for (difficulty in difficultiesInVariation)
          {
            entries.push({text: difficulty.toTitleCase(), callback: (state) -> changeDifficulty(state, difficulty)});
          }
        }

        // Add the back button.
        currentMenuEntries = entries.concat(PAUSE_MENU_ENTRIES_DIFFICULTY.clone());
      case PauseMode.Conversation:
        currentMenuEntries = PAUSE_MENU_ENTRIES_CONVERSATION.clone();
      case PauseMode.Cutscene:
        currentMenuEntries = PAUSE_MENU_ENTRIES_VIDEO_CUTSCENE.clone();
    }
  }

  /**
   * Clear the `menuEntryText` group and render the current menu entries to it.
   * We first create the `menuEntryText` group if it doesn't already exist.
   */
  function clearAndAddMenuEntries():Void
  {
    if (menuEntryText == null)
    {
      menuEntryText = new FlxTypedSpriteGroup<AtlasText>();
      menuEntryText.scrollFactor.set(0, 0);
      add(menuEntryText);
    }
    menuEntryText.clear();

    // Render out the entries depending on the mode.
    var entryIndex:Int = 0;
    var toRemove = [];
    for (entry in currentMenuEntries)
    {
      if (entry == null || (entry.filter != null && !entry.filter()))
      {
        // Remove entries that should be hidden.
        toRemove.push(entry);
      }
      else
      {
        // Handle visible entries.
        #if mobile
        // var yPos:Float = (150 * entryIndex) + 100;

        // var yPos:Float = (140 * entryIndex) + 150;
        var yPos:Float = (105 * entryIndex) + 150;

        var text:AtlasText = new AtlasText(110, yPos, entry.text, AtlasFont.BOLD);
        text.scrollFactor.set(0, 0);
        text.alpha = 0;
        for (letter in text)
        {
          letter.width *= 1.2;
          letter.height *= 1.4;
        }
        menuEntryText.add(text);

        FlxTween.tween(text, {x: 150}, 0.4 * (entryIndex + 1), {ease: FlxEase.expoOut});

        entry.sprite = text;
        #else
        var yPos:Float = 70 * entryIndex + 30;
        var text:AtlasText = new AtlasText(0, yPos, entry.text, AtlasFont.BOLD);
        text.scrollFactor.set(0, 0);
        text.alpha = 0;
        for (letter in text)
        {
          letter.width *= 2;
          letter.height *= 2;
        }
        menuEntryText.add(text);

        entry.sprite = text;
        #end

        entryIndex++;
      }
    }
    for (entry in toRemove)
    {
      currentMenuEntries.remove(entry);
    }
  }

  // ===============
  // Metadata Functions
  // ===============

  /**
   * Update the values for the metadata text in the top right.
   */
  function updateMetadataText():Void
  {
    metadataPractice.visible = PlayState.instance?.isPracticeMode ?? false;

    #if mobile
    if (metadata.members[0].y != camera.height - 185 && metadataPractice.visible)
    {
      for (text in metadata)
      {
        text.y -= 30;
      }
    }
    #end

    switch (this.currentMode)
    {
      case Standard | Difficulty:
        metadataDeaths.text = '${PlayState.instance?.deathCounter} Blue Balls';
      case Charting:
        metadataDeaths.text = 'Chart Editor Preview';
      case Conversation:
        metadataDeaths.text = 'Dialogue Paused';
      case Cutscene:
        metadataDeaths.text = 'Video Paused';
    }
  }

  // ===============
  // Menu Callbacks
  // ===============

  /**
   * Close the pause menu and resume the game.
   * @param state The current PauseSubState.
   */
  static function resume(state:PauseSubState):Void
  {
    // Resume a paused video if it exists.
    VideoCutscene.resumeVideo();
    #if FEATURE_MOBILE_ADVERTISEMENTS
    AdMobUtil.removeBanner();
    #end
    state.close();
  }

  /**
   * Switch the pause menu to the indicated mode.
   * Create a callback from this using `.bind(_, targetMode)`.
   * @param state The current PauseSubState.
   * @param targetMode The mode to switch to.
   */
  static function switchMode(state:PauseSubState, targetMode:PauseMode):Void
  {
    state.regenerateMenu(targetMode);
  }

  /**
   * Switch the game's difficulty to the indicated difficulty, then resume the game.
   * @param state The current PauseSubState.
   * @param difficulty The difficulty to switch to.
   */
  static function changeDifficulty(state:PauseSubState, difficulty:String):Void
  {
    PlayState.instance.currentSong = SongRegistry.instance.fetchEntry(PlayState.instance.currentSong.id.toLowerCase());

    // Reset campaign score when changing difficulty
    // So if you switch difficulty on the last song of a week you get a really low overall score.
    PlayStatePlaylist.campaignScore = 0;
    PlayStatePlaylist.campaignDifficulty = difficulty;
    PlayState.instance.previousDifficulty = PlayState.instance.currentDifficulty;
    PlayState.instance.currentDifficulty = PlayStatePlaylist.campaignDifficulty;

    FreeplayState.rememberedDifficulty = difficulty;

    PlayState.instance.needsReset = true;

    #if FEATURE_MOBILE_ADVERTISEMENTS
    if (AdMobUtil.PLAYING_COUNTER < AdMobUtil.MAX_BEFORE_AD) AdMobUtil.PLAYING_COUNTER++;

    if (AdMobUtil.PLAYING_COUNTER >= AdMobUtil.MAX_BEFORE_AD)
    {
      state.allowInput = false;

      AdMobUtil.loadInterstitial(function():Void {
        AdMobUtil.PLAYING_COUNTER = 0;

        AdMobUtil.removeBanner();

        state.allowInput = true;

        state.close();
      });
    }
    else
    {
      AdMobUtil.removeBanner();

      state.close();
    }
    #else
    state.close();
    #end
  }

  /**
   * Restart the current level, then resume the game.
   * @param state The current PauseSubState.
   */
  static function restartPlayState(state:PauseSubState):Void
  {
    PlayState.instance.needsReset = true;

    #if FEATURE_MOBILE_ADVERTISEMENTS
    if (AdMobUtil.PLAYING_COUNTER < AdMobUtil.MAX_BEFORE_AD) AdMobUtil.PLAYING_COUNTER++;

    if (AdMobUtil.PLAYING_COUNTER >= AdMobUtil.MAX_BEFORE_AD)
    {
      state.allowInput = false;

      AdMobUtil.loadInterstitial(function():Void {
        AdMobUtil.PLAYING_COUNTER = 0;

        AdMobUtil.removeBanner();

        state.allowInput = true;

        state.close();
      });
    }
    else
    {
      AdMobUtil.removeBanner();

      state.close();
    }
    #else
    state.close();
    #end
  }

  /**
   * Force the game into practice mode, then update the pause menu.
   * @param state The current PauseSubState.
   */
  static function enablePracticeMode(state:PauseSubState):Void
  {
    if (PlayState.instance == null) return;

    PlayState.instance.isPracticeMode = true;
    state.regenerateMenu();
  }

  /**
   * Restart the paused video cutscene, then resume the game.
   * @param state The current PauseSubState.
   */
  static function restartVideoCutscene(state:PauseSubState):Void
  {
    VideoCutscene.restartVideo();
    #if FEATURE_MOBILE_ADVERTISEMENTS
    AdMobUtil.removeBanner();
    #end
    state.close();
  }

  /**
   * Skip the paused video cutscene, then resume the game.
   * @param state The current PauseSubState.
   */
  static function skipVideoCutscene(state:PauseSubState):Void
  {
    VideoCutscene.finishVideo();
    #if FEATURE_MOBILE_ADVERTISEMENTS
    AdMobUtil.removeBanner();
    #end
    state.close();
  }

  /**
   * Restart the paused conversation, then resume the game.
   * @param state The current PauseSubState.
   */
  static function restartConversation(state:PauseSubState):Void
  {
    if (PlayState.instance?.currentConversation == null) return;

    PlayState.instance.currentConversation.resetConversation();
    #if FEATURE_MOBILE_ADVERTISEMENTS
    AdMobUtil.removeBanner();
    #end
    state.close();
  }

  /**
   * Skip the paused conversation, then resume the game.
   * @param state The current PauseSubState.
   */
  static function skipConversation(state:PauseSubState):Void
  {
    if (PlayState.instance?.currentConversation == null) return;

    PlayState.instance.currentConversation.skipConversation();
    #if FEATURE_MOBILE_ADVERTISEMENTS
    AdMobUtil.removeBanner();
    #end
    state.close();
  }

  /**
   * Quit the game and return to the main menu.
   * @param state The current PauseSubState.
   */
  static function quitToMenu(state:PauseSubState):Void
  {
    state.allowInput = false;

    PlayState.instance.deathCounter = 0;

    FlxTransitionableState.skipNextTransIn = true;
    FlxTransitionableState.skipNextTransOut = true;

    var targetState:funkin.ui.transition.stickers.StickerSubState->FlxState = (PlayStatePlaylist.isStoryMode) ? (sticker) ->
      new StoryMenuState(sticker) : (sticker) -> FreeplayState.build(sticker);

    // Do this AFTER because this resets the value of isStoryMode!
    if (PlayStatePlaylist.isStoryMode)
    {
      PlayStatePlaylist.reset();
    }

    var stickerPackId:Null<String> = PlayState.instance.currentChart.stickerPack;

    if (stickerPackId == null)
    {
      var playerCharacterId = PlayerRegistry.instance.getCharacterOwnerId(PlayState.instance.currentChart.characters.player);
      var playerCharacter = PlayerRegistry.instance.fetchEntry(playerCharacterId ?? Constants.DEFAULT_CHARACTER);

      if (playerCharacter != null)
      {
        stickerPackId = playerCharacter.getStickerPackID();
      }
    }

    #if FEATURE_MOBILE_ADVERTISEMENTS
    AdMobUtil.removeBanner();
    #end

    state.openSubState(new funkin.ui.transition.stickers.StickerSubState({targetState: targetState, stickerPack: stickerPackId}));
  }

  /**
   * Quit the game and return to the chart editor.
   * @param state The current PauseSubState.
   */
  @:access(funkin.play.PlayState)
  static function quitToChartEditor(state:PauseSubState):Void
  {
    #if FEATURE_MOBILE_ADVERTISEMENTS
    AdMobUtil.removeBanner();
    #end
    // This should come first because the sounds list gets cleared!
    PlayState.instance?.forEachPausedSound(s -> s.destroy());
    state.close();
    FlxG.sound.music?.pause(); // Don't reset song position!
    PlayState.instance?.vocals?.pause();
    PlayState.instance?.close(); // This only works because PlayState is a substate!
  }
}

/**
 * Which set of options the pause menu should display.
 */
enum PauseMode
{
  /**
   * The menu displayed when the player pauses the game during a song.
   */
  Standard;

  /**
   * The menu displayed when the player pauses the game during a song while in charting mode.
   */
  Charting;

  /**
   * The menu displayed when the player moves to change the game's difficulty.
   */
  Difficulty;

  /**
   * The menu displayed when the player pauses the game during a conversation.
   */
  Conversation;

  /**
   * The menu displayed when the player pauses the game during a video cutscene.
   */
  Cutscene;
}

/**
 * Represents a single entry in the pause menu.
 */
typedef PauseMenuEntry =
{
  /**
   * The text to display for this entry.
   * TODO: Implement localization.
   */
  var text:String;

  /**
   * The callback to execute when the user selects this entry.
   */
  var callback:PauseSubState->Void;

  /**
   * If this returns true, the entry will be displayed. If it returns false, the entry will be hidden.
   */
  var ?filter:Void->Bool;

  // Instance-specific properties

  /**
   * The text object currently displaying this entry.
   */
  var ?sprite:AtlasText;
};
