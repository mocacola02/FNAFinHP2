class MOCAFreddyNose extends MOCAInteractiveProp;

var() bool bPowerOutAtEnd;
var() Array<Sound> SoundsOnBoop;

var int CurrIdx;

// this sucks
function ProcessInteract()
{
	if ( IsPlayingAnySound() )
	{
		return;
	}

	if ( CurrIdx + 1 > SoundsOnBoop.Length )
	{
		if ( bPowerOutAtEnd )
		{
			local MOCAPowerManager PM;
			foreach AllActors(class'MOCAPowerManager', PM)
			{
				Log("you've booped your last snoot");
				PM.DrainPower(999999999999.0);
			}
		}
		
		CurrIdx = 0;
	}
	else
	{
		PlaySound(SoundsOnBoop[CurrIdx]);
		Log("boop");
		CurrIdx++;
	}
}

function bool IsPlayingAnySound()
{
	return PlayingSounds.Length > 0;
}


defaultproperties
{
	bHidden=true
	DrawType=DT_Sprite

	CooldownDuration=0.1
}