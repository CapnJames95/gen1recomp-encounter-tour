return function(mod)
  assert(load(assert(mod:read("native_legality.lua")), "@encounter-tour/native_legality.lua"))().install(mod)
  local function module(name) return assert(load(assert(mod:read(name..'.lua')),'@encounter_tour/'..name..'.lua'))() end
  local rows=module('catalog');local E=module('adapter')(mod)
  local frlgRows={};for i,r in ipairs(rows) do frlgRows[i]=r end
  local emeraldRows
  function E.refreshCatalog(s)
    local source=frlgRows
    if s and s.version=='emerald' then emeraldRows=emeraldRows or module('emerald_catalog');source=emeraldRows end
    for i=#rows,1,-1 do rows[i]=nil end
    for i,r in ipairs(source) do rows[i]=r end
  end

  local C=module('controller')(rows,E);local V=module('view')(E);local S=module('screen')(rows,E,C,V)
  local Stack=require('src.ui.game3.stack');local Help=require('src.ui.game3.help_system')
  mod.exports.dualScreenProtocol=1
  mod.exports.dualScreenBusy=function() return C.tour==true end
  local lease
  local function restoreHelp() if lease then Help.setContext(lease.previous);lease=nil end end
  local function safe(fn)
    local ok,why=pcall(fn)
    if not ok then C.stop();C.message='Encounter Tour error: '..tostring(why);S.notice=C.message;mod.log:error('%s',C.message) end
  end
  mod.hooks:wrap('ui.start_menu.items',function(next,game,items)
    local result=next(game,items);local s=E.session()
    if type(result)~='table' or not s or (s.version~='firered' and s.version~='leafgreen' and s.version~='emerald') then return result end
    for _,r in ipairs(result) do if r.id=='encounter_tour' then return result end end
    local at=#result+1;for i,r in ipairs(result) do if r.id=='save' then at=i;break end end
    table.insert(result,at,{id='encounter_tour',label='ENCOUNTER TOUR',onSelect=function() E.game=game;safe(S.show) end})
    return result
  end)
  mod.hooks:wrap('core.update',function(next,game,dt)
    E.game=game
    if game.generation~=3 then if S.active then S.hide() end;C.stop();restoreHelp();return next(game,dt) end
    local old=C.session;C.bind()
    if old and old~=C.session and S.active then S.hide() end
    if S.active and not S._frlgDetached then
      if not Stack.has('encounter_tour') then S.active=false;restoreHelp();return next(game,dt) end
      if not lease then lease={previous=Help.contextOverride} end;Help.setContext(0)
      if game.input then
        if game.input.setButtonAlias then game.input:setButtonAlias('l',nil) end
        game.input:step();safe(function() S.handleInput(game.input) end)
      end
      return
    end
    restoreHelp()
    if C.tour and game.input then
      for _,button in ipairs(game.input.pressQueue or {}) do
        if button=='start' then C.stop();break end
      end
    end
    -- Other overlays (including Shiny Hunter) retain ownership of the field.
    if not Stack.top() then safe(function() C.tick(dt) end) end
    return next(game,dt)
  end)
  mod.hooks:wrap('render.hud',function(next,game,viewport)
    next(game,viewport)
    if S.active and not S._frlgDetached and game==E.game then
      love.graphics.push('all');love.graphics.translate(viewport.gameX or 0,viewport.gameY or 0)
      love.graphics.scale((viewport.gameWidth or 240)/240,(viewport.gameHeight or 160)/160)
      S.draw();love.graphics.pop()
    end
  end)
end
