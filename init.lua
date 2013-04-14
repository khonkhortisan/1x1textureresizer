local disablethismod = false
local resolution = 1
local checkerboardme = false
local resizemethod = 1

--
--this mod starts with a 1 so it gets loaded after all the other mods
--so don't name it anything other than 1x1textureresizer
--filecopy, string:split, and deepcopy we so useful I had to steal them
--This file is read in ascending order.
--

if not disablethismod then


local imagestoreplace = {}

function scaleimage(image, resolution)
	local r = resolution
	if resizemethod == 1 then
		--ImageMagick
		os.execute('convert '..image..' -resize '..r..' '..image)
	--elseif resizemethod == 2 then
	--
	--elseif resizemethod == 3 then
	else
		print("Need more ways to scale images")
	end
end

function filecopy(from,to)
	io.input(from)
	io.output(to)
	local size = 2^13 -- good buffer size (8K)
	while true do
		local block = io.read(size)
		if not block then break end
		io.write(block)
	end
	io.close()
end

local function renameimage(image)
	local r = tostring(resolution)
	return image:gsub("%.",'_'..r..'x'..r..'.')
end

function string:split(sep)
        local sep, fields = sep or ":", {}
        local pattern = string.format("([^%s]+)", sep)
        self:gsub(pattern, function(c) fields[#fields+1] = c end)
        return fields
end

local function prepareimage(tile)
	local textures = tile:split("^{&") --multiple image or inventory cube or ?
	for t=1, #textures do
		if textures[t]:match("%.") then --extension
			imagestoreplace[textures[t]] = true
		end
	end
	return renameimage(tile)
end

local function retex(name, thing)
	local success = false
	if thing.tiles then
		for face = 1, #thing.tiles do
			if thing.tiles[face].name then --animation
				thing.tiles[face].name = prepareimage(thing.tiles[face].name)
			else
				thing.tiles[face] = prepareimage(thing.tiles[face])
			end
		end
		success = true
	end
	if thing.special_tiles then
		for stile = 1, #thing.special_tiles do
			--EEW
			--default:water_flowing has special_tiles image
			--default:water_source  has special_tiles name
			--Yuck!
			if thing.special_tiles[stile].image then
				thing.special_tiles[stile].image = prepareimage(thing.special_tiles[stile].image)
			else
				thing.special_tiles[stile].name = prepareimage(thing.special_tiles[stile].name)
			end
		end
		success = true
	end		
	if thing.inventory_image then
		thing.inventory_image = prepareimage(thing.inventory_image)
		success = true
	end
	return success
end

function deepcopy(orig)
	local orig_type = type(orig)
	local copy
	if orig_type == 'table' then
		copy = {}
		for orig_key, orig_value in next, orig, nil do
		copy[deepcopy(orig_key)] = deepcopy(orig_value)
		end
		setmetatable(copy, deepcopy(getmetatable(orig)))
	else -- number, string, boolean, etc
		copy = orig
	end
	return copy
end



local registered_nodes = deepcopy(minetest.registered_nodes)
local registered_items = deepcopy(minetest.registered_items)
for name,node in pairs(registered_nodes) do
	if retex(name,node) then
		minetest.registered_nodes[name] = nil
		minetest.register_node(":"..name,node)
	end
end
for name,item in pairs(registered_items) do
	if retex(name,item) then
		minetest.registered_items[name] = nil
		minetest.register_item(":"..name,item)
	end
end



local mymodname = minetest.get_current_modname()
local mymodpath = minetest.get_modpath(mymodname)
local sep = "/"
local failimage = mymodpath..sep.."failimage.png"
local mytexturepath = mymodpath..sep.."textures"
if not checkerboardme then
	for image,_ in pairs(imagestoreplace) do
		local renamedimage = renameimage(image)
		for _,modname in ipairs(minetest.get_modnames()) do
			local modpath = minetest.get_modpath(modname)
			local texturepath = modpath..sep.."textures"
			local oldimage = texturepath..sep..image
			local newimage = mytexturepath..sep..renamedimage
			local file = io.open(oldimage)
			if file ~= nil then io.close(file)
				filecopy(oldimage, newimage)
				scaleimage(newimage, resolution)
				imagestoreplace[image] = nil
				break
			end
		end
	end
end
for image,_ in pairs(imagestoreplace) do
	local renamedimage = renameimage(image)
	local newimage = mytexturepath..sep..renamedimage 
	filecopy(failimage, newimage)
end



end
