package funkin.play;

typedef PauseSubStateParams =
{
  ?mode:PauseMode,
};

/**
 * The menu displayed when the Play State is paused.
 */
class PauseSubState extends MusicBeatSubState
{
  static final PAUSE_MENU_ENTRIES_STANDARD = [
    {text: 'Resume', callback: resume},
    {text: 'Restart Song', callback: restartPlayState},
    {text: 'Change Difficulty', callback: switchMode.bind(_, Difficulty)},
    {text: 'Enable Practice Mode', callback: enablePracticeMode, filter: () -> (PlayState.instance?.isPracticeMode ?? true)},
    {text: 'Exit to Menu', callback: quitToMenu},
  ];

  static final PAUSE_MENU_ENTRIES_CHARTING = [
    {text: 'Resume', callback: resume},
    {text: 'Restart Song', callback: restartPlayState},
    {text: 'Return to Chart Editor', callback: quitToChartEditor},
  ];

  static final PAUSE_MENU_ENTRIES_DIFFICULTY = [
    {text: 'Back', callback: switchMode.bind(_, Standard)}
    // Other entries are added dynamically.
  ];

  static final PAUSE_MENU_ENTRIES_CUTSCENE = [
    {text: 'Resume', callback: resume},
    {text: 'Restart Cutscene', callback: restartCutscene},
    {text: 'Skip Cutscene', callback: skipCutscene},
    {text: 'Exit to Menu', callback: quitToMenu},
  ];

  static final MUSIC_FADE_IN_TIME:Float = 50;
  static final MUSIC_FINAL_VOLUME:Float = 0.5;

  public static var musicSuffix:String = '';

  // Status
  var menuEntries:Array<PauseMenuEntry>;
  var currentEntry:Int = 0;
  var currentMode:PauseMode;
  var allowInput:Bool = true;

  // Graphics
  var metadata:FlxTypedGroup<FlxText>;
  var metadataPractice:FlxText;
  var menuEntryText:FlxTypedGroup<AtlasText>;

  // Audio
  var pauseMusic:FunkinSound;

  public function new(?params:PauseSubStateParams)
  {
    super();
    this.currentMode = params?.mode ?? PauseMode.Standard;

    this.bgColor = FlxColor.TRANSPARENT; // Transparent, fades into black later.
  }

  public override function create():Void
  {
    super.create();

    startPauseMusic();

    buildMetadata();

    transitionIn();
  }

  public override function update(elapsed:Float):Void
  {
    super.update(elapsed);

    handleInputs();
  }

  function startPauseMusic():Void
  {
    pauseMusic = FunkinSound.load(Paths.music('breakfast-pixel'), true, true);

    // Start playing at a random point in the song.
    pauseMusic.play(false, FlxG.random.int(0, Std.int(pauseMusic.length / 2)));
    pauseMusic.fadeIn(MUSIC_FADE_IN_TIME, 0, MUSIC_FINAL_VOLUME);
  }

  /**
   * Render the metadata in the top right.
   */
  function buildMetadata():Void
  {
    metadata = new FlxTypedGroup<FlxSprite>();
    add(metadata);

    var metadataSong:FlxText = new FlxText(20, 15, 0, 'Song Name - Artist');
    metadataSong.setFormat(Paths.font('vcr.ttf'), 32, FlxColor.WHITE, FlxTextAlign.RIGHT);
    if (PlayState.instance?.currentChart != null)
    {
      metadataSong.text += '${PlayState.instance.currentChart.songName} - ${PlayState.instance.currentChart.songArtist}';
    }
    metadata.add(metadataSong);

    var metadataDifficulty:FlxText = new FlxText(20, 15 + 32, 0, 'Difficulty');
    metadataDifficulty.setFormat(Paths.font('vcr.ttf'), 32, FlxColor.WHITE, FlxTextAlign.RIGHT);
    if (PlayState.instance?.currentDifficulty != null)
    {
      metadataDifficulty.text += PlayState.instance.currentDifficulty.toTitleCase();
    }
    metadata.add(metadataDifficulty);

    var metadataDeaths:FlxText = new FlxText(20, 15 + 64, 0, '0 Blue Balls');
    metadataDeaths.setFormat(Paths.font('vcr.ttf'), 32, FlxColor.WHITE, FlxTextAlign.RIGHT);
    metadataDeaths.text = '${PlayState.instance?.deathCounter} Blue Balls';
    metadata.add(metadataDeaths);

    metadataPractice = new FlxText(20, 15 + 96, 0, 'PRACTICE MODE');
    metadataPractice.setFormat(Paths.font('vcr.ttf'), 32, FlxColor.WHITE, FlxTextAlign.RIGHT);
    metadataPractice.visible = PlayState.instance?.isPracticeMode ?? false;
    metadata.add(metadataPractice);
  }

  function regenerateMenu(?targetMode:PauseMode):Void
  {
    var previousMode:PauseMode = this.currentMode;
    this.currentMode = targetMode ?? this.currentMode;
    this.currentEntry = 0;

    menuEntryText.clear();

    // Choose the correct menu entries.
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
          var difficultiesInVariation = PlayState.instance.currentSong.listDifficulties(PlayState.instance.currentChart.variation);
          trace('DIFFICULTIES: ${difficultiesInVariation}');
          for (difficulty in difficultiesInVariation)
          {
            difficulties.push({text: difficulty.toTitleCase(), callback: () -> changeDifficulty(this, difficulty)});
          }
        }

        // Add the back button.
        currentMenuEntries = entries.concat(PAUSE_MENU_ENTRIES_DIFFICULTY.clone());
      case PauseMode.Cutscene:
        currentMenuEntries = PAUSE_MENU_ENTRIES_CUTSCENE.clone();
    }

    // Render out the entries depending on the mode.
    for (entryIndex in 0...entries)
    {
      var entry:PauseMenuEntry = entries[entryIndex];

      // Remove entries that should be hidden.
      if (entry.filter != null && !entry.filter()) currentMenuEntries.remove(entry);

      var yPos:Float = 70 * entryIndex + 30;
      var text:AtlasText = new AtlasText(0, yPos, entry.text, AtlasFont.BOLD);
      text.alpha = 0;
      menuEntryText.add(text);

      entry.sprite = text;
    }

    metadataPractice.visible = PlayState.instance?.isPracticeMode ?? false;

    changeSelection();
  }

  function transitionIn():Void
  {
    FlxTween.globalManager.bgColor(this, 0.4, FlxColor.fromRGB(0, 0, 0, 0.0), FlxColor.fromRGB(0, 0, 0, 0.6), {ease: FlxEase.quartInOut});

    // Animate each element a little bit downwards.
    var delay:Float = 0.3;
    for (child in metadata.members)
    {
      FlxTween.tween(child, {alpha: 1, y: child.y + 5}, 0.4, {ease: FlxEase.quartInOut, startDelay: delay});
      delay += 0.2;
    }
  }

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
    if (controls.PAUSE)
    {
      resume(this);
    }
    if (controls.ACCEPT)
    {
      menuEntries[currentEntry].callback(this);
    }

    #if (debug || FORCE_DEBUG_VERSION)
    // to pause the game and get screenshots easy, press H on pause menu!
    if (FlxG.keys.justPressed.H)
    {
      var visible = !metaDataGrp.visible;
      metadata = visible;
      menuEntryText = visible;
      this.bgColor = visible ? 0x99000000 : 0x00000000; // 60% or fully transparent black
    }
    #end
  }

  function changeSelection(change:Int = 0):Void
  {
    FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);

    currentEntry += change;

    if (currentEntry < 0) currentEntry = menuEntries.length - 1;
    if (currentEntry >= menuEntries.length) currentEntry = 0;

    for (entryIndex in 0...menuEntries.length)
    {
      var isCurrent:Bool = entryIndex == currentEntry;

      var entry:PauseMenuEntry = menuEntries[entryIndex];
      var text:AtlasText = entry.sprite;

      // Set the transparency.
      text.alpha = isCurrent ? 1.0 : 0.6;

      // Set the position.
      var targetX = FlxMath.remapToRange((entryIndex - currentEntry), 0, 1, 0, 1.3) * 20 + 90;
      var targetY = FlxMath.remapToRange((entryIndex - currentEntry), 0, 1, 0, 1.3) * 120 + (FlxG.height * 0.48);
      FlxTween.tween(text, {x: targetX, y: targetY}, 0.16, {ease: FlxEase.linear});
    }
  }

  // ===============
  // Menu Callbacks
  // ===============
  static function resume(state:PauseSubState):Void
  {
    state.close();
  }

  static function switchMode(state:PauseSubState, targetMode:PauseMode):Void
  {
    state.regenerateMenu(targetMode);
  }

  static function changeDifficulty(state:PauseSubState, difficulty:String):Void
  {
    PlayState.instance.currentSong = SongRegistry.instance.fetchEntry(PlayState.instance.currentSong.id.toLowerCase());

    // Reset campaign score when changing difficulty
    // So if you switch difficulty on the last song of a week you get a really low overall score.
    PlayStatePlaylist.campaignScore = 0;
    PlayStatePlaylist.campaignDifficulty = difficulty;
    PlayState.instance.currentDifficulty = PlayStatePlaylist.campaignDifficulty;

    PlayState.instance.needsReset = true;

    state.close();
  }

  static function restartPlayState(state:PauseSubState):Void
  {
    PlayState.instance.needsReset = true;
    state.close();
  }

  static function enablePracticeMode(state:PauseSubState):Void
  {
    if (PlayState.instance == null) return;

    PlayState.instance.isPracticeMode = true;
    regenerateMenu();
  }

  static function quitToMenu(state:PauseSubState):Void
  {
    state.allowInput = false;

    PlayState.instance.deathCounter = 0;

    FlxTransitionableState.skipNextTransIn = true;
    FlxTransitionableState.skipNextTransOut = true;

    if (PlayStatePlaylist.isStoryMode)
    {
      PlayStatePlaylist.reset();
      openSubState(new funkin.ui.transition.StickerSubState(null, (sticker) -> new funkin.ui.story.StoryMenuState(sticker)));
    }
    else
    {
      openSubState(new funkin.ui.transition.StickerSubState(null, (sticker) -> new funkin.ui.freeplay.FreeplayState(null, sticker)));
    }
  }

  static function quitToChartEditor(state:PauseSubState):Void
  {
    state.close();
    if (FlxG.sound.music != null) FlxG.sound.music.pause(); // Don't reset song position!
    PlayState.instance.close(); // This only works because PlayState is a substate!
  }

  /**
   * Reset the pause configuration to the default.
   */
  public static function reset():Void
  {
    musicSuffix = '';
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
   * The menu displayed when the player pauses the game during a cutscene.
   */
  Cutscene;
}

typedef PauseMenuEntry =
{
  var text:String;
  var callback:PauseSubState->Void;

  var ?sprite:AtlasText;

  /**
   * If this returns true, the entry will be displayed. If it returns false, the entry will be hidden.
   */
  var ?filter:Void->Bool;
};
