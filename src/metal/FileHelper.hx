package metal;

import sys.FileSystem;
import sys.io.File; //TODO move out

class FileHelper{

	public static function copyFolder(srcPath : String, dstPath : String) {
		FileSystem.createDirectory(dstPath);
		var files = FileSystem.readDirectory(srcPath);
		for (fileName in files){
			var filePath = srcPath + "/" + fileName;
			var destination = dstPath + "/" + fileName;
			if (FileSystem.isDirectory(filePath)){
				copyFolder(filePath, destination);
			}else{
				File.copy(filePath, destination);				
			}
		}
	}

	public static function recursiveReadFolder(folderPath : String, ?root : String = "", ?filePaths : Array<String> = null) : Array<String>{
		if(filePaths == null){
			filePaths = new Array<String>();
		}
		var files = FileSystem.readDirectory(folderPath);
		for (fileName in files){
			var filePath = folderPath + "/" + fileName;
			if (FileSystem.isDirectory(filePath)){
				recursiveReadFolder(filePath, root + fileName + "/", filePaths);
			}else{
				filePaths.push(root + fileName);				
			}
		}
		return filePaths;
	}


	public static function deleteDirectory(path : String):Void{
		var files = FileSystem.readDirectory(path);
	    
	    for( ff in files){
	    	var filePath = path + "/" + ff;
	    	if (FileSystem.isDirectory(filePath)){
	    		deleteDirectory(filePath);
    		}else{
    			FileSystem.deleteFile(filePath);
    		}
		    
	    }
	    FileSystem.deleteDirectory(path);
	}

	public static function findInFiles(path : String, substring : String) : Bool{
		var files = FileSystem.readDirectory(path);
	    
	    for( ff in files){
	    	var filePath = path + "/" + ff;
	    	if (FileSystem.isDirectory(filePath)){
	    		if (findInFiles(filePath, substring)){
	    			return true;
	    		}
    		}else{
    			var content = File.getContent(filePath);
    			if(content.indexOf(substring) != -1){
    				return true;
    			}
    		}
		    
	    }
	    return false;
	}
}