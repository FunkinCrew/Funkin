package funkin.ui.debug.charting;

import flixel.FlxSprite;
import flixel.addons.display.FlxGridOverlay;
import flixel.addons.display.FlxTiledSprite;
import flixel.group.FlxSpriteGroup;
import flixel.system.FlxSound;
import flixel.util.FlxColor;
import flixel.util.FlxSort;
import funkin.audio.visualize.PolygonSpectogram;
import funkin.play.HealthIcon;
import funkin.play.song.SongData.SongChartData;
import funkin.play.song.SongData.SongEventData;
import funkin.play.song.SongData.SongMetadata;
import funkin.play.song.SongData.SongNoteData;
import funkin.play.song.SongSerializer;
import funkin.ui.debug.charting.ChartEditorCommand;
import funkin.ui.haxeui.HaxeUIState;
import haxe.ui.containers.TreeView;
import haxe.ui.containers.dialogs.Dialog;
import haxe.ui.containers.menus.Menu.MenuEvent;
import haxe.ui.containers.menus.MenuBar;
import haxe.ui.containers.menus.MenuCheckBox;
import haxe.ui.containers.menus.MenuItem;
import haxe.ui.core.Component;
import haxe.ui.events.MouseEvent;
import haxe.ui.events.UIEvent;
import openfl.display.BitmapData;
import openfl.geom.Rectangle;

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

	static final DEFAULT_VARIATION = 'default';
	static final DEFAULT_DIFFICULTY = 'normal';

	// UI Element Sizes
	public static final GRID_SIZE:Int = 40;
	public static final STRUMLINE_SIZE = 4;
	static final MENU_BAR_HEIGHT = 32;
	static final GRID_TOP_PAD:Int = 8;

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

	var scrollPositionInMs(get, null):Float;

	/**
	 * scrollPosition, converted to milliseconds.
	 * TODO: Handle BPM changes.
	 */
	function get_scrollPositionInMs():Float
	{
		return scrollPositionInSteps * Conductor.stepCrochet;
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
	 * The note kind currently being placed. Defaults to `''`.
	 * Use the input in the sidebar to change this.
	 */
	var selectedNoteKind:String = '';

	/**
	 * Whether to play a metronome sound while the playhead moves.
	 */
	var shouldPlayMetronome:Bool = true;

	/**
	 * The current variation ID.
	 */
	var selectedVariation:String = DEFAULT_VARIATION;

	/**
	 * The selected difficulty ID.
	 */
	var selectedDifficulty:String = DEFAULT_DIFFICULTY;

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
	var currentSongChartNoteData(get, null):Array<SongNoteData>;

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

	/**
	 * Convenience property to get the event data for the current difficulty.
	 */
	var currentSongChartEventData(get, null):Array<SongEventData>;

	function get_currentSongChartEventData():Array<SongEventData>
	{
		if (currentSongChartData.events == null)
		{
			// Initialize to the default value if not set.
			currentSongChartData.events = [];
		}
		return currentSongChartData.events;
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

	/**
	 * Builds and displays the chart editor grid, including the playhead and cursor.
	 */
	function buildGrid()
	{
		makeGridBitmap(false);

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

		/*
			var sustainSprite:SustainTrail = new SustainTrail(0, 600, Paths.image('NOTE_hold_assets'), 0.9, false);
			sustainSprite.scrollFactor.set(0, 0);
			sustainSprite.x = gridTiledSprite.x;
			sustainSprite.y = gridTiledSprite.y + 32;
			sustainSprite.zoom *= 0.258; // 0.77;
			add(sustainSprite);
		 */
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

		// Add functionality to the menu items.

		addUIClickListener('menubarItemUndo', (event:MouseEvent) -> undoLastCommand());

		addUIClickListener('menubarItemRedo', (event:MouseEvent) -> redoLastCommand());

		addUIClickListener('menubarItemAbout', (event:MouseEvent) -> openDialog('chart-editor/dialogs/about'));

		addUIClickListener('menubarItemUserGuide', (event:MouseEvent) -> openDialog('chart-editor/dialogs/user-guide'));

		addUIChangeListener('menubarItemToggleSidebar', (event:UIEvent) ->
		{
			var sidebar:MenuCheckBox = findComponent('sidebar', MenuCheckBox);

			if (event.value)
			{
				sidebar.show();
			}
		});

		addUIChangeListener('menubarItemMetronomeEnabled', (event:UIEvent) ->
		{
			shouldPlayMetronome = event.value;
		});
		var metronomeEnabledCheckbox:MenuCheckBox = findComponent('menubarItemMetronomeEnabled', MenuCheckBox);
		if (metronomeEnabledCheckbox != null)
		{
			metronomeEnabledCheckbox.selected = shouldPlayMetronome;
		}

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

			handlePlayheadKeybinds();

			handleMenubar();
			handleSidebar();

			handleFileKeybinds();
			handleEditKeybinds();
			handleViewKeybinds();
			handleHelpKeybinds();
		}

		// DEBUG
		if (FlxG.keys.justPressed.A)
		{
			performCommand(new SwitchDifficultyCommand(selectedDifficulty, 'easy', selectedVariation, 'default'));
		}
		if (FlxG.keys.justPressed.S)
		{
			performCommand(new SwitchDifficultyCommand(selectedDifficulty, 'normal', selectedVariation, 'default'));
		}
		if (FlxG.keys.justPressed.D)
		{
			performCommand(new SwitchDifficultyCommand(selectedDifficulty, 'hard', selectedVariation, 'default'));
		}
		if (FlxG.keys.justPressed.F)
		{
			performCommand(new SwitchDifficultyCommand(selectedDifficulty, 'erect', selectedVariation, 'erect'));
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

		// PAGE DOWN = Jump Down 1 Measure
		if (FlxG.keys.justPressed.PAGEDOWN)
		{
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
			if (FlxG.mouse.diffY != 0)
			{
				// Scroll down by the amount dragged.
				scrollAmount += -FlxG.mouse.diffY;
				// Move the playhead by the same amount in the other direction so it is stationary.
				playheadAmount += FlxG.mouse.diffY;
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

		// END = Scroll to Bottom
		if (FlxG.keys.justPressed.END)
		{
			// Scroll amount is the difference between the current position and the bottom.
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
		if (FlxG.mouse.overlaps(gridTiledSprite) && (!isModalDialogOpen))
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
				var eventColumn = (STRUMLINE_SIZE * 2 + 1) - 1;
				if (cursorColumn == eventColumn)
				{
					// Place an event.

					/*
						var newEventData:SongEvent = new SongEventData(cursorMs, cursorColumn, 0, selectedNoteKind);
						currentSongChartEventData.push(newEventData);
						sortChartData();
					 */
				}
				else
				{
					// Create a note and place it in the chart.
					var cursorMs = cursorStep * Conductor.stepCrochet;

					var newNoteData:SongNoteData = new SongNoteData(cursorMs, cursorColumn, 0, selectedNoteKind);

					performCommand(new AddNoteCommand(newNoteData));
				}
			}

			// Right click.
			if (FlxG.mouse.justPressedRight)
			{
				for (noteSprite in renderedNotes.members)
				{
					if (noteSprite == null || !noteSprite.exists || !noteSprite.visible)
						continue;

					if (noteSprite.overlapsPoint(FlxG.mouse.getPosition()))
					{
						performCommand(new RemoveNoteCommand(noteSprite.noteData));
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
		}
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
				var treeSong = treeView.addNode({id: 'stv_song_dadbattle', text: "S: Dad Battle", icon: "haxeui-core/styles/default/haxeui_tiny.png"});
				treeSong.expanded = true;

				var treeVariationDefault = treeSong.addNode({
					id: 'stv_variation_default',
					text: "V: Default",
					icon: "haxeui-core/styles/default/haxeui_tiny.png"
				});
				var treeVariationErect = treeSong.addNode({id: 'stv_variation_erect', text: "V: Erect", icon: "haxeui-core/styles/default/haxeui_tiny.png"});

				var treeDifficultyEasy = treeVariationDefault.addNode({
					id: 'stv_difficulty_easy',
					text: "D: Easy",
					icon: "haxeui-core/styles/default/haxeui_tiny.png"
				});
				var treeDifficultyNormal = treeVariationDefault.addNode({
					id: 'stv_difficulty_normal',
					text: "D: Normal",
					icon: "haxeui-core/styles/default/haxeui_tiny.png"
				});
				var treeDifficultyHard = treeVariationDefault.addNode({
					id: 'stv_difficulty_hard',
					text: "D: Hard",
					icon: "haxeui-core/styles/default/haxeui_tiny.png"
				});

				var treeDifficultyErect = treeVariationErect.addNode({
					id: 'stv_difficulty_erect',
					text: "D: Erect",
					icon: "haxeui-core/styles/default/haxeui_tiny.png"
				});
			}
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
				// If middle mouse panning during song playback, move ONLY the playhead.

				var oldStepTime = Conductor.currentStepTime;
				Conductor.update(audioInstTrack.time);
				var diffStepTime = Conductor.currentStepTime - oldStepTime;

				// Move the playhead.
				playheadPosition += diffStepTime * GRID_SIZE;

				// We don't move the song to scroll position, or update the note sprites.
			}
			else
			{
				// Else, move the entire view.

				Conductor.update(audioInstTrack.time);

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
			if (audioInstTrack.playing)
			{
				audioInstTrack.pause();
				audioVocalTrack.pause();
			}
			else
			{
				audioInstTrack.play();
				audioVocalTrack.play();
			}
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
		gridTiledSprite.y = -scrollPosition + (MENU_BAR_HEIGHT + GRID_TOP_PAD);
		// Move the rendered notes to the correct position.
		renderedNotes.setPosition(gridTiledSprite.x, gridTiledSprite.y);

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
			sidebar.hidden = setUIValue('menubarItemToggleSidebar', !sidebar.hidden);
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
}
