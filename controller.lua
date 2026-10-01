return function(rows,E)
  local C={tour=false,visited={},message='Choose a destination.',index=0}
  function C.bind()
    if E.refreshCatalog then E.refreshCatalog(E.session()) end
    local s=E.session()
    if s~=C.session then
      C.session=s;C.tour=false;C.returnPoint=nil;C.current=nil;C.visited={};C.index=0;C.timer=0
    end
  end
  function C.available(e) return not e.version or e.version==C.session.version end
  function C.go(e,auto)
    C.bind()
    local ok,why=E.ready();if not ok then return false,why end
    if not C.available(e) then return false,'This prize belongs to the other version.' end
    local p; p,why=E.destination(e);if not p then return false,why end
    local origin=E.position()
    local before=E.count(e);local wasDone=E.done(e)
    ok,why=E.warp(p);if not ok then return false,why end
    C.returnPoint=C.returnPoint or origin
    C.current=e;C.before=before;C.wasDone=wasDone;C.timer=0
    C.tour=auto==true;C.visited[e.id]=true
    for i,r in ipairs(rows) do if r==e then C.index=i end end
    C.message='At '..e.name..'. '..e.note
    return true
  end
  function C.next()
    C.bind()
    local ready,why=E.ready();if not ready then return false,why end
    for i=C.index+1,#rows do
      local e=rows[i]
      if C.available(e) and not E.done(e) and not C.visited[e.id] then
        local ok;ok,why=C.go(e,true)
        if not ok then C.tour=false;C.message=why end
        return ok,why
      end
    end
    C.tour=false;C.message='Tour finished. Use Return to start or browse again.'
    return true
  end
  function C.start()
    C.bind();C.index=0;C.visited={};return C.next()
  end
  function C.stop() C.tour=false;C.timer=0;C.message='Tour paused. Browse or resume with Next encounter.' end
  function C.back()
    C.bind();if not C.returnPoint then return false,'No return point in this session.' end
    local ok,why=E.warp(C.returnPoint)
    if ok then C.tour=false;C.current=nil;C.returnPoint=nil;C.message='Returned to your starting point.' end
    return ok,why
  end
  function C.tick(dt)
    C.bind()
    if not C.tour or not C.current then return end
    local finished=(not C.wasDone and E.done(C.current)) or E.count(C.current)>C.before
    if not finished or not E.ready() then C.timer=0;return end
    C.timer=(C.timer or 0)+math.min(dt or 0,0.1)
    if C.timer>=1 then C.timer=0;local ok,why=C.next();if not ok then C.stop();C.message=why end end
  end
  return C
end
