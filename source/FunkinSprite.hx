package;
import flixel.FlxSprite;

class FunkinSprite extends FlxSprite {
    public var event : FunkinUtility.SpecialEvent;
    public var funktion : FunkinUtility.Funktion;
    public function new (x : Float, y : Float, ?coolevent : FunkinUtility.SpecialEvent) {
        super(x, y);
        if (coolevent != null) {
			event = coolevent;
			funktion = event.funkinfunction;
        }
        
    }
    public function runEvent(beat : Int, bf:Character, gf:Character, dad:Character) : Null<Dynamic> {
        if (beat % event.beatmulti != 0) return null;
        if (event == null) return null;
        if (funkiton == null) return null;
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
					currentobject.animation.play(oper.value);
				default:
					if (Reflect.hasField(currentobject, oper.field) && oper.value != null)
					{
						Reflect.setProperty(currentobject, oper.field, oper.value);
					}
			}
        }
		return null;
    }
    
}