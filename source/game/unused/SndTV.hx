import h2d.Tweenie.TType;

//praise delahee, i'll figure out what this shit means later!

enum TVVar{
	TVVVolume;
	TVVPan;
}

@:publicFields
class TweenV {
	static var GUID = 0;
	var uid 		= 0;
	
	var man 		: SndTV;	 
	var parent		: Snd;
	var n			: Float;
	var ln			: Float;
	var speed		: Float;
	var from		: Float;
	var to			: Float;
	var type		: TType;
	var plays		: Int; // -1 = infini, 1 et plus = nombre d'exécutions (1 par défaut)
	var varType		: TVVar; 
	var onUpdate	: Null<TweenV->Void>;
	var onEnd		: Null<TweenV->Void>;
	var isDebug		= false;
	
	public inline function new (
		parent:Snd	 ,
	    n:Float		 ,
	    ln:Float	 ,
		varType:TVVar,
	    speed:Float	 ,
	    from:Float	 ,
	    to:Float	 ,
	    type:h2d.Tweenie.TType ,
	    plays		 ,
	    onUpdate	 ,
	    onEnd		 
	) {
		this.parent			= parent		;
		this.n			    = n			 	;
		this.ln			    = ln			;
		this.varType 		= varType 		;
		this.speed		    = speed			;
		this.from		    = from			;
		this.to			    = to			;
		this.type		    = type		 	;
		this.plays		    = plays		 	;
		this.onUpdate	    = onUpdate	 	;
		this.onEnd		    = onEnd		 	;
	}
	
	public inline function reset(
		parent:Snd	 ,
	    n:Float		 ,
	    ln:Float	 ,
		varType:TVVar,
	    speed:Float	 ,
	    from:Float	 ,
	    to:Float	 ,
	    type:TType	 ,
	    plays:Int	 ,
	    onUpdate	 ,
	    onEnd		 
	) {
		this.parent			= parent		;
		this.n			    = n			 	;
		this.ln			    = ln			;
		this.speed		    = speed			;
		this.from		    = from			;
		this.to			    = to			;
		this.type		    = type		 	;
		this.plays		    = plays		 	;
		this.onUpdate	    = onUpdate	 	;
		this.onEnd		    = onEnd		 	;
		this.varType 		= varType 		;
		isDebug		= false;
		uid = GUID++;
	}
	
	public function clear(){
		n 			= 0.0;
		ln			= 0.0;
		speed 		= 0.0;
		plays		= 0;
		from		= 0.0;
		to			= 0.0;
		parent = null;
		onEnd = null;
		onUpdate = null;
		isDebug		= false;
		uid = GUID++;
	}
	
	
	public 
	inline
	function apply( val ) {
		switch(varType){
			case TVVVolume: {
				parent.volume = val;
				#if debug
				if( isDebug )
				trace("tv:" + val);
				#end
			}
			case TVVPan: 	parent.pan = val;
		}
		
	}
	
	public inline function kill( withCbk = true ) {
		if ( withCbk )	
			man.terminateTween( this );
		else 
			man.forceTerminateTween( this) ;
	}
	
}

/**
 * tween order is not respected
 */
class SndTV {
	static var DEFAULT_DURATION = DateTools.seconds(1);
	public var fps 				= 60.0;
	public var isDebug			= false;

	var tlist					: hxd.Stack<TweenV>;

	public function new() {
		tlist = new hxd.Stack<TweenV>();
		tlist.reserve(8);
	}
	
	function onError(e) {
		trace(e);
	}
	
	public function count() {
		return tlist.length;
	}
	
	public inline function create(parent:Snd, vartype:TVVar, to:Float, ?tp:h2d.Tweenie.TType, ?duration_ms:Float) : TweenV{
		return create_(parent, vartype, to, tp, duration_ms);
	}
	
	public function exists(p:Snd) {
		for (t in tlist)
			if (t.parent == p )
				return true;
		return false;
	}
	
	public var pool : hxd.Stack<TweenV> = new hxd.Stack();

	function create_(p:Snd, vartype:TVVar,to:Float, ?tp:h2d.Tweenie.TType, ?duration_ms:Float) : TweenV{
		if ( duration_ms==null )
			duration_ms = DEFAULT_DURATION;

		#if debug
		if ( p == null ) trace("tween2 creation failed to:"+to+" tp:"+tp);
		#end
			
		if ( tp==null ) tp = TEase;

		{
			// on supprime les tweens précédents appliqués à la même variable
			for(t in tlist.backWardIterator())
				if(t.parent==p && t.varType == vartype) {
					forceTerminateTween(t);
				}
		}
		
		var from = switch( vartype ){
			case TVVVolume 	: p.volume;
			case TVVPan 	: p.pan;
		}
		var t : TweenV;
		if (pool.length == 0){
			t = new TweenV(
				p,
				0.0,
				0.0,
				vartype,
				1 / ( duration_ms*fps/1000 ), // une seconde
				from,
				to,
				tp,
				1,
				null,
				null
			);
		}
		else {
			t = pool.pop();
			t.reset(
				p,
				0.0,
				0.0,
				vartype,
				1 / ( duration_ms*fps/1000 ), // une seconde
				from,
				to,
				tp,
				1,
				null,
				null
			); 
			
		}

		if( t.from==t.to )
			t.ln = 1; // tweening inutile : mais on s'assure ainsi qu'un update() et un end() seront bien appelés

		t.man = this;
		tlist.push(t);

		return t;
	}

	public static inline 
	function fastPow2(n:Float):Float {
		return n*n;
	}
	
	public static inline 
	function fastPow3(n:Float):Float {
		return n*n*n;
	}

	public static inline 
	function bezier(t:Float, p0:Float, p1:Float,p2:Float, p3:Float) {
		return
			fastPow3(1-t)*p0 +
			3*( t*fastPow2(1-t)*p1 + fastPow2(t)*(1-t)*p2 ) +
			fastPow3(t)*p3;
	}
	
	// suppression du tween sans aucun appel aux callbacks onUpdate, onUpdateT et onEnd (!)
	public function killWithoutCallbacks(parent:Snd) {
		for (t in tlist.backWardIterator())
			if (t.parent==parent ){
				forceTerminateTween(t);
				return true;
			}
		return false;
	}
	
	public function terminate(parent:Snd) {
		for (t in tlist.backWardIterator())
			if (t.parent==parent){
				forceTerminateTween(t);
			}
	}
	
	public function forceTerminateTween(t:TweenV) {
		var tOk = tlist.remove(t);
		if( tOk ){
			t.clear();
			pool.push(t);
		}
	}
	
	public function terminateTween(t:TweenV, ?fl_allowLoop=false) {
		var v = t.from + (t.to - t.from) * h2d.Tweenie.interp(t.type, 1);
		t.apply(v);
		onUpdate(t, 1);
		
		var ouid = t.uid;
		
		onEnd(t);
		
		if( ouid == t.uid ){
			if( fl_allowLoop && (t.plays==-1 || t.plays>1) ) {
				if( t.plays!=-1 )
					t.plays--;
				t.n = t.ln = 0;
			}
			else {
				forceTerminateTween(t);
			}
		}
	}
	
	public function terminateAll() {
		for(t in tlist)
			t.ln = 1;
		update();
	}
	
	inline
	function onUpdate(t:TweenV, n:Float) {
		if ( t.onUpdate!=null )
			t.onUpdate(t);
	}
	
	inline
	function onEnd(t:TweenV) {
		if ( t.onEnd!=null )
			t.onEnd(t);
	}
	
	public function update(?tmod = 1.0) {
		if ( tlist.length > 0 ) {
			for (t in tlist.backWardIterator() ) {
				var dist = t.to-t.from;
				if (t.type==TRand)
					t.ln+=if(Std.random(100)<33) t.speed * tmod else 0;
				else
					t.ln += t.speed * tmod;
					
				t.n = h2d.Tweenie.interp(t.type, t.ln);
				
				if ( t.ln<1 ) {
					// en cours...
					var val = t.from + t.n*dist;
					
					t.apply(val);
					
					onUpdate(t, t.ln);
				}
				else // fini !
				{
					terminateTween(t, true);
				}
			}
		}
	}
}