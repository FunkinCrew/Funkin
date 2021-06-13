package;

import flixel.FlxBasic;
import flixel.group.FlxGroup;

class Alloctable
{
	public static function alloc(group:FlxGroup)
	{
		var j = 0;
		for (i in group.members)
		{
			if (i != null)
			{
				i.destroy();
			}
			i = null;
			group.members[j] = null;
			j++;
		}

		trace('alloc: ' + j + " objects.");
	}

}
