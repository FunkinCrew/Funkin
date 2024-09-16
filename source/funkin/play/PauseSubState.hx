package funkin.play;

import flixel.addons.transition.FlxTransitionableState;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.group.FlxSpriteGroup;
import flixel.math.FlxMath;
import flixel.sound.FlxSound;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
import funkin.audio.FunkinSound;
import funkin.data.song.SongRegistry;
import funkin.ui.freeplay.FreeplayState;
import funkin.graphics.FunkinSprite;
import funkin.play.cutscene.VideoCutscene;
import funkin.play.PlayState;
import funkin.ui.AtlasText;
import funkin.ui.debug.latency.LatencyState;
import funkin.ui.MusicBeatSubState;
import funkin.ui.transition.StickerSubState;

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
    {text: 'Restart Dialogue', callback: restartConversation},
    {text: 'Skip Dialogue', callback: skipConversation},
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
  public var allowInput:Bool = false;

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
    super.destroy();
    charterFadeTween.cancel();
    charterFadeTween = null;
    pauseMusic.stop();
  }

  // ===============
  // Initialization Functions
  // ===============

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
    background.makeSolidColor(FlxG.width, FlxG.height, FlxColor.BLACK);
    background.alpha = 0.0;
    background.scrollFactor.set(0, 0);
    background.updateHitbox();
    add(background);
  }

  /**
   * Render the metadata in the top right.
   */
  function buildMetadata():Void
  {
    metadata = new FlxTypedSpriteGroup<FlxText>();
    metadata.scrollFactor.set(0, 0);
    add(metadata);

    var metadataSong:FlxText = new FlxText(20, 15, FlxG.width - 40, 'Song Name');
    metadataSong.setFormat(Paths.font('vcr.ttf'), 32, FlxColor.WHITE, FlxTextAlign.RIGHT);
    if (PlayState.instance?.currentChart != null)
    {
      metadataSong.text = '${PlayState.instance.currentChart.songName}';
    }
    metadataSong.scrollFactor.set(0, 0);
    metadata.add(metadataSong);

    metadataArtist = new FlxText(20, metadataSong.y + 32, FlxG.width - 40, 'Artist: ${Constants.DEFAULT_ARTIST}');
    metadataArtist.setFormat(Paths.font('vcr.ttf'), 32, FlxColor.WHITE, FlxTextAlign.RIGHT);
    if (PlayState.instance?.currentChart != null)
    {
      metadataArtist.text = 'Artist: ${PlayState.instance.currentChart.songArtist}';
    }
    metadataArtist.scrollFactor.set(0, 0);
    metadata.add(metadataArtist);

    var metadataDifficulty:FlxText = new FlxText(20, metadataArtist.y + 32, FlxG.width - 40, 'Difficulty: ');
    metadataDifficulty.setFormat(Paths.font('vcr.ttf'), 32, FlxColor.WHITE, FlxTextAlign.RIGHT);
    if (PlayState.instance?.currentDifficulty != null)
    {
      metadataDifficulty.text += PlayState.instance.currentDifficulty.replace('-', ' ').toTitleCase();
    }
    metadataDifficulty.scrollFactor.set(0, 0);
    metadata.add(metadataDifficulty);

    metadataDeaths = new FlxText(20, metadataDifficulty.y + 32, FlxG.width - 40, '${PlayState.instance?.deathCounter} Blue Balls');
    metadataDeaths.setFormat(Paths.font('vcr.ttf'), 32, FlxColor.WHITE, FlxTextAlign.RIGHT);
    metadataDeaths.scrollFactor.set(0, 0);
    metadata.add(metadataDeaths);

    metadataPractice = new FlxText(20, metadataDeaths.y + 32, FlxG.width - 40, 'PRACTICE MODE');
    metadataPractice.setFormat(Paths.font('vcr.ttf'), 32, FlxColor.WHITE, FlxTextAlign.RIGHT);
    metadataPractice.visible = PlayState.instance?.isPracticeMode ?? false;
    metadataPractice.scrollFactor.set(0, 0);
    metadata.add(metadataPractice);

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

  /**
   * Perform additional animations to transition the pause menu in when it is first displayed.
   */
  function transitionIn():Void
  {
    FlxTween.tween(background, {alpha: 0.6}, 0.8, {ease: FlxEase.quartOut});

    // Animate each element a little bit downwards.
    var delay:Float = 0.1;
    for (child in metadata.members)
    {
      FlxTween.tween(child, {alpha: 1, y: child.y + 5}, 1.8, {ease: FlxEase.quartOut, startDelay: delay});
      delay += 0.1;
    }

    new FlxTimer().start(0.2, (_) -> {
      allowInput = true;
    });
  }

  // ===============
  // Input Handling
  // ===============

  /**
   * Process user inputs every frame.
   */
  function handleInputs():Void
  {
    if (!allowInput) return;

    if (controls.UI_UP_P)
    {
      changeSelection(-1);
    }
    if (controls.UI_DOWN_P)
    {
      changeSelection(1);
    }

    if (controls.ACCEPT)
    {
      currentMenuEntries[currentEntry].callback(this);
    }
    else if (controls.PAUSE)
    {
      resume(this);
    }

    #if FEATURE_DEBUG_FUNCTIONS
    // to pause the game and get screenshots easy, press H on pause menu!
    if (FlxG.keys.justPressed.H)
    {
      var visible = !metadata.visible;

      metadata.visible = visible;
      menuEntryText.visible = visible;
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

    if (currentEntry < 0) currentEntry = currentMenuEntries.length - 1;
    if (currentEntry >= currentMenuEntries.length) currentEntry = 0;

    if (currentEntry != prevEntry) FunkinSound.playOnce(Paths.sound('scrollMenu'), 0.4);

    for (entryIndex in 0...currentMenuEntries.length)
    {
      var isCurrent:Bool = entryIndex == currentEntry;

      var entry:PauseMenuEntry = currentMenuEntries[entryIndex];
      var text:AtlasText = entry.sprite;

      // Set the transparency.
      text.alpha = isCurrent ? 1.0 : 0.6;

      // Set the position.
      var targetX = FlxMath.remapToRange((entryIndex - currentEntry), 0, 1, 0, 1.3) * 20 + 90;
      var targetY = FlxMath.remapToRange((entryIndex - currentEntry), 0, 1, 0, 1.3) * 120 + (FlxG.height * 0.48);
      FlxTween.globalManager.cancelTweensOf(text);
      FlxTween.tween(text, {x: targetX, y: targetY}, 0.33, {ease: FlxEase.quartOut});
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
        var yPos:Float = 70 * entryIndex + 30;
        var text:AtlasText = new AtlasText(0, yPos, entry.text, AtlasFont.BOLD);
        text.scrollFactor.set(0, 0);
        text.alpha = 0;
        menuEntryText.add(text);

        entry.sprite = text;

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
    PlayState.instance.currentDifficulty = PlayStatePlaylist.campaignDifficulty;

    FreeplayState.rememberedDifficulty = difficulty;

    PlayState.instance.needsReset = true;

    state.close();
  }

  /**
   * Restart the current level, then resume the game.
   * @param state The current PauseSubState.
   */
  static function restartPlayState(state:PauseSubState):Void
  {
    PlayState.instance.needsReset = true;
    state.close();
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
    state.close();
  }

  /**
   * Skip the paused video cutscene, then resume the game.
   * @param state The current PauseSubState.
   */
  static function skipVideoCutscene(state:PauseSubState):Void
  {
    VideoCutscene.finishVideo();
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

    if (PlayStatePlaylist.isStoryMode)
    {
      PlayStatePlaylist.reset();
      state.openSubState(new funkin.ui.transition.StickerSubState(null, (sticker) -> new funkin.ui.story.StoryMenuState(sticker)));
    }
    else
    {
      state.openSubState(new funkin.ui.transition.StickerSubState(null, (sticker) -> FreeplayState.build(null, sticker)));
    }
  }

  /**
   * Quit the game and return to the chart editor.
   * @param state The current PauseSubState.
   */
  static function quitToChartEditor(state:PauseSubState):Void
  {
    state.close();
    if (FlxG.sound.music != null) FlxG.sound.music.pause(); // Don't reset song position!
    PlayState.instance.close(); // This only works because PlayState is a substate!
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
