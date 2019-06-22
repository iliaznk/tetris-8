pico-8 cartridge // http://www.pico-8.com
version 18
__lua__
-- fr - frame counter, sz - size of a single cell in pixels, st - step, the state will be updated once per {st} number of frames
fr,sz,st=0,4,30
-- abs coords of the cup's top left corner
cupx,cupy=100,20
-- cup's width and height in cells
cupw,cuph=10,20
-- x, y - coords of the tetramino's center in cells
-- rectx, recty - coords of the the top left corner of the tetramino's bounding rectangle
x,y,rectx,recty=64,0,0,0

tetr=nil

tetrj={
 sp=0,
 table={
  {1,1,0},
  {1,0,0},
  {1,0,0},
 }
}
tetrl={
 sp=0,
 table={
  {1,0,0},
  {1,0,0},
  {1,1,0},
 }
}
tetrs={
 sp=0,
 table={
  {1,0},
  {1,1},
  {0,1},
 }
}
tetrz={
 sp=0,
 table={
  {1,1,0},
  {0,1,1},
 }
}
tetrt={
 sp=0,
 table={
  {0,1,0},
  {1,1,1},
  {0,0,0},
 }
}
tetri={
 sp=0,
 table={
  {0,0,0,0},
  {1,1,1,1},
  {0,0,0,0},
 }
}

-- can move down? (if nothing is in the way)
function candown()
 for r=#tetr.table,1,-1 do
  -- is bottom row
  isbtmrow=r==#tetr.table
  row=tetr.table[r]
  for col=1,#row do
  colx,coly=rectx+sz*(col-1),recty+sz*(r-1)
   -- if bottom row then must check pixels below it
   if (isbtmrow and row[col]==1 and pget(colx,coly+sz)!=0) return false
   -- check only if this is an empty cell
   if (row[col]==0 and pget(colx,coly)!=0) return false
  end
 end
 return true
end

-- update frame
function upframe()
 if (candown()) y+=sz
 fr=0
end

-- update rotation
function updrot()
 if (btnp(2)) tetr.table=rotate(tetr.table)
end

-- update movement along x
function updx()
	if (btnp(0)) x-=sz
	if (btnp(1)) x+=sz
end

-- update movement along y
function updy()
 if (fr==st) upframe()
 if (btnp(3) and candown()) y+=sz
end

-- draw tetramino
function drtetr()
 ofx,ofy=flr(#tetr.table[1]/3),flr(#tetr.table/3)
 rectx,recty=x-sz*ofx,y-sz*ofy
 for row=1,#tetr.table do
  local y=recty+sz*(row-1)
  for col=1,#tetr.table[row] do
   local x=rectx+sz*(col-1)
   if (tetr.table[row][col] == 1) spr(tetr.sp,x,y)
  end
 end
end

function rotate(tetr)
 result={}
 for row=1,#tetr[1] do
  for col=1,#tetr do
   if (not result[row]) result[row] = {}
   prevr=#tetr-(col-1)
   prevc=row
   result[row][col]=tetr[prevr][prevc]
  end
 end
 return result
end

function _init()

 tetr=tetrt
 
end

function _update()
 fr+=1
	updy()
 updx()
 updrot()
end

function _draw()
	cls()
 spr(1,64,64)
 drtetr()
end

__gfx__
88880000eeee00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
88880000eeee00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
88880000eeee00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
88880000eeee00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
0001000014050170501b0501d0502105022050230502405025050260502705028050290502a05029050270502405022050210501e0501b05018050170501705015050190501e05022050260502b0502f05033050
