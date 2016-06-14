select * from locatii 
where cod_Locatie<>''

select * -- delete c
from yso_CodInl c where c.Tip<>-12

--insert locatii (Cod_locatie,Este_grup,Cod_grup,UM,Capacitate,Cod_gestiune,Incarcare,Nivel,Descriere)
--select
--Cod_locatie=Cod_vechi,
--Este_grup=0,
--Cod_grup='',
--UM='',
--Capacitate=0,
--Cod_gestiune='101',
--Incarcare=0,
--Nivel=1,
--Descriere=Cod_vechi
--from yso_CodInl c where c.Tip=-12 and c.Cod_vechi not in (select l.Cod_locatie from locatii l)

select * from istoricstocuri where Locatie<>''
select * from AntetInventar where Locatie<>''
select * from antetinv where Locatie<>''
select * from stoclim where Locatie<>''
select * from pozdoc where Locatie<>''

select * -- update t set Numar_tabela=o.object_id
from yso_TabInl t join sys.objects o on o.name=t.Denumire_SQL
where t.Tip=-12

select * from yso_DetTabInl
