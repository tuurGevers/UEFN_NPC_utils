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



Main := class (creative_device):
    @editable Granter:item_granter_device= item_granter_device{}

    OnBegin<override>()<suspends>:void=
        for(Player:GetPlayspace().GetPlayers()):
            Granter.GrantItem(Player)