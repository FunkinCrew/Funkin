package funkin.ui.debug.charting;

import funkin.play.stage.StageData;
import funkin.play.character.CharacterData.CharacterDataParser;
import funkin.play.character.CharacterData;
import flixel.system.FlxAssets.FlxSoundAsset;
import flixel.math.FlxMath;
import haxe.ui.components.TextField;
import haxe.ui.components.DropDown;
import haxe.ui.components.NumberStepper;
import haxe.ui.containers.Frame;
import flixel.addons.display.FlxSliceSprite;
import flixel.addons.display.FlxTiledSprite;
import flixel.FlxCamera;
import flixel.FlxSprite;
import flixel.FlxSubState;
import flixel.group.FlxSpriteGroup;
import flixel.addons.transition.FlxTransitionableState;
import flixel.input.keyboard.FlxKey;
import flixel.math.FlxPoint;
import flixel.math.FlxRect;
import flixel.sound.FlxSound;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.tweens.misc.VarTween;
import flixel.util.FlxColor;
import flixel.util.FlxSort;
import flixel.util.FlxTimer;
import funkin.audio.visualize.PolygonSpectogram;
import funkin.audio.VoicesGroup;
import funkin.data.notestyle.NoteStyleRegistry;
import funkin.data.notestyle.NoteStyleRegistry;
import funkin.input.Cursor;
import funkin.input.TurboKeyHandler;
import funkin.modding.events.ScriptEvent;
import funkin.play.character.BaseCharacter.CharacterType;
import funkin.play.HealthIcon;
import funkin.play.notes.NoteSprite;
import funkin.play.notes.Strumline;
import funkin.play.PlayState;
import funkin.play.song.Song;
import funkin.data.song.SongData.SongChartData;
import funkin.data.song.SongRegistry;
import funkin.data.song.SongData.SongEventData;
import funkin.data.song.SongData.SongMetadata;
import funkin.data.song.SongData.SongNoteData;
import funkin.data.song.SongData.SongCharacterData;
import funkin.data.song.SongDataUtils;
import funkin.ui.debug.charting.ChartEditorCommand;
import funkin.ui.debug.charting.ChartEditorCommand;
import funkin.ui.debug.charting.ChartEditorThemeHandler.ChartEditorTheme;
import funkin.ui.debug.charting.ChartEditorToolboxHandler.ChartEditorToolMode;
import funkin.ui.haxeui.components.CharacterPlayer;
import funkin.ui.haxeui.HaxeUIState;
import funkin.util.Constants;
import funkin.util.DateUtil;
import funkin.util.FileUtil;
import funkin.util.SerializerUtil;
import funkin.util.SortUtil;
import funkin.util.WindowUtil;
import haxe.DynamicAccess;
import haxe.io.Bytes;
import haxe.io.Path;
import haxe.ui.components.Label;
import haxe.ui.components.Slider;
import haxe.ui.containers.dialogs.CollapsibleDialog;
import haxe.ui.containers.menus.MenuItem;
import haxe.ui.containers.TreeView;
import haxe.ui.containers.TreeViewNode;
import haxe.ui.core.Component;
import haxe.ui.core.Screen;
import haxe.ui.events.DragEvent;
import haxe.ui.events.UIEvent;
import haxe.ui.notifications.NotificationManager;
import haxe.ui.notifications.NotificationType;
import openfl.Assets;
import openfl.display.BitmapData;
import openfl.geom.Rectangle;

using Lambda;

/**
 * A state dedicated to allowing the user to create and edit song charts.
 * Built with HaxeUI for use by both developers and modders.
 *
 * Some functionality is moved to other classes to help maintain my sanity.
 *
 * @author MasterEric
 */
// Give other classes access to private instance fields
// @:nullSafety(Loose) // Enable this while developing, then disable to keep unit tests functional!

@:allow(funkin.ui.debug.charting.ChartEditorCommand)
@:allow(funkin.ui.debug.charting.ChartEditorDropdowns)
@:allow(funkin.ui.debug.charting.ChartEditorDialogHandler)
@:allow(funkin.ui.debug.charting.ChartEditorThemeHandler)
@:allow(funkin.ui.debug.charting.ChartEditorAudioHandler)
@:allow(funkin.ui.debug.charting.ChartEditorImportExportHandler)
@:allow(funkin.ui.debug.charting.ChartEditorToolboxHandler)
class ChartEditorState extends HaxeUIState
{
  /**
   * CONSTANTS
   */
  // ==============================
  // XML Layouts
  static final CHART_EDITOR_LAYOUT:String = Paths.ui('chart-editor/main-view');

  static final CHART_EDITOR_NOTIFBAR_LAYOUT:String = Paths.ui('chart-editor/components/notifbar');
  static final CHART_EDITOR_PLAYBARHEAD_LAYOUT:String = Paths.ui('chart-editor/components/playbar-head');

  static final CHART_EDITOR_TOOLBOX_TOOLS_LAYOUT:String = Paths.ui('chart-editor/toolbox/tools');
  static final CHART_EDITOR_TOOLBOX_NOTEDATA_LAYOUT:String = Paths.ui('chart-editor/toolbox/notedata');
  static final CHART_EDITOR_TOOLBOX_EVENTDATA_LAYOUT:String = Paths.ui('chart-editor/toolbox/eventdata');
  static final CHART_EDITOR_TOOLBOX_METADATA_LAYOUT:String = Paths.ui('chart-editor/toolbox/metadata');
  static final CHART_EDITOR_TOOLBOX_DIFFICULTY_LAYOUT:String = Paths.ui('chart-editor/toolbox/difficulty');
  static final CHART_EDITOR_TOOLBOX_PLAYER_PREVIEW_LAYOUT:String = Paths.ui('chart-editor/toolbox/player-preview');
  static final CHART_EDITOR_TOOLBOX_OPPONENT_PREVIEW_LAYOUT:String = Paths.ui('chart-editor/toolbox/opponent-preview');

  // Validation
  static final SUPPORTED_MUSIC_FORMATS:Array<String> = ['ogg'];

  /**
   * The base grid size for the chart editor.
   */
  public static final GRID_SIZE:Int = 40;

  public static final PLAYHEAD_SCROLL_AREA_WIDTH:Int = 12;

  public static final PLAYHEAD_HEIGHT:Int = Std.int(GRID_SIZE / 8);

  public static final GRID_SELECTION_BORDER_WIDTH:Int = 6;

  /**
   * Number of notes in each player's strumline.
   */
  public static final STRUMLINE_SIZE:Int = 4;

  /**
   * The height of the menu bar in the layout.
   */
  static final MENU_BAR_HEIGHT:Int = 32;

  /**
   * The height of the playbar in the layout.
   */
  static final PLAYBAR_HEIGHT:Int = 48;

  /**
   * Duration to wait before autosaving the chart.
   */
  static final AUTOSAVE_TIMER_DELAY:Float = 60.0 * 5.0;

  /**
   * The amount of padding between the menu bar and the chart grid when fully scrolled up.
   */
  static final GRID_TOP_PAD:Int = 8;

  /**
   * Duration, in milliseconds, until toast notifications are automatically hidden.
   */
  static final NOTIFICATION_DISMISS_TIME:Int = 5000;

  /**
   * Duration, in seconds, for the scroll easing animation.
   */
  static final SCROLL_EASE_DURATION:Float = 0.2;

  // UI Element Colors
  // Background color tint.
  static final CURSOR_COLOR:FlxColor = 0xE0FFFFFF;
  static final PREVIEW_BG_COLOR:FlxColor = 0xFF303030;
  static final PLAYHEAD_SCROLL_AREA_COLOR:FlxColor = 0xFF682B2F;
  static final SPECTROGRAM_COLOR:FlxColor = 0xFFFF0000;
  static final PLAYHEAD_COLOR:FlxColor = 0xC0BD0231;

  /**
   * How many pixels far the user needs to move the mouse before the cursor is considered to be dragged rather than clicked.
   */
  static final DRAG_THRESHOLD:Float = 16.0;

  /**
   * Types of notes you can snap to.
   */
  static final SNAP_QUANTS:Array<Int> = [4, 8, 12, 16, 20, 24, 32, 48, 64, 96, 192];

  static final BASE_QUANT:Int = 16;

  /**
   * INSTANCE DATA
   */
  // ==============================

  /**
   * The internal index of what note snapping value is in use.
   * Increment to make placement more preceise and decrement to make placement less precise.
   */
  var noteSnapQuantIndex:Int = 3; // default is 16

  /**
   * The current note snapping value.
   * For example, `32` when snapping to 32nd notes.
   */
  public var noteSnapQuant(get, never):Int;

  function get_noteSnapQuant():Int
  {
    return SNAP_QUANTS[noteSnapQuantIndex];
  }

  /**
   * The ratio of the current note snapping value to the default.
   * For example, `32` becomes `0.5` when snapping to 16th notes.
   */
  public var noteSnapRatio(get, never):Float;

  function get_noteSnapRatio():Float
  {
    return BASE_QUANT / noteSnapQuant;
  }

  /**
   * scrollPosition is the current position in the song, in pixels.
   * One pixel is 1/40 of 1 step, and 1/160 of 1 beat.
   */
  var scrollPositionInPixels(default, set):Float = -1.0;

  /**
   * scrollPosition, converted to steps.
   * NOT dependant on BPM, because the size of a grid square does not change with BPM.
   */
  var scrollPositionInSteps(get, set):Float;

  function get_scrollPositionInSteps():Float
  {
    return scrollPositionInPixels / GRID_SIZE;
  }

  function set_scrollPositionInSteps(value:Float):Float
  {
    scrollPositionInPixels = value * GRID_SIZE;
    return value;
  }

  /**
   * scrollPosition, converted to milliseconds.
   * DEPENDANT on BPM, because the duration of a grid square changes with BPM.
   */
  var scrollPositionInMs(get, set):Float;

  function get_scrollPositionInMs():Float
  {
    return Conductor.getStepTimeInMs(scrollPositionInSteps);
  }

  function set_scrollPositionInMs(value:Float):Float
  {
    scrollPositionInSteps = Conductor.getTimeInSteps(value);
    return value;
  }

  /**
   * The position of the playhead, in pixels, relative to the scrollPosition.
   * 0 means playhead is at the top of the grid.
   * 40 means the playhead is 1 grid length below the base position.
   * -40 means the playhead is 1 grid length above the base position.
   */
  var playheadPositionInPixels(default, set):Float = 0.0;

  function set_playheadPositionInPixels(value:Float):Float
  {
    // Make sure playhead doesn't go outside the song.
    if (value + scrollPositionInPixels < 0) value = -scrollPositionInPixels;
    if (value + scrollPositionInPixels > songLengthInPixels) value = songLengthInPixels - scrollPositionInPixels;

    this.playheadPositionInPixels = value;

    // Move the playhead sprite to the correct position.
    gridPlayhead.y = this.playheadPositionInPixels + (MENU_BAR_HEIGHT + GRID_TOP_PAD);

    return this.playheadPositionInPixels;
  }

  /**
   * playheadPosition, converted to steps.
   * NOT dependant on BPM, because the size of a grid square does not change with BPM.
   */
  var playheadPositionInSteps(get, set):Float;

  function get_playheadPositionInSteps():Float
  {
    return playheadPositionInPixels / GRID_SIZE;
  }

  function set_playheadPositionInSteps(value:Float):Float
  {
    playheadPositionInPixels = value * GRID_SIZE;
    return value;
  }

  /**
   * playheadPosition, converted to milliseconds.
   * DEPENDANT on BPM, because the duration of a grid square changes with BPM.
   */
  var playheadPositionInMs(get, set):Float;

  function get_playheadPositionInMs():Float
  {
    return Conductor.getStepTimeInMs(playheadPositionInSteps);
  }

  function set_playheadPositionInMs(value:Float):Float
  {
    playheadPositionInSteps = Conductor.getTimeInSteps(value);
    return value;
  }

  /**
   * songLength, in milliseconds.
   */
  @:isVar var songLengthInMs(get, set):Float = 0;

  function get_songLengthInMs():Float
  {
    if (songLengthInMs <= 0) return 1000;
    return songLengthInMs;
  }

  function set_songLengthInMs(value:Float):Float
  {
    this.songLengthInMs = value;

    // Make sure playhead doesn't go outside the song.
    if (playheadPositionInMs > songLengthInMs) playheadPositionInMs = songLengthInMs;

    return this.songLengthInMs;
  }

  /**
   * songLength, converted to steps.
   * Dependant on BPM, because the size of a grid square does not change with BPM but the length of a beat does.
   */
  var songLengthInSteps(get, set):Float;

  function get_songLengthInSteps():Float
  {
    return Conductor.getTimeInSteps(songLengthInMs);
  }

  function set_songLengthInSteps(value:Float):Float
  {
    // Getting a reasonable result from setting songLengthInSteps requires that Conductor.mapBPMChanges be called first.
    songLengthInMs = Conductor.getStepTimeInMs(value);
    return value;
  }

  /**
   * This is the song's length in PIXELS, same format as scrollPosition.
   * Dependant on BPM, because the size of a grid square does not change with BPM but the length of a beat does.
   */
  var songLengthInPixels(get, set):Int;

  function get_songLengthInPixels():Int
  {
    return Std.int(songLengthInSteps * GRID_SIZE);
  }

  function set_songLengthInPixels(value:Int):Int
  {
    songLengthInSteps = value / GRID_SIZE;
    return value;
  }

  /**
   * The current theme used by the editor.
   * Dictates the appearance of many UI elements.
   * Currently hardcoded to just Light and Dark.
   */
  var currentTheme(default, set):ChartEditorTheme = ChartEditorTheme.Light;

  function set_currentTheme(value:ChartEditorTheme):ChartEditorTheme
  {
    if (value == null || value == currentTheme) return currentTheme;

    currentTheme = value;
    ChartEditorThemeHandler.updateTheme(this);
    return value;
  }

  /**
   * Whether a skip button has been pressed on the playbar, and which one.
   * `null` if no button has been pressed.
   * This will be used to update the scrollPosition (in the same function that handles the scroll wheel), then cleared.
   */
  var playbarButtonPressed:Null<String> = null;

  /**
   * Whether the head of the playbar is currently being dragged with the mouse by the user.
   */
  var playbarHeadDragging:Bool = false;

  /**
   * Whether music was playing before we started dragging the playbar head.
   * If so, then when we stop dragging the playbar head, we should resume song playback.
   */
  var playbarHeadDraggingWasPlaying:Bool = false;

  /**
   * The note kind to use for notes being placed in the chart. Defaults to `''`.
   */
  var selectedNoteKind:String = '';

  /**
   * The note kind to use for notes being placed in the chart. Defaults to `''`.
   */
  var selectedEventKind:String = 'FocusCamera';

  /**
   * The note data as a struct.
   */
  var selectedEventData:DynamicAccess<Dynamic> = {};

  /**
   * Whether to play a metronome sound while the playhead is moving.
   */
  var isMetronomeEnabled:Bool = true;

  /**
   * Use the tool window to affect how the user interacts with the program.
   */
  var currentToolMode:ChartEditorToolMode = ChartEditorToolMode.Select;

  /**
   * The character sprite in the Player Preview window.
   * `null` until accessed.
   */
  var currentPlayerCharacterPlayer:Null<CharacterPlayer> = null;

  /**
   * The character sprite in the Opponent Preview window.
   * `null` until accessed.
   */
  var currentOpponentCharacterPlayer:Null<CharacterPlayer> = null;

  /**
   * The currently selected live input style.
   */
  var currentLiveInputStyle:LiveInputStyle = LiveInputStyle.None;

  /**
   * Whether the current view is in downscroll mode.
   */
  var isViewDownscroll(default, set):Bool = false;

  function set_isViewDownscroll(value:Bool):Bool
  {
    isViewDownscroll = value;

    // Make sure view is updated when we change view modes.
    noteDisplayDirty = true;
    notePreviewDirty = true;
    notePreviewViewportBoundsDirty = true;
    this.scrollPositionInPixels = this.scrollPositionInPixels;

    return isViewDownscroll;
  }

  /**
   * If true, playtesting a chart will skip to the current playhead position.
   */
  var playtestStartTime:Bool = false;

  /**
   * Whether hitsounds are enabled for at least one character.
   */
  var hitsoundsEnabled(get, never):Bool;

  function get_hitsoundsEnabled():Bool
  {
    return hitsoundsEnabledPlayer || hitsoundsEnabledOpponent;
  }

  /**
   * Whether hitsounds are enabled for the player.
   */
  var hitsoundsEnabledPlayer:Bool = true;

  /**
   * Whether hitsounds are enabled for the opponent.
   */
  var hitsoundsEnabledOpponent:Bool = true;

  /**
   * Whether the user's mouse cursor is hovering over a SOLID component of the HaxeUI.
   * If so, ignore mouse events underneath.
   */
  var isCursorOverHaxeUI(get, never):Bool;

  function get_isCursorOverHaxeUI():Bool
  {
    return Screen.instance.hasSolidComponentUnderPoint(FlxG.mouse.screenX, FlxG.mouse.screenY);
  }

  var isCursorOverHaxeUIButton(get, never):Bool;

  function get_isCursorOverHaxeUIButton():Bool
  {
    return Screen.instance.hasSolidComponentUnderPoint(FlxG.mouse.screenX, FlxG.mouse.screenY, haxe.ui.components.Button)
      || Screen.instance.hasSolidComponentUnderPoint(FlxG.mouse.screenX, FlxG.mouse.screenY, haxe.ui.components.Link);
  }

  /**
   * Set by ChartEditorDialogHandler, used to prevent background interaction while the dialog is open.
   */
  public var isHaxeUIDialogOpen:Bool = false;

  /**
   * The variation ID for the difficulty which is currently being edited.
   */
  var selectedVariation(default, set):String = Constants.DEFAULT_VARIATION;

  function set_selectedVariation(value:String):String
  {
    selectedVariation = value;

    // Make sure view is updated when the variation changes.
    noteDisplayDirty = true;
    notePreviewDirty = true;
    notePreviewViewportBoundsDirty = true;

    return selectedVariation;
  }

  /**
   * The difficulty ID for the difficulty which is currently being edited.
   */
  var selectedDifficulty(default, set):String = Constants.DEFAULT_DIFFICULTY;

  function set_selectedDifficulty(value:String):String
  {
    selectedDifficulty = value;

    // Make sure view is updated when the difficulty changes.
    noteDisplayDirty = true;
    notePreviewDirty = true;
    notePreviewViewportBoundsDirty = true;

    return selectedDifficulty;
  }

  /**
   * The character ID for the character which is currently selected.
   */
  var selectedCharacter(default, set):String = Constants.DEFAULT_CHARACTER;

  function set_selectedCharacter(value:String):String
  {
    selectedCharacter = value;

    // Make sure view is updated when the character changes.
    noteDisplayDirty = true;
    notePreviewDirty = true;
    notePreviewViewportBoundsDirty = true;

    return selectedCharacter;
  }

  /**
   * Whether the user is currently in Pattern Mode.
   * This overrides the chart editor's normal behavior.
   */
  var isInPatternMode(default, set):Bool = false;

  function set_isInPatternMode(value:Bool):Bool
  {
    isInPatternMode = value;

    // Make sure view is updated when we change modes.
    noteDisplayDirty = true;
    notePreviewDirty = true;
    notePreviewViewportBoundsDirty = true;
    this.scrollPositionInPixels = 0;

    return isInPatternMode;
  }

  var currentPattern:String = '';

  /**
   * Whether the note display render group has been modified and needs to be updated.
   * This happens when we scroll or add/remove notes, and need to update what notes are displayed and where.
   */
  var noteDisplayDirty:Bool = true;

  /**
   * Whether the note preview graphic needs to be FULLY rebuilt.
   */
  var notePreviewDirty(default, set):Bool = true;

  function set_notePreviewDirty(value:Bool):Bool
  {
    trace('Note preview dirtied!');
    return notePreviewDirty = value;
  }

  var notePreviewViewportBoundsDirty:Bool = true;

  /**
   * Whether the chart has been modified since it was last saved.
   * Used to determine whether to auto-save, etc.
   */
  var saveDataDirty(default, set):Bool = false;

  function set_saveDataDirty(value:Bool):Bool
  {
    if (value == saveDataDirty) return value;

    if (value)
    {
      // Start the auto-save timer.
      autoSaveTimer = new FlxTimer().start(AUTOSAVE_TIMER_DELAY, (_) -> autoSave());
    }
    else
    {
      if (autoSaveTimer != null)
      {
        // Stop the auto-save timer.
        autoSaveTimer.cancel();
        autoSaveTimer.destroy();
        autoSaveTimer = null;
      }
    }

    return saveDataDirty = value;
  }

  /**
   * A timer used to auto-save the chart after a period of inactivity.
   */
  var autoSaveTimer:Null<FlxTimer> = null;

  /**
   * Whether the difficulty tree view in the toolbox has been modified and needs to be updated.
   * This happens when we add/remove difficulties.
   */
  var difficultySelectDirty:Bool = true;

  /**
   * Whether the character select view in the toolbox has been modified and needs to be updated.
   * This happens when we add/remove characters.
   */
  var characterSelectDirty:Bool = true;

  /**
   * Whether the player preview toolbox have been modified and need to be updated.
   * This happens when we switch characters.
   */
  var playerPreviewDirty:Bool = true;

  /**
   * Whether the opponent preview toolbox have been modified and need to be updated.
   * This happens when we switch characters.
   */
  var opponentPreviewDirty:Bool = true;

  var isInPlaytestMode:Bool = false;

  /**
   * The list of command previously performed. Used for undoing previous actions.
   */
  var undoHistory:Array<ChartEditorCommand> = [];

  /**
   * The list of commands that have been undone. Used for redoing previous actions.
   */
  var redoHistory:Array<ChartEditorCommand> = [];

  /**
   * Handler used to track how long the user has been holding the undo keybind.
   */
  var undoKeyHandler:TurboKeyHandler = TurboKeyHandler.build([FlxKey.CONTROL, FlxKey.Z]);

  /**
   * Variable used to track how long the user has been holding the redo keybind.
   */
  var redoKeyHandler:TurboKeyHandler = TurboKeyHandler.build([FlxKey.CONTROL, FlxKey.Y]);

  /**
   * Variable used to track how long the user has been holding the up keybind.
   */
  var upKeyHandler:TurboKeyHandler = TurboKeyHandler.build(FlxKey.UP);

  /**
   * Variable used to track how long the user has been holding the down keybind.
   */
  var downKeyHandler:TurboKeyHandler = TurboKeyHandler.build(FlxKey.DOWN);

  /**
   * Variable used to track how long the user has been holding the page-up keybind.
   */
  var pageUpKeyHandler:TurboKeyHandler = TurboKeyHandler.build(FlxKey.PAGEUP);

  /**
   * Variable used to track how long the user has been holding the page-down keybind.
   */
  var pageDownKeyHandler:TurboKeyHandler = TurboKeyHandler.build(FlxKey.PAGEDOWN);

  /**
   * Whether the undo/redo histories have changed since the last time the UI was updated.
   */
  var commandHistoryDirty:Bool = true;

  /**
   * The notes which are currently in the user's selection.
   */
  var currentNoteSelection:Array<SongNoteData> = [];

  /**
   * The events which are currently in the user's selection.
   */
  var currentEventSelection:Array<SongEventData> = [];

  /**
   * The position where the user clicked to start a selection.
   * `null` if the user isn't currently selecting anything.
   * The selection box extends from this point to the current mouse position.
   */
  var selectionBoxStartPos:Null<FlxPoint> = null;

  /**
   * Whether the user's last mouse click was on the playhead scroll area.
   */
  var gridPlayheadScrollAreaPressed:Bool = false;

  /**
   * Where the user's last mouse click was on the note preview scroll area.
   * `null` if the user isn't clicking on the note preview.
   */
  var notePreviewScrollAreaStartPos:Null<FlxPoint> = null;

  /**
   * The SongNoteData which is currently being placed.
   * `null` if the user isn't currently placing a note.
   * As the user drags, we will update this note's sustain length.
   */
  var currentPlaceNoteData:Null<SongNoteData> = null;

  /**
   * The Dialog components representing the currently available tool windows.
   * Dialogs are retained here even when collapsed or hidden.
   */
  var activeToolboxes:Map<String, CollapsibleDialog> = new Map<String, CollapsibleDialog>();

  /**
   * AUDIO AND SOUND DATA
   */
  // ==============================

  /**
   * The chill audio track that plays when you open the Chart Editor.
   */
  public var welcomeMusic:FlxSound = new FlxSound();

  /**
   * The audio track for the instrumental.
   * `null` until an instrumental track is loaded.
   */
  var audioInstTrack:Null<FlxSound> = null;

  /**
   * The raw byte data for the instrumental audio track.
   * `null` until an instrumental track is loaded.
   */
  var audioInstTrackData:Null<Bytes> = null;

  /**
   * The audio track for the vocals.
   * `null` until vocal track(s) are loaded.
   */
  var audioVocalTrackGroup:Null<VoicesGroup> = null;

  /**
   * A map of the audio tracks for each character's vocals.
   * - Keys are the character IDs.
   * - Values are the FlxSound objects to play that character's vocals.
   *
   * When switching characters, the elements of the VoicesGroup will be swapped to match the new character.
   */
  var audioVocalTrackData:Map<String, Bytes> = [];

  /**
   * CHART DATA
   */
  // ==============================

  /**
   * The song metadata.
   * - Keys are the variation IDs. At least one (`default`) must exist.
   * - Values are the relevant metadata, ready to be serialized to JSON.
   */
  var songMetadata:Map<String, SongMetadata> = [];

  /**
   * Retrieves the list of variations for the current song.
   */
  var availableVariations(get, never):Array<String>;

  function get_availableVariations():Array<String>
  {
    var variations:Array<String> = [for (x in songMetadata.keys()) x];
    variations.sort(SortUtil.defaultThenAlphabetically.bind('default'));
    return variations;
  }

  /**
   * Retrieves the list of difficulties for the current variation of the current song.
   * ONLY CONTAINS DIFFICULTIES FOR THE CURRENT VARIATION so if on the default variation, erect/nightmare won't be included.
   */
  var availableDifficulties(get, never):Array<String>;

  function get_availableDifficulties():Array<String>
  {
    var m:Null<SongMetadata> = songMetadata.get(selectedVariation);
    return m?.playData?.difficulties ?? [];
  }

  /**
   * Retrieves the list of difficulties for ALL variations of the current song.
   */
  var allDifficulties(get, never):Array<String>;

  function get_allDifficulties():Array<String>
  {
    var result:Array<Array<String>> = [
      for (x in availableVariations)
      {
        var m:Null<SongMetadata> = songMetadata.get(x);
        m?.playData?.difficulties ?? [];
      }
    ];
    return result.flatten();
  }

  /**
   * The song chart data.
   * - Keys are the variation IDs. At least one (`default`) must exist.
   * - Values are the relevant chart data, ready to be serialized to JSON.
   */
  var songChartData:Map<String, SongChartData> = [];

  /**
   * Convenience property to get the chart data for the current variation.
   */
  var currentSongMetadata(get, set):SongMetadata;

  function get_currentSongMetadata():SongMetadata
  {
    var result:Null<SongMetadata> = songMetadata.get(selectedVariation);
    if (result == null)
    {
      result = new SongMetadata('Dad Battle', 'Kawai Sprite', selectedVariation);
      songMetadata.set(selectedVariation, result);
    }
    return result;
  }

  function set_currentSongMetadata(value:SongMetadata):SongMetadata
  {
    songMetadata.set(selectedVariation, value);
    return value;
  }

  /**
   * Convenience property to get the chart data for the current variation.
   */
  var currentSongChartData(get, set):SongChartData;

  function get_currentSongChartData():SongChartData
  {
    var result:Null<SongChartData> = songChartData.get(selectedVariation);
    if (result == null)
    {
      result = new SongChartData(["normal" => 1.0], [], ["normal" => []]);
      songChartData.set(selectedVariation, result);
    }
    return result;
  }

  function set_currentSongChartData(value:SongChartData):SongChartData
  {
    songChartData.set(selectedVariation, value);
    return value;
  }

  /**
   * Convenience property to get (and set) the scroll speed for the current difficulty.
   */
  var currentSongChartScrollSpeed(get, set):Float;

  function get_currentSongChartScrollSpeed():Float
  {
    var result:Null<Float> = currentSongChartData.scrollSpeed.get(selectedDifficulty);
    if (result == null)
    {
      // Initialize to the default value if not set.
      currentSongChartData.scrollSpeed.set(selectedDifficulty, 1.0);
      return 1.0;
    }
    return result;
  }

  function set_currentSongChartScrollSpeed(value:Float):Float
  {
    currentSongChartData.scrollSpeed.set(selectedDifficulty, value);
    return value;
  }

  /**
   * Convenience property to get the note data for the current difficulty.
   */
  var currentSongChartNoteData(get, set):Array<SongNoteData>;

  function get_currentSongChartNoteData():Array<SongNoteData>
  {
    var result:Array<SongNoteData> = currentSongChartData.notes.get(selectedDifficulty);
    if (result == null)
    {
      // Initialize to the default value if not set.
      result = [];
      trace('Initializing blank note data for difficulty ' + selectedDifficulty);
      currentSongChartData.notes.set(selectedDifficulty, result);
      return result;
    }
    return result;
  }

  function set_currentSongChartNoteData(value:Array<SongNoteData>):Array<SongNoteData>
  {
    currentSongChartData.notes.set(selectedDifficulty, value);
    return value;
  }

  /**
   * Convenience property to get the event data for the current difficulty.
   */
  var currentSongChartEventData(get, set):Array<SongEventData>;

  function get_currentSongChartEventData():Array<SongEventData>
  {
    if (currentSongChartData.events == null)
    {
      // Initialize to the default value if not set.
      currentSongChartData.events = [];
    }
    return currentSongChartData.events;
  }

  function set_currentSongChartEventData(value:Array<SongEventData>):Array<SongEventData>
  {
    return currentSongChartData.events = value;
  }

  public var currentSongNoteStyle(get, set):String;

  function get_currentSongNoteStyle():String
  {
    if (currentSongMetadata.playData.noteSkin == null)
    {
      // Initialize to the default value if not set.
      currentSongMetadata.playData.noteSkin = 'funkin';
    }
    return currentSongMetadata.playData.noteSkin;
  }

  function set_currentSongNoteStyle(value:String):String
  {
    return currentSongMetadata.playData.noteSkin = value;
  }

  var currentSongStage(get, set):String;

  function get_currentSongStage():String
  {
    if (currentSongMetadata.playData.stage == null)
    {
      // Initialize to the default value if not set.
      currentSongMetadata.playData.stage = 'mainStage';
    }
    return currentSongMetadata.playData.stage;
  }

  function set_currentSongStage(value:String):String
  {
    return currentSongMetadata.playData.stage = value;
  }

  var currentSongName(get, set):String;

  function get_currentSongName():String
  {
    if (currentSongMetadata.songName == null)
    {
      // Initialize to the default value if not set.
      currentSongMetadata.songName = 'New Song';
    }
    return currentSongMetadata.songName;
  }

  function set_currentSongName(value:String):String
  {
    return currentSongMetadata.songName = value;
  }

  var currentSongId(get, never):String;

  function get_currentSongId():String
  {
    return currentSongName.toLowerKebabCase().replace('.', '').replace(' ', '-');
  }

  var currentSongArtist(get, set):String;

  function get_currentSongArtist():String
  {
    if (currentSongMetadata.artist == null)
    {
      // Initialize to the default value if not set.
      currentSongMetadata.artist = 'Unknown';
    }
    return currentSongMetadata.artist;
  }

  function set_currentSongArtist(value:String):String
  {
    return currentSongMetadata.artist = value;
  }

  var currentSongCharacterPlayer(get, set):String;

  function get_currentSongCharacterPlayer():String
  {
    return currentSongMetadata.playData.characters.player;
  }

  function set_currentSongCharacterPlayer(value:String):String
  {
    return currentSongMetadata.playData.characters.player = value;
  }

  var currentSongCharacterOpponent(get, set):String;

  function get_currentSongCharacterOpponent():String
  {
    return currentSongMetadata.playData.characters.opponent;
  }

  function set_currentSongCharacterOpponent(value:String):String
  {
    return currentSongMetadata.playData.characters.opponent = value;
  }

  /**
   * SIGNALS
   */
  // ==============================
  // public var onDifficultyChange(default, never):FlxTypedSignal<ChartEditorState->Void> = new FlxTypedSignal<ChartEditorState->Void>();
  /**
   * RENDER OBJECTS
   */
  // ==============================

  /**
   * The IMAGE used for the grid. Updated by ChartEditorThemeHandler.
   */
  var gridBitmap:Null<BitmapData> = null;

  /**
   * The IMAGE used for the selection squares. Updated by ChartEditorThemeHandler.
   * Used two ways:
   * 1. A sprite is given this bitmap and placed over selected notes.
   * 2. The image is split and used for a 9-slice sprite for the selection box.
   */
  var selectionSquareBitmap:Null<BitmapData> = null;

  /**
   * The IMAGE used for the note preview bitmap. Updated by ChartEditorThemeHandler.
   * The image is split and used for a 9-slice sprite for the box over the note preview.
   */
  var notePreviewViewportBitmap:Null<BitmapData> = null;

  /**
   * The tiled sprite used to display the grid.
   * The height is the length of the song, and scrolling is done by simply the sprite.
   */
  var gridTiledSprite:Null<FlxSprite> = null;

  /**
   * The playhead representing the current position in the song.
   * Can move around on the grid independently of the view.
   */
  var gridPlayhead:FlxSpriteGroup = new FlxSpriteGroup();

  var gridPlayheadScrollArea:Null<FlxSprite> = null;

  /**
   * A sprite used to indicate the note that will be placed on click.
   */
  var gridGhostNote:Null<ChartEditorNoteSprite> = null;

  /**
   * A sprite used to indicate the note that will be placed on click.
   */
  var gridGhostHoldNote:Null<ChartEditorHoldNoteSprite> = null;

  /**
   * A sprite used to indicate the event that will be placed on click.
   */
  var gridGhostEvent:Null<ChartEditorEventSprite> = null;

  /**
   * The waveform which (optionally) displays over the grid, underneath the notes and playhead.
   */
  var gridSpectrogram:Null<PolygonSpectogram> = null;

  /**
   * The sprite used to display the note preview area.
   * We move this up and down to scroll the preview.
   */
  var notePreview:Null<ChartEditorNotePreview> = null;

  /**
   * The rectangular sprite used for representing the current viewport on the note preview.
   * We move this up and down and resize it to represent the visible area.
   */
  var notePreviewViewport:Null<FlxSliceSprite> = null;

  /**
   * The rectangular sprite used for rendering the selection box.
   * Uses a 9-slice to stretch the selection box to the correct size without warping.
   */
  var selectionBoxSprite:Null<FlxSliceSprite> = null;

  /**
   * The opponent's health icon.
   */
  var healthIconDad:Null<HealthIcon> = null;

  /**
   * The player's health icon.
   */
  var healthIconBF:Null<HealthIcon> = null;

  /**
   * The purple background sprite.
   */
  var menuBG:Null<FlxSprite> = null;

  /**
   * The layout containing the playbar head slider.
   */
  var playbarHeadLayout:Null<Component> = null;

  /**
   * The playbar head slider.
   */
  var playbarHead:Null<Slider> = null;

  /**
   * The label by the playbar telling the song position.
   */
  var playbarSongPos:Null<Label> = null;

  /**
   * The label by the playbar telling the song time remaining.
   */
  var playbarSongRemaining:Null<Label> = null;

  /**
   * The label by the playbar telling the note snap.
   */
  var playbarNoteSnap:Null<Label> = null;

  /**
   * The current process that is lerping the scroll position.
   * Used to cancel the previous lerp if the user scrolls again.
   */
  var currentScrollEase:Null<VarTween>;

  /**
   * The sprite group containing the note graphics.
   * Only displays a subset of the data from `currentSongChartNoteData`,
   * and kills notes that are off-screen to be recycled later.
   */
  var renderedNotes:FlxTypedSpriteGroup<ChartEditorNoteSprite> = new FlxTypedSpriteGroup<ChartEditorNoteSprite>();

  /**
   * The sprite group containing the hold note graphics.
   * Only displays a subset of the data from `currentSongChartNoteData`,
   * and kills notes that are off-screen to be recycled later.
   */
  var renderedHoldNotes:FlxTypedSpriteGroup<ChartEditorHoldNoteSprite> = new FlxTypedSpriteGroup<ChartEditorHoldNoteSprite>();

  /**
   * The sprite group containing the song events.
   * Only displays a subset of the data from `currentSongChartEventData`,
   * and kills events that are off-screen to be recycled later.
   */
  var renderedEvents:FlxTypedSpriteGroup<ChartEditorEventSprite> = new FlxTypedSpriteGroup<ChartEditorEventSprite>();

  var renderedSelectionSquares:FlxTypedSpriteGroup<FlxSprite> = new FlxTypedSpriteGroup<FlxSprite>();

  public function new()
  {
    // Load the HaxeUI XML file.
    super(CHART_EDITOR_LAYOUT);
  }

  override function create():Void
  {
    // super.create() must be called first, the HaxeUI components get created here.
    super.create();
    // Set the z-index of the HaxeUI.
    this.component.zIndex = 100;

    // Show the mouse cursor.
    Cursor.show();

    fixCamera();

    // Get rid of any music from the previous state.
    FlxG.sound.music.stop();

    // Play the welcome music.
    setupWelcomeMusic();

    buildDefaultSongData();

    buildBackground();

    ChartEditorThemeHandler.updateTheme(this);

    buildGrid();
    // buildSpectrogram(audioInstTrack);
    buildNotePreview();
    buildSelectionBox();

    buildAdditionalUI();

    // Setup the onClick listeners for the UI after it's been created.
    setupUIListeners();
    setupTurboKeyHandlers();

    setupAutoSave();

    refresh();

    ChartEditorDialogHandler.openWelcomeDialog(this, false);
  }

  function setupWelcomeMusic()
  {
    this.welcomeMusic.loadEmbedded(Paths.music('chartEditorLoop/chartEditorLoop'));
    this.welcomeMusic.looped = true;
    // this.welcomeMusic.play();
    // fadeInWelcomeMusic();
  }

  public function fadeInWelcomeMusic():Void
  {
    this.welcomeMusic.play();
    this.welcomeMusic.fadeIn(4, 0, 1.0);
  }

  public function stopWelcomeMusic():Void
  {
    // this.welcomeMusic.fadeOut(4, 0);
    this.welcomeMusic.pause();
  }

  function buildDefaultSongData():Void
  {
    selectedVariation = Constants.DEFAULT_VARIATION;
    selectedDifficulty = Constants.DEFAULT_DIFFICULTY;

    // Initialize the song metadata.
    songMetadata = new Map<String, SongMetadata>();

    // Initialize the song chart data.
    songChartData = new Map<String, SongChartData>();

    audioVocalTrackGroup = new VoicesGroup();
  }

  /**
   * Builds and displays the background sprite.
   */
  function buildBackground():Void
  {
    menuBG = new FlxSprite().loadGraphic(Paths.image('menuDesat'));
    add(menuBG);

    menuBG.setGraphicSize(Std.int(menuBG.width * 1.1));
    menuBG.updateHitbox();
    menuBG.screenCenter();
    menuBG.scrollFactor.set(0, 0);
    menuBG.zIndex = -100;
  }

  /**
   * Builds and displays the chart editor grid, including the playhead and cursor.
   */
  function buildGrid():Void
  {
    if (gridBitmap == null) throw 'ERROR: Tried to build grid, but gridBitmap is null! Check ChartEditorThemeHandler.updateTheme().';

    gridTiledSprite = new FlxTiledSprite(gridBitmap, gridBitmap.width, 1000, false, true);
    gridTiledSprite.x = FlxG.width / 2 - GRID_SIZE * STRUMLINE_SIZE; // Center the grid.
    gridTiledSprite.y = MENU_BAR_HEIGHT + GRID_TOP_PAD; // Push down to account for the menu bar.
    add(gridTiledSprite);
    gridTiledSprite.zIndex = 10;

    gridGhostNote = new ChartEditorNoteSprite(this);
    gridGhostNote.alpha = 0.6;
    gridGhostNote.noteData = new SongNoteData(0, 0, 0, "");
    gridGhostNote.visible = false;
    add(gridGhostNote);
    gridGhostNote.zIndex = 11;

    gridGhostHoldNote = new ChartEditorHoldNoteSprite(this);
    gridGhostHoldNote.alpha = 0.6;
    gridGhostHoldNote.noteData = new SongNoteData(0, 0, 0, "");
    gridGhostHoldNote.visible = false;
    add(gridGhostHoldNote);
    gridGhostHoldNote.zIndex = 11;

    gridGhostEvent = new ChartEditorEventSprite(this);
    gridGhostEvent.alpha = 0.6;
    gridGhostEvent.eventData = new SongEventData(-1, '', {});
    gridGhostEvent.visible = false;
    add(gridGhostEvent);
    gridGhostEvent.zIndex = 12;

    buildNoteGroup();

    gridPlayheadScrollArea = new FlxSprite(0, 0);
    gridPlayheadScrollArea.makeGraphic(10, 10, PLAYHEAD_SCROLL_AREA_COLOR); // Make it 10x10px and then scale it as needed.
    add(gridPlayheadScrollArea);
    gridPlayheadScrollArea.setGraphicSize(PLAYHEAD_SCROLL_AREA_WIDTH, 3000);
    gridPlayheadScrollArea.updateHitbox();
    gridPlayheadScrollArea.x = gridTiledSprite.x - PLAYHEAD_SCROLL_AREA_WIDTH;
    gridPlayheadScrollArea.y = MENU_BAR_HEIGHT + GRID_TOP_PAD;
    gridPlayheadScrollArea.zIndex = 25;

    // The playhead that show the current position in the song.
    add(gridPlayhead);
    gridPlayhead.zIndex = 30;

    var playheadWidth:Int = GRID_SIZE * (STRUMLINE_SIZE * 2 + 1) + (PLAYHEAD_SCROLL_AREA_WIDTH * 2);
    var playheadBaseYPos:Float = MENU_BAR_HEIGHT + GRID_TOP_PAD;
    gridPlayhead.setPosition(gridTiledSprite.x, playheadBaseYPos);
    var playheadSprite:FlxSprite = new FlxSprite().makeGraphic(playheadWidth, PLAYHEAD_HEIGHT, PLAYHEAD_COLOR);
    playheadSprite.x = -PLAYHEAD_SCROLL_AREA_WIDTH;
    playheadSprite.y = 0;
    gridPlayhead.add(playheadSprite);

    var playheadBlock:FlxSprite = ChartEditorThemeHandler.buildPlayheadBlock();
    playheadBlock.x = -PLAYHEAD_SCROLL_AREA_WIDTH;
    playheadBlock.y = -PLAYHEAD_HEIGHT / 2;
    gridPlayhead.add(playheadBlock);

    // Character icons.
    healthIconDad = new HealthIcon(currentSongCharacterOpponent);
    healthIconDad.autoUpdate = false;
    healthIconDad.size.set(0.5, 0.5);
    healthIconDad.x = gridTiledSprite.x - 15 - (HealthIcon.HEALTH_ICON_SIZE * 0.5);
    healthIconDad.y = gridTiledSprite.y + 5;
    add(healthIconDad);
    healthIconDad.zIndex = 30;

    healthIconBF = new HealthIcon(currentSongCharacterPlayer);
    healthIconBF.autoUpdate = false;
    healthIconBF.size.set(0.5, 0.5);
    healthIconBF.x = gridTiledSprite.x + gridTiledSprite.width + 15;
    healthIconBF.y = gridTiledSprite.y + 5;
    healthIconBF.flipX = true;
    add(healthIconBF);
    healthIconBF.zIndex = 30;
  }

  function buildSelectionBox():Void
  {
    if (selectionBoxSprite == null) throw 'ERROR: Tried to build selection box, but selectionBoxSprite is null! Check ChartEditorThemeHandler.updateTheme().';

    selectionBoxSprite.scrollFactor.set(0, 0);
    add(selectionBoxSprite);
    selectionBoxSprite.zIndex = 30;

    setSelectionBoxBounds();
  }

  function setSelectionBoxBounds(bounds:FlxRect = null):Void
  {
    if (selectionBoxSprite == null)
      throw 'ERROR: Tried to set selection box bounds, but selectionBoxSprite is null! Check ChartEditorThemeHandler.updateTheme().';

    if (bounds == null)
    {
      selectionBoxSprite.visible = false;
      selectionBoxSprite.x = -9999;
      selectionBoxSprite.y = -9999;
    }
    else
    {
      selectionBoxSprite.visible = true;
      selectionBoxSprite.x = bounds.x;
      selectionBoxSprite.y = bounds.y;
      selectionBoxSprite.width = bounds.width;
      selectionBoxSprite.height = bounds.height;
    }
  }

  function buildNotePreview():Void
  {
    var height:Int = FlxG.height - MENU_BAR_HEIGHT - GRID_TOP_PAD - PLAYBAR_HEIGHT - GRID_TOP_PAD - GRID_TOP_PAD;
    notePreview = new ChartEditorNotePreview(height);
    notePreview.x = 350;
    notePreview.y = MENU_BAR_HEIGHT + GRID_TOP_PAD;
    add(notePreview);

    if (notePreviewViewport == null) throw 'ERROR: Tried to build note preview, but notePreviewViewport is null! Check ChartEditorThemeHandler.updateTheme().';

    notePreviewViewport.scrollFactor.set(0, 0);
    add(notePreviewViewport);
    notePreviewViewport.zIndex = 30;

    setNotePreviewViewportBounds(calculateNotePreviewViewportBounds());
  }

  function calculateNotePreviewViewportBounds():FlxRect
  {
    var bounds:FlxRect = new FlxRect();

    // Return 0, 0, 0, 0 if the note preview doesn't exist for some reason.
    if (notePreview == null) return bounds;

    // Horizontal position and width are constant.
    bounds.x = notePreview.x;
    bounds.width = notePreview.width;

    // Vertical position depends on scroll position.
    bounds.y = notePreview.y + (notePreview.height * (scrollPositionInPixels / songLengthInPixels));

    // Height depends on the viewport size.
    bounds.height = notePreview.height * (FlxG.height / songLengthInPixels);

    // Make sure the viewport doesn't go off the top or bottom of the note preview.
    if (bounds.y < notePreview.y)
    {
      bounds.height -= notePreview.y - bounds.y;
      bounds.y = notePreview.y;
    }
    else if (bounds.y + bounds.height > notePreview.y + notePreview.height)
    {
      bounds.height -= (bounds.y + bounds.height) - (notePreview.y + notePreview.height);
    }

    var MIN_HEIGHT:Int = 8;
    if (bounds.height < MIN_HEIGHT)
    {
      bounds.y -= MIN_HEIGHT - bounds.height;
      bounds.height = MIN_HEIGHT;
    }

    return bounds;
  }

  function setNotePreviewViewportBounds(bounds:FlxRect = null):Void
  {
    if (notePreviewViewport == null)
      throw 'ERROR: Tried to set note preview viewport bounds, but notePreviewViewport is null! Check ChartEditorThemeHandler.updateTheme().';

    if (bounds == null)
    {
      notePreviewViewport.visible = false;
      notePreviewViewport.x = -9999;
      notePreviewViewport.y = -9999;
    }
    else
    {
      notePreviewViewport.visible = true;
      notePreviewViewport.x = bounds.x;
      notePreviewViewport.y = bounds.y;
      notePreviewViewport.width = bounds.width;
      notePreviewViewport.height = bounds.height;
    }
  }

  function buildSpectrogram(target:FlxSound):Void
  {
    gridSpectrogram = new PolygonSpectogram(FlxG.sound.music, FlxColor.RED, FlxG.height / 2, Math.floor(FlxG.height / 2));
    gridSpectrogram.x += 170;
    gridSpectrogram.scrollFactor.set();
    gridSpectrogram.waveAmplitude = 50;
    gridSpectrogram.visType = UPDATED;
    add(gridSpectrogram);
  }

  /**
   * Builds the group that will hold all the notes.
   */
  function buildNoteGroup():Void
  {
    if (gridTiledSprite == null) throw 'ERROR: Tried to build note groups, but gridTiledSprite is null! Check ChartEditorState.buildGrid().';

    renderedHoldNotes.setPosition(gridTiledSprite.x, gridTiledSprite.y);
    add(renderedHoldNotes);
    renderedHoldNotes.zIndex = 24;

    renderedNotes.setPosition(gridTiledSprite.x, gridTiledSprite.y);
    add(renderedNotes);
    renderedNotes.zIndex = 25;

    renderedEvents.setPosition(gridTiledSprite.x, gridTiledSprite.y);
    add(renderedEvents);
    renderedNotes.zIndex = 25;

    renderedSelectionSquares.setPosition(gridTiledSprite.x, gridTiledSprite.y);
    add(renderedSelectionSquares);
    renderedNotes.zIndex = 26;
  }

  function buildAdditionalUI():Void
  {
    playbarHeadLayout = buildComponent(CHART_EDITOR_PLAYBARHEAD_LAYOUT);

    if (playbarHeadLayout == null) throw 'ERROR: Failed to construct playbarHeadLayout! Check "${CHART_EDITOR_PLAYBARHEAD_LAYOUT}".';

    playbarHeadLayout.zIndex = 110;

    playbarHeadLayout.width = FlxG.width - 8;
    playbarHeadLayout.height = 10;
    playbarHeadLayout.x = 4;
    playbarHeadLayout.y = FlxG.height - 48 - 8;

    playbarHead = playbarHeadLayout.findComponent('playbarHead', Slider);
    if (playbarHead == null) throw 'ERROR: Failed to fetch playbarHead from playbarHeadLayout! Check "${CHART_EDITOR_PLAYBARHEAD_LAYOUT}".';
    playbarHead.allowFocus = false;
    playbarHead.width = FlxG.width;
    playbarHead.height = 10;
    playbarHead.styleString = 'padding-left: 0px; padding-right: 0px; border-left: 0px; border-right: 0px;';

    playbarHead.onDragStart = function(_:DragEvent) {
      playbarHeadDragging = true;

      // If we were dragging the playhead while the song was playing, resume playing.
      if (audioInstTrack != null && audioInstTrack.playing)
      {
        playbarHeadDraggingWasPlaying = true;
        stopAudioPlayback();
      }
      else
      {
        playbarHeadDraggingWasPlaying = false;
      }
    }

    playbarHead.onDragEnd = function(_:DragEvent) {
      playbarHeadDragging = false;

      // Set the song position to where the playhead was moved to.
      scrollPositionInPixels = songLengthInPixels * (playbarHead?.value ?? 0 / 100);
      // Update the conductor and audio tracks to match.
      moveSongToScrollPosition();

      // If we were dragging the playhead while the song was playing, resume playing.
      if (playbarHeadDraggingWasPlaying)
      {
        playbarHeadDraggingWasPlaying = false;
        // Disabled code to resume song playback on drag.
        // startAudioPlayback();
      }
    }

    add(playbarHeadLayout);

    // Setup notifications.
    @:privateAccess
    // NotificationManager.GUTTER_SIZE = 56;
    NotificationManager.GUTTER_SIZE = 20;
  }

  /**
   * Sets up the onClick listeners for the UI.
   */
  function setupUIListeners():Void
  {
    // Add functionality to the playbar.

    addUIClickListener('playbarPlay', _ -> toggleAudioPlayback());
    addUIClickListener('playbarStart', _ -> playbarButtonPressed = 'playbarStart');
    addUIClickListener('playbarBack', _ -> playbarButtonPressed = 'playbarBack');
    addUIClickListener('playbarForward', _ -> playbarButtonPressed = 'playbarForward');
    addUIClickListener('playbarEnd', _ -> playbarButtonPressed = 'playbarEnd');

    // Add functionality to the menu items.

    addUIClickListener('menubarItemNewChart', _ -> ChartEditorDialogHandler.openWelcomeDialog(this, true));
    addUIClickListener('menubarItemOpenChart', _ -> ChartEditorDialogHandler.openBrowseWizard(this, true));
    addUIClickListener('menubarItemSaveChartAs', _ -> ChartEditorImportExportHandler.exportAllSongData(this));
    addUIClickListener('menubarItemLoadInst', _ -> ChartEditorDialogHandler.openUploadInstDialog(this, true));
    addUIClickListener('menubarItemImportChart', _ -> ChartEditorDialogHandler.openImportChartDialog(this, 'legacy', true));
    addUIClickListener('menubarItemExit', _ -> quitChartEditor());

    addUIClickListener('menubarItemUndo', _ -> undoLastCommand());

    addUIClickListener('menubarItemRedo', _ -> redoLastCommand());

    addUIClickListener('menubarItemCopy', function(_) {
      // Doesn't use a command because it's not undoable.

      // Calculate a single time offset for all the notes and events.
      var timeOffset:Null<Int> = currentNoteSelection.length > 0 ? Std.int(currentNoteSelection[0].time) : null;
      if (currentEventSelection.length > 0)
      {
        if (timeOffset == null || currentEventSelection[0].time < timeOffset)
        {
          timeOffset = Std.int(currentEventSelection[0].time);
        }
      }

      SongDataUtils.writeItemsToClipboard(
        {
          notes: SongDataUtils.buildNoteClipboard(currentNoteSelection, timeOffset),
          events: SongDataUtils.buildEventClipboard(currentEventSelection, timeOffset),
        });
    });

    addUIClickListener('menubarItemCut', _ -> performCommand(new CutItemsCommand(currentNoteSelection, currentEventSelection)));

    addUIClickListener('menubarItemPaste', _ -> performCommand(new PasteItemsCommand(scrollPositionInMs + playheadPositionInMs)));

    addUIClickListener('menubarItemDelete', function(_) {
      if (currentNoteSelection.length > 0 && currentEventSelection.length > 0)
      {
        performCommand(new RemoveItemsCommand(currentNoteSelection, currentEventSelection));
      }
      else if (currentNoteSelection.length > 0)
      {
        performCommand(new RemoveNotesCommand(currentNoteSelection));
      }
      else if (currentEventSelection.length > 0)
      {
        performCommand(new RemoveEventsCommand(currentEventSelection));
      }
      else
      {
        // Do nothing???
      }
    });

    addUIClickListener('menubarItemSelectAll', _ -> performCommand(new SelectAllItemsCommand(currentNoteSelection, currentEventSelection)));

    addUIClickListener('menubarItemSelectInverse', _ -> performCommand(new InvertSelectedItemsCommand(currentNoteSelection, currentEventSelection)));

    addUIClickListener('menubarItemSelectNone', _ -> performCommand(new DeselectAllItemsCommand(currentNoteSelection, currentEventSelection)));

    // TODO: Implement these.
    // addUIClickListener('menubarItemSelectRegion', _ -> doSomething());
    // addUIClickListener('menubarItemSelectBeforeCursor', _ -> doSomething());
    // addUIClickListener('menubarItemSelectAfterCursor', _ -> doSomething());

    addUIClickListener('menubarItemPlaytestFull', _ -> testSongInPlayState(false));
    addUIClickListener('menubarItemPlaytestMinimal', _ -> testSongInPlayState(true));

    addUIChangeListener('menubarItemInputStyleGroup', function(event:UIEvent) {
      trace('Change input style: ${event.target}');
    });

    addUIClickListener('menubarItemAbout', _ -> ChartEditorDialogHandler.openAboutDialog(this));

    addUIClickListener('menubarItemUserGuide', _ -> ChartEditorDialogHandler.openUserGuideDialog(this));

    addUIChangeListener('menubarItemDownscroll', event -> isViewDownscroll = event.value);
    setUICheckboxSelected('menubarItemDownscroll', isViewDownscroll);

    addUIClickListener('menubarItemDifficultyUp', _ -> incrementDifficulty(1));
    addUIClickListener('menubarItemDifficultyDown', _ -> incrementDifficulty(-1));

    addUIChangeListener('menubarItemPlaytestStartTime', event -> playtestStartTime = event.value);
    setUICheckboxSelected('menubarItemPlaytestStartTime', playtestStartTime);

    addUIChangeListener('menuBarItemThemeLight', function(event:UIEvent) {
      if (event.target.value) currentTheme = ChartEditorTheme.Light;
    });
    setUICheckboxSelected('menuBarItemThemeLight', currentTheme == ChartEditorTheme.Light);

    addUIChangeListener('menuBarItemThemeDark', function(event:UIEvent) {
      if (event.target.value) currentTheme = ChartEditorTheme.Dark;
    });
    setUICheckboxSelected('menuBarItemThemeDark', currentTheme == ChartEditorTheme.Dark);

    addUIChangeListener('menubarItemMetronomeEnabled', event -> isMetronomeEnabled = event.value);
    setUICheckboxSelected('menubarItemMetronomeEnabled', isMetronomeEnabled);

    addUIChangeListener('menubarItemPlayerHitsounds', event -> hitsoundsEnabledPlayer = event.value);
    setUICheckboxSelected('menubarItemPlayerHitsounds', hitsoundsEnabledPlayer);

    addUIChangeListener('menubarItemOpponentHitsounds', event -> hitsoundsEnabledOpponent = event.value);
    setUICheckboxSelected('menubarItemOpponentHitsounds', hitsoundsEnabledOpponent);

    var instVolumeLabel:Null<Label> = findComponent('menubarLabelVolumeInstrumental', Label);
    if (instVolumeLabel != null)
    {
      addUIChangeListener('menubarItemVolumeInstrumental', function(event:UIEvent) {
        var volume:Float = event?.value ?? 0 / 100.0;
        if (audioInstTrack != null) audioInstTrack.volume = volume;
        instVolumeLabel.text = 'Instrumental - ${Std.int(event.value)}%';
      });
    }

    var vocalsVolumeLabel:Null<Label> = findComponent('menubarLabelVolumeVocals', Label);
    if (vocalsVolumeLabel != null)
    {
      addUIChangeListener('menubarItemVolumeVocals', function(event:UIEvent) {
        var volume:Float = event?.value ?? 0 / 100.0;
        if (audioVocalTrackGroup != null) audioVocalTrackGroup.volume = volume;
        vocalsVolumeLabel.text = 'Vocals - ${Std.int(event.value)}%';
      });
    }

    var playbackSpeedLabel:Null<Label> = findComponent('menubarLabelPlaybackSpeed', Label);
    if (playbackSpeedLabel != null)
    {
      addUIChangeListener('menubarItemPlaybackSpeed', function(event:UIEvent) {
        var pitch:Float = event.value * 2.0 / 100.0;
        pitch = Math.floor(pitch / 0.25) * 0.25; // Round to nearest 0.25.
        #if FLX_PITCH
        if (audioInstTrack != null) audioInstTrack.pitch = pitch;
        if (audioVocalTrackGroup != null) audioVocalTrackGroup.pitch = pitch;
        #end
        var pitchDisplay:Float = Std.int(pitch * 100) / 100; // Round to 2 decimal places.
        playbackSpeedLabel.text = 'Playback Speed - ${pitchDisplay}x';
      });
    }

    addUIChangeListener('menubarItemToggleToolboxDifficulty',
      event -> ChartEditorToolboxHandler.setToolboxState(this, CHART_EDITOR_TOOLBOX_DIFFICULTY_LAYOUT, event.value));
    addUIChangeListener('menubarItemToggleToolboxMetadata',
      event -> ChartEditorToolboxHandler.setToolboxState(this, CHART_EDITOR_TOOLBOX_METADATA_LAYOUT, event.value));
    addUIChangeListener('menubarItemToggleToolboxNotes',
      event -> ChartEditorToolboxHandler.setToolboxState(this, CHART_EDITOR_TOOLBOX_NOTEDATA_LAYOUT, event.value));
    addUIChangeListener('menubarItemToggleToolboxEvents',
      event -> ChartEditorToolboxHandler.setToolboxState(this, CHART_EDITOR_TOOLBOX_EVENTDATA_LAYOUT, event.value));
    addUIChangeListener('menubarItemToggleToolboxPlayerPreview',
      event -> ChartEditorToolboxHandler.setToolboxState(this, CHART_EDITOR_TOOLBOX_PLAYER_PREVIEW_LAYOUT, event.value));
    addUIChangeListener('menubarItemToggleToolboxOpponentPreview',
      event -> ChartEditorToolboxHandler.setToolboxState(this, CHART_EDITOR_TOOLBOX_OPPONENT_PREVIEW_LAYOUT, event.value));

    // TODO: Pass specific HaxeUI components to add context menus to them.
    registerContextMenu(null, Paths.ui('chart-editor/context/test'));
  }

  /**
   * Initialize TurboKeyHandlers and add them to the state (so `update()` is called)
   * We can then probe `keyHandler.activated` to see if the key combo's action should be taken.
   */
  function setupTurboKeyHandlers():Void
  {
    add(undoKeyHandler);
    add(redoKeyHandler);
    add(upKeyHandler);
    add(downKeyHandler);
    add(pageUpKeyHandler);
    add(pageDownKeyHandler);
  }

  /**
   * Setup timers and listerners to handle auto-save.
   */
  function setupAutoSave():Void
  {
    WindowUtil.windowExit.add(onWindowClose);
    saveDataDirty = false;
  }

  /**
   * Called after 5 minutes without saving.
   */
  function autoSave():Void
  {
    saveDataDirty = false;

    // Auto-save the chart.

    #if html5
    // Auto-save to local storage.
    #else
    // Auto-save to temp file.
    ChartEditorImportExportHandler.exportAllSongData(this, true);
    #end
  }

  function onWindowClose(exitCode:Int):Void
  {
    trace('Window exited with exit code: $exitCode');
    trace('Should save chart? $saveDataDirty');

    if (saveDataDirty)
    {
      ChartEditorImportExportHandler.exportAllSongData(this, true);
    }
  }

  function cleanupAutoSave():Void
  {
    WindowUtil.windowExit.remove(onWindowClose);
  }

  public override function update(elapsed:Float):Void
  {
    // Override F4 behavior to include the autosave.
    if (FlxG.keys.justPressed.F4)
    {
      quitChartEditor();
      return;
    }

    // dispatchEvent gets called here.
    super.update(elapsed);

    // These ones happen even if the modal dialog is open.
    handleMusicPlayback();
    handleNoteDisplay();

    // These ones only happen if the modal dialog is not open.
    handleScrollKeybinds();
    handleSnap();
    handleCursor();

    handleMenubar();
    handleToolboxes();
    handlePlaybar();
    handlePlayhead();
    handleNotePreview();
    handleHealthIcons();

    handleFileKeybinds();
    handleEditKeybinds();
    handleViewKeybinds();
    handleTestKeybinds();
    handleHelpKeybinds();
  }

  /**
   * Beat hit while the song is playing.
   */
  override function beatHit():Bool
  {
    // dispatchEvent gets called here.
    if (!super.beatHit()) return false;

    if (isMetronomeEnabled && this.subState == null && (audioInstTrack != null && audioInstTrack.playing))
    {
      playMetronomeTick(Conductor.currentBeat % 4 == 0);
    }

    return true;
  }

  /**
   * Step hit while the song is playing.
   */
  override function stepHit():Bool
  {
    // dispatchEvent gets called here.
    if (!super.stepHit()) return false;

    if (audioInstTrack != null && audioInstTrack.playing)
    {
      if (healthIconDad != null) healthIconDad.onStepHit(Conductor.currentStep);
      if (healthIconBF != null) healthIconBF.onStepHit(Conductor.currentStep);
    }

    // Updating these every step keeps it more accurate.
    // playerPreviewDirty = true;
    // opponentPreviewDirty = true;

    return true;
  }

  /**
   * Handle keybinds for scrolling the chart editor grid.
  **/
  function handleScrollKeybinds():Void
  {
    // Don't scroll when the cursor is over the UI, unless a playbar button (the << >> ones) is pressed.
    if (isCursorOverHaxeUI && playbarButtonPressed == null) return;

    var scrollAmount:Float = 0; // Amount to scroll the grid.
    var playheadAmount:Float = 0; // Amount to scroll the playhead relative to the grid.
    var shouldPause:Bool = false; // Whether to pause the song when scrolling.
    var shouldEase:Bool = false; // Whether to ease the scroll.

    // Mouse Wheel = Scroll
    if (FlxG.mouse.wheel != 0 && !FlxG.keys.pressed.CONTROL)
    {
      scrollAmount = -10 * FlxG.mouse.wheel;
      shouldPause = true;
    }

    // Up Arrow = Scroll Up
    if (upKeyHandler.activated && currentLiveInputStyle != LiveInputStyle.WASD)
    {
      scrollAmount = -GRID_SIZE * 0.25 * 5.0;
      shouldPause = true;
    }
    // Down Arrow = Scroll Down
    if (downKeyHandler.activated && currentLiveInputStyle != LiveInputStyle.WASD)
    {
      scrollAmount = GRID_SIZE * 0.25 * 5.0;
      shouldPause = true;
    }

    // PAGE UP = Jump up to nearest measure
    if (pageUpKeyHandler.activated)
    {
      var measureHeight:Float = GRID_SIZE * 4 * Conductor.beatsPerMeasure;
      var playheadPos:Float = scrollPositionInPixels + playheadPositionInPixels;
      var targetScrollPosition:Float = Math.floor(playheadPos / measureHeight) * measureHeight;
      // If we would move less than one grid, instead move to the top of the previous measure.
      var targetScrollAmount = Math.abs(targetScrollPosition - playheadPos);
      if (targetScrollAmount < GRID_SIZE)
      {
        targetScrollPosition -= GRID_SIZE * Constants.STEPS_PER_BEAT * Conductor.beatsPerMeasure;
      }
      scrollAmount = targetScrollPosition - playheadPos;

      shouldPause = true;
    }
    if (playbarButtonPressed == 'playbarBack')
    {
      playbarButtonPressed = '';
      scrollAmount = -GRID_SIZE * 4 * Conductor.beatsPerMeasure;
      shouldPause = true;
    }

    // PAGE DOWN = Jump down to nearest measure
    if (pageDownKeyHandler.activated)
    {
      var measureHeight:Float = GRID_SIZE * 4 * Conductor.beatsPerMeasure;
      var playheadPos:Float = scrollPositionInPixels + playheadPositionInPixels;
      var targetScrollPosition:Float = Math.ceil(playheadPos / measureHeight) * measureHeight;
      // If we would move less than one grid, instead move to the top of the next measure.
      var targetScrollAmount = Math.abs(targetScrollPosition - playheadPos);
      if (targetScrollAmount < GRID_SIZE)
      {
        targetScrollPosition += GRID_SIZE * Constants.STEPS_PER_BEAT * Conductor.beatsPerMeasure;
      }
      scrollAmount = targetScrollPosition - playheadPos;

      shouldPause = true;
    }
    if (playbarButtonPressed == 'playbarForward')
    {
      playbarButtonPressed = '';
      scrollAmount = GRID_SIZE * 4 * Conductor.beatsPerMeasure;
      shouldPause = true;
    }

    // Middle Mouse + Drag = Scroll but move the playhead the same amount.
    if (FlxG.mouse.pressedMiddle)
    {
      if (FlxG.mouse.deltaY != 0)
      {
        // Scroll down by the amount dragged.
        scrollAmount += -FlxG.mouse.deltaY;
        // Move the playhead by the same amount in the other direction so it is stationary.
        playheadAmount += FlxG.mouse.deltaY;
      }
    }

    // SHIFT + Scroll = Scroll Fast
    if (FlxG.keys.pressed.SHIFT)
    {
      scrollAmount *= 5;
    }
    // CONTROL + Scroll = Scroll Precise
    if (FlxG.keys.pressed.CONTROL)
    {
      scrollAmount /= 10;
    }

    // ALT = Move playhead instead.
    if (FlxG.keys.pressed.ALT)
    {
      playheadAmount = scrollAmount;
      scrollAmount = 0;
      shouldPause = false;
    }

    // HOME = Scroll to Top
    if (FlxG.keys.justPressed.HOME)
    {
      // Scroll amount is the difference between the current position and the top.
      scrollAmount = 0 - this.scrollPositionInPixels;
      playheadAmount = 0 - this.playheadPositionInPixels;
      shouldPause = true;
    }
    if (playbarButtonPressed == 'playbarStart')
    {
      playbarButtonPressed = '';
      scrollAmount = 0 - this.scrollPositionInPixels;
      playheadAmount = 0 - this.playheadPositionInPixels;
      shouldPause = true;
    }

    // END = Scroll to Bottom
    if (FlxG.keys.justPressed.END)
    {
      // Scroll amount is the difference between the current position and the bottom.
      scrollAmount = this.songLengthInPixels - this.scrollPositionInPixels;
      shouldPause = true;
    }
    if (playbarButtonPressed == 'playbarEnd')
    {
      playbarButtonPressed = '';
      scrollAmount = this.songLengthInPixels - this.scrollPositionInPixels;
      shouldPause = true;
    }

    if (Math.abs(scrollAmount) > GRID_SIZE * 8)
    {
      shouldEase = true;
    }

    // Resync the conductor and audio tracks.
    if (scrollAmount != 0 || playheadAmount != 0)
    {
      this.playheadPositionInPixels += playheadAmount;
      if (shouldEase)
      {
        easeSongToScrollPosition(this.scrollPositionInPixels + scrollAmount);
      }
      else
      {
        // Apply the scroll amount.
        this.scrollPositionInPixels += scrollAmount;
        moveSongToScrollPosition();
      }
    }
    if (shouldPause) stopAudioPlayback();
  }

  function handleSnap():Void
  {
    if (FlxG.keys.justPressed.LEFT && !FlxG.keys.pressed.CONTROL)
    {
      noteSnapQuantIndex--;
    }

    if (FlxG.keys.justPressed.RIGHT && !FlxG.keys.pressed.CONTROL)
    {
      noteSnapQuantIndex++;
    }
  }

  /**
   * Handle display of the mouse cursor.
   */
  function handleCursor():Void
  {
    // Note: If a menu is open in HaxeUI, don't handle cursor behavior.
    var shouldHandleCursor:Bool = !isCursorOverHaxeUI || (selectionBoxStartPos != null);
    var eventColumn:Int = (STRUMLINE_SIZE * 2 + 1) - 1;

    if (shouldHandleCursor)
    {
      // Over the course of this big conditional block,
      // we determine what the cursor should look like,
      // and fall back to the default cursor if none of the conditions are met.
      var targetCursorMode:Null<CursorMode> = null;

      if (gridTiledSprite == null) throw "ERROR: Tried to handle cursor, but gridTiledSprite is null! Check ChartEditorState.buildGrid()";

      var overlapsGrid:Bool = FlxG.mouse.overlaps(gridTiledSprite);

      // Cursor position relative to the grid.
      var cursorX:Float = FlxG.mouse.screenX - gridTiledSprite.x;
      var cursorY:Float = FlxG.mouse.screenY - gridTiledSprite.y;

      var overlapsSelectionBorder:Bool = overlapsGrid
        && ((cursorX % 40) < (GRID_SELECTION_BORDER_WIDTH / 2)
          || (cursorX % 40) > (40 - (GRID_SELECTION_BORDER_WIDTH / 2))
            || (cursorY % 40) < (GRID_SELECTION_BORDER_WIDTH / 2) || (cursorY % 40) > (40 - (GRID_SELECTION_BORDER_WIDTH / 2)));

      if (FlxG.mouse.justPressed)
      {
        if (gridPlayheadScrollArea != null && FlxG.mouse.overlaps(gridPlayheadScrollArea))
        {
          gridPlayheadScrollAreaPressed = true;
        }
        else if (notePreview != null && FlxG.mouse.overlaps(notePreview))
        {
          // Clicked note preview
          notePreviewScrollAreaStartPos = new FlxPoint(FlxG.mouse.screenX, FlxG.mouse.screenY);
        }
        else if (!overlapsGrid || overlapsSelectionBorder)
        {
          selectionBoxStartPos = new FlxPoint(FlxG.mouse.screenX, FlxG.mouse.screenY);
          // Drawing selection box.
          targetCursorMode = Crosshair;
        }
        else
        {
          // Deselect all items.
          if (currentNoteSelection.length > 0 || currentEventSelection.length > 0)
          {
            trace('Clicked outside grid, deselecting all items.');
            performCommand(new DeselectAllItemsCommand(currentNoteSelection, currentEventSelection));
          }
        }
      }

      if (gridPlayheadScrollAreaPressed && FlxG.mouse.released)
      {
        gridPlayheadScrollAreaPressed = false;
      }

      if (notePreviewScrollAreaStartPos != null && FlxG.mouse.released)
      {
        notePreviewScrollAreaStartPos = null;
      }

      if (gridPlayheadScrollAreaPressed)
      {
        // Clicked on the playhead scroll area.
        // Move the playhead to the cursor position.
        this.playheadPositionInPixels = FlxG.mouse.screenY - MENU_BAR_HEIGHT - GRID_TOP_PAD;
        moveSongToScrollPosition();

        // Cursor should be a grabby hand.
        if (targetCursorMode == null) targetCursorMode = Grabbing;
      }

      // The song position of the cursor, in steps.
      var cursorFractionalStep:Float = cursorY / GRID_SIZE;
      var cursorMs:Float = Conductor.getStepTimeInMs(cursorFractionalStep);
      // Round the cursor step to the nearest snap quant.
      var cursorSnappedStep:Float = Math.floor(cursorFractionalStep / noteSnapRatio) * noteSnapRatio;
      var cursorSnappedMs:Float = Conductor.getStepTimeInMs(cursorSnappedStep);

      // The direction value for the column at the cursor.
      var cursorColumn:Int = Math.floor(cursorX / GRID_SIZE);
      if (cursorColumn < 0) cursorColumn = 0;
      if (cursorColumn >= (STRUMLINE_SIZE * 2 + 1 - 1))
      {
        // Don't invert the event column.
        cursorColumn = (STRUMLINE_SIZE * 2 + 1 - 1);
      }
      else
      {
        // Invert player and opponent columns.
        if (cursorColumn >= STRUMLINE_SIZE)
        {
          cursorColumn -= STRUMLINE_SIZE;
        }
        else
        {
          cursorColumn += STRUMLINE_SIZE;
        }
      }

      if (selectionBoxStartPos != null)
      {
        var cursorXStart:Float = selectionBoxStartPos.x - gridTiledSprite.x;
        var cursorYStart:Float = selectionBoxStartPos.y - gridTiledSprite.y;

        var hasDraggedMouse:Bool = Math.abs(cursorX - cursorXStart) > DRAG_THRESHOLD || Math.abs(cursorY - cursorYStart) > DRAG_THRESHOLD;

        // Determine if we dragged the mouse at all.
        if (hasDraggedMouse)
        {
          // Handle releasing the selection box.
          if (FlxG.mouse.justReleased)
          {
            // We released the mouse. Select the notes in the box.
            var cursorFractionalStepStart:Float = cursorYStart / GRID_SIZE;
            var cursorStepStart:Int = Math.floor(cursorFractionalStepStart);
            var cursorMsStart:Float = Conductor.getStepTimeInMs(cursorStepStart);
            var cursorColumnBase:Int = Math.floor(cursorX / GRID_SIZE);
            var cursorColumnBaseStart:Int = Math.floor(cursorXStart / GRID_SIZE);

            // Since this selects based on noteData directly,
            // we don't need to specifically exclude sustain pieces.

            // This logic is gross because the columns go 4567-0123-8.
            // We build a list of columns to select.
            var columnStart:Int = Std.int(Math.min(cursorColumnBase, cursorColumnBaseStart));
            var columnEnd:Int = Std.int(Math.max(cursorColumnBase, cursorColumnBaseStart));
            var columns:Array<Int> = [for (i in columnStart...(columnEnd + 1)) i].map(function(i:Int):Int {
              if (i >= eventColumn)
              {
                // Don't invert the event column.
                return eventColumn;
              }
              else if (i >= STRUMLINE_SIZE)
              {
                // Invert the player columns.
                return i - STRUMLINE_SIZE;
              }
              else if (i >= 0)
              {
                // Invert the opponent columns.
                return i + STRUMLINE_SIZE;
              }
              else
              {
                // Minimum of 0.
                return 0;
              }
            });

            if (columns.length > 0)
            {
              var notesToSelect:Array<SongNoteData> = currentSongChartNoteData;
              notesToSelect = SongDataUtils.getNotesInTimeRange(notesToSelect, Math.min(cursorMsStart, cursorMs), Math.max(cursorMsStart, cursorMs));
              notesToSelect = SongDataUtils.getNotesWithData(notesToSelect, columns);

              var eventsToSelect:Array<SongEventData> = [];

              if (columns.indexOf(eventColumn) != -1)
              {
                // The drag selection included the event column.
                eventsToSelect = currentSongChartEventData;
                eventsToSelect = SongDataUtils.getEventsInTimeRange(eventsToSelect, Math.min(cursorMsStart, cursorMs), Math.max(cursorMsStart, cursorMs));
              }

              if (notesToSelect.length > 0 || eventsToSelect.length > 0)
              {
                if (FlxG.keys.pressed.CONTROL)
                {
                  // Add to the selection.
                  performCommand(new SelectItemsCommand(notesToSelect, eventsToSelect));
                }
                else
                {
                  // Set the selection.
                  performCommand(new SetItemSelectionCommand(notesToSelect, eventsToSelect, currentNoteSelection, currentEventSelection));
                }
              }
              else
              {
                // We made a selection box, but it didn't select anything.

                if (!FlxG.keys.pressed.CONTROL)
                {
                  // Deselect all items.
                  if (currentNoteSelection.length > 0 || currentEventSelection.length > 0)
                  {
                    trace('Clicked and dragged outside grid, deselecting all items.');
                    performCommand(new DeselectAllItemsCommand(currentNoteSelection, currentEventSelection));
                  }
                }
              }
            }
            else
            {
              // We made a selection box, but it didn't select any columns.
            }

            // Clear the selection box.
            selectionBoxStartPos = null;
            setSelectionBoxBounds();
          }
          else
          {
            // Clicking and dragging.

            // Scroll the screen if the mouse is above or below the grid.
            if (FlxG.mouse.screenY < MENU_BAR_HEIGHT)
            {
              // Scroll up.
              var diff:Float = MENU_BAR_HEIGHT - FlxG.mouse.screenY;
              scrollPositionInPixels -= diff * 0.5; // Too fast!
              trace('Scroll up: ' + diff);
              moveSongToScrollPosition();
            }
            else if (FlxG.mouse.screenY > (playbarHeadLayout?.y ?? 0.0))
            {
              // Scroll down.
              var diff:Float = FlxG.mouse.screenY - (playbarHeadLayout?.y ?? 0.0);
              scrollPositionInPixels += diff * 0.5; // Too fast!
              trace('Scroll down: ' + diff);
              moveSongToScrollPosition();
            }

            // Render the selection box.
            var selectionRect:FlxRect = new FlxRect();
            selectionRect.x = Math.min(FlxG.mouse.screenX, selectionBoxStartPos.x);
            selectionRect.y = Math.min(FlxG.mouse.screenY, selectionBoxStartPos.y);
            selectionRect.width = Math.abs(FlxG.mouse.screenX - selectionBoxStartPos.x);
            selectionRect.height = Math.abs(FlxG.mouse.screenY - selectionBoxStartPos.y);
            setSelectionBoxBounds(selectionRect);

            targetCursorMode = Crosshair;
          }
        }
        else if (FlxG.mouse.justReleased)
        {
          // Clear the selection box.
          selectionBoxStartPos = null;
          setSelectionBoxBounds();

          if (overlapsGrid)
          {
            // We clicked on the grid without moving the mouse.

            // Find the first note that is at the cursor position.
            var highlightedNote:Null<ChartEditorNoteSprite> = renderedNotes.members.find(function(note:ChartEditorNoteSprite):Bool {
              // If note.alive is false, the note is dead and awaiting recycling.
              return note.alive && FlxG.mouse.overlaps(note);
            });
            var highlightedEvent:Null<ChartEditorEventSprite> = null;
            if (highlightedNote == null)
            {
              highlightedEvent = renderedEvents.members.find(function(event:ChartEditorEventSprite):Bool {
                return event.alive && FlxG.mouse.overlaps(event);
              });
            }

            if (FlxG.keys.pressed.CONTROL)
            {
              if (highlightedNote != null && highlightedNote.noteData != null)
              {
                // TODO: Handle the case of clicking on a sustain piece.
                // Control click to select/deselect an individual note.
                if (isNoteSelected(highlightedNote.noteData))
                {
                  performCommand(new DeselectItemsCommand([highlightedNote.noteData], []));
                }
                else
                {
                  performCommand(new SelectItemsCommand([highlightedNote.noteData], []));
                }
              }
              else if (highlightedEvent != null && highlightedEvent.eventData != null)
              {
                // Control click to select/deselect an individual note.
                if (isEventSelected(highlightedEvent.eventData))
                {
                  performCommand(new DeselectItemsCommand([], [highlightedEvent.eventData]));
                }
                else
                {
                  performCommand(new SelectItemsCommand([], [highlightedEvent.eventData]));
                }
              }
              else
              {
                // Do nothing if you control-clicked on an empty space.
              }
            }
            else
            {
              if (highlightedNote != null && highlightedNote.noteData != null)
              {
                // Click a note to select it.
                performCommand(new SetItemSelectionCommand([highlightedNote.noteData], [], currentNoteSelection, currentEventSelection));
              }
              else if (highlightedEvent != null && highlightedEvent.eventData != null)
              {
                // Click an event to select it.
                performCommand(new SetItemSelectionCommand([], [highlightedEvent.eventData], currentNoteSelection, currentEventSelection));
              }
              else
              {
                // Click on an empty space to deselect everything.
                performCommand(new DeselectAllItemsCommand(currentNoteSelection, currentEventSelection));
              }
            }
          }
          else
          {
            // If we clicked and released outside the grid.

            if (!FlxG.keys.pressed.CONTROL)
            {
              // Deselect all items.
              if (currentNoteSelection.length > 0 || currentEventSelection.length > 0)
              {
                trace('Clicked outside grid, deselecting all items.');
                performCommand(new DeselectAllItemsCommand(currentNoteSelection, currentEventSelection));
              }
            }
          }
        }
      }
      else if (notePreviewScrollAreaStartPos != null)
      {
        // Player is clicking and holding on note preview to scrub around.
        targetCursorMode = Grabbing;

        var clickedPosInPixels:Float = FlxMath.remapToRange(FlxG.mouse.screenY, (notePreview?.y ?? 0.0),
          (notePreview?.y ?? 0.0) + (notePreview?.height ?? 0.0), 0, songLengthInPixels);

        scrollPositionInPixels = clickedPosInPixels;
        moveSongToScrollPosition();
      }
      else if (currentPlaceNoteData != null)
      {
        // Handle extending the note as you drag.

        var stepTime:Float = inline currentPlaceNoteData.getStepTime();
        var dragLengthSteps:Float = Conductor.getTimeInSteps(cursorSnappedMs) - stepTime;
        var dragLengthMs:Float = dragLengthSteps * Conductor.stepLengthMs;
        var dragLengthPixels:Float = dragLengthSteps * GRID_SIZE;

        if (dragLengthSteps > 0)
        {
          gridGhostHoldNote.visible = true;
          gridGhostHoldNote.noteData = gridGhostNote.noteData;
          gridGhostHoldNote.noteDirection = gridGhostNote.noteData.getDirection();

          gridGhostHoldNote.setHeightDirectly(dragLengthPixels);

          gridGhostHoldNote.updateHoldNotePosition(renderedHoldNotes);
        }
        else
        {
          gridGhostHoldNote.visible = false;
        }

        if (FlxG.mouse.justReleased)
        {
          if (dragLengthSteps > 0)
          {
            // Apply the new length.
            performCommand(new ExtendNoteLengthCommand(currentPlaceNoteData, dragLengthMs));
          }

          // Finished dragging. Release the note.
          currentPlaceNoteData = null;
        }
      }
      else
      {
        if (FlxG.mouse.justPressed)
        {
          // Just clicked to place a note.
          if (overlapsGrid && !overlapsSelectionBorder)
          {
            // We clicked on the grid without moving the mouse.

            // Find the first note that is at the cursor position.
            var highlightedNote:Null<ChartEditorNoteSprite> = renderedNotes.members.find(function(note:ChartEditorNoteSprite):Bool {
              // If note.alive is false, the note is dead and awaiting recycling.
              return note.alive && FlxG.mouse.overlaps(note);
            });
            var highlightedEvent:Null<ChartEditorEventSprite> = null;
            if (highlightedNote == null)
            {
              highlightedEvent = renderedEvents.members.find(function(event:ChartEditorEventSprite):Bool {
                // If event.alive is false, the event is dead and awaiting recycling.
                return event.alive && FlxG.mouse.overlaps(event);
              });
            }

            if (FlxG.keys.pressed.CONTROL)
            {
              // Control click to select/deselect an individual note.
              if (highlightedNote != null && highlightedNote.noteData != null)
              {
                if (isNoteSelected(highlightedNote.noteData))
                {
                  performCommand(new DeselectItemsCommand([highlightedNote.noteData], []));
                }
                else
                {
                  performCommand(new SelectItemsCommand([highlightedNote.noteData], []));
                }
              }
              else if (highlightedEvent != null && highlightedEvent.eventData != null)
              {
                if (isEventSelected(highlightedEvent.eventData))
                {
                  performCommand(new DeselectItemsCommand([], [highlightedEvent.eventData]));
                }
                else
                {
                  performCommand(new SelectItemsCommand([], [highlightedEvent.eventData]));
                }
              }
              else
              {
                // Do nothing when control clicking nothing.
              }
            }
            else
            {
              if (highlightedNote != null && highlightedNote.noteData != null)
              {
                // Click a note to select it.
                performCommand(new SetItemSelectionCommand([highlightedNote.noteData], [], currentNoteSelection, currentEventSelection));
              }
              else if (highlightedEvent != null && highlightedEvent.eventData != null)
              {
                // Click an event to select it.
                performCommand(new SetItemSelectionCommand([], [highlightedEvent.eventData], currentNoteSelection, currentEventSelection));
              }
              else
              {
                // Click a blank space to place a note and select it.

                if (cursorColumn == eventColumn)
                {
                  // Create an event and place it in the chart.
                  // TODO: Figure out configuring event data.
                  var newEventData:SongEventData = new SongEventData(cursorSnappedMs, selectedEventKind, selectedEventData);

                  performCommand(new AddEventsCommand([newEventData], FlxG.keys.pressed.CONTROL));
                }
                else
                {
                  // Create a note and place it in the chart.
                  var newNoteData:SongNoteData = new SongNoteData(cursorSnappedMs, cursorColumn, 0, selectedNoteKind);

                  performCommand(new AddNotesCommand([newNoteData], FlxG.keys.pressed.CONTROL));

                  currentPlaceNoteData = newNoteData;
                }
              }
            }
          }
          else
          {
            // If we clicked and released outside the grid, do nothing.
          }
        }

        var rightMouseUpdated:Bool = (FlxG.mouse.justPressedRight)
          || (FlxG.mouse.pressedRight && (FlxG.mouse.deltaX > 0 || FlxG.mouse.deltaY > 0));
        if (rightMouseUpdated && overlapsGrid)
        {
          // We right clicked on the grid.

          // Find the first note that is at the cursor position.
          var highlightedNote:Null<ChartEditorNoteSprite> = renderedNotes.members.find(function(note:ChartEditorNoteSprite):Bool {
            // If note.alive is false, the note is dead and awaiting recycling.
            return note.alive && FlxG.mouse.overlaps(note);
          });
          var highlightedEvent:Null<ChartEditorEventSprite> = null;
          if (highlightedNote == null)
          {
            highlightedEvent = renderedEvents.members.find(function(event:ChartEditorEventSprite):Bool {
              // If event.alive is false, the event is dead and awaiting recycling.
              return event.alive && FlxG.mouse.overlaps(event);
            });
          }

          if (highlightedNote != null && highlightedNote.noteData != null)
          {
            // TODO: Handle the case of clicking on a sustain piece.
            // Remove the note.
            performCommand(new RemoveNotesCommand([highlightedNote.noteData]));
          }
          else if (highlightedEvent != null && highlightedEvent.eventData != null)
          {
            // Remove the event.
            performCommand(new RemoveEventsCommand([highlightedEvent.eventData]));
          }
          else
          {
            // Right clicked on nothing.
          }
        }

        // Handle grid cursor.
        if (overlapsGrid && !overlapsSelectionBorder && !gridPlayheadScrollAreaPressed)
        {
          // Indicate that we can place a note here.

          if (cursorColumn == eventColumn)
          {
            if (gridGhostNote != null) gridGhostNote.visible = false;
            gridGhostHoldNote.visible = false;

            if (gridGhostEvent == null) throw "ERROR: Tried to handle cursor, but gridGhostEvent is null! Check ChartEditorState.buildGrid()";

            var eventData:SongEventData = gridGhostEvent.eventData != null ? gridGhostEvent.eventData : new SongEventData(cursorMs, selectedEventKind, null);

            if (selectedEventKind != eventData.event)
            {
              eventData.event = selectedEventKind;
            }
            eventData.time = cursorSnappedMs;

            gridGhostEvent.visible = true;
            gridGhostEvent.eventData = eventData;
            gridGhostEvent.updateEventPosition(renderedEvents);

            targetCursorMode = Cell;
          }
          else
          {
            if (gridGhostEvent != null) gridGhostEvent.visible = false;

            if (gridGhostNote == null) throw "ERROR: Tried to handle cursor, but gridGhostNote is null! Check ChartEditorState.buildGrid()";

            var noteData:SongNoteData = gridGhostNote.noteData != null ? gridGhostNote.noteData : new SongNoteData(cursorMs, cursorColumn, 0, selectedNoteKind);

            if (cursorColumn != noteData.data || selectedNoteKind != noteData.kind)
            {
              noteData.kind = selectedNoteKind;
              noteData.data = cursorColumn;
              gridGhostNote.playNoteAnimation();
            }
            noteData.time = cursorSnappedMs;

            gridGhostNote.visible = true;
            gridGhostNote.noteData = noteData;
            gridGhostNote.updateNotePosition(renderedNotes);

            targetCursorMode = Cell;
          }
        }
        else
        {
          if (gridGhostNote != null) gridGhostNote.visible = false;
          if (gridGhostHoldNote != null) gridGhostHoldNote.visible = false;
          if (gridGhostEvent != null) gridGhostEvent.visible = false;
        }
      }

      if (targetCursorMode == null)
      {
        if (FlxG.mouse.pressed)
        {
          if (overlapsSelectionBorder)
          {
            targetCursorMode = Crosshair;
          }
        }
        else
        {
          if (FlxG.mouse.overlaps(notePreview))
          {
            targetCursorMode = Pointer;
          }
          else if (FlxG.mouse.overlaps(gridPlayheadScrollArea))
          {
            targetCursorMode = Pointer;
          }
          else if (overlapsSelectionBorder)
          {
            targetCursorMode = Crosshair;
          }
          else if (overlapsGrid)
          {
            targetCursorMode = Cell;
          }
        }
      }

      // Actually set the cursor mode to the one we specified earlier.
      Cursor.cursorMode = targetCursorMode ?? Default;
    }
    else
    {
      if (gridGhostNote != null) gridGhostNote.visible = false;
      if (gridGhostHoldNote != null) gridGhostHoldNote.visible = false;
      if (gridGhostEvent != null) gridGhostEvent.visible = false;

      // Do not set Cursor.cursorMode here, because it will be set by the HaxeUI.
    }
  }

  /**
   * Handle using `renderedNotes` to display notes from `currentSongChartNoteData`.
   */
  function handleNoteDisplay():Void
  {
    if (noteDisplayDirty)
    {
      noteDisplayDirty = false;

      // Update for whether downscroll is enabled.
      renderedNotes.flipX = (isViewDownscroll);

      // Calculate the top and bottom of the view area.
      var viewAreaTopPixels:Float = MENU_BAR_HEIGHT;
      var visibleGridHeightPixels:Float = FlxG.height - MENU_BAR_HEIGHT - PLAYBAR_HEIGHT; // The area underneath the menu bar and playbar is not visible.
      var viewAreaBottomPixels:Float = viewAreaTopPixels + visibleGridHeightPixels;

      // Remove notes that are no longer visible and list the ones that are.
      var displayedNoteData:Array<SongNoteData> = [];
      for (noteSprite in renderedNotes.members)
      {
        if (noteSprite == null || noteSprite.noteData == null || !noteSprite.exists || !noteSprite.visible) continue;

        if (!noteSprite.isNoteVisible(viewAreaBottomPixels, viewAreaTopPixels))
        {
          // This sprite is off-screen.
          // Kill the note sprite and recycle it.
          noteSprite.noteData = null;
        }
        else if (!currentSongChartNoteData.fastContains(noteSprite.noteData))
        {
          // This note was deleted.
          // Kill the note sprite and recycle it.
          noteSprite.noteData = null;
        }
        else
        {
          // Note is already displayed and should remain displayed.
          displayedNoteData.push(noteSprite.noteData);

          // Update the note sprite's position.
          noteSprite.updateNotePosition(renderedNotes);
        }
      }
      // Sort the note data array, using an algorithm that is fast on nearly-sorted data.
      // We need this sorted to optimize indexing later.
      displayedNoteData.insertionSort(SortUtil.noteDataByTime.bind(FlxSort.ASCENDING));

      var displayedHoldNoteData:Array<SongNoteData> = [];
      for (holdNoteSprite in renderedHoldNotes.members)
      {
        if (holdNoteSprite == null || holdNoteSprite.noteData == null || !holdNoteSprite.exists || !holdNoteSprite.visible) continue;

        if (!holdNoteSprite.isHoldNoteVisible(FlxG.height - MENU_BAR_HEIGHT, GRID_TOP_PAD))
        {
          holdNoteSprite.kill();
        }
        else if (!currentSongChartNoteData.fastContains(holdNoteSprite.noteData) || holdNoteSprite.noteData.length == 0)
        {
          // This hold note was deleted.
          // Kill the hold note sprite and recycle it.
          holdNoteSprite.kill();
        }
        else if (displayedHoldNoteData.fastContains(holdNoteSprite.noteData))
        {
          // This hold note is a duplicate.
          // Kill the hold note sprite and recycle it.
          holdNoteSprite.kill();
        }
        else
        {
          displayedHoldNoteData.push(holdNoteSprite.noteData);
          // Update the event sprite's position.
          holdNoteSprite.updateHoldNotePosition(renderedNotes);
        }
      }
      // Sort the note data array, using an algorithm that is fast on nearly-sorted data.
      // We need this sorted to optimize indexing later.
      displayedHoldNoteData.insertionSort(SortUtil.noteDataByTime.bind(FlxSort.ASCENDING));

      // Remove events that are no longer visible and list the ones that are.
      var displayedEventData:Array<SongEventData> = [];
      for (eventSprite in renderedEvents.members)
      {
        if (eventSprite == null || eventSprite.eventData == null || !eventSprite.exists || !eventSprite.visible) continue;

        if (!eventSprite.isEventVisible(FlxG.height - MENU_BAR_HEIGHT, GRID_TOP_PAD))
        {
          // This sprite is off-screen.
          // Kill the event sprite and recycle it.
          eventSprite.eventData = null;
        }
        else if (!currentSongChartEventData.fastContains(eventSprite.eventData))
        {
          // This event was deleted.
          // Kill the event sprite and recycle it.
          eventSprite.eventData = null;
        }
        else
        {
          // Event is already displayed and should remain displayed.
          displayedEventData.push(eventSprite.eventData);

          // Update the event sprite's position.
          eventSprite.updateEventPosition(renderedEvents);
        }
      }
      // Sort the note data array, using an algorithm that is fast on nearly-sorted data.
      // We need this sorted to optimize indexing later.
      displayedEventData.insertionSort(SortUtil.eventDataByTime.bind(FlxSort.ASCENDING));

      // Let's try testing only notes within a certain range of the view area.
      // TODO: I don't think this messes up really long sustains, does it?
      var viewAreaTopMs:Float = scrollPositionInMs - (Conductor.measureLengthMs * 2); // Is 2 measures enough?
      var viewAreaBottomMs:Float = scrollPositionInMs + (Conductor.measureLengthMs * 2); // Is 2 measures enough?

      // Add notes that are now visible.
      for (noteData in currentSongChartNoteData)
      {
        // Remember if we are already displaying this note.
        if (noteData == null) continue;
        // Check if we are outside a broad range around the view area.
        if (noteData.time < viewAreaTopMs || noteData.time > viewAreaBottomMs) continue;

        if (displayedNoteData.fastContains(noteData))
        {
          continue;
        }

        if (!ChartEditorNoteSprite.wouldNoteBeVisible(viewAreaBottomPixels, viewAreaTopPixels, noteData,
          renderedNotes)) continue; // Else, this note is visible and we need to render it!

        // Get a note sprite from the pool.
        // If we can reuse a deleted note, do so.
        // If a new note is needed, call buildNoteSprite.
        var noteSprite:ChartEditorNoteSprite = renderedNotes.recycle(() -> new ChartEditorNoteSprite(this));
        // trace('Creating new Note... (${renderedNotes.members.length})');
        noteSprite.parentState = this;

        // The note sprite handles animation playback and positioning.
        noteSprite.noteData = noteData;

        // Setting note data resets the position relative to the group!
        // If we don't update the note position AFTER setting the note data, the note will be rendered offscreen at y=5000.
        noteSprite.updateNotePosition(renderedNotes);

        // Add hold notes that are now visible (and not already displayed).
        if (noteSprite.noteData != null && noteSprite.noteData.length > 0 && displayedHoldNoteData.indexOf(noteSprite.noteData) == -1)
        {
          var holdNoteSprite:ChartEditorHoldNoteSprite = renderedHoldNotes.recycle(() -> new ChartEditorHoldNoteSprite(this));
          // trace('Creating new HoldNote... (${renderedHoldNotes.members.length})');

          var noteLengthPixels:Float = noteSprite.noteData.getStepLength() * GRID_SIZE;

          holdNoteSprite.noteData = noteSprite.noteData;
          holdNoteSprite.noteDirection = noteSprite.noteData.getDirection();

          holdNoteSprite.setHeightDirectly(noteLengthPixels);

          holdNoteSprite.updateHoldNotePosition(renderedHoldNotes);
        }
      }

      // Add events that are now visible.
      for (eventData in currentSongChartEventData)
      {
        // Remember if we are already displaying this event.
        if (displayedEventData.indexOf(eventData) != -1)
        {
          continue;
        }

        if (!ChartEditorEventSprite.wouldEventBeVisible(viewAreaBottomPixels, viewAreaTopPixels, eventData, renderedNotes)) continue;

        // Else, this event is visible and we need to render it!

        // Get an event sprite from the pool.
        // If we can reuse a deleted event, do so.
        // If a new event is needed, call buildEventSprite.
        var eventSprite:ChartEditorEventSprite = renderedEvents.recycle(() -> new ChartEditorEventSprite(this), false, true);
        eventSprite.parentState = this;
        trace('Creating new Event... (${renderedEvents.members.length})');

        // The event sprite handles animation playback and positioning.
        eventSprite.eventData = eventData;

        // Setting event data resets position relative to the grid so we fix that.
        eventSprite.x += renderedEvents.x;
        eventSprite.y += renderedEvents.y;
      }

      // Add hold notes that have been made visible (but not their parents)
      for (noteData in currentSongChartNoteData)
      {
        // Is the note a hold note?
        if (noteData == null || noteData.length <= 0) continue;

        // Is the hold note rendered already?
        if (displayedHoldNoteData.indexOf(noteData) != -1) continue;

        // Is the hold note offscreen?
        if (!ChartEditorHoldNoteSprite.wouldHoldNoteBeVisible(viewAreaBottomPixels, viewAreaTopPixels, noteData, renderedHoldNotes)) continue;

        // Hold note should be rendered.
        var holdNoteFactory = function() {
          // TODO: Print some kind of warning if `renderedHoldNotes.members` is too high?
          return new ChartEditorHoldNoteSprite(this);
        }
        var holdNoteSprite:ChartEditorHoldNoteSprite = renderedHoldNotes.recycle(holdNoteFactory);

        var noteLengthPixels:Float = noteData.getStepLength() * GRID_SIZE;

        holdNoteSprite.noteData = noteData;
        holdNoteSprite.noteDirection = noteData.getDirection();

        holdNoteSprite.setHeightDirectly(noteLengthPixels);

        holdNoteSprite.updateHoldNotePosition(renderedHoldNotes);

        displayedHoldNoteData.push(noteData);
      }

      // Destroy all existing selection squares.
      for (member in renderedSelectionSquares.members)
      {
        // Killing the sprite is cheap because we can recycle it.
        member.kill();
      }

      // Readd selection squares for selected notes.
      // Recycle selection squares if possible.
      for (noteSprite in renderedNotes.members)
      {
        // TODO: Handle selection of hold notes.
        if (isNoteSelected(noteSprite.noteData))
        {
          var selectionSquare:FlxSprite = renderedSelectionSquares.recycle(buildSelectionSquare);

          // Set the position and size (because we might be recycling one with bad values).
          selectionSquare.x = noteSprite.x;
          selectionSquare.y = noteSprite.y;
          selectionSquare.width = noteSprite.width;
          selectionSquare.height = noteSprite.height;
        }
      }

      for (eventSprite in renderedEvents.members)
      {
        if (isEventSelected(eventSprite.eventData))
        {
          var selectionSquare:FlxSprite = renderedSelectionSquares.recycle(buildSelectionSquare);

          // Set the position and size (because we might be recycling one with bad values).
          selectionSquare.x = eventSprite.x;
          selectionSquare.y = eventSprite.y;
          selectionSquare.width = eventSprite.width;
          selectionSquare.height = eventSprite.height;
        }
      }

      // Sort the notes DESCENDING. This keeps the sustain behind the associated note.
      renderedNotes.sort(FlxSort.byY, FlxSort.DESCENDING); // TODO: .group.insertionSort()

      // Sort the events DESCENDING. This keeps the sustain behind the associated note.
      renderedEvents.sort(FlxSort.byY, FlxSort.DESCENDING); // TODO: .group.insertionSort()
    }

    // Add a debug value which displays the current size of the note pool.
    // The pool will grow as more notes need to be rendered at once.
    // If this gets too big, something needs to be optimized somewhere! -Eric
    FlxG.watch.addQuick("tapNotesRendered", renderedNotes.members.length);
    FlxG.watch.addQuick("holdNotesRendered", renderedHoldNotes.members.length);
    FlxG.watch.addQuick("eventsRendered", renderedEvents.members.length);
  }

  /**
   * Handle aligning the health icons next to the grid.
   */
  function handleHealthIcons():Void
  {
    // Right align the BF health icon.
    if (healthIconBF != null)
    {
      // Base X position to the right of the grid.
      var baseHealthIconXPos:Float = (gridTiledSprite == null) ? (0) : (gridTiledSprite.x + gridTiledSprite.width + 15);
      // Will be 0 when not bopping. When bopping, will increase to push the icon left.
      var healthIconOffset:Float = healthIconBF.width - (HealthIcon.HEALTH_ICON_SIZE * 0.5);
      healthIconBF.x = baseHealthIconXPos - healthIconOffset;
    }
  }

  function buildSelectionSquare():FlxSprite
  {
    if (selectionSquareBitmap == null)
      throw "ERROR: Tried to build selection square, but selectionSquareBitmap is null! Check ChartEditorThemeHandler.updateSelectionSquare()";

    return new FlxSprite().loadGraphic(selectionSquareBitmap);
  }

  /**
   * Handles display elements for the playbar at the bottom.
   */
  function handlePlaybar():Void
  {
    if (playbarHeadLayout == null) throw "ERROR: Tried to handle playbar, but playbarHeadLayout is null!";
    if (playbarHead == null) throw "ERROR: Tried to handle playbar, but playbarHeadLayout is null!";

    // Make sure the playbar is never nudged out of the correct spot.
    playbarHeadLayout.x = 4;
    playbarHeadLayout.y = FlxG.height - 48 - 8;

    var songPos:Float = Conductor.songPosition;
    var songRemaining:Float = Math.max(songLengthInMs - songPos, 0.0);

    // Move the playhead to match the song position, if we aren't dragging it.
    if (!playbarHeadDragging)
    {
      var songPosPercent:Float = songPos / songLengthInMs * 100;
      if (playbarHead.value != songPosPercent) playbarHead.value = songPosPercent;
    }

    var songPosSeconds:String = Std.string(Math.floor((songPos / 1000) % 60)).lpad('0', 2);
    var songPosMinutes:String = Std.string(Math.floor((songPos / 1000) / 60)).lpad('0', 2);
    var songPosString:String = '${songPosMinutes}:${songPosSeconds}';

    if (playbarSongPos == null) playbarSongPos = findComponent('playbarSongPos', Label);
    if (playbarSongPos != null && playbarSongPos.value != songPosString) playbarSongPos.value = songPosString;

    var songRemainingSeconds:String = Std.string(Math.floor((songRemaining / 1000) % 60)).lpad('0', 2);
    var songRemainingMinutes:String = Std.string(Math.floor((songRemaining / 1000) / 60)).lpad('0', 2);
    var songRemainingString:String = '-${songRemainingMinutes}:${songRemainingSeconds}';

    if (playbarSongRemaining == null) playbarSongRemaining = findComponent('playbarSongRemaining', Label);
    if (playbarSongRemaining != null
      && playbarSongRemaining.value != songRemainingString) playbarSongRemaining.value = songRemainingString;

    if (playbarNoteSnap == null) playbarNoteSnap = findComponent('playbarNoteSnap', Label);
    if (playbarNoteSnap != null && playbarNoteSnap.value != '1/${noteSnapQuant}') playbarNoteSnap.value = '1/${noteSnapQuant}';
  }

  /**
   * Handle keybinds for File menu items.
   */
  function handleFileKeybinds():Void
  {
    // CTRL + N = New Chart
    if (FlxG.keys.pressed.CONTROL && FlxG.keys.justPressed.N)
    {
      ChartEditorDialogHandler.openWelcomeDialog(this, true);
    }

    // CTRL + O = Open Chart
    if (FlxG.keys.pressed.CONTROL && FlxG.keys.justPressed.O)
    {
      ChartEditorDialogHandler.openBrowseWizard(this, true);
    }

    // CTRL + SHIFT + S = Save As
    if (FlxG.keys.pressed.CONTROL && FlxG.keys.pressed.SHIFT && FlxG.keys.justPressed.S)
    {
      ChartEditorImportExportHandler.exportAllSongData(this, false);
    }

    // CTRL + Q = Quit to Menu
    if (FlxG.keys.pressed.CONTROL && FlxG.keys.justPressed.Q)
    {
      quitChartEditor();
    }
  }

  function quitChartEditor():Void
  {
    autoSave();
    FlxG.switchState(new MainMenuState());
  }

  /**
   * Handle keybinds for edit menu items.
   */
  function handleEditKeybinds():Void
  {
    // CTRL + Z = Undo
    if (undoKeyHandler.activated)
    {
      undoLastCommand();
    }

    // CTRL + Y = Redo
    if (redoKeyHandler.activated)
    {
      redoLastCommand();
    }

    // CTRL + C = Copy
    if (FlxG.keys.pressed.CONTROL && FlxG.keys.justPressed.C)
    {
      // Copy selected notes.
      // We don't need a command for this since we can't undo it.
      SongDataUtils.writeItemsToClipboard(
        {
          notes: SongDataUtils.buildNoteClipboard(currentNoteSelection),
          events: SongDataUtils.buildEventClipboard(currentEventSelection),
        });
    }

    // CTRL + X = Cut
    if (FlxG.keys.pressed.CONTROL && FlxG.keys.justPressed.X)
    {
      // Cut selected notes.
      performCommand(new CutItemsCommand(currentNoteSelection, currentEventSelection));
    }

    // CTRL + V = Paste
    if (FlxG.keys.pressed.CONTROL && FlxG.keys.justPressed.V)
    {
      // Paste notes from clipboard, at the playhead.
      performCommand(new PasteItemsCommand(scrollPositionInMs + playheadPositionInMs));
    }

    // DELETE = Delete
    if (FlxG.keys.justPressed.DELETE)
    {
      // Delete selected items.
      if (currentNoteSelection.length > 0 && currentEventSelection.length > 0)
      {
        performCommand(new RemoveItemsCommand(currentNoteSelection, currentEventSelection));
      }
      else if (currentNoteSelection.length > 0)
      {
        performCommand(new RemoveNotesCommand(currentNoteSelection));
      }
      else if (currentEventSelection.length > 0)
      {
        performCommand(new RemoveEventsCommand(currentEventSelection));
      }
    }

    // CTRL + A = Select All
    if (FlxG.keys.pressed.CONTROL && FlxG.keys.justPressed.A)
    {
      // Select all items.
      performCommand(new SelectAllItemsCommand(currentNoteSelection, currentEventSelection));
    }

    // CTRL + I = Select Inverse
    if (FlxG.keys.pressed.CONTROL && FlxG.keys.justPressed.I)
    {
      // Select unselected items and deselect selected items.
      performCommand(new InvertSelectedItemsCommand(currentNoteSelection, currentEventSelection));
    }

    // CTRL + D = Select None
    if (FlxG.keys.pressed.CONTROL && FlxG.keys.justPressed.D)
    {
      // Deselect all items.
      performCommand(new DeselectAllItemsCommand(currentNoteSelection, currentEventSelection));
    }
  }

  /**
   * Handle keybinds for View menu items.
   */
  function handleViewKeybinds():Void
  {
    if (FlxG.keys.pressed.CONTROL && FlxG.keys.justPressed.LEFT)
    {
      incrementDifficulty(-1);
    }
    if (FlxG.keys.pressed.CONTROL && FlxG.keys.justPressed.RIGHT)
    {
      incrementDifficulty(1);
    }
  }

  function incrementDifficulty(change:Int):Void
  {
    var currentDifficultyIndex:Int = availableDifficulties.indexOf(selectedDifficulty);
    var currentAllDifficultyIndex:Int = allDifficulties.indexOf(selectedDifficulty);

    if (currentDifficultyIndex == -1 || currentAllDifficultyIndex == -1)
    {
      trace('ERROR determining difficulty index!');
    }

    var isFirstDiff:Bool = currentAllDifficultyIndex == 0;
    var isLastDiff:Bool = (currentAllDifficultyIndex == allDifficulties.length - 1);

    var isFirstDiffInVariation:Bool = currentDifficultyIndex == 0;
    var isLastDiffInVariation:Bool = (currentDifficultyIndex == availableDifficulties.length - 1);

    trace(allDifficulties);

    if (change < 0 && isFirstDiff)
    {
      trace('At lowest difficulty! Do nothing.');
      return;
    }

    if (change > 0 && isLastDiff)
    {
      trace('At highest difficulty! Do nothing.');
      return;
    }

    if (change < 0)
    {
      trace('Decrement difficulty.');

      // If we reached this point, we are not at the lowest difficulty.
      if (isFirstDiffInVariation)
      {
        // Go to the previous variation, then last difficulty in that variation.
        var currentVariationIndex:Int = availableVariations.indexOf(selectedVariation);
        var prevVariation = availableVariations[currentVariationIndex - 1];
        selectedVariation = prevVariation;

        var prevDifficulty = availableDifficulties[availableDifficulties.length - 1];
        selectedDifficulty = prevDifficulty;

        refreshDifficultyTreeSelection();
        refreshMetadataToolbox();
      }
      else
      {
        // Go to previous difficulty in this variation.
        var prevDifficulty = availableDifficulties[currentDifficultyIndex - 1];
        selectedDifficulty = prevDifficulty;

        refreshDifficultyTreeSelection();
        refreshMetadataToolbox();
      }
    }
    else
    {
      trace('Increment difficulty.');

      // If we reached this point, we are not at the highest difficulty.
      if (isLastDiffInVariation)
      {
        // Go to next variation, then first difficulty in that variation.
        var currentVariationIndex:Int = availableVariations.indexOf(selectedVariation);
        var nextVariation = availableVariations[currentVariationIndex + 1];
        selectedVariation = nextVariation;

        var nextDifficulty = availableDifficulties[0];
        selectedDifficulty = nextDifficulty;

        refreshDifficultyTreeSelection();
        refreshMetadataToolbox();
      }
      else
      {
        // Go to next difficulty in this variation.
        var nextDifficulty = availableDifficulties[currentDifficultyIndex + 1];
        selectedDifficulty = nextDifficulty;

        refreshDifficultyTreeSelection();
        refreshMetadataToolbox();
      }
    }

    #if !mac
    NotificationManager.instance.addNotification(
      {
        title: 'Switch Difficulty',
        body: 'Switched difficulty to ${selectedDifficulty.toTitleCase()}',
        type: NotificationType.Success,
        expiryMs: ChartEditorState.NOTIFICATION_DISMISS_TIME
      });
    #end
  }

  /**
   * Handle keybinds for the Test menu items.
   */
  function handleTestKeybinds():Void
  {
    if (!isHaxeUIDialogOpen && FlxG.keys.justPressed.ENTER)
    {
      var minimal = FlxG.keys.pressed.SHIFT;
      testSongInPlayState(minimal);
    }
  }

  /**
   * Handle keybinds for Help menu items.
   */
  function handleHelpKeybinds():Void
  {
    // F1 = Open Help
    if (FlxG.keys.justPressed.F1) ChartEditorDialogHandler.openUserGuideDialog(this);
  }

  function handleToolboxes():Void
  {
    handleDifficultyToolbox();
    handlePlayerPreviewToolbox();
    handleOpponentPreviewToolbox();
  }

  function handleDifficultyToolbox():Void
  {
    if (difficultySelectDirty)
    {
      difficultySelectDirty = false;

      // Manage the Select Difficulty tree view.
      var difficultyToolbox:Null<CollapsibleDialog> = ChartEditorToolboxHandler.getToolbox(this, CHART_EDITOR_TOOLBOX_DIFFICULTY_LAYOUT);
      if (difficultyToolbox == null) return;

      var treeView:Null<TreeView> = difficultyToolbox.findComponent('difficultyToolboxTree');
      if (treeView == null) return;

      // Clear the tree view so we can rebuild it.
      treeView.clearNodes();

      // , icon: 'haxeui-core/styles/default/haxeui_tiny.png'
      var treeSong:TreeViewNode = treeView.addNode({id: 'stv_song', text: 'S: $currentSongName'});
      treeSong.expanded = true;

      for (curVariation in availableVariations)
      {
        var variationMetadata:Null<SongMetadata> = songMetadata.get(curVariation);
        if (variationMetadata == null) continue;

        var treeVariation:TreeViewNode = treeSong.addNode(
          {
            id: 'stv_variation_$curVariation',
            text: 'V: ${curVariation.toTitleCase()}'
          });
        treeVariation.expanded = true;

        var difficultyList:Array<String> = variationMetadata.playData.difficulties;

        for (difficulty in difficultyList)
        {
          var _treeDifficulty:TreeViewNode = treeVariation.addNode(
            {
              id: 'stv_difficulty_${curVariation}_$difficulty',
              text: 'D: ${difficulty.toTitleCase()}'
            });
        }
      }

      treeView.onChange = onChangeTreeDifficulty;
      refreshDifficultyTreeSelection(treeView);
    }
  }

  public function createDifficulty(variation:String, difficulty:String, scrollSpeed:Float = 1.0)
  {
    var variationMetadata:Null<SongMetadata> = songMetadata.get(variation);
    if (variationMetadata == null) return;

    variationMetadata.playData.difficulties.push(difficulty);

    var resultChartData = songChartData.get(variation);
    if (resultChartData == null)
    {
      resultChartData = new SongChartData([difficulty => scrollSpeed], [], [difficulty => []]);
      songChartData.set(variation, resultChartData);
    }
    else
    {
      resultChartData.scrollSpeed.set(difficulty, scrollSpeed);
      resultChartData.notes.set(difficulty, []);
    }

    difficultySelectDirty = true; // Force the Difficulty toolbox to update.
  }

  function refreshDifficultyTreeSelection(?treeView:TreeView):Void
  {
    if (treeView == null)
    {
      // Manage the Select Difficulty tree view.
      var difficultyToolbox:Null<CollapsibleDialog> = ChartEditorToolboxHandler.getToolbox(this, CHART_EDITOR_TOOLBOX_DIFFICULTY_LAYOUT);
      if (difficultyToolbox == null) return;

      treeView = difficultyToolbox.findComponent('difficultyToolboxTree');
      if (treeView == null) return;
    }

    var currentTreeDifficultyNode = getCurrentTreeDifficultyNode(treeView);
    if (currentTreeDifficultyNode != null) treeView.selectedNode = currentTreeDifficultyNode;
  }

  function handlePlayerPreviewToolbox():Void
  {
    // Manage the Select Difficulty tree view.
    var charPreviewToolbox:Null<CollapsibleDialog> = ChartEditorToolboxHandler.getToolbox(this, CHART_EDITOR_TOOLBOX_PLAYER_PREVIEW_LAYOUT);
    if (charPreviewToolbox == null) return;

    // TODO: Re-enable the player preview once we figure out the performance issues.
    var charPlayer:Null<CharacterPlayer> = null; // charPreviewToolbox.findComponent('charPlayer');
    if (charPlayer == null) return;

    currentPlayerCharacterPlayer = charPlayer;

    if (playerPreviewDirty)
    {
      playerPreviewDirty = false;

      if (currentSongCharacterPlayer != charPlayer.charId)
      {
        if (healthIconBF != null) healthIconBF.characterId = currentSongCharacterPlayer;

        charPlayer.loadCharacter(currentSongCharacterPlayer);
        charPlayer.characterType = CharacterType.BF;
        charPlayer.flip = true;
        charPlayer.targetScale = 0.5;

        charPreviewToolbox.title = 'Player Preview - ${charPlayer.charName}';
      }

      if (charPreviewToolbox != null && !charPreviewToolbox.minimized)
      {
        charPreviewToolbox.width = charPlayer.width + 32;
        charPreviewToolbox.height = charPlayer.height + 64;
      }
    }
  }

  function handleOpponentPreviewToolbox():Void
  {
    // Manage the Select Difficulty tree view.
    var charPreviewToolbox:Null<CollapsibleDialog> = ChartEditorToolboxHandler.getToolbox(this, CHART_EDITOR_TOOLBOX_OPPONENT_PREVIEW_LAYOUT);
    if (charPreviewToolbox == null) return;

    // TODO: Re-enable the player preview once we figure out the performance issues.
    var charPlayer:Null<CharacterPlayer> = null; // charPreviewToolbox.findComponent('charPlayer');
    if (charPlayer == null) return;

    currentOpponentCharacterPlayer = charPlayer;

    if (opponentPreviewDirty)
    {
      opponentPreviewDirty = false;

      if (currentSongCharacterOpponent != charPlayer.charId)
      {
        if (healthIconDad != null) healthIconDad.characterId = currentSongCharacterOpponent;

        charPlayer.loadCharacter(currentSongCharacterOpponent);
        charPlayer.characterType = CharacterType.DAD;
        charPlayer.flip = false;
        charPlayer.targetScale = 0.5;

        charPreviewToolbox.title = 'Opponent Preview - ${charPlayer.charName}';
      }

      if (charPreviewToolbox != null && !charPreviewToolbox.minimized)
      {
        charPreviewToolbox.width = charPlayer.width + 32;
        charPreviewToolbox.height = charPlayer.height + 64;
      }
    }
  }

  public override function dispatchEvent(event:ScriptEvent):Void
  {
    super.dispatchEvent(event);

    // We can't use the ScriptedEventDispatcher with currentCharPlayer because we can't use the IScriptedClass interface on it.
    if (currentPlayerCharacterPlayer != null)
    {
      switch (event.type)
      {
        case ScriptEvent.UPDATE:
          currentPlayerCharacterPlayer.onUpdate(cast event);
        case ScriptEvent.SONG_BEAT_HIT:
          currentPlayerCharacterPlayer.onBeatHit(cast event);
        case ScriptEvent.SONG_STEP_HIT:
          currentPlayerCharacterPlayer.onStepHit(cast event);
        case ScriptEvent.NOTE_HIT:
          currentPlayerCharacterPlayer.onNoteHit(cast event);
      }
    }

    if (currentOpponentCharacterPlayer != null)
    {
      switch (event.type)
      {
        case ScriptEvent.UPDATE:
          currentOpponentCharacterPlayer.onUpdate(cast event);
        case ScriptEvent.SONG_BEAT_HIT:
          currentOpponentCharacterPlayer.onBeatHit(cast event);
        case ScriptEvent.SONG_STEP_HIT:
          currentOpponentCharacterPlayer.onStepHit(cast event);
        case ScriptEvent.NOTE_HIT:
          currentOpponentCharacterPlayer.onNoteHit(cast event);
      }
    }
  }

  function getCurrentTreeDifficultyNode(?treeView:TreeView = null):Null<TreeViewNode>
  {
    if (treeView == null)
    {
      var difficultyToolbox:Null<CollapsibleDialog> = ChartEditorToolboxHandler.getToolbox(this, CHART_EDITOR_TOOLBOX_DIFFICULTY_LAYOUT);
      if (difficultyToolbox == null) return null;

      treeView = difficultyToolbox.findComponent('difficultyToolboxTree');
      if (treeView == null) return null;
    }

    var result:TreeViewNode = treeView.findNodeByPath('stv_song/stv_variation_$selectedVariation/stv_difficulty_${selectedVariation}_$selectedDifficulty',
      'id');
    if (result == null) return null;

    return result;
  }

  /**
   * Called when selecting a tree element in the Difficulty toolbox.
   * @param event The click event.
   */
  function onChangeTreeDifficulty(event:UIEvent):Void
  {
    // Get the newly selected node.
    var treeView:TreeView = cast event.target;
    var targetNode:TreeViewNode = treeView.selectedNode;

    if (targetNode == null)
    {
      trace('No target node!');
      // Reset the user's selection.
      var currentTreeDifficultyNode = getCurrentTreeDifficultyNode(treeView);
      if (currentTreeDifficultyNode != null) treeView.selectedNode = currentTreeDifficultyNode;
      return;
    }

    switch (targetNode.data.id.split('_')[1])
    {
      case 'difficulty':
        var variation:String = targetNode.data.id.split('_')[2];
        var difficulty:String = targetNode.data.id.split('_')[3];

        if (variation != null && difficulty != null)
        {
          trace('Changing difficulty to "$variation:$difficulty"');
          selectedVariation = variation;
          selectedDifficulty = difficulty;
          // refreshDifficultyTreeSelection(treeView);
          refreshMetadataToolbox();
        }
      // case 'song':
      // case 'variation':
      default:
        // Reset the user's selection.
        trace('Selected wrong node type, resetting selection.');
        var currentTreeDifficultyNode = getCurrentTreeDifficultyNode(treeView);
        if (currentTreeDifficultyNode != null) treeView.selectedNode = currentTreeDifficultyNode;
        refreshMetadataToolbox();
    }
  }

  /**
   * When the difficulty changes, update the song metadata toolbox to reflect the new data.
   */
  function refreshMetadataToolbox():Void
  {
    var toolbox:Null<CollapsibleDialog> = ChartEditorToolboxHandler.getToolbox(this, CHART_EDITOR_TOOLBOX_METADATA_LAYOUT);
    if (toolbox == null) return;

    var inputSongName:Null<TextField> = toolbox.findComponent('inputSongName', TextField);
    if (inputSongName != null) inputSongName.value = currentSongMetadata.songName;

    var inputSongArtist:Null<TextField> = toolbox.findComponent('inputSongArtist', TextField);
    if (inputSongArtist != null) inputSongArtist.value = currentSongMetadata.artist;

    var inputStage:Null<DropDown> = toolbox.findComponent('inputStage', DropDown);
    if (inputStage != null) inputStage.value = currentSongMetadata.playData.stage;

    var inputNoteStyle:Null<DropDown> = toolbox.findComponent('inputNoteStyle', DropDown);
    if (inputNoteStyle != null) inputNoteStyle.value = currentSongMetadata.playData.noteSkin;

    var inputBPM:Null<NumberStepper> = toolbox.findComponent('inputBPM', NumberStepper);
    if (inputBPM != null) inputBPM.value = currentSongMetadata.timeChanges[0].bpm;

    var labelScrollSpeed:Null<Label> = toolbox.findComponent('labelScrollSpeed', Label);
    if (labelScrollSpeed != null) labelScrollSpeed.text = 'Scroll Speed: ${currentSongChartScrollSpeed}x';

    var inputScrollSpeed:Null<Slider> = toolbox.findComponent('inputScrollSpeed', Slider);
    if (inputScrollSpeed != null) inputScrollSpeed.value = currentSongChartScrollSpeed;

    var frameVariation:Null<Frame> = toolbox.findComponent('frameVariation', Frame);
    if (frameVariation != null) frameVariation.text = 'Variation: ${selectedVariation.toTitleCase()}';
    var frameDifficulty:Null<Frame> = toolbox.findComponent('frameDifficulty', Frame);
    if (frameDifficulty != null) frameDifficulty.text = 'Difficulty: ${selectedDifficulty.toTitleCase()}';

    var inputStage:Null<DropDown> = toolbox.findComponent('inputStage', DropDown);
    var stageId:String = currentSongMetadata.playData.stage;
    var stageData:Null<StageData> = StageDataParser.parseStageData(stageId);
    if (stageData != null)
    {
      inputStage.value = {id: stageId, text: stageData.name};
    }
    else
    {
      inputStage.value = {id: "mainStage", text: "Main Stage"};
    }

    var inputCharacterPlayer:Null<DropDown> = toolbox.findComponent('inputCharacterPlayer', DropDown);
    var charIdPlayer:String = currentSongMetadata.playData.characters.player;
    var charDataPlayer:Null<CharacterData> = CharacterDataParser.fetchCharacterData(charIdPlayer);
    if (charDataPlayer != null)
    {
      inputCharacterPlayer.value = {id: charIdPlayer, text: charDataPlayer.name};
    }
    else
    {
      inputCharacterPlayer.value = {id: "bf", text: "Boyfriend"};
    }

    var inputCharacterOpponent:Null<DropDown> = toolbox.findComponent('inputCharacterOpponent', DropDown);
    var charIdOpponent:String = currentSongMetadata.playData.characters.opponent;
    var charDataOpponent:Null<CharacterData> = CharacterDataParser.fetchCharacterData(charIdOpponent);
    if (charDataOpponent != null)
    {
      inputCharacterOpponent.value = {id: charIdOpponent, text: charDataOpponent.name};
    }
    else
    {
      inputCharacterOpponent.value = {id: "dad", text: "Dad"};
    }

    var inputCharacterGirlfriend:Null<DropDown> = toolbox.findComponent('inputCharacterGirlfriend', DropDown);
    var charIdGirlfriend:String = currentSongMetadata.playData.characters.girlfriend;
    var charDataGirlfriend:Null<CharacterData> = CharacterDataParser.fetchCharacterData(charIdGirlfriend);
    if (charDataGirlfriend != null)
    {
      inputCharacterGirlfriend.value = {id: charIdGirlfriend, text: charDataGirlfriend.name};
    }
    else
    {
      inputCharacterGirlfriend.value = {id: "none", text: "None"};
    }
  }

  /**
   * Handle the player preview/gameplay test area on the left side.
   */
  function handlePlayerDisplay():Void {}

  /**
   * Handles the note preview/scroll area on the right side.
   * Notes are rendered here as small bars.
   * This function also handles:
   * - Moving the viewport preview box around based on its current position.
   * - Scrolling the note preview area down if the note preview is taller than the screen,
   *   and the viewport nears the end of the visible area.
   */
  function handleNotePreview():Void
  {
    if (notePreviewDirty && notePreview != null)
    {
      notePreviewDirty = false;

      // TODO: Only update the notes that have changed.
      notePreview.erase();
      notePreview.addNotes(currentSongChartNoteData, Std.int(songLengthInMs));
      notePreview.addEvents(currentSongChartEventData, Std.int(songLengthInMs));
    }

    if (notePreviewViewportBoundsDirty)
    {
      setNotePreviewViewportBounds(calculateNotePreviewViewportBounds());
    }
  }

  /**
   * Handles passive behavior of the menu bar, such as updating labels or enabled/disabled status.
   * Does not handle onClick ACTIONS of the menubar.
   */
  function handleMenubar():Void
  {
    if (commandHistoryDirty)
    {
      commandHistoryDirty = false;

      // Update the Undo and Redo buttons.
      var undoButton:Null<MenuItem> = findComponent('menubarItemUndo', MenuItem);

      if (undoButton != null)
      {
        if (undoHistory.length == 0)
        {
          // Disable the Undo button.
          undoButton.disabled = true;
          undoButton.text = 'Undo';
        }
        else
        {
          // Change the label to the last command.
          undoButton.disabled = false;
          undoButton.text = 'Undo ${undoHistory[undoHistory.length - 1].toString()}';
        }
      }
      else
      {
        trace('undoButton is null');
      }

      var redoButton:Null<MenuItem> = findComponent('menubarItemRedo', MenuItem);

      if (redoButton != null)
      {
        if (redoHistory.length == 0)
        {
          // Disable the Redo button.
          redoButton.disabled = true;
          redoButton.text = 'Redo';
        }
        else
        {
          // Change the label to the last command.
          redoButton.disabled = false;
          redoButton.text = 'Redo ${redoHistory[redoHistory.length - 1].toString()}';
        }
      }
      else
      {
        trace('redoButton is null');
      }
    }
  }

  /**
   * Handle syncronizing the conductor with the music playback.
   */
  function handleMusicPlayback():Void
  {
    if (audioInstTrack != null && audioInstTrack.playing)
    {
      if (FlxG.mouse.pressedMiddle)
      {
        // If middle mouse panning during song playback, we move ONLY the playhead, without scrolling. Neat!

        var oldStepTime:Float = Conductor.currentStepTime;
        var oldSongPosition:Float = Conductor.songPosition;
        Conductor.update(audioInstTrack.time);
        handleHitsounds(oldSongPosition, Conductor.songPosition);
        // Resync vocals.
        if (audioVocalTrackGroup != null && Math.abs(audioInstTrack.time - audioVocalTrackGroup.time) > 100)
        {
          audioVocalTrackGroup.time = audioInstTrack.time;
        }
        var diffStepTime:Float = Conductor.currentStepTime - oldStepTime;

        // Move the playhead.
        playheadPositionInPixels += diffStepTime * GRID_SIZE;

        // We don't move the song to scroll position, or update the note sprites.
      }
      else
      {
        // Else, move the entire view.
        var oldSongPosition:Float = Conductor.songPosition;
        Conductor.update(audioInstTrack.time);
        handleHitsounds(oldSongPosition, Conductor.songPosition);
        // Resync vocals.
        if (audioVocalTrackGroup != null && Math.abs(audioInstTrack.time - audioVocalTrackGroup.time) > 100)
        {
          audioVocalTrackGroup.time = audioInstTrack.time;
        }

        // We need time in fractional steps here to allow the song to actually play.
        // Also account for a potentially offset playhead.
        scrollPositionInPixels = Conductor.currentStepTime * GRID_SIZE - playheadPositionInPixels;

        // DO NOT move song to scroll position here specifically.

        // We need to update the note sprites.
        noteDisplayDirty = true;

        // Update the note preview viewport box.
        setNotePreviewViewportBounds(calculateNotePreviewViewportBounds());
      }
    }

    if (FlxG.keys.justPressed.SPACE && !isHaxeUIDialogOpen)
    {
      toggleAudioPlayback();
    }
  }

  /**
   * Handle the playback of hitsounds.
   */
  function handleHitsounds(oldSongPosition:Float, newSongPosition:Float):Void
  {
    if (!hitsoundsEnabled) return;

    // Assume notes are sorted by time.
    for (noteData in currentSongChartNoteData)
    {
      // Check for notes between the old and new song positions.

      if (noteData.time < oldSongPosition) // Note is in the past.
        continue;

      if (noteData.time > newSongPosition) // Note is in the future.
        return; // Assume all notes are also in the future.

      // Note was just hit.

      // Character preview.

      // NoteScriptEvent takes a sprite, ehe. Need to rework that.
      var tempNote:NoteSprite = new NoteSprite(NoteStyleRegistry.instance.fetchDefault());
      tempNote.noteData = noteData;
      tempNote.scrollFactor.set(0, 0);
      var event:NoteScriptEvent = new NoteScriptEvent(ScriptEvent.NOTE_HIT, tempNote, 1, true);
      dispatchEvent(event);

      // Calling event.cancelEvent() skips all the other logic! Neat!
      if (event.eventCanceled) continue;

      // Hitsounds.
      switch (noteData.getStrumlineIndex())
      {
        case 0: // Player
          if (hitsoundsEnabledPlayer) ChartEditorAudioHandler.playSound(Paths.sound('funnyNoise/funnyNoise-09'));
        case 1: // Opponent
          if (hitsoundsEnabledOpponent) ChartEditorAudioHandler.playSound(Paths.sound('funnyNoise/funnyNoise-010'));
      }
    }
  }

  function startAudioPlayback():Void
  {
    if (audioInstTrack != null)
    {
      audioInstTrack.play(false, audioInstTrack.time);
      if (audioVocalTrackGroup != null) audioVocalTrackGroup.play(false, audioInstTrack.time);
    }

    setComponentText('playbarPlay', '||');
  }

  function stopAudioPlayback():Void
  {
    if (audioInstTrack != null) audioInstTrack.pause();
    if (audioVocalTrackGroup != null) audioVocalTrackGroup.pause();

    setComponentText('playbarPlay', '>');
  }

  function toggleAudioPlayback():Void
  {
    if (audioInstTrack == null) return;

    if (audioInstTrack.playing)
    {
      stopAudioPlayback();
    }
    else
    {
      startAudioPlayback();
    }
  }

  function handlePlayhead():Void
  {
    // Place notes at the playhead.
    switch (currentLiveInputStyle)
    {
      case LiveInputStyle.WASD:
        if (FlxG.keys.justPressed.A) placeNoteAtPlayhead(0);
        if (FlxG.keys.justPressed.S) placeNoteAtPlayhead(1);
        if (FlxG.keys.justPressed.W) placeNoteAtPlayhead(2);
        if (FlxG.keys.justPressed.D) placeNoteAtPlayhead(3);

        if (FlxG.keys.justPressed.LEFT) placeNoteAtPlayhead(4);
        if (FlxG.keys.justPressed.DOWN) placeNoteAtPlayhead(5);
        if (FlxG.keys.justPressed.UP) placeNoteAtPlayhead(6);
        if (FlxG.keys.justPressed.RIGHT) placeNoteAtPlayhead(7);
      case LiveInputStyle.NumberKeys:
        if (FlxG.keys.justPressed.ONE) placeNoteAtPlayhead(0);
        if (FlxG.keys.justPressed.TWO) placeNoteAtPlayhead(1);
        if (FlxG.keys.justPressed.THREE) placeNoteAtPlayhead(2);
        if (FlxG.keys.justPressed.FOUR) placeNoteAtPlayhead(3);

        if (FlxG.keys.justPressed.FIVE) placeNoteAtPlayhead(4);
        if (FlxG.keys.justPressed.SIX) placeNoteAtPlayhead(5);
        if (FlxG.keys.justPressed.SEVEN) placeNoteAtPlayhead(6);
        if (FlxG.keys.justPressed.EIGHT) placeNoteAtPlayhead(7);
      case LiveInputStyle.None:
        // Do nothing.
    }
  }

  function placeNoteAtPlayhead(column:Int):Void
  {
    var playheadPos:Float = scrollPositionInPixels + playheadPositionInPixels;
    var playheadPosFractionalStep:Float = playheadPos / GRID_SIZE / (16 / noteSnapQuant);
    var playheadPosStep:Int = Std.int(Math.floor(playheadPosFractionalStep));
    var playheadPosMs:Float = playheadPosStep * Conductor.stepLengthMs * (16 / noteSnapQuant);

    var newNoteData:SongNoteData = new SongNoteData(playheadPosMs, column, 0, selectedNoteKind);
    performCommand(new AddNotesCommand([newNoteData], FlxG.keys.pressed.CONTROL));
  }

  function set_scrollPositionInPixels(value:Float):Float
  {
    if (value < 0)
    {
      // If we're scrolling up, and we hit the top,
      // but the playhead is in the middle, move the playhead up.
      if (playheadPositionInPixels > 0)
      {
        var amount:Float = scrollPositionInPixels - value;
        playheadPositionInPixels -= amount;
      }

      value = 0;
    }

    if (value > songLengthInPixels) value = songLengthInPixels;

    if (value == scrollPositionInPixels) return value;

    // Difference in pixels.
    var diff:Float = value - scrollPositionInPixels;

    this.scrollPositionInPixels = value;

    // Move the grid sprite to the correct position.
    if (gridTiledSprite != null)
    {
      if (isViewDownscroll)
      {
        gridTiledSprite.y = -scrollPositionInPixels + (MENU_BAR_HEIGHT + GRID_TOP_PAD);
        gridPlayheadScrollArea.y = gridTiledSprite.y;
      }
      else
      {
        gridTiledSprite.y = -scrollPositionInPixels + (MENU_BAR_HEIGHT + GRID_TOP_PAD);
        gridPlayheadScrollArea.y = gridTiledSprite.y;
      }
    }

    // Move the rendered notes to the correct position.
    renderedNotes.setPosition(gridTiledSprite?.x ?? 0.0, gridTiledSprite?.y ?? 0.0);
    renderedHoldNotes.setPosition(gridTiledSprite?.x ?? 0.0, gridTiledSprite?.y ?? 0.0);
    renderedEvents.setPosition(gridTiledSprite?.x ?? 0.0, gridTiledSprite?.y ?? 0.0);
    renderedSelectionSquares.setPosition(gridTiledSprite?.x ?? 0.0, gridTiledSprite?.y ?? 0.0);
    // Offset the selection box start position, if we are dragging.
    if (selectionBoxStartPos != null) selectionBoxStartPos.y -= diff;
    // Update the note preview viewport box.
    setNotePreviewViewportBounds(calculateNotePreviewViewportBounds());
    return this.scrollPositionInPixels;
  }

  /**
   * Transitions to the Play State to test the song
   */
  public function testSongInPlayState(minimal:Bool = false):Void
  {
    autoSave();

    var startTimestamp:Float = 0;
    if (playtestStartTime) startTimestamp = scrollPositionInMs + playheadPositionInMs;

    var targetSong:Song = Song.buildRaw(currentSongId, songMetadata.values(), availableVariations, songChartData, false);

    // TODO: Rework asset system so we can remove this.
    switch (currentSongStage)
    {
      case 'mainStage':
        Paths.setCurrentLevel('week1');
      case 'spookyMansion':
        Paths.setCurrentLevel('week2');
      case 'phillyTrain':
        Paths.setCurrentLevel('week3');
      case 'limoRide':
        Paths.setCurrentLevel('week4');
      case 'mallXmas' | 'mallEvil':
        Paths.setCurrentLevel('week5');
      case 'school' | 'schoolEvil':
        Paths.setCurrentLevel('week6');
      case 'tankmanBattlefield':
        Paths.setCurrentLevel('week7');
      case 'phillyStreets' | 'phillyBlazin':
        Paths.setCurrentLevel('weekend1');
    }

    subStateClosed.add(fixCamera);
    subStateClosed.add(updateConductor);

    FlxTransitionableState.skipNextTransIn = false;
    FlxTransitionableState.skipNextTransOut = false;

    var targetState = new PlayState(
      {
        targetSong: targetSong,
        targetDifficulty: selectedDifficulty,
        // TODO: Add this.
        // targetCharacter: targetCharacter,
        practiceMode: true,
        minimalMode: minimal,
        startTimestamp: startTimestamp,
        overrideMusic: true,
      });

    // Override music.
    if (audioInstTrack != null) FlxG.sound.music = audioInstTrack;
    if (audioVocalTrackGroup != null) targetState.vocals = audioVocalTrackGroup;

    openSubState(targetState);
  }

  function fixCamera(_:FlxSubState = null):Void
  {
    FlxG.cameras.reset(new FlxCamera());
    FlxG.camera.focusOn(new FlxPoint(FlxG.width / 2, FlxG.height / 2));
    FlxG.camera.zoom = 1.0;

    add(this.component);
  }

  function updateConductor(_:FlxSubState = null):Void
  {
    var targetPos = scrollPositionInMs;
    Conductor.update(targetPos);
  }

  public function postLoadInstrumental():Void
  {
    if (audioInstTrack != null)
    {
      // Prevent the time from skipping back to 0 when the song ends.
      audioInstTrack.onComplete = function() {
        if (audioInstTrack != null) audioInstTrack.pause();
        if (audioVocalTrackGroup != null) audioVocalTrackGroup.pause();
      };

      songLengthInMs = audioInstTrack.length;

      if (gridTiledSprite != null) gridTiledSprite.height = songLengthInPixels;
      if (gridPlayheadScrollArea != null)
      {
        gridPlayheadScrollArea.setGraphicSize(Std.int(gridPlayheadScrollArea.width), songLengthInPixels);
        gridPlayheadScrollArea.updateHitbox();
      }

      buildSpectrogram(audioInstTrack);
    }

    scrollPositionInPixels = 0;
    playheadPositionInPixels = 0;
    notePreviewDirty = true;
    notePreviewViewportBoundsDirty = true;
    noteDisplayDirty = true;
    moveSongToScrollPosition();
  }

  /**
   * Clear the voices group.
   */
  public function clearVocals():Void
  {
    if (audioVocalTrackGroup != null) audioVocalTrackGroup.clear();
  }

  /**
   * When setting the scroll position, except when automatically scrolling during song playback,
   * we need to update the conductor's current step time and the timestamp of the audio tracks.
   */
  function moveSongToScrollPosition():Void
  {
    // Update the songPosition in the Conductor.
    var targetPos = scrollPositionInMs;
    Conductor.update(targetPos);

    // Update the songPosition in the audio tracks.
    if (audioInstTrack != null) audioInstTrack.time = scrollPositionInMs + playheadPositionInMs;
    if (audioVocalTrackGroup != null) audioVocalTrackGroup.time = scrollPositionInMs + playheadPositionInMs;

    // We need to update the note sprites because we changed the scroll position.
    noteDisplayDirty = true;
  }

  function easeSongToScrollPosition(targetScrollPosition:Float):Void
  {
    if (currentScrollEase != null) cancelScrollEase(currentScrollEase);

    currentScrollEase = FlxTween.tween(this, {scrollPositionInPixels: targetScrollPosition}, SCROLL_EASE_DURATION,
      {
        ease: FlxEase.quintInOut,
        onUpdate: this.onScrollEaseUpdate,
        onComplete: this.cancelScrollEase,
        type: ONESHOT
      });
  }

  function onScrollEaseUpdate(_:FlxTween):Void
  {
    moveSongToScrollPosition();
  }

  function cancelScrollEase(_:FlxTween):Void
  {
    if (currentScrollEase != null)
    {
      @:privateAccess
      var targetScrollPosition:Float = currentScrollEase._properties.scrollPositionInPixels;

      currentScrollEase.cancel();
      currentScrollEase = null;
      this.scrollPositionInPixels = targetScrollPosition;
    }
  }

  /**
   * Perform (or redo) a command, then add it to the undo stack.
   *
   * @param command The command to perform.
   * @param purgeRedoStack If true, the redo stack will be cleared.
   */
  function performCommand(command:ChartEditorCommand, purgeRedoStack:Bool = true):Void
  {
    command.execute(this);
    undoHistory.push(command);
    commandHistoryDirty = true;
    if (purgeRedoStack) redoHistory = [];
  }

  /**
   * Undo a command, then add it to the redo stack.
   * @param command The command to undo.
   */
  function undoCommand(command:ChartEditorCommand):Void
  {
    command.undo(this);
    redoHistory.push(command);
    commandHistoryDirty = true;
  }

  /**
   * Undo the last command in the undo stack, then add it to the redo stack.
   */
  function undoLastCommand():Void
  {
    var command:Null<ChartEditorCommand> = undoHistory.pop();
    if (command == null)
    {
      trace('No actions to undo.');
      return;
    }
    undoCommand(command);
  }

  /**
   * Redo the last command in the redo stack, then add it to the undo stack.
   */
  function redoLastCommand():Void
  {
    var command:Null<ChartEditorCommand> = redoHistory.pop();
    if (command == null)
    {
      trace('No actions to redo.');
      return;
    }
    performCommand(command, false);
  }

  function sortChartData():Void
  {
    // TODO: .insertionSort()
    currentSongChartNoteData.sort(function(a:SongNoteData, b:SongNoteData):Int {
      return FlxSort.byValues(FlxSort.ASCENDING, a.time, b.time);
    });

    // TODO: .insertionSort()
    currentSongChartEventData.sort(function(a:SongEventData, b:SongEventData):Int {
      return FlxSort.byValues(FlxSort.ASCENDING, a.time, b.time);
    });
  }

  function playMetronomeTick(high:Bool = false):Void
  {
    ChartEditorAudioHandler.playSound(Paths.sound('pianoStuff/piano-${high ? '001' : '008'}'));
  }

  function isNoteSelected(note:Null<SongNoteData>):Bool
  {
    return note != null && currentNoteSelection.indexOf(note) != -1;
  }

  function isEventSelected(event:Null<SongEventData>):Bool
  {
    return event != null && currentEventSelection.indexOf(event) != -1;
  }

  override function destroy():Void
  {
    super.destroy();

    cleanupAutoSave();

    // Hide the mouse cursor on other states.
    Cursor.hide();

    @:privateAccess
    ChartEditorNoteSprite.noteFrameCollection = null;
  }

  /**
   * Dismiss any existing notifications, if there are any.
   */
  function dismissNotifications():Void
  {
    NotificationManager.instance.clearNotifications();
  }
}

enum LiveInputStyle
{
  None;
  NumberKeys;
  WASD;
}
