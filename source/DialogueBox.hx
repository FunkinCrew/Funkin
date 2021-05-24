package;

import flixel.math.FlxMath;
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
import flash.display.BitmapData;
import lime.utils.Assets;
import flixel.graphics.frames.FlxFrame;
import lime.system.System;
import flixel.system.FlxAssets.FlxSoundAsset;
#if sys
import sys.FileSystem;
import haxe.io.Path;
import openfl.utils.ByteArray;
import lime.media.AudioBuffer;
import flash.media.Sound;
#end
import haxe.Json;
import haxe.format.JsonParser;
import tjson.TJSON;
using StringTools;

typedef Dialogue =
{
	var addY:Int;
	var canFlip:Bool;
}
class DialogueBox extends FlxSpriteGroup
{
	public static var _dialogue:Dialogue;
	var box:FlxSprite;

	var camLerp:Float = 0.14;

	// there's going to be a ton of these for making the system robust
	var bgALPHA:Int;
	var bgRED:Int;
	var bgGREEN:Int;
	var bgBLUE:Int;
	var curMusic:String = '';
	var charScale:Float;
	var dialogueColor:Null<FlxColor>;
	var shadowColor:Null<FlxColor> = FlxColor.WHITE;
	var portraitColor:Null<FlxColor> = FlxColor.BLACK;
	var fadeInTime:Float;
	var fadeInLoop:Int;
	var fadeOutTime:Float;
	var fadeOutLoop:Int;
	var bgFIT:Float;
	var bgFIL:Int;
	var handSprite:String = '#FFFFFFFF';
	var clickSound:String = '#FF000000';

	var curCharacter:String = '';
	var oldCharacter:String = '';
	var curVolume:Int = 100;
	var curEmotion:String = '';
	var curShake:Float = 0;
	var curShakeTime:Int = 0;
	var curShakeDelay:Int = 0;
	var curFlashTime:Int = 0;
	var curFlashDelay:Int = 0;
	var curSpeed:Float = 0.04;
	var curFlip:Bool = false;
	var curFont:String = 'Pixel Arial 11 Bold';
	var curFontScale:Int = 32;
	var curBox:String = 'pixel_normal';
	var oldBox:String = '';
	var curSound:String = 'pixelText';
	var timeCut:Int;

	var dialogue:Alphabet;
	var dialogueFile:FileParser.AdvancedDialogFile;
	// SECOND DIALOGUE FOR THE PIXEL SHIT INSTEAD???
	var swagDialogue:FlxTypeText;

	var dropText:FlxText;

	public var finishThing:Void->Void;

	var portrait:FlxSprite;

	var handSelect:FlxSprite;
	var bgFade:FlxSprite;
	public function new(talkingRight:Bool = true, ?dialogueList:Array<String>)
	{	
		super();
		if (dialogueList[0] == ':dad: The game tried to get a dialog file but couldn\'t find it. Please make sure there is a dialog file named "dialog.txt".')
			return;
		_dialogue = {
			addY: 0,
			canFlip: true,
		};
		var fileContent = "";
		for (dialogText in dialogueList)
		{
			fileContent += dialogText;
			fileContent += '\n';
		}
		fileContent = fileContent.trim();
		trace(dialogueFile = FileParser.parseAdvancedDialog(fileContent));

		setUp();
		
		FlxG.sound.playMusic('assets/images/custom_dialogs/dialogMusic/' + curMusic+'.ogg', 0);

		FlxG.sound.music.fadeIn(1, 0, 0.8 * curVolume / 100);

		bgFade = new FlxSprite(-200,
			-200).makeGraphic(Std.int(FlxG.width * 1.3), Std.int(FlxG.height * 1.3), FlxColor.fromRGB(bgRED, bgGREEN, bgBLUE, bgALPHA));
		bgFade.scrollFactor.set();
		bgFade.alpha = 0;
		add(bgFade);

		new FlxTimer().start(bgFIT, function(tmr:FlxTimer)
		{
			bgFade.alpha += (1 / bgFIL);
			if (bgFade.alpha > 1)
				bgFade.alpha = 1;
		}, bgFIL);

		switch (PlayState.SONG.song.toLowerCase())
		{
			case 'thorns':
				var face:FlxSprite = new FlxSprite(320, 170).loadGraphic('assets/images/weeb/spiritFaceForward.png');
				face.setGraphicSize(Std.int(face.width * 6));
				add(face);
		}

		portrait = new FlxSprite(-20, 40);
		portrait.frames = FlxAtlasFrames.fromSparrow('assets/images/custom_chars/$curCharacter/portrait.png',
			'assets/images/custom_chars/$curCharacter/portrait.xml');
		portrait.animation.addByPrefix('neutral', 'neutral', 24, false);
		portrait.setGraphicSize(Std.int(portrait.width * PlayState.daPixelZoom * 0.9));
		portrait.updateHitbox();
		portrait.scale.set(charScale, charScale);
		portrait.updateHitbox();
		portrait.scrollFactor.set();
		add(portrait);
		portrait.visible = false;

		box = new FlxSprite(-20, 45);
		box.frames = FlxAtlasFrames.fromSparrow('assets/images/custom_dialogs/dialogBoxes/$curBox.png',
			'assets/images/custom_dialogs/dialogBoxes/$curBox.xml');
		box.animation.addByPrefix('open', 'open', 24, false);
		box.animation.addByPrefix('normal', 'normal', 24, true);
		box.animation.play('open');
		box.setGraphicSize(Std.int(FlxG.width * 0.9));
		box.updateHitbox();
		add(box);

		if (_dialogue.canFlip)
			box.flipX = portrait.flipX;

		box.screenCenter(X);
		box.y = 710 - box.height;

		if (curBox != null)
		{
			var data:String = FNFAssets.getText('assets/images/custom_dialogs/dialogBoxes/' + curBox+ '.json');
			_dialogue = CoolUtil.parseJson(data);
		}

		box.y += _dialogue.addY;

		portrait.screenCenter(Y);

		handSelect = new FlxSprite(1240, 680).loadGraphic('assets/images/custom_dialogs/dialogHands/$handSprite.png');
		handSelect.setGraphicSize(Std.int(100));
		handSelect.updateHitbox();
		handSelect.x -= handSelect.width;
		handSelect.y -= handSelect.height;
		add(handSelect);

		dropText = new FlxText(242, 482, Std.int(FlxG.width * 0.6), "", curFontScale);
		dropText.font = curFont;
		dropText.color = shadowColor;
		add(dropText);

		swagDialogue = new FlxTypeText(240, 480, Std.int(FlxG.width * 0.6), "", curFontScale);
		swagDialogue.font = curFont;
		swagDialogue.color = dialogueColor;
		swagDialogue.sounds = [FlxG.sound.load('assets/images/custom_dialogs/$curSound.ogg', 0.6)];
		add(swagDialogue);

		dialogue = new Alphabet(0, 80, "", false, true);
		// dialogue.x = 90;
		// add(dialogue);
	}

	var dialogueOpened:Bool = false;
	var dialogueStarted:Bool = false;
	function setUp() {
		bgALPHA = dialogueFile.defines.backgroundColorA;
		bgRED = dialogueFile.defines.backgroundColorR;
		bgGREEN = dialogueFile.defines.backgroundColorG;
		bgBLUE = dialogueFile.defines.backgroundColorB;

		curMusic = dialogueFile.defines.musicName;
		curVolume = dialogueFile.defines.musicVolume;

		charScale = dialogueFile.defines.characterScale;
		curBox = dialogueFile.defines.dialogueBox;

		fadeInTime = dialogueFile.defines.fadeInTime;
		fadeInLoop = dialogueFile.defines.fadeInLoop;
		
		fadeOutTime = dialogueFile.defines.fadeOutTime;
		fadeOutLoop = dialogueFile.defines.fadeOutLoop;

		bgFIT = dialogueFile.defines.bgFIT;
		bgFIL = dialogueFile.defines.bfFIL;

		handSprite = dialogueFile.defines.textboxSprite;
		clickSound = dialogueFile.defines.acceptSound;
		curSound = dialogueFile.info[0].dialogueSound;
	}
	override function update(elapsed:Float)
	{
		if (dialogueStarted)
		{
			FlxG.sound.music.volume = FlxMath.lerp(FlxG.sound.music.volume, 0.8 * curVolume / 100,
				camLerp / 2);
			if (curFlip)
				portrait.x = FlxMath.lerp(portrait.x, 580 - portrait.width, (camLerp * 2) / 2);
			else
				portrait.x = FlxMath.lerp(portrait.x, 700, (camLerp * 2) / 2);
		}

		dropText.text = swagDialogue.text;

		if (box.animation.curAnim != null)
		{
			if (box.animation.curAnim.name == 'open' && box.animation.curAnim.finished)
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

		if (FlxG.keys.justPressed.ANY && dialogueStarted == true)
		{
			remove(dialogue);

			FlxG.sound.play('assets/images/custom_dialogs/dialogClicks/$clickSound.ogg', 0.8);

			if (dialogueFile.info[1] == null && dialogueFile.info[0] != null)
			{
				if (!isEnding)
				{
					isEnding = true;

					FlxG.sound.music.fadeOut(2.2, 0);

					new FlxTimer().start(fadeOutTime, function(tmr:FlxTimer)
					{
						box.alpha -= 1 / fadeOutLoop;
						bgFade.alpha -= 1 / fadeOutLoop * 0.7;
						portrait.visible = false;
						swagDialogue.alpha -= 1 / fadeOutLoop;
						handSelect.alpha -= 1 / fadeOutLoop;
						dropText.alpha = swagDialogue.alpha;
					}, fadeOutLoop);

					new FlxTimer().start(fadeOutTime * (fadeOutLoop + 1), function(tmr:FlxTimer)
					{
						finishThing();
						kill();
					});
				}
			}
			else
			{
				dialogueFile.info.remove(dialogueFile.info[0]);
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
		swagDialogue.resetText(dialogueFile.info[0].dialogue);

		new FlxTimer().start(curShakeDelay * curSpeed, function(tmr:FlxTimer)
		{
			FlxG.cameras.shake(curShake, curShakeTime * curSpeed);
		});

		new FlxTimer().start(curFlashDelay * curSpeed, function(tmr:FlxTimer)
		{
			FlxG.cameras.flash(0xFFFFFFFF, curFlashTime * curSpeed);
			if (curFlashTime > 0)
			{
				switch (PlayState.curStage)
				{
					case 'school' | 'schoolEvil':
						FlxG.sound.play('assets/sounds/shocker-pixel.ogg', 1);
					default:
						FlxG.sound.play('assets/sounds/shocker.ogg', 1);
				}
			}
		});

		portrait.frames = FlxAtlasFrames.fromSparrow('assets/images/custom_chars/$curCharacter/portrait.png',
			'assets/images/custom_chars/$curCharacter/portrait.xml');
		portrait.visible = true;

		if (portrait.width < 256)
		{
			portrait.setGraphicSize(Std.int(portrait.width * 6));
			portrait.antialiasing = false;
		}
		else
			portrait.antialiasing = true;

		portrait.updateHitbox();

		if (curFlip)
			portrait.flipX = true;
		else
			portrait.flipX = false;

		if (curCharacter != oldCharacter)
		{
			portrait.alpha = 0;

			new FlxTimer().start(fadeInTime, function(tmr:FlxTimer)
			{
				portrait.alpha += 1 / fadeInLoop;
			}, fadeInLoop);

			if (curFlip)
				portrait.x = 280 - portrait.width;
			else
				portrait.x = 1000;

			portrait.y = 441 - portrait.height;
		}

		if (curBox != oldBox)
		{
			remove(box);
			box = new FlxSprite(-20, 45);

			box.frames = FlxAtlasFrames.fromSparrow('assets/images/custom_dialogs/dialogBoxes/$curBox.png',
				'assets/images/custom_dialogs/dialogBoxes/$curBox.xml');
			box.animation.addByPrefix('open', 'open', 24, false);
			box.animation.addByPrefix('normal', 'normal', 24, true);

			dialogueOpened = false;
			box.animation.play('open');
			box.setGraphicSize(Std.int(FlxG.width * 0.9));
			box.updateHitbox();
			add(box);

			box.screenCenter(X);
			box.y = 710 - box.height;

			var data:String = FNFAssets.getText('assets/images/custom_dialogs/dialogBoxes/' + curBox+ '.json');
			_dialogue = Json.parse(data);

			box.y += _dialogue.addY;
		}

		if (_dialogue.canFlip)
			box.flipX = portrait.flipX;

		portrait.animation.addByPrefix(curEmotion, curEmotion, 24, false);
		portrait.animation.play(curEmotion);

		dropText.font = swagDialogue.font = curFont;
		dropText.size = swagDialogue.size = curFontScale;

		swagDialogue.sounds = [
			FlxG.sound.load('assets/images/custom_dialogs/dialogSounds/$curSound.ogg', 0.6)
		];

		dropText.color = shadowColor;
		swagDialogue.color = dialogueColor;

		if (portraitColor != null)
			portrait.color = portraitColor;

		if (timeCut > 0)
		{
			new FlxTimer().start(curSpeed * timeCut, function(tmr:FlxTimer)
			{
				dialogueFile.info.remove(dialogueFile.info[0]);
				FlxG.sound.play('assets/images/custom_dialogs/dialogClicks/$clickSound.ogg', 0.8);
				startDialogue();
			}, 1);
		}

		swagDialogue.start(curSpeed, true);
	}

	function cleanDialog():Void
	{
		oldCharacter  = curCharacter;
		curCharacter = dialogueFile.info[0].speaker;

		curEmotion = dialogueFile.info[0].emotion;
		curFont = dialogueFile.info[0].fontname;
		curFontScale = dialogueFile.info[0].fontscale;
		curVolume = dialogueFile.info[0].musicVolume;
		curShake = dialogueFile.info[0].shakeAmount;
		curShakeTime = dialogueFile.info[0].shakeDuration;
		curShakeDelay = dialogueFile.info[0].shakeDelay;
		curFlashTime = dialogueFile.info[0].flashDuration;
		curFlashDelay = dialogueFile.info[0].flashDelay;
		curSpeed = dialogueFile.info[0].writingSpeed;
		curFlip = dialogueFile.info[0].flipSides;
		oldBox = curBox;
		curBox = dialogueFile.info[0].dialogueBox;
		curSound = dialogueFile.info[0].dialogueSound;
		dialogueColor = dialogueFile.info[0].textColor;
		shadowColor = dialogueFile.info[0].textShadowColor;
		portraitColor = dialogueFile.info[0].portraitColor;
		timeCut = dialogueFile.info[0].skipAfter;

	}
}
