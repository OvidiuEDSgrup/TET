select * from sysspd p where p.Tip='TE' and (p.Gestiune like '21_' or p.Gestiune_primitoare like '21_')
and p.Numar not like '_00[0-9]_' and p.stare<>5
and p.Stergator<>p.Utilizator
order by p.Data_stergerii desc

--select * from sysspd p where p.Tip='TE' and (p.Gestiune like '21_' or p.Gestiune_primitoare like '21_')
--and p.Numar not like '_000_' 
--order by p.Data_stergerii desc