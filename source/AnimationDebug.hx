package;

import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.addons.display.FlxGridOverlay;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import openfl.events.Event;
import openfl.events.IOErrorEvent;
import openfl.net.FileReference;
import flixel.addons.ui.FlxInputText;
import flixel.addons.ui.FlxUI9SliceSprite;
import flixel.addons.ui.FlxUI;
import flixel.addons.ui.FlxUIState;
import flixel.addons.ui.FlxUICheckBox;
import flixel.addons.ui.FlxUIDropDownMenu;
import flixel.addons.ui.FlxUIInputText;
import flixel.addons.ui.FlxUINumericStepper;
import flixel.addons.ui.FlxUITabMenu;
import flixel.addons.ui.FlxUITooltip.FlxUITooltipStyle;

/**
	*DEBUG MODE
 */
using StringTools;

class AnimationDebug extends MusicBeatState
{
	var _file:FileReference;
	var bf:Boyfriend;
	var dad:Character;
	var char:Character;
	var textAnim:FlxText;
	var dumbTexts:FlxTypedGroup<FlxText>;
	var animList:Array<String> = [];
	var curAnim:Int = 0;
	var isDad:Bool = true;
	var daAnim:String = 'spooky';
	var camFollow:FlxObject;

	var background:FlxSprite;
	var curt:FlxSprite;
	var front:FlxSprite;

	var UI_box:FlxUITabMenu;
	var UI_options:FlxUITabMenu;
	var offsetX:FlxUINumericStepper;
	var offsetY:FlxUINumericStepper;

	var characters:Array<String>;

	public function new(daAnim:String = 'bf')
	{
		super();
		this.daAnim = daAnim;
	}

	override function create()
	{
		// FlxG.sound.music.stop();

		// var gridBG:FlxSprite = FlxGridOverlay.create(10, 10);
		// gridBG.scrollFactor.set(0.5, 0.5);
		// add(gridBG);

		FlxG.mouse.visible = true;

		background = new FlxSprite(-600, -525).loadGraphic(Paths.loadImage('stageback', 'shared'));
		front = new FlxSprite(-650, 325).loadGraphic(Paths.loadImage('stagefront', 'shared'));
		curt = new FlxSprite(-500, -625).loadGraphic(Paths.loadImage('stagecurtains', 'shared'));
		background.antialiasing = FlxG.save.data.antialiasing;
		front.antialiasing = FlxG.save.data.antialiasing;
		curt.antialiasing = FlxG.save.data.antialiasing;

		background.screenCenter(X);
		background.scale.set(0.7, 0.7);
		front.screenCenter(X);
		front.scale.set(0.7, 0.7);
		curt.screenCenter(X);
		curt.scale.set(0.7, 0.7);

		background.scrollFactor.set(0.9, 0.9);
		curt.scrollFactor.set(0.9, 0.9);
		front.scrollFactor.set(0.9, 0.9);

		add(background);
		add(front);
		add(curt);

		dad = new Character(0, 0, daAnim);
		dad.screenCenter();
		dad.debugMode = true;
		add(dad);

		char = dad;
		dad.flipX = false;

		dumbTexts = new FlxTypedGroup<FlxText>();
		add(dumbTexts);

		textAnim = new FlxText(300, 16);
		textAnim.size = 26;
		textAnim.setBorderStyle(OUTLINE, FlxColor.BLACK, 2);
		textAnim.scrollFactor.set();
		add(textAnim);

		genBoyOffsets();

		addHelpText();

		characters = CoolUtil.coolTextFile(Paths.txt('data/characterList'));

		var tabs = [{name: "Offsets", label: 'Offset menu'},];

		UI_box = new FlxUITabMenu(null, tabs, true);

		UI_box.scrollFactor.set();
		UI_box.resize(150, 200);
		UI_box.x = FlxG.width - UI_box.width - 20;
		UI_box.y = 20;

		// var opt_tabs = [{name: "test", label: 'test'}];

		// UI_options = new FlxUITabMenu(null, opt_tabs, true);

		// UI_options.scrollFactor.set();
		// UI_options.selected_tab = 0;
		// UI_options.resize(300, 200);
		// UI_options.x = UI_box.x;
		// UI_options.y = FlxG.height - 300;
		// no need for now
		// add(UI_options);
		add(UI_box);

		addOffsetUI();

		camFollow = new FlxObject(0, 0, 2, 2);
		camFollow.screenCenter();
		add(camFollow);

		FlxG.camera.follow(camFollow);

		super.create();
	}

	function addOffsetUI():Void
	{
		var player1DropDown = new FlxUIDropDownMenu(10, 10, FlxUIDropDownMenu.makeStrIdLabelArray(characters, true), function(character:String)
		{
			remove(dad);
			dad = new Character(0, 0, characters[Std.parseInt(character)]);
			dad.screenCenter();
			dad.debugMode = true;
			dad.flipX = false;
			add(dad);

			replace(char, dad);
			char = dad;

			dumbTexts.clear();
			genBoyOffsets(true, true);
			updateTexts();
		});

		player1DropDown.selectedLabel = char.curCharacter;

		var offsetX_label = new FlxText(10, 50, 'X Offset');

		var UI_offsetX:FlxUINumericStepper = new FlxUINumericStepper(10, offsetX_label.y + offsetX_label.height + 10, 1,
			char.animOffsets.get(animList[curAnim])[0], -500.0, 500.0, 0);
		UI_offsetX.value = char.animOffsets.get(animList[curAnim])[0];
		UI_offsetX.name = 'offset_x';
		offsetX = UI_offsetX;

		var offsetY_label = new FlxText(10, UI_offsetX.y + UI_offsetX.height + 10, 'Y Offset');

		var UI_offsetY:FlxUINumericStepper = new FlxUINumericStepper(10, offsetY_label.y + offsetY_label.height + 10, 1,
			char.animOffsets.get(animList[curAnim])[0], -500.0, 500.0, 0);
		UI_offsetY.value = char.animOffsets.get(animList[curAnim])[1];
		UI_offsetY.name = 'offset_y';
		offsetY = UI_offsetY;

		var tab_group_offsets = new FlxUI(null, UI_box);
		tab_group_offsets.name = "Offsets";

		tab_group_offsets.add(offsetX_label);
		tab_group_offsets.add(offsetY_label);
		tab_group_offsets.add(UI_offsetX);
		tab_group_offsets.add(UI_offsetY);
		tab_group_offsets.add(player1DropDown);

		UI_box.addGroup(tab_group_offsets);
	}

	function genBoyOffsets(pushList:Bool = true, ?cleanArray:Bool = false):Void
	{
		if (cleanArray)
			animList.splice(0, animList.length);

		var daLoop:Int = 0;

		for (anim => offsets in char.animOffsets)
		{
			var text:FlxText = new FlxText(10, 20 + (18 * daLoop), 0, anim + ": " + offsets, 15);
			text.scrollFactor.set();
			text.setBorderStyle(OUTLINE, FlxColor.BLACK, 2);
			text.color = FlxColor.WHITE;
			dumbTexts.add(text);

			if (pushList)
				animList.push(anim);

			daLoop++;
		}
	}

	function saveBoyOffsets():Void
	{
		var result = "";

		for (anim => offsets in char.animOffsets)
		{
			var text = anim + " " + offsets.join(" ");
			result += text + "\n";
		}

		if ((result != null) && (result.length > 0))
		{
			_file = new FileReference();
			_file.addEventListener(Event.COMPLETE, onSaveComplete);
			_file.addEventListener(Event.CANCEL, onSaveCancel);
			_file.addEventListener(IOErrorEvent.IO_ERROR, onSaveError);
			_file.save(result.trim(), daAnim + "Offsets.txt");
		}
	}

	/**
	 * Called when the save file dialog is completed.
	 */
	function onSaveComplete(_):Void
	{
		_file.removeEventListener(Event.COMPLETE, onSaveComplete);
		_file.removeEventListener(Event.CANCEL, onSaveCancel);
		_file.removeEventListener(IOErrorEvent.IO_ERROR, onSaveError);
		_file = null;
		FlxG.log.notice("Successfully saved OFFSET DATA.");
	}

	/**
	 * Called when the save file dialog is cancelled.
	 */
	function onSaveCancel(_):Void
	{
		_file.removeEventListener(Event.COMPLETE, onSaveComplete);
		_file.removeEventListener(Event.CANCEL, onSaveCancel);
		_file.removeEventListener(IOErrorEvent.IO_ERROR, onSaveError);
		_file = null;
	}

	/**
	 * Called if there is an error while saving the offset data.
	 */
	function onSaveError(_):Void
	{
		_file.removeEventListener(Event.COMPLETE, onSaveComplete);
		_file.removeEventListener(Event.CANCEL, onSaveCancel);
		_file.removeEventListener(IOErrorEvent.IO_ERROR, onSaveError);
		_file = null;
		FlxG.log.error("Problem saving Offset data");
	}

	function updateTexts():Void
	{
		offsetX.value = char.animOffsets.get(animList[curAnim])[0];
		offsetY.value = char.animOffsets.get(animList[curAnim])[1];

		dumbTexts.forEach(function(text:FlxText)
		{
			text.kill();
			dumbTexts.remove(text, true);
		});
	}

	var helpText:FlxText;

	function addHelpText():Void
	{
		var helpTextValue = "Help:\nQ/E : Zoom in and out\nF : Flip\nI/J/K/L : Pan Camera\nW/S : Cycle Animation\nArrows : Offset Animation\nShift-Arrows : Offset Animation x10\nSpace : Replay Animation\nCTRL-S : Save Offsets to File\nEnter/ESC : Exit\nPress F1 to hide/show this!\n";
		helpText = new FlxText(940, 20, 0, helpTextValue, 15);
		helpText.scrollFactor.set();
		helpText.y = FlxG.height - helpText.height - 20;
		helpText.setBorderStyle(OUTLINE, FlxColor.BLACK, 2);
		helpText.color = FlxColor.WHITE;

		add(helpText);
	}

	override function getEvent(id:String, sender:Dynamic, data:Dynamic, ?params:Array<Dynamic>)
	{
		if (id == FlxUINumericStepper.CHANGE_EVENT && (sender is FlxUINumericStepper))
		{
			var offset:FlxUINumericStepper = cast sender;
			var offsetName = offset.name;
			switch (offsetName)
			{
				case 'offset_x':
					char.animOffsets.get(animList[curAnim])[0] = offset.value;
					updateTexts();
					genBoyOffsets(false);
					char.playAnim(animList[curAnim]);
				case 'offset_y':
					char.animOffsets.get(animList[curAnim])[1] = offset.value;
					updateTexts();
					genBoyOffsets(false);
					char.playAnim(animList[curAnim]);
			}
		}
	}

	override function update(elapsed:Float)
	{
		textAnim.text = char.animation.curAnim.name;

		if (FlxG.mouse.overlaps(char) && FlxG.mouse.pressed)
		{
			// HOW THE FUCK DO I CONVERT THIS
			char.animOffsets.get(animList[curAnim])[0] = -Math.round(FlxG.mouse.x - char.frameWidth * 1.5);
			char.animOffsets.get(animList[curAnim])[1] = -Math.round(FlxG.mouse.y - char.frameHeight / 2);

			updateTexts();
			genBoyOffsets(false);
			char.playAnim(animList[curAnim]);
			// TO MOUSE MOVEMENT?????????
		}

		if (FlxG.keys.justPressed.ESCAPE)
		{
			FlxG.mouse.visible = false;
			FlxG.switchState(new PlayState());
		}

		if (FlxG.keys.justPressed.E)
			FlxG.camera.zoom += 0.25;
		if (FlxG.keys.justPressed.Q)
			FlxG.camera.zoom -= 0.25;

		if (FlxG.keys.justPressed.F)
			char.flipX = !char.flipX;

		if (FlxG.keys.pressed.I || FlxG.keys.pressed.J || FlxG.keys.pressed.K || FlxG.keys.pressed.L)
		{
			if (FlxG.keys.pressed.I)
				camFollow.velocity.y = -90;
			else if (FlxG.keys.pressed.K)
				camFollow.velocity.y = 90;
			else
				camFollow.velocity.y = 0;

			if (FlxG.keys.pressed.J)
				camFollow.velocity.x = -90;
			else if (FlxG.keys.pressed.L)
				camFollow.velocity.x = 90;
			else
				camFollow.velocity.x = 0;
		}
		else
		{
			camFollow.velocity.set();
		}

		if (FlxG.keys.justPressed.W)
		{
			curAnim -= 1;
		}

		if (FlxG.keys.justPressed.S)
		{
			curAnim += 1;
		}

		if (curAnim < 0)
			curAnim = animList.length - 1;

		if (curAnim >= animList.length)
			curAnim = 0;

		if (FlxG.keys.justPressed.S || FlxG.keys.justPressed.W || FlxG.keys.justPressed.SPACE)
		{
			char.playAnim(animList[curAnim]);

			updateTexts();
			genBoyOffsets(false);
		}

		var upP = FlxG.keys.anyJustPressed([UP]);
		var rightP = FlxG.keys.anyJustPressed([RIGHT]);
		var downP = FlxG.keys.anyJustPressed([DOWN]);
		var leftP = FlxG.keys.anyJustPressed([LEFT]);

		var holdShift = FlxG.keys.pressed.SHIFT;
		var multiplier = 1;
		if (holdShift)
			multiplier = 10;

		if (upP || rightP || downP || leftP)
		{
			updateTexts();
			if (upP)
				char.animOffsets.get(animList[curAnim])[1] += 1 * multiplier;
			if (downP)
				char.animOffsets.get(animList[curAnim])[1] -= 1 * multiplier;
			if (leftP)
				char.animOffsets.get(animList[curAnim])[0] += 1 * multiplier;
			if (rightP)
				char.animOffsets.get(animList[curAnim])[0] -= 1 * multiplier;

			updateTexts();
			genBoyOffsets(false);
			char.playAnim(animList[curAnim]);
		}

		if (FlxG.keys.pressed.CONTROL && FlxG.keys.justPressed.S)
			saveBoyOffsets();

		if (FlxG.keys.justPressed.F1)
			FlxG.save.data.showHelp = !FlxG.save.data.showHelp;

		helpText.visible = FlxG.save.data.showHelp;

		super.update(elapsed);
	}
}
