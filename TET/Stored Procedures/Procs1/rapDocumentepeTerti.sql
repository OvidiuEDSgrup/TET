--***
create procedure rapDocumentepeTerti @sesiune varchar(50)=null, @cFurnBenef varchar(1), @cData datetime, @cTert varchar(50)=null,
			@cFactura varchar(50)=null, @cContTert varchar(50)=null, @locm varchar(50)=null, @soldmin decimal(20,2)=1, @soldabs int=0,
			@dDataFactJos datetime=null, @dDataFactSus datetime=null, @dDataScadJos datetime=null, @dDataScadSus datetime=null,
			@aviz_nefac int=0, @grupa varchar(50)=null, @grupa_strict int=0, @exc_grupa varchar(50)=null,
			@fsolddata datetime=null, @comanda varchar(50)=null, @indicator varchar(50)=null, @punctLivrare varchar(50)=null,
			@tipdoc varchar(1)='F'
as
begin
	/*	--pt teste:
	declare @cFurnBenef nvarchar(1),@cData datetime,@cTert nvarchar(4000),@cFactura nvarchar(4000),@cContTert nvarchar(4000),@soldmin nvarchar(1),@soldabs int,@dDataFactJos nvarchar(4000),@dDataFactSus nvarchar(4000),@dDataScadJos nvarchar(4000),@dDataScadSus nvarchar(4000),@aviz_nefac nvarchar(1),@grupa nvarchar(4000),@grupa_strict nvarchar(1),@exc_grupa nvarchar(4000),
			@fsolddata datetime, @comanda varchar(20), @indicator varchar(20), @locm varchar(20)
			
	select @cFurnBenef=N'F',@cData='2014-07-31 00:00:00',@cTert=NULL,@cFactura=NULL,@cContTert=NULL,@soldmin=N'0',@soldabs=0,@dDataFactJos=NULL,
			@dDataFactSus=NULL,@dDataScadJos=NULL,@dDataScadSus=NULL,@aviz_nefac=N'0',@grupa=NULL,@grupa_strict=N'0',@exc_grupa=NULL
	exec rapDocumentepeTerti @cFurnBenef=@cFurnBenef, @cData=@cData
			--,@fsolddata='2012-3-14'--, @locm='140'
	--*/
	
	set transaction isolation level read uncommitted
	if object_Id('tempdb.dbo.#fFacturi') is not null drop table #fFacturi
	declare @eroare varchar(1000)
	set @eroare=''
	begin try
		declare @parXML xml, @parXMLFact xml, @dataImplementarii datetime,
			@cDataJos datetime,
			@dataSolduri datetime		/**	data pana la care orice sume vor aparea ca solduri = data implementarii sau data ultimei initializari;
											daca nu e completat @q_cdatajos va fi @q_datasolduri*/
		select @parXML=(select @sesiune sesiune for xml raw)
		select @tipdoc=(case isnull(@tipdoc,'') when '' then 'X' else @tipdoc end),
				@dataImplementarii=--'1921-1-1'
			dateadd(d,-1,
				dateadd(m,1,
				isnull((select convert(varchar(4),val_numerica) from par where tip_parametru='ge' and parametru='ANULIMPL'),'1921')+'-'+
				isnull((select convert(varchar(2),val_numerica) from par where tip_parametru='ge' and parametru='lunaimpl'),'1')+'-1'
				)),
				@dataSolduri=(select max(case when parametru='ANULINC' then convert(varchar(20),val_numerica) else '' end)+'-'
								+max(case when parametru='LUNAINC' then convert(varchar(20),val_numerica) else '' end)+'-1'
						from par p where tip_parametru='GE' and parametru in ('ANULINC','LUNAINC'))

		if (@dataSolduri<@dataImplementarii)
			set @dataSolduri=@dataImplementarii
			
		declare @avemDataJos int	select @avemDataJos=1
		if (@cDataJos is null)
		begin
			set @cDataJos='1921-1-1'
			set @avemDataJos=0
			--set @soldmin_f=@soldmin
		end
		
		set @cDataJos=dateadd(d,-1,@cDataJos)
		if(@cDataJos<@dataSolduri and @avemDataJos=0)
		begin
				 -- set @soldmin_f=@soldmin
				  set @cDataJos=@dataSolduri
		end

		declare @cuFltLocmStilVechi int, @fltLocmStilNou varchar(20)	--> se alege tipul filtrarii pe loc de munca in functie de setare
		select @cuFltLocmStilVechi=0, @fltLocmStilNou=@locm
		if exists (select 1 from par where Tip_parametru='GE' and Parametru='FLTTRTLM' and Val_logica=1)
			select @cuFltLocmStilVechi=1, @fltLocmStilNou=null
		
		declare @tipef varchar(1)
		select @tipef=(case when @cFurnBenef='F' then 'P' else 'I' end)
		
		if (isnull(@cFurnBenef,'')<>'B' or @cTert is null) set @punctLivrare=null /** filtru pe punct livrare doar daca s-a filtrat pe un beneficiar*/
		declare @q_comanda varchar(40), @subunitate varchar(20)
		set @subunitate=isnull((select val_alfanumerica from par where Tip_parametru='GE' and parametru='SUBPRO'),'1')
		set @q_comanda=	isnull(@comanda,'')+space(20-LEN(isnull(@comanda,'')))+
						isnull(@indicator,'')+space(20-LEN(isnull(@indicator,'')))
	/**1.	Creare tabela temporara - pentru a se aranja mai usor datele in forma necesara raportului:*/
		create table #fFacturi(
			sursa varchar(1), furn_benef varchar(1), subunitate varchar(20), tert varchar(50), factura varchar(50),
			tip varchar(2), numar varchar(20), data datetime, valoare decimal(20,3), tva decimal(20,3), achitat decimal(20,3), 
			valuta varchar(3), curs decimal(20,3), total_valuta decimal(20,3), achitat_valuta decimal(20,3), 
			loc_de_munca varchar(20), comanda varchar(50), cont_de_tert varchar(40), fel int, cont_coresp varchar(40),
			explicatii varchar(500), numar_pozitie int, gestiune varchar(20), data_facturii datetime,
			data_scadentei datetime, nr_dvi varchar(20), barcod varchar(50), pozitie int)
	create clustered index principal on #fFacturi (tert,subunitate,factura,furn_benef)
	 
	if (@tipdoc='X' or @tipdoc='F')
	begin
		/* se preiau datele in tabela #docfacturi prin procedura pFacturi (in locul functiei fFacturi) */
		if object_id('tempdb..#docfacturi') is not null drop table #docfacturi
		create table #docfacturi (furn_benef char(1))
		exec CreazaDiezFacturi @numeTabela='#docfacturi'
		set @parXMLFact=(select @cFurnBenef as furnbenef, convert(char(10),@cDataJos,101) as datajos, convert(char(10),@cData,101) as datasus, 
			rtrim(@cTert) as tert, rtrim(@cFactura) as factura, rtrim(@cContTert) as contfactura, @soldmin as soldmin, @soldabs as semnsold, @fltLocmStilNou as locm
			,@indicator indicator for xml raw)
		exec pFacturi @sesiune=@sesiune, @parXML=@parXMLFact

		if object_id('tempdb..#pfacturi') is not null 
			drop table #pfacturi
		create table #pfacturi (subunitate varchar(9))
		exec CreazaDiezFacturi @numeTabela='#pfacturi'
		if @fsolddata is not null
		begin
			set @parXMLFact=(select @cFurnBenef as furnbenef, '01/01/1921' as datajos, convert(char(10),@fsolddata,101) as datasus, 1 as cen, 
			rtrim(@cTert) as tert, rtrim(@cFactura) as factura, rtrim(@cContTert) as contfactura, 0.01 as soldmin, 0 as semnsold for xml raw)
			exec pFacturi @sesiune=@sesiune, @parXML=@parXMLFact
		end

		insert into #fFacturi (sursa, furn_benef, subunitate, tert, factura, tip, numar, data, valoare, tva, 
			achitat, valuta, curs, total_valuta, achitat_valuta, loc_de_munca, comanda, cont_de_tert, fel, 
			cont_coresp, explicatii, numar_pozitie, gestiune, data_facturii, data_scadentei, nr_dvi, barcod, pozitie)
		select 'F' sursa,
			ft.furn_benef, ft.subunitate, ft.tert, ft.factura,  
			(case when @fsolddata is null or ft.data>@fsolddata then ft.tip else 'SI' end) as tip,
			rtrim(case when @fsolddata is null or ft.data>@fsolddata then ft.numar else ft.factura end) as numar,
			(case when @fsolddata is null or ft.data>@fsolddata then ft.data else @fsolddata end) as data,
			round((case when @fsolddata is null or ft.data>@fsolddata then ft.valoare else ft.valoare+ft.tva-ft.achitat end),2) as valoare, 
			round((case when @fsolddata is null or ft.data>@fsolddata then ft.tva else 0 end),2) as tva, 
			round((case when @fsolddata is null or ft.data>@fsolddata then ft.achitat else 0 end),2) as achitat, 
			ft.valuta, ft.curs, ft.total_valuta, ft.achitat_valuta, ft.loc_de_munca, ft.comanda, ft.cont_de_tert, ft.fel, ft.cont_coresp, 
			(case when ft.tip='IB' and ft.data_platii<>(case when @fsolddata is null or ft.data>@fsolddata then ft.data else @fsolddata end)
			then convert(varchar(20),ft.data_platii,103) else '' end)+' '+
			rtrim((case when @fsolddata is null or ft.data>@fsolddata then ft.explicatii else 'sold initial' end)) as explicatii,
			ft.numar_pozitie, ft.gestiune,
			ft.data_facturii as data_facturii,
			ft.data_scadentei as data_scadentei,
			ft.nr_dvi, ft.barcod, ft.pozitie
		from #docfacturi ft
		--from dbo.fFacturi (@cFurnBenef, @cDataJos, @cData,@cTert,@cFactura,@cContTert,@soldmin,@soldabs,null, @fltLocmStilNou, @parXML) ft
		where 
			--ft.data_facturii between isnull(@dDataFactJos,'1901-1-1') and isnull(@dDataFactSus,'2999-1-1') and 
			ft.data_scadentei between isnull(@dDataScadJos,'1901-1-1') and isnull(@dDataScadSus,'2999-1-1')
			and (@fsolddata is null or 
				exists (select 1 from #pfacturi fc --fFacturiCen(@cFurnBenef, '01/01/1921', @fsolddata, @cTert, @cFactura, null, null, @cContTert, 0.01, 0, null) fc
						where fc.subunitate=ft.subunitate and fc.tip=ft.furn_benef and fc.tert=ft.tert and fc.factura=ft.factura --and fc.data=ft.data_facturii
						))
		and (@comanda is null or left(ft.comanda,20)=@comanda)
		and (@punctLivrare is null or ft.nr_dvi=@punctLivrare or left(ft.tip,1)='I')	--> incasarile nu au punct de livrare
	end
		--test	select @fsolddata
		if (@punctLivrare is not null)				--> eliminare incasari aferente facturilor care nu corespund punctului de livrare curent
		delete f from #fFacturi f
		where left(f.tip,1)='I' and
			not exists(select 1 from #fFacturi ff where ff.subunitate=f.subunitate and ff.tert=f.tert and ff.factura=f.factura and not (left(ff.tip,1)='I' or left(ff.tip,1)='P'))
		if (@fsolddata is null ) set @fsolddata=@cDataJos
	if (@tipdoc='X' or @tipdoc='E')
		insert into #fFacturi (sursa, furn_benef, subunitate, tert, factura, tip, numar, data, valoare, tva, 
			achitat, valuta, curs, total_valuta, achitat_valuta, loc_de_munca, comanda, cont_de_tert, fel, 
			cont_coresp, explicatii, numar_pozitie, gestiune, data_facturii, data_scadentei, nr_dvi, barcod, pozitie)
		select 'E' sursa,
			(case when ft.tip_efect='P' then 'F' else 'B' end) furn_benef, 
			ft.subunitate subunitate, ft.tert, ft.efect as factura, --ft.factura,  --> s-a cerut sa fie efect in loc de factura
			(case when @fsolddata is null or ft.data>@fsolddata then convert(varchar(2),ft.tip_efect) else 'SI' end) 
			--'SI' 
			tip, 
			rtrim(case when @fsolddata is null or ft.data>@fsolddata then ft.numar_document else ft.factura end) as numar,
			(case when @fsolddata is null or ft.data>@fsolddata then ft.data else @fsolddata end) as data,
			round((case when @fsolddata is null or ft.data>@fsolddata then ft.valoare else ft.valoare-ft.achitat end),2) valoare,
			0 tva, round((case when @fsolddata is null or ft.data>@fsolddata then ft.achitat else 0 end),2) as achitat,
			ft.valuta valuta,
			ft.curs curs, ft.valoare_valuta total_valuta, ft.achitat_valuta achitat_valuta, ft.loc_de_munca loc_de_munca, 
			ft.comanda comanda, ft.cont cont_de_tert, '' fel, ft.cont_corespondent cont_coresp,
			explicatii,
			ft.numar_pozitie, '' gestiune,
			ft.data_efect as data_facturii,
			ft.data_scadentei as data_scadentei,
			'' nr_dvi, '' barcod, numar_pozitie
		from dbo.fEfecte(@cDataJos, @cData,@tipef,@cTert,@cFactura,@cContTert,'','', @parXML) ft
		where 
			ft.data between isnull(@dDataFactJos,'1901-1-1') and isnull(@dDataFactSus,'2999-1-1') and ft.data_scadentei
			between isnull(@dDataScadJos,'1901-1-1') and isnull(@dDataScadSus,'2999-1-1')
		and (@comanda is null or left(ft.comanda,20)=@comanda)
		and (@indicator is null or substring(ft.comanda,21,20)=@indicator)
		--and (@punctLivrare is null or ft.nr_dvi=@punctLivrare)
		--test	select * from #fFacturi
		
			/**2.	Re-filtare a datelor aranjate - filtrari care nu se puteau efectua in momentul selectiei datelor (punctul 1.) 
			si trimiterea lor catre raport*/
		delete t from #fFacturi t where
		isnull((select (case when @soldabs=1 then sum(valoare+tva-achitat) 
							else abs(sum(valoare+tva-achitat)) end) from #fFacturi f 
			where t.tert=f.tert and t.factura=f.factura and t.sursa=f.sursa --and f.data>@cDataJos
		),0)<@soldmin		/**	Se elimina facturile/efectele al caror sold final este mai mic decat @soldmin*/
		
		select ft.sursa, rtrim(t.denumire) denumire, rtrim(isnull(l.oras,t.localitate)) as oras,
				ft.furn_benef, ft.subunitate, ft.tert, ft.factura, ft.tip, ft.numar, ft.data, ft.valoare, ft.tva, ft.achitat, ft.valuta, ft.curs,
				ft.total_valuta, ft.achitat_valuta, ft.loc_de_munca, ft.comanda, ft.cont_de_tert, ft.fel, ft.cont_coresp, ft.explicatii,
				ft.numar_pozitie, ft.gestiune, 
				isnull(f.data,ft.data_facturii) as data_facturii, 
				isnull(f.data_scadentei, ft.data_scadentei) as data_scadentei,
				ft.nr_dvi, ft.barcod, ft.pozitie
		from #fFacturi ft
			left outer join terti t on ft.tert=t.tert and ft.subunitate=t.subunitate
			left outer join facturi f on ft.subunitate=f.subunitate and ft.tert=f.tert and ft.factura=f.factura and convert(char(1),f.tip)=(case when ft.furn_benef='F' then 'T' else 'F' end)
			left outer join localitati l on t.localitate=l.cod_oras
		where (@aviz_nefac=0 or rtrim(isnull(f.factura,''))<>'')
				and ((@grupa is null and @grupa_strict in (0,1)) or (@grupa_strict = 0 and @grupa is not null and t.grupa like rtrim(@grupa)+'%') or 
						(@grupa_strict = 1 and @grupa is not null and t.grupa = rtrim(@grupa)))
				and (@exc_grupa is null or t.grupa <> @exc_grupa)
				and (@cuFltLocmStilVechi=0 or @locm is null or f.Loc_de_munca like @locm+'%')
				and isnull(f.data,ft.data_facturii) between isnull(@dDataFactJos,'1901-1-1') and isnull(@dDataFactSus,'2999-1-1')
/*				and ft.sursa='F' or ft.sursa='E' and 
					((ft.data<=@cDataJos and ft.tip='SI')) --< pe efecte nu se iau rulajele? (asa e in rapFisaTerti)
					*/
		order by t.denumire, ft.data
		
	end try
	begin catch
		set @eroare='rapDocumentepeTerti (linia '+convert(varchar(20),error_line())+'):'+CHAR(10)+ERROR_MESSAGE()
	end catch
	if object_Id('tempdb.dbo.#fFacturi') is not null drop table #fFacturi
	if len(@eroare)>0 raiserror(@eroare,16,1)
end
