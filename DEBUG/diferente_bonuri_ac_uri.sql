-- coduri/valori diferite intre bonuri si ac-uri
declare @datainf date, @datasup date
select @datainf='2012-03-01', @datasup='2012-03-31'

select  ISNULL(CONVERT(varchar,b.Numar_bon),'NUEXISTA') as Nr_bon,ISNULL(CONVERT(varchar,b.Data,121),'NUEXISTA') as Data_bon,ISNULL(b.Cod_produs,'NUEXISTA') as Cod_produs_bon
	,ISNULL(p.Numar,'NUEXISTA') as Nr_ac,ISNULL(CONVERT(varchar,p.Data,121),'NUEXISTA') as Data_ac,ISNULL(p.Cod,'NUEXISTA') as Cod_produs_ac
	,b.Cantitate as Cantitate_bon,p.cantitate as Cantitate_ac,b.Valoare as Valoare_bon,p.Valoare as Valoare_ac
--into diferente_bon_ac_mai_tmp
from (select max(case b.Factura_chitanta when 1 then 1 else 0 end) as Factura_chitanta,b.Casa_de_marcat,b.Numar_bon,b.Data, b.Cod_produs
		, max(a.Factura) as Factura
		, Sum(Cantitate) as Cantitate, MAX(Pret) as Pret 
		, SUM(convert(decimal(15,2),b.Cantitate*b.Pret)) as Valoare
		,(select top 1 a.bon from antetBonuri a where a.casa_de_marcat=b.casa_de_marcat and a.Numar_bon=b.Numar_bon and a.Data_bon=b.data and a.Vinzator=b.Vinzator) as bon
		from bonuri b
			left join antetBonuri a on a.casa_de_marcat=b.casa_de_marcat and a.Numar_bon=b.Numar_bon and a.Data_bon=b.data and a.Vinzator=b.Vinzator
		where b.Factura_chitanta=1 and b.Tip='21' and b.Data between @datainf and @datasup
		group by b.Casa_de_marcat,b.Numar_bon,b.Data,b.Vinzator, b.Cod_produs) b
	full outer join 
	(select p.Numar,p.Data,p.Cod,SUM(p.Cantitate) as cantitate
		,max(p.Pret_cu_amanuntul) as Pret_cu_amanuntul,max(p.Pret_amanunt_predator) as Pret_amanunt_predator,max(p.Pret_vanzare) as Pret_vanzare 
		,SUM(convert(decimal(15,2),p.Cantitate*p.Pret_amanunt_predator)) as Valoare
	from pozdoc p where p.Subunitate='1' and p.Tip='AC' and p.Data between @datainf and @datasup
	group by p.Numar,p.Data,p.Cod) p
	on p.Numar=isnull(nullif(bon.value('(/date/document/@numar_in_pozdoc)[1]','varchar(50)'),'')
		,left((case when b.Factura_chitanta=1 then rtrim(convert(varchar(4),b.Casa_de_marcat))+right(replace(str(b.Numar_bon),' ','0'),4)
		else ltrim(b.Factura) end),8)) and p.Data=b.Data and p.Cod=b.Cod_produs
where b.Cod_produs is null or p.Cod is null  
	or isnull(b.Cantitate,0)<>isnull(p.cantitate,0) or abs(isnull(b.Valoare,0)-isnull(p.Valoare,0))>0.1
go
--declare @p2 xml
--set @p2=convert(xml,N'<row tip="AP" _refresh="0" datajos="2012/05/01" datasus="2012/05/31"/>')
--exec wIaDoc @sesiune='887902FDF1490',@parXML=@p2