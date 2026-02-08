local M = {}
local cache = {}
local active_mode = {}
local ffi = require("ffi")

local function get_value(base, m, i)
    local pos = (i - 1) / 2
    local value = ffi.cast("uint8_t*", base)
    if pos >= m then
        return nil
    end
    local h = value[pos]
    local out_count = h % 16
    if pos + out_count >= m then
        return nil
    end
    local bs_count = (h - out_count) / 16
    local backspaces = string.rep("<BS>", bs_count)
    local replacement = ffi.string(value + pos + 1, out_count)
    return backspaces .. replacement
end

local function handle_key(key, i, n, m, check, base)
    local line = vim.api.nvim_get_current_line()
    local col = vim.api.nvim_win_get_cursor(0)[2]
    local text_before = line:sub(math.max(1, col - 14), col)

    for j = 1, #text_before do
        local c = text_before:byte(-j)
        i = i + c
        if i < 0 or i >= n or check[i] ~= c then
            break
        end

        i = base[i]

        if i % 2 ~= 0 then
            return get_value(base, m, i)
        end
        i = i / 2
    end

    return key
end

local function load_mapping(mode_name, datfile)
    datfile = datfile or vim.api.nvim_get_runtime_file("data/polytype/" .. mode_name .. ".dat", false)[1]
    local f = io.open(datfile, "r")
    if not f then
        return nil
    end
    local dat = f:read("*a")
    f:close()

    local header = ffi.cast("int32_t*", dat)
    if #dat < 8 or header[0] ~= 0x00015450 then
        return nil
    end

    local mapping = dat:sub(5)
    cache[mode_name] = mapping
    return mapping
end

local function set_mappings(mode_name, datfile)
    local mapping = cache[mode_name] or load_mapping(mode_name, datfile)
    if not mapping then
        return false
    end

    local bufnr = vim.api.nvim_get_current_buf()
    active_mode[bufnr] = mode_name

    local header = ffi.cast("int16_t*", mapping)
    local n = header[0]
    local m = header[1]
    local check = ffi.cast("uint8_t*", header + 2)
    local base = ffi.cast("int16_t*", check + n)
    local start = check[0]
    for c = start, 127 do
        local i = c - start
        if i < n and check[i] == c then
            local key = string.char(c)
            i = base[i]
            if i % 2 ~= 0 then
                local value = get_value(base, m, i)
                if value then
                    vim.keymap.set("i", key, value, { buffer = true })
                end
            else
                vim.keymap.set("i", key, function()
                    return handle_key(key, i / 2, n, m, check, base)
                end, { expr = true, buffer = bufnr })
            end
        end
    end
    return true
end

local function clear_mappings()
    local bufnr = vim.api.nvim_get_current_buf()
    local mapping = cache[active_mode[bufnr]]
    if not mapping then
        return
    end
    local header = ffi.cast("int16_t*", mapping)
    local n = header[0]
    local check = ffi.cast("uint8_t*", header + 2)
    local start = check[0]
    for c = start, 127 do
        local i = c - start
        if i < n and check[i] == c then
            local key = string.char(c)
            pcall(vim.keymap.del, "i", key, { buffer = true })
        end
    end
    active_mode[bufnr] = nil
end

function M.mode()
    local bufnr = vim.api.nvim_get_current_buf()
    return active_mode[bufnr]
end

function M.enable(mode_name, datfile)
    clear_mappings()
    if set_mappings(mode_name, datfile) then
        print("PolyType mode: " .. mode_name)
    end
end

function M.enable_latin()
    M.enable("latin")
end

function M.disable()
    clear_mappings()
    print("PolyType Disabled")
end

return M
