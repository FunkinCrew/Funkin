import faxe.Faxe;

import SndTV;
using StringTools;

//praise delahee, i'll figure out what this shit means later!

class Channel {
	public var		name:String;
	public var 		onEnd : Void -> Void 	= null;
	public var		isDebug = false;
	
	var started 	= true;
	var paused 		= false;
	var disposed 	= false;
	var completed 	= false;
		
	inline function new( ?name:String = null ){
		if ( name == null )
			this.name = C.EMPTY_STRING;
		else 
			this.name = name;
	}
	
	public function poolBack(){
		#if false
		//trace("pool back");
		#end
		started 	= false;
		paused 		= false;
		disposed 	= true;
		completed 	= true;
		isDebug 	= false;
	}
	
	public function reset(){
		started 	= false;
		paused 		= false;
		disposed 	= false;
		completed 	= false;
		isDebug 	= false;
	}
	
	public function stop(){
		started = false;
	}
	
	public function pause(){
		paused = false;
		started = true;
	}
	
	public function resume(){
		paused = true;
		started = true;
	}
	
	public function dispose(){
		setVolume(0);//prevent any further listen
		disposed = true;
		onEnd = null;
	}
	
	public function onComplete() {
		completed = true;
		#if !prod
		//trace("onComplete " + haxe.Timer.stamp() );
		#end
		//stop();
		if( onEnd!=null ) {
			var cb = onEnd;
			onEnd = null;
			cb();
		}
	}
	
	public function isComplete(){
		#if !prod
		if ( completed ){
			//trace("already completed");
		}
		
		if ( started ){
			//trace("started ok");
		}
		#end
		
		return completed || (started && !isPlaying());
	}
	
	//returns in secs
	public function getPlayCursorSec() : Float {
		throw "override me";
		return 0.0;
	}
	
	//returns in secs
	public function getPlayCursorMs() : Float {
		throw "override me";
		return 0.0;
	}
	
	public function setPlayCursorSec(posSec:Float) {
		setPlayCursorMs( posSec * 1000.0 );
	}
	
	public function setPlayCursorMs(posMs:Float) {
		throw "override me";
	}
	
	public function isPlaying(){
		throw "override me";
		return false;
	}
	
	public function getVolume():Float{
		throw "override me";
		return 0.0;
	}
	
	public function setVolume(v:Float){
		throw "override me";
	}
	
	public function setNbLoops(nb:Int){
		
	}
}

class ChannelEventInstance extends Channel {//basically a sound instance
	public static var EMPTY_STRING = "";
	public var data : FmodStudioEventInstanceRef = null;
	
	function new(?name:String){
		super(name);
		started = false;
		//instance does not start playing
	}
	
	public static var pool = {
		var p = new hxd.Pool<ChannelEventInstance>(ChannelEventInstance);
		//p.actives = null;
		p;
	}
	
	public static function alloc(data : FmodStudioEventInstanceRef, ?name:String=null ){
		var s = pool.alloc();
		
		s.reset();
		
		s.data = data;
		s.name = name == null ? EMPTY_STRING : name;
		return s;
	}
	
	public static function delete( c : ChannelEventInstance){
		c.dispose();
		pool.delete(c);
	}
	
	public function getData()	return data;
	
	public override function dispose(){
		super.dispose();
		if ( data != null){
			data.release();
			data = null;
		}
	}
	
	public override function poolBack(){
		super.poolBack();
		ChannelEventInstance.delete(this);
	}
	
	public override function stop(){
		if (data != null) data.stop(FmodStudioStopMode.StopAllowFadeout());
		super.stop();
	}
	
	public override function pause(){
		super.pause();
		if(data!=null) data.setPaused(true);
	}
	
	public override function resume(){
		super.resume();
		if(data!=null) data.setPaused(false);
	}
	
	public override function isPlaying(){
		if ( completed ) return false;
		
		if ( data == null ) {
			//#if !prod
			//trace("[CEI]no data " + name);
			//#end
			return false;
		}
		
		var b : Bool = false;
		data.getPaused( Cpp.addr(b));
		#if !prod
		//trace("getPaused:"+b);
		#end
		return !b;
	}
	
	//returns in secs
	public override  function getPlayCursorSec() : Float {
		if ( data == null ) return 0.0;
		
		var pos : Int = 0;
		var res = data.getTimelinePosition( Cpp.addr(pos) );
		var posF : Float = 1.0 * pos / 1000.0;
		return posF;
	}
	
	//returns in secs
	public override function getPlayCursorMs() : Float {
		if ( data == null ) return 0.0;
		
		var pos : Int = 0;
		var res = data.getTimelinePosition( Cpp.addr(pos) );
		return 1.0 * pos;
	}
	
	public override function setPlayCursorMs(posMs:Float) {
		if ( data == null ) return;
		
		if ( posMs < 0.0) posMs = 0.0;
		var pos : Int = 0;
		pos = Math.round( posMs );
		var res = data.setTimelinePosition( pos );
		if ( res != FMOD_OK){
			#if debug
			//trace("[SND][Channel]{"+name+"} Repositionning S err " + FaxeRef.fmodResultToString(res)+" to :"+pos+" ("+posMs+")");
			#end
		}
		
		#if debug
		//trace("setPlayCursorMs "+posMs);
		#end
	}
	
	public override function setNbLoops(nb:Int){
		
	}
	
	public override function getVolume() : Float{
		if (data == null ) return 0.0;
		
		var vol : cpp.Float32 = 0.0;
		var fvol : cpp.Float32 = 0.0;
		var res = data.getVolume( Cpp.addr(vol),Cpp.addr(fvol) );
		if ( res != FMOD_OK){
			#if debug
			//trace("[SND][Channel]{"+name+"} getVolume err " + FaxeRef.fmodResultToString(res));
			#end
		}
		return vol;
	}
	
	public override function setVolume(v:Float){
		if (data == null ){
			//#if debug
			//trace("no data for "+name);
			//#end
			return;
		}
		
		var res = data.setVolume( hxd.Math.clamp(v,0,1) );
		if ( res != FMOD_OK){
			//#if debug
			//trace("[SND][Channel]{"+name+"} setVolume err " + FaxeRef.fmodResultToString(res));
			//#end
		}
		else {
			//if ( isDebug ){
				//#if !prod
				//trace("[SND][Channel]{"+name+"} setVolume ok " + v);
				//#end
			//}
		}
	}
}

class ChannelLowLevel extends Channel{
	
	public static var EMPTY_STRING = "";
	public var 		data : FmodChannelRef 	= null;
	
	function new( data : FmodChannelRef, ?name:String ){
		super(name);
		this.data = data;
		started = true;
	}
	
	public static var pool = {
		var p = new hxd.Pool<ChannelLowLevel>(ChannelLowLevel);
		//p.actives = null;
		p;
	}
	
	public static function alloc(data : FmodChannelRef, ?name ){
		var s = pool.alloc();
		
		s.reset();
		
		s.data = data;
		s.name = name == null?EMPTY_STRING:name;
		
		return s;
	}
	
	public static function delete( c : ChannelLowLevel){
		c.dispose();
		pool.delete(c);
	}
	
	public function getData(){
		return data;
	}	
	
	public override function poolBack(){
		super.poolBack();
		ChannelLowLevel.delete(this);
	}
	
	public override function stop(){
		if (data != null) data.stop();
		super.stop();
	}
	
	public override function pause(){
		super.pause();
		if(data!=null) data.setPaused(true);
	}
	
	public override function resume(){
		super.resume();
		if(data!=null) data.setPaused(false);
	}
	
	public override function dispose(){
		super.dispose();
		data = null;
	}
	
	public override function isPlaying(){
		if ( completed ) return false;
		
		if (data == null) {
			//#if !prod
			//trace("no data no playing! "+name);
			//#end
			return false;
		}
		var b : Bool = false;
		var res = data.isPlaying( Cpp.addr(b));
		if ( res != FMOD_OK ){
			//#if debug
			//trace("[SND][ChannelLowLevel]{"+name+"} isPlaying err " + FaxeRef.fmodResultToString(res));
			//#end
			return false;
		}
		return b;
	}
	
	//returns in secs
	public override  function getPlayCursorSec() : Float {
		if (data == null) return 0.0;
		
		var pos : cpp.UInt32 = 0;
		var res = data.getPosition( Cpp.addr(pos), faxe.Faxe.FmodTimeUnit.FTM_MS );
		var posF : Float = 1.0 * pos * 1000.0;
		return posF;
	}
	
	//returns in secs
	public override function getPlayCursorMs() : Float {
		if (data == null) return 0.0;
		
		var pos : cpp.UInt32 = 0;
		var res = data.getPosition( Cpp.addr(pos), faxe.Faxe.FmodTimeUnit.FTM_MS );
		return 1.0 * pos;
	}

	
	public override function setPlayCursorMs(posMs:Float) {
		if (data == null) return;
		
		if ( posMs < 0.0) posMs = 0.0;
		var posU : cpp.UInt32 = 0;
		posU = Math.round( posMs );
		var res = data.setPosition( posU, FmodTimeUnit.FTM_MS );
		if ( res != FMOD_OK){
			//#if debug
			//trace("[SND][Channel]{"+name+"} Repositionning S err " + FaxeRef.fmodResultToString(res)+" to :"+posU+" ("+posMs+")");
			//#end
		}
	}
	
	public override function setNbLoops(nb:Int){
		if (data == null) return;
		data.setMode(FmodMode.FMOD_LOOP_NORMAL);
		data.setLoopCount(nb);
	}
	
	public override function getVolume():Float{
		if (data == null) return 0.0;
		
		var vol : cpp.Float32 = 0.0;
		var res = data.getVolume( Cpp.addr(vol) );
		if ( res != FMOD_OK){
			//#if debug
			//trace("[SND][Channel]{"+name+"} getVolume err " + FaxeRef.fmodResultToString(res));
			//#end
		}
		return vol;
	}
	
	public override function setVolume(v:Float){
		if (data == null) {
			//if ( isDebug ){
				//#if !prod
				//trace("[SND][Channel]{"+name+"} setVolume no data");
				//#end
			//}
			return;
		}
		
		var vcl = hxd.Math.clamp(v, 0, 1);
		var res = data.setVolume( vcl );
		if ( res != FMOD_OK){
			//#if !prod
			//trace("[SND][Channel]{"+name+"} setVolume err " + FaxeRef.fmodResultToString(res));
			//#end
		}
		else {
			if ( isDebug ){
				//#if !prod
				//trace("[SND][Channel]{"+name+"} setVolume ok " + v+" corrected:"+vcl);
				//#end
			}
		}
	}
	
	
}

class Sound {
	/**
	 * length is in seconds
	 */
	public var name = "";
	public var length(get, null) 						: Float;
	public var id3 	: Dynamic							= null;
	public var isDebug = false;
	
	var disposed = false;
	
	function new( ?name:String=null ){
		disposed = false;
	}
	
	function get_length() : Float{
		return 0.0;
	}
	
	//returns in msec
	public function getDuration(): Float{
		return getDurationMs();
	}
	
	public function getDurationSec() : Float{
		return length;
	}
	
	public function getDurationMs() : Float{
		return length * 1000.0;
	}
	
	public function dispose(){
		if (disposed) return;
		disposed = true;
	}
	
	public function play( ?offsetMs : Float = 0.0, ?nbLoops:Int = 1, ?volume:Float = 1.0 ) : Channel {
		return null;
	}
}

class SoundLowLevel extends Sound{
	
	public var data : FmodSoundRef					 	= null;
	
	public function new( data : cpp.Pointer<faxe.Faxe.FmodSound>, ?name:String = null ){
		super(name);
		this.data = Cpp.ref(data);
	}
	
	public function getData(){
		return data;
	}
	
	public override function dispose(){
		super.dispose();
		
		if ( Snd.released ) {
			data = null;
			return;
		}
		
		if(data!=null)
			data.release();
		data = null;
	}
	
	//returns in secs
	override function get_length() : Float{
		if (disposed) return 0.0;
		
		var pos : cpp.UInt32 = 0;
		var res = data.getLength( Cpp.addr(pos), FmodTimeUnit.FTM_MS );
		if ( res != FMOD_OK ){
			#if debug
			//trace("impossible to retrieve sound len");
			#end
		}
		var posF = 1.0 * pos / 1000.0;
		return posF;
	}
	
	public override function play( ?offsetMs : Float = 0.0, ?nbLoops:Int = 1, ?volume:Float = 1.0) : Channel {
		var nativeChan : FmodChannelRef = FaxeRef.playSoundWithHandle( data , false);
		var chan = ChannelLowLevel.alloc( nativeChan, name );
		
		#if debug
		//trace("[Sound] offset " + offsetMs);
		//trace("play " + haxe.Timer.stamp() );
		#end
		
		@:privateAccess chan.started = true;
		@:privateAccess chan.completed = false;
		@:privateAccess chan.disposed = false;
		@:privateAccess chan.paused = false;
		
		
		if( offsetMs != 0.0 ) 	chan.setPlayCursorMs( offsetMs );
		if( volume != 1.0 ) 	chan.setVolume( volume );
		if( nbLoops > 1 ) 		chan.setNbLoops( nbLoops );
		
		return chan;
	}
}


class SoundEvent extends Sound{
	
	public var data : FmodStudioEventDescriptionRef	= null;
	
	public function new( data : FmodStudioEventDescriptionRef, ?name:String = null ){
		super(name);
		this.data = data;
	}
	
	public override function dispose(){
		super.dispose();
		
		if ( Snd.released ) {
			data = null;
			return;
		}
		
		if ( data != null){
			data.releaseAllInstances();
			data = null;
		}
	}
	public function getData(){
		return data;
	}
	
	//returns in secs
	override function get_length() : Float{
		if (disposed) return 0.0;
		
		var pos : Int = 0;
		var res = data.getLength( Cpp.addr(pos) );
		if ( res != FMOD_OK ){
			//#if !prod
			//trace("impossible to retrieve sound len");
			//#end
		}
		var posF = 1.0 * pos / 1000.0;
		return posF;
	}
	
	public override function play( ?offsetMs : Float = 0.0, ?nbLoops:Int = 1, ?volume:Float = 1.0) : Channel{
		var nativeInstance : FmodStudioEventInstanceRef = data.createInstance();
		var chan = ChannelEventInstance.alloc( nativeInstance, name );
		
		//#if !prod
		//trace("play " + haxe.Timer.stamp() );
		//#end
		nativeInstance.start();
		
		@:privateAccess chan.started = true;
		@:privateAccess chan.completed = false;
		@:privateAccess chan.disposed = false;
		@:privateAccess chan.paused = false;
		
		if( offsetMs != 0.0 ) 	chan.setPlayCursorMs( offsetMs );
		if( volume != 1.0 ) 	chan.setVolume( volume );
		
		return chan;
	}
}

class Snd {
	public static var EMPTY_STRING = "";
	public static var 	PLAYING 		: hxd.Stack<Snd> 	= new hxd.Stack();
	static var 	MUTED 									= false;
	static var 	DISABLED		 						= false;
	static var 	GLOBAL_VOLUME 							= 1.0;
	static var 	TW 										= new SndTV();
	
	public var 	name			: String				;
	public var 	pan						: Float					= 0.0;
	public var 	volume(default,set) 	: Float 				= 1.0;
	public var 	curPlay 		: Null<Channel> 		= null;
	public var 	bus				= otherBus;	
	public var  isDebug = true;
	/**
	 * for when stop is called explicitly
	 * allows disposal
	 */
	public var 	onStop 									= new hxd.Signal();
	public var 	sound 		: Sound						= null;
		
	var onEnd				: Null<Void->Void>			= null;
	static var fmodSystem 	: FmodSystemRef				= null;
	
	public static var otherBus = new SndBus();
	public static var sfxBus = new SndBus();
	public static var musicBus = new SndBus();
	
	public function new( snd : Sound, ?name:String ) {
		volume = 1;
		pan = 0;
		sound = snd;
		muted = false;
		this.name = name==null?EMPTY_STRING:name;
	}
	
	public function isLoaded() {
		return sound!=null;
	}
	
	//does not dispose sound, only instanced
	public function stop(){
		
		TW.terminate(this);//prevent reentrancy of fadeStop() stop() not cutting any sound
		
		PLAYING.remove(this);
		
		if ( isPlaying() && !onStop.isTriggering )
			onStop.trigger();
			
		if ( curPlay != null){
			curPlay.dispose();
			curPlay.poolBack();
			curPlay = null;
			#if !prod
			//trace(name+" stopped");
			//Lib.showStack();
			#end
		}
		
		//bus = otherBus;
	}
	
	public function dispose(){
		//#if !prod
		//trace(name+" disposing");
		//#end
		
		if ( isPlaying() ){
			stop();
		}
		
		if ( curPlay != null){
			curPlay.dispose();
			curPlay.poolBack();
			curPlay = null;
			//#if !prod
			//trace(name+" disposed");
			//#end
		}
		
		if ( sound != null) {
			sound.dispose();
			sound = null;
		}
		
		onStop.dispose();
		
		onEnd = null;
		curPlay = null;
	}
	
	/**
	 * 
	 * @return in ms
	 */
	public inline function getPlayCursor() : Float {
		if ( curPlay == null) return 0.0;
		return curPlay.getPlayCursorMs();
	}
	
	
	public function play(?vol:Float, ?pan:Float) : Snd {
		if( vol == null ) 		vol = volume;
		if( pan == null )		pan = this.pan;

		start(0, vol, 0.0);
		
		return this;
	}
	
	/**
	 * launches the sound, stops previous and rewrite the cur play dropping it into oblivion for the gc
	 */
	public function start(loops:Int=0, vol:Float=1.0, ?startOffsetMs:Float=0.0) {
		if ( DISABLED ) 			{
			//#if debug
			//trace("[SND] Disabled");
			//#end
			return;
		}
		if ( sound == null ){
			//#if debug
			//trace("[SND] no inner sound");
			//#end
			return;
		}

		if ( isPlaying() ){
			//#if !prod
			//trace(name+" interrupting ");
			//#end
			
			stop();
		}
			
		TW.terminate(this);
		
		this.volume = vol;
		this.pan = normalizePanning(pan);
		
		PLAYING.push(this);
		curPlay = sound.play( startOffsetMs, loops, getRealVolume());
		
		if ( curPlay == null){
			//#if !prod
			//trace(" play missed?");
			//#end
		}
		else {
			//#if !prod
			//trace("started");
			//#end
		}
	}
	
	/**
	 * launches the sound and rewrite the cur play dropping it into oblivion for the gc
	 */
	public function startNoStop(?loops:Int=0, ?vol:Float=1.0, ?startOffsetMs:Float=0.0) : Null<Channel>{
		if ( DISABLED ) 			{
			//#if debug
			//trace("[SND] Disabled");
			//#end
			return null;
		}
		if ( sound == null ){
			//#if debug
			//trace("[SND] no inner sound");
			//#end
			return null;
		}
		
		this.volume = vol;
		this.pan = normalizePanning(pan);
		
		curPlay = sound.play( startOffsetMs, loops, getRealVolume());
		
		return curPlay;
	}
	
	public inline function getDuration() {
		return getDurationMs();
	}
	
	public inline function getDurationSec() {
		return sound.length;
	}
	
	/**
	 * returns in ms
	 */
	public inline function getDurationMs() {
		return sound.length * 1000.0;
	}
	
	public static inline 
	function trunk(v:Float, digit:Int) : Float{
		var hl = Math.pow( 10.0 , digit );
		return Std.int( v * hl ) / hl;
	}
	
	public static function dumpMemory(){
		var v0 : Int = 0;
		var v1 : Int = 0;
		var v2 : Int = 0;
		
		var v0p : cpp.Pointer<Int> = Cpp.addr(v0);
		var v1p : cpp.Pointer<Int> = Cpp.addr(v1);
		var v2p : cpp.Pointer<Int> = Cpp.addr(v2);
		var str = "";
		var res = fmodSystem.getSoundRAM( v0p, v1p, v2p );
		if ( res != FMOD_OK){
			//#if debug
			//trace("[SND] cannot fetch snd ram dump ");
			//#end
		}
		
		inline function f( val :Float) : Float{
			return trunk(val, 2);
		}
		
		if( v2 > 0 ){
			str+="fmod Sound chip RAM all:" + f(v0 / 1024.0) + "KB \t max:" + f(v1 / 1024.0) + "KB \t total: " + f(v2 / 1024.0) + " KB\r\n";
		}
		
		v0 = 0;
		v1 = 0;
		
		var res = FaxeRef.Memory_GetStats( v0p, v1p, false );
		str += "fmod Motherboard chip RAM all:" + f(v0 / 1024.0) + "KB \t max:" + f(v1 / 1024.0) + "KB \t total: " + f(v2 / 1024.0) + " KB";
		return str;
	}
	
	public function playLoop(?loops = 9999, ?vol:Float=1.0, ?startOffset = 0.0) : Snd {
		if( vol==null )
			vol = volume;

		start(loops, vol, startOffset);
		return this;
	}
	
	function set_volume(v:Float) {
		volume = v;
		refresh();
		return volume;
	}
	
	public function setVolume(v:Float) {
		set_volume(v);
	}
	
	public inline function getRealPanning() {
		return pan;
	}

	public function setPanning(p:Float) {
		pan = p;
		refresh();
	}

	public function onEndOnce(cb:Void->Void) {
		onEnd = cb;
	}
	
	public function fadePlay(?fadeDuration = 100, ?endVolume:Float=1.0 ) {
		var p = play(0.0001);
		if ( p == null ){
			//trace("nothing ret");
		}
		else {
			if ( p.curPlay == null){
				//trace("no curplay wtf?");
			}
			else 
			{
				//trace("curplay ok");
			}
		}
		tweenVolume(endVolume, fadeDuration);
		return p;
	}
	
	public function fadePlayLoop(?fadeDuration = 100, ?endVolume:Float=1.0 , ?loops=9999) {
		var p = playLoop(loops,0);
		tweenVolume(endVolume, fadeDuration);
		return p;
	}
	
	public function fadeStop( ?fadeDuration = 100 ) {
		if ( !isPlaying()){
			//#if !prod
			//trace("not playing " + name+" winn not unfade");//can cause reentrancy issues
			//#end
			return null;
		}
		
		isDebug = true;
		var t = tweenVolume(0, fadeDuration);
		t.onEnd = _stop;
		return t;
	}
	
	public var muted : Bool = false;
	
	public function toggleMute() {
		muted = !muted;//todo
		setVolume(volume);
	}
	public function mute() {
		muted = true;
		setVolume(volume);
	}
	public function unmute() {
		muted = false;
		setVolume(volume);
	}
	
	public function isPlaying(){
		if ( curPlay == null ){
			#if !prod
			//trace("no curplay");
			#end
			return false;
		}
		return curPlay.isPlaying();
	}
	
	public static function init(){
		#if debug
		trace("[Snd] fmod init");
		#end
		Faxe.fmod_init( 256 );
		fmodSystem = FaxeRef.getSystem();
		released = false;
	}
	
	public static var released = true;
	
	public static function release(){
		TW.terminateAll();
		for (s in PLAYING)
			s.dispose();
		PLAYING.hardReset();
		released = true;
		//trace("releasing fmod");
		Faxe.fmod_release();
		#if !prod
		trace("fmod released");
		#end
	}
	
	public static function setGlobalVolume(vol:Float) {
		GLOBAL_VOLUME = normalizeVolume(vol);
		refreshAll();
	}
	
	function refresh() {
		if ( curPlay != null ) {
			var vol = getRealVolume();
			//trace("r:"+vol);
			curPlay.setVolume( vol );
		}
		else {
			//#if debug
			//trace("[Snd] no playin no refresh "+name);
			//#end
		}
	}
	
	public function	setPlayCursorSec( pos:Float ) 	{
		if (curPlay != null)	{
			curPlay.setPlayCursorSec(pos);
		}
		else {
			//#if debug
			//trace("setPlayCursorSec/no current instance");
			//#end
		}
	}
	
	public function	setPlayCursorMs( pos:Float ){ 
		if (curPlay != null) 	
			curPlay.setPlayCursorMs(pos);
		else {
			//#if debug
			//trace("setPlayCursorMs/no current instance");
			//#end
		}
	}
	
	public function tweenVolume(v:Float, ?easing:h2d.Tweenie.TType, ?milliseconds:Float=100) : TweenV {
		if ( easing == null ) easing = h2d.Tweenie.TType.TEase;
		var t = TW.create(this, TVVVolume, v, easing, milliseconds);
		//#if !prod 
		//trace("tweening " + name+" to " + v);
		//#end
		return t;
	}
	
	public function tweenPan(v:Float, ?easing:h2d.Tweenie.TType, ?milliseconds:Float=100) : TweenV {
		if ( easing == null ) easing = h2d.Tweenie.TType.TEase;
		var t = TW.create(this, TVVPan, v, easing, milliseconds);
		return t;
	}
	
	public inline function getRealVolume() {
		var v = volume * GLOBAL_VOLUME * (DISABLED?0:1) * (MUTED?0:1) * (muted?0:1) * bus.volume;
		if ( v <= 0.001)
			v = 0.0;
		return normalizeVolume(v);
	}
	
	static inline function normalizeVolume(f:Float) {
		return hxd.Math.clamp(f, 0,1);
	}

	static inline function normalizePanning(f:Float) {
		return hxd.Math.clamp(f, -1,1);
	}
	
	static var _stop = function(t:TweenV){
		#if !prod
		//if( t.parent != null )
			//trace(t.parent.name+" cbk stopped");
		//else 
			//trace(" unbound stop called");
		#end
		t.parent.stop();
	}
	
	static var _refresh = function(t:TweenV) {
		
		//avoid unwanted crash
		if ( released ){
			//#if !prod
			//trace("sorry released");
			//#end
			return;
		}
		
		t.parent.refresh();
	}
	
	static function refreshAll() {
		for(s in PLAYING)
			s.refresh();
	}
	
	function onComplete(){
		//#if debug
		//trace("onComplete " + haxe.Timer.stamp());
		//#end
		
		if (curPlay != null) {
			curPlay.onComplete();
		}
		
		stop();
	}
	
	public function isComplete(){
		if ( curPlay == null ) {
			//#if!prod
			//trace("comp: no cur play");
			//#end
			return true;
		}
		return curPlay.isComplete();
	}
	
	//////////////////////////////////////
	/////////////////////STATICS//////////
	//////////////////////////////////////
	
	public static var DEBUG_TRACK = false;
	
	//@:noDebug
	public static function loadSound( path:String, streaming : Bool, blocking : Bool  ) : Sound {
		
		if ( released ) {
			//#if(!prod)
			//trace("FMOD not active "+path);
			//#end
			return null;
		}
		
		var mode = FMOD_DEFAULT;
		
		if ( streaming ) 	mode |= FMOD_CREATESTREAM;
		if ( !blocking ) 	mode |= FMOD_NONBLOCKING;
			
		mode |= FmodMode.FMOD_2D;
		
		
		if( DEBUG_TRACK) trace("Snd:loading " + path);
		
		var snd : cpp.RawPointer<faxe.Faxe.FmodSound> = cast  null;
		var sndR :  cpp.RawPointer<cpp.RawPointer<faxe.Faxe.FmodSound>> = cpp.RawPointer.addressOf(snd);
		
		#if switch
		if ( !path.startsWith("rom:"))
			path = "rom://" + path;
		#end
		
		var res : FmodResult = fmodSystem.createSound( 
			Cpp.cstring(path),
			mode,
			Cpp.nullptr(),
			sndR
		);
			
		if ( res != FMOD_OK){
			#if(!prod)
			trace("unable to load " + path + " code:" + res+" msg:"+FaxeRef.fmodResultToString(res));
			#end
			return null;
		}
		
		var n:String = null;
		
		#if debug
		n  = new bm.Path(path).getFilename();
		#end
			
		return new SoundLowLevel(cpp.Pointer.fromRaw(snd),n);
	}
	
	public static function loadEvent( path:String ) : Sound {
		if ( released ) {
			//#if (!prod) 
			//trace("FMOD not active "+path);
			//#end
			return null;
		}
		
		
		if( DEBUG_TRACK) trace("Snd:loadingEvent " + path);
		
		if ( !path.startsWith("event:/"))
			path = "event:/" + path;
		
		var fss : FmodStudioSystemRef = faxe.FaxeRef.getStudioSystem();
		var ev = fss.getEvent( path);
		
		if ( ev == null ) return null;
		
		if ( !ev.isLoaded() ){
			var t0 = haxe.Timer.stamp();
			ev.loadSampleData();
			var t1 = haxe.Timer.stamp();
			#if debug
			//trace("time to preload:" + (t1 - t0));
			#end
		}
		
		return new SoundEvent( ev, path);
	}
	
	public static function fromFaxe( path:String ) : Snd {
		if ( released ) {
			//#if (!prod) 
			//trace("FMOD not active "+path);
			//#end
			return null;
		}
		
		var s : cpp.Pointer<FmodSound> = faxe.Faxe.fmod_get_sound(path );
		if ( s == null){
			#if (!prod)
			trace("unable to find " + path);
			#end
			return null;
		}
		
		var n:String = null;
		
		#if debug
		n  = new bm.Path(path).getFilename();
		#end
		
		return new Snd( new SoundLowLevel(s,n), path);
	}
	
	public static function loadSfx( path:String ) : Snd {
		var s : Sound = loadSound(path, false, false);
		if ( s == null) return null;
		return new Snd( s, s.name);
	}
	
	public static function loadSong( path:String ) : Snd {
		var s : Sound = loadSound(path, true, true);
		if ( s == null) return null;
		return new Snd( s,  s.name);
	}
	
	public static function load( path:String, streaming=false,blocking=true ) : Snd {
		var s : Sound = loadSound(path, streaming, blocking);
		if ( s == null) {
			#if !prod
			trace("no such file " + path);
			#end
			return null;
		}
		return new Snd( s,  s.name);
	}
	
	public static function terminateTweens() {
		TW.terminateAll();
	}
	
	public static function update() {
		for ( p in PLAYING.backWardIterator())
			if ( p.isComplete()){
				#if !prod
				//trace("[Snd] isComplete " + p);
				#end
				p.onComplete();
			}
		TW.update();//let tweens complete
		
		if(!released ) Faxe.fmod_update();
	}
	
	public static function loadSingleBank( filename : String ) : Null<faxe.Faxe.FmodStudioBankRef>{
		if ( released ) {
			#if debug 
			trace("FMOD not active "+filename);
			#end
			return null;
		}
		
		if ( filename.endsWith(".fsb")) {
			#if debug 
			trace("fsb files not supported");
			#end
			return null;//old fmod format is not supported
		}
		
		var t0 = haxe.Timer.stamp();
		var fsys = FaxeRef.getStudioSystem();
		var fbank : cpp.RawPointer < FmodStudioBank > = null;
		
		//trace("trying to load " + filename);
		
		Lib.loadMode();
		var result = fsys.loadBankFile( 
			cpp.ConstCharStar.fromString( filename ), 
			FmodStudioLoadBank.FMOD_STUDIO_LOAD_BANK_NONBLOCKING, 
			cpp.RawPointer.addressOf(fbank));
		Lib.playMode();	
		
		if (result != FMOD_OK)	{
			#if debug
			trace("FMOD failed to LOAD sound bank with errcode:" + result + " errmsg:" + FaxeRef.fmodResultToString(result) + "\n");
			#end
			return null;
		}
		//else 
		//	trace("loading...");
			
		var t1 = haxe.Timer.stamp();
		#if debug
		//trace("time to load bank:" + (t1 - t0)+"s");
		#end
		return cast fbank;
	}
}