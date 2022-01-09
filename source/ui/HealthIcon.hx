package ui;

import lime.utils.Assets;

class HealthIcon extends TrackerSprite
{
	public var isPlayer:Bool = false;

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

		if(Assets.exists(Paths.image('icons/' + char + '-icons'))) // LE ICONS
			loadGraphic(Paths.image('icons/' + char + '-icons'), true, 150, 150);
		else if(Assets.exists(Paths.image('icons/' + 'icon-' + char))) // PSYCH ICONS
			loadGraphic(Paths.image('icons/' + 'icon-' + char), true, 150, 150);
		else if(Assets.exists(Paths.image('icons/' + char))) // lmao image file names i guess if you're really lazy
			loadGraphic(Paths.image('icons/' + char), true, 150, 150);
		else // UNKNOWN ICON
			loadGraphic(Paths.image('icons/placeholder-icon'), true, 150, 150);

		animation.add(char, [0, 1, 2], 0, false, isPlayer);
		animation.play(char);

		// antialiasing override
		switch(char)
		{
			case 'bf-pixel' | 'senpai' | 'senpai-angry' | 'spirit':
				antialiasing = false;
		}
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);
	}
}
