package flixel.mobile;

import flixel.group.FlxSpriteGroup;
import flixel.mobile.FlxButton;
import flixel.util.FlxColor;
import flixel.util.FlxDestroyUtil;
import flixel.FlxG;
import openfl.display.BitmapData;
import openfl.display.Shape;

/**
 * A zone with 4 hint's (A hitbox).
 * It's really easy to customize the layout.
 *
 * @author Mihai Alexandru (MAJigsaw77)
 */
class FlxHitbox extends FlxSpriteGroup
{
	/**
	 * The array containing the hitbox's hints (buttons).
	 */
	public var hints(default, null):Array<FlxButton> = [];

	/**
	 * Create the zone.
	 * 
	 * @param ammo The ammount of hints you want to create.
	 * @param perHintWidth The width that the hints will use.
	 * @param perHintHeight The height that the hints will use.
	 * @param colors The color per hint.
	 */
	public function new(ammo:UInt, perHintWidth:Int, perHintHeight:Int, colors:Array<FlxColor>):Void
	{
		super();

		if (colors == null || (colors != null && colors.length < ammo))
			colors = [for (i in 0...ammo) 0xFFFFFF];

		for (i in 0...ammo)
			add(hints[i] = createHint(i * perHintWidth, 0, perHintWidth, perHintHeight, colors[i]));

		scrollFactor.set();
	}

	/**
	 * Clean up memory.
	 */
	override public function destroy():Void
	{
		super.destroy();

		for (i in 0...hints.length)
			hints[i] = FlxDestroyUtil.destroy(hints[i]);

		hints.splice(0, hints.length);
	}

	private function createHint(x:Float, y:Float, width:Int, height:Int, color:Int = 0xFFFFFF):FlxButton
	{
		var hint:FlxButton = new FlxButton(x, y);
		hint.loadGraphic(createHintGraphic(width, height, color));
		hint.solid = false;
		hint.multiTouch = true;
		hint.immovable = true;
		hint.scrollFactor.set();
		hint.alpha = 0.00001;
		hint.onDown.callback = hint.onOver.callback = function()
		{
			if (hint.alpha != 0.2)
				hint.alpha = 0.2;
		}
		hint.onUp.callback = hint.onOut.callback = function()
		{
			if (hint.alpha != 0.00001)
				hint.alpha = 0.00001;
		}
		#if FLX_DEBUG
		hint.ignoreDrawDebug = true;
		#end
		return hint;
	}

	private function createHintGraphic(width:Int, height:Int, color:Int = 0xFFFFFF):BitmapData
	{
		var shape:Shape = new Shape();
		shape.graphics.beginFill(color);
		shape.graphics.lineStyle(3, color, 1);
		shape.graphics.drawRect(0, 0, width, height);
		shape.graphics.endFill();

		var bitmap:BitmapData = new BitmapData(width, height, true, 0);
		bitmap.draw(shape, true);
		return bitmap;
	}
}
