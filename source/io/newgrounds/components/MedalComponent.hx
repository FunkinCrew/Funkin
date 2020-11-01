package io.newgrounds.components;

import io.newgrounds.objects.events.Result;
import io.newgrounds.Call;
import io.newgrounds.NGLite;

class MedalComponent extends Component {
	
	public function new(core:NGLite):Void { super(core); }
	
	public function unlock(id:Int):Call<MedalUnlockResult> {
		
		return new Call<MedalUnlockResult>(_core, "Medal.unlock", true, true)
			.addComponentParameter("id", id);
	}
	
	public function getList():Call<MedalListResult> {
		
		return new Call<MedalListResult>(_core, "Medal.getList");
	}
}