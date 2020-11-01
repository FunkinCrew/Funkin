package io.newgrounds.objects;

typedef User = {
	
	/** The user's icon images. */
	var icons:UserIcons;
	
	/** The user's numeric ID. */
	var id:Int;
	
	/** The user's textual name. */ 
	var name:String;
	
	/** Returns true if the user has a Newgrounds Supporter upgrade. */ 
	var supporter:Bool;
	
	/** The user's NG profile url. */
	var url:String;
}
