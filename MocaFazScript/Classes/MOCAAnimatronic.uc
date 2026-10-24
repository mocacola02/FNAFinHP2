class MOCAAnimatronic extends MOCAPawn;

// AI modifier, modifies AILevel by a given amount at a given hour
struct AIModifier
{
	var() int HourToTriggerAt; 	// Moca: What hour to trigger the modifier at. Lasts for the remainder of the night.
	var() int AIToAdd;			// Moca: What AI level to add at a given hour.
};

var() name EventOnKill;	// Moca: What event to emit when killing the player

var(MOCAAnimatronicAI) int AILevel;	// Moca: Current AI level
var(MOCAAnimatronicAI) int MaxAI;	// Moca: Maximum allowed AI level
var(MOCAAnimatronicAI) Array<AIModifier> AIModifiers; // Moca: AI modifiers to activate at a given hour(s).
var(MOCAAnimatronicAI) float MoveInterval;	// Moca: How often to have a movement opportunity.

var(MOCAAnimatronicSFX) Sound WarbledVoiceSFX;		// Moca: Warbled voice sound effect (sound played on Nights 4+ while in the west and east corners)
var(MOCAAnimatronicSFX) Array<Sound> FootstepSFX;	// Moca: Array of footstep sounds to play on movement
var(MOCAAnimatronicSFX) Array<Sound> GotInSFX;		// Moca: Array of sounds to play when entering the office, before killing the player

var MOCADestinationPoint CurrDP;
var MOCACameraManager CameraManager;


//================
// Native Events
//================

event PostBeginPlay()
{
	super.PostBeginPlay();

	if ( CurrDP == None )
	{
		CurrDP = GetNearestDP();
	}

	foreach AllActors(class'MOCACameraManager', CameraManager)
	{
		break;
	}

	if ( CameraManager == None )
	{
		Log("ERROR: Could not find CameraManager!!!");
	}
}

function MOCADestinationPoint GetNearestDP()
{
	local MOCADestinationPoint TestDP;
	local MOCADestinationPoint ClosestDP;
	local float TestDistance;
	local float ClosestDistance;
	
	foreach AllActors(class'MOCADestinationPoint', TestDP)
	{
		TestDistance = GetDistanceBetweenActors(TestDP, Self);

		if ( ClosestDP == None || ( TestDistance < ClosestDistance ) )
		{
			ClosestDP = TestDP;
			ClosestDistance = TestDistance;
		}
	}

	return ClosestDP;
}


//================
// Custom Events
//================

// Called on the start of each hour
function OnNewHour(int Hour)
{
	local int i;

	// For each of our AI modifiers
	for ( i = 0; i < AIModifiers.Length; i++ )
	{
		// Get the modifier
		local AIModifier CurrentMod;
		CurrentMod = AIModifiers[i];

		// If the hour to trigger at is the current our, modify our AI level
		if ( CurrentMod.HourToTriggerAt == Hour )
		{
			SetAILevel(AILevel + CurrentMod.AIToAdd);
		}
	}
}

function OnStartNight()
{
	StartMovementTimer();
}

function OnNightEnd()
{
	SetAILevel(0);
	StopAllSounds();
	StopMovementTimer();
}


//====================
// Movement Handling
//====================

// Sets our AI level to a given level, clamped between 0 and MaxAI
function SetAILevel(int NewLevel)
{
	NewLevel = Clamp(NewLevel, 0, MaxAI);
	Log("Setting AI to " $ NewLevel);
	AILevel = NewLevel;
}

// Rolls a movement opportunity and returns whether or not it was successful
function bool ShouldMove()
{
	// Get a random number between 1 and MaxAI
	local int rnd;
	rnd = Rand(MaxAI + 1);
	rnd = Clamp(rnd, 1, MaxAI);

	Log("Trying to move with result " $ AILevel $ " - " $ rnd);

	// Return whether or not our AILevel is greater than the random number
	return AILevel >= rnd;
}

function StartMovementTimer()
{
	SetTimer(MoveInterval, true, 'HandleMovementOpportunity');
}

function StopMovementTimer()
{
	SetTimer(0.0, false, 'HandleMovementOpportunity');
}

function Sound GetFootstepSound()
{
	if ( FootstepSFX.Length <= 0 )
	{
		return None;
	}

	local int rnd;
	rnd = Rand(FootstepSFX.Length);
	return FootstepSFX[rnd];
}

function HandleMovementOpportunity()
{
	if ( ShouldMove() )
	{
		local MOCADestinationPoint NewDP;
		NewDP = GetNewDestination();

		if ( NewDP == None )
		{
			Log("Could not find a new destination!!!");
			return;
		}

		if ( CurrDP != None && CameraManager.GetCurrentCamera() == CurrDP.RelevantCamera )
		{
			CameraManager.BlockCams();
		}

		CurrDP = NewDP;
		SetLocation(NewDP.Location);
		SetRotation(NewDP.Rotation);
		PlayAnim(CurrDP.AnimToPlay);

		local Sound FootstepSound;
		FootstepSound = GetFootstepSound();
		Log("Playing footstep sound " $ FootstepSound);

		if ( FootstepSound != None )
		{
			PlaySound(FootstepSound, SLOT_Foley);
		}
	}
}

function MOCADestinationPoint GetNewDestination()
{
	if ( CurrDP == None )
	{
		return None;
	}

	return CurrDP.GetValidDestination();
}


//=================
// Sound Handling
//=================

function StopAllSounds()
{
	local int i;

	for ( i = 0; i < PlayingSounds.Length; i++ )
	{
		StopSound(PlayingSounds[i].Sound, PlayingSounds[i].Slot, 0.0);
	}
}


//==============
// CutCommands
//==============

function bool CutCommand(string command, optional string cue, optional bool bFastFlag)
{
	local string sActualCommand;
	sActualCommand = ParseDelimitedString( command, " ", 1, false );
	
	if( sActualCommand ~= "SetAI" )
	{
		return CutCommand_SetAI(command, cue, bFastFlag);
	}

	return Super.CutCommand(command, cue, bFastFlag);
}

function bool CutCommand_SetAI(string command, optional string cue, optional bool bFastFlag)
{
	local int NewAILevel;
	NewAILevel = AtoI(ParseDelimitedString( command, " ", 2, false ));
	SetAILevel(NewAILevel);
	CutCue(cue);
	return NewAILevel == AILevel;
}


//=====================
// Default Properties
//=====================

defaultproperties
{
	EventOnKill="BonnieKill"

	MaxAI=20
	MoveInterval=5.0
}