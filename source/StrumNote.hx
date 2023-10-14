package;

import flixel.FlxSprite;

using StringTools;

class StrumNote extends FlxSprite
{
	public var resetAnim:Float = 0;

	private var noteData:Int = 0;

	public function new(x:Float, y:Float, leData:Int)
	{
		noteData = leData;

		super(x, y);
	}

	override function update(elapsed:Float)
	{
		if (resetAnim > 0)
		{
			resetAnim -= elapsed;

			if (resetAnim <= 0)
			{
				playAnim('static');
				resetAnim = 0;
			}
		}

		super.update(elapsed);
	}

	public function playAnim(anim:String, ?force:Bool = false)
	{
		animation.play(anim, force);

		updateHitbox();

		offset.set(frameWidth / 2, frameHeight / 2);

		offset.x -= 156 * Note.scales[PlayState.SONG.mania] / 2;
		offset.y -= 156 * Note.scales[PlayState.SONG.mania] / 2;
	}
}
