-- RS native small-font atlases do not render reliably in these compact mod menus.
-- Keep measurement and drawing on the same readable native face.
local function collectionFont()
 local v=require('src.core.GameVersion').get()
 return (v=='ruby' or v=='sapphire') and 'normal' or nil
end
return function(E)
  local V={}
  local Window=require('src.ui.game3.window')
  local Font=require('src.ui.game3.frlg_font')
  local function text(v,x,y,w,small,colors)
    v=tostring(v or '')
    if Font.measure(v,{small=collectionFont()==nil and small})>w then
      while #v>0 and Font.measure(v..'...',{small=collectionFont()==nil and small})>w do v=v:sub(1,-2) end
      v=v..'...'
    end
    Window.printPx(v,x,y,{maxWidth=w,small=collectionFont()==nil and small,colors=colors})
  end
  function V.wrap(v,width)
    local lines,line={},''
    for word in tostring(v):gmatch('%S+') do
      local nextLine=line=='' and word or line..' '..word
      if Font.measure(nextLine,{small=collectionFont()==nil and true})>width and line~='' then lines[#lines+1]=line;line=word else line=nextLine end
    end
    if line~='' then lines[#lines+1]=line end
    return lines
  end
  function V.draw(S)
    local p=S.pages[#S.pages];if not p then return end
    local function frame(x,y,w,h) Window.userFrame(Window.template(x,y,w,h),S.frameType or 0) end
    love.graphics.setColor(.78,.88,.9,1);love.graphics.rectangle('fill',0,0,240,160)
    love.graphics.setColor(.73,.84,.87,1)
    for y=18,135,4 do love.graphics.rectangle('fill',0,y,240,1) end
    love.graphics.setColor(0,123/255,197/255,1);love.graphics.rectangle('fill',0,0,240,16)
    love.graphics.setColor(1,1,1,1)
    text(p.title,8,0,182,false,Font.COLOR.WHITE)
    text(S.C.tour and 'TOUR' or 'READY',197,0,38,true,Font.COLOR.WHITE)
    local left,width=1,28
    if p.entry then
      frame(1,3,10,13);left,width=13,16
      local e=p.entry;local id=E.species(e)
      local pic=E.pokemon.frontPic(id,0,false)
      if pic and pic.image then love.graphics.draw(pic.image,16,32) end
      text(E.pokemon.name(id),12,99,74,true)
      local level=E.session().version=='leafgreen' and e.leafgreenLevel or e.level
      text(level==0 and 'Trade level' or 'Lv.'..level,12,112,74,true)
    end
    frame(left,3,width,13)
    local first=math.max(1,math.min(p.cursor-5,#p.rows-5))
    for i=first,math.min(#p.rows,first+5) do
      local r=p.rows[i];local y=28+(i-first)*16
      if i==p.cursor then
        love.graphics.setColor(.82,.91,.96,1);love.graphics.rectangle('fill',left*8+1,y,width*8-2,16)
        love.graphics.setColor(1,1,1,1);Window.cursorPx(left*8+2,y)
      end
      text(type(r.label)=='function' and r.label() or r.label,left*8+11,y,width*8-16,true)
    end
    frame(1,17,28,2)
    local r=p.rows[p.cursor]
    text(S.notice or (r and r.help) or 'A choose / B back / Left-Right page',12,136,216,true)
  end
  return V
end
