--***
create procedure rapVerificareDescarcareBon (@datajos datetime,  @datasus datetime, @necorelate bit=1)
as
begin
declare @eroare varchar(2000)
begin try
	set transaction isolation level read uncommitted
	if object_id('tempdb..#pozdoc') is not null drop table #pozdoc
	if object_id('tempdb..#bp') is not null drop table #bp
	if object_id('tempdb..#bpGrupat') is not null drop table #bpGrupat

	declare @DetaliereBonuri bit
	select @DetaliereBonuri=0
	select @DetaliereBonuri=isnull((select val_logica from par where tip_parametru='PO' and Parametru='DETBON'),0)
	
	select space(8) nrPozdoc, b.loc_de_munca, b.data, b.cod_produs, b.total, b.cantitate, b.Casa_de_marcat, b.numar_bon
	into #bp
	from bp b where b.factura_chitanta=1 and data between @datajos and @datasus
	
	update b set
		nrPozdoc=left((case when @DetaliereBonuri=1 then RTrim(CONVERT(varchar(4),b.Casa_de_marcat))+right(replace(str(b.Numar_bon),' ','0'),4)
							else '' end),8)
		from #bp b

	select b.loc_de_munca b_gestiune, b.data b_data, b.cod_produs b_cod, sum(b.total) b_valoare, sum(b.cantitate) b_cantitate,
			(case when @DetaliereBonuri=1 then b.nrPozdoc else '' end) nrPozdoc
	into #bpgrupat
	from #bp b
	group by b.loc_de_munca, b.data, b.cod_produs, (case when @DetaliereBonuri=1 then b.nrPozdoc else '' end)
	create index ind_#bpgrupat on #bpgrupat(b_gestiune, b_data, b_cod, nrPozdoc)
	
	select p.gestiune, p.data, p.cod, 
		(case when @DetaliereBonuri=1 then p.numar else '' end) as nrPozdoc,
			sum(p.cantitate) cantitate, sum(p.cantitate*p.pret_cu_amanuntul) valoare
	into #pozdoc
	from pozdoc p where p.tip='AC' and data between @datajos and @datasus
	group by p.gestiune, p.data, p.cod, (case when @DetaliereBonuri=1 then p.numar else '' end)
	create index ind_#pozdoc on #pozdoc(gestiune, data, cod, nrPozdoc)
	
	select b.b_gestiune, b.b_data, b.b_cod, b.b_cantitate, b.b_valoare, p.gestiune, p.data, p.cod, p.cantitate, p.valoare
	from #bpgrupat b 
		left join #pozdoc p on b.b_gestiune=p.gestiune and b.b_data=p.data and b.b_cod=p.cod and b.nrPozdoc=p.nrPozdoc
	where (@necorelate=0 or b.b_cantitate<>p.cantitate or b.b_valoare<>p.valoare or p.gestiune is null)
	order by b.b_data, b.b_gestiune, b.b_cod
	
end try
begin catch
	select @eroare=ERROR_MESSAGE()+'(rapVerificareDescarcareBon '+convert(varchar(20),ERROR_LINE())+')'
end catch

if object_id('tempdb..#pozdoc') is not null drop table #pozdoc
if object_id('tempdb..#bp') is not null drop table #bp
if object_id('tempdb..#bpGrupat') is not null drop table #bpGrupat

if len(@eroare)>0 raiserror(@eroare,16,1)
end
