package io.newgrounds.components;

import io.newgrounds.objects.events.Result;
import io.newgrounds.objects.events.Result.SessionResult;
import io.newgrounds.NGLite;

class AppComponent extends Component {
	
	public function new (core:NGLite) { super(core); }
	
	public function startSession(force:Bool = false):Call<SessionResult> {
		
		return new Call<SessionResult>(_core, "App.startSession")
			.addComponentParameter("force", force, false);
	}
	
	public function checkSession():Call<SessionResult> {
		
		return new Call<SessionResult>(_core, "App.checkSession", true);
	}
	
	public function endSession():Call<SessionResult> {
		
		return new Call<SessionResult>(_core, "App.endSession", true);
	}
	
	public function getCurrentVersion(version:String):Call<GetCurrentVersionResult> {
	
		return new Call<GetCurrentVersionResult>(_core, "App.getCurrentVersion")
			.addComponentParameter("version", version);
	}
	
	public function getHostLicense():Call<GetHostResult> {
		
		return new Call<GetHostResult>(_core, "App.getHostLicense")
			.addComponentParameter("host", _core.host);
	}
	
	public function logView():Call<ResultBase> {
		
		return new Call<ResultBase>(_core, "App.logView")
			.addComponentParameter("host", _core.host);
	}
}