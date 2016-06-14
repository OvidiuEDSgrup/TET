--select * from webConfigSTDMeniu m where m.Nume like '%inloc%'
--delete TabInl where tip=-1
--insert TabInl
select Tip=-1,Numar_tabela=o.object_id,Denumire_magic=o.name,Denumire_SQL=o.name
,Camp1='',Camp2='',Inlocuiesc=isnull((select top 1 'Da' from sys.columns c where o.object_id=c.object_id and c.name like '%gest%'),'Nu')
from TabInl t inner join sys.objects o on o.name=t.Denumire_SQL where t.Tip=1
union 
select distinct Tip=-1,Numar_tabela=o.object_id,Denumire_magic=o.name,Denumire_SQL=o.name
,Camp1='',Camp2='',Inlocuiesc='Da'
from sys.columns c inner join sys.objects o on o.object_id=c.object_id 
inner join sys.partitions p on p.object_id=o.object_id and p.index_id=1
left join TabInl t on t.Tip=1 and t.Denumire_SQL=o.name
--left join DetTabInl d on d.Tip=t.Tip and d.Numar_tabela=t.Numar_tabela and d.Camp_SQL=c.name
where o.name<>'gestiuni' and c.name like '%gest%' and p.rows>0 
and t.Inlocuiesc is null
--and d.Conditie_de_inlocuire is null
--select * from DetTabInl d where d.Tip=1
--STOCLIM_LOCATORI

-- delete DetTabInl where tip=-1
-- insert DetTabInl 
select Tip=-1,Numar_tabela=o.object_id,Camp_Magic=o.name,Camp_SQL=c.name,Conditie_de_inlocuire=''
from sys.columns c inner join sys.objects o on o.object_id=c.object_id
	inner join TabInl t on t.Tip=-1 and t.Denumire_SQL=o.name
where c.name like '%gest%'

-- insert DetTabInl 
select Tip=-1,Numar_tabela=t.Numar_tabela,Camp_Magic=t.Denumire_SQL,Camp_SQL=d.Camp_SQL,Conditie_de_inlocuire=''
from TabInl t cross apply (select top 1 d.* from DetTabInl d inner join TabInl t1 on t1.Tip=d.Tip and d.Numar_tabela=t1.Numar_tabela
	inner join sys.objects o on o.name=t1.Denumire_SQL
	where d.Tip=1 and o.object_id=t.Numar_tabela) d
where not exists (select 1 from DetTabInl d1 where d1.tip=t.tip and d1.Numar_tabela=t.Numar_tabela)

-- insert DetTabInl 
select Tip=-1,Numar_tabela=o.object_id,Camp_Magic=o.name,Camp_SQL=d.Camp_SQL,Conditie_de_inlocuire=''
from DetTabInl d 
inner join TabInl t on t.Tip=d.Tip and t.Numar_tabela=d.Numar_tabela
inner join sys.objects o on o.name=t.Denumire_SQL
left join DetTabInl d1 on d1.Tip=-1 and d1.Numar_tabela=o.object_id and d1.Camp_SQL=d.Camp_SQL
where d.Tip=1 and d1.Conditie_de_inlocuire is null
	and not exists (select 1 from DetTabInl d2 where d2.Tip=d1.Tip and d2.Numar_tabela=d1.Numar_tabela)

--select * 
--from DetTabInl d 
--	left join TabInl t on t.Tip=d.Tip and d.Numar_tabela=t.Numar_tabela 
--where d.Tip=1 and d.Camp_SQL not like 

select * from TabInl t where t.Tip=1 and not exists 
(select top 1 1 from sys.columns c inner join sys.objects o on o.object_id=c.object_id 
where o.name=t.Denumire_SQL and c.name like '%gest%')

--select distinct OBJECT_ID%32767 from sysobjects

select * from mpdoc