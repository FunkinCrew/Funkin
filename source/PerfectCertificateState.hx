package;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.group.FlxGroup.FlxTypedGroup;

using StringTools;

class PerfectCertificateState extends MusicBeatState
{
	
	override function create()
	{
		var Certif:FlxSprite = new FlxSprite().loadGraphic(Paths.image('Certificate'));
		var Medal:FlxSprite = new FlxSprite(570, 78);
		Medal.frames = Paths.getSparrowAtlas('PerfectText');
		Medal.animation.addByPrefix('easy', 'Bronze', 24, true);
		Medal.animation.addByPrefix('medium', 'Silver', 24, true);
		Medal.animation.addByPrefix('hard', 'Gold', 24, true);
		add(Certif);
		add(Medal);
		
		var WeekTexts:Array<Dynamic> = [
			[ //StoryMode
				[ //Tutorial
					"Ya beat the tutorial!",
					"Now go play the whole game.",
					"Dumbass."
				],
				[ //WEEK 1
				],
				[ //WEEK 2
				],
				[ //WEEK 3
				],
				[ //WEEK 4
				],
				[ //WEEK 5
				],
				[ //WEEK 6
				],
				[ //B-Tutorial
				],
				[ //WEEK B1
				],
				[ //WEEK B2
				],
				[ //WEEK B3
				],
				[ //WEEK B4
				],
				[ //WEEK B5
				],
				[ //WEEK B6
				]
			],
			[ //Freeplay
			]
		];
		
		switch (PlayState.storyDifficulty)
		{
			case 0:
				Medal.animation.play('easy');
			case 1:
				Medal.animation.play('medium');
			case 2:
				Medal.animation.play('hard');
		}
		
		if (PlayState.CharacterSuffix.startsWith('-pixel'))
		{
			FlxG.sound.playMusic(Paths.music('PerfectWin-pixel'));
		}
		else
		{
			FlxG.sound.playMusic(Paths.music('PerfectWin'));
		}
		
		var CongText:FlxText;
		CongText = new FlxText(300, 320, 0, "Congratulations! You got a perfect!", 32);
		CongText.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE,FlxColor.ORANGE);
		add(CongText);		
		
		var ResultsText = new FlxTypedGroup<FlxText>();
		add(ResultsText);
		
		var isFreePlay:Int = 0;
		if (!PlayState.isStoryMode)
			isFreePlay = 1;
					
		for (i in 0...WeekTexts[isFreePlay][PlayState.storyWeek].length)
		{
			var DispText:FlxText = new FlxText(250, 400 + (40*i), 780, WeekTexts[isFreePlay][PlayState.storyWeek][i], 40);
			DispText.autoSize = false;
			DispText.setFormat(Paths.font("vcr.ttf"), 40, FlxColor.BLACK, CENTER);
			if ((PlayState.storyWeek == 0) && (PlayState.storyDifficulty == 2))
			{
				switch(i)
				{
					case 0:
						DispText.text = "Hey you, little piss baby.";
					case 1:
						DispText.text = "Think you're tough to beat this";
					case 2:
						DispText.text = "shit? Then play the other songs, nerd.";
				}
			}
			ResultsText.add(DispText);
		}
		
	}
	
	override function update(elapsed:Float)
	{
		super.update(elapsed);
		if (FlxG.keys.justPressed.ANY)
		{
			FlxG.sound.playMusic(Paths.music('freakyMenu'));
			FlxG.switchState(new StoryMenuState());
		}
	}
	
}
