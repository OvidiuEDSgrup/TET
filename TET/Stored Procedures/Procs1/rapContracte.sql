
/*
	exec rapContracte '', '2013-08-01', '2014-08-31', '2013-08-01', '2014-08-31', 'CB', null, null, null, null, 1, 1
*/

create procedure rapContracte @sesiune varchar(50), @datajos datetime, @datasus datetime,
	@datafjos datetime=null, @datafsus datetime=null,	--> interval pentru data facturii
	@datavjos datetime=null, @datavsus datetime=null,	--> vor aparea doar acele contracte care sunt valabile in intervalul specificat
	@tip_contract varchar(2),
	@grupa_tert varchar(300)=null,
	@tert varchar(100)=null, @contract varchar(100)=null, @cont_factura varchar(300)=null,
	@valTva bit=0, @pozGrupe bit=0
as
begin try
	declare
		@utilizator varchar(20), @eLmUtiliz int
		,@iValabilitate bit --> flag interval valabilitate

	if @datafjos is null set @datafjos='2000-1-1'
	if @datafsus is null set @datafsus='2100-1-1'
	set @iValabilitate=0
	if 	@datavjos is not null or @datavsus is not null
		set @iValabilitate=1
	if @datavjos is null set @datavjos='2000-1-1'
	if @datavsus is null set @datavsus='2100-1-1'

	select @utilizator = dbo.fIaUtilizator(@sesiune)
	
	declare @LmUtiliz table(valoare varchar(200))
	insert into @LmUtiliz(valoare)
	select cod from lmfiltrare where utilizator = @utilizator
	
	set @eLmUtiliz = isnull((select max(1) from @LmUtiliz), 0)

	if object_id('tempdb..#pozContracteFiltrate') is not null drop table #pozContracteFiltrate
	if object_id('tempdb..#contractatComandat') is not null drop table #contractatComandat
	if object_id('tempdb..#facturat') is not null drop table #facturat
	if object_id('tempdb..#incasat') is not null drop table #incasat

	/** Aducem doar contractele cu care vom lucra si pozitiile lor, in urma aplicarii filtrelor. */
	select
		pc.idPozContract as idPozContract, rtrim(c.tert) as tert, rtrim(t.denumire) as dentert,
		pc.termen as termen, isnull(rtrim(pc.cod), rtrim(g.grupa)) as cod,
		isnull(rtrim(n.Denumire), rtrim(g.Denumire) + ' (grupa)') as dencod, c.data as data, rtrim(c.numar) as [contract],
		isnull(pc.cantitate, 0) as cantitate, isnull(pc.pret, 0) as pret, isnull(n.Cota_TVA, 0) as cota_tva,
		isnull(n.UM, '') as um, c.idcontract, c.valabilitate
	into #pozContracteFiltrate
	from PozContracte pc
	inner join Contracte c on pc.idContract = c.idContract
	left join terti t on t.Tert = c.tert and (@grupa_tert is null or t.grupa = @grupa_tert)
	left join nomencl n on n.Cod = pc.cod
	left join grupe g on g.Grupa = pc.grupa
	where c.data between @datajos and @datasus
		and c.tip = @tip_contract and (@tert is null or c.tert = @tert)
		and (@contract is null or c.numar = @contract)
		and (@grupa_tert is null or t.grupa is not null)
		and (@eLmUtiliz = 0 or exists (select 1 from @LmUtiliz u where u.valoare = c.Loc_de_munca))
		and (@pozGrupe = 1 or pc.grupa is null)
		and (@iValabilitate=0 and valabilitate is null or valabilitate is not null
				and (c.data between @datavjos and @datavsus and c.valabilitate<=@datavsus
					-- or c.valabilitate between @datavjos and @datavsus
					)
			)

	/** Cantitatile contractate si comandate*/
	select
		pcf.idPozContract, pc.idPozContract as comPozContract, isnull(pcf.cantitate, 0) as cant_contractata, isnull(pc.cantitate, 0) as cant_comandata,
		isnull(pcf.cantitate * pcf.pret, 0) as valoare_contractata, isnull(pc.cantitate * pc.pret, 0) as val_comandata,
		(case when lc.idPozContractCorespondent is null then 0 else 1 end) as gasitdinprima, pcf.cod, pcf.idcontract
	into #contractatComandat
	from #pozContracteFiltrate pcf
	left join LegaturiContracte lc on lc.idPozContractCorespondent = pcf.idPozContract
	left join PozContracte pc on pc.idPozContract = lc.idPozContract
	where @tip_contract in ('CB', 'CF')
	union all
	select
		pcf.idPozContract, null as comPozContract, isnull(pcf.cantitate, 0) as cant_contractata, 1 as cant_comandata,
		isnull(pcf.cantitate * pcf.pret, 0) as valoare_contractata, 0 as val_comandata, 1, pcf.cod, pcf.idcontract
	from #pozContracteFiltrate pcf
	where @tip_contract = 'CS'

	--> completare cu datele comenzilor "legacy" pentru comandat - legatura prin intermediul antetului si a codului din pozitii:
	update c set cant_comandata=isnull(l.cantitate,0), val_comandata=isnull(l.val_comandata,0), comPozContract=isnull(c.idPozContract,0)
	from #contractatComandat c
	cross apply( select sum(isnull(pl.cantitate,0)) cantitate, sum(isnull(pl.cantitate*pl.pret,0)) val_comandata
		from contracte l
			inner join pozcontracte pl on pl.idcontract=l.idcontract and pl.cod=c.cod
		where l.idcontractcorespondent=c.idcontract) l
	where c.gasitdinprima=0
	
	/** Cantitatile facturate */
	select
		pc.idPozContract, sum(isnull(poz.Cantitate * poz.Pret_vanzare + poz.TVA_deductibil, 0)) as val_facturata,
		sum(isnull(poz.Cantitate, 0)) as cant_facturata, rtrim(poz.tert) as tert, rtrim(poz.Factura) as factura,
		poz.Data_facturii as data_facturii
		--,(case when max(lc.idPozContractCorespondent) is null then 0 else 1 end) as gasitdinprima, max(pcf.cod) cod, max(pcf.idcontract) idcontract
	into #facturat
	from #pozContracteFiltrate pcf
	inner join LegaturiContracte lc on lc.idPozContractCorespondent = pcf.idPozContract
	inner join PozContracte pc on pc.idPozContract = lc.idPozContract
	inner join LegaturiContracte lcc on lcc.idPozContract = pc.idPozContract
	left join pozdoc poz on poz.idPozDoc = lcc.idPozDoc
	where @tip_contract in ('CB', 'CF')
		and lcc.idPozContractCorespondent is null
	group by pc.idPozContract, poz.tert, poz.Factura, poz.Data_facturii

	union all

	select
		pcf.idPozContract, sum(isnull(poz.Cantitate * poz.Pret_vanzare, 0)) as val_facturata,
		sum(isnull(poz.Cantitate, 0)) as cant_facturata, rtrim(poz.tert) as tert, rtrim(poz.Factura) as factura,
		poz.Data_facturii as data_facturii--, 1, max(pcf.cod), max(pcf.idcontract)
	from #pozContracteFiltrate pcf
	inner join LegaturiContracte lc on lc.idPozContract = pcf.idPozContract
	left join pozdoc poz on poz.idPozDoc = lc.idPozDoc
	where @tip_contract = 'CS'
	group by pcf.idPozContract, poz.Tert, poz.Factura, poz.Data_facturii

	--> completare cu datele comenzilor "legacy" pentru facturat - legatura prin intermediul antetului si a codului din pozitii:
	union all
	select max(pcf.idPozContract), sum(isnull(poz.Cantitate * poz.Pret_vanzare + poz.TVA_deductibil, 0)) as val_facturata,
		sum(isnull(poz.Cantitate, 0)) as cant_facturata, rtrim(poz.tert) as tert, rtrim(poz.Factura) as factura,
		poz.Data_facturii as data_facturii
	from  #pozContracteFiltrate pcf
		inner join contracte l on l.idcontractcorespondent=pcf.idcontract
		inner join pozcontracte pc on pc.idcontract=l.idcontract and pc.cod=pcf.cod
		inner join legaturicontracte lg on lg.idpozcontract=pc.idpozcontract
		inner join pozdoc poz on poz.idpozdoc=lg.idpozdoc
	where not exists (select 1 from LegaturiContracte lc where lc.idPozContractCorespondent = pcf.idPozContract and idPozContractCorespondent is not null)
	group by pc.idPozContract, poz.tert, poz.Factura, poz.Data_facturii

	/** Cantitatile incasate */
	select
		p.tert, p.factura,
		sum(convert(decimal(12,2), p.Suma)) as val_incasata
	into #incasat
	from pozplin p
	where exists (select 1 from #facturat f where p.Subunitate = '1' and p.tert = f.tert and f.factura = p.Factura)
		and p.Plata_incasare = 'IB'
	group by p.tert, p.factura

	alter table #incasat add valoare_facturata float, k float

	update #incasat
	set valoare_facturata = convert(decimal(12,2), p.valoare_facturata),
		k = convert(decimal(12,2), #incasat.val_incasata / p.valoare_facturata)
	from (
		select
			poz.tert, poz.factura, sum(poz.Cantitate * poz.Pret_vanzare + poz.TVA_deductibil) as valoare_facturata
		from #pozContracteFiltrate pcf
		inner join LegaturiContracte lc on lc.idPozContractCorespondent = pcf.idPozContract
		inner join PozContracte pc on pc.idPozContract = lc.idPozContract
		inner join LegaturiContracte lcc on lcc.idPozContract = pc.idPozContract
		inner join pozdoc poz on poz.idPozDoc = lcc.idPozDoc
		where @tip_contract in ('CB', 'CF')
			and poz.Tip in ('AP', 'AS', 'AC')
		group by poz.tert, poz.Factura
		union all
		select
			poz.tert, poz.factura, sum(poz.Cantitate * poz.Pret_vanzare + poz.TVA_deductibil) as valoare_facturata
		from #pozContracteFiltrate pcf
		inner join LegaturiContracte lc on lc.idPozContract = pcf.idPozContract
		inner join pozdoc poz on poz.idPozDoc = lc.idPozDoc
		where @tip_contract = 'CS'
			and poz.Tip in ('AP', 'AS', 'AC')
		group by poz.tert, poz.Factura
		union all
		--> completare cu datele comenzilor "legacy" pentru incasat - legatura prin intermediul antetului si a codului din pozitii:
		select
			poz.tert, poz.factura, sum(poz.Cantitate * poz.Pret_vanzare + poz.TVA_deductibil) as valoare_facturata
		from  #pozContracteFiltrate pcf
			inner join contracte l on l.idcontractcorespondent=pcf.idcontract
			inner join pozcontracte pc on pc.idcontract=l.idcontract and pc.cod=pcf.cod
			inner join legaturicontracte lg on lg.idpozcontract=pc.idpozcontract
			inner join pozdoc poz on poz.idpozdoc=lg.idpozdoc
		where not exists (select 1 from LegaturiContracte lc where lc.idPozContractCorespondent = pcf.idPozContract and idPozContractCorespondent is not null)
			and poz.Tip in ('AP', 'AS', 'AC')
		group by pc.idPozContract, poz.tert, poz.Factura, poz.Data_facturii
	) as p
	where p.tert = #incasat.tert and p.factura = #incasat.Factura

	/** Select-ul principal */
	select
		pcf.tert as tert, pcf.dentert as dentert, convert(varchar(10), pcf.data, 103) as data, convert(varchar(10), pcf.valabilitate, 103) as valabilitate,
		pcf.contract as [contract], convert(varchar(10), pcf.termen, 103) as termen, convert(decimal(17,5), pcf.pret) as pret,
		pcf.cod as cod, pcf.dencod as dencod, isnull(pcf.um, '') as um, cc.cant_contractata as cant_contractata,
		cc.valoare_contractata + isnull((case when @valTVA = 1 then cc.valoare_contractata * pcf.cota_tva/100 else 0 end), 0) as val_contractata,
		isnull(cc.cant_comandata, 0) as cant_comandata, isnull(cc.val_comandata, 0) as val_comandata,
		isnull(f.cant_facturata, 0) as cant_facturata, isnull(f.val_facturata, 0) as val_facturata,
		convert(decimal(12,2), isnull(f.val_facturata * i.k, 0)) as val_incasata
	from #pozContracteFiltrate pcf
	inner join #contractatComandat cc on pcf.idPozContract = cc.idPozContract
	left join #facturat f on f.idPozContract = (case when @tip_contract = 'CS' then cc.idPozContract else cc.comPozContract end)
		and (f.data_facturii is null or f.data_facturii between @datafjos and @datafsus)
	left join #incasat i on i.tert = f.tert and i.factura = f.factura
	
end try
begin catch
	declare @mesajEroare varchar(500)
	set @mesajEroare = ERROR_MESSAGE() + ' (' + OBJECT_NAME(@@PROCID) + ')'
	select @mesajEroare dentert, '<EROARE>' tert
	raiserror(@mesajEroare, 16, 1)
end catch
