package metal;

import haxe.Json;
import sys.FileSystem;
import sys.io.File;

class Main extends mcli.CommandLine{

	public static function main()
    {
        new mcli.Dispatch(Sys.args()).dispatch(new Main());
    }

    public var loud:Bool;


    public function help()
    {
        Sys.println(this.showUsage());
        Sys.exit(0);
    }

    public function runDefault()
    {
    	var metalJsonPath = "metal.json";
    	if(!FileSystem.exists(metalJsonPath)){
    		metalJsonPath = "haxelib.json";
    		if(!FileSystem.exists(metalJsonPath)){
    			Sys.println("cannot find metal.json or haxelib.json in current folder");
    			Sys.exit(1);
    		}
    	} 

    	var meta : Metal = Json.parse(File.getContent(metalJsonPath));

    	var tmpFolder = "_haxelibs_";
    	try{
    		FileSystem.deleteDirectory(tmpFolder);	
    	}catch(e : Dynamic){
    		Sys.println("error deleting the tmp folder " + tmpFolder);
    	}
    	try{

    		FileSystem.createDirectory(tmpFolder);	
    	}catch(e: Dynamic){
    		Sys.println("error creating the tmp folder " + tmpFolder);
    		Sys.exit(1);
    	}
    	

    	for (libName in meta.libs.keys()){
    		var lib = meta.libs[libName];
    		var filePath = meta.classPath + "/" + libName;
    		if(FileSystem.isDirectory(filePath) && FileSystem.exists(filePath + "/haxelib.json")){
    			var destination = tmpFolder + "/" + libName + "/" + libName;
    			FileSystem.createDirectory(destination);
    			FileHelper.copyFolder(filePath, destination);
    			FileSystem.rename(destination + "/haxelib.json", tmpFolder + "/" + libName + "/haxelib.json");
    			ZipHelper.zipFolder(tmpFolder + "/" + libName + ".zip", tmpFolder +"/" + libName);
    		}
    	}

        
    }

}