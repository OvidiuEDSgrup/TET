select * from Bonuri b where b.Comanda_asis<>'' --and b.Loc_de_munca not like '21_.[1-3]' 
order by b.Data desc, b.Ora desc