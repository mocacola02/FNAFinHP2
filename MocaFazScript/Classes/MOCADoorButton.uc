class MOCADoorButton extends MOCAInteractiveProp;

enum Doors
{
	LeftDoor,
	RightDoor
};

var() Doors TargetDoor;
var() name DoorMoverTag;

var bool bButtonEnabled;
var MOCAPowerManager PowerManager;


event PostBeginPlay()
{
	Super.PostBeginPlay();
	
	foreach AllActors(class'MOCAPowerManager', PowerManager)
	{
		break;
	}

	if ( PowerManager == None )
	{
		Log("ERROR: Power manager not found!!");
	}
}

// this sucks
function ProcessInteract()
{
	if ( bButtonEnabled )
	{
		bButtonEnabled = false;

		TriggerEvent(DoorMoverTag, Self, None);

		if ( TargetDoor == LeftDoor )
		{
			PowerManager.bLeftDoorClosed = false;
		}
		else
		{
			PowerManager.bRightDoorClosed = false;
		}
	}
	else
	{
		bButtonEnabled = true;

		TriggerEvent(DoorMoverTag, Self, None);

		if ( TargetDoor == LeftDoor )
		{
			PowerManager.bLeftDoorClosed = true;
		}
		else
		{
			PowerManager.bRightDoorClosed = true;
		}
	}
}