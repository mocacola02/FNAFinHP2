class MOCARandomSoundSource extends Actor;

var() Sound SoundToPlay;
var() ESoundSlot SlotToPlayOn;

var() int Probability;
var() int CheckInterval;


event PostBeginPlay()
{
	StartCheckTimer();
}

function StartCheckTimer()
{
	SetTimer(CheckInterval, true, 'HandlePlaySound');
}

function StopCheckTimer()
{
	SetTimer(0, false, 'HandlePlaySound');
}

function bool IsPlayingSound()
{
	local int i;
	for ( i = 0; i < PlayingSounds.Length; i++ )
	{
		if ( PlayingSounds[i].Sound == SoundToPlay )
		{
			return true;
		}
	}

	return false;
}

function HandlePlaySound()
{
	if ( SoundToPlay == None || IsPlayingSound() )
	{
		Log("Invalid sound or we're already playing sound");
		return;
	}

	if ( Probability > 1 )
	{
		local int rnd;
		rnd = Rand(Probability);

		Log("Rolled a " $ rnd $ " to play sound");

		if ( rnd != 0 )
		{
			return;
		}
	}

	Log("Playing sound " $ SoundToPlay $ " on slot " $ SlotToPlayOn);
	PlaySound(SoundToPlay, SlotToPlayOn);
}


defaultproperties
{
	SlotToPlayOn=SLOT_Foley
	Probability=30
	CheckInterval=1

	bHidden=True

	SoundRadius=1024
	TransientSoundRadius=1024
}