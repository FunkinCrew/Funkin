package states;

import ui.ModIcon;
#if polymod
import modding.ModList;
import modding.PolymodHandler;
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

class ModsMenu extends MusicBeatState
{
	var curSelected:Int = 0;

	public var page:FlxTypedGroup<ModOption> = new FlxTypedGroup<ModOption>();

	public static var instance:ModsMenu;

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

		if(FlxG.sound.music == null)
			FlxG.sound.playMusic(MusicUtilities.GetOptionsMenuMusic(), 0.7, true);

		PolymodHandler.loadModMetadata();

		loadMods();
	}

	function loadMods()
	{
		page.forEachExists(function(option:ModOption)
		{
			page.remove(option);
			option.kill();
			option.destroy();
		});

		var optionLoopNum:Int = 0;

		for(modId in PolymodHandler.metadataArrays)
		{
			var modOption = new ModOption(ModList.modMetadatas.get(modId).title, modId, optionLoopNum);
			page.add(modOption);
			optionLoopNum++;
		}
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

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
		{
			PolymodHandler.loadMods();
			FlxG.switchState(new MainMenuState());
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
	}
}
#end