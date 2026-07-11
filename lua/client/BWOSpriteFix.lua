local spriteFix = function(manager)

    local removeCanPath = {
        "location_restaurant_spiffos_01_4",
        "location_restaurant_spiffos_01_5",
        "location_restaurant_spiffos_01_6",
        "location_restaurant_spiffos_01_12",
        "location_restaurant_spiffos_01_13",
        "location_restaurant_spiffos_01_14",
        "location_restaurant_spiffos_01_16",
        "location_restaurant_spiffos_01_17",
        "location_restaurant_spiffos_01_18",
        "location_restaurant_spiffos_01_19",
        "location_restaurant_spiffos_01_20",
        "location_restaurant_spiffos_01_21",
        "location_restaurant_diner_01_8",
        "location_restaurant_diner_01_9",
        "location_restaurant_diner_01_10",
        "location_restaurant_diner_01_11",
        "location_restaurant_diner_01_12",
        "location_restaurant_diner_01_13",
        "location_restaurant_seahorse_01_16",
        "location_restaurant_seahorse_01_17",
        "location_restaurant_seahorse_01_18",
        "location_restaurant_seahorse_01_19",
        "location_restaurant_seahorse_01_20",
        "location_restaurant_seahorse_01_21",
        "location_shop_fossoil_01_0",
        "location_shop_fossoil_01_1",
        "location_shop_fossoil_01_2",
        "location_shop_gas2go_01_8",
        "location_shop_gas2go_01_9",
        "location_shop_greenes_01_8",
        "location_shop_greenes_01_9",
        "location_shop_greenes_01_13",
        "location_shop_greenes_01_14",
        "location_shop_greenes_01_16",
        "location_shop_greenes_01_17",
        "location_shop_greenes_01_18",
        "location_shop_greenes_01_19",
        "walls_commercial_01_0",
        "walls_commercial_01_1",
        "walls_commercial_01_3",
        "walls_commercial_01_4",
        "walls_commercial_01_5",
        "walls_commercial_01_8",
        "walls_commercial_01_9",
        "walls_commercial_01_14",
        "walls_commercial_01_15",
        "walls_commercial_01_16",
        "walls_commercial_01_17",
        "walls_commercial_01_18",
        "walls_commercial_01_32",
        "walls_commercial_01_33",
        "walls_commercial_01_34",
        "walls_commercial_01_40",
        "walls_commercial_01_41",
        "walls_commercial_01_42",
        "walls_commercial_01_64",
        "walls_commercial_01_65",
        "walls_commercial_01_66",
        "walls_commercial_01_80",
        "walls_commercial_01_81",
        "walls_commercial_01_82",
        "walls_commercial_01_96",
        "walls_commercial_01_97",
        "walls_commercial_01_98",
        "walls_commercial_01_112",
        "walls_commercial_01_113",
        "walls_commercial_01_114",
        "walls_commercial_02_0",
        "walls_commercial_02_1",
        "walls_commercial_02_2",
        "walls_commercial_02_8",
        "walls_commercial_02_9",
        "walls_commercial_02_10",
        "walls_commercial_02_48",
        "walls_commercial_02_49",
        "walls_commercial_02_50",
        "walls_commercial_02_51",
        "walls_commercial_02_52",
        "walls_commercial_02_53",
        "walls_commercial_02_72",
        "walls_commercial_02_73",
        "walls_commercial_02_74",
        "walls_commercial_02_75",
        "walls_commercial_02_76",
        "walls_commercial_02_77",
    }

    for _, name in pairs(removeCanPath) do
        local props = manager:getSprite(name):getProperties()
        if props:has(IsoFlagType.canPathN) then
            props:unset(IsoFlagType.canPathN)
        end
        if props:has(IsoFlagType.canPathW) then
            props:unset(IsoFlagType.canPathW)
        end
        if props:has(IsoFlagType.collideW) then
            props:unset(IsoFlagType.collideW)
        end
        if props:has(IsoFlagType.collideN) then
            props:unset(IsoFlagType.collideN)
        end
        --[[
        if props:has(IsoFlagType.windowN) then
            props:unset(IsoFlagType.windowN)
        end
        if props:has(IsoFlagType.windowW) then
            props:unset(IsoFlagType.windowW)
        end
        if props:has(IsoFlagType.WindowN) then
            props:unset(IsoFlagType.WindowN)
        end
        if props:has(IsoFlagType.WindowW) then
            props:unset(IsoFlagType.WindowW)
        end]]
    end
end

Events.OnLoadedTileDefinitions.Add(spriteFix)