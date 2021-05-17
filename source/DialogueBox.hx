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

	public function new(talkingRight:Bool = true, ?dialogueList:Array<String>)
	{
		super();

		switch (PlayState.SONG.song.toLowerCase())
		{
			case 'tutorial':
				if (STOptionsRewrite._variables.extraDialogue) {
					if (PlayState.isStoryMode) {
						FlxG.sound.playMusic(Paths.music('Inst_Tutorial', 'tutorial'), 0.6);
						FlxG.sound.music.fadeIn(1, 0, 0.8);
					}
				}
			case 'bopeebo':
				if (STOptionsRewrite._variables.extraDialogue) {
					if (PlayState.isStoryMode) {
						FlxG.sound.playMusic(Paths.inst(PlayState.SONG.song), 0.6);
						FlxG.sound.music.fadeIn(1, 0, 0.8);
					}
				}
			case 'fresh':
				if (STOptionsRewrite._variables.extraDialogue) {
					if (PlayState.isStoryMode) {
						FlxG.sound.playMusic(Paths.inst(PlayState.SONG.song), 0.6);
						FlxG.sound.music.fadeIn(1, 0, 0.8);
					}
				}
			case 'spookeez':
				if (STOptionsRewrite._variables.extraDialogue) {
					if (PlayState.isStoryMode) {
						FlxG.sound.playMusic(Paths.inst(PlayState.SONG.song), 0.6);
						FlxG.sound.music.fadeIn(1, 0, 0.8);
					}
				}
			case 'south':
				if (STOptionsRewrite._variables.extraDialogue) {
					if (PlayState.isStoryMode) {
						FlxG.sound.playMusic(Paths.inst(PlayState.SONG.song), 0.6);
						FlxG.sound.music.fadeIn(1, 0, 0.8);
					}
				}
			case 'dadbattle':
				if (STOptionsRewrite._variables.extraDialogue) {
					if (PlayState.isStoryMode) {
						FlxG.sound.playMusic(Paths.inst(PlayState.SONG.song), 0.6);
						FlxG.sound.music.fadeIn(1, 0, 0.8);
					}
				}
			case 'monster':
				if (STOptionsRewrite._variables.extraDialogue) {
					if (PlayState.isStoryMode) {
						FlxG.sound.playMusic(Paths.music('Inst_Monster', 'week2'), 0.6);
						FlxG.sound.music.fadeIn(1, 0, 0.8);
					}
				}
			case 'pico':
				if (STOptionsRewrite._variables.extraDialogue) {
					if (PlayState.isStoryMode) {
						FlxG.sound.playMusic(Paths.inst(PlayState.SONG.song), 0.6);
						FlxG.sound.music.fadeIn(1, 0, 0.8);
					}
				}
			case 'philly-nice':
				if (STOptionsRewrite._variables.extraDialogue) {
					if (PlayState.isStoryMode) {
						FlxG.sound.playMusic(Paths.inst(PlayState.SONG.song), 0.6);
						FlxG.sound.music.fadeIn(1, 0, 0.8);
					}
				}
			case 'blammed':
				if (STOptionsRewrite._variables.extraDialogue) {
					if (PlayState.isStoryMode) {
						FlxG.sound.playMusic(Paths.inst(PlayState.SONG.song), 0.6);
						FlxG.sound.music.fadeIn(1, 0, 0.8);
					}
				}
			case 'satin-panties':
				if (STOptionsRewrite._variables.extraDialogue) {
					if (PlayState.isStoryMode) {
						FlxG.sound.playMusic(Paths.inst(PlayState.SONG.song), 0.6);
						FlxG.sound.music.fadeIn(1, 0, 0.8);
					}
				}
			case 'high':
				if (STOptionsRewrite._variables.extraDialogue) {
					if (PlayState.isStoryMode) {
						FlxG.sound.playMusic(Paths.inst(PlayState.SONG.song), 0.6);
						FlxG.sound.music.fadeIn(1, 0, 0.8);
					}
				}
			case 'milf':
				if (STOptionsRewrite._variables.extraDialogue) {
					if (PlayState.isStoryMode) {
						FlxG.sound.playMusic(Paths.inst(PlayState.SONG.song), 0.6);
						FlxG.sound.music.fadeIn(1, 0, 0.8);
					}
				}
			case 'cocoa':
				if (STOptionsRewrite._variables.extraDialogue) {
					if (PlayState.isStoryMode) {
						FlxG.sound.playMusic(Paths.inst(PlayState.SONG.song), 0.6);
						FlxG.sound.music.fadeIn(1, 0, 0.8);
					};
				}
			case 'eggnog':
				if (STOptionsRewrite._variables.extraDialogue) {
					if (PlayState.isStoryMode) {
						FlxG.sound.playMusic(Paths.inst(PlayState.SONG.song), 0.6);
						FlxG.sound.music.fadeIn(1, 0, 0.8);
					}
				}
			case 'winter-horrorland':
				if (STOptionsRewrite._variables.extraDialogue) {
					if (PlayState.isStoryMode) {
						FlxG.sound.playMusic(Paths.music('Inst_WinterHorrorland', 'week5'), 0.6);
						FlxG.sound.music.fadeIn(1, 0, 0.8);
					}
				}
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
		
		var hasDialog = false;
		switch (PlayState.SONG.song.toLowerCase())
		{
			case 'tutorial':
				if (STOptionsRewrite._variables.extraDialogue) {
					hasDialog = true;
					box.frames = Paths.getSparrowAtlas('speech_bubble_talking');
					box.animation.addByPrefix('normalOpen', 'Speech Bubble Normal Open', 24, false);
					box.animation.addByPrefix('normal', 'Speech Bubble Normal Open', 24, false);
					box.setGraphicSize(Std.int(box.width * 1 * 0.9));
					box.y = (FlxG.height - box.height) + 80;
				}
			case 'bopeebo':
				if (STOptionsRewrite._variables.extraDialogue) {
					hasDialog = true;
					box.frames = Paths.getSparrowAtlas('speech_bubble_talking');
					box.animation.addByPrefix('normalOpen', 'Speech Bubble Normal Open', 24, false);
					box.animation.addByPrefix('normal', 'Speech Bubble Normal Open', 24, false);
					box.setGraphicSize(Std.int(box.width * 1 * 0.9));
					box.y = (FlxG.height - box.height) + 80;
				}
			case 'fresh':
				if (STOptionsRewrite._variables.extraDialogue) {
					hasDialog = true;
					box.frames = Paths.getSparrowAtlas('speech_bubble_talking');
					box.animation.addByPrefix('normalOpen', 'Speech Bubble Normal Open', 24, false);
					box.animation.addByPrefix('normal', 'Speech Bubble Normal Open', 24, false);
					box.setGraphicSize(Std.int(box.width * 1 * 0.9));
					box.y = (FlxG.height - box.height) + 80;
				}
			case 'dadbattle':
				if (STOptionsRewrite._variables.extraDialogue) {
					hasDialog = true;
					box.frames = Paths.getSparrowAtlas('speech_bubble_talking');
					box.animation.addByPrefix('normalOpen', 'Speech Bubble Normal Open', 24, false);
					box.animation.addByPrefix('normal', 'Speech Bubble Normal Open', 24, false);
					box.setGraphicSize(Std.int(box.width * 1 * 0.9));
					box.y = (FlxG.height - box.height) + 80;
				}
			case 'spookeez':
				if (STOptionsRewrite._variables.extraDialogue) {
					hasDialog = true;
					box.frames = Paths.getSparrowAtlas('speech_bubble_talking');
					box.animation.addByPrefix('normalOpen', 'Speech Bubble Normal Open', 24, false);
					box.animation.addByPrefix('normal', 'Speech Bubble Normal Open', 24, false);
					box.setGraphicSize(Std.int(box.width * 1 * 0.9));
					box.y = (FlxG.height - box.height) + 80;
				}
			case 'south':
				if (STOptionsRewrite._variables.extraDialogue) {
					hasDialog = true;
					box.frames = Paths.getSparrowAtlas('speech_bubble_talking');
					box.animation.addByPrefix('normalOpen', 'Speech Bubble Normal Open', 24, false);
					box.animation.addByPrefix('normal', 'Speech Bubble Normal Open', 24, false);
					box.setGraphicSize(Std.int(box.width * 1 * 0.9));
					box.y = (FlxG.height - box.height) + 80;
				}
			case 'monster':
				if (STOptionsRewrite._variables.extraDialogue) {
					hasDialog = true;
					box.frames = Paths.getSparrowAtlas('speech_bubble_talking');
					box.animation.addByPrefix('normalOpen', 'Speech Bubble Normal Open', 24, false);
					box.animation.addByPrefix('normal', 'Speech Bubble Normal Open', 24, false);
					box.setGraphicSize(Std.int(box.width * 1 * 0.9));
					box.y = (FlxG.height - box.height) + 80;
				}
			case 'pico':
				if (STOptionsRewrite._variables.extraDialogue) {
					hasDialog = true;
					box.frames = Paths.getSparrowAtlas('speech_bubble_talking');
					box.animation.addByPrefix('normalOpen', 'Speech Bubble Normal Open', 24, false);
					box.animation.addByPrefix('normal', 'Speech Bubble Normal Open', 24, false);
					box.setGraphicSize(Std.int(box.width * 1 * 0.9));
					box.y = (FlxG.height - box.height) + 80;
				}
			case 'philly-nice':
				if (STOptionsRewrite._variables.extraDialogue) {
					hasDialog = true;
					box.frames = Paths.getSparrowAtlas('speech_bubble_talking');
					box.animation.addByPrefix('normalOpen', 'Speech Bubble Normal Open', 24, false);
					box.animation.addByPrefix('normal', 'Speech Bubble Normal Open', 24, false);
					box.setGraphicSize(Std.int(box.width * 1 * 0.9));
					box.y = (FlxG.height - box.height) + 80;
				}
			case 'blammed':
				if (STOptionsRewrite._variables.extraDialogue) {
					hasDialog = true;
					box.frames = Paths.getSparrowAtlas('speech_bubble_talking');
					box.animation.addByPrefix('normalOpen', 'Speech Bubble Normal Open', 24, false);
					box.animation.addByPrefix('normal', 'Speech Bubble Normal Open', 24, false);
					box.setGraphicSize(Std.int(box.width * 1 * 0.9));
					box.y = (FlxG.height - box.height) + 80;
				}
			case 'satin-panties':
				if (STOptionsRewrite._variables.extraDialogue) {
					hasDialog = true;
					box.frames = Paths.getSparrowAtlas('speech_bubble_talking');
					box.animation.addByPrefix('normalOpen', 'Speech Bubble Normal Open', 24, false);
					box.animation.addByPrefix('normal', 'Speech Bubble Normal Open', 24, false);
					box.setGraphicSize(Std.int(box.width * 1 * 0.9));
					box.y = (FlxG.height - box.height) + 80;
				}
			case 'high':
				if (STOptionsRewrite._variables.extraDialogue) {
					hasDialog = true;
					box.frames = Paths.getSparrowAtlas('speech_bubble_talking');
					box.animation.addByPrefix('normalOpen', 'Speech Bubble Normal Open', 24, false);
					box.animation.addByPrefix('normal', 'Speech Bubble Normal Open', 24, false);
					box.setGraphicSize(Std.int(box.width * 1 * 0.9));
					box.y = (FlxG.height - box.height) + 80;
				}
			case 'milf':
				if (STOptionsRewrite._variables.extraDialogue) {
					hasDialog = true;
					box.frames = Paths.getSparrowAtlas('speech_bubble_talking');
					box.animation.addByPrefix('normalOpen', 'Speech Bubble Normal Open', 24, false);
					box.animation.addByPrefix('normal', 'Speech Bubble Normal Open', 24, false);
					box.setGraphicSize(Std.int(box.width * 1 * 0.9));
					box.y = (FlxG.height - box.height) + 80;
				}
			case 'cocoa':
				if (STOptionsRewrite._variables.extraDialogue) {
					hasDialog = true;
					box.frames = Paths.getSparrowAtlas('speech_bubble_talking');
					box.animation.addByPrefix('normalOpen', 'Speech Bubble Normal Open', 24, false);
					box.animation.addByPrefix('normal', 'Speech Bubble Normal Open', 24, false);
					box.setGraphicSize(Std.int(box.width * 1 * 0.9));
					box.y = (FlxG.height - box.height) + 80;
				}
			case 'eggnog':
				if (STOptionsRewrite._variables.extraDialogue) {
					hasDialog = true;
					box.frames = Paths.getSparrowAtlas('speech_bubble_talking');
					box.animation.addByPrefix('normalOpen', 'Speech Bubble Normal Open', 24, false);
					box.animation.addByPrefix('normal', 'Speech Bubble Normal Open', 24, false);
					box.setGraphicSize(Std.int(box.width * 1 * 0.9));
					box.y = (FlxG.height - box.height) + 80;
				}
			case 'winter-horrorland':
				if (STOptionsRewrite._variables.extraDialogue) {
					hasDialog = true;
					box.frames = Paths.getSparrowAtlas('speech_bubble_talking');
					box.animation.addByPrefix('normalOpen', 'Speech Bubble Normal Open', 24, false);
					box.animation.addByPrefix('normal', 'Speech Bubble Normal Open', 24, false);
					box.setGraphicSize(Std.int(box.width * 1 * 0.9));
					box.y = (FlxG.height - box.height) + 80;
				}
			case 'senpai':
				hasDialog = true;
				box.frames = Paths.getSparrowAtlas('weeb/pixelUI/dialogueBox-pixel');
				box.animation.addByPrefix('normalOpen', 'Text Box Appear', 24, false);
				box.animation.addByIndices('normal', 'Text Box Appear', [4], "", 24);
				box.setGraphicSize(Std.int(box.width * PlayState.daPixelZoom * 0.9));

				handSelect = new FlxSprite(FlxG.width * 0.9, FlxG.height * 0.9).loadGraphic(Paths.image('weeb/pixelUI/hand_textbox'));
				add(handSelect);
			case 'roses':
				hasDialog = true;
				FlxG.sound.play(Paths.sound('ANGRY_TEXT_BOX'));

				box.frames = Paths.getSparrowAtlas('weeb/pixelUI/dialogueBox-senpaiMad');
				box.animation.addByPrefix('normalOpen', 'SENPAI ANGRY IMPACT SPEECH', 24, false);
				box.animation.addByIndices('normal', 'SENPAI ANGRY IMPACT SPEECH', [4], "", 24);
				box.setGraphicSize(Std.int(box.width * PlayState.daPixelZoom * 0.9));

				handSelect = new FlxSprite(FlxG.width * 0.9, FlxG.height * 0.9).loadGraphic(Paths.image('weeb/pixelUI/hand_textbox'));
				add(handSelect);

			case 'thorns':
				hasDialog = true;
				box.frames = Paths.getSparrowAtlas('weeb/pixelUI/dialogueBox-evil');
				box.animation.addByPrefix('normalOpen', 'Spirit Textbox spawn', 24, false);
				box.animation.addByIndices('normal', 'Spirit Textbox spawn', [11], "", 24);
				box.setGraphicSize(Std.int(box.width * PlayState.daPixelZoom * 0.9));

				handSelect = new FlxSprite(FlxG.width * 0.9, FlxG.height * 0.9).loadGraphic(Paths.image('weeb/pixelUI/hand_textbox'));
				add(handSelect);
		}

		this.dialogueList = dialogueList;
		
		if (!hasDialog)
			return;
		
		portraitLeft = new FlxSprite(-20, 40);
		add(portraitLeft);
		portraitLeft.visible = false;

		// small things: fix thorns layering issue
		if (PlayState.SONG.song.toLowerCase() == 'thorns')
		{
			var face:FlxSprite = new FlxSprite(320, 170).loadGraphic(Paths.image('weeb/spiritFaceForward'));
			face.setGraphicSize(Std.int(face.width * 6));
			add(face);
		}

		portraitRight = new FlxSprite(0, 40);
		add(portraitRight);
		portraitRight.visible = false;
		
		box.animation.play('normalOpen');
		box.updateHitbox();
		add(box);

		box.screenCenter(X);
		// portraitLeft.screenCenter(X);


		if (!talkingRight)
		{
			// box.flipX = true;
		}

		swagDialogue = new FlxTypeText(240, 500, Std.int(FlxG.width * 0.6), "", 32);
		swagDialogue.setFormat(Paths.font("vcr.ttf"), 40, FlxColor.BLACK, LEFT);
		dropText = new FlxText(242, 502, Std.int(FlxG.width * 0.6), "", 32);
		dropText.setFormat(Paths.font("vcr.ttf"), 40, FlxColor.BLACK, LEFT);

		if (PlayState.SONG.song.toLowerCase() == 'senpai' || PlayState.SONG.song.toLowerCase() == 'roses' || PlayState.SONG.song.toLowerCase() == 'thorns') {
			dropText = new FlxText(242, 502, Std.int(FlxG.width * 0.6), "", 32);
			dropText.font = 'Pixel Arial 11 Bold';
			dropText.color = 0xFFD89494;

			swagDialogue = new FlxTypeText(240, 500, Std.int(FlxG.width * 0.6), "", 32);
			swagDialogue.font = 'Pixel Arial 11 Bold';
			swagDialogue.color = 0xFF3F2021;
			swagDialogue.sounds = [FlxG.sound.load(Paths.sound('pixelText'), 0.6)];
		}

		add(dropText);
		add(swagDialogue);

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
			portraitLeft.color = FlxColor.BLACK;
			swagDialogue.color = FlxColor.WHITE;
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

					switch (PlayState.SONG.song.toLowerCase())
					{
						case 'tutorial':
							if (STOptionsRewrite._variables.extraDialogue)
								FlxG.sound.music.fadeOut(2.2, 0);
						case 'bopeebo':
							if (STOptionsRewrite._variables.extraDialogue)
								FlxG.sound.music.fadeOut(2.2, 0);
						case 'fresh':
							if (STOptionsRewrite._variables.extraDialogue)
								FlxG.sound.music.fadeOut(2.2, 0);
						case 'dadbattle':
							if (STOptionsRewrite._variables.extraDialogue)
								FlxG.sound.music.fadeOut(2.2, 0);
						case 'spookeez':
							if (STOptionsRewrite._variables.extraDialogue)
								FlxG.sound.music.fadeOut(2.2, 0);
						case 'south':
							if (STOptionsRewrite._variables.extraDialogue)
								FlxG.sound.music.fadeOut(2.2, 0);
						case 'monster':
							if (STOptionsRewrite._variables.extraDialogue)
								FlxG.sound.music.fadeOut(2.2, 0);
						case 'pico':
							if (STOptionsRewrite._variables.extraDialogue)
								FlxG.sound.music.fadeOut(2.2, 0);
						case 'philly-nice':
							if (STOptionsRewrite._variables.extraDialogue)
								FlxG.sound.music.fadeOut(2.2, 0);
						case 'blammed':
							if (STOptionsRewrite._variables.extraDialogue)
								FlxG.sound.music.fadeOut(2.2, 0);
						case 'satin-panties':
							if (STOptionsRewrite._variables.extraDialogue)
								FlxG.sound.music.fadeOut(2.2, 0);
						case 'high':
							if (STOptionsRewrite._variables.extraDialogue)
								FlxG.sound.music.fadeOut(2.2, 0);
						case 'milf':
							if (STOptionsRewrite._variables.extraDialogue)
								FlxG.sound.music.fadeOut(2.2, 0);
						case 'cocoa':
							if (STOptionsRewrite._variables.extraDialogue)
								FlxG.sound.music.fadeOut(2.2, 0);
						case 'eggnog':
							if (STOptionsRewrite._variables.extraDialogue)
								FlxG.sound.music.fadeOut(2.2, 0);
						case 'winter-horrorland':
							if (STOptionsRewrite._variables.extraDialogue)
								FlxG.sound.music.fadeOut(2.2, 0);
						case 'senpai':
							FlxG.sound.music.fadeOut(2.2, 0);
						case 'thorns':
							FlxG.sound.music.fadeOut(2.2, 0);
					}

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

				portraitLeft.visible = false;
				portraitRight.visible = false;

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

		switch (curCharacter)
		{
			case 'gf':
				swagDialogue.sounds = [FlxG.sound.load(Paths.sound('gfText'), 0.6)];
				swagDialogue.color = FlxColor.fromRGB(238, 21, 54);
				portraitRight.visible = false;
				if (!portraitLeft.visible)
				{
					portraitLeft.frames = Paths.getSparrowAtlas('portraits', 'shared');
					portraitLeft.animation.addByPrefix('enter', 'gf portrait', 24, false);
					portraitLeft.setGraphicSize(Std.int(portraitLeft.width * 1 * 0.75));
					portraitLeft.antialiasing = true;
					portraitLeft.updateHitbox();
					portraitLeft.scrollFactor.set();
					// portraitLeft.screenCenter(X);

					portraitLeft.x = box.x + 64;
					portraitLeft.y = box.y - 200;

					portraitLeft.visible = true;
					portraitLeft.animation.play('enter');
				}
			case 'bf':
				swagDialogue.sounds = [FlxG.sound.load(Paths.sound('bfText'), 0.6)];
				swagDialogue.color = FlxColor.fromRGB(80, 165, 235);
				portraitLeft.visible = false;
				if (!portraitRight.visible)
				{
					portraitRight.frames = Paths.getSparrowAtlas('portraits', 'shared');
					portraitRight.animation.addByPrefix('enter', 'bf portrait', 24, false);
					portraitRight.setGraphicSize(Std.int(portraitRight.width * 1 * 0.75));
					portraitRight.antialiasing = true;
					portraitRight.updateHitbox();
					portraitRight.scrollFactor.set();
					// portraitRight.screenCenter(X);

					portraitRight.x = (box.x + box.width) - (portraitRight.width) - 60;
					portraitRight.y = box.y - 168;

					portraitRight.visible = true;
					portraitRight.animation.play('enter');
				}
			case 'dad':
				swagDialogue.sounds = [FlxG.sound.load(Paths.sound('dadText'), 0.6)];
				swagDialogue.color = FlxColor.fromRGB(211, 150, 252);
				portraitRight.visible = false;
				if (!portraitLeft.visible)
				{
					portraitLeft.frames = Paths.getSparrowAtlas('portraits', 'shared');
					portraitLeft.animation.addByPrefix('enter', 'dad portrait', 24, false);
					portraitLeft.setGraphicSize(Std.int(portraitLeft.width * 1 * 0.65));
					portraitLeft.antialiasing = true;
					portraitLeft.updateHitbox();
					portraitLeft.scrollFactor.set();
					// portraitLeft.screenCenter(X);

					portraitLeft.x = box.x + 64;
					portraitLeft.y = box.y - 248;

					portraitLeft.visible = true;
					portraitLeft.animation.play('enter');
				}
			case 'spooky':
				swagDialogue.sounds = [FlxG.sound.load(Paths.sound('spookyText'), 0.6)];
				swagDialogue.color = FlxColor.fromRGB(82, 30, 104);
				portraitRight.visible = false;
				if (!portraitLeft.visible)
				{
					portraitLeft.frames = Paths.getSparrowAtlas('portraits', 'shared');
					portraitLeft.animation.addByPrefix('enter', 'spooky portrait', 24, false);
					portraitLeft.setGraphicSize(Std.int(portraitLeft.width * 1 * 0.75));
					portraitLeft.antialiasing = true;
					portraitLeft.updateHitbox();
					portraitLeft.scrollFactor.set();
					// portraitLeft.screenCenter(X);

					portraitLeft.x = box.x + 64;
					portraitLeft.y = box.y - 320;

					portraitLeft.visible = true;
					portraitLeft.animation.play('enter');
				}
			case 'spooky-skid':
				swagDialogue.sounds = [FlxG.sound.load(Paths.sound('spookyText'), 0.6)];
				swagDialogue.color = FlxColor.fromRGB(82, 30, 104);
				portraitRight.visible = false;
				if (!portraitLeft.visible)
				{
					portraitLeft.frames = Paths.getSparrowAtlas('portraits', 'shared');
					portraitLeft.animation.addByPrefix('enter', 'spooky-skid portrait', 24, false);
					portraitLeft.setGraphicSize(Std.int(portraitLeft.width * 1 * 0.75));
					portraitLeft.antialiasing = true;
					portraitLeft.updateHitbox();
					portraitLeft.scrollFactor.set();
					// portraitLeft.screenCenter(X);

					portraitLeft.x = box.x + 64;
					portraitLeft.y = box.y - 320;

					portraitLeft.visible = true;
					portraitLeft.animation.play('enter');
				}
			case 'spooky-pump':
				swagDialogue.sounds = [FlxG.sound.load(Paths.sound('spookyText'), 0.6)];
				swagDialogue.color = FlxColor.fromRGB(199, 70, 63);
				portraitRight.visible = false;
				if (!portraitLeft.visible)
				{
					portraitLeft.frames = Paths.getSparrowAtlas('portraits', 'shared');
					portraitLeft.animation.addByPrefix('enter', 'spooky-pump portrait', 24, false);
					portraitLeft.setGraphicSize(Std.int(portraitLeft.width * 1 * 0.75));
					portraitLeft.antialiasing = true;
					portraitLeft.updateHitbox();
					portraitLeft.scrollFactor.set();
					// portraitLeft.screenCenter(X);

					portraitLeft.x = box.x + 64;
					portraitLeft.y = box.y - 320;

					portraitLeft.visible = true;
					portraitLeft.animation.play('enter');
				}
			case 'monster':
				swagDialogue.sounds = [FlxG.sound.load(Paths.sound('monsterText'), 0.6)];
				swagDialogue.color = FlxColor.fromRGB(240, 218, 108);
				portraitRight.visible = false;
				if (!portraitLeft.visible)
				{
					portraitLeft.frames = Paths.getSparrowAtlas('portraits', 'shared');
					portraitLeft.animation.addByPrefix('enter', 'monster portrait', 24, false);
					portraitLeft.setGraphicSize(Std.int(portraitLeft.width * 1 * 0.75));
					portraitLeft.antialiasing = true;
					portraitLeft.updateHitbox();
					portraitLeft.scrollFactor.set();
					// portraitLeft.screenCenter(X);

					portraitLeft.x = box.x + 64;
					portraitLeft.y = box.y - 192;

					portraitLeft.visible = true;
					portraitLeft.animation.play('enter');
				}
			case 'pico':
				swagDialogue.sounds = [FlxG.sound.load(Paths.sound('picoText'), 0.6)];
				swagDialogue.color = FlxColor.fromRGB(36, 166, 91);
				portraitRight.visible = false;
				if (!portraitLeft.visible)
				{
					portraitLeft.frames = Paths.getSparrowAtlas('portraits', 'shared');
					portraitLeft.animation.addByPrefix('enter', 'pico portrait', 24, false);
					portraitLeft.setGraphicSize(Std.int(portraitLeft.width * 1 * 0.75));
					portraitLeft.antialiasing = true;
					portraitLeft.updateHitbox();
					portraitLeft.scrollFactor.set();
					// portraitLeft.screenCenter(X);

					portraitLeft.x = box.x + 64;
					portraitLeft.y = box.y - 192;

					portraitLeft.visible = true;
					portraitLeft.animation.play('enter');
				}
			case 'mom':
				swagDialogue.sounds = [FlxG.sound.load(Paths.sound('momText'), 0.6)];
				swagDialogue.color = FlxColor.fromRGB(211, 150, 252);
				portraitRight.visible = false;
				if (!portraitLeft.visible)
				{
					portraitLeft.frames = Paths.getSparrowAtlas('portraits', 'shared');
					portraitLeft.animation.addByPrefix('enter', 'mom portrait', 24, false);
					portraitLeft.setGraphicSize(Std.int(portraitLeft.width * 1 * 0.75));
					portraitLeft.antialiasing = true;
					portraitLeft.updateHitbox();
					portraitLeft.scrollFactor.set();
					// portraitLeft.screenCenter(X);

					portraitLeft.x = box.x + 64;
					portraitLeft.y = box.y - 264;

					portraitLeft.visible = true;
					portraitLeft.animation.play('enter');
				}
			case 'parents':
				swagDialogue.sounds = [FlxG.sound.load(Paths.sound('parentsText'), 0.6)];
				swagDialogue.color = FlxColor.fromRGB(211, 150, 252);
				portraitRight.visible = false;
				if (!portraitLeft.visible)
				{
					portraitLeft.frames = Paths.getSparrowAtlas('portraits', 'shared');
					portraitLeft.animation.addByPrefix('enter', 'parents portrait', 24, false);
					portraitLeft.setGraphicSize(Std.int(portraitLeft.width * 1 * 0.75));
					portraitLeft.antialiasing = true;
					portraitLeft.updateHitbox();
					portraitLeft.scrollFactor.set();
					// portraitLeft.screenCenter(X);

					portraitLeft.x = box.x + 64;
					portraitLeft.y = box.y - 176;

					portraitLeft.visible = true;
					portraitLeft.animation.play('enter');
				}
			case 'parents-dad':
				swagDialogue.sounds = [FlxG.sound.load(Paths.sound('dadText'), 0.6)];
				swagDialogue.color = FlxColor.fromRGB(211, 150, 252);
				portraitRight.visible = false;
				if (!portraitLeft.visible)
				{
					portraitLeft.frames = Paths.getSparrowAtlas('portraits', 'shared');
					portraitLeft.animation.addByPrefix('enter', 'parents-dad portrait', 24, false);
					portraitLeft.setGraphicSize(Std.int(portraitLeft.width * 1 * 0.75));
					portraitLeft.antialiasing = true;
					portraitLeft.updateHitbox();
					portraitLeft.scrollFactor.set();
					// portraitLeft.screenCenter(X);

					portraitLeft.x = box.x + 64;
					portraitLeft.y = box.y - 176;

					portraitLeft.visible = true;
					portraitLeft.animation.play('enter');
				}
			case 'parents-mom':
				swagDialogue.sounds = [FlxG.sound.load(Paths.sound('momText'), 0.6)];
				swagDialogue.color = FlxColor.fromRGB(211, 150, 252);
				portraitRight.visible = false;
				if (!portraitLeft.visible)
				{
					portraitLeft.frames = Paths.getSparrowAtlas('portraits', 'shared');
					portraitLeft.animation.addByPrefix('enter', 'parents-mom portrait', 24, false);
					portraitLeft.setGraphicSize(Std.int(portraitLeft.width * 1 * 0.75));
					portraitLeft.antialiasing = true;
					portraitLeft.updateHitbox();
					portraitLeft.scrollFactor.set();
					// portraitLeft.screenCenter(X);

					portraitLeft.x = box.x + 64;
					portraitLeft.y = box.y - 176;

					portraitLeft.visible = true;
					portraitLeft.animation.play('enter');
				}
			case 'senpai':
				portraitRight.visible = false;
				if (!portraitLeft.visible)
				{
					portraitLeft.frames = Paths.getSparrowAtlas('weeb/senpaiPortrait');
					portraitLeft.animation.addByPrefix('enter', 'Senpai Portrait Enter', 24, false);
					portraitLeft.setGraphicSize(Std.int(portraitLeft.width * PlayState.daPixelZoom * 0.9));
					portraitLeft.updateHitbox();
					portraitLeft.scrollFactor.set();
					portraitLeft.screenCenter(X);

					portraitLeft.visible = true;
					portraitLeft.animation.play('enter');
				}
			case 'bf-pixel':
				portraitLeft.visible = false;
				if (!portraitRight.visible)
				{
					portraitRight.frames = Paths.getSparrowAtlas('weeb/bfPixelPortrait');
					portraitRight.animation.addByPrefix('enter', 'Boyfriend portrait enter', 24, false);
					portraitRight.setGraphicSize(Std.int(portraitRight.width * PlayState.daPixelZoom * 0.9));
					portraitRight.updateHitbox();
					portraitRight.scrollFactor.set();

					portraitRight.visible = true;
					portraitRight.animation.play('enter');
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
