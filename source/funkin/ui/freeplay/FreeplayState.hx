package funkin.ui.freeplay;

import flixel.FlxCamera;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.addons.transition.FlxTransitionableState;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.group.FlxSpriteGroup.FlxTypedSpriteGroup;
import flixel.math.FlxMath;
import flixel.math.FlxPoint;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import openfl.filters.ShaderFilter;
import flixel.util.FlxTimer;
import funkin.audio.FunkinSound;
import funkin.data.freeplay.player.PlayerRegistry;
import funkin.data.freeplay.style.FreeplayStyleRegistry;
import funkin.data.song.SongRegistry;
import funkin.data.story.level.LevelRegistry;
import funkin.effects.IntervalShake;
import funkin.graphics.FunkinCamera;
import funkin.graphics.FunkinSprite;
import funkin.graphics.shaders.AngleMask;
import funkin.graphics.shaders.BlueFade;
import funkin.graphics.shaders.HSVShader;
import funkin.graphics.shaders.PureColor;
import funkin.graphics.shaders.StrokeShader;
import funkin.input.Controls;
import funkin.modding.events.ScriptEvent;
import funkin.modding.events.ScriptEventDispatcher;
import funkin.play.PlayStatePlaylist;
import funkin.play.scoring.Scoring.ScoringRank;
import funkin.play.song.Song;
import funkin.save.Save;
import funkin.save.Save.SaveScoreData;
import funkin.ui.AtlasText;
import funkin.ui.FullScreenScaleMode;
import funkin.ui.MusicBeatSubState;
import funkin.ui.freeplay.backcards.*;
import funkin.ui.freeplay.components.DifficultySprite;
import funkin.ui.freeplay.charselect.PlayableCharacter;
import funkin.ui.mainmenu.MainMenuState;
import funkin.ui.story.Level;
import funkin.ui.transition.LoadingState;
import funkin.ui.transition.stickers.StickerSubState;
import funkin.util.HapticUtil;
import funkin.util.MathUtil;
import funkin.util.SortUtil;
import openfl.display.BlendMode;
import funkin.ui.freeplay.DifficultyDot;
import funkin.ui.debug.charting.ChartEditorState;
#if FEATURE_DISCORD_RPC
import funkin.api.discord.DiscordClient;
#end
#if FEATURE_TOUCH_CONTROLS
import funkin.util.TouchUtil;
import funkin.util.SwipeUtil;
import funkin.mobile.input.ControlsHandler;
#end

/**
 * The state for the freeplay menu, allowing the player to select any song to play.
 */
@:nullSafety
class FreeplayState extends MusicBeatSubState
{
  //
  // Params
  //

  /**
   * The current character for this FreeplayState.
   * You can't change this without transitioning to a new FreeplayState.
   */
  final currentCharacterId:String;

  final currentCharacter:PlayableCharacter;

  /**
   * For the audio preview, the duration of the fade-in effect.
   */
  public static final FADE_IN_DURATION:Float = 0.5;

  /**
   * For the audio preview, the duration of the fade-out effect.
   *
   */
  public static final FADE_OUT_DURATION:Float = 0.25;

  /**
   * For the audio preview, the volume at which the fade-in starts.
   */
  public static final FADE_IN_START_VOLUME:Float = 0.25;

  /**
   * For the audio preview, the volume at which the fade-in ends.
   */
  public static final FADE_IN_END_VOLUME:Float = 1.0;

  /**
   * For the audio preview, the volume at which the fade-out starts.
   */
  public static final FADE_OUT_END_VOLUME:Float = 0.0;

  /**
   * For scaling some sprites on wide displays.
   */
  public static var CUTOUT_WIDTH:Float = FullScreenScaleMode.gameCutoutSize.x / 1.5;

  /**
   * For positioning the DJ on wide displays.
   */
  public static final DJ_POS_MULTI:Float = 0.44;

  /**
   * For positioning the songs list on wide displays.
   */
  public static final SONGS_POS_MULTI:Float = 0.75;

  var songs:Array<Null<FreeplaySongData>> = [];

  var curSelected:Int = 0;
  // curSelectedFloat is used for mobile to get "inbetween" selections for swipe/scrolling/momentum stuff
  var curSelectedFloat:Float = 0;

  /**
   * Currently selected difficulty, in string form.
   */
  var currentDifficulty:String = Constants.DEFAULT_DIFFICULTY;

  /**
   *  Current variation: default, erect, pico, bf, etc.
   */
  var currentVariation:String = Constants.DEFAULT_VARIATION;

  public var fp:FreeplayScore;

  var txtCompletion:AtlasText;
  var lerpCompletion:Float = 0;
  var intendedCompletion:Float = 0;
  var lerpScore:Float = 0;
  var intendedScore:Int = 0;

  var grpDifficulties:FlxTypedSpriteGroup<DifficultySprite>;
  var difficultyDots:FlxTypedSpriteGroup<DifficultyDot>;

  /**
   * Bit of a utility var to get the currently displayed DifficultySprite
   *
   * The getter looks like this
   * `return grpDifficulties.members.filter(d -> d.difficultyId == currentDifficulty)[0];`
   */
  var currentDifficultySprite(get, never):DifficultySprite;

  function get_currentDifficultySprite():DifficultySprite
  {
    return grpDifficulties.members.filter(d -> d.difficultyId == currentDifficulty)[0];
  }

  /**
   * Another utility var, this one gets our current selected capsule easily
   */
  var currentCapsule(get, never):SongMenuItem;

  function get_currentCapsule():SongMenuItem
  {
    return grpCapsules.members[curSelected];
  }

  var coolColors:Array<Int> = [
    0xFF9271FD,
    0xFF9271FD,
    0xFF223344,
    0xFF941653,
    0xFFFC96D7,
    0xFFA0D1FF,
    0xFFFF78BF,
    0xFFF6B604
  ];

  var grpCapsules:FlxTypedGroup<SongMenuItem>;

  var dj:Null<FreeplayDJ> = null;
  #if FEATURE_TOUCH_CONTROLS
  // For proper hitbox detection, flxanimate doesn't work with touch overlap!!
  var djHitbox:FlxObject = new FlxObject((CUTOUT_WIDTH * DJ_POS_MULTI), 320, 400, 400);
  var capsuleHitbox:FlxObject = new FlxObject((CUTOUT_WIDTH * SONGS_POS_MULTI) + 380, 150, CUTOUT_WIDTH + 590, 576);
  #end

  var ostName:FlxText;
  var albumRoll:AlbumRoll;

  var charSelectHint:FlxText;

  var letterSort:LetterSort;
  var exitMovers:ExitMoverData = new Map();

  var diffSelLeft:DifficultySelector;
  var diffSelRight:DifficultySelector;

  var exitMoversCharSel:ExitMoverData = new Map();

  var stickerSubState:Null<StickerSubState> = null;

  /**
   * The difficulty we were on when this menu was last accessed.
   */
  public static var rememberedDifficulty:String = Constants.DEFAULT_DIFFICULTY;

  /**
   * The song we were on when this menu was last accessed.
   * NOTE: `null` if the last song was `Random`.
   */
  public static var rememberedSongId:Null<String> = 'tutorial';

  /**
   * The character we were on when this menu was last accessed.
   */
  public static var rememberedCharacterId:String = Constants.DEFAULT_CHARACTER;

  /**
   * The remembered variation we were on when this menu was last accessed.
   */
  public static var rememberedVariation:String = Constants.DEFAULT_VARIATION;

  public var funnyCam:FunkinCamera;

  var rankCamera:FunkinCamera;
  var rankBg:FunkinSprite;
  var rankVignette:FlxSprite;

  // We can use this without doing Null<BackingCard> because we initialize it in new()

  /**
   * The card behind the DJ !
   */
  var backingCard:BackingCard;

  /**
   * The backing card that has the toned dots, right now we just use that one dad graphic dave cooked up
   */
  public var backingImage:FunkinSprite;

  public var angleMaskShader:AngleMask = new AngleMask();

  var fadeShader:BlueFade = new BlueFade();

  var fromResultsParams:Null<FromResultsParams> = null;
  var prepForNewRank:Bool = false;
  var styleData:Null<FreeplayStyle> = null;
  var fromCharSelect:Bool = false;

  public var freeplayArrow:Null<FlxText>;

  public function new(?params:FreeplayStateParams, ?stickers:StickerSubState)
  {
    var fetchPlayableCharacter = function():PlayableCharacter {
      var targetCharId = params?.character ?? rememberedCharacterId;
      var result = PlayerRegistry.instance.fetchEntry(targetCharId);
      if (result == null)
      {
        trace('No valid playable character with id ${targetCharId}');
        result = PlayerRegistry.instance.fetchEntry(Constants.DEFAULT_CHARACTER);
        if (result == null) throw 'WTH your default character is null?????';
      }
      return result;
    };

    currentCharacter = fetchPlayableCharacter();
    currentCharacterId = currentCharacter.id;

    currentVariation = rememberedVariation;
    currentDifficulty = rememberedDifficulty;
    styleData = FreeplayStyleRegistry.instance.fetchEntry(currentCharacter.getFreeplayStyleID());
    rememberedCharacterId = currentCharacter?.id ?? Constants.DEFAULT_CHARACTER;

    fromCharSelect = params?.fromCharSelect ?? false;
    fromResultsParams = params?.fromResults;
    prepForNewRank = fromResultsParams?.playRankAnim ?? false;

    super(FlxColor.TRANSPARENT);

    if (stickers?.members != null) stickerSubState = stickers;

    var backingCardPrep:Null<BackingCard> = null;

    if (PlayerRegistry.instance.hasNewCharacter())
    {
      backingCardPrep = new NewCharacterCard(currentCharacterId);
    }
    else
    {
      var allScriptedCards:Array<String> = ScriptedBackingCard.listScriptClasses();
      for (cardClass in allScriptedCards)
      {
        var card:BackingCard = ScriptedBackingCard.init(cardClass, "unknown");
        if (card.currentCharacter == currentCharacterId)
        {
          backingCardPrep = card;
          break;
        }
      }
    }
    // Return the default backing card if there isn't one specific for the character.

    backingCard = backingCardPrep ?? new BackingCard(currentCharacterId);

    // We build a bunch of sprites BEFORE create() so we can guarantee they aren't null later on.
    albumRoll = new AlbumRoll();
    fp = new FreeplayScore(FlxG.width - (FullScreenScaleMode.gameNotchSize.x + 353), 60, 7, 100, styleData);
    rankCamera = new FunkinCamera('rankCamera', 0, 0, FlxG.width, FlxG.height);
    funnyCam = new FunkinCamera('freeplayFunny', 0, 0, FlxG.width, FlxG.height);
    grpCapsules = new FlxTypedGroup<SongMenuItem>();
    grpDifficulties = new FlxTypedSpriteGroup<DifficultySprite>(-300, 80);

    difficultyDots = new FlxTypedSpriteGroup<DifficultyDot>(203, 170);
    letterSort = new LetterSort((CUTOUT_WIDTH * SONGS_POS_MULTI) + 400, 75);
    rankBg = new FunkinSprite(0, 0);
    rankVignette = new FlxSprite(0, 0).loadGraphic(Paths.image('freeplay/rankVignette'));
    sparks = new FlxSprite(0, 0);
    sparksADD = new FlxSprite(0, 0);
    txtCompletion = new AtlasText(FlxG.width - (FullScreenScaleMode.gameNotchSize.x + 95), 87, '69', AtlasFont.FREEPLAY_CLEAR);

    ostName = new FlxText(8 - FullScreenScaleMode.gameNotchSize.x, 8, FlxG.width - 8 - 8, 'OFFICIAL OST', 48);
    charSelectHint = new FlxText(-40, 18, FlxG.width - 8 - 8, 'Press [ LOL ] to change characters', 32);

    backingImage = FunkinSprite.create(backingCard.pinkBack.width * 0.74, 0, styleData == null ? 'freeplay/freeplayBGweek1-bf' : styleData.getBgAssetKey());

    // TODO: refactor DifficultySelector to *not* use `this` as input? Handle it's animations and style data in different manner
    diffSelLeft = new DifficultySelector((CUTOUT_WIDTH * DJ_POS_MULTI) + 20, grpDifficulties.y - 10, false, controls, styleData);
    diffSelRight = new DifficultySelector((CUTOUT_WIDTH * DJ_POS_MULTI) + 325, grpDifficulties.y - 10, true, controls, styleData);
  }

  override function create():Void
  {
    super.create();

    FlxG.state.persistentUpdate = false;
    FlxTransitionableState.skipNextTransIn = true;

    var fadeShaderFilter:ShaderFilter = new ShaderFilter(fadeShader);
    funnyCam.filters = [fadeShaderFilter];

    if (stickerSubState != null)
    {
      this.persistentUpdate = true;
      this.persistentDraw = true;

      openSubState(stickerSubState);
      stickerSubState.degenStickers();
    }

    #if FEATURE_DISCORD_RPC
    // Updating Discord Rich Presence
    DiscordClient.instance.setPresence({state: 'In the Menus', details: null});
    #end

    // Block input until the intro finishes.
    controls.active = false;

    // Add a null entry that represents the RANDOM option
    songs.push(null);

    // programmatically adds the songs via LevelRegistry and SongRegistry
    for (levelId in LevelRegistry.instance.listSortedLevelIds())
    {
      var level:Null<Level> = LevelRegistry.instance.fetchEntry(levelId);

      if (level == null)
      {
        trace('[WARN] Could not find level with id (${levelId})');
        continue;
      }

      for (songId in level.getSongs())
      {
        var song:Null<Song> = SongRegistry.instance.fetchEntry(songId);

        if (song == null)
        {
          trace('[WARN] Could not find song with id (${songId})');
          continue;
        }

        songs.push(new FreeplaySongData(song, level));
      }
    }

    // LOAD MUSIC

    // LOAD CHARACTERS

    trace(FlxG.width);
    trace(FlxG.camera.zoom);
    trace(FlxG.camera.initialZoom);
    trace(FlxCamera.defaultZoom);

    backingCard.instance = this;
    add(backingCard);
    ScriptEventDispatcher.callEvent(backingCard, new ScriptEvent(CREATE, false));
    backingCard.applyExitMovers(exitMovers, exitMoversCharSel);

    if (currentCharacter?.getFreeplayDJData() != null)
    {
      dj = new FreeplayDJ((CUTOUT_WIDTH * DJ_POS_MULTI) + 640, 366, currentCharacterId);
      exitMovers.set([dj],
        {
          x: -dj.width * 1.6,
          speed: 0.5
        });
      add(dj);
      exitMoversCharSel.set([dj],
        {
          y: -175,
          speed: 0.8,
          wait: 0.1
        });
    }

    backingImage.shader = angleMaskShader;
    backingImage.visible = false;

    #if FEATURE_TOUCH_CONTROLS
    if (dj != null) djHitbox.cameras = dj.cameras;
    djHitbox.active = false;
    add(djHitbox);
    capsuleHitbox.cameras = [funnyCam];
    capsuleHitbox.active = false;
    add(capsuleHitbox);
    #end

    var blackOverlayBullshitLOLXD:FlxSprite = new FlxSprite(FlxG.width).makeGraphic(Std.int(backingImage.width), Std.int(backingImage.height), FlxColor.BLACK);
    add(blackOverlayBullshitLOLXD); // used to mask the text lol!

    // this makes the texture sizes consistent, for the angle shader
    backingImage.setGraphicSize(0, FlxG.height);
    blackOverlayBullshitLOLXD.setGraphicSize(0, FlxG.height);

    backingImage.updateHitbox();
    blackOverlayBullshitLOLXD.updateHitbox();

    exitMovers.set([blackOverlayBullshitLOLXD, backingImage],
      {
        x: FlxG.width * 1.5,
        speed: 0.4,
        wait: 0
      });

    exitMoversCharSel.set([blackOverlayBullshitLOLXD, backingImage],
      {
        y: -100,
        speed: 0.8,
        wait: 0.1
      });
    add(grpDifficulties);
    add(difficultyDots);
    add(backingImage);
    // backingCard.pinkBack.width * 0.74

    blackOverlayBullshitLOLXD.shader = backingImage.shader;

    rankBg.makeSolidColor(FlxG.width, FlxG.height, 0xD3000000);
    add(rankBg);

    add(grpCapsules);

    exitMovers.set([grpDifficulties],
      {
        x: -300,
        speed: 0.25,
        wait: 0
      });

    exitMoversCharSel.set([grpDifficulties],
      {
        y: -270,
        speed: 0.8,
        wait: 0.1
      });

    for (diffId in Constants.DEFAULT_DIFFICULTY_LIST_FULL)
    {
      var diffSprite:DifficultySprite = new DifficultySprite(diffId);
      diffSprite.visible = diffId == Constants.DEFAULT_DIFFICULTY;
      diffSprite.height *= 2.5;
      grpDifficulties.add(diffSprite);
    }

    for (i in 0...Constants.DEFAULT_DIFFICULTY_LIST_FULL.length)
    {
      var dot:DifficultyDot = new DifficultyDot(Constants.DEFAULT_DIFFICULTY_LIST_FULL[i], i);
      difficultyDots.add(dot);
    }

    albumRoll.albumId = null;
    albumRoll.applyExitMovers(exitMovers, exitMoversCharSel);
    add(albumRoll);

    var overhangStuff:FlxSprite = new FlxSprite().makeGraphic(FlxG.width, 164, FlxColor.BLACK);
    overhangStuff.y -= overhangStuff.height;

    if (fromCharSelect)
    {
      blackOverlayBullshitLOLXD.x = backingImage.x;
      overhangStuff.y = -100;
      backingCard.skipIntroTween();
    }
    else
    {
      FlxTween.tween(overhangStuff, {y: -100}, 0.3, {ease: FlxEase.quartOut});
      FlxTween.tween(blackOverlayBullshitLOLXD, {x: backingImage.x}, 0.7, {ease: FlxEase.quintOut});
    }

    var topLeftCornerText:FlxText = new FlxText(Math.max(FullScreenScaleMode.gameNotchSize.x, 8), 8, 0, 'FREEPLAY', 48);
    topLeftCornerText.font = 'VCR OSD Mono';
    topLeftCornerText.visible = false;

    var freeplayTxtBg:FlxSprite = new FlxSprite().makeGraphic(Math.round(topLeftCornerText.width + 16), Math.round(topLeftCornerText.height + 16),
      FlxColor.BLACK);
    freeplayTxtBg.x = topLeftCornerText.x - 8;
    freeplayTxtBg.visible = false;

    freeplayArrow = new FlxText(Math.max(FullScreenScaleMode.gameNotchSize.x, 8), 8, 0, '<---', 48);
    freeplayArrow.font = 'VCR OSD Mono';
    freeplayArrow.visible = false;

    ostName.font = 'VCR OSD Mono';
    ostName.alignment = RIGHT;
    ostName.visible = false;

    charSelectHint.alignment = CENTER;
    charSelectHint.font = "5by7";
    charSelectHint.color = 0xFF5F5F5F;
    #if FEATURE_TOUCH_CONTROLS
    if (ControlsHandler.usingExternalInputDevice)
      charSelectHint.text = 'Press [ ${controls.getDialogueNameFromControl(FREEPLAY_CHAR_SELECT, true)} ] to change characters';
    else
      charSelectHint.text = 'Tap the DJ to change characters';
    #else
    charSelectHint.text = 'Press [ ${controls.getDialogueNameFromControl(FREEPLAY_CHAR_SELECT, true)} ] to change characters';
    #end
    if (!fromCharSelect)
    {
      charSelectHint.y -= 100;
      FlxTween.tween(charSelectHint, {y: charSelectHint.y + 100}, 0.8, {ease: FlxEase.quartOut});
    }

    exitMovers.set([
      overhangStuff,
      topLeftCornerText,
      ostName,
      charSelectHint,
      freeplayTxtBg,
      freeplayArrow
    ],
      {
        y: -overhangStuff.height,
        x: 0,
        speed: 0.2,
        wait: 0
      });

    exitMoversCharSel.set([
      overhangStuff,
      topLeftCornerText,
      ostName,
      charSelectHint,
      freeplayTxtBg,
      freeplayArrow
    ],
      {
        y: -300,
        speed: 0.8,
        wait: 0.1
      });

    var sillyStroke:StrokeShader = new StrokeShader(0xFFFFFFFF, 2, 2);
    topLeftCornerText.shader = sillyStroke;
    freeplayArrow.shader = sillyStroke;
    ostName.shader = sillyStroke;

    var fnfHighscoreSpr:FlxSprite = new FlxSprite(FlxG.width - (FullScreenScaleMode.gameNotchSize.x + 420), 70);
    fnfHighscoreSpr.frames = Paths.getSparrowAtlas('freeplay/highscore');
    fnfHighscoreSpr.animation.addByPrefix('highscore', 'highscore small instance 1', 24, false);
    fnfHighscoreSpr.visible = false;
    fnfHighscoreSpr.setGraphicSize(0, Std.int(fnfHighscoreSpr.height * 1));
    fnfHighscoreSpr.updateHitbox();
    add(fnfHighscoreSpr);

    new FlxTimer().start(FlxG.random.float(12, 50), function(tmr) {
      fnfHighscoreSpr.animation.play('highscore');
      tmr.time = FlxG.random.float(20, 60);
    }, 0);

    fp.visible = false;
    add(fp);

    var clearBoxSprite:FlxSprite = new FlxSprite(FlxG.width - (FullScreenScaleMode.gameNotchSize.x + 115), 65).loadGraphic(Paths.image('freeplay/clearBox'));
    clearBoxSprite.visible = false;
    add(clearBoxSprite);

    txtCompletion.visible = false;
    add(txtCompletion);

    add(letterSort);
    letterSort.visible = false;
    letterSort.instance = this;

    exitMovers.set([letterSort],
      {
        y: -100,
        speed: 0.3
      });

    exitMoversCharSel.set([letterSort],
      {
        y: -270,
        speed: 0.8,
        wait: 0.1
      });

    // Reminder, this is a callback function being set, rather than these being called here in create()
    letterSort.changeSelectionCallback = (str) -> {
      var curSong:Null<FreeplaySongData> = currentCapsule?.freeplayData;
      currentCapsule.selected = false;

      switch (str)
      {
        case 'fav':
          generateSongList({filterType: FAVORITE}, true, false);
        case 'ALL':
          generateSongList(null, true, false);
        case '#':
          generateSongList({filterType: REGEXP, filterData: '0-9'}, true, false);
        default:
          generateSongList({filterType: REGEXP, filterData: str}, true, false);
      }

      // If the current song is still in the list, or if it was random, we'll land on it
      // Otherwise we want to land on the first song of the group, rather than random song when changing letter sorts
      // that is, only if there's more than one song in the group!
      if (curSong == null || currentFilteredSongs.contains(curSong))
      {
        changeSelection();
      }
      else if (grpCapsules.members.length > 0)
      {
        curSelected = 1;
        changeSelection();
      }
    };

    exitMovers.set([fp, txtCompletion, fnfHighscoreSpr, clearBoxSprite],
      {
        x: FlxG.width,
        speed: 0.3
      });

    exitMoversCharSel.set([fp, txtCompletion, fnfHighscoreSpr, clearBoxSprite],
      {
        y: -270,
        speed: 0.8,
        wait: 0.1
      });

    diffSelLeft.visible = false;
    add(diffSelLeft);

    diffSelRight.visible = false;
    add(diffSelRight);

    // putting these here to fix the layering
    add(overhangStuff);
    add(freeplayArrow);
    add(freeplayTxtBg);
    add(topLeftCornerText);
    add(ostName);

    if (PlayerRegistry.instance.countUnlockedCharacters() > 1)
    {
      add(charSelectHint);
    }

    // be careful not to "add()" things in here unless it's to a group that's already added to the state
    // otherwise it won't be properly attatched to funnyCamera (relavent code should be at the bottom of create())
    var onDJIntroDone:Void->Void = function() {
      controls.active = true;

      // when boyfriend hits dat shiii

      albumRoll.playIntro();
      albumRoll.albumId = currentCapsule.freeplayData?.data.getAlbumId(currentDifficulty, currentVariation);

      if (!fromCharSelect)
      {
        // render optimisation
        if (_parentState != null) _parentState.persistentDraw = false;

        FlxTween.color(backingImage, 0.6, 0xFF000000, 0xFFFFFFFF,
          {
            ease: FlxEase.expoOut,
            onUpdate: function(_) {
              angleMaskShader.extraColor = backingImage.color;
            }
          });
      }

      FlxTween.cancelTweensOf(grpDifficulties);
      for (diff in grpDifficulties.group.members)
      {
        if (diff == null) continue;
        FlxTween.cancelTweensOf(diff);
        FlxTween.tween(diff, {x: (CUTOUT_WIDTH * DJ_POS_MULTI) + 90}, 0.6, {ease: FlxEase.quartOut});
        diff.y = 80;
        diff.visible = diff == currentDifficultySprite;
      }
      FlxTween.tween(grpDifficulties, {x: (CUTOUT_WIDTH * DJ_POS_MULTI) + 90}, 0.6, {ease: FlxEase.quartOut});

      diffSelLeft.visible = true;
      diffSelRight.visible = true;
      letterSort.visible = true;

      exitMovers.set([diffSelLeft, diffSelRight],
        {
          x: -diffSelLeft.width * 2,
          speed: 0.26
        });

      exitMoversCharSel.set([diffSelLeft, diffSelRight],
        {
          y: -270,
          speed: 0.8,
          wait: 0.1
        });

      new FlxTimer().start(1 / 24, function(handShit) {
        fnfHighscoreSpr.visible = true;
        topLeftCornerText.visible = true;
        freeplayTxtBg.visible = true;
        if (freeplayArrow != null) freeplayArrow.visible = true;
        ostName.visible = true;
        fp.visible = true;
        fp.updateScore(0);

        clearBoxSprite.visible = true;
        txtCompletion.visible = true;
        intendedCompletion = 0;

        new FlxTimer().start(1.5 / 24, function(bold) {
          sillyStroke.width = 0;
          sillyStroke.height = 0;
          changeSelection();
        });
      });

      backingImage.visible = true;
      backingCard.introDone();

      if (prepForNewRank && fromResultsParams != null)
      {
        rankAnimStart(fromResultsParams, currentCapsule);
        albumRoll.skipIntro();
        albumRoll.showStars();
      }

      refreshDots(5, Constants.DEFAULT_DIFFICULTY_LIST_FULL.indexOf(currentDifficulty), Constants.DEFAULT_DIFFICULTY_LIST_FULL.indexOf(currentDifficulty));
      fadeDots(true);

      #if FEATURE_TOUCH_CONTROLS
      FlxG.touches.swipeThreshold.x = 60;
      #end
    };

    // Generates song list with the starter params (who our current character is, last remembered difficulty, etc.)
    // Set this to false if you prefer the 50% transparency on the capsules when they first appear.
    generateSongList(null, true);

    // dedicated camera for the state so we don't need to fuk around with camera scrolls from the mainmenu / elsewhere
    funnyCam.bgColor = FlxColor.TRANSPARENT;
    FlxG.cameras.add(funnyCam, false);

    rankVignette.scale.set(2 * FullScreenScaleMode.wideScale.x, 2 * FullScreenScaleMode.wideScale.y);
    rankVignette.updateHitbox();
    rankVignette.blend = BlendMode.ADD;
    // rankVignette.cameras = [rankCamera];
    add(rankVignette);
    rankVignette.alpha = 0;

    forEach(function(bs) {
      bs.cameras = [funnyCam];
    });

    rankCamera.bgColor = FlxColor.TRANSPARENT;
    FlxG.cameras.add(rankCamera, false);
    rankBg.cameras = [rankCamera];
    rankBg.alpha = 0;

    #if FEATURE_TOUCH_CONTROLS
    addBackButton(FlxG.width, FlxG.height - 200, FlxColor.WHITE, goBack, 0.3, true);

    FlxTween.tween(backButton, {x: FlxG.width - 230}, 0.5, {ease: FlxEase.expoOut});
    #end

    if (prepForNewRank)
    {
      rankCamera.fade(0xFF000000, 0, false, null, true);
    }

    if (fromCharSelect)
    {
      enterFromCharSel();
      onDJIntroDone();
    }
    else
    {
      if (dj != null)
      {
        dj.onIntroDone.add(onDJIntroDone);
      }
      else
      {
        onDJIntroDone();
      }
    }
  }

  override public function dispatchEvent(event:ScriptEvent)
  {
    super.dispatchEvent(event);
    if (backingCard != null) ScriptEventDispatcher.callEvent(backingCard, event);
  }

  var currentFilter:Null<SongFilter> = null;
  var currentFilteredSongs:Array<Null<FreeplaySongData>> = [];

  /**
   * Given the current filter, rebuild the current song list and display it.
   * Automatically takes into account currentDifficulty, character, and variation
   *
   * @param filterStuff A filter to apply to the song list (regex, startswith, all, favorite)
   * @param force Whether the capsules should "jump" back in or not using their animation
   * @param onlyIfChanged Only apply the filter if the song list has changed
   * @param noJumpIn Will not call the jump-in function, used when changing difficulties to update the song list correctly without this happening twice
   */
  public function generateSongList(filterStuff:Null<SongFilter>, force:Bool = false, onlyIfChanged:Bool = true, noJumpIn:Bool = false):Void
  {
    var tempSongs:Array<Null<FreeplaySongData>> = songs;

    if (filterStuff != null) tempSongs = sortSongs(tempSongs, filterStuff);

    tempSongs = tempSongs.filter(song -> {
      if (song == null) return true; // Random

      // Available variations for current character. We get this since bf is usually `default` variation, and `pico` is `pico`
      // but sometimes pico can be the default variation (weekend 1 songs), and bf can be `bf` variation (darnell)
      var characterVariations:Array<String> = song.data.getVariationsByCharacter(currentCharacter);

      // Gets all available difficulties for our character, via our available variations
      var difficultiesAvailable:Array<String> = song.data.listDifficulties(null, characterVariations);
      return difficultiesAvailable.contains(currentDifficulty);
    });

    if (onlyIfChanged)
    {
      if (tempSongs.isEqualUnordered(currentFilteredSongs))
      {
        // If the song list is the same, we don't need to generate a new list.

        // Instead, we just apply the jump-in animation to the existing capsules.
        for (capsule in grpCapsules.members)
        {
          if (!noJumpIn)
          {
            capsule.initPosition(FlxG.width, 0);
            capsule.initJumpIn(0, force);
          }
        }

        // Stop processing.
        return;
      }
    }

    // Only now do we know that the filter is actually changing.
    currentFilter = filterStuff;

    currentFilteredSongs = tempSongs;
    curSelected = 0;

    grpCapsules.killMembers();

    // Initialize the random capsule, with empty/blank info (which we display once bf/pico does his hand)
    var randomCapsule:SongMenuItem = grpCapsules.recycle(SongMenuItem);
    randomCapsule.initRandom(styleData);
    randomCapsule.onConfirm = function() {
      capsuleOnConfirmRandom(randomCapsule);
    };

    if (fromCharSelect || noJumpIn) randomCapsule.forcePosition();
    else
    {
      randomCapsule.initJumpIn(0, force);
    }

    var hsvShader:HSVShader = new HSVShader();
    randomCapsule.hsvShader = hsvShader;
    grpCapsules.add(randomCapsule);

    for (i in 0...tempSongs.length)
    {
      var tempSong = tempSongs[i];
      if (tempSong == null) continue;

      var funnyMenu:SongMenuItem = grpCapsules.recycle(SongMenuItem);

      funnyMenu.initPosition(FlxG.width, 0);
      funnyMenu.initData(tempSong, styleData, i + 1);
      funnyMenu.onConfirm = function() {
        capsuleOnOpenDefault(funnyMenu);
      };
      funnyMenu.y = funnyMenu.intendedY(i + 1) + 10;
      funnyMenu.targetPos.x = funnyMenu.x;
      funnyMenu.ID = i;
      funnyMenu.capsule.alpha = 0.5;
      funnyMenu.hsvShader = hsvShader;
      funnyMenu.newText.animation.curAnim.curFrame = 45 - ((i * 4) % 45);

      // Stop the bounce-in animation when returning to freeplay from the character selection screen, or if noJumpIn is set to true
      if (fromCharSelect || noJumpIn) funnyMenu.forcePosition();
      else
        funnyMenu.initJumpIn(0, force);

      grpCapsules.add(funnyMenu);
      // add(funnyMenu.theActualHitbox);
    }

    FlxG.console.registerFunction('changeSelection', changeSelection);

    rememberSelection();
    changeSelection();
    refreshCapsuleDisplays();
  }

  /**
   * Filters an array of songs based on a filter
   * @param songsToFilter What data to use when filtering
   * @param songFilter The filter to apply
   * @return Array<FreeplaySongData>
   */
  public function sortSongs(songsToFilter:Array<Null<FreeplaySongData>>, songFilter:SongFilter):Array<Null<FreeplaySongData>>
  {
    var filterAlphabetically = function(a:Null<FreeplaySongData>, b:Null<FreeplaySongData>):Int {
      return SortUtil.alphabetically(a?.data.songName ?? '', b?.data.songName ?? '');
    };

    switch (songFilter.filterType)
    {
      case REGEXP:
        // filterStuff.filterData has a string with the first letter of the sorting range, and the second one
        // this creates a filter to return all the songs that start with a letter between those two

        // if filterData looks like "A-C", the regex should look something like this: ^[A-C].*
        // to get every song that starts between A and C
        var filterRegexp:EReg = new EReg('^[' + songFilter.filterData + '].*', 'i');
        songsToFilter = songsToFilter.filter(filteredSong -> {
          if (filteredSong == null) return true; // Random
          return filterRegexp.match(filteredSong.data.songName);
        });

        songsToFilter.sort(filterAlphabetically);

      case STARTSWITH:
        // extra note: this is essentially a "search"

        songsToFilter = songsToFilter.filter(filteredSong -> {
          if (filteredSong == null) return true; // Random
          return filteredSong.data.songName.toLowerCase().startsWith(songFilter.filterData ?? '');
        });
      case ALL:
        // no filter!
      case FAVORITE:
        // sort favorites by week, not alphabetically
        songsToFilter = songsToFilter.filter(filteredSong -> {
          if (filteredSong == null) return true; // Random
          return filteredSong.isFav;
        });

      default:
        // return all on default
    }

    return songsToFilter;
  }

  var sparks:FlxSprite;
  var sparksADD:FlxSprite;

  function rankAnimStart(fromResults:FromResultsParams, capsuleToRank:SongMenuItem):Void
  {
    controls.active = false;
    // We get the current selected capsule, in-case someone changes the song selection during a timer
    capsuleToRank.sparkle.alpha = 0;
    // capsuleToRank.forcePosition();

    rememberedSongId = fromResults.songId;
    rememberedDifficulty = fromResults.difficultyId;
    capsuleToRank.fakeRanking.visible = true;
    capsuleToRank.fakeRanking.alpha = 0; // If this isn't done, you'd see a tiny E being replaced for the first rank

    changeSelection();
    changeDiff();

    if (fromResultsParams?.newRank == SHIT)
    {
      dj?.fistPumpLossIntro();
    }
    else
    {
      dj?.fistPumpIntro();
    }

    // rankCamera.fade(FlxColor.BLACK, 0.5, true);
    rankCamera.fade(0xFF000000, 0.5, true, null, true);
    if (FlxG.sound.music != null) FlxG.sound.music.volume = 0;
    rankBg.alpha = 1;

    if (fromResults.oldRank != null)
    {
      capsuleToRank.fakeRanking.rank = fromResults.oldRank;

      sparks.frames = Paths.getSparrowAtlas('freeplay/sparks');
      sparks.animation.addByPrefix('sparks', 'sparks', 24, false);
      sparks.visible = false;
      sparks.blend = BlendMode.ADD;
      sparks.setPosition(517, 134);
      sparks.scale.set(0.5, 0.5);
      add(sparks);
      sparks.cameras = [rankCamera];

      sparksADD.visible = false;
      sparksADD.frames = Paths.getSparrowAtlas('freeplay/sparksadd');
      sparksADD.animation.addByPrefix('sparks add', 'sparks add', 24, false);
      sparksADD.setPosition(498, 116);
      sparksADD.blend = BlendMode.ADD;
      sparksADD.scale.set(0.5, 0.5);
      add(sparksADD);
      sparksADD.cameras = [rankCamera];
      sparksADD.color = fromResults.oldRank.getRankingFreeplayColor();
      // sparksADD.color = sparks.color;
      capsuleToRank.fakeRanking.alpha = 1.0;
    }

    capsuleToRank.doLerp = false;

    // originalPos.x = capsuleToRank.x;
    // originalPos.y = capsuleToRank.y;

    originalPos.x = (CUTOUT_WIDTH * SONGS_POS_MULTI) + 320.488;
    originalPos.y = 235.6;
    trace(originalPos);

    capsuleToRank.ranking.visible = false;

    // Rank animation vibrations.
    HapticUtil.increasingVibrate(Constants.MIN_VIBRATION_AMPLITUDE, Constants.MAX_VIBRATION_AMPLITUDE, 0.6);

    rankCamera.zoom = 1.85;
    FlxTween.tween(rankCamera, {"zoom": 1.8}, 0.6, {ease: FlxEase.sineIn});

    funnyCam.zoom = 1.15;
    FlxTween.tween(funnyCam, {"zoom": 1.1}, 0.6, {ease: FlxEase.sineIn});

    capsuleToRank.cameras = [rankCamera];
    // capsuleToRank.targetPos.set((FlxG.width / 2) - (capsuleToRank.width / 2),
    //  (FlxG.height / 2) - (capsuleToRank.height / 2));

    capsuleToRank.setPosition((FlxG.width / 2) - (capsuleToRank.width / 2), (FlxG.height / 2) - (capsuleToRank.height / 2));

    new FlxTimer().start(0.5, _ -> {
      rankDisplayNew(fromResults, capsuleToRank);
    });
  }

  function rankDisplayNew(fromResults:Null<FromResultsParams>, capsuleToRank:SongMenuItem):Void
  {
    capsuleToRank.ranking.visible = false;
    capsuleToRank.fakeRanking.visible = false;
    capsuleToRank.ranking.scale.set(20, 20);

    if (fromResults != null && fromResults.newRank != null)
    {
      capsuleToRank.ranking.playAnimationEach(fromResults.newRank.getFreeplayRankIconAsset(), true);
    }

    FlxTween.tween(capsuleToRank.ranking, {"scale.x": 1, "scale.y": 1}, 0.1);

    new FlxTimer().start(0.1, _ -> {
      capsuleToRank.ranking.visible = true;

      if (fromResults?.oldRank != null)
      {
        capsuleToRank.fakeRanking.visible = false;

        sparks.visible = true;
        sparksADD.visible = true;
        sparks.animation.play('sparks', true);
        sparksADD.animation.play('sparks add', true);

        sparks.animation.onFinish.add(anim -> {
          sparks.visible = false;
          sparksADD.visible = false;
        });
      }

      switch (fromResultsParams?.newRank)
      {
        case SHIT:
          FunkinSound.playOnce(Paths.sound('ranks/rankinbad'));
        case PERFECT:
          FunkinSound.playOnce(Paths.sound('ranks/rankinperfect'));
        case PERFECT_GOLD:
          FunkinSound.playOnce(Paths.sound('ranks/rankinperfect'));
        default:
          FunkinSound.playOnce(Paths.sound('ranks/rankinnormal'));
      }
      rankCamera.zoom = 1.3;

      FlxTween.tween(rankCamera, {"zoom": 1.5}, 0.3, {ease: FlxEase.backInOut});

      capsuleToRank.x -= 10;
      capsuleToRank.y -= 20;

      FlxTween.tween(funnyCam, {"zoom": 1.05}, 0.3, {ease: FlxEase.elasticOut});

      capsuleToRank.capsule.angle = -3;
      FlxTween.tween(capsuleToRank.capsule, {angle: 0}, 0.5, {ease: FlxEase.backOut});

      IntervalShake.shake(capsuleToRank.capsule, 0.3, 1 / 30, 0.1, 0, FlxEase.quadOut);
    });

    new FlxTimer().start(0.4, _ -> {
      FlxTween.tween(funnyCam, {"zoom": 1}, 0.8, {ease: FlxEase.sineIn});
      FlxTween.tween(rankCamera, {"zoom": 1.2}, 0.8, {ease: FlxEase.backIn});
      FlxTween.tween(capsuleToRank, {x: originalPos.x - 7, y: originalPos.y - 80}, 0.8 + 0.5, {ease: FlxEase.quartIn});
    });

    new FlxTimer().start(0.6, _ -> {
      rankAnimSlam(fromResults, capsuleToRank);
    });
  }

  function rankAnimSlam(fromResultsParams:Null<FromResultsParams>, capsuleToRank:SongMenuItem):Void
  {
    // FlxTween.tween(rankCamera, {"zoom": 1.9}, 0.5, {ease: FlxEase.backOut});
    FlxTween.tween(rankBg, {alpha: 0}, 0.5, {ease: FlxEase.expoIn});

    // FlxTween.tween(capsuleToRank, {angle: 5}, 0.5, {ease: FlxEase.backIn});

    switch (fromResultsParams?.newRank)
    {
      case SHIT:
        FunkinSound.playOnce(Paths.sound('ranks/loss'));
      case GOOD:
        FunkinSound.playOnce(Paths.sound('ranks/good'));
      case GREAT:
        FunkinSound.playOnce(Paths.sound('ranks/great'));
      case EXCELLENT:
        FunkinSound.playOnce(Paths.sound('ranks/excellent'));
      case PERFECT:
        FunkinSound.playOnce(Paths.sound('ranks/perfect'));
      case PERFECT_GOLD:
        FunkinSound.playOnce(Paths.sound('ranks/perfect'));
      default:
        FunkinSound.playOnce(Paths.sound('ranks/loss'));
    }

    FlxTween.tween(capsuleToRank, {"targetPos.x": originalPos.x, "targetPos.y": originalPos.y}, 0.5, {ease: FlxEase.expoOut});
    new FlxTimer().start(0.5, _ -> {
      // Capsule slam vibration.
      HapticUtil.vibrate(Constants.DEFAULT_VIBRATION_PERIOD, Constants.DEFAULT_VIBRATION_DURATION, Constants.MAX_VIBRATION_AMPLITUDE);

      funnyCam.shake(0.0045, 0.35);

      if (fromResultsParams?.newRank == SHIT)
      {
        if (dj != null) dj.fistPumpLoss();
      }
      else
      {
        if (dj != null) dj.fistPump();
      }

      rankCamera.zoom = 0.8;
      funnyCam.zoom = 0.8;
      FlxTween.tween(rankCamera, {"zoom": 1}, 1, {ease: FlxEase.elasticOut});
      FlxTween.tween(funnyCam, {"zoom": 1}, 0.8, {ease: FlxEase.elasticOut});

      for (index => capsule in grpCapsules.members)
      {
        var distFromSelected:Float = Math.abs(index - curSelected) - 1;

        if (distFromSelected < 5)
        {
          if (index == curSelected)
          {
            FlxTween.cancelTweensOf(capsule);
            // capsule.targetPos.x += 50;
            capsule.fadeAnim();

            rankVignette.color = capsule.getTrailColor();
            rankVignette.alpha = 1;
            FlxTween.tween(rankVignette, {alpha: 0}, 0.6, {ease: FlxEase.expoOut});

            capsule.doLerp = false;
            capsule.setPosition(originalPos.x, originalPos.y);
            IntervalShake.shake(capsule, 0.6, 1 / 24, 0.12, 0, FlxEase.quadOut, function(_) {
              capsule.doLerp = true;
              capsule.cameras = [funnyCam];

              // NOW we can interact with the menu
              controls.active = true;
              capsule.sparkle.alpha = 0.7;
              playCurSongPreview(capsule);
            }, null);

            // FlxTween.tween(capsule, {"targetPos.x": capsule.targetPos.x - 50}, 0.6,
            //   {
            //     ease: FlxEase.backInOut,
            //     onComplete: function(_) {
            //       capsule.cameras = [funnyCam];
            //     }
            //   });
            FlxTween.tween(capsule, {angle: 0}, 0.5, {ease: FlxEase.backOut});
          }
          if (index > curSelected)
          {
            // capsule.color = FlxColor.RED;
            new FlxTimer().start(distFromSelected / 20, _ -> {
              capsule.doLerp = false;

              capsule.capsule.angle = FlxG.random.float(-10 + (distFromSelected * 2), 10 - (distFromSelected * 2));
              FlxTween.tween(capsule.capsule, {angle: 0}, 0.5, {ease: FlxEase.backOut});

              IntervalShake.shake(capsule, 0.6, 1 / 24, 0.12 / (distFromSelected + 1), 0, FlxEase.quadOut, function(_) {
                capsule.doLerp = true;
              });
            });
          }

          if (index < curSelected)
          {
            // capsule.color = FlxColor.BLUE;
            new FlxTimer().start(distFromSelected / 20, _ -> {
              capsule.doLerp = false;

              capsule.capsule.angle = FlxG.random.float(-10 + (distFromSelected * 2), 10 - (distFromSelected * 2));
              FlxTween.tween(capsule.capsule, {angle: 0}, 0.5, {ease: FlxEase.backOut});

              IntervalShake.shake(capsule, 0.6, 1 / 24, 0.12 / (distFromSelected + 1), 0, FlxEase.quadOut, function(_) {
                capsule.doLerp = true;
              });
            });
          }
        }

        index += 1;
      }
    });

    new FlxTimer().start(2, _ -> {
      // dj.fistPump();
      prepForNewRank = false;
    });
  }

  var prevDotAmount:Int = 0;

  function fadeDots(fadeIn:Bool):Void
  {
    for (i in 0...difficultyDots.group.members.length)
    {
      if (fadeIn)
      {
        difficultyDots.group.members[i].fadeIn();
      }
      else
      {
        difficultyDots.group.members[i].fadeOut();
      }
    }
  }

  function refreshDots(amount:Int, index:Int, prevIndex:Int):Void
  {
    var distance:Int = 30;
    var shiftAmt:Float = (distance * amount) / 2;
    var daSong:Null<FreeplaySongData> = currentCapsule.freeplayData;

    for (i in 0...difficultyDots.group.members.length)
    {
      // if (difficultyDots.group.members[i] == null) continue;
      var targetState:DotState = SELECTED;
      var targetType:DotType = NORMAL;
      var diffId:String = difficultyDots.group.members[i].difficultyId;

      difficultyDots.group.members[i].important = false;

      if (i == index)
      {
        targetState = SELECTED;
      }
      else
      {
        if (i == prevIndex)
        {
          targetState = DESELECTING;
        }
        else
        {
          targetState = DESELECTED;
        }
      }

      if (diffId == 'erect' || diffId == 'nightmare')
      {
        targetType = ERECT;
      }

      difficultyDots.group.members[i].visible = true;
      difficultyDots.group.members[i].x = (CUTOUT_WIDTH * DJ_POS_MULTI) + ((difficultyDots.x + (distance * i)) - shiftAmt);

      if (daSong?.data.hasDifficulty(diffId, daSong?.data.getFirstValidVariation(diffId, currentCharacter)) == false)
      {
        targetType = INACTIVE;
      }
      else
      {
        if (daSong?.isDifficultyNew(diffId) == true)
        {
          // at the moment, we don't want the other difficulties to show the pulse, cause the
          // feature only works on new songs at the moment and its not particularly hard to find a new song on easy/normal/hard.
          // eventually this will probably be moved to affect all types.
          if (targetType == ERECT)
          {
            difficultyDots.group.members[i].important = true;
          }
        }
      }

      // originally was gonna hide the dots if erect/nightmare wasnt present, leaving this functionality just in case
      // mods (or we) need to display a different amount
      if (i > amount - 1 && amount != 5)
      {
        difficultyDots.group.members[i].visible = false;
      }

      difficultyDots.group.members[i].updateState(targetType, targetState);
    }

    prevDotAmount = amount;
  }

  function tryOpenCharSelect():Void
  {
    // Check if we have ACCESS to character select!
    trace('Is Pico unlocked? ${PlayerRegistry.instance.fetchEntry('pico')?.isUnlocked()}');
    trace('Number of characters: ${PlayerRegistry.instance.countUnlockedCharacters()}');

    if (PlayerRegistry.instance.countUnlockedCharacters() > 1)
    {
      trace('Opening character select!');
    }
    else
    {
      trace('Not enough characters unlocked to open character select!');
      FunkinSound.playOnce(Paths.sound('cancelMenu'));
      return;
    }

    controls.active = false;

    FunkinSound.playOnce(Paths.sound('confirmMenu'));

    if (dj != null)
    {
      dj.toCharSelect();
    }

    // Get this character's transition delay, with a reasonable default.
    var transitionDelay:Float = currentCharacter.getFreeplayDJData()?.getCharSelectTransitionDelay() ?? 0.25;

    new FlxTimer().start(transitionDelay, _ -> {
      transitionToCharSelect();
    });
  }

  function transitionToCharSelect():Void
  {
    controls.active = false;
    var transitionGradient:FlxSprite = new FlxSprite(0, 720).loadGraphic(Paths.image('freeplay/transitionGradient'));
    transitionGradient.scale.set(1280, 1);
    transitionGradient.updateHitbox();
    transitionGradient.cameras = [rankCamera];
    exitMoversCharSel.set([transitionGradient],
      {
        y: -720,
        speed: 0.8,
        wait: 0.1
      });
    add(transitionGradient);
    for (index => capsule in grpCapsules.members)
    {
      var distFromSelected:Float = Math.abs(index - curSelected) - 1;
      if (distFromSelected < 5)
      {
        capsule.doLerp = false;
        exitMoversCharSel.set([capsule],
          {
            y: -250,
            speed: 0.8,
            wait: 0.1
          });
      }
    }

    fadeDots(false);

    #if FEATURE_TOUCH_CONTROLS
    FlxTween.tween(backButton, {alpha: 0.0001}, 0.4, {ease: FlxEase.quadOut});
    #end

    fadeShader.fade(1.0, 0.0, 0.8, {ease: FlxEase.quadIn});
    FlxG.sound.music?.fadeOut(0.9, 0);

    // Passing the currrent Freeplay character to the CharSelect so we can start it with that character selected
    new FlxTimer().start(0.9, _ -> {
      FlxG.switchState(() -> new funkin.ui.charSelect.CharSelectSubState({character: currentCharacterId}));
    });

    for (grpSpr in exitMoversCharSel.keys())
    {
      if (exitMoversCharSel.get(grpSpr) == null) continue;

      for (spr in grpSpr)
      {
        if (spr == null) continue;

        var moveDataY = exitMoversCharSel.get(grpSpr)?.y ?? spr.y;
        var moveDataSpeed = exitMoversCharSel.get(grpSpr)?.speed ?? 0.2;

        FlxTween.tween(spr, {y: moveDataY + spr.y}, moveDataSpeed, {ease: FlxEase.backIn});
      }
    }
    backingCard.enterCharSel();
  }

  function enterFromCharSel():Void
  {
    controls.active = false;
    if (_parentState != null) _parentState.persistentDraw = false;

    var transitionGradient = new FlxSprite(0, 720).loadGraphic(Paths.image('freeplay/transitionGradient'));
    transitionGradient.scale.set(1280, 1);
    transitionGradient.updateHitbox();
    transitionGradient.cameras = [rankCamera];
    exitMoversCharSel.set([transitionGradient],
      {
        y: -720,
        speed: 1.5,
        wait: 0.1
      });
    add(transitionGradient);
    // FlxTween.tween(transitionGradient, {alpha: 0}, 1, {ease: FlxEase.circIn});
    // for (index => capsule in grpCapsules.members)
    // {
    //   var distFromSelected:Float = Math.abs(index - curSelected) - 1;
    //   if (distFromSelected < 5)
    //   {
    //     capsule.doLerp = false;
    //     exitMoversCharSel.set([capsule],
    //       {
    //         y: -250,
    //         speed: 0.8,
    //         wait: 0.1
    //       });
    //   }
    // }
    fadeShader.fade(0.0, 1.0, 0.8, {ease: FlxEase.quadIn});
    for (grpSpr in exitMoversCharSel.keys())
    {
      if (exitMoversCharSel.get(grpSpr) == null) continue;

      for (spr in grpSpr)
      {
        if (spr == null) continue;

        var moveDataY = exitMoversCharSel.get(grpSpr)?.y ?? spr.y;
        var moveDataSpeed = exitMoversCharSel.get(grpSpr)?.speed ?? 0.2;

        spr.y += moveDataY;

        FlxTween.tween(spr, {y: spr.y - moveDataY}, moveDataSpeed * 1.2,
          {
            ease: FlxEase.expoOut,
            onComplete: function(_) {
              for (index => capsule in grpCapsules.members)
              {
                capsule.doLerp = true;
                fromCharSelect = false;
                controls.active = true;
              }
            }
          });
      }
    }
  }

  var spamTimer:Float = 0;
  var spamming:Bool = false;

  var originalPos:FlxPoint = new FlxPoint();

  var hintTimer:Float = 0;

  var allowPicoBulletsVibration:Bool = false;

  var backTransitioning:Bool = false;

  override function update(elapsed:Float):Void
  {
    super.update(elapsed);

    #if FEATURE_TOUCH_CONTROLS
    if (backButton != null && !backTransitioning)
    {
      if (!controls.active)
      {
        backButton.animation.play("idle");
        backButton.alpha = backButton.restingOpacity;
      }
      backButton.active = controls.active;
    }
    #end

    if (charSelectHint != null)
    {
      hintTimer += elapsed * 2;
      var targetAmt:Float = (Math.sin(hintTimer) + 1) / 2;
      charSelectHint.alpha = FlxMath.lerp(0.3, 0.9, targetAmt);
    }

    #if FEATURE_DEBUG_FUNCTIONS
    if (FlxG.keys.justPressed.P)
    {
      FlxG.switchState(() -> FreeplayState.build(
        {
          {
            character: currentCharacterId == "pico" ? Constants.DEFAULT_CHARACTER : "pico",
          }
        }));
    }

    if (FlxG.keys.justPressed.T)
    {
      rankAnimStart(fromResultsParams ??
        {
          playRankAnim: true,
          newRank: PERFECT_GOLD,
          songId: "tutorial",
          difficultyId: "hard"
        }, currentCapsule);
    }
    #end // ^<-- FEATURE_DEBUG_FUNCTIONS

    if ((controls.FREEPLAY_CHAR_SELECT #if FEATURE_TOUCH_CONTROLS
      || (TouchUtil.pressAction(djHitbox, funnyCam, false) && !SwipeUtil.swipeAny) #end)
      && controls.active)
    {
      tryOpenCharSelect();
    }

    if (controls.FREEPLAY_FAVORITE && controls.active) favoriteSong();

    if (controls.FREEPLAY_JUMP_TO_TOP && controls.active) changeSelection(-curSelected);

    if (controls.FREEPLAY_JUMP_TO_BOTTOM && controls.active) changeSelection(grpCapsules.countLiving() - curSelected - 1);

    calculateCompletion();

    handleInputs(elapsed);

    if (dj != null) FlxG.watch.addQuick('dj-anim', dj.getCurrentAnimation());

    // If the allowPicoBulletsVibration is true, trigger vibration each update (for pico shooting bullets animation).
    if (allowPicoBulletsVibration) HapticUtil.vibrate(0, 0.01, (Constants.MAX_VIBRATION_AMPLITUDE / 3) * 2.5);
  }

  function calculateCompletion():Void
  {
    lerpScore = MathUtil.snap(MathUtil.smoothLerpPrecision(lerpScore, intendedScore, FlxG.elapsed, 0.2), intendedScore, 1);
    lerpCompletion = MathUtil.snap(MathUtil.smoothLerpPrecision(lerpCompletion, intendedCompletion, FlxG.elapsed, 0.5), intendedCompletion, 1 / 100);

    if (Math.isNaN(lerpScore))
    {
      lerpScore = intendedScore;
    }

    if (Math.isNaN(lerpCompletion))
    {
      lerpCompletion = intendedCompletion;
    }

    fp.updateScore(Std.int(lerpScore));

    // sets the text of the completion percentage. Perhaps eventually we may want to generalize this,
    // but for now we can just clamp the values between 0 and 100.
    // Fixes issue where it rounds to negative integer overflow on Windows? Which occurs when switching to an unranked song?
    txtCompletion.text = '${FlxMath.clamp(Math.floor(lerpCompletion * 100), 0, 100)}';

    // Right align the completion percentage
    switch (txtCompletion.text.length)
    {
      case 3:
        txtCompletion.offset.x = 10;
      case 2:
        txtCompletion.offset.x = 0;
      case 1:
        txtCompletion.offset.x = -24;
      default:
        txtCompletion.offset.x = 0;
    }
  }

  var _dragOffset:Float = 0;
  var _prevRoundedDragOffset:Float = 0;
  var _pressedOnSelected:Bool = false;
  var _moveLength:Float = 0;
  var _flickEnded:Bool = true;
  var _pressedOnCapsule:Bool = false;
  var draggingDifficulty:Bool = false;

  function handleInputs(elapsed:Float):Void
  {
    if (!controls.active) return;

    final upP:Bool = controls.UI_UP_P;
    final downP:Bool = controls.UI_DOWN_P;
    final accepted:Bool = controls.ACCEPT;

    #if FEATURE_TOUCH_CONTROLS
    handleTouchCapsuleClick();
    handleTouchFavoritesAndDifficulties();
    handleTouchSelectionScroll(elapsed);
    #end

    handleDirectionalInput(elapsed);

    final wheelAmount:Float = #if !html5 FlxG.mouse.wheel #else FlxG.mouse.wheel / 8 #end;

    if (wheelAmount != 0)
    {
      dj?.resetAFKTimer();
      changeSelection(-Math.round(wheelAmount));
    }

    handleDifficultySwitch();
    handleDebugKeys();

    #if FEATURE_TOUCH_CONTROLS
    if (TouchUtil.justReleased)
    {
      _pressedOnSelected = false;
      _pressedOnCapsule = false;
    }

    if (!TouchUtil.pressed && !FlxG.touches.flickManager.initialized)
    {
      _flickEnded = true;
      draggingDifficulty = false;
    }
    #end

    if (controls.BACK)
    {
      goBack();
    }

    if (accepted && controls.active)
    {
      currentCapsule.onConfirm();
    }
  }

  function handleDirectionalInput(elapsed:Float):Void
  {
    final upP:Bool = controls.UI_UP;
    final downP:Bool = controls.UI_DOWN;

    if (upP || downP)
    {
      if (spamming)
      {
        if (spamTimer >= 0.07)
        {
          spamTimer = 0;
          changeSelection(upP ? -1 : 1);
        }
      }
      else if (spamTimer >= 0.9)
      {
        spamming = true;
      }
      else if (spamTimer <= 0)
      {
        changeSelection(upP ? -1 : 1);
      }

      spamTimer += elapsed;
      dj?.resetAFKTimer();
    }
    else
    {
      spamming = false;
      spamTimer = 0;
    }
  }

  function handleDifficultySwitch():Void
  {
    #if FEATURE_TOUCH_CONTROLS
    final leftPressed:Bool = controls.UI_LEFT_P || TouchUtil.pressAction(diffSelLeft, funnyCam, false);
    final rightPressed:Bool = controls.UI_RIGHT_P || TouchUtil.pressAction(diffSelRight, funnyCam, false);
    #else
    final leftPressed:Bool = controls.UI_LEFT_P;
    final rightPressed:Bool = controls.UI_RIGHT_P;
    #end

    if (leftPressed)
    {
      dj?.resetAFKTimer();
      changeDiff(-1);
      generateSongList(currentFilter, true, false);
    }

    if (rightPressed)
    {
      dj?.resetAFKTimer();
      changeDiff(1);
      generateSongList(currentFilter, true, false);
    }
  }

  function handleDebugKeys():Void
  {
    #if FEATURE_CHART_EDITOR
    if (!controls.active) return;
    if (!controls.DEBUG_CHART) return;

    controls.active = false;

    var targetSongID = currentCapsule?.freeplayData?.data.id ?? 'unknown';
    if (targetSongID == 'unknown')
    {
      letterSort.inputEnabled = false;

      var availableSongCapsules:Array<SongMenuItem> = grpCapsules.members.filter(function(cap:SongMenuItem) {
        // Dead capsules are ones which were removed from the list when changing filters.
        return cap.alive && cap.freeplayData != null;
      });

      trace('Available songs: ${availableSongCapsules.map(function(cap) {
          return cap?.freeplayData?.data.songName;
        })}');

      if (availableSongCapsules.length == 0)
      {
        trace('No songs available!');
        controls.active = true;
        letterSort.inputEnabled = true;
        FunkinSound.playOnce(Paths.sound('cancelMenu'));
        return;
      }

      var targetSong:SongMenuItem = FlxG.random.getObject(availableSongCapsules);

      // Seeing if I can do an animation...
      curSelected = grpCapsules.members.indexOf(targetSong);
      changeSelection(0);
      targetSongID = currentCapsule?.freeplayData?.data.id ?? 'unknown';
    }
    // Play the confirm animation so the user knows they actually did something.
    FunkinSound.playOnce(Paths.sound('confirmMenu'));
    if (dj != null) dj.confirm();
    new FlxTimer().start(styleData?.getStartDelay(), function(tmr:FlxTimer) {
      FlxG.switchState(() -> new ChartEditorState(
        {
          targetSongId: targetSongID,
          targetSongDifficulty: currentDifficulty,
          targetSongVariation: currentVariation,
        }));
    });
    #end
  }

  #if FEATURE_TOUCH_CONTROLS
  private function handleTouchCapsuleClick():Void
  {
    if (diffSelRight == null) return;
    if (TouchUtil.pressAction() && !TouchUtil.overlaps(diffSelRight, funnyCam) && !draggingDifficulty)
    {
      curSelected = Math.round(curSelectedFloat);

      for (i in 0...grpCapsules.members.length)
      {
        final capsule = grpCapsules.members[i];

        if (capsule == null || !capsule.visible) continue;
        if (capsule.capsule == null || !capsule.capsule.visible) continue;
        if (!TouchUtil.overlaps(capsule.theActualHitbox, funnyCam)) continue;
        if (SwipeUtil.swipeAny) continue;

        if (capsule.selected)
        {
          capsule.onConfirm();
        }
        else
        {
          curSelected = i;
          changeSelection(0);
          FunkinSound.playOnce(Paths.sound('scrollMenu'), 0.4);
          HapticUtil.vibrate(0, 0.01, 0.5);
        }
        break;
      }
    }

    if (TouchUtil.justPressed)
    {
      final selected = currentCapsule.theActualHitbox;
      _pressedOnSelected = selected != null && TouchUtil.overlaps(selected, funnyCam);
    }
  }

  function handleTouchSelectionScroll(elapsed:Float):Void
  {
    if (draggingDifficulty || ControlsHandler.usingExternalInputDevice) return;
    if (TouchUtil.pressAction(currentCapsule.theActualHitbox, funnyCam)) return;

    if (TouchUtil.justPressed && TouchUtil.overlaps(capsuleHitbox, funnyCam))
    {
      _pressedOnCapsule = true;
    }

    for (touch in FlxG.touches.list)
    {
      if (touch.pressed && _pressedOnCapsule)
      {
        final delta = touch.deltaViewY;
        if (Math.abs(delta) >= 2)
        {
          var dpiScale = FlxG.stage.window.display.dpi / 160;

          dpiScale = FlxMath.clamp(dpiScale, 0.5, #if android 1 #else 2 #end);

          var moveLength = delta / FlxG.updateFramerate / dpiScale;
          _moveLength += Math.abs(moveLength);
          curSelectedFloat -= moveLength;
          updateSongsScroll();
        }
      }
      else if (_moveLength > 0)
      {
        _moveLength = 0.0;
        changeSelection(0);
      }
    }
    if (!TouchUtil.overlaps(capsuleHitbox, funnyCam) && TouchUtil.justReleased)
    {
      FlxG.touches.flickManager.destroy();
    }

    if (FlxG.touches.flickManager.initialized)
    {
      var flickVelocity = FlxG.touches.flickManager.velocity.y;
      if (Math.isFinite(flickVelocity))
      {
        _flickEnded = false;
        var dpiScale = FlxG.stage.window.display.dpi / 160;

        dpiScale = FlxMath.clamp(dpiScale, 0.5, #if android 1 #else 2 #end);
        var velocityMove = flickVelocity * elapsed / dpiScale;
        _moveLength += Math.abs(velocityMove);
        curSelectedFloat -= velocityMove;
        updateSongsScroll();
      }
    }
    else if (!_flickEnded)
    {
      _flickEnded = true;
      if (_moveLength > 0)
      {
        _moveLength = 0.0;
        changeSelection(0);
      }
    }

    curSelectedFloat = FlxMath.clamp(curSelectedFloat, 0, grpCapsules.countLiving() - 1);
    curSelected = Math.round(curSelectedFloat);

    for (i in 0...grpCapsules.members.length)
    {
      grpCapsules.members[i].selected = (i == curSelected);
    }

    if (!TouchUtil.pressed && (curSelected == 0 || curSelected == grpCapsules.countLiving() - 1) && FlxG.touches.flickManager.initialized)
    {
      FlxG.touches.flickManager.destroy();
      _flickEnded = true;
      if (_moveLength > 0)
      {
        _moveLength = 0.0;
        changeSelection(0);
      }
    }
  }

  function handleTouchFavoritesAndDifficulties()
  {
    // Note: I was a bit evil, and used `draggingDifficulty` for the DifficultySprite dragging as well!

    if ((TouchUtil.pressed || TouchUtil.justReleased))
    {
      if (_pressedOnSelected && TouchUtil.touch != null)
      {
        if (SwipeUtil.swipeLeft)
        {
          draggingDifficulty = true;
          dj?.resetAFKTimer();
          changeDiff(-1, false, true);
          _pressedOnSelected = false;
          FlxG.touches.flickManager.destroy();
          _flickEnded = true;

          new FlxTimer().start(0.21, (afteranim) -> {
            currentCapsule.doLerp = true;
            generateSongList(currentFilter, true, false, true);
            FlxG.touches.flickManager.destroy();
          });
          new FlxTimer().start(0.3, (afteranim) -> {
            draggingDifficulty = false;
          });
          return;
        }
        else if (SwipeUtil.swipeRight)
        {
          draggingDifficulty = true;
          dj?.resetAFKTimer();
          changeDiff(1, false, true);
          _pressedOnSelected = false;
          FlxG.touches.flickManager.destroy();
          _flickEnded = true;

          new FlxTimer().start(0.21, (afteranim) -> {
            currentCapsule.doLerp = true;
            generateSongList(currentFilter, true, false, true);
            FlxG.touches.flickManager.destroy();
          });
          new FlxTimer().start(0.3, (afteranim) -> {
            draggingDifficulty = false;
          });
          return;
        }

        if (TouchUtil.touch.ticksDeltaSincePress >= 500)
        {
          _pressedOnSelected = false;
          draggingDifficulty = false;
          favoriteSong();
        }
      }
      else
      {
        currentCapsule.doLerp = true;
      }

      if (!controls.active) return;
      if (currentDifficultySprite == null) return;

      // If we press onto our difficulty, we want to "grab" it rather than simply check if we are overlapping
      if (TouchUtil.overlapsComplex(currentDifficultySprite, funnyCam) && TouchUtil.justPressed && !draggingDifficulty)
      {
        HapticUtil.vibrate(0, 0.01, 0.375, 0.4);
        draggingDifficulty = true;
      }

      if (!draggingDifficulty) return;

      if (_dragOffset == 0 && TouchUtil.pressed) _dragOffset = TouchUtil.touch.x;
      currentDifficultySprite.offset.x = MathUtil.smoothLerpPrecision(currentDifficultySprite.offset.x, (TouchUtil.touch.x - _dragOffset) * -1, FlxG.elapsed,
        0.2);

      var vibDist:Float = 5; // essentially how far the touch needs to be before it will trigger a tiny haptic feel
      if (Std.int((TouchUtil.touch.x - _dragOffset) / vibDist) * vibDist != _prevRoundedDragOffset)
      {
        HapticUtil.vibrate(0, 0.01, 0.2, 0.8);
      }
      _prevRoundedDragOffset = Std.int((TouchUtil.touch.x - _dragOffset) / vibDist) * vibDist;

      if (TouchUtil.justReleased)
      {
        FlxG.touches.flickManager.destroy();
        handleDiffDragRelease(currentDifficultySprite);
        return;
      }

      if (TouchUtil.touch.justMovedRight)
      {
        handleDiffBoundaryChange(1);
        return;
      }
      if (TouchUtil.touch.justMovedLeft)
      {
        handleDiffBoundaryChange(-1);
        return;
      }

      return;
    }
    else
    {
      // we aren't pressin nothin, we should lerp our difficulty thing back to og offset/position
      currentDifficultySprite.offset.x = MathUtil.smoothLerpPrecision(currentDifficultySprite.offset.x, 0, FlxG.elapsed, 0.4);
    }

    diffSelRight.setPress(TouchUtil.overlaps(diffSelRight, funnyCam) && TouchUtil.justPressed);
    diffSelLeft.setPress(TouchUtil.overlaps(diffSelLeft, funnyCam) && TouchUtil.justPressed);
  }
  #end

  override function beatHit():Bool
  {
    backingCard.beatHit();

    return super.beatHit();
  }

  public override function destroy():Void
  {
    super.destroy();
    // remove and destroy freeplay camera
    FlxG.cameras.remove(funnyCam);
  }

  function goBack():Void
  {
    if (!controls.active) return;
    backTransitioning = true;
    #if FEATURE_TOUCH_CONTROLS
    if (backButton != null)
    {
      backButton.alpha = 1;
      backButton.animation.play("confirm");
    }
    #end
    controls.active = false;
    FlxTween.globalManager.clear();
    FlxTimer.globalManager.clear();
    if (dj != null) dj.onIntroDone.removeAll();

    FunkinSound.playOnce(Paths.sound('cancelMenu'));

    var longestTimer:Float = 0;

    backingCard.disappear();
    fadeDots(false);

    for (grpSpr in exitMovers.keys())
    {
      var moveData:Null<MoveData> = exitMovers.get(grpSpr);
      if (moveData == null) continue;

      for (spr in grpSpr)
      {
        if (spr == null) continue;

        var funnyMoveShit:MoveData = moveData;

        var moveDataX = funnyMoveShit.x ?? spr.x;
        var moveDataY = funnyMoveShit.y ?? spr.y;
        var moveDataSpeed = funnyMoveShit.speed ?? 0.2;
        var moveDataWait = funnyMoveShit.wait ?? 0.0;

        FlxTween.tween(spr, {x: moveDataX, y: moveDataY}, moveDataSpeed, {ease: FlxEase.expoIn});

        longestTimer = Math.max(longestTimer, moveDataSpeed + moveDataWait);
      }
    }

    #if FEATURE_TOUCH_CONTROLS
    FlxTween.tween(backButton, {x: FlxG.width + 300}, 0.45, {ease: FlxEase.expoIn});
    FlxTween.tween(backButton, {alpha: 0.0001}, 0.3, {ease: FlxEase.quadOut, startDelay: 0.15});
    #end

    for (caps in grpCapsules.members)
    {
      caps.doJumpIn = false;
      caps.doLerp = false;
      caps.doJumpOut = true;
    }

    if (Type.getClass(_parentState) == MainMenuState)
    {
      _parentState.persistentUpdate = false;
      _parentState.persistentDraw = true;
    }

    new FlxTimer().start(longestTimer, (_) -> {
      FlxTransitionableState.skipNextTransIn = true;
      FlxTransitionableState.skipNextTransOut = true;
      if (Type.getClass(_parentState) == MainMenuState)
      {
        FunkinSound.playMusic('freakyMenu',
          {
            overrideExisting: true,
            restartTrack: false,
            // Continue playing this music between states, until a different music track gets played.
            persist: true
          });
        FlxG.sound.music.fadeIn(4.0, 0.0, 1.0);
        close();
      }
      else
      {
        FlxG.switchState(() -> new MainMenuState());
      }
    });
  }

  /**
   * findClosestDiff will find the closest difficulty to the given diff.
   * It will return the index of the closest song in the grpCapsules.members array.
   * @param diff
   * @return Int
   */
  function findClosestDiff(characterVariations:Array<String>, diff:String):Int
  {
    var closestIndex:Int = 0;
    var closest:Int = curSelected;

    for (index in 0...grpCapsules.members.length)
    {
      var song:Null<FreeplaySongData> = grpCapsules.members[index].freeplayData;
      if (song == null) continue;
      var characterVar = song.data.getVariationsByCharacter(currentCharacter);
      var songDiff:Null<String> = song.data.getDifficulty(diff, null, characterVar)?.difficulty;
      // if the difference between the current index and this index is the smallest so far,
      // take this one as the closest index. (By comparing with the closest variable)
      var c:Int = curSelected - index;
      if (songDiff == diff && (Math.abs(c) < Math.abs(closestIndex - curSelected) || closestIndex == 0))
      {
        // trace('Found closest diff: ${songDiff} at index ${index} (current: ${curSelected})');
        closestIndex = index;
        closest = c;
      }
    }

    return closestIndex;
  }

  /**
   * changeDiff is the root of both difficulty and variation changes/management.
   * It will check the difficulty of the current variation, all available variations, and all available difficulties per variation.
   * Call generateSongList after this with the right parameters if you want the capsules to do their jump-in animation after changing difficulties.
   * @param change
   * @param force
   * @param capsuleAnim
   */
  function changeDiff(change:Int = 0, force:Bool = false, capsuleAnim:Bool = false):Void
  {
    if (!controls.active) return;

    if (capsuleAnim)
    {
      if (currentCapsule != null)
      {
        controls.active = false;
        currentCapsule.doLerp = false;

        var movement:Float = (change > 0) ? 15 : -15;
        FlxTween.tween(currentCapsule, {x: currentCapsule.x - movement}, 0.1, {ease: FlxEase.expoOut});
        FlxTween.tween(currentCapsule, {x: currentCapsule.x + movement}, 0.1, {ease: FlxEase.expoIn, startDelay: 0.1});
      }
    }

    for (diff in grpDifficulties.group.members)
    {
      if (diff == null || diff.difficultyId != currentDifficulty) continue;
      if (change == 0) break;

      diff.visible = true;
      final newX:Int = (change > 0) ? -320 : 500;

      controls.active = false;
      FlxTween.tween(diff, {x: newX + (CUTOUT_WIDTH * DJ_POS_MULTI)}, 0.2,
        {
          ease: FlxEase.circInOut,
          onComplete: function(_) {
            controls.active = true;
            diff.x = 90 + (CUTOUT_WIDTH * DJ_POS_MULTI);
            diff.visible = false;
          }
        });
      break;
    }
    if (change != 0)
    {
      HapticUtil.vibrate(0, 0.01, 0.5, 0.1);
      FunkinSound.playOnce(Paths.sound('scrollMenu'), 0.4);
    }

    var previousVariation:String = currentVariation;
    var daSong:Null<FreeplaySongData> = currentCapsule.freeplayData;
    currentCapsule.selected = false;

    // Available variations for current character. We get this since bf is usually `default` variation, and `pico` is `pico`
    // but sometimes pico can be the default variation (weekend 1 songs), and bf can be `bf` variation (darnell)
    var characterVariations:Array<String> = daSong?.data.getVariationsByCharacter(currentCharacter) ?? Constants.DEFAULT_VARIATION_LIST;
    var difficultiesAvailable:Array<String> = SongRegistry.instance.listAllDifficulties(currentCharacterId) ?? Constants.DEFAULT_DIFFICULTY_LIST_FULL;
    // Gets all available difficulties for our character, via our available variations
    var songDifficulties:Array<String> = daSong?.data.listDifficulties(null, characterVariations) ?? Constants.DEFAULT_DIFFICULTY_LIST;

    var currentDifficultyIndex:Int = difficultiesAvailable.indexOf(currentDifficulty);
    var prevDifficultyIndex:Int = currentDifficultyIndex;

    if (currentDifficultyIndex == -1) currentDifficultyIndex = difficultiesAvailable.indexOf(Constants.DEFAULT_DIFFICULTY);

    currentDifficultyIndex += change;

    if (currentDifficultyIndex < 0) currentDifficultyIndex = Std.int(difficultiesAvailable.length - 1);
    if (currentDifficultyIndex >= difficultiesAvailable.length) currentDifficultyIndex = 0;
    // Update the current difficulty
    currentDifficulty = difficultiesAvailable[currentDifficultyIndex];
    // For when we change the difficulty, but the song doesn't have that difficulty!
    if (daSong != null && !songDifficulties.contains(difficultiesAvailable[currentDifficultyIndex]))
    {
      // Switch to the closest song with that difficulty.
      curSelected = findClosestDiff(characterVariations, difficultiesAvailable[currentDifficultyIndex]);
      daSong = currentCapsule.freeplayData;
      rememberedSongId = daSong?.data.id;

      // Update the variation list for the new song.
      characterVariations = daSong?.data.getVariationsByCharacter(currentCharacter) ?? Constants.DEFAULT_VARIATION_LIST;
    }

    for (variation in characterVariations)
    {
      if (daSong?.data.hasDifficulty(currentDifficulty, variation) ?? false)
      {
        currentVariation = variation;
        rememberedVariation = variation;
        break;
      }
    }

    if (daSong != null)
    {
      var targetSong:Null<Song> = SongRegistry.instance.fetchEntry(daSong.data.id);
      if (targetSong == null)
      {
        FlxG.log.warn('WARN: could not find song with id (${daSong.data.id})');
        return;
      }

      var songScore:Null<SaveScoreData> = Save.instance.getSongScore(daSong.data.id, currentDifficulty, currentVariation);
      intendedScore = songScore?.score ?? 0;
      intendedCompletion = songScore == null ? 0.0 : Math.max(0,
        ((songScore.tallies.sick + songScore.tallies.good - songScore.tallies.missed) / songScore.tallies.totalNotes));
      rememberedDifficulty = currentDifficulty;
      if (!capsuleAnim) generateSongList(currentFilter, false, true, true);
      currentCapsule.refreshDisplay((prepForNewRank == true) ? false : true);
    }
    else
    {
      intendedScore = 0;
      intendedCompletion = 0.0;
      rememberedDifficulty = currentDifficulty;
      if (!capsuleAnim) generateSongList(currentFilter, false, true, true);
    }

    if (intendedCompletion == Math.POSITIVE_INFINITY || intendedCompletion == Math.NEGATIVE_INFINITY || Math.isNaN(intendedCompletion))
    {
      intendedCompletion = 0;
    }

    for (diffSprite in grpDifficulties.group.members)
    {
      if (diffSprite == null) continue;

      final isCurrentDiff:Bool = diffSprite.difficultyId == currentDifficulty;

      if (change == 0) diffSprite.visible = isCurrentDiff;

      if (!isCurrentDiff || change == 0) continue;

      diffSprite.x = (change > 0) ? 500 : -320;
      diffSprite.x += (CUTOUT_WIDTH * DJ_POS_MULTI);

      FlxTween.tween(diffSprite, {x: 90 + (CUTOUT_WIDTH * DJ_POS_MULTI)}, 0.2,
        {
          ease: FlxEase.circInOut,
          onComplete: function(_) {
            #if FEATURE_TOUCH_CONTROLS
            FlxG.touches.flickManager.destroy();
            _flickEnded = true;
            #end
          }
        });

      diffSprite.offset.y += 5;
      diffSprite.alpha = 0.5;
      new FlxTimer().start(1 / 24, function(swag) {
        diffSprite.alpha = 1;
        diffSprite.updateHitbox();
        diffSprite.visible = true;
        diffSprite.height *= 2.5;
      });
    }

    // refreshDots(songDifficulties.length, currentDifficultyIndex, prevDifficultyIndex);
    refreshDots(5, currentDifficultyIndex, prevDifficultyIndex);

    if (change != 0 || force)
    {
      // Update the song capsules to reflect the new difficulty info.
      for (songCapsule in grpCapsules.members)
      {
        if (songCapsule == null) continue;

        if (songCapsule.freeplayData != null)
        {
          songCapsule.initData(songCapsule.freeplayData);
          songCapsule.checkClip();
        }
      }

      // Reset the song preview in case we changed variations (normal->erect etc)
      if (currentVariation != previousVariation) playCurSongPreview();
    }

    // Set the album graphic and play the animation if relevant.
    var newAlbumId:Null<String> = daSong?.data.getAlbumId(currentDifficulty, currentVariation);
    if (albumRoll.albumId != newAlbumId)
    {
      albumRoll.albumId = newAlbumId;
      albumRoll.skipIntro();
    }

    // Set difficulty star count.
    albumRoll.setDifficultyStars(daSong?.data.getDifficulty(currentDifficulty, currentVariation)?.difficultyRating ?? 0);

    currentCapsule.selected = true; // set selected again, so it can run its getter function to initialize movement
  }

  #if FEATURE_TOUCH_CONTROLS
  function handleDiffDragRelease(diff:FlxSprite):Void
  {
    if (SwipeUtil.flickLeft) handleDiffBoundaryChange(1);
    else if (SwipeUtil.flickRight) handleDiffBoundaryChange(-1);

    draggingDifficulty = false;
    _dragOffset = 0;
  }

  function handleDiffBoundaryChange(change:Int):Void
  {
    if (!controls.active) return;
    dj?.resetAFKTimer();
    changeDiff(change);
    generateSongList(currentFilter, true, false);
    FlxG.touches.flickManager.destroy();
    _flickEnded = true;
    _dragOffset = 0;
    draggingDifficulty = false;
  }
  #end

  function capsuleOnConfirmRandom(randomCapsule:SongMenuItem):Void
  {
    trace('RANDOM SELECTED');

    controls.active = false;
    #if NO_FEATURE_TOUCH_CONTROLS
    letterSort.inputEnabled = false;
    #end

    var availableSongCapsules:Array<SongMenuItem> = grpCapsules.members.filter(function(cap:SongMenuItem) {
      // Dead capsules are ones which were removed from the list when changing filters.
      return cap.alive && cap.freeplayData != null;
    });

    trace('Available songs: ${availableSongCapsules.map(function(cap) {
      return cap?.freeplayData?.data.songName;
    })}');

    if (availableSongCapsules.length == 0)
    {
      trace('No songs available!');
      controls.active = true;
      #if NO_FEATURE_TOUCH_CONTROLS
      letterSort.inputEnabled = true;
      #end
      FunkinSound.playOnce(Paths.sound('cancelMenu'));
      return;
    }

    var targetSong:SongMenuItem = FlxG.random.getObject(availableSongCapsules);

    // Seeing if I can do an animation...
    curSelected = grpCapsules.members.indexOf(targetSong);
    changeSelection(0); // Trigger an update.

    // Act like we hit Confirm on that song.
    capsuleOnConfirmDefault(targetSong);
  }

  /**
   * Called when hitting ENTER to open the instrumental list.
   */
  function capsuleOnOpenDefault(cap:SongMenuItem):Void
  {
    controls.active = false;
    letterSort.inputEnabled = false;
    var targetSongId:String = cap?.freeplayData?.data.id ?? 'unknown';
    var targetSongNullable:Null<Song> = SongRegistry.instance.fetchEntry(targetSongId);
    if (targetSongNullable == null)
    {
      FlxG.log.warn('WARN: could not find song with id (${targetSongId})');
      controls.active = true;
      letterSort.inputEnabled = true;
      return;
    }
    var targetSong:Song = targetSongNullable;
    var targetDifficultyId:String = currentDifficulty;
    var targetVariation:Null<String> = currentVariation;
    trace('target song: ${targetSongId} (${targetVariation})');
    var targetLevelId:Null<String> = cap?.freeplayData?.levelId;
    PlayStatePlaylist.campaignId = targetLevelId ?? null;

    var targetDifficulty:Null<SongDifficulty> = targetSong.getDifficulty(targetDifficultyId, targetVariation);
    if (targetDifficulty == null)
    {
      FlxG.log.warn('WARN: could not find difficulty with id (${targetDifficultyId})');
      controls.active = true;
      letterSort.inputEnabled = true;
      return;
    }

    trace('target difficulty: ${targetDifficultyId}');
    trace('target variation: ${targetDifficulty?.variation ?? Constants.DEFAULT_VARIATION}');

    var baseInstrumentalId:String = targetSong.getBaseInstrumentalId(targetDifficultyId, targetDifficulty?.variation ?? Constants.DEFAULT_VARIATION) ?? '';
    var altInstrumentalIds:Array<String> = targetSong.listAltInstrumentalIds(targetDifficultyId,
      targetDifficulty?.variation ?? Constants.DEFAULT_VARIATION) ?? [];

    #if !mobile
    if (altInstrumentalIds.length > 0)
    {
      var instrumentalIds = [baseInstrumentalId].concat(altInstrumentalIds);
      openInstrumentalList(cap, instrumentalIds);

      return;
    }
    #end

    #if mobile
    trace('ALTS ARE DISABLED');
    #else
    trace('NO ALTS');
    #end
    capsuleOnConfirmDefault(cap);
  }

  public function getControls():Controls
  {
    return controls;
  }

  function openInstrumentalList(cap:SongMenuItem, instrumentalIds:Array<String>):Void
  {
    capsuleOptionsMenu = new CapsuleOptionsMenu(this, cap.targetPos.x + 175, cap.targetPos.y + 115, instrumentalIds);
    capsuleOptionsMenu.cameras = [funnyCam];
    capsuleOptionsMenu.zIndex = 10000;
    add(capsuleOptionsMenu);

    capsuleOptionsMenu.onConfirm = function(targetInstId:String) {
      capsuleOnConfirmDefault(cap, targetInstId);
    };
  }

  var capsuleOptionsMenu:Null<CapsuleOptionsMenu> = null;

  public function cleanupCapsuleOptionsMenu():Void
  {
    this.controls.active = true;
    letterSort.inputEnabled = true;

    if (capsuleOptionsMenu != null)
    {
      remove(capsuleOptionsMenu);
      capsuleOptionsMenu = null;
    }
  }

  /**
   * Called when hitting ENTER to play the song.
   */
  function capsuleOnConfirmDefault(cap:SongMenuItem, ?targetInstId:String):Void
  {
    controls.active = false;
    #if NO_FEATURE_TOUCH_CONTROLS
    letterSort.inputEnabled = false;
    #end

    PlayStatePlaylist.isStoryMode = false;

    var targetSongId:String = cap?.freeplayData?.data.id ?? 'unknown';
    var targetSongNullable:Null<Song> = SongRegistry.instance.fetchEntry(targetSongId);
    if (targetSongNullable == null)
    {
      FlxG.log.warn('WARN: could not find song with id (${targetSongId})');
      controls.active = true;
      letterSort.inputEnabled = true;
      return;
    }
    var targetSong:Song = targetSongNullable;
    var targetVariation:Null<String> = currentVariation;
    var targetLevelId:Null<String> = cap?.freeplayData?.levelId;
    PlayStatePlaylist.campaignId = targetLevelId ?? null;

    var targetDifficulty:Null<SongDifficulty> = targetSong.getDifficulty(currentDifficulty, currentVariation);
    if (targetDifficulty == null)
    {
      FlxG.log.warn('WARN: could not find difficulty with id (${currentDifficulty})');
      controls.active = true;
      letterSort.inputEnabled = true;
      return;
    }

    if (targetInstId == null)
    {
      var baseInstrumentalId:String = targetSong?.getBaseInstrumentalId(currentDifficulty, targetDifficulty.variation ?? Constants.DEFAULT_VARIATION) ?? '';
      targetInstId = baseInstrumentalId;
    }

    // Visual and audio effects.
    FunkinSound.playOnce(Paths.sound('confirmMenu'));
    if (dj != null) dj.confirm();

    currentCapsule.forcePosition();
    currentCapsule.confirm();

    backingCard.confirm();
    fadeDots(false);

    // Start vibration after half of second.
    if (HapticUtil.hapticsAvailable)
    {
      new FlxTimer().start(0.5, function(tmr) {
        switch (currentCharacterId)
        {
          // Toggles the bool that allows vibration on update.
          case "pico":
            allowPicoBulletsVibration = true;
            new FlxTimer().start(0.5, function(tmr) {
              allowPicoBulletsVibration = false;
            });

          // A single vibration.
          default:
            HapticUtil.vibrate(Constants.DEFAULT_VIBRATION_PERIOD, Constants.DEFAULT_VIBRATION_DURATION * 5, (Constants.MAX_VIBRATION_AMPLITUDE / 3) * 2.5);
        }
      });
    }

    new FlxTimer().start(styleData?.getStartDelay(), function(tmr:FlxTimer) {
      FunkinSound.emptyPartialQueue();

      Paths.setCurrentLevel(cap?.freeplayData?.levelId);
      LoadingState.loadPlayState(
        {
          targetSong: targetSong,
          targetDifficulty: currentDifficulty,
          targetVariation: currentVariation,
          targetInstrumental: targetInstId,
          practiceMode: false,
          minimalMode: false,

          #if FEATURE_DEBUG_FUNCTIONS
          botPlayMode: FlxG.keys.pressed.SHIFT,
          #else
          botPlayMode: false,
          #end
          // TODO: Make these an option! It's currently only accessible via chart editor.
          // startTimestamp: 0.0,
          // playbackRate: 0.5,
          // botPlayMode: true,
        }, true);
    });
  }

  function refreshCapsuleDisplays():Void
  {
    grpCapsules.forEachAlive((cap:SongMenuItem) -> {
      cap.refreshDisplay();
    });
  }

  function rememberSelection():Void
  {
    if (rememberedSongId != null)
    {
      curSelected = currentFilteredSongs.findIndex(function(song) {
        if (song == null) return false;
        return song.data.id == rememberedSongId;
      });

      if (curSelected == -1) curSelected = 0;
    }

    if (rememberedDifficulty != null)
    {
      currentDifficulty = rememberedDifficulty;
    }

    if (rememberedVariation != null)
    {
      currentVariation = rememberedVariation;
    }
  }

  function updateSongsScroll():Void
  {
    var prevSelected:Int = curSelected;
    curSelected = Math.round(curSelectedFloat);

    for (index => capsule in grpCapsules.members)
    {
      index += 1;

      capsule.selected = false;
      capsule.forceHighlight = index == curSelected + 1;

      capsule.targetPos.y = capsule.intendedY(index - curSelectedFloat);
      capsule.targetPos.x = capsule.intendedX(index - curSelectedFloat) + (CUTOUT_WIDTH * SONGS_POS_MULTI);
    }

    if (curSelected != prevSelected)
    {
      FunkinSound.playOnce(Paths.sound('scrollMenu'), 0.4);
      HapticUtil.vibrate(0, 0.01, 0.5);
      dj?.resetAFKTimer();
      _pressedOnSelected = false;
    }
  }

  function changeSelection(change:Int = 0):Void
  {
    var prevSelected:Int = curSelected;

    curSelected += change;
    curSelectedFloat = curSelected;

    if (curSelected < 0)
    {
      #if FEATURE_TOUCH_CONTROLS
      curSelected = (SwipeUtil.flickUp && !ControlsHandler.usingExternalInputDevice) ? 0 : grpCapsules.countLiving() - 1;
      SwipeUtil.resetSwipeVelocity();
      #else
      curSelected = grpCapsules.countLiving() - 1;
      #end
    }
    if (curSelected >= grpCapsules.countLiving())
    {
      #if FEATURE_TOUCH_CONTROLS
      curSelected = (SwipeUtil.flickDown && !ControlsHandler.usingExternalInputDevice) ? grpCapsules.countLiving() - 1 : 0;
      SwipeUtil.resetSwipeVelocity();
      #else
      curSelected = 0;
      #end
    }

    if (!prepForNewRank && curSelected != prevSelected) FunkinSound.playOnce(Paths.sound('scrollMenu'), 0.4);

    var daSongCapsule:SongMenuItem = currentCapsule;
    if (daSongCapsule.freeplayData != null)
    {
      var songScore:Null<SaveScoreData> = Save.instance.getSongScore(daSongCapsule.freeplayData.data.id, currentDifficulty, currentVariation);
      intendedScore = songScore?.score ?? 0;
      intendedCompletion = songScore == null ? 0.0 : ((songScore.tallies.sick +
        songScore.tallies.good - songScore.tallies.missed) / songScore.tallies.totalNotes);
      rememberedSongId = daSongCapsule.freeplayData.data.id;
      changeDiff();
      daSongCapsule.refreshDisplay((prepForNewRank == true) ? false : true);
    }
    else
    {
      intendedScore = 0;
      intendedCompletion = 0.0;
      rememberedSongId = null;
      albumRoll.albumId = null;
      changeDiff();
      daSongCapsule.refreshDisplay();
    }

    for (index => capsule in grpCapsules.members)
    {
      index += 1;

      capsule.forceHighlight = false;
      capsule.selected = index == curSelected + 1;

      capsule.curSelected = curSelected;

      capsule.targetPos.y = capsule.intendedY(index - curSelected);
      capsule.targetPos.x = capsule.intendedX(index - curSelected) + (CUTOUT_WIDTH * SONGS_POS_MULTI);
      if (index < curSelected #if FEATURE_TOUCH_CONTROLS
        && ControlsHandler.usingExternalInputDevice #end) capsule.targetPos.y -= 100; // another 100 for good measure
    }

    if (grpCapsules.countLiving() > 0 && !prepForNewRank && controls.active)
    {
      playCurSongPreview(daSongCapsule);
      currentCapsule.selected = true;

      // switchBackingImage(daSongCapsule.freeplayData);
    }

    // Small vibrations every selection change.
    if (change != 0) HapticUtil.vibrate(0, 0.01, 0.5);
  }

  public function playCurSongPreview(?daSongCapsule:SongMenuItem):Void
  {
    if (daSongCapsule == null) daSongCapsule = currentCapsule;
    if (curSelected == 0)
    {
      FunkinSound.playMusic('freeplayRandom',
        {
          startingVolume: 0.0,
          overrideExisting: true,
          restartTrack: false
        });
      FlxG.sound.music.fadeIn(2, 0, 0.8);
    }
    else
    {
      var previewSong:Null<Song> = daSongCapsule?.freeplayData?.data;
      if (previewSong == null) return;

      // Check if character-specific difficulty exists
      var songDifficulty:Null<SongDifficulty> = previewSong.getDifficulty(currentDifficulty, currentVariation);

      var baseInstrumentalId:String = previewSong.getBaseInstrumentalId(currentDifficulty, songDifficulty?.variation ?? Constants.DEFAULT_VARIATION) ?? '';
      var altInstrumentalIds:Array<String> = previewSong.listAltInstrumentalIds(currentDifficulty,
        songDifficulty?.variation ?? Constants.DEFAULT_VARIATION) ?? [];
      var instSuffix:String = baseInstrumentalId;
      #if FEATURE_DEBUG_FUNCTIONS
      if (altInstrumentalIds.length > 0 && FlxG.keys.pressed.CONTROL)
      {
        instSuffix = altInstrumentalIds[0];
      }
      #end
      instSuffix = (instSuffix != '') ? '-$instSuffix' : '';
      // trace('Attempting to play partial preview: ${previewSong.id}:${instSuffix}');
      FunkinSound.playMusic(previewSong.id,
        {
          startingVolume: 0.0,
          overrideExisting: true,
          restartTrack: false,
          mapTimeChanges: false, // The music metadata is not alongside the audio file so this won't work.
          pathsFunction: INST,
          suffix: instSuffix,
          partialParams:
            {
              loadPartial: true,
              start: 0,
              end: 0.2
            },
          onLoad: function() {
            FlxG.sound.music.fadeIn(2, 0, 0.4);
          }
        });
      if (songDifficulty != null)
      {
        Conductor.instance.mapTimeChanges(songDifficulty.timeChanges);
        Conductor.instance.update(FlxG.sound?.music?.time ?? 0.0);
      }
    }
  }

  public function switchBackingImage(?freeplaySongData:FreeplaySongData):Void
  {
    var path = Paths.image('freeplay/freeplayBG${freeplaySongData?.levelId ?? 'week1'}-${currentCharacterId ?? 'bf'}');
    if (!Assets.exists(path)) path = Paths.image('freeplay/freeplayBGweek1-bf');
    backingImage.loadTextureAsync(path);
  }

  /**
   * Build an instance of `FreeplayState` that is above the `MainMenuState`.
   * @return The MainMenuState with the FreeplayState as a substate.
   */
  public static function build(?params:FreeplayStateParams, ?stickers:StickerSubState):MusicBeatState
  {
    // Since CUTOUT_WIDTH is static it might retain some old inccrect values so we update it before loading freeplay
    CUTOUT_WIDTH = FullScreenScaleMode.gameCutoutSize.x / 1.5;
    var result:MainMenuState;
    result = new MainMenuState(true);
    result.openSubState(new FreeplayState(params, stickers));
    result.persistentUpdate = false;
    result.persistentDraw = true;
    return result;
  }

  function favoriteSong():Void
  {
    var targetSong = currentCapsule?.freeplayData;
    if (targetSong != null)
    {
      var realShit:Int = curSelected;
      var isFav = targetSong.toggleFavorite();
      if (isFav)
      {
        grpCapsules.members[realShit].favIcon.visible = true;
        grpCapsules.members[realShit].favIconBlurred.visible = true;
        grpCapsules.members[realShit].favIcon.animation.play('fav');
        grpCapsules.members[realShit].favIconBlurred.animation.play('fav');
        FunkinSound.playOnce(Paths.sound('fav'), 1);
        grpCapsules.members[realShit].checkClip();
        grpCapsules.members[realShit].selected = true; // set selected again, so it can run its getter function to initialize movement
        controls.active = false;

        grpCapsules.members[realShit].doLerp = false;
        FlxTween.tween(grpCapsules.members[realShit], {y: grpCapsules.members[realShit].y - 5}, 0.1, {ease: FlxEase.expoOut});

        FlxTween.tween(grpCapsules.members[realShit], {y: grpCapsules.members[realShit].y + 5}, 0.1,
          {
            ease: FlxEase.expoIn,
            startDelay: 0.1,
            onComplete: function(_) {
              grpCapsules.members[realShit].doLerp = true;
              controls.active = true;
            }
          });
      }
      else
      {
        grpCapsules.members[realShit].favIcon.animation.play('fav', true, true, 9);
        grpCapsules.members[realShit].favIconBlurred.animation.play('fav', true, true, 9);
        FunkinSound.playOnce(Paths.sound('unfav'), 1);
        new FlxTimer().start(0.2, _ -> {
          grpCapsules.members[realShit].favIcon.visible = false;
          grpCapsules.members[realShit].favIconBlurred.visible = false;
          grpCapsules.members[realShit].checkClip();
          grpCapsules.members[realShit].selected = true; // set selected again, so it can run its getter function to initialize movement
        });

        controls.active = false;
        grpCapsules.members[realShit].doLerp = false;
        FlxTween.tween(grpCapsules.members[realShit], {y: grpCapsules.members[realShit].y + 5}, 0.1, {ease: FlxEase.expoOut});
        FlxTween.tween(grpCapsules.members[realShit], {y: grpCapsules.members[realShit].y - 5}, 0.1,
          {
            ease: FlxEase.expoIn,
            startDelay: 0.1,
            onComplete: function(_) {
              grpCapsules.members[realShit].doLerp = true;
              controls.active = true;
            }
          });
      }
    }
  }
}

/**
 * The difficulty selector arrows to the left and right of the difficulty.
 */
@:nullSafety
class DifficultySelector extends FlxSprite
{
  var controls:Controls;
  var whiteShader:PureColor;

  #if FEATURE_TOUCH_CONTROLS
  var pressed:Bool = false;
  #end

  public function new(x:Float, y:Float, flipped:Bool, controls:Controls, ?styleData:FreeplayStyle)
  {
    super(x, y);
    this.controls = controls;
    this.whiteShader = new PureColor(FlxColor.WHITE);

    this.frames = Paths.getSparrowAtlas(styleData?.getSelectorAssetKey() ?? "freeplay/freeplaySelector");
    animation.addByPrefix('shine', 'arrow pointer loop', 24);
    animation.play('shine');

    this.shader = whiteShader;
    this.flipX = flipped;
  }

  override function update(elapsed:Float):Void
  {
    if (!controls.active) return;

    if (flipX && controls.UI_RIGHT_P) moveShitDown();
    if (!flipX && controls.UI_LEFT_P) moveShitDown();
    super.update(elapsed);
  }

  #if FEATURE_TOUCH_CONTROLS
  public function setPress(press:Bool):Void
  {
    if (!press)
    {
      scale.x = scale.y = 1;
      whiteShader.colorSet = false;
      updateHitbox();
    }
    else
    {
      offset.y = -5;
      whiteShader.colorSet = true;
      scale.x = scale.y = 0.5;
    }

    pressed = press;
  }

  override function updateHitbox()
  {
    super.updateHitbox();
    width *= 1.5;
    height *= 1.5;
  }
  #end

  function moveShitDown():Void
  {
    offset.y -= 5;

    whiteShader.colorSet = true;

    scale.x = scale.y = 0.5;

    new FlxTimer().start(2 / 24, function(tmr) {
      scale.x = scale.y = 1;
      whiteShader.colorSet = false;
      updateHitbox();
    });
  }
}

/**
 * Structure for the current song filter.
 */
typedef SongFilter =
{
  var filterType:FilterType;
  var ?filterData:Dynamic;
}

/**
 * Possible types to use for the song filter.
 */
enum abstract FilterType(String)
{
  /**
   * Filter to songs which start with a string
   */
  public var STARTSWITH;

  /**
   * Filter to songs which match a regular expression
   */
  public var REGEXP;

  /**
   * Filter to songs which are favorited
   */
  public var FAVORITE;

  /**
   * Filter to all songs
   */
  public var ALL;
}

/**
 * Data about a specific song in the freeplay menu.
 */
@:nullSafety
class FreeplaySongData
{
  /**
   * We used to have a billion fields, but this SongMetadata variable should be all we need
   * to be able to get most information about an available song.
   * For example, you can get the artist via `data.songArtist`
   *
   * You can usually get various other particulars of a specific difficulty/variation by
   * using data.getDifficulty(), and inputting specifics on your difficulty, variations, etc.
   * See the getters here for songCharacter, fullSongName, and songStartingBpm for examples.
   *
   * @see Song
   */
  public var data:Song;

  /**
   * The level id of the song, useful for sorting from week1 -> week 7 + weekend1
   * and for properly loading PlayStatePlaylist for preloading on web
   */
  public var levelId(get, never):Null<String>;

  function get_levelId():Null<String>
  {
    return _levelId;
  }

  var _levelId:String;

  /**
   * Whether or not the song has been favorited.
   */
  public var isFav:Bool = false;

  /**
   * Whether the player has seen/played this song before within freeplay
   */
  public var isNew(get, never):Bool;

  /**
   * The default opponent for the song.
   * Does the getter stuff for you depending on your current (or rather, rememberd) variation and difficulty.
   */
  public var songCharacter(get, never):String;

  /**
   * The full song name, dynamically generated depending on your current (or rather, rememberd) variation and difficulty.
   */
  public var fullSongName(get, never):String;

  /**
   * The starting BPM of the song, dynamically generated depending on your current (or rather, rememberd) variation and difficulty.
   */
  public var songStartingBpm(get, never):Float;

  public var difficultyRating(get, never):Int;

  public var scoringRank(get, never):Null<ScoringRank>;

  public function new(data:Song, levelData:Level)
  {
    this.data = data;
    _levelId = levelData.id;
    this.isFav = Save.instance.isSongFavorited(data.songName);
  }

  /**
   * Toggle whether or not the song is favorited, then flush to save data.
   * @return Whether or not the song is now favorited.
   */
  public function toggleFavorite():Bool
  {
    isFav = !isFav;
    if (isFav)
    {
      Save.instance.favoriteSong(data.songName);
    }
    else
    {
      Save.instance.unfavoriteSong(data.songName);
    }
    return isFav;
  }

  function updateValues(variations:Array<String>):Void
  {
    // this.isNew = song.isSongNew(suffixedDifficulty);
  }

  public function isDifficultyNew(difficulty:String):Bool
  {
    // grabs a specific difficulty's new status. used for the difficulty dots.

    var variations:Array<String> = data.getVariationsByCharacterId(FreeplayState.rememberedCharacterId);
    var variation:Null<String> = data.getFirstValidVariation(difficulty, null, variations);
    if (variation == null) variation = Constants.DEFAULT_VARIATION;
    return data.isSongNew(difficulty, variation);
  }

  function get_isNew():Bool
  {
    // We use a slightly different manner to get the new status of a song than the other getters here
    // `isSongNew()` only takes a single variation, and it's data that isn't accessible via the Song data/metadata
    // it's stored in the song .hxc script in a function that overrides `isSongNew()`
    // and is only accessible with the correct valid variation inputs

    var variations:Array<String> = data.getVariationsByCharacterId(FreeplayState.rememberedCharacterId);
    var variation:Null<String> = data.getFirstValidVariation(FreeplayState.rememberedDifficulty, null, variations);
    if (variation == null) variation = Constants.DEFAULT_VARIATION;
    return data.isSongNew(FreeplayState.rememberedDifficulty, variation);
  }

  function get_songCharacter():String
  {
    var variations:Array<String> = data.getVariationsByCharacterId(FreeplayState.rememberedCharacterId);
    return data.getDifficulty(FreeplayState.rememberedDifficulty, null, variations)?.characters.opponent ?? '';
  }

  function get_fullSongName():String
  {
    var variations:Array<String> = data.getVariationsByCharacterId(FreeplayState.rememberedCharacterId);

    return data.getDifficulty(FreeplayState.rememberedDifficulty, null, variations)?.songName ?? data.songName;
  }

  function get_songStartingBpm():Float
  {
    var variations:Array<String> = data.getVariationsByCharacterId(FreeplayState.rememberedCharacterId);

    return data.getDifficulty(FreeplayState.rememberedDifficulty, null, variations)?.getStartingBPM() ?? 0;
  }

  function get_difficultyRating():Int
  {
    var variations:Array<String> = data.getVariationsByCharacterId(FreeplayState.rememberedCharacterId);
    return data.getDifficulty(FreeplayState.rememberedDifficulty, null, variations)?.difficultyRating ?? 0;
  }

  function get_scoringRank():Null<ScoringRank>
  {
    var variations:Array<String> = data.getVariationsByCharacterId(FreeplayState.rememberedCharacterId);
    var variation:Null<String> = data.getFirstValidVariation(FreeplayState.rememberedDifficulty, null, variations);

    return Save.instance.getSongRank(data.id, FreeplayState.rememberedDifficulty, variation);
  }
}

/**
 * Parameters used to initialize the FreeplayState.
 */
typedef FreeplayStateParams =
{
  ?character:String,
  ?fromCharSelect:Bool,
  ?fromResults:FromResultsParams,
};

/**
 * A set of parameters for transitioning to the FreeplayState from the ResultsState.
 */
typedef FromResultsParams =
{
  /**
   * The previous rank the song hand, if any. Null if it had no score before.
   */
  var ?oldRank:ScoringRank;

  /**
   * Whether or not to play the rank animation on returning to freeplay.
   */
  var playRankAnim:Bool;

  /**
   * The new rank the song has.
   */
  var newRank:ScoringRank;

  /**
   * The song ID to play the animation on.
   */
  var songId:String;

  /**
   * The difficulty ID to play the animation on.
   */
  var difficultyId:String;
};

/**
 * The map storing information about the exit movers.
 */
typedef ExitMoverData = Map<Array<FlxSprite>, MoveData>;

/**
 * The data for an exit mover.
 */
typedef MoveData =
{
  var ?x:Float;
  var ?y:Float;
  var ?speed:Float;
  var ?wait:Float;
}
