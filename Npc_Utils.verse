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

RaycastingProp := class(tag){}
RaycastingScaleProp := class(tag){}
NPCTag := class(tag){}

RaycastProp := class:
    Parent:creative_prop
    OutputProp:creative_prop
    ScaleProp:creative_prop

SpawnRaycastProp(Asset:creative_prop_asset,Position:vector3, CB(Prop:RaycastProp)<suspends>:void)<suspends>:void=
        SpawnedProp := SpawnTarget(Position, Asset)

        var PossibleProps : []creative_prop = array{}
        for(Obj: GetCreativeObjectsWithTag(RaycastingProp{})):
            if(Prop:= creative_prop[Obj]):
                set PossibleProps += array{Prop}

        var PossibleScaleProps : []creative_prop = array{}
        for(Obj: GetCreativeObjectsWithTag(RaycastingScaleProp{})):
            if(Prop:= creative_prop[Obj]):
                set PossibleScaleProps += array{Prop}

        SelectedProp:= SpawnedProp.GetClosestPropInRange(PossibleProps)
        SelectedScaleProp:= SpawnedProp.GetClosestPropInRange(PossibleScaleProps)

        if(Prop := SelectedProp?, ScaleProp := SelectedScaleProp?):
            spawn. CB(RaycastProp{Parent:=SpawnedProp, OutputProp:=Prop, ScaleProp:=ScaleProp})

SpawnRaycastPropWithTransform(Asset:creative_prop_asset,Position:transform,  CB(Prop:RaycastProp)<suspends>:void)<suspends>:void=
        SpawnedProp := SpawnTarget(Position.Translation, Asset, ?Rotation:=Position.Rotation)

        var PossibleProps : []creative_prop = array{}
        for(Obj: GetCreativeObjectsWithTag(RaycastingProp{})):
            if(Prop:= creative_prop[Obj]):
                set PossibleProps += array{Prop}

        var PossibleScaleProps : []creative_prop = array{}
        for(Obj: GetCreativeObjectsWithTag(RaycastingScaleProp{})):
            if(Prop:= creative_prop[Obj]):
                set PossibleScaleProps += array{Prop}

        SelectedProp:= SpawnedProp.GetClosestPropInRange(PossibleProps)
        SelectedScaleProp:= SpawnedProp.GetClosestPropInRange(PossibleScaleProps)

        if(Prop := SelectedProp?, ScaleProp := SelectedScaleProp?):
            spawn. CB(RaycastProp{Parent:=SpawnedProp, OutputProp:=Prop, ScaleProp:=ScaleProp})



ProjectileAttack(raycastProp:RaycastProp, Player:player)<suspends>:void=
    raycastProp.Parent.MoveTo(raycastProp.Parent.GetTransform().Translation, raycastProp.Parent.GetTransform().Rotation.ApplyPitch(DegreesToRadians(25.0)), 0.1)
    var V:vector3=CalculatePointNonPlayer(raycastProp.Parent.GetTransform(), 125.0, "Forward")
    spawn. raycastProp.Parent.MoveTo(V, raycastProp.Parent.GetTransform().Rotation, 0.41)
    loop:
        Sleep(0.1)
        var Trans: transform= raycastProp.Parent.GetTransform()
        set Trans.Rotation = Trans.Rotation.ApplyPitch(DegreesToRadians(-5.0))
        set V=CalculatePointNonPlayer(Trans, 125.0, "Forward")
        if(raycastProp.OutputProp.GetTransform().Scale.X >= 2.0):
            if(NpcPos :=TempPlayerPersistance[Player].Positions):
                ClosestNPC := raycastProp.Parent.GetClosestVectorInRange(NpcPos, ?MaxRange:=raycastProp.ScaleProp.GetTransform().Scale.Z*2)
                MaybeFC:= raycastProp.Parent.GetClosestFCInRange(GetFortCharacters(), ?MaxRange:=raycastProp.ScaleProp.GetTransform().Scale.Z*2)
                if((not ClosestNPC(0)?) or MaybeFC(0)?):
                    Print("Raycast hit Prop location {raycastProp.OutputProp.GetTransform().Translation}")
                    if(FC:= MaybeFC(0)?):
                        FC.Damage(30.0)
                        raycastProp.Parent.Dispose()
                        break

FetchPlayers := class(creative_device):
    FGetPlayers()<transacts>: []agent=
        return GetPlayspace().GetPlayers()


(NPC:fort_character).IsPlayerInRange(Players:[]agent, MaxRange:float)<transacts>: ?agent=
    if(NPC.IsActive[]):
        NpcLocation := NPC.GetTransform().Translation
        for(Player:Players):
            if(FC:=Player.GetFortCharacter[]):
                PlayerLocation := FC.GetTransform().Translation
                if(ManhattenDistance(NpcLocation, PlayerLocation) < MaxRange):
                    return option{Player}
    return false
    

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

(NPC:fort_character).GetKnockbackCube()<transacts>: ?creative_prop=
    var TotalProps: []creative_prop = array{}
    for(Obj: GetCreativeObjectsWithTag(KnockbackCube{})):
        if(Prop:= creative_prop[Obj]):
            set TotalProps += array{Prop}

    return NPC.GetClosestPropToChar(TotalProps)

CountDown(MaxTime:float , nav:navigatable)<suspends>: logic=
    Sleep(MaxTime)
    return false
    
GetAnimationByName(Name:string)<transacts>:animation_sequence=
        return case(Name):
            "slime_attack" =>  npc.Enemy_Anim_MonsterArmature_Bite_Front
            "slime_hit" => npc.Enemy_Anim_MonsterArmature_HitRecieve
            "slime_death" => npc.Enemy_Anim_MonsterArmature_Death
            "crab_attack" => crab_npc.Crab_Anim_MonsterArmature_Bite_Front
            "crab_hit" => crab_npc.Crab_Anim_MonsterArmature_HitRecieve
            _=> npc.Enemy_Anim_MonsterArmature_Bite_Front

GetPlayers()<transacts>: []agent=
    return FetchPlayers{}.FGetPlayers()

GetFortCharacters()<transacts>:[]fort_character=
        Players:= GetPlayers()
        var FCs : []fort_character = array{}
        for(Player:Players):
            if(FC:= Player.GetFortCharacter[]):
                set FCs += array{FC}
        return FCs