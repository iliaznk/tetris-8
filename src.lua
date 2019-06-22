function _init()
  -- set black color as non-transparent.
  palt(0,false)
  -- fr - frame counter, sz - size of a xsingle cell in pixels, st - step, the state will be updated once per {st} number of frames.
  fr,sz=0,4
  -- abs coords of the cup's top left corner, cup's width and height in cells, cup's color.
  cupx,cupy,cupw,cuph,cupc=11 * sz,sz * 2,10,20,1
  -- current tetromino, rotated version of its table, next tetromino
  tetr,rotation,nexttetr=nil,nil,nil
  
  isover=false
  level=1
  speed=getspeed(level)
  score=0
  lines=0
  linescore={
    40,
    100,
    300,
    1200,
  }
  
  tetrj={
    sp=1,
    table={
      { 1,1,0 },
      { 1,0,0 },
      { 1,0,0 },
    }
  }
  tetrl={
    sp=2,
    table={
      { 1,0,0 },
      { 1,0,0 },
      { 1,1,0 },
    }
  }
  tetrs={
    sp=3,
    table={
      { 1,0 },
      { 1,1 },
      { 0,1 },
    }
  }
  tetrz={
    sp=4,
    table={
      { 1,1,0 },
      { 0,1,1 },
    }
  }
  tetrt={
    sp=5,
    table={
      { 0,1,0 },
      { 1,1,1 },
      { 0,0,0 },
    }
  }
  tetri={
    sp=6,
    table={
      { 0,0,0,0 },
      { 1,1,1,1 },
      { 0,0,0,0 },
    }
  }
  tetro={
    sp=7,
    table={
      { 1,1 },
      { 1,1 },
    }
  }
  alltetr={ tetrj,tetrs,tetro,tetrt,tetri,tetrz,tetrl }
  fill={}
  full={
    step=5,
    fr=0,
    stage=0,
    rows=nil,
  }
  nexttetr=inittetr()
  initnext()
end

function getlinescore(linesnum)
  if linesnum > #linescore then linesnum=#linescore end
  return linescore[linesnum] * level
end

function getspeed(l)
  local s
  if l == 1 then s=24
  elseif l == 2 then s=21
  elseif l == 3 then s=18
  elseif l == 4 then s=15
  elseif l == 5 then s=12
  elseif l == 6 then s=10
  elseif l == 7 then s=8
  elseif l == 8 then s=6
  elseif l == 9 then s=5
  elseif l >= 10 or l <= 12 then s=4
  elseif l >= 13 or l <= 15 then s=3
  elseif l >= 16 or l <= 18 then s=2
  elseif l >= 19 then s=1
  end
  return s
end

-- convert cell coords to absolute screen coords.
function getabscoords(cellx,celly)
  return cupx + cellx * sz,cupy + celly * sz
end

-- scan tetromino.
function scantetr(tetr,cb)
  tetr.rx,tetr.ry=tetr.cx - (tetr.ccol - 1),tetr.cy - (tetr.crow - 1)
  for row=1,#tetr.table do
    for col=1,#tetr.table[row] do
      if tetr.table[row][col] == 1 then
        local cellx,celly=tetr.rx + (col - 1),tetr.ry + (row - 1)
        if cb(cellx,celly,row,col) == false then return false end
      end
    end
  end
  return true
end

-- can rotate? (if there's enough room around).
function canrotate()
  rotation={
    table=rotatetable(tetr.table),
    cx=tetr.cx,
    cy=tetr.cy
  }
  rotation.ccol,rotation.crow=ceil(#rotation.table[1] / 2),ceil(#rotation.table / 2)
  return testpos(rotation)
end

function testpos(newtetr)
  tetr.rx,tetr.ry=tetr.cx - (tetr.ccol - 1),tetr.cy - (tetr.crow - 1)
  function testcell(x,y)
    if x < 0 or x > cupw - 1 or y > cuph - 1 then return false end
    local r,c=1 + (y - tetr.ry),1 + (x - tetr.rx)
    local frow,fcol=cuph-y,x+1
    if not tetr.table[r] or not tetr.table[r][c] or tetr.table[r][c] ~= 1 then
      local fillrow=fill[frow]
      if not fillrow then return true end
      if fillrow[fcol] then return false end
      return true
    end
    return true
  end
  return scantetr(newtetr,testcell)
end

-- can move to new x, y?
function canmove(ncellx,ncelly)
  local new={
    table=tetr.table,
    cx=ncellx,
    cy=ncelly,
    ccol=tetr.ccol,
    crow=tetr.crow,
  }
  return testpos(new)
end

-- update frame.
function updframe()
  if not fr then return end
  if fr == speed then
    fr=nil
    if canmove(tetr.cx,tetr.cy + 1) then tetr.cy=tetr.cy + 1
    elseif tetr.cy == tetr.starty then gameover() else
      fixtetr()
      sfx(4)
    end
    fr=0
  else
    fr=fr + 1
  end
end

function rotate()
  if canrotate() then
    tetr.table=copytable(rotation.table)
    tetr.ccol,tetr.crow=rotation.ccol,rotation.crow
    sfx(2)
  else
    sfx(0)
  end
end

function move(dx,dy)
  local x,y=tetr.cx + dx,tetr.cy + dy
  if canmove(x,y) then
    tetr.cx=x
    tetr.cy=y
    sfx(1)
  else sfx(0) end
end

function drop()
  fr=nil
  while (canmove(tetr.cx,tetr.cy + 1)) do tetr.cy=tetr.cy + 1 end
  if tetr.cy == tetr.starty then gameover() else
    fixtetr()
    sfx(3)
  end
end

-- fix tetromino in place.
function fixtetr()
  filltetr()
  checkfull()
end

function addfill(cellx,celly)
  local frow,fcol=cuph - celly,cellx + 1
  if not fill[frow] then fill[frow]={} end
  fill[frow][fcol]=tetr.sp
end

-- draw cell.
function drawcell(cellx,celly,sp)
  if celly < 0 then return end
  local absx,absy=getabscoords(cellx,celly)
  spr(sp,absx,absy,0.5,0.5)
end

--draw tetromino.
function drawtetr(tetr)
  if not tetr then return end
  function makedraw(sp)
    return function(x,y)
      drawcell(x,y,sp)
    end
  end
  drawfn=makedraw(tetr.sp)
  scantetr(tetr,drawfn)
end

function filltetr()
  scantetr(tetr,addfill)
end

function drawcup()
  x0,y0=cupx - 1,cupy - 1
  x1,y1=cupx - 1,cupy + cuph * sz
  x2,y2=cupx + cupw * sz,cupy + cuph * sz
  x3,y3=x2,y0
  x4,y4=x0,y0
  line(x0,y0,x1,y1,cupc)
  line(x2,y2)
  line(x3,y3)
  line(x4,y4)
end

function drawstats()
  local mainc,scorec,levelc,linesc=6,8,12,9
  
  -- next tetromino
  local x,y=cupx + (cupw * sz) + sz,cupy
  cursor(x,y,mainc)
  print('next')
  nexttetr.cx=cupw + nexttetr.ccol
  nexttetr.cy=nexttetr.crow + 1
  drawtetr(nexttetr)
  
  -- score
  x=cupx - (sz * 6 - 1)
  local scorestr=tostr(score)
  cursor(x,y,mainc)
  print('score')
  x,y=cupx - ((#scorestr + 1) * sz - 1),cupy + 8
  cursor(x,y,scorec)
  print(scorestr)
  
  -- level
  x,y=cupx - (sz * 6 - 1),y + 8
  local levelstr=tostr(level)
  cursor(x,y,mainc)
  print('level')
  x,y=cupx - ((#levelstr + 1) * sz - 1),y + 8
  cursor(x,y,levelc)
  print(level)
  
  -- lines
  x,y=cupx - (sz * 6 - 1),y + 8
  local linesstr=tostr(lines)
  cursor(x,y,mainc)
  print('lines')
  x,y=cupx - ((#linesstr + 1) * sz - 1),y + 8
  cursor(x,y,linesc)
  print(linesstr)
  
  -- speed
  --x,y=cupx + (cupw * sz) + sz,cupy+3*8
  --cursor(x,y,mainc)
  --print('speed')
  --cursor(x,y+8)
  --print(speed)
end

function drawfill()
  for frow=1,cuph do
    if fill[frow] then
      for fcol=1,cupw do
        if fill[frow][fcol] then
          local sp=fill[frow][fcol]
          if full.rows and full.rows[frow] and full.stage % 2 ~= 0 then sp=0 end
          fx,fy=getabscoords(fcol - 1,cuph - frow)
          spr(sp,fx,fy,0.5,0.5)
        end
      end
    end
  end
end

function cleanfull()
  local newfill={}
  local linesnum=0
  for r=1,cuph do
    if full.rows[r] then linesnum=linesnum + 1 else add(newfill,fill[r]) end
  end
  fill=newfill
  return linesnum
end

function checkfull()
  for r=1,cuph do
    local count=0
    local row=fill[r]
    
    if not row then break end
    
    for c=1,cupw do
      if not row[c] then break end
      count=count + 1
    end
    if count == cupw then
      if not full.rows then full.rows={} end
      full.rows[r]=true
    end
  end
  if not full.rows then initnext() end
end

function updstats()
  level=flr(lines / 10) + 1
  speed=getspeed(level)
end

function updfull()
  if not full.rows then return end
  if full.fr == 0 and full.stage == 0 then sfx(5) end
  if full.fr ~= full.step then
    full.fr=full.fr + 1
    return
  end
  full.fr=0
  if full.stage ~= 4 then
    full.stage=full.stage + 1
    return
  end
  local linesnum=cleanfull()
  if linesnum > 0 then
    lines=lines + linesnum
    score=score + getlinescore(linesnum)
  end
  full.fr=0
  full.stage=0
  full.rows=nil
  updstats()
  initnext()
end

function rotatetable(table)
  result={}
  for row=1,#table[1] do
    for col=1,#table do
      if not result[row] then result[row]={} end
      local prevr=#table - (col - 1)
      local prevc=row
      result[row][col]=table[prevr][prevc]
    end
  end
  return result
end

function plcontrol()
  if isover then
    if btnp(4) or btnp(5) then _init() end
  else
    if not fr then return end
    if btnp(0) then move(-1,0) end
    if btnp(1) then move(1,0) end
    if btnp(3) then move(0,1) end
    if btnp(2) then rotate() end
    if btnp(4) or btnp(5) then drop() end
  end
end

function copytable(table)
  local t={}
  for r=1,#table do
    for c=1,#table[r] do
      if not t[r] then t[r]={} end
      t[r][c]=table[r][c]
    end
  end
  return t
end

function isallzero(row)
  for v in all(row) do
    if v == 1 then return false end
  end
  return true
end

function inittetr()
  local new=alltetr[flr(rnd(#alltetr) + 1)]
  local ccol,crow=ceil(#new.table[1] / 2),ceil(#new.table / 2)
  local tetr={
    sp=new.sp,
    table=copytable(new.table),
    ccol=ccol,
    crow=crow,
  }
  return tetr
end

function initnext()
  local allzero,even=0,1
  if isallzero(nexttetr.table[#nexttetr.table]) then allzero=1 end
  if #nexttetr.table[1] % 2 ~= 0 then even=0 end
  local y=nexttetr.crow - #nexttetr.table + allzero
  tetr={
    sp=nexttetr.sp,
    table=copytable(nexttetr.table),
    crow=nexttetr.crow,
    ccol=nexttetr.ccol,
    cx=flr((cupw / 2) - even),
    cy=y,
    starty=y,
  }
  nexttetr=inittetr()
  fr=0
end

function gameover()
  if not isover then sfx(6) end
  isover=true
  local x,y=cupx + 3,cupy + flr((cuph * sz) / 2 - sz)
  rectfill(cupx,y - 1,cupx + cupw * sz - 1,y + sz + 1,0)
  cursor(x,y,8)
  print('game')
  cursor(x + 5 * 4 - 1,y,8)
  print('over')
  x,y=cupx - 7,cupy + cuph * sz + 8
  cursor(x,y,1)
  print('press \x8e or \x97')
  x,y=x + 6,y + 8
  cursor(x,y)
  print('to continue')
end

function _update()
  updframe()
  plcontrol()
  updfull()
end

function _draw()
  cls()
  drawtetr(tetr)
  drawcup()
  drawfill()
  drawstats()
  if isover then gameover() end
end
