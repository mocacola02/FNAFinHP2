class MOCAPowerManager extends Actor;

var() int InitialPower;
var() int DeincrementValue;
var() int DeincrementInterval;
var() name PowerOutEvent;
var() Mover PowerBarMover;

var(MOCAFoxy) int BaseFoxyDrain;
var(MOCAFoxy) int FoxyDrainIncrement;
var(MOCAFoxy) int MaxFoxyDrain;

var int FoxyHits;

var int CurrentPower;
var int CurrentUsage;

var int CurrentIntervalTime;


function Reset()
{
	CurrentPower = InitialPower;
	CurrentUsage = 0;
	CurrentIntervalTime = 0;
	FoxyHits = 0;
}

function bool IsOutOfPower()
{
	return CurrentPower < 0;
}

function CheckPowerLevel()
{
	if ( IsOutOfPower() )
	{
		TriggerEvent(PowerOutEvent);
		StopPowerTimer();
	}
}

function DrainPower(int Amount)
{
	CurrentPower -= Amount;

	if ( PowerBarMover != None )
	{
		PowerBarMover.SetLocation(PowerBarMover.Location - vec(0.0, 0.0, -Amount));
	}

	CheckPowerLevel();
}

function HandleFoxyHit()
{
	// Since the first hit should only take 1% power, we'll increment FoxyHits AFTER the hit drain
	local int DrainAmount;
	DrainAmount = BaseFoxyDrain + (FoxyDrainIncrement * FoxyHits);
	DrainPower(DrainAmount);

	FoxyHits++;
}

function StartPowerTimer()
{
	SetTimer(1.0, true, 'HandleDrain');
}

function StopPowerTimer()
{
	SetTimer(0.0, false, 'HandleDrain');
}

function HandleDrain()
{
	if ( CurrentPower >= 0 )
	{
		CurrentIntervalTime++;

		if ( CurrentIntervalTime >= DeincrementInterval - CurrentUsage )
		{
			DrainPower(DeincrementValue);
		}
	}
}

defaultproperties
{
	InitialPower=100
	DeincrementValue=1
	DeincrementInterval=5
	PowerOutEvent="PowerOut"

	BaseFoxyDrain=1
	FoxyDrainIncrement=5
}