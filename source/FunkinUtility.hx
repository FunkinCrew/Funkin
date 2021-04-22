package;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.FlxG;
import flixel.graphics.frames.FlxAtlasFrames;
using StringTools;
/**
 * Nice converter to convert funkin objects to regular objects
 */
class FunkinUtility {
    static function convertFunkinSprite(funkin: FunkinSprite, ?graphicCallback:(BeatSprite, FunkinSprite)->Void, ?animCallback:(BeatSprite,FunkinSprite)->Void) : BeatSprite {
        if (graphicCallback == null) {
            graphicCallback = function(sprite : BeatSprite, funkee : FunkinSprite) : Void {
                sprite.loadGraphic(funkee.graphic + '.png');
            }
        }
        if (animCallback == null) {
            animCallback = function(sprite:BeatSprite, funkee : FunkinSprite) : Void {
                // if animation e
                var tex = FlxAtlasFrames.fromSparrow(funkee.graphic + '.png', funkee.graphic + '.xml');
                sprite.frames = tex;
            }
        }
        var realSprite : BeatSprite = new BeatSprite(funkin.x, funkin.y, funkin.canDance);
        if (funkin.graphic != null) {
            
			if (funkin.animation != null) {
                animCallback(realSprite, funkin);
            } else {
				graphicCallback(realSprite, funkin);
            }
        }
        realSprite.antialiasing = funkin.antialiasing;
        realSprite.flipX = funkin.flipX;
        realSprite.flipY = funkin.flipY;
        realSprite.setGraphicSize(Std.int(funkin.scale * realSprite.width));
        realSprite.updateHitbox();
        if (funkin.animation != null) {
            for (anim in funkin.animation) {
                if (anim.indices != null) {
                    realSprite.animation.addByIndices(anim.name, anim.prefix, anim.indices,"", anim.fps, anim.loop);
                } else {
                    realSprite.animation.addByPrefix(anim.name, anim.prefix, anim.fps, anim.loop);
                }
            }
        }
        return realSprite;
    }
    static function convertOffsetGroup(offsetgroup :OffsetSpriteGroup) : FlxTypedGroup<BeatSprite> {
        var group : FlxTypedGroup<BeatSprite> = new FlxTypedGroup<BeatSprite>();
        for (i in 0...offsetgroup.copies) {

            var sprite : BeatSprite = convertFunkinSprite(offsetgroup.sprite);
            sprite.x += i * offsetgroup.multiX;
            sprite.y += i * offsetgroup.multiY;
            group.add(sprite);
        }
        return group;
    }
    static function convertIndexGroup(indexgroup:IndexedSpriteGroup) : FlxTypedGroup<BeatSprite> {
        var group : FlxTypedGroup<BeatSprite> = new FlxTypedGroup<BeatSprite>();
        for (i in 0...indexgroup.copies) {
            var callback = function (sprite : BeatSprite, funkin : FunkinSprite) {
                sprite.loadGraphic(indexgroup.file.replace("${n}", Std.string(i)) + '.png');
            }
			var animCallback = function(sprite:BeatSprite, funkee:FunkinSprite):Void
			{
				// if animation e
				var tex = FlxAtlasFrames.fromSparrow(indexgroup.file.replace("${n}", Std.string(i)) + '.png',
					indexgroup.file.replace("${n}", Std.string(i)) + '.xml');
				sprite.frames = tex;
			}
            var sprite : BeatSprite = convertFunkinSprite(indexgroup.sprite, callback, animCallback);
			group.add(sprite);
        }

        return group;
    }
    // thank you unions for being cool
    static function calculateFunkinInt(funkinint:FunkinInt) : Int {
        switch funkinint.type() {
            case Int(i):
                return i;
            case FunkinRandomInt(f):
                return FlxG.random.int(f.min, f.max);
            case Null:
                return 0;
            default:
                return 0;
        }
    }
    static function executeFunktionOn(object:Dynamic, funktion : Funktion, boyfriend : Character, gf : Character, dad : Character) : Null<Dynamic> {
        var operators = funktion.operations;
        var currentobject : Dynamic = object;
        for (operat in operators) {
            switch (operat.useon) {
                case "boyfriend" | "bf" :
                    currentobject = boyfriend;
                case "girlfriend" | "gf":
                    currentobject = gf;
                case "dad":
                    currentobject = dad;
                default:
                    currentobject = object;
            }
            switch (operat.field) {
                case "return":
                    // return the function now, with the value if specified
                    if (operat.value != null) {
                        return operat.value;
                    } else {
                        return null;
                    }
                case "play_anim":
					currentobject.animation.play(operat.value);
                default: 
					if (Reflect.hasField(currentobject, operat.field) && operat.value != null) {
						Reflect.setProperty(currentobject, operat.field, operat.value);
                    }
            }
        }
        return null;
    }
 }
/**
 * type used with json2object to make custom stages easier. includes all required members of a sprite
 **/ 

typedef FunkinSprite = {
    @:default(0.0)
    var x : Float;
	@:default(0.0)
    var y : Float;
    @:default(false) @:optional
    var flipX : Bool;
    @:default(false) @:optional
    var flipY : Bool;
    @:optional
    var animation : Array<AnimationObject>;
    @:optional
    // path relative to the main fnf folder. expected to have no file ending, and
    // png files and xml files are only types supported.
    var graphic : String;
    @:default(false) @:optional
    var antialiasing : Bool;
    @:default(1) @:optional
    var scale : Int;
    @:default(false) @:optional
    var canDance : Bool;
    @:default(1) @:optional
    var beatmulti : Int;
    @:optional
    var event : SpecialEvent;
}
typedef LegalStageObject = Union3<FunkinSprite, IndexedSpriteGroup, OffsetSpriteGroup>;
typedef StageGroup = {
    @:default("default")
    var name : String;
    var sprites : Array<LegalStageObject>;
}
/**
 * A special type of int that can be either a regular int or a random int. Random
 * is (usually) calculated whenever it is needed, and not constant. 
 */
typedef FunkinInt = Union<Int, FunkinRandomInt>;
/**
 * Base type for groups that use only one sprite as a reference. This doesn't mean the graphic is the same,
 * it just means most things are similar between sprites.
 */
typedef CloneFunkinGroup = {
    var sprite : FunkinSprite;
    @:optional
    var event : SpecialEvent;
}
/**
 * A generic group, all it does is render sprites normally. Good for organization
 * although will probably impact preformance
 */
typedef FunkinGroup = {
    var sprites : Array<FunkinSprite>;
    @:optional
    var event : SpecialEvent;
}
/**
 * a sprite group that indexes each sprite. all sprites share the same values except the graphic,
 * which does a special file replacement. format of string is "blahblah${n}" and ${n} will be replaced
 * with a number. Makes all but 1 invisible. 
 */
typedef IndexedSpriteGroup = {
    > CloneFunkinGroup,
    var file : String;
    var copies : Int;
}
/**
 * A sprite group that offsets on x/y based on a multiple of a value + a starting position. 
 * Used for the dancing demons on the limo stage
 */
typedef OffsetSpriteGroup = {
    > CloneFunkinGroup,
    @:default(0.0)
    var multiX : Float;
    @:default(0.0)
    var multiY : Float;
    @:default(1)
    var copies : Int;
}
typedef AnimationObject = {
    var prefix : String;
    @:optional
    var indices : Array<Int>;
    var name : String;
    @:default(false) @:optional
    var loop : Bool;
    @:default(24) @:optional
    var fps : Int;
}
/**
 * Special events, animations, etc, that happen on beats. 
 */
typedef SpecialEvent = {
    @:default(true) 
    var onbeat : Bool;
    // this will probably act weird, as it will be calculated every beat if it is random
    @:default(1)
    var beatmulti : FunkinInt;
    // these ones are mostly used for lightning strike. 
    @:default(false) @:optional
    var onbool : Bool;
    @:default(1)
    var beatoffset : FunkinInt;
    @:default(10)
    var rollchance : Float;
    // What to execute. Referenced from the actual sprite, if it exists. 
    @:alias("function") var funkinfunction : Funktion;
}

/**
 * Random Integer, in json form. 
 */
typedef FunkinRandomInt = {
    @:default(0)
    var min : Int;
    @:default(1)
    var max : Int;
}
/**
 * A json based function that isn't as versitile as haxe, but allows manipulation of the sprite.
 * 
 */
 typedef Funktion = {
    var operations : Array<FunkinExpression>;
 }
/**
 * A json based expression, used to operate on sprites. Used in Funktion.
 */
 typedef FunkinExpression = {
     var field : String;
     // dynamic because it could be anything. will have to mess with casting to make sure it is proper
     // yes this means you will have to know FlxSprite names. Too Bad!
     // it's optional because there are some special cases, like return.
     @:optional
     var value : Dynamic;
     @:optional
     // who to use on. if not included presumes it is just ourselves.
     // can be a value of boyfriend, girlfriend
     var useon : String;
 }
typedef Stage = {
    var stages : Array<StageGroup>;
}