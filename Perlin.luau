--[[
	A perlin module. HUGE THANKS to https://adrianb.io/ for their incredible article (https://adrianb.io/2014/08/09/perlinnoise.html)
	
	Usage:
	Perlin.new(seed: number?, repeat: number?)
]]

--!strict
local Perlin = {}
Perlin.__index = Perlin
export type perlin = typeof(setmetatable({} :: {Repeat: number, p: {number}}, Perlin))

-- PRIVATE FUNCTIONS

-- The formula for this is: 6t^5-15t^4+10t^3. This just uses less multiplication
local function fade(t: number)
	return t * t * t * (t * (t * 6 - 15) + 10)
end

local function lerp(a: number, b: number, t: number)
	return a + t * (b - a)
end

local function grad(hash: number, x: number, y: number, z: number)
	local h = bit32.band(hash, 15)
	
	local u = h < 8 and x or y
	
	local v
	if h < 4 then
		v = y
	elseif h == 12 or h == 14 then
		v = x
	else
		v = z
	end
	
	--(h&1) == 0 ? u : -u
	local t1 = bit32.band(h, 1) == 0 and u or -u
	
	--(h&2) == 0 ? v : -v
	local t2 = bit32.band(h, 2) == 0 and v or -v
	
	return t1 + t2
end

function Perlin:increment(n: number)
	n = n + 1 -- global
	if self.Repeat > 0 then
		n = n % self.Repeat
	end	
	return n
end

-- PUBLIC FUNCTIONS

-- constructor
function Perlin.new(seed: number?, repeatValue: number?)
	local self = setmetatable({}, Perlin)
	self.Repeat = (repeatValue or 0) :: number
	
	-- Create the permuatations table
	local random = Random.new(seed) -- this creates a random number generator. If the seed is nil, it creates the rng with a random seed.
	
	local permutations = {}
	for i = 0, 255 do
		permutations[i] = i
	end
	
	-- shuffle
	for i = 255, 1, -1 do
		local k = random:NextInteger(0, i)
		permutations[i], permutations[k] = permutations[k], permutations[i]
	end
	
	-- an array twice the size
	self.p = {}
	for i = 0, 511 do
		self.p[i] = permutations[i % 256]
	end
	
	return self
end

-- noise functions

-- standard perlin noise
function Perlin:Noise(x: number, y:number, z:number)
	local self = self :: perlin
	
	if self.Repeat > 0 then
		x = x % self.Repeat -- global
		y = y % self.Repeat -- global
		z = z % self.Repeat -- global
	end
	
	local xi = bit32.band(math.floor(x), 255)
	local yi = bit32.band(math.floor(y), 255)
	local zi = bit32.band(math.floor(z), 255)
	
	local xf = x - math.floor(x)
	local yf = y - math.floor(y)
	local zf = z - math.floor(z)
	
	local u = fade(xf)
	local v = fade(yf)
	local w = fade(zf)
	
	local p = self.p -- cached
	
	--hash function
	local aaa = p[p[p[xi]+yi]+zi]
	local aba = p[p[p[xi]+self:increment(yi)]+zi]
	local aab = p[p[p[xi]+yi]+self:increment(zi)]
	local abb = p[p[p[xi]+self:increment(yi)]+self:increment(zi)]
	local baa = p[p[p[self:increment(xi)]+yi]+zi]
	local bba = p[p[p[self:increment(xi)]+self:increment(yi)]+zi]
	local bab = p[p[p[self:increment(xi)]+yi]+self:increment(zi)]
	local bbb = p[p[p[self:increment(xi)]+self:increment(yi)]+self:increment(zi)]
	
	local x1 = lerp(grad(aaa, xf, yf, zf),
		grad(baa, xf-1, yf, zf),
		u)
	local x2 = lerp(grad(aba, xf, yf-1, zf), 
		grad(bba, xf-1, yf-1, zf), 
		u
	)
	local y1 = lerp(x1, x2, v)
	local x1 = lerp(grad(aab, xf, yf, zf-1), 
		grad(bab, xf-1, yf, zf-1), 
		u
	)
	local x2 = lerp(grad(abb, xf, yf-1, zf-1), 
		grad(bbb, xf-1, yf-1, zf-1),
		u
	)
	local y2 = lerp(x1, x2, v)
	
	return (lerp(y1, y2, w)+1)/2
end

-- perlin noise with octaves
function Perlin:OctavePerlin(x: number, y: number, z: number, octaves: number?, persistence: number?)
	local self = self :: perlin
	
	local octaves = octaves or 4
	local persistence = persistence or 0.5
	
	local total, frequency, amplitude, maxValue = 0, 1, 1, 0
	
	for i = 1, octaves do
		total = total + self:Noise(x * frequency, y * frequency, z * frequency) * amplitude
		
		maxValue = maxValue + amplitude
		amplitude = amplitude * persistence
		frequency = frequency * 2
	end
	
	return total / maxValue
end

return Perlin
