--***
create procedure rapFisaParteneri @sesiune varchar(50)=null,
	@datajos datetime=null, @datasus datetime,
	@tip_tert int=0,	-->	0=B sau F, 1=B si F, 2=B, 3=F
	@soldmin decimal(15,3),
	@ctert varchar(100)=null,
	@cfactura varchar(100)=null,
	@cu_explicatii varchar(1)=0

as
declare @eroare varchar(2000)
set @eroare=''
begin try
	set transaction isolation level read uncommitted
	IF OBJECT_ID('tempdb..#explic') IS NOT NULL drop table #explic
	if object_id('tempdb..#fisa') is not null drop table #fisa
	if object_id('tempdb..#factura') is not null drop table #factura

	select p.Tip, p.tert,p.Factura,p.data, MAX(n.denumire) as denumire
	into #explic from pozdoc p 
	inner join nomencl n on n.Cod=p.Cod
	where p.Tip in ('AP','AS','RM','RS') and @cu_explicatii='1' and (@ctert is null or p.tert=@ctert) and (@cfactura is null or p.factura=@cfactura)
	group by p.Tip, p.tert,p.Factura,p.data
	
	create table #facturi(tip varchar(1), tert varchar(100), factura varchar(100), data datetime, data_scadentei datetime, valoare decimal(15,3), tva_22 decimal(15,3), sold decimal(15,3))
	
	if @datasus is null	and @datajos is null--> raportul "la zi"
	begin
		insert into #facturi (tip, tert, factura, data, data_scadentei, valoare, tva_22, sold)
		select (case when f1.tip=0x54 then 'F' else 'B' end) as tip, f1.tert,f1.factura, f1.data, f1.data_scadentei, f1.valoare, f1.tva_22,
			f1.sold
		from facturi f1
		where f1.sold>=@soldmin --and f1.data between @datajos and @datasus
			and (@ctert is null or f1.tert like @ctert) and (@cfactura is null or f1.factura like @cFactura)
	end
	else
	begin	--> daca nu este "la zi" raportul isi va lua datele pe baza raportului Fisa terti:
		if object_id('tempdb..#fisa') is null
		begin
			create table #fisa (ceva char(1) default '')
			exec rapFisaTerti_structFisa
		end
		
		exec rapFisaTerti @cFurnBenef=''
		, @cDataJos=@datajos
		,@cData=@datasus
		,@ctert=@ctert
		,@cfactura=@cfactura
		,@soldmin=@soldmin
		
		insert into #facturi (tip, tert, factura, data, data_scadentei, valoare, tva_22, sold)
		select f1.furn_benef as tip, f1.tert,f1.factura,f1.data_facturii data, max(f1.data_scadentei) data_scadentei,
			sum(f1.soldi+f1.valoare) valoare, sum(f1.tva) tva, sum(f1.soldi+f1.valoare+f1.tva-f1.achitat) as sold
		from #fisa f1
		group by f1.furn_benef, f1.tert, f1.factura, f1.data_facturii
	end
	
	select @datasus=isnull(@datasus,'2100-1-1'), @datajos=ISNULL(@datajos,'1901-1-1')
	select rtrim(case when isnull(f1.tert,'')='' then f2.tert else f1.tert end)+' - '+rtrim(isnull(t.denumire,'<Necatalogat>')) as denumire,
			(case when isnull(f1.tert,'')=''
		then f2.tert else f1.tert end) as partener,
		f1.tert, f1.Factura_furn, f1.Dataf, f1.Datascf, f1.Valoare_factura_f, f1.serviciu1, f1.Sold_ca_furnizor, f1.numar_rand_f1,
		f2.Factura_benef, f2.Datab, f2.Datascb, f2.Valoare_factura_b, f2.serviciu2, f2.Sold_ca_beneficiar, f2.numar_rand_f2,
		isnull(f1.Sold_ca_furnizor,0)-isnull(f2.Sold_ca_beneficiar,0) as diferente
	 from  	(select f1.tert,f1.factura as Factura_furn,f1.data as Dataf,f1.data_scadentei as Datascf,f1.valoare+f1.tva_22 as Valoare_factura_f,
			e.denumire as serviciu1, isnull(f1.sold,0) as Sold_ca_furnizor,row_number() 
			over (partition by f1.tert order by f1.tert,f1.data) as numar_rand_f1
			from #facturi f1 
				left join #explic e on e.tert=f1.tert and e.factura=f1.factura
			where f1.tip='F' and abs(f1.sold)>=@soldmin and f1.data between 
				@datajos and @datasus) f1 full join 
		(select f2.tert,f2.factura as Factura_benef,f2.data as Datab,f2.data_scadentei as Datascb,f2.valoare+ f2.tva_22 as Valoare_factura_b
			,e.denumire as serviciu2,isnull(f2.sold,0) as Sold_ca_beneficiar,
			row_number() over (partition by f2.tert order by f2.tert,f2.data) as numar_rand_f2
			from #facturi f2 
				left join #explic e on e.tert=f2.tert and e.factura=f2.factura
			where f2.tip='B' and abs(f2.sold)>=@soldmin and 
				f2.data between @datajos and @datasus) f2 on numar_rand_f1=numar_rand_f2 and f1.tert=f2.tert
		left join terti t on t.tert=(case when isnull(f1.tert,'')='' then f2.tert else f1.tert end)
		left join
		(select tert,max(f1.factura) as Fact_furn
			from #facturi f1
			where tip='F' and abs(f1.sold)>=@soldmin and data between @datajos and @datasus and @tip_tert <>2
	group by tert) f11 on f11.tert=(case when isnull(f1.tert,'nulll')='nulll' then f2.tert else f1.tert end)
		left join 
		(select tert,max(f1.factura) as Fact_furn
			from facturi f1
			where tip='B' and abs(f1.sold)>=@soldmin and data between @datajos and @datasus and @tip_tert <>3
	group by tert) f22 on f22.tert=(case when isnull(f1.tert,'nulll')='nulll' then f2.tert else f1.tert end)
	where	--(isnull(rtrim(f1.[factura furn.]),'')<>'' or isnull(rtrim(f2.[factura benef.]),'')<>'') and 
		(isnull(@ctert,'nulll')='nulll' or @ctert=t.tert or @ctert='' and isnull(t.tert,'nulll')='nulll') --and (isnull(@cfactura,'nullll')='nullll' or @cfactura=factura_furn or @cfactura=factura_benef)
		and (case @tip_tert when 3 then isnull(f11.tert,'nulll')
							when 2 then isnull(f22.tert,'nulll')
							when 1 then (case when isnull(f11.tert,'nulll')<>'nulll' then isnull(f22.tert,'nulll') else 'nulll' end)
							else '' end)<>'nulll'
	order by 	t.tert,f1.dataf,f2.datab
end try
begin catch
	set @eroare=ERROR_MESSAGE()+' (rapFisaParteneri)'
end catch

IF OBJECT_ID('tempdb..#explic') IS NOT NULL drop table #explic
if object_id('tempdb..#fisa') is not null drop table #fisa
if object_id('tempdb..#factura') is not null drop table #factura
if (@eroare<>'')
	select '<EROARE>' as partener, @eroare as denumire
