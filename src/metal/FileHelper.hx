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

}