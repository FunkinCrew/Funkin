package;

import flixel.tweens.FlxTween;
import flixel.system.FlxSound;
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

	var dialogueBGShit:FlxSprite;

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
	var screenJustTouched:Bool = false;

	function isWeekSix():Bool {
		var song = PlayState.CURRENT_SONG;
		return song == 'roses' || song == 'senpai' || song == 'thorns';
	}


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
			// default:
				// FlxG.sound.playMusic(Paths.music('Lunchbox'), 0);
				// FlxG.sound.music.fadeIn(1, 0, 0.8);
	
		}

		var song = PlayState.CURRENT_SONG;


		bgFade = new FlxSprite(-200, -200).makeGraphic(Std.int(FlxG.width * 1.3), Std.int(FlxG.height * 1.3), FlxColor.BLACK);
		// bgFade.alpha = 0.25;
		bgFade.scrollFactor.set();
		bgFade.alpha = 0;
		add(bgFade);
	

		dialogueBGShit = new FlxSprite(0, 0).loadGraphic(Paths.image('cutscenes/1'));
		// dialogueBGShit.setSize(FlxG.width * 1, FlxG.height * 1);
		// dialogueBGShit.scrollFactor.set(1, 1);
		// dialogueBGShit.alpha = 0;

		dialogueBGShit.setGraphicSize(Std.int(dialogueBGShit.width * 1.25));
		dialogueBGShit.scrollFactor.set();
		dialogueBGShit.updateHitbox();
		dialogueBGShit.screenCenter();
		dialogueBGShit.x = -100;
		dialogueBGShit.y = 0;
		dialogueBGShit.alpha = 0;
		add(dialogueBGShit);


		FlxTween.tween(bgFade, {alpha: 0.7}, 0.5, null);
		// bgFade.
		// new FlxTimer().start(0.5, function(tmr:FlxTimer)
		// {
		// 	bgFade.alpha += (1 / 60) * 0.7;
		// 	if (bgFade.alpha > 0.7)
		// 		bgFade.alpha = 0.7;
		// }, 60);

		box = new FlxSprite(-20, 45);
		
		var hasDialog = false;
		switch (PlayState.SONG.song.toLowerCase())
		{
		
			case 'senpai':
				hasDialog = true;
				box.frames = Paths.getSparrowAtlas('weeb/pixelUI/dialogueBox-pixel');
				box.animation.addByPrefix('normalOpen', 'Text Box Appear', 24, false);
				box.animation.addByIndices('normal', 'Text Box Appear', [4], "", 24);
			case 'roses':
				hasDialog = true;
				FlxG.sound.play(Paths.sound('ANGRY_TEXT_BOX'));

				box.frames = Paths.getSparrowAtlas('weeb/pixelUI/dialogueBox-senpaiMad');
				box.animation.addByPrefix('normalOpen', 'SENPAI ANGRY IMPACT SPEECH', 24, false);
				box.animation.addByIndices('normal', 'SENPAI ANGRY IMPACT SPEECH', [4], "", 24);

			case 'thorns':
				hasDialog = true;
				box.frames = Paths.getSparrowAtlas('weeb/pixelUI/dialogueBox-evil');
				box.animation.addByPrefix('normalOpen', 'Spirit Textbox spawn', 24, false);
				box.animation.addByIndices('normal', 'Spirit Textbox spawn', [11], "", 24);
				var face:FlxSprite = new FlxSprite(320, 170).loadGraphic(Paths.image('weeb/spiritFaceForward'));
				face.setGraphicSize(Std.int(face.width * 6));
				add(face);

			default:
				hasDialog = true;
				box.frames = Paths.getSparrowAtlas('speech_bubble_talking', 'shared');
				box.animation.addByPrefix('normalOpen', 'Speech Bubble Normal Open', 24, false);
				box.animation.addByIndices('normal', 'speech bubble normal', [4], "", 24);
				box.width = 200;
				box.height = 100;
				box.x = -100;	 
				box.y = 375;
				box.flipX = true;

		}

		this.dialogueList = dialogueList;
		
		if (!hasDialog)
			return;

		// PlayState.dad.scale.y = 0;
		// PlayState.instance.focusOnEnemy();
		var s = PlayState.CURRENT_SONG;

		if(isWeekSix())
		{
			//KUDORADO//DISABLE//DISABLEtraceget gfffff shit!');
			portraitLeft = new FlxSprite(-20, 40);
			var path = song == 'thorns' ? 'portraits/emptyPortrait' : 'weeb/senpaiPortrait';

			portraitLeft.frames = Paths.getSparrowAtlas(path);
			portraitLeft.animation.addByPrefix('enter', 'Senpai Portrait Enter', 24, false);
			portraitLeft.setGraphicSize(Std.int(portraitLeft.width * PlayState.daPixelZoom * 0.9));
			portraitLeft.updateHitbox();
			portraitLeft.scrollFactor.set();
			add(portraitLeft);
			portraitLeft.visible = false;

		}

		else
		{
			//KUDORADO//DISABLE//DISABLEtraceget gf shit!');
			var char = PlayState.SONG.player2.toLowerCase();
			curCharacter = char;
			showDialogue(false);
			
			// addLeftChar(getCharPortrait(char));
		}

		if(isWeekSix())
		{

			portraitRight = new FlxSprite(0, 40);
			portraitRight.frames = Paths.getSparrowAtlas('weeb/bfPortrait');
			portraitRight.animation.addByPrefix('enter', 'Boyfriend portrait enter', 24, false);
			portraitRight.setGraphicSize(Std.int(portraitRight.width * PlayState.daPixelZoom * 0.9));
			portraitRight.updateHitbox();
			portraitRight.scrollFactor.set();
			add(portraitRight);
			portraitRight.visible = false;


			handSelect = new FlxSprite(FlxG.width * 0.9, FlxG.height * 0.9).loadGraphic(Paths.image('weeb/pixelUI/hand_textbox'));
			add(handSelect);

		
		}
		else
		{
			//KUDORADO//DISABLE//DISABLEtraceget gf shit!1');
			addRightChar('boyfriend');
		
		}
		
		box.animation.play('normalOpen');
		box.setGraphicSize(Std.int(box.width * PlayState.daPixelZoom * 0.9));
		box.updateHitbox();
		add(box);



		box.screenCenter(X);
		// portraitLeft.screenCenter(X);
		// portraitLeft.x -= 100;

		if (!talkingRight)
		{
			// box.flipX = true;
		}

		dropText = new FlxText(235, 487, Std.int(FlxG.width * 0.6), "", 32);
		// dropText.setFormat()'Pixel Arial 11 Bold';
		// text.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, RIGHT);

		dropText.color = 0xFFD89494;
		dropText.screenCenter(X);
		dropText.x += 50;

		swagDialogue = new FlxTypeText(233, 485, Std.int(FlxG.width * 0.6), "", 32);
		// swagDialogue.font = 'Pixel Arial 11 Bold';
		swagDialogue.color = 0xFF3F2021;
		swagDialogue.sounds = [FlxG.sound.load(Paths.sound('pixelText'), 0.6)];
		swagDialogue.screenCenter(X);

		swagDialogue.x += 50;

		if (isWeekSix())
		{
			dropText.setFormat(Paths.font("pixel.otf"), 32);
			swagDialogue.setFormat(Paths.font("pixel.otf"), 32);
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
			// FlxTween.tween(PlayState.dad, {alpha: 0}, 0.15, null);
			startDialogue();
			dialogueStarted = true;
		}


		for (touch in FlxG.touches.list)
			{
				screenJustTouched = false;
				
				if (touch.justReleased){
					screenJustTouched = true;
				}
			}
			
			
		if (screenJustTouched || FlxG.keys.justPressed.ANY  && dialogueStarted == true)
		{
			nextDialogueShit();
		}
		
		super.update(elapsed);
	}

	var isEnding:Bool = false;

	function getCharPortrait(char:String):String
	{
		switch (char)
		{
			case 'gf':
			return 'gf';

			case 'dad' | 'dearest': 
				return 'dad';

			case 'spookeez':
				return 'skid';

			case 'pico':
				return 'pico';
			
			case 'philly' | 'blammed':
				return 'picoAngry';
			
			case 'mom' | 'mom-car':
				return 'mom';

			case 'monster' | 'monster-christmas':
				return 'christmasLemon';

			case 'parents-christmas':
				return 'parents';
			
			case 'garcello' | 'garcellotired' | 'garcellodead' | 'garcelloghosty':
				return 'gar';

			case 'hex' | 'hex-virus':
				return 'hex';

			case 'sarvente' | 'parish' | 'sarvente-dark' |'luci-sarv' |
				 'worship' | 'zavodila' | 'ruv' | 
				 'selever' | 'casanova':
				 return 'mfm';

			case 'tricky' | 'trickymask':
				return 'tricky';

			case 'whitty' | 'whitty-overhead' | 'ballistic':
				return 'whitty';

			default:
				return 'empty';
		}

		// return 
	}

	function addLeftChar(
		char:String, x:
		Float = 100, y:Float = 360, 
		defaultAnimation:String = 'Portrait Enter instance')
	{

		if(portraitLeft != null)
		remove(portraitLeft);


		var path = 'portraits/' + char + 'Portrait';
		//KUDORADO//DISABLE//DISABLEtraceadd left char shit: ' + path);
		//KUDORADO//DISABLE//DISABLEtraceleft char animation shit: ' + defaultAnimation);
		portraitLeft = new FlxSprite(-1600, 10);
		portraitLeft.frames = Paths.getSparrowAtlas(path);
		portraitLeft.animation.addByPrefix('enter', defaultAnimation, 24, false);
		portraitLeft.setGraphicSize(Std.int(portraitLeft.width * PlayState.daPixelZoom * 0.175));
		portraitLeft.updateHitbox();
		portraitLeft.scrollFactor.set();
		add(portraitLeft);
		portraitLeft.visible = false;

		portraitLeft.x = box.x - x;
		portraitLeft.y = box.y - y;

		// portraitLeft.screenCenter(X);
		// portraitLeft.x -= 100;
	}

	function nextDialogueShit() 
	{
			remove(dialogue);
			FlxG.sound.play(Paths.sound('clickText'), 0.8);
			if (dialogueList[1] == null && dialogueList[0] != null)
			{
				if (!isEnding)
				{
					isEnding = true;

					// PlayState.instance.setIconShitActive(true);

					// if (PlayState.SONG.song.toLowerCase() == 'senpai' 
					// 	|| PlayState.SONG.song.toLowerCase()  == 'tutorial'
					// 	|| PlayState.SONG.song.toLowerCase() == 'thorns')
						FlxG.sound.music.fadeOut(2.2, 0);



					// FlxTween.tween(PlayState.dad, {scale.x: 1}, 0.5, null);
					// FlxTween.tween(PlayState.dad(), {alpha: 1}, 1, null);


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
						FlxG.sound.music.stop();
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
	function addRightChar(char:String,  x:Float = 0, y:Float = 0, defaultAnim = 'Portrait Enter instance'){
		if(portraitRight != null)
			remove(portraitRight);

		//KUDORADO//DISABLE//DISABLEtraceadd right char shit: ' + char);

		portraitRight = new FlxSprite(0, 40);
		portraitRight.frames = Paths.getSparrowAtlas('portraits/' + char + 'Portrait');
		portraitRight.animation.addByPrefix('enter', defaultAnim, 24, false);
		portraitRight.setGraphicSize(Std.int(portraitRight.width * PlayState.daPixelZoom * 0.15));
		portraitRight.updateHitbox();
		portraitRight.scrollFactor.set();
		add(portraitRight);
		portraitRight.visible = false;
		portraitRight.x += x;
		portraitRight.y -= y;
	}

	function startDialogue():Void
	{
		cleanDialog();
		// var theDialog:Alphabet = new Alphabet(0, 70, dialogueList[0], false, true);
		// dialogue = theDialog;
		// add(theDialog);

		// swagDialogue.text = ;
		swagDialogue.resetText(dialogueList[0]);
		swagDialogue.start(0.04, true);
		// portraitLeft.flipX = false;{

		if(isWeekSix())
		{
			showDialogueWeekSix();
		}
		else
		showDialogue();
		
	}

	function showDialogueWeekSix()
	{
		swagDialogue.resetText(dialogueList[0]);
		swagDialogue.start(0.04, true);

		switch (curCharacter)
		{
			case 'dad':
				portraitRight.visible = false;
				if (!portraitLeft.visible)
				{
					portraitLeft.visible = true;
					portraitLeft.animation.play('enter');
				}
			case 'bf':
				portraitLeft.visible = false;
				if (!portraitRight.visible)
				{
					portraitRight.visible = true;
					portraitRight.animation.play('enter');
				}
		}
	}

	function showDialogue(show:Bool = true)
	{
		var song = PlayState.CURRENT_SONG;

		//KUDORADO//DISABLE//DISABLEtracedialogue cur Char:'  + curCharacter);
		var ctc = curCharacter.toLowerCase();

		if (song == 'senpai' || song ==  'roses' || song == 'thorns')
		{

			if(show && (ctc == "bf" || ctc == 'boyfriend'))
			{
				showLeftDialog();
				return;
			}
			// if(ctc != 'bf' && ctc != 'boyfriend')
				// curCharacter = 'shitttttttttttttt';
		}

		var isLeftDialogue = false;
		
		switch (ctc)
		{

			case 'bf' | 'boyfriend':
				addRightChar('boyfriend');
				isLeftDialogue = false;

			case 'myst':
				addLeftChar('hex', 350);
				isLeftDialogue = true;

			case 'gf':
				if (song == 'tutorial' || song == 'tutorial-remix' || song == 'tutorial-bsides')
				{
					addLeftChar('gf', 350);
					isLeftDialogue = true;
				}

				if(song == 'parish')
				{
					addRightChar('gfCheer', 0, 0);
					isLeftDialogue = false;
				}

				if(song == 'casanova') 
				{
					addLeftChar('gf', 350);
					isLeftDialogue = true;
				}
				if (song == 'dunk' || song == 'encore')
				{
					addLeftChar('gf', 350);
					isLeftDialogue = true;
				}

				if(song == 'expurgation') 
				{
					addRightChar('gfCheer', 0, 0);
					isLeftDialogue = false;
				}

			if(song == 'my-battle' || song == 'last-chance' || song == 'genocide')
			{
				addLeftChar('gf', 350);
				isLeftDialogue = true;
			}


			case 'christmaslemon':
				addLeftChar('christmasLemon', 385);
				isLeftDialogue = true;

			case 'gf-cheer':
				if(PlayState.CURRENT_SONG == 'pico-bsides')
				{
					addRightChar('gfCheer', 0, 0);
					isLeftDialogue = false;
				}
				if(song == 'encore')
				{
					addRightChar('gfCheer', 50, 50);
					isLeftDialogue = false;
				}

			case 'pico':
				addLeftChar('pico', 275);
				isLeftDialogue = true;
			case 'pico-angry':
				addLeftChar('picoAngry', 275);
				isLeftDialogue = true;


			case 'mom' | 'mom-car':
				addLeftChar('mom', 425);
				isLeftDialogue = true;

			case 'parentsdad':
				addLeftChar('parentsDad', 210);
				isLeftDialogue = true;

			case 'parentsmom':
				addLeftChar('parentsMom', 210);
				// portraitLeft.flipX = true;
				isLeftDialogue = true;
			
			case 'parents':
				addLeftChar('parents', 210);
				isLeftDialogue = true;

			case 'skid': 
				addLeftChar(curCharacter, 285, 390);
				isLeftDialogue = true;

			case 'pump':
				addLeftChar(curCharacter, 275, 390);
				isLeftDialogue = true;

			case 'sarvente-happy':
				addLeftChar('mfm', 0, 213, 'SarvHappy0');
				isLeftDialogue = true;

			case 'sarvente-sad':
				addLeftChar('mfm', 0, 213, 'SarvSad0');
				isLeftDialogue = true;
			
			case 'sarvente-smile':
				addLeftChar('mfm', 0, 213, 'SarvSmile0');
				isLeftDialogue = true;

			case 'sarvente-upset':
				addLeftChar('mfm', 0, 203, 'SarvUpset0');
				isLeftDialogue = true;

			case 'sarvente-angry':
				addLeftChar('mfm', 0, 203, 'SarvUpset0');
				isLeftDialogue = true;
			
			case 'sarvente-devil':
				addLeftChar('mfm', 25, 250, 'SarvDevil0');
				isLeftDialogue = true;

			case 'ruv':
				addLeftChar('mfm', 35, 203, 'RuvNormal0');
				isLeftDialogue = true;
		
			case 'ruv-angry':
				addLeftChar('mfm', 35, 203, 'RuvAngery0');
				isLeftDialogue = true;

			case 'ruv-bruh':
				addLeftChar('mfm', 35, 203, 'RuvBruh0');
				isLeftDialogue = true;

			case 'selever-happy' | 'selever':
				addLeftChar('mfm', -25, 240, 'SelHappy');
				isLeftDialogue = true;
			
			case 'selever-smile':
				addLeftChar('mfm', -25, 240, 'SelSmile0');
				isLeftDialogue = true;

			case 'selever-upset':
				addLeftChar('mfm', -25, 240, 'SelUpset0');
				isLeftDialogue = true;
	
			case 'selever-xd':
				addLeftChar('mfm', -25, 240, 'SelXD0');
				isLeftDialogue = true;

			case 'selever-angry':
				addLeftChar('mfm', -25, 240, 'SelAngery0');
				isLeftDialogue = true;

			case 'ras':
				addLeftChar('mfm', 0, 215, 'RasNormal0');
				isLeftDialogue = true;

			case 'ras-bruh':
				addLeftChar('mfm', 0, 215, 'RasBruh0');
				isLeftDialogue = true;

			case 'whitty':
				addLeftChar('whitty', 0, 215, 'Whitty Portrait Normal instance 1');
				isLeftDialogue = true;
			
			case 'whitty-crazy':
				addLeftChar('whitty', 0, 215, 'Whitty Portrait Agitated instance 1');
				isLeftDialogue = true;

			case 'ballistic':
				addLeftChar('whitty', -30, 220, 'Whitty Portrait Crazy instance');
				isLeftDialogue = true;

			case 'hex':
				if(song == 'encore' || song == 'dunk')
					addLeftChar('hex', 50, 235, 'default');
				
				if(song == 'ram')
					addLeftChar('hex', 50, 235, 'sunset');
				
				if(song == 'hello-world')
					addLeftChar('hex', 50, 235, 'night');
				
				if(song == 'glitcher')
					addLeftChar('hex', 50, 235, 'glitcher');

				isLeftDialogue = true;

			case 'hex-virus':
				addLeftChar('hex', 50, 235, 'virus');
				isLeftDialogue = true;

			case 'tricky':
				addLeftChar('tricky', 50, 235, 'Mad');
				isLeftDialogue = true;

			case 'tricky-mask':
				addLeftChar('tricky', 50, 235, 'Normal');
				isLeftDialogue = true;

			case 'dearest':
				addLeftChar('dad', 325, 335);
				isLeftDialogue = true;

			case 'tabi':
				addLeftChar('tabi', -25, 350, 'tabi');
				isLeftDialogue = true;

			case 'tabi-mad':
				addLeftChar('tabi', -25, 350, 'tabiMad');
				isLeftDialogue = true;

			case 'tabi-worried':
				addLeftChar('tabi', -25, 350, 'tabiWorried');
				isLeftDialogue = true;

			case 'gf-talking':
				addRightChar('tabi', 700, -100, 'gfTalking');
				isLeftDialogue = false;

			case 'gf-letsgo':
				addRightChar('tabi', 700, -100, 'gfLetsgo');
				isLeftDialogue = false;

			case 'gf-hmm':
				addRightChar('tabi', 700, -100, 'gfHmm');
				isLeftDialogue = false;

			case 'bf-exp':
				addRightChar('tabi', 700, -100, 'bfExp');
				isLeftDialogue = false;

			case 'bf-right':
				addRightChar('tabi', 700, -100, 'bfRight');
				isLeftDialogue = false;

			case 'bf-left':
				addLeftChar('tabi', 50, 250, 'bfLeft');
				isLeftDialogue = true;

	


			case 'agoti' | 'agoti-crazy' | 'agoti-scared':
				{
					switch (PlayState.CURRENT_SONG)
					{
						case 'screenplay':
							addLeftChar('agoti', -40, 300, 'Agoti_Dialogue_A');
							isLeftDialogue = true;
	
						case 'parasite':
							addLeftChar('agoti', -40, 300, 'Agoti_Dialogue_B');
							isLeftDialogue = true;

						default:
							addLeftChar('agoti', -40, 300, 'Agoti_Dialogue_C');
							isLeftDialogue = true;
		

					}
				}

			case 'dad':
				switch (PlayState.CURRENT_SONG)
				{
					case 'headache':
						addLeftChar('gar', 50, 235, 'gar Default instance');
						isLeftDialogue = true;

					case 'nerves':
						addLeftChar('gar', 50, 225, 'gar Nervous Enter instance');
						isLeftDialogue = true;

					case 'release':
						addLeftChar('gar', 60, 225, 'gar Ghost Enter instance');
						isLeftDialogue = true;

					case 'fading':
						addLeftChar('gar', 60, 225, 'gar Dippy Enter instance');
						isLeftDialogue = true;

					default:
						addLeftChar(curCharacter, 325, 335);
						isLeftDialogue = true;
					}
	
				

			default:
				if(portraitLeft == null)
				addLeftChar('empty');	

				isLeftDialogue = true;
		}

		if (show)
		{
			if(isLeftDialogue)
				showLeftDialog();
			else
				showRightDialog();
		}
		



	}

	function showLeftDialog()
	{
		box.flipX = true;

		if(portraitRight != null)
		portraitRight.visible = false;

		if (PlayState.CURRENT_SONG == 'thorns')
		{
			portraitLeft.visible = false;
			return;
		}

		if (!portraitLeft.visible)
		{
			portraitLeft.visible = true;
			portraitLeft.animation.play('enter');
		}
	}
	function showRightDialog()
	{
		box.flipX = false;

		if(portraitLeft != null)
		portraitLeft.visible = false;
		if (!portraitRight.visible)
		{
			portraitRight.visible = true;
			portraitRight.animation.play('enter');
		}
	}

	function cleanDialog():Void
	{
		var splitName:Array<String> = dialogueList[0].split(":");

		//DISABLEtrace("split 0: " + splitName[0]);
		//DISABLEtrace("split 1: " + splitName[1]);

		curCharacter = splitName[1];

		dialogueList[0] = dialogueList[0].substr(splitName[1].length + 2).trim();
		//KUDORADO//DISABLE//DISABLEtracebg shit: ' + curCharacter.toLowerCase());

		switch (curCharacter.toLowerCase())
		{
			case 'bgchange':
				dialogueBGShit.graphic = null;
				dialogueBGShit.loadGraphic(Paths.image(dialogueList[0]));
				dialogueBGShit.alpha = 1;
				nextDialogueShit();

			case 'playsound':
				// var e = new FlxSound().loadEmbedded(Paths.music('bzzt'), false, true);
				// e.play();
				nextDialogueShit();

			case 'bgtrack':
				// FlxG.sound.playMusic(Paths.music('hectic'), 1);
				nextDialogueShit();

		}
	}
}
