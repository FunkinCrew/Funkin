package funkin.ui.debug.charting;

import funkin.ui.transition.Transition;
#if FEATURE_CHART_EDITOR
import flixel.FlxBasic;
import flixel.FlxCamera;
import flixel.FlxSprite;
import flixel.FlxSubState;
import flixel.addons.display.FlxSliceSprite;
import flixel.addons.transition.FlxTransitionableState;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.group.FlxSpriteGroup;
import flixel.input.gamepad.FlxGamepadInputID;
import flixel.input.keyboard.FlxKey;
import flixel.input.mouse.FlxMouseEvent;
import flixel.math.FlxMath;
import flixel.math.FlxPoint;
import flixel.math.FlxRect;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import funkin.assets.FunkinAssetCache;
import flixel.util.FlxSort;
import flixel.util.FlxStringUtil;
import flixel.util.FlxTimer;
import funkin.util.FlxStateUtil;
import funkin.assets.Assets.AssetType;
import funkin.assets.Paths.AssetPath;
import funkin.audio.FunkinSound;
import funkin.audio.VoicesGroup;
import funkin.data.character.CharacterRegistry;
import funkin.data.notestyle.NoteStyleRegistry;
import funkin.data.song.SongData.NoteParamData;
import funkin.data.song.SongData.SongChartData;
import funkin.data.song.SongData.SongChartEditorData;
import funkin.data.song.SongData.SongEventData;
import funkin.data.song.SongData.SongMetadata;
import funkin.data.song.SongData.SongNoteData;
import funkin.data.song.SongData.SongOffsets;
import funkin.data.song.SongData.CommentData;
import funkin.data.song.SongDataUtils;
import funkin.data.song.SongNoteDataUtils;
import funkin.data.song.importer.ChartManifestData;
import funkin.graphics.FunkinCamera;
import funkin.graphics.FunkinSprite;
import funkin.input.Cursor;
import funkin.input.TurboButtonHandler;
import funkin.input.TurboKeyHandler;
import funkin.modding.events.ScriptEvent;
import funkin.play.PlayState;
import funkin.play.PlayStatePlaylist;
import funkin.play.character.BaseCharacter.CharacterType;
import funkin.play.components.HealthIcon;
import funkin.play.components.Subtitles;
import funkin.play.event.SongEvent;
import funkin.play.notes.NoteSprite;
import funkin.play.notes.notekind.NoteKindManager;
import funkin.play.song.Song;
import funkin.play.stage.Stage;
import funkin.save.Save;
import funkin.ui.debug.FunkinDebugDisplay.DebugDisplayMode;
import funkin.ui.debug.cameraeditor.CameraEditorState;
import funkin.ui.debug.charting.commands.comments.AddCommentCommand;
import funkin.ui.debug.charting.commands.events.AddEventsCommand;
import funkin.ui.debug.charting.commands.timing.AddNewTimeChangeCommand;
import funkin.ui.debug.charting.commands.notes.AddNotesCommand;
import funkin.ui.debug.charting.commands.ChartEditorCommand;
import funkin.ui.debug.charting.util.ChartEditorScaleMode;
import funkin.ui.debug.charting.commands.items.CopyItemsCommand;
import funkin.ui.debug.charting.commands.items.CutItemsCommand;
import funkin.ui.debug.charting.commands.selection.DeselectAllItemsBetweenTimeCommand;
import funkin.ui.debug.charting.commands.selection.DeselectAllItemsCommand;
import funkin.ui.debug.charting.commands.selection.DeselectItemsCommand;
import funkin.ui.debug.charting.commands.notes.ExtendNoteLengthCommand;
import funkin.ui.debug.charting.commands.notes.FlipNotesCommand;
import funkin.ui.debug.charting.commands.selection.InvertSelectedItemsCommand;
import funkin.ui.debug.charting.commands.notes.MirrorNotesCommand;
import funkin.ui.debug.charting.commands.events.MoveEventsCommand;
import funkin.ui.debug.charting.commands.items.MoveItemsCommand;
import funkin.ui.debug.charting.commands.notes.MoveNotesCommand;
import funkin.ui.debug.charting.commands.items.PasteItemsCommand;
import funkin.ui.debug.charting.commands.events.RemoveEventsCommand;
import funkin.ui.debug.charting.commands.items.RemoveItemsCommand;
import funkin.ui.debug.charting.commands.notes.RemoveNotesCommand;
import funkin.ui.debug.charting.commands.notes.RemoveStackedNotesCommand;
import funkin.ui.debug.charting.commands.selection.SelectAllItemsBetweenTimeCommand;
import funkin.ui.debug.charting.commands.selection.SelectAllItemsCommand;
import funkin.ui.debug.charting.commands.selection.SelectItemsCommand;
import funkin.ui.debug.charting.commands.selection.SetItemSelectionCommand;
import funkin.ui.debug.charting.commands.song.SwitchDifficultyCommand;
import funkin.ui.debug.charting.components.palette.ChartEditorCommandPalette;
import funkin.ui.debug.charting.components.comments.ChartEditorCommentPanel;
import funkin.ui.debug.charting.components.comments.ChartEditorCommentPinSprite;
import funkin.ui.debug.charting.components.notes.ChartEditorEventSprite;
import funkin.ui.debug.charting.components.notes.ChartEditorHoldNoteSprite;
import funkin.ui.debug.charting.components.grid.ChartEditorGridLines;
import funkin.ui.debug.charting.components.grid.ChartEditorWaveformSprite;
import funkin.ui.debug.charting.components.grid.ChartEditorMeasureTicks;
import funkin.ui.debug.charting.components.grid.ChartEditorDifficultyHeatmap;
import funkin.ui.debug.charting.selection.ChartEditorCommentItems;
import funkin.ui.debug.charting.selection.ChartEditorSelectable;
import funkin.ui.debug.charting.selection.ChartEditorSubBeatItems;
import funkin.ui.debug.charting.selection.ChartEditorTimeChangeItems;
import funkin.ui.debug.charting.components.playbar.ChartEditorNotePreview;
import funkin.ui.debug.charting.components.notes.ChartEditorNoteSprite;
import funkin.ui.debug.charting.components.playbar.ChartEditorPlaybarHead;
import funkin.ui.debug.charting.components.grid.ChartEditorSelectionSquareSprite;
import funkin.ui.debug.charting.handlers.ui.ChartEditorToolboxHandler;
import funkin.ui.debug.charting.toolboxes.ChartEditorDifficultyToolbox;
import funkin.ui.debug.charting.toolboxes.ChartEditorListKeyTarget;
import funkin.ui.debug.charting.toolboxes.ChartEditorEventDataToolbox;
import funkin.ui.debug.charting.toolboxes.ChartEditorTimingToolbox;
import funkin.ui.haxeui.components.CharacterPlayer;
import funkin.ui.mainmenu.MainMenuState;
import funkin.ui.transition.preload.hotreload.HotReloadState.HotReloadStateParams;
import funkin.util.Constants;
import funkin.util.FileUtil;
import funkin.util.MathUtil;
import funkin.util.SortUtil;
import funkin.util.WindowUtil;
import funkin.util.file.FNFCUtil.FNFCData;
import funkin.util.logging.CrashHandler;
import haxe.DynamicAccess;
import haxe.io.Bytes;
import haxe.io.Path;
import haxe.ui.Toolkit;
import haxe.ui.backend.flixel.UIState;
import haxe.ui.components.Button;
import haxe.ui.components.DropDown;
import haxe.ui.components.Label;
import haxe.ui.components.NumberStepper;
import haxe.ui.components.Range;
import haxe.ui.components.Slider;
import haxe.ui.components.TextArea;
import haxe.ui.components.VerticalScroll;
import haxe.ui.containers.dialogs.CollapsibleDialog;
import haxe.ui.containers.dialogs.Dialog;
import haxe.ui.containers.menus.Menu;
import haxe.ui.containers.menus.MenuBar;
import haxe.ui.containers.menus.MenuCheckBox;
import haxe.ui.containers.menus.MenuItem;
import haxe.ui.core.Screen;
import haxe.ui.dragdrop.DragManager;
import haxe.ui.events.DragEvent;
import haxe.ui.events.MouseEvent;
import haxe.ui.events.UIEvent;
import haxe.ui.focus.FocusManager;
import haxe.ui.tooltips.ToolTipManager;
import openfl.display.BitmapData;
import funkin.assets.Assets;
import funkin.assets.ValidatedPaths as Paths;

using Lambda;

/**
 * A state dedicated to allowing the user to create and edit song charts.
 * Built with HaxeUI for use by both developers and modders.
 *
 * Some functionality is split into handler classes to help maintain my sanity.
 *
 * @author EliteMasterEric
 */
// @:nullSafety

@:build(haxe.ui.ComponentBuilder.build('assets/exclude/ui/editors/chart-editor/main-view.xml'))
@:access(haxe.ui.tooltips.ToolTipManager)
@:access(funkin.audio.VoicesGroup)
class ChartEditorState extends UIState // UIState derives from MusicBeatState
{
  /**
   * CONSTANTS
   */
  // ==============================
  // Layouts
  public static final CHART_EDITOR_TOOLBOX_DIFFICULTY_LAYOUT:String = Paths.xml('exclude/ui/editors/chart-editor/toolboxes/difficulty').toString();

  public static final CHART_EDITOR_TOOLBOX_PLAYER_PREVIEW_LAYOUT:String = Paths.xml('ui/editors/chart-editor/toolbox/player-preview').toString();
  public static final CHART_EDITOR_TOOLBOX_OPPONENT_PREVIEW_LAYOUT:String = Paths.xml('ui/editors/chart-editor/toolbox/opponent-preview').toString();
  public static final CHART_EDITOR_TOOLBOX_METADATA_LAYOUT:String = Paths.xml('exclude/ui/editors/chart-editor/toolboxes/metadata').toString();
  public static final CHART_EDITOR_TOOLBOX_TIMING_LAYOUT:String = Paths.xml('exclude/ui/editors/chart-editor/toolboxes/timing').toString();
  public static final CHART_EDITOR_TOOLBOX_NOTE_DATA_LAYOUT:String = Paths.xml('exclude/ui/editors/chart-editor/toolboxes/note-data').toString();
  public static final CHART_EDITOR_TOOLBOX_EVENT_DATA_LAYOUT:String = Paths.xml('exclude/ui/editors/chart-editor/toolboxes/event-data').toString();
  public static final CHART_EDITOR_TOOLBOX_PREFERENCES_LAYOUT:String = Paths.xml('ui/editors/chart-editor/toolbox/preferences').toString();
  // Validation
  public static final SUPPORTED_MUSIC_FORMATS:Array<String> = ['ogg'];
  // Layout

  /**
   * The base grid size for the chart editor.
   */
  public static final GRID_SIZE:Int = 40;

  /**
   * Zoom levels the grid can be scaled to.
   */
  public static final ZOOM_LEVELS:Array<Float> = [0.1, 0.15, 0.25, 0.375, 0.5, 0.75, 1, 1.5, 2, 3, 4, 6, 8];

  /**
   * The index of the default zoom level in `ZOOM_LEVELS`.
   */
  public static final BASE_ZOOM_INDEX:Int = 6;

  /**
   * Duration, in seconds, for easing between zoom levels.
   */
  public static final ZOOM_EASE_DURATION:Float = 0.15;

  /**
   * The width of the scroll area.
   */
  public static final PLAYHEAD_SCROLL_AREA_WIDTH:Int = Std.int(GRID_SIZE);

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
   * The height of the note selection buttons above the grid.
   */
  public static final NOTE_SELECT_BUTTON_HEIGHT:Int = 32;

  /**
   * The Y position of the note selection buttons, just under the menu bar.
   */
  public static final NOTE_SELECT_BUTTON_Y:Int = MENU_BAR_HEIGHT + 4;

  /**
   * Space between the note selection buttons and the playhead.
   */
  public static final GRID_PLAYHEAD_MARGIN:Int = Std.int(GRID_SIZE * 1.5);

  /**
   * The amount of padding between the menu bar and the chart grid when fully scrolled up.
   */
  public static final GRID_TOP_PAD:Int = NOTE_SELECT_BUTTON_HEIGHT + 4 + GRID_PLAYHEAD_MARGIN;

  /**
   * The initial vertical position of the chart grid.
   */
  public static final GRID_INITIAL_Y_POS:Int = MENU_BAR_HEIGHT + GRID_TOP_PAD;

  /**
   * The X position of the note preview area.
   */
  public static final NOTE_PREVIEW_X_POS:Int = 320;

  /**
   * The Y position of the note preview area.
   */
  public static final NOTE_PREVIEW_Y_POS:Int = NOTE_SELECT_BUTTON_Y + 4;

  /**
   * The X position of the note grid.
   */
  public static var GRID_X_POS(get, never):Float;

  static function get_GRID_X_POS():Float
  {
    return FlxG.width / 2 - GRID_SIZE * STRUMLINE_SIZE;
  }

  // Colors
  // Background color tint.
  public static final CURSOR_COLOR:FlxColor = 0xE0FFFFFF;
  public static final CURSOR_LINE_COLOR:FlxColor = 0xFFE0A030;
  public static final PREVIEW_BG_COLOR:FlxColor = 0xFF303030;
  public static final PLAYHEAD_SCROLL_AREA_COLOR:FlxColor = 0xFF682B2F;
  public static final SPECTROGRAM_COLOR:FlxColor = 0xFFFF0000;
  public static final PLAYHEAD_COLOR:FlxColor = 0xC0BD0231;
  // Timings

  /**
   * Duration, in seconds, for the scroll easing animation.
   */
  public static final SCROLL_EASE_DURATION:Float = 0.4;

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
  public static final SNAP_QUANTS:Array<Int> = [
    4,
    8,
    12,
    16,
    20,
    24,
    32,
    48,
    64,
    96,
    192
  ];

  /**
   * The default note snapping value.
   */
  public static final BASE_QUANT:Int = 16;

  /**
   * The index of thet default note snapping value in the `SNAP_QUANTS` array.
   */
  public static final BASE_QUANT_INDEX:Int = 3;

  /**
   * A map of the keys for every live input style.
   */
  public static final LIVE_INPUT_KEYS:Map<ChartEditorLiveInputStyle, Array<FlxKey>> = [
    NumberKeys => [
      FIVE, SIX, SEVEN, EIGHT,
       ONE, TWO, THREE,  FOUR
    ],
    WASDKeys => [
      LEFT, DOWN, UP, RIGHT,
         A,    S,  W,     D
    ],
    None => []
  ];

  /**
   * INSTANCE DATA
   */
  // ==============================
  // Song Length

  /**
   * The length of the current instrumental, in milliseconds.
   */
  @:isVar
  var songLengthInMs(get, set):Float = 0;

  function get_songLengthInMs():Float
  {
    if (songLengthInMs <= 0) return 1000;
    return songLengthInMs;
  }

  function set_songLengthInMs(value:Float):Float
  {
    this.songLengthInMs = value;

    resetPreviewTimes();
    this.updateGridHeight();
    scrollPositionInPixels = 0;
    playheadPositionInPixels = 0;

    return this.songLengthInMs;
  }

  inline function clamp(value:Float, min:Float, max:Float):Float
  {
    return Math.max(min, Math.min(value, max));
  }

  /**
   * The length of the current instrumental, converted to steps.
   * Dependent on BPM, because the size of a grid square does not change with BPM but the length of a beat does.
   */
  var songLengthInSteps(get, set):Float;

  function get_songLengthInSteps():Float
  {
    return Conductor.instance.getTimeInSteps(songLengthInMs);
  }

  function set_songLengthInSteps(value:Float):Float
  {
    // Getting a reasonable result from setting songLengthInSteps requires that Conductor.instance.mapBPMChanges be called first.
    songLengthInMs = Conductor.instance.getStepTimeInMs(value);
    return value;
  }

  /**
   * The length of the chart grid, in steps.
   * This is `songLengthInSteps` rounded up, so the last row of the grid doesn't cut off weirdly.
   */
  var gridLengthInSteps(get, never):Float;

  function get_gridLengthInSteps():Float
  {
    return Math.ceil(songLengthInSteps);
  }

  /**
   * Last step a note can be snapped to while still fitting on the grid.
   * Dependent on the current note snap.
   */
  var lastSnappedGridStep(get, never):Float;

  function get_lastSnappedGridStep():Float
  {
    return Math.floor((gridLengthInSteps - 1) / noteSnapRatio) * noteSnapRatio;
  }

  /**
   * The length of the chart grid, in PIXELS.
   * Dependent on BPM, because the size of a grid square does not change with BPM but the length of a beat does.
   */
  var songLengthInPixels(get, set):Int;

  function get_songLengthInPixels():Int
  {
    return Std.int(ChartEditorTimeScale.stepToPixels(gridLengthInSteps));
  }

  function set_songLengthInPixels(value:Int):Int
  {
    songLengthInSteps = ChartEditorTimeScale.pixelsToStep(value);
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

    // Make sure playhead doesn't scroll outside the song.
    if (value + playheadPositionInPixels < 0) playheadPositionInPixels = -value;
    if (value + playheadPositionInPixels > songLengthInPixels) playheadPositionInPixels = songLengthInPixels - value;

    if (value > songLengthInPixels) value = songLengthInPixels;

    if (value == scrollPositionInPixels) return value;

    // Difference in pixels.
    var diff:Float = value - scrollPositionInPixels;

    this.scrollPositionInPixels = value;

    // Move the grid sprite to the correct position.
    if (gridTiledSprite != null && measureTicks != null)
    {
      gridTiledSprite.y = -scrollPositionInPixels + (GRID_INITIAL_Y_POS);

      // The waveforms only rebuild when the view leaves the chunk they cover.
      for (member in audioWaveforms.members)
      {
        if (member != null) member.refresh(gridTiledSprite.y);
      }
    }

    // Move the rendered notes to the correct position.
    renderedNotes.setPosition(gridTiledSprite?.x ?? 0.0, gridTiledSprite?.y ?? 0.0);
    renderedHoldNotes.setPosition(gridTiledSprite?.x ?? 0.0, gridTiledSprite?.y ?? 0.0);
    renderedEvents.setPosition(gridTiledSprite?.x ?? 0.0, gridTiledSprite?.y ?? 0.0);
    renderedSelectionSquares.setPosition(gridTiledSprite?.x ?? 0.0, gridTiledSprite?.y ?? 0.0);
    gridLines?.refresh(gridLinesDirty);
    gridLinesDirty = false;
    // Offset the selection box start position, if we are dragging.
    if (selectionBoxStartPos != null) selectionBoxStartPos.y -= diff;

    // Update the note preview.
    this.setNotePreviewViewportBounds(this.calculateNotePreviewViewportBounds());
    this.refreshNotePreviewPlayheadPosition();

    if (measureTicks != null) this.handleMeasureTickPosition();
    return this.scrollPositionInPixels;
  }

  /**
   * The relative scroll position in the song, converted to steps.
   * NOT dependent on BPM, because the size of a grid square does not change with BPM.
   */
  var scrollPositionInSteps(get, set):Float;

  function get_scrollPositionInSteps():Float
  {
    return ChartEditorTimeScale.pixelsToStep(scrollPositionInPixels);
  }

  function set_scrollPositionInSteps(value:Float):Float
  {
    scrollPositionInPixels = ChartEditorTimeScale.stepToPixels(value);
    return value;
  }

  /**
   * The relative scroll position in the song, converted to milliseconds.
   * DEPENDENT on BPM, because the duration of a grid square changes with BPM.
   */
  var scrollPositionInMs(get, set):Float;

  function get_scrollPositionInMs():Float
  {
    return ChartEditorTimeScale.pixelsToMs(scrollPositionInPixels);
  }

  function set_scrollPositionInMs(value:Float):Float
  {
    scrollPositionInPixels = ChartEditorTimeScale.msToPixels(value);
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
    gridPlayhead.y = this.playheadPositionInPixels + GRID_INITIAL_Y_POS;

    this.updatePlayheadGhostHoldNotes();
    this.refreshNotePreviewPlayheadPosition();

    return this.playheadPositionInPixels;
  }

  /**
   * playheadPosition, converted to steps.
   * NOT dependent on BPM, because the size of a grid square does not change with BPM.
   */
  var playheadPositionInSteps(get, set):Float;

  function get_playheadPositionInSteps():Float
  {
    return ChartEditorTimeScale.pixelsToStep(scrollPositionInPixels + playheadPositionInPixels) - scrollPositionInSteps;
  }

  function set_playheadPositionInSteps(value:Float):Float
  {
    playheadPositionInPixels = ChartEditorTimeScale.stepToPixels(scrollPositionInSteps + value) - scrollPositionInPixels;
    return value;
  }

  /**
   * playheadPosition, converted to milliseconds.
   * DEPENDENT on BPM, because the duration of a grid square changes with BPM.
   */
  var playheadPositionInMs(get, set):Float;

  function get_playheadPositionInMs():Float
  {
    return ChartEditorTimeScale.pixelsToMs(scrollPositionInPixels + playheadPositionInPixels) - scrollPositionInMs;
  }

  function set_playheadPositionInMs(value:Float):Float
  {
    playheadPositionInPixels = ChartEditorTimeScale.msToPixels(scrollPositionInMs + value) - scrollPositionInPixels;
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
   * The note kind to use for notes being placed in the chart. Defaults to `null`.
   */
  var noteKindToPlace:Null<String> = null;

  /**
   * The note params to use for notes being placed in the chart. Defaults to `[]`.
   */
  var noteParamsToPlace:Array<NoteParamData> = [];

  /**
   * The event type to use for events being placed in the chart. Defaults to `''`.
   */
  var eventKindToPlace:String = 'FocusCamera';

  /**
   * The event data to use for events being placed in the chart.
   */
  var eventDataToPlace:DynamicAccess<Dynamic> = {};

  /**
   * The color of comment to place, as a hex string.
   * Uses the last color of comment you selected.
   */
  var commentColorToPlace:String = '#0000BB';

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
    return BASE_QUANT / (noteSnapQuant * 4 / Conductor.instance.timeSignatureDenominator);
  }

  /**
   * The index of the current zoom level in `ZOOM_LEVELS`.
   */
  var zoomLevelIndex(default, set):Int = BASE_ZOOM_INDEX;

  function set_zoomLevelIndex(value:Int):Int
  {
    return zoomLevelIndex = Std.int(clamp(value, 0, ZOOM_LEVELS.length - 1));
  }

  /**
   * The zoom currently shown, which eases toward `ZOOM_LEVELS[zoomLevelIndex]`.
   */
  var zoomCurrent:Float = 1;

  /**
   * Whether constant scroll is turned on in Preferences. See `CONSTANT_SCROLL`.
   */
  var constantScrollEnabled(default, set):Bool = false;

  function set_constantScrollEnabled(value:Bool):Bool
  {
    constantScrollEnabled = value;
    this.updateGridScale(gridTiledSprite != null);
    notePreviewDirty = true;
    return constantScrollEnabled;
  }

  /**
   * How fast the grid scrolls with constant scroll on, as a multiplier.
   */
  var constantScrollSpeed(default, set):Float = 1.0;

  /**
   * How large the editor is drawn.
   */
  var uiScale(default, set):Float = 1.45;

  var uiScaleDirty:Bool = false;

  function set_uiScale(value:Float):Float
  {
    value = FlxMath.bound(value, ChartEditorScaleMode.MIN_UI_SCALE, ChartEditorScaleMode.MAX_UI_SCALE);
    if (value != uiScale) uiScaleDirty = true;
    return uiScale = value;
  }

  function set_constantScrollSpeed(value:Float):Float
  {
    constantScrollSpeed = FlxMath.bound(value, 0.1, 10);
    this.updateGridScale();
    return constantScrollSpeed;
  }

  /**
   * The currently selected live input style.
   */
  var currentLiveInputStyle:ChartEditorLiveInputStyle = NumberKeys;

  /**
   * The currently selected waveform position.
   */
  var currentWaveformPos:ChartEditorWaveformPos = Adjacent;

  /**
   * If true, playtesting a chart will skip to the current playhead position.
   */
  var playtestStartTime:Bool = false;

  /**
   * If true, playtesting a chart will let you "gameover" / die when you lose ur health!
   */
  var playtestPracticeMode:Bool = false;

  /**
   * If true, playtesting a chart will make the computer do it for you!
   */
  var playtestBotPlayMode:Bool = false;

  /**
   * If true, after playtesting a chart the results screen will show your score.
   */
  var playtestShowResults:Bool = false;

  /**
   * If true, playtesting a chart will use the audio settings that were set here.
   */
  var playtestAudioSettings:Bool = false;

  /**
   * Whether song scripts should be enabled during playtesting.
   * You should probably check the box if the song has custom mechanics.
   */
  var playtestSongScripts:Bool = true;

  /**
   * Whether we are CURRENTLY playtesting a chart.
   */
  var isPlaytesting(get, never):Bool;

  function get_isPlaytesting():Bool
  {
    return this.subState != null && Std.isOfType(this.subState, PlayState);
  }

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
    commentDisplayDirty = true;
    notePreviewViewportBoundsDirty = true;
    this.scrollPositionInPixels = this.scrollPositionInPixels;
    // Characters have probably changed too.
    healthIconsDirty = true;

    return isViewDownscroll;
  }

  /**
   * Whether to show an indicator if a note is of a non-default kind.
   */
  var showNoteKindIndicators:Bool = false;

  /**
   * Whether the difficulty heatmap shows over the player's side of the grid.
   */
  var showDifficultyHeatmap(default, set):Bool = false;

  function set_showDifficultyHeatmap(value:Bool):Bool
  {
    showDifficultyHeatmap = value;
    if (difficultyHeatmap != null) difficultyHeatmap.visible = value;
    difficultyHeatmapDirty = true;
    return value;
  }

  var difficultyHeatmap:Null<ChartEditorDifficultyHeatmap> = null;

  /**
   * Set when the notes or scroll speed change, so the heatmap is redrawn the next time it shows.
   */
  var difficultyHeatmapDirty:Bool = true;

  /**
   * Toggles the subtitles.
   */
  var showSubtitles(default, set):Bool = false;

  function set_showSubtitles(value:Bool):Bool
  {
    showSubtitles = value;

    if (subtitles != null)
    {
      subtitles.exists = showSubtitles;
    }

    return showSubtitles;
  }

  /**
   * Whether the Preferences toolbox should apply changes from its controls.
   */
  var preferencesListening:Bool = false;

  /**
   * Which filter, if any, is applied to the waveform overlay.
   */
  var waveformFilter(default, set):ChartEditorWaveformFilter = ChartEditorWaveformFilter.None;

  function set_waveformFilter(value:ChartEditorWaveformFilter):ChartEditorWaveformFilter
  {
    if (value != waveformFilter) queueWaveformFilterUpdate();
    return waveformFilter = value;
  }

  /**
   * How strong the waveform filter is, from 0 to 1. Higher cuts more of the sound away.
   */
  var waveformFilterStrength(default, set):Float = 0.5;

  function set_waveformFilterStrength(value:Float):Float
  {
    value = FlxMath.bound(value, 0, 1);
    if (value != waveformFilterStrength) queueWaveformFilterUpdate();
    return waveformFilterStrength = value;
  }

  /**
   * The delay before the waveform overlays are rebuilt, in seconds.
   */
  var waveformFilterDelay:Float = -1;

  function queueWaveformFilterUpdate():Void
  {
    waveformFilterDelay = 0.25;
  }

  /**
   * Counts up every time the filter settings are applied, so results from older settings can be thrown away.
   */
  var waveformFilterGeneration:Int = 0;

  #if target.threaded
  /**
   * Finished filter jobs.
   */
  var waveformFilterResults:sys.thread.Deque<WaveformFilterResult> = new sys.thread.Deque();
  #end

  /**
   * Whether to show the instrumental waveform in the chart editor.
   */
  var showInstrumentalWaveform(default, set):Bool = false;

  function set_showInstrumentalWaveform(value:Bool):Bool
  {
    if (value != showInstrumentalWaveform)
    {
      waveformsDirty = true;
      queueWaveformFilterUpdate();
    }
    return showInstrumentalWaveform = value;
  }

  /**
   * Whether the instrumental waveform is shown, based on the current settings and available waveforms.
   */
  var usingInstrumentalWaveform(get, never):Bool;

  function get_usingInstrumentalWaveform():Bool
  {
    if (showInstrumentalWaveform) return true;
    for (waveform in audioWaveforms.members)
    {
      if (waveform != null && waveform.exists && waveform.iconId != GF) return false;
    }
    return true;
  }

  /**
   * Prefix for the instrumental's key in `audioWaveformDataCache`.
   */
  public static final INSTRUMENTAL_WAVEFORM_CACHE_PREFIX:String = 'inst:';

  var instrumentalWaveform:Null<ChartEditorWaveformSprite> = null;
  var instrumentalWaveformTrack:Null<FunkinSound> = null;

  /**
   * Audio samples per waveform data point in the chart editor.
   */
  public static final WAVEFORM_SAMPLES_PER_POINT:Int = 16;

  /**
   * Whether to draw a line on every beat, in addition to measure lines.
   */
  var showBeatLines(default, set):Bool = true;

  function set_showBeatLines(value:Bool):Bool
  {
    if (value != showBeatLines) gridLinesDirty = true;
    return showBeatLines = value;
  }

  /**
   * Whether to draw a line at the snap the cursor would place a note on.
   */
  var showCursorLine:Bool = true;

  /**
   * How opaque the grid backing is, from 0 to 1.
   */
  var gridBackingAlpha(default, set):Float = ChartEditorThemeHandler.GRID_BACKING_ALPHA;

  function set_gridBackingAlpha(value:Float):Float
  {
    gridBackingAlpha = FlxMath.bound(value, 0, 1);
    if (gridLines != null) gridLines.backing.alpha = gridBackingAlpha;
    return gridBackingAlpha;
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
    waveformsDirty = true;
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
    if (textInputJustClosed)
    {
      if (FlxG.keys.pressed.ENTER || FlxG.keys.pressed.ESCAPE) return true;
      textInputJustClosed = false;
    }
    if (!haxeUIFocusedValid)
    {
      haxeUIFocusedValid = true;
      haxeUIFocusedCache = FocusManager.instance.focus != null;
    }
    return haxeUIFocusedCache;
  }

  /**
   * Whether `haxeUIFocusedCache` is up to date.
   */
  static var haxeUIFocusedValid:Bool = false;

  static var haxeUIFocusedCache:Bool = false;

  /**
   * Set when a text field closes on Enter or Escape, so that key press doesn't also reach the editor's keybinds.
   */
  var textInputJustClosed:Bool = false;

  /**
   * Whether the user's mouse cursor is hovering over a SOLID component of the HaxeUI.
   * If so, we can ignore certain mouse events underneath.
   */
  var isCursorOverHaxeUI(get, never):Bool;

  function get_isCursorOverHaxeUI():Bool
  {
    return Screen.instance.hasSolidComponentUnderPoint(FlxG.mouse.viewX, FlxG.mouse.viewY);
  }

  /**
   * Whether the user's mouse cursor is hovering over a comment, and not any other component of the HaxeUI.
   * If so, we can still scroll underneath.
   */
  var canScrollComment(get, never):Bool;

  function get_canScrollComment():Bool
  {
    for (component in Screen.instance.findSolidComponentUnderPoint(FlxG.mouse.viewX, FlxG.mouse.viewY))
    {
      if (!Std.isOfType(component, ChartEditorCommentPanel) && component.findAncestor(null, ChartEditorCommentPanel) == null) return false;
      if (Std.isOfType(component, TextArea) && component.findComponent(VerticalScroll, false) != null) return false;
    }
    return true;
  }

  /**
   * The value of `isCursorOverHaxeUI` from the previous frame.
   * This is useful because we may have just clicked a menu item, causing the menu to disappear.
   */
  var wasCursorOverHaxeUI:Bool = false;

  /**
   * Set by ChartEditorDialogHandler, used to prevent background interaction while a dialog is open.
   */
  var isHaxeUIDialogOpen:Bool = false;

  /**
   * The value of `isHaxeUIDialogOpen` from the previous frame.
   */
  var wasHaxeUIDialogOpen:Bool = false;

  /**
   * The Dialog components representing the currently available tool windows.
   * Dialogs are retained here even when collapsed or hidden.
   */
  var activeToolboxes:Map<String, CollapsibleDialog> = new Map<String, CollapsibleDialog>();

  /**
   * The camera component we're using for this state.
   */
  var uiCamera:FlxCamera;

  // Audio

  /**
   * Play the welcome music or not.
   */
  var shouldPlayWelcomeMusic:Bool = false;

  /**
   * The duration before the welcome music starts to fade back in after the user stops playing music in the chart editor.
   */
  public static final WELCOME_MUSIC_FADE_IN_DELAY:Float = 10;

  /**
   * The duration of the welcome music fade in.
   */
  public static final WELCOME_MUSIC_FADE_IN_DURATION:Float = 20;

  /**
   * Whether to play a metronome sound while the playhead is moving, and what volume.
   */
  var metronomeVolume:Float = 1.0;

  /**
   * The volume to play the player's hitsounds at.
   */
  var hitsoundVolumePlayer:Float = 1.0;

  /**
   * The volume to play the opponent's hitsounds at.
   */
  var hitsoundVolumeOpponent:Float = 1.0;

  /**
   * The audio volume before it was toggled to zero.
   * Metronome, hitsounds (player and opponent), instrumental, vocals (player and opponent)
   */
  var previousAudioVolumes:Array<Float> = [
    1.0,
    1.0,
    1.0,
    1.0,
    1.0,
    1.0
  ];

  /**
   * Whether hitsounds are enabled for at least one character.
   */
  var hitsoundsEnabled(get, never):Bool;

  function get_hitsoundsEnabled():Bool
  {
    return !hitsoundsMuted && hitsoundVolumePlayer + hitsoundVolumeOpponent > 0;
  }

  /**
   * Whether the `Audio -> Mute Metronome` toggle is on. Kept separate from the volume, so unmuting brings it back as it was.
   */
  var metronomeMuted:Bool = false;

  /**
   * Whether the `Audio -> Mute Hitsounds` toggle is on, for both sides. Kept separate from the volumes, so unmuting brings them back as they were.
   */
  var hitsoundsMuted:Bool = false;

  var stretchySound1:Null<FunkinSound> = null;
  var stretchySound2:Null<FunkinSound> = null;
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
   */
  var currentScrollEase:Null<Float>;

  /**
   * The position where the user middle clicked to place a scroll anchor.
   * Scroll each frame with speed based on the distance between the mouse and the scroll anchor.
   * `null` if no scroll anchor is present.
   */
  var scrollAnchorScreenPos:Null<FlxPoint> = null;

  // Note Placement

  /**
   * The SongNoteData which is currently being placed.
   * `null` if the user isn't currently placing a note.
   * As the user drags, we will update this note's sustain length, and finalize the note when they release.
   */
  var currentPlaceNoteData(default, set):Null<SongNoteData> = null;

  function set_currentPlaceNoteData(value:Null<SongNoteData>):Null<SongNoteData>
  {
    noteDisplayDirty = true;

    return currentPlaceNoteData = value;
  }

  /**
   * The SongNoteData which is currently being placed, for each column.
   * `null` if the user isn't currently placing a note.
   * As the user moves down, we will update this note's sustain length, and finalize the note when they release.
   */
  var currentLiveInputPlaceNoteData:Array<SongNoteData> = [];

  /**
   * Defines how "close" two notes must be to be considered stacked, based on steps.
   * For example, setting this to `0.5` (16/32) will highlight notes half a step apart.
   * Setting it to `0` only highlights notes that are nearly perfectly aligned.
   * In the dropdown menu, the threshold is based on note snaps instead.
   * For example, `0.5` would be displayed as `1/32`, and `0` would show as `Exact`.
   */
  public static var stackedNoteThreshold:Float = 0;

  /**
   * Whether the user was playtesting a chart before hot reloading began.
   */
  static var wasPlaytesting:Bool = false;

  // Note Movement

  /**
   * The note sprite we are currently moving, if any.
   */
  var dragTargetNote:Null<ChartEditorNoteSprite> = null;

  /**
   * The song event sprite we are currently moving, if any.
   */
  var dragTargetEvent:Null<ChartEditorEventSprite> = null;

  var dragEventWasSelected:Bool = false;
  var currentOverlappingEvents:Array<ChartEditorEventSprite> = [];
  var currentOverlappingEventCycleIndex:Int = 0;

  /**
   * The amount of vertical steps the note sprite has moved by since the user started dragging.
   */
  var dragTargetCurrentStep:Float = 0;

  /**
   * The amount of horizontal columns the note sprite has moved by since the user started dragging.
   */
  var dragTargetCurrentColumn:Int = 0;

  var dragStartCursorStep:Float = 0;
  var dragStartCursorColumn:Int = 0;
  // Hold Note Dragging

  /**
   * The current length of the hold note we are dragging, in steps.
   * Play a sound when this value changes.
   */
  var dragLengthCurrent:Float = 0;

  /**
   * The current length of the hold note we are placing with the playhead, in steps.
   * Play a sound when this value changes.
   */
  var playheadDragLengthCurrent:Array<Float> = [];

  /**
   * Flip-flop to alternate between two stretching sounds.
   */
  var stretchySounds:Bool = false;

  // Selection

  /**
   * The notes which are currently in the user's selection.
   */
  var currentNoteSelection(default, set):Array<SongNoteData> = [];

  function set_currentNoteSelection(value:Array<SongNoteData>):Array<SongNoteData>
  {
    // This value is true if all elements of the current selection are also in the new selection.
    var isSuperset:Bool = currentNoteSelection.isSubset(value);
    var isEqual:Bool = currentNoteSelection.isEqualUnordered(value);

    currentNoteSelection = value;
    if (value.length > 0)
    {
      // Picking notes lets go of the other kinds of items.
      for (selectable in selectables) selectable.clearSelection();
    }

    if (!isEqual)
    {
      if (currentNoteSelection.length > 0 && isSuperset)
      {
        notePreview.addSelectedNotes(currentNoteSelection, songLengthInPixels);
      }
      else
      {
        // The new selection removes elements from the old selection, so we have to redraw the note preview.
        notePreviewDirty = true;
      }
    }

    return currentNoteSelection;
  }

  var currentOverlappingNotes(default, set):Array<SongNoteData> = [];

  function set_currentOverlappingNotes(value:Array<SongNoteData>):Array<SongNoteData>
  {
    // This value is true if all elements of the current overlapping array are also in the new array.
    var isSuperset:Bool = currentOverlappingNotes.isSubset(value);
    var isEqual:Bool = currentOverlappingNotes.isEqualUnordered(value);

    currentOverlappingNotes = value;

    if (!isEqual)
    {
      if (currentOverlappingNotes.length > 0 && isSuperset)
      {
        notePreview.addOverlappingNotes(currentOverlappingNotes, songLengthInPixels);
      }
      else
      {
        // The new array might add or remove elements from the old array, so we have to redraw the note preview.
        notePreviewDirty = true;
      }
    }

    return currentOverlappingNotes;
  }

  /**
   * The events which are currently in the user's selection.
   */
  var currentEventSelection:Array<SongEventData> = [];

  /**
   * The picked BPM and time signature changes.
   */
  var timeChangeItems:ChartEditorTimeChangeItems;

  /**
   * The picked comments.
   */
  var commentItems:ChartEditorCommentItems;

  /**
   * The picked sub-beats.
   */
  var subBeatItems:ChartEditorSubBeatItems;

  /**
   * All selectable items.
   */
  var selectables:Array<ChartEditorSelectable>;

  /**
   * The position where the user clicked to start a selection.
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
   */
  var noteDisplayDirty:Bool = true;

  var notesNeedSort:Bool = true;

  // bunch of caches for various sets of notes and events.
  var windowNotes:Array<SongNoteData> = [];
  var windowNoteSet:haxe.ds.ObjectMap<SongNoteData, Bool> = new haxe.ds.ObjectMap();
  var windowEventSet:haxe.ds.ObjectMap<SongEventData, Bool> = new haxe.ds.ObjectMap();
  var selectedNoteSet:haxe.ds.ObjectMap<SongNoteData, Bool> = new haxe.ds.ObjectMap();
  var selectedEventSet:haxe.ds.ObjectMap<SongEventData, Bool> = new haxe.ds.ObjectMap();
  var stackedNoteSet:haxe.ds.ObjectMap<SongNoteData, Bool> = new haxe.ds.ObjectMap();
  var displayedNoteSet:haxe.ds.ObjectMap<SongNoteData, Bool> = new haxe.ds.ObjectMap();
  var displayedEventSet:haxe.ds.ObjectMap<SongEventData, Bool> = new haxe.ds.ObjectMap();
  var displayedHoldNotes:haxe.ds.ObjectMap<SongNoteData, ChartEditorHoldNoteSprite> = new haxe.ds.ObjectMap();

  /**
   * Whether the comment data has been modified and the comment pins need to be updated.
   */
  var commentDisplayDirty:Bool = true;

  var noteTooltipsDirty:Bool = true;

  /**
   * Whether the selected characters have been modified and the health icons need to be updated.
   */
  var healthIconsDirty:Bool = true;

  /**
   * Whether the waveforms were modified and need to be updated.
   */
  var waveformsDirty:Bool = false;

  /**
   * Whether the grid checker rows and snap, beat and measure lines need to be rebuilt.
   */
  var gridLinesDirty:Bool = true;

  /**
   * Whether the note preview graphic needs to be FULLY rebuilt.
   */
  var notePreviewDirty:Bool = true;

  var notePreviewViewportBoundsDirty:Bool = true;

  /**
   * Whether the chart has been modified since it was last saved.
   * Used to determine whether to auto-save, etc.
   */
  var saveDataDirty(default, set):Bool = false;

  function set_saveDataDirty(value:Bool):Bool
  {
    if (value && autoSaveTimer == null) this.queueAutoSave();
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
    this.applyWindowTitle();
    return saveDataDirty;
  }

  var shouldShowBackupAvailableDialog(get, set):Bool;

  function get_shouldShowBackupAvailableDialog():Bool
  {
    return Save.instance.chartEditorHasBackup.value && ChartEditorImportExportHandler.getLatestBackupPath('chart-editor-') != null;
  }

  function set_shouldShowBackupAvailableDialog(value:Bool):Bool
  {
    return Save.instance.chartEditorHasBackup.value = value;
  }

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
    this.applyWindowTitle();
    this.populateOpenRecentMenu();
    this.applyCanQuickSave();
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
      previousWorkingFilePaths = previousWorkingFilePaths.filter(function(x:Null<String>):Bool
      {
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

    this.populateOpenRecentMenu();
    this.applyWindowTitle();

    return value;
  }

  /**
   * Whether the difficulty tree view in the toolbox has been modified and needs to be updated.
   * This happens when we add/remove difficulties.
   */
  var difficultySelectDirty:Bool = true;

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

  /**
   * Whether the selection has changed and the edit buttons need to be updated.
   */
  var editButtonsDirty:Bool = true;

  /**
   * Whether the clipboard has changed and the paste buttons need to be updated.
   */
  var clipboardDirty:Bool = true;

  /**
   * Whether the clipboard is valid and contains a json of notes and events.
   */
  var clipboardValid:Bool = true;

  /**
   * If true, we are currently in the process of quitting the chart editor.
   * Skip any update functions as most of them will call a crash.
   */
  var criticalFailure:Bool = false;

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
   * Variable used to track how long the user has been holding up on the dpad.
   */
  var dpadUpGamepadHandler:TurboButtonHandler = TurboButtonHandler.build(FlxGamepadInputID.DPAD_UP);

  /**
   * Variable used to track how long the user has been holding down on the dpad.
   */
  var dpadDownGamepadHandler:TurboButtonHandler = TurboButtonHandler.build(FlxGamepadInputID.DPAD_DOWN);

  /**
   * Variable used to track how long the user has been holding left on the dpad.
   */
  var dpadLeftGamepadHandler:TurboButtonHandler = TurboButtonHandler.build(FlxGamepadInputID.DPAD_LEFT);

  /**
   * Variable used to track how long the user has been holding right on the dpad.
   */
  var dpadRightGamepadHandler:TurboButtonHandler = TurboButtonHandler.build(FlxGamepadInputID.DPAD_RIGHT);

  /**
   * Variable used to track how long the user has been holding up on the left stick.
   */
  var leftStickUpGamepadHandler:TurboButtonHandler = TurboButtonHandler.build(FlxGamepadInputID.LEFT_STICK_DIGITAL_UP);

  /**
   * Variable used to track how long the user has been holding down on the left stick.
   */
  var leftStickDownGamepadHandler:TurboButtonHandler = TurboButtonHandler.build(FlxGamepadInputID.LEFT_STICK_DIGITAL_DOWN);

  /**
   * Variable used to track how long the user has been holding left on the left stick.
   */
  var leftStickLeftGamepadHandler:TurboButtonHandler = TurboButtonHandler.build(FlxGamepadInputID.LEFT_STICK_DIGITAL_LEFT);

  /**
   * Variable used to track how long the user has been holding right on the left stick.
   */
  var leftStickRightGamepadHandler:TurboButtonHandler = TurboButtonHandler.build(FlxGamepadInputID.LEFT_STICK_DIGITAL_RIGHT);

  /**
   * Variable used to track how long the user has been holding up on the right stick.
   */
  var rightStickUpGamepadHandler:TurboButtonHandler = TurboButtonHandler.build(FlxGamepadInputID.RIGHT_STICK_DIGITAL_UP);

  /**
   * Variable used to track how long the user has been holding down on the right stick.
   */
  var rightStickDownGamepadHandler:TurboButtonHandler = TurboButtonHandler.build(FlxGamepadInputID.RIGHT_STICK_DIGITAL_DOWN);

  /**
   * Variable used to track how long the user has been holding left on the right stick.
   */
  var rightStickLeftGamepadHandler:TurboButtonHandler = TurboButtonHandler.build(FlxGamepadInputID.RIGHT_STICK_DIGITAL_LEFT);

  /**
   * Variable used to track how long the user has been holding right on the right stick.
   */
  var rightStickRightGamepadHandler:TurboButtonHandler = TurboButtonHandler.build(FlxGamepadInputID.RIGHT_STICK_DIGITAL_RIGHT);

  /**
   * AUDIO AND SOUND DATA
   */
  // ==============================

  /**
   * The chill audio track that plays in the chart editor.
   * Plays when the main music is NOT being played.
   */
  var welcomeMusic:FunkinSound = new FunkinSound();

  /**
   * The audio track for the instrumental.
   * Replaced when switching instrumentals.
   * `null` until an instrumental track is loaded.
   */
  var audioInstTrack:Null<FunkinSound> = null;

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
  var audioVocalTrackGroup:VoicesGroup = new VoicesGroup();

  /**
   * The audio waveform visualization for the inst/vocals.
   * `null` until vocal track(s) are loaded.
   * When switching characters, the elements will be swapped to match the new character.
   */
  var audioWaveforms:FlxTypedGroup<ChartEditorWaveformSprite> = new FlxTypedGroup<ChartEditorWaveformSprite>();

  /**
   * Parsed waveform data for each vocal track key.
   */
  var audioWaveformDataCache:Map<String, funkin.audio.waveform.WaveformData> = [];

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
   * The song manifest data.
   * If none already exists, it's initialized with the current song name in lower-kebab-case.
   */
  var _songManifestData:Null<ChartManifestData> = null;

  var songManifestData(get, set):ChartManifestData;

  function get_songManifestData():ChartManifestData
  {
    if (_songManifestData != null) return _songManifestData;
    return _songManifestData = new ChartManifestData(getDefaultSongId());
  }

  function set_songManifestData(value:ChartManifestData):ChartManifestData
  {
    return _songManifestData = value;
  }

  /**
   * The song metadata.
   * - Keys are the variation IDs. At least one (`default`) must exist.
   * - Values are the relevant metadata, ready to be serialized to JSON.
   */
  var songMetadata:Map<String, SongMetadata> = [];

  /**
   * Updates the current song's play data variations list.
   */
  function refreshPlayDataVariations():Void
  {
    var songVariations:Array<String> = songMetadata.get(Constants.DEFAULT_VARIATION).playData.songVariations;
    songVariations.clear();
    for (variation in availableVariations)
    {
      if (variation == Constants.DEFAULT_VARIATION) continue;
      songVariations.pushUnique(variation);
    }
  }

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
    return getAvailableDifficulties(selectedVariation);
  }

  function getAvailableDifficulties(variation:String):Array<String>
  {
    var m:Null<SongMetadata> = songMetadata.get(variation);
    return m?.playData?.difficulties ?? [Constants.DEFAULT_DIFFICULTY];
  }

  /**
   * Retrieves the list of (suffixed) difficulties for ALL variations of the current song.
   */
  var allDifficulties(get, never):Array<String>;

  function get_allDifficulties():Array<String>
  {
    var result:Array<Array<String>> = [for (x in availableVariations)
    {
      var m:Null<SongMetadata> = songMetadata.get(x);
      [for (diff in (m?.playData?.difficulties ?? [])) '$diff-$x'];
    }];
    return result.flatten();
  }

  var hasInstrumentalData(get, never):Bool;

  function get_hasInstrumentalData():Bool
  {
    return audioInstTrackData.size() > 0;
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
      result = new SongMetadata('Default Song Name', Constants.DEFAULT_ARTIST, Constants.DEFAULT_CHARTER, selectedVariation);
      songMetadata.set(selectedVariation, result);
    }
    return result;
  }

  function set_currentSongMetadata(value:SongMetadata):SongMetadata
  {
    songMetadata.set(selectedVariation, value);

    resetPreviewTimes();

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
      if (songChartData.size() == 0)
      {
        // There's no chart data at all.
      }
      else
      {
        // There's no chart data for the selected variation.
        this.warning('Missing Chart Data', 'No chart data found for variation ${selectedVariation}.');
      }
      result = new SongChartData([
        Constants.DEFAULT_DIFFICULTY => 1.0
      ], [], [
        Constants.DEFAULT_DIFFICULTY => []
      ]);
      songChartData.set(selectedVariation, result);
    }
    return result;
  }

  function set_currentSongChartData(value:SongChartData):SongChartData
  {
    songChartData.set(selectedVariation, value);
    var variationMetadata:Null<SongMetadata> = songMetadata.get(selectedVariation);
    if (variationMetadata != null)
    {
      // Add the chartdata difficulties to the metadata difficulties if they don't exist so that the editor properly loads them
      var keys:Array<String> = [for (x in songChartData.get(selectedVariation).notes.keys()) x];
      for (key in keys)
      {
        variationMetadata.playData.difficulties.pushUnique(key);
      }
    }
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
    noteDisplayDirty = true;
    difficultyHeatmapDirty = true;
    var difficultyToolbox:Null<ChartEditorDifficultyToolbox> = cast activeToolboxes.get(CHART_EDITOR_TOOLBOX_DIFFICULTY_LAYOUT);
    if (difficultyToolbox != null) difficultyToolbox.refreshDetails();
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
      if (!hasInstrumentalData)
      {
        // There's no chart data at all.
      }
      else
      {
        // There's no chart data for the selected variation.
        this.warning(
          'Missing Chart Data',
          'No chart data found for difficulty ${selectedDifficulty} (variation ${selectedVariation} has ${availableDifficulties.join(", ")}).'
        );
      }
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

  /**
   * Convenience property to get the comment data for the current difficulty.
   */
  var currentSongChartCommentData(get, set):Array<CommentData>;

  function get_currentSongChartCommentData():Array<CommentData>
  {
    // Initialize to the default value if not set.
    if (currentSongChartData.editorData == null) currentSongChartData.editorData = new SongChartEditorData();
    // Initialize to the default value if not set.
    if (currentSongChartData.editorData.comments == null) currentSongChartData.editorData.comments = [];

    return currentSongChartData.editorData.comments;
  }

  function set_currentSongChartCommentData(value:Array<CommentData>):Array<CommentData>
  {
    if (currentSongChartData.editorData == null) currentSongChartData.editorData = new SongChartEditorData();

    return currentSongChartData.editorData.comments = value;
  }

  /**
   * Convenience property to get the rating for this difficulty in the Freeplay menu.
   */
  var currentSongChartDifficultyRating(get, set):Int;

  function get_currentSongChartDifficultyRating():Int
  {
    var result:Null<Int> = currentSongMetadata.playData.ratings.get(selectedDifficulty);
    if (result == null)
    {
      // Initialize to the default value if not set.
      currentSongMetadata.playData.ratings.set(selectedDifficulty, 0);
      return 0;
    }
    return result;
  }

  function set_currentSongChartDifficultyRating(value:Int):Int
  {
    currentSongMetadata.playData.ratings.set(selectedDifficulty, value);
    return value;
  }

  var currentSongNoteStyle(get, set):String;

  function get_currentSongNoteStyle():String
  {
    if (currentSongMetadata.playData.noteStyle == null || currentSongMetadata.playData.noteStyle == '' || currentSongMetadata.playData.noteStyle == 'item')
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

  var currentSongAlbum(get, set):Null<String>;

  function get_currentSongAlbum():Null<String>
  {
    if (currentSongMetadata.playData.album == null || currentSongMetadata.playData.album == '' || currentSongMetadata.playData.album == 'item')
    {
      // Initialize to the default value if not set.
      currentSongMetadata.playData.album = Constants.DEFAULT_ALBUM_ID;
    }
    return currentSongMetadata.playData.album;
  }

  function set_currentSongAlbum(value:String):Null<String>
  {
    return currentSongMetadata.playData.album = value;
  }

  var currentSongStickerPack(get, set):Null<String>;

  function get_currentSongStickerPack():Null<String>
  {
    if (
      currentSongMetadata.playData.stickerPack == null
      || currentSongMetadata.playData.stickerPack == ''
      || currentSongMetadata.playData.stickerPack == 'item'
    )
    {
      // Initialize to the default value if not set.
      currentSongMetadata.playData.stickerPack = Constants.DEFAULT_STICKER_PACK;
    }
    return currentSongMetadata.playData.stickerPack;
  }

  function set_currentSongStickerPack(value:String):Null<String>
  {
    return currentSongMetadata.playData.stickerPack = value;
  }

  var currentSongFreeplayPreviewStart(get, set):Float;

  function get_currentSongFreeplayPreviewStart():Float
  {
    return currentSongMetadata.playData.previewStart;
  }

  function set_currentSongFreeplayPreviewStart(value:Float):Float
  {
    return currentSongMetadata.playData.previewStart = value * (value < 1 ? songLengthInMs : 1);
  }

  var currentSongFreeplayPreviewEnd(get, set):Float;

  function get_currentSongFreeplayPreviewEnd():Float
  {
    return currentSongMetadata.playData.previewEnd;
  }

  function set_currentSongFreeplayPreviewEnd(value:Float):Float
  {
    return currentSongMetadata.playData.previewEnd = value * (value < 1 ? songLengthInMs : 1);
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
    return songManifestData.songId;
  }

  function getDefaultSongId():String
  {
    var defaultSongId:String = currentSongName.trim().toLowerKebabCase().sanitize();
    if (defaultSongId == '') defaultSongId = 'new-song';
    return defaultSongId;
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
   * Convenience property to get the player charId for the current variation.
   */
  var currentPlayerChar(get, set):String;

  function get_currentPlayerChar():String
  {
    if (currentSongMetadata.playData.characters.player == null)
    {
      // Initialize to the default value if not set.
      currentSongMetadata.playData.characters.player = Constants.DEFAULT_CHARACTER;
    }
    return currentSongMetadata.playData.characters.player;
  }

  function set_currentPlayerChar(value:String):String
  {
    return currentSongMetadata.playData.characters.player = value;
  }

  /**
   * Convenience property to get the opponent charId for the current variation.
   */
  var currentOpponentChar(get, set):String;

  function get_currentOpponentChar():String
  {
    if (currentSongMetadata.playData.characters.opponent == null)
    {
      // Initialize to the default value if not set.
      currentSongMetadata.playData.characters.opponent = Constants.DEFAULT_CHARACTER;
    }
    return currentSongMetadata.playData.characters.opponent;
  }

  function set_currentOpponentChar(value:String):String
  {
    return currentSongMetadata.playData.characters.opponent = value;
  }

  /**
   * Convenience property to get the song offset data for the current variation.
   */
  var currentSongOffsets(get, set):SongOffsets;

  function get_currentSongOffsets():SongOffsets
  {
    if (currentSongMetadata.offsets == null)
    {
      // Initialize to the default value if not set.
      currentSongMetadata.offsets = new SongOffsets();
    }
    return currentSongMetadata.offsets;
  }

  function set_currentSongOffsets(value:SongOffsets):SongOffsets
  {
    return currentSongMetadata.offsets = value;
  }

  var currentInstrumentalOffset(get, set):Float;

  function get_currentInstrumentalOffset():Float
  {
    // TODO: Apply for alt instrumentals.
    return currentSongOffsets.getInstrumentalOffset();
  }

  function set_currentInstrumentalOffset(value:Float):Float
  {
    // TODO: Apply for alt instrumentals.
    currentSongOffsets.setInstrumentalOffset(value);
    waveformsDirty = true;
    return value;
  }

  var currentVocalOffsetPlayer(get, set):Float;

  function get_currentVocalOffsetPlayer():Float
  {
    return currentSongOffsets.getVocalOffset(currentPlayerChar);
  }

  function set_currentVocalOffsetPlayer(value:Float):Float
  {
    currentSongOffsets.setVocalOffset(currentPlayerChar, value);
    waveformsDirty = true;
    return value;
  }

  var currentVocalOffsetOpponent(get, set):Float;

  function get_currentVocalOffsetOpponent():Float
  {
    return currentSongOffsets.getVocalOffset(currentOpponentChar);
  }

  function set_currentVocalOffsetOpponent(value:Float):Float
  {
    currentSongOffsets.setVocalOffset(currentOpponentChar, value);
    waveformsDirty = true;
    return value;
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
    noteTooltipsDirty = true;
    notePreviewViewportBoundsDirty = true;
    commentDisplayDirty = true;

    // Switching difficulties should automatically clear the selection.
    currentNoteSelection = [];
    currentEventSelection = [];

    this.switchToCurrentInstrumental();
    trace('F');
    this.postLoadInstrumental();
    trace('G');

    return selectedVariation;
  }

  /**
   * The difficulty ID for the difficulty which is currently being edited.
   */
  var selectedDifficulty(default, set):String = Constants.DEFAULT_DIFFICULTY;

  function set_selectedDifficulty(value:String):String
  {
    if (value == null)
    {
      this.warning('Invalid Difficulty', 'Difficulty cannot be null. Defaulting to ${Constants.DEFAULT_DIFFICULTY}.');
      value = availableDifficulties[0] ?? Constants.DEFAULT_DIFFICULTY;
    }

    if (!availableDifficulties.contains(value))
    {
      this.warning(
        'Invalid Difficulty',
        'Difficulty ${value} does not exist for variation ${selectedVariation}. Defaulting to ${Constants.DEFAULT_DIFFICULTY}.'
      );
      value = availableDifficulties[0] ?? Constants.DEFAULT_DIFFICULTY;
    }

    selectedDifficulty = value;

    // Make sure view is updated when the difficulty changes.
    noteDisplayDirty = true;
    notePreviewDirty = true;
    noteTooltipsDirty = true;
    notePreviewViewportBoundsDirty = true;
    commentDisplayDirty = true;

    if (hasInstrumentalData && songChartData.get(selectedVariation)?.notes.exists(selectedDifficulty) != true)
    {
      this.warning('No Notes', 'No note data found for difficulty ${selectedDifficulty} (variation ${selectedVariation}).');
    }

    // Switching difficulties should automatically clear the selection.
    currentNoteSelection = [];
    currentEventSelection = [];

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
   * HAXEUI COMPONENTS
   */
  // ==============================

  /**
   * The layout containing the playbar.
   * Constructed manually and added to the layout so we can control its position.
   */
  var playbarHeadLayout:Null<ChartEditorPlaybarHead> = null;

  // NOTE: All the components below are automatically assigned via HaxeUI macros.

  /**
   * The menubar at the top of the screen.
   */
  var menubar:MenuBar;

  /**
   * The comment panel on the right side.
   * Constructed manually and added to the layout so we can control its position.
   */
  var commentPanels:Array<ChartEditorCommentPanel> = [];

  /**
   * The `File -> New Chart` menu item.
   */
  var menubarItemNewChart:MenuItem;

  /**
   * The `File -> Open Chart` menu item.
   */
  var menubarItemOpenChart:MenuItem;

  /**
   * The `File -> Open Recent` menu.
   */
  var menubarOpenRecent:Menu;

  /**
   * The `File -> Save Chart` menu item.
   */
  var menubarItemSaveChart:MenuItem;

  /**
   * The `File -> Save Chart As` menu item.
   */
  var menubarItemSaveChartAs:MenuItem;

  /**
   * The `File -> Preferences` menu item.
   */
  var menubarItemPreferences:MenuItem;

  /**
   * The `File -> Exit` menu item.
   */
  var menubarItemExit:MenuItem;

  /**
   * The `Edit -> Undo` menu item.
   */
  var menubarItemUndo:MenuItem;

  /**
   * The `Edit -> Redo` menu item.
   */
  var menubarItemRedo:MenuItem;

  /**
   * The `Edit -> Cut` menu item.
   */
  var menubarItemCut:MenuItem;

  /**
   * The `Edit -> Copy` menu item.
   */
  var menubarItemCopy:MenuItem;

  /**
   * The `Edit -> Paste` menu item.
   */
  var menubarItemPaste:MenuItem;

  /**
   * The `Edit -> Paste Unsnapped` menu item.
   */
  var menubarItemPasteUnsnapped:MenuItem;

  /**
   * The `Edit -> Delete` menu item.
   */
  var menubarItemDelete:MenuItem;

  /**
   * The `Edit -> Delete Stacked Notes` menu item.
   */
  var menubarItemDeleteStacked:MenuItem;

  /**
   * The `Edit -> Flip Notes` menu item.
   */
  var menubarItemFlipNotes:MenuItem;

  /**
   * The `Edit -> Mirror Notes -> X Axis` menu item.
   */
  var menubarItemMirrorX:MenuItem;

  /**
   * The `Edit -> Mirror Notes -> Y Axis` menu item.
   */
  var menubarItemMirrorY:MenuItem;

  /**
   * The `Edit -> Mirror Notes -> XY Axis` menu item.
   */
  var menubarItemMirrorXY:MenuItem;

  /**
   * The `Edit -> Mirror Notes -> Flip Within Strumline` menu checkbox.
   */
  var menubarItemMirrorFlipWithinStrumline:MenuCheckBox;

  /**
   * The `Edit -> Select All` menu item.
   */
  var menubarItemSelectAll:MenuItem;

  /**
   * The `Edit -> Select Inverse` menu item.
   */
  var menubarItemSelectInverse:MenuItem;

  /**
   * The `Edit -> Select None` menu item.
   */
  var menubarItemSelectNone:MenuItem;

  /**
   * The `Edit -> Select Region` menu item.
   */
  var menubarItemSelectRegion:MenuItem;

  /**
   * The `Edit -> Select Before Playhead` menu item.
   */
  var menubarItemSelectBeforePlayhead:MenuItem;

  /**
   * The `Edit -> Select After Playhead` menu item.
   */
  var menubarItemSelectAfterPlayhead:MenuItem;

  /**
   * The `Edit -> Decrease Note Snap Precision` menu item.
   */
  var menuBarItemNoteSnapDecrease:MenuItem;

  /**
   * The `Edit -> Decrease Note Snap Precision` menu item.
   */
  var menuBarItemNoteSnapIncrease:MenuItem;


  /**
   * The `View -> Downscroll` menu item.
   */
  var menubarItemDownscroll:MenuCheckBox;


  /**
   * The `View -> Waveforms` menu item.
   */
  var menubarItemViewWaveforms:MenuCheckBox;
  var menubarItemViewDifficultyHeatmap:MenuCheckBox;

  /**
   * The `View -> Increase Difficulty` menu item.
   */
  var menubarItemDifficultyUp:MenuItem;

  /**
   * The `View -> Decrease Difficulty` menu item.
   */
  var menubarItemDifficultyDown:MenuItem;

  /**
   * The `Audio -> Play/Pause` menu item.
   */
  var menubarItemPlayPause:MenuItem;

  /**
   * The `Audio -> Load Instrumental` menu item.
   */
  var menubarItemLoadInstrumental:MenuItem;

  /**
   * The `Audio -> Load Vocals` menu item.
   */
  var menubarItemLoadVocals:MenuItem;

  /**
   * The `Preferences -> Audio -> Metronome Volume` label.
   */
  var preferencesLabelVolumeMetronome:Label;

  /**
   * The `Preferences -> Audio -> Metronome Volume` slider.
   */
  var preferencesVolumeMetronome:Slider;


  /**
   * The `Preferences -> Audio -> Player Hitsound Volume` label.
   */
  var preferencesLabelVolumeHitsoundPlayer:Label;

  /**
   * The `Preferences -> Audio -> Opponent Hitsound Volume` label.
   */
  var preferencesLabelVolumeHitsoundOpponent:Label;

  /**
   * The `Preferences -> Audio -> Player Hitsound Volume` slider.
   */
  var preferencesVolumeHitsoundPlayer:Slider;

  /**
   * The `Preferences -> Audio -> Opponent Hitsound Volume` slider.
   */
  var preferencesVolumeHitsoundOpponent:Slider;

  /**
   * The `Preferences -> Audio -> Instrumental Volume` label.
   */
  var preferencesLabelVolumeInstrumental:Label;

  /**
   * The `Preferences -> Audio -> Instrumental Volume` slider.
   */
  var preferencesVolumeInstrumental:Slider;

  /**
   * The `Preferences -> Audio -> Player Volume` label.
   */
  var preferencesLabelVolumeVocalsPlayer:Label;

  /**
   * The `Preferences -> Audio -> Opponent Volume` label.
   */
  var preferencesLabelVolumeVocalsOpponent:Label;

  /**
   * The `Preferences -> Audio -> Player Volume` slider.
   */
  var preferencesVolumeVocalsPlayer:Slider;

  /**
   * The `Preferences -> Audio -> Opponent Volume` slider.
   */
  var preferencesVolumeVocalsOpponent:Slider;

  /**
   * The `Audio -> Playback Speed` label.
   */
  var menubarLabelPlaybackSpeed:Label;

  /**
   * The `Audio -> Playback Speed` slider.
   */
  var menubarItemPlaybackSpeed:Slider;

  /**
   * The `Camera Editor` menu item.
   */
  var menubarItemCameraEditor:MenuItem;

  /**
   * The label by the playbar telling the song position.
   */
  var playbarSongPos:Label;

  /**
   * The label by the playbar telling the current beat rounded to 2
   */
  var playbarBeatNum:Label;

  /**
   * The label by the playbar telling the current step
   */
  var playbarStepNum:Label;

  /**
   * The label by the playbar telling the song time remaining.
   */
  var playbarSongRemaining:Label;

  /**
   * The label by the playbar telling the note snap.
   */
  var playbarNoteSnap:Label;

  /**
   * The button by the playbar to jump to the start of the song.
   */
  var playbarStart:Button;

  /**
   * The button by the playbar to jump backwards in the song.
   */
  var playbarBack:Button;

  /**
   * The button by the playbar to play or pause the song.
   */
  var playbarPlay:Button;

  /**
   * The button by the playbar to jump forwards in the song.
   */
  var playbarForward:Button;

  /**
   * The button by the playbar to jump to the end of the song.
   */
  var playbarEnd:Button;

  /**
   * The button above the grid that does nothing currently. Used for covering up the measure ticks being cut off :)
   * Constructed manually and added to the layout so we can control its position.
   */
  var buttonSelectDummy:Button;

  /**
   * The button above the grid that selects all notes on the opponent's side.
   * Constructed manually and added to the layout so we can control its position.
   */
  var buttonSelectOpponent:Button;

  /**
   * The button above the grid that selects all notes on the player's side.
   * Constructed manually and added to the layout so we can control its position.
   */
  var buttonSelectPlayer:Button;

  /**
   * The button above the grid that selects all song events.
   * Constructed manually and added to the layout so we can control its position.
   */
  var buttonSelectEvent:Button;

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
   * Used three ways:
   * 1. A sprite is given this bitmap and placed over selected notes.
   * 2. Same as above but for notes that are overlapped by another.
   * 3. The image is split and used for a 9-slice sprite for the selection box.
   */
  var selectionSquareBitmap:Null<BitmapData> = null;

  /**
   * The IMAGE used for the note preview bitmap. Updated by ChartEditorThemeHandler.
   * The image is split and used for a 9-slice sprite for the box over the note preview.
   */
  var notePreviewViewportBitmap:Null<BitmapData> = null;

  /**
   * The IMAGE used for the offset ticks. Updated by ChartEditorThemeHandler.
   */
  var offsetTickBitmap:Null<BitmapData> = null;

  /**
   * The tiled sprite used to display the grid.
   * The height is the length of the song, and scrolling is done by simply the sprite.
   */
  var gridTiledSprite:Null<FlxSprite> = null;

  /**
   * The checker rows and measure, beat and snap lines drawn on the grid.
   */
  var gridLines:Null<ChartEditorGridLines> = null;

  /**
   * The line across the grid at the snapped position under the cursor.
   */
  var gridCursorLine:Null<FunkinSprite> = null;

  /**
   * The measure ticks area. Includes the numbers and the background sprite.
   */
  var measureTicks:Null<ChartEditorMeasureTicks> = null;

  /**
   * The playhead representing the current position in the song.
   * Can move around on the grid independently of the view.
   */
  var gridPlayhead:FlxSpriteGroup = new FlxSpriteGroup();

  /**
   * A sprite used to indicate the note that will be placed on click.
   */
  var gridGhostNote:Null<ChartEditorNoteSprite> = null;

  /**
   * A sprite used to indicate the hold note that will be placed on click.
   */
  var gridGhostHoldNote:Null<ChartEditorHoldNoteSprite> = null;

  /**
   * A sprite used to indicate the hold note that will be placed on button release.
   */
  var gridPlayheadGhostHoldNotes:Array<ChartEditorHoldNoteSprite> = [];

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
   * The thin sprite used for representing the playhead on the note preview.
   * We move this up and down to represent the current position.
   */
  var notePreviewPlayhead:Null<FlxSprite> = null;

  /**
   * Whether the note preview playhead is currently being dragged with the mouse by the user.
   */
  var notePreviewPlayHeadDragging:Bool = false;

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
   * The text that pop's up when copying something
   */
  var txtCopyNotif:Null<FlxText> = null;

  /**
   * The purple background sprite.
   */
  var menuBG:Null<FlxSprite> = null;

  /**
   * The subtitles to display song's lyrics.
   */
  var subtitles:Null<Subtitles> = null;

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
   * The sprite group containing the comment pins.
   */
  var renderedPins:FlxTypedSpriteGroup<ChartEditorCommentPinSprite> = new FlxTypedSpriteGroup<ChartEditorCommentPinSprite>();

  // ==============================

  /**
   * ASSET LOADING FUNCTIONS
   */
  // ==============================

  public static function queryAssets(type:AssetType, ?params:ChartEditorParams):Array<AssetPath>
  {
    var results:Array<AssetPath> = []; // Get assets for ALL note styles the user might select.

    var noteStyleIds:Array<String> = NoteStyleRegistry.instance.listEntryIds();

    for (noteStyleId in noteStyleIds)
    {
      results.appendUnique(NoteStyleRegistry.instance.queryAssets(type, noteStyleId));
    }

    // Song event icons.
    // results.appendUnique(ChartEditorEventSprite.queryAssets(type));

    switch (type)
    {
      case IMAGE: // Character freeplay icons
        results.appendUnique(funkin.assets.Assets.listInPath('ui/freeplay/characters', IMAGE));
        // Character health icons
        for (characterId in CharacterRegistry.instance.listEntryIds())
        {
          results.push(funkin.assets.Paths.image('gameplay/characters/$characterId/icon-$characterId'));
        }

        results.appendUnique([ // Overall background
          funkin.assets.Paths.image('ui/main-menu/menu-desat'),]);
      case XML: // Character freeplay icons
        results.appendUnique(funkin.assets.Assets.listInPath('ui/freeplay/characters', XML));
        // Character health icons
        for (characterId in CharacterRegistry.instance.listEntryIds())
        {
          results.push(funkin.assets.Paths.xml('gameplay/characters/$characterId/icon-$characterId').orNull());
        }
      case SOUND:
        results.appendUnique([
          funkin.assets.Paths.music('ui/editors/chart-editor/artistic-expression').audio(),

          funkin.assets.Paths.sound('ui/editors/chart-editor/charting-sounds/click-down'),
          funkin.assets.Paths.sound('ui/editors/chart-editor/charting-sounds/click-up'),

          funkin.assets.Paths.sound('ui/editors/chart-editor/charting-sounds/metronome-1'),
          funkin.assets.Paths.sound('ui/editors/chart-editor/charting-sounds/metronome-2'),

          funkin.assets.Paths.sound('ui/editors/chart-editor/charting-sounds/hitsound-player'),
          funkin.assets.Paths.sound('ui/editors/chart-editor/charting-sounds/hitsound-opponent'),

          funkin.assets.Paths.sound('ui/editors/chart-editor/charting-sounds/stretch-1'),
          funkin.assets.Paths.sound('ui/editors/chart-editor/charting-sounds/stretch-2'),
          funkin.assets.Paths.sound('ui/editors/chart-editor/charting-sounds/stretch-snap'),

          funkin.assets.Paths.sound('ui/editors/chart-editor/charting-sounds/note-place'),
          funkin.assets.Paths.sound('ui/editors/chart-editor/charting-sounds/note-erase'),

          funkin.assets.Paths.sound('ui/editors/chart-editor/charting-sounds/window-open'),
          funkin.assets.Paths.sound('ui/editors/chart-editor/charting-sounds/window-exit')
        ]);

      case JSON:
        results.appendUnique([funkin.assets.Paths.music('ui/editors/chart-editor/artistic-expression').metadata()]);

      case SHADER:
        results.push(funkin.assets.Paths.frag('ui/shaders/hsv'));
      default:
        // Nothing
    }

    return results.filterNull();
  }

  /**
   * LIFE CYCLE FUNCTIONS
   */
  // ==============================

  /**
   * The params which were passed in when the Chart Editor was initialized.
   */
  var params:Null<ChartEditorParams>;

  public function new(?params:ChartEditorParams)
  {
    super();
    this.params = params;
    timeChangeItems = new ChartEditorTimeChangeItems(this);
    commentItems = new ChartEditorCommentItems(this);
    subBeatItems = new ChartEditorSubBeatItems(this);
    selectables = [timeChangeItems, commentItems, subBeatItems];
  }

  override public function dispatchEvent(event:ScriptEvent, finish:Bool = true):Void
  {
    super.dispatchEvent(event, false);

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

    if (finish) event.finish();
  }

  override function onPreHotReload():Void
  {
    wasPlaytesting = isPlaytesting;
  }

  override function getHotReloadParams():HotReloadStateParams
  {
    @:privateAccess
    var nextState = () -> new ChartEditorState({
      loadFromPath: currentWorkingFilePath,
      loadFromFNFCData: (
        currentWorkingFilePath == null
        && hasInstrumentalData
      ) ? this.buildFNFCDataFromCurrentChart() : null, // We want to reload the FNFCData so the user doesn't lose progress.
      targetSongDifficulty: this.selectedDifficulty,
      targetSongVariation: this.selectedVariation,
      targetSongPosition: scrollPositionInMs + playheadPositionInMs
    });

    return {
      onComplete: () ->
      {
        if (wasPlaytesting)
        {
          // Fixes a bug where hot-reloading after playtesting would close PlayState.
          FlxTransitionableState.skipNextTransIn = true;
        }
      },
      targetState: nextState
    }
  }

  override function onPostHotReload():Void
  {
    if (wasPlaytesting)
    {
      @:privateAccess
      this.testSongInPlayState(PlayState.lastParams.minimalMode);
    }
  }

  override function create():Void
  {
    // super.create() must be called first, the HaxeUI components get created here.
    super.create();
    // Set the z-index of the HaxeUI.
    this.root.zIndex = 100;

    // Get rid of any music from the previous state.
    if (FlxG.sound.music != null) FlxG.sound.music.stop();

    // Play the welcome music.
    this.setupWelcomeMusic();

    // Show the mouse cursor.
    Cursor.show();

    funkin.util.plugins.VolumePlugin.ignoreWithControl = true;

    this.bindPreferencesAudioControls();
    this.loadPreferences();

    ChartEditorScaleMode.apply(uiScale);
    uiScaleDirty = false;
    dialogLayoutSize.set(FlxG.width, FlxG.height);
    FlxG.signals.preStateSwitch.add(restoreScaleMode);
    takeTabKey();

    uiCamera = new FunkinCamera('chartEditorUI');
    FlxG.cameras.reset(uiCamera);

    buildDefaultSongData();

    this.buildBackground();

    this.updateTheme();

    this.buildGrid();
    this.buildMeasureTicks();
    this.buildNotePreview();

    this.buildAdditionalUI();
    this.populateOpenRecentMenu();
    this.applyPlatformShortcutText();

    this.createSubtitles();

    // Setup the onClick listeners for the UI after it's been created.
    this.setupUIListeners();
    this.setupTurboKeyHandlers();

    this.setupAutoSave();

    refresh();

    if (params != null && params.loadFromPath != null)
    {
      // Chart editor was opened from the command line. Open the FNFC file now!
      try
      {
        this.loadSongFromFNFCPath(params.loadFromPath);
        if (params.targetSongVariation != null) this.selectedVariation = params.targetSongVariation;
        if (params.targetSongDifficulty != null) this.selectedDifficulty = params.targetSongDifficulty;
        if (params.targetSongPosition != null)
        {
          this.scrollPositionInMs = params.targetSongPosition;
          this.moveSongToScrollPosition();
          this.currentScrollEase = this.scrollPositionInPixels;
        }
      }
      catch (e)
      {
        this.error('Failure', 'Failed to load chart (${params.loadFromPath}):\n$e');
        // Song failed to load, open the Welcome dialog so we aren't in a broken state.
        var welcomeDialog = this.openWelcomeDialog(false);
        if (shouldShowBackupAvailableDialog)
        {
          this.openBackupAvailableDialog(welcomeDialog);
        }
      }
    }
    else if (params != null && params.loadFromTemplate != null)
    {
      var targetSongId = params.loadFromTemplate;
      var targetSongDifficulty = params.targetSongDifficulty ?? null;
      var targetSongVariation = params.targetSongVariation ?? null;

      try
      {
        this.loadSongFromTemplate(targetSongId, targetSongDifficulty, targetSongVariation);
        if (targetSongVariation != null) this.selectedVariation = targetSongVariation;
        if (targetSongDifficulty != null) this.selectedDifficulty = targetSongDifficulty;
        if (params.targetSongPosition != null)
        {
          this.scrollPositionInMs = params.targetSongPosition;
          this.moveSongToScrollPosition();
          this.currentScrollEase = this.scrollPositionInPixels;
        }
      }
      catch (e)
      {
        this.error('Failure', 'Failed to load chart (${targetSongId})\n$e');

        // Song failed to load, open the Welcome dialog so we aren't in a broken state.
        var welcomeDialog = this.openWelcomeDialog(false);
        if (shouldShowBackupAvailableDialog)
        {
          this.openBackupAvailableDialog(welcomeDialog);
        }
      }
    }
    else if (params != null && params.loadFromFNFCData != null)
    {
      try
      {
        this.loadSongFromFNFCData(params.loadFromFNFCData);
        if (params.targetSongVariation != null) this.selectedVariation = params.targetSongVariation;
        if (params.targetSongDifficulty != null) this.selectedDifficulty = params.targetSongDifficulty;
        if (params.targetSongPosition != null)
        {
          this.scrollPositionInMs = params.targetSongPosition;
          this.moveSongToScrollPosition();
          this.currentScrollEase = this.scrollPositionInPixels;
        }
      }
      catch (e)
      {
        this.error('Failure', 'Failed to load FNFCData (${params.loadFromFNFCData})\n$e');

        // Song failed to load, open the Welcome dialog so we aren't in a broken state.
        var welcomeDialog = this.openWelcomeDialog(false);
        if (shouldShowBackupAvailableDialog)
        {
          this.openBackupAvailableDialog(welcomeDialog);
        }
      }
    }
    else
    {
      var welcomeDialog = this.openWelcomeDialog(false);
      if (shouldShowBackupAvailableDialog)
      {
        this.openBackupAvailableDialog(welcomeDialog);
      }
    }

    #if FEATURE_DISCORD_RPC
    updateDiscordRPC();
    #end

    Toolkit.callLater(() ->
    {
      @:nullSafety(Off)
      {
        final f = FocusManager.instance.focus;
        if (f != null) f.focus = false;
      }
      for (root in haxe.ui.core.Screen.instance.rootComponents)
      {
        root.removeClass(":hover", false, true);
        root.removeClass(":down", false, true);
      }
    });
  }

  #if FEATURE_DISCORD_RPC
  function updateDiscordRPC():Void
  {
    funkin.api.discord.DiscordClient.instance.setPresence({
      // TODO: Make this display the song name and update when it changes.
      // state: '${currentSongName} [${selectedDifficulty}]',
      state: null,
      details: 'Chart Editor [Charting]'
    });
  }
  #end

  public function resetPreviewTimes()
  {
    currentSongFreeplayPreviewStart = (currentSongMetadata?.playData?.previewStart ?? Constants.DEFAULT_PREVIEW_START_TIME);
    currentSongFreeplayPreviewEnd = (currentSongMetadata?.playData?.previewEnd ?? Constants.DEFAULT_PREVIEW_END_TIME);
  }

  var bgMusicTimer:FlxTimer;

  function buildDefaultSongData():Void
  {
    selectedVariation = Constants.DEFAULT_VARIATION;
    selectedDifficulty = Constants.DEFAULT_DIFFICULTY;

    // Initialize the song metadata.
    songMetadata = new Map<String, SongMetadata>();

    // Initialize the song chart data.
    songChartData = new Map<String, SongChartData>();
  }

  /**
   * Builds and displays the background sprite.
   */
  /**
   * Leaving the editor: the next state is built at the game's normal size.
   */
  function restoreScaleMode():Void
  {
    FlxG.signals.preStateSwitch.remove(restoreScaleMode);
    ChartEditorScaleMode.restore();
    // The cameras were already reset at the editor's size.
    FlxG.cameras.reset();
  }

  /**
   * The game size changed, from the window or the UI scale. Moves everything placed when the editor was built.
   */
  override public function onResize(width:Int, height:Int):Void
  {
    super.onResize(width, height);
    if (gridTiledSprite == null) return;

    for (camera in FlxG.cameras.list) camera.setSize(FlxG.width, FlxG.height);

    if (root != null)
    {
      root.width = Screen.instance.width;
      root.height = Screen.instance.height;
    }
    this.relayoutDialogs();
    this.refreshUIScaleLabel();

    if (menuBG != null)
    {
      menuBG.setGraphicSize(Std.int(Math.max(FlxG.width, FlxG.height * menuBG.frameWidth / menuBG.frameHeight) * 1.1));
      menuBG.updateHitbox();
      menuBG.screenCenter();
    }

    var gridX:Float = GRID_X_POS;
    gridTiledSprite.x = gridX;
    gridPlayhead.x = gridX;

    if (measureTicks != null) measureTicks.x = gridX - GRID_SIZE;

    renderedNotes.x = gridX;
    renderedHoldNotes.x = gridX;
    renderedEvents.x = gridX;
    renderedSelectionSquares.x = gridX;

    if (buttonSelectOpponent != null)
    {
      buttonSelectOpponent.x = gridX;
      if (buttonSelectDummy != null) buttonSelectDummy.x = gridX - GRID_SIZE;
      if (buttonSelectPlayer != null)
      {
        buttonSelectPlayer.x = buttonSelectOpponent.x + buttonSelectOpponent.width;
        if (buttonSelectEvent != null) buttonSelectEvent.x = buttonSelectPlayer.x + buttonSelectPlayer.width;
      }
    }

    if (notePreview != null) notePreview.x = ChartEditorLayoutHandler.notePreviewXPos();
    if (notePreviewPlayhead != null && notePreview != null) notePreviewPlayhead.x = notePreview.x;
    notePreviewViewportBoundsDirty = true;

    if (playbarHeadLayout != null)
    {
      playbarHeadLayout.width = FlxG.width;
      playbarHeadLayout.playbarHead.width = FlxG.width;
    }
    gridLinesDirty = true;

    if (notePreview != null)
    {
      notePreview.resize(FlxG.height - NOTE_PREVIEW_Y_POS - (PLAYBAR_HEIGHT + 10));
      notePreviewDirty = true;
      notePreviewViewportBoundsDirty = true;
    }
    noteDisplayDirty = true;
    commentDisplayDirty = true;
    waveformsDirty = true;
  }

  /**
   * The game size the dialogs were last placed for.
   */
  var dialogLayoutSize:FlxPoint = FlxPoint.get(FlxG.initialWidth, FlxG.initialHeight);

  /**
   * Automatically goes through and calls render on everything you added.
   */
  override public function draw():Void
  {
    if (criticalFailure) return;

    super.draw();
  }

  var displayAutosavePopup:Bool = false;

  /**
   * Open the backups folder in the file explorer.
   * Don't call this on HTML5.
   */
  function openBackupsFolder(?_):Bool
  {
    #if sys
    // TODO: Is there a way to open a folder and highlight a file in it?
    var absoluteBackupsPath:String = Path.join([
      Sys.getCwd(),
      ChartEditorImportExportHandler.BACKUPS_PATH
    ]);
    FileUtil.openFolder(absoluteBackupsPath);
    return true;
    #else
    trace('No file system access, cannot open backups folder.');
    return false;
    #end
  }

  override public function update(elapsed:Float):Void
  {
    // dispatchEvent gets called here.
    super.update(elapsed);

    haxeUIFocusedValid = false;

    if (criticalFailure) return;

    if (uiScaleDirty && !FlxG.mouse.pressed)
    {
      uiScaleDirty = false;
      ChartEditorScaleMode.apply(uiScale);
    }

    Preferences.debugDisplay == DebugDisplayMode.Off ? menubar.paddingLeft = null : menubar.paddingLeft = 256;

    // These ones happen even if the modal dialog is open.
    this.handleMusicPlayback(elapsed);
    this.handleCommentDisplay();
    this.handleZoom(elapsed);
    this.handleNoteDisplay();
    this.handleGridLines();
    this.handleRangeSelection();
    this.handleStaleTooltip();
    this.handleGridTooltips(elapsed);

    if (isHaxeUIFocused && !isCursorOverHaxeUI && (FlxG.mouse.justPressedRight || FlxG.mouse.deltaWheel.y != 0))
    {
      ChartEditorToolboxHandler.clearHaxeUIFocus();
    }

    // These ones only happen if the modal dialog is not open.
    this.handleScrollKeybinds();

    this.handleCursor();
    this.handleGridDoubleClicks();
    this.handleSelectables();

    this.handleListKeybinds();
    this.handleUndoRedoKeybinds();
    if (!(isHaxeUIFocused || isCursorOverHaxeUI))
    {
      this.handleSnap();
      this.handlePlayhead();
      this.handleEditKeybinds();
    }

    this.handleMenubar();
    this.handleToolboxes();
    this.handlePlaybar();
    this.handleNotePreview();
    this.handleHealthIcons();
    this.handleWaveforms();
    this.handleWaveformFilter(elapsed);

    this.handleCommandPalette();

    this.handleFileKeybinds();
    this.handleViewKeybinds();
    this.handleTestKeybinds();
    this.handleHelpKeybinds();
    this.handleAudioKeybinds();

    #if FEATURE_DEBUG_FUNCTIONS
    handleQuickWatch();
    #end

    handlePostUpdate();
  }

  /**
   * Function called when the game window loses focus.
   */
  override public function onFocusLost():Void
  {
    super.onFocusLost();

    if (selectionBoxStartPos != null)
    {
      if (selectionBoxSprite != null) selectionBoxSprite.visible = false;
      selectionBoxStartPos.put();
      selectionBoxStartPos = null;
    }

    // Stop the song upon tabbing out.
    if (Preferences.autoPause)
    {
      this.stopAudioPlayback(false);
    }

    // No mouse events arrive while unfocused, so the tooltip would never be told to hide.
    this.hideTooltip();
  }

  // The note or event sprite under the mouse, how long it has been there, and whether its tooltip is showing.
  var gridTooltipTarget:Null<FlxSprite> = null;
  var gridTooltipTime:Float = 0;
  var gridTooltipShown:Bool = false;

  /**
   * Function called when the game window regains focus.
   */
  override public function onFocus():Void
  {
    super.onFocus();

    if (!isPlaytesting)
    {
      this.fadeInWelcomeMusic(WELCOME_MUSIC_FADE_IN_DELAY, WELCOME_MUSIC_FADE_IN_DURATION);
    }
  }

  /**
   * Beat hit while the song is playing.
   */
  override function beatHit():Bool
  {
    // dispatchEvent gets called here.
    if (!super.beatHit()) return false;

    if (metronomeVolume > 0.0 && !metronomeMuted && !isPlaytesting && ((audioInstTrack != null && audioInstTrack.isPlaying) || audioVocalTrackGroup.playing))
    {
      var currentMeasureTime:Float = Conductor.instance.getMeasureTimeInMs(Conductor.instance.currentMeasure);
      var currentStepTime:Float = Conductor.instance.getStepTimeInMs(Conductor.instance.currentStep);
      final msTreshold:Float = 10.0;
      this.playMetronomeTick(currentMeasureTime >= currentStepTime - msTreshold && currentMeasureTime <= currentStepTime + msTreshold);
    }

    // Show the mouse cursor.
    // Just throwing this somewhere convenient and infrequently called because sometimes Flixel's debug thing hides the cursor.
    if (!isPlaytesting) Cursor.show();

    return true;
  }

  /**
   * Step hit while the song is playing.
   */
  override function stepHit():Bool
  {
    // dispatchEvent gets called here.
    if (!super.stepHit()) return false;

    if ((audioInstTrack != null && audioInstTrack.isPlaying) || audioVocalTrackGroup.playing)
    {
      if (healthIconDad != null) healthIconDad.onStepHit(Conductor.instance.currentStep);
      if (healthIconBF != null) healthIconBF.onStepHit(Conductor.instance.currentStep);
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
   * A stretch of song time picked with Tab. The first press marks the start at the playhead, the second marks the end.
   */
  var rangeSelectionStartMs:Null<Float> = null;

  var rangeSelectionEndMs:Null<Float> = null;

  /**
   * Covers the selected stretch across the note field, or marks its start with a line.
   */
  var rangeSelectionSprite:Null<FlxSprite> = null;

  static final RANGE_SELECTION_COLOR:FlxColor = 0xFF3C8DF0;
  static final RANGE_SELECTION_ALPHA:Float = 0.5;
  static final RANGE_SELECTION_MARKER_HEIGHT:Float = 3;

  /**
   * Whether both ends of the Tab selection are marked.
   */
  var hasRangeSelection(get, never):Bool;

  /**
   * Stop haxeui from taking my tab
   */
  function takeTabKey():Void
  {
    Screen.instance.unregisterEvent(haxe.ui.events.KeyboardEvent.KEY_DOWN, @:privateAccess Toolkit.onKeyDown);
    Screen.instance.registerEvent(haxe.ui.events.KeyboardEvent.KEY_DOWN, onEditorTabKey);
  }

  function returnTabKey():Void
  {
    Screen.instance.unregisterEvent(haxe.ui.events.KeyboardEvent.KEY_DOWN, onEditorTabKey);
    Screen.instance.registerEvent(haxe.ui.events.KeyboardEvent.KEY_DOWN, @:privateAccess Toolkit.onKeyDown);
  }

  static function onEditorTabKey(event:haxe.ui.events.KeyboardEvent):Void
  {
    if (FocusManager.instance.focus == null) return;
    @:privateAccess Toolkit.onKeyDown(event);
  }

  function get_hasRangeSelection():Bool
  {
    return rangeSelectionStartMs != null && rangeSelectionEndMs != null;
  }

  /**
   * Handle using `renderedNotes` to display notes from `currentSongChartNoteData`.
   */
  /**
   * The snap event chains were last grouped at. Changing the snap regroups them.
   */
  var eventChainSnapRatio:Float = -1;

  /**
   * The last click on an event or time change tag, to tell when it's clicked again quickly.
   */
  var lastGridClickTime:Float = 0;

  var lastGridClickTarget:Dynamic = null;

  static final DOUBLE_CLICK_SECONDS:Float = 0.35;

  /**
   * Migrates old event data with ease and without easeDir fields, so we split them into ease and easeDir here.
   */
  function migrateEventEaseDirectionFields(eventValues:Dynamic):Dynamic
  {
    if (eventValues.ease != null && SongEvent.EASE_TYPE_DIR_REGEX.match(eventValues.ease))
    {
      eventValues.ease = SongEvent.EASE_TYPE_DIR_REGEX.matchedLeft();
      eventValues.easeDir = SongEvent.EASE_TYPE_DIR_REGEX.matched(0);
    }
    return eventValues;
  }

  /**
   * Handle aligning the health icons next to the grid.
   */
  var _charIconData = null;

  function performCleanup():Void
  {
    this.destroyHaxeUIComponents();

    @:privateAccess
    ChartEditorNoteSprite.noteFrameCollection = null;
    @:privateAccess
    ChartEditorEventSprite.eventFrames = null;

    activeToolboxes.clear();

    criticalFailure = true;
  }

  @:nullSafety(Off)
  function quitChartEditor(exitPrompt:Bool = false):Void
  {
    if (saveDataDirty && exitPrompt)
    {
      this.openLeaveConfirmationDialog();
      return;
    }

    this.autoSave();

    this.hideAllToolboxes();

    this.stopWelcomeMusic();
    // TODO: PR Flixel to make onComplete nullable.
    if (audioInstTrack != null) audioInstTrack.onComplete = null;

    performCleanup();

    MenuMusicGroup.instance.reset(MAIN_MENU);

    Transition.switchState(() -> new MainMenuState(), {
      assetQuery: MainMenuState.queryAssets,
      transition: BlackScreen(None, None)
    });

    this.resetWindowTitle();
  }

  /**
   * The last clicked toolbox list that receives keyboard input for copy, paste, and delete actions.
   */
  var listKeyTarget:Null<ChartEditorListKeyTarget> = null;

  /**
   * Small helper for MacOS, "WINDOWS" is keycode 15, which maps to "COMMAND" on Mac, which is more often used than "CONTROL"
   * Everywhere else, it just returns `FlxG.keys.pressed.CONTROL`
   * @return Bool
   */
  function pressingControl():Bool
  {
    #if mac
    return FlxG.keys.pressed.WINDOWS;
    #else
    return FlxG.keys.pressed.CONTROL;
    #end
  }

  /**
   * Apply every volume slider in the Preferences toolbox to the audio, and update their labels.
   */
  function applyPreferenceVolumes():Void
  {
    metronomeVolume = preferencesVolumeMetronome.pos / 100.0;
    preferencesLabelVolumeMetronome.text = 'Metronome - ${Math.round(preferencesVolumeMetronome.pos)}%';
    hitsoundVolumePlayer = preferencesVolumeHitsoundPlayer.pos / 100.0;
    preferencesLabelVolumeHitsoundPlayer.text = 'Player - ${Math.round(preferencesVolumeHitsoundPlayer.pos)}%';
    hitsoundVolumeOpponent = preferencesVolumeHitsoundOpponent.pos / 100.0;
    preferencesLabelVolumeHitsoundOpponent.text = 'Opponent - ${Math.round(preferencesVolumeHitsoundOpponent.pos)}%';
    if (audioInstTrack != null) audioInstTrack.volume = preferencesVolumeInstrumental.pos / 100.0;
    preferencesLabelVolumeInstrumental.text = 'Instrumental - ${Math.round(preferencesVolumeInstrumental.pos)}%';
    audioVocalTrackGroup.playerVolume = preferencesVolumeVocalsPlayer.pos / 100.0;
    preferencesLabelVolumeVocalsPlayer.text = 'Player - ${Math.round(preferencesVolumeVocalsPlayer.pos)}%';
    audioVocalTrackGroup.opponentVolume = preferencesVolumeVocalsOpponent.pos / 100.0;
    preferencesLabelVolumeVocalsOpponent.text = 'Opponent - ${Math.round(preferencesVolumeVocalsOpponent.pos)}%';
  }

  function handleQuickWatch():Void
  {
    FlxG.watch.addQuick('songLengthInMs', audioInstTrack?.length ?? 0.0);
    FlxG.watch.addQuick('songLengthInSteps', Conductor.instance.getTimeInSteps(audioInstTrack?.length ?? 0.0));
    FlxG.watch.addQuick('songLengthInPixels', songLengthInPixels);
    FlxG.watch.addQuick('gridHeight', gridTiledSprite?.height ?? 0.0);

    FlxG.watch.addQuick('musicTime', audioInstTrack?.time ?? 0.0);

    FlxG.watch.addQuick('noteKindToPlace', noteKindToPlace);
    FlxG.watch.addQuick('noteParamsToPlace', noteParamsToPlace);
    FlxG.watch.addQuick('eventKindToPlace', eventKindToPlace);

    FlxG.watch.addQuick('scrollPosInPixels', scrollPositionInPixels);
    FlxG.watch.addQuick('playheadPosInPixels', playheadPositionInPixels);

    FlxG.watch.addQuick('tapNotesRendered', renderedNotes?.members?.length);
    FlxG.watch.addQuick('holdNotesRendered', renderedHoldNotes?.members?.length);
    FlxG.watch.addQuick('eventsRendered', renderedEvents?.members?.length);
    FlxG.watch.addQuick('notesSelected', currentNoteSelection?.length);
    FlxG.watch.addQuick('eventsSelected', currentEventSelection?.length);
  }

  function handlePostUpdate():Void
  {
    wasCursorOverHaxeUI = isCursorOverHaxeUI;
    wasHaxeUIDialogOpen = isHaxeUIDialogOpen;
  }

  /**
   * PLAYTEST FUNCTIONS
   */
  // ====================

  /**
   * COMMAND FUNCTIONS
   */
  // ====================

  /**
   * Perform (or redo) a command, then add it to the undo stack.
   *
   * @param command The command to perform.
   * @param purgeRedoStack If `true`, the redo stack will be cleared after performing the command.
   */
  function performCommand(command:ChartEditorCommand, purgeRedoStack:Bool = true):Void
  {
    command.execute(this);
    if (command.shouldAddToHistory(this))
    {
      undoHistory.push(command);
      commandHistoryDirty = true;
    }
    if (purgeRedoStack) redoHistory = [];

    ChartEditorToolboxHandler.refreshToolbox(this, ChartEditorState.CHART_EDITOR_TOOLBOX_EVENT_DATA_LAYOUT);
    ChartEditorToolboxHandler.refreshToolbox(this, ChartEditorState.CHART_EDITOR_TOOLBOX_NOTE_DATA_LAYOUT);
  }

  /**
   * Undo a command, then add it to the redo stack.
   * @param command The command to undo.
   */
  function undoCommand(command:ChartEditorCommand):Void
  {
    command.undo(this);
    // Note, if we are undoing a command, it should already be in the history,
    // therefore we don't need to check `shouldAddToHistory(state)`
    redoHistory.push(command);
    commandHistoryDirty = true;

    ChartEditorToolboxHandler.refreshToolbox(this, ChartEditorState.CHART_EDITOR_TOOLBOX_EVENT_DATA_LAYOUT);
    ChartEditorToolboxHandler.refreshToolbox(this, ChartEditorState.CHART_EDITOR_TOOLBOX_NOTE_DATA_LAYOUT);
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
   * AUDIO FUNCTIONS
   */
  // ====================

  /**
   * CHART DATA FUNCTIONS
   */
  // ====================

  function sortChartData():Void
  {
    // TODO: .insertionSort()
    currentSongChartNoteData.sort(function(a:SongNoteData, b:SongNoteData):Int
    {
      return FlxSort.byValues(FlxSort.ASCENDING, a.time, b.time);
    });

    // TODO: .insertionSort()
    currentSongChartEventData.sort(function(a:SongEventData, b:SongEventData):Int
    {
      return FlxSort.byValues(FlxSort.ASCENDING, a.time, b.time);
    });
  }

  /**
   * For each event chain, the event the grid shows for it, and the rest of the chain.
   */
  var eventChainFollowers:haxe.ds.ObjectMap<SongEventData, Bool> = new haxe.ds.ObjectMap();

  var eventChainRest:haxe.ds.ObjectMap<SongEventData, Array<SongEventData>> = new haxe.ds.ObjectMap();

  /**
   * SCROLLING FUNCTIONS
   */
  // ====================

  /**
   * HAXEUI FUNCTIONS
   */
  // ==================

  /**
   * STATIC FUNCTIONS
   */
  // ==================

  /**
   * Handle the playback of hitsounds.
   */
  var _scriptNoteObj:NoteSprite = null;

  var _currentEvents = null;
  var _allowedEvents = null;
  var _eventTarget:Null<CharacterPlayer> = null;

  public static var _allowedEventsNames:Array<String> = ['PlayAnimation', 'SetTargetBopSpeed'];

  /**
   * Whether the `Audio -> Mute Player Vocals` toggle is on.
   */
  var playerVocalsMuted(default, set):Bool = false;

  function set_playerVocalsMuted(value:Bool):Bool
  {
    playerVocalsMuted = value;
    this.applyVocalMutes();
    return playerVocalsMuted;
  }

  /**
   * Whether the `Audio -> Mute Opponent Vocals` toggle is on.
   */
  var opponentVocalsMuted(default, set):Bool = false;

  function set_opponentVocalsMuted(value:Bool):Bool
  {
    opponentVocalsMuted = value;
    this.applyVocalMutes();
    return opponentVocalsMuted;
  }

  /**
   * Whether the `Audio -> Mute Instrumental` toggle is on.
   */
  var instrumentalMuted(default, set):Bool = false;

  function set_instrumentalMuted(value:Bool):Bool
  {
    instrumentalMuted = value;
    if (audioInstTrack != null) audioInstTrack.muted = instrumentalMuted;
    return instrumentalMuted;
  }

  /**
   * Refreshes the offsets toolbox in the chart editor.
   */
  function hardRefreshOffsetsToolbox():Void
  {
    this.refreshToolbox(CHART_EDITOR_TOOLBOX_METADATA_LAYOUT);
  }

  function isNoteSelected(note:Null<SongNoteData>):Bool
  {
    return note != null && currentNoteSelection.indexOf(note) != -1;
  }

  function doesNoteStack(note:Null<SongNoteData>,
    curStackedNotes:Array<SongNoteData>):Bool
  {
    return note != null && curStackedNotes.contains(note);
  }

  @:nullSafety(Off)
  override function destroy():Void
  {
    trace('Destroying ChartEditorState...');
    returnTabKey();
    FlxG.signals.preStateSwitch.remove(restoreScaleMode);
    ChartEditorScaleMode.restore();
    ChartEditorCommandPalette.instance?.close();
    funkin.util.plugins.VolumePlugin.ignoreWithControl = false;
    super.destroy();

    performCleanup();
    this.resetWindowTitle();

    this.cleanupAutoSave();

    this.closeExistingMenu();

    // Hide the mouse cursor on other states.
    Cursor.hide();

    // Stop the music.
    if (welcomeMusic != null) welcomeMusic.destroy();
    if (audioInstTrack != null) audioInstTrack.destroy();
    if (audioVocalTrackGroup != null) audioVocalTrackGroup.destroy();

    // Destroy graphics and components.
    if (renderedNotes != null)
    {
      renderedNotes.destroy();
      renderedNotes = null;
    }
    if (renderedHoldNotes != null)
    {
      renderedHoldNotes.destroy();
      renderedHoldNotes = null;
    }
    if (renderedEvents != null)
    {
      renderedEvents.destroy();
      renderedEvents = null;
    }
    if (renderedSelectionSquares != null)
    {
      renderedSelectionSquares.destroy();
      renderedSelectionSquares = null;
    }

    // Reset the sounds used by some playables.
    funkin.play.GameOverSubState.reset();
    funkin.play.PauseSubState.reset();
    funkin.play.Countdown.reset();

    // Clear graphics from HaxeUI's cache
    @:privateAccess {
      haxe.ui.ToolkitAssets.instance._imageCache.clear();
      haxe.ui.ToolkitAssets.instance._imageCallbacks._map.clear();
    }
  }
}

/**
 * Parameters to initialize the Chart Editor with.
 * Most of these are optional.
 */
typedef ChartEditorParams =
{
  // CHART LOADING

  /**
   * If non-null, load an existing song directly from a file path.
   */
  var ?loadFromPath:String;

  /**
   * If non-null, load an existing song directly from the game's assets.
   */
  var ?loadFromTemplate:String;

  /**
   * If non-null, load from existing FNFCData.
   */
  var ?loadFromFNFCData:FNFCData;

  // STARTING POSITION

  /**
   * If non-null, load this difficulty immediately instead of the default difficulty.
   */
  var ?targetSongDifficulty:String;

  /**
   * If non-null, load this variation immediately instead of the default variation.
   */
  var ?targetSongVariation:String;

  /**
   * If non-null, load into the editor with the cursor directly at the given song position,
   * instead of at the start of the song.
   */
  var ?targetSongPosition:Float;
};

#end

/**
 * Available input modes for the chart editor state. Numbers/arrows/WASD available for other keybinds.
 */
enum abstract ChartEditorLiveInputStyle(String)
{
  /**
   * No hotkeys to place notes at the playbar.
   */
  public var None;

  /**
   * 1/2/3/4 to place notes on opponent's side, 5/6/7/8 to place notes on player's side.
   */
  public var NumberKeys;

  /**
   * WASD to place notes on opponent's side, Arrow keys to place notes on player's side.
   */
  public var WASDKeys;
}

/**
 * Available waveform positions for the chart editor state.
 */
/**
 * A finished waveform filter job.
 */
typedef WaveformFilterResult =
{
  /**
   * Which application of the filter settings this was made for.
   */
  var generation:Int;

  var waveform:ChartEditorWaveformSprite;
  var data:Null<funkin.audio.waveform.WaveformData>;
}

/**
 * Filters that can be applied to the chart editor's waveform overlay.
 */
enum abstract ChartEditorWaveformFilter(String)
{
  /**
   * No overlay.
   */
  public var None;

  /**
   * Keeps the low end, like kicks and bass.
   */
  public var LowPass;

  /**
   * Keeps the high end, like hats and consonants.
   */
  public var HighPass;
}

enum abstract ChartEditorWaveformPos(String)
{
  /**
   * Waveforms are shown adjacent to the charting grid.
   */
  public var Adjacent;

  /**
   * Waveforms are shown overlapping the charting grid.
   */
  public var Overlay;
}

/**
 * Available themes for the chart editor state.
 */
enum abstract ChartEditorTheme(String)
{
  /**
   * The default theme for the chart editor.
   */
  public var Light;

  /**
   * A theme which introduces darker colors.
   */
  public var Dark;
}
