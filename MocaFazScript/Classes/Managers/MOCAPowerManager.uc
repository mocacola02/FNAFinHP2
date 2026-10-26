class MOCAPowerManager extends Actor;

var() int InitialPower;			// Moca: How much power to start with each night
var() int DeincrementValue;		// Moca: How much power to drain each time we lose power (excluding Foxy drainage)
var() int DeincrementInterval;	// Moca: How many seconds between power drains. Gets shortened based on power usage.
var() name PowerOutEvent;		// Moca: Event to send when power runs out.
var() Mover PowerBarMover;		// Moca: Reference to the power bar mover.

var(MOCAFoxy) int BaseFoxyDrain;		// Moca: Base amount of power Foxy should drain when hitting the door.
var(MOCAFoxy) int FoxyDrainIncrement;	// Moca: How much power to add onto the base drain, increasing with the number of times Foxy has hit.
var(MOCAFoxy) int MaxFoxyDrain;			// Moca: Maximum amount of power Foxy is allowed to drain. < 0 means no limit.

var bool bLeftDoorClosed;
var bool bRightDoorClosed;

var int FoxyHits;

var int CurrentPower;
var int CurrentUsage;

var int CurrentIntervalTime;


// Resets key values to their intended default
function Reset()
{
	CurrentPower = InitialPower;
	CurrentUsage = 0;
	CurrentIntervalTime = 0;
	FoxyHits = 0;
}

// Returns whether or not we're out of power
function bool IsOutOfPower()
{
	return CurrentPower < 0;
}

// Checks if we're out of power, emits an event if so and stops the drain timer
function CheckPowerLevel()
{
	if ( IsOutOfPower() )
	{
		TriggerEvent(PowerOutEvent, Self, None);
		StopPowerTimer();
	}
}

// Removes a given amount of power, moves the power bar mover, and checks if we are out of power
function DrainPower(int Amount)
{
	CurrentPower -= Amount;

	if ( PowerBarMover != None )
	{
		PowerBarMover.SetLocation(PowerBarMover.Location - vec(0.0, 0.0, -Amount));
	}

	CheckPowerLevel();
}

// Handles logic for Foxy hitting the door
function HandleFoxyHit()
{
	// Since the first hit should only take 1% power, we'll increment FoxyHits AFTER the hit drain
	local int DrainAmount;
	// Calculates the drain amount from our base drain that should be taken each time, plus an increment that is increased for each hit
	DrainAmount = BaseFoxyDrain + (FoxyDrainIncrement * FoxyHits);

	if ( MaxFoxyDrain >= 0 )
	{
		DrainAmount = Clamp(DrainAmount, 0, MaxFoxyDrain);
	}

	// Drain the calculated amount
	DrainPower(DrainAmount);

	// Increment our hit counter
	FoxyHits++;
}

// Starts the power drain timer
function StartPowerTimer()
{
	SetTimer(1.0, true, 'HandleDrain');
}

// Stops the power drain timer
function StopPowerTimer()
{
	SetTimer(0.0, false, 'HandleDrain');
}

// Determines if we should drain power yet
function HandleDrain()
{
	// If we have power
	if ( CurrentPower >= 0 )
	{
		// Increment time interval
		CurrentIntervalTime++;

		// If current time is greater than or equal to our set interval minus the current usage (aka drain power faster when usage is higher), drain power
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
	MaxFoxyDrain=-1
}