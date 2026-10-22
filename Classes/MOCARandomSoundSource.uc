class MOCARandomSoundSource extends Actor;

var() Sound SoundToPlay;
var() ESoundSlot SlotToPlayOn;

var() int Probability;
var() int CheckInterval;


function StartCheckTimer()
{
	SetTimer(CheckInterval, true, 'HandlePlaySound');
}

function StopCheckTimer()
{
	SetTimer(0, false, 'HandlePlaySound');
}

function HandlePlaySound()
{
	if ( SoundToPlay == None || SoundSlotOccupied(SlotToPlayOn) )
	{
		return;
	}

	if ( Probability > 1 )
	{
		local int rnd;
		rnd = Rand(Probability);

		if ( rnd != 0 )
		{
			return;
		}
	}

	PlaySound(SoundToPlay, SlotToPlayOn);
}


defaultproperties
{
	SlotToPlayOn=SLOT_Ambient
	Probability=30
	CheckInterval=1
}