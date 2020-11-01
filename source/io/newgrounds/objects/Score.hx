package io.newgrounds.objects;

/** We don't want to serialize scores since there's a bajillion of them. */
typedef Score = {
	
	/** The value value in the format selected in your scoreboard settings. */
	var formatted_value:String;
	
	/** The tag attached to this value (if any). */
	var tag:String;
	
	/** The user who earned value. If this property is absent, the value belongs to the active user. */
	var user:User;
	
	/** The integer value of the value. */
	var value:Int;
}