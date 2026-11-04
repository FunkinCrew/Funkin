package funkin.ui.debug.charting;

import funkin.ui.transition.Transition;
#if FEATURE_CHART_EDITOR
import funkin.ui.debug.charting.components.ChartEditorCommandPalette;
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
import funkin.ui.debug.charting.commands.AddCommentCommand;
import funkin.ui.debug.charting.commands.AddEventsCommand;
import funkin.ui.debug.charting.commands.AddNewTimeChangeCommand;
import funkin.ui.debug.charting.commands.AddNotesCommand;
import funkin.ui.debug.charting.commands.ChartEditorCommand;
import funkin.ui.debug.charting.commands.CopyItemsCommand;
import funkin.ui.debug.charting.commands.CutItemsCommand;
import funkin.ui.debug.charting.commands.DeselectAllItemsBetweenTimeCommand;
import funkin.ui.debug.charting.commands.DeselectAllItemsCommand;
import funkin.ui.debug.charting.commands.DeselectItemsCommand;
import funkin.ui.debug.charting.commands.ExtendNoteLengthCommand;
import funkin.ui.debug.charting.commands.FlipNotesCommand;
import funkin.ui.debug.charting.commands.InvertSelectedItemsCommand;
import funkin.ui.debug.charting.commands.MirrorNotesCommand;
import funkin.ui.debug.charting.commands.MoveEventsCommand;
import funkin.ui.debug.charting.commands.MoveItemsCommand;
import funkin.ui.debug.charting.commands.MoveNotesCommand;
import funkin.ui.debug.charting.commands.PasteItemsCommand;
import funkin.ui.debug.charting.commands.RemoveEventsCommand;
import funkin.ui.debug.charting.commands.RemoveItemsCommand;
import funkin.ui.debug.charting.commands.RemoveNotesCommand;
import funkin.ui.debug.charting.commands.RemoveStackedNotesCommand;
import funkin.ui.debug.charting.commands.SelectAllItemsBetweenTimeCommand;
import funkin.ui.debug.charting.commands.SelectAllItemsCommand;
import funkin.ui.debug.charting.commands.SelectItemsCommand;
import funkin.ui.debug.charting.commands.SetItemSelectionCommand;
import funkin.ui.debug.charting.commands.SwitchDifficultyCommand;
import funkin.ui.debug.charting.components.ChartEditorCommentPinSprite;
import funkin.ui.debug.charting.components.ChartEditorEventSprite;
import funkin.ui.debug.charting.components.ChartEditorHoldNoteSprite;
import funkin.ui.debug.charting.components.ChartEditorGridLines;
import funkin.ui.debug.charting.components.ChartEditorWaveformSprite;
import funkin.ui.debug.charting.components.ChartEditorMeasureTicks;
import funkin.ui.debug.charting.components.ChartEditorDifficultyHeatmap;
import funkin.ui.debug.charting.components.ChartEditorTimeChangeSelection;
import funkin.ui.debug.charting.components.ChartEditorNotePreview;
import funkin.ui.debug.charting.util.ChartEditorScaleMode;
import funkin.ui.debug.charting.components.ChartEditorNoteSprite;
import funkin.ui.debug.charting.components.ChartEditorPlaybarHead;
import funkin.ui.debug.charting.components.ChartEditorCommentPanel;
import funkin.ui.debug.charting.components.ChartEditorSelectionSquareSprite;
import funkin.ui.debug.charting.handlers.ChartEditorToolboxHandler;
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
    updateGridHeight();
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
    setNotePreviewViewportBounds(calculateNotePreviewViewportBounds());
    refreshNotePreviewPlayheadPosition();

    if (measureTicks != null) handleMeasureTickPosition();
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

    updatePlayheadGhostHoldNotes();
    refreshNotePreviewPlayheadPosition();

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

  function handleZoom(elapsed:Float):Void
  {
    var target:Float = ZOOM_LEVELS[zoomLevelIndex];
    if (zoomCurrent == target) return;

    // Eased in log space, so each zoom step feels the same size at both ends of the range.
    var logZoom:Float = MathUtil.smoothLerpPrecision(Math.log(zoomCurrent), Math.log(target), elapsed, ZOOM_EASE_DURATION, 1 / 1000);
    zoomCurrent = MathUtil.snap(Math.exp(logZoom), target, target / 1000);
    updateGridScale();
  }

  /**
   * Whether constant scroll is turned on in Preferences. See `CONSTANT_SCROLL`.
   */
  var constantScrollEnabled(default, set):Bool = false;

  function set_constantScrollEnabled(value:Bool):Bool
  {
    constantScrollEnabled = value;
    updateGridScale(gridTiledSprite != null);
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
    updateGridScale();
    return constantScrollSpeed;
  }

  /**
   * Recalculate how the grid maps to the song.
   * @param rebuildScrollSpeeds Also rebuild the constant scroll speed map from the events.
   */
  function updateGridScale(rebuildScrollSpeeds:Bool = false):Void
  {
    var hasGrid:Bool = gridTiledSprite != null;
    var playheadSongMs:Float = hasGrid ? ChartEditorTimeScale.pixelsToMs(scrollPositionInPixels + playheadPositionInPixels) : 0;
    var oldEase:Null<Float> = currentScrollEase;
    var easeSongMs:Null<Float> = (!hasGrid || oldEase == null) ? null : ChartEditorTimeScale.pixelsToMs(oldEase + playheadPositionInPixels);

    var oldStepHeight:Float = ChartEditorTimeScale.STEP_HEIGHT;
    var oldConstantScroll:Bool = ChartEditorTimeScale.CONSTANT_SCROLL;
    var oldPixelsPerMs:Float = ChartEditorTimeScale.PIXELS_PER_MS;
    ChartEditorTimeScale.STEP_HEIGHT = GRID_SIZE * zoomCurrent;
    ChartEditorTimeScale.CONSTANT_SCROLL = constantScrollEnabled;
    ChartEditorTimeScale.PIXELS_PER_MS = ChartEditorTimeScale.STEP_HEIGHT * constantScrollSpeed / ChartEditorTimeScale.CONSTANT_SCROLL_REFERENCE_STEP_MS;
    var speedsChanged:Bool = rebuildScrollSpeeds && ChartEditorTimeScale.buildScrollSpeedPoints(currentSongChartEventData, currentSongChartScrollSpeed);

    if (!hasGrid) return;
    var layoutChanged:Bool = speedsChanged && !ChartEditorTimeScale.CONSTANT_SCROLL;
    if (!layoutChanged && oldStepHeight == ChartEditorTimeScale.STEP_HEIGHT && oldConstantScroll == ChartEditorTimeScale.CONSTANT_SCROLL && oldPixelsPerMs == ChartEditorTimeScale.PIXELS_PER_MS) return;

    // Then back to pixels with the new scale.
    var playheadSongPixels:Float = ChartEditorTimeScale.msToPixels(playheadSongMs);
    var easeSongPixels:Null<Float> = (easeSongMs == null) ? null : ChartEditorTimeScale.msToPixels(easeSongMs);
    var newPlayhead:Float = playheadPositionInPixels;
    var newScroll:Float = playheadSongPixels - newPlayhead;
    if (newScroll < 0)
    {
      newScroll = 0;
      newPlayhead = playheadSongPixels;
    }

    // The old values are in the old scale's pixels, so write them directly before the setters clamp against them.
    @:bypassAccessor this.playheadPositionInPixels = newPlayhead;
    @:bypassAccessor this.scrollPositionInPixels = -1;
    scrollPositionInPixels = newScroll;
    playheadPositionInPixels = newPlayhead;

    currentScrollEase = (easeSongPixels == null) ? scrollPositionInPixels : Math.max(0, easeSongPixels - newPlayhead);

    if (gridTiledSprite != null) gridTiledSprite.height = songLengthInPixels;
    measureTicks?.setHeight(songLengthInPixels);

    noteDisplayDirty = true;
    commentDisplayDirty = true;
    gridLinesDirty = true;
    waveformsDirty = true;
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

  function handleWaveformFilter(elapsed:Float):Void
  {
    #if target.threaded
    var result:Null<WaveformFilterResult> = waveformFilterResults.pop(false);
    while (result != null)
    {
      if (result.generation == waveformFilterGeneration && result.waveform.exists)
      {
        result.waveform.overlayData = result.data;
        waveformsDirty = true;
      }
      result = waveformFilterResults.pop(false);
    }
    #end

    if (waveformFilterDelay < 0) return;
    waveformFilterDelay -= elapsed;
    if (waveformFilterDelay > 0) return;
    waveformFilterDelay = -1;

    waveformFilterGeneration++;
    var generation:Int = waveformFilterGeneration;

    for (waveform in audioWaveforms.members)
    {
      // Hidden waveforms get their overlay when shown again, since switching waveforms queues another update.
      if (waveform == null || !waveform.visible) continue;
      var buffer:Null<lime.media.AudioBuffer> = waveform.audioBuffer;
      if (waveformFilter == ChartEditorWaveformFilter.None || buffer == null)
      {
        waveform.overlayData = null;
        waveformsDirty = true;
        continue;
      }

      var highPass:Bool = waveformFilter == ChartEditorWaveformFilter.HighPass;

      var cutoffHz:Float = highPass ? 20 * Math.pow(250, waveformFilterStrength) : 20000 * Math.pow(0.005, waveformFilterStrength);

      #if target.threaded
      var results = waveformFilterResults;
      sys.thread.Thread.create(() ->
      {
        var data = funkin.audio.waveform.WaveformDataParser.interpretAudioBufferFiltered(buffer, WAVEFORM_SAMPLES_PER_POINT, highPass, cutoffHz);
        data?.mipLevelCount();
        results.add({generation: generation, waveform: waveform, data: data});
      });
      #else
      waveform.overlayData = funkin.audio.waveform.WaveformDataParser.interpretAudioBufferFiltered(buffer, WAVEFORM_SAMPLES_PER_POINT, highPass, cutoffHz);
      waveformsDirty = true;
      #end
    }
  }

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
   * Update the instrumental waveform sprite to match the current setting and instrumental.
   */
  function updateInstrumentalWaveform():Void
  {
    var needed:Bool = usingInstrumentalWaveform && audioInstTrack != null;

    var current:Null<ChartEditorWaveformSprite> = instrumentalWaveform;
    if (current != null && (!needed || !current.exists || instrumentalWaveformTrack != audioInstTrack))
    {
      if (current.exists)
      {
        audioWaveforms.remove(current, true);
        current.destroy();
      }
      instrumentalWaveform = null;
      instrumentalWaveformTrack = null;
      waveformsDirty = true;
    }

    var track:Null<FunkinSound> = audioInstTrack;
    if (!needed || instrumentalWaveform != null || track == null) return;

    var instId:String = (currentInstrumentalId == '') ? Constants.DEFAULT_VARIATION : currentInstrumentalId;
    var cacheKey:String = INSTRUMENTAL_WAVEFORM_CACHE_PREFIX + instId;
    var data:Null<funkin.audio.waveform.WaveformData> = audioWaveformDataCache.get(cacheKey);
    if (data == null)
    {
      data = funkin.audio.waveform.WaveformDataParser.interpretFlxSound(track, WAVEFORM_SAMPLES_PER_POINT, true);
      if (data == null) return;
      audioWaveformDataCache.set(cacheKey, data);
    }

    // Super secret GF key
    var waveform:ChartEditorWaveformSprite = new ChartEditorWaveformSprite(this, data, GF);
    @:privateAccess waveform.audioBuffer = track._source?.buffer;
    audioWaveforms.add(waveform);
    instrumentalWaveform = waveform;
    instrumentalWaveformTrack = track;
    waveformsDirty = true;
    queueWaveformFilterUpdate();
  }

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
   * Turn the theme music on or off, fading it back in if it should be playing.
   */
  function setThemeMusicEnabled(value:Bool):Void
  {
    shouldPlayWelcomeMusic = value;
    if (!welcomeMusic.active || !shouldPlayWelcomeMusic)
    {
      fadeInWelcomeMusic(WELCOME_MUSIC_FADE_IN_DELAY, WELCOME_MUSIC_FADE_IN_DURATION);
    }
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

    populateOpenRecentMenu();
    applyWindowTitle();

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

    switchToCurrentInstrumental();
    trace('F');
    postLoadInstrumental();
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
      testSongInPlayState(PlayState.lastParams.minimalMode);
    }
  }

  /**
   * Binds the audio volume controls from the Preferences toolbox to the ChartEditorState.
   */
  function bindPreferencesAudioControls():Void
  {
    var toolbox = ChartEditorToolboxHandler.getToolboxUnCast(this, CHART_EDITOR_TOOLBOX_PREFERENCES_LAYOUT);

    preferencesVolumeMetronome = toolbox.findComponent('preferencesVolumeMetronome', Slider);
    preferencesLabelVolumeMetronome = toolbox.findComponent('preferencesLabelVolumeMetronome', Label);
    preferencesVolumeHitsoundPlayer = toolbox.findComponent('preferencesVolumeHitsoundPlayer', Slider);
    preferencesLabelVolumeHitsoundPlayer = toolbox.findComponent('preferencesLabelVolumeHitsoundPlayer', Label);
    preferencesVolumeHitsoundOpponent = toolbox.findComponent('preferencesVolumeHitsoundOpponent', Slider);
    preferencesLabelVolumeHitsoundOpponent = toolbox.findComponent('preferencesLabelVolumeHitsoundOpponent', Label);
    preferencesVolumeInstrumental = toolbox.findComponent('preferencesVolumeInstrumental', Slider);
    preferencesLabelVolumeInstrumental = toolbox.findComponent('preferencesLabelVolumeInstrumental', Label);
    preferencesVolumeVocalsPlayer = toolbox.findComponent('preferencesVolumeVocalsPlayer', Slider);
    preferencesLabelVolumeVocalsPlayer = toolbox.findComponent('preferencesLabelVolumeVocalsPlayer', Label);
    preferencesVolumeVocalsOpponent = toolbox.findComponent('preferencesVolumeVocalsOpponent', Slider);
    preferencesLabelVolumeVocalsOpponent = toolbox.findComponent('preferencesLabelVolumeVocalsOpponent', Label);
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
    setupWelcomeMusic();

    // Show the mouse cursor.
    Cursor.show();

    funkin.util.plugins.VolumePlugin.ignoreWithControl = true;

    bindPreferencesAudioControls();
    loadPreferences();

    ChartEditorScaleMode.apply(uiScale);
    uiScaleDirty = false;
    dialogLayoutSize.set(FlxG.width, FlxG.height);
    FlxG.signals.preStateSwitch.add(restoreScaleMode);
    takeTabKey();

    uiCamera = new FunkinCamera('chartEditorUI');
    FlxG.cameras.reset(uiCamera);

    buildDefaultSongData();

    buildBackground();

    this.updateTheme();

    buildGrid();
    buildMeasureTicks();
    buildNotePreview();

    buildAdditionalUI();
    populateOpenRecentMenu();
    this.applyPlatformShortcutText();

    createSubtitles();

    // Setup the onClick listeners for the UI after it's been created.
    setupUIListeners();
    setupTurboKeyHandlers();

    setupAutoSave();

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
          moveSongToScrollPosition();
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
          moveSongToScrollPosition();
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
          moveSongToScrollPosition();
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

  function setupWelcomeMusic()
  {
    this.welcomeMusic.loadEmbedded(Paths.music('ui/editors/chart-editor/artistic-expression').audio().toFlxSoundAsset());
    FlxG.sound.list.add(this.welcomeMusic);
    this.welcomeMusic.looped = true;
  }

  public function resetPreviewTimes()
  {
    currentSongFreeplayPreviewStart = (currentSongMetadata?.playData?.previewStart ?? Constants.DEFAULT_PREVIEW_START_TIME);
    currentSongFreeplayPreviewEnd = (currentSongMetadata?.playData?.previewEnd ?? Constants.DEFAULT_PREVIEW_END_TIME);
  }

  /**
   * Load the Chart Editor preferences from the save file.
   */
  public function loadPreferences():Void
  {
    var save:Save = Save.instance;

    if (previousWorkingFilePaths[0] == null)
    {
      previousWorkingFilePaths = [null].concat(save.chartEditorPreviousFiles.value);
    }
    else
    {
      previousWorkingFilePaths = [currentWorkingFilePath].concat(save.chartEditorPreviousFiles.value);
    }

    noteSnapQuantIndex = save.chartEditorNoteQuant.value;
    zoomLevelIndex = save.chartEditorZoomLevel.value;
    zoomCurrent = ZOOM_LEVELS[zoomLevelIndex];
    updateGridScale();
    currentLiveInputStyle = save.chartEditorLiveInputStyle.value;
    currentWaveformPos = save.chartEditorWaveformPos.value;
    showInstrumentalWaveform = save.chartEditorShowInstrumentalWaveform.value;
    waveformFilter = save.chartEditorWaveformFilter.value;
    waveformFilterStrength = save.chartEditorWaveformFilterStrength.value;
    isViewDownscroll = save.chartEditorDownscroll.value;
    showNoteKindIndicators = save.chartEditorShowNoteKinds.value;
    showDifficultyHeatmap = save.chartEditorShowDifficultyHeatmap.value;
    showBeatLines = save.chartEditorShowBeatLines.value;
    showCursorLine = save.chartEditorShowCursorLine.value;
    constantScrollSpeed = save.chartEditorConstantScrollSpeed.value;
    uiScale = save.chartEditorUIScale.value;
    constantScrollEnabled = save.chartEditorConstantScroll.value;
    gridBackingAlpha = save.chartEditorGridBackingAlpha.value;
    showSubtitles = save.chartEditorShowSubtitles.value;
    playtestStartTime = save.chartEditorPlaytestStartTime.value;
    playtestAudioSettings = save.chartEditorPlaytestAudioSettings.value;
    playtestShowResults = save.chartEditorPlaytestResultsSettings.value;
    playtestPracticeMode = save.chartEditorPlaytestPracticeMode.value;
    playtestBotPlayMode = save.chartEditorPlaytestBotPlayMode.value;
    playtestSongScripts = save.chartEditorPlaytestSongScripts.value;
    stackedNoteThreshold = save.chartEditorStackedNoteThreshold.value;
    currentTheme = save.chartEditorTheme.value;
    metronomeVolume = save.chartEditorMetronomeVolume.value;
    hitsoundVolumePlayer = save.chartEditorHitsoundVolumePlayer.value;
    hitsoundVolumeOpponent = save.chartEditorHitsoundVolumeOpponent.value;
    shouldPlayWelcomeMusic = save.chartEditorThemeMusic.value;

    preferencesVolumeInstrumental.value = Std.int(save.chartEditorInstVolume.value * 100);
    preferencesVolumeVocalsPlayer.value = Std.int(save.chartEditorPlayerVoiceVolume.value * 100);
    preferencesVolumeVocalsOpponent.value = Std.int(save.chartEditorOpponentVoiceVolume.value * 100);
    menubarItemPlaybackSpeed.value = Math.round(save.chartEditorPlaybackSpeed.value * 100.0);
  }

  /**
   * Write the Chart Editor preferences to the save file.
   *
   * @param hasBackup Whether there is a
   */
  public function writePreferences(hasBackup:Bool):Void
  {
    var save:Save = Save.instance;

    // Can't use filter() because of null safety checking!
    var filteredWorkingFilePaths:Array<String> = [];
    for (chartPath in previousWorkingFilePaths) if (chartPath != null) filteredWorkingFilePaths.pushUnique(chartPath);
    save.chartEditorPreviousFiles.value = filteredWorkingFilePaths;

    if (hasBackup) trace('Queuing backup prompt for next time!');
    save.chartEditorHasBackup.value = hasBackup;

    save.chartEditorNoteQuant.value = noteSnapQuantIndex;
    save.chartEditorZoomLevel.value = zoomLevelIndex;
    save.chartEditorLiveInputStyle.value = currentLiveInputStyle;
    save.chartEditorWaveformPos.value = currentWaveformPos;
    save.chartEditorShowInstrumentalWaveform.value = showInstrumentalWaveform;
    save.chartEditorWaveformFilter.value = waveformFilter;
    save.chartEditorWaveformFilterStrength.value = waveformFilterStrength;
    save.chartEditorDownscroll.value = isViewDownscroll;
    save.chartEditorShowNoteKinds.value = showNoteKindIndicators;
    save.chartEditorShowDifficultyHeatmap.value = showDifficultyHeatmap;
    save.chartEditorShowBeatLines.value = showBeatLines;
    save.chartEditorShowCursorLine.value = showCursorLine;
    save.chartEditorConstantScroll.value = constantScrollEnabled;
    save.chartEditorConstantScrollSpeed.value = constantScrollSpeed;
    save.chartEditorUIScale.value = uiScale;
    save.chartEditorGridBackingAlpha.value = gridBackingAlpha;
    save.chartEditorPlaytestStartTime.value = playtestStartTime;
    save.chartEditorPlaytestAudioSettings.value = playtestAudioSettings;
    save.chartEditorPlaytestResultsSettings.value = playtestShowResults;
    save.chartEditorPlaytestPracticeMode.value = playtestPracticeMode;
    save.chartEditorPlaytestBotPlayMode.value = playtestBotPlayMode;
    save.chartEditorPlaytestSongScripts.value = playtestSongScripts;
    save.chartEditorStackedNoteThreshold.value = stackedNoteThreshold;
    save.chartEditorShowSubtitles.value = showSubtitles;
    save.chartEditorTheme.value = currentTheme;
    save.chartEditorMetronomeVolume.value = metronomeVolume;
    save.chartEditorHitsoundVolumePlayer.value = hitsoundVolumePlayer;
    save.chartEditorHitsoundVolumeOpponent.value = hitsoundVolumeOpponent;
    save.chartEditorThemeMusic.value = shouldPlayWelcomeMusic;

    save.chartEditorInstVolume.value = preferencesVolumeInstrumental.value / 100.0;
    save.chartEditorPlayerVoiceVolume.value = preferencesVolumeVocalsPlayer.value / 100.0;
    save.chartEditorOpponentVoiceVolume.value = preferencesVolumeVocalsOpponent.value / 100.0;
    save.chartEditorPlaybackSpeed.value = menubarItemPlaybackSpeed.value / 100.0;
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
      menuItemRecentChart.onClick = function(_event)
      {
        try
        {
          this.loadSongFromFNFCPath(chartPath);
        }
        catch (e)
        {
          this.error('Failure', 'Failed to load chart (${chartPath.toString()}): $e');
        }
      };

      if (!FileUtil.fileExists(chartPath))
      {
        trace('Previously loaded chart file (${chartPath.toString()}) does not exist, disabling link...');
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

  var bgMusicTimer:FlxTimer;

  function fadeInWelcomeMusic(?extraWait:Float = 0, ?fadeInTime:Float = 5):Void
  {
    if (!shouldPlayWelcomeMusic)
    {
      stopWelcomeMusic();
      return;
    }

    if ((audioInstTrack != null && audioInstTrack.isPlaying) || audioVocalTrackGroup.playing) return;

    if (welcomeMusic.isPlaying) return;

    if (!welcomeMusic.exists) setupWelcomeMusic();

    if (bgMusicTimer != null) bgMusicTimer.cancel();
    bgMusicTimer = new FlxTimer().start(extraWait, (_) ->
    {
      if (shouldPlayWelcomeMusic)
      {
        this.welcomeMusic.play();
        this.welcomeMusic.fadeIn(fadeInTime, 0, 1.0);
      }
      // Cleanup.
      if (bgMusicTimer != null)
      {
        bgMusicTimer.cancel();
        bgMusicTimer = null;
      }
    });
  }

  function stopWelcomeMusic():Void
  {
    if (bgMusicTimer != null)
    {
      bgMusicTimer.cancel();
      bgMusicTimer = null;
    }
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
    relayoutDialogs();

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

    if (notePreview != null) notePreview.x = notePreviewXPos();
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
    waveformsDirty = true;
  }

  /**
   * The note preview keeps the same gap to the grid that it has at 1280x720.
   */
  static function notePreviewXPos():Float
  {
    return GRID_X_POS - (FlxG.initialWidth / 2 - GRID_SIZE * STRUMLINE_SIZE - NOTE_PREVIEW_X_POS);
  }

  /**
   * The game size the dialogs were last placed for.
   */
  var dialogLayoutSize:FlxPoint = FlxPoint.get(FlxG.initialWidth, FlxG.initialHeight);

  /**
   * Keep toolboxes and dialogs at the same place relative to the screen when its size changes, and fully on it.
   */
  function relayoutDialogs():Void
  {
    var ratioX:Float = FlxG.width / dialogLayoutSize.x;
    var ratioY:Float = FlxG.height / dialogLayoutSize.y;
    dialogLayoutSize.set(FlxG.width, FlxG.height);
    if (ratioX == 1 && ratioY == 1) return;

    this.repositionNotifications();

    var dialogs:Array<Dialog> = [for (toolbox in activeToolboxes) toolbox];
    for (component in Screen.instance.rootComponents)
    {
      if (component is Dialog && !dialogs.contains(cast component)) dialogs.push(cast component);
    }

    for (dialog in dialogs)
    {
      // Scale the dialog's center, so it stays in the same part of the screen.
      var centerX:Float = (dialog.left + dialog.width / 2) * ratioX;
      var centerY:Float = (dialog.top + dialog.height / 2) * ratioY;
      var maxLeft:Float = Math.max(0, FlxG.width - dialog.width);
      var maxTop:Float = Math.max(MENU_BAR_HEIGHT, FlxG.height - dialog.height);
      dialog.left = FlxMath.bound(centerX - dialog.width / 2, 0, maxLeft);
      dialog.top = FlxMath.bound(centerY - dialog.height / 2, MENU_BAR_HEIGHT, maxTop);
    }
  }

  function buildBackground():Void
  {
    menuBG = new FlxSprite().loadGraphic(Paths.image('ui/main-menu/menu-desat').toFlxGraphicAsset());
    add(menuBG);

    menuBG.setGraphicSize(Std.int(FlxG.width * 1.1));
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

    gridTiledSprite = new FlxSprite().makeGraphic(1, 1, FlxColor.TRANSPARENT);
    gridTiledSprite.width = GRID_SIZE * ChartEditorThemeHandler.TOTAL_COLUMN_COUNT;
    gridTiledSprite.height = 1000;
    gridTiledSprite.visible = false;
    gridTiledSprite.x = GRID_X_POS; // Center the grid.
    gridTiledSprite.y = GRID_INITIAL_Y_POS; // Push down to account for the menu bar.
    add(gridTiledSprite);
    gridTiledSprite.zIndex = 10;

    gridLines = new ChartEditorGridLines(this);
    gridLines.backing.zIndex = 10;
    add(gridLines.backing);

    gridLines.lines.zIndex = 16;
    add(gridLines.lines);
    gridLines.dividers.zIndex = 16;
    add(gridLines.dividers);
    gridLines.markers.zIndex = 30;
    add(gridLines.markers);

    rangeSelectionSprite = new FlxSprite().makeGraphic(1, 1, RANGE_SELECTION_COLOR);
    rangeSelectionSprite.visible = false;
    rangeSelectionSprite.zIndex = 18;
    add(rangeSelectionSprite);

    gridCursorLine = new FunkinSprite().makeSolidColor(GRID_SIZE * ChartEditorThemeHandler.TOTAL_COLUMN_COUNT, 2, CURSOR_LINE_COLOR);
    gridCursorLine.visible = false;
    gridCursorLine.zIndex = 17;
    add(gridCursorLine);

    gridGhostNote = new ChartEditorNoteSprite(this, true);
    gridGhostNote.alpha = 0.6;
    gridGhostNote.noteData = new SongNoteData(0, 0, 0, '', []);
    gridGhostNote.visible = false;
    add(gridGhostNote);
    gridGhostNote.zIndex = 21;

    gridGhostHoldNote = new ChartEditorHoldNoteSprite(this);
    gridGhostHoldNote.alpha = 0.6;
    gridGhostHoldNote.noteData = null;
    gridGhostHoldNote.visible = false;
    add(gridGhostHoldNote);
    gridGhostHoldNote.zIndex = 21;

    gridGhostEvent = new ChartEditorEventSprite(this, true);
    gridGhostEvent.alpha = 0.6;
    gridGhostEvent.eventData = new SongEventData(-1, '', {
    });
    gridGhostEvent.visible = false;
    add(gridGhostEvent);
    gridGhostEvent.zIndex = 22;

    buildNoteGroup();

    add(renderedPins);
    renderedPins.zIndex = 50;

    // The playhead that show the current position in the song.
    add(gridPlayhead);
    gridPlayhead.zIndex = 30;

    var playheadWidth:Int = GRID_SIZE * (STRUMLINE_SIZE * 2 + 1) + PLAYHEAD_SCROLL_AREA_WIDTH;
    var playheadBaseYPos:Float = GRID_INITIAL_Y_POS;
    gridPlayhead.setPosition(GRID_X_POS, playheadBaseYPos);
    var playheadSprite:FunkinSprite = new FunkinSprite().makeSolidColor(playheadWidth, PLAYHEAD_HEIGHT, PLAYHEAD_COLOR);
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

    // 15 is above the grid, but below most stuff that's on the grid.
    audioWaveforms.zIndex = 15;
    add(audioWaveforms);
  }

  function createSubtitles():Void
  {
    subtitles = new Subtitles(0, 78);
    subtitles.zIndex = 100;
    subtitles.cameras = [uiCamera];
    add(subtitles);
  }

  function buildMeasureTicks():Void
  {
    measureTicks = new ChartEditorMeasureTicks(this);
    var measureTicksWidth = GRID_SIZE;
    measureTicks.x = gridTiledSprite.x - measureTicksWidth;
    measureTicks.zIndex = 20;
    add(measureTicks);

    handleMeasureTickPosition();
  }

  function buildNotePreview():Void
  {
    var playbarHeightWithPad = PLAYBAR_HEIGHT + 10;
    var notePreviewHeight:Int = FlxG.height - NOTE_PREVIEW_Y_POS - playbarHeightWithPad;
    notePreview = new ChartEditorNotePreview(notePreviewHeight);
    notePreview.x = notePreviewXPos();
    notePreview.y = NOTE_PREVIEW_Y_POS;
    add(notePreview);

    difficultyHeatmap = new ChartEditorDifficultyHeatmap(this);
    difficultyHeatmap.zIndex = 19;
    difficultyHeatmap.visible = showDifficultyHeatmap;
    add(difficultyHeatmap);

    if (notePreviewViewport == null) throw 'ERROR: Tried to build note preview, but notePreviewViewport is null! Check ChartEditorThemeHandler.updateTheme().';

    notePreviewViewport.scrollFactor.set(0, 0);
    add(notePreviewViewport);
    notePreviewViewport.zIndex = 30;

    notePreviewPlayhead = new FlxSprite().makeGraphic(2, 2, 0xFFFF0000);
    notePreviewPlayhead.scrollFactor.set(0, 0);
    notePreviewPlayhead.scale.set(notePreview.width / 2, 0.5); // Setting width does nothing.
    notePreviewPlayhead.updateHitbox();
    notePreviewPlayhead.x = notePreview.x;
    notePreviewPlayhead.y = notePreview.y;
    add(notePreviewPlayhead);
    notePreviewPlayhead.zIndex = 31;

    setNotePreviewViewportBounds(calculateNotePreviewViewportBounds());
  }

  function setSelectionBoxBounds(?bounds:FlxRect):Void
  {
    if (selectionBoxSprite == null) throw 'ERROR: Tried to set selection box bounds, but selectionBoxSprite is null! Check ChartEditorThemeHandler.updateTheme().';

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

  /**
   * Automatically goes through and calls render on everything you added.
   */
  override public function draw():Void
  {
    if (criticalFailure) return;

    super.draw();
  }

  function calculateNotePreviewViewportBounds():FlxRect
  {
    var bounds:FlxRect = FlxRect.weak();

    // Return 0, 0, 0, 0 if the note preview doesn't exist for some reason.
    if (notePreview == null) return bounds;

    // Horizontal position and width are constant.
    bounds.x = notePreview.x;
    bounds.width = notePreview.width;

    var viewTopPixels:Float = scrollPositionInPixels - GRID_TOP_PAD;
    var viewHeightPixels:Float = FlxG.height - MENU_BAR_HEIGHT - PLAYBAR_HEIGHT;
    bounds.y = notePreview.y + (notePreview.height * (viewTopPixels / songLengthInPixels));
    bounds.height = notePreview.height * (viewHeightPixels / songLengthInPixels);

    var MIN_HEIGHT:Int = 8;
    if (bounds.height < MIN_HEIGHT)
    {
      bounds.y -= (MIN_HEIGHT - bounds.height) / 2;
      bounds.height = MIN_HEIGHT;
    }

    // Make sure the viewport doesn't go off the top or bottom of the note preview.
    if (bounds.y < notePreview.y)
    {
      bounds.height -= notePreview.y - bounds.y;
      bounds.y = notePreview.y;
    }
    if (bounds.y + bounds.height > notePreview.y + notePreview.height)
    {
      bounds.height -= (bounds.y + bounds.height) - (notePreview.y + notePreview.height);
    }
    if (bounds.height < 1) bounds.height = 1;

    // trace('Note preview viewport bounds: ' + bounds.toString());

    return bounds;
  }

  function setNotePreviewViewportBounds(?bounds:FlxRect):Void
  {
    if (notePreviewViewport == null)
    {
      trace(' WARNING '.warning() + ' Tried to set note preview viewport bounds, but notePreviewViewport is null!');
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

  function refreshNotePreviewPlayheadPosition():Void
  {
    if (notePreviewPlayhead == null) return;

    notePreviewPlayhead.y = notePreview.y + (notePreview.height * ((scrollPositionInPixels + playheadPositionInPixels) / songLengthInPixels));
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
    playbarHeadLayout = new ChartEditorPlaybarHead();

    playbarHeadLayout.zIndex = 110;
    playbarHeadLayout.width = FlxG.width;
    playbarHeadLayout.height = 10;
    playbarHeadLayout.x = 0;
    playbarHeadLayout.y = FlxG.height - 48 - 8;

    playbarHeadLayout.playbarHead.allowFocus = false;
    playbarHeadLayout.playbarHead.width = FlxG.width;
    playbarHeadLayout.playbarHead.height = 10;
    playbarHeadLayout.playbarHead.styleString = 'padding-left: 0px; padding-right: 0px; border-left: 0px; border-right: 0px;';
    playbarHeadLayout.playbarHead.findComponent('range').styleString = 'padding-left: 4px; padding-right: 0px;';
    playbarHeadLayout.playbarHead.min = 0;

    playbarHeadLayout.playbarHead.onDragStart = function(_:DragEvent)
    {
      playbarHeadDragging = true;

      if ((audioInstTrack != null && audioInstTrack.isPlaying) || audioVocalTrackGroup.playing)
      {
        playbarHeadDraggingWasPlaying = true;
        stopAudioPlayback();
      }
      else
      {
        playbarHeadDraggingWasPlaying = false;
      }
    }

    playbarHeadLayout.playbarHead.onDrag = function(d:DragEvent)
    {
      if (playbarHeadDragging)
      {
        // Update the conductor and audio tracks to match.
        currentScrollEase = d.value;
        easeSongToScrollPosition(currentScrollEase);
      }
    }

    playbarHeadLayout.playbarHead.onDragEnd = function(_:DragEvent)
    {
      playbarHeadDragging = false;

      // If we were dragging the playhead while the song was playing, resume playing.
      if (playbarHeadDraggingWasPlaying)
      {
        playbarHeadDraggingWasPlaying = false;

        // Disabled code to resume song playback on drag.
        startAudioPlayback();
      }
    }

    add(playbarHeadLayout);

    buildCommentPanel();

    // Little text that shows up when you copy something.
    txtCopyNotif = new haxe.ui.backend.flixel.HiResFlxText(0, 0, 0, '', 24);
    txtCopyNotif.setBorderStyle(OUTLINE, 0xFF074809, 1);
    txtCopyNotif.color = 0xFF52FF77;
    txtCopyNotif.zIndex = 120;
    add(txtCopyNotif);

    this.setupNotifications();

    // Setup character dropdowns.
    FlxMouseEvent.add(healthIconDad, function(_)
    {
      if (!isCursorOverHaxeUI && !isPlaytesting)
      {
        if (FlxG.keys.pressed.SHIFT) return;
        if (pressingControl())
        {
          this.setToolboxState(CHART_EDITOR_TOOLBOX_OPPONENT_PREVIEW_LAYOUT, true);
        }
        else
        {
          this.openCharacterDropdown(CharacterType.DAD, true);
        }
      }
    }, false, true, false);

    FlxMouseEvent.add(healthIconBF, function(_)
    {
      if (!isCursorOverHaxeUI && !isPlaytesting)
      {
        if (FlxG.keys.pressed.SHIFT) return;
        if (pressingControl())
        {
          this.setToolboxState(CHART_EDITOR_TOOLBOX_PLAYER_PREVIEW_LAYOUT, true);
        }
        else
        {
          this.openCharacterDropdown(CharacterType.BF, true);
        }
      }
    }, false, true, false);

    buttonSelectOpponent = new Button();
    buttonSelectOpponent.allowFocus = false;
    buttonSelectOpponent.text = 'Opponent'; // Default text.
    buttonSelectOpponent.x = GRID_X_POS;
    buttonSelectOpponent.y = NOTE_SELECT_BUTTON_Y;
    buttonSelectOpponent.width = GRID_SIZE * 4;
    buttonSelectOpponent.height = NOTE_SELECT_BUTTON_HEIGHT;
    buttonSelectOpponent.tooltip = 'Click to set selection to all notes on this side.\nShift-click to add all notes on this side to selection.';
    buttonSelectOpponent.zIndex = 110;
    add(buttonSelectOpponent);

    buttonSelectOpponent.onClick = (_) ->
    {
      var notesToSelect:Array<SongNoteData> = currentSongChartNoteData;
      notesToSelect = SongDataUtils.getNotesInDataRange(notesToSelect, STRUMLINE_SIZE, STRUMLINE_SIZE * 2 - 1);
      if (FlxG.keys.pressed.SHIFT)
      {
        performCommand(new SelectItemsCommand(notesToSelect, []));
      }
      else
      {
        performCommand(new SetItemSelectionCommand(notesToSelect, []));
      }
    }

    buttonSelectPlayer = new Button();
    buttonSelectPlayer.allowFocus = false;
    buttonSelectPlayer.text = 'Player'; // Default text.
    buttonSelectPlayer.x = buttonSelectOpponent.x + buttonSelectOpponent.width;
    buttonSelectPlayer.y = buttonSelectOpponent.y;
    buttonSelectPlayer.width = GRID_SIZE * 4;
    buttonSelectPlayer.height = NOTE_SELECT_BUTTON_HEIGHT;
    buttonSelectPlayer.tooltip = 'Click to set selection to all notes on this side.\nShift-click to add all notes on this side to selection.';
    buttonSelectPlayer.zIndex = 110;
    add(buttonSelectPlayer);

    buttonSelectPlayer.onClick = (_) ->
    {
      var notesToSelect:Array<SongNoteData> = currentSongChartNoteData;
      notesToSelect = SongDataUtils.getNotesInDataRange(notesToSelect, 0, STRUMLINE_SIZE - 1);
      if (FlxG.keys.pressed.SHIFT)
      {
        performCommand(new SelectItemsCommand(notesToSelect, []));
      }
      else
      {
        performCommand(new SetItemSelectionCommand(notesToSelect, []));
      }
    }

    buttonSelectEvent = new Button();
    buttonSelectEvent.allowFocus = false;
    buttonSelectEvent.icon = Paths.image('ui/editors/chart-editor/events/Default').toFlxGraphicAsset();
    buttonSelectEvent.iconPosition = 'top';
    buttonSelectEvent.x = buttonSelectPlayer.x + buttonSelectPlayer.width;
    buttonSelectEvent.y = buttonSelectPlayer.y;
    buttonSelectEvent.width = GRID_SIZE;
    buttonSelectEvent.height = NOTE_SELECT_BUTTON_HEIGHT;
    buttonSelectEvent.tooltip = 'Click to set selection to all events.\nShift-click to add all events to selection.';
    buttonSelectEvent.zIndex = 110;
    add(buttonSelectEvent);

    buttonSelectEvent.onClick = (_) ->
    {
      if (FlxG.keys.pressed.SHIFT)
      {
        performCommand(new SelectItemsCommand([], currentSongChartEventData));
      }
      else
      {
        performCommand(new SetItemSelectionCommand([], currentSongChartEventData));
      }
    }

    buttonSelectDummy = new Button();
    buttonSelectDummy.allowFocus = false;
    buttonSelectDummy.x = buttonSelectOpponent.x - GRID_SIZE;
    buttonSelectDummy.y = buttonSelectEvent.y;
    buttonSelectDummy.width = GRID_SIZE;
    buttonSelectDummy.height = NOTE_SELECT_BUTTON_HEIGHT;
    buttonSelectDummy.zIndex = 110;
    add(buttonSelectDummy);
  }

  /**
   * Sets up the onClick listeners for the UI.
   */
  function setupUIListeners():Void
  {
    // Add functionality to the playbar.

    playbarStart.onClick = _ -> playbarButtonPressed = 'playbarStart';
    playbarBack.onClick = _ -> playbarButtonPressed = 'playbarBack';
    playbarPlay.onClick = _ -> toggleAudioPlayback();
    playbarForward.onClick = _ -> playbarButtonPressed = 'playbarForward';
    playbarEnd.onClick = _ -> playbarButtonPressed = 'playbarEnd';

    // Cycle note snap quant.
    playbarNoteSnap.onRightClick = _ ->
    {
      noteSnapQuantIndex--;
      if (noteSnapQuantIndex < 0) noteSnapQuantIndex = SNAP_QUANTS.length - 1;
    };
    playbarNoteSnap.onClick = _ ->
    {
      if (FlxG.keys.pressed.SHIFT)
      {
        noteSnapQuantIndex = BASE_QUANT_INDEX;
      }
      else
      {
        noteSnapQuantIndex++;
        if (noteSnapQuantIndex >= SNAP_QUANTS.length) noteSnapQuantIndex = 0;
      }
    };

    playbarZoom.onClick = _ ->
    {
      if (FlxG.keys.pressed.SHIFT) zoomLevelIndex = BASE_ZOOM_INDEX;
      else
        zoomLevelIndex++;
    };
    playbarZoom.onRightClick = _ -> zoomLevelIndex--;

    playbarBPM.onClick = _ ->
    {
      if (pressingControl())
      {
        this.setToolboxState(CHART_EDITOR_TOOLBOX_METADATA_LAYOUT, true);
      }
      else
      {
        Conductor.instance.currentTimeChange.bpm += 1;
        this.refreshToolbox(CHART_EDITOR_TOOLBOX_METADATA_LAYOUT);
      }
    }

    playbarBPM.onRightClick = _ ->
    {
      Conductor.instance.currentTimeChange.bpm -= 1;
      this.refreshToolbox(CHART_EDITOR_TOOLBOX_METADATA_LAYOUT);
    }

    playbarDifficulty.onClick = _ ->
    {
      if (pressingControl())
      {
        this.setToolboxState(CHART_EDITOR_TOOLBOX_DIFFICULTY_LAYOUT, true);
      }
      else
      {
        incrementDifficulty(-1);
        this.refreshToolbox(CHART_EDITOR_TOOLBOX_DIFFICULTY_LAYOUT);
      }
    }

    playbarDifficulty.onRightClick = _ ->
    {
      incrementDifficulty(1);
      this.refreshToolbox(CHART_EDITOR_TOOLBOX_DIFFICULTY_LAYOUT);
    }

    // Add functionality to the menu items.

    // File
    menubarItemNewChart.onClick = _ -> this.openWelcomeDialog(true);
    menubarItemOpenChart.onClick = _ -> this.openBrowseFNFC(true);
    menubarItemSaveChart.onClick = _ ->
    {
      if (currentWorkingFilePath != null)
      {
        this.exportCurrentChartToFNFC(true, currentWorkingFilePath);
        this.success('Saved Chart', 'Chart saved successfully to ${currentWorkingFilePath}.');
      }
      else
      {
        this.exportCurrentChartToFNFC(false, null, function(path:String)
        {
          // CTRL + SHIFT + S Successful
          this.success('Saved Chart', 'Chart saved successfully to ${path}.');
        }, function()
        {
          // CTRL + SHIFT + S Cancelled
        });
      }
    };
    menubarItemSaveChartAs.onClick = _ -> this.exportCurrentChartToFNFC(false, null, (path:String) ->
    {
      // CTRL + SHIFT + S Successful
      this.success('Saved Chart', 'Chart saved successfully to ${path}.');
    }, () -> {
        // CTRL + SHIFT + S Cancelled
    });
    menubarItemExportChartAsFolder.onClick = _ -> this.exportCurrentChartToFolder(null, (path:String) ->
    {
      this.success('Exported Chart', 'Chart exported successfully to ${path}.');
    }, () -> {
        // Cancelled
    });
    menubarItemExit.onClick = _ -> quitChartEditor(true);

    // Edit
    menubarItemUndo.onClick = _ -> undoLastCommand();
    menubarItemRedo.onClick = _ -> redoLastCommand();
    menubarItemCopy.onClick = function(_)
    {
      copySelection();
    };
    menubarItemCut.onClick = _ -> performCommand(new CutItemsCommand(currentNoteSelection, currentEventSelection));

    menubarItemPaste.onClick = _ ->
    {
      var targetMs:Float = scrollPositionInMs + playheadPositionInMs;
      var targetStep:Float = Conductor.instance.getTimeInSteps(targetMs);
      var targetSnappedStep:Float = Math.floor(targetStep / noteSnapRatio) * noteSnapRatio;
      var targetSnappedMs:Float = Conductor.instance.getStepTimeInMs(targetSnappedStep);
      performCommand(new PasteItemsCommand(targetSnappedMs));
    };

    menubarItemPasteUnsnapped.onClick = _ ->
    {
      var targetMs:Float = scrollPositionInMs + playheadPositionInMs;
      performCommand(new PasteItemsCommand(targetMs));
    };

    menubarItemDelete.onClick = _ ->
    {
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
    };

    menubarItemDeleteStacked.onClick = _ ->
    {
      if (currentEventSelection.length > 0 && currentNoteSelection.length == 0)
      {
        performCommand(new RemoveEventsCommand(currentEventSelection));
      }
      else
      {
        performCommand(new RemoveStackedNotesCommand(currentNoteSelection.length > 0 ? currentNoteSelection : null));
      }
    };

    menubarItemFlipNotes.onClick = _ -> performCommand(new FlipNotesCommand(currentNoteSelection));

    menubarItemMirrorX.onClick = _ -> performCommand(
      new MirrorNotesCommand(currentNoteSelection, menubarItemMirrorFlipWithinStrumline.selected, !menubarItemMirrorFlipWithinStrumline.selected, true, false)
    );

    menubarItemMirrorY.onClick = _ -> performCommand(
      new MirrorNotesCommand(currentNoteSelection, menubarItemMirrorFlipWithinStrumline.selected, !menubarItemMirrorFlipWithinStrumline.selected, false, true)
    );

    menubarItemMirrorXY.onClick = _ -> performCommand(
      new MirrorNotesCommand(currentNoteSelection, menubarItemMirrorFlipWithinStrumline.selected, !menubarItemMirrorFlipWithinStrumline.selected, true, true)
    );

    menubarItemSelectAllNotes.onClick = _ -> performCommand(new SelectAllItemsCommand(true, false));

    menubarItemSelectAllEvents.onClick = _ -> performCommand(new SelectAllItemsCommand(false, true));

    menubarItemSelectInverse.onClick = _ -> performCommand(new InvertSelectedItemsCommand());

    menubarItemSelectNone.onClick = _ -> performCommand(new DeselectAllItemsCommand());

    menubarItemSelectBeforePlayhead.onClick = _ -> performCommand(
      new SelectAllItemsBetweenTimeCommand(scrollPositionInMs + playheadPositionInMs, true, true, true)
    );

    menubarItemSelectAfterPlayhead.onClick = _ -> performCommand(
      new SelectAllItemsBetweenTimeCommand(scrollPositionInMs + playheadPositionInMs, false, true, true)
    );

    menubarItemPlaytestFull.onClick = _ -> testSongInPlayState(false);
    menubarItemPlaytestMinimal.onClick = _ -> testSongInPlayState(true);

    menuBarItemNoteSnapDecrease.onClick = _ ->
    {
      noteSnapQuantIndex--;
      if (noteSnapQuantIndex < 0) noteSnapQuantIndex = SNAP_QUANTS.length - 1;
    };
    menuBarItemNoteSnapIncrease.onClick = _ ->
    {
      noteSnapQuantIndex++;
      if (noteSnapQuantIndex >= SNAP_QUANTS.length) noteSnapQuantIndex = 0;
    };

    menubarItemPreferences.onClick = _ -> this.setToolboxState(CHART_EDITOR_TOOLBOX_PREFERENCES_LAYOUT, true);

    menubarItemAbout.onClick = _ -> this.openAboutDialog();
    menubarItemWelcomeDialog.onClick = _ -> this.openWelcomeDialog(true);

    #if sys
    menubarItemGoToBackupsFolder.onClick = _ -> this.openBackupsFolder();
    #else
    // Disable the menu item if we're not on a native platform.
    menubarItemGoToBackupsFolder.disabled = true;
    #end

    menubarItemUserGuide.onClick = _ -> this.openUserGuideDialog();

    menubarItemDownscroll.onClick = event -> isViewDownscroll = event.value;
    menubarItemDownscroll.selected = isViewDownscroll;

    menubarItemZoomIn.onClick = _ -> zoomLevelIndex++;
    menubarItemZoomOut.onClick = _ -> zoomLevelIndex--;
    menubarItemZoomReset.onClick = _ -> zoomLevelIndex = BASE_ZOOM_INDEX;

    menubarItemViewWaveforms.onClick = event -> audioWaveforms.visible = menubarItemViewWaveforms.selected;
    menubarItemViewDifficultyHeatmap.onClick = event -> showDifficultyHeatmap = menubarItemViewDifficultyHeatmap.selected;
    menubarItemViewDifficultyHeatmap.selected = showDifficultyHeatmap;
    menubarItemViewWaveforms.selected = audioWaveforms.visible;

    menubarItemCommandPalette.onClick = _ -> ChartEditorCommandPalette.openPalette(this, '?');
    menubarItemDifficultyUp.onClick = _ -> incrementDifficulty(1);
    menubarItemDifficultyDown.onClick = _ -> incrementDifficulty(-1);

    menubarItemPlayPause.onClick = _ -> toggleAudioPlayback();

    menubarItemMutePlayerVocals.onChange = _ -> playerVocalsMuted = menubarItemMutePlayerVocals.selected;
    menubarItemMutePlayerVocals.selected = playerVocalsMuted;

    menubarItemMuteOpponentVocals.onChange = _ -> opponentVocalsMuted = menubarItemMuteOpponentVocals.selected;
    menubarItemMuteOpponentVocals.selected = opponentVocalsMuted;

    menubarItemMuteInstrumental.onChange = _ -> instrumentalMuted = menubarItemMuteInstrumental.selected;
    menubarItemMuteInstrumental.selected = instrumentalMuted;

    menubarItemMuteMetronome.onChange = _ -> metronomeMuted = menubarItemMuteMetronome.selected;
    menubarItemMuteMetronome.selected = metronomeMuted;

    menubarItemMuteHitsounds.onChange = _ -> hitsoundsMuted = menubarItemMuteHitsounds.selected;
    menubarItemMuteHitsounds.selected = hitsoundsMuted;

    menubarItemLoadInstrumental.onClick = _ ->
    {
      var dialog = this.openUploadInstDialog(true);
      // Ensure instrumental and vocals are reloaded properly.
      dialog.onDialogClosed = function(_)
      {
        this.isHaxeUIDialogOpen = false;
        this.switchToCurrentInstrumental();
        this.postLoadInstrumental();
      }
    };

    menubarItemLoadVocals.onClick = _ ->
    {
      var dialog = this.openUploadVocalsDialog(true);
      // Ensure instrumental and vocals are reloaded properly.
      dialog.onDialogClosed = function(_)
      {
        this.isHaxeUIDialogOpen = false;
        this.switchToCurrentInstrumental();
        this.postLoadInstrumental();
      }
    };

    preferencesVolumeMetronome.onChange = event ->
    {
      var volume:Float = event.value.toFloat() / 100.0;
      metronomeVolume = volume;
      preferencesLabelVolumeMetronome.text = 'Metronome - ${Math.round(event.value)}%';
    };
    preferencesVolumeMetronome.onRightClick = _ ->
    {
      if (metronomeVolume <= 0.0)
      {
        metronomeVolume = 1.0;
        preferencesVolumeMetronome.value = 100.0;
        preferencesLabelVolumeMetronome.text = 'Metronome - 100%';
      }
      else
      {
        metronomeVolume = 0.0;
        preferencesVolumeMetronome.value = 0.0;
        preferencesLabelVolumeMetronome.text = 'Metronome - 0%';
      }
    }
    preferencesVolumeMetronome.value = Std.int(metronomeVolume * 100);
    previousAudioVolumes[0] = Std.int(metronomeVolume * 100);

    preferencesVolumeHitsoundPlayer.onChange = event ->
    {
      var volume:Float = event.value.toFloat() / 100.0;
      hitsoundVolumePlayer = volume;
      preferencesLabelVolumeHitsoundPlayer.text = 'Player - ${Math.round(event.value)}%';
    };
    preferencesVolumeHitsoundPlayer.onRightClick = _ ->
    {
      if (hitsoundVolumePlayer <= 0.0)
      {
        hitsoundVolumePlayer = 1.0;
        preferencesVolumeHitsoundPlayer.value = 100.0;
        preferencesLabelVolumeHitsoundPlayer.text = 'Player - 100%';
      }
      else
      {
        hitsoundVolumePlayer = 0.0;
        preferencesVolumeHitsoundPlayer.value = 0.0;
        preferencesLabelVolumeHitsoundPlayer.text = 'Player - 0%';
      }
    }
    preferencesVolumeHitsoundPlayer.value = Std.int(hitsoundVolumePlayer * 100);
    previousAudioVolumes[1] = Std.int(hitsoundVolumePlayer * 100);

    preferencesVolumeHitsoundOpponent.onChange = event ->
    {
      var volume:Float = event.value.toFloat() / 100.0;
      hitsoundVolumeOpponent = volume;
      preferencesLabelVolumeHitsoundOpponent.text = 'Opponent - ${Math.round(event.value)}%';
    };
    preferencesVolumeHitsoundOpponent.onRightClick = _ ->
    {
      if (hitsoundVolumeOpponent <= 0.0)
      {
        hitsoundVolumeOpponent = 1.0;
        preferencesVolumeHitsoundOpponent.value = 100.0;
        preferencesLabelVolumeHitsoundOpponent.text = 'Opponent - 100%';
      }
      else
      {
        hitsoundVolumeOpponent = 0.0;
        preferencesVolumeHitsoundOpponent.value = 0.0;
        preferencesLabelVolumeHitsoundOpponent.text = 'Opponent - 0%';
      }
    }
    preferencesVolumeHitsoundOpponent.value = Std.int(hitsoundVolumeOpponent * 100);
    previousAudioVolumes[2] = Std.int(hitsoundVolumeOpponent * 100);

    preferencesVolumeInstrumental.onChange = event ->
    {
      var volume:Float = event.value.toFloat() / 100.0;
      if (audioInstTrack != null) audioInstTrack.volume = volume;
      preferencesLabelVolumeInstrumental.text = 'Instrumental - ${Math.round(event.value)}%';
    };
    preferencesVolumeInstrumental.onRightClick = _ ->
    {
      if (preferencesVolumeInstrumental.value <= 0.0)
      {
        if (audioInstTrack != null) audioInstTrack.volume = 1.0;
        preferencesVolumeInstrumental.value = 100.0;
        preferencesLabelVolumeInstrumental.text = 'Instrumental - 100%';
      }
      else
      {
        if (audioInstTrack != null) audioInstTrack.volume = 0.0;
        preferencesVolumeInstrumental.value = 0.0;
        preferencesLabelVolumeInstrumental.text = 'Instrumental - 0%';
      }
    }
    previousAudioVolumes[3] = preferencesVolumeInstrumental.value;

    preferencesVolumeVocalsPlayer.onChange = event ->
    {
      var volume:Float = event.value.toFloat() / 100.0;
      audioVocalTrackGroup.playerVolume = volume;
      preferencesLabelVolumeVocalsPlayer.text = 'Player - ${Math.round(event.value)}%';
    };
    preferencesVolumeVocalsPlayer.onRightClick = _ ->
    {
      if (audioVocalTrackGroup.playerVolume <= 0.0)
      {
        audioVocalTrackGroup.playerVolume = 1.0;
        preferencesVolumeVocalsPlayer.value = 100.0;
        preferencesLabelVolumeVocalsPlayer.text = 'Player - 100%';
      }
      else
      {
        audioVocalTrackGroup.playerVolume = 0.0;
        preferencesVolumeVocalsPlayer.value = 0.0;
        preferencesLabelVolumeVocalsPlayer.text = 'Player - 0%';
      }
    }
    previousAudioVolumes[4] = preferencesVolumeVocalsPlayer.value;

    preferencesVolumeVocalsOpponent.onChange = event ->
    {
      var volume:Float = event.value.toFloat() / 100.0;
      audioVocalTrackGroup.opponentVolume = volume;
      preferencesLabelVolumeVocalsOpponent.text = 'Opponent - ${Math.round(event.value)}%';
    };
    preferencesVolumeVocalsOpponent.onRightClick = _ ->
    {
      if (audioVocalTrackGroup.opponentVolume <= 0.0)
      {
        audioVocalTrackGroup.opponentVolume = 1.0;
        preferencesVolumeVocalsOpponent.value = 100.0;
        preferencesLabelVolumeVocalsOpponent.text = 'Opponent - 100%';
      }
      else
      {
        audioVocalTrackGroup.opponentVolume = 0.0;
        preferencesVolumeVocalsOpponent.value = 0.0;
        preferencesLabelVolumeVocalsOpponent.text = 'Opponent - 0%';
      }
    }
    previousAudioVolumes[5] = preferencesVolumeVocalsOpponent.value;

    menubarItemPlaybackSpeed.onChange = _ -> applyPlaybackSpeed(menubarItemPlaybackSpeed.pos / 50.0);
    menubarItemPlaybackSpeed.onRightClick = _ -> setPlaybackSpeed(1.0);

    menubarItemToggleToolboxDifficulty.onChange = event -> this.setToolboxState(CHART_EDITOR_TOOLBOX_DIFFICULTY_LAYOUT, event.value);
    menubarItemToggleToolboxMetadata.onChange = event -> this.setToolboxState(CHART_EDITOR_TOOLBOX_METADATA_LAYOUT, event.value);
    menubarItemToggleToolboxTiming.onChange = event -> this.setToolboxState(CHART_EDITOR_TOOLBOX_TIMING_LAYOUT, event.value);
    menubarItemToggleToolboxNoteData.onChange = event -> this.setToolboxState(CHART_EDITOR_TOOLBOX_NOTE_DATA_LAYOUT, event.value);
    menubarItemToggleToolboxEventData.onChange = event -> this.setToolboxState(CHART_EDITOR_TOOLBOX_EVENT_DATA_LAYOUT, event.value);
    menubarItemToggleToolboxPlayerPreview.onChange = event ->
    {
      this.setToolboxState(CHART_EDITOR_TOOLBOX_PLAYER_PREVIEW_LAYOUT, event.value);
      playerPreviewDirty = event.value;
    }
    menubarItemToggleToolboxOpponentPreview.onChange = event ->
    {
      this.setToolboxState(CHART_EDITOR_TOOLBOX_OPPONENT_PREVIEW_LAYOUT, event.value);
      opponentPreviewDirty = event.value;
    }

    menubarItemCameraEditor.onClick = _ ->
    {
      this.moveToCameraEditor();
    };

    // TODO: Pass specific HaxeUI components to add context menus to them.
    // registerContextMenu(null, Paths.xml('ui/editors/chart-editor/context/test'));
  }

  function copySelection():Void
  {
    clipboardDirty = true;
    clipboardValid = true;
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

    SongDataUtils.writeItemsToClipboard({
      notes: SongDataUtils.buildNoteClipboard(currentNoteSelection, timeOffset),
      events: SongDataUtils.buildEventClipboard(currentEventSelection, timeOffset),
    });
  }

  /**
   * Initialize TurboKeyHandlers and add them to the state (so `update()` is called)
   * We can then probe `keyHandler.activated` to see if the key combo's action should be taken.
   */
  function setupTurboKeyHandlers():Void
  {
    // Keyboard shortcuts
    add(undoKeyHandler);
    add(redoKeyHandler);
    add(upKeyHandler);
    add(downKeyHandler);
    add(wKeyHandler);
    add(sKeyHandler);
    add(pageUpKeyHandler);
    add(pageDownKeyHandler);

    // Gamepad inputs
    add(dpadUpGamepadHandler);
    add(dpadDownGamepadHandler);
    add(dpadLeftGamepadHandler);
    add(dpadRightGamepadHandler);
    add(leftStickUpGamepadHandler);
    add(leftStickDownGamepadHandler);
    add(leftStickLeftGamepadHandler);
    add(leftStickRightGamepadHandler);
    add(rightStickUpGamepadHandler);
    add(rightStickDownGamepadHandler);
    add(rightStickLeftGamepadHandler);
    add(rightStickRightGamepadHandler);
  }

  /**
   * Setup timers and listeners to handle auto-save.
   */
  function setupAutoSave():Void
  {
    // Called when clicking the X button on the window.
    WindowUtil.windowExit.add(onWindowClose);

    // Called when the game crashes.
    CrashHandler.errorSignal.add(onWindowCrash);
    CrashHandler.criticalErrorSignal.add(onWindowCrash);

    saveDataDirty = false;
  }

  var displayAutosavePopup:Bool = false;

  /**
   * UPDATE FUNCTIONS
   */
  function autoSave(?beforePlaytest:Bool = false):Void
  {
    var needsAutoSave:Bool = saveDataDirty;

    saveDataDirty = false;

    // Auto-save preferences.
    writePreferences(needsAutoSave);

    // Auto-save the chart.
    #if html5
    // Auto-save to local storage.
    // TODO: Implement this.
    #else
    // Auto-save to temp file.
    if (needsAutoSave)
    {
      this.exportCurrentChartToFNFC(true, null);
      if (beforePlaytest)
      {
        displayAutosavePopup = true;
      }
      else
      {
        displayAutosavePopup = false;
        var absoluteBackupsPath:String = Path.join([
          Sys.getCwd(),
          ChartEditorImportExportHandler.BACKUPS_PATH
        ]);
        this.infoWithActions('Auto-Save', 'Chart auto-saved to ${absoluteBackupsPath}.', [{
          text: 'Open In Folder',
          callback: openBackupsFolder,
        }]);
      }
    }
    #end
  }

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

  /**
   * Called when the window was closed, to save a backup of the chart.
   * @param exitCode The exit code of the window. We use `-1` when calling the function due to a game crash.
   */
  function onWindowClose(exitCode:Int):Void
  {
    trace('Window exited with exit code: $exitCode');
    trace('Should save chart? $saveDataDirty');

    var needsAutoSave:Bool = saveDataDirty;

    writePreferences(needsAutoSave);

    if (needsAutoSave)
    {
      this.exportCurrentChartToFNFC(true, null);
    }
  }

  function onWindowCrash(message:String):Void
  {
    trace('Chart editor intercepted crash:');
    trace('${message}');

    trace('Should save chart? $saveDataDirty');

    var needsAutoSave:Bool = saveDataDirty;

    writePreferences(needsAutoSave);

    if (needsAutoSave)
    {
      this.exportCurrentChartToFNFC(true, null);
    }
  }

  function cleanupAutoSave():Void
  {
    WindowUtil.windowExit.remove(onWindowClose);
    CrashHandler.errorSignal.remove(onWindowCrash);
    CrashHandler.criticalErrorSignal.remove(onWindowCrash);
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
    handleMusicPlayback(elapsed);
    handleCommentDisplay();
    handleZoom(elapsed);
    handleNoteDisplay();
    handleGridLines();
    handleRangeSelection();
    handleStaleTooltip();
    handleGridTooltips(elapsed);

    if (isHaxeUIFocused && !isCursorOverHaxeUI && (FlxG.mouse.justPressedRight || FlxG.mouse.deltaWheel.y != 0))
    {
      ChartEditorToolboxHandler.clearHaxeUIFocus();
    }

    // These ones only happen if the modal dialog is not open.
    handleScrollKeybinds();

    handleCursor();
    handleGridDoubleClicks();

    handleListKeybinds();
    if (!(isHaxeUIFocused || isCursorOverHaxeUI))
    {
      handleSnap();
      handlePlayhead();
      handleEditKeybinds();
    }

    handleMenubar();
    handleToolboxes();
    handlePlaybar();
    handleNotePreview();
    handleHealthIcons();
    handleWaveforms();
    handleWaveformFilter(elapsed);

    handleCommandPalette();

    handleFileKeybinds();
    handleViewKeybinds();
    handleTestKeybinds();
    handleHelpKeybinds();
    handleAudioKeybinds();

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
      stopAudioPlayback(false);
    }

    // No mouse events arrive while unfocused, so the tooltip would never be told to hide.
    hideTooltip();
  }

  /**
   * Handles the hiding of stale tooltips that are no longer relevant.
   */
  function handleStaleTooltip():Void
  {
    var manager:ToolTipManager = ToolTipManager.instance;
    var showing:Bool = manager._toolTip != null && !manager._toolTip.hidden;
    if (!showing && manager._timer == null) return;

    var mouseX:Float = haxe.ui.backend.flixel.MouseHelper.currentWorldX;
    var mouseY:Float = haxe.ui.backend.flixel.MouseHelper.currentWorldY;

    var region = manager._currentRegion;
    if (region != null)
    {
      var stillThere:Bool = manager._toolTipRegions.contains(region);
      var underMouse:Bool = mouseX >= region.left && mouseX < region.left + region.width && mouseY >= region.top && mouseY < region.top + region.height;
      if (!stillThere || !underMouse || isHaxeUIDialogOpen)
      {
        manager._currentRegion = null;
        hideTooltip();
      }
      return;
    }

    var component = manager._currentComponent;
    if (component != null && (!component.exists || component.hidden || !component.hitTest(mouseX, mouseY)))
    {
      hideTooltip();
    }
  }

  function hideTooltip():Void
  {
    var manager:ToolTipManager = ToolTipManager.instance;
    manager.stopCurrent();
    manager.hideCurrentToolTip();
    gridTooltipShown = false;
  }

  // The note or event sprite under the mouse, how long it has been there, and whether its tooltip is showing.
  var gridTooltipTarget:Null<FlxSprite> = null;
  var gridTooltipTime:Float = 0;
  var gridTooltipShown:Bool = false;

  /**
   * Show tooltips for the notes and events on the grid.
   */
  function handleGridTooltips(elapsed:Float):Void
  {
    var target:Null<FlxSprite> = null;
    var options:Null<haxe.ui.tooltips.ToolTipOptions> = null;

    if (gridTiledSprite != null && !isCursorOverHaxeUI && !isHaxeUIDialogOpen && FlxG.mouse.overlaps(gridTiledSprite))
    {
      for (eventSprite in renderedEvents.members)
      {
        if (eventSprite == null || !eventSprite.alive || !eventSprite.visible || eventSprite.eventData == null) continue;
        if ((eventSprite.tooltip.tipData?.text ?? '').length == 0 || !FlxG.mouse.overlaps(eventSprite)) continue;
        target = eventSprite;
        options = eventSprite.tooltip;
        break;
      }

      if (target == null)
      {
        for (noteSprite in renderedNotes.members)
        {
          if (noteSprite == null || !noteSprite.alive || !noteSprite.visible || noteSprite.noteData == null) continue;
          if ((noteSprite.tooltip.tipData?.text ?? '').length == 0 || !FlxG.mouse.overlaps(noteSprite)) continue;
          target = noteSprite;
          options = noteSprite.tooltip;
          break;
        }
      }
    }

    if (target != gridTooltipTarget)
    {
      if (gridTooltipShown) hideTooltip();
      gridTooltipTarget = target;
      gridTooltipTime = 0;
    }

    var manager:ToolTipManager = ToolTipManager.instance;
    if (target == null && manager._toolTip != null && !manager._toolTip.hidden && manager._currentRegion == null && manager._currentComponent == null)
    {
      manager._toolTip.hide();
    }

    if (target == null || options == null || gridTooltipShown) return;

    gridTooltipTime += elapsed;
    if (gridTooltipTime * 1000 < ToolTipManager.defaultDelay) return;

    ToolTipManager.instance.showToolTipAt(haxe.ui.backend.flixel.MouseHelper.currentWorldX, haxe.ui.backend.flixel.MouseHelper.currentWorldY, options);
    gridTooltipShown = true;
  }

  /**
   * Function called when the game window regains focus.
   */
  override public function onFocus():Void
  {
    super.onFocus();

    if (!isPlaytesting)
    {
      fadeInWelcomeMusic(WELCOME_MUSIC_FADE_IN_DELAY, WELCOME_MUSIC_FADE_IN_DURATION);
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
      playMetronomeTick(currentMeasureTime >= currentStepTime - msTreshold && currentMeasureTime <= currentStepTime + msTreshold);
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
   * Handle syncronizing the conductor with the music playback.
   */
  function handleMusicPlayback(elapsed:Float):Void
  {
    if (audioInstTrack != null)
    {
      // This normally gets called by FlxG.sound.update()
      // but we handle instrumental updates manually to prevent FlxG.sound.music.update()
      // from being called twice when we move to the PlayState.
      audioInstTrack.update(elapsed);

      // If the song starts 50ms in, make sure we start the song there.
      if (Conductor.instance.instrumentalOffset < 0)
      {
        if (audioInstTrack.time < -Conductor.instance.instrumentalOffset)
        {
          trace('Resetting instrumental time to ${- Conductor.instance.instrumentalOffset}ms');
          audioInstTrack.time = -Conductor.instance.instrumentalOffset;
        }
      }

      audioVocalTrackGroup.updatePending(audioInstTrack.time, audioInstTrack.isPlaying);

      if
        ((!audioInstTrack.isPlaying || (audioVocalTrackGroup.length > 0 && !audioVocalTrackGroup.playing))
          && currentScrollEase != scrollPositionInPixels
        ) easeSongToScrollPosition(currentScrollEase);
    }

    if ((audioInstTrack != null && audioInstTrack.isPlaying) || audioVocalTrackGroup.playing)
    {
      currentScrollEase = scrollPositionInPixels;

      if (FlxG.keys.pressed.ALT && !FlxG.keys.pressed.CONTROL)
      {
        // If middle mouse panning during song playback, we move ONLY the playhead, without scrolling. Neat!

        var oldSongPosition:Float = Conductor.instance.songPosition + Conductor.instance.instrumentalOffset;
        updateSongTime();
        handleMusicPositionUpdate(oldSongPosition, Conductor.instance.songPosition + Conductor.instance.instrumentalOffset);
        // Resync vocals.
        if (Math.abs(audioInstTrack.time - audioVocalTrackGroup.time) > 100)
        {
          audioVocalTrackGroup.time = audioInstTrack.time;
        }
        // Move the playhead.
        playheadPositionInPixels = ChartEditorTimeScale.stepToPixels(Conductor.instance.currentStepTime + Conductor.instance.instrumentalOffsetSteps) - scrollPositionInPixels;

        // We don't move the song to scroll position, or update the note sprites.
      }
      else
      {
        // Else, move the entire view.
        var oldSongPosition:Float = Conductor.instance.songPosition + Conductor.instance.instrumentalOffset;
        updateSongTime();
        handleMusicPositionUpdate(oldSongPosition, Conductor.instance.songPosition + Conductor.instance.instrumentalOffset);
        // Resync vocals.
        if (Math.abs(audioInstTrack.time - audioVocalTrackGroup.time) > 100)
        {
          audioVocalTrackGroup.time = audioInstTrack.time;
        }

        // We need time in fractional steps here to allow the song to actually play.
        // Also account for a potentially offset playhead.
        scrollPositionInPixels = ChartEditorTimeScale.stepToPixels(Conductor.instance.currentStepTime + Conductor.instance.instrumentalOffsetSteps) - playheadPositionInPixels;

        // DO NOT move song to scroll position here specifically.

        // We need to update the note sprites.
        noteDisplayDirty = true;

        // Update the note preview viewport box.
        setNotePreviewViewportBounds(calculateNotePreviewViewportBounds());
      }
    }

    if (FlxG.keys.justPressed.SPACE && !(isHaxeUIDialogOpen || isHaxeUIFocused))
    {
      toggleAudioPlayback();
    }
  }

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

  function handleRangeSelection():Void
  {
    if (FlxG.keys.justPressed.TAB && !(isHaxeUIDialogOpen || isHaxeUIFocused))
    {
      var playheadMs:Float = scrollPositionInMs + playheadPositionInMs;
      var start:Null<Float> = rangeSelectionStartMs;
      if (start == null || rangeSelectionEndMs != null)
      {
        // Start a new selection.
        rangeSelectionStartMs = playheadMs;
        rangeSelectionEndMs = null;
      }
      else
      {
        rangeSelectionStartMs = Math.min(start, playheadMs);
        rangeSelectionEndMs = Math.max(start, playheadMs);
      }
    }

    var sprite:Null<FlxSprite> = rangeSelectionSprite;
    if (sprite == null || gridTiledSprite == null) return;

    var start:Null<Float> = rangeSelectionStartMs;
    sprite.visible = start != null;
    if (start == null) return;

    var top:Float = gridTiledSprite.y + ChartEditorTimeScale.msToPixels(start);
    var end:Null<Float> = rangeSelectionEndMs;
    var height:Float = RANGE_SELECTION_MARKER_HEIGHT;
    if (end != null)
    {
      height = Math.max(RANGE_SELECTION_MARKER_HEIGHT, ChartEditorTimeScale.msToPixels(end) - ChartEditorTimeScale.msToPixels(start));
      sprite.alpha = RANGE_SELECTION_ALPHA;
    }
    else
    {
      top -= RANGE_SELECTION_MARKER_HEIGHT / 2;
      sprite.alpha = 1;
    }

    sprite.scale.set(gridTiledSprite.width, height);
    sprite.updateHitbox();
    sprite.x = gridTiledSprite.x;
    sprite.y = top;
  }

  function handleGridLines():Void
  {
    if (gridLines == null) return;
    gridLines.refresh(gridLinesDirty);
    gridLinesDirty = false;
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

  /**
   * The time change picked in the Timing panel, which gets a box around its tags on the grid.
   */
  var selectedTimeChangeIndex:Int = -1;

  /**
   * Sends copy, paste and delete to the picked time change.
   */
  var timeChangeSelection:Null<ChartEditorTimeChangeSelection> = null;

  /**
   * The time change to box on the grid, or -1 when the Timing panel isn't on screen.
   */
  function outlinedTimeChangeIndex():Int
  {
    var toolbox:Null<CollapsibleDialog> = activeToolboxes.get(CHART_EDITOR_TOOLBOX_TIMING_LAYOUT);
    if (toolbox == null || toolbox.hidden || !Screen.instance.rootComponents.contains(toolbox)) return -1;
    return selectedTimeChangeIndex;
  }

  static final DOUBLE_CLICK_SECONDS:Float = 0.35;

  /**
   * Double clicking an event opens it in the Events panel.
   */
  function handleGridDoubleClicks():Void
  {
    if (!FlxG.mouse.justPressed || isCursorOverHaxeUI) return;

    var timeChangeIndex:Int = gridLines != null ? gridLines.timeChangeUnderMouse() : -1;
    if (timeChangeIndex >= 0)
    {
      lastGridClickTarget = null;
      if (selectedTimeChangeIndex == timeChangeIndex)
      {
        openToolboxFromGrid(CHART_EDITOR_TOOLBOX_TIMING_LAYOUT, menubarItemToggleToolboxTiming);
        var timingToolbox:Null<ChartEditorTimingToolbox> = cast activeToolboxes.get(CHART_EDITOR_TOOLBOX_TIMING_LAYOUT);
        if (timingToolbox != null) timingToolbox.refreshTimeChanges(timeChangeIndex);
      }
      else
      {
        selectedTimeChangeIndex = timeChangeIndex;
      }
      timeChangeSelection ??= new ChartEditorTimeChangeSelection(this);
      listKeyTarget = timeChangeSelection;
      return;
    }

    if (outlinedTimeChangeIndex() < 0) selectedTimeChangeIndex = -1;

    var target:Dynamic = null;
    var clickedEvent:Null<SongEventData> = null;
    for (eventSprite in renderedEvents.members)
    {
      if (eventSprite != null && eventSprite.alive && eventSprite.eventData != null && FlxG.mouse.overlaps(eventSprite))
      {
        clickedEvent = eventSprite.eventData;
        target = clickedEvent;
        break;
      }
    }

    var now:Float = haxe.Timer.stamp();
    var isDouble:Bool = target != null && target == lastGridClickTarget && now - lastGridClickTime <= DOUBLE_CLICK_SECONDS;
    lastGridClickTarget = isDouble ? null : target;
    lastGridClickTime = now;
    if (!isDouble) return;

    if (clickedEvent != null)
    {
      // The first click already selected the event and its chain.
      if (!isEventSelected(clickedEvent)) performCommand(new SetItemSelectionCommand([], [clickedEvent]));
      openToolboxFromGrid(CHART_EDITOR_TOOLBOX_EVENT_DATA_LAYOUT, menubarItemToggleToolboxEventData);
      this.refreshToolbox(CHART_EDITOR_TOOLBOX_EVENT_DATA_LAYOUT);
      var eventToolbox:Null<ChartEditorEventDataToolbox> = cast activeToolboxes.get(CHART_EDITOR_TOOLBOX_EVENT_DATA_LAYOUT);
      if (eventToolbox != null) listKeyTarget = eventToolbox;
    }
  }

  function openToolboxFromGrid(id:String, menuItem:MenuCheckBox):Void
  {
    if (!menuItem.selected) menuItem.selected = true;
    this.setToolboxState(id, true);
  }

  function handleNoteDisplay():Void
  {
    if (noteSnapRatio != eventChainSnapRatio)
    {
      eventChainSnapRatio = noteSnapRatio;
      noteDisplayDirty = true;
    }

    if (noteDisplayDirty)
    {
      if (!ChartEditorTimeScale.CONSTANT_SCROLL) updateGridScale(true);
      noteDisplayDirty = false;

      // Some optimization to cull notes -

      // Update for whether downscroll is enabled.
      renderedNotes.flipX = (isViewDownscroll);

      // Calculate the top and bottom of the view area.
      var viewAreaTopPixels:Float = MENU_BAR_HEIGHT;
      var visibleGridHeightPixels:Float = FlxG.height - MENU_BAR_HEIGHT - PLAYBAR_HEIGHT; // The area underneath the menu bar and playbar is not visible.
      var viewAreaBottomPixels:Float = viewAreaTopPixels + visibleGridHeightPixels;

      var viewAreaTopMs:Float = ChartEditorTimeScale.pixelsToMs(scrollPositionInPixels - visibleGridHeightPixels);
      var viewAreaBottomMs:Float = ChartEditorTimeScale.pixelsToMs(scrollPositionInPixels + visibleGridHeightPixels * 2);

      // One pass over the chart collects everything in range
      windowNoteSet.clear();
      windowNotes.resize(0);

      for (noteData in currentSongChartNoteData)
      {
        if (noteData == null) continue;
        if (noteData.time > viewAreaBottomMs) continue;
        // Hold notes that started earlier but still reach into the range count too.
        if (noteData.time + Math.max(0, noteData.length) < viewAreaTopMs) continue;
        windowNoteSet.set(noteData, true);
        windowNotes.push(noteData);
      }
      windowEventSet.clear();
      for (eventData in currentSongChartEventData)
      {
        if (eventData != null && eventData.time >= viewAreaTopMs && eventData.time <= viewAreaBottomMs) windowEventSet.set(eventData, true);
      }
      selectedNoteSet.clear();
      for (noteData in currentNoteSelection)
        selectedNoteSet.set(noteData, true);
      selectedEventSet.clear();
      for (eventData in currentEventSelection)
        selectedEventSet.set(eventData, true);

      // Remove notes that are no longer visible and list the ones that are.
      displayedNoteSet.clear();
      for (noteSprite in renderedNotes.members)
      {
        if (noteSprite == null || noteSprite.noteData == null || !noteSprite.exists || !noteSprite.visible) continue;

        // Resolve an issue where dragging an event too far would cause it to be hidden.
        var isSelectedAndDragged = (dragTargetCurrentStep != 0) && selectedNoteSet.exists(noteSprite.noteData);

        if ((windowNoteSet.exists(noteSprite.noteData) && noteSprite.isNoteVisible(viewAreaBottomPixels, viewAreaTopPixels)) || isSelectedAndDragged)
        {
          // Note is already displayed and should remain displayed.
          displayedNoteSet.set(noteSprite.noteData, true);

          // Update the note sprite's position.
          noteSprite.updateNotePosition(renderedNotes);
        }
        else
        {
          // This sprite is off-screen or was deleted.
          // Kill the note sprite and recycle it.
          noteSprite.kill();
        }
      }

      displayedHoldNotes.clear();
      for (holdNoteSprite in renderedHoldNotes.members)
      {
        if (holdNoteSprite == null || holdNoteSprite.noteData == null || !holdNoteSprite.exists || !holdNoteSprite.visible) continue;

        // Fixes an issue where dragging a hold note too far would hide its sustain trail
        var isSelectedAndDragged = (dragTargetCurrentStep != 0) && selectedNoteSet.exists(holdNoteSprite.noteData);

        if (!isSelectedAndDragged && (holdNoteSprite.noteData == currentPlaceNoteData // Being dragged, displayed by gridGhostHoldNoteSprite instead.
          || !windowNoteSet.exists(holdNoteSprite.noteData) // Deleted or out of range.
          || !holdNoteSprite.isHoldNoteVisible(viewAreaBottomPixels, viewAreaTopPixels) // Off-screen.
          || holdNoteSprite.noteData.length == 0 // Also deleted.
        ))
        {
          // Kill the hold note sprite and recycle it.
          holdNoteSprite.kill();
        }
        else
        {
          displayedHoldNotes.set(holdNoteSprite.noteData, holdNoteSprite);
          // Update the hold note sprite's height and position.
          var holdNoteHeight = ChartEditorTimeScale.lengthToPixels(holdNoteSprite.noteData.time, holdNoteSprite.noteData.length, holdNoteSprite.noteData.getStepLength());
          holdNoteSprite.setHeightDirectly(holdNoteHeight);
          holdNoteSprite.updateHoldNotePosition(renderedHoldNotes);
        }
      }

      // Remove events that are no longer visible and list the ones that are.
      rebuildEventChains();
      displayedEventSet.clear();
      for (eventSprite in renderedEvents.members)
      {
        if (eventSprite == null || eventSprite.eventData == null || !eventSprite.exists || !eventSprite.visible) continue;

        // Resolve an issue where dragging an event too far would cause it to be hidden.
        var isSelectedAndDragged = (dragTargetCurrentStep != 0) && selectedEventSet.exists(eventSprite.eventData);

        var isChainFollower:Bool = eventChainFollowers.exists(eventSprite.eventData);
        if (!isChainFollower
          && ((windowEventSet.exists(eventSprite.eventData) && eventSprite.isEventVisible(viewAreaBottomPixels, viewAreaTopPixels)) || isSelectedAndDragged))
        {
          // Event is already displayed and should remain displayed.
          displayedEventSet.set(eventSprite.eventData, true);

          // Update the event sprite's position.
          eventSprite.updateEventPosition(renderedEvents);
          // Update the sprite's graphic. TODO: Is this inefficient?
          eventSprite.playAnimation(eventSprite.eventData.eventKind);
          eventSprite.overlappingEventDatas = eventChainRest.get(eventSprite.eventData) ?? [];
        }
        else
        {
          // This event was deleted.
          // Kill the event sprite and recycle it.
          eventSprite.kill();
        }
      }

      // Add notes that are now visible.
      for (noteData in windowNotes)
      {
        // Remember if we are already displaying this note.
        if (displayedNoteSet.exists(noteData)) continue;

        if (!ChartEditorNoteSprite.wouldNoteBeVisible(
          viewAreaBottomPixels,
          viewAreaTopPixels,
          noteData,
          renderedNotes
        )) continue; // Else, this note is visible and we need to render it!

        // Get a note sprite from the pool.
        // If we can reuse a deleted note, do so.
        // If a new note is needed, call buildNoteSprite.
        var noteSprite:ChartEditorNoteSprite = renderedNotes.recycle(() -> new ChartEditorNoteSprite(this));
        notesNeedSort = true;
        // trace('Creating new Note... (${renderedNotes.members.length})');
        noteSprite.parentState = this;

        // The note sprite handles animation playback and positioning.
        noteSprite.noteData = noteData;
        noteSprite.noteStyle = NoteKindManager.getNoteStyleId(noteData.kind, currentSongNoteStyle) ?? currentSongNoteStyle;
        noteSprite.overrideStepTime = null;
        noteSprite.overrideData = null;

        // Setting note data resets the position relative to the group!
        // If we don't update the note position AFTER setting the note data, the note will be rendered offscreen at y=5000.
        noteSprite.updateNotePosition(renderedNotes);

        // Add hold notes that are now visible (and not already displayed).
        if (
          noteSprite.noteData != null
          && noteSprite.noteData.length > 0
          && !displayedHoldNotes.exists(noteSprite.noteData)
          && noteSprite.noteData != currentPlaceNoteData
        )
        {
          var holdNoteSprite:ChartEditorHoldNoteSprite = renderedHoldNotes.recycle(() -> new ChartEditorHoldNoteSprite(this));
          displayedHoldNotes.set(noteSprite.noteData, holdNoteSprite);
          // trace('Creating new HoldNote... (${renderedHoldNotes.members.length})');

          var noteLengthPixels:Float = ChartEditorTimeScale.lengthToPixels(noteSprite.noteData.time, noteSprite.noteData.length, noteSprite.noteData.getStepLength());

          holdNoteSprite.noteData = noteSprite.noteData;
          holdNoteSprite.overrideStepTime = null;
          holdNoteSprite.overrideData = null;
          holdNoteSprite.noteDirection = noteSprite.noteData.getDirection();

          holdNoteSprite.setHeightDirectly(noteLengthPixels);

          holdNoteSprite.noteStyle = NoteKindManager.getNoteStyleId(noteSprite.noteData.kind, currentSongNoteStyle) ?? currentSongNoteStyle;

          holdNoteSprite.updateHoldNotePosition(renderedHoldNotes);
        }
      }

      // Add events that are now visible.
      for (eventData in currentSongChartEventData)
      {
        // Remember if we are already displaying this event.
        if (!windowEventSet.exists(eventData) || displayedEventSet.exists(eventData)) continue;
        if (eventChainFollowers.exists(eventData)) continue;

        if (!ChartEditorEventSprite.wouldEventBeVisible(viewAreaBottomPixels, viewAreaTopPixels, eventData, renderedNotes)) continue;

        // Else, this event is visible and we need to render it!

        // Get an event sprite from the pool.
        // If we can reuse a deleted event, do so.
        // If a new event is needed, call buildEventSprite.
        var eventSprite:ChartEditorEventSprite = renderedEvents.recycle(() -> new ChartEditorEventSprite(this), false, true);
        eventSprite.parentState = this;
        // trace('Creating new Event... (${renderedEvents.members.length})');

        if (eventData?.value != null && (eventData.getString('ease') != null && eventData.getInt('easeDir') == null))
        {
          eventData.value = migrateEventEaseDirectionFields(eventData.value);
        }

        // The event sprite handles animation playback and positioning.
        eventSprite.eventData = eventData;
        eventSprite.overrideStepTime = null;

        // Update the tooltip in-case there's overlapping events.
        eventSprite.overlappingEventDatas = eventChainRest.get(eventData) ?? [];

        // Setting event data resets position relative to the grid so we fix that.
        eventSprite.x += renderedEvents.x;
        eventSprite.y += renderedEvents.y;
      }

      // Add hold notes that have been made visible (but not their parents)
      for (noteData in windowNotes)
      {
        // Is the note a hold note?
        if (noteData.length <= 0) continue;

        // Is the note the one we are dragging? If so, ghostHoldNoteSprite will handle it.
        if (noteData == currentPlaceNoteData) continue;

        // Is the hold note rendered already?
        if (displayedHoldNotes.exists(noteData)) continue;

        // Is the hold note offscreen?
        if (!ChartEditorHoldNoteSprite.wouldHoldNoteBeVisible(viewAreaBottomPixels, viewAreaTopPixels, noteData, renderedHoldNotes)) continue;

        // Hold note should be rendered.
        var holdNoteFactory = function()
        {
          // TODO: Print some kind of warning if `renderedHoldNotes.members` is too high?
          return new ChartEditorHoldNoteSprite(this);
        }
        var holdNoteSprite:ChartEditorHoldNoteSprite = renderedHoldNotes.recycle(holdNoteFactory);
        displayedHoldNotes.set(noteData, holdNoteSprite);

        var noteLengthPixels:Float = ChartEditorTimeScale.lengthToPixels(noteData.time, noteData.length, noteData.getStepLength());

        holdNoteSprite.noteData = noteData;
        holdNoteSprite.overrideStepTime = null;
        holdNoteSprite.overrideData = null;
        holdNoteSprite.noteDirection = noteData.getDirection();
        holdNoteSprite.setHeightDirectly(noteLengthPixels);

        holdNoteSprite.noteStyle = NoteKindManager.getNoteStyleId(noteData.kind, currentSongNoteStyle) ?? currentSongNoteStyle;

        holdNoteSprite.updateHoldNotePosition(renderedHoldNotes);
      }

      // Destroy all existing selection squares.
      for (member in renderedSelectionSquares.members)
      {
        // Killing the sprite is cheap because we can recycle it.
        member.kill();
      }

      // Gather stacked notes to render later
      // No need to update it every time we scroll
      if (Math.abs(currentScrollEase - scrollPositionInPixels) < .0001)
      {
        currentOverlappingNotes = SongNoteDataUtils.listStackedNotes(currentSongChartNoteData, stackedNoteThreshold);
      }
      stackedNoteSet.clear();
      for (noteData in currentOverlappingNotes)
        stackedNoteSet.set(noteData, true);

      // Readd selection squares for selected notes.
      // Recycle selection squares if possible.
      for (noteSprite in renderedNotes.members)
      {
        if (noteSprite == null || noteSprite.noteData == null || !noteSprite.exists || !noteSprite.visible) continue;

        // TODO: Handle selection of hold notes.
        if (selectedNoteSet.exists(noteSprite.noteData))
        {
          var holdNoteSprite:Null<ChartEditorHoldNoteSprite> = (noteSprite.noteData.length > 0) ? displayedHoldNotes.get(noteSprite.noteData) : null;

          // Determine if the note is being dragged and offset the vertical position accordingly.
          if (dragTargetCurrentStep != 0.0)
          {
            var stepTime:Float = (noteSprite.noteData == null) ? 0.0 : noteSprite.noteData.getStepTime();
            // Update the note's "ghost" step time.
            noteSprite.overrideStepTime = (stepTime + dragTargetCurrentStep).clamp(0, lastSnappedGridStep);
            // Then reapply the note sprite's position relative to the grid.
            noteSprite.updateNotePosition(renderedNotes);

            // We only need to update the position of the hold note tails as we drag the note.
            if (holdNoteSprite != null)
            {
              holdNoteSprite.overrideStepTime = noteSprite.overrideStepTime;
              holdNoteSprite.updateHoldNotePosition(renderedHoldNotes);
            }
          }
          else
          {
            if (noteSprite.overrideStepTime != null)
            {
              // Reset the note's "ghost" step time.
              noteSprite.overrideStepTime = null;
              // Then reapply the note sprite's position relative to the grid.
              noteSprite.updateNotePosition(renderedNotes);

              if (holdNoteSprite != null)
              {
                holdNoteSprite.overrideStepTime = null;
                holdNoteSprite.updateHoldNotePosition(renderedHoldNotes);
              }
            }
          }

          // Determine if the note is being dragged and offset the horizontal position accordingly.
          if (dragTargetCurrentColumn != 0)
          {
            var data:Int = (noteSprite.noteData == null) ? 0 : noteSprite.noteData.data;
            // Update the note's "ghost" column.
            noteSprite.overrideData = ChartEditorNoteUtil.gridColumnToNoteData(
              (ChartEditorNoteUtil.noteDataToGridColumn(data) + dragTargetCurrentColumn).clamp(0, ChartEditorState.STRUMLINE_SIZE * 2 - 1)
            );
            // Then reapply the note sprite's position relative to the grid.
            noteSprite.updateNotePosition(renderedNotes);

            // We only need to update the position of the hold note tails as we drag the note.
            if (holdNoteSprite != null)
            {
              holdNoteSprite.overrideData = noteSprite.overrideData;
              holdNoteSprite.updateHoldNotePosition(renderedHoldNotes);
            }
          }
          else
          {
            if (noteSprite.overrideData != null)
            {
              // Reset the note's "ghost" column.
              noteSprite.overrideData = null;
              // Then reapply the note sprite's position relative to the grid.
              noteSprite.updateNotePosition(renderedNotes);

              if (holdNoteSprite != null)
              {
                holdNoteSprite.overrideData = null;
                holdNoteSprite.noteDirection = noteSprite.noteData.getDirection();
                holdNoteSprite.updateHoldNoteGraphic();
                holdNoteSprite.updateHoldNotePosition(renderedHoldNotes);
              }
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
          selectionSquare.color = FlxColor.WHITE;

          var stepLength = noteSprite.noteData.getStepLength();

          selectionSquare.height = (stepLength <= 0) ? GRID_SIZE : (ChartEditorTimeScale.lengthToPixels(noteSprite.noteData.time, noteSprite.noteData.length, stepLength) + GRID_SIZE / 2);
        }
        else if (stackedNoteSet.exists(noteSprite.noteData))
        {
          // TODO: Maybe use another way to display these notes
          var selectionSquare:ChartEditorSelectionSquareSprite = renderedSelectionSquares.recycle(buildSelectionSquare);

          // Set the position and size (because we might be recycling one with bad values).
          selectionSquare.noteData = noteSprite.noteData;
          selectionSquare.eventData = null;
          selectionSquare.x = noteSprite.x;
          selectionSquare.y = noteSprite.y;
          selectionSquare.width = selectionSquare.height = GRID_SIZE;
          selectionSquare.color = FlxColor.RED;
        }

        // Additional cleanup on notes.
        if (noteTooltipsDirty) noteSprite.updateTooltipText();
      }

      for (eventSprite in renderedEvents.members)
      {
        if (eventSprite == null || eventSprite.eventData == null || !eventSprite.exists || !eventSprite.visible) continue;

        if (isEventSelected(eventSprite.eventData))
        {
          // Determine if the note is being dragged and offset the position accordingly.
          if (dragTargetCurrentStep != 0.0 || dragTargetCurrentColumn != 0)
          {
            var stepTime = (eventSprite.eventData == null) ? 0 : eventSprite.eventData.getStepTime();
            eventSprite.overrideStepTime = (stepTime + dragTargetCurrentStep).clamp(0, lastSnappedGridStep);
            // Then reapply the note sprite's position relative to the grid.
            eventSprite.updateEventPosition(renderedEvents);
          }
          else
          {
            if (eventSprite.overrideStepTime != null)
            {
              eventSprite.overrideStepTime = null;
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
          selectionSquare.color = FlxColor.WHITE;
        }
        else
        {
          if (eventSprite.overrideStepTime != null)
          {
            eventSprite.overrideStepTime = null;
            eventSprite.updateEventPosition(renderedEvents);
          }
        }

        // Additional cleanup on notes.
        if (noteTooltipsDirty) eventSprite.updateTooltipText();
      }

      noteTooltipsDirty = false;

      // Sort the notes DESCENDING. This keeps the sustain behind the associated note.
      if (notesNeedSort || dragTargetCurrentStep != 0 || dragTargetCurrentColumn != 0)
      {
        renderedNotes.sort(FlxSort.byY, FlxSort.DESCENDING);
        notesNeedSort = false;
      }

      // Sort the events DESCENDING. This keeps the sustain behind the associated note.
      renderedEvents.sort(function(order:Int, obj1:FlxBasic, obj2:FlxBasic):Int
      {
        var event1:ChartEditorEventSprite = cast obj1;
        var event2:ChartEditorEventSprite = cast obj2;

        var sel1 = event1.eventData != null && selectedEventSet.exists(event1.eventData);
        var sel2 = event2.eventData != null && selectedEventSet.exists(event2.eventData);

        if (sel1 && !sel2) return 1;
        if (!sel1 && sel2) return -1;

        return FlxSort.byValues(order, event1.y, event2.y);
      }, FlxSort.DESCENDING);
    }
  }

  /**
   * Handle using `renderedPins` to display comment pins from `currentSongChartCommentData`.
   */
  function handleCommentDisplay():Void
  {
    // We need to update when comments change OR we scroll.
    if (noteDisplayDirty || commentDisplayDirty)
    {
      // Current algorithm displays every on-screen comment, starting closest to the playhead

      var playheadPosMs:Float = scrollPositionInMs + playheadPositionInMs;

      var startPos:Float = ChartEditorTimeScale.pixelsToMs(scrollPositionInPixels - (GRID_TOP_PAD + commentPanels[0].height));
      var endPos:Float = ChartEditorTimeScale.pixelsToMs(scrollPositionInPixels + (FlxG.height - PLAYBAR_HEIGHT - GRID_INITIAL_Y_POS));

      var nearbyCommentData:Array<CommentData> = currentSongChartCommentData.filter((comment) ->
      {
        return (comment.time >= startPos && comment.time <= endPos);
      });

      nearbyCommentData.sort((commentA, commentB) ->
      {
        if (commentA.time == commentB.time) return 0;

        // Sort by which is closer to the playheadPosMs.
        var commentADistance = Math.abs(commentA.time - playheadPosMs);
        var commentBDistance = Math.abs(commentB.time - playheadPosMs);
        return (commentADistance - commentBDistance) > 0 ? 1 : -1;
      });

      while (commentPanels.length < nearbyCommentData.length)
      {
        buildCommentPanel();
      }

      for (i in 0...commentPanels.length)
      {
        var commentPanel:ChartEditorCommentPanel = commentPanels[i];
        commentPanel.commentData = i < nearbyCommentData.length ? nearbyCommentData[i] : null;
        commentPanel.updatePosition();
        commentPanel.updateColor();
      }
    }

    if (commentDisplayDirty)
    {
      commentDisplayDirty = false;

      // Remove comments that are no longer visible and list the ones that are.
      var displayedCommentData:Array<CommentData> = [];
      for (pinSprite in renderedPins.members)
      {
        if (pinSprite == null || pinSprite.commentData == null || !pinSprite.exists || !pinSprite.visible) continue;

        if (!currentSongChartCommentData.contains(pinSprite.commentData))
        {
          // Comment has been removed!
          trace('Discarding comment pin ${pinSprite.commentData}');
          // Clearing the comment data on the pin will automatically kill it.
          pinSprite.commentData = null;
        }
        else
        {
          // Mark that we are already rendering this comment.
          displayedCommentData.push(pinSprite.commentData);

          // Make sure the pin display is up to date.
          pinSprite.updateDisplay();
        }
      }

      // Add comments that are newly visible.
      for (commentData in currentSongChartCommentData)
      {
        trace('Rendering comment pin ${commentData}');
        var pinSprite:ChartEditorCommentPinSprite = renderedPins.recycle(() -> new ChartEditorCommentPinSprite(this));

        // Updating the comment data automatically triggers a position/color/text update.
        pinSprite.commentData = commentData;
      }
    }
  }

  function buildCommentPanel():Void
  {
    var commentPanel:ChartEditorCommentPanel = new ChartEditorCommentPanel(this);
    commentPanel.zIndex = 10;
    commentPanel.hidden = true;
    add(commentPanel);
    commentPanels.push(commentPanel);
    refresh();
  }

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
   * Handle keybinds for scrolling the chart editor grid.
   */
  function handleScrollKeybinds():Void
  {
    // Don't scroll when the user is interacting with the UI, unless a playbar button (the << >> ones) is pressed.
    if ((isHaxeUIFocused || (isCursorOverHaxeUI && !canScrollComment && scrollAnchorScreenPos == null)) && playbarButtonPressed == null) return;

    var scrollAmount:Float = 0; // Amount to scroll the grid.
    var playheadAmount:Float = 0; // Amount to scroll the playhead relative to the grid.
    var shouldPause:Bool = false; // Whether to pause the song when scrolling.
    var shouldEase:Bool = false; // Whether to ease the scroll.
    var shouldSnap:Bool = false; // Whether the move is a fixed number of grid steps, so the playhead should land on the grid.

    // Handle scroll anchor
    if (scrollAnchorScreenPos != null)
    {
      var currentScreenPos = FlxPoint.weak(FlxG.mouse.x, FlxG.mouse.y);
      var distance = currentScreenPos - scrollAnchorScreenPos;

      var verticalDistance = distance.y;

      // How much scrolling should be done based on the distance of the cursor from the anchor.
      final ANCHOR_SCROLL_SPEED = 12;

      scrollAmount = ANCHOR_SCROLL_SPEED * verticalDistance * FlxG.elapsed;
      shouldPause = true;
    }

    // Ctrl+Mouse Wheel = Zoom
    if (FlxG.mouse.deltaWheel.y != 0 && pressingControl())
    {
      zoomLevelIndex += (FlxG.mouse.deltaWheel.y > 0) ? 1 : -1;
    }
    // Mouse Wheel = Scroll
    else if (FlxG.mouse.deltaWheel.y != 0)
    {
      scrollAmount = -ChartEditorTimeScale.currentStepPixels() * FlxG.mouse.deltaWheel.y;
      shouldPause = true;
      shouldSnap = true;
    }

    // Up Arrow = Scroll Up
    if (upKeyHandler.activated && currentLiveInputStyle != WASDKeys)
    {
      scrollAmount = -ChartEditorTimeScale.currentStepPixels() * 4;
      shouldPause = true;
      shouldSnap = true;
    }
    // Down Arrow = Scroll Down
    if (downKeyHandler.activated && currentLiveInputStyle != WASDKeys)
    {
      scrollAmount = ChartEditorTimeScale.currentStepPixels() * 4;
      shouldPause = true;
      shouldSnap = true;
    }

    // W = Scroll Up (doesn't work with Ctrl+Scroll)
    if (wKeyHandler.activated && currentLiveInputStyle != WASDKeys && !pressingControl())
    {
      scrollAmount = -ChartEditorTimeScale.currentStepPixels() * 4;
      shouldPause = true;
      shouldSnap = true;
    }
    // S = Scroll Down (doesn't work with Ctrl+Scroll)
    if (sKeyHandler.activated && currentLiveInputStyle != WASDKeys && !pressingControl())
    {
      scrollAmount = ChartEditorTimeScale.currentStepPixels() * 4;
      shouldPause = true;
      shouldSnap = true;
    }

    // GAMEPAD LEFT STICK UP = Scroll Up by 1 note snap
    if (leftStickUpGamepadHandler.activated)
    {
      scrollAmount = -ChartEditorTimeScale.currentStepPixels() * noteSnapRatio;
      shouldPause = true;
      shouldSnap = true;
    }
    // GAMEPAD LEFT STICK DOWN = Scroll Down by 1 note snap
    if (leftStickDownGamepadHandler.activated)
    {
      scrollAmount = ChartEditorTimeScale.currentStepPixels() * noteSnapRatio;
      shouldPause = true;
      shouldSnap = true;
    }

    // GAMEPAD RIGHT STICK UP = Scroll Up by 1 note snap (playhead only)
    if (rightStickUpGamepadHandler.activated)
    {
      playheadAmount = -ChartEditorTimeScale.currentStepPixels() * noteSnapRatio;
      shouldPause = true;
      shouldSnap = true;
    }
    // GAMEPAD RIGHT STICK DOWN = Scroll Down by 1 note snap (playhead only)
    if (rightStickDownGamepadHandler.activated)
    {
      playheadAmount = ChartEditorTimeScale.currentStepPixels() * noteSnapRatio;
      shouldPause = true;
      shouldSnap = true;
    }

    var funcJumpUp = (playheadOnly:Bool) ->
    {
      var playheadPosition:Float = ChartEditorTimeScale.pixelsToMs(currentScrollEase + playheadPositionInPixels);
      var currentPositionMeasure:Float = Conductor.instance.getTimeInMeasures(playheadPosition);
      var currentPositionMeasureFlooredInMs:Float = Conductor.instance.getMeasureTimeInMs(Math.floor(currentPositionMeasure));
      var targetScrollPosition:Float = 0;
      if (FlxMath.inBounds(
        playheadPosition,
        currentPositionMeasureFlooredInMs - 1,
        currentPositionMeasureFlooredInMs + Conductor.instance.getTypeLengthAtMs(playheadPosition, 'step')
      ))
      {
        targetScrollPosition = Conductor.instance.getMeasureTimeInMs(Math.floor(currentPositionMeasure - 1));
      }
      else
      {
        targetScrollPosition = currentPositionMeasureFlooredInMs;
      }

      targetScrollPosition = ChartEditorTimeScale.msToPixels(targetScrollPosition);
      playheadPosition = ChartEditorTimeScale.msToPixels(playheadPosition);

      if (playheadOnly)
      {
        playheadAmount = targetScrollPosition - playheadPosition;
      }
      else
      {
        scrollAmount = targetScrollPosition - playheadPosition;
      }
    }

    // PAGE UP = Jump up to nearest measure
    // GAMEPAD LEFT STICK LEFT = Jump up to nearest measure
    if (pageUpKeyHandler.activated || leftStickLeftGamepadHandler.activated)
    {
      funcJumpUp(false);
      shouldPause = true;
    }
    if (rightStickLeftGamepadHandler.activated)
    {
      funcJumpUp(true);
      shouldPause = true;
    }
    if (playbarButtonPressed == 'playbarBack')
    {
      playbarButtonPressed = '';
      funcJumpUp(false);
      shouldPause = true;
    }

    var funcJumpDown = (playheadOnly:Bool) ->
    {
      var playheadPosition:Float = ChartEditorTimeScale.pixelsToMs(currentScrollEase + playheadPositionInPixels);
      var currentPositionMeasure:Float = Conductor.instance.getTimeInMeasures(playheadPosition);
      var targetScrollPosition:Float = Conductor.instance.getMeasureTimeInMs(Math.floor(currentPositionMeasure + 1.0001));
      // Now, why the hell is that .0001 there? It's to fix floating point bullshit that would result in "floor(measure + 1)" giving back
      // the SAME MEASURE NUMBER that you can see in the Flixel F2 debugger.
      // tldr: we wouldn't actually jump to the next measure.

      targetScrollPosition = ChartEditorTimeScale.msToPixels(targetScrollPosition);
      playheadPosition = ChartEditorTimeScale.msToPixels(playheadPosition);

      if (playheadOnly)
      {
        playheadAmount = targetScrollPosition - playheadPosition;
      }
      else
      {
        scrollAmount = targetScrollPosition - playheadPosition;
      }
    }

    // PAGE DOWN = Jump down to nearest measure
    // GAMEPAD LEFT STICK RIGHT = Jump down to nearest measure
    if (pageDownKeyHandler.activated || leftStickRightGamepadHandler.activated)
    {
      funcJumpDown(false);
      shouldPause = true;
    }
    if (rightStickRightGamepadHandler.activated)
    {
      funcJumpDown(true);
      shouldPause = true;
    }
    if (playbarButtonPressed == 'playbarForward')
    {
      playbarButtonPressed = '';
      funcJumpDown(false);
      shouldPause = true;
    }

    // SHIFT + Scroll = Scroll Fast
    // GAMEPAD LEFT STICK CLICK + Scroll = Scroll Fast
    if (FlxG.keys.pressed.SHIFT || (FlxG.gamepads.firstActive?.pressed?.LEFT_STICK_CLICK ?? false))
    {
      scrollAmount *= 2;
    }
    // CONTROL + Scroll = Scroll Precise
    if (pressingControl())
    {
      scrollAmount /= 4;
    }

    // Alt + Drag = Scroll but move the playhead the same amount.
    if (FlxG.keys.pressed.ALT)
    {
      playheadAmount = scrollAmount;
      scrollAmount = 0;
      shouldPause = false;
    }

    // HOME = Scroll to Top
    if (!FlxG.keys.pressed.SHIFT && FlxG.keys.justPressed.HOME)
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
    if (!FlxG.keys.pressed.SHIFT && FlxG.keys.justPressed.END)
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

    shouldEase = true;
    if (shouldPause && (audioInstTrack?.isPlaying || audioVocalTrackGroup.playing)) stopAudioPlayback(); // Only do this once, not every frame

    if (shouldSnap && currentScrollEase != null)
    {
      var playheadAbsolute:Float = currentScrollEase + this.playheadPositionInPixels;
      if (scrollAmount != 0) scrollAmount = snapStepMove(playheadAbsolute, scrollAmount) - playheadAbsolute;
      if (playheadAmount != 0) playheadAmount = snapStepMove(playheadAbsolute, playheadAmount) - playheadAbsolute;
    }

    // Resync the conductor and audio tracks.
    if (playheadAmount != 0) this.playheadPositionInPixels += playheadAmount;

    if (scrollAmount != 0) currentScrollEase += scrollAmount;
  }

  function releaseScrollAnchor():Void
  {
    scrollAnchorScreenPos.put();
    scrollAnchorScreenPos = null;

    if (currentScrollEase == null) return;

    // Snapped in steps rather than pixels.
    var playheadAbsolute:Float = currentScrollEase + this.playheadPositionInPixels;
    var gridSteps:Float = ChartEditorTimeScale.pixelsToStep(playheadAbsolute) / noteSnapRatio;
    var targetSteps:Float = Math.fround(gridSteps);
    if (currentScrollEase > scrollPositionInPixels) targetSteps = Math.fceil(gridSteps - 0.001);
    else if (currentScrollEase < scrollPositionInPixels) targetSteps = Math.ffloor(gridSteps + 0.001);
    currentScrollEase += ChartEditorTimeScale.stepToPixels(targetSteps * noteSnapRatio) - playheadAbsolute;
  }

  /**
   * Snap a move to the nearest grid step, based on the current note snap ratio.
   * @param fromPixels The absolute position of the playhead in the song, in pixels.
   * @param amountPixels How far the move goes, in pixels.
   * @return The absolute position to land on, in pixels.
   */
  function snapStepMove(fromPixels:Float, amountPixels:Float):Float
  {
    // Snapped in steps rather than pixels, since with constant scroll the two don't line up.
    var amountSteps:Float = amountPixels / ChartEditorTimeScale.currentStepPixels();
    var gridSteps:Float = Math.min(noteSnapRatio, Math.abs(amountSteps));
    if (gridSteps <= 0) return fromPixels + amountPixels;
    var targetStep:Float = Math.fround((ChartEditorTimeScale.pixelsToStep(fromPixels) + amountSteps) / gridSteps) * gridSteps;
    return ChartEditorTimeScale.stepToPixels(targetStep);
  }

  /**
   * Handle changing the note snapping level.
   */
  function handleSnap():Void
  {
    if (currentLiveInputStyle != WASDKeys)
    {
      if (FlxG.keys.justPressed.LEFT && !pressingControl())
      {
        noteSnapQuantIndex--;
        if (noteSnapQuantIndex < 0) noteSnapQuantIndex = SNAP_QUANTS.length - 1;
      }

      if (FlxG.keys.justPressed.RIGHT && !pressingControl())
      {
        noteSnapQuantIndex++;
        if (noteSnapQuantIndex >= SNAP_QUANTS.length) noteSnapQuantIndex = 0;
      }
    }

    if (FlxG.keys.justPressed.LBRACKET)
    {
      noteSnapQuantIndex--;
      if (noteSnapQuantIndex < 0) noteSnapQuantIndex = SNAP_QUANTS.length - 1;
    }
    if (FlxG.keys.justPressed.RBRACKET)
    {
      noteSnapQuantIndex++;
      if (noteSnapQuantIndex >= SNAP_QUANTS.length) noteSnapQuantIndex = 0;
    }
  }

  /**
   * Handle display of the mouse cursor.
   */
  function handleCursor():Void
  {
    if (gridGhostNote != null) gridGhostNote.visible = false;
    if (gridGhostHoldNote != null) gridGhostHoldNote.visible = false;
    if (gridGhostEvent != null) gridGhostEvent.visible = false;
    if (gridCursorLine != null) gridCursorLine.visible = false;

    // Mouse sounds
    if (FlxG.mouse.justPressed) FunkinSound.playOnce(Paths.sound('ui/editors/chart-editor/charting-sounds/click-down').toString());
    if (FlxG.mouse.justReleased) FunkinSound.playOnce(Paths.sound('ui/editors/chart-editor/charting-sounds/click-up').toString());

    if (playbarHeadDragging) Screen.instance.setCursor('grabbing');

    // Note: If a menu is open in HaxeUI, don't handle cursor behavior.
    var shouldHandleCursor:Bool =
      !(isHaxeUIFocused || playbarHeadDragging || isHaxeUIDialogOpen || DragManager.instance.isDragging)
      || (selectionBoxStartPos != null)
      || (dragTargetNote != null || dragTargetEvent != null);

    var eventColumn:Int = (STRUMLINE_SIZE * 2 + 1) - 1;

    // TODO: TBH some of this should be using FlxMouseEventManager...

    // early return if we shouldn't handle the cursor at all
    if (!shouldHandleCursor)
    {
      // Do not set Cursor.cursorMode here, because it will be set by the HaxeUI.
      return;
    }

    // Over the course of this big conditional block,
    // we determine what the cursor should look like,
    // and fall back to the default cursor if none of the conditions are met.
    var targetCursorMode:Null<CursorMode> = null;

    if (gridTiledSprite == null) throw 'ERROR: Tried to handle cursor, but gridTiledSprite is null! Check ChartEditorState.buildGrid()';

    var overlapsGrid:Bool = FlxG.mouse.overlaps(gridTiledSprite);

    var overlapsRenderedNotes:Bool = true;
    var overlapsRenderedEvents:Bool = true;
    var overlapsRenderedHoldNotes:Bool = true;

    var overlapsRenderedPins:Bool = FlxG.mouse.overlaps(renderedPins);

    var highlightedNote:Null<ChartEditorNoteSprite> = null;
    var highlightedEvent:Null<ChartEditorEventSprite> = null;
    var highlightedHoldNote:Null<ChartEditorHoldNoteSprite> = null;

    // Find the first note that is at the cursor position.
    if (overlapsGrid && FlxG.mouse.overlaps(renderedNotes))
    {
      highlightedNote = renderedNotes.members.find(function(note:ChartEditorNoteSprite):Bool
      {
        // If note.alive is false, the note is dead and awaiting recycling.
        return note.alive && FlxG.mouse.overlaps(note);
      });
    }

    if (highlightedNote == null)
    {
      // Cursor is not overlapping an note
      overlapsRenderedNotes = false;
    }

    // Find the first event that is at the cursor position.
    // Skip this if we're already highlighting a note.
    if (overlapsGrid && !overlapsRenderedNotes && FlxG.mouse.overlaps(renderedEvents))
    {
      var newOverlappingEvents:Array<ChartEditorEventSprite> = renderedEvents.members.filter(function(event:ChartEditorEventSprite):Bool
      {
        return event.alive && FlxG.mouse.overlaps(event);
      });

      if (newOverlappingEvents.length > 0)
      {
        newOverlappingEvents.sort(function(a:ChartEditorEventSprite, b:ChartEditorEventSprite):Int
        {
          return currentSongChartEventData.indexOf(a.eventData) - currentSongChartEventData.indexOf(b.eventData);
        });

        var eventsChanged:Bool = currentOverlappingEvents.length != newOverlappingEvents.length;
        if (!eventsChanged)
        {
          for (i in 0...newOverlappingEvents.length)
          {
            if (newOverlappingEvents[i] != currentOverlappingEvents[i])
            {
              eventsChanged = true;
              break;
            }
          }
        }

        if (eventsChanged)
        {
          currentOverlappingEvents = newOverlappingEvents;
          currentOverlappingEventCycleIndex = 0;

          for (i in 0...currentOverlappingEvents.length)
          {
            if (isEventSelected(currentOverlappingEvents[i].eventData))
            {
              currentOverlappingEventCycleIndex = i;
              break;
            }
          }
        }

        highlightedEvent = currentOverlappingEvents[currentOverlappingEventCycleIndex];
      }
      else
      {
        currentOverlappingEvents = [];
        currentOverlappingEventCycleIndex = 0;
      }
    }
    else
    {
      currentOverlappingEvents = [];
      currentOverlappingEventCycleIndex = 0;
    }

    if (highlightedEvent == null)
    {
      // Cursor is not overlapping an event
      overlapsRenderedEvents = false;
    }

    // Find the first hold note that is at the cursor position.
    // Skip this if we're already highlighting a note or event.
    if (overlapsGrid && !(overlapsRenderedNotes || overlapsRenderedEvents) && FlxG.mouse.overlaps(renderedHoldNotes))
    {
      if (overlapsGrid) highlightedHoldNote = renderedHoldNotes.members.find(function(holdNote:ChartEditorHoldNoteSprite):Bool
      {
        // If holdNote.alive is false, the holdNote is dead and awaiting recycling.
        return holdNote.alive && FlxG.mouse.overlaps(holdNote);
      });
    }

    if (highlightedHoldNote == null)
    {
      // Cursor is not overlapping a hold note
      overlapsRenderedHoldNotes = false;
    }

    // Cursor position relative to the grid.
    var cursorX:Float = FlxG.mouse.viewX - gridTiledSprite.x;
    var cursorY:Float = FlxG.mouse.viewY - gridTiledSprite.y;

    var overlapsSelection:Bool = false;

    var highlightedSelectionSquare:Null<ChartEditorSelectionSquareSprite> = null;

    if (overlapsGrid) highlightedSelectionSquare = renderedSelectionSquares.members.find(function(selectionSquare:ChartEditorSelectionSquareSprite):Bool
    {
      return selectionSquare.alive && FlxG.mouse.overlaps(selectionSquare);
    });

    if (highlightedSelectionSquare != null)
    {
      overlapsSelection = true;
    }

    var overlapsHealthIcons:Bool = FlxG.mouse.overlaps(healthIconBF) || FlxG.mouse.overlaps(healthIconDad);

    if (FlxG.mouse.justPressedMiddle)
    {
      if (scrollAnchorScreenPos == null)
      {
        scrollAnchorScreenPos = FlxPoint.get(FlxG.mouse.x, FlxG.mouse.y);
        selectionBoxStartPos = null;
      }
      else
      {
        releaseScrollAnchor();
        Screen.instance.setCursor('default');
      }
    }

    if (FlxG.mouse.justPressedRight)
    {
      if (gridPlayhead != null && FlxG.mouse.overlaps(gridPlayhead) && !isCursorOverHaxeUI)
      {
        var playheadPosMs:Float = scrollPositionInMs + playheadPositionInMs;

        // Add a new comment at the grid playhead's position.
        performCommand(new AddCommentCommand({
          time: playheadPosMs,
          text: 'New Comment',
          color: commentColorToPlace,
        }));
        this.success('New Comment', 'Added a comment at the playhead position.');
      }
    }

    // An odd way to fix this since measureTicks contains more than just the gray sidebar now.
    var gridPlayheadScrollArea:FlxRect = FlxRect.weak(measureTicks?.x ?? -100, GRID_INITIAL_Y_POS, GRID_SIZE, FlxG.height - PLAYBAR_HEIGHT - GRID_INITIAL_Y_POS);

    if (FlxG.mouse.justPressed)
    {
      if (scrollAnchorScreenPos != null)
      {
        releaseScrollAnchor();
        Screen.instance.setCursor('default');
      }
      else
      {
        if (!FlxG.keys.pressed.SHIFT)
        {
          // Dragging playhead
          if (measureTicks != null && gridPlayheadScrollArea.containsXY(FlxG.mouse.viewX, FlxG.mouse.viewY) && !isCursorOverHaxeUI)
          {
            gridPlayheadScrollAreaPressed = true;
            if ((audioInstTrack != null && audioInstTrack.isPlaying) || audioVocalTrackGroup.playing)
            {
              playbarHeadDraggingWasPlaying = true;
              stopAudioPlayback();
            }
          }
          else if (notePreview != null && FlxG.mouse.overlaps(notePreview) && !isCursorOverHaxeUI)
          {
            // Clicked note preview
            notePreviewScrollAreaStartPos = FlxPoint.get(FlxG.mouse.viewX, FlxG.mouse.viewY);
          }
        }
        else if (!isCursorOverHaxeUI && FlxG.keys.pressed.SHIFT)
        {
          trace('Started selection box at (${FlxG.mouse.viewX}, ${FlxG.mouse.viewY})');
          selectionBoxStartPos = FlxPoint.get(FlxG.mouse.viewX, FlxG.mouse.viewY);
          // Drawing selection box.
          targetCursorMode = Crosshair;
        }
      }
    }

    if (gridPlayheadScrollAreaPressed && FlxG.mouse.released)
    {
      gridPlayheadScrollAreaPressed = false;
      // If we were dragging the playhead while the song was playing, resume playing.
      if (playbarHeadDraggingWasPlaying)
      {
        playbarHeadDraggingWasPlaying = false;
        startAudioPlayback();
      }
    }

    if (notePreviewScrollAreaStartPos != null && FlxG.mouse.released)
    {
      notePreviewScrollAreaStartPos.put();
      notePreviewScrollAreaStartPos = null;
      notePreviewPlayHeadDragging = false;

      if (playbarHeadDraggingWasPlaying)
      {
        playbarHeadDraggingWasPlaying = false;
        startAudioPlayback();
      }
    }

    if (gridPlayheadScrollAreaPressed)
    {
      // Clicked on the playhead scroll area.
      // Move the playhead to the cursor position.
      this.playheadPositionInPixels = FlxG.mouse.viewY - (GRID_INITIAL_Y_POS);
      moveSongToScrollPosition();

      // Cursor should be a grabby hand.
      if (targetCursorMode == null) targetCursorMode = Grabbing;
    }

    // The song position of the cursor, in steps.
    var cursorFractionalStep:Float = ChartEditorTimeScale.pixelsToStep(cursorY);
    var cursorMs:Float = Conductor.instance.getStepTimeInMs(cursorFractionalStep);
    // Round the cursor step to the nearest snap quant.
    var cursorSnappedStep:Float = Math.max(0, Math.fround(cursorFractionalStep / noteSnapRatio) * noteSnapRatio);
    cursorSnappedStep = Math.min(cursorSnappedStep, lastSnappedGridStep);
    var cursorSnappedMs:Float = Conductor.instance.getStepTimeInMs(cursorSnappedStep);

    // A line across the grid at the snap the cursor would place on.
    var draggedStep:Null<Float> = null;
    if (dragTargetNote?.noteData != null) draggedStep = dragTargetNote.noteData.getStepTime();
    else if (dragTargetEvent?.eventData != null) draggedStep = dragTargetEvent.eventData.getStepTime();

    if (showCursorLine && gridCursorLine != null && (draggedStep != null || (overlapsGrid && !isCursorOverHaxeUI)))
    {
      var lineStep:Float = (draggedStep != null) ? (draggedStep + dragTargetCurrentStep).clamp(0, lastSnappedGridStep) : cursorSnappedStep;
      gridCursorLine.visible = true;
      gridCursorLine.x = gridTiledSprite.x;
      gridCursorLine.y = Math.round(gridTiledSprite.y + ChartEditorTimeScale.stepToPixels(lineStep)) - Std.int(gridCursorLine.height / 2);
    }

    // The direction value for the column at the cursor.
    var cursorGridPos:Int = Math.floor(cursorX / GRID_SIZE);
    var cursorColumn:Int = ChartEditorNoteUtil.gridColumnToNoteData(cursorGridPos);

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
          var cursorFractionalStepStart:Float = ChartEditorTimeScale.pixelsToStep(cursorYStart);
          var cursorStepStart:Int = Math.floor(cursorFractionalStepStart);
          var cursorMsStart:Float = Conductor.instance.getStepTimeInMs(cursorStepStart);
          var cursorColumnBase:Int = Math.floor(cursorX / GRID_SIZE);
          var cursorColumnBaseStart:Int = Math.floor(cursorXStart / GRID_SIZE);

          // Since this selects based on noteData directly,
          // we don't need to specifically exclude sustain pieces.

          // This logic is gross because the columns go 4567-0123-8.
          // We build a list of columns to select.
          var columnStart:Int = Std.int(Math.min(cursorColumnBase, cursorColumnBaseStart));
          var columnEnd:Int = Std.int(Math.max(cursorColumnBase, cursorColumnBaseStart));
          var columns:Array<Int> = [for (i in columnStart...(columnEnd + 1)) i].map(function(i:Int):Int
          {
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
              // Minimum of -1.
              return -1;
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
              if (pressingControl())
              {
                // Add to the selection.
                performCommand(new SelectItemsCommand(notesToSelect, eventsToSelect));
              }
              else
              {
                // Set the selection.
                performCommand(new SetItemSelectionCommand(notesToSelect, eventsToSelect));
              }
            }
            else
            {
              // We made a selection box, but it didn't select anything.

              if (!pressingControl())
              {
                // Deselect all items.
                var shouldDeselect:Bool = !wasCursorOverHaxeUI && (currentNoteSelection.length > 0 || currentEventSelection.length > 0);
                if (shouldDeselect)
                {
                  performCommand(new DeselectAllItemsCommand());
                }
              }
            }
          }
          else
          {
            // We made a selection box, but it didn't select any columns.
          }

          // Clear the selection box.
          selectionBoxStartPos.put();
          selectionBoxStartPos = null;
          setSelectionBoxBounds();
        }
        else
        {
          // Clicking and dragging.
          scrollMouseToGrid();

          // Scroll the screen if the mouse is above or below the grid.
          if (FlxG.mouse.viewY < MENU_BAR_HEIGHT)
          {
            // Scroll up.
            var diff:Float = MENU_BAR_HEIGHT - FlxG.mouse.viewY;
            currentScrollEase -= diff * 0.5; // Too fast!
          }
          else if (FlxG.mouse.viewY > (playbarHeadLayout?.y ?? 0.0))
          {
            // Scroll down.
            var diff:Float = FlxG.mouse.viewY - (playbarHeadLayout?.y ?? 0.0);
            currentScrollEase += (diff * 0.5); // Too fast!
          }

          // Render the selection box, and keep the rendered graphic clamped to the size of the screen
          var selectionRect:FlxRect = FlxRect.weak();
          selectionRect.x = Math.min(FlxG.mouse.viewX, selectionBoxStartPos.x);
          selectionRect.y = Math.min(Math.max(0, selectionBoxStartPos.y), FlxG.mouse.viewY);
          selectionRect.width = Math.abs(FlxG.mouse.viewX - selectionBoxStartPos.x);
          selectionRect.height = Math.abs(FlxG.mouse.viewY - Math.max(Math.min(FlxG.height, selectionBoxStartPos.y), 0));
          setSelectionBoxBounds(selectionRect);

          targetCursorMode = Crosshair;
        }
      }
      else if (FlxG.mouse.justReleased)
      {
        // Clear the selection box.
        selectionBoxStartPos.put();
        selectionBoxStartPos = null;
        setSelectionBoxBounds();

        if (overlapsGrid)
        {
          // We clicked on the grid without moving the mouse.

          if (pressingControl())
          {
            if (highlightedNote != null && highlightedNote.noteData != null)
            {
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
            else if (highlightedHoldNote != null && highlightedHoldNote.noteData != null)
            {
              // Control click to select/deselect an individual note.
              if (isNoteSelected(highlightedHoldNote.noteData))
              {
                performCommand(new DeselectItemsCommand([highlightedHoldNote.noteData], []));
              }
              else
              {
                performCommand(new SelectItemsCommand([highlightedHoldNote.noteData], []));
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
              performCommand(new SetItemSelectionCommand([highlightedNote.noteData], []));
            }
            else if (highlightedEvent != null && highlightedEvent.eventData != null)
            {
              // Click an event to select it.
              performCommand(new SetItemSelectionCommand([], [highlightedEvent.eventData]));
            }
            else if (highlightedHoldNote != null && highlightedHoldNote.noteData != null)
            {
              // Click a hold note to select it.
              performCommand(new SetItemSelectionCommand([highlightedHoldNote.noteData], []));
            }
            else
            {
              // Click on an empty space to deselect everything.
              var shouldDeselect:Bool = !wasCursorOverHaxeUI && (currentNoteSelection.length > 0 || currentEventSelection.length > 0);
              if (shouldDeselect)
              {
                performCommand(new DeselectAllItemsCommand());
              }
            }
          }
        }
        else
        {
          // If we clicked and released outside the grid.

          if (!pressingControl())
          {
            // Deselect all items.
            var shouldDeselect:Bool = !wasCursorOverHaxeUI && (currentNoteSelection.length > 0 || currentEventSelection.length > 0);
            if (shouldDeselect)
            {
              performCommand(new DeselectAllItemsCommand());
            }
          }
        }
      }
    }
    else if (notePreviewScrollAreaStartPos != null)
    {
      notePreviewPlayHeadDragging = true;
      // Stop audio playback while dragging on the note preview playhead.
      if ((audioInstTrack != null && audioInstTrack.isPlaying) || audioVocalTrackGroup.playing)
      {
        playbarHeadDraggingWasPlaying = true;
        stopAudioPlayback();
      }

      // Player is clicking and holding on note preview to scrub around.
      targetCursorMode = Grabbing;

      var clickedPosInPixels:Float = FlxMath.remapToRange(
        FlxG.mouse.viewY,
        (notePreview?.y ?? 0.0),
        (notePreview?.y ?? 0.0) + (notePreview?.height ?? 0.0),
        0,
        songLengthInPixels
      );

      currentScrollEase = clickedPosInPixels;
      easeSongToScrollPosition(currentScrollEase);
    }
    else if (scrollAnchorScreenPos != null)
    {
      // Cursor should be a scroll anchor.
      targetCursorMode = Scroll;
      Screen.instance.setCursor('scroll');
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
          dragDistanceMs = Conductor.instance.getStepTimeInMs(dragTargetNote.noteData.getStepTime() + dragDistanceSteps) - dragTargetNote.noteData.time;
        }
        else if (dragTargetEvent != null && dragTargetEvent.eventData != null)
        {
          dragDistanceMs = Conductor.instance.getStepTimeInMs(dragTargetEvent.eventData.getStepTime() + dragDistanceSteps) - dragTargetEvent.eventData.time;
        }
        var dragDistanceColumns:Int = dragTargetCurrentColumn;

        if (dragTargetCurrentStep == 0 && dragTargetCurrentColumn == 0)
        {
          // There's no need to move anything.
          // Also prevents the selection boxes on notes from disappearing when they're 'moved' like this.

          if (dragTargetEvent != null && currentOverlappingEvents.length > 1 && dragEventWasSelected)
          {
            var nextIndex:Int = (currentOverlappingEventCycleIndex + 1) % currentOverlappingEvents.length;
            highlightedEvent = currentOverlappingEvents[nextIndex];
            performCommand(new SetItemSelectionCommand([], [highlightedEvent.eventData]));
          }

          dragTargetNote = null;
          dragTargetEvent = null;
          dragTargetCurrentStep = 0;
          dragTargetCurrentColumn = 0;
          return;
        }

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

        scrollMouseToGrid();

        // calculate distance between the position dragged to and the original position.
        var dragDistanceSteps:Float =
          Conductor.instance.getTimeInSteps(cursorSnappedMs).clamp(0, lastSnappedGridStep)
          - dragStartCursorStep;

        var selectionEndStep:Float = 0;
        for (note in currentNoteSelection)
        {
          selectionEndStep = Math.max(selectionEndStep, note.getStepTime() + note.getStepLength() + 1);
        }
        for (event in currentEventSelection)
        {
          selectionEndStep = Math.max(selectionEndStep, event.getStepTime() + 1);
        }

        var maxDragDistanceSteps:Float = Math.max(Math.floor((gridLengthInSteps - selectionEndStep) / noteSnapRatio) * noteSnapRatio, 0);
        if (dragDistanceSteps > maxDragDistanceSteps) dragDistanceSteps = maxDragDistanceSteps;

        var dragDistanceColumns:Int = cursorGridPos - dragStartCursorColumn;

        if ((dragTargetCurrentColumn != dragDistanceColumns && overlapsGrid) || dragTargetCurrentStep != dragDistanceSteps)
        {
          // Play a sound as we drag.
          this.playSound(Paths.sound('ui/editors/chart-editor/charting-sounds/note-place').toString());

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
      var dragLengthSteps:Float = Conductor.instance.getTimeInSteps(cursorSnappedMs) - stepTime;
      var dragLengthMs:Float = dragLengthSteps * Conductor.instance.stepLengthMs;
      var dragLengthPixels:Float = ChartEditorTimeScale.lengthToPixels(currentPlaceNoteData.time, cursorSnappedMs - currentPlaceNoteData.time, dragLengthSteps);

      if (gridGhostHoldNote != null)
      {
        if (dragLengthSteps > 0)
        {
          if (dragLengthCurrent != dragLengthSteps)
          {
            this.playStretchySound();

            dragLengthCurrent = dragLengthSteps;
          }

          var sameHold:Bool = (gridGhostHoldNote.noteData == currentPlaceNoteData);

          gridGhostHoldNote.visible = true;
          gridGhostHoldNote.noteData = currentPlaceNoteData;
          gridGhostHoldNote.noteDirection = currentPlaceNoteData.getDirection();
          gridGhostHoldNote.setHeightDirectly(dragLengthPixels, sameHold);
          gridGhostHoldNote.noteStyle = NoteKindManager.getNoteStyleId(currentPlaceNoteData.kind, currentSongNoteStyle) ?? currentSongNoteStyle;
          gridGhostHoldNote.updateHoldNotePosition(renderedHoldNotes);
          gridGhostHoldNote.updateHoldNoteGraphic();
        }
        else
        {
          gridGhostHoldNote.setHeightDirectly(0);
        }
      }

      if (FlxG.mouse.justReleased)
      {
        if (dragLengthSteps > 0)
        {
          this.playSound(Paths.sound('ui/editors/chart-editor/charting-sounds/stretch-snap').toString());
          // Apply the new length.
          performCommand(new ExtendNoteLengthCommand(currentPlaceNoteData, dragLengthMs));
        }
        else
        {
          // Apply the new (zero) length if we are changing the length.
          if (currentPlaceNoteData.length > 0)
          {
            this.playSound(Paths.sound('ui/editors/chart-editor/charting-sounds/stretch-snap').toString());
            performCommand(new ExtendNoteLengthCommand(currentPlaceNoteData, 0));
          }
        }

        // Finished dragging. Release the note.
        currentPlaceNoteData = null;
        if (gridGhostHoldNote != null) gridGhostHoldNote.noteData = null;
      }
      else
      {
        scrollMouseToGrid(0.2);

        // Cursor should be a grabby hand.
        if (targetCursorMode == null) targetCursorMode = Grabbing;
      }
    }
    else if (overlapsRenderedPins)
    {
      // Cursor should be a pointer.
      targetCursorMode = Pointer;
    }
    else
    {
      if (FlxG.mouse.justPressed && !FlxG.keys.pressed.SHIFT)
      {
        // Just clicked to place a note.
        if (!isCursorOverHaxeUI && overlapsGrid)
        {
          // We clicked on the grid without moving the mouse.

          if (pressingControl())
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
            else if (highlightedHoldNote != null && highlightedHoldNote.noteData != null)
            {
              if (isNoteSelected(highlightedHoldNote.noteData))
              {
                performCommand(new DeselectItemsCommand([highlightedHoldNote.noteData], []));
              }
              else
              {
                performCommand(new SelectItemsCommand([highlightedHoldNote.noteData], []));
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
                dragTargetNote = highlightedNote;
                dragStartCursorStep = Conductor.instance.getTimeInSteps(cursorSnappedMs);
                dragStartCursorColumn = cursorGridPos;
              }
              else
              {
                // If you click an unselected note, and aren't holding Control, deselect everything else.
                performCommand(new SetItemSelectionCommand([highlightedNote.noteData], []));
                dragTargetNote = highlightedNote;
                dragStartCursorStep = Conductor.instance.getTimeInSteps(cursorSnappedMs);
                dragStartCursorColumn = cursorGridPos;
              }
            }
            else if (highlightedEvent != null && highlightedEvent.eventData != null)
            {
              if (isEventSelected(highlightedEvent.eventData))
              {
                // Clicked a selected event, start dragging.
                dragTargetEvent = highlightedEvent;
                dragStartCursorStep = Conductor.instance.getTimeInSteps(cursorSnappedMs);
                dragStartCursorColumn = cursorGridPos;
                dragEventWasSelected = true;
              }
              else
              {
                // If you click an unselected event, and aren't holding Control, deselect everything else.
                performCommand(new SetItemSelectionCommand([], [highlightedEvent.eventData]));
                dragTargetEvent = highlightedEvent;
                dragStartCursorStep = Conductor.instance.getTimeInSteps(cursorSnappedMs);
                dragStartCursorColumn = cursorGridPos;
                dragEventWasSelected = false;
              }
            }
            else if (highlightedHoldNote != null && highlightedHoldNote.noteData != null)
            {
              // Clicked a hold note, start dragging TO EXTEND NOTE LENGTH.
              currentPlaceNoteData = highlightedHoldNote.noteData;
            }
            else
            {
              var shouldDeselect:Bool = !wasCursorOverHaxeUI && (currentNoteSelection.length > 0 || currentEventSelection.length > 0);
              if (shouldDeselect)
              {
                performCommand(new DeselectAllItemsCommand());
              }
              // Click a blank space to place a note and select it.

              if (cursorGridPos == eventColumn)
              {
                // Create an event and place it in the chart.
                // TODO: Figure out configuring event data.
                var newEventData:SongEventData = new SongEventData(cursorSnappedMs, eventKindToPlace, eventDataToPlace.copy());

                performCommand(new AddEventsCommand([newEventData], pressingControl()));
              }
              else
              {
                // Create a note and place it in the chart.
                var newNoteData:SongNoteData = new SongNoteData(
                  cursorSnappedMs,
                  cursorColumn,
                  0,
                  noteKindToPlace,
                  ChartEditorNoteUtil.cloneNoteParams(noteParamsToPlace)
                );

                performCommand(new AddNotesCommand([newNoteData], pressingControl()));

                currentPlaceNoteData = newNoteData;
              }
            }
          }
        }
        else
        {
          // If we clicked and released outside the grid (or on HaxeUI), do nothing.
        }
      }

      var rightMouseUpdated:Bool = (FlxG.mouse.justPressedRight) || (FlxG.mouse.pressedRight && (FlxG.mouse.deltaX > 0 || FlxG.mouse.deltaY > 0));
      if (rightMouseUpdated && overlapsGrid)
      {
        // We right clicked on the grid.

        if (highlightedNote != null && highlightedNote.noteData != null)
        {
          // TODO: Handle the case of clicking on a sustain piece.
          if (FlxG.keys.pressed.SHIFT)
          {
            // Shift + Right click opens the context menu.
            // If we are clicking a large selection, open the Selection context menu, otherwise open the Note context menu.
            var isHighlightedNoteSelected:Bool = isNoteSelected(highlightedNote.noteData);
            var useSingleNoteContextMenu:Bool = (!isHighlightedNoteSelected) || (isHighlightedNoteSelected && currentNoteSelection.length == 1);
            // Show the context menu connected to the note.
            if (useSingleNoteContextMenu)
            {
              // Open the hold note menu instead if the highlighted note has a length value
              if (highlightedNote.noteData.length > 0) this.openHoldNoteContextMenu(FlxG.mouse.viewX, FlxG.mouse.viewY, highlightedNote.noteData);
              else
                this.openNoteContextMenu(FlxG.mouse.viewX, FlxG.mouse.viewY, highlightedNote.noteData);
            }
            else
            {
              this.openSelectionContextMenu(FlxG.mouse.viewX, FlxG.mouse.viewY);
            }
          }
          else
          {
            // Right click removes the note.
            performCommand(new RemoveNotesCommand([highlightedNote.noteData]));
          }
        }
        else if (highlightedEvent != null && highlightedEvent.eventData != null)
        {
          if (FlxG.keys.pressed.SHIFT)
          {
            // Shift + Right click opens the context menu.
            // If we are clicking a large selection, open the Selection context menu, otherwise open the Event context menu.
            var isHighlightedEventSelected:Bool = isEventSelected(highlightedEvent.eventData);
            var useSingleEventContextMenu:Bool = (!isHighlightedEventSelected) || (isHighlightedEventSelected && currentEventSelection.length == 1);
            if (useSingleEventContextMenu)
            {
              this.openEventContextMenu(FlxG.mouse.viewX, FlxG.mouse.viewY, highlightedEvent.eventData);
            }
            else
            {
              this.openSelectionContextMenu(FlxG.mouse.viewX, FlxG.mouse.viewY);
            }
          }
          else
          {
            // Right click removes the event.
            performCommand(new RemoveEventsCommand([highlightedEvent.eventData]));
          }
        }
        else if (highlightedHoldNote != null && highlightedHoldNote.noteData != null)
        {
          if (FlxG.keys.pressed.SHIFT)
          {
            // Shift + Right click opens the context menu.
            // If we are clicking a large selection, open the Selection context menu, otherwise open the Note context menu.
            var isHighlightedNoteSelected:Bool = isNoteSelected(highlightedHoldNote.noteData);
            var useSingleNoteContextMenu:Bool = (!isHighlightedNoteSelected) || (isHighlightedNoteSelected && currentNoteSelection.length == 1);
            // Show the context menu connected to the note.
            if (useSingleNoteContextMenu)
            {
              this.openHoldNoteContextMenu(FlxG.mouse.viewX, FlxG.mouse.viewY, highlightedHoldNote.noteData);
            }
            else
            {
              this.openSelectionContextMenu(FlxG.mouse.viewX, FlxG.mouse.viewY);
            }
          }
          else
          {
            // Right click removes hold from the note.
            this.playSound(Paths.sound('ui/editors/chart-editor/charting-sounds/stretch-snap').toString());
            performCommand(new ExtendNoteLengthCommand(highlightedHoldNote.noteData, 0));
          }
        }
        else
        {
          // Right clicked on nothing.
        }
      }

      var isOrWillSelect =
        overlapsSelection
        || dragTargetNote != null
        || dragTargetEvent != null
        || overlapsRenderedNotes
        || overlapsRenderedHoldNotes
        || overlapsRenderedEvents;
      // Handle grid cursor.
      if (!isCursorOverHaxeUI && overlapsGrid && !isOrWillSelect && !gridPlayheadScrollAreaPressed)
      {
        // Indicate that we can place a note here.

        if (cursorGridPos == eventColumn)
        {
          if (gridGhostEvent == null) throw 'ERROR: Tried to handle cursor, but gridGhostEvent is null! Check ChartEditorState.buildGrid()';

          var eventData:SongEventData = gridGhostEvent.eventData != null ? gridGhostEvent.eventData : new SongEventData(cursorMs, eventKindToPlace, null);

          if (eventKindToPlace != eventData.eventKind)
          {
            eventData.eventKind = eventKindToPlace;
          }
          eventData.time = cursorSnappedMs;

          gridGhostEvent.visible = true;
          gridGhostEvent.eventData = eventData;
          gridGhostEvent.updateEventPosition(renderedEvents);

          targetCursorMode = Cell;
        }
        else
        {
          if (gridGhostNote == null) throw 'ERROR: Tried to handle cursor, but gridGhostNote is null! Check ChartEditorState.buildGrid()';

          var noteData:SongNoteData = gridGhostNote.noteData != null ? gridGhostNote.noteData : new SongNoteData(
            cursorMs,
            cursorColumn,
            0,
            noteKindToPlace,
            ChartEditorNoteUtil.cloneNoteParams(noteParamsToPlace)
          );

          if (cursorColumn != noteData.data || noteKindToPlace != noteData.kind || noteParamsToPlace != noteData.params)
          {
            noteData.kind = noteKindToPlace;
            noteData.params = noteParamsToPlace;
            noteData.data = cursorColumn;
            gridGhostNote.noteStyle = NoteKindManager.getNoteStyleId(noteData.kind, currentSongNoteStyle) ?? currentSongNoteStyle;
            gridGhostNote.playNoteAnimation();
          }
          noteData.time = cursorSnappedMs;

          gridGhostNote.visible = true;
          gridGhostNote.noteData = noteData;
          gridGhostNote.updateNotePosition(renderedNotes);

          targetCursorMode = Cell;
        }
      }
    }

    if (targetCursorMode == null)
    {
      if (activeToolboxes.get(CHART_EDITOR_TOOLBOX_PLAYER_PREVIEW_LAYOUT)?.hitTest(FlxG.mouse.viewX, FlxG.mouse.viewY) == true
        || activeToolboxes.get(CHART_EDITOR_TOOLBOX_OPPONENT_PREVIEW_LAYOUT)?.hitTest(FlxG.mouse.viewX, FlxG.mouse.viewY) == true)
      {
        targetCursorMode = Pointer;
      }
      else if (FlxG.mouse.pressed)
      {
        if (overlapsSelection)
        {
          targetCursorMode = Grabbing;
        }
      }
      else
      {
        if (!isCursorOverHaxeUI)
        {
          if (notePreview != null && FlxG.mouse.overlaps(notePreview))
          {
            targetCursorMode = Pointer;
          }
          else if (measureTicks != null && FlxG.mouse.overlaps(measureTicks))
          {
            targetCursorMode = Pointer;
          }
          else if (overlapsSelection)
          {
            targetCursorMode = Pointer;
          }
          else if (overlapsRenderedNotes)
          {
            targetCursorMode = Pointer;
          }
          else if (overlapsRenderedHoldNotes)
          {
            targetCursorMode = Pointer;
          }
          else if (overlapsRenderedEvents)
          {
            targetCursorMode = Pointer;
          }
          else if (overlapsGrid)
          {
            targetCursorMode = Cell;
          }
          else if (overlapsHealthIcons)
          {
            targetCursorMode = Pointer;
          }
        }
      }
    }

    // Actually set the cursor mode to the one we specified earlier.
    Cursor.cursorMode = targetCursorMode ?? Default;
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

      var variationMetadata:Null<SongMetadata> = songMetadata.get(selectedVariation);
      if (variationMetadata != null) variationMetadata.playData.difficulties.sort(
        SortUtil.defaultsThenAlphabetically.bind(Constants.DEFAULT_DIFFICULTY_LIST_FULL)
      );

      var difficultyToolbox:ChartEditorDifficultyToolbox = cast this.getToolbox(CHART_EDITOR_TOOLBOX_DIFFICULTY_LAYOUT);
      if (difficultyToolbox == null) return;

      difficultyToolbox.updateTree();
    }
  }

  function handlePlayerPreviewToolbox():Void
  {
    // Manage the Select Difficulty tree view.
    var charPreviewToolbox:Null<CollapsibleDialog> = this.getToolboxUnCast(CHART_EDITOR_TOOLBOX_PLAYER_PREVIEW_LAYOUT);
    if (charPreviewToolbox == null) return;
    // TODO: Re-enable the player preview once we figure out the performance issues.
    var charPlayer:Null<CharacterPlayer> = charPreviewToolbox.findComponent('charPlayer');
    if (charPlayer == null) return;
    if (playerPreviewDirty)
    {
      playerPreviewDirty = false;

      if (currentSongMetadata.playData.characters.player != charPlayer.charId)
      {
        if (healthIconBF != null)
        {
          healthIconBF.characterId = currentSongMetadata.playData.characters.player;
        }

        charPlayer.loadCharacter(currentSongMetadata.playData.characters.player);
        charPlayer.characterType = CharacterType.BF;
        charPlayer.flip = true;
        charPlayer.targetScale = 0.5;

        charPreviewToolbox.title = 'Player Preview - ${charPlayer.charName}';
        charPreviewToolbox.invalidateComponentLayout();
      }
    }

    if (charPreviewToolbox != null && !charPreviewToolbox.minimized)
    {
      charPreviewToolbox.width = charPlayer.width + 32;
      charPreviewToolbox.height = charPlayer.height + 64;
    }
    currentPlayerCharacterPlayer = charPlayer;
  }

  function handleOpponentPreviewToolbox():Void
  {
    // Manage the Select Difficulty tree view.
    var charPreviewToolbox:Null<CollapsibleDialog> = this.getToolboxUnCast(CHART_EDITOR_TOOLBOX_OPPONENT_PREVIEW_LAYOUT);
    if (charPreviewToolbox == null) return;

    // TODO: Re-enable the player preview once we figure out the performance issues.
    var charPlayer:Null<CharacterPlayer> = charPreviewToolbox.findComponent('charOpponent');
    if (charPlayer == null) return;

    if (opponentPreviewDirty)
    {
      opponentPreviewDirty = false;

      if (currentSongMetadata.playData.characters.opponent != charPlayer.charId)
      {
        if (healthIconDad != null)
        {
          healthIconDad.characterId = currentSongMetadata.playData.characters.opponent;
        }

        charPlayer.loadCharacter(currentSongMetadata.playData.characters.opponent);
        charPlayer.characterType = CharacterType.DAD;
        charPlayer.flip = false;
        charPlayer.targetScale = 0.5;

        charPreviewToolbox.title = 'Opponent Preview - ${charPlayer.charName}';
        charPreviewToolbox.invalidateComponentLayout();
      }
    }

    if (charPreviewToolbox != null && !charPreviewToolbox.minimized)
    {
      charPreviewToolbox.width = charPlayer.width + 32;
      charPreviewToolbox.height = charPlayer.height + 64;
    }
    currentOpponentCharacterPlayer = charPlayer;
  }

  function handleSelectionButtons():Void
  {
    // Make sure buttons are never nudged out of the correct spot.
    // TODO: Why do these even move in the first place? The camera never moves, LOL.
    buttonSelectOpponent.y = NOTE_SELECT_BUTTON_Y - 2;
    buttonSelectPlayer.y = NOTE_SELECT_BUTTON_Y - 2;
    buttonSelectEvent.y = NOTE_SELECT_BUTTON_Y - 2;
  }

  /**
   * Handles display elements for the playbar at the bottom.
   */
  function handlePlaybar():Void
  {
    if (playbarHeadLayout == null) throw 'ERROR: Tried to handle playbar, but playbarHeadLayout is null!';

    if (Conductor.instance == null || playbarSongRemaining == null) return;

    // Move the playhead to match the song position, if we aren't dragging it.
    playbarHeadLayout.playbarHead.pos = currentScrollEase;

    playbarHeadLayout.playbarHead.max = songLengthInPixels * (FlxG.width - 4) / (FlxG.width - 8);
    @:privateAccess playbarHeadLayout.playbarHead.findComponent('range', Range).virtualStart = -4 * songLengthInPixels / (FlxG.width - 8);

    // Make sure the playbar is never nudged out of the correct spot.
    playbarHeadLayout.x = 0;
    playbarHeadLayout.y = FlxG.height - 48 - 8;

    var songPos:Float = ChartEditorTimeScale.pixelsToMs(currentScrollEase + playheadPositionInPixels);
    var songStepTime:Float = Conductor.instance.getTimeInSteps(songPos - Conductor.instance.instrumentalOffset);
    var songPosMilliseconds:String = Std.string(Math.floor(Math.abs(songPos) % Constants.MS_PER_SEC)).lpad('0', 3).substr(0, 2);
    var songPosSeconds:String = Std.string(Math.floor((Math.abs(songPos) / Constants.MS_PER_SEC) % Constants.SECS_PER_MIN)).lpad('0', 2);
    var songPosMinutes:String = Std.string(Math.floor((Math.abs(songPos) / Constants.MS_PER_SEC) / Constants.SECS_PER_MIN)).lpad('0', 2);
    if (songPos < 0) songPosMinutes = '-' + songPosMinutes;
    var songPosString:String = '${songPosMinutes}:${songPosSeconds}.${songPosMilliseconds}';

    if (playbarSongPos.value != songPosString) playbarSongPos.value = songPosString;

    var songRemaining:Float = Math.max(songLengthInMs - songPos, 0.0);
    var songRemainingMilliseconds:String = Std.string(Math.floor(Math.abs(songRemaining) % Constants.MS_PER_SEC)).lpad('0', 3).substr(0, 2);
    var songRemainingSeconds:String = Std.string(Math.floor((songRemaining / Constants.MS_PER_SEC) % Constants.SECS_PER_MIN)).lpad('0', 2);
    var songRemainingMinutes:String = Std.string(Math.floor((songRemaining / Constants.MS_PER_SEC) / Constants.SECS_PER_MIN)).lpad('0', 2);
    var songRemainingString:String = '-${songRemainingMinutes}:${songRemainingSeconds}.${songRemainingMilliseconds}';

    if (playbarSongRemaining.value != songRemainingString) playbarSongRemaining.value = songRemainingString;

    playbarBeatNum.text = 'Beat: ${FlxStringUtil.formatMoney(songStepTime / Constants.STEPS_PER_BEAT)}';
    playbarStepNum.text = 'Step: ${Math.floor(songStepTime)}';

    playbarNoteSnap.text = '1/${noteSnapQuant}';
    playbarZoom.text = '${ZOOM_LEVELS[zoomLevelIndex]}x';
    var difftext:String = '${selectedDifficulty.toTitleCase()}${selectedVariation == Constants.DEFAULT_VARIATION ? '' : ' (${selectedVariation.toTitleCase()})'}';
    if (difftext.length > 20) difftext = difftext.substring(0, 19) + '...';
    playbarDifficulty.text = difftext;
    playbarBPM.text = 'BPM: ${(Conductor.instance.bpm ?? 0.0)}${Conductor.instance.timeSignatureNumerator != Constants.DEFAULT_TIME_SIGNATURE_NUM
        || Conductor.instance.timeSignatureDenominator != Constants.DEFAULT_TIME_SIGNATURE_DEN ? ' (${Conductor.instance.timeSignatureNumerator}/${Conductor.instance.timeSignatureDenominator})' : ''}';
  }

  function handlePlayhead():Void
  {
    // Place notes at the playhead with the keyboard.
    for (note => key in LIVE_INPUT_KEYS[currentLiveInputStyle])
    {
      if (FlxG.keys.checkStatus(key, JUST_PRESSED)) placeNoteAtPlayhead(note)
      else if (FlxG.keys.checkStatus(key, JUST_RELEASED)) finishPlaceNoteAtPlayhead(note);
    }

    // Place events at playhead.
    if (FlxG.keys.justPressed.COMMA) placeEventAtPlayhead(true);
    if (FlxG.keys.justPressed.PERIOD) placeEventAtPlayhead(false);

    updatePlayheadGhostHoldNotes();
  }

  function placeNoteAtPlayhead(column:Int):Void
  {
    // SHIFT + press or LEFT_SHOULDER + press to remove notes instead of placing them.
    var removeNoteInstead:Bool = FlxG.keys.pressed.SHIFT || (FlxG.gamepads.firstActive?.pressed?.LEFT_SHOULDER ?? false);

    var playheadFractionalStep:Float = ChartEditorTimeScale.pixelsToStep(scrollPositionInPixels + playheadPositionInPixels);
    // Notes are centered on their line, so the nearest snap is the one the playhead is over.
    var playheadSnappedStep:Float = Math.fround(playheadFractionalStep / noteSnapRatio) * noteSnapRatio;
    playheadSnappedStep = Math.min(playheadSnappedStep, lastSnappedGridStep);
    var playheadSnappedMs:Float = Conductor.instance.getStepTimeInMs(playheadSnappedStep);

    // Look for notes within half a snap of the playhead, since placing rounds to the nearest snap.
    var halfSnapMs:Float = Conductor.instance.getTypeLengthAtMs(playheadSnappedMs, 'step') * noteSnapRatio / 2;
    var notesAtPos:Array<SongNoteData> = SongDataUtils.getNotesInTimeRange(currentSongChartNoteData, playheadSnappedMs - halfSnapMs, playheadSnappedMs + halfSnapMs);
    notesAtPos = SongDataUtils.getNotesWithData(notesAtPos, [column]);

    if (notesAtPos.length > 0)
    {
      trace('Removing existing note at position. ${column}');
      performCommand(new RemoveNotesCommand(notesAtPos));
    }
    else if (!removeNoteInstead)
    {
      trace('Placing note. ${column}');
      var newNoteData:SongNoteData = new SongNoteData(playheadSnappedMs, column, 0, noteKindToPlace, ChartEditorNoteUtil.cloneNoteParams(noteParamsToPlace));
      performCommand(new AddNotesCommand([newNoteData], pressingControl()));
      currentLiveInputPlaceNoteData[column] = newNoteData;
    }
  }

  function placeEventAtPlayhead(isOpponent:Bool):Void
  {
    // SHIFT + press or LEFT_SHOULDER + press to remove events instead of placing them.
    var removeEventInstead:Bool = FlxG.keys.pressed.SHIFT || (FlxG.gamepads.firstActive?.pressed?.LEFT_SHOULDER ?? false);

    var playheadFractionalStep:Float = ChartEditorTimeScale.pixelsToStep(scrollPositionInPixels + playheadPositionInPixels);
    var playheadSnappedStep:Float = Math.fround(playheadFractionalStep / noteSnapRatio) * noteSnapRatio;
    playheadSnappedStep = Math.min(playheadSnappedStep, lastSnappedGridStep);
    var playheadSnappedMs:Float = Conductor.instance.getStepTimeInMs(playheadSnappedStep);

    // Look for events within 1 step of the playhead.
    var eventsAtPos:Array<SongEventData> = SongDataUtils.getEventsInTimeRange(
      currentSongChartEventData,
      playheadSnappedMs,
      playheadSnappedMs + Conductor.instance.getTypeLengthAtMs(playheadSnappedMs, 'step') * noteSnapRatio
    );
    eventsAtPos = SongDataUtils.getEventsWithKind(eventsAtPos, ['FocusCamera']);

    if (eventsAtPos.length == 0 && !removeEventInstead)
    {
      trace('Placing event ${isOpponent}');
      var newEventData:SongEventData = new SongEventData(playheadSnappedMs, 'FocusCamera', {
        char: isOpponent ? 1 : 0,
      });
      performCommand(new AddEventsCommand([newEventData], pressingControl()));
    }
    else if (removeEventInstead)
    {
      trace('Removing existing event at position.');
      performCommand(new RemoveEventsCommand(eventsAtPos));
    }
    else
    {
      trace('Already an event there.');
    }
  }

  function updatePlayheadGhostHoldNotes():Void
  {
    // Ensure all the ghost hold notes exist.
    while (gridPlayheadGhostHoldNotes.length < (STRUMLINE_SIZE * 2))
    {
      var ghost = new ChartEditorHoldNoteSprite(this);
      ghost.alpha = 0.6;
      ghost.noteData = null;
      ghost.visible = false;
      ghost.zIndex = 21;
      add(ghost); // Don't add to `renderedHoldNotes` because then it will get killed every frame.

      gridPlayheadGhostHoldNotes.push(ghost);
      refresh();
    }

    // Update playhead ghost hold notes.
    for (column in 0...gridPlayheadGhostHoldNotes.length)
    {
      var targetNoteData = currentLiveInputPlaceNoteData[column];
      var ghostHold = gridPlayheadGhostHoldNotes[column];

      if (targetNoteData == null && ghostHold.noteData != null)
      {
        // Remove the ghost hold note.
        ghostHold.noteData = null;
      }

      if (targetNoteData != null && ghostHold.noteData == null)
      {
        // Readd the new ghost hold note.
        ghostHold.noteData = targetNoteData.clone();
        ghostHold.noteDirection = ghostHold.noteData.getDirection();
        ghostHold.visible = true;
        ghostHold.alpha = 0.6;
        ghostHold.setHeightDirectly(0);
        ghostHold.noteStyle = NoteKindManager.getNoteStyleId(ghostHold.noteData.kind, currentSongNoteStyle) ?? currentSongNoteStyle;
        ghostHold.updateHoldNotePosition(renderedHoldNotes);
      }

      if (ghostHold.noteData == null)
      {
        ghostHold.visible = false;
        ghostHold.setHeightDirectly(0);
        playheadDragLengthCurrent[column] = 0;
        continue;
      }

      var playheadFractionalStep:Float = ChartEditorTimeScale.pixelsToStep(scrollPositionInPixels + playheadPositionInPixels);
      var playheadSnappedStep:Float = Math.fround(playheadFractionalStep / noteSnapRatio) * noteSnapRatio;
      playheadSnappedStep = Math.min(playheadSnappedStep, lastSnappedGridStep);
      var playheadSnappedMs:Float = Conductor.instance.getStepTimeInMs(playheadSnappedStep);

      var newNoteLength:Float = playheadSnappedMs - ghostHold.noteData.time;
      trace('newNoteLength: ${newNoteLength}');

      if (newNoteLength > 0)
      {
        ghostHold.noteData.length = newNoteLength;
        var targetNoteLengthSteps:Float = ghostHold.noteData.getStepLength(true);
        var targetNoteLengthStepsInt:Int = Std.int(Math.floor(targetNoteLengthSteps));
        var targetNoteLengthPixels:Float = ChartEditorTimeScale.lengthToPixels(ghostHold.noteData.time, newNoteLength, targetNoteLengthSteps);

        if (playheadDragLengthCurrent[column] != targetNoteLengthStepsInt)
        {
          this.playStretchySound();
          playheadDragLengthCurrent[column] = targetNoteLengthStepsInt;
        }
        ghostHold.visible = true;
        ghostHold.alpha = 0.6;
        ghostHold.setHeightDirectly(targetNoteLengthPixels, true);
        ghostHold.updateHoldNotePosition(renderedHoldNotes);
        trace('lerpLength: ${ghostHold.fullSustainLength}');
        trace('position: ${ghostHold.x}, ${ghostHold.y}');
      }
      else
      {
        ghostHold.visible = false;
        ghostHold.setHeightDirectly(0);
        playheadDragLengthCurrent[column] = 0;
        continue;
      }
    }
  }

  function finishPlaceNoteAtPlayhead(column:Int):Void
  {
    if (currentLiveInputPlaceNoteData[column] == null) return;

    var playheadFractionalStep:Float = ChartEditorTimeScale.pixelsToStep(scrollPositionInPixels + playheadPositionInPixels);
    var playheadSnappedStep:Float = Math.fround(playheadFractionalStep / noteSnapRatio) * noteSnapRatio;
    playheadSnappedStep = Math.min(playheadSnappedStep, lastSnappedGridStep);
    var playheadSnappedMs:Float = Conductor.instance.getStepTimeInMs(playheadSnappedStep);

    var newNoteLength:Float = playheadSnappedMs - currentLiveInputPlaceNoteData[column].time;
    trace('finishPlace newNoteLength: ${newNoteLength}');

    if (newNoteLength < Conductor.instance.stepLengthMs)
    {
      // Don't extend the note if it's too short.
      trace('Not extending note. ${column}');
      currentLiveInputPlaceNoteData[column] = null;
      gridPlayheadGhostHoldNotes[column].noteData = null;
    }
    else
    {
      // Extend the note to the playhead position.
      trace('Extending note. ${column}');
      this.playSound(Paths.sound('ui/editors/chart-editor/charting-sounds/stretch-snap').toString());
      performCommand(new ExtendNoteLengthCommand(currentLiveInputPlaceNoteData[column], newNoteLength));
      currentLiveInputPlaceNoteData[column] = null;
      gridPlayheadGhostHoldNotes[column].noteData = null;
    }
  }

  /**
   * Handle aligning the health icons next to the grid.
   */
  var _charIconData = null;

  @:access(funkin.play.character.BaseCharacter)
  function handleHealthIcons():Void
  {
    if (healthIconsDirty)
    {
      _charIconData = currentPlayerCharacterPlayer?.character?._data ?? CharacterRegistry.instance.fetchCharacterData(
        currentSongMetadata.playData.characters.player
      );

      if (healthIconBF != null)
      {
        healthIconBF.configure(_charIconData?.healthIcon);
        healthIconBF.iconOffset.set();
        healthIconBF.size *= 0.5; // Make the icon smaller in Chart Editor.
        healthIconBF.flipX = !healthIconBF.flipX; // BF faces the other way.
      }

      if (buttonSelectPlayer != null)
      {
        buttonSelectPlayer.text = _charIconData?.name ?? 'Player';
      }

      _charIconData = currentOpponentCharacterPlayer?.character?._data ?? CharacterRegistry.instance.fetchCharacterData(
        currentSongMetadata.playData.characters.opponent
      );

      if (healthIconDad != null)
      {
        healthIconDad.configure(_charIconData?.healthIcon);
        healthIconDad.iconOffset.set();
        healthIconDad.size *= 0.5; // Make the icon smaller in Chart Editor.
      }
      if (buttonSelectOpponent != null)
      {
        buttonSelectOpponent.text = _charIconData?.name ?? 'Opponent';
      }
      waveformsDirty = true;
      healthIconsDirty = false;
      _charIconData = null;
    }

    // Right align, and visibly center, the BF health icon.
    if (healthIconBF != null)
    {
      // Base X position to the right of the grid.
      healthIconBF.x = (gridTiledSprite == null) ? (0) : (gridTiledSprite.x + gridTiledSprite.width);
      var yOffset = 30 - (healthIconBF.height / 2);
      healthIconBF.y = (gridTiledSprite == null) ? (0) : (NOTE_SELECT_BUTTON_Y + 8) + yOffset;
    }

    // Visibly center the Dad health icon.
    if (healthIconDad != null)
    {
      healthIconDad.x = (gridTiledSprite == null) ? (0) : (measureTicks.x - healthIconDad.width);
      var yOffset = 30 - (healthIconDad.height / 2);
      healthIconDad.y = (gridTiledSprite == null) ? (0) : (NOTE_SELECT_BUTTON_Y + 8) + yOffset;
    }
  }

  /**
   * Handle waveforms aligning based on the health icons position.
   */
  function handleWaveforms()
  {
    updateInstrumentalWaveform();
    if (!waveformsDirty) return;

    for (waveform in audioWaveforms.members)
    {
      if (waveform == null) continue;

      waveform.overlayColor = ChartEditorThemeHandler.getWaveformFilterColor(currentTheme);

      if (waveform.iconId == GF)
      {
        waveform.visible = true;
        waveform.waveformWidth = GRID_SIZE * STRUMLINE_SIZE;
        waveform.baseColor = ChartEditorThemeHandler.getWaveformOverlayColor(currentTheme);
        waveform.coreColor = ChartEditorThemeHandler.getWaveformCoreColor(currentTheme);
        waveform.alpha = ChartEditorThemeHandler.WAVEFORM_OVERLAY_ALPHA;
        waveform.audioOffsetMs = 0;
        waveform.x = gridTiledSprite.x + GRID_SIZE * STRUMLINE_SIZE / 2;
        waveform.markDirty();
        waveform.refresh(gridTiledSprite?.y ?? GRID_INITIAL_Y_POS);
        continue;
      }

      waveform.visible = !usingInstrumentalWaveform;
      waveform.waveformWidth = (currentWaveformPos == Overlay) ? (GRID_SIZE * 4) : (GRID_SIZE * 2);
      // Colors are drawn into the bitmap, so the base and the filtered overlay can differ.
      waveform.baseColor = (currentWaveformPos == Overlay) ? ChartEditorThemeHandler.getWaveformOverlayColor(currentTheme) : FlxColor.WHITE;
      waveform.coreColor = (currentWaveformPos == Overlay) ? ChartEditorThemeHandler.getWaveformCoreColor(currentTheme) : null;
      waveform.alpha = (currentWaveformPos == Overlay) ? ChartEditorThemeHandler.WAVEFORM_OVERLAY_ALPHA : 1.0;

      waveform.audioOffsetMs = (waveform.iconId == DAD) ? currentVocalOffsetOpponent : currentVocalOffsetPlayer;
      waveform.markDirty();

      switch (waveform.iconId)
      {
        case BF:
          if (currentWaveformPos == Overlay)
          {
            waveform.x = gridTiledSprite.x + (GRID_SIZE * 4);
          }
          else if (healthIconBF != null)
          {
            waveform.x = healthIconBF.x;
          }
          else
          {
            waveform.x = 840 + FullScreenScaleMode.gameCutoutSize.x * 0.5;
          }
        case DAD:
          if (currentWaveformPos == Overlay)
          {
            waveform.x = gridTiledSprite.x;
          }
          else if (healthIconDad != null)
          {
            waveform.x = healthIconDad.x;
          }
          else
          {
            waveform.x = 360 + FullScreenScaleMode.gameCutoutSize.x * 0.5;
          }
        default:
          waveform.x = 0;
      }

      waveform.refresh(gridTiledSprite?.y ?? GRID_INITIAL_Y_POS);
    }

    waveformsDirty = false;
  }

  /**
   * Handle update code for the Command Palette.
   */
  function handleCommandPalette():Void
  {
    var canOpenCommandPalette:Bool = (ChartEditorCommandPalette.instance != null || !isHaxeUIDialogOpen);

    // CTRL + P = Open Command Palette
    if (pressingControl() && !FlxG.keys.pressed.SHIFT && !FlxG.keys.pressed.ALT && FlxG.keys.justPressed.P && canOpenCommandPalette)
    {
      ChartEditorCommandPalette.openPalette(this, '');
    }
    // CTRL + SHIFT + P = Show and Run Commands
    if (pressingControl() && FlxG.keys.pressed.SHIFT && !FlxG.keys.pressed.ALT && FlxG.keys.justPressed.P && canOpenCommandPalette)
    {
      ChartEditorCommandPalette.openPalette(this, '>');
    }
    // CTRL + G = Go to Measure
    if (pressingControl() && !FlxG.keys.pressed.SHIFT && !FlxG.keys.pressed.ALT && FlxG.keys.justPressed.G && canOpenCommandPalette)
    {
      ChartEditorCommandPalette.openPalette(this, ':');
    }
    // CTRL + B = Go to Comment
    if (pressingControl() && !FlxG.keys.pressed.SHIFT && !FlxG.keys.pressed.ALT && FlxG.keys.justPressed.B && canOpenCommandPalette)
    {
      ChartEditorCommandPalette.openPalette(this, '#');
    }
    // CTRL + W = Open Toolbox
    if (pressingControl() && !FlxG.keys.pressed.SHIFT && !FlxG.keys.pressed.ALT && FlxG.keys.justPressed.W && canOpenCommandPalette)
    {
      ChartEditorCommandPalette.openPalette(this, '%');
    }
  }

  /**
   * Handle keybinds for File menu items.
   */
  function handleFileKeybinds():Void
  {
    // CTRL + N = New Chart
    if (pressingControl() && FlxG.keys.justPressed.N && !isHaxeUIDialogOpen && !FlxG.keys.pressed.SHIFT && !FlxG.keys.pressed.ALT)
    {
      this.openWelcomeDialog(true);
    }

    // CTRL + O = Open Chart
    if (pressingControl() && FlxG.keys.justPressed.O && !isHaxeUIDialogOpen)
    {
      this.openBrowseFNFC(true);
    }

    if (pressingControl() && FlxG.keys.justPressed.S && !isHaxeUIDialogOpen)
    {
      if (currentWorkingFilePath == null || FlxG.keys.pressed.SHIFT)
      {
        // CTRL + SHIFT + S = Save As
        this.exportCurrentChartToFNFC(false, null, function(path:String)
        {
          // CTRL + SHIFT + S Successful
          this.success('Saved Chart', 'Chart saved successfully to ${path}.');
        }, function()
        {
          // CTRL + SHIFT + S Cancelled
        });
      }
      else
      {
        // CTRL + S = Save Chart
        this.exportCurrentChartToFNFC(true, currentWorkingFilePath);
        this.success('Saved Chart', 'Chart saved successfully to ${currentWorkingFilePath}.');
      }
    }

    // CTRL + Q = Quit to Menu
    if (pressingControl() && FlxG.keys.justPressed.Q)
    {
      quitChartEditor(true);
    }
  }

  function performCleanup():Void
  {
    destroyHaxeUIComponents();

    @:privateAccess
    ChartEditorNoteSprite.noteFrameCollection = null;
    @:privateAccess
    ChartEditorEventSprite.eventFrames = null;

    activeToolboxes.clear();

    criticalFailure = true;
  }

  @:nullSafety(Off)
  function destroyHaxeUIComponents():Void
  {
    this.clearNotifications();

    if (playbarHeadLayout != null)
    {
      remove(playbarHeadLayout);
      playbarHeadLayout.destroy();
      playbarHeadLayout = null;
    }
    for (commentPanel in commentPanels)
    {
      remove(commentPanel);
      commentPanel.destroy();
    }
    commentPanels = [];
    if (txtCopyNotif != null)
    {
      remove(txtCopyNotif);
      txtCopyNotif.destroy();
      txtCopyNotif = null;
    }
    if (buttonSelectPlayer != null)
    {
      remove(buttonSelectPlayer);
      buttonSelectPlayer.destroy();
      buttonSelectPlayer = null;
    }
    if (buttonSelectPlayer != null)
    {
      remove(buttonSelectPlayer);
      buttonSelectPlayer.destroy();
      buttonSelectPlayer = null;
    }
    if (buttonSelectEvent != null)
    {
      remove(buttonSelectEvent);
      buttonSelectEvent.destroy();
      buttonSelectEvent = null;
    }
    if (buttonSelectDummy != null)
    {
      remove(buttonSelectDummy);
      buttonSelectDummy.destroy();
      buttonSelectDummy = null;
    }
  }

  @:nullSafety(Off)
  function quitChartEditor(exitPrompt:Bool = false):Void
  {
    if (saveDataDirty && exitPrompt)
    {
      this.openLeaveConfirmationDialog();
      return;
    }

    Transition.switchState(() -> new MainMenuState(), {
      assetQuery: MainMenuState.queryAssets,
      transition: BlackScreen(None, None)
    });
  }

  /**
   * The last clicked toolbox list that receives keyboard input for copy, paste, and delete actions.
   */
  var listKeyTarget:Null<ChartEditorListKeyTarget> = null;

  function handleListKeybinds():Void
  {
    var target:Null<ChartEditorListKeyTarget> = listKeyTarget;
    if (target == null) return;
    if (!target.isListShown() || (FlxG.mouse.justPressed || FlxG.mouse.justPressedRight) && !target.containsMouse())
    {
      listKeyTarget = null;
      return;
    }
    // Typing in a text field, such as a rename.
    if (isHaxeUIFocused) return;

    if (pressingControl() && FlxG.keys.justPressed.C) target.copySelection();
    if (pressingControl() && FlxG.keys.justPressed.V) target.pasteSelection();

    var delete:Bool = FlxG.keys.justPressed.DELETE;
    #if mac
    delete = delete || FlxG.keys.justPressed.BACKSPACE;
    #end
    if (delete) target.deleteSelection();
  }

  /**
   * Handle keybinds for edit menu items.
   */
  function handleEditKeybinds():Void
  {
    var listHasKeys:Bool = listKeyTarget != null;

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
    if (!listHasKeys && pressingControl() && FlxG.keys.justPressed.C)
    {
      performCommand(new CopyItemsCommand(currentNoteSelection, currentEventSelection));
    }

    // CTRL + X = Cut
    if (!listHasKeys && pressingControl() && FlxG.keys.justPressed.X)
    {
      // Cut selected notes.
      performCommand(new CutItemsCommand(currentNoteSelection, currentEventSelection));
    }

    // CTRL + V = Paste
    if (!listHasKeys && pressingControl() && FlxG.keys.justPressed.V)
    {
      // CTRL + SHIFT + V = Paste Unsnapped.
      var targetMs:Float = if (FlxG.keys.pressed.SHIFT)
      {
        scrollPositionInMs + playheadPositionInMs;
      }
      else
      {
        var targetMs:Float = scrollPositionInMs + playheadPositionInMs;
        var targetStep:Float = Conductor.instance.getTimeInSteps(targetMs);
        var targetSnappedStep:Float = Math.floor(targetStep / noteSnapRatio) * noteSnapRatio;
        var targetSnappedMs:Float = Conductor.instance.getStepTimeInMs(targetSnappedStep);
        targetSnappedMs;
      }
      performCommand(new PasteItemsCommand(targetMs));
    }

    // DELETE = Delete
    var delete:Bool = FlxG.keys.justPressed.DELETE;

    // on macbooks, Delete == backspace
    #if mac
    delete = delete || FlxG.keys.justPressed.BACKSPACE;
    #end

    if (delete && !listHasKeys)
    {
      var noteSelection = currentNoteSelection.length > 0;
      var eventSelection = currentEventSelection.length > 0;

      // Shift to delete stacked notes
      if (FlxG.keys.pressed.SHIFT)
      {
        if (eventSelection && !noteSelection)
        {
          performCommand(new RemoveEventsCommand(currentEventSelection));
        }
        else
        {
          performCommand(new RemoveStackedNotesCommand(noteSelection ? currentNoteSelection : null));
        }
      }
      else
      {
        // Delete selected items.
        if (noteSelection && eventSelection)
        {
          performCommand(new RemoveItemsCommand(currentNoteSelection, currentEventSelection));
        }
        else if (noteSelection)
        {
          performCommand(new RemoveNotesCommand(currentNoteSelection));
        }
        else if (eventSelection)
        {
          performCommand(new RemoveEventsCommand(currentEventSelection));
        }
      }
    }

    // CTRL + F = Flip Notes
    if (pressingControl() && FlxG.keys.justPressed.F)
    {
      // Flip selected notes.
      performCommand(new FlipNotesCommand(currentNoteSelection));
    }

    // CTRL + SHIFT + ALT + M = Mirror Notes along XY axis
    if (FlxG.keys.pressed.CONTROL && FlxG.keys.pressed.SHIFT && FlxG.keys.pressed.ALT && FlxG.keys.justPressed.M)
    {
      performCommand(
        new MirrorNotesCommand(currentNoteSelection, menubarItemMirrorFlipWithinStrumline.selected, !menubarItemMirrorFlipWithinStrumline.selected, true, true)
      );
    }

    // CTRL + SHIFT + M = Mirror Notes along X axis
    if (!FlxG.keys.pressed.ALT && FlxG.keys.pressed.CONTROL && FlxG.keys.pressed.SHIFT && FlxG.keys.justPressed.M)
    {
      performCommand(
        new MirrorNotesCommand(
          currentNoteSelection,
          menubarItemMirrorFlipWithinStrumline.selected,
          !menubarItemMirrorFlipWithinStrumline.selected,
          true,
          false
        )
      );
    }

    // CTRL + ALT + M = Mirror Notes along the Y axis
    if (!FlxG.keys.pressed.SHIFT && FlxG.keys.pressed.CONTROL && FlxG.keys.pressed.ALT && FlxG.keys.justPressed.M)
    {
      performCommand(
        new MirrorNotesCommand(
          currentNoteSelection,
          menubarItemMirrorFlipWithinStrumline.selected,
          !menubarItemMirrorFlipWithinStrumline.selected,
          false,
          true
        )
      );
    }

    // CTRL + A = Select All Notes
    if (pressingControl() && FlxG.keys.justPressed.A)
    {
      // Select all items.
      if (FlxG.keys.pressed.ALT)
      {
        if (FlxG.keys.pressed.SHIFT)
        {
          // CTRL + ALT + SHIFT + A = Append All Events to Selection
          performCommand(new SelectItemsCommand([], currentSongChartEventData));
        }
        else
        {
          // CTRL + ALT + A = Set Selection to All Events
          performCommand(new SelectAllItemsCommand(false, true));
        }
      }
      else
      {
        if (FlxG.keys.pressed.SHIFT)
        {
          // CTRL + SHIFT + A = Append All Notes to Selection
          performCommand(new SelectItemsCommand(currentSongChartNoteData, []));
        }
        else
        {
          // CTRL + A = Set Selection to All Notes
          performCommand(new SelectAllItemsCommand(true, false));
        }
      }
    }

    // CTRL + I = Select Inverse
    if (pressingControl() && FlxG.keys.justPressed.I)
    {
      // Select unselected items and deselect selected items.
      performCommand(new InvertSelectedItemsCommand());
    }

    // CTRL + D = Select None
    if (pressingControl() && FlxG.keys.justPressed.D)
    {
      // Deselect all items.
      performCommand(new DeselectAllItemsCommand());
    }

    // SHIFT + Home = Select all above playhead
    if (FlxG.keys.pressed.SHIFT && FlxG.keys.justPressed.HOME)
    {
      // CTRL +  SHIFT + Home = Inverse - deselect all above playhead
      if (FlxG.keys.pressed.CONTROL)
      {
        performCommand(new DeselectAllItemsBetweenTimeCommand(scrollPositionInMs + playheadPositionInMs, true, true, true));
      }
      else
      {
        performCommand(new SelectAllItemsBetweenTimeCommand(scrollPositionInMs + playheadPositionInMs, true, true, true));
      }
    }

    // SHIFT + End = Select all below playhead
    if (FlxG.keys.pressed.SHIFT && FlxG.keys.justPressed.END)
    {
      // CTRL +  SHIFT + Home = Inverse - deselect all below playhead
      if (FlxG.keys.pressed.CONTROL)
      {
        performCommand(new DeselectAllItemsBetweenTimeCommand(scrollPositionInMs + playheadPositionInMs, false, true, true));
      }
      else
      {
        performCommand(new SelectAllItemsBetweenTimeCommand(scrollPositionInMs + playheadPositionInMs, false, true, true));
      }
    }
  }

  /**
   * Handle keybinds for View menu items.
   */
  function handleViewKeybinds():Void
  {
    if (currentLiveInputStyle != WASDKeys)
    {
      if (pressingControl() && FlxG.keys.justPressed.LEFT)
      {
        incrementDifficulty(-1);
      }
      if (pressingControl() && FlxG.keys.justPressed.RIGHT)
      {
        incrementDifficulty(1);
      }
      // Would bind Ctrl+A and Ctrl+D here, but they are already bound to Select All and Select None.
    }
    else
    {
      // trace('Ignoring keybinds for View menu items because we are in live input mode (${currentLiveInputStyle}).');
    }

    // Ctrl + Plus/Minus = Change the playback speed by 0.1x.
    if (pressingControl() && !isHaxeUIFocused)
    {
      if (FlxG.keys.justPressed.PLUS || FlxG.keys.justPressed.NUMPADPLUS) changePlaybackSpeed(0.1);
      if (FlxG.keys.justPressed.MINUS || FlxG.keys.justPressed.NUMPADMINUS) changePlaybackSpeed(-0.1);
    }

    // B = New Comment
    if (!pressingControl() && !FlxG.keys.pressed.SHIFT && !FlxG.keys.pressed.ALT && FlxG.keys.justPressed.B && !isHaxeUIDialogOpen && !isHaxeUIFocused)
    {
      // Add a new comment at the grid playhead's position.
      var playheadPosMs:Float = scrollPositionInMs + playheadPositionInMs;
      performCommand(new AddCommentCommand({
        time: playheadPosMs,
        text: 'New Comment',
        color: commentColorToPlace,
      }));
      this.success('New Comment', 'Added a comment at the playhead position.');
    }
  }

  /**
   * Step the playback speed, staying on whole tenths between 0.1x and 2x.
   */
  function changePlaybackSpeed(amount:Float):Void
  {
    // The slider runs from 0 to 100 for 0x to 2x.
    var currentRate:Float = menubarItemPlaybackSpeed.pos / 50.0;
    var newRate:Float = Math.round((currentRate + amount) * 10) / 10;
    setPlaybackSpeed(newRate.clamp(0.1, 2.0));
  }

  /**
   * Set the playback speed from code, moving the slider to match.
   */
  function setPlaybackSpeed(rate:Float):Void
  {
    menubarItemPlaybackSpeed.pos = rate * 50.0;
    applyPlaybackSpeed(rate);
  }

  function applyPlaybackSpeed(rate:Float):Void
  {
    if (audioInstTrack != null) audioInstTrack.pitch = rate;
    audioVocalTrackGroup.pitch = rate;
    var rateDisplay:Float = Std.int(rate * 100) / 100; // Round to 2 decimal places.
    menubarLabelPlaybackSpeed.text = 'Playback Speed - ${rateDisplay}x';
  }

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
   * Handle keybinds for the Test menu items.
   */
  function handleTestKeybinds():Void
  {
    // Use wasOpen, otherwise the command palette triggers playtests.
    if (!wasHaxeUIDialogOpen && !isHaxeUIFocused && FlxG.keys.justPressed.ENTER)
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
    if (FlxG.keys.justPressed.F1 && !isHaxeUIDialogOpen)
    {
      this.openUserGuideDialog();
    }
  }

  /**
   * Handle keybinds for audio playback.
   */
  function handleAudioKeybinds():Void
  {
    // Same as the Audio -> Mute Metronome toggle, which keeps the volume as it is.
    if (!isHaxeUIFocused && FlxG.keys.pressed.SHIFT && FlxG.keys.justPressed.M && !pressingControl())
    {
      metronomeMuted = !metronomeMuted;
      menubarItemMuteMetronome.selected = metronomeMuted;
    }
    // Same as the Audio -> Mute Hitsounds toggle, which keeps the volumes as they are.
    if (!isHaxeUIFocused && FlxG.keys.pressed.SHIFT && FlxG.keys.justPressed.H)
    {
      hitsoundsMuted = !hitsoundsMuted;
      menubarItemMuteHitsounds.selected = hitsoundsMuted;
    }
    // Same as the Audio -> Mute Instrumental toggle, which keeps the volume as it is.
    if (!isHaxeUIFocused && FlxG.keys.pressed.SHIFT && FlxG.keys.justPressed.I)
    {
      instrumentalMuted = !instrumentalMuted;
      menubarItemMuteInstrumental.selected = instrumentalMuted;
    }
    // Both vocal mute toggles at once. Mutes both unless both are already muted, then unmutes both.
    if (!isHaxeUIFocused && FlxG.keys.pressed.SHIFT && FlxG.keys.justPressed.V && !pressingControl())
    {
      var mute:Bool = !(playerVocalsMuted && opponentVocalsMuted);
      playerVocalsMuted = opponentVocalsMuted = mute;
      menubarItemMutePlayerVocals.selected = menubarItemMuteOpponentVocals.selected = mute;
    }
    // Same as the Audio -> Mute Player Vocals toggle.
    if (!isHaxeUIFocused && FlxG.keys.pressed.SHIFT && FlxG.keys.justPressed.B)
    {
      playerVocalsMuted = !playerVocalsMuted;
      menubarItemMutePlayerVocals.selected = playerVocalsMuted;
    }
    // Same as the Audio -> Mute Opponent Vocals toggle.
    if (!isHaxeUIFocused && FlxG.keys.pressed.SHIFT && FlxG.keys.justPressed.D && !pressingControl())
    {
      opponentVocalsMuted = !opponentVocalsMuted;
      menubarItemMuteOpponentVocals.selected = opponentVocalsMuted;
    }
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

  function moveToCameraEditor(hasSaved:Bool = false):Void
  {
    if (!hasSaved)
    {
      // Save the current chart as a file.
      if (currentWorkingFilePath != null)
      {
        this.exportCurrentChartToFNFC(true, currentWorkingFilePath);
        moveToCameraEditor(true);
      }
      else
      {
        this.exportCurrentChartToFNFC(false, null, function(path:String)
        {
          // CTRL + SHIFT + S Successful
          // Just to be sure
          currentWorkingFilePath = path;

          moveToCameraEditor(true);
        }, function()
        {
          // CTRL + SHIFT + S Cancelled, do NOTHING
          return;
        });
      }
    }
    else
    {
      if (currentWorkingFilePath == null)
      {
        this.error("Can't Move To Camera Editor", 'Camera Editor can only be accessed when the current chart has been saved to a file.');
        return;
      }

      var startTimestamp:Float = scrollPositionInMs + playheadPositionInMs;

      @:nullSafety(Off)
      {
        final f = FocusManager.instance.focus;
        if (f != null) f.focus = false;
      }

      writePreferences(false);
      performCleanup();

      var cameraEditorParams = {
        loadFromPath: this.currentWorkingFilePath,
        targetSongDifficulty: this.selectedDifficulty,
        targetSongVariation: this.selectedVariation,
        targetSongPosition: startTimestamp,
      };

      Transition.switchState(() -> new CameraEditorState(cameraEditorParams), {
        assetQuery: Transition.NO_ASSETS, // CameraEditorState.queryAssets.bind(_, cameraEditorParams),
        transition: BlackScreen(None, Fade(South))
      });
    }
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
    for (component in Screen.instance.rootComponents.copy())
    {
      if (component is Menu)
      {
        if (cast(component, Menu).menuBar != null) component.dispatch(new UIEvent(UIEvent.CLOSE));
        else
          Screen.instance.removeComponent(component, false);
      }
      for (dropDown in component.findComponents(null, DropDown, -1)) dropDown.hideDropDown();
    }

    autoSave(true);

    if (!wasPlaytesting)
    {
      }

    // Stop audio playback after note preview is stopped.
    // `false` to force the welcome theme to stop too.
    stopAudioPlayback(false);

    var startTimestamp:Float = 0;
    if (playtestStartTime) startTimestamp = scrollPositionInMs + playheadPositionInMs;

    var playbackRate:Float = 1.0;
    if (playtestAudioSettings)
    {
      playbackRate = ((menubarItemPlaybackSpeed.value / 100.0) ?? 0.5) * 2.0;
      playbackRate = playbackRate.clamp(0.05, 2.0); // Clamp to 5% to 200%
    }

    funkin.play.GameOverSubState.reset();
    funkin.play.PauseSubState.reset();

    var targetSong:Song;
    try
    {
      targetSong = Song.buildRaw(currentSongId, songMetadata.values(), selectedVariation, songChartData, playtestSongScripts, false);
    }
    catch (e)
    {
      this.error('Could Not Playtest', 'Got an error trying to playtest the song.\n${e}');
      return;
    }

    PlayStatePlaylist.reset();

    subStateClosed.add(reviveUICamera);
    subStateClosed.add(resetConductorAfterTest);

    var targetStateParams = {
      targetSong: targetSong,
      targetDifficulty: selectedDifficulty,
      targetVariation: selectedVariation,
      practiceMode: playtestPracticeMode,
      botPlayMode: playtestBotPlayMode,
      playtestResults: playtestShowResults,
      minimalMode: minimal,
      startTimestamp: startTimestamp,
      playbackRate: playbackRate,
      overrideMusic: true,
    };

    // Override music.
    if (audioInstTrack != null)
    {
      FlxG.sound.music = audioInstTrack;
    }
    // The playtest runs at the game's normal size.
    ChartEditorScaleMode.restore();

    // Kill and replace the UI camera so it doesn't get destroyed during the state transition.
    uiCamera.kill();
    FlxG.cameras.remove(uiCamera, false);
    FlxG.cameras.reset(new FunkinCamera('chartEditorUI2'));

    this.persistentUpdate = false;
    this.persistentDraw = false;

    Cursor.hide();

    funkin.ui.transition.Transition.openPlayState(targetStateParams, {
      transition: Throbber,
      shouldStopMusic: false,
      onConstruct: (targetState) ->
      {
        if (playbarHeadDragging) playbarHeadDragging = false;
        // Apply volume settings.
        final playState = cast(targetState, funkin.play.PlayState);
        if (playtestAudioSettings)
        {
          playState.instrumentalVolume = instrumentalMuted ? 0.0 : ((preferencesVolumeInstrumental.value / 100.0) ?? 1.0);
          playState.playerVocalsVolume = playerVocalsMuted ? 0.0 : ((preferencesVolumeVocalsPlayer.value / 100.0) ?? 1.0);
          playState.opponentVocalsVolume = opponentVocalsMuted ? 0.0 : ((preferencesVolumeVocalsOpponent.value / 100.0) ?? 1.0);
        }
        else audioVocalTrackGroup.muted = false;

        playState.vocals = audioVocalTrackGroup;
      }
    }, true);

    /*LoadingState.loadPlayState(targetStateParams, false, true, function(targetState)
      {

    });*/
  }

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
   * This is for the smaller green squares that appear over each note when you select them.
   */
  function buildSelectionSquare():ChartEditorSelectionSquareSprite
  {
    if (selectionSquareBitmap == null) throw 'ERROR: Tried to build selection square, but selectionSquareBitmap is null! Check ChartEditorThemeHandler.updateSelectionSquare()';

    // FlxG.bitmapLog.add(selectionSquareBitmap, "selectionSquareBitmap");
    var result = new ChartEditorSelectionSquareSprite(this);
    result.loadGraphic(selectionSquareBitmap);
    return result;
  }

  /**
   * Revive the UI camera and re-establish it as the main camera so UI elements depending on it don't explode.
   */
  function reviveUICamera(?closedSubState:FlxSubState):Void
  {
    if (closedSubState != null && (FlxStateUtil.isTransition(closedSubState) || FlxStateUtil.isLoadingState(closedSubState)))
    {
      // The state that closed was a loading screen for the substate we're opening,
      // so we shouldn't do any cleanup.
      return;
    }

    uiScaleDirty = false;
    ChartEditorScaleMode.apply(uiScale);
    uiCamera.revive();
    FlxG.cameras.reset(uiCamera);
    uiCamera.setSize(FlxG.width, FlxG.height);
    uiCamera.onResize();

    add(this.root);
  }

  /**
   * AUDIO FUNCTIONS
   */
  // ====================

  function startAudioPlayback():Void
  {
    if (audioInstTrack == null && audioVocalTrackGroup.length == 0) return;

    // Don't allow the audio to be played while we're dragging any of the playheads
    if (playbarHeadDragging || gridPlayheadScrollAreaPressed || notePreviewPlayHeadDragging) return;
    stopWelcomeMusic();
    if (audioInstTrack != null) audioInstTrack.play(false, audioInstTrack.time);
    audioVocalTrackGroup.play(false, audioInstTrack.time);

    playbarPlay.text = '||'; // Pause
  }

  /**
   * Play the metronome tick sound.
   * @param high Whether to play the full beat sound rather than the quarter beat sound.
   */
  function playMetronomeTick(high:Bool = false):Void
  {
    this.playSound(Paths.sound('ui/editors/chart-editor/charting-sounds/metronome-${high ? '1' : '2'}').toString(), metronomeVolume);
  }

  function switchToCurrentInstrumental():Void
  {
    // ChartEditorAudioHandler
    this.switchToInstrumental(currentInstrumentalId);
  }

  public function updateGridHeight():Void
  {
    // Make sure playhead doesn't go outside the song after we update the grid height.
    if (playheadPositionInMs > songLengthInMs) playheadPositionInMs = songLengthInMs;

    if (gridTiledSprite != null)
    {
      gridTiledSprite.height = songLengthInPixels;
      measureTicks.setHeight(gridTiledSprite.height);
    }
    gridLinesDirty = true;
    waveformsDirty = true;

    for (difficultyNotes in currentSongChartData.notes)
    {
      for (note in difficultyNotes)
      {
        note.getStepTime(true);
        note.getStepLength(true);
      }
    }
    for (event in currentSongChartData.events)
    {
      event.getStepTime(null, true);
    }

    if (audioInstTrack != null && currentSongChartData.notes.get(selectedDifficulty) != null)
    {
      // Remove any notes past the end of the song, if this difficulty exists.
      var songCutoffPointSteps:Float = gridLengthInSteps - 0.1;
      var songCutoffPointMs:Float = Conductor.instance.getStepTimeInMs(songCutoffPointSteps);
      currentSongChartNoteData = SongDataUtils.clampSongNoteData(currentSongChartNoteData, 0.0, songCutoffPointMs);
      currentSongChartEventData = SongDataUtils.clampSongEventData(currentSongChartEventData, 0.0, songCutoffPointMs);
    }
    else
    {
      // We end up here if we're midway through switching variation AND difficulty,
      // and we're on the new variation but the old difficulty, so the current difficulty doesn't exist.
      trace('Skipping difficulty that does not exist');
    }

    notePreviewDirty = true;
    notePreviewViewportBoundsDirty = true;
    noteDisplayDirty = true;
    commentDisplayDirty = true;
    moveSongToScrollPosition();
  }

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
   * Which snap position an event is on.
   */
  public function eventChainKey(event:SongEventData):Int
  {
    return Math.round(Conductor.instance.getTimeInSteps(event.time) / noteSnapRatio);
  }

  /**
   * Every event in the same chain as an event, including it, in chart order.
   */
  public function eventChainOf(event:SongEventData):Array<SongEventData>
  {
    var key:Int = eventChainKey(event);
    var chain:Array<SongEventData> = [for (other in currentSongChartEventData) if (other == event || eventChainKey(other) == key) other];
    if (!chain.contains(event)) chain.push(event);
    return chain;
  }

  /**
   * The events given, plus every event in a chain with any of them.
   */
  public function withEventChains(events:Array<SongEventData>):Array<SongEventData>
  {
    if (events.length == 0) return events;
    var result:Array<SongEventData> = [];
    for (event in events)
    {
      for (member in eventChainOf(event)) if (!result.contains(member)) result.push(member);
    }
    return result;
  }

  /**
   * Whether the events are all one chain, or one event on its own.
   */
  public function isOneEventChain(events:Array<SongEventData>):Bool
  {
    if (events.length == 0) return false;
    var key:Int = eventChainKey(events[0]);
    for (event in events) if (eventChainKey(event) != key) return false;
    return true;
  }

  /**
   * For each event chain, the event the grid shows for it, and the rest of the chain.
   */
  var eventChainFollowers:haxe.ds.ObjectMap<SongEventData, Bool> = new haxe.ds.ObjectMap();

  var eventChainRest:haxe.ds.ObjectMap<SongEventData, Array<SongEventData>> = new haxe.ds.ObjectMap();

  function rebuildEventChains():Void
  {
    eventChainFollowers.clear();
    eventChainRest.clear();
    var sorted:Array<SongEventData> = [for (event in currentSongChartEventData) if (event != null) event];
    haxe.ds.ArraySort.sort(sorted, (a, b) -> a.time < b.time ? -1 : (a.time > b.time ? 1 : 0));
    var leader:Null<SongEventData> = null;
    var leaderKey:Int = 0;
    for (event in sorted)
    {
      var key:Int = eventChainKey(event);
      if (leader != null && key == leaderKey)
      {
        eventChainFollowers.set(event, true);
        eventChainRest.get(leader).push(event);
      }
      else
      {
        leader = event;
        leaderKey = key;
        eventChainRest.set(leader, []);
      }
    }
  }

  function isEventSelected(event:Null<SongEventData>):Bool
  {
    return event != null && currentEventSelection.indexOf(event) != -1;
  }

  function createDifficulty(variation:String, difficulty:String, scrollSpeed:Float = 1.0):Void
  {
    var variationMetadata:Null<SongMetadata> = songMetadata.get(variation);
    if (variationMetadata == null) return;

    variationMetadata.playData.difficulties.pushUnique(difficulty);

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

  function cloneDifficulty(variation:String, difficulty:String, newVariation:String, newDifficulty:String, scrollSpeed:Float = 1.0):Void
  {
    var newVariationMetadata:Null<SongMetadata> = songMetadata.get(newVariation);
    if (newVariationMetadata == null) return;

    var oldChartData:Null<SongChartData> = songChartData.get(variation);
    if (oldChartData == null)
    {
      // If we can't access the difficulty to copy, just create a blank one.
      createDifficulty(newVariation, newDifficulty, scrollSpeed);
      return;
    };

    var newNoteData:Null<Array<SongNoteData>> = oldChartData.notes.get(difficulty)?.clone();
    if (newNoteData == null || newNoteData.length == 0)
    {
      // If we can't access the difficulty to copy, just create a blank one.
      createDifficulty(newVariation, newDifficulty, scrollSpeed);
      return;
    };

    // Actually add the new difficulty.

    newVariationMetadata.playData.difficulties.pushUnique(newDifficulty);

    var newChartData = songChartData.get(newVariation);
    if (newChartData == null)
    {
      newChartData = new SongChartData([newDifficulty => scrollSpeed], [], [newDifficulty => newNoteData]);
      songChartData.set(newVariation, newChartData);
    }
    else
    {
      newChartData.scrollSpeed.set(newDifficulty, scrollSpeed);
      newChartData.notes.set(newDifficulty, newNoteData);
    }

    difficultySelectDirty = true; // Force the Difficulty toolbox to update.
  }

  function removeDifficulty(variation:String, difficulty:String):Void
  {
    var variationMetadata:Null<SongMetadata> = songMetadata.get(variation);
    if (variationMetadata == null) return;

    variationMetadata.playData.difficulties.remove(difficulty);

    var resultChartData = songChartData.get(variation);
    if (resultChartData != null)
    {
      resultChartData.scrollSpeed.remove(difficulty);
      resultChartData.notes.remove(difficulty);
    }

    // Remove the variation if it is empty.
    var variationEmpty:Bool = variation != Constants.DEFAULT_VARIATION && variationMetadata.playData.difficulties.length == 0;
    if (variationEmpty)
    {
      songMetadata.remove(variation);
      songChartData.remove(variation);
    }

    if (variation == selectedVariation)
    {
      if (variationEmpty) selectedVariation = Constants.DEFAULT_VARIATION;
      var remaining:Array<String> = songMetadata.get(selectedVariation)?.playData.difficulties ?? [];
      if (remaining.length > 0 && !remaining.contains(selectedDifficulty)) selectedDifficulty = remaining[0];
    }

    refreshPlayDataVariations();
    difficultySelectDirty = true; // Force the Difficulty toolbox to update.
  }

  /**
   * Turn typed text into a difficulty or variation ID.
   */
  static function sanitizeDifficultyId(text:String):Null<String>
  {
    var result:String = ~/[^a-z0-9_-]/g.replace(~/\s+/g.replace(StringTools.trim(text).toLowerCase(), '-'), '');
    return result.length > 0 ? result : null;
  }

  /**
   * Find an ID based on `base` that is not in `taken`.
   */
  static function uniqueDifficultyId(base:String, taken:Array<String>):String
  {
    if (!taken.contains(base)) return base;
    var index:Int = 2;
    while (taken.contains('$base-$index')) index++;
    return '$base-$index';
  }

  static function moveMapKey<T>(map:Null<Map<String, T>>, from:String, to:String):Void
  {
    if (map == null || !map.exists(from)) return;
    map.set(to, map.get(from));
    map.remove(from);
  }

  function markDifficultiesChanged():Void
  {
    difficultySelectDirty = true;
    saveDataDirty = true;
    noteDisplayDirty = true;
    notePreviewDirty = true;
    noteTooltipsDirty = true;
    this.refreshToolbox(CHART_EDITOR_TOOLBOX_METADATA_LAYOUT);
  }

  /**
   * Give a difficulty a new ID.
   * @return Whether the rename happened.
   */
  function renameDifficulty(variation:String, difficulty:String, newDifficulty:String):Bool
  {
    if (difficulty == newDifficulty) return false;
    var variationMetadata:Null<SongMetadata> = songMetadata.get(variation);
    if (variationMetadata == null) return false;
    var difficulties:Array<String> = variationMetadata.playData.difficulties;
    var index:Int = difficulties.indexOf(difficulty);
    if (index == -1 || difficulties.contains(newDifficulty)) return false;

    difficulties[index] = newDifficulty;
    var chartData:Null<SongChartData> = songChartData.get(variation);
    if (chartData != null)
    {
      moveMapKey(chartData.scrollSpeed, difficulty, newDifficulty);
      moveMapKey(chartData.notes, difficulty, newDifficulty);
    }
    moveMapKey(variationMetadata.playData.ratings, difficulty, newDifficulty);

    if (variation == selectedVariation && selectedDifficulty == difficulty) selectedDifficulty = newDifficulty;
    markDifficultiesChanged();
    return true;
  }

  /**
   * Copy a difficulty into a new difficulty, which can be in another variation.
   * @return Whether the copy was made.
   */
  function duplicateDifficulty(variation:String, difficulty:String, targetVariation:String, newDifficulty:String):Bool
  {
    var targetMetadata:Null<SongMetadata> = songMetadata.get(targetVariation);
    if (targetMetadata == null || targetMetadata.playData.difficulties.contains(newDifficulty)) return false;

    var sourceChart:Null<SongChartData> = songChartData.get(variation);
    var sourceNotes:Null<Array<SongNoteData>> = sourceChart != null ? sourceChart.notes.get(difficulty) : null;
    var notes:Array<SongNoteData> = sourceNotes != null ? sourceNotes.deepClone() : [];
    var sourceSpeed:Null<Float> = sourceChart != null ? sourceChart.scrollSpeed.get(difficulty) : null;
    var speed:Float = sourceSpeed ?? 1.0;

    targetMetadata.playData.difficulties.push(newDifficulty);
    var targetChart:Null<SongChartData> = songChartData.get(targetVariation);
    if (targetChart == null)
    {
      songChartData.set(targetVariation, new SongChartData([newDifficulty => speed], [], [newDifficulty => notes]));
    }
    else
    {
      targetChart.scrollSpeed.set(newDifficulty, speed);
      targetChart.notes.set(newDifficulty, notes);
    }

    var rating:Null<Int> = songMetadata.get(variation)?.playData.ratings?.get(difficulty);
    if (rating != null && targetMetadata.playData.ratings != null) targetMetadata.playData.ratings.set(newDifficulty, rating);

    markDifficultiesChanged();
    return true;
  }

  /**
   * Move a difficulty to another variation, following it if it was the one being edited.
   * @return Whether the move happened.
   */
  function moveDifficulty(variation:String, difficulty:String, targetVariation:String):Bool
  {
    if (variation == targetVariation) return false;
    var targetMetadata:Null<SongMetadata> = songMetadata.get(targetVariation);
    if (targetMetadata == null) return false;

    var newDifficulty:String = uniqueDifficultyId(difficulty, targetMetadata.playData.difficulties);
    var wasSelected:Bool = variation == selectedVariation && difficulty == selectedDifficulty;
    if (!duplicateDifficulty(variation, difficulty, targetVariation, newDifficulty)) return false;

    if (wasSelected)
    {
      selectedVariation = targetVariation;
      selectedDifficulty = newDifficulty;
    }
    removeDifficulty(variation, difficulty);
    markDifficultiesChanged();
    return true;
  }

  /**
   * Delete a whole variation. The default variation can't be removed.
   */
  function removeVariation(variation:String):Void
  {
    if (variation == Constants.DEFAULT_VARIATION || !songMetadata.exists(variation)) return;

    if (variation == selectedVariation)
    {
      selectedVariation = Constants.DEFAULT_VARIATION;
      selectedDifficulty = availableDifficulties[0];
    }
    songMetadata.remove(variation);
    songChartData.remove(variation);

    refreshPlayDataVariations();
    markDifficultiesChanged();
  }

  function incrementDifficulty(change:Int):Void
  {
    var variatedDifficulty:String = '$selectedDifficulty-$selectedVariation';
    var currentDifficultyIndex:Int = availableDifficulties.indexOf(selectedDifficulty);
    var currentAllDifficultyIndex:Int = allDifficulties.indexOf(variatedDifficulty);

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
        var prevVariationDifficulties:Array<String> = getAvailableDifficulties(prevVariation);
        var prevDifficulty = prevVariationDifficulties[prevVariationDifficulties.length - 1];

        trace('${selectedVariation}:${selectedDifficulty} -> ${prevVariation}:${prevDifficulty}');
        performCommand(new SwitchDifficultyCommand(selectedDifficulty, prevDifficulty, selectedVariation, prevVariation));

        Conductor.instance.mapTimeChanges(this.currentSongMetadata.timeChanges);
        updateTimeSignature();

        this.refreshToolbox(CHART_EDITOR_TOOLBOX_METADATA_LAYOUT);
        this.refreshToolbox(CHART_EDITOR_TOOLBOX_DIFFICULTY_LAYOUT);
      }
      else
      {
        // Go to previous difficulty in this variation.
        var prevDifficulty = availableDifficulties[currentDifficultyIndex - 1];
        trace('${selectedVariation}:${selectedDifficulty} -> ${selectedVariation}:${prevDifficulty}');
        performCommand(new SwitchDifficultyCommand(selectedDifficulty, prevDifficulty, selectedVariation, selectedVariation));

        this.refreshToolbox(CHART_EDITOR_TOOLBOX_METADATA_LAYOUT);
        this.refreshToolbox(CHART_EDITOR_TOOLBOX_DIFFICULTY_LAYOUT);
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
        var nextVariationDifficulties:Array<String> = getAvailableDifficulties(nextVariation);
        var nextDifficulty = nextVariationDifficulties[0];

        trace('${selectedVariation}:${selectedDifficulty} -> ${nextVariation}:${nextDifficulty}');
        performCommand(new SwitchDifficultyCommand(selectedDifficulty, nextDifficulty, selectedVariation, nextVariation));

        this.refreshToolbox(CHART_EDITOR_TOOLBOX_METADATA_LAYOUT);
        this.refreshToolbox(CHART_EDITOR_TOOLBOX_DIFFICULTY_LAYOUT);
      }
      else
      {
        // Go to next difficulty in this variation.
        var nextDifficulty = availableDifficulties[currentDifficultyIndex + 1];
        trace('${selectedVariation}:${selectedDifficulty} -> ${selectedVariation}:${nextDifficulty}');
        performCommand(new SwitchDifficultyCommand(selectedDifficulty, nextDifficulty, selectedVariation, selectedVariation));

        this.refreshToolbox(CHART_EDITOR_TOOLBOX_DIFFICULTY_LAYOUT);
        this.refreshToolbox(CHART_EDITOR_TOOLBOX_METADATA_LAYOUT);
      }
    }

    // Removed this notification because you can see your difficulty in the playbar now.
    // this.success('Switch Difficulty', 'Switched difficulty to ${selectedDifficulty.toTitleCase()}');
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
      audioInstTrack.time = scrollPositionInMs + playheadPositionInMs - Conductor.instance.instrumentalOffset;
      // Update the songPosition in the Conductor.
      updateSongTime();
      audioVocalTrackGroup.time = audioInstTrack.time;
    }

    // We need to update the note sprites because we changed the scroll position.
    noteDisplayDirty = true;
  }

  function moveScrollPositionToSong():Void
  {
    scrollPositionInPixels = ChartEditorTimeScale.stepToPixels(Conductor.instance.currentStepTime + Conductor.instance.instrumentalOffsetSteps) - playheadPositionInPixels;
    currentScrollEase = scrollPositionInPixels;
  }

  /**
   * Smoothly ease the song to a new scroll position over a duration.
   * @param targetScrollPosition The target position in the song, in pixels.
   */
  function easeSongToScrollPosition(targetScrollPosition:Float):Void
  {
    currentScrollEase = Math.max(0, targetScrollPosition);
    currentScrollEase = Math.min(currentScrollEase, songLengthInPixels);
    scrollPositionInPixels = MathUtil.snap(
      MathUtil.smoothLerpPrecision(scrollPositionInPixels, currentScrollEase, FlxG.elapsed, SCROLL_EASE_DURATION, 1 / 1000),
      currentScrollEase,
      1 / 1000
    );
    moveSongToScrollPosition();
  }

  /**
   * Smoothly ease the song to a new song time in milliseconds.
   * @param songTimeMs The target song time in milliseconds.
   */
  public function easeToSongTimeMs(songTimeMs:Float):Void
  {
    easeSongToScrollPosition(ChartEditorTimeScale.msToPixels(songTimeMs));
  }

  /**
   * Fix the current scroll position after exiting the PlayState used when testing.
   */
  @:nullSafety(Off)
  function resetConductorAfterTest(?closedSubState:FlxSubState):Void
  {
    if (closedSubState != null && (FlxStateUtil.isTransition(closedSubState) || FlxStateUtil.isLoadingState(closedSubState)))
    {
      // The state that closed was a loading screen for the substate we're opening,
      // so we shouldn't do any cleanup.
      return;
    }

    this.persistentUpdate = true;
    this.persistentDraw = true;

    if (displayAutosavePopup)
    {
      displayAutosavePopup = false;
      #if sys
      haxe.ui.Toolkit.callLater(() ->
      {
        var absoluteBackupsPath:String = Path.join([
          Sys.getCwd(),
          ChartEditorImportExportHandler.BACKUPS_PATH
        ]);
        this.infoWithActions('Auto-Save', 'Chart auto-saved to ${absoluteBackupsPath}.', [{
          text: 'Open In Folder',
          callback: openBackupsFolder,
        }]);
      });
      #else
      // TODO: No auto-save on HTML5?
      #end
    }

    moveSongToScrollPosition();

    fadeInWelcomeMusic(WELCOME_MUSIC_FADE_IN_DELAY, WELCOME_MUSIC_FADE_IN_DURATION);

    Cursor.show();

    // Reapply the volume and playback rate.
    var instTargetVolume:Float = (preferencesVolumeInstrumental.value / 100.0) ?? 1.0;
    var vocalPlayerTargetVolume:Float = (preferencesVolumeVocalsPlayer.value / 100.0) ?? 1.0;
    var vocalOpponentTargetVolume:Float = (preferencesVolumeVocalsOpponent.value / 100.0) ?? 1.0;

    var playbackRate = ((menubarItemPlaybackSpeed.value / 100.0) ?? 0.5) * 2.0;
    playbackRate = playbackRate.clamp(0.05, 2.0); // Clamp to 5% to 200%

    if (audioInstTrack != null)
    {
      audioInstTrack.volume = instTargetVolume;
      audioInstTrack.pitch = playbackRate;
      audioInstTrack.onComplete = null;
    }
    if (audioVocalTrackGroup != null)
    {
      audioVocalTrackGroup.playerVolume = vocalPlayerTargetVolume;
      audioVocalTrackGroup.opponentVolume = vocalOpponentTargetVolume;
      audioVocalTrackGroup.pitch = playbackRate;
    }
    if (audioInstTrack != null) audioInstTrack.muted = instrumentalMuted;
    applyVocalMutes();

    noteTooltipsDirty = true;
  }

  /**
   * Updates the Conductor instance and checkes for time signature changes.
   */
  function updateSongTime():Void
  {
    var oldTimeSignatureNum:Int = Conductor.instance.timeSignatureNumerator;
    var oldTimeSignatureDen:Int = Conductor.instance.timeSignatureDenominator;
    Conductor.instance.update(audioInstTrack.time, false);
    if (Conductor.instance.timeSignatureNumerator != oldTimeSignatureNum || Conductor.instance.timeSignatureDenominator != oldTimeSignatureDen)
    {
      updateTimeSignature();
    }
  }

  /**
   * Rebuilds the grid lines and measure numbers after the time signature or a time change was modified.
   */
  function updateTimeSignature():Void
  {
    gridLinesDirty = true;
    measureTicks?.updateMeasureNumbers(true);
  }

  /**
   * Handle positioning the measure ticks sprite.
   */
  function handleMeasureTickPosition():Void
  {
    // var currentMeasureTime = Conductor.instance.getMeasureTimeInMs(Math.floor(Conductor.instance.getTimeInMeasures(scrollPositionInMs)));
    // var currentMeasurePos = currentMeasureTime < 0 ? 0 : Conductor.instance.getTimeInSteps(currentMeasureTime) * GRID_SIZE;
    measureTicks.y = gridTiledSprite?.y;
  }

  /**
   * HAXEUI FUNCTIONS
   */
  // ==================

  /**
   * STATIC FUNCTIONS
   */
  // ==================

  function handleNotePreview():Void
  {
    if (notePreviewDirty && notePreview != null)
    {
      notePreviewDirty = false;
      difficultyHeatmapDirty = true;

      // TODO: Only update the notes that have changed.
      notePreview.erase();
      notePreview.addNotes(currentSongChartNoteData, songLengthInPixels);
      notePreview.addOverlappingNotes(currentOverlappingNotes, songLengthInPixels);
      notePreview.addSelectedNotes(currentNoteSelection, songLengthInPixels);
      notePreview.addEvents(currentSongChartEventData, songLengthInPixels);
    }

    if (difficultyHeatmap != null && difficultyHeatmap.visible && gridTiledSprite != null)
    {
      if (difficultyHeatmapDirty)
      {
        difficultyHeatmapDirty = false;
        difficultyHeatmap.setChart(currentSongChartNoteData, currentSongChartScrollSpeed);
      }
      difficultyHeatmap.refresh(gridTiledSprite.x, gridTiledSprite.y, MENU_BAR_HEIGHT, FlxG.height - PLAYBAR_HEIGHT);
    }

    if (notePreviewViewportBoundsDirty)
    {
      setNotePreviewViewportBounds(calculateNotePreviewViewportBounds());
      notePreviewViewportBoundsDirty = false;
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
      if (undoHistory.length == 0)
      {
        // Disable the Undo button.
        menubarItemUndo.disabled = true;
        menubarItemUndo.text = 'Undo';
      }
      else
      {
        // Change the label to the last command.
        menubarItemUndo.disabled = false;
        menubarItemUndo.text = 'Undo ${undoHistory[undoHistory.length - 1].toString()}';
      }

      if (redoHistory.length == 0)
      {
        // Disable the Redo button.
        menubarItemRedo.disabled = true;
        menubarItemRedo.text = 'Redo';
      }
      else
      {
        // Change the label to the last command.
        menubarItemRedo.disabled = false;
        menubarItemRedo.text = 'Redo ${redoHistory[redoHistory.length - 1].toString()}';
      }
    }
    if (clipboardDirty)
    {
      clipboardDirty = false;

      if (funkin.util.ClipboardUtil.getClipboard() == null || !clipboardValid)
      {
        menubarItemPaste.disabled = true;
        menubarItemPasteUnsnapped.disabled = true;
        clipboardValid = false;
      }
      else if (clipboardValid)
      {
        menubarItemPaste.disabled = false;
        menubarItemPasteUnsnapped.disabled = false;
      }
    }

    if (editButtonsDirty)
    {
      editButtonsDirty = false;

      if (currentEventSelection.length > 0 || currentNoteSelection.length > 0)
      {
        menubarItemCopy.disabled = false;
        menubarItemCut.disabled = false;
        menubarItemDelete.disabled = false;
        menubarItemSelectNone.disabled = false;
      }
      else
      {
        menubarItemCopy.disabled = true;
        menubarItemCut.disabled = true;
        menubarItemDelete.disabled = true;
        menubarItemSelectNone.disabled = true;
      }
      if (currentNoteSelection.length > 0)
      {
        menubarItemFlipNotes.disabled = false;
      }
      else
      {
        menubarItemFlipNotes.disabled = true;
      }
    }
  }

  /**
   * Handle the playback of hitsounds.
   */
  var _scriptNoteObj:NoteSprite = null;

  var _currentEvents = null;
  var _allowedEvents = null;
  var _eventTarget:Null<CharacterPlayer> = null;

  public static var _allowedEventsNames:Array<String> = ['PlayAnimation', 'SetTargetBopSpeed'];

  function handleMusicPositionUpdate(oldSongPosition:Float, newSongPosition:Float):Void
  {
    _currentEvents = SongDataUtils.getEventsInTimeRange(currentSongChartEventData, oldSongPosition, newSongPosition);
    _allowedEvents = SongDataUtils.getEventsWithKind(_currentEvents, _allowedEventsNames);

    // Assume notes are sorted by time.
    for (noteData in currentSongChartNoteData)
    {
      // Check for notes between the old and new song positions.

      if (noteData.time < oldSongPosition) // Note is in the past.
        continue;

      if (noteData.time > newSongPosition) break;

      /**
       * We hit a note.
       * We're gonna create scripted event and dispatch it all over the Chart Editor.
       */
      _scriptNoteObj = new NoteSprite(NoteStyleRegistry.instance.fetchDefault());
      _scriptNoteObj.noteData = noteData;
      _scriptNoteObj.kill();
      _scriptNoteObj.direction = _scriptNoteObj.noteData?.getDirection() ?? 0;
      _scriptNoteObj.scrollFactor.set();

      var event = HitNoteScriptEvent.get(_scriptNoteObj, 0.0, 0, (noteData.getStrumlineIndex() == 0 ? 'perfect' : 'sick'), false, 0);
      dispatchEvent(event, false);

      // Calling event.cancelEvent() skips all the other logic! Neat!
      if (event.eventCanceled)
      {
        _scriptNoteObj = null;
        event.finish();

        continue;
      }

      // Hitsounds.
      if (hitsoundsEnabled)
      {
        switch (noteData.getStrumlineIndex())
        {
          case 0: // Player
            if (hitsoundVolumePlayer > 0) this.playSound(
              Paths.sound('ui/editors/chart-editor/charting-sounds/hitsound-player').toString(),
              hitsoundVolumePlayer
            );
          case 1: // Opponent
            if (hitsoundVolumeOpponent > 0) this.playSound(
              Paths.sound('ui/editors/chart-editor/charting-sounds/hitsound-opponent').toString(),
              hitsoundVolumeOpponent
            );
        }
      }

      event.finish();
    }

    for (data in _allowedEvents)
    {
      switch (data.eventKind)
      {
        case 'PlayAnimation':
          switch (data.getString('target').toLowerCase().trim())
          {
            case 'boyfriend' | 'bf' | 'player':
              _eventTarget = currentPlayerCharacterPlayer;
            case 'dad' | 'opponent':
              _eventTarget = currentOpponentCharacterPlayer;
            default:
          }
          if (_eventTarget != null) _eventTarget.playAnimManually(data.getString('anim') ?? 'idle', data.getBool('force') ?? false);

        case 'SetTargetBopSpeed':
          switch (data.getString('target').toLowerCase().trim())
          {
            case 'boyfriend' | 'bf' | 'player':
              _eventTarget = currentPlayerCharacterPlayer;
            case 'dad' | 'opponent':
              _eventTarget = currentOpponentCharacterPlayer;
            default:
          }
          if (_eventTarget != null) _eventTarget.setBopSpeed(data.getFloat('rate') ?? Constants.DEFAULT_PROP_RATE);
      }
    }

    _currentEvents = null;
    _allowedEvents.resize(0);
    _eventTarget = null;
  }

  /**
   * Stop playback of the chart's instrumental and vocals.
   * @param welcomeMusic If `true`, queue the welcome music to play after a timeout. `false` to force the welcome music to stop too.
   */
  function stopAudioPlayback(welcomeMusic:Bool = true):Void
  {
    if (audioInstTrack == null && audioVocalTrackGroup.length == 0) return;

    if (audioInstTrack != null) audioInstTrack.pause();
    audioVocalTrackGroup.pause();
    if (welcomeMusic)
    {
      fadeInWelcomeMusic(WELCOME_MUSIC_FADE_IN_DELAY, WELCOME_MUSIC_FADE_IN_DURATION);
    }
    else
    {
      // Force the welcome music to stop too.
      stopWelcomeMusic();
    }

    playbarPlay.text = '>';
  }

  function toggleAudioPlayback():Void
  {
    if (audioInstTrack == null && audioVocalTrackGroup.length == 0) return;

    currentScrollEase = this.scrollPositionInPixels;

    if (audioInstTrack.isPlaying || audioVocalTrackGroup.playing)
    {
      // Pause
      stopAudioPlayback();
    }
    else
    {
      // Don't allow the audio to be played while we're dragging any of the playheads
      if (playbarHeadDragging || gridPlayheadScrollAreaPressed || notePreviewPlayHeadDragging) return;
      // Play
      startAudioPlayback();
    }
  }

  function scrollMouseToGrid(?speed:Float = 0.5):Void
  {
    // Scroll the screen if the mouse is above or below the grid.
    if (FlxG.mouse.viewY < MENU_BAR_HEIGHT)
    {
      // Scroll up.
      var diff:Float = MENU_BAR_HEIGHT - FlxG.mouse.viewY;
      currentScrollEase -= diff * speed; // Too fast!
    }
    else if (FlxG.mouse.viewY > (playbarHeadLayout?.y ?? 0.0))
    {
      // Scroll down.
      var diff:Float = FlxG.mouse.viewY - (playbarHeadLayout?.y ?? 0.0);
      currentScrollEase += (diff * speed); // Too fast!
    }
  }

  public function postLoadInstrumental():Void
  {
    // Reapply the volume and playback rate.
    var instTargetVolume:Float = ((preferencesVolumeInstrumental.value / 100) ?? 1.0);
    var playbackRate:Float = ((menubarItemPlaybackSpeed.value / 100.0) ?? 0.5) * 2.0;
    playbackRate = playbackRate.clamp(0.05, 2.0); // Clamp to 5% to 200%
    if (audioInstTrack != null)
    {
      // Prevent the time from skipping back to 0 when the song ends.
      audioInstTrack.onComplete = function()
      {
        if (audioInstTrack != null)
        {
          audioInstTrack.pause();
          // Keep the track at the end.
          audioInstTrack.time = audioInstTrack.length;
        }
        audioVocalTrackGroup.pause();
      };
      audioInstTrack.volume = instTargetVolume;
      audioInstTrack.pitch = playbackRate;
      audioInstTrack.muted = instrumentalMuted;
    }
    else
    {
      trace('ERROR: Instrumental track is null!');
    }
    Conductor.instance.mapTimeChanges(this.currentSongMetadata.timeChanges);
    updateTimeSignature();
    @:privateAccess measureTicks?.updateMeasureNumbers(true);

    this.songLengthInMs = (audioInstTrack?.length ?? 1000.0) + Conductor.instance.instrumentalOffset;
    Conductor.instance.update(0, false);

    // Many things get reset when song length changes.
    healthIconsDirty = true;
    playerPreviewDirty = true;
    opponentPreviewDirty = true;
  }

  public function loadSubtitles():Void
  {
    var subtitlesFile:String = 'gameplay/songs/${currentSongId}/subtitles/song-lyrics';
    if (selectedVariation != Constants.DEFAULT_VARIATION)
    {
      subtitlesFile += '-${selectedVariation}';
    }
    subtitles.assignSubtitles(subtitlesFile, audioInstTrack);
  }

  public function postLoadVocals():Void
  {
    // Reapply the volume and playback rate.
    var vocalPlayerTargetVolume:Float = (preferencesVolumeVocalsPlayer.value / 100.0) ?? 1.0;
    var vocalOpponentTargetVolume:Float = (preferencesVolumeVocalsOpponent.value / 100.0) ?? 1.0;
    var playbackRate:Float = ((menubarItemPlaybackSpeed.value / 100.0) ?? 0.5) * 2.0;
    playbackRate = playbackRate.clamp(0.05, 2.0); // Clamp to 5% to 200%

    if (audioVocalTrackGroup != null)
    {
      audioVocalTrackGroup.playerVolume = vocalPlayerTargetVolume;
      audioVocalTrackGroup.opponentVolume = vocalOpponentTargetVolume;
      audioVocalTrackGroup.pitch = playbackRate;
    }
    // Newly loaded tracks start unmuted.
    applyVocalMutes();
  }

  /**
   * Whether the `Audio -> Mute Player Vocals` toggle is on.
   */
  var playerVocalsMuted(default, set):Bool = false;

  function set_playerVocalsMuted(value:Bool):Bool
  {
    playerVocalsMuted = value;
    applyVocalMutes();
    return playerVocalsMuted;
  }

  /**
   * Whether the `Audio -> Mute Opponent Vocals` toggle is on.
   */
  var opponentVocalsMuted(default, set):Bool = false;

  function set_opponentVocalsMuted(value:Bool):Bool
  {
    opponentVocalsMuted = value;
    applyVocalMutes();
    return opponentVocalsMuted;
  }

  function applyVocalMutes():Void
  {
    if (audioVocalTrackGroup == null) return;
    // A legacy shared Voices file is added as the player's track, so it follows the player toggle.
    audioVocalTrackGroup.playerVoices?.forEach(voice -> voice.muted = playerVocalsMuted);
    audioVocalTrackGroup.opponentVoices?.forEach(voice -> voice.muted = opponentVocalsMuted);
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

  /**
   * Clear the voices group.
   */
  public function clearVocals():Void
  {
    audioVocalTrackGroup.clear();
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
    resetWindowTitle();

    cleanupAutoSave();

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
    WindowUtil.setWindowTitle('Friday Night Funkin\' Chart Editor - ${inner} ');
  }

  function resetWindowTitle():Void
  {
    WindowUtil.setWindowTitle('Friday Night Funkin\'');
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
