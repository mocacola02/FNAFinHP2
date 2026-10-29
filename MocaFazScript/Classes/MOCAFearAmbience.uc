// all the math in this is incredibly silly and not the way to do this lol
class MOCAFearAmbience extends Actor;

var() float RequiredDistance;
var() float DistanceFactor;

var float TotalDist;

event PostBeginPlay()
{
    Super.PostBeginPlay();
    SetTimer(1.0, true, 'LogDist');
}

event Tick(float DeltaTime)
{
    TotalDist = 0.0;

    local MOCAAnimatronic A;
    foreach AllActors(class'MOCAAnimatronic', A)
    {
        TotalDist += VSize(Level.PlayerHarryActor.Location - A.Location);
    }

    if ( TotalDist > RequiredDistance )
    {
        SoundVolMult = 0.0;
        return;
    }

    local float NewVol;
    NewVol = 1.0 - (TotalDist / DistanceFactor);
    Clamp(NewVol, 0.0, 1.0);
    SoundVolMult = NewVol;
}

function LogDist()
{
    Log(TotalDist);
}

defaultproperties
{
    RequiredDistance=19000.0
    DistanceFactor=130000.0

    SoundVolMult=0.0
}