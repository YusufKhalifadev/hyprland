local function enable_transparency()
    vim.api.nvim_set_hl(0, "Normal", { bg = "none" })
    vim.api.nvim_set_hl(0, "NormalFloat", { bg = "none" })
    vim.api.nvim_set_hl(0, "LineNr", { bg = "none" })
end

return {
    {
        "ellisonleao/gruvbox.nvim",
        config = function()
            vim.cmd.colorscheme "gruvbox"
            vim.cmd('hi Directory guibg=NONE')
            vim.cmd('hi SignColumn guibg=NONE')
            enable_transparency()
        end
    },
}
