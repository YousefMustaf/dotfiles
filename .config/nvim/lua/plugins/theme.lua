return {
  {
    "bjarneo/aether.nvim",
    branch = "v3",
    name = "aether",
    priority = 1000,
    opts = {
      colors = {
        bg = "#282a36",
        dark_bg = "#1e2029",
        darker_bg = "#14151b",
        lighter_bg = "#44475a",

        fg = "#f8f8f2",
        dark_fg = "#a0a19f",
        light_fg = "#fbfbf6",
        bright_fg = "#ffffff",
        muted = "#44475a",

        red = "#ffafcc",
        yellow = "#cbc3e3",
        orange = "#ffb86c",
        green = "#8be9fd",
        cyan = "#8be9fd",
        blue = "#8be9fd",
        magenta = "#ffc8dd",
        brown = "#755f69",

        bright_red = "#ffafcc",
        bright_yellow = "#cbc3e3",
        bright_green = "#bde0fe",
        bright_cyan = "#bde0fe",
        bright_blue = "#bde0fe",
        bright_magenta = "#ffc8dd",

        accent = "#8be9fd",
        cursor = "#ffffff",
        foreground = "#f8f8f2",
        background = "#282a36",
        selection = "#44475a",
        selection_foreground = "#ffffff",
        selection_background = "#44475a",
      },
    },
  },
  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = "aether",
    },
  },
}
