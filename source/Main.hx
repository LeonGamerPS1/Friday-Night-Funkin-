package;

import flixel.FlxG;
import flixel.FlxGame;
import metashit.FPS_Mem;
import openfl.display.Sprite;

class Main extends Sprite
{
	public function new()
	{
		super();
		//	PlayerSettings.init();

		addChild(new FlxGame(0, 0, states.PlayState, 66, 66, true, false));
		var fps_mem:FPS_Mem = new FPS_Mem(10, 10, 0xffffff);

		addChild(fps_mem);
		FlxG.sound.cacheAll();
	}
}
