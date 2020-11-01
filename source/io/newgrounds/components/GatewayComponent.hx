package io.newgrounds.components;

import io.newgrounds.objects.events.Result;
import io.newgrounds.NGLite;

class GatewayComponent extends Component {
	
	public function new (core:NGLite){ super(core); }
	
	public function getDatetime():Call<GetDateTimeResult> {
		
		return new Call<GetDateTimeResult>(_core, "Gateway.getDatetime");
	}
	
	public function getVersion():Call<GetVersionResult> {
		
		return new Call<GetVersionResult>(_core, "Gateway.getVersion");
	}
	
	public function ping():Call<PingResult> {
		
		return new Call<PingResult>(_core, "Gateway.ping");
	}
	
}