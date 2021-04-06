import faxe.Faxe;

import SndTV;
using StringTools;

// Praise delahee, I'll figure out what this shit means later!

class Channel {
	public var name:String;
	public var onEnd:Void->Void = null;
	public var isDebug:Bool = false;
	
	var started:Bool = true;
	var paused:Bool = false;
	var disposed:Bool = false;
	var completed:Bool = false;
		
	function new(?name:String = null) {
		if (name == null) this.name = C.EMPTY_STRING;
		else this.name = name;
	}
	
	public function poolBack():Void {
		#if false
		// trace('pool back');
		#end
		started = false;
		paused = false;
		disposed = true;
		completed = true;
		isDebug = false;
	}
	
	public function reset():Void {
		started = false;
		paused = false;
		disposed = false;
		completed = false;
		isDebug = false;
	}
	
	public function stop():Void {
		started = false;
	}
	
	public function pause():Void {
		paused = false;
		started = true;
	}
	
	public function resume():Void {
		paused = true;
		started = true;
	}
	
	public function dispose():Void {
		setVolume(0); // Prevent further listening
		disposed = true;
		onEnd = null;
	}
	
	public function onComplete():Void {
		completed = true;
		#if !prod
		// trace('onComplete ${haxe.Timer.stamp()}');
		#end
		// stop();
		if (onEnd != null) {
			var cb:Any = onEnd;
			onEnd = null;
			cb();
		}
	}
	
	public function isComplete():Bool {
		#if !prod
		if (completed) {
			// trace('already completed');
		}
		
		if (started) {
			// trace('started ok');
		}
		#end
		
		return completed || (started && !isPlaying());
	}
	
	// Returns in secs
	public function getPlayCursorSec():Float {
		throw 'override me';
		return 0.0;
	}
	
	// Returns in secs
	public function getPlayCursorMs():Float {
		throw 'override me';
		return 0.0;
	}
	
	public function setPlayCursorSec(posSec:Float):Void {
		setPlayCursorMs(posSec * 1000.0);
	}
	
	public function setPlayCursorMs(posMs:Float):Void {
		throw 'override me';
	}
	
	public function isPlaying():Bool {
		throw 'override me';
		return false;
	}
	
	public function getVolume():Float {
		throw 'override me';
		return 0.0;
	}
	
	public function setVolume(v:Float):Void {
		throw 'override me';
	}
	
	public function setNbLoops(nb:Int):Void {}
}

class ChannelEventInstance extends Channel { // Basically a sound instance
	public static var EMPTY_STRING:String = '';
	public var data:FmodStudioEventInstanceRef = null;
	
	function new(?name:String) {
		super(name);
		started = false;
		// Instance does not start playing
	}
	
	public static var pool:Any = {
		var p:Any = new hxd.Pool<ChannelEventInstance>(ChannelEventInstance);
		// p.actives = null;
		p;
	}
	
	public static function alloc(data:FmodStudioEventInstanceRef, ?name:String = null):Any {
		var s:Any = pool.alloc();
		
		s.reset();
		
		s.data = data;
		s.name = name || EMPTY_STRING;
		return s;
	}
	
	public static function delete(c:ChannelEventInstance):Any {
		c.dispose();
		pool.delete(c);
	}
	
	public inline function getData():Any return data;
	
	public override function dispose():Void {
		super.dispose();
		if (data != null) {
			data.release();
			data = null;
		}
	}
	
	public override function poolBack():Void {
		super.poolBack();
		ChannelEventInstance.delete(this);
	}
	
	public override function stop():Void {
		if (data != null) data.stop(FmodStudioStopMode.StopAllowFadeout());
		super.stop();
	}
	
	public override function pause():Void {
		super.pause();
		if (data != null) data.setPaused(true);
	}
	
	public override function resume():Void {
		super.resume();
		if (data != null) data.setPaused(false);
	}
	
	public override function isPlaying():Bool {
		if (completed) return false;
		
		if (data == null) {
			// #if !prod
			//    trace('[CEI]no data $name');
			// #end
			return false;
		}
		
		var b:Bool = false;
		data.getPaused(Cpp.addr(b));
		#if !prod
		// trace('getPaused:' + b);
		#end
		return !b;
	}
	
	// Returns in secs
	public override function getPlayCursorSec():Float {
		if (data == null) return 0.0;
		
		var pos:Int = 0;
		var res:Any = data.getTimelinePosition(Cpp.addr(pos));
		var posF:Float = 1.0 * pos / 1000.0;
		return posF;
	}
	
	// Returns in secs
	public override function getPlayCursorMs():Float {
		if (data == null) return 0.0;
		
		var pos:Int = 0;
		var res:Any = data.getTimelinePosition(Cpp.addr(pos));
		return 1.0 * pos;
	}
	
	public override function setPlayCursorMs(posMs:Float):Void {
		if (data == null) return;
		
		if (posMs < 0.0) posMs = 0.0;
		var pos:Int = 0;
		pos = Math.round(posMs);
		var res:Any = data.setTimelinePosition(pos);
		if (res != FMOD_OK) {
			#if debug
			// trace('[SND][Channel]{$name} Repositionning S err ${FaxeRef.fmodResultToString(res)} to :$pos ($posMs)');
			#end
		}
		
		#if debug
		// trace('setPlayCursorMs $posMs');
		#end
	}
	
	public override function setNbLoops(nb:Int):Void {}
	
	public override function getVolume():Float {
		if (data == null) return 0.0;
		
		var vol:cpp.Float32 = 0.0;
		var fvol:cpp.Float32 = 0.0;
		var res:Any = data.getVolume(Cpp.addr(vol), Cpp.addr(fvol));
		if (res != FMOD_OK) {
			#if debug
			// trace('[SND][Channel]{$name} getVolume err ${FaxeRef.fmodResultToString(res)}');
			#end
		}
		return vol;
	}
	
	public override function setVolume(v:Float):Void {
		if (data == null) {
			// #if debug
			//    trace('no data for $name');
			// #end
			return;
		}
		
		var res:Any = data.setVolume(hxd.Math.clamp(v, 0, 1));
		if (res != FMOD_OK) {
			// #if debug
			//    trace('[SND][Channel]{$name} setVolume err ${FaxeRef.fmodResultToString(res)}');
			// #end
		} else {
			// if (isDebug) {
				// #if !prod
				//    trace('[SND][Channel]{$name} setVolume ok $v');
				// #end
			// }
		}
	}
}

class ChannelLowLevel extends Channel {
	
	public static var EMPTY_STRING:String = '';
	public var data:FmodChannelRef = null;
	
	function new(data:FmodChannelRef, ?name:String) {
		super(name);
		this.data = data;
		started = true;
	}
	
	public static var pool:Any = {
		var p:Any = new hxd.Pool<ChannelLowLevel>(ChannelLowLevel);
		// p.actives = null;
		p;
	}
	
	public static function alloc(data:FmodChannelRef, ?name:String):Any {
		var s:Any = pool.alloc();
		
		s.reset();
		
		s.data = data;
		s.name = name || EMPTY_STRING;
		
		return s;
	}
	
	public static function delete(c:ChannelLowLevel):Void {
		c.dispose();
		pool.delete(c);
	}
	
	public inline function getData():Any return data;
	
	public override function poolBack():Void {
		super.poolBack();
		ChannelLowLevel.delete(this);
	}
	
	public override function stop():Void {
		if (data != null) data.stop();
		super.stop();
	}
	
	public override function pause():Void {
		super.pause();
		if (data != null) data.setPaused(true);
	}
	
	public override function resume():Void {
		super.resume();
		if (data != null) data.setPaused(false);
	}
	
	public override function dispose():Void {
		super.dispose();
		data = null;
	}
	
	public override function isPlaying():Bool {
		if (completed) return false;
		
		if (data == null) {
			// #if !prod
			//    trace('no data no playing! $name');
			// #end
			return false;
		}

		var b:Bool = false;
		var res:Any = data.isPlaying(Cpp.addr(b));
		if (res != FMOD_OK) {
			// #if debug
			//    trace('[SND][ChannelLowLevel]{$name} isPlaying err ${FaxeRef.fmodResultToString(res)}');
			// #end
			return false;
		}
		return b;
	}
	
	// Returns in secs
	public override function getPlayCursorSec():Float {
		if (data == null) return 0.0;
		
		var pos:cpp.UInt32 = 0;
		var res:Any = data.getPosition(Cpp.addr(pos), faxe.Faxe.FmodTimeUnit.FTM_MS);
		var posF:Float = 1.0 * pos * 1000.0;
		return posF;
	}
	
	// Returns in secs
	public override function getPlayCursorMs():Float {
		if (data == null) return 0.0;
		
		var pos:cpp.UInt32 = 0;
		var res:Any = data.getPosition(Cpp.addr(pos), faxe.Faxe.FmodTimeUnit.FTM_MS);
		return 1.0 * pos;
	}

	
	public override function setPlayCursorMs(posMs:Float):Void {
		if (data == null) return;
		
		if (posMs < 0.0) posMs = 0.0;
		var posU:cpp.UInt32 = 0;
		posU = Math.round(posMs);
		var res:Any = data.setPosition(posU, FmodTimeUnit.FTM_MS);
		if (res != FMOD_OK) {
			// #if debug
			//    trace('[SND][Channel]{$name} Repositionning S err ${FaxeRef.fmodResultToString(res)} to :$posU ($posMs)');
			// #end
		}
	}
	
	public override function setNbLoops(nb:Int):Void {
		if (data == null) return;
		data.setMode(FmodMode.FMOD_LOOP_NORMAL);
		data.setLoopCount(nb);
	}
	
	public override function getVolume():Float {
		if (data == null) return 0.0;
		
		var vol:cpp.Float32 = 0.0;
		var res:Any = data.getVolume(Cpp.addr(vol));
		if (res != FMOD_OK) {
			// #if debug
			//    trace('[SND][Channel]{$name} getVolume err ${FaxeRef.fmodResultToString(res)}');
			// #end
		}
		return vol;
	}
	
	public override function setVolume(v:Float):Void {
		if (data == null) {
			// if (isDebug) {
				// #if !prod
				//    trace('[SND][Channel]{$name} setVolume no data');
				// #end
			// }
			return;
		}
		
		var vcl:Any = hxd.Math.clamp(v, 0, 1);
		var res:Any = data.setVolume(vcl);
		if (res != FMOD_OK) {
			// #if !prod
			//    trace('[SND][Channel]{$name} setVolume err ${FaxeRef.fmodResultToString(res)}');
			// #end
		} else {
			if (isDebug) {
				// #if !prod
				//    trace('[SND][Channel]{$name} setVolume ok $v corrected:$vcl');
				// #end
			}
		}
	}
	
	
}

class Sound {
	// length is in seconds
	public var name:String = '';
	public var length(get, null):Float;
	public var id3:Dynamic = null;
	public var isDebug:Bool = false;
	
	var disposed:Bool = false;
	
	function new(?name:String = null) {
		disposed = false;
	}
	
	inline function get_length():Float return 0.0;
	
	// Returns in milliseconds
	public inline function getDuration():Float return getDurationMs();
	
	public inline function getDurationSec():Float return length;
	
	public inline function getDurationMs():Float return length * 1000.0;
	
	public function dispose():Void {
		if (disposed) return;
		disposed = true;
	}
	
	public inline function play(?offsetMs:Float = 0.0, ?nbLoops:Int = 1, ?volume:Float = 1.0):Channel return null;
}

class SoundLowLevel extends Sound {
	
	public var data:FmodSoundRef = null;
	
	public function new(data:cpp.Pointer<faxe.Faxe.FmodSound>, ?name:String = null) {
		super(name);
		this.data = Cpp.ref(data);
	}
	
	public inline function getData():Any return data;
	
	public override function dispose():Void {
		super.dispose();
		
		if (Snd.released) {
			data = null;
			return;
		}
		
		if (data != null) data.release();
		data = null;
	}
	
	// Returns in secs
	override function get_length():Float {
		if (disposed) return 0.0;
		
		var pos:cpp.UInt32 = 0;
		var res:Any = data.getLength(Cpp.addr(pos), FmodTimeUnit.FTM_MS);
		if (res != FMOD_OK) {
			#if debug
			// trace('impossible to retrieve sound len');
			#end
		}
		var posF:Float = 1.0 * pos / 1000.0;
		return posF;
	}
	
	public override function play(?offsetMs:Float = 0.0, ?nbLoops:Int = 1, ?volume:Float = 1.0):Channel {
		var nativeChan:FmodChannelRef = FaxeRef.playSoundWithHandle(data, false);
		var chan:Any = ChannelLowLevel.alloc(nativeChan, name);
		
		#if debug
		// trace('[Sound] offset $offsetMs');
		// trace('play ${haxe.Timer.stamp()}');
		#end
		
		@:privateAccess chan.started = true;
		@:privateAccess chan.completed = false;
		@:privateAccess chan.disposed = false;
		@:privateAccess chan.paused = false;
		
		
		if (offsetMs != 0.0) chan.setPlayCursorMs(offsetMs);
		if (volume != 1.0) chan.setVolume(volume);
		if (nbLoops > 1) chan.setNbLoops(nbLoops);
		
		return chan;
	}
}


class SoundEvent extends Sound {
	
	public var data:FmodStudioEventDescriptionRef = null;
	
	public function new(data:FmodStudioEventDescriptionRef, ?name:String = null) {
		super(name);
		this.data = data;
	}
	
	public override function dispose():Void {
		super.dispose();
		
		if (Snd.released) {
			data = null;
			return;
		}
		
		if (data != null) {
			data.releaseAllInstances();
			data = null;
		}
	}

	public inline function getData():Any return data;
	
	// Returns in secs
	override function get_length():Float {
		if (disposed) return 0.0;
		
		var pos:Int = 0;
		var res:Any = data.getLength(Cpp.addr(pos));
		if (res != FMOD_OK) {
			// #if !prod
			//    trace('impossible to retrieve sound len');
			// #end
		}
		var posF:Float = 1.0 * pos / 1000.0;
		return posF;
	}
	
	public override function play(?offsetMs:Float = 0.0, ?nbLoops:Int = 1, ?volume:Float = 1.0):Channel {
		var nativeInstance:FmodStudioEventInstanceRef = data.createInstance();
		var chan:Any = ChannelEventInstance.alloc(nativeInstance, name);
		
		// #if !prod
		//    trace('play ${haxe.Timer.stamp()}');
		// #end
		nativeInstance.start();
		
		@:privateAccess chan.started = true;
		@:privateAccess chan.completed = false;
		@:privateAccess chan.disposed = false;
		@:privateAccess chan.paused = false;
		
		if (offsetMs != 0.0) chan.setPlayCursorMs(offsetMs);
		if (volume != 1.0) chan.setVolume(volume);
		
		return chan;
	}
}

class Snd {
	public static var EMPTY_STRING:String = '';
	public static var PLAYING:hxd.Stack<Snd> = new hxd.Stack();
	static var MUTED:Bool = false;
	static var DISABLED:Bool = false;
	static var GLOBAL_VOLUME:Float = 1.0;
	static var TW:SndTV = new SndTV();
	
	public var name:String;
	public var pan:Float = 0.0;
	public var volume(default, set):Float = 1.0;
	public var curPlay:Null<Channel> = null;
	public var bus:Any = otherBus;	
	public var isDebug:Bool = true;
	/**
	 * for when stop is called explicitly
	 * allows disposal
	 */
	public var onStop:hxd.Signal = new hxd.Signal();
	public var sound:Sound = null;
		
	var onEnd:Null<Void->Void> = null;
	static var fmodSystem:FmodSystemRef = null;
	
	public static var otherBus:SndBus = new SndBus();
	public static var sfxBus:SndBus = new SndBus();
	public static var musicBus:SndBus = new SndBus();
	
	public function new(snd:Sound, ?name:String) {
		volume = 1;
		pan = 0;
		sound = snd;
		muted = false;
		this.name = name || EMPTY_STRING;
	}
	
	public inline function isLoaded():Bool return sound != null;
	
	// Does not dispose sound, only instanced
	public function stop():Void {
		TW.terminate(this); // Prevent re-entrance of fadeStop() and stop() not cutting any sound
		
		PLAYING.remove(this);
		
		if (isPlaying() && !onStop.isTriggering) onStop.trigger();
			
		if (curPlay != null) {
			curPlay.dispose();
			curPlay.poolBack();
			curPlay = null;
			#if !prod
			// trace('$name stopped');
			// Lib.showStack();
			#end
		}
		
		// bus = otherBus;
	}
	
	public function dispose():Void {
		// #if !prod
		//    trace('$name disposing');
		// #end
		
		if (isPlaying()) stop();
		
		if (curPlay != null) {
			curPlay.dispose();
			curPlay.poolBack();
			curPlay = null;
			// #if !prod
			//    trace('$name disposed');
			// #end
		}
		
		if (sound != null) {
			sound.dispose();
			sound = null;
		}
		
		onStop.dispose();
		
		onEnd = null;
		curPlay = null;
	}
	
	// Return in milliseconds
	public function getPlayCursor():Float {
		if (curPlay == null) return 0.0;
		return curPlay.getPlayCursorMs();
	}
	
	
	public function play(?vol:Float, ?pan:Float):Snd {
		if (vol == null) vol = volume;
		if (pan == null) pan = this.pan;

		start(0, vol, 0.0);
		
		return this;
	}
	
	/**
	 * Launches the sound, stops previous and rewrite the cur play dropping it into oblivion for the gc
	 */
	public function start(loops:Int = 0, vol:Float = 1.0, ?startOffsetMs:Float = 0.0):Void {
		if (DISABLED) {
			// #if debug
			//    trace('[SND] Disabled');
			// #end
			return;
		}

		if (sound == null) {
			// #if debug
			//    trace('[SND] no inner sound');
			// #end
			return;
		}

		if (isPlaying()) {
			// #if !prod
			//    trace('$name interrupting');
			// #end
			
			stop();
		}
			
		TW.terminate(this);
		
		this.volume = vol;
		this.pan = normalizePanning(pan);
		
		PLAYING.push(this);
		curPlay = sound.play(startOffsetMs, loops, getRealVolume());
		
		if (curPlay == null) {
			// #if !prod
			//    trace('play missed?');
			// #end
		} else {
			// #if !prod
			//    trace('started');
			// #end
		}
	}
	
	/**
	 * Launches the sound and rewrite the cur play dropping it into oblivion for the gc
	 */
	public function startNoStop(?loops:Int = 0, ?vol:Float = 1.0, ?startOffsetMs:Float = 0.0):Null<Channel> {
		if (DISABLED) {
			// #if debug
			//    trace('[SND] Disabled');
			// #end
			return null;
		}

		if (sound == null) {
			// #if debug
			//    trace('[SND] no inner sound');
			// #end
			return null;
		}
		
		this.volume = vol;
		this.pan = normalizePanning(pan);
		
		curPlay = sound.play(startOffsetMs, loops, getRealVolume());
		
		return curPlay;
	}
	
	public inline function getDuration():Float return getDurationMs();
	
	public inline function getDurationSec():Int return sound.length;
	
        // Returns in milliseconds
	public inline function getDurationMs():Float return sound.length * 1000.0;
	
	public static inline function trunk(v:Float, digit:Int):Float {
		var hl:Int = Math.pow(10.0, digit);
		return Std.int(v * hl) / hl;
	}
	
	public static function dumpMemory():String {
		var v0:Int = 0;
		var v1:Int = 0;
		var v2:Int = 0;
		
		var v0p:cpp.Pointer<Int> = Cpp.addr(v0);
		var v1p:cpp.Pointer<Int> = Cpp.addr(v1);
		var v2p:cpp.Pointer<Int> = Cpp.addr(v2);
		var str:String = '';
		var res:Any = fmodSystem.getSoundRAM(v0p, v1p, v2p);
		if (res != FMOD_OK) {
			// #if debug
			//    trace('[SND] cannot fetch snd ram dump');
			// #end
		}
		
		inline function f(val:Float):Float return trunk(val, 2);
		
		if (v2 > 0) str += 'fmod Sound chip RAM all:${f(v0 / 1024.0)}KB \t max:${f(v1 / 1024.0)}KB \t total: ${f(v2 / 1024.0)}KB\r\n';
		
		v0 = 0;
		v1 = 0;
		
		var res:Any = FaxeRef.Memory_GetStats(v0p, v1p, false);
		str += 'fmod Motherboard chip RAM all:${f(v0 / 1024.0)}KB \t max:${f(v1 / 1024.0)}KB \t total: ${f(v2 / 1024.0)}KB';
		return str;
	}
	
	public function playLoop(?loops:Int = 9999, ?vol:Float = 1.0, ?startOffset:Flost = 0.0):Snd {
		if (vol == null) vol = volume;

		start(loops, vol, startOffset);
		return this;
	}
	
	function set_volume(v:Float):Float {
		volume = v;
		refresh();
		return volume;
	}
	
	public inline function setVolume(v:Float):Void set_volume(v);
	
	public inline function getRealPanning():Float return pan;

	public function setPanning(p:Float):Void {
		pan = p;
		refresh();
	}

	public function onEndOnce(cb:Void->Void):Void {
		onEnd = cb;
	}
	
	public function fadePlay(?fadeDuration:Int = 100, ?endVolume:Float = 1.0):Any {
		var p:Any = play(0.0001);
		if (p == null) {
			// trace('nothing returned');
		} else {
			if (p.curPlay == null) {
				// trace('no curplay wtf?');
			} else {
				// trace('curplay ok');
			}
		}
		tweenVolume(endVolume, fadeDuration);
		return p;
	}
	
	public function fadePlayLoop(?fadeDuration:Int = 100, ?endVolume:Float = 1.0 , ?loops:Int = 9999):Any {
		var p:Any = playLoop(loops,0);
		tweenVolume(endVolume, fadeDuration);
		return p;
	}
	
	public function fadeStop(?fadeDuration:Int = 100):Any {
		if (!isPlaying()) {
			// #if !prod
			//    trace('not playing $name winn not unfade'); // Can cause re-entrance issues
			// #end
			return null;
		}
		
		isDebug = true;
		var t:Any = tweenVolume(0, fadeDuration);
		t.onEnd = _stop;
		return t;
	}
	
	public var muted:Bool = false;
	
	public function toggleMute():Void {
		muted = !muted; // TODO
		setVolume(volume);
	}

	public function mute():Void {
		muted = true;
		setVolume(volume);
	}

	public function unmute():Void {
		muted = false;
		setVolume(volume);
	}
	
	public function isPlaying():Bool {
		if (curPlay == null) {
			#if !prod
			// trace('no curplay');
			#end
			return false;
		}
		return curPlay.isPlaying();
	}
	
	public static function init():Void {
		#if debug
		   trace('[Snd] fmod init');
		#end
		Faxe.fmod_init(256);
		fmodSystem = FaxeRef.getSystem();
		released = false;
	}
	
	public static var released:Bool = true;
	
	public static function release():Void {
		TW.terminateAll();
		for (s in PLAYING) s.dispose();
		PLAYING.hardReset();
		released = true;
		// trace('releasing fmod');
		Faxe.fmod_release();
		#if !prod
		   trace('fmod released');
		#end
	}
	
	public static function setGlobalVolume(vol:Float):Void {
		GLOBAL_VOLUME = normalizeVolume(vol);
		refreshAll();
	}
	
	function refresh():Void {
		if (curPlay != null) {
			var vol:Any = getRealVolume();
			// trace('r:$vol');
			curPlay.setVolume(vol);
		} else {
			// #if debug
			//    trace('[Snd] no playin no refresh $name');
			// #end
		}
	}
	
	public function	setPlayCursorSec(pos:Float):Void {
		if (curPlay != null) curPlay.setPlayCursorSec(pos);
		else {
			// #if debug
			//    trace('setPlayCursorSec/no current instance');
			// #end
		}
	}
	
	public function	setPlayCursorMs(pos:Float):Void { 
		if (curPlay != null) curPlay.setPlayCursorMs(pos);
		else {
			// #if debug
			//    trace('setPlayCursorMs/no current instance');
			// #end
		}
	}
	
	public function tweenVolume(v:Float, ?easing:h2d.Tweenie.TType, ?milliseconds:Float = 100.0):TweenV {
		if (easing == null) easing = h2d.Tweenie.TType.TEase;
		var t:Any = TW.create(this, TVVVolume, v, easing, milliseconds);
		// #if !prod 
		//    trace('tweening $name to $v');
		// #end
		return t;
	}
	
	public function tweenPan(v:Float, ?easing:h2d.Tweenie.TType, ?milliseconds:Float = 100.0):TweenV {
		if (easing == null) easing = h2d.Tweenie.TType.TEase;
		var t:Any = TW.create(this, TVVPan, v, easing, milliseconds);
		return t;
	}
	
	public function getRealVolume():Any {
		var v:Float = volume * GLOBAL_VOLUME * (DISABLED ? 0 : 1) * (MUTED ? 0 : 1) * (muted ? 0 : 1) * bus.volume;
		if (v <= 0.001) v = 0.0;
		return normalizeVolume(v);
	}
	
	static inline function normalizeVolume(f:Float):Any return hxd.Math.clamp(f, 0, 1);

	static inline function normalizePanning(f:Float):Any return hxd.Math.clamp(f, -1, 1);
	
	static var _stop:Any = function(t:TweenV):Void {
		#if !prod
		// if (t.parent != null)
			// trace('${t.parent.name} cbk stopped');
		// else 
			// trace('unbound stop called');
		#end
		t.parent.stop();
	}
	
	static var _refresh:Any = function(t:TweenV):Void {
		
		// Avoid unwanted crash
		if (released) {
			// #if !prod
			//    trace('sorry released');
			// #end
			return;
		}
		
		t.parent.refresh();
	}
	
	static function refreshAll():Void {
		for (s in PLAYING) s.refresh();
	}
	
	function onComplete():Void {
		// #if debug
		//    trace('onComplete ${haxe.Timer.stamp()}');
		// #end
		
		if (curPlay != null) curPlay.onComplete();
		
		stop();
	}
	
	public function isComplete():Bool {
		if (curPlay == null) {
			// #if !prod
			//    trace('comp: no cur play');
			// #end
			return true;
		}

		return curPlay.isComplete();
	}
	
	/////////////////////////////////////////
	///////////////STATISTICS////////////////
	/////////////////////////////////////////
	
	public static var DEBUG_TRACK:Bool = false;
	
	// @:noDebug
	public static function loadSound(path:String, streaming:Bool, blocking:Bool):Sound {
		if (released) {
			// #if !prod
			//    trace('FMOD not active $path');
			// #end
			return null;
		}
		
		var mode:Any = FMOD_DEFAULT;
		
		if (streaming) mode |= FMOD_CREATESTREAM;
		if (!blocking) mode |= FMOD_NONBLOCKING;
			
		mode |= FmodMode.FMOD_2D;
		
		
		if (DEBUG_TRACK) trace('Snd:loading $path');
		
		var snd:cpp.RawPointer<faxe.Faxe.FmodSound> = cast null;
		var sndR:cpp.RawPointer<cpp.RawPointer<faxe.Faxe.FmodSound>> = cpp.RawPointer.addressOf(snd);
		
		#if switch
		   if (!path.startsWith('rom:')) path = 'rom://$path';
		#end
		
		var res:FmodResult = fmodSystem.createSound( 
			Cpp.cstring(path),
			mode,
			Cpp.nullptr(),
			sndR
		);
			
		if (res != FMOD_OK) {
			#if !prod
			    trace('unable to load $path code:$res msg:${FaxeRef.fmodResultToString(res)}');
			#end
			return null;
		}
		
		var n:String = null;
		
		#if debug
		   n = new bm.Path(path).getFilename();
		#end
			
		return new SoundLowLevel(cpp.Pointer.fromRaw(snd), n);
	}
	
	public static function loadEvent(path:String):Sound {
		if (released) {
			// #if !prod
			//    trace('FMOD not active $path');
			// #end
			return null;
		}
		
		
		if (DEBUG_TRACK) trace('Snd:loadingEvent $path');
		
		if (!path.startsWith('event:/')) path = 'event:/$path';
		
		var fss:FmodStudioSystemRef = faxe.FaxeRef.getStudioSystem();
		var ev:Any = fss.getEvent(path);
		
		if (ev == null) return null;
		
		if (!ev.isLoaded()) {
			var t0:Any = haxe.Timer.stamp();
			ev.loadSampleData();
			var t1:Any = haxe.Timer.stamp();
			#if debug
			// trace('time to preload:${(t1 - t0)}');
			#end
		}
		
		return new SoundEvent(ev, path);
	}
	
	public static function fromFaxe(path:String):Snd {
		if (released) {
			// #if !prod
			//    trace('FMOD not active $path');
			// #end
			return null;
		}
		
		var s:cpp.Pointer<FmodSound> = faxe.Faxe.fmod_get_sound(path);
		if (s == null) {
			#if !prod
			   trace('unable to find $path');
			#end
			return null;
		}
		
		var n:String = null;
		
		#if debug
		   n = new bm.Path(path).getFilename();
		#end
		
		return new Snd(new SoundLowLevel(s, n), path);
	}
	
	public static function loadSfx(path:String):Snd {
		var s:Sound = loadSound(path, false, false);
		if (s == null) return null;
		return new Snd(s, s.name);
	}
	
	public static function loadSong(path:String):Snd {
		var s:Sound = loadSound(path, true, true);
		if (s == null) return null;
		return new Snd(s, s.name);
	}
	
	public static function load(path:String, streaming:Bool = false, blocking:Bool = true):Snd {
		var s:Sound = loadSound(path, streaming, blocking);
		if (s == null) {
			#if !prod
			   trace('no such file $path');
			#end
			return null;
		}
		return new Snd(s, s.name);
	}
	
	public static inline function terminateTweens():Void TW.terminateAll();
	
	public static function update():Void {
		for (p in PLAYING.backWardIterator())
			if (p.isComplete()) {
				#if !prod
				// trace('[Snd] isComplete $p');
				#end
				p.onComplete();
			}
		TW.update(); // Let tweens complete
		
		if (!released) Faxe.fmod_update();
	}
	
	public static function loadSingleBank(filename:String):Null<faxe.Faxe.FmodStudioBankRef> {
		if (released) {
			#if debug 
			   trace('FMOD not active $filename');
			#end
			return null;
		}
		
		if (filename.endsWith('.fsb')) {
			#if debug 
			   trace('fsb files not supported');
			#end
			return null; // Old fmod format is not supported
		}
		
		var t0:Any = haxe.Timer.stamp();
		var fsys:Any = FaxeRef.getStudioSystem();
		var fbank:cpp.RawPointer<FmodStudioBank> = null;
		
		// trace('trying to load $filename');
		
		Lib.loadMode();
		var result:Any = fsys.loadBankFile( 
			cpp.ConstCharStar.fromString(filename), 
			FmodStudioLoadBank.FMOD_STUDIO_LOAD_BANK_NONBLOCKING, 
			cpp.RawPointer.addressOf(fbank));
		Lib.playMode();	
		
		if (result != FMOD_OK) {
			#if debug
			   trace('FMOD failed to LOAD sound bank with errcode:$result errmsg:${FaxeRef.fmodResultToString(result)}\n');
			#end
			return null;
		}
		// else 
		//	trace('loading...');
			
		var t1:Any = haxe.Timer.stamp();
		#if debug
		// trace('time to load bank:${(t1 - t0)}s');
		#end
		return cast fbank;
	}
}
