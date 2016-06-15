--***
create procedure yso_rapVerificareDescarcareBon 
	(@datajos datetime,  @datasus datetime, @necorelate bit=1, @gestiune varchar(9)=null)
as
begin
declare @eroare varchar(2000)
begin try
	set transaction isolation level read uncommitted
	if object_id('tempdb..##pozdocte') is not null drop table ##pozdocte
	if object_id('tempdb..##pozdocac') is not null drop table ##pozdocac
	if object_id('tempdb..##bp') is not null drop table ##bp
	if object_id('tempdb..##bpGrupat') is not null drop table ##bpGrupat

	declare @DetaliereBonuri bit
	select @DetaliereBonuri=0
	select @DetaliereBonuri=isnull((select val_logica from par where tip_parametru='PO' and Parametru='DETBON'),0)
	
	select space(8) nrPozdoc, a.Gestiune ,b.loc_de_munca, b.data, b.cod_produs, b.total, b.cantitate, b.Casa_de_marcat, b.numar_bon, b.Tip
	into ##bp
	from bp b inner join antetbonuri a on a.IdAntetBon=b.IdAntetBon 
	where b.factura_chitanta=1 and data between @datajos and @datasus
		--/*sp
		and b.Tip='21' and (isnull(@gestiune,'')='' or a.Gestiune=@gestiune)
		--sp*/
	
	update b set
		nrPozdoc=left((case when @DetaliereBonuri=1 then RTrim(CONVERT(varchar(4),b.Casa_de_marcat))+right(replace(str(b.Numar_bon),' ','0'),4)
							else '' end),8)
		from ##bp b

	select b.gestiune as b_gestiune, b.data b_data, rtrim(b.cod_produs) b_cod, sum(b.total) b_valoare, sum(b.cantitate) b_cantitate,
/*sp		(case when @DetaliereBonuri=1 then b.nrPozdoc else '' end) nrPozdoc
--sp*/b.nrPozdoc, Casa_de_marcat=MAX(b.Casa_de_marcat), Numar_bon=MAX(b.Numar_bon)
	into ##bpgrupat
	from ##bp b
	group by b.Gestiune, b.data, b.cod_produs, /*sp (case when @DetaliereBonuri=1 then b.nrPozdoc else '' end) 
													--sp*/b.nrPozdoc
	create index ind_##bpgrupat on ##bpgrupat(b_gestiune, b_data, b_cod, nrPozdoc)
	
	select p.gestiune, p.data, p.cod, 
		(case when @DetaliereBonuri=1 then p.numar else '' end) as nrPozdoc,
			sum(p.cantitate) cantitate, sum(p.cantitate*p.pret_cu_amanuntul) valoare
	into ##pozdocac
	from pozdoc p where p.tip='AC' and data between @datajos and @datasus 
		/*sp*/ and (isnull(@gestiune,'')='' or p.Gestiune=@gestiune) /*sp*/
	group by p.gestiune, p.data, p.cod, (case when @DetaliereBonuri=1 then p.numar else '' end)
	create index ind_##pozdocac on ##pozdocac(gestiune, data, cod, nrPozdoc)
	
--/*sp
	select gestiune=max(p.gestiune), p.data, p.cod, 
		(case when @DetaliereBonuri=1 then p.numar else '' end) as nrPozdoc,
			sum(p.cantitate) cantitate, sum(p.cantitate*p.pret_cu_amanuntul) valoare
		, sum(p.cantitate*p.Pret_amanunt_predator) valoare_predator
		,p.Gestiune_primitoare
	into ##pozdocte
	from pozdoc p where p.tip='TE' and data between @datajos and @datasus
		/*sp*/ and (isnull(@gestiune,'')='' or p.Gestiune=@gestiune) /*sp*/
	group by p.gestiune, p.data, p.cod, (case when @DetaliereBonuri=1 then p.numar else '' end), p.Gestiune_primitoare
	create index ind_##pozdocte on ##pozdocte(gestiune, data, cod, nrPozdoc, Gestiune_primitoare)
--sp*/

	select b.b_gestiune, b.b_data, b.b_cod, b.b_cantitate, b.b_valoare, p.gestiune, p.data, p.cod, p.cantitate, p.valoare
--/*sp
	,p.nrPozdoc, b.Casa_de_marcat, b.Numar_bon
	--into yso_rapVerificareDescarcareBonTblRez1
--sp*/	
	from ##bpgrupat b 
/*sp
		left join ##pozdocte t on b.b_gestiune=t.gestiune and b.b_data=t.data and b.b_cod=t.cod and b.nrPozdoc=t.nrPozdoc
--sp*/	
		left join ##pozdocac p on p.gestiune=b.b_gestiune and b.b_data=p.data and b.b_cod=p.cod 
			and b.nrPozdoc=p.nrPozdoc

	where (@necorelate=0 or b.b_cantitate<>p.cantitate or abs(b.b_valoare-p.valoare)>0.5 or p.gestiune is null)
	order by b.b_data, b.b_gestiune, b.b_cod /*sp*/, p.nrPozdoc, b.Casa_de_marcat, b.Numar_bon /*sp*/
	
end try
begin catch
	select @eroare=ERROR_MESSAGE()+'(yso_rapVerificareDescarcareBon '+convert(varchar(20),ERROR_LINE())+')'
end catch

if object_id('tempdb..##pozdocte') is not null drop table ##pozdocte
if object_id('tempdb..##pozdocac') is not null drop table ##pozdocac
if object_id('tempdb..##bp') is not null drop table ##bp
if object_id('tempdb..##bpGrupat') is not null drop table ##bpGrupat

if len(@eroare)>0 raiserror(@eroare,16,1)
end
