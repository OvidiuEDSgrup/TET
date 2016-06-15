--***
create procedure rapBalantaTerti (@sesiune varchar(50)=null, @datajos datetime,@datasus datetime
		,@tip varchar(1)='F'	-->	F=furnizor, B=beneficiar
		,@tipdoc varchar(1)='F'	--> F=Facturi, E=Efecte, X=Ambele
		,@ordonare varchar(1)=0	-->	0=Terti (cod), 1=Denumire
		,@compensari varchar(1)=1	-->	1=Da, 0=Nu
		,@centralizare varchar(1)=1	-->	0=Terti, 1=Detalii
		,@doar_facturi_pe_sold varchar(1)=0	-->	0=Nu, 1=Da
		,@valuta varchar(20)=null
		,@cont varchar(40)='',@tert varchar(40)=null, @locm varchar(20)=null	--> filtre
		,@compensari_acelasi_cont bit=0	--> daca sa includa compensarile prin acelasi cont
		)
as 
begin
	declare @tipef varchar(1), @epsilon float, @detTVA int, @semn_sold int, @dataMinSold datetime, @subunitate varchar(20), 
		@parXML xml, @parXMLFact xml
	select @tipef=(case when @tip='F' then 'P' else 'I' end)
			,@epsilon=0.001 ,@detTVA=1 ,@semn_sold=(case when @tip='B' then 1 else -1 end)
			,@dataMinSold='1901-1-1'
			,@subunitate=isnull((select max(rtrim(val_alfanumerica)) from par where parametru='subpro' and tip_parametru='GE'),'1')
			,@parXML=(select @sesiune sesiune for xml raw)
	/* Am scos cele de mai jos pentru ca fFacturi aduce datele filtrate in functie de setare, nu este nevoie sa se trateze aici
	declare @locm_stil_vechi varchar(20)
	select @locm_stil_vechi='%'
	if exists (select 1 from par where Tip_parametru='GE' and Parametru='FLTTRTLM' and Val_logica=1) 
		select @locm_stil_vechi=isnull(@locm,'')+'%'
	*/
	set transaction isolation level read uncommitted
	if @valuta='' raiserror('Valuta trebuie completata!',16,1)
	
	IF OBJECT_ID('tempdb..#fFacturi') IS NOT NULL drop table #fFacturi	/**	un pic de curatenie, in cazul in care ar fi ramas de alta data tabelele*/
	IF OBJECT_ID('tempdb..#final') IS NOT NULL drop table #final

/**1.	Se citesc datele in tabela intermediara #fFacturi pentru a fi mai usor de impartit pe solduri si rulaje:	*/
	/* se preiau datele in tabela #docfacturi prin procedura pFacturi (in locul functiei fFacturi) */
	if object_id('tempdb..#docfacturi') is not null drop table #docfacturi
	create table #docfacturi (furn_benef char(1))
	exec CreazaDiezFacturi @numeTabela='#docfacturi'
	set @parXMLFact=(select @tip as furnbenef, convert(char(10),@datajos,101) as datajos, convert(char(10),@datasus,101) as datasus, 
		rtrim(@tert) as tert, rtrim(@cont) as contfactura, rtrim(@locm) as locm for xml raw)
	exec pFacturi @sesiune=@sesiune, @parXML=@parXMLFact

	select 'F' sursa, p.tert, --p.valoare+p.tva-p.achitat as suma, 
		(case when (left(p.tip,1)<>'C' or p.tip in ('CO','C3')) and p.tip not in ('PS','IS') then p.valoare else -p.achitat end) as rulaj_credit, 
		(case when (left(p.tip,1)<>'C' or p.tip in ('CO','C3')) and p.tip not in ('PS','IS') then p.achitat else -p.valoare end) as rulaj_debit,
		(case when left(p.tip,1)<>'C' or tip in ('CO','C3') then p.tva else 0 end) as rulaj_credit_tva, 
		(case when left(p.tip,1)<>'C' or tip in ('CO','C3') then 0 else -p.tva end) as rulaj_debit_tva,
		p.factura numar, p.data_facturii data, p.data data_doc, c.tip_cont, p.cont_de_tert, p.cont_coresp, 
		(case when (left(p.tip,1)<>'C' or p.tip in ('CO','C3')) and p.tip not in ('PS','IS') then p.total_valuta else -p.achitat_valuta end) as rulaj_credit_valuta,	--> valuta
		(case when (left(p.tip,1)<>'C' or p.tip in ('CO','C3')) and p.tip not in ('PS','IS') then p.achitat_valuta else -p.total_valuta end) as rulaj_debit_valuta
		--,p.achitat_valuta, p.total_valuta
	into #fFacturi
	from #docfacturi p  
	--from dbo.fFacturi (@tip, @datajos, @datasus, @tert, '%', @cont, 0, 0, 0, @locm, @parXML) p  
		left join conturi c on c.Cont=p.cont_de_tert
	where (@tert is null or tert=@tert)
		and (@tipdoc='X' or @tipdoc='F') and (@compensari=1 or p.cont_de_tert<>p.cont_coresp) --and (@locm_stil_vechi='%' or p.loc_de_munca like @locm_stil_vechi)
		and (@valuta is null or p.valuta=@valuta)
		and (@compensari_acelasi_cont=1 or not (p.valuta='' and p.tip in ('CF','FX','CB','BX') and p.cont_de_tert=p.cont_coresp))
	union all
	select 'E' sursa, p.tert, p.valoare as rulaj_credit, p.achitat as rulaj_debit,0,0, p.efect numar, p.data, p.data, c.tip_cont,p.cont,p.cont_corespondent,
		p.valoare_valuta rulaj_credit_valuta, p.achitat_valuta rulaj_credit_valuta
	from fEfecte(@dataMinSold, @datasus, @tipef, @tert,null,@cont,@locm,'', @parxml) p inner join conturi c on c.Cont=p.cont
	where (@tert is null or tert=@tert)
		and (@tipdoc='X' or @tipdoc='E') and (@compensari=1 or p.cont<>p.cont_corespondent)
		and (@valuta is null or p.valuta=@valuta)
	
	if (@valuta is not null)	--> pentru valuta sa apara valorile in valuta
	update #fFacturi set rulaj_credit=rulaj_credit_valuta, rulaj_debit=rulaj_debit_valuta, rulaj_credit_tva=0, rulaj_debit_tva=0
/**2.	Se organizeaza datele astfel incat sa se poata afisa in raport:	*/
	select ltrim(max(sursa)) sursa,max(numar) as numar, sum(p.sold_initial) sold_initial,
				sum(rulaj_debit) rulaj_debit, sum(rulaj_credit) rulaj_credit
				,p.tert ,max(t.Denumire) Denumire, min(p.data) as data, p.cont_de_tert,
			max(p.tip_cont)
			tip_cont, (case when @ordonare<>1 then p.tert else max(t.denumire) end) as ordonare
	into #final
	from
		(
	/**	sold */
		select sursa, p.numar, p.tert, sum(p.rulaj_credit-p.rulaj_debit+p.rulaj_credit_tva-p.rulaj_debit_tva)
				as sold_initial,
				0 rulaj_debit,0 rulaj_credit
				,p.data,p.cont_de_tert,max(p.tip_cont) tip_cont
			from #fFacturi p
			where p.data_doc<@datajos
		group by sursa, p.tert, p.numar, p.data, p.cont_de_tert	/**	Soldurile initiale	*/
		union all
		select p.sursa sursa, p.numar,  p.tert, 0 as sold_initial, 
			sum(rulaj_debit+(case when @detTVA=0 then rulaj_debit_tva else 0 end)) rulaj_debit,
			sum(rulaj_credit+(case when @detTVA=0 then rulaj_credit_tva else 0 end)) rulaj_credit
				,p.data, p.cont_de_tert,max(p.tip_cont) tip_cont
			from #fFacturi p
			where p.data_doc>=@datajos
			group by sursa, p.tert, p.numar, p.data, p.cont_de_tert
	/**	rulaje	*/
		union all
		select p.sursa sursa, p.numar,  p.tert, 0 as sold_initial, 
	sum(rulaj_debit_tva) rulaj_debit, 
	sum(rulaj_credit_tva) as rulaj_credit
				, p.data, p.cont_de_tert,max(p.tip_cont) tip_cont
			from #fFacturi p
			where p.data_doc>=@datajos and @detTVA=1
			group by sursa, p.tert, p.numar, p.data, p.cont_de_tert
		) p
	left join terti t on t.Tert=p.tert and t.Subunitate=@subunitate
	where abs(sold_initial)>@epsilon or abs(rulaj_debit)>@epsilon or abs(rulaj_credit)>@epsilon
	group by p.tert,numar, p.cont_de_tert--,(case when @centralizare=1 then data else '' end)
	order by min(p.data), max(p.numar)
/**3.	Se trimit datele catre raport, aplicandu-se filtre finale	*/
	select max(sursa) sursa, max(numar) numar, 
			max(tip_cont) tip_cont,
			@semn_sold*sum(case tip_cont when 'A' then sold_initial when 'P' then 0 when 'B' then (case when sold_initial>0 then sold_initial else 0 end) end) si_debit,
			-@semn_sold*sum(case tip_cont when 'P' then sold_initial when 'A' then 0 when 'B' then (case when sold_initial<0 then sold_initial else 0 end) end) si_credit,
			(case when @tip='F' then sum(rulaj_debit) else sum(rulaj_credit) end) rulaj_debit,
			(case when @tip='B' then sum(rulaj_debit) else sum(rulaj_credit) end) rulaj_credit,
			max(tert) tert, max(Denumire) Denumire, max(data) data, cont_de_tert cont from #final
			where @doar_facturi_pe_sold=0 or 
				@doar_facturi_pe_sold=1 and (ABS(rulaj_debit-rulaj_credit)>@epsilon and abs(sold_initial-(rulaj_debit-rulaj_credit))>@epsilon or ABS(rulaj_debit-rulaj_credit)<@epsilon and abs(sold_initial)>@epsilon)
	group by tert,cont_de_tert, (case when @centralizare=1 then numar else '' end)
	having (abs(sum(sold_initial))>@epsilon or abs(sum(rulaj_debit))>@epsilon or abs(sum(rulaj_credit))>@epsilon)
	order by max(ordonare),data,numar
	
	IF OBJECT_ID('tempdb..#fFacturi') IS NOT NULL drop table #fFacturi
	IF OBJECT_ID('tempdb..#final') IS NOT NULL drop table #final
end
