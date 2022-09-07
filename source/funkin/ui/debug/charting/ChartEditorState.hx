package funkin.ui.debug.charting;

import flixel.FlxSprite;
import flixel.addons.display.FlxGridOverlay;
import flixel.group.FlxSpriteGroup;
import flixel.util.FlxColor;
import funkin.ui.haxeui.HaxeUIState;
import haxe.ui.containers.dialogs.Dialog;
import haxe.ui.containers.menus.MenuItem;
import haxe.ui.core.Component;
import haxe.ui.events.MouseEvent;
import openfl.display.BitmapData;

class ChartEditorState extends HaxeUIState
{
	static final CHART_EDITOR_LAYOUT = Paths.ui('chart-editor/main-view');

	/**
	 * The number of notes on each character's strumline.
	 * TODO: Refactor this logic for larger strumlines in the future.
	 */
	static final STRUMLINE_SIZE = 4;

	/**
	 * The height of the menu bar in pixels. Used for positioning UI components.
	 */
	static final MENU_BAR_HEIGHT = 32;

	/**
	 * The width (and height) of each grid square, in pixels.
	 */
	static final GRID_SIZE:Int = 40;

	/**
	 * Pixel distance between the menu bar and the start of the chart grid.
	 */
	static final GRID_TOP_PAD:Int = 8;

	static final GRID_ALTERNATE:Bool = true;
	static final GRID_COLOR_1:FlxColor = 0xFFE7E6E6;
	static final GRID_COLOR_2:FlxColor = 0xFFD9D5D5;

	var gridBitmap:BitmapData;
	var gridSprites:FlxSpriteGroup;
	var gridDividerA:FlxSprite;
	var gridDividerB:FlxSprite;

	var menuBG:FlxSprite;

	// TODO: Make the unit of measurement for this non-arbitrary
	// to assist with logic later.
	var scrollPosition(default, set):Float = -1.0;

	public function new()
	{
		super(CHART_EDITOR_LAYOUT);
	}

	override function create()
	{
		FlxG.sound.music.stop();

		buildBackground();
		buildGrid();

		super.create();

		setupMenuListeners();

		scrollPosition = 0;
	}

	function buildBackground()
	{
		menuBG = new FlxSprite().loadGraphic(Paths.image('menuDesat'));
		add(menuBG);
		menuBG.color = 0xFF673ab7;
		menuBG.setGraphicSize(Std.int(menuBG.width * 1.1));
		menuBG.updateHitbox();
		menuBG.screenCenter();
		menuBG.scrollFactor.set(0, 0);
	}

	function buildGrid()
	{
		// The checkerboard background image of the chart.
		// 2 * (Strumline Size) + 1 grid squares wide, by 2 grid squares tall.
		// This gets reused to fill the screen.
		gridBitmap = FlxGridOverlay.createGrid(GRID_SIZE, GRID_SIZE, GRID_SIZE * (STRUMLINE_SIZE * 2 + 1), GRID_SIZE * 2, GRID_ALTERNATE, GRID_COLOR_1,
			GRID_COLOR_2);

		gridSprites = new FlxSpriteGroup();
		add(gridSprites);

		for (i in 0...10)
		{
			var gridSprite = new FlxSprite().loadGraphic(gridBitmap);
			gridSprite.x = FlxG.width / 2 - GRID_SIZE * STRUMLINE_SIZE; // Center the grid.
			gridSprite.y = MENU_BAR_HEIGHT + GRID_TOP_PAD + (i * gridSprite.height); // Push down to account for the menu bar.
			gridSprites.add(gridSprite);
		}

		// The black divider between the two halves of the chart.
		gridDividerA = new FlxSprite(gridSprites.members[0].x + GRID_SIZE * STRUMLINE_SIZE,
			MENU_BAR_HEIGHT).makeGraphic(2, FlxG.height - MENU_BAR_HEIGHT, FlxColor.BLACK);
		add(gridDividerA);
		gridDividerB = new FlxSprite(gridSprites.members[0].x + GRID_SIZE * STRUMLINE_SIZE * 2,
			MENU_BAR_HEIGHT).makeGraphic(2, FlxG.height - MENU_BAR_HEIGHT, FlxColor.BLACK);
		add(gridDividerB);
	}

	public override function update(elapsed:Float)
	{
		super.update(elapsed);

		FlxG.mouse.visible = true;

		handleScroll();

		if (FlxG.keys.justPressed.B)
			toggleSidebar();
	}

	function handleScroll()
	{
		var scrollAmount:Float = 0;

		if (FlxG.keys.justPressed.UP)
		{
			scrollAmount = -10;
		}
		if (FlxG.keys.justPressed.DOWN)
		{
			scrollAmount = 10;
		}
		if (FlxG.mouse.wheel != 0)
		{
			scrollAmount = -10 * FlxG.mouse.wheel;
		}

		if (FlxG.keys.pressed.SHIFT)
		{
			scrollAmount *= 10;
		}
		if (FlxG.keys.pressed.CONTROL)
		{
			scrollAmount /= 10;
		}

		this.scrollPosition += scrollAmount;
	}

	function set_scrollPosition(value:Float):Float
	{
		// TODO: Calculate this.
		var MAX_SCROLL = 10000;
		if (value == scrollPosition || value < 0 || value > MAX_SCROLL)
			return scrollPosition;

		this.scrollPosition = value;

		trace('SCROLL: $scrollPosition');

		// Move the grid sprites to the correct position.
		gridSprites.y = -scrollPosition;

		// Nudge the grid dividers down if needed.
		if (-gridSprites.y < GRID_TOP_PAD)
		{
			gridDividerA.y = MENU_BAR_HEIGHT + GRID_TOP_PAD + gridSprites.y;
			gridDividerB.y = MENU_BAR_HEIGHT + GRID_TOP_PAD + gridSprites.y;
		}
		else
		{
			gridDividerA.y = MENU_BAR_HEIGHT;
			gridDividerB.y = MENU_BAR_HEIGHT;
		}

		// Rearrange grid sprites so they stay on screen.
		gridSprites.forEachAlive(function(sprite:FlxSprite)
		{
			// If this grid sprite is off the top of the screen...
			if (sprite.y + sprite.height < MENU_BAR_HEIGHT)
			{
				// Move it to the bottom of the screen.
				sprite.y += sprite.height * gridSprites.length;
			}
			// If this grid sprite is off the bottom of the screen...
			if (sprite.y > FlxG.height)
			{
				// Move it to the top of the screen.
				sprite.y -= sprite.height * gridSprites.length;
			}
		});

		// TODO: Add a clip rectangle to the FlxSpriteGroup to hide the grid sprites that got moved up,
		// when we scroll back to the top of the chart.
		// Note that clip rectangles on sprite groups are borken right now, so we'll have to wait for that to be fixed.

		return this.scrollPosition;
	}

	function toggleSidebar()
	{
		var sidebar:Component = this.component.findComponent('sidebar', Component);

		sidebar.visible = !sidebar.visible;
	}

	function openDialog(key:String, modal:Bool = true)
	{
		var dialog:Dialog = cast buildComponent(Paths.ui(key));

		// modal = true makes the background unclickable
		dialog.showDialog(modal);
	}

	function setupMenuListeners()
	{
		addMenuListener('menubarItemToggleSidebar', (event:MouseEvent) -> toggleSidebar());
		addMenuListener('menubarItemAbout', (event:MouseEvent) -> openDialog('chart-editor/dialogs/about'));
		addMenuListener('menubarItemUserGuide', (event:MouseEvent) -> openDialog('chart-editor/dialogs/user-guide'));
	}

	function addMenuListener(key:String, callback:MouseEvent->Void)
	{
		var menuItem:MenuItem = this.component.findComponent(key, MenuItem);
		if (menuItem == null)
		{
			trace('WARN: Could not locate menu item: $key');
		}
		else
		{
			menuItem.onClick = callback;
		}
	}
}
