class MOCAPowerOutManager extends MOCAFNAFManagers;

var() name StartEvent;
var() name MusicBoxEvent;
var() name BlackoutEvent;
var() name JumpscareEvent;

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
        TriggerEvent(StartEvent, Self, None);
        CurrTimer = 0.0;
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
            Goto('begin');
        }
}

state stateMusic
{
    event BeginState()
    {
        Log("Power out music");
        TriggerEvent(MusicBoxEvent, Self, None);
        CurrTimer = 0.0;
    }

    event Tick(float DeltaTime)
    {
        CurrTimer += DeltaTime;

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
        TriggerEvent(BlackoutEvent, Self, None);
        CurrTimer = 0.0;
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
        Sleep(2.0);
        RandInt = Rand(5);
        Log("Rolled a " $ RandInt $ " to progress power out.");
        if ( RandInt == 0 )
        {
            GotoState('stateJumpscare');
        }
        else
        {
            Goto('begin');
        }
}

state stateJumpscare
{
    event BeginState()
    {
        TriggerEvent(JumpscareEvent, Self, None);
    }
}