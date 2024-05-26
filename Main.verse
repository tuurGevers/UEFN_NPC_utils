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
RaycastProp := class:
    Parent:creative_prop
    OutputProp:creative_prop

Main := class (creative_device):
    @editable Granter:item_granter_device= item_granter_device{}
    @editable ScaleProp : creative_prop_asset = DefaultCreativePropAsset

    @editable NpcSpawners: []npc_spawner_device = array{}

    var AliveNpcs : []fort_character = array{}

    OnBegin<override>()<suspends>:void=
        for(Spawner: NpcSpawners):
            Spawner.SpawnedEvent.Subscribe(AddNPC)
            Spawner.EliminatedEvent.Subscribe(RemoveNPC)

        for(Player:GetPlayspace().GetPlayers()):
            Granter.GrantItem(Player)
            for(I:=0..4):
                spawn. SpawnRaycastProp()

    AddNPC(NPC:agent):void=
        if(NPCFC:= NPC.GetFortCharacter[]):
            set AliveNpcs += array{NPCFC}

    RemoveNPC(Res:device_ai_interaction_result):void=
        if(Target:=Res.Target?):
            if(FC:= fort_character[Target]):
                if(FoundIndex := AliveNpcs.Find[FC], NewArr:= AliveNpcs.RemoveElement[FoundIndex]):
                    set AliveNpcs = NewArr

    FilterActive()<transacts>:[]fort_character=
        var ActiveFCs : []fort_character = array{}
        for(FC: AliveNpcs):
            if(FC.IsActive[]):
                set ActiveFCs += array{FC}
        return ActiveFCs
     
    SpawnRaycastProp()<suspends>:void=
        SpawnedProp := SpawnTarget(GetRandomVector3(vector3{X:=10.0,Y:=10.0, Z:=100.0}, vector3{X:=800.0,Y:=800.0, Z:=150.0}), ScaleProp)

        var PossibleProps : []creative_prop = array{}
        for(Obj: GetCreativeObjectsWithTag(RaycastingProp{})):
            if(Prop:= creative_prop[Obj]):
                set PossibleProps += array{Prop}
        SelectedProp:= SpawnedProp.GetClosestPropInRange(PossibleProps)
        
        if(Prop := SelectedProp?):
            spawn. CheckRaycastProp(RaycastProp{Parent:=SpawnedProp, OutputProp:=Prop})


    CheckRaycastProp(RaycastPropInst:RaycastProp)<suspends>:void=
            loop:
                Sleep(0.2)
                if(RaycastPropInst.OutputProp.GetTransform().Scale.X >= 2.0):
                    MaybeFC:= RaycastPropInst.Parent.GetClosestFCInRange(GetFortCharacters() + FilterActive())
                    Print("Prop location {RaycastPropInst.OutputProp.GetTransform().Translation}")
                    if(FC:= MaybeFC?):
                        FC.Damage(10.0)
                        Print("Player Hit!")
                        RaycastPropInst.Parent.Dispose()
                        break

    GetFortCharacters()<transacts>:[]fort_character=
        Players:= GetPlayspace().GetPlayers()
        var FCs : []fort_character = array{}
        for(Player:Players):
            if(FC:= Player.GetFortCharacter[]):
                set FCs += array{FC}
        return FCs