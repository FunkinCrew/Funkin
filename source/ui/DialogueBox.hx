package ui;

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

	var curCharacter:String = '';

	var dialogue:Alphabet;
	var dialogueList:Array<String> = [];

	// SECOND DIALOGUE FOR THE PIXEL SHIT INSTEAD???
	var swagDialogue:FlxTypeText;

	var dropText:FlxText;

	public var finishThing:Void->Void;

	var portraitLeft:FlxSprite;
	var portraitRight:FlxSprite;

	var handSelect:FlxSprite;
	var bgFade:FlxSprite;
	var ambientMusic:FlxSound = null;

	var sections:Array<DialogueSection>;

	public function new(sections:Array<DialogueSection>, ?music:String)
	{
		super();

		this.sections = sections;

		// Ambient Music //

		if(music != null)
			ambientMusic = FlxG.sound.load(Paths.music(music, 'shared'), 0, true);

		if(ambientMusic != null && PlayState.playCutsceneLmao)
		{
			ambientMusic.play();
			ambientMusic.fadeIn(1, 0, 0.8);
		}

		// Background Fade //

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

		box = new FlxSprite(120, 450);

		var face:FlxSprite = new FlxSprite(-1000);
		
		var hasDialog = false;
		switch (PlayState.SONG.song.toLowerCase())
		{
			case 'senpai':
				box.loadGraphic(Paths.image('weeb/pixelUI/dialogueBox-pixel', 'week6'));
			case 'roses':
				FlxG.sound.play(Paths.sound('ANGRY_TEXT_BOX'));
				box.loadGraphic(Paths.image('weeb/pixelUI/dialogueBox-pixel', 'week6'));

			case 'thorns':
				box.loadGraphic(Paths.image('weeb/pixelUI/dialogueBox-evil', 'week6'));

				face = new FlxSprite(320, 170).loadGraphic(Paths.image('weeb/spiritFaceForward'));
				face.setGraphicSize(Std.int(face.width * 6));
				add(face);
		}

		#if sys
		hasDialog = FileSystem.exists(Sys.getCwd() + "assets/data/song data/" + PlayState.SONG.song.toLowerCase() + "/dialogue.txt");
		#else
		hasDialog = PlayState.SONG.song.toLowerCase() == 'senpai' || PlayState.SONG.song.toLowerCase() == "roses" || PlayState.SONG.song.toLowerCase() == "thorns";
		#end

		if (!hasDialog)
			return;

		this.dialogueList = CoolUtil.coolTextFile(Paths.txt("song data/" + PlayState.SONG.song.toLowerCase() + "/dialogue"));
		
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
		add(swagDialogue);

		dialogue = new Alphabet(0, 80, "", false, true);

		dialogueOpened = true;
	}

	var dialogueOpened:Bool = false;
	var dialogueStarted:Bool = false;

	override function update(elapsed:Float)
	{
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
			remove(dialogue);
				
			FlxG.sound.play(Paths.sound('clickText'), 0.8);

			if (dialogueList[1] == null && dialogueList[0] != null)
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
				dialogueList.remove(dialogueList[0]);
				startDialogue();
			}
		}
		
		super.update(elapsed);
	}

	var isEnding:Bool = false;

	function startDialogue():Void
	{
		cleanDialog();

		var gaming = dialogueList[0].replace("-lb-", "\n");

		var theDialog:Alphabet = new Alphabet(0, 70, gaming, false, true);
		dialogue = theDialog;
		//add(theDialog);

		var pixelDialogue = dialogueList[0].replace("-lb-", " ");

		swagDialogue.resetText(pixelDialogue);
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
		}
	}

	function cleanDialog():Void
	{
		var splitName:Array<String> = dialogueList[0].split(":");
		curCharacter = splitName[1];
		dialogueList[0] = dialogueList[0].substr(splitName[1].length + 2).trim();
	}
}
