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
typedef TModifierNoName = {
	var value:Bool;
	var conflicts:Array<String>;
	var multi:Float;
	var ?times:Null<Bool>;
	var desc:String;
	var ?amount:Null<Float>;
	var ?defAmount:Null<Float>;
	var ?precision:Null<Float>;
	var ?minimum:Null<Float>;
	var ?maximum:Null<Float>;
	// used for things that give you points in both directions
	var ?absolute:Null<Bool>;
}
typedef TModifier = {
	> TModifierNoName,
	var name:String;
	var internName:String;
	
}
class ModifierState extends MusicBeatState
{

	// use only in this class
	public static var modifiers:Array<TModifier> = [
		{
			name: "",
			internName: "antijank",
			value: false,
			conflicts: [],
			multi: 1,
			times: true,
			desc: ""
		},
		{
			name: "Sick Mode",
			internName: "mfc",
			value: false,
			conflicts: [
				"fc",
				"gfc",
				"practice",
				"healthloss",
				"healthgain", "regen", "degen", "poison", "duo", "demo"],
			multi: 3,
			times: true,
			desc: "Instantly fail when you don't get 'Sick'"
		},
		{
			name: "Good Full Combo",
			internName : "gfc",
			value: false,
			conflicts: [
				"mfc",
				"fc",
				"practice",
				"healthloss",
				"healthgain",
				"regen",
				"degen",
				"poison",
				"duo",
				"demo"
			],
			multi : 2.5,
			times: true,
			desc: "Instantly fall if you get worse than 'Good'"
		},
		{
			name: "FC Mode",
			internName: "fc",
			value: false,
			conflicts: [
				"mfc","gfc", "practice", "healthloss", "healthgain", "regen", "degen", "poison", "duo", "demo"],
			multi: 2,
			times: true,
			desc: "Fail when you miss a note, Go for the Perfect!"
		},
		{
			name: "Practice Mode",
			internName: "practice",
			value: false,
			conflicts: ["mfc","gfc", "fc", "duo", "demo"],
			multi: 0,
			times: true,
			desc: "You can't die while you're in practice! (DISABLES SCORE)"
		},
		/*
		{
			name: "Health Gain \\^",
			internName: "hgu",
			value: false,
			conflicts: ["mfc", "fc", 4, 19, 21],
			multi: -0.5,
			desc: "Raise your health gain a little"
		},
		{
			name: "Health Gain \\v",
			internName: "hgd",
			value: false,
			conflicts: [0, 1, 3, 19, 21],
			multi: 0.5,
			desc: "Lower your health gain a little."
		},
		{
			name: "Health Loss \\^",
			internName: "hlu",
			value: false,
			conflicts: [0, 1, 6, 19, 21],
			multi: 0.5,
			desc: "Raise your health loss a little."
		},
		{
			name: "Health Loss \\v",
			internName: "hld",
			value: false,
			conflicts: [0, 1, 5, 19, 21],
			multi: -0.5,
			desc: "Lower your health loss a little."
		},
		*/
		{
			name: "Health Loss",
			internName: "healthloss",
			value:false,
			conflicts: ["mfc", "fc", "gfc"],
			multi: 0.1,
			amount: 1,
			defAmount: 1,
			precision: 0.5,
			minimum: 0,
			maximum: 10,
			desc: "How much health you lose. Can be changed numerically."
		},
		{
			name: "Health Gain",
			internName: "healthgain",
			value: false,
			conflicts: ["mfc", "fc", "gfc"],
			multi: -0.1,
			amount: 1,
			defAmount: 1,
			precision: 0.5,
			minimum: 0,
			maximum: 10,
			desc: "How much health you gain. Can be changed numerically."
		},
		{
			name: "Sup. Love",
			internName: "regen",
			value: false,
			conflicts: ["fc", "mfc", "degen", "duo", "demo", "gfc"],
			multi: -0.03,
			amount: 0,
			defAmount: 0,
			precision: 5,
			minimum: 0,
			maximum: 500,
			desc: "Who knew simping could be so healthy?"
		},
		{
			name: "Poison Fright",
			internName: "degen",
			value: false,
			conflicts: ["fc", "mfc", "duo", "regen", "demo", "gfc"],
			multi: 0.03,
			amount: 0,
			defAmount: 0,
			precision: 5,
			minimum: 0,
			maximum: 500,
			desc: "You are constantly losing health!"
		},
		{
			name: "Fragile Funkin",
			internName: "poison",
			value: false,
			conflicts: ["fc", "mfc", "duo", "demo", "gfc"],
			multi: 1,
			desc: "Missed note makes you lose a lot of health. You wanna have a bad time?"
		},
		{
			name: "Flipped Notes",
			internName: "flipped",
			value: false,
			conflicts: ["invis"],
			multi: 0.5,
			desc: "Notes are flipped"
		},
		{
			name: "Slow Notes",
			internName: "slow",
			value: false,
			conflicts: ["fast", "accel"],
			multi: -0.3,
			desc: "Notes are slow"
		},
		{
			name: "Fast Notes",
			value: false,
			internName: "fast",
			conflicts: ["slow", "accel"],
			multi: 0.8,
			desc: "Notes gotta go fast!"
		},
		{
			name: "Accel Notes",
			internName: "accel",
			value: false,
			conflicts: ["fast", "slow"],
			multi: 0.4,
			desc: "Notes get faster and faster"
		},
		{
			name: "Vnsh Notes",
			internName: "vanish",
			value: false,
			conflicts: ["invis"],
			multi: 0.5,
			desc: "Notes vanish when they get close to the strum line."
		},
		{
			name: "Invs Notes",
			internName: "invis",
			value: false,
			conflicts: ["flipped", "vanish", "snake", "drunk"],
			multi: 1.5,
			desc: "Notes are now invisible! Hard enough for you?"
		},
		{
			name: "Snake Notes",
			internName: "snake",
			value: false,
			conflicts: ["invis"],
			multi: 0.5,
			desc: "Notes smoove across the screen"
		},
		{
			name: "Drunk Notes",
			internName: "drunk",
			value: false,
			conflicts: ["invis"],
			multi: 0.5,
			desc: "Notes be like my dad after a long day at work"
		},
		{
			name: "Stuck in a loop",
			internName: "loop",
			value: false,
			conflicts: ["practice"],
			multi: 0,
			desc: "Insta-replay the level after you die!"
		},
		{
			name: "Duo Mode",
			internName: "duo",
			value: false,
			conflicts: ["mfc", "fc", "gfc", "healthloss", "regen", "degen", "poison", "oppnt", "demo"],
			multi: 0,
			times: true,
			desc: "Boogie with a friend! (FRIEND NOT REQUIRED)"
		},
		{
			name: "Oppnt. Play",
			internName: "oppnt",
			value: false,
			conflicts: ["duo", "demo"],
			multi: 0,
			desc: "Play as the enemy that wanted to beat up Boyfriend!"
		},
		{
			name: "Demo Mode",
			internName: "demo",
			value: false,
			conflicts: ["mfc", "fc","gfc", "healthloss", "regen", "degen", "poison", "oppnt", "duo"],
			multi: 0,
			times: true,
			desc: "Let the game play itself!"
		},
		{
			name: "Chart...",
			internName: "chart",
			value: false,
			conflicts: [],
			multi: 1,
			times: true,
			desc: "Open the Debug Menu without Pressing 7"
		},
		{
			name: "Char Select...",
			internName: "charselect",
			value: false,
			conflicts: [],
			multi: 1,
			times: true,
			desc: "You can just select some custom characters"
		},
		{
			name: "Play",
			internName: "play",
			value: false,
			conflicts: [],
			multi: 1,
			times: true,
			desc: "Play the Funkin Game!"
		}
	];
	var grpAlphabet:FlxTypedGroup<Alphabet>;
	var curSelected:Int = 1;
	var checkmarks:Array<FlxSprite> = [];
	var numberdisplays:Array<NumberDisplay> = [];
	var multiTxt:FlxText;
	public static var isStoryMode:Bool = false;
	public static var scoreMultiplier:Float = 1;
	var description:FlxText;
	public static var namedModifiers:Dynamic = {};
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
		multiTxt.setFormat("assets/fonts/vcr.ttf", 40, FlxColor.WHITE, RIGHT, OUTLINE, FlxColor.BLACK);
		multiTxt.text = "Multiplier: 1";
		multiTxt.scrollFactor.set();
		description = new FlxText(750, 150, 350, "", 90);
		description.setFormat("assets/fonts/vcr.ttf", 32, FlxColor.WHITE, LEFT, OUTLINE, FlxColor.BLACK);
		description.text = "Instantly fail when you don't get \"Sick\"";
		description.scrollFactor.set();
		for (modifier in 0...modifiers.length) {
			var swagModifier = new Alphabet(0, 10, "   "+modifiers[modifier].name, true, false, true);
			swagModifier.isMenuItem = true;
			swagModifier.targetY = modifier;
			var coolCheckmark:FlxSprite = new FlxSprite().loadGraphic('assets/images/checkmark.png');
			coolCheckmark.visible = modifiers[modifier].value;
			var displayNum:NumberDisplay = new NumberDisplay(0, 0, modifiers[modifier].defAmount, modifiers[modifier].precision, modifiers[modifier].minimum, modifiers[modifier].maximum);
			displayNum.visible = modifiers[modifier].amount != null;
			if (displayNum.visible)
				displayNum.value = modifiers[modifier].amount;
			displayNum.size = 90;
			checkmarks.push(coolCheckmark);
			numberdisplays.push(displayNum);
			displayNum.x += swagModifier.width + displayNum.width;
			swagModifier.add(coolCheckmark);
			swagModifier.add(displayNum);
			grpAlphabet.add(swagModifier);
			
			
			Reflect.setField(namedModifiers, modifiers[modifier].internName, modifiers[modifier]);
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
				LoadingState.loadAndSwitchState(new StoryMenuState());
			else
				LoadingState.loadAndSwitchState(new FreeplayState());
		}
		if (controls.UP_P)
		{
			changeSelection(-1);
		}
		if (controls.DOWN_P)
		{
			changeSelection(1);
		}
		if (controls.RIGHT_P) {
			changeAmount(true);
		}  else if (controls.LEFT_P) {
			changeAmount(false);
		}
		if (controls.ACCEPT)
			toggleSelection();
	}
	function changeAmount(increase:Bool=false) {
		if (!numberdisplays[curSelected].visible)
			// not meant to be here...
			return;
		numberdisplays[curSelected].changeAmount(increase);
		modifiers[curSelected].amount = numberdisplays[curSelected].value;
		if (numberdisplays[curSelected].value == numberdisplays[curSelected].useDefaultValue && modifiers[curSelected].value) {
			toggleSelection();
		}
		else if (numberdisplays[curSelected].value != numberdisplays[curSelected].useDefaultValue && !modifiers[curSelected].value) {
			toggleSelection();
		}
		calculateMultiplier();
	}
	function changeSelection(change:Int = 0)
	{

		FlxG.sound.play('assets/sounds/custom_menu_sounds/'
			+ CoolUtil.parseJson(FNFAssets.getText("assets/sounds/custom_menu_sounds/custom_menu_sounds.json")).customMenuScroll+'/scrollMenu' + TitleState.soundExt, 0.4);

		curSelected += change;



		curSelected = Std.int(FlxMath.wrap(curSelected, 1, modifiers.length - 1));
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
	}
	function calculateMultiplier() {
		scoreMultiplier = 1;
		var timesThings:Array<Float> = [];
		var i = 0;
		for (modifier in modifiers) {
			if (modifier.value) {
				if (modifier.times)
					timesThings.push(modifier.multi);
				else {
					trace(numberdisplays[i].changedBy);
					if (modifier.amount != null)
						scoreMultiplier += numberdisplays[i].changedBy * modifier.multi;
					else
						scoreMultiplier += modifier.multi;
				}
			}
			i++;
		}
		for (timesThing in timesThings) {
			scoreMultiplier *= timesThing;
		}
		if (scoreMultiplier <= 0 && timesThings.length == 0) {
			scoreMultiplier = 0.1;
		}
		multiTxt.text = "Multiplier: " + scoreMultiplier;
	}
	function toggleSelection() {			
		switch(modifiers[curSelected].internName) {
			case 'play':
				if (FlxG.sound.music != null)
					FlxG.sound.music.stop();
				LoadingState.loadAndSwitchState(new PlayState(), true);
			case 'chart':
				LoadingState.loadAndSwitchState(new ChartingState());
			case 'charselect':
				LoadingState.loadAndSwitchState(new ChooseCharState(PlayState.SONG.player1));
			case 'antijank':
				// do nothi n
			default:
					checkmarks[curSelected].visible = !checkmarks[curSelected].visible;
					for (conflicting in modifiers[curSelected].conflicts)
					{
						var coolNum = 0;
						for (modifier in 0...modifiers.length) {
							if (modifiers[modifier].internName == conflicting) {
								coolNum = modifier;
							}
						}
						checkmarks[coolNum].visible = false;
						modifiers[coolNum].value = false;
					}
					calculateMultiplier();

					modifiers[curSelected].value = checkmarks[curSelected].visible;
				if (modifiers[curSelected].value
					&& modifiers[curSelected].amount != null
					&& numberdisplays[curSelected].value == numberdisplays[curSelected].useDefaultValue) {
						numberdisplays[curSelected].changeAmount(true);
					} else if (!modifiers[curSelected].value){
						numberdisplays[curSelected].resetValues();
					}
					calculateMultiplier();
					multiTxt.text = "Multiplier: " + scoreMultiplier;
		}
	}
}
