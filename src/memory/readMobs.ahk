#SingleInstance, Force
SendMode Input
SetWorkingDir, %A_ScriptDir%


ReadMobs(d2rprocess, startingOffset, ByRef mobs) {
    ; monsters
    mobs := []
    global mobinfo:=
    monstersOffset := startingOffset + 1024
    Loop, 128
    {
        newOffset := monstersOffset + (8 * (A_Index - 1))
        mobAddress := d2rprocess.BaseAddress + newOffset
        mobUnit := d2rprocess.read(mobAddress, "Int64")
        while (mobUnit > 0) { ; keep following the next pointer
            mobType := d2rprocess.read(mobUnit + 0x00, "UInt")
            txtFileNo := d2rprocess.read(mobUnit + 0x04, "UInt")
            if (!HideNPC(txtFileNo)) {
                unitId := d2rprocess.read(mobUnit + 0x08, "UInt")
                mode := d2rprocess.read(mobUnit + 0x0c, "UInt")
                pUnitData := d2rprocess.read(mobUnit + 0x10, "Int64")
                pPath := d2rprocess.read(mobUnit + 0x38, "Int64")
            
                isUnique := d2rprocess.read(pUnitData + 0x18, "UShort")
                monx := d2rprocess.read(pPath + 0x02, "UShort")
                mony := d2rprocess.read(pPath + 0x06, "UShort")
                xPosOffset := d2rprocess.read(pPath + 0x00, "UShort") 
                yPosOffset := d2rprocess.read(pPath + 0x04, "UShort")
                xPosOffset := xPosOffset / 65536   ; get percentage
                yPosOffset := yPosOffset / 65536   ; get percentage
                monx := monx + xPosOffset
                mony := mony + yPosOffset

                isBoss := 0
                textTitle := getBossName(txtFileNo)
                if (textTitle) {
                    name:=textTitle
                    isBoss:= 1
                }
                isMerc:= getMerc(txtFileNo)
                if (isMerc) {
                    name:="Merc"
                    isMerc:= 1
                }
                isNpc:=getNPCname(txtFileNo)
                if (isNpc) {
                    name:=isNpc
                    isNpc:= 1
                }
                ;get immunities
                pStatsListEx := d2rprocess.read(mobUnit + 0x88, "Int64")
                ownerType := d2rprocess.read(pStatsListEx + 0x08, "UInt")
                ownerId := d2rprocess.read(pStatsListEx + 0x0C, "UInt")

                statPtr := d2rprocess.read(pStatsListEx + 0x30, "Int64")
                statCount := d2rprocess.read(pStatsListEx + 0x38, "Int64")

                immunities := { physical: 0, magic: 0, fire: 0, light: 0, cold: 0, poison: 0 }
                Loop, %statCount%
                ;Loop, 2000
                {     
                    statEnum := d2rprocess.read(statPtr + 0x2 + offset, "UShort")
                    statValue := d2rprocess.read(statPtr + 0x4 + offset, "UInt")
                    if(isMerc){
                        ;msgbox,,, % 
                        enums.=statCount . "#" . statEnum  . "__" . statValue . " | "

                    }
                    if (isMerc){
                        break
                    }
                    offset := (A_Index -1) * 8
                    ;statParam := d2rprocess.read(statPtr + offset, "UShort")
                    if (statValue >= 100) {
                        switch (statEnum) {
                            ; no enums here, just bad practices instead
                            case 36: immunities["physical"] := 1 ;physical immune
                            case 37: immunities["magic"] := 1    ;magic immune
                            case 39: immunities["fire"] := 1     ;fire resist
                            case 41: immunities["light"] := 1    ;light resist
                            case 43: immunities["cold"] := 1     ;cold resist
                            case 45: immunities["poison"] := 1   ;poison resist
                        }
                    }
                }
                mobname:=(getMobNameDesc(txtFileNo))
                if (!isNpc and !isBoss and !isMerc){
                    name:=mobname:=(getMobNameDesc(txtFileNo))
                }

                mob := {"name": name,"txtFileNo": txtFileNo, "mode": mode, "x": monx, "y": mony, "isUnique": isUnique, "isBoss": isBoss, "isMerc": isMerc, "isNPC": isNpc, "textTitle": textTitle, "immunities": immunities }
                mobs.push(mob)

                ;mob debug infostats
                if (mobname=""){
                } else if (mode=12){
                } else {
                    mobinfo.=((isUnique)?("UNI:"):("")) . txtFileNo . ":ID:" . name . ":M:" . mode . ":X" . floor(monx) . ":Y" . floor(mony) . "`n"
                }
                ;mob debug
            }

            /* poking in merc stats
            if (oldenums`=enums){
            } else {
                oldenums:=enums
                ;ToolTip, % enums , 600, 0, 3
            }
            */     

            mobUnit := d2rprocess.read(mobUnit + 0x150, "Int64")  ; get next mob
        }
    } 
}


getBossName(txtFileNo) {
    switch (txtFileNo) {
        case "156": return "Andariel"
        case "211": return "Duriel"
        case "229": return "Radament"
        case "242": return "Mephisto"
        case "243": return "Diablo"
        case "250": return "Summoner"
        case "256": return "Izual"
        case "267": return "Bloodraven"
        case "333": return "Diabloclone"
        case "365": return "Griswold"
        case "526": return "Nihlathak"
        case "544": return "Baal"
        case "570": return "Baalclone"
        case "704": return "Uber Mephisto"
        case "705": return "Uber Diablo"
        case "706": return "Uber Izual"
        case "707": return "Uber Andariel"
        case "708": return "Uber Duriel"
        case "709": return "Uber Baal"
    }
    return ""
}
getMerc(txtFileNo){
    switch (txtFileNo) {
            case "271": return "roguehire"
            case "338": return "act2hire"
            case "359": return "Iron Wolf"
            case "560": return "act5hire1"
            case "561": return "act5hire2"
        }
        return ""
}
getNPCname(txtFileNo){
    switch (txtFileNo) {
        case "146": return "DeckardCain"
        case "147": return "Gheed"
        case "148": return "Akara"
        case "150": return "Kashya"
        case "154": return "Charsi"
        case "155": return "Warriv"
        case "175": return "Warriv"
        case "176": return "Atma"
        case "177": return "Drognan"
        case "178": return "Fara"
        case "198": return "Greiz"
        case "199": return "Elzix"
        case "201": return "Jerhyn"
        case "202": return "Lysander"
        case "210": return "Meshif"
        case "244": return "DeckardCain"
        case "245": return "DeckardCain"
        case "246": return "DeckardCain"
        case "264": return "meshif"
        case "265": return "DeckardCain"
        case "254": return "alkor"
        case "255": return "ormus"
        case "251": return "tyrael"
        case "252": return "asheara"
        case "253": return "hratli"
        case "256": return "izual"
        case "257": return "halbu"
        case "367": return "Tyrael"
        case "405": return "Jamella"
        case "406": return "Izual"
        case "511": return "Larzuk"
        case "512": return "Anya"
        case "513": return "Malah"
        case "514": return "Nihlathak Town"
        case "515": return "Qual-Kehk"
        case "520": return "DeckardCain"
        case "521": return "tyrael"
    }
    return ""
}
getSuperUniqueName(txtFileNo) {
    switch (txtFileNo) {
        case "0": return "Bonebreak"
        case "5": return "Corpsefire"
        case "11": return "Pitspawn Fouldog"
        case "20": return "Rakanishu"
        case "24": return "Treehead WoodFist"
        case "31": return "Fire Eye"
        case "45": return "The Countess"
        case "47": return "Sarina the Battlemaid"
        ;case "56": return "Night Shifter"
        case "62": return "Baal Subject 1"
        case "66": return "Flamespike the Crawler"
        case "75": return "Fangskin"
        case "83": return "Bloodwitch the Wild"
        case "92": return "Beetleburst"
        case "97": return "Leatherarm"
        case "103": return "Ancient Kaa the Soulless"
        case "105": return "Baal Subject 2"
        case "120": return "The Tormentor"
        case "125": return "Web Mage the Burning"
        case "129": return "Stormtree"
        ;case "131": return ""
        case "138": return "Icehawk Riftwing"
        case "160": return "Coldcrow"
        case "276": return "Boneash"
        case "281": return "Witch Doctor Endugu"
        case "284": return "Coldworm the Burrower"
        case "299": return "Taintbreeder"
        case "306": return "Grand Vizier of Chaos"
        case "308": return "Riftwraith the Cannibal"
        case "312": return "Lord De Seis"
        ; case "345": return "Council Member"
        ; case "346": return "Council Member"
        ; case "347": return "Council Member"
        case "362": return "Winged Death"
        case "402": return "The Smith"
        case "409": return "The Feature Creep"
        case "437": return "Bonesaw Breaker"
        case "440": return "Pindleskin"
        case "443": return "Threash Socket"
        case "449": return "Frozenstein"
        case "453": return "Megaflow Rectifier"
        case "472": return "Anodized Elite"
        case "475": return "Vinvear Molech"
        case "479": return "Siege Boss"
        case "481": return "Sharp Tooth Sayer"
        case "494": return "Dac Farren"
        case "496": return "Magma Torquer"
        case "501": return "Snapchip Shatter"
        case "508": return "Axe Dweller"
        case "529": return "Eyeback Unleashed"
        case "533": return "Blaze Ripper"
        case "540": return "Ancient Barbarian 1"
        case "541": return "Ancient Barbarian 2"
        case "542": return "Ancient Barbarian 3"
        case "557": return "Baal Subject 3"
        case "558": return "Baal Subject 4"
        case "571": return "Baal Subject 5"
        case "735": return "The Cow King"
        case "736": return "Dark Elder"
    }
    return ""
}

; certain NPCs we don't want to see such as mercs
HideNPC(txtFileNo) {
    switch (txtFileNo) {
        case 149: return 1
        case 151: return 1
        case 152: return 1
        case 153: return 1
        case 157: return 1
        case 158: return 1
        case 159: return 1
        case 195: return 1
        case 196: return 1
        case 197: return 1
        case 179: return 1
        case 185: return 1
        case 200: return 1 ;"Geglash" ;act 2
        case 203: return 1
        case 204: return 1
        case 205: return 1
        case 268: return 1
        case 269: return 1
        ;case 271: return 1
        case 272: return 1
        case 293: return 1
        case 294: return 1
        case 289: return 1
        case 290: return 1
        case 291: return 1
        case 292: return 1
        case 296: return 1
        case 318: return 1
        case 319: return 1
        case 320: return 1
        case 321: return 1
        case 322: return 1
        case 323: return 1
        case 324: return 1
        case 325: return 1
        case 331: return 1 ;"Kaelan" ;act 2
        case 332: return 1
        case 339: return 1
        case 344: return 1
        case 355: return 1
        case 363: return 1
        case 364: return 1
        case 370: return 1
        case 377: return 1
        case 378: return 1
        case 392: return 1
        case 393: return 1
        case 401: return 1
        case 411: return 1
        case 412: return 1
        case 414: return 1
        case 415: return 1
        case 416: return 1
        case 567: return 1
        case 568: return 1
        case 569: return 1
        case 711: return 1
    }
    return 0
}
list_NPC:=
getMobNameDesc(txtFileNo){
    switch (txtFileNo) {
        case "0": return "Skeleton"
        case "1": return "Returned"
        case "2": return "BoneWarrior"
        case "3": return "BurningDead"
        case "4": return "Horror"
        case "5": return "Zombie"
        case "6": return "HungryDead"
        case "7": return "Ghoul"
        case "8": return "DrownedCarcass"
        case "9": return "PlagueBearer"
        case "10": return "Afflicted"
        case "11": return "Tainted"
        case "12": return "Misshapen"
        case "13": return "Disfigured"
        case "14": return "Damned"
        case "15": return "FoulCrow"
        case "16": return "BloodHawk"
        case "17": return "BlackRaptor"
        case "18": return "CloudStalker"
        case "19": return "Fallen"
        case "20": return "Carver"
        case "21": return "Devilkin"
        case "22": return "DarkOne"
        case "23": return "WarpedFallen"
        case "24": return "Brute"
        case "25": return "Yeti"
        case "26": return "Crusher"
        case "27": return "WailingBeast"
        case "28": return "GargantuanBeast"
        case "29": return "SandRaider"
        case "30": return "Marauder"
        case "31": return "Invader"
        case "32": return "Infidel"
        case "33": return "Assailant"
        case "38": return "Ghost"
        case "39": return "Wraith"
        case "40": return "Specter"
        case "41": return "Apparition"
        case "42": return "DarkShape"
        case "43": return "DarkHunter"
        case "44": return "VileHunter"
        case "45": return "DarkStalker"
        case "46": return "BlackRogue"
        case "47": return "FleshHunter"
        case "48": return "DuneBeast"
        case "49": return "RockDweller"
        case "50": return "JungleHunter"
        case "51": return "DoomApe"
        case "52": return "TempleGuard"
        case "53": return "MoonClan"
        case "54": return "NightClan"
        case "55": return "BloodClan"
        case "56": return "HellClan"
        case "57": return "DeathClan"
        case "58": return "FallenShaman"
        case "59": return "CarverShaman"
        case "60": return "DevilkinShaman"
        case "61": return "DarkShaman"
        case "62": return "WarpedShaman"
        case "63": return "QuillRat"
        case "64": return "SpikeFiend"
        case "65": return "ThornBeast"
        case "66": return "RazorSpine"
        case "67": return "JungleUrchin"
        case "68": return "SandMaggot"
        case "69": return "RockWorm"
        case "70": return "Devourer"
        case "71": return "GiantLamprey"
        case "72": return "WorldKiller"
        case "73": return "TombViper"
        case "74": return "ClawViper"
        case "75": return "Salamander"
        case "76": return "PitViper"
        case "77": return "SerpentMagus"
        case "78": return "SandLeaper"
        case "79": return "CaveLeaper"
        case "80": return "TombCreeper"
        case "81": return "TreeLurker"
        case "82": return "RazorPitDemon"
        case "83": return "Huntress"
        case "84": return "SaberCat"
        case "85": return "NightTiger"
        case "86": return "HellCat"
        case "87": return "Itchies"
        case "88": return "BlackLocusts"
        case "89": return "PlagueBugs"
        case "90": return "HellSwarm"
        case "91": return "DungSoldier"
        case "92": return "SandWarrior"
        case "93": return "Scarab"
        case "94": return "SteelWeevil"
        case "95": return "AlbinoRoach"
        case "96": return "DriedCorpse"
        case "97": return "Decayed"
        case "98": return "Embalmed"
        case "99": return "PreservedDead"
        case "100": return "Cadaver"
        case "101": return "HollowOne"
        case "102": return "Guardian"
        case "103": return "Unraveler"
        case "104": return "Horadrim Ancient"
        case "105": return "Baal Subject Mummy"
        case "110": return "CarrionBird"
        case "111": return "UndeadScavenger"
        case "112": return "HellBuzzard"
        case "113": return "WingedNightmare"
        case "114": return "Sucker"
        case "115": return "Feeder"
        case "116": return "BloodHook"
        case "117": return "BloodWing"
        case "118": return "Gloam"
        case "119": return "SwampGhost"
        case "120": return "BurningSoul"
        case "121": return "BlackSoul"
        case "122": return "Arach"
        case "123": return "SandFisher"
        case "124": return "PoisonSpinner"
        case "125": return "FlameSpider"
        case "126": return "SpiderMagus"
        case "127": return "ThornedHulk"
        case "128": return "BrambleHulk"
        case "129": return "Thrasher"
        case "130": return "Spikefist"
        case "131": return "GhoulLord"
        case "132": return "NightLord"
        case "133": return "DarkLord"
        case "134": return "BloodLord"
        case "135": return "Banished"
        case "136": return "DesertWing"
        case "137": return "Fiend"
        case "138": return "Gloombat"
        case "139": return "BloodDiver"
        case "140": return "DarkFamiliar"
        case "141": return "RatMan"
        case "142": return "Fetish"
        case "143": return "Flayer"
        case "144": return "SoulKiller"
        case "145": return "StygianDoll"
        case "156": return "Andariel"
        case "160": return "DarkRanger"
        case "161": return "VileArcher"
        case "162": return "DarkArcher"
        case "163": return "BlackArcher"
        case "164": return "FleshArcher"
        case "165": return "DarkSpearwoman"
        case "166": return "VileLancer"
        case "167": return "DarkLancer"
        case "168": return "BlackLancer"
        case "169": return "FleshLancer"
        case "170": return "SkeletonArcher"
        case "171": return "ReturnedArcher"
        case "172": return "BoneArcher"
        case "173": return "BurningDeadArcher"
        case "174": return "HorrorArcher"
        case "180": return "SandMaggotYoung"
        case "181": return "RockWormYoung"
        case "182": return "DevourerYoung"
        case "183": return "GiantLampreyYoung"
        case "184": return "WorldKillerYoung"
        case "186": return "Blunderbore"
        case "187": return "Gorbelly"
        case "188": return "Mauler"
        case "189": return "Urdar"
        case "190": return "SandMaggotEgg"
        case "191": return "RockWormEgg"
        case "192": return "DevourerEgg"
        case "193": return "GiantLampreyEgg"
        case "194": return "WorldKillerEgg"
        case "206": return "FoulCrowNest"
        case "207": return "BloodHawkNest"
        case "208": return "BlackVultureNest"
        case "209": return "CloudStalkerNest"
        case "211": return "Duriel"
        case "212": return "Undead RatMan"
        case "213": return "Undead Fetish"
        case "214": return "Undead Flayer"
        case "215": return "Undead SoulKiller"
        case "216": return "Undead StygianDoll"
        case "227": return "Maggot"
        case "228": return "MummyGenerator"
        case "229": return "Radament"
        case "234": return "FlyingScimitar"
        case "235": return "Zakarumite"
        case "236": return "Faithful"
        case "237": return "Zealot"
        case "238": return "Sexton"
        case "239": return "Cantor"
        case "240": return "Heirophant"
        case "241": return "Heirophant"
        case "242": return "Mephisto"
        case "243": return "Diablo"
       
        case "247": return "Swamp Dweller"
        case "248": return "Bog Creature"
        case "249": return "Slime Prince"
        case "250": return "Summoner"
        
        case "258": return "WaterWatcherLimb"
        case "259": return "RiverStalkerLimb"
        case "260": return "StygianWatcherLimb"
        case "261": return "WaterWatcherHead"
        case "262": return "RiverStalkerHead"
        case "263": return "StygianWatcherHead"
       
        case "266": return "navi"
        case "267": return "Bloodraven"
        case "270": return "RogueScout"
        case "273": return "GargoyleTrap"
        case "274": return "ReturnedMage"
        case "275": return "BoneMage"
        case "276": return "BurningDeadMage"
        case "277": return "HorrorMage"
        case "278": return "RatManShaman"
        case "279": return "FetishShaman"
        case "280": return "FlayerShaman"
        case "281": return "SoulKillerShaman"
        case "282": return "StygianDollShaman"
        case "283": return "larva"
        case "284": return "SandMaggotQueen"
        case "285": return "RockWormQueen"
        case "286": return "DevourerQueen"
        case "287": return "GiantLampreyQueen"
        case "288": return "WorldKillerQueen"
        case "289": return "ClayGolem"
        case "290": return "BloodGolem"
        case "291": return "IronGolem"
        case "292": return "FireGolem"
        case "295": return "NightMarauder"
        case "297": return "Natalya"
        case "298": return "FleshSpawner"
        case "299": return "StygianHag"
        case "300": return "Grotesque"
        case "301": return "FleshBeast"
        case "302": return "StygianDog"
        case "303": return "GrotesqueWyrm"
        case "304": return "Groper"
        case "305": return "Strangler"
        case "306": return "StormCaster"
        case "307": return "Corpulent"
        case "308": return "CorpseSpitter"
        case "309": return "MawFiend"
        case "310": return "DoomKnight"
        case "311": return "AbyssKnight"
        case "312": return "OblivionKnight"
        case "313": return "QuillBear"
        case "314": return "SpikeGiant"
        case "315": return "ThornBrute"
        case "316": return "RazorBeast"
        case "317": return "GiantUrchin"
        case "326": return "a trap"
        case "327": return "a trap"
        case "328": return "a trap"
        case "329": return "a trap"
        case "330": return "a trap"
        case "333": return "Diablo"
        case "334": return "SuckerNest"
        case "335": return "FeederNest"
        case "336": return "BloodHookNest"
        case "337": return "BloodWingNest"
        case "340": return "skillname88"
        case "341": return "skillname88"
        case "342": return "skillname88"
        case "343": return "skillname88"
        case "345": return "Council Member"
        case "346": return "Council Member"
        case "347": return "Council Member"
        case "348": return "Turret"
        case "349": return "Turret"
        case "350": return "Turret"
        case "351": return "Hydra"
        case "352": return "Hydra"
        case "353": return "Hydra"
        case "354": return "a trap"
        ;case "359": return "Iron Wolf"
        case "360": return "Balrog"
        case "361": return "PitLord"
        case "362": return "VenomLord"
        case "363": return "skeleton"
        case "364": return "skillan80"
        case "365": return "Griswold"
        case "366": return "compellingorb"
        case "368": return "Dark Wanderer" ;"youngdiablo"
        case "369": return "a trap"
        case "371": return "LightningSpire"
        case "372": return "FireTower"
        case "373": return "Slinger"
        case "374": return "SpearCat"
        case "375": return "NightSlinger"
        case "376": return "HellSlinger"
        case "379": return "ReturnedMage"
        case "380": return "BoneMage"
        case "381": return "BaalColdMage"
        case "382": return "HorrorMage"
        case "383": return "ReturnedMage"
        case "384": return "BoneMage"
        case "385": return "BurningDeadMage"
        case "386": return "HorrorMage"
        case "387": return "ReturnedMage"
        case "388": return "BoneMage"
        case "389": return "BurningDeadMage"
        case "390": return "HorrorMage"
        case "391": return "Hell Bovine"
        case "392": return "StrMonsterWindow"
        case "393": return "StrMonsterWindow"
        case "394": return "SpearCat"
        case "395": return "NightSlinger"
        case "396": return "RatMan"
        case "397": return "Fetish"
        case "398": return "Flayer"
        case "399": return "SoulKiller"
        case "400": return "StygianDoll"
        case "402": return "The Smith"
        case "403": return "TrappedSoul"
        case "404": return "TrappedSoul"
        
        case "407": return "RatMan"
        case "408": return "Malachai"
        case "409": return "The Feature Creep"
        case "410": return "Wake of Destruction"
        case "411": return "Charged Bolt Sentry"
        case "412": return "Lightning Sentry"
        case "413": return "Blade Creeper"
        case "414": return "Invis Pet"
        case "415": return "Inferno Sentry"
        case "416": return "Death Sentry"
        case "417": return "Shadow Warrior"
        case "418": return "Shadow Master"
        case "419": return "Druid Hawk"
        case "420": return "Druid Spirit Wolf"
        case "421": return "Druid Fenris"
        case "422": return "Spirit of Barbs"
        case "423": return "Heart of Wolverine"
        case "424": return "Oak Sage"
        case "425": return "Druid Plague Poppy"
        case "426": return "Druid Cycle of Life"
        case "427": return "Vine Creature"
        case "428": return "Druid Bear"
        case "429": return "Eagleexp"
        case "430": return "Wolf"
        case "431": return "Bear"
        case "432": return "Barricade Door"
        case "433": return "Barricade Door"
        case "434": return "Prison Door"
        case "435": return "Barricade Tower"
        case "436": return "RotWalker"
        case "437": return "ReanimatedHorde"
        case "438": return "ProwlingDead"
        case "439": return "UnholyCorpse"
        case "440": return "DefiledWarrior"
        case "441": return "Siege Beast"
        case "442": return "CrushBiest"
        case "443": return "BloodBringer"
        case "444": return "GoreBearer"
        case "445": return "DeamonSteed"
        case "446": return "SnowYeti1"
        case "447": return "SnowYeti2"
        case "448": return "SnowYeti3"
        case "449": return "SnowYeti4"
        case "450": return "WolfRider1"
        case "451": return "WolfRider2"
        case "452": return "WolfRider3"
        case "453": return "Minionexp"
        case "454": return "Slayerexp"
        case "455": return "IceBoar"
        case "456": return "FireBoar"
        case "457": return "HellSpawn"
        case "458": return "IceSpawn"
        case "459": return "GreaterHellSpawn"
        case "460": return "GreaterIceSpawn"
        case "461": return "FanaticMinion"
        case "462": return "BerserkSlayer"
        case "463": return "ConsumedIceBoar"
        case "464": return "ConsumedFireBoar"
        case "465": return "FrenziedHellSpawn"
        case "466": return "FrenziedIceSpawn"
        case "467": return "InsaneHellSpawn"
        case "468": return "InsaneIceSpawn"
        case "469": return "Succubusexp"
        case "470": return "VileTemptress"
        case "471": return "StygianHarlot"
        case "472": return "Hell Temptress"
        case "473": return "Blood Temptress"
        case "474": return "Dominus"
        case "475": return "VileWitch"
        case "476": return "StygianFury"
        case "477": return "Blood Witch"
        case "478": return "Hell Witch"
        case "479": return "OverSeer"
        case "480": return "Lasher"
        case "481": return "OverLord"
        case "482": return "BloodBoss"
        case "483": return "HellWhip"
        case "484": return "MinionSpawner"
        case "485": return "MinionSlayerSpawner"
        case "486": return "MinionIce/fireBoarSpawner"
        case "487": return "MinionIce/fireBoarSpawner"
        case "488": return "Minionice/hellSpawnSpawner"
        case "489": return "MinionIce/fireBoarSpawner"
        case "490": return "MinionIce/fireBoarSpawner"
        case "491": return "Minionice/hellSpawnSpawner"
        case "492": return "Imp1"
        case "493": return "Imp2"
        case "494": return "Imp3"
        case "495": return "Imp4"
        case "496": return "Imp5"
        case "497": return "CatapultS"
        case "498": return "CatapultE"
        case "499": return "CatapultSiege"
        case "500": return "CatapultW"
        case "501": return "Frozen Horror1"
        case "502": return "Frozen Horror2"
        case "503": return "Frozen Horror3"
        case "504": return "Frozen Horror4"
        case "505": return "Frozen Horror5"
        case "506": return "Blood Lord1"
        case "507": return "Blood Lord2"
        case "508": return "Blood Lord3"
        case "509": return "Blood Lord4"
        case "510": return "Blood Lord5"
        
        case "516": return "Catapult Spotter S"
        case "517": return "Catapult Spotter E"
        case "518": return "Catapult Spotter Siege"
        case "519": return "Catapult Spotter W"

        case "522": return "Act 5 Combatant"
        case "523": return "Act 5 Combatant"
        case "524": return "Barricade Wall Right"
        case "525": return "Barricade Wall Left"
        case "526": return "Nihlathak"
        case "527": return "Drehya"
        case "528": return "Evil hut"
        case "529": return "Death Mauler1"
        case "530": return "Death Mauler2"
        case "531": return "Death Mauler3"
        case "532": return "Death Mauler4"
        case "533": return "Death Mauler5"
        case "534": return "POW"
        case "535": return "Act 5 Townguard"
        case "536": return "Act 5 Townguard"
        case "537": return "Ancient Statue 1"
        case "538": return "Ancient Statue 2"
        case "539": return "Ancient Statue 3"
        case "540": return "Ancient Barbarian 1"
        case "541": return "Ancient Barbarian 2"
        case "542": return "Ancient Barbarian 3"
        case "543": return "Baal Throne"
        case "544": return "Baal Crab"
        case "545": return "Baal Taunt"
        case "546": return "Putrid Defiler1"
        case "547": return "Putrid Defiler2"
        case "548": return "Putrid Defiler3"
        case "549": return "Putrid Defiler4"
        case "550": return "Putrid Defiler5"
        case "551": return "Pain Worm1"
        case "552": return "Pain Worm2"
        case "553": return "Pain Worm3"
        case "554": return "Pain Worm4"
        case "555": return "Pain Worm5"
        case "556": return "Bunny"
        case "557": return "Council Member"
        case "558": return "VenomLord"
        case "559": return "Baal Crab to Stairs"
        case "560": return "Act 5 Hireling 1hs"
        case "561": return "Act 5 Hireling 2hs"
        case "562": return "Baal Tentacle"
        case "563": return "Baal Tentacle"
        case "564": return "Baal Tentacle"
        case "565": return "Baal Tentacle"
        case "566": return "Baal Tentacle"
        case "567": return "Injured Barbarian 1"
        case "568": return "Injured Barbarian 2"
        case "569": return "Injured Barbarian 3"
        case "570": return "Baal Crab Clone"
        case "571": return "Baals Minion"
        case "572": return "Baals Minion"
        case "573": return "Baals Minion"
        case "574": return "Worldstone Effect"
        case "575": return "BurningDeadArcher"
        case "576": return "BoneArcher"
        case "577": return "BurningDeadArcher"
        case "578": return "ReturnedArcher"
        case "579": return "HorrorArcher"
        case "580": return "Afflicted"
        case "581": return "Tainted"
        case "582": return "Misshapen"
        case "583": return "Disfigured"
        case "584": return "Damned"
        case "585": return "MoonClan"
        case "586": return "NightClan"
        case "587": return "HellClan"
        case "588": return "BloodClan"
        case "589": return "DeathClan"
        case "590": return "FoulCrow"
        case "591": return "BloodHawk"
        case "592": return "BlackRaptor"
        case "593": return "CloudStalker"
        case "594": return "ClawViper"
        case "595": return "PitViper"
        case "596": return "Salamander"
        case "597": return "TombViper"
        case "598": return "SerpentMagus"
        case "599": return "Marauder"
        case "600": return "Infidel"
        case "601": return "SandRaider"
        case "602": return "Invader"
        case "603": return "Assailant"
        case "604": return "Death Mauler1"
        case "605": return "QuillRat"
        case "606": return "SpikeFiend"
        case "607": return "RazorSpine"
        case "608": return "CarrionBird"
        case "609": return "ThornedHulk"
        case "610": return "Slinger"
        case "611": return "Slinger"
        case "612": return "Slinger"
        case "613": return "VileArcher"
        case "614": return "DarkArcher"
        case "615": return "VileLancer"
        case "616": return "DarkLancer"
        case "617": return "BlackLancer"
        case "618": return "Blunderbore"
        case "619": return "Mauler"
        case "620": return "ReturnedMage"
        case "621": return "BurningDeadMage"
        case "622": return "ReturnedMage"
        case "623": return "HorrorMage"
        case "624": return "BoneMage"
        case "625": return "HorrorMage"
        case "626": return "HorrorMage"
        case "627": return "Huntress"
        case "628": return "SaberCat"
        case "629": return "CaveLeaper"
        case "630": return "TombCreeper"
        case "631": return "Ghost"
        case "632": return "Wraith"
        case "633": return "Specter"
        case "634": return "Succubusexp"
        case "635": return "Hell Temptress"
        case "636": return "Dominus"
        case "637": return "Hell Witch"
        case "638": return "VileWitch"
        case "639": return "Gloam"
        case "640": return "BlackSoul"
        case "641": return "BurningSoul"
        case "642": return "Carver"
        case "643": return "Devilkin"
        case "644": return "DarkOne"
        case "645": return "CarverShaman"
        case "646": return "DevilkinShaman"
        case "647": return "DarkShaman"
        case "648": return "BoneWarrior"
        case "649": return "Returned"
        case "650": return "Gloombat"
        case "651": return "Fiend"
        case "652": return "Blood Lord1"
        case "653": return "Blood Lord4"
        case "654": return "Scarab"
        case "655": return "SteelWeevil"
        case "656": return "Flayer"
        case "657": return "StygianDoll"
        case "658": return "SoulKiller"
        case "659": return "Flayer"
        case "660": return "StygianDoll"
        case "661": return "SoulKiller"
        case "662": return "FlayerShaman"
        case "663": return "StygianDollShaman"
        case "664": return "SoulKillerShaman"
        case "665": return "TempleGuard"
        case "666": return "TempleGuard"
        case "667": return "Guardian"
        case "668": return "Unraveler"
        case "669": return "Horadrim Ancient"
        case "670": return "Horadrim Ancient"
        case "671": return "Zealot"
        case "672": return "Zealot"
        case "673": return "Heirophant"
        case "674": return "Heirophant"
        case "675": return "Grotesque"
        case "676": return "FleshSpawner"
        case "677": return "GrotesqueWyrm"
        case "678": return "FleshBeast"
        case "679": return "WorldKiller"
        case "680": return "WorldKillerYoung"
        case "681": return "WorldKillerEgg"
        case "682": return "Slayerexp"
        case "683": return "HellSpawn"
        case "684": return "GreaterHellSpawn"
        case "685": return "Arach"
        case "686": return "Balrog"
        case "687": return "PitLord"
        case "688": return "Imp1"
        case "689": return "Imp4"
        case "690": return "Undead StygianDoll"
        case "691": return "Undead SoulKiller"
        case "692": return "Strangler"
        case "693": return "StormCaster"
        case "694": return "MawFiend"
        case "695": return "BloodLord"
        case "696": return "GhoulLord"
        case "697": return "DarkLord"
        case "698": return "UnholyCorpse"
        case "699": return "DoomKnight"
        case "700": return "DoomKnight"
        case "701": return "OblivionKnight"
        case "702": return "OblivionKnight"
        case "703": return "Cadaver"
        case "704": return "Mephisto"
        case "705": return "Diablo"
        case "706": return "izual"
        case "707": return "Lilith"
        case "708": return "Duriel"
        case "709": return "Baal Crab"
        case "710": return "Evil hut"
        case "712": return "PitLord"
        case "713": return "OblivionKnight"
        case "714": return "Imp4"
        case "715": return "HellSwarm"
        case "716": return "WorldKiller"
        case "717": return "Arach"
        case "718": return "SteelWeevil"
        case "719": return "Hell Temptress"
        case "720": return "VileWitch"
        case "721": return "FleshHunter"
        case "722": return "DarkArcher"
        case "723": return "BlackLancer"
        case "724": return "HellWhip"
        case "725": return "Returned"
        case "726": return "HorrorArcher"
        case "727": return "BurningDeadMage"
        case "728": return "HorrorMage"
        case "729": return "BoneMage"
        case "730": return "HorrorMage"
        case "731": return "DarkLord"
        case "732": return "Specter"
        case "733": return "BurningSoul"
        case "735": return "Hell Bovine"
        case "736": return "PlagueBearer"
       
    }
    return ""
}
