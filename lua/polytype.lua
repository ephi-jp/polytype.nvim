local M = {}
local active_mode = nil

-- ==========================================
-- 1. 設定: モードごとの置換ルール
-- ==========================================
-- 形式: [トリガーキー] = { { 前にある文字, 置換後の文字 }, ... }
-- "前にある文字" が空文字列 "" の場合は、無条件で置換します（単一キー置換）
local modes = {
    latin = {
        -- 'a' を打った時、直前が 'a;' なら 'á' にする (計3文字削除して置換ではない点に注意)
        -- ここでは「トリガーキーを含まない直前の文字列」を指定します。
        ["a"] = { { "a;", "á" }, { "e;", "é" }, { "o;", "ó" } },
    },
    cyrillic = {
        -- 単発置換の例: z を打つと即座に з になる
        ["z"] = { { "", "з" } },
        ["g"] = { { "", "г" } },
        ["d"] = { { "", "д" } },
        ["l"] = { { "", "л" } },
    },
}

-- ==========================================
-- 2. ロジック: カーソル位置のチェックと置換生成
-- ==========================================
function M.handle_key(key)
    if not active_mode then
        return key
    end

    local rules = modes[active_mode][key]
    if not rules then
        return key
    end

    -- 現在の行とカーソル位置を取得
    -- col は 0-indexed で、カーソルは「次の入力位置」にある
    local line = vim.api.nvim_get_current_line()
    local col = vim.api.nvim_win_get_cursor(0)[2]

    -- カーソルより前のテキストを取得
    local text_before = line:sub(1, col)

    for _, rule in ipairs(rules) do
        local suffix = rule[1] -- 前にあるべき文字 (例: "a;")
        local replacement = rule[2] -- 置換後の文字 (例: "á")

        -- 直前のテキストが suffix で終わっているか確認
        if text_before:sub(-#suffix) == suffix then
            -- マッチした場合:
            -- 1. suffixの文字数分バックスペース (<BS>) を生成
            -- 2. 置換後の文字を続ける
            local backspaces = string.rep("<BS>", #suffix)

            return backspaces .. replacement
        end
    end

    -- どのルールにもマッチしなければ、入力されたキーをそのまま返す
    return key
end

-- ==========================================
-- 3. マッピング管理
-- ==========================================
local function set_mappings(mode_name)
    local rules = modes[mode_name]
    if not rules then
        return
    end

    -- ルールに登録されている「トリガーキー」だけを expr マッピングする
    for key, _ in pairs(rules) do
        vim.keymap.set("i", key, function()
            return M.handle_key(key)
        end, { expr = true, buffer = true }) -- buffer=trueで現在のバッファのみに適用
    end
    print("Enabled mode: " .. mode_name)
end

local function clear_mappings(mode_name)
    if not mode_name or not modes[mode_name] then
        return
    end
    for key, _ in pairs(modes[mode_name]) do
        pcall(vim.keymap.del, "i", key, { buffer = true })
    end
end

-- ==========================================
-- 4. 公開コマンド
-- ==========================================
function M.enable(mode_name)
    if active_mode then
        clear_mappings(active_mode)
    end
    active_mode = mode_name
    set_mappings(mode_name)
end

function M.disable()
    if active_mode then
        clear_mappings(active_mode)
        active_mode = nil
        print("IME Disabled")
    end
end

function M.setup()
    vim.api.nvim_create_user_command("ImeL", function()
        M.enable("latin")
    end, {})
    vim.api.nvim_create_user_command("ImeC", function()
        M.enable("cyrillic")
    end, {})
    vim.api.nvim_create_user_command("ImeOff", function()
        M.disable()
    end, {})
end

return M
