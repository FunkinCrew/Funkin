
/*
package;
import flixel.FlxSprite;
import flixel.FlxG;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
class FunkinSprite extends FlxSprite {
    public var event : FunkinUtility.SpecialEvent;
    public var funktion : FunkinUtility.Funktion;
    public var graphicpath : String;
    public function new (x : Float, y : Float, ?coolevent : FunkinUtility.SpecialEvent) {
        super(x, y);
        if (coolevent != null) {
			event = coolevent;
			funktion = event.funkinfunction;
        }
        
    }
    public function runEvent(beat : Int, bf:Character, gf:Character, dad:Character) : Null<Dynamic> {
        trace("checking event.");
        if (beat % event.beatmulti != 0) {
            trace("beat multi");
            return null;
        }
        if (event == null) return null;
        trace("Event passed");
        if (funktion == null) return null;
        trace("Funktion passes");
        var currentobject : FlxSprite = this;
        for (oper in funktion.operations) {
			switch (oper.useon)
			{
				case "boyfriend" | "bf":
					currentobject = bf;
				case "girlfriend" | "gf":
					currentobject = gf;
				case "dad":
					currentobject = dad;
				default:
					currentobject = this;
			}
			trace(oper.field);
			switch (oper.field)
			{
				case "return":
					// return the function now, with the value if specified
					if (oper.value != null)
					{
						return oper.value;
					}
					else
					{
						return null;
					}
				case "play_anim":
					trace(oper.value);

					currentobject.animation.play(oper.value);
				case "play_sound":
					FlxG.sound.play(graphicpath + oper.value + '.ogg');
				default:
					if (oper.dotween)
					{
						var easeing:Float->Float;
						switch (oper.easing)
						{
							case "cubeinout":
								easeing = FlxEase.cubeInOut;
							default:
								easeing = FlxEase.linear;
						}
						var values = {};
						Reflect.setField(values, oper.field, Std.parseFloat(oper.value));
						FlxTween.tween(currentobject, values, oper.tweentime, {
							ease: easeing
						});
					}
					else
					{
						if (Reflect.hasField(currentobject, oper.field) && oper.value != null)
						{
							Reflect.setProperty(currentobject, oper.field, oper.value);
						}
					}
			}
        }
		return null;
    }
			
}*/
    