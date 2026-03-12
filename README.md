# luau-perlin-noise
A luau module script that lets you create perlin noise easily with up to 3 dimensions (1D, 2D, 3D).

Huge thanks to Adrian Biagioli for their [awesome article](https://adrianb.io/2014/08/09/perlinnoise.html) on which I have based the luau implementation!

---

## Features
* **Uses a constructor:** You can create multiple independent generators.
* **Has seed support:** Create identical noise patterns from one seed (if you don't provide a seed, it's random).
* **Supports different dimensions:** Can generate 1D, 2D and 3D noise.
* **Supports fractal and repeating noise:** Layer noise to create more natural-looking results (using an octave variable) or create seamless tiling patterns (using a repeat interval)

## Showcase

### Video (click the image to view):

[![Perlin Noise in Roblox Studio](https://img.youtube.com/vi/3HLCahIMYzI/maxresdefault.jpg)](https://youtu.be/3HLCahIMYzI)

### Code used in showcase:

**Note:** This script uses 4x4x4 block models located in ServerStorage.Assets, a part in the workspace called "Start" to get the starter coordinates and a Perlin module located in ReplicatedStorage.

```luau
local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local module = require(ReplicatedStorage.Perlin)

local Assets = ServerStorage.Assets

local perlin = module.new(nil, 0) -- create a generator with a random seed

local start = workspace.Start
local START_POS = start.Position
start.Transparency = 1

local GrassBlockTemplate, StoneBlockTemplate, DirtBlockTemplate = Assets.Grass, Assets.Stone, Assets.Dirt

local templates = {
	["Grass"] = GrassBlockTemplate,
	["Stone"] = StoneBlockTemplate,
	["Dirt"] = DirtBlockTemplate,
}

local GRID_SIZE = 4
local SCALE = 50 -- what the coordinates are divided by
local MAX_HEIGHT = 30 -- the world height
local MAX_X, MAX_Z = 90,90 -- the world size
local BATCH_SIZE = 100 -- how many blocks are generated before the script yields for a frame
local CAVE_SIZE = 10
local CAVE_NOISE_OFFSET = 999 -- how much the cave noise is offsetted from the surface noise

local blocks = Instance.new("Folder")
blocks.Name = "Blocks"
blocks.Parent = workspace

print("Creating world...")

local startTime = os.clock()
local c = 0
for x = 1, MAX_X do
	for z = 1, MAX_Z do
		local surfaceNoise = perlin:OctavePerlin(x/SCALE, z/SCALE, 0)
		
		local surfaceBlockHeight = math.floor(surfaceNoise*MAX_HEIGHT)
		
		for y = 1, surfaceBlockHeight do
			local caveNoise = perlin:OctavePerlin((x+CAVE_NOISE_OFFSET)/CAVE_SIZE, (y+CAVE_NOISE_OFFSET)/CAVE_SIZE, (z+CAVE_NOISE_OFFSET)/CAVE_SIZE)
			
			if caveNoise > 0.3 then
				local blockType = "Stone"
				if y == surfaceBlockHeight then
					blockType = "Grass"
				elseif y >= surfaceBlockHeight - 3 then
					blockType = "Dirt"
				end
				
				local template = templates[blockType] :: Part
				local block = template:Clone()
				block.Position = START_POS + Vector3.new(x * GRID_SIZE, y * GRID_SIZE, z * GRID_SIZE)
				block.Parent = blocks
				
				-- batch logic
				c+=1
				if c % BATCH_SIZE == 0 then
					task.wait()
				end
			end
		end
	end
end
print(string.format("Finished in %.3f", os.clock() - startTime))
```

## Usage

### 1. Require the module:
```luau
local Perlin = require(pathToModule)
```

### 2. Create a generator

`Perlin.new(seed: number?, repeat: number?)`

**Arguments:**
- **`seed`** (optional): A number used by the random number generator to create the permutations array. If not provided, chooses a random one.
- **`repeat`** (optional): The interval at which the noise pattern should repeat. If not provided, defaults to 0 (doesn't repeat).

```luau
local generator1 = Perlin.new(123321) -- creates a generator with a set seed (123231)

local generator2 = Perlin.new() -- creates a generator with a random seed
```

### 3. Generate noise

There are two functions you can use the generate noise:
1) `Perlin:Noise()`
2) `Perlin:OctavePerlin()`

### `Perlin:Noise(x: number, y: number, z: number)`

Returns the 3D Perlin noise value (from 0 to 1) for the given coordinates.

```luau
local value = perlin:Noise(5.5, 20.1, 9.3)
print(value) -- 0.468

-- Create a 2D slice
local value2 = perlin:Noise(5.5, 20.1, 0) -- I'm still providing a Z coordinate, but it's set to 0
print(value2) -- 0.671
```

### `Perlin:OctavePerlin(x, y, z, octaves: number?, persistence: number?)`

Returns the fractal noise value by layering multiple noise "octaves" on top of each other. This is great for generating natural-looking (like Minecraft!) terrain.

-   **`octaves`** (optional): The number of noise layers to combine. Defaults to 4.
-   **`persistence`** (optional): How much each successive octave contributes to the final result. Defaults to 0.5.

```luau
-- Generate a 16x16 terrain chunk with 4 octaves at coordinates 10, 10, 10

local blocks = Instance.new("Folder")
blocks.Name = "Blocks"
blocks.Parent = workspace

for x = 1, 16 do
  for z = 1, 16 do
    -- Generate noise
    local noise = noiseGenerator1:OctavePerlin(x/50, z/50, 0) -- I didn't provide the ocatves and persistence args because we can use the defaults. Also I set z to 0 so we get a 2D slice. 50 is the scale we use to turns the ints into floats.
    local height = math.floor(noise * 8) -- 8 is the max height

    -- Show it in the world
    local block = Instance.new("Part")
    block.Size = Vector3.new(1,1,1)
    block.Anchored = true
    block.Position = Vector3.new(10+1*x,10+height,10+1*z)
    block.Parent = blocks

    task.wait() -- yield for a frame to not lag
  end
end
```
