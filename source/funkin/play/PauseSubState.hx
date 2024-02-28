package funkin.play;

import flixel.addons.transition.FlxTransitionableState;
import flixel.FlxG;
import flixel.util.FlxTimer;
import flixel.FlxSprite;
import flixel.group.FlxSpriteGroup;
import flixel.math.FlxMath;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import funkin.audio.FunkinSound;
import funkin.data.song.SongRegistry;
import funkin.graphics.FunkinSprite;
import funkin.play.cutscene.VideoCutscene;
import funkin.play.PlayState;
import funkin.ui.AtlasText;
import funkin.ui.MusicBeatSubState;
import funkin.ui.transition.StickerSubState;

typedef PauseSubStateParams =
{
  ?mode:PauseMode,
};

/**
 * The menu displayed when the Play State is paused.
 */
class PauseSubState extends MusicBeatSubState
{
  static final PAUSE_MENU_ENTRIES_STANDARD:Array<PauseMenuEntry> = [
    {text: 'Resume', callback: resume},
    {text: 'Restart Song', callback: restartPlayState},
    {text: 'Change Difficulty', callback: switchMode.bind(_, Difficulty)},
    {text: 'Enable Practice Mode', callback: enablePracticeMode, filter: () -> !(PlayState.instance?.isPracticeMode ?? false)},
    {text: 'Exit to Menu', callback: quitToMenu},
  ];

  static final PAUSE_MENU_ENTRIES_CHARTING:Array<PauseMenuEntry> = [
    {text: 'Resume', callback: resume},
    {text: 'Restart Song', callback: restartPlayState},
    {text: 'Return to Chart Editor', callback: quitToChartEditor},
  ];

  static final PAUSE_MENU_ENTRIES_DIFFICULTY:Array<PauseMenuEntry> = [
    {text: 'Back', callback: switchMode.bind(_, Standard)}
    // Other entries are added dynamically.
  ];

  static final PAUSE_MENU_ENTRIES_VIDEO_CUTSCENE:Array<PauseMenuEntry> = [
    {text: 'Resume', callback: resume},
    {text: 'Restart Cutscene', callback: restartVideoCutscene},
    {text: 'Skip Cutscene', callback: skipVideoCutscene},
    {text: 'Exit to Menu', callback: quitToMenu},
  ];

  static final PAUSE_MENU_ENTRIES_CONVERSATION:Array<PauseMenuEntry> = [
    {text: 'Resume', callback: resume},
    {text: 'Restart Dialogue', callback: restartConversation},
    {text: 'Skip Dialogue', callback: skipConversation},
    {text: 'Exit to Menu', callback: quitToMenu},
  ];

  static final MUSIC_FADE_IN_TIME:Float = 50;
  static final MUSIC_FINAL_VOLUME:Float = 0.5;

  public static var musicSuffix:String = '';

  // Status
  var currentMenuEntries:Array<PauseMenuEntry>;
  var currentEntry:Int = 0;
  var currentMode:PauseMode;

  /**
   * Disallow input until the transition in is complete!
   * This prevents the pause menu from immediately closing.
   */
  public var allowInput:Bool = false;

  // Graphics
  var background:FunkinSprite;
  var metadata:FlxTypedSpriteGroup<FlxText>;
  var metadataPractice:FlxText;
  var metadataDeaths:FlxText;
  var menuEntryText:FlxTypedSpriteGroup<AtlasText>;

  // Audio
  var pauseMusic:FunkinSound;

  public function new(?params:PauseSubStateParams)
  {
    super();
    this.currentMode = params?.mode ?? Standard;
  }

  public override function create():Void
  {
    super.create();

    startPauseMusic();

    buildBackground();

    buildMetadata();

    menuEntryText = new FlxTypedSpriteGroup<AtlasText>();
    menuEntryText.scrollFactor.set(0, 0);
    add(menuEntryText);

    regenerateMenu();

    transitionIn();
  }

  public override function update(elapsed:Float):Void
  {
    super.update(elapsed);

    handleInputs();
  }

  public override function destroy():Void
  {
    super.destroy();
    pauseMusic.stop();
  }

  function startPauseMusic():Void
  {
    pauseMusic = FunkinSound.load(Paths.music('breakfast$musicSuffix'), true, true);

    // Start playing at a random point in the song.
    pauseMusic.play(false, FlxG.random.int(0, Std.int(pauseMusic.length / 2)));
    pauseMusic.fadeIn(MUSIC_FADE_IN_TIME, 0, MUSIC_FINAL_VOLUME);
  }

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

    var metadataSong:FlxText = new FlxText(20, 15, FlxG.width - 40, 'Song Name - Artist');
    metadataSong.setFormat(Paths.font('vcr.ttf'), 32, FlxColor.WHITE, FlxTextAlign.RIGHT);
    if (PlayState.instance?.currentChart != null)
    {
      metadataSong.text = '${PlayState.instance.currentChart.songName} - ${PlayState.instance.currentChart.songArtist}';
    }
    metadataSong.scrollFactor.set(0, 0);
    metadata.add(metadataSong);

    var metadataDifficulty:FlxText = new FlxText(20, 15 + 32, FlxG.width - 40, 'Difficulty: ');
    metadataDifficulty.setFormat(Paths.font('vcr.ttf'), 32, FlxColor.WHITE, FlxTextAlign.RIGHT);
    if (PlayState.instance?.currentDifficulty != null)
    {
      metadataDifficulty.text += PlayState.instance.currentDifficulty.toTitleCase();
    }
    metadataDifficulty.scrollFactor.set(0, 0);
    metadata.add(metadataDifficulty);

    metadataDeaths = new FlxText(20, 15 + 64, FlxG.width - 40, '${PlayState.instance?.deathCounter} Blue Balls');
    metadataDeaths.setFormat(Paths.font('vcr.ttf'), 32, FlxColor.WHITE, FlxTextAlign.RIGHT);
    metadataDeaths.scrollFactor.set(0, 0);
    metadata.add(metadataDeaths);

    metadataPractice = new FlxText(20, 15 + 96, FlxG.width - 40, 'PRACTICE MODE');
    metadataPractice.setFormat(Paths.font('vcr.ttf'), 32, FlxColor.WHITE, FlxTextAlign.RIGHT);
    metadataPractice.visible = PlayState.instance?.isPracticeMode ?? false;
    metadataPractice.scrollFactor.set(0, 0);
    metadata.add(metadataPractice);

    updateMetadataText();
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

    updateMetadataText();

    changeSelection();
  }

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

  function transitionIn():Void
  {
    FlxTween.tween(background, {alpha: 0.6}, 0.4, {ease: FlxEase.quartInOut});

    // Animate each element a little bit downwards.
    var delay:Float = 0.1;
    for (child in metadata.members)
    {
      FlxTween.tween(child, {alpha: 1, y: child.y + 5}, 0.4, {ease: FlxEase.quartInOut, startDelay: delay});
      delay += 0.05;
    }

    new FlxTimer().start(0.2, (_) -> {
      allowInput = true;
    });
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

    if (controls.ACCEPT)
    {
      currentMenuEntries[currentEntry].callback(this);
    }
    else if (controls.PAUSE)
    {
      resume(this);
    }

    #if (debug || FORCE_DEBUG_VERSION)
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

  function changeSelection(change:Int = 0):Void
  {
    FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);

    currentEntry += change;

    if (currentEntry < 0) currentEntry = currentMenuEntries.length - 1;
    if (currentEntry >= currentMenuEntries.length) currentEntry = 0;

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
      trace(targetY);
      FlxTween.tween(text, {x: targetX, y: targetY}, 0.16, {ease: FlxEase.linear});
    }
  }

  // ===============
  // Menu Callbacks
  // ===============
  static function resume(state:PauseSubState):Void
  {
    // Resume a paused video if it exists.
    VideoCutscene.resumeVideo();

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
    state.regenerateMenu();
  }

  static function restartVideoCutscene(state:PauseSubState):Void
  {
    VideoCutscene.restartVideo();
    state.close();
  }

  static function skipVideoCutscene(state:PauseSubState):Void
  {
    VideoCutscene.finishVideo();
    state.close();
  }

  static function restartConversation(state:PauseSubState):Void
  {
    if (PlayState.instance?.currentConversation == null) return;

    PlayState.instance.currentConversation.resetConversation();
    state.close();
  }

  static function skipConversation(state:PauseSubState):Void
  {
    if (PlayState.instance?.currentConversation == null) return;

    PlayState.instance.currentConversation.skipConversation();
    state.close();
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
      state.openSubState(new funkin.ui.transition.StickerSubState(null, (sticker) -> new funkin.ui.story.StoryMenuState(sticker)));
    }
    else
    {
      state.openSubState(new funkin.ui.transition.StickerSubState(null, (sticker) -> new funkin.ui.freeplay.FreeplayState(null, sticker)));
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
   * The menu displayed when the player pauses the game during a conversation.
   */
  Conversation;

  /**
   * The menu displayed when the player pauses the game during a video cutscene.
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
