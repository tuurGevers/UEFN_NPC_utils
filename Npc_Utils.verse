using { /Fortnite.com/AI }
using { /Verse.org/Simulation }
using { /Fortnite.com/Characters }
using { /UnrealEngine.com/Temporary/SpatialMath }
using { /Verse.org/Random }
using { /Fortnite.com/Devices }
using { /Verse.org/Simulation/Tags }
using { /Fortnite.com/UI }
using { /UnrealEngine.com/Temporary/UI }
using { /Verse.org/Assets }
using { /Fortnite.com/Devices/CreativeAnimation }

RaycastingProp := class(tag){}
RaycastingScaleProp := class(tag){}
NPCTag := class(tag){}

#wrapper class to fetch players outside of creative_devices
FetchPlayers := class(creative_device):
    FGetPlayers()<transacts>: []agent=
        return GetPlayspace().GetPlayers()

#IsPlayerInRange is a function that checks if a player is within a certain range of the NPC.
(NPC:fort_character).IsPlayerInRange(Players:[]agent, MaxRange:float)<transacts>: ?agent=
    if(NPC.IsActive[]):
        NpcLocation := NPC.GetTransform().Translation
        for(Player:Players):
            if(FC:=Player.GetFortCharacter[]):
                PlayerLocation := FC.GetTransform().Translation
                if(ManhattenDistance(NpcLocation, PlayerLocation) < MaxRange):
                    return option{Player}
    return false
    
# NavigateToPlayer is a function that makes the NPC navigate to the player within a max amount of time.
(NPC:fort_character).NavigateToPlayer(Player:agent, MaxTime:float)<suspends>: logic=
    var IsInTime : logic = true
    if(FC:=Player.GetFortCharacter[]):
        if(Navigatable := NPC.GetNavigatable[]):
            navTarget := MakeNavigationTarget(Player)
            if(NPC.IsActive[]):
                Res := race:
                    Navigatable.NavigateTo(navTarget)
                    CountDown(MaxTime, Navigatable)
                if(Res = false):
                    Print("nav failed")
                    set IsInTime = false
                if(NPC.IsActive[]):
                    Navigatable.StopNavigation()

    return IsInTime

# NavigateToLocation is a function that makes the NPC navigate to a location within a max amount of time.
(NPC:fort_character).NavigateToLocation(Location:vector3, MaxTime:float)<suspends>: logic=
    var IsInTime : logic = true
    if(Navigatable := NPC.GetNavigatable[]):
        navTarget := MakeNavigationTarget(Location)
        if(NPC.IsActive[]):
            Res := race:
                Navigatable.NavigateTo(navTarget)
                CountDown(MaxTime, Navigatable)
            if(Res = false):
                Print("nav failed")
                set IsInTime = false
            if(NPC.IsActive[]):
                Navigatable.StopNavigation()

    return IsInTime

# NavigateToRandomLocation is a function that makes the NPC navigate to a random location within a max amount of time.
(NPC:fort_character).NavigateToRandomLocation(MaxTime:float, MaxOffset:float)<suspends>: logic=
    var IsInTime : logic = true
    if(Navigatable := NPC.GetNavigatable[]):
        RandomLocation := GetRandomVectorWithOffset(NPC.GetTransform().Translation, MaxOffset, ?ChangeZ:=false)
        navTarget := MakeNavigationTarget(RandomLocation)
        # spawn. CountDown(MaxTime, Navigatable)
        if(NPC.IsActive[]):
            Res := race:
                Navigatable.NavigateTo(navTarget)
                CountDown(MaxTime, Navigatable)
            if(Res = false):
                Print("nav failed")
                set IsInTime = false
            if(NPC.IsActive[]):
                Navigatable.StopNavigation()

    return IsInTime

(NPC:fort_character).GetDistance(Player:agent)<transacts>:float=
    if(FC:=Player.GetFortCharacter[]):
        return ManhattenDistance(NPC.GetTransform().Translation, FC.GetTransform().Translation)
    return 0.0

# CountDown is a function that suspends the execution for a given amount of time used with the maxtime in other functions.
CountDown(MaxTime:float , nav:navigatable)<suspends>: logic=
    Sleep(MaxTime)
    return false
    
GetAnimationByName(Name:string)<transacts>:animation_sequence=
        return case(Name):
            "slime_attack" =>  npc.Enemy_Anim_MonsterArmature_Bite_Front
            "slime_hit" => npc.Enemy_Anim_MonsterArmature_HitRecieve
            "crab_attack" => crab_npc.Crab_Anim_MonsterArmature_Bite_Front
            "crab_hit" => crab_npc.Crab_Anim_MonsterArmature_HitRecieve
            "soldier_hit" =>soldier.Character_Soldier_Anim_CharacterArmature_HitReact
            "soldier_attack" =>soldier.Character_Soldier_Anim_CharacterArmature_Idle_Shoot
            _=> npc.Enemy_Anim_MonsterArmature_Bite_Front

#gets all players in game
GetPlayers()<transacts>: []agent=
    return FetchPlayers{}.FGetPlayers()

#gets all fort characters in game
GetFortCharacters()<transacts>:[]fort_character=
        Players:= GetPlayers()
        var FCs : []fort_character = array{}
        for(Player:Players):
            if(FC:= Player.GetFortCharacter[]):
                set FCs += array{FC}
        return FCs

###RAYCASTING###

# A class with the props used in the raycast bp.
#Attributes:
#         Parent (creative_prop): The main prop that interacts with other objects.
#         OutputProp (creative_prop): The target prop affected by interactions.
#         ScaleProp (creative_prop): Prop that defines scaling parameters for interactions.
RaycastProp := class:
    Parent:creative_prop
    OutputProp:creative_prop
    ScaleProp:creative_prop


# GetClosestObjectByTag is a function that returns the closest creative_prop object with the specified tag to the parent object.
# Parameters:
# - Parent: The parent object from which to search for the closest creative_prop object.
# - Tag: The tag to filter the creative_prop objects.
# Returns:
# - The closest creative_prop object with the specified tag, or null if no matching object is found.
GetClosestObjectByTag(Parent:creative_prop, Tag:tag)<transacts>:?creative_prop=
    var TotalProps: []creative_prop = array{}
    for(Obj: GetCreativeObjectsWithTag(Tag)):
        if(Prop:= creative_prop[Obj]):
            set TotalProps += array{Prop}

    return Parent.GetClosestPropInRange(TotalProps)

# SpawnRaycastProp is a function that spawns a raycast prop at the specified position with the given asset.
# It also takes a callback function that will be called when the prop is spawned.
# The callback function takes a RaycastProp as input and returns void.
SpawnRaycastProp(Asset:creative_prop_asset, Position:vector3, CB(Prop:RaycastProp)<suspends>:void):void=
    SpawnedProp := SpawnTarget(Position, Asset)

    SelectedProp:= GetClosestObjectByTag(SpawnedProp, RaycastingProp{})
    SelectedScaleProp:= GetClosestObjectByTag(SpawnedProp, RaycastingScaleProp{})

    if(Prop := SelectedProp?, ScaleProp := SelectedScaleProp?):
        spawn. CB(RaycastProp{Parent:=SpawnedProp, OutputProp:=Prop, ScaleProp:=ScaleProp})

# SpawnRaycastPropWithTransform is a function that spawns a raycast prop with a given asset and transform.
# It takes in the following parameters:
# - Asset: The asset of the prop to be spawned.
# - Position: The transform position where the prop will be spawned.
# - CB(Prop:RaycastProp)<suspends>: The callback function that will be called after the prop is spawned.
# The callback function takes in the spawned prop as a parameter and returns void.
# The function itself returns void.
SpawnRaycastPropWithTransform(Asset:creative_prop_asset,Position:transform,  CB(Prop:RaycastProp)<suspends>:void):void=
        SpawnedProp := SpawnTarget(Position.Translation, Asset, ?Rotation:=Position.Rotation)

        SelectedProp:= GetClosestObjectByTag(SpawnedProp, RaycastingProp{})
        SelectedScaleProp:= GetClosestObjectByTag(SpawnedProp, RaycastingScaleProp{})

        if(Prop := SelectedProp?, ScaleProp := SelectedScaleProp?):
            spawn. CB(RaycastProp{Parent:=SpawnedProp, OutputProp:=Prop, ScaleProp:=ScaleProp})

# It returns the RaycastProp object.
SpawnRaycastProp(Asset:creative_prop_asset, Position:vector3):?RaycastProp=
    SpawnedProp := SpawnTarget(Position, Asset)

    SelectedProp:= GetClosestObjectByTag(SpawnedProp, RaycastingProp{})
    SelectedScaleProp:= GetClosestObjectByTag(SpawnedProp, RaycastingScaleProp{})

    if(Prop := SelectedProp?, ScaleProp := SelectedScaleProp?):
        return option{RaycastProp{Parent:=SpawnedProp, OutputProp:=Prop, ScaleProp:=ScaleProp}}
    else:
        return false

# SpawnRaycastPropWithTransform is a function that spawns a raycast prop with a given asset and transform.
# It returns the RaycastProp object.
SpawnRaycastPropWithTransform(Asset:creative_prop_asset,Position:transform):?RaycastProp=
    SpawnedProp := SpawnTarget(Position.Translation, Asset, ?Rotation:=Position.Rotation)

    SelectedProp:= GetClosestObjectByTag(SpawnedProp, RaycastingProp{})
    SelectedScaleProp:= GetClosestObjectByTag(SpawnedProp, RaycastingScaleProp{})

    if(Prop := SelectedProp?, ScaleProp := SelectedScaleProp?):
        return option{RaycastProp{Parent:=SpawnedProp, OutputProp:=Prop, ScaleProp:=ScaleProp}}
    else:
        return false


# ProjectileAttack is a function that spawns a raycast prop and shoots it away with a makeshift gravity effect.
# It takes in a RaycastProp as input and returns void.
ProjectileAttack(raycastProp:RaycastProp)<suspends>:void=
    raycastProp.Parent.MoveTo(raycastProp.Parent.GetTransform().Translation, raycastProp.Parent.GetTransform().Rotation.ApplyPitch(DegreesToRadians(25.0)), 0.1)
    var V:vector3=CalculatePointNonPlayer(raycastProp.Parent.GetTransform(), 125.0, "Forward")
    spawn. raycastProp.Parent.MoveTo(V, raycastProp.Parent.GetTransform().Rotation, 0.41)
    loop:
        Sleep(0.1)
        var Trans: transform= raycastProp.Parent.GetTransform()
        set Trans.Rotation = Trans.Rotation.ApplyPitch(DegreesToRadians(-5.0))
        set V=CalculatePointNonPlayer(Trans, 125.0, "Forward")
        spawn. raycastProp.Parent.MoveTo(V, Trans.Rotation, 0.11)

        if(raycastProp.OutputProp.GetTransform().Scale.X >= 2.0):
            if(Player:=GetPlayers()[0], NpcPos :=TempPlayerPersistance[Player].Positions):
                ClosestNPC := raycastProp.Parent.GetClosestVectorInRange(NpcPos, ?MaxRange:=raycastProp.ScaleProp.GetTransform().Scale.Z*2.5)
                MaybeFC:= raycastProp.Parent.GetClosestFCInRange(GetFortCharacters(), ?MaxRange:=raycastProp.ScaleProp.GetTransform().Scale.Z*2)
                if((not ClosestNPC(0)?) or MaybeFC(0)?):
                    if(FC:= MaybeFC(0)?):
                        FC.Damage(30.0)
                    raycastProp.Parent.GraceFullDispose()
                    break

(NPC:fort_character).ProjectileNoGravity(Asset:creative_prop_asset, OnHit(FC:fort_character)<suspends>:void)<suspends>:void=
    VStart := CalculatePointNonPlayer(NPC.GetTransform(), 250.0, "Forward")
    raycastProp:= SpawnRaycastPropWithTransform(Asset, transform{
        Translation:= VStart,
        Rotation:= NPC.GetTransform().Rotation,
        Scale:= vector3{X:=1.0, Y:=1.0, Z:=1.0}
    })
    if(Prop:=raycastProp?):
        Print("Projectile spawned")
        race:
            MoveProjectile(Prop)
            HitDetection(Prop, OnHit)
           
MoveProjectile(Prop:RaycastProp)<suspends>:void=
    loop:
        V:=CalculatePointNonPlayer(Prop.Parent.GetTransform(), 200.0, "Forward")
        spawn. Prop.Parent.MoveTo(V, Prop.Parent.GetTransform().Rotation, 0.11)
        Sleep(0.1)

HitDetection(Prop:RaycastProp,OnHit(FC:fort_character)<suspends>:void)<suspends>:void=
    var Time:float = 0.0
    loop:
        Sleep(0.03)
        set Time += 0.05
        if(Prop.OutputProp.GetTransform().Scale.X >= 2.0):
            if(Player:=GetPlayers()[0], NpcPos :=TempPlayerPersistance[Player].Positions):
                ClosestNPC := Prop.Parent.GetClosestVectorInRange(NpcPos, ?MaxRange:=Prop.ScaleProp.GetTransform().Scale.Z*2.5)
                MaybeFC:= Prop.Parent.GetClosestFCInRange(GetFortCharacters(), ?MaxRange:=Prop.ScaleProp.GetTransform().Scale.Z*2)
                if((not ClosestNPC(0)?) or MaybeFC(0)? or Time>=5.0):
                    if(FC:= MaybeFC(0)?):
                        spawn. OnHit(FC)
                    Print("disposing")
                    Prop.Parent.GraceFullDispose()
                    break

 

