package ui;

import game.Cutscene;
import game.Cutscene.DialogueSection;
import flixel.system.FlxSound;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.addons.text.FlxTypeText;
import flixel.group.FlxSpriteGroup;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;

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

	var bgFade:FlxSprite;

	var hand:FlxSprite;

	var music:FlxSound;

	public function new(cutscene:Cutscene)
	{
		cutscene_Data = cutscene;

		super();

		if(cutscene_Data.bgFade != false)
		{
			var color:FlxColor = FlxColor.WHITE;

			if(cutscene_Data.bgColor != null)
				color = FlxColor.fromString(cutscene_Data.bgColor);

			bgFade = new FlxSprite(-200, -200).makeGraphic(Std.int(FlxG.width * 1.3), Std.int(FlxG.height * 1.3), color);
			bgFade.scrollFactor.set();
			bgFade.alpha = 0;
			add(bgFade);	

			new FlxTimer().start(0.83, function(tmr:FlxTimer)
			{
				bgFade.alpha += (1 / 5) * 0.7;

				if (bgFade.alpha > 0.7)
					bgFade.alpha = 0.7;
			}, 5);
		}

		loadAssets();

		if(cutscene_Data.dialogueMusic != null)
		{
			music = FlxG.sound.load(Paths.music(cutscene_Data.dialogueMusic, "shared"), 1, true);
			music.play();
			music.fadeIn(1, 0, 0.8);
		}
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

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

					if(music != null)
						music.fadeOut(2.2, 0, function(_) {
							if(music != null)
								music.stop();
						});

					new FlxTimer().start(0.2, function(tmr:FlxTimer)
					{
						portraitLeft.visible = false;
						portraitRight.visible = false;
	
						box.alpha -= 1 / 5;

						if(bgFade != null)
							bgFade.alpha -= 1 / 5 * 0.7;
	
						if(dialogue != null)
							dialogue.alpha -= 1 / 5;
	
						if(dialogue_Shadow != null)
							dialogue_Shadow.alpha = dialogue.alpha;
	
						if(alphabet != null)
							alphabet.alpha -= 1 / 5;

						if(hand != null)
							hand.alpha -= 1 / 5;
					}, 5);
	
					new FlxTimer().start(1.2, function(tmr:FlxTimer)
					{
						finish_Function();
						kill();
					});
				}
			}
		}
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
			box.updateHitbox();

			box.setGraphicSize(Std.int(box.width * cutscene_Data.dialogueBoxSize));
			box.updateHitbox();
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

		if(cutscene_Data.dialogueBoxSize == null)
			cutscene_Data.dialogueBoxSize = 1;

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
				portraitRight.visible = false;

				if(cutscene_Data.dialogueBoxFlips)
					box.flipX = true;
			case "right":
				portraitRight.visible = true;
				portraitLeft.visible = false;

				if(cutscene_Data.dialogueBoxFlips)
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

		if(hand != null)
			remove(hand);

		if(current_Section.has_Hand)
		{
			hand = new FlxSprite().loadGraphic(Paths.image("cutscenes/" + current_Section.hand_Sprite.sprite, "shared"));
			hand.antialiasing = current_Section.hand_Sprite.antialiased;

			if(current_Section.hand_Sprite.scale == null)
				current_Section.hand_Sprite.scale = 1;
			
			hand.setGraphicSize(Std.int(hand.width * current_Section.hand_Sprite.scale));
			hand.updateHitbox();

			hand.x = (box.x + box.width) - hand.width;
			hand.y = (box.y + box.height) - hand.height;

			hand.x += current_Section.hand_Sprite.x;
			hand.y += current_Section.hand_Sprite.y;

			add(hand);
		}

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
				dialogue_Shadow.color = FlxColor.fromString(current_Section.dialogue.shadowColor);
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