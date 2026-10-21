class MOCANightManager extends Actor;

const ANIMATRONIC_COUNT = 4;
const NUM_OF_HOURS = 6;
const ZERO_POWER = 0;
const FOXY_DRAIN_BASE = 1;
const FOXY_DRAIN_INCREMENT = 5;
const FEAR_VOLUME_INCREMENT = 64;
const MAX_NIGHTS = 7;

const BONNIE = 0;
const CHICA = 1;
const FOXY = 2;
const FREDDY = 3;

struct AIValues
{
	var() int AILevel[4];
}

var() int NightLength;		// How long in seconds are nights
var() int InitialPower;		// How much power do you start with

var() name StartNightEvent;
var() name EndNightEvent;
var() name DeathEvent;

var() MOCAAnimatronic Animatronics[4];

var() Sound RegularAmbSFX;
var() Sound OfficeAmbSFX;
var() Sound ScaryAmbSFX;
var() Sound CameraAmbSFX;
var() Sound LightSFX;
var() Sound DoorSFX;
var() Sound JumpscareSFX;
var() Sound FoxyHumSFX;
var() Sound CarnivalSFX;
var() Sound ThumpingSFX;
var() Sound PowerOutSFX;
var() Sound MusicBoxSFX;
var() Sound FreddyLaughSFX;
var() Sound FoxyRunningSFX;
var() Sound WarbledVoiceSFX;
var() Sound CallDialogSFX[5];
var() Array<Sound> FootstepSFX;
var() Array<Sound> CameraOutageSFX;
var() Array<Sound> KitchenSFX;
var() Array<Sound> TheyGotInSFX;

var() Actor RegularAmbSource;	// Moca: Actor to play the regular ambience on
var() Actor OfficeAmbSource;	// Moca: Actor to play the office ambience on
var() Actor ScaryAmbSource;		// Moca: Actor to play the scary ambience on
var() Actor CameraAmbSource;	// Moca: Actor to play the camera ambience on
var() Actor LightSource1;		// Moca: Actor to play the left light on
var() Actor LightSource2;		// Moca: Actor to play the right light on
var() Actor DoorSource1;		// Moca: Actor to play the left door on
var() Actor DoorSource2;		// Moca: Actor to play the right door on
var() Actor CarnivalSource;		// Moca: Actor to play the carnival music on
var() Actor ThumpingSource;		// Moca: Actor to play the thumping on
var() Actor PowerOutSource;		// Moca: Actor to play the power out on
var() Actor CallSource;			// Moca: Actor to play the phone call on

var() Array<MOCASecurityCamera> Cameras;
var() Array<Texture> CameraTextures;

var int CurrNight;			// Moca: Current night (1 - 7)
var int NightTime;			// Moca: Current night time

var int CurrPower;			// Moca: Current power level
var int PowerLossFreq;		// Moca: How frequently to lose power
var int CurrPowerLossInc;	// Moca: Current increment number for power loss timing

var int FoxyHits;

var int FearLevel;

// All fixed arrays are ordered as Bonnie, Chica, Foxy, Freddy

var float MoveInterval[4];		// Moca: How often each animatronic gets a movement opportunity
var float CurrentMoveTime[4]; 	// Moca: Current time each animatronic is at for their move interval.

var AIValues CurrAILevel;		// Moca: Current AI level of each animatronic
var AIValues AIPerNight[7];		// Moca: Base AI level of each animation for each night


//=================
// Power Handling
//=================

function SetPowerLevel(int PowerLevel)
{
	CurrPower = PowerLevel;
}

function DeincrementPower()
{
	SetPowerLevel(CurrPower - 1);
}

function IncrementFoxyHits()
{
	FoxyHits++;
}

function int GetFoxyPowerDrain()
{
	return FOXY_DRAIN_BASE + (FOXY_DRAIN_INCREMENT * FoxyHits);
}

function bool ShouldLosePower()
{
	return CurrPowerLossInc >= PowerLossFreq;
}

function bool IsOutOfPower()
{
	return CurrPower < ZERO_POWER;
}


//=================
// Night Handling
//=================

function SetNight(int Night)
{
	if ( Night > 7 )
	{
		Night = 7;
	}

	CurrNight = Night;
}

function StartNight()
{
	Log("Starting Night " $ CurrNight);
	TriggerEvent(StartNightEvent, Self, None);
}

function EndNight()
{
	TriggerEvent(EndNightEvent, Self, None);
}

function KillNight()
{
	TriggerEvent(DeathEvent, Self, None);
}

function StartNightTimer()
{
	StartTimer(1.0, true, 'TickNight');
}

function StopNightTimer()
{
	StartTimer(0.0, false, 'TickNight');
}

function TickNight();

//================
// Time Handling
//================

// Sets the current time to a given time.
function SetTime(int NewTime)
{
	NightTime = NewTime;
}

// Increments the current time by 1 second.
function IncrementTime()
{
	SetTime(NightTime + 1);
}

// Returns the total elapsed seconds value of a given hour.
function int GetHourInSeconds(int Hour)
{
	Hour = Clamp(Hour, 0, NUM_OF_HOURS);

	local int SecondsLen;
	SecondsLen = NightLength / NUM_OF_HOURS;
	return Hour * SecondsLen;
}

// Returns whether or not we are currently within a given hour.
function bool IsInHour(int Hour)
{
	Hour = Clamp(Hour, 0, NUM_OF_HOURS);
	return ( NightTime >= GetHourInSeconds(Hour) && NightTime < GetHourInSeconds(Hour + 1) ) || ( Hour >= NUM_OF_HOURS && IsNightOver() );
}

// Returns whether or not the night is over based on the current time and night length.
function bool IsNightOver()
{
	return NightTime >= NightLength;
}


//==============
// AI Handling
//==============

function SetAI(int idx, int AILevel)
{
	if ( AILevel == -1 )
	{
		AILevel = Clamp(Rand(3), 1, 2);
	}
	else if ( AILevel < -1 )
	{
		return;
	}

	CurrAILevel[idx] = AILevel;
}

// Called at 3AM and 4AM for Bonnie, Chica, and Foxy, as well as at 2AM for Bonnie only.
function IncreaseAI(int idx)
{
	if ( CurrAILevel(idx) < 20 )
	{
		CurrAILevel(idx)++;
	}
	else
	{
		Log("Cannot increase AI as " $ GetAnimatronicName(idx) $ " is already at AI level 20.");
	} 
}

// 
function IncreaseAll()
{
	local int i;

	for ( i = 0; i < ANIMATRONIC_COUNT - 1; i++ )
	{
		IncreaseAI(i);
	}

	ValidateAILevels();
}

function SetStartingAI()
{
	local int i;

	for ( i = 0; i < ANIMATRONIC_COUNT; i++ )
	{
		local int ai;

		// kinda smelly but im too lazy to improve this
		switch(CurrNight)
		{
			case 1:
			{
				ai = Night1Level[i];
			}
			case 2:
			{
				ai = Night2Level[i];
			}
			case 3:
			{
				ai = Night3Level[i];
			}
			case 4:
			{
				ai = Night4Level[i];
			}
			case 5:
			{
				ai = Night5Level[i];
			}
			case 6:
			{
				ai = Night6Level[i];
			}
			default:
			{
				ai = 0;
			}
		}
	}
}

// Ensures all AI levels are under or equal to 20.
function ValidateAILevels()
{
	local int i;

	for ( i = 0; i < ANIMATRONIC_COUNT; i++ )
	{
		if ( CurrAILevel[i] > 20 )
		{
			Log(GetAnimatronicName(i) $ "'s AI went over 20, capping it.");
			CurrAILevel[i] = 20;
		}
	}
}

function StartAnimatronicTimers()
{
	local int i;

	for ( i = 0; i < ANIMATRONIC_COUNT; i++ )
	{
		local name TargetFunc;

		switch(i)
		{
			case BONNIE:
			{
				TargetFunc = 'HandleBonnieMove';
			}
			case CHICA:
			{
				TargetFunc = 'HandleChicaMove';
			}
			case FOXY:
			{
				TargetFunc = 'HandleFoxyMove';
			}
			case FREDDY:
			{
				TargetFunc = 'HandleFreddyMove';
			}
			default:
			{
				continue;
			}
		}

		SetTimer(MoveInterval[i], true, TargetFunc);
	}
}

//==============
// CutCommands
//==============

function bool CutCommand(string command, optional string cue, optional bool bFastFlag)
{
	local string sActualCommand;
	local string targetName;
	local actor tempActor;
	local sound tempSound;
	local bool bTemp;
	local string tempStr;


	sActualCommand = ParseDelimitedString( command, " ", 1, false );
	
	if( sActualCommand ~= "StartNight" )
	{
		return CutCommand_StartNight(command, cue, bFastFlag);
	}

	
	return Super.CutCommand(command, cue, bFastFlag);
}

function bool CutCommand_StartNight(string command, optional string cue, optional bool bFastFlag)
{
	local int TargetNight;
	TargetNight = ParseDelimitedString( command, " ", 2, false );
	TargetNight = Clamp(TargetNight, 1, 6);

	SetNight(int(str));
	StartNight();
}


//=================
// Sound Handling
//=================

function PlayPhoneCall()
{
	local Sound TargetSound;
	TargetSound = CallDialogSFX[CurrNight - 1];

	if (TargetSound != None && CallSource != None)
	{
		CallSource.PlaySound(TargetSound, SLOT_Talk);
	}
}

function StopPhoneCall()
{
	if (CallSource != None)
	{
		CallSource.StopSound();
	}
}

function Sound GetFootstepSFX()
{
	local int rand;
	rand = Rand(FootstepSFX.Length);
	return FootstepSFX[rand];
}

function PlayFootsteps(int idx)
{
	local MOCAAnimatronic Target;

	Target = Animatronics[idx];

	if ( Target != None )
	{
		Target.PlaySound(GetFootstepSFX(), SLOT_Foley);
	}
}

function GetFearVolume()
{
	return FEAR_VOLUME_INCREMENT * FearLevel;
}

function PlayRandomSound(Sound TargetSound, Actor TargetSource, int Probability, optional ESoundSlot Slot)
{
	if ( TargetSound == None || TargetSource == None )
	{
		return;
	}

	if ( Probability > 1 )
	{
		local int rand;
		rand = Rand(Probability);

		if ( rand != 0 )
		{
			return;
		}
	}

	TargetSource.PlaySound(TargetSound, Slot);
}

function PlayCarnivalMusic()
{
	if ( CarnivalSource == None || CarnivalSource.SoundSlotOccupied(SLOT_Ambient) )
	{
		return;
	}

	PlayRandomSound(CarnivalSFX, CarnivalSource, 30, SLOT_Ambient);
}

function PlayHummingSFX()
{
	local MOCAAnimatronic foxy;

	foxy = Animatronics[FOXY];

	if ( foxy == None || foxy.SoundSlotOccupied(SLOT_Ambient) )
	{
		return;
	}

	PlayRandomSound(FoxyHumSFX, foxy, 30, SLOT_Ambient);
}


//================
// Misc. Helpers
//================

function ResetNight()
{
	NightTime = 0;
	CurrPower = InitialPower;
	PowerLossFreq = 0;
	CurrPowerLossInc = 0;
	FoxyHits = 0;
	FearLevel = 0;
	ResetAllMoveIntervals();
}

function ResetMoveInterval(int idx)
{
	CurrentMoveTime[idx] = 0;
}

function ResetAllMoveIntervals()
{
	local int i;

	for ( i = 0; i < ANIMATRONIC_COUNT; i++ )
	{
		ResetMoveInterval(i);
	}
}

// Returns a string of an animatronic's name based off of an index (matches with the fixed arrays).
function string GetAnimatronicName(int idx)
{
	switch(idx)
	{
		case 0:
		{
			return "Bonnie";
		}
		case 1:
		{
			return "Chica";
		}
		case 2:
		{
			return "Foxy";
		}
		case 3:
		{
			return "Freddy";
		}
		default:
		{
			return "Unknown";
		}
	}

	return "Unknown";
}


//=========
// States
//=========

state stateNighttime
{
	event BeginState()
	{
		ResetNight();
		SetStartingAI();

		StartNightTimer();
	}

	event EndState()
	{
		StopNightTimer();

	}

	function TickNight()
	{

	}
}


//=====================
// Default Properties
//=====================

defaultproperties
{
	NightLength=534
	InitialPower=100

	CurrNight=1

	MoveInterval(0)=4.97
	MoveInterval(1)=4.98
	MoveInterval(2)=5.01
	MoveInterval(3)=3.02

	Night1Level(0)=0
	Night1Level(1)=0
	Night1Level(2)=0
	Night1Level(3)=0

	Night2Level(0)=3
	Night2Level(1)=1
	Night2Level(2)=1
	Night2Level(3)=0

	Night3Level(0)=0
	Night3Level(1)=5
	Night3Level(2)=2
	Night3Level(3)=-1

	Night4Level(0)=2
	Night4Level(1)=4
	Night4Level(2)=6
	Night4Level(3)=1

	Night5Level(0)=5
	Night5Level(1)=7
	Night5Level(2)=5
	Night5Level(3)=3


	Night6Level(0)=10
	Night6Level(1)=12
	Night6Level(2)=6
	Night6Level(3)=4
}