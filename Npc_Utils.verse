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

FetchPlayers := class(creative_device):
    FGetPlayers(): []agent=
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

GetPlayers(): []agent=
    return FetchPlayers{}.FGetPlayers()
    