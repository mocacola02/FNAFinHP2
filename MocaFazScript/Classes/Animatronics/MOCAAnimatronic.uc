class MOCAAnimatronic extends MOCAPawn;

enum Doors
{
	DTA_Left,
	DTA_Right
};

// AI modifier, modifies AILevel by a given amount at a given hour
struct AIModifier
{
	var() int HourToTriggerAt; 	// Moca: What hour to trigger the modifier at. Lasts for the remainder of the night.
	var() int AIToAdd;			// Moca: What AI level to add at a given hour.
};

struct SoundEvent
{
	var() bool bLoop;
	var() float LoopDelay;
	var() MOCADestinationPoint RelevantDP;
	var() Array<Sound> SoundsToPlay;
	var() ESoundSlot SlotToPlayOn;

	var Sound CurrSound;
};

var() name EventOnKill;	// Moca: What event to emit when killing the player
var() name KillSpotTag;	// Moca: Tag of the CutMark to place us at during kill animation
var() name JumpscareAnim;
var() float JumpscareAnimRate;
var() Doors DoorToAttack;

var(MOCAAnimatronicAI) int AILevel;	// Moca: Current AI level
var(MOCAAnimatronicAI) int MaxAI;	// Moca: Maximum allowed AI level
var(MOCAAnimatronicAI) Array<AIModifier> AIModifiers; // Moca: AI modifiers to activate at a given hour(s).
var(MOCAAnimatronicAI) float MoveInterval;	// Moca: How often to have a movement opportunity.

var(MOCAAnimatronicSFX) Sound WarbledVoiceSFX;		// Moca: Warbled voice sound effect (sound played on Nights 4+ while in the west and east corners)
var(MOCAAnimatronicSFX) Array<Sound> FootstepSFX;	// Moca: Array of footstep sounds to play on movement
var(MOCAAnimatronicSFX) Array<Sound> GotInSFX;		// Moca: Array of sounds to play when entering the office, before killing the player
var(MOCAAnimatronicSFX) Array<SoundEvent> DPSFX;

var bool bHasMoved;
var bool bStingerCooldown;
var bool bKillingPlayer;
var float SETimer;
var SoundEvent CurrSE;
var MOCADestinationPoint CurrDP;
var MOCACameraManager CameraManager;
var MOCAPowerManager PowerManager;
var SoundEvent BlankSE;

var Sound GotInSound;

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
		Log(CutName $ ": ERROR: Could not find CameraManager!!!");
	}

	foreach AllActors(class'MOCAPowerManager', PowerManager)
	{
		break;
	}

	if ( PowerManager == None )
	{
		Log(Cutname $ ": ERROR: Could not find power manager!");
	}
}

event Bump(Actor Other)
{
	if ( Other == PlayerHarry )
	{
		Jumpscare();
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
	Log(CutName $ ": Starting night, and my starting destination is " $ CurrDP);
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
	Log(CutName $ ": Setting AI to " $ NewLevel);
	AILevel = NewLevel;
}

// Rolls a movement opportunity and returns whether or not it was successful
function bool ShouldMove()
{
	if ( AILevel <= 0 )
	{
		return false;
	}

	// Get a random number between 1 and MaxAI
	local int rnd;
	rnd = Rand(MaxAI + 1);
	rnd = Clamp(rnd, 1, MaxAI);

	Log(CutName $ ": Trying to move with result " $ AILevel $ " - " $ rnd);

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
		if ( CurrDP.bIsKillPoint )
		{
			if ( DoorToAttack == DTA_Left && !PowerManager.bLeftDoorClosed && CanKill() )
			{
				GetIn();
				return;
			}
			else if ( DoorToAttack == DTA_Right && !PowerManager.bRightDoorClosed && CanKill() )
			{
				GetIn();
				return;
			}
		}

		local MOCADestinationPoint NewDP;
		NewDP = GetNewDestination();

		if ( NewDP == None )
		{
			Log(CutName $ ": Could not find a new destination!!!");
			return;
		}

		Log(CutName $ ": Our CurrDP is " $ CurrDP $ " with the camera " $ CurrDP.RelevantCamera $ " and the current camera is " $ CameraManager.GetCurrentCamera());

		// If we're looking at the pre-movement position, block cams
		if ( CurrDP != None && CameraManager.GetCurrentCamera() == CurrDP.RelevantCamera )
		{
			Log(CutName $ ": screw you and your cameras, BLOCKED");
			CameraManager.BlockCams();
		}

		if ( CurrSE != BlankSE )
		{
			StopSoundEvent();
		}

		TriggerEvent(CurrDP.EventOnMove, Self, Self);
		TriggerEvent(NewDP.EventOnMove, Self, Self);

		if ( NewDP.bIsKillPoint || CurrDP.bIsKillPoint )
		{
			local MOCAOfficeButton Button;
			foreach AllActors(class'MOCAOfficeButton', Button)
			{
				if ( ( Button.ButtonTarget == BP_LeftLight && PowerManager.bLeftLightOn ) || ( Button.ButtonTarget == BP_RightLight && PowerManager.bRightLightOn ) )
				{
					Log(CutName $ ": Disabling light");
					Button.ProcessInteract();
				}
			}
		}

		Log(CutName $ ": Our NewDP is " $ NewDP $ " with the camera " $ NewDP.RelevantCamera $ " and the current camera is " $ CameraManager.GetCurrentCamera());

		// If we're looking at the destination position, block cams
		if ( CameraManager.GetCurrentCamera() == NewDP.RelevantCamera )
		{
			Log(CutName $ ": screw you and your cameras, BLOCKED");
			CameraManager.BlockCams();
		}

		CurrDP = NewDP;
		SetLocation(NewDP.Location);
		SetRotation(NewDP.Rotation);
		PlayAnim(CurrDP.AnimToPlay);

		bHasMoved = true;
		bStingerCooldown = false;

		local Sound FootstepSound;
		FootstepSound = GetFootstepSound();

		if ( FootstepSound != None )
		{
			PlaySound(FootstepSound, SLOT_Foley);
		}

		local SoundEvent NewSE;
		NewSE = GetSoundEvent(NewDP);

		if ( NewSE != BlankSE )
		{
			DoSoundEvent(NewSE);
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

function bool CanKill()
{
	if ( AILevel <= 0 )
	{
		return false;
	}

	local MOCAAnimatronic A;

	foreach AllActors(class'MOCAAnimatronic', A)
	{
		if ( A.bKillingPlayer )
		{
			return false;
		}
	}

	return true;
}

function GetIn()
{
	if ( AILevel <= 0 )
	{
		return;
	}

	local MOCAOfficeButton Button;
	foreach AllActors(class'MOCAOfficeButton', Button)
	{
		if ( ( Button.ButtonTarget == BP_LeftLight && PowerManager.bLeftLightOn ) || ( Button.ButtonTarget == BP_RightLight && PowerManager.bRightLightOn ) )
		{
			Log(CutName $ ": Disabling light");
			Button.ProcessInteract();
		}

		Button.bBtnDisabled = true;
	}

	SetTimer(RandRange(0.5, 2.0), false, 'PlayBreathing');
}

function PlayBreathing()
{
	if ( GotInSFX.Length > 0 )
	{
		local int GIRand;
		GIRand = Rand(GotInSFX.Length);
		GotInSound = GotInSFX[GIRand];
		PlaySound(GotInSound, SLOT_Foley);
	}

	SetTimer(RandRange(2.25, 5.0), false, 'Jumpscare');
}

function Jumpscare()
{
	if ( AILevel <= 0 )
	{
		return;
	}

	StopSound(GotInSound, SLOT_Foley);

	if ( PowerManager.CurrPower <= 0.0 )
	{
		return;
	}

	bKillingPlayer = true;

	ConsoleCommand("hidehud");

	PlayerHarry.bStationary = true;
	PlayerHarry.bBehindView = true;
	EmitKillEvent();
}

function EmitKillEvent()
{
	TriggerEvent(EventOnKill, Self, Self);
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

function bool IsPlayingSound(Sound SoundToTest)
{
	local int i;
	for ( i = 0; i < PlayingSounds.Length; i++ )
	{
		if ( PlayingSounds[i].Sound == SoundToTest )
		{
			return true;
		}
	}

	return false;
}

function DoSoundEvent(SoundEvent NewSE)
{
	StopSoundEvent();
	CurrSE = NewSE;
	GotoState('statePlayingSound');
}

function Sound GetSESound()
{
	if ( CurrSE.SoundsToPlay.Length <= 0 )
	{
		return None;
	}

	local int SEInt;
	SEInt = Rand(CurrSE.SoundsToPlay.Length);
	return CurrSE.SoundsToPlay[SEInt];
}

function SoundEvent GetSoundEvent(MOCADestinationPoint TestDP)
{
	local int i;
	for ( i = 0; i < DPSFX.Length; i++ )
	{
		if ( DPSFX[i].RelevantDP == TestDP )
		{
			return DPSFX[i];
		}
	}

	return BlankSE;
}

function StopSoundEvent()
{
	StopSound(CurrSE.CurrSound, CurrSE.SlotToPlayOn);
	SETimer = 0.0;
	CurrSE = BlankSE;
	GotoState('stateNormal');
}

auto state stateNormal
{
}

state statePlayingSound
{
	event BeginState()
	{
		SETimer = 0.0;
		CurrSE.CurrSound = GetSESound();
		PlaySound(CurrSE.CurrSound, CurrSE.SlotToPlayOn);
	}

	event Tick(float DeltaTime)
	{
		Global.Tick(DeltaTime);

		if ( CurrSE == BlankSE )
		{
			return;
		}

		if ( IsPlayingSound(CurrSE.CurrSound) )
		{
			return;
		}

		if ( !CurrSE.bLoop )
		{
			return;
		}

		SETimer += DeltaTime;

		if ( SETimer >= CurrSE.LoopDelay )
		{
			SETimer = 0.0;

			CurrSE.CurrSound = GetSESound();
			PlaySound(CurrSE.CurrSound, CurrSE.SlotToPlayOn);
		}
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
	JumpscareAnimRate=2.0

	MaxAI=20
	MoveInterval=5.0
}