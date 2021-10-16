package ui;

import flixel.input.actions.FlxAction;
import game.Cutscene;
import game.Cutscene.DialogueSection;
import flixel.system.FlxSound;
#if sys
import sys.FileSystem;
import sys.io.File;
#end
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
	var box:FlxSprite;

	var dialogue:FlxTypeText;
	var dialogueShadow:FlxText;

	public var finishThing:Void->Void;

	var portraitLeft:FlxSprite;
	var portraitRight:FlxSprite;

	var handSelect:FlxSprite;
	var bgFade:FlxSprite;
	var ambientMusic:FlxSound = null;

	var sections:Array<DialogueSection>;
	var cutscene:Cutscene;

	public function new(cutscene:Cutscene)
	{
		super();

		/*
		this.cutscene = cutscene;
		this.sections = this.cutscene.dialogueSections;

		// Ambient Music //

		if(cutscene.dialogueMusic != null)
			ambientMusic = FlxG.sound.load(Paths.music(cutscene.dialogueMusic, 'shared'), 0, true);

		if(ambientMusic != null && PlayState.playCutsceneLmao)
		{
			ambientMusic.play();
			ambientMusic.fadeIn(1, 0, 0.8);
		}

		// Background Fade //

		if(cutscene.bgFade)
		{
			bgFade = new FlxSprite(-200, -200).makeGraphic(Std.int(FlxG.width * 1.3), Std.int(FlxG.height * 1.3), 0xFFB3DFd8);
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

		box = new FlxSprite(0, 0);

		if(cutscene.dialogueSound != null)
			FlxG.sound.play(Paths.sound(cutscene.dialogueSound, 'shared'));

		//if(sections[0].box)

		switch (PlayState.SONG.song.toLowerCase())
		{
			case 'senpai':
				box.loadGraphic(Paths.image('weeb/pixelUI/dialogueBox-pixel', 'week6'));
			case 'roses':
				box.loadGraphic(Paths.image('weeb/pixelUI/dialogueBox-pixel', 'week6'));

			case 'thorns':
				box.loadGraphic(Paths.image('weeb/pixelUI/dialogueBox-evil', 'week6'));

				face = new FlxSprite(320, 170).loadGraphic(Paths.image('weeb/spiritFaceForward'));
				face.setGraphicSize(Std.int(face.width * 6));
				add(face);
		}

		dialogueOpened = true;
		*/
	}

	var dialogueOpened:Bool = false;
	var dialogueStarted:Bool = false;

	override function update(elapsed:Float)
	{
		/*
		// HARD CODING CUZ IM STUPDI
		if (PlayState.SONG.song.toLowerCase() == 'thorns')
		{
			portraitLeft.visible = false;
			swagDialogue.color = FlxColor.WHITE;
			dropText.color = FlxColor.BLACK;
		}

		dropText.text = swagDialogue.text;

		if (dialogueOpened && !dialogueStarted)
		{
			startDialogue();
			dialogueStarted = true;
		}

		if (FlxG.keys.justPressed.ANY  && dialogueStarted == true)
		{
			FlxG.sound.play(Paths.sound('clickText'), 0.8);

			if (sections[1] == null && sections[0] != null)
			{
				if (!isEnding)
				{
					isEnding = true;

					if (PlayState.SONG.song.toLowerCase() == 'senpai' || PlayState.SONG.song.toLowerCase() == 'thorns')
						ambientMusic.fadeOut(2.2, 0);

					new FlxTimer().start(0.2, function(tmr:FlxTimer)
					{
						box.alpha -= 1 / 5;
						bgFade.alpha -= 1 / 5 * 0.7;
						portraitLeft.visible = false;
						portraitRight.visible = false;
						swagDialogue.alpha = 1 / 5;
						dropText.alpha = swagDialogue.alpha;
						handSelect.alpha = swagDialogue.alpha;
					}, 5);

					new FlxTimer().start(1.2, function(tmr:FlxTimer)
					{
						if(ambientMusic != null)
							ambientMusic.stop();
						
						finishThing();
						kill();
					});
				}
			}
			else
			{
				sections.remove(sections[0]);
				startDialogue();
			}
		}
		*/
		super.update(elapsed);
	}

	var isEnding:Bool = false;

	function startDialogue():Void
	{
		/*
		swagDialogue.resetText(sections[0].dialogue.text);
		swagDialogue.start(0.04, true);

		switch (curCharacter)
		{
			case 'dad':
				portraitRight.visible = false;
				if (!portraitLeft.visible)
				{
					portraitLeft.visible = true;
				}
			case 'bf':
				portraitLeft.visible = false;
				if (!portraitRight.visible)
				{
					portraitRight.visible = true;
				}
		}*/
	}

	function reloadAssets()
	{
		/*
		var cutsceneData = sections[0];

		if(box != null)
		{
			remove(box);
			box.kill();
			box.destroy();
		}

		box = new FlxSprite(0, 0);

		var boxData = cutsceneData.box;

		if(boxData.animated)
		{
			box.frames = Paths.getSparrowAtlas("cutscenes/" + boxData.sprite);
			box.animation.addByPrefix("default", boxData.anim_Name, (boxData.fps != null ? boxData.fps : 24));
			box.animation.play("default");
		}

		if(boxData.antialiased != null)
			box.antialiasing = boxData.antialiased;

		if(boxData.scale != null)
			boxData.scale = 1;

		box.setGraphicSize(Std.int(box.width * boxData.scale));
		box.updateHitbox();

		box.screenCenter(X);

		box.y = FlxG.height - box.height;

		box.x += boxData.x;
		box.y += boxData.y;

		portraitLeft = new FlxSprite(255, 120);

		// hard coding cuz im not making proper system yet, just fixing bug
		if(PlayState.SONG.song.toLowerCase() != 'roses')
			portraitLeft.loadGraphic(Paths.image('weeb/senpai_Port', 'week6'));
		else
			portraitLeft.loadGraphic(Paths.image('weeb/senpaiAngry_Port', 'week6'));

		portraitLeft.setGraphicSize(Std.int(portraitLeft.width * PlayState.daPixelZoom * 0.9));
		portraitLeft.updateHitbox();
		portraitLeft.scrollFactor.set();

		var boxOffset = 0.0;

		if(PlayState.SONG.song.toLowerCase() != 'thorns')
			boxOffset = 3.7;

		box.setGraphicSize(Std.int(box.width * PlayState.daPixelZoom * 0.9));
		box.updateHitbox();
		box.screenCenter(X);

		portraitLeft.x = (box.x + (portraitLeft.width / 2)) + 10;
		portraitLeft.y = (box.y - (portraitLeft.height + (boxOffset * PlayState.daPixelZoom * 0.9)));

		if(PlayState.SONG.song.toLowerCase() != 'thorns')
			add(portraitLeft);
		
		portraitLeft.visible = false;

		portraitRight = new FlxSprite(700, 187);
		portraitRight.loadGraphic(Paths.image('weeb/bf_Port', 'week6'));
		portraitRight.setGraphicSize(Std.int(portraitRight.width * PlayState.daPixelZoom * 0.9));
		portraitRight.updateHitbox();
		portraitRight.scrollFactor.set();
		add(portraitRight);
		portraitRight.visible = false;

		box.y = (FlxG.height - box.height) - 15;
		add(box);

		handSelect = new FlxSprite(FlxG.width * 0.84, FlxG.height * 0.84).loadGraphic(Paths.image('weeb/pixelUI/hand_textbox'));
		handSelect.setGraphicSize(Std.int(handSelect.width * PlayState.daPixelZoom));
		if(PlayState.SONG.song.toLowerCase() != 'thorns')
			add(handSelect);

		dropText = new FlxText(242, 452, Std.int(FlxG.width * 0.6), "", 32);
		dropText.font = 'Pixel Arial 11 Bold';
		dropText.color = 0xFFD89494;
		add(dropText);

		swagDialogue = new FlxTypeText(240, 450, Std.int(FlxG.width * 0.6), "", 32);
		swagDialogue.font = 'Pixel Arial 11 Bold';
		swagDialogue.color = 0xFF3F2021;
		swagDialogue.sounds = [FlxG.sound.load(Paths.sound('cutscene/pixelText', 'shared'), 0.6)];
		add(swagDialogue);*/
	}
}
