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

typedef AtlasAsset = OneOfTwo<String, FlxAtlasFrames>;

class MenuItemList extends MenuTypedItemList<MenuItem>
{
	public var atlas:FlxAtlasFrames;
	
	public function new (atlas, navControls:NavControls = Vertical)
	{
		super(navControls);
		
		if (Std.is(atlas, String))
			this.atlas = Paths.getSparrowAtlas(cast atlas);
		else
			this.atlas = cast atlas;
	}
	
	public function createItem(x = 0.0, y = 0.0, name, callback, fireInstantly = false)
	{
		var item = new MenuItem(x, y, name, atlas, callback);
		item.fireInstantly = fireInstantly;
		return addItem(name, item);
	}
	
	override function destroy()
	{
		super.destroy();
		atlas = null;
	}
}

class MenuTypedItemList<T:MenuItem> extends FlxTypedGroup<T>
{
	public var selectedIndex(default, null) = 0;
	/** Called when a new item is highlighted */
	public var onChange(default, null) = new FlxTypedSignal<T->Void>();
	/** Called when an item is accepted */
	public var onAcceptPress(default, null) = new FlxTypedSignal<T->Void>();
	/** The navigation control scheme to use */
	public var navControls:NavControls;
	/** Set to false to disable nav control */
	public var enabled:Bool = true;
	
	var byName = new Map<String, T>();
	/** Set to true, internally to disable controls, without affecting vars like `enabled` */
	var busy:Bool = false;
	
	public function new (navControls:NavControls = Vertical)
	{
		this.navControls = navControls;
		super();
	}
	
	function addItem(name:String, item:T):T
	{
		if (length == selectedIndex)
			item.select();
		
		byName[name] = item;
		return add(item);
	}
	
	public function resetItem(oldName:String, newName:String, ?callback:Void->Void):T
	{
		if (!byName.exists(oldName))
			throw "No item named:" + oldName;
		
		var item = byName[oldName];
		byName.remove(oldName);
		byName[newName] = item;
		item.setItem(newName, callback);
		
		return item;
	}
	
	override function update(elapsed:Float)
	{
		super.update(elapsed);
		
		if (enabled && !busy)
			updateControls();
	}
	
	inline function updateControls()
	{
		var controls = PlayerSettings.player1.controls;
		
		switch(navControls)
		{
			case Vertical:
			{
				if (controls.UP_P  ) prev();
				if (controls.DOWN_P) next();
			}
			case Horizontal:
			{
				if (controls.LEFT_P ) prev();
				if (controls.RIGHT_P) next();
			}
			case Both:
			{
				if (controls.LEFT_P  || controls.UP_P  ) prev();
				if (controls.RIGHT_P || controls.DOWN_P) next();
			}
		}

		if (controls.ACCEPT)
			accept();
	}
	
	public function accept()
	{
		var selected = members[selectedIndex];
		onAcceptPress.dispatch(selected);
		
		if (selected.fireInstantly)
			selected.callback();
		else
		{
			busy = true;
			FlxG.sound.play(Paths.sound('confirmMenu'));
			FlxFlicker.flicker(selected, 1, 0.06, true, false, function(_)
			{
				busy = false;
				selected.callback();
			});
		}
	}
	
	inline function prev() changeItem(-1);
	inline function next() changeItem(1);
	
	function changeItem(amount:Int)
	{
		FlxG.sound.play(Paths.sound('scrollMenu'));
		var index = selectedIndex + amount;
		if (index >= length)
			index = 0;
		else if (index < 0)
			index = length - 1;
		
		selectItem(index);
	}
	
	public function selectItem(index:Int)
	{
		members[selectedIndex].idle();
		
		selectedIndex = index;
		
		var selected = members[selectedIndex];
		selected.select();
		onChange.dispatch(selected);
	}
	
	public function getItem(name:String)
	{
		return byName[name];
	}
	
	override function destroy()
	{
		super.destroy();
		byName.clear();
	}
}

class MenuItem extends flixel.FlxSprite
{	
	public var callback:Void->Void;
	/**
	 * Set to true for things like opening URLs otherwise, it may it get blocked.
	 */
	public var fireInstantly = false;
	
	public function new (x = 0.0, y = 0.0, name, tex, callback)
	{
		super(x, y);
		
		frames = tex;
		setItem(name, callback);
		antialiasing = true;
	}
	
	public function setItem(name:String, ?callback:Void->Void)
	{
		if (callback != null)
			this.callback = callback;
		
		var selected = animation.curAnim != null && animation.curAnim.name == "selected";
		
		animation.addByPrefix('idle', '$name basic', 24);
		animation.addByPrefix('selected', '$name white', 24);
		idle();
		if (selected)
			select();
	}
	
	function changeAnim(anim:String)
	{
		animation.play(anim);
		updateHitbox();
	}
	
	public function idle()
	{
		changeAnim('idle');
	}
	
	public function select()
	{
		changeAnim('selected');
	}
}

enum NavControls
{
	Horizontal;
	Vertical;
	Both;
}