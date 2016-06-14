select * from comenzi c where c.comanda in 
(select t.cod_tehn from tehn t)
and c.Comanda like 'TEST%'
SELECT * from pozcom p where p.Comanda like 'TEST%'
-- insert pozcom
select 1,'TEST1','TEST',1,'UM'

select * from tehn t where t.Cod_tehn not in 
(select c.comanda from comenzi c)
-- drop index Denumire on comenzi; alter table comenzi alter column Descriere char(150) not null; create nonclustered index Denumire on comenzi (Descriere)
--insert comenzi 
select
'1' --Subunitate	char	9
,t.Cod_tehn --Comanda	char	20
,t.Tip_tehn --Tip_comanda	char	1
,t.Denumire --Descriere	char	80
,GETDATE() --Data_lansarii	datetime	8
,GETDATE() --Data_inchiderii	datetime	8
,'P' --Starea_comenzii	char	1
,0 --Grup_de_comenzi	bit	1
,'1' --Loc_de_munca	char	9
,CONVERT(char(13),getdate(),111) --Numar_de_inventar	char	13
,'' --Beneficiar	char	13
,'' --Loc_de_munca_beneficiar	char	9
,'' --Comanda_beneficiar	char	20
,'' --Art_calc_benef	char	200
from tehn t where t.Cod_tehn not in 
(select c.comanda from comenzi c)


-- insert pozcom (Subunitate,Comanda,Cod_produs,Cantitate,UM )
select
'1' --Subunitate	char	9
,tp.Cod_tehn --Comanda	char	20
,tp.Cod_tehn --Cod_produs	char	30
,tp.Specific --Cantitate	float	8
,n.UM --UM	char	3
from tehnpoz tp inner join nomencl n on n.cod=tp.Cod 
where tp.Tip='R'
	--and exists (select 1 from comenzi c where c.Subunitate='1' and c.Comanda=tp.Cod_tehn)
	and not exists (select 1 from pozcom pc where pc.Subunitate='1' and pc.Comanda=tp.Cod_tehn and pc.Cod_produs=tp.Cod_tehn)


select * from tehnpoz tp where tp.Tip='R'