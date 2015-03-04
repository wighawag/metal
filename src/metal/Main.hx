package metal;

import haxe.Json;
import metal.Haxelib.HaxelibDependencies;
import metal.InputHelper;
import sys.FileSystem;
import sys.io.File;

using StringTools;

class Main extends mcli.CommandLine{

	public static function main()
    {
        new mcli.Dispatch(Sys.args()).dispatch(new Main());
    }

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
        if(FileSystem.exists(tmpFolder)){
            try{
                FileHelper.deleteDirectory(tmpFolder);  
            }catch(e : Dynamic){
                Sys.println("error deleting the tmp folder " + tmpFolder);
                Sys.exit(1);
            }    
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
            if(!FileSystem.exists(filePath) || !FileSystem.isDirectory(filePath)){
                Sys.println("no directory at " + filePath);
                Sys.exit(1);
            }
    	}

        var fileNames = FileSystem.readDirectory(meta.classPath);
        for (fileName in fileNames){
            var filePath = meta.classPath + "/" + fileName;
            if(FileSystem.isDirectory(filePath)){
                if(!meta.libs.exists(fileName)){
                    Sys.println("Library " + fileName + " not registered in metal.json/haxelib.json file");
                    Sys.println("Please fill in the form");
                    var descritpion = InputHelper.ask("description");
                    var tags = InputHelper.ask("tags (separated by commas)").split(",");
                    for (i in 0...tags.length){
                        tags[i] = tags[i].trim();
                    }
                    var dependencyStrings = InputHelper.ask("dependencies (separated by commas and specified via <name>:<version>)").split(",");
                    for (i in 0...dependencyStrings.length){
                        dependencyStrings[i] = dependencyStrings[i].trim();
                    }
                    var url = InputHelper.ask("url (press enter to use meta lib url)");
                    var dependencies : HaxelibDependencies = {};
                    for (depString in dependencyStrings){
                        var split = depString.split(":");
                        if(split.length > 1){
                            dependencies[split[0]] = split[1];
                        }else{
                            dependencies[split[0]] = "";
                        }
                    }
                    if(url == null || url == ""){
                        meta.libs[fileName] = {
                            description : descritpion,
                            tags : tags,
                            dependencies : dependencies
                        }    
                    }else{
                        meta.libs[fileName] = {
                            description : descritpion,
                            tags : tags,
                            dependencies : dependencies,                       
                            url:url
                        }
                    }
                    
                    
                }
            }
        }

        for(libName in meta.libs.keys()){
            var regex = new EReg("\\b" + libName + "\\..+", "");
            for(otherLibName in meta.libs.keys()){
                if(otherLibName != libName){
                    var folderPath = meta.classPath + "/" + otherLibName;
                    var filePaths = FileHelper.recursiveReadFolder(folderPath);
                    for(filePath in filePaths){
                        if(StringTools.endsWith(filePath, ".hx")){
                            var content = File.getContent(folderPath + "/" + filePath);
                            if(regex.match(content)){
                                trace("found " + libName + " in " + otherLibName);
                            }
                        }
                    }
                }
            }
        }

        File.saveContent(metalJsonPath,Json.stringify(meta,null, "  "));

        //var meta : Metal = Json.parse(File.getContent(metalJsonPath));

        for(libName in meta.libs.keys()){
            var lib = meta.libs[libName];
            var filePath = meta.classPath + "/" + libName;
            var destination = tmpFolder + "/" + libName + "/src/" + libName;
            FileSystem.createDirectory(destination);
            FileHelper.copyFolder(filePath, destination);
            var haxelibFilePath = tmpFolder + "/" + libName + "/haxelib.json";
            var haxelibJsonString = haxe.Json.stringify(HaxelibUtil.createHaxelibConfiguration(filePath, libName, meta, "test", "0.0.1"), "  ");
            File.saveContent(haxelibFilePath, haxelibJsonString);
            ZipHelper.zipFolder(tmpFolder + "/" + libName + ".zip", tmpFolder +"/" + libName);
        }

        
    }


}