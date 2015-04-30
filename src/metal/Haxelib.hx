package metal;

import haxe.DynamicAccess;

typedef HaxelibDependencies = DynamicAccess<String>;

typedef Haxelib = {
	name : String,
	license : String,
	description : String,
	contributors : Array<String>,
	releasenote : String,
	version : String,
	url : String,
	?classPath : String,
	dependencies : HaxelibDependencies,
	tags : Array<String>
};
