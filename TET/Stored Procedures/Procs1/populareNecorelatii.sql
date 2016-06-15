--***
-------------Procedura care populeaza tabela de necorelatii------------------
create procedure populareNecorelatii(@data_jos datetime, @data_sus datetime,@pretAm int,@tip_necorelatii varchar(2),@inUM2 int,@filtruCont varchar(40),
	@filtruGest varchar(13),@filtruCod_intrare varchar(13),	@filtruGrupa varchar(13),@tipStoc varchar(1),@filtruCod varchar(20),@filtruLM varchar(13),
	@filtruComanda varchar(20),@filtruFurn varchar(13),@filtruLot varchar(13),@filtruLocatie varchar(20),@corelatiiPeContAtribuit int,@filtruContCor varchar(40),
	@rulajePeLocMunca int,@valuta varchar(3))
AS
/*
exec populareNecorelatii '2013-10-01','2013-10-31',0,'SC',0,null,null,null,null,null,null,null,null,null,null,null,1,null,0,null
select * from necorelatii where tip_necorelatii='SC' and tip_document in ('DF','DI')
*/
begin try

	declare @sub varchar(2),@mesajeroare varchar(500),@utilizator varchar(20),@dincorel int,@filtruFact varchar(20),@parXMLJ xml,@lista_lm int,@parXMLFact xml
	
	exec luare_date_par 'GE', 'SUBPRO', 0, 0, @sub output 
	
	set @utilizator=dbo.fIauUtilizatorCurent()
	
	set @dincorel=case when @tip_necorelatii='SC' then 1 else 0 end
	set @lista_lm=dbo.f_areLMFiltru(@utilizator)
	
	if exists (select * from sysobjects where name ='necorelatii')
		delete from necorelatii where utilizator=@utilizator and tip_necorelatii=@tip_necorelatii
	/*else --am pus crearea tabelei necorelatii in +tabele
		create table necorelatii(
		tip_necorelatii varchar(2),
		tip_document varchar(2),
		tip_alte varchar(2),
		numar varchar(20),
		data datetime,
		cont varchar(40),
		valoare_1 float,
		valoare_2 float,
		valoare_3 float,
		valoare_4 float,
		valuta varchar(13),
		lm varchar(13),
		msg_eroare varchar(500),
		utilizator varchar(20),										
		)
	*/
	
	if @tip_necorelatii in ('EP','EI') -- Efecte plata / Efecte incasare
	begin

		if object_id('tempdb..#ef_plata') is not null drop table #ef_plata

		select
			rtrim(pp.subunitate) as subunitate,
			pp.idPozPlin as numar_pozitie,
			@tip_necorelatii as tip_necorelatii,
			'EF' as tip_document,
			'' as tip_alte,
			rtrim(pp.cont) as numar, 
			pp.data as data,
			rtrim(pp.cont) as cont,
			convert(float,pp.suma) as valoare_1,
			convert(float,0) as valoare_2,
			convert(float,0) as valoare_3,
			convert(float,0) as valoare_4,
			'' valuta,
			rtrim(pp.loc_de_munca) as lm,
			'' as msg_eroare,
			@utilizator as utilizator
		into #ef_plata
		from pozplin pp
		where 
			isnull(pp.efect,'') <> ''
			and right(@tip_necorelatii,1) = (case when pp.plata_incasare='PS' then 'I' when pp.plata_incasare='IS' then 'P' else left(pp.plata_incasare,1) end)
			and pp.data between @data_jos and @data_sus

		update e
			set valoare_2 = x.suma
		from #ef_plata e 
		cross apply 
			(select top 1 sum(isnull(suma,0)) suma 
			from pozincon p 
			where p.subunitate=e.subunitate and p.Numar_document=e.cont and p.data=e.data and p.numar_pozitie=e.numar_pozitie
			group by p.Subunitate, p.numar_document, p.data) x

		insert into necorelatii	(tip_necorelatii,tip_document,tip_alte,numar,data,cont,valoare_1,valoare_2,valoare_3,valoare_4,valuta,lm,msg_eroare,utilizator)
		select tip_necorelatii,tip_document,tip_alte,numar,data,cont,valoare_1,valoare_2,valoare_3,valoare_4,valuta,lm,msg_eroare,utilizator
		from #ef_plata
		where valoare_1 != valoare_2

		if object_id('tempdb..#ef_plata') is not null drop table #ef_plata

	end

	if @tip_necorelatii = 'DE' -- Deconturi
	begin

		if object_id('tempdb..#necorelatii_dec') is not null drop table #necorelatii_dec

		select
			rtrim(pp.subunitate) as subunitate,
			pp.idPozPlin as numar_pozitie,
			@tip_necorelatii as tip_necorelatii,
			'DE' as tip_document,
			'' as tip_alte,
			rtrim(pp.cont) as numar, 
			pp.data as data,
			rtrim(pp.cont) as cont,
			convert(float,(case when isnull(pp.valuta,'')!='' then pp.suma_valuta else pp.suma end)) as valoare_1,
			convert(float,0) as valoare_2,
			convert(float,0) as valoare_3,
			convert(float,0) as valoare_4,
			rtrim(pp.valuta) valuta,
			rtrim(pp.loc_de_munca) as lm,
			'' as msg_eroare,
			@utilizator as utilizator
		into #necorelatii_dec
		from pozplin pp
		where 
			isnull(pp.decont,'') <> ''
			and pp.data between @data_jos and @data_sus

		update d
			set valoare_2 = x.suma
		from #necorelatii_dec d
		cross apply 
			(select top 1 (case when isnull(d.valuta,'') != '' then sum(isnull(suma_valuta,0)) else sum(isnull(suma,0)) end) suma 
			from pozincon p 
			where p.subunitate=d.subunitate and p.Numar_document=d.cont and p.data=d.data and p.numar_pozitie=d.numar_pozitie
			group by p.Subunitate, p.numar_document, p.data) x

		insert into necorelatii	(tip_necorelatii,tip_document,tip_alte,numar,data,cont,valoare_1,valoare_2,valoare_3,valoare_4,valuta,lm,msg_eroare,utilizator)
		select tip_necorelatii,tip_document,tip_alte,numar,data,cont,valoare_1,valoare_2,valoare_3,valoare_4,valuta,lm,msg_eroare,utilizator
		from #necorelatii_dec
		where valoare_1 != valoare_2

		if object_id('tempdb..#necorelatii_dec') is not null drop table #necorelatii_dec

	end

	--select @tip_necorelatii, @data_jos, @data_sus, @corelatiiPeContAtribuit, @filtruCont
	if @tip_necorelatii in ('BE','FU','FB','FF') 
	begin
		/* se preiau datele in tabela #docfacturi prin procedura pFacturi (in locul functiei fFacturi) */
		if object_id('tempdb..#docfacturi') is not null drop table #docfacturi
		create table #docfacturi (furn_benef char(1))
		exec CreazaDiezFacturi @numeTabela='#docfacturi'
	end
	
	if @tip_necorelatii in ('BE','FU','FB','FF') 
	begin
		set @parXMLFact=(select (case when @tip_necorelatii in ('BE','FU') then LEFT(@tip_necorelatii,1) else RIGHT(@tip_necorelatii,1) end) as furnbenef, 
			(case when @tip_necorelatii in ('BE','FU') then @data_jos else '01/01/1921' end) as datajos, (case when @tip_necorelatii in ('BE','FU') then @data_sus else '12/31/2999' end) as datasus, 
			@filtruCont as contfactura, (case when @tip_necorelatii in ('BE','FU') then 1 else 0 end) as strictperioada for xml raw)
		exec pFacturi @sesiune=null, @parXML=@parXMLFact

		select p.subunitate, p.tert, p.factura, p.tip, p.numar, p.data, (case when p.data between @data_jos and @data_sus then '2' else '1' end) as in_perioada, 
			p.valoare+p.tva as total, 0 as tva_11, p.tva as tva_22, p.achitat as achitat, 
			p.loc_de_munca, p.comanda, p.cont_de_tert, p.fel, p.cont_coresp, space(3) as valuta, p.explicatii, p.numar_pozitie, 
			(case when (case when @tip_necorelatii in ('BE','FU') then LEFT(@tip_necorelatii,1) else RIGHT(@tip_necorelatii,1) end)='F' 
				then (case when p.tip in ('SI', 'PF', 'PR') then 'FC' when p.tip in ('SX', 'CO', 'FX', 'C3', 'RX') then 'D' else 'C' end) 
				else (case when p.tip in ('SI', 'IB', 'IR') then 'FD' when p.tip in ('IX', 'BX', 'CO', 'C3', 'AX') then 'C' else 'D' end) end) as op,
			p.gestiune, p.data_facturii, p.data_scadentei, 0 as curs, p.nr_dvi as DVI, p.barcod, 0 as totLPV, 0 as achLPV, space(10) as Utilizator, contTVA, contract, data_platii 
		into #doctertt 
		from #docfacturi p
		/*from dbo.fFacturi ((case when @tip_necorelatii in ('BE','FU') then LEFT(@tip_necorelatii,1) else RIGHT(@tip_necorelatii,1) end), 
			(case when @tip_necorelatii in ('BE','FU') then @data_jos else '01/01/1921' end), (case when @tip_necorelatii in ('BE','FU') then @data_sus else '12/31/2999' end), 
			null, '%', isnull(@filtruCont,''), 0, 0, (case when @tip_necorelatii in ('BE','FU') then 1 else 0 end), '', null) p */
		where ((case when @tip_necorelatii in ('BE','FU') then 1 else 0 end)=0 or p.tip<>'SI') 
	end
		
	if @tip_necorelatii in ('BE','FU') --necorelatii terti - contabilitate
	begin
		if @corelatiiPeContAtribuit=1 --necorelatii pe cont atribuit
		begin
			select subunitate, max(case when tip in ('RP','RQ') then 'RM' when tip='SX' then 'SF' when tip='FX' then 'CF' when tip='IX' then 'IF' 
				when tip='BX' then 'CB' when tip='AX' then 'AP' when tip='RX' then 'RM' else tip end) as tip, 
				max(ltrim((case when left(tip,1)='M' then tip else '' end)+numar)) as numar, data, 
				(case when fel=2 or fel=1 or max(tip) in ('FB','FF') or ((max(tip)='SF' or max(tip)='IF') and max(achitat)=0) then sum(total) else sum(achitat) end) as total, 
				cont_de_tert, (case when fel=3 then abs(numar_pozitie) else 1 end) as numar_pozitie, fel, (case when fel=3 then cont_coresp else '' end) as cont_coresp 
			into #valdoc 
			from #doctertt
			where cont_de_tert in (select cont from conturi where sold_credit=(case when @tip_necorelatii='FU' then 1 else 2 end)) and data between @data_jos and @data_sus 
			group by subunitate, (case when tip in ('RP','RQ') then 'RM' when tip='SX' then 'SF' when tip='FX' then 'CF' when tip='IX' then 'IF' 
				when tip='BX' then 'CB' when tip='AX' then 'AP' when tip='RX' then 'RM' else tip end), 
				(case when left(tip,1)='M' then tip else '' end)+(case when fel=3 then '' else numar end), data, cont_de_tert, fel, 
				(case when fel=3 then abs(numar_pozitie) else 1 end), (case when fel=3 then cont_coresp else '' end) 
			
			select p.subunitate, p.tip_document, p.numar_document, p.data, (case when @tip_necorelatii='FU' then -p.suma else p.suma end) as suma, p.cont_debitor as cont, 'D' as tip, 
				(case when p.tip_document='PI' then p.numar_pozitie else 1 end) as numar_pozitie, p.cont_creditor as contc, p.Utilizator 
			into #valincont 
			from pozincon p
				left join lmfiltrare lu on lu.cod=p.loc_de_munca and lu.utilizator=@utilizator
			where p.cont_debitor in (select cont from conturi where sold_credit=(case when @tip_necorelatii='FU' then 1 else 2 end) and cont like rtrim(@filtruCont)+'%') 
				and p.data between @data_jos and @data_sus 
				and (@lista_lm=0 or lu.cod is not null)
			union all 
			select p.subunitate, p.tip_document, p.numar_document, p.data, (case when @tip_necorelatii='BE' then -p.suma else p.suma end) as suma, p.cont_creditor as cont, 'C' as tip, 
				(case when p.tip_document='PI' then p.numar_pozitie else 1 end), p.cont_debitor, p.Utilizator 
			from pozincon p
				left join lmfiltrare lu on lu.cod=p.loc_de_munca and lu.utilizator=@utilizator
			where p.cont_creditor in (select cont from conturi where sold_credit=(case when @tip_necorelatii='FU' then 1 else 2 end) and cont like rtrim(@filtruCont)+'%') 
				and p.data between @data_jos and @data_sus
				and (@lista_lm=0 or lu.cod is not null)
			
			select subunitate, tip_document, ltrim(numar_document) numar_document, data, sum(suma) as suma, cont, (case when tip_document='PI' then numar_pozitie else 1 end) as numar_pozitie, 
				(case when tip_document='PI' then /*contc*/numar_document else '' end) as contc 
			into #gincont 
			from #valincont
			group by subunitate, tip_document, numar_document, data, cont, (case when tip_document='PI' then numar_pozitie else 1 end), 
				(case when tip_document='PI' then /*contc*/numar_document else '' end)
			
			insert into necorelatii (tip_necorelatii,tip_document,tip_alte,numar,data,cont,valoare_1,valoare_2,valoare_3,valuta,msg_eroare,utilizator)
			select @tip_necorelatii, isnull(a.tip,b.tip_document), '', isnull(a.numar,b.numar_document), convert(char(10),isnull(a.data,b.data),101), 
				isnull(a.cont_de_tert,b.cont), convert(decimal(17,4),isnull(a.total,0)), convert(decimal(17,4),isnull(b.suma,0)), 0, '', '', @utilizator 
			from #valdoc a 
			full outer join #gincont b on a.subunitate=b.subunitate 
				and (case when a.fel=4 and a.tip in ('AP','AS', 'RM', 'RS') then left(a.tip,1) when a.fel in (1,2,4) then a.tip when 1=0 and a.fel=4 then a.numar else '1' end)
					=(case when a.fel=4 and b.tip_document in ('AP', 'AS', 'RM', 'RS') then left(b.tip_document,1) when a.fel in (1,2,4) then b.tip_document else '1' end) 
				and (case when a.fel=3 then a.numar_pozitie else 1 end)=(case when a.fel=3 then b.numar_pozitie else 1 end) 
				and (case when a.fel in (1,2,4) then a.numar else '1' end)=(case when a.fel in (1,2,4) then b.numar_document else '1' end) and a.data=b.data and a.cont_de_tert=b.cont 
				and (case when a.fel=3 then a.cont_coresp else '' end)=(case when b.tip_document='PI' then b.numar_document else '' end)
			where abs(convert(decimal(17,3),isnull(a.total,0)))<>abs(convert(decimal(17,3),isnull(b.suma,0))) 
				and abs(abs(convert(decimal(17,3),isnull(a.total,0)))-abs(convert(decimal(17,3),isnull(b.suma,0))))>1 and (a.fel<>3 or a.numar_pozitie>0 or b.numar_pozitie>0)

			drop table #doctertt, #valdoc, #valincont, #gincont
		end
		else 
		begin --necorelatii pe cont neatribuit
			insert into necorelatii	(tip_necorelatii,tip_document,tip_alte,numar,data,cont,valoare_1,valoare_2,valoare_3,valuta,msg_eroare,utilizator)
				select @tip_necorelatii, tip, '', numar, convert(char(10),data,101), max(cont_de_tert), 
					convert(decimal(17,4),(case when fel=2 or fel=1 or tip in ('FB','FF') or ((tip='SF' or tip='IF') and max(achitat)=0) then sum(total) else sum(achitat) end)), 
					0, 0, '', '', @utilizator--, fel 
				from #doctertt 
				where cont_de_tert in (select cont from conturi where sold_credit=0 and cont like rtrim(isnull(@filtruCont,''))+'%') and data between @data_jos and @data_sus 
				group by subunitate, tip, numar, data, cont_de_tert, fel
			
			drop table #doctertt
		end
	end
	
	declare @p xml
	if object_id('tempdb..#docstoc') is not null drop table #docstoc
			create table #docstoc(subunitate varchar(9))
			exec pStocuri_tabela
		
	if @tip_necorelatii='SC'--necorelatii stocuri<->contabilitate
	begin
		
		select @p=(select 	@data_jos dDataJos, @data_sus dDataSus, @filtruCod cCod, @filtruGest cGestiune, @filtruCod_intrare cCodi, @filtruGrupa cGrupa, 'D' TipStoc, @filtruCont cCont, 
				@dincorel Corelatii, @filtruLM LM, @filtruComanda Comanda, @filtruFurn Furnizor, @filtruLot Lot for xml raw)
		truncate table #docstoc
		exec pstoc @sesiune='', @parxml=@p
		
		declare @faraInregConturiEgaleTE bit
		exec luare_date_par 'GE','NUCTEGAL',@faraInregConturiEgaleTE OUTPUT,0,'' 
		-- apel pentru depozit
		select a.subunitate, a.gestiune, a.cont, a.cod, a.data, a.data_stoc, a.cod_intrare, a.pret,	a.tip_document  as tip_document,a.numar_document, 
			(case when @inUM2=0 then a.cantitate else a.cantitate_UM2 end) as cantitate, a.tip_miscare, a.in_out, a.predator, a.jurnal, a.tert, a.serie, 
			a.pret_cu_amanuntul-(case when @dincorel=1 and @faraInregConturiEgaleTE=1 and (a.tip_document in ('TE', 'TI') and a.cont=a.cont_corespondent) then a.pret else 0 end) as pret_cu_amanuntul,
			a.tip_gestiune, a.locatie, a.data_expirarii, a.TVA_neexigibil, a.pret_vanzare, a.accize_cump,a.comanda, a.furnizor, a.contract, a.loc_de_munca
		into #bal1
		from #docstoc a
			/*dbo.fStocuri(@data_jos, @data_sus, @filtruCod, @filtruGest, @filtruCod_intrare, @filtruGrupa, 'D' /*@tipStoc*/, @filtruCont, 
						  @dincorel, null, @filtruLM, @filtruComanda, null, @filtruFurn, @filtruLot, null) a	--*/
		where (@pretAm=0 or a.tip_gestiune='A')
			and (isnull(@filtruComanda,'')='' or a.comanda=@filtruComanda) 
			and (isnull(@filtruFurn,'')='' or a.furnizor=@filtruFurn) 
			and (isnull(@filtruLM,'')='' or a.loc_de_munca=@filtruLM) 
			and (isnull(@filtruLot,'')='' or a.lot=@filtruLot)
			--and (@faraInregConturiEgaleTE= 0 or not (a.tip_document in ('TE', 'TI') and a.cont=a.cont_corespondent /*and a.tip_gestiune not in ('A', 'V')*/))
			and (@inUM2=0 or abs(a.cantitate_UM2)>=0.001)
		
		select @p=(select 	@data_jos dDataJos, @data_sus dDataSus, @filtruCod cCod, @filtruGest cGestiune, @filtruCod_intrare cCodi, @filtruGrupa cGrupa, 'F' TipStoc, @filtruCont cCont, 
				@dincorel Corelatii, @filtruLM LM, @filtruComanda Comanda, @filtruFurn Furnizor, @filtruLot Lot for xml raw)
		truncate table #docstoc
		exec pstoc @sesiune='', @parxml=@p
		
		-- apel pentru folosinta
		select a.subunitate, a.gestiune, a.cont, a.cod, a.data, a.data_stoc, a.cod_intrare, a.pret, a.tip_document  as tip_document,a.numar_document, 
			(case when @inUM2=0 then a.cantitate else a.cantitate_UM2 end) as cantitate, a.tip_miscare, a.in_out, a.predator, a.jurnal, a.tert, a.serie, 
			a.pret_cu_amanuntul/*-(case when @dincorel=1 and a.tip_document in ('TE', 'TI') and a.cont=a.cont_corespondent then a.pret else 0 end) */ as pret_cu_amanuntul,
			a.tip_gestiune, a.locatie, a.data_expirarii, a.TVA_neexigibil, a.pret_vanzare, a.accize_cump,a.comanda, a.furnizor, a.contract, a.loc_de_munca
		into #bal2
		from #docstoc a 
			/*dbo.fStocuri(@data_jos, @data_sus, @filtruCod, @filtruGest, @filtruCod_intrare, @filtruGrupa, 'F', @filtruCont, 
						  @dincorel, null, @filtruLM, @filtruComanda, null, @filtruFurn, @filtruLot, null) a	--*/
		where (@pretAm=0 or a.tip_gestiune='A')
			and (isnull(@filtruComanda,'')='' or a.comanda=@filtruComanda) 
			and (isnull(@filtruFurn,'')='' or a.furnizor=@filtruFurn) 
			and (isnull(@filtruLM,'')='' or a.loc_de_munca=@filtruLM) 
			and (isnull(@filtruLot,'')='' or a.lot=@filtruLot)
			--and not (@dincorel=1 and a.tip_document in ('TE', 'TI') and a.cont=a.cont_corespondent and a.tip_gestiune not in ('A', 'V'))
			and (@inUM2=0 or abs(a.cantitate_UM2)>=0.001)	

		if @corelatiiPeContAtribuit=1 --necorelatii pe cont atribuit
		begin
			select subunitate, tip_document, numar_document, data, cont, 
				round(convert(decimal(17,5),cantitate)*convert(decimal(17,5), (case when tip_gestiune in ('A','V') and LEFT(Cont,3) in ('371','357') then pret_cu_amanuntul else pret end)), 2) as valoare 
			into #balstdoc 
			from #bal1 
			where cont in (select cont from conturi where sold_credit=3) 
				and data between @data_jos and @data_sus 
				and in_out>1 			
			union all 
			select subunitate, tip_document, numar_document, data, cont, 
				round(convert(decimal(17,5),cantitate)*convert(decimal(17,5), (case when tip_gestiune in ('A','V') and LEFT(Cont,3) in ('371','357') then pret_cu_amanuntul else pret end)), 2) as valoare 
			from #bal2 
			where cont in (select cont from conturi where sold_credit=3) 
				and data between @data_jos and @data_sus 
				and in_out>1				
			
			select subunitate, (case when tip_document='TI' then 'TE' else tip_document end) as tip_document, numar_document, data, cont, 
				sum((case when tip_document='TI' then -1 else 1 end)*valoare) as valoare 
			into #gbaldoc 
			from #balstdoc 
			group by subunitate,(case when tip_document='TI' then 'TE' else tip_document end), numar_document, data, cont			
			
			select subunitate, 
				(case when tip_document in ('TE', 'DF', 'PF')
					and (not exists (select 1 from pozdoc p 
										 left outer join gestiuni c on c.subunitate = p.subunitate and c.cod_gestiune = p.gestiune 
										 left outer join gestiuni b on B.subunitate = p.subunitate and B.cod_gestiune = p.Gestiune_primitoare
									 where p.subunitate = pozincon.subunitate and p.tip = pozincon.tip_document and p.numar = pozincon.numar_document 
										and p.data = pozincon.data and c.tip_gestiune in ('A','V') 
										and (tip_document='TE' and b.tip_gestiune not in ('A','V') or p.cont_de_stoc = pozincon.cont_debitor)) 
										or left(cont_creditor,3) not in ('378','442')) then (case tip_document when 'DF' then 'DI'/*'DI' */when 'PF' then 'PI' else 'TI' end) 
																								else tip_document end) as tip_document, 
										
				numar_document, data, 
				(case when tip_document in (/*'DF',*/'AP','AC','CM','AE') 
					or tip_document in ('TE', 'DF', 'PF') and exists (select 1 from pozdoc p 
									left outer join gestiuni c on c.subunitate = p.subunitate and c.cod_gestiune = p.gestiune 
									left outer join gestiuni b on b.subunitate = p.subunitate and b.cod_gestiune = p.gestiune_primitoare 
								where p.subunitate = pozincon.subunitate and p.tip = pozincon.tip_document and p.numar = pozincon.numar_document and p.data = pozincon.data 
									and c.tip_gestiune in ('A','V') and (tip_document='TE' and b.tip_gestiune not in ('A','V') or p.cont_de_stoc = pozincon.cont_debitor)) 
									and left(cont_creditor,3) in ('378','442') then -suma else suma end) as suma, 
			
				cont_debitor as cont 
			into #valincon 
			from pozincon 
			where cont_debitor  in (select cont from conturi where sold_credit=3 and (cont like rtrim(@filtruCont)+'%' or isnull(@filtruCont,'')='')) 
				and data between @data_jos and @data_sus  
				and not (@faraInregConturiEgaleTE=1 and tip_document='TE' and cont_debitor=cont_creditor)
			union all 
			select subunitate, tip_document, numar_document, data, (case when tip_document='AI' then -suma else suma end), cont_creditor as cont 
			from pozincon 
			where cont_creditor in (select cont from conturi where sold_credit=3 and (cont like rtrim(@filtruCont)+'%' or isnull(@filtruCont,'')=''))
				and data between @data_jos and @data_sus 
				and not (@faraInregConturiEgaleTE=1 and tip_document='TE' and cont_debitor=cont_creditor)
			
			select subunitate, (case when tip_document='TI' then 'TE' else tip_document end) as tip_document, numar_document, data, 
				sum(case when tip_document='TI' then -suma else suma end) as suma, cont 
			into #gincon 
			from #valincon
			group by subunitate, (case when tip_document='TI' then 'TE' else tip_document end), numar_document, data, cont
					
			insert into necorelatii	(tip_necorelatii,tip_document,tip_alte,numar,data,cont,valoare_1,valoare_2,valoare_3,valuta,msg_eroare,utilizator)
			select 'SC',isnull(a.tip_document,b.tip_document) as tip_document,'', rtrim(isnull(a.numar_document,b.numar_document)) as numar, 
				convert(char(10),isnull(a.data,b.data),101)as data, rtrim(isnull(a.cont,b.cont)) as cont, 
				convert(decimal(17,4),(isnull(a.valoare,0))) as valoare_doc, convert(decimal(17,4),(isnull(b.suma,0))) as valoare_inreg,0,'','',
				@utilizator 
			from #gbaldoc a 
			full outer join #gincon b on a.subunitate=b.subunitate and a.tip_document=b.tip_document  and  a.numar_document=b.numar_document and a.data=b.data and a.cont=b.cont 
			where convert(decimal(16,2),isnull(a.valoare,0))<>convert(decimal(16,2),isnull(b.suma,0)) 
				and abs(convert(decimal(16,2),isnull(a.valoare,0))-convert(decimal(16,2),isnull(b.suma,0)))>0.02
			
			drop table #balstdoc
			drop table #gbaldoc
			drop table #gincon	
		end
		
		else --necorelatii pe cont neatribuit
		begin
			insert into necorelatii	(tip_necorelatii,tip_document,tip_alte,numar,data,cont,valoare_1,valoare_2,valoare_3,valuta,msg_eroare,utilizator)
			select 'SC', tip_document,'', rtrim(numar_document), convert(char(10),data,101), rtrim(cont), sum(cantitate*pret),0,0,'','',@utilizator 
			from #bal1 
			where cont in (select cont from conturi where sold_credit=0 and cont like rtrim(ISNULL(@filtruCont,''))+'%') and data between @data_jos and @data_sus 
			group by subunitate,tip_document, numar_document, data, cont
		end
		drop table #bal1
		drop table #bal2

	end	
		
	if @tip_necorelatii='TC'--necorelatii TVA colectat<->contabilitate
	begin
		declare @CCTVA varchar(40)
		exec luare_date_par 'GE', 'CCTVA', 0, 0, @CCTVA output 

		if object_id('tempdb..#jtvavanz') is not null drop table #jtvavanz
		if object_id('tempdb..#FdocTVAVAnz') is not null drop table #FdocTVAVAnz
		if object_id('tempdb..#FinconTVAVanz') is not null drop table #FinconTVAVanz
		-----------Tva din rapJurnalTVAVanzari-----------
		set @parXMLJ=(select 1 tipcump, '' tipfact, 0 tvanx, 0 tvaeronat, 1 dincorelatii for xml raw)
		create table #jtvavanz (numar char(20))
		exec CreazaDiezTVA '#jtvavanz'
		exec rapJurnalTVAVanzari  @sesiune=null, @DataJ=@data_jos, @DataS=@data_sus, @RecalcBaza=1, @nTVAex=0	
			,@Provenienta='', @OrdDataDoc=0, @OrdDenTert=0, @DifIgnor=0.5, @TipTvaTert=0
			,@ContF=@filtruCont, @LM=@filtruLM, @LMExcep=0, @ContCor=@filtruContCor, @ContFExcep=0, @Tert=null, @Factura=null
			,@cotatvaptfiltr=null, @Gest=@filtruGest, @Jurnal=null, @FFFBTVA0='0', @SiFactAnul=0, @TVAAlteCont=0, @DVITertExt=0
			,@DetalDoc=1, @CtVenScDed='', @CtPIScDed='', @CtCorespNeimpoz='', @parXML=@parXMLJ

		select tip_doc as tip, ltrim((case when tip_doc in ('MI','ME','MM') then tip_doc else '' end)+nr_doc) as numar, data_doc as data, sum(suma_tva_doc) as suma
		into #FdocTVAVAnz
		from #jtvavanz d
		where tip_doc<>'BP'
		group by tip_doc, ltrim((case when tip_doc in ('MI','ME','MM') then tip_doc else '' end)+nr_doc), data_doc

		--Tva din incon
		select p.subunitate, (case when p.tip_document='IC' and left(p.numar_document,1)='M' then 'MF' else p.tip_document end) as tip, 
		(case when p.tip_document='IC' and left(p.numar_document,1)='M' then substring(p.numar_document,3,11) else p.numar_document end) as numar, p.data, sum(p.suma) as suma 
		into #FinconTVAVanz 
		from pozincon p
			left join lmfiltrare lu on lu.cod=p.loc_de_munca and lu.utilizator=@utilizator
		where p.subunitate=@sub
			and p.Cont_creditor like rtrim(isnull(@CCTVA,''))+'%' 
			and p.Cont_debitor like rtrim(isnull(@filtruCont,''))+'%'
			and p.data between @data_jos and @data_sus  
			and (@lista_lm=0 or lu.cod is not null)
		group by p.subunitate, (case when p.tip_document='IC' and left(p.numar_document,1)='M' then 'MF' else p.tip_document end), 
							 (case when p.tip_document='IC' and left(p.numar_document,1)='M' then substring(p.numar_document,3,11) else p.numar_document end),
							  p.data

		insert into necorelatii	(tip_necorelatii,tip_document,tip_alte,numar,data,cont,valoare_1,valoare_2,valoare_3,valuta,msg_eroare,utilizator)
			(select 'TC',isnull(a.tip,b.tip),'', isnull(a.numar,b.numar), isnull(a.data,b.data), '',isnull(a.suma,0), isnull(b.suma,0),0,'','',@utilizator 
			from #FdocTVAVAnz a  
				full outer join #FinconTVAVanz b on b.subunitate=@sub and a.data=b.data and a.tip=b.tip and a.numar=b.numar 
			where abs(abs(convert(decimal(17,3),isnull(a.suma,0)))-abs(convert(decimal(17,3),isnull(b.suma,0))))>1)
		
		if object_id('tempdb..#jtvavanz') is not null drop table #jtvavanz
		if object_id('tempdb..#FdocTVAVAnz') is not null drop table #FdocTVAVAnz
		if object_id('tempdb..#FinconTVAVanz') is not null drop table #FinconTVAVanz
	end
		
	if @tip_necorelatii='TD'--necorelatii TVA deductibil<->contabilitate
	begin
		declare @CDTVA varchar(40)
		exec luare_date_par 'GE', 'CDTVA', 0, 0, @CDTVA output 

		if object_id('tempdb..#jtvacump') is not null drop table #jtvacump
		if object_id('tempdb..#FdocTVACump') is not null drop table #FdocTVACump
		if object_id('tempdb..#FinconTVACump') is not null drop table #FinconTVACump
		-----------Tva din rapJurnalTVACumparari--------------
		set @parXMLJ=(select 1 tipcump, '' tipfact, 0 tvanx, 0 IAFTVA0, 0 tvaeronat, '' CtNeimpoz, 1 dincorelatii for xml raw)

		create table #jtvacump (numar char(20))
		exec CreazaDiezTVA '#jtvacump'
		exec dbo.rapJurnalTVACumparari
			@sesiune=null, @DataJ=@data_jos, @DataS=@data_sus
			,@nTVAex=0, @FFFBTVA0='0', @SFTVA0='0', @OrdDataDoc=0, @Provenienta='', @DifIgnor=0.5
			,@UnifFact=0, @nTVAneded=2, @cotatvaptfiltr=null
			,@ContF=@filtruCont, @LM =@filtruLM, @ContCor=@filtruContCor, @Tert=null, @Factura=null
			,@marcaj=0, @DVITertExt=0, @RPTVACompPeRM=0, @Gest=@filtruGest, @LMExcep=0, @Jurnal=null, @RecalcBaza=1
			,@TVAAlteCont=0, @OrdDenTert=0, @DetalDoc=1, @TipTvaTert=0, @parXML=@parXMLJ

		select (case when tip_doc='RC' then 'RM' else tip_doc end) as tip, ltrim((case when tip_doc in ('MI','ME','MM') then tip_doc else '' end)+nr_doc) as numar, data_doc as data, sum(suma_tva_doc) as suma
		into #FdocTVACump
		from #jtvacump d
		group by tip_doc, ltrim((case when tip_doc in ('MI','ME','MM') then tip_doc else '' end)+nr_doc), data_doc

		--Tva din incon
		select p.subunitate, (case when p.tip_document='IC' and left(p.numar_document,1)='M' then 'MF' else p.tip_document end) as tip, 
		(case when p.tip_document='IC' and left(p.numar_document,1)='M' then substring(p.numar_document,3,11) else p.numar_document end) as numar, p.data, sum(p.suma) as suma 
		into #FinconTVACump 
		from pozincon p
			left join lmfiltrare lu on lu.cod=p.loc_de_munca and lu.utilizator=@utilizator
		where p.subunitate=@sub
			and p.Cont_debitor like rtrim(isnull(@CDTVA,''))+'%' 
			and p.Cont_creditor like rtrim(ISNULL(@filtruCont,''))+'%' 
			and p.data between @data_jos and @data_sus  
			and (@lista_lm=0 or lu.cod is not null)
		group by p.subunitate, (case when p.tip_document='IC' and left(p.numar_document,1)='M' then 'MF' else p.tip_document end), 
							 (case when p.tip_document='IC' and left(p.numar_document,1)='M' then substring(p.numar_document,3,11) else p.numar_document end),
							  p.data

		insert into necorelatii	(tip_necorelatii,tip_document,tip_alte,numar,data,cont,valoare_1,valoare_2,valoare_3,valuta,msg_eroare,utilizator)
			(select 'TD',isnull(a.tip,b.tip),'', isnull(a.numar,b.numar), isnull(a.data,b.data), '',isnull(a.suma,0), isnull(b.suma,0),0,'','',@utilizator 
			from #FdocTVACump a  
				full outer join #FinconTVACump b on b.subunitate=@sub and a.data=b.data and a.tip=b.tip and a.numar=b.numar 
			where abs(abs(convert(decimal(17,3),isnull(a.suma,0)))-abs(convert(decimal(17,3),isnull(b.suma,0))))>1)
			
		if object_id('tempdb..#jtvacump') is not null drop table #jtvacump
		if object_id('tempdb..#FdocTVACump') is not null drop table #FdocTVACump
		if object_id('tempdb..#FinconTVACump') is not null drop table #FinconTVACump
	end
		
	if @tip_necorelatii='RI'--necorelatii rulaje<->inregistrari
	begin
		select a.cont_debitor as cont, sum(round(convert(decimal(15, 3),a.suma), 2)) as valoarei, sum(rulaj_debit) as valoarer, 'D' as tip 
		into #RulajeInregistrari
		from 
		(select subunitate,Cont_debitor, (case when @rulajePeLocMunca=1 then p.Loc_de_munca else '' end) Loc_de_munca, sum(p.Suma) suma 
			from pozincon p 
			where p.Data between @data_jos and @data_sus and p.cont_debitor like rtrim(isnull(@filtruCont,''))+'%' and not (p.cont_creditor like '8%' and p.cont_debitor='')
				and p.cont_debitor like rtrim(isnull(@filtruCont,''))+'%'
			group by subunitate,Cont_debitor,(case when @rulajePeLocMunca=1 then p.Loc_de_munca else '' end)) a, 
			(select subunitate, cont, (case when @rulajePeLocMunca=1 then b.Loc_de_munca else '' end) Loc_de_munca, sum(b.rulaj_debit) rulaj_debit
			from rulaje b 
			where b.data=@data_sus and b.valuta=''
			group by subunitate, cont, (case when @rulajePeLocMunca=1 then b.Loc_de_munca else '' end)) b
		where  a.subunitate=b.subunitate and a.cont_debitor=b.cont and 
			(@rulajePeLocMunca=0 or 
			a.loc_de_munca=b.loc_de_munca) 
		group by a.cont_debitor 
		having abs(sum(round(convert(decimal(15, 3),a.suma), 2))-sum(rulaj_debit))>=0.01
		
		union all
		select a.cont_creditor, sum(round(convert(decimal(15, 3),a.suma), 2)), sum(rulaj_credit), 'C' 
		from (select subunitate,Cont_creditor Cont_creditor, (case when @rulajePeLocMunca=1 then p.Loc_de_munca else '' end) as Loc_de_munca, sum(p.Suma) suma 
			from pozincon p 
			where p.Data between @data_jos and @data_sus and p.cont_debitor like rtrim(isnull(@filtruCont,''))+'%' and not (p.Cont_debitor like '8%' and p.Cont_creditor='')
				and p.cont_creditor like rtrim(isnull(@filtruCont,''))+'%' 
			group by subunitate,Cont_creditor,(case when @rulajePeLocMunca=1 then p.Loc_de_munca else '' end)) a, 
			 (select subunitate, cont, (case when @rulajePeLocMunca=1 then b.Loc_de_munca else '' end) as Loc_de_munca, sum(b.rulaj_credit) rulaj_credit
				from rulaje b where b.data=@data_sus and b.valuta=''
			group by subunitate, cont, (case when @rulajePeLocMunca=1 then b.Loc_de_munca else '' end)) b
		where a.subunitate=b.subunitate and a.cont_creditor=b.cont and 
			(@rulajePeLocMunca=0 or a.loc_de_munca=b.loc_de_munca)
		group by a.cont_creditor
		having abs(sum(round(convert(decimal(15, 3),a.suma), 2))-sum(rulaj_credit))>=0.01

		union all 
		select a.cont_debitor, sum(round(convert(decimal(15, 3),a.suma), 2)), 0, 'D' 
		from pozincon a
		where a.data between @data_jos and @data_sus and a.cont_debitor like rtrim(isnull(@filtruCont,''))+'%' and not exists (select 1 from rulaje b where b.data=@data_sus and a.cont_debitor=b.cont and 
			(@rulajePeLocMunca=0 or a.loc_de_munca=b.loc_de_munca) and b.valuta='') and not (a.cont_creditor like '8%' and a.cont_debitor='') 
		group by a.cont_debitor
		union all 
		
		select a.cont_creditor, sum(round(convert(decimal(15, 3),a.suma), 2)), 0, 'C' 
		from pozincon a
		where a.data between @data_jos and @data_sus and a.cont_creditor like rtrim(isnull(@filtruCont,''))+'%' and not exists (select 1 from rulaje b where b.data=@data_sus and a.cont_creditor=b.cont and 
			(@rulajePeLocMunca=0 or a.loc_de_munca=b.loc_de_munca) and b.valuta='') and not (a.cont_debitor like '8%' and a.cont_creditor='')
		group by a.cont_creditor 
		
		insert into necorelatii	(tip_necorelatii,tip_document,tip_alte,numar,data,cont,valoare_1,valoare_2,valoare_3,valuta,msg_eroare,utilizator)
		select 'RI','',r.tip,'','',rtrim(r.cont),0,r.valoarei,r.valoarer,'','',@utilizator
		from #RulajeInregistrari r
		
		drop table #RulajeInregistrari
	end
			
	if @tip_necorelatii='SA' --necorelatii conturi analitic<->sintetic
	begin
		
		IF OBJECT_ID('tempdb.dbo.#tmpct') IS NOT NULL
			drop table #tmpct
		
		create table #tmpct (cont varchar(20), loc_de_munca varchar(20), valuta varchar(20), data datetime, rd float DEFAULT 0, rc float DEFAULT 0, rda float DEFAULT 0, rca float DEFAULT 0)

		/* Luam RULAJELE conturilor sintetice */
		INSERT INTO #tmpct (cont, data, loc_de_munca, valuta, rd, rc)
		select
			c.cont, r.data, r.loc_de_munca, r.valuta, r.rulaj_debit, r.rulaj_credit 
		from Rulaje r
		JOIN Conturi c on r.cont=c.Cont and c.Are_analitice=1
		where r.data between @data_jos and @data_sus and (r.valuta=@valuta or ISNULL(@valuta,'')='') and c.cont like rtrim(ISNULL(@filtruCont,''))+'%'
		
		/* Luam rulajele din analitice	*/
		update t
			set t.rca=ISNULL(ca.rca,0), t.rda=ISNULL(ca.rda,0)
		FROM #tmpct t
		JOIN
		(
			select 
				a.cont_parinte as cont, b.data, sum(b.rulaj_debit) as rda, sum(b.rulaj_credit) as rca, b.valuta as valuta, b.loc_de_munca
			from conturi a
			JOIN rulaje b on a.cont=b.cont and a.cont_parinte<>'' and b.data between @data_jos and @data_sus			
			group by a.cont_parinte, b.data, b.valuta, b.loc_de_munca 
		) ca on ca.cont=t.cont and ca.data=t.data and ca.loc_de_munca=t.loc_de_munca and ca.valuta=t.valuta
		
		insert into necorelatii	(tip_necorelatii, tip_document, tip_alte, numar, data, cont, valoare_1, valoare_2, valoare_3, valoare_4, valuta, lm, msg_eroare, utilizator)					
		select
			'SA', '', '', '', data, cont, rda, rca, rd, rc, valuta, loc_de_munca, '', @utilizator
		from #tmpct where ABS(rc-rca)>0.5 or ABS(rd-rda)>0.5

	end	
	
	if @tip_necorelatii in ('FB','FF') --necorelatii doc. - facturi
	begin
		truncate table #docfacturi
		set @parXMLFact=(select right(@tip_necorelatii,1) as furnbenef, '01/01/1921' as datajos, '12/31/2999' as datasus, @filtruCont as contfactura for xml raw)
		exec pFacturi @sesiune=null, @parXML=@parXMLFact

		--#doctertt se creeaza mai sus
		select p.subunitate, p.tert, p.factura, p.valuta, p.tip, p.numar, p.data,(case when p.data between @data_jos and @data_sus then '2' else '1' end) as in_perioada,
			p.total_valuta as total, 0 as tva_11, 0 as tva_22, p.achitat_valuta as achitat, p.loc_de_munca, p.cont_de_tert, p.fel, p.cont_coresp, p.explicatii, p.gestiune, 
			p.data_facturii, p.data_scadentei, p.curs, p.nr_dvi as DVI, p.barcod, p.numar_pozitie, 0 as totLPV, 0 as achLPV, contTVA, contract, data_platii 
		into #doctertvf 
		from #docfacturi p
		/*from dbo.fFacturi (right(@tip_necorelatii,1), '01/01/1921', '12/31/2999'/*@data_jos, @data_sus*/, null, '%', isnull(@filtruCont,''), 0, 0, 0, '', null) p */
			left outer join terti t on p.subunitate=t.subunitate and p.tert=t.tert 
		where p.valuta<>'' and isnull(t.tert_extern, 0)=1
		
		select subunitate, max(loc_de_munca) as loc_de_munca, max(comanda) as comanda, (case when @tip_necorelatii='FB' then 0x46 else 0x54 end) as tipF, factura, tert,
			min(data_facturii) as data, min(data_scadentei) as data_scadentei, 
			sum(round(convert(decimal(17,5),total),2)-round(convert(decimal(17,5),tva_11),2)-round(convert(decimal(17,5),tva_22),2)) as valoare, 
			sum(round(convert(decimal(17,5),tva_11),2)) as tva_11, sum(round(convert(decimal(17,5),tva_22),2)) as tva_22, '' as valuta, 0 as curs, 0 as valoare_valuta, 
			sum(round(convert(decimal(17,5),achitat),2)) as achitat, sum(round(convert(decimal(17,5),total),2)-round(convert(decimal(17,5),achitat),2)) as sold, 
			max(cont_de_tert) as cont_de_tert, 0 as achitat_valuta, 0 as sold_valuta, max(data) as data_ultimei_achitari 
		into #facttert from #doctertt
		group by subunitate, tert, factura
		union all 
		select subunitate, max(loc_de_munca), '', (case when @tip_necorelatii='FB' then 0x46 else 0x54 end), factura, tert, min(data_facturii), min(data_scadentei), 0, 0, 0, 
			max(valuta), max(curs), sum(round(convert(decimal(17,5),total),2)), 0, 0, max(cont_de_tert), sum(round(convert(decimal(17,5),achitat),2)), 
			sum(round(convert(decimal(17,5),total),2)-round(convert(decimal(17,5),achitat),2)), max(data) 
		from #doctertvf 
		group by subunitate, tert, factura
		
		update #facttert set data=isnull((select min(data_facturii) from #doctertt where subunitate=#facttert.subunitate and tert=#facttert.tert 
				and factura=#facttert.factura and tip in ('SI','AP','AS','RM','RS','FF','SF','FB','IF')),data), 
			data_scadentei=isnull((select min(data_scadentei) from #doctertt where subunitate=#facttert.subunitate and tert=#facttert.tert 
				and factura=#facttert.factura and tip in ('SI','AP','AS','RM','RS','FF','SF','FB','IF')),data_scadentei), 
			valuta=isnull((select max(valuta) from #doctertvf where subunitate=#facttert.subunitate and tert=#facttert.tert 
				and factura=#facttert.factura and tip in ('SI','AP','AS','RM','RS','FF','SF','FB','IF')),valuta), 
			curs=isnull((select max(curs) from #doctertvf where subunitate=#facttert.subunitate and tert=#facttert.tert 
				and factura=#facttert.factura and tip in ('SI','AP','AS','RM','RS','FF','SF','FB','IF') 
				and #doctertvf.data=(select max(data) from #doctertvf where subunitate=#facttert.subunitate and tert=#facttert.tert 
				and factura=#facttert.factura and tip in ('SI','AP','AS','RM','RS','FF','SF','FB','IF'))),curs) 
		
		drop table #doctertt, #doctertvf
		
		select subunitate, max(loc_de_munca) as loc_de_munca, tipF as tip, factura, tert, 
			min(data) as data, min(data_scadentei) as data_scadentei, 
			sum(valoare) as valoare, sum(tva_11) as tva_11, sum(tva_22) as tva_22, 
			max(valuta) as valuta, max(curs) as curs, 
			sum(valoare_valuta) as valoare_valuta, sum(achitat) as achitat, sum(sold) as sold, 
			max(cont_de_tert) as cont_de_tert, sum(achitat_valuta) as achitat_valuta, sum(sold_valuta) as sold_valuta, 
			max(comanda) as comanda, max(data_ultimei_achitari) as data_ultimei_achitari 
		into #docfacttert 
		from #facttert 
		group by subunitate, tert, tipF, factura 
		
		select subunitate, max(loc_de_munca) as loc_de_munca, tip, factura, tert, 
			min(data) as data, min(data_scadentei) as data_scadentei, 
			sum(valoare) as valoare, sum(tva_11) as tva_11, sum(tva_22) as tva_22, 
			max(valuta) as valuta, max(curs) as curs, 
			sum(valoare_valuta) as valoare_valuta, sum(achitat) as achitat, sum(sold) as sold, 
			max(cont_de_tert) as cont_de_tert, sum(achitat_valuta) as achitat_valuta, sum(sold_valuta) as sold_valuta, 
			max(comanda) as comanda, max(data_ultimei_achitari) as data_ultimei_achitari 
		into #factfacttert 
		from facturi 
		where subunitate=@sub and tip=(case when @tip_necorelatii='FB' then 0x46 else 0x54 end) and (ISNULL(@filtruFurn,'')='' or tert=@filtruFurn) 
			and (ISNULL(@filtruFact,'')='' or factura=@filtruFact)
		group by subunitate, tert, tip, factura 

		insert into necorelatii	(tip_necorelatii,tip_document,tip_alte,numar,data,cont,valoare_1,valoare_2,valoare_3,valoare_4,valuta,lm,msg_eroare,utilizator)
			select @tip_necorelatii, right(@tip_necorelatii,1), '', isnull(d.factura, f.factura), isnull(d.data, f.data), isnull(d.tert, f.tert), 
				isnull(d.sold, 0) /*as sold_doc*/, isnull(f.sold, 0) /*as sold_fact*/, isnull(d.sold_valuta, 0) /*as sold_valuta_doc*/, 
				isnull(f.sold_valuta, 0) /*as sold_valuta_fact*/, '', '', ''/*isnull(t.denumire, '')*/, @utilizator 
			from #docfacttert d 
				full outer join #factfacttert f on d.subunitate=f.subunitate and d.tip=f.tip and d.tert=f.tert and d.factura=f.factura 
				--left outer join terti t on t.subunitate=isnull(d.subunitate, t.subunitate) and t.tert=isnull(d.tert, f.tert) 
			where abs(isnull(d.sold, 0)-isnull(f.sold, 0)) >= 0.01 
				or abs(isnull(d.sold_valuta, 0)-isnull(f.sold_valuta, 0)) >= 0.01 
			order by isnull(d.data, f.data), isnull(d.factura, f.factura), isnull(d.tert, f.tert) 

		drop table #facttert, #docfacttert, #factfacttert
	end

	if @tip_necorelatii='SS' --necorelatii doc. - stocuri
	begin
		declare @anulinc int, @lunainc int, @iststocuri int
		
		exec luare_date_par 'GE', 'ANULINC', 0, @anulinc output, ''
		exec luare_date_par 'GE', 'LUNAINC', 0, @lunainc output, ''
		set @iststocuri=case when @data_jos<=dbo.eom(convert(datetime,str(@lunainc,2)+'/01/'+str(@anulinc,4))) then 1 else 0 end
		
		select @p=(select 	@data_jos dDataJos, '01/01/2999' dDataSus, (case when @filtruCod='' then null else @filtruCod end) cCod, 'D' TipStoc, isnull(@filtruCont,'') cCont, 2 Corelatii for xml raw)
		truncate table #docstoc
		exec pstoc @sesiune='', @parxml=@p
		
		select a.subunitate, a.gestiune, a.cont, a.cod, a.data, a.data_stoc, a.cod_intrare, a.pret, a.tip_document as tip_document, 
			a.numar_document, (case when 0=0 then a.cantitate else a.cantitate_UM2 end) as cantitate, a.tip_miscare, a.in_out, a.predator, a.jurnal, a.tert, a.serie, 
			a.pret_cu_amanuntul-(case when 2=1 and a.tip_document in ('TE', 'TI') and a.cont=a.cont_corespondent then a.pret else 0 end) as pret_cu_amanuntul,
			a.tip_gestiune, a.locatie, a.data_expirarii, a.TVA_neexigibil, a.pret_vanzare, a.accize_cump, a.comanda, a.furnizor, a.contract, a.loc_de_munca
		into #balsts
		from #docstoc a
		--dbo.fStocuri(@data_jos, '01/01/2999'/*@data_sus*/, (case when @filtruCod='' then null else @filtruCod end), null, null, '', 'D', isnull(@filtruCont,''), 2, '', '', '', '', '', '', null) a
				
		if @filtruCod is null set @filtruCod=''
		
		select subunitate, gestiune as cod_gestiune,cod, cod_intrare, sum(cantitate*(case when tip_miscare='I' then 1 else -1 end)) as stoc
		into #stocBal
		from #balsts 
		where cod between (case when @filtruCod<>'' then @filtruCod else '' end) and (case when @filtruCod<>'' then @filtruCod else 'zzzzzzzzzzzzzzzzzzzz' end) 
			and gestiune not in (select cod_gestiune from gestiuni where tip_gestiune='V')
		group by subunitate, gestiune, cod, cod_intrare

		select subunitate, cod_gestiune, cod, cod_intrare, sum(stoc) as stoc 
		into #stocStoc
		from stocuri
		where cod between (case when @filtruCod<>'' then @filtruCod else '' end) and (case when @filtruCod<>'' then @filtruCod else 'zzzzzzzzzzzzzzzzzzzz' end) 
			and Tip_gestiune not in ('F','T') and cod_gestiune not in (select cod_gestiune from gestiuni where tip_gestiune='V')
		group by subunitate, cod_gestiune, cod, cod_intrare
		
		insert into necorelatii	(tip_necorelatii,tip_document,tip_alte,numar,data,cont,valoare_1,valoare_2,valoare_3,valoare_4,valuta,lm,msg_eroare,utilizator)
		select @tip_necorelatii,'','', isnull(a.cod,b.cod), GETDATE(), isnull(a.cod_intrare,b.cod_intrare), isnull(a.stoc,0), isnull(b.stoc,0), 0, 0, '',  
			isnull(a.cod_gestiune,b.cod_gestiune), '', @utilizator
		from #stocBal a 
			full outer join #stocStoc b on a.subunitate=b.subunitate and a.cod_gestiune=b.cod_gestiune and a.cod=b.cod and a.cod_intrare=b.cod_intrare 
		where abs(convert(decimal(16,2),isnull(a.stoc,0))-convert(decimal(16,2),isnull(b.stoc,0)))>1
		order by isnull(a.cod_gestiune,b.cod_gestiune), isnull(a.cod,b.cod), isnull(a.cod_intrare,b.cod_intrare)
		
		drop table #stocBal, #stocStoc, #balsts
	end
end try

begin catch
	set @mesajeroare='(populareNecorelatii) '+ERROR_MESSAGE()
end catch

if LEN(@mesajeroare)>0
	raiserror(@mesajeroare, 11, 1)
