-- The path to the file that holds the theme name.
-- Note: Lua uses '/' as the path separator, even on Linux.
local theme_file_path = os.getenv("HOME") .. "/.config/current/lazyvim"

-- Function to safely read the theme name from the file
local function get_current_colorscheme()
  -- Attempt to open the file in read mode ('r')
  local f = io.open(theme_file_path, "r")
  local theme_name = "gruvbox" -- Default theme if file read fails

  if f then
    -- Read the first line (the theme name) and remove leading/trailing whitespace
    theme_name = f:read("*l"):match("^%s*(.-)%s*$")
    f:close()
  end

  -- Ensure we return a string, even if it's the default
  return theme_name or "gruvbox"
end

-- Get the dynamic theme name
local active_colorscheme = get_current_colorscheme()

return {
  -- Add the required colorschemes as plugins
  { "ellisonleao/gruvbox.nvim" },
  { "Mofiqul/dracula.nvim" },
  { "catppuccin/nvim" }, -- Add any other theme plugins here
  { "gbprod/nord.nvim" },
  { "neanias/everforest-nvim" },
  { "tahayvr/matteblack.nvim" },

  -- Configure LazyVim to load the dynamic colorscheme
  {
    "LazyVim/LazyVim",
    opts = {
      -- This line now uses the variable read from the symbolic link!
      colorscheme = active_colorscheme,
    },
  },
}
