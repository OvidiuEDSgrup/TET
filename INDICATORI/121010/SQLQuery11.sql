select * from pozdoc p 
left join proprietati pp on pp.Tip='TERT' and pp.Cod_proprietate='ECHIPA'
and pp.Cod=p.Tert
where pp.Valoare='Proiectanti'
and p.Data between '2012-08-01' and '2012-08-31'
and p.Loc_de_munca='1SRV04' 