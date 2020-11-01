package io.newgrounds.components;

import io.newgrounds.objects.events.Result.LogEventResult;
import io.newgrounds.NGLite;

class EventComponent extends Component {
	
	public function new (core:NGLite){ super(core); }
	
	public function logEvent(eventName:String):Call<LogEventResult> {
		
		return new Call<LogEventResult>(_core, "Event.logEvent")
			.addComponentParameter("event_name", eventName)
			.addComponentParameter("host", _core.host);
	}
}