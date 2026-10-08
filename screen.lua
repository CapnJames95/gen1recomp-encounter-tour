return function(rows,E,C,V)
  local S={pages={},C=C,active=false}
  local Stack=require('src.ui.game3.stack')
  local categories={'Starters','Johto starters','Legendaries','Event islands','Static battles','Gifts & eggs','Fossils','Game Corner','NPC trades'}
  local function push(title,r,entry) S.notice=nil;S.pages[#S.pages+1]={title=title,rows=r,cursor=1,entry=entry} end
  local function back() S.notice=nil;if #S.pages>1 then table.remove(S.pages) else S.hide() end end
  local function info(title,message)
    local r={};for _,line in ipairs(V.wrap(message,210)) do r[#r+1]={label=line} end
    r[#r+1]={label='Back',action=back};push(title,r)
  end
  local function act(fn)
    local ok,why=fn();if ok then S.hide() else info('CANNOT TELEPORT',why or 'Try again from the field.') end
  end
  local function detail(e)
    push(e.name:upper(),{
      {label='Teleport here',help=e.note,action=function() act(function() return C.go(e,false) end) end},
      {label='Tour from here',help='Advances after completion. Use Next to skip.',action=function() act(function() return C.go(e,true) end) end},
      {label=function() return not C.available(e) and 'Other version' or E.done(e) and 'Already resolved' or 'Not resolved' end,help='Story requirements still apply. Resolved may mean defeated or claimed.'},
      {label='Requirements',help=e.note,action=function() info('ENCOUNTER NOTES',e.note) end},
      {label='Location',help=e.map,action=function() info('LOCATION',e.map:gsub('_',' ')) end},
      {label='Back',action=back},
    },e)
  end
  local function list(category)
    local r={}
    for _,entry in ipairs(rows) do local e=entry
      if not category or e.category==category then
        r[#r+1]={label=function() return (not C.available(e) and '[X] ' or E.done(e) and '[DONE] ' or '')..e.name end,help=e.note,action=function() detail(e) end}
      end
    end
    push(category and category:upper() or 'ALL ENCOUNTERS',r)
  end
  local function browse()
    local r={{label='All '..#rows..' entries',action=function() list() end}}
    for _,name in ipairs(categories) do
      local cat=name
      for _,entry in ipairs(rows) do
        if entry.category==cat then
          r[#r+1]={label=cat,action=function() list(cat) end};break
        end
      end
    end
    push('ENCOUNTER CATEGORIES',r)
  end
  local function controls()
    push('TOUR CONTROLS',{
      {label='Start new automatic tour',help='Skips resolved and other-version entries.',action=function() act(C.start) end},
      {label='Next / skip encounter',help='Moves to the next unresolved entry in catalogue order.',action=function() act(C.next) end},
      {label='Pause automatic tour',help='Stay here and play normally.',action=function() C.stop();S.notice=C.message end},
      {label='Current stop',help=C.message,action=function() info('TOUR STATUS',C.message) end},
      {label='How it works',action=function() info('AUTOMATIC TOUR','You interact, battle and catch normally. After a claim or completion flag, the tour waits until dialogue, movement and battle finish, then teleports onward. Use Next to skip a locked encounter. No battles or captures are automated.') end},
      {label='Back',action=back},
    })
  end
  local function extras()
    if E.session().version=='ruby' or E.session().version=='sapphire' then
      info('HOENN COVERAGE','Latios roams Ruby; Latias roams Sapphire. Southern Island has the opposite Pokemon and requires the Eon Ticket. Gifts, fossils and NPC trades use native scripts and normal requirements. Repeat starters are in Encounter Reset. Mascot story scenes and the first Steven Kecleon scene are not replayed. No Aurora, Mystic Ticket or Old Sea Map islands exist in these games.')
      return
    end
    if E.session().version=='emerald' then
      info('HOENN COVERAGE','Latias or Latios roams Hoenn according to your TV choice. Old Sea Map Mew requires a Japanese Emerald origin, so no English-ROM teleport is offered. Starter selection, fossils, NPC trades and story gifts not listed here must be reached normally. The catalogue covers verified static destinations; teleporting does not unlock story requirements.')
      return
    end
    push('OTHER SPECIAL POKEMON',{
      {label='Raikou / Entei / Suicune',help='Roamers have no fixed static encounter.',action=function() info('ROAMING BEAST','The beast unlocked by your starter roams Kanto after the Network Machine quest. It moves when you change maps, so this menu does not promise a fixed teleport encounter. Use wild hunting or the Shiny Hunter mod.') end},
      {label='Mew / Celebi / Jirachi',help='External distributions; no FRLG map encounter.',action=function() info('DISTRIBUTION POKEMON','These Pokemon have no native FireRed or LeafGreen encounter map. External event distributions, event eggs and GameCube gifts cannot be reached by teleporting. Use your Event Distributor or LegalMon mod for those origins.') end},
      {label='Breeding eggs / wilds',help='Not one-time static encounters.',action=function() info('REPEATABLE ENCOUNTERS','Day Care eggs, fishing, grass, Surf, Rock Smash, Safari and Unown are repeatable encounters rather than fixed individual static Pokemon. The static gift Togepi egg is in Gifts & eggs.') end},
      {label='Back',action=back},
    })
  end
  function S.show()
    C.bind();S.active=true;S.pages={}
    local s=E.session();S.frameType=require('src.core.game3.options').ensure(s).frameType or 0
    push('ENCOUNTER TOUR',{
      {label='Browse encounters',help=(s.version=='emerald' or s.version=='ruby' or s.version=='sapphire') and 'Hoenn legends, static battles, gifts, fossils and trades.' or 'Starters, legends, gifts, fossils, prizes and trades.',action=browse},
      {label='Automatic tour',help='Visit each unresolved encounter in sequence.',action=controls},
      {label='Return to start',help='Returns your position; keeps acquired Pokemon and progress.',action=function() act(C.back) end},
      {label='Other special Pokemon',help='Roamers and external events explained.',action=extras},
      {label='Help & controls',action=function() info('HELP','A selects. B, L or START goes back. Left and Right move six rows. Teleports bypass travel and ferry gates. Story scripts still apply; this mod does not restore claimed starters, defeated legends or other one-time gifts. Tour and return point last until the session changes. Save normally when you want to keep progress.') end},
      {label='Close',action=S.hide},
    })
    Stack.push('encounter_tour',S,{fullscreen=true})
  end
  function S.hide()
    S.active=false;Stack.pop('encounter_tour')
    local Start=require('src.ui.game3.start_menu');if Start.isOpen() then Start.close(true) end
  end
  function S.handleInput(input)
    if input:wasPressed('b') or input:wasPressed('l') or input:wasPressed('start') then back();return end
    local p=S.pages[#S.pages];if not p then return end
    local d=input:wasPressed('up') and -1 or input:wasPressed('down') and 1 or input:wasPressed('left') and -6 or input:wasPressed('right') and 6 or 0
    if d~=0 then p.cursor=(p.cursor-1+d)%#p.rows+1;S.notice=nil end
    if input:wasPressed('a') then local r=p.rows[p.cursor];if r and r.action then r.action() end end
  end
  function S.draw() V.draw(S) end
  return S
end
