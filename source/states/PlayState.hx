package states;

import Section.SwagSection;
import Song.SwagSong;
import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.math.FlxMath;
import flixel.math.FlxRect;
import flixel.sound.FlxSound;
import flixel.tweens.FlxTween;
import flixel.ui.FlxBar;
import flixel.util.FlxSort;

using StringTools;

class PlayState extends MusicBeatState
{
	public static var instance:PlayState;
	public static var curStage:String = 'sex';
	public static var daPixelZoom:Float = 6;
	public static var SONG:SwagSong;

	public var camHUD:FlxCamera;
	public var healthBarBG:FlxSprite;
	public var healthBar:FlxBar;
	public var health:Float = 1;
	public var camGame:FlxCamera;
	public var notes:FlxTypedGroup<Note>;
	public var unspawnNotes:Array<Note> = [];

	public var strumLineNotes:FlxTypedGroup<FlxSprite>;

	public static var downscroll:Bool = false;

	public var cpuStrums:FlxTypedGroup<FlxSprite>;

	public var playerStrums:FlxTypedGroup<FlxSprite>;

	public var strumLine:FlxSprite;

	var generatedMusic:Bool = false;
	var paused:Bool = false;
	var cpuControlled = false;

	override public function create()
	{
		super.create();

		camGame = new SwagCamera();
		camHUD = new FlxCamera();
		camHUD.bgColor.alpha = 0;
		FlxG.cameras.reset(camGame);
		FlxG.cameras.add(camHUD, false);

		strumLineNotes = new FlxTypedGroup<FlxSprite>();
		notes = new FlxTypedGroup<Note>();

		playerStrums = new FlxTypedGroup<FlxSprite>();

		cpuStrums = new FlxTypedGroup<FlxSprite>();
		add(strumLineNotes);

		musicshitInit('hard', 'bopeebo');
		generateStaticArrows(0);
		generateStaticArrows(1);
		var y = FlxG.height * 0.9;
		if (downscroll)
			y = FlxG.height * 0.1;

		healthBarBG = new FlxSprite(0, y).loadGraphic(Paths.image('healthBar'));
		healthBarBG.screenCenter(X);
		healthBarBG.scrollFactor.set();
		add(healthBarBG);

		//	if (PreferencesMenu.getPref('downscroll'))
		//	healthBarBG.y = FlxG.height * 0.1;

		healthBar = new FlxBar(healthBarBG.x + 4, healthBarBG.y + 4, RIGHT_TO_LEFT, Std.int(healthBarBG.width - 8), Std.int(healthBarBG.height - 8), this,
			'health', 0, 2);
		healthBar.scrollFactor.set();
		healthBar.createFilledBar(0xFFFF0000, 0xFF66FF33);
		// healthBar
		add(healthBar);
		strumLineNotes.cameras = [camHUD];
		notes.cameras = [camHUD];
		healthBar.cameras = [camHUD];
		healthBarBG.cameras = [camHUD];
		strumLine.cameras = [camHUD];
		add(notes);
	}

	override function onFocusLost()
	{
		super.onFocusLost();
	}

	function resyncVocals():Void
	{
		if (_exiting)
			return;
	}

	function musicshitInit(diff, song)
	{
		var y = 50.0;
		if (downscroll)
		{
			y = FlxG.height * 0.75;
		}

		SONG = Song.loadFromJson(song + "-" + diff, song);
		strumLine = new FlxSprite(0, y).makeGraphic(FlxG.width, 1);
		add(strumLine);

		strumLine.scrollFactor.set();

		// if (SONG == null)

		Conductor.mapBPMChanges(SONG);
		Conductor.changeBPM(SONG.bpm);

		FlxG.sound.playMusic(Paths.inst(SONG.song), 1, false);

		var noteData:Array<SwagSection>;

		// NEW SHIT
		var songData = SONG;
		noteData = songData.notes;

		for (section in noteData)
		{
			for (songNotes in section.sectionNotes)
			{
				var daStrumTime:Float = songNotes[0];
				var daNoteData:Int = Std.int(songNotes[1] % 4);

				var gottaHitNote:Bool = section.mustHitSection;

				if (songNotes[1] > 3)
					gottaHitNote = !section.mustHitSection;

				var oldNote:Note;
				if (unspawnNotes.length > 0)
					oldNote = unspawnNotes[Std.int(unspawnNotes.length - 1)];
				else
					oldNote = null;

				var swagNote:Note = new Note(daStrumTime, daNoteData, oldNote);
				swagNote.sustainLength = songNotes[2];
				swagNote.altNote = songNotes[3];
				swagNote.scrollFactor.set(0, 0);

				var susLength:Float = swagNote.sustainLength;

				susLength = susLength / Conductor.stepCrochet;
				unspawnNotes.push(swagNote);

				for (susNote in 0...Math.floor(susLength))
				{
					oldNote = unspawnNotes[Std.int(unspawnNotes.length - 1)];

					var sustainNote:Note = new Note(daStrumTime + (Conductor.stepCrochet * susNote) + Conductor.stepCrochet, daNoteData, oldNote, true);
					sustainNote.scrollFactor.set();
					unspawnNotes.push(sustainNote);

					sustainNote.mustPress = gottaHitNote;

					if (sustainNote.mustPress)
						sustainNote.x += FlxG.width / 2; // general offset
				}

				swagNote.mustPress = gottaHitNote;

				if (swagNote.mustPress)
					swagNote.x += FlxG.width / 2; // general offset
			}
		}

		unspawnNotes.sort(sortByShit);

		generatedMusic = true;
	}

	public static function getDownscroll()
	{
		return downscroll;
	}

	function worstSpawningCrap()
	{
		var strumTime:Float = 2000;
		for (currentNumber in 0...100)
		{
			strumTime += 100;
			var daStrumTime:Float = strumTime;
			var daNoteData:Int = Std.int(FlxG.random.int(0, 3) % 4);

			var oldNote:Note;
			if (unspawnNotes.length > 0)
				oldNote = unspawnNotes[Std.int(unspawnNotes.length - 1)];
			else
				oldNote = null;

			var swagNote:Note = new Note(daStrumTime, daNoteData, oldNote);
			swagNote.sustainLength = 0;
			swagNote.altNote = false;
			swagNote.scrollFactor.set(0, 0);
			swagNote.mustPress = false;

			var susLength:Float = swagNote.sustainLength;

			susLength = susLength / Conductor.stepCrochet;
			unspawnNotes.push(swagNote);
			trace(currentNumber);
		}
	}

	function sortByShit(Obj1:Note, Obj2:Note):Int
	{
		return sortNotes(FlxSort.ASCENDING, Obj1, Obj2);
	}

	function sortNotes(order:Int = FlxSort.ASCENDING, Obj1:Note, Obj2:Note)
	{
		return FlxSort.byValues(order, Obj1.strumTime, Obj2.strumTime);
	}

	var previousFrameTime:Int = 0;
	var songTime:Float = 0;

	override public function update(elapsed:Float)
	{
		// + Conductor.offset; // 20 is THE MILLISECONDS??
		// Conductor.songPosition += FlxG.elapsed * 1000;
		camHUD.zoom = FlxMath.lerp(1.05, camHUD.zoom, 0.8);
		// Conductor.lastSongPos = FlxG.sound.music.time;
		while (unspawnNotes[0] != null && unspawnNotes[0].strumTime - Conductor.songPosition < 1800 / SONG.speed)
		{
			var dunceNote:Note = unspawnNotes[0];
			notes.add(dunceNote);

			var index:Int = unspawnNotes.indexOf(dunceNote);
			unspawnNotes.shift();
		}

		if (FlxG.sound.music.playing)
			Conductor.songPosition = FlxG.sound.music.time;
		super.update(elapsed);
		if (generatedMusic)
		{
			notes.forEachAlive(function(daNote:Note)
			{
				if ((downscroll && daNote.y < -daNote.height) || (!downscroll && daNote.y > FlxG.height))
				{
					daNote.active = false;
					daNote.visible = false;
				}
				else
				{
					daNote.visible = true;
					daNote.active = true;
				}
				var strum:FlxSprite = strumLineNotes.members[daNote.noteData % 4];
				// daNote.x = strum.x;
				if (daNote.mustPress && daNote.wasGoodHit || !daNote.mustPress && daNote.wasGoodHit)
					noteClip(daNote);
				if (daNote.canMove)
				{
					switch (downscroll)
					{
						case true:
							daNote.y = (strumLine.y + (Conductor.songPosition - daNote.strumTime) * (0.45 * FlxMath.roundDecimal(SONG.speed, 2)));

						default:
							daNote.y = (strumLine.y - (Conductor.songPosition - daNote.strumTime) * (0.45 * FlxMath.roundDecimal(SONG.speed, 2)));
					}
				}
				if (!daNote.mustPress && daNote.wasGoodHit && !daNote.isSustainNote)
				{
					cpuStrums.forEach(function(spr:FlxSprite)
					{
						if (Math.abs(daNote.noteData) == spr.ID)
						{
							// spr.animation.play('confirm', true);
							daNote.canMove = false;
						}
					});
					invalidateNote(daNote);
				}
				if (daNote.tooLate)
				{
					invalidateNote(daNote);
				}
			});
			keyShit();
		}
	}

	public function noteClip(daNote:Note)
	{
		var center = strumLine.y + Note.swagWidth / 2;
		if (downscroll)
		{
			if (daNote.y - daNote.offset.y * daNote.scale.y + daNote.height >= center)
			{
				var swagRect = new FlxRect(0, 0, daNote.frameWidth, daNote.frameHeight);
				swagRect.height = (center - daNote.y) / daNote.scale.y;
				swagRect.y = daNote.frameHeight - swagRect.height;

				daNote.clipRect = swagRect;
			}
		}
		else
		{
			if (daNote.y + daNote.offset.y * daNote.scale.y <= center)
			{
				var swagRect = new FlxRect(0, 0, daNote.width / daNote.scale.x, daNote.height / daNote.scale.y);
				swagRect.y = (center - daNote.y) / daNote.scale.y;
				swagRect.height -= swagRect.y;

				daNote.clipRect = swagRect;
			}
		}
	}

	public function invalidateNote(daNote:Note)
	{
		daNote.kill();
		notes.remove(daNote, true);
		daNote.destroy();
		if (!daNote.mustPress) {}
	}

	override function beatHit()
	{
		super.beatHit();
		sortingnBpmChangeShit();

		if (camHUD.zoom < 1.35 && curBeat % 4 == 0)
		{
			camHUD.zoom += 0.0095;
		}
	}

	override function stepHit()
	{
		super.stepHit();
	}

	function sortingnBpmChangeShit()
	{
		if (generatedMusic)
		{
			notes.sort(sortNotes, FlxSort.DESCENDING);
		}

		if (SONG.notes[Math.floor(curStep / 16)] != null)
		{
			if (SONG.notes[Math.floor(curStep / 16)].changeBPM)
			{
				Conductor.changeBPM(SONG.notes[Math.floor(curStep / 16)].bpm);
				FlxG.log.add('CHANGED BPM!');
			}
			// else
			// Conductor.changeBPM(SONG.bpm);
		}
	}

	public function generateStaticArrows(player:Int):Void
	{
		for (i in 0...4)
		{
			// FlxG.log.add(i);
			var babyArrow:FlxSprite = new FlxSprite(0, strumLine.y);
			switch (curStage)
			{
				case 'ass' | 'schoolEvil':
					babyArrow.loadGraphic(Paths.image('weeb/pixelUI/arrows-pixels'), true, 17, 17);
					babyArrow.animation.add('green', [6]);
					babyArrow.animation.add('red', [7]);
					babyArrow.animation.add('blue', [5]);
					babyArrow.animation.add('purplel', [4]);

					babyArrow.setGraphicSize(Std.int(babyArrow.width * daPixelZoom));
					babyArrow.updateHitbox();
					babyArrow.antialiasing = false;

					switch (Math.abs(i))
					{
						case 0:
							babyArrow.x += Note.swagWidth * 0;
							babyArrow.animation.add('static', [0]);
							babyArrow.animation.add('pressed', [4, 8], 12, false);
							babyArrow.animation.add('confirm', [12, 16], 24, false);
						case 1:
							babyArrow.x += Note.swagWidth * 1;
							babyArrow.animation.add('static', [1]);
							babyArrow.animation.add('pressed', [5, 9], 12, false);
							babyArrow.animation.add('confirm', [13, 17], 24, false);
						case 2:
							babyArrow.x += Note.swagWidth * 2;
							babyArrow.animation.add('static', [2]);
							babyArrow.animation.add('pressed', [6, 10], 12, false);
							babyArrow.animation.add('confirm', [14, 18], 12, false);
						case 3:
							babyArrow.x += Note.swagWidth * 3;
							babyArrow.animation.add('static', [3]);
							babyArrow.animation.add('pressed', [7, 11], 12, false);
							babyArrow.animation.add('confirm', [15, 19], 24, false);
					}

				default:
					babyArrow.frames = Paths.getSparrowAtlas('NOTE_assets');
					babyArrow.animation.addByPrefix('green', 'arrowUP');
					babyArrow.animation.addByPrefix('blue', 'arrowDOWN');
					babyArrow.animation.addByPrefix('purple', 'arrowLEFT');
					babyArrow.animation.addByPrefix('red', 'arrowRIGHT');

					babyArrow.antialiasing = true;
					babyArrow.setGraphicSize(Std.int(babyArrow.width * 0.7));

					switch (Math.abs(i))
					{
						case 0:
							babyArrow.x += Note.swagWidth * 0;
							babyArrow.animation.addByPrefix('static', 'arrow static instance 1');
							babyArrow.animation.addByPrefix('pressed', 'left press', 24, false);
							babyArrow.animation.addByPrefix('confirm', 'left confirm', 24, false);
						case 1:
							babyArrow.x += Note.swagWidth * 1;
							babyArrow.animation.addByPrefix('static', 'arrow static instance 2');
							babyArrow.animation.addByPrefix('pressed', 'down press', 24, false);
							babyArrow.animation.addByPrefix('confirm', 'down confirm', 24, false);
						case 2:
							babyArrow.x += Note.swagWidth * 2;
							babyArrow.animation.addByPrefix('static', 'arrow static instance 4');
							babyArrow.animation.addByPrefix('pressed', 'up press', 24, false);
							babyArrow.animation.addByPrefix('confirm', 'up confirm', 24, false);
						case 3:
							babyArrow.x += Note.swagWidth * 3;
							babyArrow.animation.addByPrefix('static', 'arrow static instance 3');
							babyArrow.animation.addByPrefix('pressed', 'right press', 24, false);
							babyArrow.animation.addByPrefix('confirm', 'right confirm', 24, false);
						case 4:
							babyArrow.x += Note.swagWidth * 0;
							babyArrow.animation.addByPrefix('static', 'arrow static instance 1');
							babyArrow.animation.addByPrefix('pressed', 'left press', 24, false);
							babyArrow.animation.addByPrefix('confirm', 'left confirm', 24, false);
						case 5:
							babyArrow.x += Note.swagWidth * 1;
							babyArrow.animation.addByPrefix('static', 'arrow static instance 2');
							babyArrow.animation.addByPrefix('pressed', 'down press', 24, false);
							babyArrow.animation.addByPrefix('confirm', 'down confirm', 24, false);
						case 6:
							babyArrow.x += Note.swagWidth * 2;
							babyArrow.animation.addByPrefix('static', 'arrow static instance 4');
							babyArrow.animation.addByPrefix('pressed', 'up press', 24, false);
							babyArrow.animation.addByPrefix('confirm', 'up confirm', 24, false);
						case 7:
							babyArrow.x += Note.swagWidth * 3;
							babyArrow.animation.addByPrefix('static', 'arrow static instance 3');
							babyArrow.animation.addByPrefix('pressed', 'right press', 24, false);
							babyArrow.animation.addByPrefix('confirm', 'right confirm', 24, false);
					}
			}

			babyArrow.updateHitbox();
			babyArrow.scrollFactor.set();

			babyArrow.ID = i;

			switch (player)
			{
				case 0:
					cpuStrums.add(babyArrow);
					babyArrow.animation.finishCallback = function(name)
					{
						if (name == 'pressed')
							babyArrow.animation.play('static');
					};

				case 1:
					playerStrums.add(babyArrow);
			}

			babyArrow.animation.play('static');
			babyArrow.x += 50;
			babyArrow.x += ((FlxG.width / 2) * player);

			strumLineNotes.add(babyArrow);
		}
	}

	public function keyShit()
	{
		// control arrays, order L D R U
		var holdArray:Array<Bool> = [
			FlxG.keys.pressed.LEFT,
			FlxG.keys.pressed.DOWN,
			FlxG.keys.pressed.UP,
			FlxG.keys.pressed.RIGHT
		];
		var pressArray:Array<Bool> = [
			FlxG.keys.justPressed.LEFT,
			FlxG.keys.justPressed.DOWN,
			FlxG.keys.justPressed.UP,
			FlxG.keys.justPressed.RIGHT
		];
		var releaseArray:Array<Bool> = [
			FlxG.keys.justReleased.LEFT,
			FlxG.keys.justReleased.DOWN,
			FlxG.keys.justReleased.UP,
			FlxG.keys.justReleased.RIGHT
		];

		// HOLDS, check for sustain notes
		if (holdArray.contains(true) && /*!boyfriend.stunned && */ generatedMusic)
		{
			notes.forEachAlive(function(daNote:Note)
			{
				if (daNote.isSustainNote && daNote.canBeHit && daNote.mustPress && holdArray[daNote.noteData])
					goodNoteHit(daNote);
			});
		}

		// PRESSES, check for note hits
		if (pressArray.contains(true) && /*!boyfriend.stunned && */ generatedMusic)
		{
			// boyfriend.holdTimer = 0;

			var possibleNotes:Array<Note> = []; // notes that can be hit
			var directionList:Array<Int> = []; // directions that can be hit
			var dumbNotes:Array<Note> = []; // notes to kill later

			notes.forEachAlive(function(daNote:Note)
			{
				if (daNote.canBeHit && daNote.mustPress && !daNote.tooLate && !daNote.wasGoodHit)
				{
					if (directionList.contains(daNote.noteData))
					{
						for (coolNote in possibleNotes)
						{
							if (coolNote.noteData == daNote.noteData && Math.abs(daNote.strumTime - coolNote.strumTime) < 10)
							{ // if it's the same note twice at < 10ms distance, just delete it
								// EXCEPT u cant delete it in this loop cuz it fucks with the collection lol
								dumbNotes.push(daNote);
								break;
							}
							else if (coolNote.noteData == daNote.noteData && daNote.strumTime < coolNote.strumTime)
							{ // if daNote is earlier than existing note (coolNote), replace
								possibleNotes.remove(coolNote);
								possibleNotes.push(daNote);
								break;
							}
						}
					}
					else
					{
						possibleNotes.push(daNote);
						directionList.push(daNote.noteData);
					}
				}
			});

			for (note in dumbNotes)
			{
				FlxG.log.add("killing dumb ass note at " + note.strumTime);
				note.kill();
				notes.remove(note, true);

				note.destroy();
			}

			possibleNotes.sort(sortByShit);

			// if (perfectMode)
			// goodNoteHit(possibleNotes[0]);
			if (possibleNotes.length > 0)
			{
				for (coolNote in possibleNotes)
				{
					if (pressArray[coolNote.noteData])
						goodNoteHit(coolNote);
				}
			}
			else
			{
				for (shit in 0...pressArray.length)
					if (pressArray[shit])
						noteMiss(shit);
			}
		}

		playerStrums.forEach(function(spr:FlxSprite)
		{
			if (pressArray[spr.ID] && spr.animation.curAnim.name != 'confirm' && !cpuControlled)
				spr.animation.play('pressed');
			if (!holdArray[spr.ID]
				&& !cpuControlled
				|| cpuControlled
				&& spr.animation.curAnim.name == 'confirm'
				&& spr.animation.curAnim.finished)
				spr.animation.play('static');

			if (spr.animation.curAnim.name == 'confirm' && !curStage.startsWith('ass'))
			{
				spr.centerOffsets();
				spr.offset.x -= 13;
				spr.offset.y -= 13;
			}
			else
				spr.centerOffsets();
		});
		cpuStrums.forEach(function(spr:FlxSprite)
		{
			if (spr.animation.curAnim.name == 'confirm' && spr.animation.curAnim.finished)
				spr.animation.play('static');

			if (spr.animation.curAnim.name == 'confirm' && !curStage.startsWith('ass'))
			{
				spr.centerOffsets();
				spr.offset.x -= 13;
				spr.offset.y -= 13;
			}
			else
				spr.centerOffsets();
		});
	}

	function noteMiss(direction:Int = 1):Void
	{
		// whole function used to be encased in if (!boyfriend.stunned)
		health -= 0.04;
		// killCombo();

		// if (!practiceMode)
		//	songScore -= 10;
		// misses += 1;
		// vocals.volume = 0;
		// FlxG.sound.play(Paths.soundRandom('missnote', 1, 3), FlxG.random.float(0.1, 0.2));

		/* boyfriend.stunned = true;

			// get stunned for 5 seconds
			new FlxTimer().start(5 / 60, function(tmr:FlxTimer)
			{
				boyfriend.stunned = false;
		});*/
	}

	function goodNoteHit(note:Note):Void
	{
		if (!note.wasGoodHit)
		{
			if (!note.isSustainNote)
			{
				// combo += 1;
				// popUpScore(note.strumTime, note);
			}

			if (note.noteData >= 0)
				health += 0.023;
			else
				health += 0.004;

			playerStrums.forEach(function(spr:FlxSprite)
			{
				if (Math.abs(note.noteData) == spr.ID)
				{
					spr.animation.play('confirm', true);
				}
			});

			note.wasGoodHit = true;
			// vocals.volume = 1;

			if (!note.isSustainNote)
			{
				invalidateNote(note);
			}
		}
	}
}
