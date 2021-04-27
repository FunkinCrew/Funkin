package;

import flixel.FlxBasic;
import flixel.group.FlxGroup;

class FlxZIndexGroup<T:FlxBasic> extends FlxTypedGroup<T>
{
	var zIndexByMember:Map<T, Int>;

	override public function new()
	{
		super();
		zIndexByMember = new Map<T, Int>();
	}

	override function add(Object:T):T
	{
		super.add(Object);
		return setZIndex(Object, 0);
	}

	override function remove(Object:T, Splice:Bool = false):T
	{
		super.remove(Object, Splice);
		zIndexByMember.remove(Object);
		return Object;
	}

	override function clear()
	{
		super.clear();
		zIndexByMember.clear();
	}

	public function addWithZIndex(member:T, zIndex:Int):T
	{
		super.add(member);
		return setZIndex(member, zIndex);
	}

	public function getZIndex(member:T):Int
	{
		return zIndexByMember.exists(member) ? zIndexByMember[member] : -1;
	}

	public function setZIndex(member:T, zIndex:Int):T
	{
		if (members.indexOf(member) != -1)
		{
			zIndexByMember.set(member, zIndex);
			sortByZ();
		}
		return member;
	}

	private function sortByZ():Void
	{
		this.members.sort((m1, m2) -> getZIndex(m1) - getZIndex(m2));
	}
}