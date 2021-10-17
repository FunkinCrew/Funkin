package;

import flixel.FlxSubState;
import flixel.input.gamepad.FlxGamepad;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import openfl.Lib;
import Options;
import Controls.Control;
import flash.text.TextField;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.addons.display.FlxGridOverlay;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.input.keyboard.FlxKey;
import flixel.math.FlxMath;
import flixel.text.FlxText;
import flixel.util.FlxColor;

class OptionCata extends FlxSprite
{
	public var title:String;
	public var options:Array<Option>;

	public var optionObjects:FlxTypedGroup<FlxText>;

	public var titleObject:FlxText;

	public function new(x:Float, y:Float, _title:String, _options:Array<Option>)
	{
		super(x, y);
		title = _title;
		makeGraphic(295, 64, FlxColor.BLACK);
		alpha = 0.4;

		options = _options;

		optionObjects = new FlxTypedGroup();

		titleObject = new FlxText(x, y + 16, 0, title);
		titleObject.setFormat(Paths.font("vcr.ttf"), 35, FlxColor.WHITE, FlxTextAlign.LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		titleObject.borderSize = 3;

		titleObject.x += (width / 2) - (titleObject.fieldWidth / 2);

		titleObject.scrollFactor.set();

		scrollFactor.set();

		for (i in 0...options.length)
		{
			var opt = options[i];
			var text:FlxText = new FlxText(72, 112 + (46 * i), 0, opt.getDisplay());
			text.setFormat(Paths.font("vcr.ttf"), 35, FlxColor.WHITE, FlxTextAlign.LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
			text.borderSize = 3;
			text.borderQuality = 1;
			text.scrollFactor.set();
			optionObjects.add(text);
		}
	}

	public function changeColor(color:FlxColor)
	{
		makeGraphic(295, 64, color);
	}
}

class OptionsMenu extends FlxSubState
{
	public static var instance:OptionsMenu;

	public var background:FlxSprite;

	public var selectedCat:OptionCata;

	public var selectedOption:Option;

	public var selectedCatIndex = 0;
	public var selectedOptionIndex = 0;

	public var isInCat:Bool = false;

	var options:Array<OptionCata> = [
		new OptionCata(50, 40, "Gameplay", [
			new ScrollSpeedOption("Change your scroll speed. (1 = Chart dependent)"),
			new AccuracyDOption("Change how accuracy is calculated. (Accurate = Simple, Complex = Milisecond Based)"),
			new GhostTapOption("Toggle counting pressing a directional input when no arrow is there as a miss."),
			new DownscrollOption("Toggle making the notes scroll down rather than up."),
			#if desktop new FPSCapOption("Change your FPS Cap."),
			#end
			new ResetButtonOption("Toggle pressing R to gameover."),
			new InstantRespawn("Toggle if you instantly respawn after dying."),
			new CamZoomOption("Toggle the camera zoom in-game."),
			// new OffsetMenu("Get a note offset based off of your inputs!"),
			new DFJKOption(),
			new CustomizeGameplay("Drag and drop gameplay modules to your prefered positions!")
		]),
		new OptionCata(345, 40, "Appearance", [
			new NoteskinOption("Change your current noteskin"), new EditorRes("Not showing the editor grid will greatly increase editor performance"),
			new DistractionsAndEffectsOption("Toggle stage distractions that can hinder your gameplay."),
			new MiddleScrollOption("Put your lane in the center or on the right."), new HealthBarOption("Toggles health bar visibility"),
			new StepManiaOption("Sets the colors of the arrows depending on quantization instead of direction."),
			new AccuracyOption("Display accuracy information on the info bar."),
			new SongPositionOption("Show the song's current position as a scrolling bar."),
			new Colour("The color behind icons now fit with their theme. (e.g. Pico = green)"),
			new NPSDisplayOption("Shows your current Notes Per Second on the info bar."),
			new RainbowFPSOption("Make the FPS Counter flicker through rainbow colors."),
			new CpuStrums("Toggle the CPU's strumline lighting up when it hits a note."),
		]),
		new OptionCata(640, 40, "Misc", [
			new FPSOption("Toggle the FPS Counter"),
			new FlashingLightsOption("Toggle flashing lights that can cause epileptic seizures and strain."),
			new WatermarkOption("Enable and disable all watermarks from the engine."),
			new AntialiasingOption("Toggle antialiasing, improving graphics quality at a slight performance penalty."),
			new MissSoundsOption("Toggle miss sounds playing when you don't hit a note."),
			new ScoreScreen("Show the score screen after the end of a song"),
			new ShowInput("Display every single input on the score screen."),
		]),
		new OptionCata(935, 40, "Saves", [
			#if desktop // new ReplayOption("View saved song replays."),
			#end
			new ResetScoreOption("Reset your score on all songs and weeks. This is irreversible!"),
			new LockWeeksOption("Reset your story mode progress. This is irreversible!"),
			new ResetSettings("Reset ALL your settings. This is irreversible!")
		])
	];

	public var isInPause = false;

	public function new(pauseMenu:Bool = false)
	{
		super();

		isInPause = pauseMenu;
	}

	override function create()
	{
		instance = this;

		background = new FlxSprite(50, 40).makeGraphic(1180, 640, FlxColor.BLACK);
		background.alpha = 0.5;
		background.scrollFactor.set();
		add(background);

		if (isInPause)
		{
			var bg:FlxSprite = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
			bg.alpha = 0;
			bg.scrollFactor.set();
			add(bg);

			background.alpha = 0.3;
			bg.alpha = 0.6;

			cameras = [FlxG.cameras.list[FlxG.cameras.list.length - 1]];
		}

		selectedCat = options[0];

		selectedOption = selectedCat.options[0];

		for (cat in options)
		{
			add(cat);
			add(cat.titleObject);
		}

		switchCat(selectedCat);

		selectedOption = selectedCat.options[0];

		isInCat = true;

		super.create();
	}

	public function switchCat(cat:OptionCata)
	{
		selectedCat.changeColor(FlxColor.BLACK);
		selectedCat.alpha = 0.5;
		remove(selectedCat.optionObjects);
		selectedCat = cat;
		selectedCat.alpha = 0.2;
		selectedCat.changeColor(FlxColor.WHITE);
		add(selectedCat.optionObjects);

		selectedOption = selectedCat.options[0];

		Debug.logTrace("Changed cat: " + selectedCatIndex);
	}

	public function selectOption(option:Option)
	{
		var object = selectedCat.optionObjects.members[selectedOptionIndex];

		selectedOption = option;

		object.text = "> " + option.getDisplay();

		Debug.logTrace("Changed opt: " + selectedOptionIndex);
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		if (isInCat)
		{
			if (FlxG.keys.justPressed.RIGHT)
			{
				selectedCat.optionObjects.members[selectedOptionIndex].text = selectedOption.getDisplay();
				selectedCatIndex++;

				if (selectedCatIndex > options.length - 1)
					selectedCatIndex = 0;
				if (selectedCatIndex < 0)
					selectedCatIndex = options.length - 1;

				switchCat(options[selectedCatIndex]);
			}
			else if (FlxG.keys.justPressed.LEFT)
			{
				selectedCat.optionObjects.members[selectedOptionIndex].text = selectedOption.getDisplay();
				selectedCatIndex--;

				if (selectedCatIndex > options.length - 1)
					selectedCatIndex = 0;
				if (selectedCatIndex < 0)
					selectedCatIndex = options.length - 1;

				switchCat(options[selectedCatIndex]);
			}

			if (FlxG.keys.justPressed.ENTER)
			{
				selectedOptionIndex = 0;
				isInCat = false;
				selectedCat.optionObjects.members[0].text = "> " + selectedOption.getDisplay();
			}

			if (FlxG.keys.justPressed.ESCAPE)
			{
				if (!isInPause)
					FlxG.switchState(new MainMenuState());
				else
				{
					PauseSubState.goBack = true;
					close();
				}
			}
		}
		else
		{
			if (FlxG.keys.justPressed.DOWN)
			{
				selectedCat.optionObjects.members[selectedOptionIndex].text = selectedOption.getDisplay();
				selectedOptionIndex++;

				if (selectedOptionIndex > options[selectedCatIndex].options.length - 1)
					selectedOptionIndex = 0;
				if (selectedOptionIndex < 0)
					selectedOptionIndex = options[selectedCatIndex].options.length - 1;

				selectOption(options[selectedCatIndex].options[selectedOptionIndex]);
			}
			else if (FlxG.keys.justPressed.UP)
			{
				selectedCat.optionObjects.members[selectedOptionIndex].text = selectedOption.getDisplay();
				selectedOptionIndex--;

				if (selectedOptionIndex > options[selectedCatIndex].options.length - 1)
					selectedOptionIndex = 0;
				if (selectedOptionIndex < 0)
					selectedOptionIndex = options[selectedCatIndex].options.length - 1;

				selectOption(options[selectedCatIndex].options[selectedOptionIndex]);
			}

			if (FlxG.keys.justPressed.RIGHT)
			{
				var object = selectedCat.optionObjects.members[selectedOptionIndex];
				selectedOption.right();

				FlxG.save.flush();

				object.text = "> " + selectedOption.getValue();
				Debug.logTrace("New text: " + object.text + " " + FlxG.save.data.scrollSpeed);
			}
			else if (FlxG.keys.justPressed.LEFT)
			{
				var object = selectedCat.optionObjects.members[selectedOptionIndex];
				selectedOption.left();

				FlxG.save.flush();

				object.text = "> " + selectedOption.getValue();
				Debug.logTrace("New text: " + object.text);
			}

			if (FlxG.keys.justPressed.ENTER)
			{
				var object = selectedCat.optionObjects.members[selectedOptionIndex];
				selectedOption.press();

				FlxG.save.flush();

				object.text = "> " + selectedOption.getValue();
				isInCat = true;
			}

			if (FlxG.keys.justPressed.ESCAPE)
			{
				selectedCat.optionObjects.members[selectedOptionIndex].text = selectedOption.getDisplay();
				isInCat = true;
			}
		}
	}
}
