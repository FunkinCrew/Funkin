package ui;

import lime.utils.Assets;

class HealthIcon extends TrackerSprite
{
	public var isPlayer:Bool = false;

	public var animatedIcon:Bool = false;

	public var offsetX:Float = 0.0;
	public var offsetY:Float = 0.0;

	public var startWidth:Float = 150;

	public function new(char:String = 'bf', isPlayer:Bool = false)
	{
		super(null, 10, -30, RIGHT);

		this.isPlayer = isPlayer;

		// plays anim lol
		playSwagAnim(char);
		scrollFactor.set();
	}

	public function playSwagAnim(?char:String = 'bf')
	{		
		changeIconSet(char);
	}

	public function changeIconSet(char:String = 'bf')
	{
		antialiasing = true;

		if(
			Assets.exists(Paths.image('icons/' + char + '-icons').split(".png")[0] + ".xml") ||
			Assets.exists(Paths.image('icons/icon-' + char).split(".png")[0] + ".xml") ||
			Assets.exists(Paths.image('icons/' + char).split(".png")[0] + ".xml")
		)
		{
			var selected = "your";

			if(Assets.exists(Paths.image('icons/' + char + '-icons').split(".png")[0] + ".xml"))
			{
				frames = Paths.getSparrowAtlas('icons/' + char + '-icons');
				selected = Paths.image('icons/' + char + '-icons');
			}
			else if(Assets.exists(Paths.image('icons/icon-' + char).split(".png")[0] + ".xml"))
			{
				frames = Paths.getSparrowAtlas('icons/icon-' + char);
				selected = Paths.image('icons/icon-' + char);
			}
			else if(Assets.exists(Paths.image('icons/' + char).split(".png")[0] + ".xml"))
			{
				frames = Paths.getSparrowAtlas('icons/' + char);
				selected = Paths.image('icons/' + char);
			}

			animation.addByPrefix(char, char, 24, true, isPlayer);

			if(Assets.exists(selected.split(".png")[0] + ".txt"))
			{
				var theFunny = Assets.getText(selected.split(".png")[0] + ".txt").split(" ");

				setGraphicSize(Std.int(width * Std.parseFloat(theFunny[2])));
				updateHitbox();

				offsetX = Std.parseFloat(theFunny[0]);
				offsetY = Std.parseFloat(theFunny[1]);
			}

			animatedIcon = true;
		}
		else
		{
			if(Assets.exists(Paths.image('icons/' + char + '-icons'))) // LE ICONS
				loadGraphic(Paths.image('icons/' + char + '-icons'), true, 150, 150);
			else if(Assets.exists(Paths.image('icons/' + 'icon-' + char))) // PSYCH ICONS
				loadGraphic(Paths.image('icons/' + 'icon-' + char), true, 150, 150);
			else if(Assets.exists(Paths.image('icons/' + char))) // lmao image file names i guess if you're really lazy
				loadGraphic(Paths.image('icons/' + char), true, 150, 150);
			else // UNKNOWN ICON
				loadGraphic(Paths.image('icons/placeholder-icon'), true, 150, 150);

			animation.add(char, [0, 1, 2], 0, false, isPlayer);
		}

		animation.play(char);

		startWidth = width;

		// antialiasing override
		switch(char)
		{
			case 'bf-pixel' | 'senpai' | 'senpai-angry' | 'spirit':
				antialiasing = false;
		}
	}
}
