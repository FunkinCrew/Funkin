package;
import flixel.graphics.FlxGraphic;
import flixel.FlxSprite;
import flixel.group.FlxGroup.FlxTypedGroup;
/**
 * Nice converter to convert funkin objects to regular objects
 */
class FunkinUtility {
    static function convertFunkinSprite(funkin: FunkinSprite) : BeatSprite {
        var realSprite : BeatSprite = new BeatSprite(funkin.x, funkin.y, false);
        if (funkin.graphic != null) {
            realSprite.loadGraphic(funkin.graphic);
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
            var sprite : BeatSprite = new BeatSprite(offsetgroup.sprite.x, offsetgroup.sprite.y);
			sprite.antialiasing = offsetgroup.sprite.antialiasing;
			sprite.flipX = offsetgroup.sprite.flipX;
			sprite.flipY = offsetgroup.sprite.flipY;
			sprite.setGraphicSize(Std.int(offsetgroup.sprite.scale * sprite.width));
            sprite.updateHitbox();
			if (offsetgroup.sprite.animation != null) {
				for (anim in offsetgroup.sprite.animation) {
                    if (anim.indices != null) {
                        sprite.animation.addByIndices(anim.name, anim.prefix, anim.indices, "", anim.fps, anim.loop);
                    } else {
                        sprite.animation.addByPrefix(anim.name, anim.prefix, anim.fps, anim.loop);
                    }
                }
            }
            group.add(sprite);
        }
        return group;
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
    var graphic : String;
    @:default(false) @:optional
    var antialiasing : Bool;
    @:default(1) @:optional
    var scale : Int;
}
typedef StageGroup = {
    @:default("default")
    var name : String;
    var sprites : Array<Union3<FunkinSprite, IndexedSpriteGroup, OffsetSpriteGroup>>;
}
/**
 * a sprite group that indexes each sprite. all sprites share the same values except the graphic,
 * which does a special file replacement. format of string is "blahblah${n}" and ${n} will be replaced
 * with a number
 */
typedef IndexedSpriteGroup = {
    var file : String;
    var sprite : FunkinSprite;
}
/**
 * A sprite group that offsets on x/y based on a multiple of a value + a starting position. 
 * Used for the dancing demons on the limo stage
 */
typedef OffsetSpriteGroup = {
    @:default(0.0)
    var defaultX : Float;
    @:default(0.0)
    var defaultY : Float;
    @:default(0.0)
    var multiX : Float;
    @:default(0.0)
    var multiY : Float;
    @:default(1)
    var copies : Int;
    var sprite : FunkinSprite;
}
typedef AnimationObject = {
    var prefix : String;
    var indices : Array<Int>;
    var name : String;
    @:default(false) @:optional
    var loop : Bool;
    @:default(24) @:optional
    var fps : Int;
} 
