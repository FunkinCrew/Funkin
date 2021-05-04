package;

import Controls.Control;
import flash.text.TextField;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.math.FlxMath;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import lime.utils.Assets;
#if sys
import sys.io.File;
#end
import haxe.Json;
using StringTools;
typedef TModifier = {
	var name:String;
	var value:Bool;
	var conflicts: Array<Int>;
	var multi: Float;
	var ?times:Null<Bool>;
	var desc:String;
}
class ModifierState extends MusicBeatState
{


	public static var modifiers:Array<TModifier>;
	var grpAlphabet:FlxTypedGroup<Alphabet>;
	var curSelected:Int = 0;
	var checkmarks:Array<FlxSprite> = [];
	var multiTxt:FlxText;
	public static var isStoryMode:Bool = false;
	public static var scoreMultiplier:Float = 1;
	var description:FlxText;
	override function create()
	{
		var menuBG:FlxSprite = new FlxSprite().loadGraphic('assets/images/menuDesat.png');
		menuBG.color = 0xFFea71fd;
		grpAlphabet = new FlxTypedGroup<Alphabet>();
		menuBG.setGraphicSize(Std.int(menuBG.width * 1.1));
		menuBG.updateHitbox();
		menuBG.screenCenter();
		menuBG.antialiasing = true;
		multiTxt = new FlxText(800, 60, 0, "", 200);
		multiTxt.setFormat("assets/fonts/vcr.ttf", 40, FlxColor.WHITE, RIGHT);
		multiTxt.text = "Multiplier: 1";
		multiTxt.scrollFactor.set();
		description = new FlxText(500, FlxG.height - 50, 0, "", 150);
		description.setFormat("assets/fonts/vcr.ttf", 40, FlxColor.WHITE, RIGHT, OUTLINE, FlxColor.BLACK);
		description.text = "Instantly fail when you don't get \"Sick\"";
		description.scrollFactor.set();
		// save between files
		if (modifiers == null) {
			modifiers = [
				{name: "Sick Mode", value: false, conflicts: [1,2,3,4,5,6,7,8,9,19,21], multi: 3, times: true, desc:"Instantly fail when you don't get 'Sick'"},
				{name:"FC Mode", value: false, conflicts: [0,2,3,4,5,6,7,8,9,19,21], multi: 2, times: true, desc:"Fail when you miss a note"},
				{name: "Practice Mode", value: false, conflicts: [0,1,18,19,21], multi: 0, times:true, desc:"You can't die while you're in practice! (Disables score.)"},
				{name: "Health Gain Up", value: false, conflicts: [0,1,4,19,21], multi: -0.5, desc:"Raise your health gain a little"},
				{name: "Health Gain Down", value: false, conflicts: [0,1,3,19,21], multi: 0.5, desc:"Lower your health gain a little."},
			 	{name: "Health Loss Up", value: false, conflicts: [0,1,6,19,21], multi: 0.5, desc:"Raise your health loss a little."},
			 	{name: "Health Loss Down", value: false, conflicts: [0,1,5,19,21], multi: -0.5, desc:"Lower your health loss a little."},
				{name: "Sup Love", value: false, conflicts: [0,1,8,19], multi: -0.4, desc:"Who knew simping could be so healthy?"},
				{name: "Poison Fright", value: false, conflicts: [0,1,7,19,21], multi: 0.4,desc:"You are constantly losing health!"},
				{name: "Fragile Funkin", value: false, conflicts: [0,1,19,21], multi: 1, desc:"Missed note makes you lose a lot of health. You wanna have a bad time?"},
				{name: "Flipped Notes", value: false, conflicts: [15], multi: 0.5, desc:"Notes are flipped"},
				{name: "Slow Notes", value: false, conflicts: [12,13], multi: -0.3,desc:"Notes are slow"},
				{name: "Fast Notes", value: false, conflicts: [11,13], multi: 0.8, desc:"Notes gotta go fast!"},
				{name: "Accel Notes", value: false, conflicts: [11,12], multi: 0.4, desc:"Notes get faster and faster"},
				{name: "Vnsh Notes", value: false, conflicts: [15], multi: 0.5, desc:"Notes vanish when they get close to the strum line."},
				{name: "Invs Notes", value: false, conflicts: [10,14,16], multi: 1.5, desc:"Notes are now invisible (Hard enough for you?)"},
				{name: "Snake Notes", value: false, conflicts: [15], multi: 0.5, desc:"Notes smoove across the screen"},
				{name: "Drunk Notes", value: false, conflicts: [15], multi: 0.5, desc:"Notes be like my dad after a long day at work"},
				{name: "Stuck in a loop", value: false, conflicts: [2], multi: 0, desc:"Insta-replay the level after you die! (Like in the Prototype!)"},
				{name:"Duo Mode", value: false, conflicts: [0,1,2,3,4,5,6,7,8,9,20,21], multi: 0,times:true, desc:"Boogie with a friend (Friend not required)"},
				{name: "Opponent Play", value: false, conflicts: [19,21],multi:0, desc:"Play as the enemy that you wanted to beat up Boyfriend!"},
				{name: "Demo Mode", value: false, conflicts: [19,20,0,1,2,3,4,5,6,7,8,9],multi:0,times:true, desc:"Let the game play itself! (You don't need FNFBot lol)"},
				{name: "Chart", value: false, conflicts: [], multi: 1, times:true, desc:"Open the Debug Menu without Pressing 7"},
				{name: "Char Select", value: false, conflicts: [], multi: 1, times:true, desc:"You can just select some custom characters"},
				{name: "Play", value: false, conflicts: [], multi: 1, times:true, desc:"Start your own Funkin Adventure"}

			];
		}
		for (modifier in 0...modifiers.length) {
			var swagModifier = new Alphabet(0, 10, "   "+modifiers[modifier].name, true, false, false);
			swagModifier.isMenuItem = true;
			swagModifier.targetY = modifier;
			var coolCheckmark:FlxSprite = new FlxSprite().loadGraphic('assets/images/checkmark.png');
			coolCheckmark.visible = modifiers[modifier].value;
			checkmarks.push(coolCheckmark);
			swagModifier.add(coolCheckmark);
			grpAlphabet.add(swagModifier);
		}
		add(menuBG);
		add(grpAlphabet);
		add(multiTxt);
		add(description);
		calculateMultiplier();
		multiTxt.text = "Multiplier: "+scoreMultiplier;
		changeSelection(0);
		super.create();
	}
	override function update(elapsed:Float) {
		super.update(elapsed);
		if (controls.BACK) {
			if (isStoryMode)
				FlxG.switchState(new StoryMenuState());
			else
				FlxG.switchState(new FreeplayState());
		}
		if (controls.UP_P)
		{
			changeSelection(-1);
		}
		if (controls.DOWN_P)
		{
			changeSelection(1);
		}

		if (controls.ACCEPT)
			toggleSelection();
	}
	function changeSelection(change:Int = 0)
	{

		FlxG.sound.play('assets/sounds/scrollMenu' + TitleState.soundExt, 0.4);

		curSelected += change;

		if (curSelected < 0)
			curSelected = modifiers.length - 1;
		if (curSelected >= modifiers.length)
			curSelected = 0;


		var bullShit:Int = 0;

		for (item in grpAlphabet.members)
		{
			item.targetY = bullShit - curSelected;
			bullShit++;

			item.alpha = 0.6;
			// item.setGraphicSize(Std.int(item.width * 0.8));

			if (item.targetY == 0)
			{
				item.alpha = 1;
				// item.setGraphicSize(Std.int(item.width));
			}
		}
		description.text = modifiers[curSelected].desc;
		description.x = FlxG.width - description.width - 50;
		description.y = FlxG.height - description.height - 10;
	}
	function calculateMultiplier() {
		scoreMultiplier = 1;
		var timesThings:Array<Float> = [];
		for (modifier in modifiers) {
			if (modifier.value) {
				if (modifier.times)
					timesThings.push(modifier.multi);
				else {
					scoreMultiplier += modifier.multi;
				}
			}
		}
		for (timesThing in timesThings) {
			scoreMultiplier *= timesThing;
		}
		if (scoreMultiplier < 0) {
			scoreMultiplier = 0;
		}
	}
	function toggleSelection() {			
		switch(modifiers[curSelected].name) {
			case 'Play':
				if (FlxG.sound.music != null)
					FlxG.sound.music.stop();
				FlxG.switchState(new PlayState());
			case 'Chart':
				FlxG.switchState(new ChartingState());
			case 'Char Select':
				FlxG.switchState(new ChooseCharState(PlayState.SONG.player1));
			default:
					checkmarks[curSelected].visible = !checkmarks[curSelected].visible;
					for (conflicting in modifiers[curSelected].conflicts)
					{
						checkmarks[conflicting].visible = false;
						modifiers[conflicting].value = false;
					}
					calculateMultiplier();

					modifiers[curSelected].value = checkmarks[curSelected].visible;
					calculateMultiplier();
					multiTxt.text = "Multiplier: " + scoreMultiplier;
		}
	}
}
