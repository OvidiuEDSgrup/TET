/*
update p set p.Comanda='1800319125811'
--*/select * 
from pozdoc p where p.Tip='TE' and p.Numar like '[0-9]00[0-9][0-9]' and p.Gestiune='700'
and exists
(select 1 from stocuri s where s.Cod_gestiune=p.Gestiune and s.Cod=p.Cod and s.Cod_intrare=p.Cod_intrare and s.Comanda<>p.Comanda)

select * from antetBonuri a where a.Data_bon='2012-07-04' and a.Casa_de_marcat=2 and a.Numar_bon=1 

select * from stocuri s where s.Cod_gestiune='700'
and exists 
	(select 1 from pozdoc p where p.Tip='TE' and p.Numar like '[0-9]00[0-9][0-9]' 
		and s.Cod_gestiune=p.Gestiune and s.Cod=p.Cod and s.Cod_intrare=p.Cod_intrare and s.Comanda<>p.Comanda)

/*
update ti set Grupa=RTRIM(replace(grupa,'.',''))
--*/select * 
from pozdoc ti where ti.Tip='TE' and ti.Gestiune_primitoare='700' and exists 
	(select 1 from stocuri s where s.Cod_gestiune=ti.Gestiune_primitoare and ti.Cod=s.Cod and s.Cod_intrare=ti.Grupa
	and exists 
		(select 1 from pozdoc p where p.Tip='TE' and p.Numar like '[0-9]00[0-9][0-9]' 
			and s.Cod_gestiune=p.Gestiune and s.Cod=p.Cod and s.Cod_intrare=p.Cod_intrare and s.Comanda<>p.Comanda))
			
			
select * 
from pozdoc ti where ti.Tip='TE' and ti.Gestiune_primitoare='700' 
and ti.Comanda='2810824124246' 
and ti.Cod in ('PKKP500/1400'        
,'PKKP600/1000'        
,'2207CU3')
