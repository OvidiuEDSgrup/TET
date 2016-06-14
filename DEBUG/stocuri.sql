select s.Comanda,* from stocuri s where s.Cod_gestiune='700'
--and s.Comanda like '1710605126190'
AND S.Cod='BHRS5023'
order by s.Cod

select p.Comanda,p.Gestiune,p.Cod_intrare,p.Gestiune_primitoare,p.Grupa,* from pozdoc p where exists 
(select * from stocuri s where S.Cod_gestiune='700'
--and s.Comanda like '1710605126190' 
and s.Cod=p.Cod
and s.Cod_gestiune in (p.Gestiune,p.Gestiune_primitoare) 
and s.Cod_intrare in (p.Cod_intrare,p.Grupa))
AND p.Cod='BHRS5023'
ORDER BY P.Data,p.Numar

select s.Comanda,* from stocuri s where s.Cod='BHRS5023' and s.Cod_gestiune='212'

--select * from par where par.Parametru like 'STOC%'

select ss.Comanda,* from stocuri ss 
where ss.Cod_gestiune='700' and ss.Cod in 
(select s.Cod from stocuri s where 
--s.Comanda like '2840121245037' 
s.Cod_gestiune='700' 
and s.Stoc>0
group by s.Cod
having COUNT(distinct s.Comanda)>1)

select s.comanda,s.* from stocuri s 
where s.Cod_gestiune='212' and s.Cod='28100358'
--and s.Cod_intrare='5596019AB'
--AND 
--S.Cod='BHRS5023'
--order by s.Cod

--SELECT	* from par where par.Parametru like 'TEACCODI'