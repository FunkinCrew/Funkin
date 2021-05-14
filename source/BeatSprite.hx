/*
 * Mozilla Public License, Version 2.0
 *
 * Copyright (c) 2021 BulbyVR
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/.
 
package;
import flixel.FlxSprite;

class BeatSprite extends FunkinSprite {
    var danceDir : Bool = false;
    public var danceBeat : Int = 1;
    public var shouldDance : Bool = false;
    public var shouldIdleDance : Bool = false;
    public function new (x : Float, y : Float, shouldDanceVar : Bool = false, danceBeatVar : Int = 1, ?event:FunkinUtility.SpecialEvent) {
        super(x, y,event);
        shouldDance = shouldDanceVar;
        danceBeat = danceBeatVar;
    }
    public function dance(beat : Int):Void {
        // if character doesn't have dance anim, don't dance
        if (!shouldDance) return;
        if (beat % danceBeat != 0) return;
        danceDir = !danceDir;

        if (danceDir && !shouldIdleDance) {
            animation.play("danceRight", true);
        } else if (!shouldIdleDance){
            animation.play("danceLeft", true);
        } else {
            animation.play("idle", true);
        }
    }

}*/