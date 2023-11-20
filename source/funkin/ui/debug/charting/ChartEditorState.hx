package funkin.ui.debug.charting;

import flixel.addons.display.FlxSliceSprite;
import flixel.addons.display.FlxTiledSprite;
import flixel.addons.transition.FlxTransitionableState;
import flixel.FlxCamera;
import flixel.FlxSprite;
import flixel.FlxSubState;
import flixel.group.FlxSpriteGroup;
import flixel.input.keyboard.FlxKey;
import flixel.math.FlxMath;
import flixel.math.FlxPoint;
import flixel.math.FlxRect;
import flixel.sound.FlxSound;
import flixel.system.FlxAssets.FlxSoundAsset;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.tweens.misc.VarTween;
import flixel.util.FlxColor;
import funkin.ui.mainmenu.MainMenuState;
import flixel.util.FlxSort;
import flixel.util.FlxTimer;
import funkin.audio.visualize.PolygonSpectogram;
import funkin.audio.VoicesGroup;
import funkin.data.notestyle.NoteStyleRegistry;
import funkin.data.song.SongData.SongChartData;
import funkin.data.song.SongData.SongEventData;
import funkin.data.song.SongData.SongMetadata;
import funkin.data.song.SongData.SongNoteData;
import funkin.data.song.SongDataUtils;
import funkin.input.Cursor;
import funkin.input.TurboKeyHandler;
import funkin.modding.events.ScriptEvent;
import funkin.play.character.BaseCharacter.CharacterType;
import funkin.play.character.CharacterData;
import funkin.play.character.CharacterData.CharacterDataParser;
import funkin.play.components.HealthIcon;
import funkin.play.notes.NoteSprite;
import funkin.play.PlayState;
import funkin.play.song.Song;
import funkin.data.song.SongData.SongChartData;
import funkin.data.song.SongRegistry;
import funkin.data.song.SongData.SongEventData;
import funkin.data.song.SongData.SongMetadata;
import funkin.data.song.SongData.SongNoteData;
import funkin.data.song.SongData.SongCharacterData;
import funkin.data.song.SongDataUtils;
import funkin.ui.debug.charting.commands.ChartEditorCommand;
import funkin.ui.debug.charting.handlers.ChartEditorShortcutHandler;
import funkin.play.stage.StageData;
import funkin.save.Save;
import funkin.ui.debug.charting.commands.AddEventsCommand;
import funkin.ui.debug.charting.commands.AddNotesCommand;
import funkin.ui.debug.charting.commands.ChartEditorCommand;
import funkin.ui.debug.charting.commands.CutItemsCommand;
import funkin.ui.debug.charting.commands.DeselectAllItemsCommand;
import funkin.ui.debug.charting.commands.DeselectItemsCommand;
import funkin.ui.debug.charting.commands.ExtendNoteLengthCommand;
import funkin.ui.debug.charting.commands.FlipNotesCommand;
import funkin.ui.debug.charting.commands.InvertSelectedItemsCommand;
import funkin.ui.debug.charting.commands.MoveEventsCommand;
import funkin.ui.debug.charting.commands.MoveItemsCommand;
import funkin.ui.debug.charting.commands.MoveNotesCommand;
import funkin.ui.debug.charting.commands.PasteItemsCommand;
import funkin.ui.debug.charting.commands.RemoveEventsCommand;
import funkin.ui.debug.charting.commands.RemoveItemsCommand;
import funkin.ui.debug.charting.commands.RemoveNotesCommand;
import funkin.ui.debug.charting.commands.SelectAllItemsCommand;
import funkin.ui.debug.charting.commands.SelectItemsCommand;
import funkin.ui.debug.charting.commands.SetItemSelectionCommand;
import funkin.ui.debug.charting.components.ChartEditorEventSprite;
import funkin.ui.debug.charting.components.ChartEditorHoldNoteSprite;
import funkin.ui.debug.charting.components.ChartEditorNotePreview;
import funkin.ui.debug.charting.components.ChartEditorNoteSprite;
import funkin.ui.debug.charting.components.ChartEditorSelectionSquareSprite;
import funkin.ui.haxeui.components.CharacterPlayer;
import funkin.ui.haxeui.HaxeUIState;
import funkin.util.Constants;
import funkin.util.SortUtil;
import funkin.util.WindowUtil;
import haxe.DynamicAccess;
import haxe.io.Bytes;
import haxe.io.Path;
import haxe.ui.components.DropDown;
import haxe.ui.components.Label;
import haxe.ui.components.NumberStepper;
import haxe.ui.components.Slider;
import haxe.ui.components.TextField;
import haxe.ui.containers.dialogs.CollapsibleDialog;
import haxe.ui.containers.Frame;
import haxe.ui.containers.menus.Menu;
import haxe.ui.containers.menus.MenuItem;
import haxe.ui.containers.TreeView;
import haxe.ui.containers.TreeViewNode;
import haxe.ui.core.Component;
import haxe.ui.core.Screen;
import haxe.ui.events.DragEvent;
import haxe.ui.events.UIEvent;
import haxe.ui.focus.FocusManager;
import haxe.ui.notifications.NotificationManager;
import haxe.ui.notifications.NotificationType;
import openfl.display.BitmapData;
import funkin.util.FileUtil;

using Lambda;

/**
 * A state dedicated to allowing the user to create and edit song charts.
 * Built with HaxeUI for use by both developers and modders.
 *
 * Some functionality is moved to other classes to help maintain my sanity.
 *
 * @author MasterEric
 */
@:nullSafety
class ChartEditorState extends HaxeUIState
{
  /**
   * CONSTANTS
   */
  // ==============================
  // XML Layouts
  public static final CHART_EDITOR_LAYOUT:String = Paths.ui('chart-editor/main-view');

  public static final CHART_EDITOR_NOTIFBAR_LAYOUT:String = Paths.ui('chart-editor/components/notifbar');
  public static final CHART_EDITOR_PLAYBARHEAD_LAYOUT:String = Paths.ui('chart-editor/components/playbar-head');

  public static final CHART_EDITOR_TOOLBOX_NOTEDATA_LAYOUT:String = Paths.ui('chart-editor/toolbox/notedata');
  public static final CHART_EDITOR_TOOLBOX_EVENTDATA_LAYOUT:String = Paths.ui('chart-editor/toolbox/eventdata');
  public static final CHART_EDITOR_TOOLBOX_METADATA_LAYOUT:String = Paths.ui('chart-editor/toolbox/metadata');
  public static final CHART_EDITOR_TOOLBOX_DIFFICULTY_LAYOUT:String = Paths.ui('chart-editor/toolbox/difficulty');
  public static final CHART_EDITOR_TOOLBOX_PLAYER_PREVIEW_LAYOUT:String = Paths.ui('chart-editor/toolbox/player-preview');
  public static final CHART_EDITOR_TOOLBOX_OPPONENT_PREVIEW_LAYOUT:String = Paths.ui('chart-editor/toolbox/opponent-preview');

  // Validation
  public static final SUPPORTED_MUSIC_FORMATS:Array<String> = ['ogg'];

  // Layout

  /**
   * The base grid size for the chart editor.
   */
  public static final GRID_SIZE:Int = 40;

  /**
   * The width of the scroll area.
   */
  public static final PLAYHEAD_SCROLL_AREA_WIDTH:Int = 12;

  /**
   * The height of the playhead, in pixels.
   */
  public static final PLAYHEAD_HEIGHT:Int = Std.int(GRID_SIZE / 8);

  /**
   * The width of the border between grid squares, where the crosshair changes from "Place Notes" to "Select Notes".
   */
  public static final GRID_SELECTION_BORDER_WIDTH:Int = 6;

  /**
   * The height of the menu bar in the layout.
   */
  public static final MENU_BAR_HEIGHT:Int = 32;

  /**
   * The height of the playbar in the layout.
   */
  public static final PLAYBAR_HEIGHT:Int = 48;

  /**
   * The amount of padding between the menu bar and the chart grid when fully scrolled up.
   */
  public static final GRID_TOP_PAD:Int = 8;

  // Colors
  // Background color tint.
  public static final CURSOR_COLOR:FlxColor = 0xE0FFFFFF;
  public static final PREVIEW_BG_COLOR:FlxColor = 0xFF303030;
  public static final PLAYHEAD_SCROLL_AREA_COLOR:FlxColor = 0xFF682B2F;
  public static final SPECTROGRAM_COLOR:FlxColor = 0xFFFF0000;
  public static final PLAYHEAD_COLOR:FlxColor = 0xC0BD0231;

  // Timings

  /**
   * Duration, in seconds, for the scroll easing animation.
   */
  public static final SCROLL_EASE_DURATION:Float = 0.2;

  // Other

  /**
   * Number of notes in each player's strumline.
   */
  public static final STRUMLINE_SIZE:Int = 4;

  /**
   * How many pixels far the user needs to move the mouse before the cursor is considered to be dragged rather than clicked.
   */
  public static final DRAG_THRESHOLD:Float = 16.0;

  /**
   * Precisions of notes you can snap to.
   */
  public static final SNAP_QUANTS:Array<Int> = [4, 8, 12, 16, 20, 24, 32, 48, 64, 96, 192];

  /**
   * The default note snapping value.
   */
  public static final BASE_QUANT:Int = 16;

  /**
   * The index of thet default note snapping value in the `SNAP_QUANTS` array.
   */
  public static final BASE_QUANT_INDEX:Int = 3;

  /**
   * INSTANCE DATA
   */
  // ==============================
  // Song Length

  /**
   * The length of the current instrumental, in milliseconds.
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
   * The length of the current instrumental, converted to steps.
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
   * The length of the current instrumental, in PIXELS.
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

  // Scroll Position

  /**
   * The relative scroll position in the song, in pixels.
   * One pixel is 1/40 of 1 step, and 1/160 of 1 beat.
   */
  var scrollPositionInPixels(default, set):Float = -1.0;

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
    if (gridTiledSprite != null && gridPlayheadScrollArea != null)
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
   * The relative scroll position in the song, converted to steps.
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
   * The relative scroll position in the song, converted to milliseconds.
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

  // Playhead (on the grid)

  /**
   * The position of the playhead, in pixels, relative to the `scrollPositionInPixels`.
   * `0` means playhead is at the top of the grid.
   * `40` means the playhead is 1 grid length below the base position.
   * `-40` means the playhead is 1 grid length above the base position.
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

  // Playbar (at the bottom)

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

  // Tools Status

  /**
   * The note kind to use for notes being placed in the chart. Defaults to `''`.
   */
  var selectedNoteKind:String = '';

  /**
   * The event type to use for events being placed in the chart. Defaults to `''`.
   */
  var selectedEventKind:String = 'FocusCamera';

  /**
   * The event data to use for events being placed in the chart.
   */
  var selectedEventData:DynamicAccess<Dynamic> = {};

  /**
   * The internal index of what note snapping value is in use.
   * Increment to make placement more preceise and decrement to make placement less precise.
   */
  var noteSnapQuantIndex:Int = BASE_QUANT_INDEX;

  /**
   * The current note snapping value.
   * For example, `32` when snapping to 32nd notes.
   */
  var noteSnapQuant(get, never):Int;

  function get_noteSnapQuant():Int
  {
    return SNAP_QUANTS[noteSnapQuantIndex];
  }

  /**
   * The ratio of the current note snapping value to the default.
   * For example, `32` becomes `0.5` when snapping to 16th notes.
   */
  var noteSnapRatio(get, never):Float;

  function get_noteSnapRatio():Float
  {
    return BASE_QUANT / noteSnapQuant;
  }

  /**
   * The currently selected live input style.
   */
  var currentLiveInputStyle:ChartEditorLiveInputStyle = None;

  /**
   * If true, playtesting a chart will skip to the current playhead position.
   */
  var playtestStartTime:Bool = false;

  // Visuals

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
    // Characters have probably changed too.
    healthIconsDirty = true;

    return isViewDownscroll;
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
    this.updateTheme();
    return value;
  }

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

  // HaxeUI

  /**
   * Whether the user is focused on an input in the Haxe UI, and inputs are being fed into it.
   * If the user clicks off the input, focus will leave.
   */
  var isHaxeUIFocused(get, never):Bool;

  function get_isHaxeUIFocused():Bool
  {
    return FocusManager.instance.focus != null;
  }

  /**
   * Set by ChartEditorDialogHandler, used to prevent background interaction while the dialog is open.
   */
  var isHaxeUIDialogOpen:Bool = false;

  /**
   * The Dialog components representing the currently available tool windows.
   * Dialogs are retained here even when collapsed or hidden.
   */
  var activeToolboxes:Map<String, CollapsibleDialog> = new Map<String, CollapsibleDialog>();

  // Audio

  /**
   * Whether to play a metronome sound while the playhead is moving.
   */
  var isMetronomeEnabled:Bool = true;

  /**
   * Whether hitsounds are enabled for the player.
   */
  var hitsoundsEnabledPlayer:Bool = true;

  /**
   * Whether hitsounds are enabled for the opponent.
   */
  var hitsoundsEnabledOpponent:Bool = true;

  /**
   * Whether hitsounds are enabled for at least one character.
   */
  var hitsoundsEnabled(get, never):Bool;

  function get_hitsoundsEnabled():Bool
  {
    return hitsoundsEnabledPlayer || hitsoundsEnabledOpponent;
  }

  // Auto-save

  /**
   * A timer used to auto-save the chart after a period of inactivity.
   */
  var autoSaveTimer:Null<FlxTimer> = null;

  // Scrolling

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
   * The current process that is lerping the scroll position.
   * Used to cancel the previous lerp if the user scrolls again.
   */
  var currentScrollEase:Null<VarTween>;

  // Note Placement

  /**
   * The SongNoteData which is currently being placed.
   * `null` if the user isn't currently placing a note.
   * As the user drags, we will update this note's sustain length, and finalize the note when they release.
   */
  var currentPlaceNoteData:Null<SongNoteData> = null;

  // Note Movement

  /**
   * The note sprite we are currently moving, if any.
   */
  var dragTargetNote:Null<ChartEditorNoteSprite> = null;

  /**
   * The song event sprite we are currently moving, if any.
   */
  var dragTargetEvent:Null<ChartEditorEventSprite> = null;

  /**
   * The amount of vertical steps the note sprite has moved by since the user started dragging.
   */
  var dragTargetCurrentStep:Float = 0;

  /**
   * The amount of horizontal columns the note sprite has moved by since the user started dragging.
   */
  var dragTargetCurrentColumn:Int = 0;

  // Hold Note Dragging

  /**
   * The current length of the hold note we are dragging, in steps.
   * Play a sound when this value changes.
   */
  var dragLengthCurrent:Float = 0;

  /**
   * Flip-flop to alternate between two stretching sounds.
   */
  var stretchySounds:Bool = false;

  // Selection

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

  // History

  /**
   * The list of command previously performed. Used for undoing previous actions.
   */
  var undoHistory:Array<ChartEditorCommand> = [];

  /**
   * The list of commands that have been undone. Used for redoing previous actions.
   */
  var redoHistory:Array<ChartEditorCommand> = [];

  // Dirty Flags

  /**
   * Whether the note display render group has been modified and needs to be updated.
   * This happens when we scroll or add/remove notes, and need to update what notes are displayed and where.
   */
  var noteDisplayDirty:Bool = true;

  /**
   * Whether the selected charactesr have been modified and the health icons need to be updated.
   */
  var healthIconsDirty:Bool = true;

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
      autoSaveTimer = new FlxTimer().start(Constants.AUTOSAVE_TIMER_DELAY_SEC, (_) -> autoSave());
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

    saveDataDirty = value;
    applyWindowTitle();
    return saveDataDirty;
  }

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

  /**
   * Whether the undo/redo histories have changed since the last time the UI was updated.
   */
  var commandHistoryDirty:Bool = true;

  // Input

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
   * Variable used to track how long the user has been holding the W keybind.
   */
  var wKeyHandler:TurboKeyHandler = TurboKeyHandler.build(FlxKey.W);

  /**
   * Variable used to track how long the user has been holding the S keybind.
   */
  var sKeyHandler:TurboKeyHandler = TurboKeyHandler.build(FlxKey.S);

  /**
   * Variable used to track how long the user has been holding the page-up keybind.
   */
  var pageUpKeyHandler:TurboKeyHandler = TurboKeyHandler.build(FlxKey.PAGEUP);

  /**
   * Variable used to track how long the user has been holding the page-down keybind.
   */
  var pageDownKeyHandler:TurboKeyHandler = TurboKeyHandler.build(FlxKey.PAGEDOWN);

  /**
   * AUDIO AND SOUND DATA
   */
  // ==============================

  /**
   * The chill audio track that plays when you open the Chart Editor.
   */
  var welcomeMusic:FlxSound = new FlxSound();

  /**
   * The audio track for the instrumental.
   * Replaced when switching instrumentals.
   * `null` until an instrumental track is loaded.
   */
  var audioInstTrack:Null<FlxSound> = null;

  /**
   * The raw byte data for the instrumental audio tracks.
   * Key is the instrumental name.
   * `null` until an instrumental track is loaded.
   */
  var audioInstTrackData:Map<String, Bytes> = [];

  /**
   * The audio track for the vocals.
   * `null` until vocal track(s) are loaded.
   * When switching characters, the elements of the VoicesGroup will be swapped to match the new character.
   */
  var audioVocalTrackGroup:Null<VoicesGroup> = null;

  /**
   * A map of the audio tracks for each character's vocals.
   * - Keys are `characterId-variation` (with `characterId` being the default variation).
   * - Values are the byte data for the audio track.
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
      result = new SongMetadata('DadBattle', 'Kawai Sprite', selectedVariation);
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
    var result:Null<Array<SongNoteData>> = currentSongChartData.notes.get(selectedDifficulty);
    if (result == null)
    {
      // Initialize to the default value if not set.
      result = [];
      trace('Initializing blank note data for difficulty ' + selectedDifficulty);
      currentSongChartData.notes.set(selectedDifficulty, result);
      currentSongMetadata.playData.difficulties.pushUnique(selectedDifficulty);
      return result;
    }
    return result;
  }

  function set_currentSongChartNoteData(value:Array<SongNoteData>):Array<SongNoteData>
  {
    currentSongChartData.notes.set(selectedDifficulty, value);
    currentSongMetadata.playData.difficulties.pushUnique(selectedDifficulty);
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

  var currentSongNoteStyle(get, set):String;

  function get_currentSongNoteStyle():String
  {
    if (currentSongMetadata.playData.noteStyle == null)
    {
      // Initialize to the default value if not set.
      currentSongMetadata.playData.noteStyle = Constants.DEFAULT_NOTE_STYLE;
    }
    return currentSongMetadata.playData.noteStyle;
  }

  function set_currentSongNoteStyle(value:String):String
  {
    return currentSongMetadata.playData.noteStyle = value;
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

  /**
   * The variation ID for the difficulty which is currently being edited.
   */
  var selectedVariation(default, set):String = Constants.DEFAULT_VARIATION;

  /**
   * Setter called when we are switching variations.
   * We will likely need to switch instrumentals as well.
   */
  function set_selectedVariation(value:String):String
  {
    // Don't update if we're already on the variation.
    if (selectedVariation == value) return selectedVariation;
    selectedVariation = value;

    // Make sure view is updated when the variation changes.
    noteDisplayDirty = true;
    notePreviewDirty = true;
    notePreviewViewportBoundsDirty = true;

    switchToCurrentInstrumental();

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

    // Make sure the difficulty we selected is in the list of difficulties.
    currentSongMetadata.playData.difficulties.pushUnique(selectedDifficulty);

    return selectedDifficulty;
  }

  /**
   * The instrumental ID which is currently selected.
   */
  var currentInstrumentalId(get, set):String;

  function get_currentInstrumentalId():String
  {
    var instId:Null<String> = currentSongMetadata.playData.characters.instrumental;
    if (instId == null || instId == '') instId = (selectedVariation == Constants.DEFAULT_VARIATION) ? '' : selectedVariation;
    return instId;
  }

  function set_currentInstrumentalId(value:String):String
  {
    return currentSongMetadata.playData.characters.instrumental = value;
  }

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

  /**
   * The sprite for the scroll area under
   */
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
   * The submenu in the menubar containing recently opened files.
   */
  var menubarOpenRecent:Null<Menu> = null;

  /**
   * The item in the menubar to save the currently opened chart.
   */
  var menubarItemSaveChart:Null<MenuItem> = null;

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

  var renderedSelectionSquares:FlxTypedSpriteGroup<ChartEditorSelectionSquareSprite> = new FlxTypedSpriteGroup<ChartEditorSelectionSquareSprite>();

  /**
   * LIFE CYCLE FUNCTIONS
   */
  // ==============================

  /**
   * The params which were passed in when the Chart Editor was initialized.
   */
  var params:Null<ChartEditorParams>;

  /**
   * A list of previous working file paths.
   * Also known as the "recent files" list.
   * The first element is [null] if the current working file has not been saved anywhere yet.
   */
  public var previousWorkingFilePaths(default, set):Array<Null<String>> = [null];

  function set_previousWorkingFilePaths(value:Array<Null<String>>):Array<Null<String>>
  {
    // Called only when the WHOLE LIST is overridden.
    previousWorkingFilePaths = value;
    applyWindowTitle();
    populateOpenRecentMenu();
    applyCanQuickSave();
    return value;
  }

  /**
   * The current file path which the chart editor is working with.
   * If `null`, the current chart has not been saved yet.
   */
  public var currentWorkingFilePath(get, set):Null<String>;

  function get_currentWorkingFilePath():Null<String>
  {
    return previousWorkingFilePaths[0];
  }

  function set_currentWorkingFilePath(value:Null<String>):Null<String>
  {
    if (value == previousWorkingFilePaths[0]) return value;

    if (previousWorkingFilePaths.contains(null))
    {
      // Filter all instances of `null` from the array.
      previousWorkingFilePaths = previousWorkingFilePaths.filter(function(x:Null<String>):Bool {
        return x != null;
      });
    }

    if (previousWorkingFilePaths.contains(value))
    {
      // Move the path to the front of the list.
      previousWorkingFilePaths.remove(value);
      previousWorkingFilePaths.unshift(value);
    }
    else
    {
      // Add the path to the front of the list.
      previousWorkingFilePaths.unshift(value);
    }

    while (previousWorkingFilePaths.length > Constants.MAX_PREVIOUS_WORKING_FILES)
    {
      // Remove the last path in the list.
      previousWorkingFilePaths.pop();
    }

    populateOpenRecentMenu();
    applyWindowTitle();

    return value;
  }

  public function new(?params:ChartEditorParams)
  {
    // Load the HaxeUI XML file.
    super(CHART_EDITOR_LAYOUT);

    this.params = params;
  }

  public override function dispatchEvent(event:ScriptEvent):Void
  {
    super.dispatchEvent(event);

    // We can't use the ScriptedEventDispatcher with currentCharPlayer because we can't use the IScriptedClass interface on it.
    if (currentPlayerCharacterPlayer != null)
    {
      switch (event.type)
      {
        case UPDATE:
          currentPlayerCharacterPlayer.onUpdate(cast event);
        case SONG_BEAT_HIT:
          currentPlayerCharacterPlayer.onBeatHit(cast event);
        case SONG_STEP_HIT:
          currentPlayerCharacterPlayer.onStepHit(cast event);
        case NOTE_HIT:
          currentPlayerCharacterPlayer.onNoteHit(cast event);
        default: // Continue
      }
    }

    if (currentOpponentCharacterPlayer != null)
    {
      switch (event.type)
      {
        case UPDATE:
          currentOpponentCharacterPlayer.onUpdate(cast event);
        case SONG_BEAT_HIT:
          currentOpponentCharacterPlayer.onBeatHit(cast event);
        case SONG_STEP_HIT:
          currentOpponentCharacterPlayer.onStepHit(cast event);
        case NOTE_HIT:
          currentOpponentCharacterPlayer.onNoteHit(cast event);
        default: // Continue
      }
    }
  }

  override function create():Void
  {
    // super.create() must be called first, the HaxeUI components get created here.
    super.create();
    // Set the z-index of the HaxeUI.
    this.component.zIndex = 100;

    // Show the mouse cursor.
    Cursor.show();

    loadPreferences();

    fixCamera();

    // Get rid of any music from the previous state.
    if (FlxG.sound.music != null) FlxG.sound.music.stop();

    // Play the welcome music.
    setupWelcomeMusic();

    buildDefaultSongData();

    buildBackground();

    this.updateTheme();

    buildGrid();
    buildNotePreview();
    buildSelectionBox();

    buildAdditionalUI();
    populateOpenRecentMenu();
    ChartEditorShortcutHandler.applyPlatformShortcutText(this);

    // Setup the onClick listeners for the UI after it's been created.
    setupUIListeners();
    setupTurboKeyHandlers();

    setupAutoSave();

    refresh();

    if (params != null && params.fnfcTargetPath != null)
    {
      // Chart editor was opened from the command line. Open the FNFC file now!
      var result:Null<Array<String>> = ChartEditorImportExportHandler.loadFromFNFCPath(this, params.fnfcTargetPath);
      if (result != null)
      {
        #if !mac
        NotificationManager.instance.addNotification(
          {
            title: 'Success',
            body: result.length == 0 ? 'Loaded chart (${params.fnfcTargetPath})' : 'Loaded chart (${params.fnfcTargetPath})\n${result.join("\n")}',
            type: result.length == 0 ? NotificationType.Success : NotificationType.Warning,
            expiryMs: Constants.NOTIFICATION_DISMISS_TIME
          });
        #end
      }
      else
      {
        #if !mac
        NotificationManager.instance.addNotification(
          {
            title: 'Failure',
            body: 'Failed to load chart (${params.fnfcTargetPath})',
            type: NotificationType.Error,
            expiryMs: Constants.NOTIFICATION_DISMISS_TIME
          });
        #end

        // Song failed to load, open the Welcome dialog so we aren't in a broken state.
        ChartEditorDialogHandler.openWelcomeDialog(this, false);
      }
    }
    else if (params != null && params.targetSongId != null)
    {
      this.loadSongAsTemplate(params.targetSongId);
    }
    else
    {
      ChartEditorDialogHandler.openWelcomeDialog(this, false);
    }
  }

  function setupWelcomeMusic()
  {
    this.welcomeMusic.loadEmbedded(Paths.music('chartEditorLoop/chartEditorLoop'));
    this.welcomeMusic.looped = true;
  }

  public function loadPreferences():Void
  {
    var save:Save = Save.get();

    if (previousWorkingFilePaths[0] == null)
    {
      previousWorkingFilePaths = [null].concat(save.chartEditorPreviousFiles);
    }
    else
    {
      previousWorkingFilePaths = [currentWorkingFilePath].concat(save.chartEditorPreviousFiles);
    }
    noteSnapQuantIndex = save.chartEditorNoteQuant;
    currentLiveInputStyle = save.chartEditorLiveInputStyle;
    isViewDownscroll = save.chartEditorDownscroll;
    playtestStartTime = save.chartEditorPlaytestStartTime;
    currentTheme = save.chartEditorTheme;
    isMetronomeEnabled = save.chartEditorMetronomeEnabled;
    hitsoundsEnabledPlayer = save.chartEditorHitsoundsEnabledPlayer;
    hitsoundsEnabledOpponent = save.chartEditorHitsoundsEnabledOpponent;

    // audioInstTrack.volume = save.chartEditorInstVolume;
    // audioInstTrack.pitch = save.chartEditorPlaybackSpeed;
    // audioVocalTrackGroup.volume = save.chartEditorVoicesVolume;
    // audioVocalTrackGroup.pitch = save.chartEditorPlaybackSpeed;
  }

  public function writePreferences():Void
  {
    var save:Save = Save.get();

    // Can't use filter() because of null safety checking!
    var filteredWorkingFilePaths:Array<String> = [];
    for (chartPath in previousWorkingFilePaths)
      if (chartPath != null) filteredWorkingFilePaths.push(chartPath);

    save.chartEditorPreviousFiles = filteredWorkingFilePaths;
    save.chartEditorNoteQuant = noteSnapQuantIndex;
    save.chartEditorLiveInputStyle = currentLiveInputStyle;
    save.chartEditorDownscroll = isViewDownscroll;
    save.chartEditorPlaytestStartTime = playtestStartTime;
    save.chartEditorTheme = currentTheme;
    save.chartEditorMetronomeEnabled = isMetronomeEnabled;
    save.chartEditorHitsoundsEnabledPlayer = hitsoundsEnabledPlayer;
    save.chartEditorHitsoundsEnabledOpponent = hitsoundsEnabledOpponent;

    // save.chartEditorInstVolume = audioInstTrack.volume;
    // save.chartEditorVoicesVolume = audioVocalTrackGroup.volume;
    // save.chartEditorPlaybackSpeed = audioInstTrack.pitch;
  }

  public function populateOpenRecentMenu():Void
  {
    if (menubarOpenRecent == null) return;

    #if sys
    menubarOpenRecent.removeAllComponents();

    for (chartPath in previousWorkingFilePaths)
    {
      if (chartPath == null) continue;

      var menuItemRecentChart:MenuItem = new MenuItem();
      menuItemRecentChart.text = chartPath;
      menuItemRecentChart.onClick = function(_event) {
        stopWelcomeMusic();

        // Load chart from file
        var result:Null<Array<String>> = ChartEditorImportExportHandler.loadFromFNFCPath(this, chartPath);
        if (result != null)
        {
          #if !mac
          NotificationManager.instance.addNotification(
            {
              title: 'Success',
              body: result.length == 0 ? 'Loaded chart (${chartPath.toString()})' : 'Loaded chart (${chartPath.toString()})\n${result.join("\n")}',
              type: result.length == 0 ? NotificationType.Success : NotificationType.Warning,
              expiryMs: Constants.NOTIFICATION_DISMISS_TIME
            });
          #end
        }
        else
        {
          #if !mac
          NotificationManager.instance.addNotification(
            {
              title: 'Failure',
              body: 'Failed to load chart (${chartPath.toString()})',
              type: NotificationType.Error,
              expiryMs: Constants.NOTIFICATION_DISMISS_TIME
            });
          #end
        }
      }

      if (!FileUtil.doesFileExist(chartPath))
      {
        trace('Previously loaded chart file (${chartPath}) does not exist, disabling link...');
        menuItemRecentChart.disabled = true;
      }
      else
      {
        menuItemRecentChart.disabled = false;
      }

      menubarOpenRecent.addComponent(menuItemRecentChart);
    }
    #else
    menubarOpenRecent.hide();
    #end
  }

  function fadeInWelcomeMusic():Void
  {
    this.welcomeMusic.play();
    this.welcomeMusic.fadeIn(4, 0, 1.0);
  }

  function stopWelcomeMusic():Void
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
    healthIconDad = new HealthIcon(currentSongMetadata.playData.characters.opponent);
    healthIconDad.autoUpdate = false;
    healthIconDad.size.set(0.5, 0.5);
    add(healthIconDad);
    healthIconDad.zIndex = 30;

    healthIconBF = new HealthIcon(currentSongMetadata.playData.characters.player);
    healthIconBF.autoUpdate = false;
    healthIconBF.size.set(0.5, 0.5);
    healthIconBF.flipX = true;
    add(healthIconBF);
    healthIconBF.zIndex = 30;
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
    {
      trace('[WARN] Tried to set note preview viewport bounds, but notePreviewViewport is null!');
      return;
    }

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
    renderedEvents.zIndex = 25;

    renderedSelectionSquares.setPosition(gridTiledSprite.x, gridTiledSprite.y);
    add(renderedSelectionSquares);
    renderedSelectionSquares.zIndex = 26;
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

    menubarOpenRecent = findComponent('menubarOpenRecent', Menu);
    if (menubarOpenRecent == null) throw "Could not find menubarOpenRecent!";

    menubarItemSaveChart = findComponent('menubarItemSaveChart', MenuItem);
    if (menubarItemSaveChart == null) throw "Could not find menubarItemSaveChart!";

    // Setup notifications.
    @:privateAccess
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

    // Cycle note snap quant.
    addUIRightClickListener('playbarNoteSnap', function(_) {
      noteSnapQuantIndex--;
      if (noteSnapQuantIndex < 0) noteSnapQuantIndex = SNAP_QUANTS.length - 1;
    });
    addUIClickListener('playbarNoteSnap', function(_) {
      noteSnapQuantIndex++;
      if (noteSnapQuantIndex >= SNAP_QUANTS.length) noteSnapQuantIndex = 0;
    });

    // Add functionality to the menu items.

    addUIClickListener('menubarItemNewChart', _ -> ChartEditorDialogHandler.openWelcomeDialog(this, true));
    addUIClickListener('menubarItemOpenChart', _ -> ChartEditorDialogHandler.openBrowseFNFC(this, true));
    addUIClickListener('menubarItemSaveChart', _ -> {
      if (currentWorkingFilePath != null)
      {
        ChartEditorImportExportHandler.exportAllSongData(this, true, currentWorkingFilePath);
      }
      else
      {
        ChartEditorImportExportHandler.exportAllSongData(this, false);
      }
    });
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

    addUIClickListener('menubarItemPaste', _ -> {
      var targetMs:Float = scrollPositionInMs + playheadPositionInMs;
      var targetStep:Float = Conductor.getTimeInSteps(targetMs);
      var targetSnappedStep:Float = Math.floor(targetStep / noteSnapRatio) * noteSnapRatio;
      var targetSnappedMs:Float = Conductor.getStepTimeInMs(targetSnappedStep);
      performCommand(new PasteItemsCommand(targetSnappedMs));
    });

    addUIClickListener('menubarItemPasteUnsnapped', _ -> {
      var targetMs:Float = scrollPositionInMs + playheadPositionInMs;
      performCommand(new PasteItemsCommand(targetMs));
    });

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

    addUIClickListener('menubarItemFlipNotes', _ -> performCommand(new FlipNotesCommand(currentNoteSelection)));

    addUIClickListener('menubarItemSelectAll', _ -> performCommand(new SelectAllItemsCommand(currentNoteSelection, currentEventSelection)));

    addUIClickListener('menubarItemSelectInverse', _ -> performCommand(new InvertSelectedItemsCommand(currentNoteSelection, currentEventSelection)));

    addUIClickListener('menubarItemSelectNone', _ -> performCommand(new DeselectAllItemsCommand(currentNoteSelection, currentEventSelection)));

    addUIClickListener('menubarItemPlaytestFull', _ -> testSongInPlayState(false));
    addUIClickListener('menubarItemPlaytestMinimal', _ -> testSongInPlayState(true));

    addUIClickListener('menuBarItemNoteSnapDecrease', _ -> {
      noteSnapQuantIndex--;
      if (noteSnapQuantIndex < 0) noteSnapQuantIndex = SNAP_QUANTS.length - 1;
    });
    addUIClickListener('menuBarItemNoteSnapIncrease', _ -> {
      noteSnapQuantIndex++;
      if (noteSnapQuantIndex >= SNAP_QUANTS.length) noteSnapQuantIndex = 0;
    });

    addUIChangeListener('menuBarItemInputStyleNone', function(event:UIEvent) {
      currentLiveInputStyle = None;
    });
    addUIChangeListener('menuBarItemInputStyleNumberKeys', function(event:UIEvent) {
      currentLiveInputStyle = NumberKeys;
    });
    addUIChangeListener('menuBarItemInputStyleWASD', function(event:UIEvent) {
      currentLiveInputStyle = WASD;
    });

    addUIClickListener('menubarItemAbout', _ -> this.openAboutDialog());
    addUIClickListener('menubarItemWelcomeDialog', _ -> this.openWelcomeDialog(true));

    addUIClickListener('menubarItemUserGuide', _ -> this.openUserGuideDialog());

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

    addUIClickListener('menubarItemPlayPause', _ -> toggleAudioPlayback());

    addUIClickListener('menubarItemLoadInstrumental', _ -> this.openUploadInstDialog(true));
    addUIClickListener('menubarItemLoadVocals', _ -> this.openUploadVocalsDialog(true));

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
        var volume:Float = (event?.value ?? 0) / 100.0;
        if (audioInstTrack != null) audioInstTrack.volume = volume;
        instVolumeLabel.text = 'Instrumental - ${Std.int(event.value)}%';
      });
    }

    var vocalsVolumeLabel:Null<Label> = findComponent('menubarLabelVolumeVocals', Label);
    if (vocalsVolumeLabel != null)
    {
      addUIChangeListener('menubarItemVolumeVocals', function(event:UIEvent) {
        var volume:Float = (event?.value ?? 0) / 100.0;
        if (audioVocalTrackGroup != null) audioVocalTrackGroup.volume = volume;
        vocalsVolumeLabel.text = 'Voices - ${Std.int(event.value)}%';
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

    addUIChangeListener('menubarItemToggleToolboxDifficulty', event -> this.setToolboxState(CHART_EDITOR_TOOLBOX_DIFFICULTY_LAYOUT, event.value));
    addUIChangeListener('menubarItemToggleToolboxMetadata', event -> this.setToolboxState(CHART_EDITOR_TOOLBOX_METADATA_LAYOUT, event.value));
    addUIChangeListener('menubarItemToggleToolboxNotes', event -> this.setToolboxState(CHART_EDITOR_TOOLBOX_NOTEDATA_LAYOUT, event.value));
    addUIChangeListener('menubarItemToggleToolboxEvents', event -> this.setToolboxState(CHART_EDITOR_TOOLBOX_EVENTDATA_LAYOUT, event.value));
    addUIChangeListener('menubarItemToggleToolboxPlayerPreview', event -> this.setToolboxState(CHART_EDITOR_TOOLBOX_PLAYER_PREVIEW_LAYOUT, event.value));
    addUIChangeListener('menubarItemToggleToolboxOpponentPreview', event -> this.setToolboxState(CHART_EDITOR_TOOLBOX_OPPONENT_PREVIEW_LAYOUT, event.value));

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
    add(wKeyHandler);
    add(sKeyHandler);
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
   * UPDATE FUNCTIONS
   */
  function autoSave():Void
  {
    saveDataDirty = false;

    // Auto-save preferences.
    writePreferences();

    // Auto-save the chart.
    #if html5
    // Auto-save to local storage.
    // TODO: Implement this.
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

    #if debug
    handleQuickWatch();
    #end
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
   * UPDATE HANDLERS
   */
  // ====================

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

        // Resolve an issue where dragging an event too far would cause it to be hidden.
        var isSelectedAndDragged = currentNoteSelection.fastContains(noteSprite.noteData) && (dragTargetCurrentStep != 0);

        if ((noteSprite.isNoteVisible(viewAreaBottomPixels, viewAreaTopPixels)
          && currentSongChartNoteData.fastContains(noteSprite.noteData))
          || isSelectedAndDragged)
        {
          // Note is already displayed and should remain displayed.
          displayedNoteData.push(noteSprite.noteData);

          // Update the note sprite's position.
          noteSprite.updateNotePosition(renderedNotes);
        }
        else
        {
          // This sprite is off-screen or was deleted.
          // Kill the note sprite and recycle it.
          noteSprite.noteData = null;
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

        // Resolve an issue where dragging an event too far would cause it to be hidden.
        var isSelectedAndDragged = currentEventSelection.fastContains(eventSprite.eventData) && (dragTargetCurrentStep != 0);

        if ((eventSprite.isEventVisible(FlxG.height - MENU_BAR_HEIGHT, GRID_TOP_PAD)
          && currentSongChartEventData.fastContains(eventSprite.eventData))
          || isSelectedAndDragged)
        {
          // Event is already displayed and should remain displayed.
          displayedEventData.push(eventSprite.eventData);

          // Update the event sprite's position.
          eventSprite.updateEventPosition(renderedEvents);
        }
        else
        {
          // This event was deleted.
          // Kill the event sprite and recycle it.
          eventSprite.eventData = null;
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
        noteSprite.overrideStepTime = null;
        noteSprite.overrideData = null;

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
        eventSprite.overrideStepTime = null;

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
          // Determine if the note is being dragged and offset the vertical position accordingly.
          if (dragTargetCurrentStep != 0.0)
          {
            var stepTime:Float = (noteSprite.noteData == null) ? 0.0 : noteSprite.noteData.getStepTime();
            // Update the note's "ghost" step time.
            noteSprite.overrideStepTime = (stepTime + dragTargetCurrentStep).clamp(0, songLengthInSteps - (1 * noteSnapRatio));
            // Then reapply the note sprite's position relative to the grid.
            noteSprite.updateNotePosition(renderedNotes);
          }
          else
          {
            if (noteSprite.overrideStepTime != null)
            {
              // Reset the note's "ghost" step time.
              noteSprite.overrideStepTime = null;
              // Then reapply the note sprite's position relative to the grid.
              noteSprite.updateNotePosition(renderedNotes);
            }
          }

          // Determine if the note is being dragged and offset the horizontal position accordingly.
          if (dragTargetCurrentColumn != 0)
          {
            var data:Int = (noteSprite.noteData == null) ? 0 : noteSprite.noteData.data;
            // Update the note's "ghost" column.
            noteSprite.overrideData = gridColumnToNoteData((noteDataToGridColumn(data) + dragTargetCurrentColumn).clamp(0,
              ChartEditorState.STRUMLINE_SIZE * 2 - 1));
            // Then reapply the note sprite's position relative to the grid.
            noteSprite.updateNotePosition(renderedNotes);
          }
          else
          {
            if (noteSprite.overrideData != null)
            {
              // Reset the note's "ghost" column.
              noteSprite.overrideData = null;
              // Then reapply the note sprite's position relative to the grid.
              noteSprite.updateNotePosition(renderedNotes);
            }
          }

          // Then, render the selection square.
          var selectionSquare:ChartEditorSelectionSquareSprite = renderedSelectionSquares.recycle(buildSelectionSquare);

          // Set the position and size (because we might be recycling one with bad values).
          selectionSquare.noteData = noteSprite.noteData;
          selectionSquare.eventData = null;
          selectionSquare.x = noteSprite.x;
          selectionSquare.y = noteSprite.y;
          selectionSquare.width = GRID_SIZE;
          selectionSquare.height = GRID_SIZE;
        }
      }

      for (eventSprite in renderedEvents.members)
      {
        if (isEventSelected(eventSprite.eventData))
        {
          // Determine if the note is being dragged and offset the position accordingly.
          if (dragTargetCurrentStep > 0 || dragTargetCurrentColumn > 0)
          {
            var stepTime = (eventSprite.eventData == null) ? 0 : eventSprite.eventData.getStepTime();
            eventSprite.overrideStepTime = (stepTime + dragTargetCurrentStep).clamp(0, songLengthInSteps);
            // Then reapply the note sprite's position relative to the grid.
            eventSprite.updateEventPosition(renderedEvents);
          }
          else
          {
            if (eventSprite.overrideStepTime != null)
            {
              // Reset the note's "ghost" column.
              eventSprite.overrideStepTime = null;
              // Then reapply the note sprite's position relative to the grid.
              eventSprite.updateEventPosition(renderedEvents);
            }
          }

          // Then, render the selection square.
          var selectionSquare:ChartEditorSelectionSquareSprite = renderedSelectionSquares.recycle(buildSelectionSquare);

          // Set the position and size (because we might be recycling one with bad values).
          selectionSquare.noteData = null;
          selectionSquare.eventData = eventSprite.eventData;
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
  }

  /**
   * Handle keybinds for scrolling the chart editor grid.
   */
  function handleScrollKeybinds():Void
  {
    // Don't scroll when the user is interacting with the UI, unless a playbar button (the << >> ones) is pressed.
    if (isHaxeUIFocused && playbarButtonPressed == null) return;

    var scrollAmount:Float = 0; // Amount to scroll the grid.
    var playheadAmount:Float = 0; // Amount to scroll the playhead relative to the grid.
    var shouldPause:Bool = false; // Whether to pause the song when scrolling.
    var shouldEase:Bool = false; // Whether to ease the scroll.

    // Mouse Wheel = Scroll
    if (FlxG.mouse.wheel != 0 && !FlxG.keys.pressed.CONTROL)
    {
      scrollAmount = -50 * FlxG.mouse.wheel;
      shouldPause = true;
    }

    // Up Arrow = Scroll Up
    if (upKeyHandler.activated && currentLiveInputStyle == None)
    {
      scrollAmount = -GRID_SIZE * 0.25 * 25.0;
      shouldPause = true;
    }
    // Down Arrow = Scroll Down
    if (downKeyHandler.activated && currentLiveInputStyle == None)
    {
      scrollAmount = GRID_SIZE * 0.25 * 25.0;
      shouldPause = true;
    }

    // W = Scroll Up (doesn't work with Ctrl+Scroll)
    if (wKeyHandler.activated && currentLiveInputStyle == None && !FlxG.keys.pressed.CONTROL)
    {
      scrollAmount = -GRID_SIZE * 0.25 * 25.0;
      shouldPause = true;
    }
    // S = Scroll Down (doesn't work with Ctrl+Scroll)
    if (sKeyHandler.activated && currentLiveInputStyle == None && !FlxG.keys.pressed.CONTROL)
    {
      scrollAmount = GRID_SIZE * 0.25 * 25.0;
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
      scrollAmount *= 2;
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

  /**
   * Handle changing the note snapping level.
   */
  function handleSnap():Void
  {
    if (currentLiveInputStyle == None)
    {
      if (FlxG.keys.justPressed.LEFT && !FlxG.keys.pressed.CONTROL)
      {
        noteSnapQuantIndex--;
        if (noteSnapQuantIndex < 0) noteSnapQuantIndex = SNAP_QUANTS.length - 1;
      }

      if (FlxG.keys.justPressed.RIGHT && !FlxG.keys.pressed.CONTROL)
      {
        noteSnapQuantIndex++;
        if (noteSnapQuantIndex >= SNAP_QUANTS.length) noteSnapQuantIndex = 0;
      }
    }
  }

  /**
   * Handle display of the mouse cursor.
   */
  function handleCursor():Void
  {
    // Mouse sounds
    if (FlxG.mouse.justPressed) FlxG.sound.play(Paths.sound("chartingSounds/ClickDown"));
    if (FlxG.mouse.justReleased) FlxG.sound.play(Paths.sound("chartingSounds/ClickUp"));

    // Note: If a menu is open in HaxeUI, don't handle cursor behavior.
    var shouldHandleCursor:Bool = !isHaxeUIFocused
      || (selectionBoxStartPos != null)
      || (dragTargetNote != null || dragTargetEvent != null);
    var eventColumn:Int = (STRUMLINE_SIZE * 2 + 1) - 1;

    // trace('shouldHandleCursor: $shouldHandleCursor');

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

      var overlapsSelection:Bool = FlxG.mouse.overlaps(renderedSelectionSquares);

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
        else if (overlapsSelection)
        {
          // Do nothing
          trace('Clicked on a selected note!');
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
      var cursorGridPos:Int = Math.floor(cursorX / GRID_SIZE);
      var cursorColumn:Int = gridColumnToNoteData(cursorGridPos);

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
              moveSongToScrollPosition();
            }
            else if (FlxG.mouse.screenY > (playbarHeadLayout?.y ?? 0.0))
            {
              // Scroll down.
              var diff:Float = FlxG.mouse.screenY - (playbarHeadLayout?.y ?? 0.0);
              scrollPositionInPixels += diff * 0.5; // Too fast!
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
      else if (dragTargetNote != null || dragTargetEvent != null)
      {
        if (FlxG.mouse.justReleased)
        {
          // Perform the actual drag operation.
          var dragDistanceSteps:Float = dragTargetCurrentStep;
          var dragDistanceMs:Float = 0;
          if (dragTargetNote != null && dragTargetNote.noteData != null)
          {
            dragDistanceMs = Conductor.getStepTimeInMs(dragTargetNote.noteData.getStepTime() + dragDistanceSteps) - dragTargetNote.noteData.time;
          }
          else if (dragTargetEvent != null && dragTargetEvent.eventData != null)
          {
            dragDistanceMs = Conductor.getStepTimeInMs(dragTargetEvent.eventData.getStepTime() + dragDistanceSteps) - dragTargetEvent.eventData.time;
          }
          var dragDistanceColumns:Int = dragTargetCurrentColumn;

          if (currentNoteSelection.length > 0 && currentEventSelection.length > 0)
          {
            // Both notes and events are selected.
            performCommand(new MoveItemsCommand(currentNoteSelection, currentEventSelection, dragDistanceMs, dragDistanceColumns));
          }
          else if (currentNoteSelection.length > 0)
          {
            // Only notes are selected.
            performCommand(new MoveNotesCommand(currentNoteSelection, dragDistanceMs, dragDistanceColumns));
          }
          else if (currentEventSelection.length > 0)
          {
            // Only events are selected.
            performCommand(new MoveEventsCommand(currentEventSelection, dragDistanceMs));
          }

          // Finished dragging. Release the note at the new position.
          dragTargetNote = null;
          dragTargetEvent = null;

          noteDisplayDirty = true;

          dragTargetCurrentStep = 0;
          dragTargetCurrentColumn = 0;
        }
        else
        {
          // Player is clicking and holding on a selected note or event to move the selection around.
          targetCursorMode = Grabbing;

          // Scroll the screen if the mouse is above or below the grid.
          if (FlxG.mouse.screenY < MENU_BAR_HEIGHT)
          {
            // Scroll up.
            trace('Scroll up!');
            var diff:Float = MENU_BAR_HEIGHT - FlxG.mouse.screenY;
            scrollPositionInPixels -= diff * 0.5; // Too fast!
            moveSongToScrollPosition();
          }
          else if (FlxG.mouse.screenY > (playbarHeadLayout?.y ?? 0.0))
          {
            // Scroll down.
            trace('Scroll down!');
            var diff:Float = FlxG.mouse.screenY - (playbarHeadLayout?.y ?? 0.0);
            scrollPositionInPixels += diff * 0.5; // Too fast!
            moveSongToScrollPosition();
          }

          // Calculate distance between the position dragged to and the original position.
          var stepTime:Float = 0;
          if (dragTargetNote != null && dragTargetNote.noteData != null)
          {
            stepTime = dragTargetNote.noteData.getStepTime();
          }
          else if (dragTargetEvent != null && dragTargetEvent.eventData != null)
          {
            stepTime = dragTargetEvent.eventData.getStepTime();
          }
          var dragDistanceSteps:Float = Conductor.getTimeInSteps(cursorSnappedMs).clamp(0, songLengthInSteps - (1 * noteSnapRatio)) - stepTime;
          var data:Int = 0;
          var noteGridPos:Int = 0;
          if (dragTargetNote != null && dragTargetNote.noteData != null)
          {
            data = dragTargetNote.noteData.data;
            noteGridPos = noteDataToGridColumn(data);
          }
          else if (dragTargetEvent != null)
          {
            data = ChartEditorState.STRUMLINE_SIZE * 2 + 1;
          }
          var dragDistanceColumns:Int = cursorGridPos - noteGridPos;

          if (dragTargetCurrentStep != dragDistanceSteps || dragTargetCurrentColumn != dragDistanceColumns)
          {
            // Play a sound as we drag.
            this.playSound(Paths.sound('chartingSounds/noteLay'));

            trace('Dragged ${dragDistanceColumns} X and ${dragDistanceSteps} Y.');
            dragTargetCurrentStep = dragDistanceSteps;
            dragTargetCurrentColumn = dragDistanceColumns;

            noteDisplayDirty = true;
          }
        }
      }
      else if (currentPlaceNoteData != null)
      {
        // Handle extending the note as you drag.

        var stepTime:Float = inline currentPlaceNoteData.getStepTime();
        var dragLengthSteps:Float = Conductor.getTimeInSteps(cursorSnappedMs) - stepTime;
        var dragLengthMs:Float = dragLengthSteps * Conductor.stepLengthMs;
        var dragLengthPixels:Float = dragLengthSteps * GRID_SIZE;

        if (gridGhostNote != null && gridGhostNote.noteData != null && gridGhostHoldNote != null)
        {
          if (dragLengthSteps > 0)
          {
            if (dragLengthCurrent != dragLengthSteps)
            {
              stretchySounds = !stretchySounds;
              this.playSound(Paths.sound('chartingSounds/stretch' + (stretchySounds ? '1' : '2') + '_UI'));

              dragLengthCurrent = dragLengthSteps;
            }

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
        }

        if (FlxG.mouse.justReleased)
        {
          if (dragLengthSteps > 0)
          {
            this.playSound(Paths.sound('chartingSounds/stretchSNAP_UI'));
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
                if (isNoteSelected(highlightedNote.noteData))
                {
                  // Clicked a selected event, start dragging.
                  trace('Ready to drag!');
                  dragTargetNote = highlightedNote;
                }
                else
                {
                  // If you click an unselected note, and aren't holding Control, deselect everything else.
                  performCommand(new SetItemSelectionCommand([highlightedNote.noteData], [], currentNoteSelection, currentEventSelection));
                }
              }
              else if (highlightedEvent != null && highlightedEvent.eventData != null)
              {
                if (isEventSelected(highlightedEvent.eventData))
                {
                  // Clicked a selected event, start dragging.
                  trace('Ready to drag!');
                  dragTargetEvent = highlightedEvent;
                }
                else
                {
                  // If you click an unselected event, and aren't holding Control, deselect everything else.
                  performCommand(new SetItemSelectionCommand([], [highlightedEvent.eventData], currentNoteSelection, currentEventSelection));
                }
              }
              else
              {
                // Click a blank space to place a note and select it.

                if (cursorGridPos == eventColumn)
                {
                  // Create an event and place it in the chart.
                  // TODO: Figure out configuring event data.
                  var newEventData:SongEventData = new SongEventData(cursorSnappedMs, selectedEventKind, selectedEventData.clone());

                  performCommand(new AddEventsCommand([newEventData], FlxG.keys.pressed.CONTROL));
                }
                else
                {
                  // Create a note and place it in the chart.
                  var newNoteData:SongNoteData = new SongNoteData(cursorSnappedMs, cursorColumn, 0, selectedNoteKind.clone());

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

        var isOrWillSelect = overlapsSelection || dragTargetNote != null || dragTargetEvent != null;
        // Handle grid cursor.
        if (overlapsGrid && !isOrWillSelect && !overlapsSelectionBorder && !gridPlayheadScrollAreaPressed)
        {
          // Indicate that we can place a note here.

          if (cursorGridPos == eventColumn)
          {
            if (gridGhostNote != null) gridGhostNote.visible = false;
            if (gridGhostHoldNote != null) gridGhostHoldNote.visible = false;

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
          if (overlapsSelection)
          {
            targetCursorMode = Grabbing;
          }
          if (overlapsSelectionBorder)
          {
            targetCursorMode = Crosshair;
          }
        }
        else
        {
          if (notePreview != null && FlxG.mouse.overlaps(notePreview))
          {
            targetCursorMode = Pointer;
          }
          else if (gridPlayheadScrollArea != null && FlxG.mouse.overlaps(gridPlayheadScrollArea))
          {
            targetCursorMode = Pointer;
          }
          else if (overlapsSelection)
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
      var difficultyToolbox:Null<CollapsibleDialog> = this.getToolbox(CHART_EDITOR_TOOLBOX_DIFFICULTY_LAYOUT);
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

  function handlePlayerPreviewToolbox():Void
  {
    // Manage the Select Difficulty tree view.
    var charPreviewToolbox:Null<CollapsibleDialog> = this.getToolbox(CHART_EDITOR_TOOLBOX_PLAYER_PREVIEW_LAYOUT);
    if (charPreviewToolbox == null) return;

    // TODO: Re-enable the player preview once we figure out the performance issues.
    var charPlayer:Null<CharacterPlayer> = null; // charPreviewToolbox.findComponent('charPlayer');
    if (charPlayer == null) return;

    currentPlayerCharacterPlayer = charPlayer;

    if (playerPreviewDirty)
    {
      playerPreviewDirty = false;

      if (currentSongMetadata.playData.characters.player != charPlayer.charId)
      {
        if (healthIconBF != null) healthIconBF.characterId = currentSongMetadata.playData.characters.player;

        charPlayer.loadCharacter(currentSongMetadata.playData.characters.player);
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
    var charPreviewToolbox:Null<CollapsibleDialog> = this.getToolbox(CHART_EDITOR_TOOLBOX_OPPONENT_PREVIEW_LAYOUT);
    if (charPreviewToolbox == null) return;

    // TODO: Re-enable the player preview once we figure out the performance issues.
    var charPlayer:Null<CharacterPlayer> = null; // charPreviewToolbox.findComponent('charPlayer');
    if (charPlayer == null) return;

    currentOpponentCharacterPlayer = charPlayer;

    if (opponentPreviewDirty)
    {
      opponentPreviewDirty = false;

      if (currentSongMetadata.playData.characters.opponent != charPlayer.charId)
      {
        if (healthIconDad != null) healthIconDad.characterId = currentSongMetadata.playData.characters.opponent;

        charPlayer.loadCharacter(currentSongMetadata.playData.characters.opponent);
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
    if (playbarNoteSnap != null) playbarNoteSnap.text = '1/${noteSnapQuant}';
  }

  function handlePlayhead():Void
  {
    // Place notes at the playhead.
    switch (currentLiveInputStyle)
    {
      case ChartEditorLiveInputStyle.WASD:
        if (FlxG.keys.justPressed.A) placeNoteAtPlayhead(4);
        if (FlxG.keys.justPressed.S) placeNoteAtPlayhead(5);
        if (FlxG.keys.justPressed.W) placeNoteAtPlayhead(6);
        if (FlxG.keys.justPressed.D) placeNoteAtPlayhead(7);

        if (FlxG.keys.justPressed.LEFT) placeNoteAtPlayhead(0);
        if (FlxG.keys.justPressed.DOWN) placeNoteAtPlayhead(1);
        if (FlxG.keys.justPressed.UP) placeNoteAtPlayhead(2);
        if (FlxG.keys.justPressed.RIGHT) placeNoteAtPlayhead(3);
      case ChartEditorLiveInputStyle.NumberKeys:
        // Flipped because Dad is on the left but represents data 0-3.
        if (FlxG.keys.justPressed.ONE) placeNoteAtPlayhead(4);
        if (FlxG.keys.justPressed.TWO) placeNoteAtPlayhead(5);
        if (FlxG.keys.justPressed.THREE) placeNoteAtPlayhead(6);
        if (FlxG.keys.justPressed.FOUR) placeNoteAtPlayhead(7);

        if (FlxG.keys.justPressed.FIVE) placeNoteAtPlayhead(0);
        if (FlxG.keys.justPressed.SIX) placeNoteAtPlayhead(1);
        if (FlxG.keys.justPressed.SEVEN) placeNoteAtPlayhead(2);
        if (FlxG.keys.justPressed.EIGHT) placeNoteAtPlayhead(3);
      case ChartEditorLiveInputStyle.None:
        // Do nothing.
    }
  }

  function placeNoteAtPlayhead(column:Int):Void
  {
    var playheadPos:Float = scrollPositionInPixels + playheadPositionInPixels;
    var playheadPosFractionalStep:Float = playheadPos / GRID_SIZE / noteSnapRatio;
    var playheadPosStep:Int = Std.int(Math.floor(playheadPosFractionalStep));
    var playheadPosSnappedMs:Float = playheadPosStep * Conductor.stepLengthMs * noteSnapRatio;

    // Look for notes within 1 step of the playhead.
    var notesAtPos:Array<SongNoteData> = SongDataUtils.getNotesInTimeRange(currentSongChartNoteData, playheadPosSnappedMs,
      playheadPosSnappedMs + Conductor.stepLengthMs * noteSnapRatio);
    notesAtPos = SongDataUtils.getNotesWithData(notesAtPos, [column]);

    if (notesAtPos.length == 0)
    {
      var newNoteData:SongNoteData = new SongNoteData(playheadPosSnappedMs, column, 0, selectedNoteKind);
      performCommand(new AddNotesCommand([newNoteData], FlxG.keys.pressed.CONTROL));
    }
    else
    {
      trace('Already a note there.');
    }
  }

  /**
   * Handle aligning the health icons next to the grid.
   */
  function handleHealthIcons():Void
  {
    if (healthIconsDirty)
    {
      var charDataBF = CharacterDataParser.fetchCharacterData(currentSongMetadata.playData.characters.player);
      var charDataDad = CharacterDataParser.fetchCharacterData(currentSongMetadata.playData.characters.opponent);
      if (healthIconBF != null)
      {
        healthIconBF.configure(charDataBF?.healthIcon);
        healthIconBF.size *= 0.5; // Make the icon smaller in Chart Editor.
        healthIconBF.flipX = !healthIconBF.flipX; // BF faces the other way.
      }
      if (healthIconDad != null)
      {
        healthIconDad.configure(charDataDad?.healthIcon);
        healthIconDad.size *= 0.5; // Make the icon smaller in Chart Editor.
      }
      healthIconsDirty = false;
    }

    // Right align, and visibly center, the BF health icon.
    if (healthIconBF != null)
    {
      // Base X position to the right of the grid.
      healthIconBF.x = (gridTiledSprite == null) ? (0) : (gridTiledSprite.x + gridTiledSprite.width + 45 - (healthIconBF.width / 2));
      healthIconBF.y = (gridTiledSprite == null) ? (0) : (MENU_BAR_HEIGHT + GRID_TOP_PAD + 30 - (healthIconBF.height / 2));
    }

    // Visibly center the Dad health icon.
    if (healthIconDad != null)
    {
      healthIconDad.x = (gridTiledSprite == null) ? (0) : (gridTiledSprite.x - 45 - (healthIconDad.width / 2));
      healthIconDad.y = (gridTiledSprite == null) ? (0) : (MENU_BAR_HEIGHT + GRID_TOP_PAD + 30 - (healthIconDad.height / 2));
    }
  }

  /**
   * Handle keybinds for File menu items.
   */
  function handleFileKeybinds():Void
  {
    // CTRL + N = New Chart
    if (FlxG.keys.pressed.CONTROL && FlxG.keys.justPressed.N)
    {
      this.openWelcomeDialog(true);
    }

    // CTRL + O = Open Chart
    if (FlxG.keys.pressed.CONTROL && FlxG.keys.justPressed.O)
    {
      this.openBrowseFNFC(true);
    }

    if (FlxG.keys.pressed.CONTROL && FlxG.keys.justPressed.S)
    {
      if (currentWorkingFilePath == null || FlxG.keys.pressed.SHIFT)
      {
        // CTRL + SHIFT + S = Save As
        ChartEditorImportExportHandler.exportAllSongData(this, false);
      }
      else
      {
        // CTRL + S = Save Chart
        ChartEditorImportExportHandler.exportAllSongData(this, true, currentWorkingFilePath);
      }
    }

    if (FlxG.keys.pressed.CONTROL && FlxG.keys.pressed.SHIFT && FlxG.keys.justPressed.S)
    {
      this.exportAllSongData(false);
    }
    // CTRL + Q = Quit to Menu
    if (FlxG.keys.pressed.CONTROL && FlxG.keys.justPressed.Q)
    {
      quitChartEditor();
    }
  }

  @:nullSafety(Off)
  function quitChartEditor():Void
  {
    autoSave();
    stopWelcomeMusic();
    // TODO: PR Flixel to make onComplete nullable.
    if (audioInstTrack != null) audioInstTrack.onComplete = null;
    FlxG.switchState(new MainMenuState());

    resetWindowTitle();
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
      // CTRL + SHIFT + V = Paste Unsnapped.
      var targetMs:Float = if (FlxG.keys.pressed.SHIFT)
      {
        scrollPositionInMs + playheadPositionInMs;
      }
      else
      {
        var targetMs:Float = scrollPositionInMs + playheadPositionInMs;
        var targetStep:Float = Conductor.getTimeInSteps(targetMs);
        var targetSnappedStep:Float = Math.floor(targetStep / noteSnapRatio) * noteSnapRatio;
        var targetSnappedMs:Float = Conductor.getStepTimeInMs(targetSnappedStep);
        targetSnappedMs;
      }
      performCommand(new PasteItemsCommand(targetMs));
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
    if (currentLiveInputStyle == None)
    {
      if (FlxG.keys.pressed.CONTROL && FlxG.keys.justPressed.LEFT)
      {
        incrementDifficulty(-1);
      }
      if (FlxG.keys.pressed.CONTROL && FlxG.keys.justPressed.RIGHT)
      {
        incrementDifficulty(1);
      }
      // Would bind Ctrl+A and Ctrl+D here, but they are already bound to Select All and Select None.
    }
  }

  /**
   * Handle keybinds for the Test menu items.
   */
  function handleTestKeybinds():Void
  {
    if (!isHaxeUIDialogOpen && !isHaxeUIFocused && FlxG.keys.justPressed.ENTER)
    {
      var minimal = FlxG.keys.pressed.SHIFT;
      this.hideAllToolboxes();
      testSongInPlayState(minimal);
    }
  }

  /**
   * Handle keybinds for Help menu items.
   */
  function handleHelpKeybinds():Void
  {
    // F1 = Open Help
    if (FlxG.keys.justPressed.F1) this.openUserGuideDialog();
  }

  override function handleQuickWatch():Void
  {
    super.handleQuickWatch();

    FlxG.watch.addQuick('scrollPosInPixels', scrollPositionInPixels);
    FlxG.watch.addQuick('playheadPosInPixels', playheadPositionInPixels);

    FlxG.watch.addQuick("tapNotesRendered", renderedNotes.members.length);
    FlxG.watch.addQuick("holdNotesRendered", renderedHoldNotes.members.length);
    FlxG.watch.addQuick("eventsRendered", renderedEvents.members.length);
    FlxG.watch.addQuick("notesSelected", currentNoteSelection.length);
    FlxG.watch.addQuick("eventsSelected", currentEventSelection.length);
  }

  /**
   * PLAYTEST FUNCTIONS
   */
  // ====================

  /**
   * Transitions to the Play State to test the song
   */
  function testSongInPlayState(minimal:Bool = false):Void
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
    subStateClosed.add(resetConductorAfterTest);

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

  /**
   * COMMAND FUNCTIONS
   */
  // ====================

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

  /**
   * GRAPHICS FUNCTIONS
   */
  // ====================

  /**
   * This is for the smaller green squares that appear over each note when you select them.
   */
  function buildSelectionSquare():ChartEditorSelectionSquareSprite
  {
    if (selectionSquareBitmap == null)
      throw "ERROR: Tried to build selection square, but selectionSquareBitmap is null! Check ChartEditorThemeHandler.updateSelectionSquare()";

    // FlxG.bitmapLog.add(selectionSquareBitmap, "selectionSquareBitmap");
    var result = new ChartEditorSelectionSquareSprite();
    result.loadGraphic(selectionSquareBitmap);
    return result;
  }

  /**
   * Fix a camera issue caused when closing the PlayState used when testing.
   */
  function fixCamera(_:FlxSubState = null):Void
  {
    FlxG.cameras.reset(new FlxCamera());
    FlxG.camera.focusOn(new FlxPoint(FlxG.width / 2, FlxG.height / 2));
    FlxG.camera.zoom = 1.0;

    add(this.component);
  }

  /**
   * AUDIO FUNCTIONS
   */
  // ====================

  function startAudioPlayback():Void
  {
    if (audioInstTrack != null)
    {
      audioInstTrack.play(false, audioInstTrack.time);
      if (audioVocalTrackGroup != null) audioVocalTrackGroup.play(false, audioInstTrack.time);
    }

    setComponentText('playbarPlay', '||');
  }

  /**
   * Play the metronome tick sound.
   * @param high Whether to play the full beat sound rather than the quarter beat sound.
   */
  function playMetronomeTick(high:Bool = false):Void
  {
    this.playSound(Paths.sound('chartingSounds/metronome${high ? '1' : '2'}'));
  }

  function switchToCurrentInstrumental():Void
  {
    // ChartEditorAudioHandler
    this.switchToInstrumental(currentInstrumentalId, currentSongMetadata.playData.characters.player, currentSongMetadata.playData.characters.opponent);
  }

  /**
   * CHART DATA FUNCTIONS
   */
  // ====================

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

  function isEventSelected(event:Null<SongEventData>):Bool
  {
    return event != null && currentEventSelection.indexOf(event) != -1;
  }

  function createDifficulty(variation:String, difficulty:String, scrollSpeed:Float = 1.0)
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
        expiryMs: Constants.NOTIFICATION_DISMISS_TIME
      });
    #end
  }

  /**
   * SCROLLING FUNCTIONS
   */
  // ====================

  /**
   * When setting the scroll position, except when automatically scrolling during song playback,
   * we need to update the conductor's current step time and the timestamp of the audio tracks.
   */
  function moveSongToScrollPosition():Void
  {
    // Update the songPosition in the audio tracks.
    if (audioInstTrack != null)
    {
      audioInstTrack.time = scrollPositionInMs + playheadPositionInMs;
      // Update the songPosition in the Conductor.
      Conductor.update(audioInstTrack.time);
    }
    if (audioVocalTrackGroup != null) audioVocalTrackGroup.time = scrollPositionInMs + playheadPositionInMs;

    // We need to update the note sprites because we changed the scroll position.
    noteDisplayDirty = true;
  }

  /**
   * Smoothly ease the song to a new scroll position over a duration.
   * @param targetScrollPosition The desired value for the `scrollPositionInPixels`.
   */
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

  /**
   * Callback function executed every frame that the scroll position is being eased.
   * @param _
   */
  function onScrollEaseUpdate(_:FlxTween):Void
  {
    moveSongToScrollPosition();
  }

  /**
   * Callback function executed when cancelling an existing scroll position ease.
   * Ensures that the ease is immediately cancelled and the scroll position is set to the target value.
   */
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
   * Fix the current scroll position after exiting the PlayState used when testing.
   */
  @:nullSafety(Off)
  function resetConductorAfterTest(_:FlxSubState = null):Void
  {
    moveSongToScrollPosition();

    var instVolumeSlider:Null<Slider> = findComponent('menubarItemVolumeInstrumental', Slider);
    var vocalVolumeSlider:Null<Slider> = findComponent('menubarItemVolumeVocals', Slider);

    // Reapply the volume.
    var instTargetVolume:Float = instVolumeSlider?.value ?? 1.0;
    var vocalTargetVolume:Float = vocalVolumeSlider?.value ?? 1.0;

    if (audioInstTrack != null)
    {
      audioInstTrack.volume = instTargetVolume;
      audioInstTrack.onComplete = null;
    }
    if (audioVocalTrackGroup != null) audioVocalTrackGroup.volume = vocalTargetVolume;
  }

  /**
   * HAXEUI FUNCTIONS
   */
  // ====================

  /**
   * Set the currently selected item in the Difficulty tree view to the node representing the current difficulty.
   * @param treeView The tree view to update. If `null`, the tree view will be found.
   */
  function refreshDifficultyTreeSelection(?treeView:TreeView):Void
  {
    if (treeView == null)
    {
      // Manage the Select Difficulty tree view.
      var difficultyToolbox:Null<CollapsibleDialog> = this.getToolbox(CHART_EDITOR_TOOLBOX_DIFFICULTY_LAYOUT);
      if (difficultyToolbox == null) return;

      treeView = difficultyToolbox.findComponent('difficultyToolboxTree');
      if (treeView == null) return;
    }

    var currentTreeDifficultyNode = getCurrentTreeDifficultyNode(treeView);
    if (currentTreeDifficultyNode != null) treeView.selectedNode = currentTreeDifficultyNode;
  }

  /**
   * Retrieve the node representing the current difficulty in the Difficulty tree view.
   * @param treeView The tree view to search. If `null`, the tree view will be found.
   * @return The node representing the current difficulty, or `null` if not found.
   */
  function getCurrentTreeDifficultyNode(?treeView:TreeView = null):Null<TreeViewNode>
  {
    if (treeView == null)
    {
      var difficultyToolbox:Null<CollapsibleDialog> = this.getToolbox(CHART_EDITOR_TOOLBOX_DIFFICULTY_LAYOUT);
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
    var toolbox:Null<CollapsibleDialog> = this.getToolbox(CHART_EDITOR_TOOLBOX_METADATA_LAYOUT);
    if (toolbox == null) return;

    var inputSongName:Null<TextField> = toolbox.findComponent('inputSongName', TextField);
    if (inputSongName != null) inputSongName.value = currentSongMetadata.songName;

    var inputSongArtist:Null<TextField> = toolbox.findComponent('inputSongArtist', TextField);
    if (inputSongArtist != null) inputSongArtist.value = currentSongMetadata.artist;

    var inputStage:Null<DropDown> = toolbox.findComponent('inputStage', DropDown);
    if (inputStage != null) inputStage.value = currentSongMetadata.playData.stage;

    var inputNoteStyle:Null<DropDown> = toolbox.findComponent('inputNoteStyle', DropDown);
    if (inputNoteStyle != null) inputNoteStyle.value = currentSongMetadata.playData.noteStyle;

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
    if (inputStage != null)
    {
      inputStage.value = (stageData != null) ?
        {id: stageId, text: stageData.name} :
          {id: "mainStage", text: "Main Stage"};
    }

    var inputCharacterPlayer:Null<DropDown> = toolbox.findComponent('inputCharacterPlayer', DropDown);
    var charIdPlayer:String = currentSongMetadata.playData.characters.player;
    var charDataPlayer:Null<CharacterData> = CharacterDataParser.fetchCharacterData(charIdPlayer);
    if (inputCharacterPlayer != null)
    {
      inputCharacterPlayer.value = (charDataPlayer != null) ?
        {id: charIdPlayer, text: charDataPlayer.name} :
          {id: "bf", text: "Boyfriend"};
    }

    var inputCharacterOpponent:Null<DropDown> = toolbox.findComponent('inputCharacterOpponent', DropDown);
    var charIdOpponent:String = currentSongMetadata.playData.characters.opponent;
    var charDataOpponent:Null<CharacterData> = CharacterDataParser.fetchCharacterData(charIdOpponent);
    if (inputCharacterOpponent != null)
    {
      inputCharacterOpponent.value = (charDataOpponent != null) ?
        {id: charIdOpponent, text: charDataOpponent.name} :
          {id: "dad", text: "Dad"};
    }

    var inputCharacterGirlfriend:Null<DropDown> = toolbox.findComponent('inputCharacterGirlfriend', DropDown);
    var charIdGirlfriend:String = currentSongMetadata.playData.characters.girlfriend;
    var charDataGirlfriend:Null<CharacterData> = CharacterDataParser.fetchCharacterData(charIdGirlfriend);
    if (inputCharacterGirlfriend != null)
    {
      inputCharacterGirlfriend.value = (charDataGirlfriend != null) ?
        {id: charIdGirlfriend, text: charDataGirlfriend.name} :
          {id: "none", text: "None"};
    }
  }

  /**
   * STATIC FUNCTIONS
   */
  // ====================

  /**
   * Dismiss any existing HaxeUI notifications, if there are any.
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
      var event:NoteScriptEvent = new NoteScriptEvent(NOTE_HIT, tempNote, 1, true);
      dispatchEvent(event);

      // Calling event.cancelEvent() skips all the other logic! Neat!
      if (event.eventCanceled) continue;

      // Hitsounds.
      switch (noteData.getStrumlineIndex())
      {
        case 0: // Player
          if (hitsoundsEnabledPlayer) ChartEditorAudioHandler.playSound(this, Paths.sound('chartingSounds/hitNotePlayer'));
        case 1: // Opponent
          if (hitsoundsEnabledOpponent) ChartEditorAudioHandler.playSound(this, Paths.sound('chartingSounds/hitNoteOpponent'));
      }
    }
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
    }
    else
    {
      trace('[WARN] Instrumental track was null!');
    }

    // Pretty much everything is going to need to be reset.
    scrollPositionInPixels = 0;
    playheadPositionInPixels = 0;
    notePreviewDirty = true;
    notePreviewViewportBoundsDirty = true;
    noteDisplayDirty = true;
    healthIconsDirty = true;
    moveSongToScrollPosition();
  }

  /**
   * Clear the voices group.
   */
  public function clearVocals():Void
  {
    if (audioVocalTrackGroup != null) audioVocalTrackGroup.clear();
  }

  function isNoteSelected(note:Null<SongNoteData>):Bool
  {
    return note != null && currentNoteSelection.indexOf(note) != -1;
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

  function applyCanQuickSave():Void
  {
    if (menubarItemSaveChart == null) return;

    if (currentWorkingFilePath == null)
    {
      menubarItemSaveChart.disabled = true;
    }
    else
    {
      menubarItemSaveChart.disabled = false;
    }
  }

  function applyWindowTitle():Void
  {
    var inner:String = 'New Chart';
    var cwfp:Null<String> = currentWorkingFilePath;
    if (cwfp != null)
    {
      inner = cwfp;
    }
    if (currentWorkingFilePath == null || saveDataDirty)
    {
      inner += '*';
    }
    WindowUtil.setWindowTitle('Friday Night Funkin\' Chart Editor - ${inner}');
  }

  function resetWindowTitle():Void
  {
    WindowUtil.setWindowTitle('Friday Night Funkin\'');
  }

  /**
   * Convert a note data value into a chart editor grid column number.
   */
  public static function noteDataToGridColumn(input:Int):Int
  {
    if (input < 0) input = 0;
    if (input >= (ChartEditorState.STRUMLINE_SIZE * 2 + 1))
    {
      // Don't invert the Event column.
      input = (ChartEditorState.STRUMLINE_SIZE * 2 + 1);
    }
    else
    {
      // Invert player and opponent columns.
      if (input >= ChartEditorState.STRUMLINE_SIZE)
      {
        input -= ChartEditorState.STRUMLINE_SIZE;
      }
      else
      {
        input += ChartEditorState.STRUMLINE_SIZE;
      }
    }
    return input;
  }

  /**
   * Convert a chart editor grid column number into a note data value.
   */
  public static function gridColumnToNoteData(input:Int):Int
  {
    if (input < 0) input = 0;
    if (input >= (ChartEditorState.STRUMLINE_SIZE * 2 + 1))
    {
      // Don't invert the Event column.
      input = (ChartEditorState.STRUMLINE_SIZE * 2 + 1);
    }
    else
    {
      // Invert player and opponent columns.
      if (input >= ChartEditorState.STRUMLINE_SIZE)
      {
        input -= ChartEditorState.STRUMLINE_SIZE;
      }
      else
      {
        input += ChartEditorState.STRUMLINE_SIZE;
      }
    }
    return input;
  }
}

/**
 * Available input modes for the chart editor state.
 */
enum ChartEditorLiveInputStyle
{
  /**
   * No hotkeys to place notes at the playbar.
   */
  None;

  /**
   * 1/2/3/4 to place notes on opponent's side, 5/6/7/8 to place notes on player's side.
   */
  NumberKeys;

  /**
   * WASD to place notes on opponent's side, arrow keys to place notes on player's side.
   */
  WASD;
}

typedef ChartEditorParams =
{
  /**
   * If non-null, load this song immediately instead of the welcome screen.
   */
  var ?fnfcTargetPath:String;

  /**
   * If non-null, load this song immediately instead of the welcome screen.
   */
  var ?targetSongId:String;
};

/**
 * Available themes for the chart editor state.
 */
enum ChartEditorTheme
{
  /**
   * The default theme for the chart editor.
   */
  Light;

  /**
   * A theme which introduces darker colors.
   */
  Dark;
}
