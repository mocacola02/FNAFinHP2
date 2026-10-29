class MOCAFreddy extends MOCAAnimatronic;

var() MOCAAnimatronic Bonnie;
var() MOCAAnimatronic Chica;

var() MOCADestinationPoint FinalDP;
var() MOCADestinationPoint MusicBoxDP;
var() MOCADestinationPoint PreFinalDP;
var() MOCADestinationPoint BackupDP;

var() Sound MusicBox;

var() bool bAboutToKill;

var int RandInt;
var float CurrTimer;

function bool IsBeingWatched()
{
    return CurrDP.RelevantCamera == CameraManager.GetCurrentCamera();
}

function HandleMovementOpportunity()
{
    return;
}

function MoveToNextDP()
{
    if ( !Bonnie.bHasMoved || !Chica.bHasMoved )
    {
        return;
    }

    if ( IsBeingWatched() )
    {
        Log(CutName $ ": darnit I'm being watched!");
        return;
    }

    local MOCADestinationPoint NewDP;
    local Sound FootstepSound;

    if ( CurrDP == PreFinalDP )
    {
        NewDP = FinalDP;
    }
    else
    {
        NewDP = GetNewDestination();
    }
    
    if ( NewDP == None )
    {
        Log(CutName $ ": Could not find a new destination!!!");
        return;
    }

    if ( NewDP.RelevantCamera == CameraManager.GetCurrentCamera() )
    {
        Log(CutName $ ": rats, my DP is being watched! staying here");
        return;
    }

    if ( NewDP.bIsKillPoint )
    {
        if ( PowerManager.bRightDoorClosed || !CameraManager.bUtilized || IsBeingWatched() || CameraManager.GetCurrentCamera() == None )
        {
            Log(CutName $ ": GOING TO BACKUP! Can't get to kill point cuz this dang door is closed! Or cameras are off");
            NewDP = BackupDP;
        }
        else
        {
            bAboutToKill = true;

            Log(CutName $ ": I'M AT A KILL POINT!!!!!!!");

            FootstepSound = GetFootstepSound();

            if ( FootstepSound != None )
            {
                PlaySound(FootstepSound, SLOT_Foley);
            }

            GotoState('statePendingKill');

            return;
        }
    }

    TriggerEvent(CurrDP.EventOnMove, Self, Self);
    TriggerEvent(NewDP.EventOnMove, Self, Self);

    Log(CutName $ ": Our NewDP is " $ NewDP $ " with the camera " $ NewDP.RelevantCamera $ " and the current camera is " $ CameraManager.GetCurrentCamera());

    CurrDP = NewDP;
    SetLocation(NewDP.Location);
    SetRotation(NewDP.Rotation);
    PlayAnim(CurrDP.AnimToPlay);

    FootstepSound = GetFootstepSound();

    if ( FootstepSound != None )
    {
        PlaySound(FootstepSound, SLOT_Foley);
    }

    if ( NewDP == MusicBoxDP )
    {
        PlaySound(MusicBox, SLOT_Effect);
    }
    else
    {
        StopSound(MusicBox, SLOT_Effect);
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
        else if ( AILevel <= 0 )
        {
            Log(CutName $ ": Can't move cuz i'm AI 0");
        }
        else
        {
            Log(CutName $ ": Can't move cuz im being watched");
        }
    }

    begin:
        Sleep(2.0);
        Log(CutName $ ": I'm inactive...");
        Goto('begin');
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

    begin:
        Sleep(0.5);
        Log(CutName $ ": I'm waiting for " $ CurrTimer);
        Goto('begin');
}

state stateMove
{
    event BeginState()
    {
        Log(CutName $ ": I'm moving!");
        MoveToNextDP();

        if ( !bAboutToKill )
        {
            GotoState('stateInactive');
        }
    }
}

state statePendingKill
{
    function MoveToNextDP()
    {
        return;
    }

    event BeginState()
    {
        Log(CutName $ ": I'M PENDING KILL!");
    }

    event Tick(float DeltaTime)
    {
        return;
    }

    begin:
        Sleep(1.0);

        RandInt = Rand(5);
        Log(CutName $ ": Rolled a " $ RandInt $ " to kill, we need 0");
        if ( RandInt == 0 )
        {
            Jumpscare();
        }
        else
        {
            Goto('begin');
        }
}