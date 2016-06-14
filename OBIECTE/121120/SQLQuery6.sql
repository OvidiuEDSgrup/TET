select p.Gestiune,p.Gestiune_primitoare,p.Utilizator,* from pozdoc p where '400' in (p.Gestiune,p.Gestiune_primitoare)
order by p.Data desc