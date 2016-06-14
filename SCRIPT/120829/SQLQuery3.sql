select * from pozdoc p where p.Tip='TE' and (p.Gestiune like '21_' or p.Gestiune_primitoare like '21_')
and p.Numar not like '_000_' 
order by p.Data_operarii desc

select * from sysspd p where p.Tip='TE' and (p.Gestiune like '21_' or p.Gestiune_primitoare like '21_')
and p.Numar not like '_000_' 
order by p.Data_stergerii desc