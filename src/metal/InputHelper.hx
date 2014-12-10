package metal;

class InputHelper{
	public static function ask( question : String, ?passwd : Bool = false ) {
		Sys.print(question+" : ");
		if( passwd ) {
			var s = new StringBuf();
			do switch Sys.getChar(false) {
				case 10, 13: break;
				case c: s.addChar(c);
			}
			while (true);
			Sys.println("");
			return s.toString();
		}
		return Sys.stdin().readLine();
	}
}