package metal;

import haxe.DynamicAccess;
typedef SubLib = {
	tags : Array<String>,
	description : String,
	?dependencies : DynamicAccess<String>,
	?url:String
};

typedef Metal = {
	license : String,
	contributors : Array<String>,
	last_version : String,
	url : String,
	libs : DynamicAccess<SubLib>,
	classPath : String
};
