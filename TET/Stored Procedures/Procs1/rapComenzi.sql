--***
create procedure rapComenzi @sesiune varchar(50)=null, @datajos datetime, @datasus datetime,
	@cod varchar(20)=null, @grupa_cod varchar(13)=null, @tert varchar(13)=null,
	@grupa_tert varchar(300)=null, @comanda varchar(20)=null, @gestiune varchar(13)=null,
	@datajost datetime=null, @datasust datetime=null,
	@stare varchar(1)=null,
	@tip_contract varchar(2),	-- CL = Comanda livrare, CA = Comanda aprovizionare
	@grupare int=0
as
begin try
	
	declare
		@utilizator varchar(20)

	exec wIaUtilizator @sesiune = @sesiune, @utilizator = @utilizator output

	if object_id('tempdb..#pozContracteFiltrate') is not null drop table #pozContracteFiltrate
	if object_id('tempdb..#pozCantitati') is not null drop table #pozCantitati
	if object_id('tempdb..#incasat') is not null drop table #incasat

	/**	Pregatire filtrare pe proprietati utilizatori*/
	declare @fltGstUt int
	declare @GestUtiliz table(valoare varchar(200), cod varchar(20))
	insert into @GestUtiliz(valoare, cod)
	select valoare, cod_proprietate from fPropUtiliz(@sesiune) where cod_proprietate = 'GESTIUNE' and valoare <> ''
	set	@fltGstUt = isnull((select count(1) from @GestUtiliz), 0)

	declare @eLmUtiliz int
	declare @LmUtiliz table(valoare varchar(200), cod_proprietate varchar(20))
	insert into @LmUtiliz(valoare, cod_proprietate)
	select valoare, cod_proprietate from fPropUtiliz(@sesiune) where valoare <> '' and cod_proprietate = 'LOCMUNCA'
	set @eLmUtiliz = isnull((select max(1) from @LmUtiliz), 0)

	/** Contractele si pozitiile filtrate: lucram doar cu cele de care avem nevoie */
	select 
		p.idPozContract as idPozContract, c.tert as tert, rtrim(t.denumire) as nume_tert,
		p.cod as cod, rtrim(n.denumire) as nume_cod, n.um as um,
		p.cantitate as cantitate, c.data as data, c.numar as comanda, rtrim(g.Denumire_gestiune) as dengestiune,
		rtrim(c.explicatii) as explicatii, p.pret as pret, st.denstare as denstare
	into #pozContracteFiltrate
	from PozContracte p
	inner join Contracte c on c.idContract = p.idContract
	left join nomencl n on n.cod = p.cod and (@gestiune is null or @gestiune = n.gestiune)
	left join terti t on c.tert = t.tert and (@grupa_tert is null or t.grupa = @grupa_tert)
	left join gestiuni g on g.Cod_gestiune = n.gestiune
	cross apply (select top 1 j.stare stare, s.denumire denstare from JurnalContracte j 
		inner join StariContracte s on j.stare = s.stare and s.tipContract = c.tip and j.idContract = c.idContract order by j.data desc) st
	where c.data between @datajos and @datasus
		and (c.tip = @tip_contract)
		and (@cod is null or p.cod = @cod)
		and (@grupa_cod is null or n.grupa = @grupa_cod)
		and (@tert is null or @tert = c.tert) and (@grupa_tert is null or t.grupa is not null) 
		and (@comanda is null or @comanda = c.numar)
		and (@gestiune is null or n.gestiune is not null)
		and (@datajost is null or @datasust is null or p.termen between @datajost and @datasust)
		and (@stare is null or st.stare = @stare)
		and (@fltGstUt = 0 or exists (select 1 from @GestUtiliz pr where pr.valoare = n.gestiune))
		and (@eLmUtiliz = 0 or exists (select 1 from @LmUtiliz u where u.valoare = c.Loc_de_munca))
	
	/** Cantitatile insumate si legatura pe pozdoc 
		Left join pe pozdoc si fara clauza where, pentru ca unele comenzi pot fi nefacturate
		(sa se poata vedea cat s-a comandat, iar restul sa fie 0)
	*/
	select
		pcf.idPozContract, sum(pcf.cantitate) as cantitate, sum(isnull(poz.Cantitate, 0)) as cant_facturata,
		sum(isnull(pcf.cantitate * pcf.pret, 0)) as valoare,
		sum(isnull(poz.Cantitate * poz.Pret_vanzare + poz.TVA_deductibil, 0)) as valoare_facturata,
		rtrim(poz.Factura) as factura, rtrim(pcf.tert) as tert
	into #pozCantitati
	from #pozContracteFiltrate pcf
	left join LegaturiContracte lc on lc.idPozContract = pcf.idPozContract
	left join pozdoc poz on poz.idPozDoc = lc.idPozDoc
	where lc.idPozContractCorespondent is null
	group by pcf.idPozContract, poz.Factura, pcf.tert

	/** Cantitatile incasate */
	select
		p.tert, p.factura,
		sum(convert(decimal(12,2), p.Suma)) as val_incasata
	into #incasat
	from pozplin p
	where exists (select 1 from #pozCantitati f where p.Subunitate = '1' and p.tert = f.tert and f.factura = p.Factura)
		and p.Plata_incasare = 'IB'
	group by p.tert, p.factura

	alter table #incasat add valoare_facturata float, k float

	/** Aici punem clauza where pe pozdoc pentru ca valoarea incasata tine cont
		de ce s-a facturat.
	 */
	update #incasat
	set valoare_facturata = convert(decimal(12,2), p.valoare_facturata),
		k = convert(decimal(12,2), #incasat.val_incasata / p.valoare_facturata)
	from (
		select
			poz.tert, poz.factura, sum(poz.Cantitate * poz.Pret_vanzare + poz.TVA_deductibil) as valoare_facturata
		from #pozContracteFiltrate pcf
		inner join LegaturiContracte lc on lc.idPozContract = pcf.idPozContract
		inner join pozdoc poz on poz.idPozDoc = lc.idPozDoc
		where poz.Tip in ('AP', 'AS', 'AC')
		group by poz.tert, poz.factura
	) as p
	where p.tert = #incasat.tert and p.factura = #incasat.Factura

	/** Select-ul principal */
	select (case @grupare when 0 then pcf.tert
						when 1 then pcf.cod else '1' end) as grupare1
		,(case @grupare when 0 then pcf.nume_tert
						when 1 then pcf.nume_cod else 'Unitate' end) as numegrupare1
		,(case @grupare when 1 then pcf.tert else pcf.comanda end) as grupare2
		,(case @grupare when 1 then pcf.nume_tert else isnull(pcf.explicatii, '') end) as numegrupare2
		,(case @grupare when 1 then pcf.comanda else pcf.cod end) as grupare3
		,(case @grupare when 1 then isnull(pcf.explicatii, '') else pcf.nume_cod end) as numegrupare3
		,pcf.tert as tert, pcf.nume_tert as nume_tert, pcf.cod as cod, pcf.nume_cod as nume_cod,
		pcf.um as um, pcf.data as data, pcf.comanda as comanda, isnull(pcf.explicatii, '') as explicatii,
		pcf.denstare as denstare, pcf.dengestiune as dengestiune,
		convert(decimal(12,2), pc.valoare) as valoare, pc.cantitate as cantitate,
		convert(decimal(12,2), pc.cant_facturata) as cant_facturata,
		convert(decimal(12,2), pc.valoare_facturata) as valoare_facturata,
		convert(decimal(12,2), isnull(pc.valoare_facturata * i.k, 0)) as val_incasata
	from #pozContracteFiltrate pcf
	inner join #pozCantitati pc on pc.idPozContract = pcf.idPozContract
	left join #incasat i on pc.tert = i.tert and pc.factura = i.Factura
	order by 1,3,5

end try
begin catch
	declare @mesajEroare varchar(500)
	set @mesajEroare = ERROR_MESSAGE() + ' (' + OBJECT_NAME(@@PROCID) + ')'
	select '<EROARE>' as grupare1, @mesajEroare as numegrupare1
	raiserror(@mesajEroare, 16, 1)
end catch
