class MOCAOfficeButton extends MOCAInteractiveProp;

enum ButtonPurpose
{
	BP_LeftDoor,
	BP_RightDoor,
	BP_LeftLight,
	BP_RightLight
};

var() ButtonPurpose ButtonTarget;
var() name EventToEmit;

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

		TriggerEvent(EventToEmit, Self, None);

		switch(ButtonTarget)
		{
			case BP_LeftDoor:
				PowerManager.bLeftDoorClosed = false;
				break;
			case BP_RightDoor:
				PowerManager.bRightDoorClosed = false;
				break;
			case BP_LeftLight:
				PowerManager.bLeftLightOn = false;
				break;
			case BP_RightLight:
				PowerManager.bRightLightOn = false;
				break;
			default:
				break;
		}
	}
	else
	{
		bButtonEnabled = true;

		TriggerEvent(EventToEmit, Self, None);

		switch(ButtonTarget)
		{
			case BP_LeftDoor:
				PowerManager.bLeftDoorClosed = true;
				break;
			case BP_RightDoor:
				PowerManager.bRightDoorClosed = true;
				break;
			case BP_LeftLight:
				PowerManager.bLeftLightOn = true;
				break;
			case BP_RightLight:
				PowerManager.bRightLightOn = true;
				break;
			default:
				break;
		}
	}
}


defaultproperties
{
	bHidden=true
	DrawType=DT_Sprite
}