package metal;

import haxe.DynamicAccess;
typedef SubLib = {
	tags : Array<String>,
	description : String,
	?dependencies : Array<String>,
	?url:String,
};

typedef Metal = {
	name : String,
	license : String,
	contributors : Array<String>,
	version : String,
	releasenote:String,
	url : String,
	libs : DynamicAccess<SubLib>,
	classPath : String,
	?dependencies : DynamicAccess<String>
};
