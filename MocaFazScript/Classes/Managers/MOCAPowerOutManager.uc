class MOCAPowerOutManager extends MOCAFNAFManagers;

var() name JumpscareEvent;
var() Sound MusicBox;
var() Sound LightBuzz;
var() Sound PowerOut;
var() Sound Footstep;
var() CutMark TargetCutMark;
var() TriggerLight FreddyEyes;
var() TriggerLight OfficeLight;
var() MOCAAnimatronic Freddy;

var int RandInt;
var float CurrTimer;

function Start()
{
    GotoState('stateWaiting');
}

function Cancel()
{
    GotoState('stateInactive');
}

auto state stateInactive
{

}

state stateWaiting
{
    event BeginState()
    {
        Log("Power out waiting");
        CurrTimer = 0.0;

		PlaySound(PowerOut, SLOT_Foley);

		local MOCACrosshair CH;
		foreach AllActors(class'MOCACrosshair', CH)
		{
			CH.Destroy();
		}

		PlayerHarry.ConsoleCommand("hidehud");

		local vector OffsetPos, TargetPos;
		OffsetPos = PlayerHarry.MapDefault.Location - PlayerHarry.Location;
		TargetPos = TargetCutMark.Location - OffsetPos;
		PlayerHarry.SetLocation(TargetPos);
    }

    event Tick(float DeltaTime)
    {
        CurrTimer += DeltaTime;

        if ( CurrTimer >= 20.0 )
        {
            GotoState('stateMusic');
        }
    }

    begin:
        Sleep(5.0);
        RandInt = Rand(5);
        Log("Rolled a " $ RandInt $ " to progress power out.");
        if ( RandInt == 0 )
        {
            GotoState('stateMusic');
        }
        else
        {
			RandInt = Rand(2);
			if ( RandInt == 0 )
			{
				Freddy.PlaySound(Footstep, SLOT_Foley);
			}

            Goto('begin');
        }
}

state stateMusic
{
    event BeginState()
    {
        Log("Power out music");
        CurrTimer = 0.0;

		FreddyEyes.Trigger(Self, None);
		Freddy.PlaySound(MusicBox, SLOT_Ambient);
    }

    event Tick(float DeltaTime)
    {
        CurrTimer += DeltaTime;

		// turn to controller wouldn't work so im doing this
		local vector TowardHarry;
		local rotator RotHarry;
		TowardHarry = PlayerHarry.Location - Freddy.Location;
		RotHarry = Freddy.Rotation;
		RotHarry.Yaw = rotator(TowardHarry).Yaw;
		Freddy.SetRotation(RotHarry);

        if ( CurrTimer >= 20.0 )
        {
            GotoState('stateBlackout');
        }
    }

    begin:
        Sleep(5.0);
        RandInt = Rand(5);
        Log("Rolled a " $ RandInt $ " to progress power out.");
        if ( RandInt == 0 )
        {
            GotoState('stateBlackout');
        }
        else
        {
            Goto('begin');
        }
}

state stateBlackout
{
    event BeginState()
    {
        Log("Power out blackout");
        CurrTimer = 0.0;

		FreddyEyes.Trigger(Self, None);
		Freddy.StopSound(MusicBox, SLOT_Ambient);
    }

    event Tick(float DeltaTime)
    {
        CurrTimer += DeltaTime;

        if ( CurrTimer >= 20.0 )
        {
            GotoState('stateJumpscare');
        }
    }

    begin:
		OfficeLight.Trigger(Self, None);
		PlaySound(LightBuzz, SLOT_Ambient);
		Sleep(0.1);
		OfficeLight.Trigger(Self, None);
		StopSound(LightBuzz, SLOT_Ambient);
		Sleep(0.1);
		OfficeLight.Trigger(Self, None);
		PlaySound(LightBuzz, SLOT_Ambient);
		Sleep(0.1);
		OfficeLight.Trigger(Self, None);
		StopSound(LightBuzz, SLOT_Ambient);
		Sleep(0.1);
		OfficeLight.Trigger(Self, None);
		PlaySound(LightBuzz, SLOT_Ambient);
		Sleep(0.1);
		StopSound(LightBuzz, SLOT_Ambient);

		PlayerHarry.bStationary = true;

	loop:
        Sleep(2.0);
        RandInt = Rand(5);
        Log("Rolled a " $ RandInt $ " to progress power out.");
        if ( RandInt == 0 )
        {
            GotoState('stateJumpscare');
        }
        else
        {
			RandInt = Rand(2);
			if ( RandInt == 0 )
			{
				Freddy.PlaySound(Footstep, SLOT_Foley);
			}

            Goto('loop');
        }
}

state stateJumpscare
{
    event BeginState()
    {
        TriggerEvent(JumpscareEvent, Self, None);
    }
}