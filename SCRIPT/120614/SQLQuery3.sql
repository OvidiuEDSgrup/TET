drop trigger yso_instehnpozcom 
go
create trigger yso_instehnpozcom on tehnpoz instead of insert as

insert tehnpoz (Cod_tehn,Tip,Cod,Cod_operatie,Nr,Subtip,Supr,Coef_consum,Randament,Specific,Cod_inlocuit,Loc_munca,Obs,Utilaj,Timp_preg,Timp_util,Categ_salar,Norma_timp,Tarif_unitar,Lungime,Latime,Inaltime,Comanda,Alfa1,Alfa2,Alfa3,Alfa4,Alfa5,Val1,Val2,Val3,Val4,Val5)
select			Cod_tehn,Tip,Cod,Cod_operatie,Nr,Subtip,Supr,Coef_consum,Randament,Specific,Cod_inlocuit,Loc_munca,Obs,Utilaj,Timp_preg,Timp_util,Categ_salar,Norma_timp,Tarif_unitar,Lungime,Latime,Inaltime,Comanda,Alfa1,Alfa2,Alfa3,Alfa4,Alfa5,Val1,Val2,Val3,Val4,Val5
from inserted

insert pozcom (Subunitate,Comanda,Cod_produs,Cantitate,UM )
select
'1' --Subunitate	char	9
,tp.Cod_tehn --Comanda	char	20
,tp.Cod_tehn --Cod_produs	char	30
,tp.Specific --Cantitate	float	8
,n.UM --UM	char	3
from inserted tp inner join nomencl n on n.cod=tp.Cod 
where tp.Tip='R'
	--and exists (select 1 from comenzi c where c.Subunitate='1' and c.Comanda=tp.Cod_tehn)
	and not exists (select 1 from pozcom pc where pc.Subunitate='1' and pc.Comanda=tp.Cod_tehn and pc.Cod_produs=tp.Cod_tehn)