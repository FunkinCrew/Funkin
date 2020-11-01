package io.newgrounds.components;
class ComponentList {
	
	var _core:NGLite;
	
	// --- COMPONENTS
	public var medal     : MedalComponent;
	public var app       : AppComponent;
	public var event     : EventComponent;
	public var scoreBoard: ScoreBoardComponent;
	public var loader    : LoaderComponent;
	public var gateway   : GatewayComponent;
	
	public function new(core:NGLite) {
		
		_core = core;
		
		medal      = new MedalComponent     (_core);
		app        = new AppComponent       (_core);
		event      = new EventComponent     (_core);
		scoreBoard = new ScoreBoardComponent(_core);
		loader     = new LoaderComponent    (_core);
		gateway    = new GatewayComponent   (_core);
	}
}
