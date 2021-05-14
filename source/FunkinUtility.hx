/*

package;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.FlxG;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.graphics.frames.FlxAtlasFrames;
using StringTools;

class FunkinUtility {
    public static function convertFunkinSprite(funkin: TFunkinSprite, ?graphicCallback:(BeatSprite, TFunkinSprite)->Void, ?animCallback:(BeatSprite,TFunkinSprite)->Void) : BeatSprite {
        if (graphicCallback == null) {
            graphicCallback = function(sprite : BeatSprite, funkee : TFunkinSprite) : Void {
                sprite.loadGraphic(funkee.graphic + '.png');
            }
        }
        if (animCallback == null) {
            animCallback = function(sprite:BeatSprite, funkee : TFunkinSprite) : Void {
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
    public static function convertOffsetGroup(offsetgroup :OffsetSpriteGroup) : FlxTypedGroup<BeatSprite> {
        var group : FlxTypedGroup<BeatSprite> = new FlxTypedGroup<BeatSprite>();
        for (i in 0...offsetgroup.copies) {

            var sprite : BeatSprite = convertFunkinSprite(offsetgroup.sprite);
            sprite.x += i * offsetgroup.multiX;
            sprite.y += i * offsetgroup.multiY;
            group.add(sprite);
        }
        return group;
    }
    public static function convertIndexGroup(indexgroup:IndexedSpriteGroup) : FlxTypedGroup<BeatSprite> {
        var group : FlxTypedGroup<BeatSprite> = new FlxTypedGroup<BeatSprite>();
        for (i in 0...indexgroup.copies) {
            var callback = function (sprite : BeatSprite, funkin : TFunkinSprite) {
                sprite.loadGraphic(indexgroup.file.replace("${n}", Std.string(i)) + '.png');
            }
			var animCallback = function(sprite:BeatSprite, funkee:TFunkinSprite):Void
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

    public static function executeFunktionOn(object:Dynamic, funktion : Funktion, boyfriend : Character, gf : Character, dad : Character) : Null<Dynamic> {
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


typedef TFunkinSprite = {
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
class JSONFunkinSprite {
    @:default(0.0) public var x : Float;
    @:default(0.0) public var y : Float;
    @:default(false) @:optional public var flipX : Bool;
    @:default(false) @:optional public var flipY : Bool;
    @:default(1.0) public var alpha : Float;
    @:optional public var animation : Array<AnimationObject>;
    public var graphic : String;
    // not read from the file. expected to be assigned by playstate, depending on what it is reading.
    // Makes it so json files aren't piling up :hueh:
    @:jignored public var graphicpath : String;
    @:default(true) @:optional public var antialiasing : Bool;
    @:default(1) @:optional public var scale : Int;
    @:default(false) @:optional public var canDance : Bool;
    @:default(1) @:optional public var beatmulti : Int;
    @:optional public var event : SpecialEvent;
    public function new() {}

    public function convertToBeatSprite() : BeatSprite {
        trace(graphicpath + graphic);
        var beatsprite = new BeatSprite(x, y, canDance, beatmulti, event);
        beatsprite.flipX = flipX;
        beatsprite.alpha = alpha;
        beatsprite.flipY = flipY;
        if (animation != null) {
            trace(animation);
            var tex = FlxAtlasFrames.fromSparrow(graphicpath + graphic + '.png', graphicpath + graphic + '.xml');
            beatsprite.frames = tex;
			for (anim in animation)
			{
				if (anim.indices != null)
				{
					beatsprite.animation.addByIndices(anim.name, anim.prefix, anim.indices, "", anim.fps, anim.loop);
				}
				else
				{
					beatsprite.animation.addByPrefix(anim.name, anim.prefix, anim.fps, anim.loop);
				}
                
			}
			beatsprite.animation.play('idle');
        } else {
            beatsprite.loadGraphic(graphicpath + graphic + '.png');
        }
        beatsprite.antialiasing = antialiasing;
        beatsprite.graphicpath = graphicpath;
        return beatsprite;
    }

}
typedef LegalStageObject = Union3<TFunkinSprite, IndexedSpriteGroup, OffsetSpriteGroup>;
typedef StageGroup = {
    @:default("default")
    var name : String;
    var sprites : Array<JSONFunkinSprite>;
}

typedef CloneFunkinGroup = {
    var sprite : TFunkinSprite;
    @:optional
    var event : SpecialEvent;
}

typedef FunkinGroup = {
    var sprites : Array<TFunkinSprite>;
    @:optional
    var event : SpecialEvent;
}

typedef IndexedSpriteGroup = {
    > CloneFunkinGroup,
    var file : String;
    var copies : Int;
}

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

typedef SpecialEvent = {
    @:default(1)
    var beatmulti : Int;
    // What to execute. Referenced from the actual sprite, if it exists. 
    @:alias("function") var funkinfunction : Funktion;
}
typedef FunkinCommand = Union<FunkinExpression, FunkinIf>;

 typedef Funktion = {
    var operations : Array<FunkinExpression>;
 }

 typedef FunkinExpression = {
     var field : String;
     // dynamic because it could be anything. will have to mess with casting to make sure it is proper
     // yes this means you will have to know FlxSprite names. Too Bad!
     // it's optional because there are some special cases, like return.
     @:optional
     var value : String;
     @:optional
     // who to use on. if not included presumes it is just ourselves.
     // can be a value of boyfriend, girlfriend, or dad
     var useon : String;
     // do tween?
     @:default(false) @:optional var dotween : Bool;
     @:optional var tweentime : Float;

     // linear or cubeinout
     @:optional @:default("cubeinout") var easing : String;

 }
 typedef FunkinComparison = {
     // how are we comparing?
    @:default("equal")
    var comparing : String;
    // a value that will be compared using our comparing tool.
    // on left side of equation
    var valueone : String;
    // on right side of equation
    var valuetwo : String;
 }
 typedef FunkinIf = {
     // a funkincomparison
     var comparison : FunkinComparison;
     // what to do if true
    var iftrue : Funktion;
    // what to do if false
    @:optional @:alias("else")
    var funkelse : Funktion;

 }
typedef Stage = {
    var stages : Array<StageGroup>;
    var bfoffset : Array<Float>;
    var gfoffset : Array<Float>;
    var dadoffset : Array<Float>;
    var defaultZoom : Float;
}

typedef EventData = {
    var lastbeat : Int;
    var beatoffset : Int;
}

typedef SpriteData = {
    var eventindex : Int;
    var spriteindex : Int;
}
*/