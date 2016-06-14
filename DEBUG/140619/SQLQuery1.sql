select * from par p where p.Denumire_parametru like '%furn%'
select * from stocuri
select n.Loc_de_munca,* from nomencl n where n.Loc_de_munca<>'' and LEN(n.Loc_de_munca)>20