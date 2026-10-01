-- Emerald-only native encounter records. Symbolic constants are edition-specific.
local C=require('src.core.game3.constants').of('emerald')
local function flag(name) return C:require('flags','FLAG_'..name) end
local rows={}
local function add(id,name,species,level,category,map,object,x,y,names,note)
 local clear={};for _,n in ipairs(names) do clear[#clear+1]=flag(n) end
 rows[#rows+1]={id=id,name=name,species=species,level=level,category=category,map='EM_'..map,
  object=object,x=x,y=y+1,facing='up',targetX=x,targetY=y,flag=clear[1],clear=clear,
  version='emerald',note=note or 'Interact for the native encounter. Normal story requirements apply.'}
 return rows[#rows]
end
add("regirock","Regirock",377,40,"Legendaries","DESERT_RUINS",1,8,7,{"HIDE_REGIROCK","DEFEATED_REGIROCK"})
add("regice","Regice",378,40,"Legendaries","ISLAND_CAVE",1,8,7,{"HIDE_REGICE","DEFEATED_REGICE"})
add("registeel","Registeel",379,40,"Legendaries","ANCIENT_TOMB",1,8,7,{"HIDE_REGISTEEL","DEFEATED_REGISTEEL"})
add("rayquaza","Rayquaza",384,70,"Legendaries","SKY_PILLAR_TOP",2,14,6,{"HIDE_SKY_PILLAR_TOP_RAYQUAZA_STILL","DEFEATED_RAYQUAZA"},"Complete the Sootopolis story first, then return for the level-70 battle.")
add("lugia","Lugia",249,70,"Event islands","NAVEL_ROCK_BOTTOM",1,11,13,{"HIDE_LUGIA","DEFEATED_LUGIA","CAUGHT_LUGIA"})
add("ho_oh","Ho-Oh",250,70,"Event islands","NAVEL_ROCK_TOP",1,12,4,{"HIDE_HO_OH","DEFEATED_HO_OH","CAUGHT_HO_OH"})
add("deoxys","Deoxys",386,30,"Event islands","BIRTH_ISLAND_EXTERIOR",1,15,12,{"HIDE_BIRTH_ISLAND_DEOXYS_TRIANGLE","DEFEATED_DEOXYS","BATTLED_DEOXYS","DEOXYS_ROCK_COMPLETE"},"Solve the native triangle puzzle. Teleport bypasses ferry access.")
add("beldum","Beldum",374,5,"Gifts & eggs","MOSSDEEP_CITY_STEVENS_HOUSE",2,4,3,{"HIDE_MOSSDEEP_CITY_STEVENS_HOUSE_BELDUM_POKEBALL","RECEIVED_BELDUM"},"Collect the Poke Ball after becoming Champion. Keep a free party slot.")
add("sudowoodo","Sudowoodo",185,40,"Static battles","BATTLE_FRONTIER_OUTSIDE_EAST",14,54,62,{"HIDE_BATTLE_FRONTIER_SUDOWOODO","DEFEATED_SUDOWOODO"},"Use the Wailmer Pail from your bag while facing Sudowoodo.")
add("voltorb_1","Voltorb 1",100,25,"Static battles","NEW_MAUVILLE_INSIDE",6,25,18,{"HIDE_NEW_MAUVILLE_VOLTORB_1"})
add("voltorb_2","Voltorb 2",100,25,"Static battles","NEW_MAUVILLE_INSIDE",7,6,11,{"HIDE_NEW_MAUVILLE_VOLTORB_2"})
add("voltorb_3","Voltorb 3",100,25,"Static battles","NEW_MAUVILLE_INSIDE",8,13,10,{"HIDE_NEW_MAUVILLE_VOLTORB_3"})
add("electrode_1","Electrode 1",101,30,"Static battles","AQUA_HIDEOUT_B1F",6,16,9,{"HIDE_AQUA_HIDEOUT_B1F_ELECTRODE_1"})
add("electrode_2","Electrode 2",101,30,"Static battles","AQUA_HIDEOUT_B1F",8,16,10,{"HIDE_AQUA_HIDEOUT_B1F_ELECTRODE_2"})
local kyogre=add("kyogre","Kyogre",382,70,"Legendaries","MARINE_CAVE_END",1,9,22,{"HIDE_MARINE_CAVE_KYOGRE","DEFEATED_KYOGRE"},"Walk north to trigger the battle. The Marine Cave weather quest must already be active.")
kyogre.y=27;kyogre.approach=true
local groudon=add("groudon","Groudon",383,70,"Legendaries","TERRA_CAVE_END",1,17,22,{"HIDE_TERRA_CAVE_GROUDON","DEFEATED_GROUDON"},"Walk north to trigger the battle. The Terra Cave weather quest must already be active.")
groudon.y=27;groudon.approach=true
local eon=add("eon_ticket","Eon Ticket encounter",381,50,"Event islands","SOUTHERN_ISLAND_INTERIOR",1,13,12,{"CAUGHT_LATIAS_OR_LATIOS","DEFEATED_LATIAS_OR_LATIOS"},"Interact with the island altar. The species is the opposite of your TV-choice roamer. Event ticket access requirements still apply.")
eon.flag=nil;eon.eon=true
for _,r in ipairs(rows) do
 if r.id=='ho_oh' then r.y=11;r.approach=true;r.note='Walk north to trigger the native Ho-Oh battle. Teleport bypasses ferry access.' end
 if r.id=='deoxys' then r.set={flag('HIDE_DEOXYS')} end
end
-- Rewards with independent completion flags; no story variables are rewound.
local function reward(id,name,species,level,category,map,object,x,y,flagName,note)
 local r=add(id,name,species,level,category,map,object,x,y,{flagName},note)
 r.completionOnly=true
 return r
end
reward('wynaut','Wynaut egg',360,5,'Gifts & eggs','LAVARIDGE_TOWN',9,4,7,'RECEIVED_LAVARIDGE_EGG','Talk to the egg woman. Requires a free party slot; hatches normally.')
local castform=reward('castform','Castform',351,25,'Gifts & eggs','ROUTE119_WEATHER_INSTITUTE_2F',5,18,6,'RECEIVED_CASTFORM','After clearing Team Aqua, speak to the scientist. Reset changes only the gift receipt, not the Weather Institute story.')
castform.x=4;castform.y=7;castform.approach=true
castform.requiredVar=C:require('vars','VAR_WEATHER_INSTITUTE_STATE');castform.requiredValue=1
castform.requirement='Clear Team Aqua from the Weather Institute first.'
local trades={
 {'seedot_trade','Seedot trade',273,'RUSTBORO_CITY_HOUSE1',1,6,4,'RUSTBORO_NPC_TRADE_COMPLETED','Ralts'},
 {'plusle_trade','Plusle trade',311,'FORTREE_CITY_HOUSE1',1,1,3,'FORTREE_NPC_TRADE_COMPLETED','Volbeat'},
 {'horsea_trade','Horsea trade',116,'PACIFIDLOG_TOWN_HOUSE3',2,4,2,'PACIFIDLOG_NPC_TRADE_COMPLETED','Bagon'},
 {'meowth_trade','Meowth trade',52,'BATTLE_FRONTIER_LOUNGE6',1,2,4,'BATTLE_FRONTIER_TRADE_DONE','Skitty'},
}
for _,t in ipairs(trades)do
 local r=reward(t[1],t[2],t[3],0,'NPC trades',t[4],t[5],t[6],t[7],t[8],'Trade your '..t[9]..' through the native NPC trade. Original identity and normal payment are retained.')
 r.trade=true
end
for _,f in ipairs({{'lileep','Lileep',345,'ROOT_FOSSIL'},{'anorith','Anorith',347,'CLAW_FOSSIL'}})do
 local r=add(f[1],f[2],f[3],20,'Fossils','RUSTBORO_CITY_DEVON_CORP_2F',5,14,8,{},'Give the matching fossil to the Devon scientist, leave the room and return. Reset supplies one fossil only if absent; an unfinished revival cannot be replaced.')
 r.completionOnly=true;r.nativeFossil=C:require('items','ITEM_'..f[4])
end
-- This post-Pokedex reward has its own choice state, separate from the Hoenn rescue.
for _,j in ipairs({{'cyndaquil',155,4,8},{'totodile',158,5,9},{'chikorita',152,6,10}})do
 local r=add(j[1],j[1]:sub(1,1):upper()..j[1]:sub(2),j[2],5,'Johto starters','LITTLEROOT_TOWN_PROFESSOR_BIRCHS_LAB',j[3],6,8,{},'Birch must already have awarded a Johto starter. Reset reopens the shared choice of one of three; it does not change your original Hoenn starter or story.')
 r.completionOnly=true;r.johto=true;r.x=j[4];r.y=5;r.approach=true
 r.storyVar=C:require('vars','VAR_DEX_UPGRADE_JOHTO_STARTER_STATE');r.storyDoneAt=6
 r.requiredVar=r.storyVar;r.requiredValue=5;r.requirement="Earn Birch's Johto starter reward through the Hoenn Pokedex quest first."
end
-- Original rescue choice remains a shared, one-time native story event.
for _,v in ipairs({{'treecko','Treecko',252},{'torchic','Torchic',255},{'mudkip','Mudkip',258}}) do
 local r=add(v[1],v[2],v[3],5,'Starters','ROUTE101',3,7,14,{'HIDE_ROUTE_101_BIRCH_STARTERS_BAG'},'Original Birch rescue: choose one starter from the bag while the story offers it. After the Pokedex, Encounter Reset can prepare repeat gifts here without changing the story.')
 r.completionOnly=true
end
return rows
