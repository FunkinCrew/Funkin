package states;

import substates.UISkinSelect;
import substates.ControlMenuSubstate;
import modding.CharacterCreationState;
import utilities.MusicUtilities;
import ui.Option;
import ui.Checkbox;
import flixel.group.FlxGroup;
import debuggers.ChartingState;
import debuggers.StageMakingState;
import flixel.system.FlxSound;
import debuggers.AnimationDebug;
import utilities.Controls.Control;
import flash.text.TextField;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.addons.display.FlxGridOverlay;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.input.keyboard.FlxKey;
import flixel.math.FlxMath;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import lime.utils.Assets;
import ui.Alphabet;
import ui.ControlsBox;
import game.Song;
import debuggers.StageMakingState;
import game.Highscore;

class OptionsMenu extends MusicBeatState
{
	var curSelected:Int = 0;

	public static var inMenu = false;

	public var pages:Array<Dynamic> = [
		[
			"Categories",
			new PageOption("Gameplay", 0, "Gameplay"),
			new PageOption("Graphics", 1, "Graphics"),
			new PageOption("Tools", 2, "Tools"),
			new PageOption("Misc", 3, "Misc")
		],
		[
			"Gameplay",
			new PageOption("Back", 0, "Categories"),
			new ControlMenuSubStateOption("Binds", 1),
			new SongOffsetOption("Song Offset", 2),
			new AccuracyOption(3),
			new BoolOption("Downscroll", "downscroll", FlxG.save.data.downscroll, 4),
			new BoolOption("Centered Arrows", "middleScroll", FlxG.save.data.middleScroll, 5),
			new BoolOption("No Miss", "nohit", FlxG.save.data.nohit, 6),
			new BoolOption("Reset Button", "resetButtonOn", FlxG.save.data.resetButtonOn, 7),
			new BoolOption("Bot", "bot", FlxG.save.data.bot, 8),
			new BoolOption("Quick Restart", "quickRestart", FlxG.save.data.quickRestart, 9)
		],
		[
			"Graphics",
			new PageOption("Back", 0, "Categories"),
			new BoolOption("Enemy Arrow Glow", "enemyGlow", FlxG.save.data.enemyGlow, 1),
			new BoolOption("Note Splashes", "noteSplashes", FlxG.save.data.noteSplashes, 1),
			new BoolOption("Note Accuracy Text", "msText", FlxG.save.data.msText, 2),
			new BoolOption("FPS Counter", "fpsCounter", FlxG.save.data.fpsCounter, 3),
			new BoolOption("Memory Counter", "memoryCounter", FlxG.save.data.memoryCounter, 4),
			new UISkinSelectOption("UI Skin", 5)
		],
		[
			"Tools",
			new PageOption("Back", 0, "Categories"),
			new GameStateOption("Charter", 1, new ChartingState()),
			new GameStateOption("Animation Debug", 2, new AnimationDebug("dad")),
			//new GameStateOption("Stage Editor", 3, new StageMakingState("stage")),
			new GameStateOption("Character Creator", 3, new CharacterCreationState("bf"))
		],
		[
			"Misc",
			new PageOption("Back", 0, "Categories"),
			new BoolOption("Prototype Title Screen", "oldTitle", FlxG.save.data.oldTitle, 1),
			new BoolOption("Friday-Night Title Music", "nightMusic", FlxG.save.data.nightMusic, 2),
			new BoolOption("Watermarks", "watermarks", FlxG.save.data.watermarks, 3),
			new BoolOption("Freeplay Music", "freeplayMusic", FlxG.save.data.freeplayMusic, 4),
			new BoolOption("Discord RPC", "discordRPC", FlxG.save.data.discordRPC, 5)
		]
	];

	public var page:FlxTypedGroup<Option> = new FlxTypedGroup<Option>();

	public static var instance:OptionsMenu;

	override function create()
	{
		instance = this;

		var menuBG:FlxSprite = new FlxSprite().loadGraphic(Paths.image('menuDesat'));
		menuBG.color = 0xFFea71fd;
		menuBG.setGraphicSize(Std.int(menuBG.width * 1.1));
		menuBG.updateHitbox();
		menuBG.screenCenter();
		menuBG.antialiasing = true;
		add(menuBG);

		super.create();

		add(page);

		LoadPage("Categories");

		if(FlxG.sound.music == null)
			FlxG.sound.playMusic(MusicUtilities.GetOptionsMenuMusic(), 0.7, true);
	}

	public static function LoadPage(Page_Name:String)
	{
		inMenu = true;
		instance.curSelected = 0;

		var bruh = 0;

		for (x in instance.page.members)
		{
			x.Alphabet_Text.targetY = bruh - instance.curSelected;
			bruh++;
		}

		var curPage = instance.page;

		curPage.clear();

		var selectedPage:Array<Dynamic> = [];

		for(i in 0...instance.pages.length)
		{
			if(instance.pages[i][0] == Page_Name)
			{
				for(x in 0...instance.pages[i].length)
				{
					if(instance.pages[i][x] != Page_Name)
						selectedPage.push(instance.pages[i][x]);
				}
			}
		}

		for(x in selectedPage)
		{
			curPage.add(x);
		}

		inMenu = false;
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		if (!inMenu)
		{
			if (controls.UP_P)
			{
				curSelected -= 1;
				FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);
			}

			if (controls.DOWN_P)
			{
				curSelected += 1;
				FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);
			}

			if (controls.BACK)
				FlxG.switchState(new MainMenuState());
		}
		else
		{
			if(controls.BACK)
				inMenu = false;
		}

		if (curSelected < 0)
			curSelected = page.length - 1;

		if (curSelected >= page.length)
			curSelected = 0;

		var bruh = 0;

		for (x in page.members)
		{
			x.Alphabet_Text.targetY = bruh - curSelected;
			bruh++;
		}

		for (x in page.members)
		{
			if(x.Alphabet_Text.targetY != 0)
			{
				for(item in x.members)
				{
					item.alpha = 0.6;
				}
			}
			else
			{
				for(item in x.members)
				{
					item.alpha = 1;
				}
			}
		}
	}
}