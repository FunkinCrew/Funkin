package;

import flixel.FlxBasic;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxObject;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.util.FlxColor;
import flixel.text.FlxText;

using StringTools;

class OptionsMenu extends MusicBeatState
{
	var textMenuItems:Array<String> = 
	[
	'Controls',
	'Downscroll',
	'Ghost Tapping',
	'Note Splashes',
	'Light CPU Strums',
	'Watermarks',
	'Anti-Aliasing',
	'Show FPS',
	'BotPlay',
	'Color Party',
	'Hide HUD',
	'Framerate',
	"HaxeFlixel splash"
	];
	var description:String;

	var descriptions:Array<String> =
	[
	'Change controls',
	'Change strumline position',
	"If you press the arrow you don't get miss",
	'SPLOOSH',
	'Lights strums and splash if enemy hit it',
	'Turn on/off WB watermarks',
	'Turn on/off anti-aliasing',
	'Turn on/off fps cap',
	'Showcase your charts and mods with auto play(Thanks Kadedev for the code)',
	'Sync healthbar colors with icons',
	"Hide some HUD elements",
	"Change framerate",
	"Just a splash in start of the game"
	];

	var selector:FlxSprite;
	var curSelected:Int = 0;
	var versionShit:FlxText;
	var camFollow:FlxObject;
	var startedFuckinState:Bool = false;

	var grpOptionsTexts:FlxTypedGroup<Alphabet>;

	public function new()
	{
		super();
		
		var menuBG:FlxSprite = new FlxSprite().loadGraphic(Paths.image('menuDesat'));
		menuBG.color = 0xFFea71fd;
		menuBG.setGraphicSize(Std.int(menuBG.width * 1.1));
		menuBG.updateHitbox();
		menuBG.screenCenter();
		menuBG.antialiasing = true;
		add(menuBG);

		new flixel.util.FlxTimer().start(1, function(tmr:flixel.util.FlxTimer)
		{
			startedFuckinState = true;
		});

		changeItem(0);
		description = descriptions[0];
		super.create();

		camFollow = new FlxObject(0, 0, 1, 1);
		add(camFollow);

		grpOptionsTexts = new FlxTypedGroup<Alphabet>();
		add(grpOptionsTexts);

		for (i in 0...textMenuItems.length)
		{
			var optionText:Alphabet = new Alphabet(0, 30 + (curSelected * 10), textMenuItems[i], true);
			optionText.ID = i;
			optionText.targetY = i;
			grpOptionsTexts.add(optionText);
			optionText.screenCenter(XY);
		}

		versionShit = new FlxText(5, FlxG.height - 18, 0);
		versionShit.size = 12;
		versionShit.scrollFactor.set();
		versionShit.setFormat("VCR OSD Mono", 16, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		add(versionShit);
	}

	var bullShit:Int = 0;

	function changeItem(huh:Int = 0)
	{
		curSelected += huh;
		description = descriptions[curSelected];

		if (curSelected < 0)
		{
			curSelected = textMenuItems.length - 1;
			description = descriptions[textMenuItems.length - 1];
		}

		if (curSelected >= textMenuItems.length)
		{
			curSelected = 0;
			description = descriptions[0];
		}
	}
	override function update(elapsed:Float)
	{
		super.update(elapsed);

		if (controls.UP_P)
			changeItem(-1);

		if (controls.DOWN_P)
			changeItem(1);

		if(FlxG.keys.pressed.SHIFT)
		{
			if(FlxG.keys.pressed.LEFT)
				FlxG.save.data.offset -= 1;
			else if (FlxG.keys.pressed.RIGHT)
				FlxG.save.data.offset += 1;
		}
		else
		{
			if(FlxG.keys.justPressed.LEFT)
				FlxG.save.data.offset -= 1;
			else if (FlxG.keys.justPressed.RIGHT)
				FlxG.save.data.offset += 1;			
		}

		grpOptionsTexts.forEach(function(txt:Alphabet)
		{
			txt.color = FlxColor.WHITE;
			txt.alpha = 0;

			if (txt.ID == curSelected)
				txt.alpha = 1;
		});

		if(FlxG.save.data.offset < -150)
			FlxG.save.data.offset = -150;
		else if(FlxG.save.data.offset > 150)
			FlxG.save.data.offset = 150;

		versionShit.text = "(" + description + ") Offset: " + FlxG.save.data.offset + ' (Max 150, Min -150, Press SHIFT to go faster)';

		if (controls.ACCEPT)
		{
			switch (textMenuItems[curSelected].toLowerCase())
			{
				case "controls":
					FlxG.state.openSubState(new KeyBindMenu());
				case "downscroll":
					FlxG.save.data.downscroll = !FlxG.save.data.downscroll;
					if(FlxG.save.data.downscroll)
						FlxG.sound.play(Paths.sound('confirmMenu'));
					else
						FlxG.sound.play(Paths.sound('cancelMenu'));
				case "ghost tapping":
					FlxG.save.data.ghost = !FlxG.save.data.ghost;
					if(FlxG.save.data.ghost)
						FlxG.sound.play(Paths.sound('confirmMenu'));
					else
						FlxG.sound.play(Paths.sound('cancelMenu'));
				case "note splashes":
					FlxG.save.data.sploosh = !FlxG.save.data.sploosh;
					if(FlxG.save.data.sploosh)
						FlxG.sound.play(Paths.sound('confirmMenu'));
					else
						FlxG.sound.play(Paths.sound('cancelMenu'));
				case "light cpu strums":
					FlxG.save.data.cpuStrums = !FlxG.save.data.cpuStrums;
					if(FlxG.save.data.cpuStrums)
						FlxG.sound.play(Paths.sound('confirmMenu'));
					else
						FlxG.sound.play(Paths.sound('cancelMenu'));
				case "watermarks":
					FlxG.save.data.watermarks = !FlxG.save.data.watermarks;
					if(FlxG.save.data.watermarks)
						FlxG.sound.play(Paths.sound('confirmMenu'));
					else
						FlxG.sound.play(Paths.sound('cancelMenu'));	
				case "anti-aliasing":
					FlxG.save.data.antialiasing = !FlxG.save.data.antialiasing;
					if(FlxG.save.data.antialiasing)
						FlxG.sound.play(Paths.sound('confirmMenu'));
					else
						FlxG.sound.play(Paths.sound('cancelMenu'));		
				case 'show fps':
					Main.instance.changeFPS();
				case 'botplay':
					FlxG.save.data.botplay = !FlxG.save.data.botplay;
					if(FlxG.save.data.botplay)	
						FlxG.sound.play(Paths.sound('confirmMenu'));
					else
						FlxG.sound.play(Paths.sound('cancelMenu'));
				case 'color party':
					FlxG.save.data.colour = !FlxG.save.data.colour;
					if(FlxG.save.data.colour)
						FlxG.sound.play(Paths.sound('confirmMenu'));
					else
						FlxG.sound.play(Paths.sound('cancelMenu'));
				case 'hide hud':
				{
					FlxG.save.data.hud = !FlxG.save.data.hud;
					if(FlxG.save.data.hud)
						FlxG.sound.play(Paths.sound('confirmMenu'));
					else
						FlxG.sound.play(Paths.sound('cancelMenu'));
				}
				case 'haxeflixel splash':
					FlxG.save.data.splash = !FlxG.save.data.splash;
					if(FlxG.save.data.splash)
						FlxG.sound.play(Paths.sound('confirmMenu'));
					else
						FlxG.sound.play(Paths.sound('cancelMenu'));
			}
		}
		if(controls.BACK)
		{
			LoadingState.loadAndSwitchState(new MainMenuState());
		}
	}
}
