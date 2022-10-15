package funkin.ui.debug.charting;

import flixel.FlxSprite;
import flixel.addons.display.FlxGridOverlay;
import flixel.addons.display.FlxTiledSprite;
import flixel.group.FlxSpriteGroup;
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
import funkin.ui.haxeui.HaxeUIState;
import haxe.ui.components.Button;
import haxe.ui.components.CheckBox;
import haxe.ui.components.Slider;
import haxe.ui.containers.SideBar;
import haxe.ui.containers.TreeView;
import haxe.ui.containers.TreeViewNode;
import haxe.ui.containers.dialogs.Dialog;
import haxe.ui.containers.dialogs.MessageBox;
import haxe.ui.containers.menus.Menu.MenuEvent;
import haxe.ui.containers.menus.MenuBar;
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

// Since Haxe 3.1.0, if access is allowed to an interface, it extends to all classes implementing that interface.
// Thus, any ChartEditorCommand has access to any private field.
@:allow(funkin.ui.debug.charting.ChartEditorCommand)
class ChartEditorState extends HaxeUIState
{
	/**
	 * CONSTANTS
	 */
	// ==============================

	/**
	 * The location of the chart editor's HaxeUI XML file.
	 */
	static final CHART_EDITOR_LAYOUT = Paths.ui('chart-editor/main-view');

	static final CHART_EDITOR_NOTIFBAR_LAYOUT = Paths.ui('chart-editor/components/notifbar');
	static final CHART_EDITOR_PLAYBARHEAD_LAYOUT = Paths.ui('chart-editor/components/playbar-head');

	static final DEFAULT_VARIATION = 'default';
	static final DEFAULT_DIFFICULTY = 'normal';

	// UI Element Sizes
	public static final GRID_SIZE:Int = 40;
	public static final STRUMLINE_SIZE = 4;
	static final MENU_BAR_HEIGHT = 32;
	static final GRID_TOP_PAD:Int = 8;
	static final SELECTION_SQUARE_BORDER_WIDTH:Int = 1;

	static final NOTIFICATION_DISMISS_TIME:Float = 3.0;

	// UI Element Colors
	static final BG_COLOR:FlxColor = 0xFF673AB7;
	static final GRID_ALTERNATE:Bool = true;
	static final GRID_COLOR_1:FlxColor = 0xFFE7E6E6;
	static final GRID_COLOR_1_DARK:FlxColor = 0xFF181919;
	static final GRID_COLOR_2:FlxColor = 0xFFD9D5D5;
	static final GRID_COLOR_2_DARK:FlxColor = 0xFF262A2A;
	static final CURSOR_COLOR:FlxColor = 0xC0FFFFFF;
	static final PREVIEW_BG_COLOR:FlxColor = 0xFF303030;
	static final PLAYHEAD_COLOR:FlxColor = 0xC0808080;
	static final SPECTROGRAM_COLOR:FlxColor = 0xFFFF0000;
	static final SELECTION_SQUARE_BORDER_COLOR:FlxColor = 0xFF339933;
	static final SELECTION_SQUARE_FILL_COLOR:FlxColor = 0x4033FF33;

	/**
	 * INSTANCE DATA
	 */
	// ==============================

	/**
	 * scrollPosition is the current position in the song, in pixels.
	 * One pixel is 1/40 of 1 step, and 1 step is 1/4 of a beat.
	 */
	var scrollPosition(default, set):Float = -1.0;

	/**
	 * scrollPosition, converted to steps.
	 * TODO: Handle BPM changes.
	 */
	var scrollPositionInSteps(get, null):Float;

	function get_scrollPositionInSteps():Float
	{
		return scrollPosition / GRID_SIZE;
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
		scrollPosition = value / Conductor.stepCrochet;
		return value;
	}

	/**
	 * The position of the playhead, in pixels, relative to the scroll position.
	 * For example, 0 means the playhead is at the top of the grid, and 40 means the playhead is 1 step farther.
	 */
	var playheadPosition(default, set):Float;

	var playheadPositionInSteps(get, null):Float;

	/**
	 * playheadPosition, converted to steps.
	 */
	function get_playheadPositionInSteps():Float
	{
		return playheadPosition / GRID_SIZE;
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
	 * This is the song's length in PIXELS , same format as scrollPosition.
	 */
	var songLength:Int;

	/**
	 * songLength, converted to steps.
	 */
	var songLengthInSteps(get, null):Float;

	function get_songLengthInSteps():Float
	{
		return songLength / GRID_SIZE;
	}

	/**
	 * songLength, converted to milliseconds.
	 */
	var songLengthInMs(get, null):Float;

	function get_songLengthInMs():Float
	{
		return songLengthInSteps * Conductor.stepCrochet;
	}

	/**
	 * If true, a HaxeUI dialog is open and the user interface underneath should be disabled.
	 */
	var isModalDialogOpen:Bool = false;

	/**
	 * Whether a skip button has been pressed on the playbar, and which one.
	 */
	var playbarButtonPressed:String = null;

	/**
	 * Whether the head of the playbar is being dragged.
	 */
	var playbarHeadDragging:Bool = false;

	/**
	 * Whether music was playing before we started dragging the playbar head.
	 */
	var playbarHeadDraggingWasPlaying:Bool = false;

	/**
	 * The note kind currently being placed. Defaults to `''`.
	 * Use the input in the sidebar to change this.
	 */
	var selectedNoteKind:String = '';

	/**
	 * Whether to play a metronome sound while the playhead moves.
	 */
	var shouldPlayMetronome:Bool = true;

	/**
	 * Whether the current view is in downscroll mode.
	 */
	var isViewDownscroll(default, set):Bool = false;

	function set_isViewDownscroll(value:Bool):Bool
	{
		isViewDownscroll = value;

		// Make sure view is updated.
		noteDisplayDirty = true;
		notePreviewDirty = true;
		this.scrollPosition = this.scrollPosition;

		return isViewDownscroll;
	}

	var isCursorOverHaxeUI(get, null):Bool;

	function get_isCursorOverHaxeUI():Bool
	{
		return Screen.instance.hasSolidComponentUnderPoint(FlxG.mouse.screenX, FlxG.mouse.screenY);
	}

	/**
	 * The current variation ID.
	 */
	var selectedVariation(default, set):String = DEFAULT_VARIATION;

	function set_selectedVariation(value:String):String
	{
		selectedVariation = value;

		// Make sure view is updated.
		noteDisplayDirty = true;
		notePreviewDirty = true;

		return selectedVariation;
	}

	/**
	 * The selected difficulty ID.
	 */
	var selectedDifficulty(default, set):String = DEFAULT_DIFFICULTY;

	function set_selectedDifficulty(value:String):String
	{
		selectedDifficulty = value;

		// Make sure view is updated.
		noteDisplayDirty = true;
		notePreviewDirty = true;

		return selectedDifficulty;
	}

	/**
	 * Whether the note display render group needs to be updated.
	 */
	var noteDisplayDirty:Bool = true;

	/**
	 * Whether the neat note preview graphic needs to be updated (i.e. fully rebuilt).
	 */
	var notePreviewDirty:Bool = true;

	/**
	 * Whether the difficulty tree view in the sidebar needs to be updated.
	 */
	var difficultySelectDirty:Bool = true;

	var isInPatternMode:Bool = false;
	var currentPattern:String = '';
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
	 * Whether the undo/redo histories have changed since the last time the UI was updated.
	 */
	var commandHistoryDirty:Bool = true;

	/**
	 * The notes which are currently in the selection.
	 */
	var currentSelection:Array<SongNoteData> = [];

	/**
	 * AUDIO AND SOUND DATA
	 */
	/**
	 * The audio track for the instrumental.
	 */
	var audioInstTrack:FlxSound;

	/**
	 * The audio track for the vocals.
	 * TODO: Replace with a VocalSoundGroup.
	 */
	var audioVocalTrack:FlxSound;

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

	var currentSongNoteSkin(get, set):String;

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
	 * The IMAGE used for the grid.
	 */
	var gridBitmap:BitmapData;

	/**
	 * The IMAGE used for the selection squares.
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

	/**
	 * A sprite used to highlight the grid square under the cursor.
	 */
	var gridCursor:FlxSprite;

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
		buildGrid();
		buildNoteGroup();

		// Add the HaxeUI components after the grid so they're on top.
		super.create();
		buildAdditionalUI();

		// Setup the onClick listeners for the UI after it's been created.
		setupUIListeners();

		// TODO: We should be loading the music later when the user requests it.
		loadMusic();
	}

	function buildDefaultSongData()
	{
		selectedVariation = DEFAULT_VARIATION;
		selectedDifficulty = DEFAULT_DIFFICULTY;

		// Initialize the song metadata.
		songMetadata = new Map<String, SongMetadata>();

		// Initialize the song chart data.
		songChartData = new Map<String, SongChartData>();
	}

	/**
	 * Builds and displays the background sprite.
	 */
	function buildBackground()
	{
		menuBG = new FlxSprite().loadGraphic(Paths.image('menuDesat'));
		add(menuBG);
		menuBG.color = BG_COLOR;
		menuBG.setGraphicSize(Std.int(menuBG.width * 1.1));
		menuBG.updateHitbox();
		menuBG.screenCenter();
		menuBG.scrollFactor.set(0, 0);
	}

	/**
	 * Draws the grid texture used for the chart editor, and adds dividing lines to it.
	 * @param dark Whether to draw the grid in a dark color instead of a light one.
	 */
	function makeGridBitmap(?dark:Bool = true)
	{
		// The checkerboard background image of the chart.
		// 2 * (Strumline Size) + 1 grid squares wide, by 2 grid squares tall.
		// This gets reused to fill the screen.
		gridBitmap = FlxGridOverlay.createGrid(GRID_SIZE, GRID_SIZE, GRID_SIZE * (STRUMLINE_SIZE * 2 + 1), GRID_SIZE * 2, GRID_ALTERNATE,
			dark ? GRID_COLOR_1_DARK : GRID_COLOR_1, dark ? GRID_COLOR_2_DARK : GRID_COLOR_2);
	}

	function makeSelectionSquareBitmap()
	{
		selectionSquareBitmap = new BitmapData(GRID_SIZE, GRID_SIZE, true);

		selectionSquareBitmap.fillRect(new Rectangle(0, 0, GRID_SIZE, GRID_SIZE), SELECTION_SQUARE_BORDER_COLOR);
		selectionSquareBitmap.fillRect(new Rectangle(SELECTION_SQUARE_BORDER_WIDTH, SELECTION_SQUARE_BORDER_WIDTH,
			GRID_SIZE - (SELECTION_SQUARE_BORDER_WIDTH * 2), GRID_SIZE - (SELECTION_SQUARE_BORDER_WIDTH * 2)),
			SELECTION_SQUARE_FILL_COLOR);
	}

	/**
	 * Builds and displays the chart editor grid, including the playhead and cursor.
	 */
	function buildGrid()
	{
		makeGridBitmap(false);

		makeSelectionSquareBitmap();

		// Draw dividers between the strumlines.
		var dividerLineAX = GRID_SIZE * (STRUMLINE_SIZE) - 1;
		gridBitmap.fillRect(new Rectangle(dividerLineAX, 0, 2, gridBitmap.height), 0xFF000000);
		var dividerLineBX = GRID_SIZE * (STRUMLINE_SIZE * 2) - 1;
		gridBitmap.fillRect(new Rectangle(dividerLineBX, 0, 2, gridBitmap.height), 0xFF000000);

		gridTiledSprite = new FlxTiledSprite(gridBitmap, gridBitmap.width, 1000, false, true);
		gridTiledSprite.x = FlxG.width / 2 - GRID_SIZE * STRUMLINE_SIZE; // Center the grid.
		gridTiledSprite.y = MENU_BAR_HEIGHT + GRID_TOP_PAD; // Push down to account for the menu bar.
		add(gridTiledSprite);

		/*
			buildSpectrogram(audioVocalTrack);
		 */

		// The cursor that appears when hovering over the grid.
		gridCursor = new FlxSprite().makeGraphic(GRID_SIZE, GRID_SIZE, CURSOR_COLOR);
		add(gridCursor);

		// The playhead that show the current position in the song.
		gridPlayhead = new FlxSpriteGroup();
		add(gridPlayhead);

		var playheadWidth = GRID_SIZE * (STRUMLINE_SIZE * 2 + 1) + 10 + 10;
		var playheadBaseYPos = MENU_BAR_HEIGHT + GRID_TOP_PAD;
		gridPlayhead.setPosition(gridTiledSprite.x, playheadBaseYPos);
		var playheadSprite = new FlxSprite().makeGraphic(playheadWidth, Std.int(GRID_SIZE / 4), PLAYHEAD_COLOR);
		playheadSprite.x = -10;
		playheadSprite.y = 0;
		gridPlayhead.add(playheadSprite);

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

	function buildSpectrogram(target:FlxSound)
	{
		gridSpectrogram = new PolygonSpectogram(target, SPECTROGRAM_COLOR, FlxG.height / 2, Math.floor(FlxG.height / 2));
		gridSpectrogram.x = 0;
		gridSpectrogram.y = 0;
		gridSpectrogram.waveAmplitude = 50;
		gridSpectrogram.scrollFactor.set(0, 0);
		// musSpec.visType = FREQUENCIES;
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
			if (audioVocalTrack.playing)
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
			trace('Seek to position: ${playbarHead.value}%');
			playbarHeadDragging = false;

			// Set the song position to where the playhead was moved to.
			scrollPosition = songLength * (playbarHead.value / 100);
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
		// Make sure clicking on the menu doesn't affect the grid behind it while it's open.
		var menubarComponent:MenuBar = findComponent('menubar', MenuBar);
		if (menubarComponent != null)
		{
			menubarComponent.onMenuOpened = (e:MenuEvent) ->
			{
				isModalDialogOpen = true;
			}
			menubarComponent.onMenuClosed = (e:MenuEvent) ->
			{
				isModalDialogOpen = false;
			}
		}

		// Add functionality to the playbar.

		addUIClickListener('playbarPlay', (event:MouseEvent) -> toggleAudioPlayback());
		addUIClickListener('playbarStart', (event:MouseEvent) -> playbarButtonPressed = 'playbarStart');
		addUIClickListener('playbarBack', (event:MouseEvent) -> playbarButtonPressed = 'playbarBack');
		addUIClickListener('playbarForward', (event:MouseEvent) -> playbarButtonPressed = 'playbarForward');
		addUIClickListener('playbarEnd', (event:MouseEvent) -> playbarButtonPressed = 'playbarEnd');

		// Add functionality to the menu items.

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

		addUIClickListener('menubarItemSelectInverse', (event:MouseEvent) -> {
			// TODO: Implement this.
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

		addUIClickListener('menubarItemAbout', (event:MouseEvent) -> openDialog('chart-editor/dialogs/about'));

		addUIClickListener('menubarItemUserGuide', (event:MouseEvent) -> openDialog('chart-editor/dialogs/user-guide'));

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

		addUIChangeListener('menubarItemVolumeInstrumental', (event:UIEvent) ->
		{
			var volume:Float = event.value / 100.0;
			audioInstTrack.volume = volume;
		});

		addUIChangeListener('menubarItemVolumeVocals', (event:UIEvent) ->
		{
			var volume:Float = event.value / 100.0;
			audioVocalTrack.volume = volume;
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

		if (!isModalDialogOpen)
		{
			// These ones only happen if the modal dialog is not open.
			handleScrollKeybinds();
			handleCursor();

			handleMenubar();
			handleSidebar();
			handlePlaybar();

			handlePlayheadKeybinds();
			handleFileKeybinds();
			handleEditKeybinds();
			handleViewKeybinds();
			handleHelpKeybinds();
		}

		// DEBUG
		if (FlxG.keys.justPressed.F)
		{
			showNotification('Hi there :)');
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
		if (FlxG.mouse.wheel != 0)
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
			scrollAmount *= 10;
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
			scrollAmount = 0 - this.scrollPosition;
		}
		if (playbarButtonPressed == 'playbarStart')
		{
			playbarButtonPressed = '';
			scrollAmount = 0 - this.scrollPosition;
		}

		// END = Scroll to Bottom
		if (FlxG.keys.justPressed.END)
		{
			// Scroll amount is the difference between the current position and the bottom.
			scrollAmount = this.songLength - this.scrollPosition;
		}
		if (playbarButtonPressed == 'playbarEnd')
		{
			playbarButtonPressed = '';
			scrollAmount = this.songLength - this.scrollPosition;
		}

		// Apply the scroll amount.
		this.scrollPosition += scrollAmount;
		this.playheadPosition += playheadAmount;

		// Resync the conductor and audio tracks.
		if (scrollAmount != 0 || playheadAmount != 0)
			moveSongToScrollPosition();
	}

	/**
	 * Handle display of the mouse cursor.
	 */
	function handleCursor()
	{
		// Note: If a menu is open in HaxeUI, don't handle cursor behavior.
		if (FlxG.mouse.overlaps(gridTiledSprite) && (!isModalDialogOpen) && (!isCursorOverHaxeUI))
		{
			// Cursor position relative to the grid.
			var cursorX:Float = FlxG.mouse.screenX - gridTiledSprite.x;
			var cursorY:Float = FlxG.mouse.screenY - gridTiledSprite.y;

			// The song position of the cursor, in steps.
			var cursorFractionalStep:Float = cursorY / GRID_SIZE;
			var cursorStep:Int = Math.floor(cursorFractionalStep);
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

			gridCursor.visible = true;
			// X and Y are the cursor position relative to the grid, snapped to the top left of the grid square.
			gridCursor.x = Math.floor(cursorX / GRID_SIZE) * GRID_SIZE + gridTiledSprite.x;
			gridCursor.y = cursorStep * GRID_SIZE + gridTiledSprite.y;

			// Handle clicks.

			// Left click.
			if (FlxG.mouse.justPressed)
			{
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
						// Select/deselect an individual note.
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
					}
				}
				else
				{
					if (highlightedNote != null)
					{
						// Remove the note.
						performCommand(new RemoveNotesCommand([highlightedNote.noteData]));
					}
					else
					{
						// Place a note.
						var eventColumn = (STRUMLINE_SIZE * 2 + 1) - 1;
						if (cursorColumn == eventColumn)
						{
							// Create an event and place it in the chart.
							var cursorMs = cursorStep * Conductor.stepCrochet;

							// TODO: Allow configuring the event to place from the sidebar.
							var newEventData:SongEventData = new SongEventData(cursorMs, "test", {});

							performCommand(new AddEventsCommand([newEventData]));
						}
						else
						{
							// Create a note and place it in the chart.
							var cursorMs = cursorStep * Conductor.stepCrochet;

							var newNoteData:SongNoteData = new SongNoteData(cursorMs, cursorColumn, 0, selectedNoteKind);

							performCommand(new AddNotesCommand([newNoteData]));
						}
					}
				}
			}
		}
		else
		{
			gridCursor.visible = false;
			gridCursor.x = -9999;
			gridCursor.y = -9999;
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
			var viewAreaTop:Float = this.scrollPosition - GRID_TOP_PAD;
			var viewHeight:Float = (FlxG.height - MENU_BAR_HEIGHT);
			var viewAreaBottom:Float = this.scrollPosition + viewHeight;

			// Remove notes that are no longer visible and list the ones that are.
			var displayedNoteData:Array<SongNoteData> = [];
			for (noteSprite in renderedNotes.members)
			{
				if (noteSprite == null || !noteSprite.exists || !noteSprite.visible)
					continue;

				if (noteSprite.y + noteSprite.height < viewAreaTop || noteSprite.y > viewAreaBottom)
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
				else
				{
					displayedNoteData.push(noteSprite.noteData);
				}
			}

			// Add notes that are now visible.
			for (noteData in currentSongChartNoteData)
			{
				// Remember if we are already displaying this note.
				if (displayedNoteData.indexOf(noteData) != -1)
					continue;

				var noteTimePixels:Float = noteData.time / Conductor.stepCrochet * GRID_SIZE;

				// Make sure the note appears when scrolling up.
				var modifiedViewAreaTop = viewAreaTop - GRID_SIZE;

				if (noteTimePixels < modifiedViewAreaTop || noteTimePixels > viewAreaBottom)
					continue;

				// Else, this note is visible and we need to render it!

				// Get a note sprite from the pool.
				// If we can reuse a deleted note, do so.
				// If a new note is needed, call buildNoteSprite.
				var noteSprite:ChartEditorNoteSprite = renderedNotes.recycle(ChartEditorNoteSprite);

				// The note sprite handles animation playback and positioning.
				noteSprite.noteData = noteData;

				// Setting note data resets position relative to the grid so we fix that.
				noteSprite.x += renderedNotes.x;
				noteSprite.y += renderedNotes.y;
			}

			// Handle selection squares.
			for (member in renderedNoteSelectionSquares.members)
			{
				member.kill();
			}

			for (noteSprite in renderedNotes.members)
			{
				if (isNoteSelected(noteSprite.noteData))
				{
					var selectionSquare:FlxSprite = renderedNoteSelectionSquares.recycle(FlxSprite).loadGraphic(selectionSquareBitmap);

					selectionSquare.x = noteSprite.x;
					selectionSquare.y = noteSprite.y;
					selectionSquare.width = noteSprite.width;
					selectionSquare.height = noteSprite.height;
				}
			}
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

		// CTRL + Y = Redo
		if (FlxG.keys.pressed.CONTROL && FlxG.keys.justPressed.Y)
		{
			redoLastCommand();
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
			openDialog('chart-editor/dialogs/user-guide');
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
					icon: "haxeui-core/styles/default/haxeui_tiny.png"
				});
				treeVariationDefault.expanded = true;

				var treeDifficultyEasy = treeVariationDefault.addNode({
					id: 'stv_difficulty_default_easy',
					text: "D: Easy",
					icon: "haxeui-core/styles/default/haxeui_tiny.png"
				});
				var treeDifficultyNormal = treeVariationDefault.addNode({
					id: 'stv_difficulty_default_normal',
					text: "D: Normal",
					icon: "haxeui-core/styles/default/haxeui_tiny.png"
				});
				var treeDifficultyHard = treeVariationDefault.addNode({
					id: 'stv_difficulty_default_hard',
					text: "D: Hard",
					icon: "haxeui-core/styles/default/haxeui_tiny.png"
				});

				var treeVariationErect = treeSong.addNode({id: 'stv_variation_erect', text: "V: Erect", icon: "haxeui-core/styles/default/haxeui_tiny.png"});
				treeVariationErect.expanded = true;

				var treeDifficultyErect = treeVariationErect.addNode({
					id: 'stv_difficulty_erect_erect',
					text: "D: Erect",
					icon: "haxeui-core/styles/default/haxeui_tiny.png"
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
		if (audioInstTrack.playing)
		{
			if (FlxG.mouse.pressedMiddle)
			{
				// If middle mouse panning during song playback, we move ONLY the playhead, without scrolling. Neat!

				var oldStepTime = Conductor.currentStepTime;
				Conductor.update(audioInstTrack.time);
				// Resync vocals.
				if (Math.abs(audioInstTrack.time - audioVocalTrack.time) > 100)
					audioVocalTrack.time = audioInstTrack.time;
				var diffStepTime = Conductor.currentStepTime - oldStepTime;

				// Move the playhead.
				playheadPosition += diffStepTime * GRID_SIZE;

				// We don't move the song to scroll position, or update the note sprites.
			}
			else
			{
				// Else, move the entire view.

				Conductor.update(audioInstTrack.time);
				// Resync vocals.
				if (Math.abs(audioInstTrack.time - audioVocalTrack.time) > 100)
					audioVocalTrack.time = audioInstTrack.time;

				// We need time in fractional steps here to allow the song to actually play.
				// Also account for a potentially offset playhead.
				scrollPosition = Conductor.currentStepTime * GRID_SIZE - playheadPosition;

				// DO NOT move song to scroll position here specifically.

				// We need to update the note sprites.
				noteDisplayDirty = true;
			}
		}

		if (FlxG.keys.justPressed.SPACE)
		{
			toggleAudioPlayback();
		}
	}

	function startAudioPlayback()
	{
		audioInstTrack.play();
		audioVocalTrack.play();
	}

	function stopAudioPlayback()
	{
		audioInstTrack.pause();
		audioVocalTrack.pause();
	}

	function toggleAudioPlayback()
	{
		if (audioInstTrack.playing)
		{
			stopAudioPlayback();
		}
		else
		{
			startAudioPlayback();
		}
	}

	function handlePlayheadKeybinds()
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
		var gridSnappedPlayheadPos = scrollPosition - (scrollPosition % GRID_SIZE);
	}

	function set_scrollPosition(value:Float):Float
	{
		if (value < 0)
		{
			// If we're scrolling up, and we hit the top,
			// but the playhead is in the middle, move the playhead up.
			if (playheadPosition > 0)
			{
				var amount = scrollPosition - value;
				playheadPosition -= amount;
			}

			value = 0;
		}

		if (value > songLength)
			value = songLength;

		if (value == scrollPosition)
			return value;

		this.scrollPosition = value;

		// Move the grid sprite to the correct position.
		if (isViewDownscroll)
		{
			gridTiledSprite.y = -scrollPosition + (MENU_BAR_HEIGHT + GRID_TOP_PAD);
		}
		else
		{
			gridTiledSprite.y = -scrollPosition + (MENU_BAR_HEIGHT + GRID_TOP_PAD);
		}
		// Move the rendered notes to the correct position.
		renderedNotes.setPosition(gridTiledSprite.x, gridTiledSprite.y);
		renderedNoteSelectionSquares.setPosition(renderedNotes.x, renderedNotes.y);

		return this.scrollPosition;
	}

	function set_playheadPosition(value:Float):Float
	{
		// Make sure playhead doesn't go outside the song.
		if (value + scrollPosition < 0)
			value = -scrollPosition;
		if (value + scrollPosition > songLength)
			value = songLength - scrollPosition;

		this.playheadPosition = value;

		// Move the playhead sprite to the correct position.
		gridPlayhead.y = this.playheadPosition + (MENU_BAR_HEIGHT + GRID_TOP_PAD);

		return this.playheadPosition;
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
	 * Opens a dialog.
	 * @param modal Makes the background uninteractable.
	 */
	function openDialog(key:String, modal:Bool = true)
	{
		var dialog:Dialog = cast buildComponent(Paths.ui(key));

		dialog.onDialogClosed = function(e:DialogEvent)
		{
			if (modal)
			{
				isModalDialogOpen = false;
			}
		}
		dialog.showDialog(modal);

		isModalDialogOpen = modal;
	}

	/**
	 * Load a music track for playback.
	 */
	function loadMusic()
	{
		// TODO: How to load music by selecting with a file dialog?
		audioInstTrack = FlxG.sound.play(Paths.inst('dadbattle'), 1.0, false);
		audioInstTrack.autoDestroy = false;
		audioInstTrack.pause();

		// Prevent the time from skipping back to 0 when the song ends.
		audioInstTrack.onComplete = function()
		{
			audioInstTrack.pause();
			audioVocalTrack.pause();
		};

		audioVocalTrack = FlxG.sound.play(Paths.voices('dadbattle'), 1.0, false);
		audioVocalTrack.autoDestroy = false;
		audioVocalTrack.pause();

		// TODO: Make sure Conductor works properly with changing BPMs.
		var DAD_BATTLE_BPM = 180;
		var BOPEEBO_BPM = 100;
		Conductor.forceBPM(DAD_BATTLE_BPM);

		songLength = Std.int(Conductor.getTimeInSteps(audioInstTrack.length) * GRID_SIZE);

		gridTiledSprite.height = songLength;
		if (gridSpectrogram != null)
			gridSpectrogram.setSound(audioVocalTrack);

		scrollPosition = 0;
		playheadPosition = 0;
		moveSongToScrollPosition();
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
		audioInstTrack.time = scrollPositionInMs + playheadPositionInMs;
		audioVocalTrack.time = scrollPositionInMs + playheadPositionInMs;

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
