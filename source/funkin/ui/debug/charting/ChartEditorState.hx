package funkin.ui.debug.charting;

import funkin.ui.debug.charting.ChartEditorCommand;
import flixel.input.keyboard.FlxKey;
import funkin.input.TurboKeyHandler;
import haxe.ui.notifications.NotificationType;
import haxe.ui.notifications.NotificationManager;
import haxe.DynamicAccess;
import haxe.io.Path;
import flixel.addons.display.FlxSliceSprite;
import flixel.addons.display.FlxTiledSprite;
import flixel.FlxSprite;
import flixel.group.FlxSpriteGroup;
import flixel.math.FlxPoint;
import flixel.math.FlxRect;
import flixel.sound.FlxSound;
import flixel.util.FlxColor;
import flixel.util.FlxSort;
import flixel.util.FlxTimer;
import funkin.audio.visualize.PolygonSpectogram;
import funkin.audio.VoicesGroup;
import funkin.input.Cursor;
import funkin.modding.events.ScriptEvent;
import funkin.play.HealthIcon;
import funkin.play.song.Song;
import funkin.play.song.SongData.SongChartData;
import funkin.play.song.SongData.SongDataParser;
import funkin.play.song.SongData.SongEventData;
import funkin.play.song.SongData.SongMetadata;
import funkin.play.song.SongData.SongNoteData;
import funkin.play.song.SongDataUtils;
import funkin.ui.debug.charting.ChartEditorThemeHandler.ChartEditorTheme;
import funkin.ui.debug.charting.ChartEditorToolboxHandler.ChartEditorToolMode;
import funkin.ui.haxeui.components.CharacterPlayer;
import funkin.ui.haxeui.HaxeUIState;
import funkin.util.Constants;
import funkin.util.FileUtil;
import funkin.util.DateUtil;
import funkin.util.SerializerUtil;
import haxe.ui.components.Label;
import haxe.ui.components.Slider;
import haxe.ui.containers.dialogs.Dialog;
import haxe.ui.containers.menus.MenuItem;
import haxe.ui.containers.TreeView;
import haxe.ui.containers.TreeViewNode;
import haxe.ui.core.Component;
import haxe.ui.core.Screen;
import haxe.ui.events.DragEvent;
import haxe.ui.events.UIEvent;
import funkin.util.WindowUtil;
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
@:allow(funkin.ui.debug.charting.ChartEditorCommand)
@:allow(funkin.ui.debug.charting.ChartEditorDialogHandler)
@:allow(funkin.ui.debug.charting.ChartEditorThemeHandler)
@:allow(funkin.ui.debug.charting.ChartEditorToolboxHandler)
class ChartEditorState extends HaxeUIState
{
  /**
   * CONSTANTS
   */
  // ==============================
  // XML Layouts
  static final CHART_EDITOR_LAYOUT = Paths.ui('chart-editor/main-view');

  static final CHART_EDITOR_NOTIFBAR_LAYOUT = Paths.ui('chart-editor/components/notifbar');
  static final CHART_EDITOR_PLAYBARHEAD_LAYOUT = Paths.ui('chart-editor/components/playbar-head');

  static final CHART_EDITOR_TOOLBOX_TOOLS_LAYOUT = Paths.ui('chart-editor/toolbox/tools');
  static final CHART_EDITOR_TOOLBOX_NOTEDATA_LAYOUT = Paths.ui('chart-editor/toolbox/notedata');
  static final CHART_EDITOR_TOOLBOX_EVENTDATA_LAYOUT = Paths.ui('chart-editor/toolbox/eventdata');
  static final CHART_EDITOR_TOOLBOX_METADATA_LAYOUT = Paths.ui('chart-editor/toolbox/metadata');
  static final CHART_EDITOR_TOOLBOX_DIFFICULTY_LAYOUT = Paths.ui('chart-editor/toolbox/difficulty');
  static final CHART_EDITOR_TOOLBOX_CHARACTERS_LAYOUT = Paths.ui('chart-editor/toolbox/characters');
  static final CHART_EDITOR_TOOLBOX_PLAYER_PREVIEW_LAYOUT = Paths.ui('chart-editor/toolbox/player-preview');
  static final CHART_EDITOR_TOOLBOX_OPPONENT_PREVIEW_LAYOUT = Paths.ui('chart-editor/toolbox/opponent-preview');

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
  public static final STRUMLINE_SIZE = 4;

  /**
   * The height of the menu bar in the layout.
   */
  static final MENU_BAR_HEIGHT = 32;

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

  // Start performing rapid undo after this many seconds.
  static final RAPID_UNDO_DELAY:Float = 0.4;
  // Perform a rapid undo every this many seconds.
  static final RAPID_UNDO_INTERVAL:Float = 0.1;

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

  /**
   * INSTANCE DATA
   */
  // ==============================
  public var currentZoomLevel:Float = 1.0;

  var noteSnapQuantIndex:Int = 3;

  public var noteSnapQuant(get, never):Int;

  function get_noteSnapQuant():Int
  {
    return SNAP_QUANTS[noteSnapQuantIndex];
  }

  /**
   * scrollPosition is the current position in the song, in pixels.
   * One pixel is 1/40 of 1 step, and 1/160 of 1 beat.
   */
  var scrollPositionInPixels(default, set):Float = -1.0;

  /**
   * scrollPosition, converted to steps.
   * TODO: Handle BPM changes.
   */
  var scrollPositionInSteps(get, null):Float;

  function get_scrollPositionInSteps():Float
  {
    return scrollPositionInPixels / GRID_SIZE;
  }

  /**
   * scrollPosition, converted to milliseconds.
   * TODO: Handle BPM changes.
   */
  var scrollPositionInMs(get, set):Float;

  function get_scrollPositionInMs():Float
  {
    return scrollPositionInSteps * Conductor.stepLengthMs;
  }

  function set_scrollPositionInMs(value:Float):Float
  {
    scrollPositionInPixels = value / Conductor.stepLengthMs;
    return value;
  }

  /**
   * The position of the playhead, in pixels, relative to the scrollPosition.
   * 0 means playhead is at the top of the grid.
   * 40 means the playhead is 1 grid length below the base position.
   * -40 means the playhead is 1 grid length above the base position.
   */
  var playheadPositionInPixels(default, set):Float;

  var playheadPositionInSteps(get, null):Float;

  /**
   * playheadPosition, converted to steps.
   */
  function get_playheadPositionInSteps():Float
  {
    return playheadPositionInPixels / GRID_SIZE;
  }

  /**
   * playheadPosition, converted to milliseconds.
   */
  var playheadPositionInMs(get, null):Float;

  function get_playheadPositionInMs():Float
  {
    return playheadPositionInSteps * Conductor.stepLengthMs;
  }

  /**
   * This is the song's length in PIXELS, same format as scrollPosition.
   */
  var songLengthInPixels(get, default):Int;

  function get_songLengthInPixels():Int
  {
    if (songLengthInPixels <= 0) return 1000;

    return songLengthInPixels;
  }

  /**
   * songLength, converted to steps.
   * TODO: Handle BPM changes.
   */
  var songLengthInSteps(get, set):Float;

  function get_songLengthInSteps():Float
  {
    return songLengthInPixels / GRID_SIZE;
  }

  function set_songLengthInSteps(value:Float):Float
  {
    songLengthInPixels = Std.int(value * GRID_SIZE);
    return value;
  }

  /**
   * songLength, converted to milliseconds.
   * TODO: Handle BPM changes.
   */
  var songLengthInMs(get, set):Float;

  function get_songLengthInMs():Float
  {
    return songLengthInSteps * Conductor.stepLengthMs;
  }

  function set_songLengthInMs(value:Float):Float
  {
    songLengthInSteps = Conductor.getTimeInSteps(audioInstTrack.length);
    return value;
  }

  var currentTheme(default, set):ChartEditorTheme = null;

  function set_currentTheme(value:ChartEditorTheme):ChartEditorTheme
  {
    if (value == null || value == currentTheme) return currentTheme;

    currentTheme = value;
    ChartEditorThemeHandler.updateTheme(this);
    return value;
  }

  /**
   * Whether a skip button has been pressed on the playbar, and which one.
   * This will be used to update the scrollPosition (in the same function that handles the scroll wheel), then cleared.
   */
  var playbarButtonPressed:String = null;

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
  var shouldPlayMetronome:Bool = true;

  /**
   * Use the tool window to affect how the user interacts with the program.
   */
  var currentToolMode:ChartEditorToolMode = ChartEditorToolMode.Select;

  /**
   * The character sprite in the Player Preview window.
   */
  var currentPlayerCharacterPlayer:CharacterPlayer = null;

  /**
   * The character sprite in the Opponent Preview window.
   */
  var currentOpponentCharacterPlayer:CharacterPlayer = null;

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
    this.scrollPositionInPixels = this.scrollPositionInPixels;

    return isViewDownscroll;
  }

  /**
   * Whether hitsounds are enabled for at least one character.
   */
  var hitsoundsEnabled(get, null):Bool;

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
  var isCursorOverHaxeUI(get, null):Bool;

  function get_isCursorOverHaxeUI():Bool
  {
    return Screen.instance.hasSolidComponentUnderPoint(FlxG.mouse.screenX, FlxG.mouse.screenY);
  }

  var isCursorOverHaxeUIButton(get, null):Bool;

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

    return selectedDifficulty;
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
   * The Bitmap can be modified by individual commands without using this.
   */
  var notePreviewDirty:Bool = true;

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
      // Stop the auto-save timer.
      autoSaveTimer.cancel();
      autoSaveTimer.destroy();
      autoSaveTimer = null;
    }

    return saveDataDirty = value;
  }

  /**
   * A timer used to auto-save the chart after a period of inactivity.
   */
  var autoSaveTimer:FlxTimer;

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
   * The selection box extends from this point to the current mouse position.
   */
  var selectionBoxStartPos:FlxPoint = null;

  /**
   * Whether the user's last mouse click was on the playhead scroll area.
   */
  var gridPlayheadScrollAreaPressed:Bool = false;

  /**
   * The SongNoteData which is currently being placed.
   * As the user drags, we will update this note's sustain length.
   */
  var currentPlaceNoteData:SongNoteData = null;

  /**
   * The Dialog components representing the currently available tool windows.
   * Dialogs are retained here even when collapsed or hidden.
   */
  var activeToolboxes:Map<String, Dialog> = new Map<String, Dialog>();

  /**
   * AUDIO AND SOUND DATA
   */
  // ==============================

  /**
   * The audio track for the instrumental.
   */
  var audioInstTrack:FlxSound;

  /**
   * The audio track for the vocals.
   */
  var audioVocalTrackGroup:VoicesGroup;

  /**
   * A map of the audio tracks for each character's vocals.
   * - Keys are the character IDs.
   * - Values are the FlxSound objects to play that character's vocals.
   *
   * When switching characters, the elements of the VoicesGroup will be swapped to match the new character.
   */
  var audioVocalTracks:Map<String, FlxSound> = new Map<String, FlxSound>();

  /**
   * CHART DATA
   */
  // ==============================

  /**
   * The song metadata.
   * - Keys are the variation IDs. At least one (`default`) must exist.
   * - Values are the relevant metadata, ready to be serialized to JSON.
   */
  var songMetadata:Map<String, SongMetadata>;

  var availableVariations(get, null):Array<String>;

  function get_availableVariations():Array<String>
  {
    return [for (x in songMetadata.keys()) x];
  }

  /**
   * The song chart data.
   * - Keys are the variation IDs. At least one (`default`) must exist.
   * - Values are the relevant chart data, ready to be serialized to JSON.
   */
  var songChartData:Map<String, SongChartData>;

  /**
   * Convenience property to get the chart data for the current variation.
   */
  var currentSongMetadata(get, set):SongMetadata;

  function get_currentSongMetadata():SongMetadata
  {
    var result = songMetadata.get(selectedVariation);
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
    var result = songChartData.get(selectedVariation);
    if (result == null)
    {
      result = new SongChartData(1.0, [], []);
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
    var result = currentSongChartData.scrollSpeed.get(selectedDifficulty);
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
    var result = currentSongChartData.notes.get(selectedDifficulty);
    if (result == null)
    {
      // Initialize to the default value if not set.
      result = [];
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

  public var currentSongNoteSkin(get, set):String;

  function get_currentSongNoteSkin():String
  {
    if (currentSongMetadata.playData.noteSkin == null)
    {
      // Initialize to the default value if not set.
      currentSongMetadata.playData.noteSkin = 'Normal';
    }
    return currentSongMetadata.playData.noteSkin;
  }

  function set_currentSongNoteSkin(value:String):String
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

  var currentSongId(get, null):String;

  function get_currentSongId():String
  {
    return currentSongName.toLowerKebabCase();
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

  /**
   * RENDER OBJECTS
   */
  // ==============================

  /**
   * The IMAGE used for the grid. Updated by ChartEditorThemeHandler.
   */
  var gridBitmap:BitmapData;

  /**
   * The IMAGE used for the selection squares. Updated by ChartEditorThemeHandler.
   * Used two ways:
   * 1. A sprite is given this bitmap and placed over selected notes.
   * 2. The image is split and used for a 9-slice sprite for the selection box.
   */
  var selectionSquareBitmap:BitmapData = null;

  /**
   * The tiled sprite used to display the grid.
   * The height is the length of the song, and scrolling is done by simply the sprite.
   */
  var gridTiledSprite:FlxSprite;

  /**
   * The playhead representing the current position in the song.
   * Can move around on the grid independently of the view.
   */
  var gridPlayhead:FlxSpriteGroup;

  var gridPlayheadScrollArea:FlxSprite;

  /**
   * A sprite used to indicate the note that will be placed on click.
   */
  var gridGhostNote:ChartEditorNoteSprite;

  /**
   * A sprite used to indicate the event that will be placed on click.
   */
  var gridGhostEvent:ChartEditorEventSprite;

  /**
   * The waveform which (optionally) displays over the grid, underneath the notes and playhead.
   */
  var gridSpectrogram:PolygonSpectogram;

  /**
   * The rectangle used for the note preview area.
   * Should span the full height of the song. We scribble on this to draw the preview.
   */
  var notePreviewBitmap:BitmapData;

  /**
   * The sprite used to display the note preview area.
   * We move this up and down to scroll the preview.
   */
  var notePreviewSprite:FlxSprite;

  /**
   * The rectangular sprite used for rendering the selection box.
   * Uses a 9-slice to stretch the selection box to the correct size without warping.
   */
  var selectionBoxSprite:FlxSliceSprite;

  /**
   * The opponent's health icon.
   */
  var healthIconDad:HealthIcon;

  /**
   * The player's health icon.
   */
  var healthIconBF:HealthIcon;

  /**
   * The purple background sprite.
   */
  var menuBG:FlxSprite;

  /**
   * The sprite group containing the note graphics.
   * Only displays a subset of the data from `currentSongChartNoteData`,
   * and kills notes that are off-screen to be recycled later.
   */
  var renderedNotes:FlxTypedSpriteGroup<ChartEditorNoteSprite>;

  /**
   * The sprite group containing the song events.
   * Only displays a subset of the data from `currentSongChartEventData`,
   * and kills events that are off-screen to be recycled later.
   */
  var renderedEvents:FlxTypedSpriteGroup<ChartEditorEventSprite>;

  var renderedSelectionSquares:FlxTypedSpriteGroup<FlxSprite>;

  var playbarHead:Slider;

  public function new()
  {
    // Load the HaxeUI XML file.
    super(CHART_EDITOR_LAYOUT);
  }

  override function create():Void
  {
    // Get rid of any music from the previous state.
    FlxG.sound.music.stop();

    buildDefaultSongData();

    buildBackground();

    currentTheme = ChartEditorTheme.Light;

    buildGrid();
    buildSelectionBox();

    // Add the HaxeUI components after the grid so they're on top.
    super.create();
    buildAdditionalUI();

    // Setup the onClick listeners for the UI after it's been created.
    setupUIListeners();
    setupTurboKeyHandlers();

    setupAutoSave();

    ChartEditorDialogHandler.openWelcomeDialog(this, false);
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
  }

  /**
   * Builds and displays the chart editor grid, including the playhead and cursor.
   */
  function buildGrid():Void
  {
    gridTiledSprite = new FlxTiledSprite(gridBitmap, gridBitmap.width, 1000, false, true);
    gridTiledSprite.x = FlxG.width / 2 - GRID_SIZE * STRUMLINE_SIZE; // Center the grid.
    gridTiledSprite.y = MENU_BAR_HEIGHT + GRID_TOP_PAD; // Push down to account for the menu bar.
    add(gridTiledSprite);

    gridGhostNote = new ChartEditorNoteSprite(this);
    gridGhostNote.alpha = 0.6;
    gridGhostNote.noteData = new SongNoteData(-1, -1, 0, "");
    gridGhostNote.visible = false;
    add(gridGhostNote);

    gridGhostEvent = new ChartEditorEventSprite(this);
    gridGhostEvent.alpha = 0.6;
    gridGhostEvent.eventData = new SongEventData(-1, "", {});
    gridGhostEvent.visible = false;
    add(gridGhostEvent);

    buildNoteGroup();

    gridPlayheadScrollArea = new FlxSprite(gridTiledSprite.x - PLAYHEAD_SCROLL_AREA_WIDTH,
      MENU_BAR_HEIGHT).makeGraphic(PLAYHEAD_SCROLL_AREA_WIDTH, FlxG.height - MENU_BAR_HEIGHT, PLAYHEAD_SCROLL_AREA_COLOR);
    add(gridPlayheadScrollArea);

    // The playhead that show the current position in the song.
    gridPlayhead = new FlxSpriteGroup();
    add(gridPlayhead);

    var playheadWidth = GRID_SIZE * (STRUMLINE_SIZE * 2 + 1) + (PLAYHEAD_SCROLL_AREA_WIDTH * 2);
    var playheadBaseYPos = MENU_BAR_HEIGHT + GRID_TOP_PAD;
    gridPlayhead.setPosition(gridTiledSprite.x, playheadBaseYPos);
    var playheadSprite = new FlxSprite().makeGraphic(playheadWidth, PLAYHEAD_HEIGHT, PLAYHEAD_COLOR);
    playheadSprite.x = -PLAYHEAD_SCROLL_AREA_WIDTH;
    playheadSprite.y = 0;
    gridPlayhead.add(playheadSprite);

    var playheadBlock = ChartEditorThemeHandler.buildPlayheadBlock();
    playheadBlock.x = -PLAYHEAD_SCROLL_AREA_WIDTH;
    playheadBlock.y = -PLAYHEAD_HEIGHT / 2;
    gridPlayhead.add(playheadBlock);

    // Character icons.
    healthIconDad = new HealthIcon('dad');
    healthIconDad.autoUpdate = false;
    healthIconDad.size.set(0.5, 0.5);
    healthIconDad.x = gridTiledSprite.x - 15 - (HealthIcon.HEALTH_ICON_SIZE * 0.5);
    healthIconDad.y = gridTiledSprite.y + 5;
    add(healthIconDad);

    healthIconBF = new HealthIcon('bf');
    healthIconBF.autoUpdate = false;
    healthIconBF.size.set(0.5, 0.5);
    healthIconBF.x = gridTiledSprite.x + GRID_SIZE * (STRUMLINE_SIZE * 2 + 1) + 15;
    healthIconBF.y = gridTiledSprite.y + 5;
    healthIconBF.flipX = true;
    add(healthIconBF);
  }

  function buildSelectionBox():Void
  {
    selectionBoxSprite.scrollFactor.set(0, 0);
    add(selectionBoxSprite);

    setSelectionBoxBounds();
  }

  function setSelectionBoxBounds(?bounds:FlxRect = null):Void
  {
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

  function buildSpectrogram(target:FlxSound):Void
  {
    gridSpectrogram = new PolygonSpectogram(target, SPECTROGRAM_COLOR, FlxG.height / 2, Math.floor(FlxG.height / 2));
    // Halfway through the grid.
    // gridSpectrogram.x = gridTiledSprite.x + STRUMLINE_SIZE * GRID_SIZE;
    // gridSpectrogram.y = gridTiledSprite.y;
    gridSpectrogram.x = 200;
    gridSpectrogram.y = 200;
    gridSpectrogram.visType = STATIC; // We move the spectrogram manually.
    gridSpectrogram.waveAmplitude = 50;
    gridSpectrogram.scrollFactor.set(0, 0);
    add(gridSpectrogram);
  }

  /**
   * Builds the group that will hold all the notes.
   */
  function buildNoteGroup():Void
  {
    renderedNotes = new FlxTypedSpriteGroup<ChartEditorNoteSprite>();
    renderedNotes.setPosition(gridTiledSprite.x, gridTiledSprite.y);
    add(renderedNotes);

    renderedEvents = new FlxTypedSpriteGroup<ChartEditorEventSprite>();
    renderedEvents.setPosition(gridTiledSprite.x, gridTiledSprite.y);
    add(renderedEvents);

    renderedSelectionSquares = new FlxTypedSpriteGroup<FlxSprite>();
    renderedSelectionSquares.setPosition(gridTiledSprite.x, gridTiledSprite.y);
    add(renderedSelectionSquares);
  }

  var playbarHeadLayout:Component;

  function buildAdditionalUI():Void
  {
    playbarHeadLayout = buildComponent(CHART_EDITOR_PLAYBARHEAD_LAYOUT);

    playbarHeadLayout.width = FlxG.width - 8;
    playbarHeadLayout.height = 10;
    playbarHeadLayout.x = 4;
    playbarHeadLayout.y = FlxG.height - 48 - 8;

    playbarHead = playbarHeadLayout.findComponent('playbarHead', Slider);
    playbarHead.allowFocus = false;
    playbarHead.width = FlxG.width;
    playbarHead.height = 10;
    playbarHead.styleString = "padding-left: 0px; padding-right: 0px; border-left: 0px; border-right: 0px;";

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
      scrollPositionInPixels = songLengthInPixels * (playbarHead.value / 100);
      // Update the conductor and audio tracks to match.
      moveSongToScrollPosition();

      // If we were dragging the playhead while the song was playing, resume playing.
      if (playbarHeadDraggingWasPlaying)
      {
        playbarHeadDraggingWasPlaying = false;
        startAudioPlayback();
      }
    }

    add(playbarHeadLayout);
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
    addUIClickListener('menubarItemSaveChartAs', _ -> exportAllSongData());
    addUIClickListener('menubarItemLoadInst', _ -> ChartEditorDialogHandler.openUploadInstDialog(this, true));

    addUIClickListener('menubarItemUndo', _ -> undoLastCommand());

    addUIClickListener('menubarItemRedo', _ -> redoLastCommand());

    addUIClickListener('menubarItemCopy', function(_) {
      // Doesn't use a command because it's not undoable.
      SongDataUtils.writeItemsToClipboard(
        {
          notes: SongDataUtils.buildNoteClipboard(currentNoteSelection),
          events: SongDataUtils.buildEventClipboard(currentEventSelection),
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

    addUIClickListener('menubarItemAbout', _ -> ChartEditorDialogHandler.openAboutDialog(this));

    addUIClickListener('menubarItemUserGuide', _ -> ChartEditorDialogHandler.openUserGuideDialog(this));

    addUIChangeListener('menubarItemDownscroll', event -> isViewDownscroll = event.value);
    setUICheckboxSelected('menubarItemDownscroll', isViewDownscroll);

    addUIChangeListener('menuBarItemThemeLight', function(event:UIEvent) {
      if (event.target.value) currentTheme = ChartEditorTheme.Light;
    });
    setUICheckboxSelected('menuBarItemThemeLight', currentTheme == ChartEditorTheme.Light);

    addUIChangeListener('menuBarItemThemeDark', function(event:UIEvent) {
      if (event.target.value) currentTheme = ChartEditorTheme.Dark;
    });
    setUICheckboxSelected('menuBarItemThemeDark', currentTheme == ChartEditorTheme.Dark);

    addUIChangeListener('menubarItemMetronomeEnabled', event -> shouldPlayMetronome = event.value);
    setUICheckboxSelected('menubarItemMetronomeEnabled', shouldPlayMetronome);

    addUIChangeListener('menubarItemPlayerHitsounds', event -> hitsoundsEnabledPlayer = event.value);
    setUICheckboxSelected('menubarItemPlayerHitsounds', hitsoundsEnabledPlayer);

    addUIChangeListener('menubarItemOpponentHitsounds', event -> hitsoundsEnabledOpponent = event.value);
    setUICheckboxSelected('menubarItemOpponentHitsounds', hitsoundsEnabledOpponent);

    var instVolumeLabel:Label = findComponent('menubarLabelVolumeInstrumental', Label);
    addUIChangeListener('menubarItemVolumeInstrumental', function(event:UIEvent) {
      var volume:Float = event.value / 100.0;
      if (audioInstTrack != null) audioInstTrack.volume = volume;
      instVolumeLabel.text = 'Instrumental - ${Std.int(event.value)}%';
    });

    var vocalsVolumeLabel:Label = findComponent('menubarLabelVolumeVocals', Label);
    addUIChangeListener('menubarItemVolumeVocals', function(event:UIEvent) {
      var volume:Float = event.value / 100.0;
      if (audioVocalTrackGroup != null) audioVocalTrackGroup.volume = volume;
      vocalsVolumeLabel.text = 'Vocals - ${Std.int(event.value)}%';
    });

    var playbackSpeedLabel:Label = findComponent('menubarLabelPlaybackSpeed', Label);
    addUIChangeListener('menubarItemPlaybackSpeed', function(event:UIEvent) {
      var pitch:Float = event.value * 2.0 / 100.0;
      #if FLX_PITCH
      if (audioInstTrack != null) audioInstTrack.pitch = pitch;
      if (audioVocalTrackGroup != null) audioVocalTrackGroup.pitch = pitch;
      #end
      playbackSpeedLabel.text = 'Playback Speed - ${Std.int(pitch * 100) / 100}x';
    });

    addUIChangeListener('menubarItemToggleToolboxTools',
      event -> ChartEditorToolboxHandler.setToolboxState(this, CHART_EDITOR_TOOLBOX_TOOLS_LAYOUT, event.value));
    addUIChangeListener('menubarItemToggleToolboxNotes',
      event -> ChartEditorToolboxHandler.setToolboxState(this, CHART_EDITOR_TOOLBOX_NOTEDATA_LAYOUT, event.value));
    addUIChangeListener('menubarItemToggleToolboxEvents',
      event -> ChartEditorToolboxHandler.setToolboxState(this, CHART_EDITOR_TOOLBOX_EVENTDATA_LAYOUT, event.value));
    addUIChangeListener('menubarItemToggleToolboxDifficulty',
      event -> ChartEditorToolboxHandler.setToolboxState(this, CHART_EDITOR_TOOLBOX_DIFFICULTY_LAYOUT, event.value));
    addUIChangeListener('menubarItemToggleToolboxMetadata',
      event -> ChartEditorToolboxHandler.setToolboxState(this, CHART_EDITOR_TOOLBOX_METADATA_LAYOUT, event.value));
    addUIChangeListener('menubarItemToggleToolboxCharacters',
      event -> ChartEditorToolboxHandler.setToolboxState(this, CHART_EDITOR_TOOLBOX_CHARACTERS_LAYOUT, event.value));
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
    exportAllSongData(true, true);
    #end
  }

  function onWindowClose(exitCode:Int):Void
  {
    trace('Window exited with exit code: $exitCode');
    trace('Should save chart? $saveDataDirty');

    if (saveDataDirty)
    {
      exportAllSongData(true);
    }
  }

  function cleanupAutoSave():Void
  {
    WindowUtil.windowExit.remove(onWindowClose);
  }

  public override function update(elapsed:Float):Void
  {
    // dispatchEvent gets called here.
    super.update(elapsed);

    FlxG.mouse.visible = true;

    // These ones happen even if the modal dialog is open.
    handleMusicPlayback();
    handleNoteDisplay();

    // These ones only happen if the modal dialog is not open.
    handleScrollKeybinds();
    // handleZoom();
    // handleSnap();
    handleCursor();

    handleMenubar();
    handleToolboxes();
    handlePlaybar();
    handlePlayhead();

    handleFileKeybinds();
    handleEditKeybinds();
    handleViewKeybinds();
    handleHelpKeybinds();

    // DEBUG
    #if debug
    if (FlxG.keys.justPressed.F)
    {
      NotificationManager.instance.addNotification(
        {
          title: 'This is a Notification',
          body: 'Hello, world!',
          type: NotificationType.Info,
          expiryMs: NOTIFICATION_DISMISS_TIME
          // styleNames: 'cssStyleName',
          // icon: 'assetPath',
          // actions: ['action1', 'action2']
        });
    }

    if (FlxG.keys.justPressed.E)
    {
      currentSongMetadata.timeChanges[0].timeSignatureNum = (currentSongMetadata.timeChanges[0].timeSignatureNum == 4 ? 3 : 4);
    }
    #end

    // Right align the BF health icon.

    // Base X position to the right of the grid.
    var baseHealthIconXPos = gridTiledSprite.x + GRID_SIZE * (STRUMLINE_SIZE * 2 + 1) + 15;
    // Will be 0 when not bopping. When bopping, will increase to push the icon left.
    var healthIconOffset = healthIconBF.width - (HealthIcon.HEALTH_ICON_SIZE * 0.5);
    healthIconBF.x = baseHealthIconXPos - healthIconOffset;
  }

  /**
   * Beat hit while the song is playing.
   */
  override function beatHit():Bool
  {
    // dispatchEvent gets called here.
    if (!super.beatHit()) return false;

    if (shouldPlayMetronome && (audioInstTrack != null && audioInstTrack.playing))
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
      healthIconDad.onStepHit(Conductor.currentStep);
      healthIconBF.onStepHit(Conductor.currentStep);
    }

    // if (shouldPlayMetronome)
    // 	playMetronomeTick(false);

    return true;
  }

  /**
   * Handle keybinds for scrolling the chart editor grid.
  **/
  function handleScrollKeybinds():Void
  {
    // Don't scroll when the cursor is over the UI.
    if (isCursorOverHaxeUI) return;

    // Amount to scroll the grid.
    var scrollAmount:Float = 0;
    // Amount to scroll the playhead relative to the grid.
    var playheadAmount:Float = 0;
    var shouldPause:Bool = false;

    // Up Arrow = Scroll Up
    if (upKeyHandler.activated)
    {
      scrollAmount = -GRID_SIZE * 0.25 * 5.0;
      shouldPause = true;
    }
    // Down Arrow = Scroll Down
    if (downKeyHandler.activated)
    {
      scrollAmount = GRID_SIZE * 0.25 * 5.0;
      shouldPause = true;
    }

    // PAGE UP = Jump Up 1 Measure
    if (pageUpKeyHandler.activated)
    {
      scrollAmount = -GRID_SIZE * 4 * Conductor.beatsPerMeasure;
      shouldPause = true;
    }
    if (playbarButtonPressed == 'playbarBack')
    {
      playbarButtonPressed = '';
      scrollAmount = -GRID_SIZE * 4 * Conductor.beatsPerMeasure;
      shouldPause = true;
    }

    // PAGE DOWN = Jump Down 1 Measure
    if (pageDownKeyHandler.activated)
    {
      scrollAmount = GRID_SIZE * 4 * Conductor.beatsPerMeasure;
      shouldPause = true;
    }
    if (playbarButtonPressed == 'playbarForward')
    {
      playbarButtonPressed = '';
      scrollAmount = GRID_SIZE * 4 * Conductor.beatsPerMeasure;
      shouldPause = true;
    }

    // Mouse Wheel = Scroll
    if (FlxG.mouse.wheel != 0 && !FlxG.keys.pressed.CONTROL)
    {
      scrollAmount = -10 * FlxG.mouse.wheel;
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

    // Apply the scroll amount.
    this.scrollPositionInPixels += scrollAmount;
    this.playheadPositionInPixels += playheadAmount;

    // Resync the conductor and audio tracks.
    if (scrollAmount != 0 || playheadAmount != 0) moveSongToScrollPosition();
    if (shouldPause) stopAudioPlayback();
  }

  function handleZoom():Void
  {
    if (FlxG.keys.justPressed.MINUS)
    {
      currentZoomLevel /= 2;

      // Update the grid.
      ChartEditorThemeHandler.updateTheme(this);
      // Update the note positions.
      noteDisplayDirty = true;
    }

    if (FlxG.keys.justPressed.PLUS)
    {
      currentZoomLevel *= 2;

      // Update the grid.
      ChartEditorThemeHandler.updateTheme(this);
      // Update the note positions.
      noteDisplayDirty = true;
    }
  }

  function handleSnap():Void
  {
    if (FlxG.keys.justPressed.LEFT)
    {
      noteSnapQuantIndex--;
    }

    if (FlxG.keys.justPressed.RIGHT)
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
    var shouldHandleCursor = !isCursorOverHaxeUI || (selectionBoxStartPos != null);
    var eventColumn = (STRUMLINE_SIZE * 2 + 1) - 1;

    if (shouldHandleCursor)
    {
      var overlapsGrid:Bool = FlxG.mouse.overlaps(gridTiledSprite);

      // Cursor position relative to the grid.
      var cursorX:Float = FlxG.mouse.screenX - gridTiledSprite.x;
      var cursorY:Float = FlxG.mouse.screenY - gridTiledSprite.y;

      var overlapsSelectionBorder = overlapsGrid
        && (cursorX % 40) < (GRID_SELECTION_BORDER_WIDTH / 2)
          || (cursorX % 40) > (40 - (GRID_SELECTION_BORDER_WIDTH / 2))
            || (cursorY % 40) < (GRID_SELECTION_BORDER_WIDTH / 2) || (cursorY % 40) > (40 - (GRID_SELECTION_BORDER_WIDTH / 2));

      if (FlxG.mouse.justPressed)
      {
        if (FlxG.mouse.overlaps(gridPlayheadScrollArea))
        {
          gridPlayheadScrollAreaPressed = true;
        }
        else if (!overlapsGrid || overlapsSelectionBorder)
        {
          selectionBoxStartPos = new FlxPoint(FlxG.mouse.screenX, FlxG.mouse.screenY);
        }
      }

      if (gridPlayheadScrollAreaPressed)
      {
        Cursor.cursorMode = Grabbing;
      }
      else if (FlxG.mouse.overlaps(gridPlayheadScrollArea))
      {
        Cursor.cursorMode = Pointer;
      }
      else
      {
        Cursor.cursorMode = Default;
      }

      if (gridPlayheadScrollAreaPressed && FlxG.mouse.released)
      {
        gridPlayheadScrollAreaPressed = false;
      }

      if (gridPlayheadScrollAreaPressed)
      {
        // Clicked on the playhead scroll area.
        // Move the playhead to the cursor position.
        this.playheadPositionInPixels = FlxG.mouse.screenY - MENU_BAR_HEIGHT - GRID_TOP_PAD;
        moveSongToScrollPosition();
      }

      // Cursor position snapped to the grid.

      // The song position of the cursor, in steps.
      var cursorFractionalStep:Float = cursorY / GRID_SIZE / (16 / noteSnapQuant);
      var cursorStep:Int = Std.int(Math.floor(cursorFractionalStep));
      var cursorMs:Float = cursorStep * Conductor.stepLengthMs * (16 / noteSnapQuant);
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
            var cursorMsStart:Float = cursorStepStart * Conductor.stepLengthMs;
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
            // Render the selection box.
            var selectionRect = new FlxRect();
            selectionRect.x = Math.min(FlxG.mouse.screenX, selectionBoxStartPos.x);
            selectionRect.y = Math.min(FlxG.mouse.screenY, selectionBoxStartPos.y);
            selectionRect.width = Math.abs(FlxG.mouse.screenX - selectionBoxStartPos.x);
            selectionRect.height = Math.abs(FlxG.mouse.screenY - selectionBoxStartPos.y);
            setSelectionBoxBounds(selectionRect);
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
            var highlightedNote:ChartEditorNoteSprite = renderedNotes.members.find(function(note:ChartEditorNoteSprite):Bool {
              // If note.alive is false, the note is dead and awaiting recycling.
              return note.alive && FlxG.mouse.overlaps(note);
            });
            var highlightedEvent:ChartEditorEventSprite = null;
            if (highlightedNote == null)
            {
              highlightedEvent = renderedEvents.members.find(function(event:ChartEditorEventSprite):Bool {
                return event.alive && FlxG.mouse.overlaps(event);
              });
            }

            if (FlxG.keys.pressed.CONTROL)
            {
              if (highlightedNote != null)
              {
                // Handle the case of clicking on a sustain piece.
                highlightedNote = highlightedNote.getBaseNoteSprite();
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
              else if (highlightedEvent != null)
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
              if (highlightedNote != null)
              {
                // Click a note to select it.
                performCommand(new SetItemSelectionCommand([highlightedNote.noteData], [], currentNoteSelection, currentEventSelection));
              }
              else if (highlightedEvent != null)
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
            // If we clicked and released outside the grid, do nothing.
          }
        }
      }
      else if (currentPlaceNoteData != null)
      {
        // Handle extending the note as you drag.

        // Since use Math.floor and stepLengthMs here, the hold notes will be beat snapped.
        var dragLengthSteps:Float = Math.floor((cursorMs - currentPlaceNoteData.time) / Conductor.stepLengthMs);

        // Without this, the newly placed note feels too short compared to the user's input.
        var INCREMENT:Float = 1.0;
        var dragLengthMs:Float = (dragLengthSteps + INCREMENT) * Conductor.stepLengthMs;

        // TODO: Add and update some sort of preview?

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
            var highlightedNote:ChartEditorNoteSprite = renderedNotes.members.find(function(note:ChartEditorNoteSprite):Bool {
              // If note.alive is false, the note is dead and awaiting recycling.
              return note.alive && FlxG.mouse.overlaps(note);
            });
            var highlightedEvent:ChartEditorEventSprite = null;
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
              if (highlightedNote != null)
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
              else if (highlightedEvent != null)
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
              if (highlightedNote != null)
              {
                // Click a note to select it.
                performCommand(new SetItemSelectionCommand([highlightedNote.noteData], [], currentNoteSelection, currentEventSelection));
              }
              else if (highlightedEvent != null)
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
                  var newEventData:SongEventData = new SongEventData(cursorMs, selectedEventKind, selectedEventData);

                  performCommand(new AddEventsCommand([newEventData], FlxG.keys.pressed.CONTROL));
                }
                else
                {
                  // Create a note and place it in the chart.
                  var newNoteData:SongNoteData = new SongNoteData(cursorMs, cursorColumn, 0, selectedNoteKind);

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
          var highlightedNote:ChartEditorNoteSprite = renderedNotes.members.find(function(note:ChartEditorNoteSprite):Bool {
            // If note.alive is false, the note is dead and awaiting recycling.
            return note.alive && FlxG.mouse.overlaps(note);
          });
          var highlightedEvent:ChartEditorEventSprite = null;
          if (highlightedNote == null)
          {
            highlightedEvent = renderedEvents.members.find(function(event:ChartEditorEventSprite):Bool {
              // If event.alive is false, the event is dead and awaiting recycling.
              return event.alive && FlxG.mouse.overlaps(event);
            });
          }

          if (highlightedNote != null)
          {
            // Handle the case of clicking on a sustain piece.
            highlightedNote = highlightedNote.getBaseNoteSprite();
            // Remove the note.
            performCommand(new RemoveNotesCommand([highlightedNote.noteData]));
          }
          else if (highlightedEvent != null)
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
          Cursor.cursorMode = Pointer;

          // Indicate that we can place a note here.

          if (cursorColumn == eventColumn)
          {
            gridGhostEvent.visible = true;
            gridGhostNote.visible = false;

            if (selectedEventKind != gridGhostEvent.eventData.event)
            {
              gridGhostEvent.eventData.event = selectedEventKind;
            }

            gridGhostEvent.eventData.time = cursorMs;
            gridGhostEvent.updateEventPosition(renderedEvents);
          }
          else
          {
            gridGhostEvent.visible = false;
            gridGhostNote.visible = true;

            if (cursorColumn != gridGhostNote.noteData.data || selectedNoteKind != gridGhostNote.noteData.kind)
            {
              gridGhostNote.noteData.kind = selectedNoteKind;
              gridGhostNote.noteData.data = cursorColumn;
              gridGhostNote.playNoteAnimation();
            }

            gridGhostNote.noteData.time = cursorMs;
            gridGhostNote.updateNotePosition(renderedNotes);
          }

          // gridCursor.visible = true;
          // // X and Y are the cursor position relative to the grid, snapped to the top left of the grid square.
          // gridCursor.x = Math.floor(cursorX / GRID_SIZE) * GRID_SIZE + gridTiledSprite.x + (GRID_SELECTION_BORDER_WIDTH / 2);
          // gridCursor.y = cursorStep * GRID_SIZE + gridTiledSprite.y + (GRID_SELECTION_BORDER_WIDTH / 2);
        }
        else
        {
          gridGhostNote.visible = false;
          gridGhostEvent.visible = false;
          Cursor.cursorMode = Default;
        }
      }
    }
    else
    {
      gridGhostNote.visible = false;
      gridGhostEvent.visible = false;
    }

    if (isCursorOverHaxeUIButton && Cursor.cursorMode == Default)
    {
      Cursor.cursorMode = Pointer;
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

      // Calculate the view bounds.
      var viewAreaTop:Float = this.scrollPositionInPixels - GRID_TOP_PAD;
      var viewHeight:Float = (FlxG.height - MENU_BAR_HEIGHT);
      var viewAreaBottom:Float = this.scrollPositionInPixels + viewHeight;

      // Remove notes that are no longer visible and list the ones that are.
      var displayedNoteData:Array<SongNoteData> = [];
      for (noteSprite in renderedNotes.members)
      {
        if (noteSprite == null || !noteSprite.exists || !noteSprite.visible) continue;

        if (!noteSprite.isNoteVisible(viewAreaBottom, viewAreaTop))
        {
          // This sprite is off-screen.
          // Kill the note sprite and recycle it.
          noteSprite.noteData = null;
        }
        else if (currentSongChartNoteData.indexOf(noteSprite.noteData) == -1)
        {
          // This note was deleted.
          // Kill the note sprite and recycle it.
          noteSprite.noteData = null;
        }
        else if (noteSprite.noteData.length > 0 && (noteSprite.parentNoteSprite == null && noteSprite.childNoteSprite == null))
        {
          // Note was extended.
          // Kill the note sprite and recycle it.
          noteSprite.noteData = null;
        }
        else if (noteSprite.noteData.length == 0 && (noteSprite.parentNoteSprite != null || noteSprite.childNoteSprite != null))
        {
          // Note was shortened.
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

      // Remove events that are no longer visible and list the ones that are.
      var displayedEventData:Array<SongEventData> = [];
      for (eventSprite in renderedEvents.members)
      {
        if (eventSprite == null || !eventSprite.exists || !eventSprite.visible) continue;

        if (!eventSprite.isEventVisible(viewAreaBottom, viewAreaTop))
        {
          // This sprite is off-screen.
          // Kill the event sprite and recycle it.
          eventSprite.eventData = null;
        }
        else if (currentSongChartEventData.indexOf(eventSprite.eventData) == -1)
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

      // Add notes that are now visible.
      for (noteData in currentSongChartNoteData)
      {
        // Remember if we are already displaying this note.
        if (displayedNoteData.indexOf(noteData) != -1)
        {
          continue;
        }

        // Get the position the note should be at.
        var noteTimePixels:Float = noteData.time / Conductor.stepLengthMs * GRID_SIZE;

        // Make sure the note appears when scrolling up.
        var modifiedViewAreaTop = viewAreaTop - GRID_SIZE;

        if (noteTimePixels < modifiedViewAreaTop || noteTimePixels > viewAreaBottom) continue;

        // Else, this note is visible and we need to render it!

        // Get a note sprite from the pool.
        // If we can reuse a deleted note, do so.
        // If a new note is needed, call buildNoteSprite.
        var noteSprite:ChartEditorNoteSprite = renderedNotes.recycle(() -> new ChartEditorNoteSprite(this));
        noteSprite.parentState = this;

        // The note sprite handles animation playback and positioning.
        noteSprite.noteData = noteData;

        // Setting note data resets position relative to the grid so we fix that.
        noteSprite.x += renderedNotes.x;
        noteSprite.y += renderedNotes.y;

        if (noteSprite.noteData.length > 0)
        {
          // If the note is a hold, we need to make sure it's long enough.
          var noteLengthMs:Float = noteSprite.noteData.length;
          var noteLengthSteps:Float = (noteLengthMs / Conductor.stepLengthMs);
          var lastNoteSprite:ChartEditorNoteSprite = noteSprite;

          while (noteLengthSteps > 0)
          {
            if (noteLengthSteps <= 1.0)
            {
              // Last note in the hold.
              // TODO: We may need to make it shorter and clip it visually.
            }

            var nextNoteSprite:ChartEditorNoteSprite = renderedNotes.recycle(ChartEditorNoteSprite);
            nextNoteSprite.parentState = this;
            nextNoteSprite.parentNoteSprite = lastNoteSprite;
            lastNoteSprite.childNoteSprite = nextNoteSprite;

            lastNoteSprite = nextNoteSprite;

            noteLengthSteps -= 1;
          }

          // Make sure the last note sprite shows the end cap properly.
          lastNoteSprite.childNoteSprite = null;

          // var noteLengthPixels:Float = (noteLengthMs / Conductor.stepLengthMs + 1) * GRID_SIZE;
          // add(new FlxSprite(noteSprite.x, noteSprite.y - renderedNotes.y + noteLengthPixels).makeGraphic(40, 2, 0xFFFF0000));
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

        // Get the position the event should be at.
        var eventTimePixels:Float = eventData.time / Conductor.stepLengthMs * GRID_SIZE;

        // Make sure the event appears when scrolling up.
        var modifiedViewAreaTop = viewAreaTop - GRID_SIZE;

        if (eventTimePixels < modifiedViewAreaTop || eventTimePixels > viewAreaBottom) continue;

        // Else, this event is visible and we need to render it!

        // Get an event sprite from the pool.
        // If we can reuse a deleted event, do so.
        // If a new event is needed, call buildEventSprite.
        var eventSprite:ChartEditorEventSprite = renderedEvents.recycle(() -> new ChartEditorEventSprite(this));
        eventSprite.parentState = this;

        // The event sprite handles animation playback and positioning.
        eventSprite.eventData = eventData;

        // Setting event data resets position relative to the grid so we fix that.
        eventSprite.x += renderedEvents.x;
        eventSprite.y += renderedEvents.y;
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
        if (isNoteSelected(noteSprite.noteData) && noteSprite.parentNoteSprite == null)
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
      renderedNotes.sort(FlxSort.byY, FlxSort.DESCENDING);

      // Sort the events DESCENDING. This keeps the sustain behind the associated note.
      renderedEvents.sort(FlxSort.byY, FlxSort.DESCENDING);
    }
  }

  function buildSelectionSquare():FlxSprite
  {
    return new FlxSprite().loadGraphic(selectionSquareBitmap);
  }

  /**
   * Handles display elements for the playbar at the bottom.
   */
  function handlePlaybar():Void
  {
    // Make sure the playbar is never nudged out of the correct spot.
    playbarHeadLayout.x = 4;
    playbarHeadLayout.y = FlxG.height - 48 - 8;

    var songPos = Conductor.songPosition;
    var songRemaining = songLengthInMs - songPos;

    // Move the playhead to match the song position, if we aren't dragging it.
    if (!playbarHeadDragging)
    {
      var songPosPercent:Float = songPos / songLengthInMs;
      playbarHead.value = songPosPercent * 100;
    }

    var songPosSeconds:String = Std.string(Math.floor((songPos / 1000) % 60)).lpad('0', 2);
    var songPosMinutes:String = Std.string(Math.floor((songPos / 1000) / 60)).lpad('0', 2);
    var songPosString:String = '${songPosMinutes}:${songPosSeconds}';

    setUIValue('playbarSongPos', songPosString);

    var songRemainingSeconds:String = Std.string(Math.floor((songRemaining / 1000) % 60)).lpad('0', 2);
    var songRemainingMinutes:String = Std.string(Math.floor((songRemaining / 1000) / 60)).lpad('0', 2);
    var songRemainingString:String = '-${songRemainingMinutes}:${songRemainingSeconds}';

    setUIValue('playbarSongRemaining', songRemainingString);
  }

  /**
   * Handle keybinds for File menu items.
   */
  function handleFileKeybinds():Void
  {
    // CTRL + Q = Quit to Menu
    if (FlxG.keys.pressed.CONTROL && FlxG.keys.justPressed.Q)
    {
      FlxG.switchState(new MainMenuState());
    }
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
  function handleViewKeybinds():Void {}

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
      var difficultyToolbox = ChartEditorToolboxHandler.getToolbox(this, CHART_EDITOR_TOOLBOX_DIFFICULTY_LAYOUT);
      if (difficultyToolbox == null) return;

      var treeView:TreeView = difficultyToolbox.findComponent('difficultyToolboxTree');
      if (treeView == null) return;

      // Clear the tree view so we can rebuild it.
      treeView.clearNodes();

      var treeSong = treeView.addNode({id: 'stv_song', text: 'S: $currentSongName', icon: "haxeui-core/styles/default/haxeui_tiny.png"});
      treeSong.expanded = true;

      for (curVariation in availableVariations)
      {
        var variationMetadata:SongMetadata = songMetadata.get(curVariation);

        var treeVariation = treeSong.addNode(
          {
            id: 'stv_variation_$curVariation',
            text: 'V: ${curVariation.toTitleCase()}',
            // icon: "haxeui-core/styles/default/haxeui_tiny.png"
          });
        treeVariation.expanded = true;

        var difficultyList = variationMetadata.playData.difficulties;

        for (difficulty in difficultyList)
        {
          var treeDifficulty = treeVariation.addNode(
            {
              id: 'stv_difficulty_${curVariation}_$difficulty',
              text: 'D: ${difficulty.toTitleCase()}',
              // icon: "haxeui-core/styles/default/haxeui_tiny.png"
            });
        }
      }

      treeView.onChange = onChangeTreeDifficulty;
      treeView.selectedNode = getCurrentTreeDifficultyNode();
    }
  }

  function handlePlayerPreviewToolbox():Void
  {
    // Manage the Select Difficulty tree view.
    var charPreviewToolbox = ChartEditorToolboxHandler.getToolbox(this, CHART_EDITOR_TOOLBOX_PLAYER_PREVIEW_LAYOUT);
    if (charPreviewToolbox == null) return;

    var charPlayer:CharacterPlayer = charPreviewToolbox.findComponent('charPlayer');
    if (charPlayer == null) return;

    currentPlayerCharacterPlayer = charPlayer;
  }

  function handleOpponentPreviewToolbox():Void
  {
    // Manage the Select Difficulty tree view.
    var charPreviewToolbox = ChartEditorToolboxHandler.getToolbox(this, CHART_EDITOR_TOOLBOX_OPPONENT_PREVIEW_LAYOUT);
    if (charPreviewToolbox == null) return;

    var charPlayer:CharacterPlayer = charPreviewToolbox.findComponent('charPlayer');
    if (charPlayer == null) return;

    currentOpponentCharacterPlayer = charPlayer;
  }

  override function dispatchEvent(event:ScriptEvent):Void
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

  function getCurrentTreeDifficultyNode():TreeViewNode
  {
    var treeView:TreeView = findComponent('difficultyToolboxTree');

    if (treeView == null) return null;

    var result = treeView.findNodeByPath('stv_song/stv_variation_$selectedVariation/stv_difficulty_${selectedVariation}_$selectedDifficulty', 'id');

    if (result == null) return null;

    return result;
  }

  function onChangeTreeDifficulty(event:UIEvent):Void
  {
    // Get the newly selected node.
    var treeView:TreeView = cast event.target;
    var targetNode:TreeViewNode = treeView.selectedNode;

    if (targetNode == null)
    {
      trace('No target node!');
      // Reset the user's selection.
      treeView.selectedNode = getCurrentTreeDifficultyNode();
      return;
    }

    switch (targetNode.data.id.split('_')[1])
    {
      case 'difficulty':
        var variation = targetNode.data.id.split('_')[2];
        var difficulty = targetNode.data.id.split('_')[3];

        if (variation != null && difficulty != null)
        {
          trace('Changing difficulty to $variation:$difficulty');
          selectedVariation = variation;
          selectedDifficulty = difficulty;
        }
      // case 'song':
      // case 'variation':
      default:
        // Reset the user's selection.
        trace('Selected wrong node type, resetting selection.');
        treeView.selectedNode = getCurrentTreeDifficultyNode();
    }
  }

  function addDifficulty(variation:String):Void {}

  function addVariation(variationId:String):Void
  {
    // Create a new variation with the specified ID.
    songMetadata.set(variationId, currentSongMetadata.clone(variationId));
    // Switch to the new variation.
    selectedVariation = variationId;
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
    //
    if (notePreviewDirty)
    {
      notePreviewDirty = false;

      var PREVIEW_WIDTH:Int = GRID_SIZE * 2;
      var STEP_HEIGHT:Int = 1;
      var PREVIEW_HEIGHT:Int = Std.int(Conductor.getTimeInSteps(audioInstTrack.length) * STEP_HEIGHT);

      notePreviewBitmap = new BitmapData(PREVIEW_WIDTH, PREVIEW_HEIGHT, true);
      notePreviewBitmap.fillRect(new Rectangle(0, 0, PREVIEW_WIDTH, PREVIEW_HEIGHT), PREVIEW_BG_COLOR);
    }
  }

  /**
   * Perform a spot update on the note preview, by editing the note preview
   * only where necessary. More efficient than a full update.
   */
  function updateNotePreview(note:SongNoteData, ?deleteNote:Bool = false):Void {}

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
      var undoButton:MenuItem = findComponent('menubarItemUndo', MenuItem);

      if (undoButton != null)
      {
        if (undoHistory.length == 0)
        {
          // Disable the Undo button.
          undoButton.disabled = true;
          undoButton.text = "Undo";
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
        trace("undoButton is null");
      }

      var redoButton:MenuItem = findComponent('menubarItemRedo', MenuItem);

      if (redoButton != null)
      {
        if (redoHistory.length == 0)
        {
          // Disable the Redo button.
          redoButton.disabled = true;
          redoButton.text = "Redo";
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
        trace("redoButton is null");
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

        var oldStepTime = Conductor.currentStepTime;
        var oldSongPosition = Conductor.songPosition;
        Conductor.update(audioInstTrack.time);
        handleHitsounds(oldSongPosition, Conductor.songPosition);
        // Resync vocals.
        if (Math.abs(audioInstTrack.time - audioVocalTrackGroup.time) > 100) audioVocalTrackGroup.time = audioInstTrack.time;
        var diffStepTime = Conductor.currentStepTime - oldStepTime;

        // Move the playhead.
        playheadPositionInPixels += diffStepTime * GRID_SIZE;

        // We don't move the song to scroll position, or update the note sprites.
      }
      else
      {
        // Else, move the entire view.
        var oldSongPosition = Conductor.songPosition;
        Conductor.update(audioInstTrack.time);
        handleHitsounds(oldSongPosition, Conductor.songPosition);
        // Resync vocals.
        if (audioVocalTrackGroup != null
          && Math.abs(audioInstTrack.time - audioVocalTrackGroup.time) > 100) audioVocalTrackGroup.time = audioInstTrack.time;

        // We need time in fractional steps here to allow the song to actually play.
        // Also account for a potentially offset playhead.
        scrollPositionInPixels = Conductor.currentStepTime * GRID_SIZE - playheadPositionInPixels;

        // DO NOT move song to scroll position here specifically.

        // We need to update the note sprites.
        noteDisplayDirty = true;
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
      if (noteData.time < oldSongPosition) // Note is in the past.
        continue;

      if (noteData.time >= newSongPosition) // Note is in the future.
        return;

      // Note was just hit.

      // Character preview.

      // Why does NOTESCRIPTEVENT TAKE A SPRITE AAAAA
      var tempNote:Note = new Note(noteData.time, noteData.data, null, false, NORMAL);
      tempNote.mustPress = noteData.getMustHitNote();
      tempNote.data.sustainLength = noteData.length;
      tempNote.data.noteKind = noteData.kind;
      tempNote.scrollFactor.set(0, 0);
      var event:NoteScriptEvent = new NoteScriptEvent(ScriptEvent.NOTE_HIT, tempNote, 1, true);
      dispatchEvent(event);

      // Calling event.cancelEvent() skips all the other logic! Neat!
      if (event.eventCanceled) continue;

      // Hitsounds.
      switch (noteData.getStrumlineIndex())
      {
        case 0: // Player
          if (hitsoundsEnabledPlayer) playSound(Paths.sound('funnyNoise/funnyNoise-09'));
        case 1: // Opponent
          if (hitsoundsEnabledOpponent) playSound(Paths.sound('funnyNoise/funnyNoise-010'));
      }
    }
  }

  function startAudioPlayback():Void
  {
    if (audioInstTrack != null) audioInstTrack.play();
    if (audioVocalTrackGroup != null) audioVocalTrackGroup.play();
    if (audioVocalTrackGroup != null) audioVocalTrackGroup.play();

    setComponentText('playbarPlay', '||');
  }

  function stopAudioPlayback():Void
  {
    if (audioInstTrack != null) audioInstTrack.pause();
    if (audioVocalTrackGroup != null) audioVocalTrackGroup.pause();
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
    // TODO: Add the ability to switch modes.
    if (true)
    {
      if (FlxG.keys.justPressed.ONE) placeNoteAtPlayhead(0);
      if (FlxG.keys.justPressed.TWO) placeNoteAtPlayhead(1);
      if (FlxG.keys.justPressed.THREE) placeNoteAtPlayhead(2);
      if (FlxG.keys.justPressed.FOUR) placeNoteAtPlayhead(3);
      if (FlxG.keys.justPressed.FIVE) placeNoteAtPlayhead(4);
      if (FlxG.keys.justPressed.SIX) placeNoteAtPlayhead(5);
      if (FlxG.keys.justPressed.SEVEN) placeNoteAtPlayhead(6);
      if (FlxG.keys.justPressed.EIGHT) placeNoteAtPlayhead(7);
    }
  }

  function placeNoteAtPlayhead(column:Int):Void
  {
    var gridSnappedPlayheadPos = scrollPositionInPixels - (scrollPositionInPixels % GRID_SIZE);
  }

  function set_scrollPositionInPixels(value:Float):Float
  {
    if (value < 0)
    {
      // If we're scrolling up, and we hit the top,
      // but the playhead is in the middle, move the playhead up.
      if (playheadPositionInPixels > 0)
      {
        var amount = scrollPositionInPixels - value;
        playheadPositionInPixels -= amount;
      }

      value = 0;
    }

    if (value > songLengthInPixels) value = songLengthInPixels;

    if (value == scrollPositionInPixels) return value;

    this.scrollPositionInPixels = value;

    // Move the grid sprite to the correct position.
    if (isViewDownscroll)
    {
      gridTiledSprite.y = -scrollPositionInPixels + (MENU_BAR_HEIGHT + GRID_TOP_PAD);
    }
    else
    {
      gridTiledSprite.y = -scrollPositionInPixels + (MENU_BAR_HEIGHT + GRID_TOP_PAD);
    }
    // Move the rendered notes to the correct position.
    renderedNotes.setPosition(gridTiledSprite.x, gridTiledSprite.y);
    renderedEvents.setPosition(gridTiledSprite.x, gridTiledSprite.y);
    renderedSelectionSquares.setPosition(gridTiledSprite.x, gridTiledSprite.y);
    if (gridSpectrogram != null)
    {
      // Move the spectrogram to the correct position.
      gridSpectrogram.y = gridTiledSprite.y;
      gridSpectrogram.setPosition(0, 0);
    }

    return this.scrollPositionInPixels;
  }

  function get_playheadPositionInPixels():Float
  {
    return this.playheadPositionInPixels;
  }

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
   * Loads an instrumental from an absolute file path, replacing the current instrumental.
   *
   * @param path The absolute path to the audio file.
   * @return Success or failure.
   */
  public function loadInstrumentalFromPath(path:Path):Bool
  {
    #if sys
    // Validate file extension.
    if (!SUPPORTED_MUSIC_FORMATS.contains(path.ext))
    {
      return false;
    }

    var fileBytes:haxe.io.Bytes = sys.io.File.getBytes(path.toString());
    return loadInstrumentalFromBytes(fileBytes, '${path.file}.${path.ext}');
    #else
    trace("[WARN] This platform can't load audio from a file path, you'll need to fetch the bytes some other way.");
    return false;
    #end
  }

  /**
   * Loads an instrumental from audio byte data, replacing the current instrumental.
   * @param bytes The audio byte data.
   * @param fileName The name of the file, if available. Used for notifications.
   * @return Success or failure.
   */
  public function loadInstrumentalFromBytes(bytes:haxe.io.Bytes, fileName:String = null):Bool
  {
    var openflSound:openfl.media.Sound = new openfl.media.Sound();
    openflSound.loadCompressedDataFromByteArray(openfl.utils.ByteArray.fromBytes(bytes), bytes.length);
    audioInstTrack = FlxG.sound.load(openflSound, 1.0, false);
    audioInstTrack.autoDestroy = false;
    audioInstTrack.pause();

    postLoadInstrumental();

    return true;
  }

  /**
   * Loads an instrumental from an OpenFL asset, replacing the current instrumental.
   * @param path The path to the asset. Use `Paths` to build this.
   * @return Success or failure.
   */
  public function loadInstrumentalFromAsset(path:String):Bool
  {
    var instTrack:FlxSound = FlxG.sound.load(path, 1.0, false);
    if (instTrack != null)
    {
      audioInstTrack = instTrack;

      postLoadInstrumental();
      return true;
    }

    return false;
  }

  function postLoadInstrumental():Void
  {
    // Prevent the time from skipping back to 0 when the song ends.
    audioInstTrack.onComplete = function() {
      if (audioInstTrack != null) audioInstTrack.pause();
      if (audioVocalTrackGroup != null) audioVocalTrackGroup.pause();
    };

    songLengthInMs = audioInstTrack.length;

    gridTiledSprite.height = songLengthInPixels;
    if (gridSpectrogram != null)
    {
      gridSpectrogram.setSound(audioInstTrack);
      gridSpectrogram.generateSection(0, songLengthInMs / 1000);
    }

    scrollPositionInPixels = 0;
    playheadPositionInPixels = 0;
    moveSongToScrollPosition();
  }

  /**
   * Loads a vocal track from an absolute file path.
   * @param path The absolute path to the audio file.
   * @param charKey The character to load the vocal track for.
   */
  public function loadVocalsFromPath(path:Path, charKey:String = null):Bool
  {
    #if sys
    var fileBytes:haxe.io.Bytes = sys.io.File.getBytes(path.toString());
    return loadVocalsFromBytes(fileBytes, charKey);
    #else
    trace("[WARN] This platform can't load audio from a file path, you'll need to fetch the bytes some other way.");
    return false;
    #end
  }

  public function loadVocalsFromAsset(path:String, charKey:String = null):Bool
  {
    var vocalTrack:FlxSound = FlxG.sound.load(path, 1.0, false);
    if (vocalTrack != null)
    {
      audioVocalTrackGroup.add(vocalTrack);
      return true;
    }
    return false;
  }

  /**
   * Loads a vocal track from audio byte data.
   */
  public function loadVocalsFromBytes(bytes:haxe.io.Bytes, charKey:String = null):Bool
  {
    var openflSound = new openfl.media.Sound();
    openflSound.loadCompressedDataFromByteArray(openfl.utils.ByteArray.fromBytes(bytes), bytes.length);
    var vocalTrack:FlxSound = FlxG.sound.load(openflSound, 1.0, false);
    audioVocalTrackGroup.add(vocalTrack);
    return true;
  }

  /**
   * Fetch's a song's existing chart and audio and loads it, replacing the current song.
   */
  public function loadSongAsTemplate(songId:String):Void
  {
    var song:Song = SongDataParser.fetchSong(songId);

    if (song == null)
    {
      // showNotification('Failed to load song.');
      return;
    }

    // Load the song metadata.
    var rawSongMetadata:Array<SongMetadata> = song.getRawMetadata();
    var songName:String = rawSongMetadata[0].songName;

    this.songMetadata = new Map<String, SongMetadata>();

    for (metadata in rawSongMetadata)
    {
      var variation = (metadata.variation == null || metadata.variation == '') ? 'default' : metadata.variation;
      this.songMetadata.set(variation, metadata);
    }

    this.songChartData = new Map<String, SongChartData>();

    for (metadata in rawSongMetadata)
    {
      var variation = (metadata.variation == null || metadata.variation == '') ? 'default' : metadata.variation;
      this.songChartData.set(variation, SongDataParser.parseSongChartData(songId, metadata.variation));
    }

    Conductor.forceBPM(null); // Disable the forced BPM.
    Conductor.mapTimeChanges(currentSongMetadata.timeChanges);

    loadInstrumentalFromAsset(Paths.inst(songId));
    loadVocalsFromAsset(Paths.voices(songId));

    NotificationManager.instance.addNotification(
      {
        title: 'Success',
        body: 'Loaded song ($songName)',
        type: NotificationType.Success,
        expiryMs: ChartEditorState.NOTIFICATION_DISMISS_TIME
      });
  }

  /**
   * When setting the scroll position, except when automatically scrolling during song playback,
   * we need to update the conductor's current step time and the timestamp of the audio tracks.
   */
  function moveSongToScrollPosition():Void
  {
    // Update the songPosition in the Conductor.
    Conductor.update(scrollPositionInMs);

    // Update the songPosition in the audio tracks.
    if (audioInstTrack != null) audioInstTrack.time = scrollPositionInMs + playheadPositionInMs;
    if (audioVocalTrackGroup != null) audioVocalTrackGroup.time = scrollPositionInMs + playheadPositionInMs;

    // We need to update the note sprites because we changed the scroll position.
    noteDisplayDirty = true;
  }

  /**
   * Perform (or redo) a command, then add it to the undo stack.
   *
   * @param command The command to perform.
   * @param purgeRedoStack If true, the redo stack will be cleared.
   */
  function performCommand(command:ChartEditorCommand, ?purgeRedoStack:Bool = true):Void
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
    if (undoHistory.length == 0)
    {
      trace('No actions to undo.');
      return;
    }

    var command:ChartEditorCommand = undoHistory.pop();
    undoCommand(command);
  }

  /**
   * Redo the last command in the redo stack, then add it to the undo stack.
   */
  function redoLastCommand():Void
  {
    if (redoHistory.length == 0)
    {
      trace('No actions to redo.');
      return;
    }

    var command:ChartEditorCommand = redoHistory.pop();
    performCommand(command, false);
  }

  function sortChartData():Void
  {
    currentSongChartNoteData.sort(function(a:SongNoteData, b:SongNoteData):Int {
      return FlxSort.byValues(FlxSort.ASCENDING, a.time, b.time);
    });

    currentSongChartEventData.sort(function(a:SongEventData, b:SongEventData):Int {
      return FlxSort.byValues(FlxSort.ASCENDING, a.time, b.time);
    });
  }

  function playMetronomeTick(?high:Bool = false):Void
  {
    playSound(Paths.sound('pianoStuff/piano-${high ? '001' : '008'}'));
  }

  function isNoteSelected(note:SongNoteData):Bool
  {
    return currentNoteSelection.indexOf(note) != -1;
  }

  function isEventSelected(event:SongEventData):Bool
  {
    return currentEventSelection.indexOf(event) != -1;
  }

  /**
   * Play a sound effect.
   * Automatically cleans up after itself and recycles previous FlxSound instances if available, for performance.
   */
  function playSound(path:String):Void
  {
    var snd:FlxSound = FlxG.sound.list.recycle(FlxSound);
    snd.loadEmbedded(FlxG.sound.cache(path));
    snd.autoDestroy = true;
    FlxG.sound.list.add(snd);
    snd.play();
  }

  override function destroy():Void
  {
    super.destroy();

    cleanupAutoSave();

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

  /**
   * @param force Whether to force the export without prompting the user for a file location.
   * @param tmp If true, save to the temporary directory instead of the local `backup` directory.
   */
  public function exportAllSongData(?force:Bool = false, ?tmp:Bool = false):Void
  {
    var zipEntries = [];

    for (variation in availableVariations)
    {
      var variationId = variation;
      if (variation == '' || variation == 'default' || variation == 'normal')
      {
        variationId = '';
      }

      if (variationId == '')
      {
        var variationMetadata = songMetadata.get(variation);
        zipEntries.push(FileUtil.makeZIPEntry('$currentSongId-metadata.json', SerializerUtil.toJSON(variationMetadata)));
        var variationChart = songChartData.get(variation);
        zipEntries.push(FileUtil.makeZIPEntry('$currentSongId-chart.json', SerializerUtil.toJSON(variationChart)));
      }
      else
      {
        var variationMetadata = songMetadata.get(variation);
        zipEntries.push(FileUtil.makeZIPEntry('$currentSongId-metadata-$variationId.json', SerializerUtil.toJSON(variationMetadata)));
        var variationChart = songChartData.get(variation);
        zipEntries.push(FileUtil.makeZIPEntry('$currentSongId-chart-$variationId.json', SerializerUtil.toJSON(variationChart)));
      }
    }

    // TODO: Add audio files to the ZIP.

    trace('Exporting ${zipEntries.length} files to ZIP...');

    if (force)
    {
      var targetPath:String = if (tmp)
      {
        Path.join([FileUtil.getTempDir(), 'chart-editor-exit-${DateUtil.generateTimestamp()}.zip']);
      }
      else
      {
        Path.join(['./backups/', 'chart-editor-exit-${DateUtil.generateTimestamp()}.zip']);
      }

      // We have to force write because the program will die before the save dialog is closed.
      trace('Force exporting to $targetPath...');
      FileUtil.saveFilesAsZIPToPath(zipEntries, targetPath);
      return;
    }

    // Prompt and save.
    var onSave:Array<String>->Void = function(paths:Array<String>) {
      trace('Successfully exported files.');
    };

    var onCancel:Void->Void = function() {
      trace('Export cancelled.');
    };

    FileUtil.saveMultipleFiles(zipEntries, onSave, onCancel, '$currentSongId-chart.zip');
  }
}
