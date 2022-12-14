package funkin.ui.debug.charting;

import funkin.play.song.SongData.SongDataParser;
import funkin.play.song.Song;
import lime.media.AudioBuffer;
import funkin.input.Cursor;
import flixel.FlxSprite;
import flixel.addons.display.FlxSliceSprite;
import flixel.addons.display.FlxTiledSprite;
import flixel.group.FlxSpriteGroup;
import flixel.math.FlxPoint;
import flixel.math.FlxRect;
import flixel.system.FlxSound;
import flixel.util.FlxColor;
import flixel.util.FlxSort;
import flixel.util.FlxTimer;
import funkin.audio.visualize.PolygonSpectogram;
import funkin.play.HealthIcon;
import funkin.play.song.SongData.SongChartData;
import funkin.play.song.SongData.SongEventData;
import funkin.play.song.SongData.SongMetadata;
import funkin.play.song.SongData.SongNoteData;
import funkin.play.song.SongDataUtils;
import funkin.play.song.SongSerializer;
import funkin.ui.debug.charting.ChartEditorCommand;
import funkin.ui.debug.charting.ChartEditorThemeHandler.ChartEditorTheme;
import funkin.ui.debug.charting.ChartEditorToolboxHandler.ChartEditorToolMode;
import funkin.ui.haxeui.HaxeUIState;
import funkin.util.Constants;
import haxe.ui.components.Button;
import haxe.ui.components.CheckBox;
import haxe.ui.components.Label;
import haxe.ui.components.Slider;
import haxe.ui.containers.SideBar;
import haxe.ui.containers.TreeView;
import haxe.ui.containers.TreeViewNode;
import haxe.ui.containers.dialogs.Dialog;
import haxe.ui.containers.dialogs.MessageBox;
import haxe.ui.containers.menus.MenuCheckBox;
import haxe.ui.containers.menus.MenuItem;
import haxe.ui.core.Component;
import haxe.ui.core.Screen;
import haxe.ui.events.DragEvent;
import haxe.ui.events.MouseEvent;
import haxe.ui.events.UIEvent;
import openfl.display.BitmapData;
import openfl.geom.Rectangle;

using Lambda;
using StringTools;

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
	static final CHART_EDITOR_TOOLBOX_SONGDATA_LAYOUT = Paths.ui('chart-editor/toolbox/songdata');

	// The base grid size for the chart editor.
	public static final GRID_SIZE:Int = 40;

	// Number of notes in each strumline.
	public static final STRUMLINE_SIZE = 4;

	// The height of the menu bar in the layout.
	static final MENU_BAR_HEIGHT = 32;

	// The amount of padding between the menu bar and the chart grid when fully scrolled up.
	static final GRID_TOP_PAD:Int = 8;

	public static final PLAYHEAD_SCROLL_AREA_WIDTH:Int = 12;
	public static final PLAYHEAD_HEIGHT:Int = Std.int(GRID_SIZE / 8);

	public static final GRID_SELECTION_BORDER_WIDTH:Int = 6;

	// Duration until notifications are automatically hidden.
	static final NOTIFICATION_DISMISS_TIME:Float = 3.0;

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
		return scrollPositionInSteps * Conductor.stepCrochet;
	}

	function set_scrollPositionInMs(value:Float):Float
	{
		scrollPositionInPixels = value / Conductor.stepCrochet;
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
		return playheadPositionInSteps * Conductor.stepCrochet;
	}

	/**
	 * This is the song's length in PIXELS, same format as scrollPosition.
	 */
	var songLengthInPixels(get, default):Int;

	function get_songLengthInPixels():Int
	{
		if (songLengthInPixels <= 0)
			return 1000;

		return songLengthInPixels;
	}

	/**
	 * songLength, converted to steps.
	 */
	var songLengthInSteps(get, null):Float;

	function get_songLengthInSteps():Float
	{
		return songLengthInPixels / GRID_SIZE;
	}

	/**
	 * songLength, converted to milliseconds.
	 */
	var songLengthInMs(get, null):Float;

	function get_songLengthInMs():Float
	{
		return songLengthInSteps * Conductor.stepCrochet;
	}

	var currentTheme(default, set):ChartEditorTheme = null;

	function set_currentTheme(value:ChartEditorTheme):ChartEditorTheme
	{
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
	 * Use the input in the sidebar to change this.
	 */
	var selectedNoteKind:String = '';

	/**
	 * Whether to play a metronome sound while the playhead is moving.
	 */
	var shouldPlayMetronome:Bool = true;

	/**
	 * Use the tool window to affect how the user interacts with the program.
	 */
	var currentToolMode:ChartEditorToolMode = ChartEditorToolMode.Select;

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
	 * Whether the difficulty tree view in the sidebar has been modified and needs to be updated.
	 * This happens when we add/remove difficulties.
	 */
	var difficultySelectDirty:Bool = true;

	var isInPlaytestMode:Bool = false;

	/**
	 * The list of command previously performed. Used for undoing previous actions.
	 */
	var undoHistory:Array<ChartEditorCommand> = [];

	/**
	 * The list of commands that have been undone. Used for redoing previous actions.
	 */
	var redoHistory:Array<ChartEditorCommand> = [];

	var undoHeldTime:Float = 0.0;

	var redoHeldTime:Float = 0.0;

	/**
	 * Whether the undo/redo histories have changed since the last time the UI was updated.
	 */
	var commandHistoryDirty:Bool = true;

	/**
	 * The notes which are currently in the selection.
	 */
	var currentSelection:Array<SongNoteData> = [];

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
	 * TODO: Replace with a VocalSoundGroup.
	 */
	var audioVocalTrackGroup:VoicesGroup;

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
		currentSongChartData.events = value;
		return value;
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

	var renderedNoteSelectionSquares:FlxTypedSpriteGroup<FlxSprite>;

	var notifBar:SideBar;
	var playbarHead:Slider;

	public function new()
	{
		// Load the HaxeUI XML file.
		super(CHART_EDITOR_LAYOUT);
	}

	override function create()
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

		// TODO: We should be loading the music later when the user requests it.
		// loadDefaultMusic();

		// TODO: Change to false.
		var canCloseInitialDialog = true;
		ChartEditorDialogHandler.openWelcomeDialog(this, canCloseInitialDialog);
	}

	function buildDefaultSongData()
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
	function buildBackground()
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
	function buildGrid()
	{
		gridTiledSprite = new FlxTiledSprite(gridBitmap, gridBitmap.width, 1000, false, true);
		gridTiledSprite.x = FlxG.width / 2 - GRID_SIZE * STRUMLINE_SIZE; // Center the grid.
		gridTiledSprite.y = MENU_BAR_HEIGHT + GRID_TOP_PAD; // Push down to account for the menu bar.
		add(gridTiledSprite);

		gridGhostNote = new ChartEditorNoteSprite(this);
		gridGhostNote.alpha = 0.8;
		gridGhostNote.noteData = new SongNoteData(-1, -1, 0, "");
		gridGhostNote.visible = false;
		add(gridGhostNote);

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

	function buildSelectionBox()
	{
		selectionBoxSprite.scrollFactor.set(0, 0);
		add(selectionBoxSprite);

		setSelectionBoxBounds();
	}

	function setSelectionBoxBounds(?bounds:FlxRect = null)
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

	function buildSpectrogram(target:FlxSound)
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
	function buildNoteGroup()
	{
		renderedNotes = new FlxTypedSpriteGroup<ChartEditorNoteSprite>();
		renderedNotes.setPosition(gridTiledSprite.x, gridTiledSprite.y);
		add(renderedNotes);

		renderedNoteSelectionSquares = new FlxTypedSpriteGroup<FlxSprite>();
		renderedNoteSelectionSquares.setPosition(gridTiledSprite.x, gridTiledSprite.y);
		add(renderedNoteSelectionSquares);

		/*
			var sustainSprite:SustainTrail = new SustainTrail(0, 600, Paths.image('NOTE_hold_assets'), 0.9, false);
			sustainSprite.scrollFactor.set(0, 0);
			sustainSprite.x = gridTiledSprite.x;
			sustainSprite.y = gridTiledSprite.y + 32;
			sustainSprite.zoom *= 0.258; // 0.77;
			add(sustainSprite);
		 */
	}

	function buildAdditionalUI():Void
	{
		notifBar = cast buildComponent(CHART_EDITOR_NOTIFBAR_LAYOUT);

		add(notifBar);

		var playbarHeadLayout:Component = buildComponent(CHART_EDITOR_PLAYBARHEAD_LAYOUT);

		playbarHeadLayout.width = FlxG.width;
		playbarHeadLayout.height = 10;
		playbarHeadLayout.x = 0;
		playbarHeadLayout.y = FlxG.height - 48 - 8;

		playbarHead = playbarHeadLayout.findComponent('playbarHead', Slider);
		playbarHead.allowFocus = false;
		playbarHead.width = FlxG.width;
		playbarHead.height = 10;
		playbarHead.styleString = "padding-left: 0px; padding-right: 0px; border-left: 0px; border-right: 0px;";

		playbarHead.onDragStart = function(_:DragEvent)
		{
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

		playbarHead.onDragEnd = function(_:DragEvent)
		{
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

		addUIClickListener('playbarPlay', (event:MouseEvent) -> toggleAudioPlayback());
		addUIClickListener('playbarStart', (event:MouseEvent) -> playbarButtonPressed = 'playbarStart');
		addUIClickListener('playbarBack', (event:MouseEvent) -> playbarButtonPressed = 'playbarBack');
		addUIClickListener('playbarForward', (event:MouseEvent) -> playbarButtonPressed = 'playbarForward');
		addUIClickListener('playbarEnd', (event:MouseEvent) -> playbarButtonPressed = 'playbarEnd');

		// Add functionality to the menu items.

		addUIClickListener('menubarItemNewChart', (event:MouseEvent) -> ChartEditorDialogHandler.openWelcomeDialog(this, true));
		addUIClickListener('menubarItemLoadInst', (event:MouseEvent) -> ChartEditorDialogHandler.openUploadInstDialog(this, true));

		addUIClickListener('menubarItemUndo', (event:MouseEvent) -> undoLastCommand());

		addUIClickListener('menubarItemRedo', (event:MouseEvent) -> redoLastCommand());

		addUIClickListener('menubarItemCopy', (event:MouseEvent) ->
		{
			SongDataUtils.writeNotesToClipboard(SongDataUtils.buildClipboard(currentSelection));
		});

		addUIClickListener('menubarItemCut', (event:MouseEvent) ->
		{
			performCommand(new CutNotesCommand(currentSelection));
		});

		addUIClickListener('menubarItemPaste', (event:MouseEvent) ->
		{
			performCommand(new PasteNotesCommand(scrollPositionInMs + playheadPositionInMs));
		});

		addUIClickListener('menubarItemDelete', (event:MouseEvent) ->
		{
			performCommand(new RemoveNotesCommand(currentSelection));
		});

		addUIClickListener('menubarItemSelectAll', (event:MouseEvent) ->
		{
			performCommand(new SelectAllNotesCommand(currentSelection));
		});

		addUIClickListener('menubarItemSelectInverse', (event:MouseEvent) ->
		{
			performCommand(new InvertSelectedNotesCommand(currentSelection));
		});

		addUIClickListener('menubarItemSelectNone', (event:MouseEvent) ->
		{
			performCommand(new DeselectAllNotesCommand(currentSelection));
		});

		addUIClickListener('menubarItemSelectRegion', (event:MouseEvent) -> {
			// TODO: Implement this.
		});

		addUIClickListener('menubarItemSelectBeforeCursor', (event:MouseEvent) -> {
			// TODO: Implement this.
		});

		addUIClickListener('menubarItemSelectAfterCursor', (event:MouseEvent) -> {
			// TODO: Implement this.
		});

		addUIClickListener('menubarItemAbout', (event:MouseEvent) -> ChartEditorDialogHandler.openAboutDialog(this));

		addUIClickListener('menubarItemUserGuide', (event:MouseEvent) -> ChartEditorDialogHandler.openUserGuideDialog(this));

		addUIChangeListener('menubarItemToggleSidebar', (event:UIEvent) ->
		{
			var sidebar:Component = findComponent('sidebar', Component);

			sidebar.visible = event.value;
		});
		setUISelected('menubarItemToggleSidebar', true);

		addUIChangeListener('menubarItemDownscroll', (event:UIEvent) ->
		{
			isViewDownscroll = event.value;
		});
		setUISelected('menubarItemDownscroll', isViewDownscroll);

		addUIChangeListener('menubarItemMetronomeEnabled', (event:UIEvent) ->
		{
			shouldPlayMetronome = event.value;
		});
		setUISelected('menubarItemMetronomeEnabled', shouldPlayMetronome);

		addUIChangeListener('menubarItemPlayerHitsounds', (event:UIEvent) ->
		{
			hitsoundsEnabledPlayer = event.value;
		});
		setUISelected('menubarItemPlayerHitsounds', hitsoundsEnabledPlayer);

		addUIChangeListener('menubarItemOpponentHitsounds', (event:UIEvent) ->
		{
			hitsoundsEnabledOpponent = event.value;
		});
		setUISelected('menubarItemOpponentHitsounds', hitsoundsEnabledOpponent);

		var instVolumeLabel:Label = findComponent('menubarLabelVolumeInstrumental', Label);
		addUIChangeListener('menubarItemVolumeInstrumental', (event:UIEvent) ->
		{
			var volume:Float = event.value / 100.0;
			if (audioInstTrack != null)
				audioInstTrack.volume = volume;
			instVolumeLabel.text = 'Instrumental - ${Std.int(event.value)}%';
		});

		var vocalsVolumeLabel:Label = findComponent('menubarLabelVolumeVocals', Label);
		addUIChangeListener('menubarItemVolumeVocals', (event:UIEvent) ->
		{
			var volume:Float = event.value / 100.0;
			if (audioVocalTrackGroup != null)
				audioVocalTrackGroup.volume = volume;
			vocalsVolumeLabel.text = 'Vocals - ${Std.int(event.value)}%';
		});

		var playbackSpeedLabel:Label = findComponent('menubarLabelPlaybackSpeed', Label);
		addUIChangeListener('menubarItemPlaybackSpeed', (event:UIEvent) ->
		{
			var pitch = event.value * 2.0 / 100.0;
			#if FLX_PITCH
			if (audioInstTrack != null)
				audioInstTrack.pitch = pitch;
			if (audioVocalTrackGroup != null)
				audioVocalTrackGroup.pitch = pitch;
			#end
			playbackSpeedLabel.text = 'Playback Speed - ${Std.int(event.value * 100) / 100}x';
		});

		addUIChangeListener('menubarItemToggleToolboxTools', (event:UIEvent) ->
		{
			ChartEditorToolboxHandler.setToolboxState(this, CHART_EDITOR_TOOLBOX_TOOLS_LAYOUT, event.value);
		});
		setUISelected('menubarItemToggleToolboxTools', true);

		addUIChangeListener('menubarItemToggleToolboxNotes', (event:UIEvent) ->
		{
			ChartEditorToolboxHandler.setToolboxState(this, CHART_EDITOR_TOOLBOX_NOTEDATA_LAYOUT, event.value);
		});
		addUIChangeListener('menubarItemToggleToolboxEvents', (event:UIEvent) ->
		{
			ChartEditorToolboxHandler.setToolboxState(this, CHART_EDITOR_TOOLBOX_EVENTDATA_LAYOUT, event.value);
		});
		addUIChangeListener('menubarItemToggleToolboxSong', (event:UIEvent) ->
		{
			ChartEditorToolboxHandler.setToolboxState(this, CHART_EDITOR_TOOLBOX_SONGDATA_LAYOUT, event.value);
		});

		addUIClickListener('sidebarSaveMetadata', (event:MouseEvent) ->
		{
			// Save metadata for current variation.
			SongSerializer.exportSongMetadata(currentSongMetadata);
		});
		addUIClickListener('sidebarSaveChart', (event:MouseEvent) ->
		{
			// Save chart data for current variation.
			SongSerializer.exportSongChartData(currentSongChartData);
		});
		addUIClickListener('sidebarLoadMetadata', (event:MouseEvent) ->
		{
			// Replace metadata for current variation.
			SongSerializer.importSongMetadataAsync(function(songMetadata:SongMetadata)
			{
				currentSongMetadata = songMetadata;
			});
		});
		addUIClickListener('sidebarLoadChart', (event:MouseEvent) ->
		{
			// Replace chart data for current variation.
			SongSerializer.importSongChartDataAsync(function(songChartData:SongChartData)
			{
				currentSongChartData = songChartData;

				noteDisplayDirty = true;
			});
		});
		addUIChangeListener('sidebarSongName', (event:UIEvent) ->
		{
			// Set song name (for current variation)
			currentSongName = event.value;
		});
		setUIValue('sidebarSongName', currentSongName);
		addUIChangeListener('sidebarSongArtist', (event:UIEvent) ->
		{
			currentSongArtist = event.value;
		});
		setUIValue('sidebarSongArtist', currentSongArtist);
		addUIChangeListener('sidebarStage', (event:UIEvent) ->
		{
			currentSongStage = event.value;
		});
		setUIValue('sidebarStage', currentSongStage);
		addUIChangeListener('sidebarNoteSkin', (event:UIEvent) ->
		{
			currentSongNoteSkin = event.value;
		});
		setUIValue('sidebarNoteSkin', currentSongNoteSkin);
		// TODO: Pass specific HaxeUI components to add context menus to them.
		registerContextMenu(null, Paths.ui('chart-editor/context/test'));
	}

	public override function update(elapsed:Float)
	{
		super.update(elapsed);

		FlxG.mouse.visible = true;

		// These ones happen even if the modal dialog is open.
		handleMusicPlayback();
		handleNoteDisplay();

		// These ones only happen if the modal dialog is not open.
		handleScrollKeybinds();
		handleZoom();
		handleSnap();
		handleCursor();

		handleMenubar();
		handleSidebar();
		handlePlaybar();
		handlePlayhead();

		handleFileKeybinds();
		handleEditKeybinds();
		handleViewKeybinds();
		handleHelpKeybinds();

		// DEBUG
		if (FlxG.keys.justPressed.F)
		{
			showNotification('Hi there :)');
		}

		if (FlxG.keys.justPressed.Q)
		{
			ChartEditorDialogHandler.openWelcomeDialog(this, true);
		}

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
		if (!super.beatHit())
			return false;

		if (shouldPlayMetronome && audioInstTrack.playing)
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
		if (!super.stepHit())
			return false;

		if (audioInstTrack.playing)
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
	function handleScrollKeybinds()
	{
		// Don't scroll when the cursor is over the UI.
		if (isCursorOverHaxeUI)
			return;

		// Amount to scroll the grid.
		var scrollAmount:Float = 0;
		// Amount to scroll the playhead relative to the grid.
		var playheadAmount:Float = 0;

		// Up Arrow = Scroll Up
		if (FlxG.keys.justPressed.UP)
		{
			scrollAmount = -GRID_SIZE * 0.25;
		}
		// Down Arrow = Scroll Down
		if (FlxG.keys.justPressed.DOWN)
		{
			scrollAmount = GRID_SIZE * 0.25;
		}

		// PAGE UP = Jump Up 1 Measure
		if (FlxG.keys.justPressed.PAGEUP)
		{
			scrollAmount = -GRID_SIZE * 4 * Conductor.beatsPerMeasure;
		}
		if (playbarButtonPressed == 'playbarBack')
		{
			playbarButtonPressed = '';
			scrollAmount = -GRID_SIZE * 4 * Conductor.beatsPerMeasure;
		}

		// PAGE DOWN = Jump Down 1 Measure
		if (FlxG.keys.justPressed.PAGEDOWN)
		{
			scrollAmount = GRID_SIZE * 4 * Conductor.beatsPerMeasure;
		}
		if (playbarButtonPressed == 'playbarForward')
		{
			playbarButtonPressed = '';
			scrollAmount = GRID_SIZE * 4 * Conductor.beatsPerMeasure;
		}

		// Mouse Wheel = Scroll
		if (FlxG.mouse.wheel != 0 && !FlxG.keys.pressed.CONTROL)
		{
			scrollAmount = -10 * FlxG.mouse.wheel;
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
		}

		// HOME = Scroll to Top
		if (FlxG.keys.justPressed.HOME)
		{
			// Scroll amount is the difference between the current position and the top.
			scrollAmount = 0 - this.scrollPositionInPixels;
			playheadAmount = 0 - this.playheadPositionInPixels;
		}
		if (playbarButtonPressed == 'playbarStart')
		{
			playbarButtonPressed = '';
			scrollAmount = 0 - this.scrollPositionInPixels;
			playheadAmount = 0 - this.playheadPositionInPixels;
		}

		// END = Scroll to Bottom
		if (FlxG.keys.justPressed.END)
		{
			// Scroll amount is the difference between the current position and the bottom.
			scrollAmount = this.songLengthInPixels - this.scrollPositionInPixels;
		}
		if (playbarButtonPressed == 'playbarEnd')
		{
			playbarButtonPressed = '';
			scrollAmount = this.songLengthInPixels - this.scrollPositionInPixels;
		}

		// Apply the scroll amount.
		this.scrollPositionInPixels += scrollAmount;
		this.playheadPositionInPixels += playheadAmount;

		// Resync the conductor and audio tracks.
		if (scrollAmount != 0 || playheadAmount != 0)
			moveSongToScrollPosition();
	}

	function handleZoom()
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

	function handleSnap()
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
	function handleCursor()
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
			var cursorMs:Float = cursorStep * Conductor.stepCrochet * (16 / noteSnapQuant);
			// The direction value for the column at the cursor.
			var cursorColumn:Int = Math.floor(cursorX / GRID_SIZE);
			if (cursorColumn < 0)
				cursorColumn = 0;
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

				// Determine if we moved the mouse at all.
				if (Math.abs(cursorX - cursorXStart) > DRAG_THRESHOLD || Math.abs(cursorY - cursorYStart) > DRAG_THRESHOLD)
				{
					// Handle releasing the selection box.
					if (FlxG.mouse.justReleased)
					{
						// We released the mouse. Select the notes in the box.
						var cursorFractionalStepStart:Float = cursorYStart / GRID_SIZE;
						var cursorStepStart:Int = Math.floor(cursorFractionalStepStart);
						var cursorMsStart:Float = cursorStepStart * Conductor.stepCrochet;
						var cursorColumnBase:Int = Math.floor(cursorX / GRID_SIZE);
						var cursorColumnBaseStart:Int = Math.floor(cursorXStart / GRID_SIZE);

						// Since this selects based on noteData directly,
						// we don't need to specifically exclude sustain pieces.

						var notesToSelect:Array<SongNoteData> = currentSongChartNoteData;
						notesToSelect = SongDataUtils.getNotesInTimeRange(notesToSelect, Math.min(cursorMsStart, cursorMs), Math.max(cursorMsStart, cursorMs));

						// This logic is gross because the columns go 4567-0123-8.
						// We build a list of columns to select.
						var columnStart:Int = Std.int(Math.min(cursorColumnBase, cursorColumnBaseStart));
						var columnEnd:Int = Std.int(Math.max(cursorColumnBase, cursorColumnBaseStart));
						var columns:Array<Int> = [for (i in columnStart...(columnEnd + 1)) i].map(function(i:Int):Int
						{
							if (i >= (STRUMLINE_SIZE * 2 + 1 - 1))
							{
								// Don't invert the event column.
								return (STRUMLINE_SIZE * 2 + 1 - 1);
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
						notesToSelect = SongDataUtils.getNotesWithData(notesToSelect, columns);

						if (notesToSelect != null && notesToSelect.length > 0)
						{
							if (FlxG.keys.pressed.CONTROL)
							{
								// Add to the selection.
								performCommand(new SelectNotesCommand(notesToSelect));
							}
							else
							{
								// Set the selection.
								performCommand(new SetNoteSelectionCommand(notesToSelect, currentSelection));
							}
						}
						else
						{
							// We made a selection box, but it didn't select anything.
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
						var highlightedNote:ChartEditorNoteSprite = renderedNotes.members.find(function(note:ChartEditorNoteSprite):Bool
						{
							// If note.alive is false, the note is dead and awaiting recycling.
							return note.alive && FlxG.mouse.overlaps(note);
						});

						if (FlxG.keys.pressed.CONTROL)
						{
							if (highlightedNote != null)
							{
								// Handle the case of clicking on a sustain piece.
								highlightedNote = highlightedNote.getBaseNoteSprite();
								// Control click to select/deselect an individual note.
								if (isNoteSelected(highlightedNote.noteData))
								{
									performCommand(new DeselectNotesCommand([highlightedNote.noteData]));
								}
								else
								{
									performCommand(new SelectNotesCommand([highlightedNote.noteData]));
								}
							}
							else
							{
								if (highlightedNote != null)
								{
									// Click to select an individual note and deselect everything else.
									if (isNoteSelected(highlightedNote.noteData))
									{
										performCommand(new SetNoteSelectionCommand([highlightedNote.noteData], currentSelection));
									}
									else
									{
										// Do nothing if you control-clicked on an empty space.
									}
								}
							}
						}
						else
						{
							if (highlightedNote != null)
							{
								// Click a note to select it.
								performCommand(new SetNoteSelectionCommand([highlightedNote.noteData], currentSelection));
							}
							else
							{
								// Click on an empty space to deselect everything.
								// We don't place a note since this is the Select tool mode.
								performCommand(new DeselectAllNotesCommand(currentSelection));
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

				// Since use Math.floor and stepCrochet here, the hold notes will be beat snapped.
				var dragLengthSteps:Float = Math.floor((cursorMs - currentPlaceNoteData.time) / Conductor.stepCrochet);

				// Without this, the newly placed note feels too short compared to the user's input.
				var INCREMENT:Float = 1.0;
				var dragLengthMs:Float = (dragLengthSteps + INCREMENT) * Conductor.stepCrochet;

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
						var highlightedNote:ChartEditorNoteSprite = renderedNotes.members.find(function(note:ChartEditorNoteSprite):Bool
						{
							// If note.alive is false, the note is dead and awaiting recycling.
							return note.alive && FlxG.mouse.overlaps(note);
						});

						if (FlxG.keys.pressed.CONTROL)
						{
							// Control click to select/deselect an individual note.
							if (isNoteSelected(highlightedNote.noteData))
							{
								performCommand(new DeselectNotesCommand([highlightedNote.noteData]));
							}
							else
							{
								performCommand(new SelectNotesCommand([highlightedNote.noteData]));
							}
						}
						else
						{
							if (highlightedNote != null)
							{
								// Click a note to select it.
								performCommand(new SetNoteSelectionCommand([highlightedNote.noteData], currentSelection));
							}
							else
							{
								// Click a blank space to place a note and select it.

								if (cursorColumn == eventColumn)
								{
									// Create an event and place it in the chart.
									// TODO: Allow configuring the event to place from the sidebar.
									var newEventData:SongEventData = new SongEventData(cursorMs, "test", {});

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
					var highlightedNote:ChartEditorNoteSprite = renderedNotes.members.find(function(note:ChartEditorNoteSprite):Bool
					{
						// If note.alive is false, the note is dead and awaiting recycling.
						return note.alive && FlxG.mouse.overlaps(note);
					});

					if (highlightedNote != null)
					{
						// Handle the case of clicking on a sustain piece.
						highlightedNote = highlightedNote.getBaseNoteSprite();
						// Remove the note.
						performCommand(new RemoveNotesCommand([highlightedNote.noteData]));
					}
				}

				// Handle grid cursor.
				if (overlapsGrid && !overlapsSelectionBorder && !gridPlayheadScrollAreaPressed)
				{
					Cursor.cursorMode = Pointer;

					// Indicate that we can pla
					gridGhostNote.visible = (cursorColumn != eventColumn);

					if (cursorColumn != gridGhostNote.noteData.data || selectedNoteKind != gridGhostNote.noteData.kind) {
						gridGhostNote.noteData.kind = selectedNoteKind;
						gridGhostNote.noteData.data = cursorColumn;
						gridGhostNote.playNoteAnimation();
					}
					
					FlxG.watch.addQuick("cursorY", cursorY);
					FlxG.watch.addQuick("cursorFractionalStep", cursorFractionalStep);
					FlxG.watch.addQuick("cursorStep", cursorStep);
					FlxG.watch.addQuick("cursorMs", cursorMs);

					gridGhostNote.noteData.time = cursorMs;
					gridGhostNote.updateNotePosition(renderedNotes);

					// gridCursor.visible = true;
					// // X and Y are the cursor position relative to the grid, snapped to the top left of the grid square.
					// gridCursor.x = Math.floor(cursorX / GRID_SIZE) * GRID_SIZE + gridTiledSprite.x + (GRID_SELECTION_BORDER_WIDTH / 2);
					// gridCursor.y = cursorStep * GRID_SIZE + gridTiledSprite.y + (GRID_SELECTION_BORDER_WIDTH / 2);
				}
				else
				{
					gridGhostNote.visible = false;
					Cursor.cursorMode = Default;
				}
			}
		}
		else
		{
			gridGhostNote.visible = false;
		}

		if (isCursorOverHaxeUIButton && Cursor.cursorMode == Default)
		{
			Cursor.cursorMode = Pointer;
		}
	}

	/**
	 * Handle using `renderedNotes` to display notes from `currentSongChartNoteData`.
	 */
	function handleNoteDisplay()
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
				if (noteSprite == null || !noteSprite.exists || !noteSprite.visible)
					continue;

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

			// Add notes that are now visible.
			for (noteData in currentSongChartNoteData)
			{
				// Remember if we are already displaying this note.
				if (displayedNoteData.indexOf(noteData) != -1)
				{
					continue;
				}

				// Get the position the note should be at.
				var noteTimePixels:Float = noteData.time / Conductor.stepCrochet * GRID_SIZE;

				// Make sure the note appears when scrolling up.
				var modifiedViewAreaTop = viewAreaTop - GRID_SIZE;

				if (noteTimePixels < modifiedViewAreaTop || noteTimePixels > viewAreaBottom)
					continue;

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
					var noteLengthSteps:Float = (noteLengthMs / Conductor.stepCrochet);
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

					// var noteLengthPixels:Float = (noteLengthMs / Conductor.stepCrochet + 1) * GRID_SIZE;
					// add(new FlxSprite(noteSprite.x, noteSprite.y - renderedNotes.y + noteLengthPixels).makeGraphic(40, 2, 0xFFFF0000));
				}
			}

			// Destroy and recreate smaller selection squares.
			for (member in renderedNoteSelectionSquares.members)
			{
				// Killing the sprite is cheap because we can recycle it.
				member.kill();
			}

			for (noteSprite in renderedNotes.members)
			{
				if (isNoteSelected(noteSprite.noteData) && noteSprite.parentNoteSprite == null)
				{
					var selectionSquare:FlxSprite = renderedNoteSelectionSquares.recycle(() ->
					{
						return new FlxSprite().loadGraphic(selectionSquareBitmap);
					});

					selectionSquare.x = noteSprite.x;
					selectionSquare.y = noteSprite.y;
					selectionSquare.width = noteSprite.width;
					selectionSquare.height = noteSprite.height;
				}
			}

			// Sort the notes DESCENDING. This keeps the sustain behind the associated note.
			renderedNotes.sort(FlxSort.byY, FlxSort.DESCENDING);
		}
	}

	/**
	 * Handles display elements for the playbar at the bottom.
	 */
	function handlePlaybar()
	{
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
	function handleFileKeybinds()
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
	function handleEditKeybinds()
	{
		// CTRL + Z = Undo
		if (FlxG.keys.pressed.CONTROL && FlxG.keys.justPressed.Z)
		{
			undoLastCommand();
		}

		if (FlxG.keys.pressed.CONTROL && FlxG.keys.pressed.Z && !FlxG.keys.pressed.Y)
		{
			undoHeldTime += FlxG.elapsed;
		}
		else
		{
			undoHeldTime = 0;
		}
		if (undoHeldTime > RAPID_UNDO_DELAY + RAPID_UNDO_INTERVAL)
		{
			undoLastCommand();
			undoHeldTime -= RAPID_UNDO_INTERVAL;
		}

		// CTRL + Y = Redo
		if (FlxG.keys.pressed.CONTROL && FlxG.keys.justPressed.Y)
		{
			redoLastCommand();
		}

		if (FlxG.keys.pressed.CONTROL && FlxG.keys.pressed.Y && !FlxG.keys.pressed.Z)
		{
			redoHeldTime += FlxG.elapsed;
		}
		else
		{
			redoHeldTime = 0;
		}
		if (redoHeldTime > RAPID_UNDO_DELAY + RAPID_UNDO_INTERVAL)
		{
			redoLastCommand();
			redoHeldTime -= RAPID_UNDO_INTERVAL;
		}

		// CTRL + C = Copy
		if (FlxG.keys.pressed.CONTROL && FlxG.keys.justPressed.C)
		{
			// Copy selected notes.
			// We don't need a command for this since we can't undo it.
			SongDataUtils.writeNotesToClipboard(SongDataUtils.buildClipboard(currentSelection));
		}

		// CTRL + X = Cut
		if (FlxG.keys.pressed.CONTROL && FlxG.keys.justPressed.X)
		{
			// Cut selected notes.
			performCommand(new CutNotesCommand(currentSelection));
		}

		// CTRL + V = Paste
		if (FlxG.keys.pressed.CONTROL && FlxG.keys.justPressed.V)
		{
			// Paste notes from clipboard, at the playhead.
			performCommand(new PasteNotesCommand(scrollPositionInMs + playheadPositionInMs));
		}

		// DELETE = Delete
		if (FlxG.keys.justPressed.DELETE)
		{
			// Delete selected notes.
			performCommand(new RemoveNotesCommand(currentSelection));
		}

		// CTRL + A = Select All
		if (FlxG.keys.pressed.CONTROL && FlxG.keys.justPressed.A)
		{
			// Select all notes.
			performCommand(new SelectAllNotesCommand(currentSelection));
		}

		// CTRL + I = Select Inverse
		if (FlxG.keys.pressed.CONTROL && FlxG.keys.justPressed.I)
		{
			// Select unselected notes and deselect selected notes..
			performCommand(new InvertSelectedNotesCommand(currentSelection));
		}

		// CTRL + D = Select None
		if (FlxG.keys.pressed.CONTROL && FlxG.keys.justPressed.D)
		{
			// Deselect all notes.
			performCommand(new DeselectAllNotesCommand(currentSelection));
		}
	}

	/**
	 * Handle keybinds for View menu items.
	 */
	function handleViewKeybinds()
	{
		// B = Toggle Sidebar
		if (FlxG.keys.justPressed.B)
			toggleSidebar();
	}

	/**
	 * Handle keybinds for Help menu items.
	 */
	function handleHelpKeybinds()
	{
		// F1 = Open Help
		if (FlxG.keys.justPressed.F1)
			ChartEditorDialogHandler.openUserGuideDialog(this);
	}

	function handleSidebar()
	{
		if (difficultySelectDirty)
		{
			difficultySelectDirty = false;

			// Manage the Select Difficulty tree view.
			var treeView:TreeView = findComponent('sidebarDifficulties');

			if (treeView != null)
			{
				// Clear the tree view so we can rebuild it.
				treeView.clearNodes();

				var treeSong = treeView.addNode({id: 'stv_song', text: 'S: $currentSongName', icon: "haxeui-core/styles/default/haxeui_tiny.png"});
				treeSong.expanded = true;

				var treeVariationDefault = treeSong.addNode({
					id: 'stv_variation_default',
					text: "V: Default",
					// icon: "haxeui-core/styles/default/haxeui_tiny.png"
				});
				treeVariationDefault.expanded = true;

				var treeDifficultyEasy = treeVariationDefault.addNode({
					id: 'stv_difficulty_default_easy',
					text: "D: Easy",
					// icon: "haxeui-core/styles/default/haxeui_tiny.png"
				});
				var treeDifficultyNormal = treeVariationDefault.addNode({
					id: 'stv_difficulty_default_normal',
					text: "D: Normal",
					// icon: "haxeui-core/styles/default/haxeui_tiny.png"
				});
				var treeDifficultyHard = treeVariationDefault.addNode({
					id: 'stv_difficulty_default_hard',
					text: "D: Hard",
					// icon: "haxeui-core/styles/default/haxeui_tiny.png"
				});

				var treeVariationErect = treeSong.addNode({
					id: 'stv_variation_erect',
					text: "V: Erect",
					// icon: "haxeui-core/styles/default/haxeui_tiny.png"
				});
				treeVariationErect.expanded = true;

				var treeDifficultyErect = treeVariationErect.addNode({
					id: 'stv_difficulty_erect_erect',
					text: "D: Erect",
					// icon: "haxeui-core/styles/default/haxeui_tiny.png"
				});

				treeView.onChange = onChangeTreeDifficulty;
				treeView.selectedNode = getCurrentTreeDifficultyNode();
			}
		}
	}

	function getCurrentTreeDifficultyNode():TreeViewNode
	{
		var treeView:TreeView = findComponent('sidebarDifficulties');

		if (treeView == null)
			return null;

		var result = treeView.findNodeByPath('stv_song/stv_variation_$selectedVariation/stv_difficulty_${selectedVariation}_$selectedDifficulty', 'id');

		if (result == null)
			return null;

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

	/**
	 * Handle the player preview/gameplay test area on the left side.
	 */
	function handlePlayerDisplay()
	{
	}

	/**
	 * Handles the note preview/scroll area on the right side.
	 * Notes are rendered here as small bars.
	 * This function also handles:
	 * - Moving the viewport preview box around based on its current position.
	 * - Scrolling the note preview area down if the note preview is taller than the screen,
	 *   and the viewport nears the end of the visible area.
	 */
	function handleNotePreview()
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
	function updateNotePreview(note:SongNoteData, ?deleteNote:Bool = false)
	{
	}

	/**
	 * Handles passive behavior of the menu bar, such as updating labels or enabled/disabled status.
	 * Does not handle onClick ACTIONS of the menubar.
	 */
	function handleMenubar()
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
	function handleMusicPlayback()
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
				if (Math.abs(audioInstTrack.time - audioVocalTrackGroup.time) > 100)
					audioVocalTrackGroup.time = audioInstTrack.time;
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
				if (audioVocalTrackGroup != null && Math.abs(audioInstTrack.time - audioVocalTrackGroup.time) > 100)
					audioVocalTrackGroup.time = audioInstTrack.time;

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
		if (!hitsoundsEnabled)
			return;

		// Assume notes are sorted by time.
		for (noteData in currentSongChartNoteData)
		{
			if (noteData.time < oldSongPosition)
				// Note is in the past.
				continue;

			if (noteData.time >= newSongPosition)
				// Note is in the future.
				return;

			// Note was just hit.
			switch (noteData.getStrumlineIndex())
			{
				case 0: // Player
					if (hitsoundsEnabledPlayer)
						playSound(Paths.sound('funnyNoise/funnyNoise-09'));
				case 1: // Opponent
					if (hitsoundsEnabledOpponent)
						playSound(Paths.sound('funnyNoise/funnyNoise-010'));
			}
		}
	}

	function startAudioPlayback()
	{
		if (audioInstTrack != null)
			audioInstTrack.play();
		if (audioVocalTrackGroup != null)
			audioVocalTrackGroup.play();
		if (audioVocalTrackGroup != null)
			audioVocalTrackGroup.play();
	}

	function stopAudioPlayback()
	{
		if (audioInstTrack != null)
			audioInstTrack.pause();
		if (audioVocalTrackGroup != null)
			audioVocalTrackGroup.pause();
		if (audioVocalTrackGroup != null)
			audioVocalTrackGroup.pause();
	}

	function toggleAudioPlayback()
	{
		if (audioInstTrack == null)
			return;

		if (audioInstTrack.playing)
		{
			stopAudioPlayback();
		}
		else
		{
			startAudioPlayback();
		}
	}

	function handlePlayhead()
	{
		// Place notes at the playhead.
		// TODO: Add the ability to switch modes.
		if (true)
		{
			if (FlxG.keys.justPressed.ONE)
				placeNoteAtPlayhead(0);
			if (FlxG.keys.justPressed.TWO)
				placeNoteAtPlayhead(1);
			if (FlxG.keys.justPressed.THREE)
				placeNoteAtPlayhead(2);
			if (FlxG.keys.justPressed.FOUR)
				placeNoteAtPlayhead(3);
			if (FlxG.keys.justPressed.FIVE)
				placeNoteAtPlayhead(4);
			if (FlxG.keys.justPressed.SIX)
				placeNoteAtPlayhead(5);
			if (FlxG.keys.justPressed.SEVEN)
				placeNoteAtPlayhead(6);
			if (FlxG.keys.justPressed.EIGHT)
				placeNoteAtPlayhead(7);
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

		if (value > songLengthInPixels)
			value = songLengthInPixels;

		if (value == scrollPositionInPixels)
			return value;

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
		renderedNoteSelectionSquares.setPosition(renderedNotes.x, renderedNotes.y);
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
		if (value + scrollPositionInPixels < 0)
			value = -scrollPositionInPixels;
		if (value + scrollPositionInPixels > songLengthInPixels)
			value = songLengthInPixels - scrollPositionInPixels;

		this.playheadPositionInPixels = value;

		// Move the playhead sprite to the correct position.
		gridPlayhead.y = this.playheadPositionInPixels + (MENU_BAR_HEIGHT + GRID_TOP_PAD);

		return this.playheadPositionInPixels;
	}

	/**
	 * Show the sidebar if it's hidden, or hide it if it's shown.
	 */
	function toggleSidebar()
	{
		var sidebar:Component = findComponent('sidebar', Component);

		// Set visibility while syncing the checkbox.
		if (sidebar != null)
		{
			sidebar.visible = setUISelected('menubarItemToggleSidebar', !sidebar.visible);
		}
	}

	/**
	 * Loads an instrumental from an absolute file path, replacing the current instrumental.
	 */
	public function loadInstrumentalFromPath(path:String):Void
	{
		#if sys
		var fileBytes:haxe.io.Bytes = sys.io.File.getBytes(path);
		loadInstrumentalFromBytes(fileBytes);
		#else
		trace("[WARN] This platform can't load audio from a file path, you'll need to fetch the bytes some other way.");
		#end
	}

	/**
	 * Loads an instrumental from audio byte data, replacing the current instrumental.
	 */
	public function loadInstrumentalFromBytes(bytes:haxe.io.Bytes):Void
	{
		var openflSound = new openfl.media.Sound();
		openflSound.loadCompressedDataFromByteArray(openfl.utils.ByteArray.fromBytes(bytes), bytes.length);
		audioInstTrack = FlxG.sound.load(openflSound, 1.0, false);
		audioInstTrack.autoDestroy = false;
		audioInstTrack.pause();

		// Tell the user the load was successful.
		// TODO: Un-bork this.
		// showNotification('Loaded instrumental track successfully.');

		postLoadInstrumental();
	}

	public function loadInstrumentalFromAsset(path:String):Void
	{
		var vocalTrack = FlxG.sound.load(path, 1.0, false);
		audioInstTrack = vocalTrack;

		postLoadInstrumental();
	}

	function postLoadInstrumental()
	{
		// Prevent the time from skipping back to 0 when the song ends.
		audioInstTrack.onComplete = function()
		{
			if (audioInstTrack != null)
				audioInstTrack.pause();
			if (audioVocalTrackGroup != null)
				audioVocalTrackGroup.pause();
		};

		songLengthInPixels = Std.int(Conductor.getTimeInSteps(audioInstTrack.length) * GRID_SIZE);

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
	 */
	public function loadVocalsFromPath(path:String):Void
	{
		#if sys
		var fileBytes:haxe.io.Bytes = sys.io.File.getBytes(path);
		loadVocalsFromBytes(fileBytes);
		#else
		trace("[WARN] This platform can't load audio from a file path, you'll need to fetch the bytes some other way.");
		#end
	}

	public function loadVocalsFromAsset(path:String):Void
	{
		var vocalTrack = FlxG.sound.load(path, 1.0, false);
		audioVocalTrackGroup.add(vocalTrack);
	}

	/**
	 * Loads a vocal track from audio byte data.
	 */
	public function loadVocalsFromBytes(bytes:haxe.io.Bytes):Void
	{
		var openflSound = new openfl.media.Sound();
		openflSound.loadCompressedDataFromByteArray(openfl.utils.ByteArray.fromBytes(bytes), bytes.length);
		var vocalTrack = FlxG.sound.load(openflSound, 1.0, false);
		audioVocalTrackGroup.add(vocalTrack);

		// Tell the user the load was successful.
		// TODO: Un-bork this.
		// showNotification('Loaded instrumental track successfully.');
	}

	/**
	 * Fetch's a song's existing chart and audio and loads it, replacing the current song.
	 */
	public function loadSongAsTemplate(songId:String)
	{
		var song:Song = SongDataParser.fetchSong(songId);

		if (song == null)
		{
			// showNotification('Failed to load song template.');
			return;
		}

		// Load the song metadata.
		var rawSongMetadata:Array<SongMetadata> = song.getRawMetadata();

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

		// showNotification('Loaded song ${songId}.');
	}

	/**
	 * When setting the scroll position, except when automatically scrolling during song playback,
	 * we need to update the conductor's current step time and the timestamp of the audio tracks.
	 */
	function moveSongToScrollPosition()
	{
		// Update the songPosition in the Conductor.
		Conductor.update(scrollPositionInMs);

		// Update the songPosition in the audio tracks.
		if (audioInstTrack != null)
			audioInstTrack.time = scrollPositionInMs + playheadPositionInMs;
		if (audioVocalTrackGroup != null)
			audioVocalTrackGroup.time = scrollPositionInMs + playheadPositionInMs;

		// We need to update the note sprites because we changed the scroll position.
		noteDisplayDirty = true;
	}

	/**
	 * Add an onClick listener to a HaxeUI menu bar item.
	**/
	function addUIClickListener(key:String, callback:MouseEvent->Void)
	{
		var target:Component = findComponent(key);
		if (target == null)
		{
			// Gracefully handle the case where the item can't be located.
			trace('WARN: Could not locate menu item: $key');
		}
		else
		{
			target.onClick = callback;
		}
	}

	/**
	 * Add an onChange listener to a HaxeUI menu bar item such as a slider.
	 */
	function addUIChangeListener(key:String, callback:UIEvent->Void)
	{
		var target:Component = findComponent(key);
		if (target == null)
		{
			// Gracefully handle the case where the item can't be located.
			trace('WARN: Could not locate menu item: $key');
		}
		else
		{
			target.onChange = callback;
		}
	}

	/**
	 * Set the value of a HaxeUI component.
	 * Usually modifies the text of a label.
	 */
	function setUIValue<T>(key:String, value:T):T
	{
		var target:Component = findComponent(key);
		if (target == null)
		{
			// Gracefully handle the case where the item can't be located.
			trace('WARN: Could not locate menu item: $key');
			return value;
		}
		else
		{
			return target.value = value;
		}
	}

	/**
	 * Set the value of a HaxeUI checkbox,
	 * since that's on 'selected' instead of 'value'.
	 */
	function setUISelected<T>(key:String, value:Bool):Bool
	{
		var targetA:CheckBox = findComponent(key, CheckBox);

		if (targetA != null)
		{
			return targetA.selected = value;
		}

		var targetB:MenuCheckBox = findComponent(key, MenuCheckBox);
		if (targetB != null)
		{
			return targetB.selected = value;
		}

		// Gracefully handle the case where the item can't be located.
		trace('WARN: Could not locate check box: $key');
		return value;
	}

	/**
	 * Perform (or redo) a command, then add it to the undo stack.
	 * @param command The command to perform.
	 * @param purgeRedoStack If true, the redo stack will be cleared.
	 */
	function performCommand(command:ChartEditorCommand, ?purgeRedoStack:Bool = true):Void
	{
		command.execute(this);
		undoHistory.push(command);
		commandHistoryDirty = true;
		if (purgeRedoStack)
			redoHistory = [];
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

		var command = undoHistory.pop();
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

		var command = redoHistory.pop();
		performCommand(command, false);
	}

	function sortChartData()
	{
		currentSongChartNoteData.sort(function(a:SongNoteData, b:SongNoteData):Int
		{
			return FlxSort.byValues(FlxSort.ASCENDING, a.time, b.time);
		});

		currentSongChartEventData.sort(function(a:SongEventData, b:SongEventData):Int
		{
			return FlxSort.byValues(FlxSort.ASCENDING, a.time, b.time);
		});
	}

	function playMetronomeTick(?high:Bool = false)
	{
		playSound(Paths.sound('pianoStuff/piano-${high ? '001' : '008'}'));
	}

	function isNoteSelected(note:SongNoteData):Bool
	{
		return currentSelection.indexOf(note) != -1;
	}

	/**
	 * Play a sound effect.
	 * Automatically cleans up after itself and recycles previous FlxSound instances if available, for performance.
	 */
	function playSound(path:String)
	{
		var snd:FlxSound = FlxG.sound.list.recycle(FlxSound);
		snd.loadEmbedded(FlxG.sound.cache(path));
		snd.autoDestroy = true;
		FlxG.sound.list.add(snd);
		snd.play();
	}

	override function destroy()
	{
		super.destroy();

		@:privateAccess
		ChartEditorNoteSprite.noteFrameCollection = null;
	}

	/**
	 * Displays a notification to the user. The only action is to dismiss.
	 */
	function showNotification(text:String)
	{
		var notifBarText:Label = notifBar.findComponent('notifBarText', Label);
		var notifBarAction1:Button = notifBar.findComponent('notifBarAction1', Button);

		// Make it appear.
		notifBar.show();

		// Don't shift the UI up.
		notifBar.method = "float";
		// Anchor to far right.
		notifBar.x = FlxG.width - notifBar.width;

		// Set the message.
		notifBarText.text = text;

		// Configure the action button.
		notifBarAction1.text = 'Dismiss';
		notifBarAction1.onClick = (_:UIEvent) -> dismissNotification();

		// Auto dismiss.
		new FlxTimer().start(NOTIFICATION_DISMISS_TIME, (_:FlxTimer) -> dismissNotification());
	}

	/**
	 * Dismiss any existing notifications, if there are any.
	 */
	function dismissNotification():Void
	{
		notifBar.hide();
	}

	/**
	 * Displays a prompt to the user, to save their changes made to this chart,
	 * or to discard them.
	 *
	 * @param onComplete Function to call after the user clicks Save or Don't Save.
	 *                   If Save was clicked, we save before calling this.
	 * @param onCancel Function to call if the user clicks Cancel.
	 */
	function promptSaveChanges(onComplete:Void->Void, ?onCancel:Void->Void):Void
	{
		var messageBox:MessageBox = new MessageBox();

		messageBox.title = 'Save Changes?';
		messageBox.message = 'Do you want to save the changes you made to $currentSongName?\n\nYour changes will be lost if you don\'t save them.';
		messageBox.type = 'question';
		messageBox.modal = true;
		messageBox.buttons = DialogButton.SAVE | "Don't Save" | "Cancel";

		messageBox.registerEvent(DialogEvent.DIALOG_CLOSED, function(e:DialogEvent):Void
		{
			trace('Pressed: ${e.button}');
			switch (e.button)
			{
				case 'Save':
					// TODO: Make sure to actually save.
					// saveChart();
					onComplete();
				case "Don't Save":
					onComplete();
				case 'Cancel':
					if (onCancel != null)
						onCancel();
			}
		});
	}
}
