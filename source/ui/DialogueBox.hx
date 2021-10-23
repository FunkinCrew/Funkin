package ui;

import flixel.addons.display.shapes.FlxShapeType;
import haxe.io.Path;
import flixel.input.actions.FlxAction;
import game.Cutscene;
import game.Cutscene.DialogueSection;
import flixel.system.FlxSound;
import states.PlayState;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.addons.text.FlxTypeText;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.group.FlxSpriteGroup;
import flixel.input.FlxKeyManager;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
import utilities.CoolUtil;

using StringTools;

class DialogueBox extends FlxSpriteGroup
{
	var cutscene_Data:Cutscene;
	var current_Section:DialogueSection;
	var section_Index:Int = 0;

	var box:FlxSprite;

	var portraitRight:DialoguePortrait;
	var portraitLeft:DialoguePortrait;

	var dialogue:FlxTypeText;
	var dialogue_Shadow:FlxText;

	var alphabet:Alphabet;

	var exiting:Bool = false;
	var starting:Bool = true;

	public function new(cutscene:Cutscene)
	{
		cutscene_Data = cutscene;

		super();

		loadAssets();
	}

	override function update(elapsed:Float)
	{
		if(dialogue_Shadow != null)
			dialogue_Shadow.text = dialogue.text;

		if(FlxG.keys.justPressed.ENTER)
		{
			FlxG.sound.play(Paths.sound('clickText'), 0.8);

			section_Index++;

			if(section_Index < cutscene_Data.dialogueSections.length)
				loadAssets();
			else
			{
				if(!exiting)
				{
					exiting = true;

					new FlxTimer().start(0.2, function(tmr:FlxTimer)
					{
						portraitLeft.visible = false;
						portraitRight.visible = false;
	
						box.alpha -= 1 / 5;
	
						if(dialogue != null)
							dialogue.alpha -= 1 / 5;
	
						if(dialogue_Shadow != null)
							dialogue_Shadow.alpha = dialogue.alpha;
	
						if(alphabet != null)
							alphabet.alpha -= 1 / 5;
					}, 5);
	
					new FlxTimer().start(1.2, function(tmr:FlxTimer)
					{
						finish_Function();
						kill();
					});
				}
			}
		}

		super.update(elapsed);
	}

	public function loadAssets(?new_Cutscene:Cutscene) {
		// incase this is ever used lmao (i dont think it will be, but whatevs)
		if(new_Cutscene != null)
			cutscene_Data = new_Cutscene;

		current_Section = cutscene_Data.dialogueSections[section_Index];

		if(box == null)
		{
			box = new FlxSprite();
			box.frames = Paths.getSparrowAtlas("cutscenes/" + cutscene_Data.dialogueBox, "shared");
			box.scrollFactor.set(0,0);
		}

		if(current_Section.box_Open != null && current_Section.box_Open != "")
			box.animation.addByPrefix("open", current_Section.box_Open, current_Section.box_FPS, false);

		if(current_Section.box_Anim != null && current_Section.box_Anim != "")
			box.animation.addByPrefix("loop", current_Section.box_Anim, current_Section.box_FPS, true);

		box.animation.finishCallback = function(animName:String) {
			if(animName == "open")
				box.animation.play("loop");
		}
			
		box.animation.play("loop", true);

		if(current_Section.box_Antialiased != null)
			box.antialiasing = current_Section.box_Antialiased != false;

		box.updateHitbox();

		box.screenCenter(X);
		box.y = FlxG.height - box.height;

		if(portraitRight == null)
			portraitRight = new DialoguePortrait();

		if(current_Section.rightPortrait.scale == null)
			current_Section.rightPortrait.scale = 1;

		portraitRight.loadPortrait(current_Section.rightPortrait.sprite);
		portraitRight.setGraphicSize(Std.int(portraitRight.width * current_Section.rightPortrait.scale));
		portraitRight.updateHitbox();

		portraitRight.setPosition(
			((box.x + box.width) - portraitRight.width) + current_Section.rightPortrait.x,
			(box.y - portraitRight.height) + current_Section.rightPortrait.y
		);

		if(current_Section.rightPortrait.antialiased == null)
			portraitRight.antialiasing = current_Section.rightPortrait.antialiased;

		if(portraitLeft == null)
			portraitLeft = new DialoguePortrait();

		if(current_Section.leftPortrait.scale == null)
			current_Section.leftPortrait.scale = 1;

		portraitLeft.loadPortrait(current_Section.leftPortrait.sprite);
		portraitLeft.setGraphicSize(Std.int(portraitLeft.width * current_Section.leftPortrait.scale));
		portraitLeft.updateHitbox();

		portraitLeft.setPosition(
			box.x + current_Section.leftPortrait.x,
			(box.y - portraitLeft.height) + current_Section.leftPortrait.y
		);

		if(current_Section.leftPortrait.antialiased == null)
			portraitLeft.antialiasing = current_Section.leftPortrait.antialiased;

		switch(current_Section.side)
		{
			case "left":
				portraitLeft.visible = true;
				box.flipX = true;
			case "right":
				portraitRight.visible = true;
				box.flipX = false;
		}

		if(current_Section.showOtherPortrait)
		{
			portraitLeft.visible = true;
			portraitRight.visible = true;
		}

		if(current_Section.open_Box)
			box.animation.play("open", true);

		add(portraitRight);
		add(portraitLeft);
		add(box);

		if(dialogue_Shadow != null)
			remove(dialogue_Shadow);

		if(dialogue != null)
			remove(dialogue);

		if(alphabet != null)
			remove(alphabet);

		if(!current_Section.dialogue.alphabet)
		{
			if(current_Section.dialogue.hasShadow)
			{
				dialogue_Shadow = new FlxText(
					box.x + current_Section.dialogue.box_Offset[0] + current_Section.dialogue.shadowOffset,
					box.y + current_Section.dialogue.box_Offset[1] + current_Section.dialogue.shadowOffset,
					Std.int(FlxG.width * 0.6), "",
					current_Section.dialogue.size
				);
	
				dialogue_Shadow.font = Paths.font(current_Section.dialogue.font);
				dialogue_Shadow.color = 0xFFD89494;
				add(dialogue_Shadow);
			}
	
			dialogue = new FlxTypeText(
				box.x + current_Section.dialogue.box_Offset[0],
				box.y + current_Section.dialogue.box_Offset[1],
				Std.int(FlxG.width * 0.6), "",
				current_Section.dialogue.size
			);
	
			dialogue.font = Paths.font(current_Section.dialogue.font);
			dialogue.color = FlxColor.fromString(current_Section.dialogue.color);
	
			if(current_Section.dialogue.sound != null)
				dialogue.sounds = [FlxG.sound.load(Paths.sound(current_Section.dialogue.sound, "shared"), 0.6)];
	
			dialogue.resetText(current_Section.dialogue.text);
			dialogue.start((current_Section.dialogue.text_Delay != null ? current_Section.dialogue.text_Delay : 0.04), true);
	
			add(dialogue);
		}
		else
		{
			alphabet = new Alphabet(
				box.x + current_Section.dialogue.box_Offset[0],
				box.y + current_Section.dialogue.box_Offset[1],
				current_Section.dialogue.text,
				current_Section.dialogue.bold,
				true
			);

			add(alphabet);
		}
	}

	dynamic public function finish_Function() {}
}

class DialoguePortrait extends FlxSprite
{
	public function new(x:Float = 0.0, y:Float = 0.0) {
		super(x,y);
		
		scrollFactor.set(0,0); // cuz its ui lmao
	}

	public function loadPortrait(path:String)
	{
		// possibly add if statement for animated dialogue sprites in future (this is y its in a function lol)
		loadGraphic(Paths.image("cutscenes/" + path, "shared"));
	}
}