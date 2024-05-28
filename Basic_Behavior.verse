using { /Fortnite.com/AI }
using { /Verse.org/Simulation }
using { /Fortnite.com/Characters }
using { /Fortnite.com/Game }
using { /Fortnite.com/Animation/PlayAnimation }
using { /Verse.org/Assets }
using { /Fortnite.com/Devices }
using { /UnrealEngine.com/Temporary/SpatialMath }
using { /Verse.org/Random }
using { /Verse.org/Simulation/Tags }


BasicBehaviors:= enum{BASIC_MELEE, MELEE_CHASE ,BASIC_RANGED}


# A Verse-authored NPC Behavior that can be used within an NPC Character Definition or an NPC Spawner device's NPC Behavior Script Override.
Basic_Behavior<public> := class(npc_behavior):
    @editable AttackAnimation:string = ""
    @editable HitAnimation:string = ""
    @editable DeathProp: creative_prop_asset = DefaultCreativePropAsset
    @editable BaseBehavior:BasicBehaviors = BasicBehaviors.BASIC_MELEE
    @editable RaycastPropAsset : creative_prop_asset = DefaultCreativePropAsset

    var IsAlive:logic = true
    var IsHitInLoop:logic = false
    var IsAttacking:logic = false
    var LastTransform:transform= transform{}
    var CurrentAnim: ?play_animation_instance = false
    var LastPlayer:?agent=false

    # This function runs when the NPC is spawned in the world and ready to follow a behavior.
    OnBegin<override>()<suspends>:void=
        if(NpcAgent:= GetAgent[], NPC:=NpcAgent.GetFortCharacter[], Anim:= NPC.GetPlayAnimationController[]):
            NPC.EliminatedEvent().Subscribe(HandleDeath)
            NPC.DamagedEvent().Subscribe(HandleHit)

            case(BaseBehavior):
                BasicBehaviors.BASIC_MELEE=>BasicMeleeLoop()
                BasicBehaviors.MELEE_CHASE=>MeleeChaseLoop()
                BasicBehaviors.BASIC_RANGED=>RangedLoop()
            

    SetTargettedPlayer(Dist:float):?agent=
        if(NpcAgent:= GetAgent[], NPC:=NpcAgent.GetFortCharacter[], Anim:= NPC.GetPlayAnimationController[]):
            Players:= GetPlayers()
            var PlayerInRange:?agent=false
            if(LastAgent:=LastPlayer?):
                set PlayerInRange = option{LastAgent}    
            else:
                if(RandomPlayerInRange := NPC.IsPlayerInRange(Players, Dist)?):
                    set PlayerInRange = option{RandomPlayerInRange}    
            return PlayerInRange
        return false

    BasicMeleeLoop()<suspends>:void=
        if(NpcAgent:= GetAgent[], NPC:=NpcAgent.GetFortCharacter[], Anim:= NPC.GetPlayAnimationController[]):
            NPC.NavigateToRandomLocation(1.0, 500.0)
            loop:
                set IsHitInLoop = false
                set IsAttacking = false

                Sleep(0.2)
                if(IsAlive = false):
                    break

                if(IsHitInLoop = false):
                    PlayerInRange:= SetTargettedPlayer(1000.0)
                    
                    
                    if(FoundPlayer:= PlayerInRange?):
                        if(IsHitInLoop = false):
                            Res:= NPC.NavigateToPlayer(FoundPlayer, 2.0)
                            if(Res = true):
                                if(IsHitInLoop = false):
                                    set IsAttacking = true
                                    AttackAnim:=Anim.Play(GetAnimationByName(AttackAnimation))
                                    set CurrentAnim = option{AttackAnim}
                                    AttackAnim.Await()
                                    if(IsHitInLoop = false):
                                        if(FC:= FoundPlayer.GetFortCharacter[]):
                                            Print("player found")
                                            FC.Damage(20.0)
                            else:
                                Print("Player is not in range")
                    else:
                        if(IsHitInLoop = false):
                            NPC.NavigateToRandomLocation(1.0, 500.0)

    MeleeChaseLoop()<suspends>:void=
        if(NpcAgent:= GetAgent[], NPC:=NpcAgent.GetFortCharacter[], Anim:= NPC.GetPlayAnimationController[]):
            loop:
                set IsHitInLoop = false
                set IsAttacking = false

                Sleep(0.1)
                if(IsAlive = false):
                    break

                if(IsHitInLoop = false):
                    Players:= GetPlayers()
                    var PlayerInRange:?agent=false
                    if(LastAgent:=LastPlayer?):
                        set PlayerInRange = option{LastAgent}    
                    else:
                        if(RandomPlayerInRange := NPC.IsPlayerInRange(Players, 2500.0)?):
                            set PlayerInRange = option{RandomPlayerInRange}    

                    if(FoundPlayer:= PlayerInRange?):
                        if(IsHitInLoop = false):
                            Res:= NPC.NavigateToPlayer(FoundPlayer, 2.0)
                            if(Res = true):
                                if(IsHitInLoop = false):
                                    set IsAttacking = true
                                    AttackAnim:=Anim.Play(GetAnimationByName(AttackAnimation))
                                    set CurrentAnim = option{AttackAnim}
                                    AttackAnim.Await()
                                    if(IsHitInLoop = false):
                                        if(FC:= FoundPlayer.GetFortCharacter[]):
                                            Print("player found")
                                            FC.Damage(20.0)
                            else:
                                Print("Player is not in range")

    RangedLoop()<suspends>:void=
        if(NpcAgent:= GetAgent[], NPC:=NpcAgent.GetFortCharacter[], Anim:= NPC.GetPlayAnimationController[], Focus:=NPC.GetFocusInterface[]):
            loop:
                Print("loop")
                set IsHitInLoop = false
                set IsAttacking = false

                Sleep(1.0)
                if(IsAlive = false):
                    break
                
                if(IsHitInLoop = false):
                    Print("not hit")
                    PlayerInRange:= SetTargettedPlayer(5000.0)
                    Print("player searched")
                    if(FoundPlayer:= PlayerInRange?):
                        spawn. Focus.MaintainFocus(FoundPlayer)

                        if(NPC.GetDistance(FoundPlayer) < 500.0):
                            V:= CalculatePoint(FoundPlayer, 1500.0, "Forward")
                            NPC.NavigateToLocation(V, 1.0)
                        else:
                            NPC.NavigateToPlayer(FoundPlayer, 1.0)

                        if(IsHitInLoop = false):
                            set IsAttacking = true
                            Print("starting attack")
                            for(I:=0..5):
                                NPC.NavigateToPlayer(FoundPlayer, 0.05)
                                AttackAnim:=Anim.Play(GetAnimationByName(AttackAnimation))
                                set CurrentAnim = option{AttackAnim}
                                AttackAnim.Await()
                                if(IsHitInLoop = false):
                                    spawn. NPC.ProjectileNoGravity(RaycastPropAsset, HandleRangedHit)

                                

    HandleRangedHit(FC:fort_character)<suspends>:void=
        FC.Damage(20.0)
        
    HandleDeath(res:elimination_result):void=
        Prop:=SpawnTarget(vector3{X:=LastTransform.Translation.X, Y:=LastTransform.Translation.Y, Z:=LastTransform.Translation.Z-90.0}, DeathProp, ?Rotation:=LastTransform.Rotation.ApplyYaw(DegreesToRadians(-90.0)))
        spawn. RemoveProp(Prop)
        Print("NPC Eliminated")
        set IsAlive = false
    
    RemoveProp(prop:creative_prop)<suspends>:void=
        Sleep(1.5)
        prop.Dispose()

    HandleHit(res:damage_result):void=
        if(NPC:= GetAgent[].GetFortCharacter[], Nav:=NPC.GetNavigatable[]):
            set LastTransform = NPC.GetTransform()
            if(IsAttacking = false):
                if(Anim := CurrentAnim?):
                    Anim.Stop()
                    Print("Stopped Anim")
                if(Instigator:=res.Instigator?,PFC:=fort_character[Instigator]):
                    if(Player:=PFC.GetAgent[] ):
                        if(PFC <> NPC):
                            set LastPlayer = option{Player}
                        
                Nav.StopNavigation()
                set IsHitInLoop = true
                spawn. SuspendHitAnimation(res.Amount)
    
    SuspendHitAnimation(dmg:float)<suspends>:void=
        if(NpcAgent:= GetAgent[], NPC:=NpcAgent.GetFortCharacter[], Anim:= NPC.GetPlayAnimationController[]):
            if(NPC.IsActive[]):
                Anim.PlayAndAwait(GetAnimationByName(HitAnimation))

        Print("NPC Hit")

    # This function runs when the NPC is despawned or eliminated from the world.
    OnEnd<override>():void=
        set IsAlive = false
        Print("Goodbye, NPC!")
