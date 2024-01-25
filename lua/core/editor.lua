vim.opt.guifont = "MesloLGS NF:h21"

vim.opt.tabstop = 4
vim.opt.shiftwidth = 4
vim.opt.softtabstop = 4
vim.opt.expandtab = true

vim.opt.completeopt:remove("preview")


do
    -- Doesn't work properly, because all bindings are not recursive by default.
    -- This just remaps each character individually, I think.
    -- local russianLangmap = 'ФИСВУАПРШОЛДЬТЩЗЙКЫЕГМЦЧНЯ;ABCDEFGHIJKLMNOPQRSTUVWXYZ,фисвуапршолдьтщзйкыегмцчня;abcdefghijklmnopqrstuvwxyz'
    -- local romanianLangmap = [[ĂÎÂȘȚ;{}|:,ăîâșț[]\;']]
    -- local combinedLangmap = russianLangmap .. ',' .. romanianLangmap
    -- vim.opt.langmap = combinedLangmap

    --
    -- vim.opt.keymap = "russian-jcukenwin"
end

