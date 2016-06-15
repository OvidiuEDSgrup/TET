--***
CREATE procedure rapFisaTerti(@sesiune varchar(50)=null,
	@cFurnBenef varchar(1), @cData datetime, @cTert varchar(50) = null, @cFactura varchar(50) = null, @cContTert varchar(50) = null,
	@soldmin decimal(20,2)=0.01, @soldabs int=0, @dDataFactJos datetime=null, @dDataFactSus datetime=null, @dDataScadJos datetime=null,@dDataScadSus datetime=null,
	@aviz_nefac int = 0, -- nu mai este folosit 
	@grupa varchar(50) = null, @grupa_strict int=0, @exc_grupa varchar(50)=null,
	@fsolddata1 int=0, 
	@fsold int=2,	--> @fsold=facturi pe sold; echivalenta cu : 1 => @soldmin=0.01 si @soldabs=1; 0 => @soldmin=0.00 si @soldabs=1
	@comanda varchar(50) = null, @indicator varchar(50) = null, @cDataJos datetime = null, 
	@tipdoc varchar(1) = 'F',	-->	sursa:	F=Facturi, E=Efecte, X=Toate
	@locm varchar(20) = null,
	@punctLivrare varchar(20) = null,
	@moneda bit=0, @valuta varchar(20)=null,
	@centralizare int=0,	--> prin parametrul centralizare se determina ordonarea datelor; daca 0=facturi se ord pe facturi, daca 1=documente se ord pe documente
	@gestiune varchar(20)=null,
	@soldcumulat bit=0,	--> daca se calculeaza sold cumulat sau ramane sold normal
	@cuefecte bit=0,	--> sa fie aduse facturile achitate prin efecte: 0, null = nu se aplica, 1 = se aduc doar cele cu efecte neachitate
	@judet varchar(100)=null,	-->	judet tert
	@inclFacturiNe bit=1,		--> include facturi nesosite/neintocmite
	@ordonare int=1,		--> 0 = cod, 1 = denumire
	@grupare varchar(100)='TE'	/*	"UN"=unitate,tert
									"GR"=grupa terti,tert
									"LM"=loc de munca,tert
									"CO"=comanda,tert
									"IB"=indicator bugetar,tert
									"TE"=tert,tip
									"PL"=tert, punct livrare
									"CT"=cont de tert, tert
								*/
	,@grupare1 varchar(100)='T'
	,@grupare2 varchar(100)='TP'
			/*		TE	Tert
					TP	Tip
					PL	Punct de livrare
					GR	Grupa terti
					LM	Loc de munca
					CO	Comanda
					IB	Indicator bugetar
					CT	Cont de tert
					DD	Data documentului
					DA	Data scadentei
			*/
	)
as
begin	
/*	--	Valori pentru teste
declare @cFurnBenef nvarchar(1),@cData datetime,@cTert nvarchar(7),@cFactura nvarchar(4000),
	@cContTert nvarchar(4000),@soldmin nvarchar(4),	@soldabs int,@dDataFactJos nvarchar(4000),
	@dDataFactSus nvarchar(4000),@dDataScadJos nvarchar(4000),@dDataScadSus nvarchar(4000),
	@aviz_nefac nvarchar(1),@grupa nvarchar(4000),@grupa_strict nvarchar(1),
	@exc_grupa nvarchar(4000),@fsolddata1 int, @comanda nvarchar(4000),@indicator nvarchar(4000),
	@cDataJos datetime, @tipdoc varchar(1), @locm varchar(20)
select @cFurnBenef=N'F',@cData='2011-08-31 00:00:00',--@cTert=N'253232 ',
	@cFactura=NULL,@cContTert=NULL,@soldmin=N'1', @soldabs=0,@dDataFactJos=NULL,
	@dDataFactSus=NULL,@dDataScadJos=NULL,@dDataScadSus=NULL,@aviz_nefac=N'0',@grupa=NULL,
	@grupa_strict=N'0',@exc_grupa=NULL,@fsolddata1=0,@comanda=NULL,@indicator=NULL,
	@cDataJos='2011-1-1 00:00:00', @tipdoc='x', @locm='11'
--*/
	set transaction isolation level read uncommitted
	--> evitare "parameter sniffing":
		declare @q_sesiune varchar(50), @q_cFurnBenef varchar(1), @q_cData datetime, @q_cTert varchar(50), @q_cFactura varchar(50), @q_cContTert varchar(50),
			@q_soldmin decimal(20,2), @q_soldabs int, @q_dDataFactJos datetime, @q_dDataFactSus datetime, @q_dDataScadJos datetime,
			@q_dDataScadSus datetime, @q_aviz_nefac int, @q_grupa varchar(50), @q_grupa_strict int, @q_exc_grupa varchar(50),
			@q_fsolddata1 int, @q_fsold int, @q_comanda varchar(50), @q_indicator varchar(50), @q_cDataJos datetime, @q_tipdoc varchar(1),
			@q_locm varchar(20), @q_punctLivrare varchar(20), @q_moneda bit, @q_valuta varchar(20), @q_centralizare int,
			@q_gestiune varchar(20), @q_soldcumulat bit
				
		select @q_sesiune=@sesiune, @q_cFurnBenef=@cFurnBenef, @q_cData=@cData, @q_cTert=@cTert, @q_cFactura=@cFactura, @q_cContTert=@cContTert,
			@q_soldmin=@soldmin, @q_soldabs=@soldabs, @q_dDataFactJos=@dDataFactJos, @q_dDataFactSus=@dDataFactSus, @q_dDataScadJos=@dDataScadJos,
			@q_dDataScadSus=@dDataScadSus, @q_aviz_nefac=@aviz_nefac, @q_grupa=@grupa, @q_grupa_strict=@grupa_strict, @q_exc_grupa=@exc_grupa,
			@q_fsolddata1=@fsolddata1, @q_fsold=@fsold, @q_comanda=@comanda, @q_indicator=@indicator, @q_cDataJos=@cDataJos, @q_tipdoc=@tipdoc,
			@q_locm=@locm+'%', @q_punctLivrare=@punctLivrare, @q_moneda=@moneda, @q_valuta=@valuta, @q_centralizare=@centralizare,
			@q_gestiune=@gestiune, @q_soldcumulat=@soldcumulat
			
	declare @q_deNesters bit, @parXML xml, @parXMLFact xml
	select @q_deNesters=0, @parXML=(select @sesiune as sesiune, isnull(@cuefecte,0) as efecteachitate for xml raw)
	if object_Id('tempdb.dbo.#fFacturi') is not null drop table #fFacturi
	IF OBJECT_ID('tempdb..#raport') IS NOT NULL drop table #raport
	IF OBJECT_ID('tempdb..#facturiCuGestiuni') IS NOT NULL drop table #facturiCuGestiuni
declare @q_eroare varchar(1000)
set @q_eroare=''
begin try
	if object_id('tempdb..#fisa') is null
	begin
		create table #fisa (ceva char(1) default '')
		exec rapFisaTerti_structFisa
	end
	else select @q_deNesters=1
	
	if (@q_fsold=1)	select @q_soldmin=(case when abs(@soldmin)>0.01 then @soldmin else 0.01 end), @q_soldabs=0
	if (@q_fsold=0)	select @q_soldmin=0.00, @q_soldabs=0
		
	declare @q_utilizator varchar(50), @cuFiltruLM bit
	select @q_utilizator=dbo.fiautilizator(@q_sesiune), @cuFiltruLM=0
	if @q_cdata is null and exists (select 1 from lmfiltrare l where l.utilizator=@q_utilizator)
		select @cuFiltruLM=1
		
	/* Am scos cele de mai jos pentru ca fFacturi aduce datele filtrate in functie de setare, nu este nevoie sa se trateze aici
	--declare @q_cuFltLocmStilVechi int, @q_fltLocmStilNou varchar(20)	--> se alege tipul filtrarii pe loc de munca in functie de setare
	--select @q_cuFltLocmStilVechi=0, @q_fltLocmStilNou=@q_locm
	--if exists (select 1 from par where Tip_parametru='GE' and Parametru='FLTTRTLM' and Val_logica=1)
	--	select @q_cuFltLocmStilVechi=1, @q_fltLocmStilNou=null
	*/
	
	declare @q_dataImplementarii datetime,
			@q_dataSolduri datetime		/**	data pana la care orice sume vor aparea ca solduri = data implementarii sau data ultimei initializari;
											daca nu e completat @q_cdatajos va fi @q_datasolduri*/
			, @lDPreImpl int, @dDPreImpl datetime  -- o setare care spune ca am date initiale anterioare factimpl, tinute in istfact 
	select @q_dataImplementarii=--'1921-1-1'
	dateadd(d,-1,
		dateadd(m,1,
		isnull((select convert(varchar(4),val_numerica) from par where tip_parametru='ge' and parametru='ANULIMPL'),'1921')+'-'+
		isnull((select convert(varchar(2),val_numerica) from par where tip_parametru='ge' and parametru='lunaimpl'),'1')+'-1'
		)),
		@q_dataSolduri=(select max(case when parametru='ANULINC' then convert(varchar(20),val_numerica) else '' end)+'-'
								+max(case when parametru='LUNAINC' then convert(varchar(20),val_numerica) else '' end)+'-1'
						from par p where tip_parametru='GE' and parametru in ('ANULINC','LUNAINC'))
		
		if (@q_dataSolduri<@q_dataImplementarii) set @q_dataSolduri=@q_dataImplementarii
	--*/
	select	@lDPreImpl=isnull((select top 1 val_logica from par where tip_parametru='GE' and parametru='PREIMPL'),0), 
			@dDPreImpl=isnull((select max(convert(datetime,val_alfanumerica)) from par where tip_parametru='GE' and parametru='PREIMPL'),'1901-01-01')

	declare @q_soldmin_f varchar(20), @q_tipef varchar(1)
	select @q_soldmin_f=0.00,
		@q_tipef=(case when @q_cFurnBenef='F' then 'P' else 'I' end)
	
	declare @q_avemDataJos int	select @q_avemDataJos=1
	if (@q_cDataJos is null)
	begin
		set @q_cDataJos='1921-1-1'
		--set @q_fsolddata1=0
		set @q_avemDataJos=0
		--set @q_soldmin_f=@q_soldmin
	end
	set @q_cDataJos=dateadd(d,-1,@q_cDataJos)
	if(@q_cDataJos<@q_dataSolduri and @q_avemDataJos=0)
	begin
			 -- set @q_soldmin_f=@q_soldmin
			  set @q_cDataJos=@q_dataSolduri
	end
	if @lDPreImpl=1 and @q_cData<=@q_dataImplementarii
		set @q_cDataJos=@dDPreImpl
	
	if (isnull(@q_cFurnBenef,'')<>'B' or @q_cTert is null) set @q_punctLivrare=null /** filtru pe punct livrare doar daca s-a filtrat pe un beneficiar*/
	
	declare @q_q_comanda varchar(40)
	set @q_q_comanda=	isnull(@q_comanda,'')+space(20-LEN(isnull(@q_comanda,'')))+
					isnull(@q_indicator,'')+space(20-LEN(isnull(@q_indicator,'')))
	/**1.	Creare tabela temporara - pentru a se aranja mai usor datele in forma necesara raportului:*/
		create table #fFacturi(
			sursa varchar(1), furn_benef varchar(1), subunitate varchar(20), tert varchar(50),
			factura varchar(50), tip varchar(10), numar varchar(20), data datetime, 
			valoare decimal(20,3), tva decimal(20,3), achitat decimal(20,3), valuta varchar(10),
			curs decimal(20,4), total_valuta decimal(20,3), achitat_valuta decimal(20,3),
			loc_de_munca varchar(50), comanda varchar(50), cont_de_tert varchar(50), fel int,
			cont_coresp varchar(50), gestiune varchar(50), data_facturii datetime, 
			data_scadentei datetime, nr_dvi varchar(50), barcod varchar(50), explicatii varchar(500),
			data_platii datetime, numar_pozitie int, pozitie int, achitat_efect decimal(15,5) default 0
			,indicator varchar(100) default ''
			)
	if @q_tipdoc='C'	--> fisa terti combinata - doar cu pstocuri merge
	begin
		--if object_id('pstocuri') is null raiserror('Fisa terti combinata functioneaza doar daca procedura pstocuri e instalata!',16,1)
		declare @p xml
		select @p=(select --?: cod, @comanda Comanda, @
			@q_cDataJos as dDataJos, @q_cData as dDataSus, @gestiune cGestiune, @cTert+'%' locatieLike, 'T' as subtipGestiune for xml raw)
		create table #docstoc(subunitate varchar(max))
		exec pStocuri_tabela
		exec pstoc @sesiune=@sesiune, @parxml=@p
--select * from #docstoc
		if object_id('tempdb..#preturi') is not null 
			drop table #preturi
		create table #preturi(cod varchar(20), nestlevel int)
		
		insert into #preturi
		select cod, @@NESTLEVEL
		from #docstoc
		group by cod
			
		exec CreazaDiezPreturi

		declare @parXMLPreturi xml
		set @parxmlpreturi = (select @q_ctert tert for xml raw)
		exec wIapreturi @sesiune, @parXMLPreturi

		update d
			set pret=p.pret_amanunt_discountat /* pret cu amanuntul, deoarece restul sumelor sunt in pret cu amanuntul (a se vedea achitat/sold final) */
		from #docstoc d, #preturi p
		where d.cod=p.cod

		insert into #fFacturi(sursa, furn_benef, subunitate, tert, factura, tip, numar, data, 
				valoare, tva, achitat, valuta, curs, total_valuta, achitat_valuta, loc_de_munca, comanda, cont_de_tert,
				fel, cont_coresp, gestiune, data_facturii, data_scadentei, nr_dvi, barcod, explicatii,
				data_platii, numar_pozitie, pozitie, achitat_efect, indicator)
		select 'S', '', '1', rtrim(left(locatie,13)), numar_document, tip_document, numar_document, data,
				cantitate*pret, 0, 0, '', 1, 0, 0, d.loc_de_munca, d.comanda, d.cont, 
				'' fel, cont_corespondent, d.gestiune, data, '2099-01-01', '', '', rtrim(n.denumire),
				'', 0, 0, 0, ''
		from #docstoc d
		left join nomencl n on d.cod=n.cod
		where (@ctert is null or isnull(locatie,'')<>'')

		set @q_tipdoc='X'
	end
if (@q_tipdoc='X' or @q_tipdoc='F')
begin
	if @q_cdata is null
	begin
		if @cuefecte=1
		begin
			select @q_eroare='Varianta la zi a fisei terti nu tine cont de achitarea prin efecte!'+char(10)+'Rulati raportul fara aceasta optiune sau pe un interval!'
			raiserror(@q_eroare,16,1) 
		end
		insert into #fFacturi(sursa, furn_benef, subunitate, tert, factura, tip, numar, data, valoare, tva,
				achitat, valuta, curs, total_valuta, achitat_valuta, loc_de_munca, comanda, cont_de_tert,
				fel, cont_coresp, gestiune, data_facturii, data_scadentei, nr_dvi, barcod, explicatii,
				data_platii, numar_pozitie, pozitie, achitat_efect)
		select 'F', (case when ft.tip=0x54 then 'F' else 'B' end), subunitate, tert, factura, 'FA', factura, data, valoare, tva_22+tva_11,
						achitat, valuta, curs, valoare_valuta, achitat_valuta, loc_de_munca, comanda, cont_de_tert,
						'' fel, '' cont_coresp, '' gestiune, data, data_scadentei, '' nr_dvi, '' barcod, '' explicatii,
						'' data_platii, '' numar_pozitie, '' pozitie, 0	
		from facturi ft
		where
			@q_cFurnBenef=(case when ft.tip=0x54 then 'F' else 'B' end)
				and (@q_ctert is null or ft.tert like @q_ctert)
				and (@q_cfactura is null or ft.factura like @q_cfactura)
				and (@q_cContTert is null or ft.cont_de_tert like @q_cContTert)
				and (@q_locm is null or ft.loc_de_munca like @q_locm)
			and ft.data between isnull(@q_dDataFactJos,'1901-1-1') and isnull(@q_dDataFactSus,'2999-1-1')
				and ft.data_scadentei between isnull(@q_dDataScadJos,'1901-1-1') and isnull(@q_dDataScadSus,'2999-1-1')
				--and (@q_aviz_nefac=0 or rtrim(isnull(ft.factura,''))<>'')
				and (@q_comanda is null or left(ft.comanda,20)=@q_comanda) 
				and (@q_indicator is null or substring(ft.comanda,21,20)=@q_indicator)
			and (@cuFiltruLM=0 or exists (select 1 from lmfiltrare l where l.utilizator=@q_utilizator and l.cod=ft.loc_de_munca))
	end
	else
		begin
			/* se preiau datele in tabela #docfacturi prin procedura pFacturi (in locul functiei fFacturi) */
			if object_id('tempdb..#docfacturi') is not null drop table #docfacturi
			create table #docfacturi (furn_benef char(1))
			exec CreazaDiezFacturi @numeTabela='#docfacturi'
			set @parXMLFact=(select @q_cFurnBenef as furnbenef, convert(char(10),@q_cDataJos,101) as datajos, convert(char(10),@q_cData,101) as datasus, 
				rtrim(@q_cTert) as tert, rtrim(@q_cFactura) as factura, rtrim(@q_cContTert) as contfactura, @q_soldmin_f as soldmin, @soldabs as semnsold, 
				rtrim(@locm) as locm, isnull(@cuefecte,0) as efecteachitate,(case when @centralizare='101' then 'tert,data,loc_de_munca' else '' end) as grupare,
				@inclFacturiNe inclfacturine, (case when @grupa_strict=0 then @q_grupa else null end) as gtert,
				@indicator indicator for xml raw)
			exec pFacturi @sesiune=@sesiune, @parXML=@parXMLFact

			if object_id('tempdb..#tfacturi') is not null drop table #tfacturi -- tabela cu datele globale ale facturii
			select ft.furn_benef furn_benef, ft.subunitate subunitate, ft.tert, ft.factura,  
				max(ft.comanda) comanda, 
	-->Luci: data facturii si data scadentei nu se iau de pe liniile de Plati/Incasari:
			--/*
				min(case when year(isnull(f.data,ft.data_facturii))<1902 or left(ft.tip,1) in ('I','P') then '2999-12-31' else isnull(f.data,ft.data_facturii) end) as data_facturii, 
				min(case when year(isnull(f.data_scadentei,ft.data_scadentei))<1902 or left(ft.tip,1) in ('I','P') then '2999-12-31' else isnull(f.data_scadentei,ft.data_scadentei) end) as data_scadentei 
				--*/
			into #tfacturi
			from #docfacturi ft
				left join facturi f on f.tip=(case when @q_cFurnBenef='F' then 0x54 else 0x46 end) and
					f.subunitate=ft.subunitate and f.factura=ft.factura and f.tert=ft.tert --and f.data<ft.data_facturii
			group by ft.furn_benef, ft.subunitate, ft.tert, ft.factura
--select 'test',* from #tfacturi
			--> completare puncte de livrare; incasarile nu au puncte de livrare, doar documentele:
			update ft set nr_dvi=d.nr_dvi
				from #docfacturi ft 
				inner join #docfacturi d on d.tert=ft.tert and d.factura=ft.factura and d.furn_benef=ft.furn_benef and d.nr_dvi<>''
				where ft.nr_dvi=''

			--> filtrarea pe puncte de livrare; incasarile nu au puncte de livrare, doar documentele:
			if @q_punctLivrare is not null
				delete ft from #docfacturi ft where ft.nr_dvi!=@q_punctLivrare

			insert into #fFacturi(sursa, furn_benef, subunitate, tert, factura, tip, numar, data, valoare, tva,
				achitat, valuta, curs, total_valuta, achitat_valuta, loc_de_munca, comanda, cont_de_tert,
				fel, cont_coresp, gestiune, data_facturii, data_scadentei, nr_dvi, barcod, explicatii,
				data_platii, numar_pozitie, pozitie, achitat_efect, indicator)
			select 'F' sursa,
				ft.furn_benef furn_benef, ft.subunitate subunitate, ft.tert, ft.factura,  
				ft.tip, ft.numar,  ft.data data, ft.valoare valoare, ft.tva, ft.achitat, ft.valuta valuta,
				ft.curs curs, ft.total_valuta total_valuta, ft.achitat_valuta achitat_valuta, ft.loc_de_munca loc_de_munca, 
				isnull(f.comanda,ft.comanda) comanda, ft.cont_de_tert cont_de_tert, ft.fel fel, ft.cont_coresp cont_coresp,
				ft.gestiune gestiune, 
				isnull(f.data_facturii, ft.data_facturii) as data_facturii, 
				isnull(f.data_scadentei, ft.data_scadentei) as data_scadentei, 
				ft.nr_dvi nr_dvi, ft.barcod barcod, explicatii, data_platii, numar_pozitie, pozitie, achitare_efect_in_curs,
				ft.indbug as indicator
			from #docfacturi ft
			--from dbo.fFacturi (@q_cFurnBenef, @q_cDataJos, @q_cData,@q_cTert,@q_cFactura,@q_cContTert,@q_soldmin_f,0,0,@locm, @parXML) ft
			left outer join #tfacturi f on f.subunitate=ft.subunitate and f.tert=ft.tert and f.factura=ft.factura and f.furn_benef=ft.furn_benef
			where --(@q_tipdoc='X' or @q_tipdoc='F') and
				isnull(nullif(f.data_facturii,'2999-12-31'), ft.data_facturii) between isnull(@q_dDataFactJos,'1901-1-1') and isnull(@q_dDataFactSus,'2999-12-31')
				and isnull(nullif(f.data_scadentei,'2999-12-31'), ft.data_scadentei)
				--ft.data_scadentei 
				between isnull(@q_dDataScadJos,'1901-1-1') and isnull(@q_dDataScadSus,'2999-12-31')
				--and (@q_aviz_nefac=0 or rtrim(isnull(ft.factura,''))<>'')
				and (@q_comanda is null or left(isnull(f.comanda, ft.comanda),20)=@q_comanda) 
				--and (@q_indicator is null or ft.indbug=@q_indicator)			
		end
end

if (@q_tipdoc='X' or @q_tipdoc='E')
begin
	if @q_cdata is null
		insert into #fFacturi(sursa, furn_benef, subunitate, tert, factura, tip, numar, data, valoare, tva,
				achitat, valuta, curs, total_valuta, achitat_valuta, loc_de_munca, comanda, cont_de_tert,
				fel, cont_coresp, gestiune, data_facturii, data_scadentei, nr_dvi, barcod, explicatii,
				data_platii, numar_pozitie, pozitie, achitat_efect, indicator)
		select 'E', (case when ft.tip='P' then 'F' else 'B' end), subunitate, tert, nr_efect, 'EF', nr_efect, data, valoare, 0 tva,
						decontat achitat, valuta, curs, valoare_valuta, decontat_valuta achitat_valuta, loc_de_munca, comanda, cont cont_de_tert,
						'' fel, '' cont_coresp, '' gestiune, data, data_scadentei, '' nr_dvi, '' barcod, explicatii explicatii,
						'' data_platii, '' numar_pozitie, '' pozitie, 0, substring(ft.comanda,21,20)
		from efecte ft
		where
			@q_tipef=ft.tip
				and (@q_ctert is null or ft.tert like @q_ctert)
				and (@q_cfactura is null or ft.nr_efect like @q_cfactura)
				and (@q_cContTert is null or ft.cont like @q_cContTert)
				and (@q_locm is null or ft.loc_de_munca like @q_locm)
			and ft.data between isnull(@q_dDataFactJos,'1901-1-1') and isnull(@q_dDataFactSus,'2999-1-1')
				and ft.data_scadentei between isnull(@q_dDataScadJos,'1901-1-1') and isnull(@q_dDataScadSus,'2999-1-1')
				--and (@q_aviz_nefac=0 or rtrim(isnull(ft.nr_efect,''))<>'')
				and (@q_comanda is null or left(ft.comanda,20)=@q_comanda) 
				and (@q_indicator is null or substring(ft.comanda,21,20)=@q_indicator)
			and (@cuFiltruLM=0 or exists (select 1 from lmfiltrare l where l.utilizator=@q_utilizator and l.cod=ft.loc_de_munca))
	else
		insert into #fFacturi(sursa, furn_benef, subunitate, tert, factura, tip, numar, data, valoare, tva,
				achitat, valuta, curs, total_valuta, achitat_valuta, loc_de_munca, comanda, cont_de_tert,
				fel, cont_coresp, gestiune, data_facturii, data_scadentei, nr_dvi, barcod, explicatii,
				data_platii, numar_pozitie, pozitie, achitat_efect, indicator)
		select 'E' sursa,
		(case when ft.tip_efect='P' then 'F' else 'B' end) furn_benef, ft.subunitate subunitate, ft.tert, 
		--ft.factura,	--> pentru efecte numarul facturii s-a inlocuit cu numarul efectului
		ft.efect factura,
		ft.tip_document tip, ft.numar_document,  ft.data data, ft.valoare valoare, 0 tva, ft.achitat, ft.valuta valuta,
		ft.curs curs, ft.valoare_valuta total_valuta, ft.achitat_valuta achitat_valuta, ft.loc_de_munca loc_de_munca, 
		ft.comanda comanda, ft.cont cont_de_tert, '' fel, ft.cont_corespondent cont_coresp,
		'' gestiune, ft.data_efect as data_facturii, ft.data_scadentei as data_scadentei, 
		'' nr_dvi, '' barcod, explicatii, '1901-1-1', numar_pozitie, '', 0, substring(comanda,21,20)
		from dbo.fEfecte(@q_cDataJos, @q_cData,@q_tipef,@q_cTert,@q_cFactura,@q_cContTert,@locm,'', @parXML) ft
		where --@q_cDataJos>dateadd(d,-1,@q_dataSolduri)
			(@q_tipdoc='X' or @q_tipdoc='E')
			and isnull(ft.data_scadentei, ft.data_scadentei) between isnull(@q_dDataScadJos,'1901-1-1') and isnull(@q_dDataScadSus,'2999-1-1')
			--and (@q_aviz_nefac=0 or rtrim(isnull(ft.factura,''))<>'')
			and (@q_comanda is null or left(ft.comanda,20)=@q_comanda) 
			and (@q_indicator is null or substring(ft.comanda,21,20)=@q_indicator)
end
	/**	Se elimina facturile/efectele al caror sold final este mai mic decat @q_soldmin*/
	select tert, factura, sursa, (case when @q_soldabs=1 then sum(valoare+tva-achitat) else abs(sum(valoare+tva-achitat)) end) as sold, sum(achitat_efect) achitat_efect
		into #fFactGrup 
		from #fFacturi group by tert, factura, sursa 
		having (case when @q_soldabs=1 then sum(valoare+tva-achitat) else abs(sum(valoare+tva-achitat)) end) < @q_soldmin 

	delete t 
		from #fFacturi t, #fFactGrup f 
		where t.tert=f.tert and t.factura=f.factura and t.sursa=f.sursa --and f.data>@q_cDataJos
			and abs(f.achitat_efect)<=0.001

	--select * into #test from #fFacturi
	/**2.	Aranjarea datelor pentru raport:*/
	if (@q_avemDataJos=1) set @q_cDataJos=dateadd(d,1,@q_cDataJos)
	
	create table #facturiCuGestiuni(tert varchar(20), factura varchar(20))
	if (@q_gestiune is not null)
	begin
		insert into #facturiCuGestiuni (tert, factura)
		select tert, factura from #fFacturi where gestiune=@q_gestiune and isnull(factura,'')<>'' group by tert, factura
	
		delete f
		from #fFacturi f where not exists (select 1 from #facturiCuGestiuni g where g.tert=f.tert and g.factura=f.factura)
	end
	
	--update #fFacturi set explicatii=rtrim(explicatii)+' ('+rtrim(cont_coresp)+')'
	create table #raport(sursa varchar(200), denumire varchar(200), oras varchar(200), furn_benef varchar(1), subunitate varchar(20), tert varchar(20),
		factura varchar(20), tip varchar(20), numar varchar(20), data datetime, soldi decimal(15,4), soldi_valuta decimal(15,4), valoare decimal(15,4),
		tva decimal(15,4), achitat decimal(15,4), valuta  varchar(20), curs decimal(15,4), total_valuta decimal(15,4), achitat_valuta decimal(15,4), 
		loc_de_munca varchar(20), comanda  varchar(40), cont_de_tert varchar(40), fel int, cont_coresp varchar(40), explicatii  varchar(500),
		numar_pozitie varchar(20), gestiune  varchar(20), data_facturii datetime, data_scadentei datetime, nr_dvi  varchar(40), 
		barcod varchar(500), pozitie varchar(20), peSold bit, primSold int,
		ordonare varchar(2000), sold_cumulat_valuta decimal(15,5), sold_cumulat_lei decimal(15,5),
		partitionareSold varchar(200), achitat_efect decimal(15,5), gtert varchar(200), dengtert varchar(2000),
		denlm varchar(2000), indicator varchar(100) default '',
		den_pctlivrare varchar(2000) null, den_cont varchar(2000) null,
		grupare1 varchar(100) default null, denumire1 varchar(1000) default null,
		grupare2 varchar(100) default null, denumire2 varchar(1000) default null)

	insert into #raport (sursa, denumire, oras, furn_benef, subunitate, tert,
		factura, tip, numar, data, soldi, soldi_valuta, valoare,
		tva, achitat, valuta, curs, total_valuta, achitat_valuta, 
		loc_de_munca, comanda, cont_de_tert, fel, cont_coresp, explicatii,
		numar_pozitie, gestiune, data_facturii, data_scadentei, nr_dvi, 
		barcod, pozitie, peSold, primSold,
		ordonare, sold_cumulat_valuta, sold_cumulat_lei,
		partitionareSold, achitat_efect, gtert, dengtert, denlm, indicator)
	select sursa,
		t.denumire, l.oras,
		furn_benef, f.subunitate, f.tert, f.factura, tip, numar, data, soldi, soldi_valuta, valoare,
		tva, achitat, valuta, curs, total_valuta, achitat_valuta,
		loc_de_munca, comanda, cont_de_tert, fel, cont_coresp, rtrim(explicatii)--+' '+rtrim(cont_coresp)  --> a fost mutat in coloana distincta din detalii
			explicatii, numar_pozitie, gestiune, data_facturii, data_scadentei, nr_dvi,
		barcod, pozitie, peSold, row_number() over (partition by tip, f.subunitate, f.factura, f.tert, f.sursa, f.furn_benef order by f.data_facturii desc, f.data_scadentei desc) as primSold,
		space(2000) as ordonare, convert(decimal(15,3),0) as sold_cumulat_valuta, convert(decimal(15,3),0) as sold_cumulat_lei,
		convert(varchar(2000),rtrim(isnull(f.tert,''))+'|'--+(case when @q_moneda=0 then '' else isnull(f.valuta,'') end)
		)
		as partitionareSold, achitat_efect, rtrim(t.grupa), rtrim(g.denumire), rtrim(lm.denumire), indicator
	from
	(	/**	Sold initial */
		select sursa,
			furn_benef, subunitate, tert, factura, 
			'SI' tip, factura numar, min(data) as data, sum(round(valoare+tva-achitat,2)) as soldi,
			sum(round(f.total_valuta-achitat_valuta,2)) as soldi_valuta, 0 as valoare,
			0 tva, 0 achitat, max(valuta) valuta, max(curs) curs, 0 total_valuta,
			0 achitat_valuta,
			max(loc_de_munca) loc_de_munca, max(comanda) comanda, max(cont_de_tert) cont_de_tert, max(fel) fel, max(cont_coresp) cont_coresp, 
			'sold initial' explicatii, 0 numar_pozitie, max(gestiune) gestiune, max(data_facturii) data_facturii,
			max(data_scadentei) data_scadentei, max(nr_dvi) nr_dvi, max(barcod) barcod, 0 pozitie,
			(case when abs(sum(round(valoare+tva-achitat,2)))>0.0001 then 1 else 0 end) as peSold, sum(isnull(achitat_efect,0)) achitat_efect, indicator
		from #fFacturi f
		where	--(@q_fsolddata1=0 or abs(valoare)>0.0001) and 
			f.data<@q_cDataJos
		group by subunitate, factura,tert, --f.data,
			sursa, furn_benef, indicator
	union all	/**	rulaje	*/
		select sursa, furn_benef, subunitate, tert, factura, tip, numar, data, 
			0 as soldi, 0 as soldi_valuta, round(valoare,2),	round(tva,2), round(achitat,2), 
			valuta, curs, total_valuta, achitat_valuta, 
			loc_de_munca, comanda, cont_de_tert, fel, cont_coresp, 
			(case when f.tip='IB' and f.data_platii<>f.data	then convert(varchar(20),f.data_platii,103) else '' end)+' '+
			rtrim(explicatii), numar_pozitie, gestiune, data_facturii, data_scadentei, nr_dvi, 
			barcod, pozitie, (case when tip='SI' and abs((round(valoare+tva-achitat,2)))>0.0001 then 1 else 0 end) as peSold,
			isnull(achitat_efect,0) achitat_efect, indicator
		from #fFacturi f
			where --(@q_tipdoc='X' or @q_tipdoc='F') and	--< pe efecte nu se iau rulaje?
				f.data>=@q_cDataJos
	) f
		left outer join terti t on f.tert=t.tert and f.subunitate=t.subunitate
		left join gterti g on t.grupa=g.grupa
		left join lm on f.loc_de_munca=lm.cod
		left outer join localitati l on t.localitate=l.cod_oras
		where ((@q_grupa is null and @q_grupa_strict in (0,1)) or (@q_grupa_strict = 0 and @q_grupa is not null and t.grupa like rtrim(@q_grupa)+'%') or 
				(@q_grupa_strict = 1 and @q_grupa is not null and t.grupa = rtrim(@q_grupa)))
				and (@q_exc_grupa is null or t.grupa <> @q_exc_grupa) --and (@q_cuFltLocmStilVechi=0 or @q_locm is null or f.loc_de_munca like @q_locm+'%')
				and (@judet is null or l.cod_judet=@judet)
	order by f.tert, (case when @q_moneda=0 then '' else f.valuta end), f.data, f.tip, f.numar

	--create index indrap on #raport (subunitate, factura, tert, data, sursa, furn_benef)

	--> daca se doreste doar facturi pe sold la inceput interval:
	if (@q_fsolddata1=1)
	begin
		--> eliminare inregistrari care nu au sold initial
		delete r from #raport r where not exists (select 1 from #raport rs where rs.tip='SI' and
				rs.subunitate=r.subunitate and rs.factura=r.factura and rs.tert=r.tert --and rs.data_facturii=r.data_facturii
				and rs.sursa=r.sursa and rs.furn_benef=r.furn_benef		-->>????? trebuie join pe data, si daca da, cum?
				and rs.data<@q_cDataJos)

		--> eliminare inregistrari care au fost achitate complet inainte de inceputul intervalului
		delete r from #raport r where exists (select 1 from #raport rs where rs.tip='SI' and
				rs.subunitate=r.subunitate and rs.factura=r.factura and rs.tert=r.tert --and rs.data_facturii=r.data_facturii
				and rs.sursa=r.sursa and rs.furn_benef=r.furn_benef
				and rs.peSold=0)
	end	
--/*	--> stabilesc data facturii si data scadentei pentru toate liniile care tin de o factura:
	update r set data_facturii=rs.data_facturii, data_scadentei=rs.data_scadentei
	from #raport r inner join #raport rs on rs.tip='SI' and
			rs.subunitate=r.subunitate and rs.factura=r.factura and rs.tert=r.tert
			and rs.sursa=r.sursa and rs.furn_benef=r.furn_benef and rs.primSold=1
		--*/
--/*
	-- daca exista factura, se iau de acolo data_facturii si data_scadentei
	update r set data_facturii=f.data, data_scadentei=f.data_scadentei
	from #raport r inner join facturi f on f.tip=(case when @q_cFurnBenef='F' then 0x54 else 0x46 end) and
			f.subunitate=r.subunitate and f.factura=r.factura and f.tert=r.tert
--*/
	-- daca sunt pe fisa ante-implementare:
	if @lDPreImpl=1 and @q_cData<=@q_dataImplementarii
	update r set data_facturii=f.data_facturii, data_scadentei=f.data_scadentei
	from #raport r 
	inner join (select subunitate, factura, tert, min(data_facturii) data_facturii, max(data_scadentei) data_scadentei
		from #raport f
		group by subunitate, factura, tert) f on f.subunitate=r.subunitate and f.factura=r.factura and f.tert=r.tert

	--> eliminare inregistrari care nu se incadreaza in intervalul datei emiterii: -- mai sus am filtrat, dar aici se aplica si la efecte
	delete f from #raport f where convert(datetime, f.data_facturii) not between convert(datetime,isnull(@q_dDataFactJos,'1901-1-1')) and convert(datetime,isnull(@q_dDataFactSus,'2999-1-1'))

	--> eliminare inregistrari care au valori 0 atat la inceput de interval cat si in cadrul intervalului
	delete f from #raport f 
	where soldi=0 and valoare=0 and tva=0 and achitat=0 and sold_cumulat_lei=0 
		and soldi_valuta=0 and total_valuta=0 and achitat_valuta=0 and sold_cumulat_valuta=0 

	--delete f from #raport f 
	--where not ((@q_moneda=0 or len(rtrim(valuta))>0) -- daca @q_moneda=0 (=> Fisa tert.RDL) se aduc si facturile in lei (cu valuta necompletata), in rest doar cele cu valuta completata
	--	and (@q_valuta is null or valuta=@q_valuta))

	delete f 
		from #raport f, terti t 
		where t.subunitate=f.subunitate and t.tert=f.tert 
			and not((@q_moneda=0 or t.tert_extern=1) -- daca fisa in valuta sa ia doar tertii cu decontare in valuta 
					and (@q_valuta is null or valuta=@q_valuta))

	declare @q_partitionareSold varchar(2000), @q_soldCvaluta decimal(15,3), @q_soldClei decimal(15,3)
	select @q_partitionareSold='', @q_soldCvaluta=0, @q_soldClei=0
	
		--> incasarile nu au punct de livrare asociat; il completez in baza tertului si a facturii:
	if @grupare='PL' or @grupare1='PL' or @grupare2='PL'
	begin
		update f
		set nr_dvi=s.nr_dvi
		from #raport f cross apply (select top 1 nr_dvi from #raport s where s.tip=f.tip and s.tert=f.tert and s.factura=f.factura and isnull(nr_dvi,'')<>'') s
		where isnull(f.nr_dvi,'')=''
	end
	
	if @grupare='PL' or @grupare1='PL' or @grupare2='PL'
	update f set den_pctlivrare=rtrim(i.descriere)
	from #raport f left join infotert i on i.subunitate=f.subunitate and i.tert=f.tert and i.identificator=f.nr_dvi
	
	if @grupare='CT' or @grupare1='CO' or @grupare2='CO'
	update f set den_cont=rtrim(c.denumire_cont)
	from #raport f left join conturi c on f.subunitate=c.subunitate and f.cont_de_tert=c.cont
	
	/*update f set f.dentert
	from #fisa f left join terti t on t.subunitate=f.subunitate and f.tert=t.tert
		left join gterti g on t.grupa=g.grupa
		left join lm l on f.loc_de_munca=l.cod
		left join infotert i on i.subunitate=t.subunitate and i.tert=f.tert and i.identificator=f.nr_dvi*/
		
	--> regulile de grupare anterioare, in cazul in care vom lasa compatibilitate in urma:
	if @grupare<>'TE' and @grupare1='TE' and @grupare2='TP'
		update #raport set grupare1=rtrim(case @grupare
									when 'GR' then gtert
									when 'LM' then loc_de_munca
									when 'CO' then comanda
									when 'IB' then indicator
									when 'TE' then tert --sursa+'|'+tert
									when 'PL' then tert
									when 'CT' then cont_de_tert
									else ''
									end),
									
					denumire1=rtrim(case @grupare
									when 'GR' then dengtert
									when 'LM' then denlm
									when 'CO' then comanda
									when 'IB' then indicator
									when 'TE' then denumire
									when 'PL' then denumire
									when 'CT' then den_cont
									else ''
									end),

					grupare2=rtrim(case @grupare
									when 'UN' then tert
									when 'GR' then tert
									when 'LM' then tert
									when 'CO' then tert
									when 'CT' then tert
									when 'IB' then tert
									when 'TE' then sursa
									when 'PL' then nr_dvi
									else ''
									end),
									
					denumire2=rtrim(case @grupare
									when 'UN' then denumire
									when 'GR' then denumire
									when 'LM' then denumire
									when 'CO' then denumire
									when 'IB' then denumire
									when 'CT' then denumire
									when 'TE' then (case sursa when 'F' then 'Facturi' when 'E' then 'Efecte' when 'S' then 'Stoc' end)
									when 'PL' then den_pctlivrare
									else ''
									end)
	else	--> regulile de grupare curente:
	update #raport set grupare1=rtrim(case @grupare1
									when 'TE' then tert --sursa+'|'+tert
									when 'TP' then sursa --sursa+'|'+tert
									when 'PL' then nr_dvi
									when 'GR' then gtert
									when 'LM' then loc_de_munca
									when 'CO' then comanda
									when 'IB' then indicator
									when 'CT' then cont_de_tert
									when 'DD' then convert(varchar(20),data,102)
									when 'DA' then convert(varchar(20),data_scadentei,102)
									else ''
									end),
									
					denumire1=rtrim(case @grupare1
									when 'TE' then denumire --sursa+'|'+tert
									when 'TP' then (case sursa when 'F' then 'Facturi' when 'E' then 'Efecte' when 'S' then 'Stoc' end) --sursa+'|'+tert
									when 'PL' then den_pctlivrare
									when 'GR' then dengtert
									when 'LM' then denlm
									when 'CO' then comanda
									when 'IB' then indicator
									when 'CT' then den_cont
									when 'DD' then convert(varchar(20),data,103)
									when 'DA' then convert(varchar(20),data_scadentei,103)
									else ''
									end),

					grupare2=rtrim(case @grupare2
									when 'TE' then tert --sursa+'|'+tert
									when 'TP' then sursa --sursa+'|'+tert
									when 'PL' then nr_dvi
									when 'GR' then gtert
									when 'LM' then loc_de_munca
									when 'CO' then comanda
									when 'IB' then indicator
									when 'CT' then cont_de_tert
									when 'DD' then convert(varchar(20),data,102)
									when 'DA' then convert(varchar(20),data_scadentei,102)
									else ''
									end),
									
					denumire2=rtrim(case @grupare2
									when 'TE' then denumire --sursa+'|'+tert
									when 'TP' then (case sursa when 'F' then 'Facturi' when 'E' then 'Efecte' when 'S' then 'Stoc' end) --sursa+'|'+tert
									when 'PL' then den_pctlivrare
									when 'GR' then dengtert
									when 'LM' then denlm
									when 'CO' then comanda
									when 'IB' then indicator
									when 'CT' then den_cont
									when 'DD' then convert(varchar(20),data,103)
									when 'DA' then convert(varchar(20),data_scadentei,103)
									else ''
									end)
	
	update #raport set ordonare=
				isnull((case	when @grupare1 in ('DA','DD') then grupare1
						when @ordonare=0 then grupare1
						when @ordonare=1 then
					denumire1
				end)+'|','')+
				isnull((case	when @grupare2 in ('DA','DD') then grupare2
						when @ordonare=0 then grupare2
						when @ordonare=2 then
					denumire2
				end),'')+
				'|'+rtrim(case @ordonare when 0 then tert else denumire end)+
				'|'+rtrim(isnull(partitionareSold,''))+
				('|'+convert(varchar(20), data_facturii,102)+'|'+rtrim(factura))
				+(case when tip='SI' then '1' else '2' end)
				+'|'+convert(varchar(20), data,102)
			
			-- calcul sold cumulat - valuta si lei, la nivel de facturi, pentru fiecare tert:
	create clustered index indrap on #raport(ordonare)
	update #raport set @q_soldcvaluta=(case when @q_partitionareSold=partitionareSold then @q_soldCvaluta
								else 0 end)+
							isnull(soldi_valuta,0)+isnull(total_valuta,0)-
										isnull(achitat_valuta,0),
					sold_cumulat_valuta=@q_soldCvaluta,
					@q_soldClei=(case when @q_partitionareSold=partitionareSold then @q_soldClei
								else 0 end)+
							isnull(soldi,0)+isnull(valoare,0)+
										isnull(tva,0)-isnull(achitat,0),
					sold_cumulat_lei=@q_soldClei,
					@q_partitionareSold=partitionareSold

	if @q_moneda=0	--> in lei:
	insert into #fisa(sursa,
		denumire, oras, furn_benef, subunitate, tert, factura, tip, numar, data,
		soldi, valoare, tva, total, achitat, valuta, curs, loc_de_munca, 
		comanda, cont_de_tert, fel, cont_coresp, explicatii, numar_pozitie,
		gestiune, data_facturii, data_scadentei, nr_dvi, barcod, pozitie, peSold, soldf, sold_cumulat,
		soldi_valuta, valoare_valuta, tva_valuta, total_valuta, achitat_valuta, soldf_valuta, sold_cumulat_valuta,
		ordonare, achitat_efect, indicator, grupare1, denumire1, grupare2, denumire2)
	select sursa,
		denumire, oras, furn_benef, subunitate, tert, factura, tip, rtrim(numar) numar, data,
		soldi, valoare, tva, tva+valoare, achitat, valuta, curs, loc_de_munca, 
		comanda, cont_de_tert, fel, cont_coresp, rtrim(explicatii) explicatii, numar_pozitie,
		gestiune, data_facturii, data_scadentei, nr_dvi, barcod, pozitie, peSold, soldi+tva+valoare-achitat soldf, sold_cumulat_lei,
		0 soldi_valuta, 0 valoare_valuta, 0 tva_valuta, 0 total_valuta, 0 achitat_valuta, 0 soldf_valuta, 0 sold_cumulat_valuta,
		ordonare, achitat_efect, indicator, grupare1, denumire1, grupare2, denumire2
	from #raport
	order by ordonare

	if @q_moneda=1 or @q_moneda=2	-->	in valuta:
	insert into #fisa(sursa,
		denumire, oras, furn_benef, subunitate, tert, factura, tip, numar, data,
		soldi, valoare, tva, total, achitat, valuta, curs, loc_de_munca, 
		comanda, cont_de_tert, fel, cont_coresp, explicatii, numar_pozitie,
		gestiune, data_facturii, data_scadentei, nr_dvi, barcod, pozitie, peSold, soldf, sold_cumulat,
		soldi_valuta, valoare_valuta, tva_valuta, total_valuta, achitat_valuta, soldf_valuta, sold_cumulat_valuta,
		ordonare, achitat_efect, indicator, grupare1, denumire1, grupare2, denumire2)
	select sursa,
		denumire, oras, furn_benef, subunitate, tert, factura, tip, rtrim(numar) numar, data,
		soldi, valoare, tva, tva+valoare, achitat, valuta, curs, loc_de_munca,
		comanda, cont_de_tert, fel, cont_coresp, rtrim(explicatii) explicatii, numar_pozitie,
		gestiune, data_facturii, data_scadentei, nr_dvi, barcod, pozitie, peSold, soldi+tva+valoare-achitat soldf, sold_cumulat_lei sold_cumulat,
		soldi_valuta, total_valuta valoare_valuta, 0 tva_valuta, total_valuta, achitat_valuta, soldi_valuta+total_valuta-achitat_valuta soldf_valuta, sold_cumulat_valuta,
		ordonare, achitat_efect, indicator, grupare1, denumire1, grupare2, denumire2
	from #raport 
	order by ordonare
	
	if exists (select 1 from sys.objects o where name='rapFisaTerti_SP')
	begin
		--select ... for xml raw
		exec rapFisaTerti_SP --@sesiune,@parXML
	end
	
	if exists (select 1 from sys.objects o where name='rapFisaTertiSP')
	begin
		declare @pxml xml
		select @pxml=(select @grupare1 grupare1, @grupare2 grupare2 for xml raw)
		exec rapFisaTertiSP @sesiune=@sesiune, @parXML=@pXML
	end
	
	--> daca procedura e apelata de alte proceduri totul se termina aici, altfel mai trebuie prelucrari pentru rapFisaTerti:
	if @q_deNesters=1 return
		--> ar fi mai corect sa se faca procedura separata pt rapFisaTerti care sa apeleze si ea partea comuna, dar s-ar putea sa complice lucrurile la instalari
	
	select sursa,
		rtrim(f.denumire) denumire, oras, furn_benef, f.subunitate, f.tert, rtrim(factura) factura, tip,
		rtrim(numar) numar, data,
		soldi, valoare, tva, total, achitat, valuta, curs, rtrim(loc_de_munca) loc_de_munca,
		left(comanda,20) comanda, rtrim(cont_de_tert) cont_de_tert, fel, rtrim(cont_coresp) cont_coresp
		, rtrim(explicatii) explicatii,
		numar_pozitie,
		gestiune, data_facturii, data_scadentei, nr_dvi, barcod, pozitie, peSold, soldf, sold_cumulat,
		soldi_valuta, valoare_valuta, tva_valuta, total_valuta, achitat_valuta, soldf_valuta,
		sold_cumulat_valuta, ordonare, f.indicator indicator,
		rtrim(t.grupa) as gtert, rtrim(g.denumire) dengtert, rtrim(l.denumire) as denlm,
		rtrim(t.grupa) as grupa, rtrim(i.descriere) as den_pctlivrare, grupare1, denumire1,
		grupare2, denumire2
	from #fisa f left join terti t on t.subunitate=f.subunitate and f.tert=t.tert
		left join gterti g on t.grupa=g.grupa
		left join lm l on f.loc_de_munca=l.cod
		left join infotert i on i.subunitate=t.subunitate and i.tert=f.tert and i.identificator=f.nr_dvi
	union all -- anulez achitarile cu efecte, daca efectul este pe sold
	select sursa,
		f.denumire, oras, furn_benef, f.subunitate, f.tert, rtrim(factura) factura, tip, rtrim(numar) numar, data,
		soldi, achitat_efect valoare, tva, 0 total, -achitat_efect achitat, valuta, curs, rtrim(loc_de_munca) loc_de_munca,
		left(comanda,20) comanda, rtrim(cont_de_tert) cont_de_tert, fel, rtrim(cont_coresp) cont_coresp,
		rtrim(explicatii) explicatii, numar_pozitie,
		gestiune, data_facturii, data_scadentei, nr_dvi, barcod, pozitie, peSold, achitat_efect soldf, sold_cumulat,
		soldi_valuta, valoare_valuta, tva_valuta, total_valuta, achitat_valuta, soldf_valuta, sold_cumulat_valuta,
		ordonare, f.indicator indicator,
		rtrim(t.grupa) as gtert, rtrim(g.denumire) dengtert, rtrim(l.denumire) as denlm, rtrim(t.grupa) as grupa,
		rtrim(i.descriere) as den_pctlivrare, grupare1, denumire1, grupare2, denumire2
	from #fisa f left join terti t on t.subunitate=f.subunitate and f.tert=t.tert
		left join gterti g on t.grupa=g.grupa
		left join lm l on f.loc_de_munca=l.cod
		left join infotert i on i.subunitate=t.subunitate and i.tert=f.tert and i.identificator=f.nr_dvi
	where (@cuefecte=1 and abs(achitat_efect)>0.001)
	order by ordonare
	
end try
begin catch
	set @q_eroare=ERROR_MESSAGE()+' (rapFisaTerti)'
end catch
	
IF OBJECT_ID('tempdb..#fisa') IS NOT NULL and @q_denesters=0 drop table #fisa
IF OBJECT_ID('tempdb..#fFacturi') IS NOT NULL drop table #fFacturi
IF OBJECT_ID('tempdb..#raport') IS NOT NULL drop table #raport
IF OBJECT_ID('tempdb..#facturiCuGestiuni') IS NOT NULL drop table #facturiCuGestiuni
	--> erorile in reporting nu apar, asa ca se vor returna ca date, urmand ca in raport sa se trateze situatia:
if (@q_eroare<>'')
	select '<EROARE>' as tert, @q_eroare as denumire
end