using { /Fortnite.com/AI }
using { /Verse.org/Simulation }
using { /Fortnite.com/Characters }
using { /Fortnite.com/Game }
using { /Fortnite.com/Animation/PlayAnimation }
using { /Verse.org/Assets }
using { /Fortnite.com/Devices }

# A Verse-authored NPC Behavior that can be used within an NPC Character Definition or an NPC Spawner device's NPC Behavior Script Override.
Basic_Behavior<public> := class(npc_behavior):
    @editable AttackAnimation:string = ""
    @editable HitAnimation:string = ""
    @editable DeathAnimation:string = ""

    var IsAlive:logic = true
    var IsHitInLoop:logic = false
    # This function runs when the NPC is spawned in the world and ready to follow a behavior.
    OnBegin<override>()<suspends>:void=
        if(NpcAgent:= GetAgent[], NPC:=NpcAgent.GetFortCharacter[],Anim:= NPC.GetPlayAnimationController[]):
            NPC.EliminatedEvent().Subscribe(HandleDeath)
            NPC.DamagedEvent().Subscribe(HandleHit)

            NPC.NavigateToRandomLocation(1.0, 500.0)
            loop:
                set IsHitInLoop = false
                Print("new loop")
                Sleep(0.2)
                if(IsAlive= false):
                    break

                if(IsHitInLoop = false):
                    Players:= GetPlayers()
                    if(PlayerInRange := NPC.IsPlayerInRange(Players, 1000.0)?):
                        Print("NavPlayer")
                        if(IsHitInLoop = false):
                            Res:= NPC.NavigateToPlayer(PlayerInRange, 2.0)
                            if(Res = true):
                                if(IsHitInLoop = false):
                                    Print("Player is in range")
                                    Anim.PlayAndAwait(GetAnimationByName(AttackAnimation))
                                    if(IsHitInLoop = false):
                                        if(FC:= PlayerInRange.GetFortCharacter[]):
                                            Print("damaging player")
                                            FC.Damage(20.0)

                            else:
                                Print("Player is not in range")
                    else:
                        Print("nav random")
                        if(IsHitInLoop = false):
                            NPC.NavigateToRandomLocation(1.0, 500.0)
            
            
    HandleDeath(res:elimination_result):void=
        Print("NPC Eliminated")
        set IsAlive = false

    HandleHit(res:damage_result):void=
        set IsHitInLoop = true
        spawn. SuspendHitAnimation(res.Amount)
    
    SuspendHitAnimation(dmg:float)<suspends>:void=
        if(NpcAgent:= GetAgent[], NPC:=NpcAgent.GetFortCharacter[],Anim:= NPC.GetPlayAnimationController[]):
            if(NPC.IsActive[]):
                Anim.PlayAndAwait(GetAnimationByName(HitAnimation))
        Print("NPC Hit")

    # This function runs when the NPC is despawned or eliminated from the world.
    OnEnd<override>():void=
        
        # TODO: Replace this with your code
        set IsAlive = false
        Print("Goodbye, NPC!")