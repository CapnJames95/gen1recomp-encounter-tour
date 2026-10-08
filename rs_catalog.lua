-- Resolve the active edition's native object positions and symbolic flags.
-- No imported map/script data is packaged here.
return function(version,includeRoamer)
 assert(version=='ruby' or version=='sapphire','RS catalogue requires its own edition')
 local C=require('src.core.game3.constants').of(version)
 local bundle=require('src.core.game3.scripting.space').ensureBundle()
 local rows={}
 local function add(id,name,species,level,category,hide,extra)
  local flag=C:require('flags','FLAG_'..hide)
  local found
  for map,ev in pairs(bundle.events or {})do
   for _,o in ipairs(ev.objects or {})do if o.flag==flag and not (version=="ruby" and map:find("AQUA_HIDEOUT") or version=="sapphire" and map:find("MAGMA_HIDEOUT")) then
    assert(not found,'Ambiguous native object for '..hide)
    local clear={flag};for _,n in ipairs(extra or {})do clear[#clear+1]=C:require('flags','FLAG_'..n)end
    found={id=id,name=name,species=species,level=level,category=category,version=version,
     map=map,object=o.localId,targetX=o.x,targetY=o.y,x=o.x,y=o.y+1,facing='up',flag=flag,clear=clear,
     note='Use the native encounter. Normal story requirements apply. Leave its map before resetting.'}
   end end
  end
  assert(found,'Missing native object for '..hide)
  rows[#rows+1]=found
  return found
 end
 add('regirock','Regirock',377,40,'Legendaries','HIDE_REGIROCK')
 add('regice','Regice',378,40,'Legendaries','HIDE_REGICE')
 add('registeel','Registeel',379,40,'Legendaries','HIDE_REGISTEEL')
 add('rayquaza','Rayquaza',384,70,'Legendaries','HIDE_RAYQUAZA')
 add('beldum','Beldum',374,5,'Gifts & eggs','HIDE_BELDUM_BALL_STEVENS_HOUSE',{'RECEIVED_BELDUM'})
 for i=1,3 do add('voltorb_'..i,'Voltorb '..i,100,25,'Static battles','HIDE_VOLTORB_'..i..'_NEW_MAUVILLE')end
 for i=1,2 do add('electrode_'..i,'Electrode '..i,101,30,'Static battles','HIDE_ELECTRODE_'..i..'_HIDEOUT')end
 -- Repeatable Kecleon objects exclude Steven's first story demonstration and
 -- Fortree's fleeing roadblock; their scene variables must not be rewound.
 for i=2,7 do add('kecleon_120_'..i,'Kecleon Route 120 / '..i,352,30,'Static battles','HIDE_KECLEON_ROUTE120_'..i)end
 for i=1,2 do add('kecleon_119_'..i,'Kecleon Route 119 / '..i,352,30,'Static battles','HIDE_KECLEON_ROUTE119_'..i)end
 local prefix=require('src.core.game3.profile').of(version).map.enginePrefix
 local function reward(id,name,species,level,category,map,localId,completion,note)
  map=prefix..map
  local object
  for _,o in ipairs(assert(bundle.events[map],map).objects or {})do if o.localId==localId then object=o end end
  assert(object,'Missing native reward object '..id)
  local clear=completion and {C:require('flags','FLAG_'..completion)} or {}
  local r={id=id,name=name,species=species,level=level,category=category,version=version,map=map,object=localId,
   targetX=object.x,targetY=object.y,x=object.x,y=object.y+1,facing='up',clear=clear,flag=clear[1],completionOnly=true,note=note}
  rows[#rows+1]=r;return r
 end
 reward('wynaut','Wynaut egg',360,5,'Gifts & eggs','LAVARIDGE_TOWN',9,'RECEIVED_LAVARIDGE_EGG','Talk to the egg woman with a free party slot. Only the gift receipt is reset; the egg hatches normally.')
 local castform=reward('castform','Castform',351,25,'Gifts & eggs','ROUTE119_WEATHER_INSTITUTE_2F',5,'RECEIVED_CASTFORM','Clear the Weather Institute first, then speak to the scientist. Reset changes only the gift receipt.')
 castform.requiredVar=C:require('vars','VAR_WEATHER_INSTITUTE_STATE');castform.requiredValue=1
 castform.requirement='Clear the enemy team from the Weather Institute first.'
 castform.x=4;castform.y=7;castform.approach=true
 local P=require('src.core.game3.pokemon');local Trade=require('src.core.game3.scripting.natives_trade')
 for i,t in ipairs({{'RUSTBORO_CITY_HOUSE1',1,'RUSTBORO_NPC_TRADE_COMPLETED'},{'FORTREE_CITY_HOUSE1',1,'FORTREE_NPC_TRADE_COMPLETED'},{'PACIFIDLOG_TOWN_HOUSE3',2,'PACIFIDLOG_NPC_TRADE_COMPLETED'}})do
  local native=assert(Trade.entry(i-1),'Missing native NPC trade')
  local r=reward('npc_trade_'..i,P.name(native.species)..' trade',P.national(native.species),0,'NPC trades',t[1],t[2],t[3],'Use the native NPC trade. The offered Pokemon is still required; only the completion flag is reset.')
  r.trade=true
 end
 for _,f in ipairs({{'lileep','Lileep',345,'ROOT_FOSSIL'},{'anorith','Anorith',347,'CLAW_FOSSIL'}})do
  local r=reward(f[1],f[2],f[3],20,'Fossils','RUSTBORO_CITY_DEVON_CORP_2F',5,nil,'Give the matching fossil to the Devon scientist, leave and return. Reset supplies one missing fossil without replacing a pending revival.')
  r.nativeFossil=C:require('items','ITEM_'..f[4])
 end
 local eon=reward('eon_ticket',version=='ruby' and 'Latias (Southern Island)' or 'Latios (Southern Island)',version=='ruby' and 380 or 381,50,'Event islands','SOUTHERN_ISLAND_INTERIOR',1,'ENCOUNTERED_LATIAS_OR_LATIOS','Use the native island altar. The Eon Ticket must already be received. Only the island encounter flag is reset, not the roaming Pokemon or ferry story.')
 eon.x=13;eon.y=12;eon.targetX=13;eon.targetY=11;eon.object=nil
 eon.requiredFlag=C:require('flags','FLAG_SYS_HAS_EON_TICKET');eon.requirement='Receive the Eon Ticket before visiting or resetting Southern Island.'
 if includeRoamer then
  rows[#rows+1]={id='rs_roamer',name=version=='ruby' and 'Latios (roamer)' or 'Latias (roamer)',species=version=='ruby' and 381 or 380,level=40,category='Roaming beasts',version=version,roamer=true,clear={},map='Hoenn routes',
   note='Restores only the previously unlocked native roamer after capture or defeat. Native Ruby/Sapphire generation and IV behaviour are preserved.'}
 end
 return rows
end
