package modding;

#if sys
import polymod.backends.PolymodAssets;
#end
import flixel.FlxG;
import openfl.utils.Assets;
import flixel.system.FlxAssets;
import flixel.system.FlxSound;
import flash.events.Event;
import flash.media.Sound;
import openfl.utils.ByteArray;
#if (openfl >= "8.0.0")
import openfl.utils.AssetType;
#end

/*
	public function loadByteArray(Bytes:openfl.utils.ByteArray, Looped:Bool = false, AutoDestroy:Bool = false, ?OnComplete:Void->Void):ModdingSound
	{
		cleanup(true);

		_sound = new Sound();
		_sound.addEventListener(Event.ID3, gotID3);
		_sound.loadCompressedDataFromByteArray(Bytes, Bytes.length);

		return init(Looped, AutoDestroy, OnComplete);
	}
*/

/**
* Basically a copy of ModdingSound that is modified to play sounds from system paths (which i originally modified my flxsound.hx for :scared:)
*/
class ModdingSound extends FlxSound
{
     /**
      * One of the main setup functions for sounds, this function loads a sound from a ByteArray.
      *
      * @param	Bytes 			A ByteArray object.
      * @param	Looped			Whether or not this sound should loop endlessly.
      * @param	AutoDestroy		Whether or not this ModdingSound instance should be destroyed when the sound finishes playing.
      * 							Default value is false, but `FlxG.sound.play()` and `FlxG.sound.stream()` will set it to true by default.
      * @return	This ModdingSound instance (nice for chaining stuff together, if you're into that).
      */
    public function loadByteArray(Bytes:openfl.utils.ByteArray, Looped:Bool = false, AutoDestroy:Bool = false, ?OnComplete:Void->Void):FlxSound
    {
        cleanup(true);

        _sound = new Sound();
        _sound.addEventListener(Event.ID3, gotID3);
        _sound.loadCompressedDataFromByteArray(Bytes, Bytes.length);

        return init(Looped, AutoDestroy, OnComplete);
    }
}