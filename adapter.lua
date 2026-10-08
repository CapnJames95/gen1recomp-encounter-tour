return function(mod)
  local E={}
  local Runtime=require('src.core.game3.runtime')
  local Map=require('src.core.game3.map')
  local Catalog=require('src.import.gba.map_catalog')
  local Space=require('src.core.game3.scripting.space')
  local Flags=require('src.core.game3.scripting.flags')
  local Player=require('src.core.game3.player')
  local Warp=require('src.core.game3.warp')
  local Field=require('src.core.game3.field')
  local Battle=require('src.core.game3.battle')
  local Fade=require('src.ui.game3.fade')
  local P=require('src.core.CollPermissions')
  local Collision=require('src.core.game3.collision')
  local Pokemon=require('src.core.game3.pokemon')
  E.session=Runtime.getSession
  E.pokemon=Pokemon
  function E.ready()
    local s=E.session()
    if not s or (s.version~='firered' and s.version~='leafgreen' and s.version~='emerald' and s.version~='ruby' and s.version~='sapphire') or not E.game or E.game.phase~='field' then return false,'Load a supported Gen 3 field save.' end
    if Battle.isActive() or require('src.core.game3.battle_transition').isActive() or Field.locked or Player.moving or Warp.isBusy() or Fade.isActive()
      or (Space.vm and Space.vm:isRunning()) or (Space._immediateVm and Space._immediateVm:isRunning()) then
      return false,'Finish the battle, dialogue or movement first.'
    end
    if (s.version=='ruby' or s.version=='sapphire') and tostring(Map.current):find('BATTLE_TOWER',1,true) then return false,'Leave the Battle Tower before using this tool.' end
    if s.version=='emerald' and s.frontier and (s.frontier.challengeStatus or 0)~=0 then return false,'Finish the Battle Frontier challenge first.' end
    if E.game.speedLocked and E.game:speedLocked() then return false,'Finish the linked activity first.' end
    if require('src.core.game3.safari').isActive(s) then return false,'Leave the Safari game before teleporting.' end
    return true
  end
  function E.done(e)
    if e.eon then for _,id in ipairs(e.clear) do if Flags.getFlag(Space.store,nil,id) then return true end end end
    if e.flag and Flags.getFlag(Space.store,nil,e.flag) then return true end
    return e.storyVar and Flags.getVar(Space.store,nil,e.storyVar)>=(e.storyDoneAt or 1) or false
  end
  function E.species(e)
    if e.eon then
      local C=require('src.core.game3.constants').of('emerald')
      local choice=Flags.getVar(Space.store,nil,C:require('vars','VAR_ROAMER_POKEMON'))
      return Pokemon.speciesFromNational(choice==0 and 381 or 380)
    end
    local nat=E.session().version=='leafgreen' and e.leafgreenSpecies or e.species
    return Pokemon.speciesFromNational(nat) or nat
  end
  function E.count(e)
    local s=E.session(); local id=E.species(e);local n=0
    local function mon(m) if m and (m.species or m.speciesId)==id then n=n+1 end end
    for _,m in pairs(s.party or {}) do mon(m) end
    for _,b in pairs((s.storage or {}).boxes or {}) do for _,m in pairs(b.mons or {}) do mon(m) end end
    return n
  end
  function E.position()
    return {map=Map.current,x=Player.cellX,y=Player.cellY,facing=Player.facing,surfing=Player.surfing==true,biking=Player.biking==true,bikeType=Player.bikeType,underwater=Player.underwater==true}
  end
  function E.destination(e)
    if e.requiredFlag and not Flags.getFlag(Space.store,nil,e.requiredFlag) then return nil,e.requirement end
    if e.requiredVar and Flags.getVar(Space.store,nil,e.requiredVar)<e.requiredValue then return nil,e.requirement end
    local id=(e.map:match('^[A-Z][A-Z]_') and e.map or Catalog.pretToEngine(e.map))
    local def=E.game and E.game.data and E.game.data.maps[id]
    local layout=def and Map.ensureMidLayout(E.game,id,def)
    if not layout then return nil,'This map is missing from the loaded game.' end
    local ev=Space.bundle and Space.bundle.events and Space.bundle.events[id]
    if not ev then return nil,'Encounter scripts are unavailable.' end
    local function clear(x,y)
      if x<0 or y<0 or x>=layout.width or y>=layout.height then return false end
      local c=layout:collAt(x,y)
      if not P.isWalkable(c) or P.isLedge(c) or Collision.isWarpMetatileBehavior(Collision.behaviorOn(def,x,y)) then return false end
      for _,w in ipairs(def.warps or {}) do if w.x==x and w.y==y then return false end end
      for _,o in ipairs(ev.objects or {}) do if o.x==x and o.y==y then return false end end
      for _,o in ipairs(ev.coordEvents or {}) do if o.x==x and o.y==y then return false end end
      return true
    end
    local choices={{e.x,e.y,e.facing}}
    if e.targetX then
      -- Adjacent alternatives handle blocked tiles south of Snorlax/Electrode.
      choices[#choices+1]={e.targetX,e.targetY+1,'up'}
      choices[#choices+1]={e.targetX,e.targetY-1,'down'}
      choices[#choices+1]={e.targetX+1,e.targetY,'left'}
      choices[#choices+1]={e.targetX-1,e.targetY,'right'}
    end
    for _,p in ipairs(choices) do if clear(p[1],p[2]) then return {map=id,x=p[1],y=p[2],facing=p[3]} end end
    return nil,'No safe landing tile beside this encounter.'
  end
  function E.warp(p)
    local ready,why=E.ready();if not ready then return false,why end
    local ok,result,err=pcall(Warp.request,nil,E.game,p.map,p.x,p.y,p.facing,{fade=false,se=false})
    if not ok or not result then return false,'Teleport failed: '..tostring(err or result) end
    -- Map.load runs normal entry scripts and resets the avatar; restore only
    -- valid traversal state at the saved return point.
    Player.surfing=p.surfing==true;Player.biking=p.biking==true;Player.bikeType=p.bikeType;Player.underwater=p.underwater==true
    Player.facing=p.facing;Player.syncSavePosition(E.game)
    return true
  end
  return E
end
