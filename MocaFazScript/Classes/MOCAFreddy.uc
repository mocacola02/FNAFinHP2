class MOCAFreddy extends MOCAAnimatronic;

var float CurrTimer;

function MoveToNextDP()
{
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
}

auto state stateInactive
{
    function HandleMovementOpportunity()
    {
        if ( !CameraManager.bUtilized )
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
            if ( !CameraManager.bUtilized )
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