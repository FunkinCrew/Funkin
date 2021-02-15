package ui;

import flixel.util.typeLimit.OneOfTwo;
import flixel.math.FlxPoint;
import flixel.FlxG;
import flixel.effects.FlxFlicker;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.group.FlxGroup;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxSignal;

typedef ItemAsset = OneOfTwo<String, FlxAtlasFrames>

class MenuItemList extends MenuTypedItemList<MenuItem>
{
	public function addItem(x = 0.0, y = 0.0, name, callback, fireInstantly = false)
	{
		var i = length;
		var menuItem = new MenuItem(name, tex, callback, x, y);
		menuItem.fireInstantly = fireInstantly;
		menuItem.ID = i;
		add(menuItem);
		
		if (i == selectedIndex)
			menuItem.select();
		
		return menuItem;
	}
}

class MenuTypedItemList<T:MenuItem> extends FlxTypedGroup<T>
{
	public var tex:FlxAtlasFrames;
	public var selectedIndex = 0;
	public var onChange(default, null) = new FlxTypedSignal<T->Void>();
	public var onAcceptPress(default, null) = new FlxTypedSignal<T->Void>();
	
	public function new (asset:ItemAsset)
	{
		super();
		
		if (Std.is(asset, String))
			tex = Paths.getSparrowAtlas(cast asset);
		else
			tex = cast asset;
	}
	
	override function update(elapsed:Float)
	{
		super.update(elapsed);
		
		var controls = PlayerSettings.player1.controls;
		
		if (controls.UP_P)
			prev();

		if (controls.DOWN_P)
			next();

		if (controls.ACCEPT)
			accept();
	}
	
	public function accept()
	{
		var selected = members[selectedIndex];
		if (selected.fireInstantly)
			selected.callback();
		else
		{
			active = false;
			FlxG.sound.play(Paths.sound('confirmMenu'));
			FlxFlicker.flicker(selected, 1, 0.06, true, false, function(_)
			{
				selected.callback();
				active = true;
			});
		}
	}
	
	inline function prev() changeItem(-1);
	inline function next() changeItem(1);
	
	function changeItem(amount:Int)
	{
		FlxG.sound.play(Paths.sound('scrollMenu'));
		members[selectedIndex].idle();
		
		selectedIndex += amount;

		if (selectedIndex >= length)
			selectedIndex = 0;
		else if (selectedIndex < 0)
			selectedIndex = length - 1;
		
		var selected = members[selectedIndex];
		selected.select();
		onChange.dispatch(selected);
	}
	
	override function destroy()
	{
		super.destroy();
		tex = null;
	}
}

class MenuItem extends flixel.FlxSprite
{	
	public var callback:Void->Void;
	/**
	 * Set to true for things like opening URLs otherwise, it may it get blocked.
	 */
	public var fireInstantly = false;
	
	public function new (name, tex, callback, x = 0.0, y = 0.0)
	{
		super(x, y);
		
		frames = tex;
		setItem(name, callback);
	}
	
	public function setItem(name:String, callback:Void->Void)
	{
		this.callback = callback;
		
		animation.addByPrefix('idle', '$name basic', 24);
		animation.addByPrefix('selected', '$name white', 24);
		idle();
		scrollFactor.set();
		antialiasing = true;
	}
	
	function updateSize()
	{
		updateHitbox();
		centerOrigin();
		offset.copyFrom(origin);
	}
	
	public function idle()
	{
		animation.play('idle');
		updateSize();
	}
	
	public function select()
	{
		animation.play('selected');
		updateSize();
	}
}