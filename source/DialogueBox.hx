package;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.addons.text.FlxTypeText;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.group.FlxSpriteGroup;
import flixel.input.FlxKeyManager;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;

using StringTools;

//Yo percentage i recommend changing some shit, Don't gotta tho -Blue

class DialogueBox extends FlxSpriteGroup
{
	var box:FlxSprite;

	var curCharacter:String = '';

	var dialogue:Alphabet;
	var dialogueList:Array<String> = [];

	var swagDialogue:FlxTypeText;

	var dropText:FlxText;

	public var finishThing:Void->Void;

	var portraitLeft:FlxSprite;
	var portraitRight:FlxSprite;

	var handSelect:FlxSprite;
	var bgFade:FlxSprite;

	public function new(talkingRight:Bool = true, ?dialogueList:Array<String>)
	{
		super();

		switch (PlayState.SONG.song.toLowerCase())
		{
			case 'senpai':
				FlxG.sound.playMusic(Paths.music('Lunchbox'), 0);
				FlxG.sound.music.fadeIn(1, 0, 0.8);
			case 'thorns':
				FlxG.sound.playMusic(Paths.music('LunchboxScary'), 0);
				FlxG.sound.music.fadeIn(1, 0, 0.8);
		}

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

		box = new FlxSprite(-20, 45);
		
		//doesnt crash if its always true so daz kewl
		var hasDialog = true;

		var fontPixel = false;

		switch (PlayState.SONG.song.toLowerCase())
		{
			default:
				box.frames = Paths.getSparrowAtlas('speech_bubble_talking', 'shared');
				box.animation.addByPrefix('normalOpen', 'Speech Bubble Normal Open', 24, false);
				box.animation.addByIndices('normal', 'speech bubble normal', [11], "", 24);
				box.width = 225;
				box.height = 125;
				box.x = -500;
				box.y = 375;
			case 'senpai':
				box.frames = Paths.getSparrowAtlas('weeb/pixelUI/dialogueBox-pixel');
				box.animation.addByPrefix('normalOpen', 'Text Box Appear', 24, false);
				box.animation.addByIndices('normal', 'Text Box Appear', [4], "", 24);
				box.y +=322;
			case 'roses':
				FlxG.sound.play(Paths.sound('ANGRY_TEXT_BOX'));

				box.frames = Paths.getSparrowAtlas('weeb/pixelUI/dialogueBox-senpaiMad');
				box.animation.addByPrefix('normalOpen', 'SENPAI ANGRY IMPACT SPEECH', 24, false);
				box.animation.addByIndices('normal', 'SENPAI ANGRY IMPACT SPEECH', [4], "", 24);
				box.y +=322;

			case 'thorns':
				box.frames = Paths.getSparrowAtlas('weeb/pixelUI/dialogueBox-evil');
				box.animation.addByPrefix('normalOpen', 'Spirit Textbox spawn', 24, false);
				box.animation.addByIndices('normal', 'Spirit Textbox spawn', [11], "", 24);
				box.y +=322;

				var face:FlxSprite = new FlxSprite(320, 170).loadGraphic(Paths.image('weeb/spiritFaceForward'));
				face.setGraphicSize(Std.int(face.width * 6));
				add(face);
		}

		this.dialogueList = dialogueList;
		
		if (!hasDialog)
			return;

		if (PlayState.SONG.song.toLowerCase() == 'senpai' || PlayState.SONG.song.toLowerCase() == 'roses' || PlayState.SONG.song.toLowerCase() == 'thorns'){
			fontPixel = true;
			
			portraitLeft = new FlxSprite(-20, 40);
			portraitLeft.frames = Paths.getSparrowAtlas('weeb/senpaiPortrait');
			portraitLeft.animation.addByPrefix('enter', 'Senpai Portrait Enter', 24, false);
			portraitLeft.setGraphicSize(Std.int(portraitLeft.width * PlayState.daPixelZoom * 0.9));
			portraitLeft.updateHitbox();
			portraitLeft.scrollFactor.set();
			add(portraitLeft);
			portraitLeft.visible = false;
	
			portraitRight = new FlxSprite(0, 40);
			portraitRight.frames = Paths.getSparrowAtlas('weeb/bfPortrait');
			portraitRight.animation.addByPrefix('enter', 'Boyfriend portrait enter', 24, false);
			portraitRight.setGraphicSize(Std.int(portraitRight.width * PlayState.daPixelZoom * 0.9));
			portraitRight.updateHitbox();
			portraitRight.scrollFactor.set();
			add(portraitRight);
			portraitRight.visible = false;
		}
		else{

			if (PlayState.SONG.player2 != null){
				portraitLeft = new FlxSprite(-20, 40);
				portraitLeft.frames = Paths.getSparrowAtlas('Portraits/' + PlayState.SONG.player2 + 'Portrait', 'shared');
				portraitLeft.animation.addByPrefix('enter', 'Portrait Enter', 24, false);
				//portraitLeft.setGraphicSize(Std.int(portraitLeft.width * PlayState.daPixelZoom * 0.9));
				portraitLeft.updateHitbox();
				portraitLeft.scrollFactor.set();
				add(portraitLeft);
				portraitLeft.visible = false;
			}
			else{
				portraitLeft = new FlxSprite(-20, 40);
				portraitLeft.frames = Paths.getSparrowAtlas('Portraits/dadPortrait', 'shared');
				portraitLeft.animation.addByPrefix('enter', 'Portrait Enter', 24, false);
				//portraitLeft.setGraphicSize(Std.int(portraitLeft.width * PlayState.daPixelZoom * 0.9));
				portraitLeft.updateHitbox();
				portraitLeft.scrollFactor.set();
				add(portraitLeft);
				portraitLeft.visible = false;
			}

			portraitRight = new FlxSprite(0, 40);
			portraitRight.frames = Paths.getSparrowAtlas('Portraits/bfPortrait', 'shared');
			portraitRight.animation.addByPrefix('enter', 'Portrait Enter', 24, false);
			//portraitRight.setGraphicSize(Std.int(portraitRight.width * PlayState.daPixelZoom * 0.9));
			portraitRight.updateHitbox();
			portraitRight.scrollFactor.set();
			add(portraitRight);
			portraitRight.visible = false;
		}
		
		box.animation.play('normalOpen');
		box.updateHitbox();
		add(box);

		box.screenCenter(X);
		portraitLeft.screenCenter(X);

		handSelect = new FlxSprite(FlxG.width * 0.9, FlxG.height * 0.9).loadGraphic(Paths.image('weeb/pixelUI/hand_textbox', 'week6'));
		add(handSelect);


		if (!talkingRight)
		{
			// box.flipX = true;
		}

		//Add Text
		
		if (PlayState.SONG.song.toLowerCase() == 'senpai' || PlayState.SONG.song.toLowerCase() == 'roses' || PlayState.SONG.song.toLowerCase() == 'thorns'){
			box.setGraphicSize(Std.int(box.width * PlayState.daPixelZoom * 0.9));
			fontPixel = true;
		}
		else{
			fontPixel = false;
		}

		swagDialogue = new FlxTypeText(240, 500, Std.int(FlxG.width * 0.6), "", 32);
		swagDialogue.font = 'PhantomMuff 1.5';
		swagDialogue.color = 0xFF000000;
		swagDialogue.sounds = [FlxG.sound.load(Paths.sound('pixelText'), 0.6)];
		add(swagDialogue);

		dropText = new FlxText(242, 502, Std.int(FlxG.width * 0.6), "", 32);
		dropText.font = 'PhantomMuff 1.5';
		dropText.color = 0xFFD89494;
		dropText.visible = false;
		add(dropText);

		if (fontPixel == true){
			swagDialogue.font = 'Pixel Arial 11 Bold';
			dropText.font = 'Pixel Arial 11 Bold';
			swagDialogue.size = 32;
			dropText.size = 32;
		}

		dialogue = new Alphabet(0, 80, "", false, true);

		// dialogue.x = 90;
		// add(dialogue);
	}

	var dialogueOpened:Bool = false;
	var dialogueStarted:Bool = false;

	override function update(elapsed:Float)
	{
		// HARD CODING CUZ IM STUPDI
		if (PlayState.SONG.song.toLowerCase() == 'roses')
			portraitLeft.visible = false;
		if (PlayState.SONG.song.toLowerCase() == 'thorns')
		{
			portraitLeft.visible = false;
			//portraitLeft.color = FlxColor.BLACK;
			//swagDialogue.color = FlxColor.WHITE;
			//dropText.color = FlxColor.BLACK;
		}

		if (PlayState.SONG.song.toLowerCase() != 'roses' || PlayState.SONG.song.toLowerCase() != 'thorns'){
			//portraitLeft.color = FlxColor.BLACK;
			//swagDialogue.color = FlxColor.BLACK;
			dropText.color = FlxColor.BLACK;
		}

		dropText.text = swagDialogue.text;

		if (box.animation.curAnim != null)
		{
			if (box.animation.curAnim.name == 'normalOpen' && box.animation.curAnim.finished)
			{
				box.animation.play('normal');
				dialogueOpened = true;
			}
		}

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
						FlxG.sound.music.fadeOut(2.2, 0);

					new FlxTimer().start(0.2, function(tmr:FlxTimer)
					{
						box.alpha -= 1 / 5;
						bgFade.alpha -= 1 / 5 * 0.7;
						portraitLeft.visible = false;
						portraitRight.visible = false;
						swagDialogue.alpha -= 1 / 5;
						dropText.alpha = swagDialogue.alpha;
					}, 5);

					new FlxTimer().start(1.2, function(tmr:FlxTimer)
					{
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
		// var theDialog:Alphabet = new Alphabet(0, 70, dialogueList[0], false, true);
		// dialogue = theDialog;
		// add(theDialog);

		// swagDialogue.text = ;
		swagDialogue.resetText(dialogueList[0]);
		swagDialogue.start(0.04, true);

		//yay im not a complete idiot
		switch (curCharacter)
		{
			case 'player2':
				portraitRight.visible = false;
				portraitLeft.visible = false;
				if (!portraitLeft.visible)
				{
					//Use this for hardcoded only, Only works if sprite doesn't get changed by other character portraits. For example gf.
					swagDialogue.color = FlxColor.BLACK;
					portraitLeft.visible = true;
					portraitLeft.animation.play('enter');
				}
			case 'dad':
				portraitRight.visible = false;
				portraitLeft.visible = false;
				if (!portraitLeft.visible)
				{
					swagDialogue.color = FlxColor.RED;

					portraitLeft.frames = Paths.getSparrowAtlas('Portraits/dadPortrait', 'shared');
					portraitLeft.animation.addByPrefix('enter', 'Portrait Enter', 24, false);
					portraitLeft.screenCenter(X);

					portraitLeft.visible = true;
					portraitLeft.animation.play('enter');
				}
			case 'bf':
				portraitRight.visible = false;
				portraitLeft.visible = false;
				if (!portraitRight.visible)
				{
					swagDialogue.color = FlxColor.BLUE;
					portraitRight.visible = true;
					portraitRight.animation.play('enter');
				}
			case 'gf':
				portraitRight.visible = false;
				portraitLeft.visible = false;
				if (!portraitLeft.visible)
				{
					swagDialogue.color = FlxColor.RED;

					portraitLeft.frames = Paths.getSparrowAtlas('Portraits/gfPortrait', 'shared');
					portraitLeft.animation.addByPrefix('enter', 'Portrait Enter', 24, false);
					portraitLeft.screenCenter(X);

					portraitLeft.visible = true;
					portraitLeft.animation.play('enter');
				}
			case 'spirit':
				portraitRight.visible = false;
				portraitLeft.visible = false;
				if (!portraitLeft.visible)
				{
					//Pretty sure this man is a period stain sooooo color gonna be red!
					swagDialogue.color = FlxColor.RED;
					portraitLeft.visible = true;
					portraitLeft.animation.play('enter');
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
