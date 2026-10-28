class MOCAFreddy extends MOCAAnimatronic;

var int RandInt;
var float CurrTimer;

function bool IsBeingWatched()
{
    return CurrDP.RelevantCamera == CameraManager.GetCurrentCamera();
}

function MoveToNextDP()
{
    if ( IsBeingWatched() || !CameraManager.bUtilized )
    {
        Log(CutName $ ": darnit I'm being watched! Or cameras are off");
        return;
    }

    local MOCADestinationPoint NewDP;
    NewDP = GetNewDestination();

    if ( NewDP == None )
    {
        Log(CutName $ ": Could not find a new destination!!!");
        return;
    }

    CurrDP.StopOccupiedSound();
    NewDP.PlayOccupiedSound();

    TriggerEvent(CurrDP.EventOnMove, Self, Self);
    TriggerEvent(NewDP.EventOnMove, Self, Self);

    Log(CutName $ ": Our NewDP is " $ NewDP $ " with the camera " $ NewDP.RelevantCamera $ " and the current camera is " $ CameraManager.GetCurrentCamera());

    CurrDP = NewDP;
    SetLocation(NewDP.Location);
    SetRotation(NewDP.Rotation);
    PlayAnim(CurrDP.AnimToPlay);

    local Sound FootstepSound;
    FootstepSound = GetFootstepSound();

    if ( FootstepSound != None )
    {
        PlaySound(FootstepSound, SLOT_Foley);
    }

    if ( CurrDP.bIsKillPoint )
    {
        GotoState('statePendingKill');
    }
}

auto state stateInactive
{
    function HandleMovementOpportunity()
    {
        if ( AILevel > 0 && !IsBeingWatched() )
        {
            GotoState('stateWaiting');
        }
    }
}

state stateWaiting
{
    event EndState()
    {
        CurrTimer = 0.0;
    }

    event Tick(float DeltaTime)
    {
        CurrTimer += DeltaTime;

        if ( CurrTimer >= (1000.0 / 60.0) - (AILevel * (100.0 / 60.0)) )
        {
            if ( !IsBeingWatched() )
            {
                GotoState('stateMove');
            }
        }
    }

    function HandleMovementOpportunity()
    {
        return;
    }
}

state stateMove
{
    event BeginState()
    {
        MoveToNextDP();
    }
}

state statePendingKill
{
    begin:
        Sleep(1.0);

        RandInt = Rand(5);
        Log(CutName $ ": Rolled a " $ RandInt $ " to kill, we need 0");
        if ( RandInt == 0 )
        {
            Jumpscare();
        }
}