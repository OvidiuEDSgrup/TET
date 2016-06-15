--***
create procedure rapFisaDeconturipeSalariati (@sesiune varchar(50)=null,
		@cDatajos datetime=null,
		@cData datetime,
		@grupare varchar(1)='S',	-->S=Salariati, L=Loc de munca, I=Indicator bugetar
		@marca varchar(20)=null,
		@decont varchar(100)=null, @cont varchar(50)=null, @ptrulaj bit=0, @ptfisa bit=0,
		@datajos datetime=null, @datasus datetime=null, @dDataScadJos datetime=null,@dDataScadSus datetime=null,
		@pe_sold bit=1, @plecati int=2, @locm varchar(40)=null,
		@nvaluta bit=0,	--> in valuta: 1= se aduc valorile in valuta
		@valuta varchar(20)=null,	--> functioneaza doar daca @nvaluta=1
		@ordonare varchar(20)=0,		--> 0=marca, 1=denumire
		@doarrulaj bit,
		@indicator varchar(100)=null
		)
as

if object_id('tempdb..#dec') is not null drop table #dec
set transaction isolation level read uncommitted
declare @eroare varchar(2000)
begin try
	if @cData is null and @cDatajos is not null		--> setez limita superioara daca lipseste si daca avem limita inferioare (daca ar fi ambele null inseamna raport la zi, din tabela deconturi)
		set @cData=getdate()
	if @cData is not null and @cDatajos is null select @cDatajos='1/1/1901'	--> setez limita inferioara daca lipseste si nu e raport la zi
	declare @q_sesiune varchar(50), @filtru_locm bit, @utilizator varchar(50)
	select @q_sesiune=@sesiune
	select @filtru_locm=(case when isnull(@locm,'')='' then 0 else 1 end), @locm=@locm+'%',
			@utilizator=dbo.fIaUtilizator(@q_sesiune)
	if len(@utilizator)=0 raiserror('Nu s-a identificat utilizatorul! Raportul "Deconturi pe salariati" nu este configurat corect!',16,1)
	
	create table #dec(marca varchar(20), valoare decimal(20,5), valoare_valuta decimal(20,5), achitat decimal(20,5), achitat_valuta decimal(20,5),
			decont varchar(1000), data datetime, data_scadentei datetime, cont varchar(1000), tip_document varchar(20), numar_document varchar(100),
			explicatii varchar(2000), valuta varchar(200), cont_coresp varchar(1000), nr_ordine int, sold_initial decimal(20,5),
			sold_initial_valuta decimal(20,5), data_decont datetime, curs decimal(20,5), indbug varchar(100),
			locm varchar(1000),
			grupare1 varchar(1000) default '', denumiregrupare1 varchar(4000) default '')
	
	if @cData is null and @cdatajos is null	--> daca se cere la zi, se va lua direct din tabela de deconturi:
	insert into #dec(marca, valoare, valoare_valuta, achitat, achitat_valuta, decont, data, data_scadentei, cont, tip_document, numar_document,
		explicatii, valuta, cont_coresp, nr_ordine, sold_initial, sold_initial_valuta, data_decont, curs, indbug, locm)
	select Marca, valoare, valoare_valuta, decontat, decontat_valuta, Decont, data, data_scadentei, cont, '', '', explicatii, valuta, '', row_number() over (order by ft.data), 0, 0, data, curs, substring(comanda, 21, 20),
			loc_de_munca
	--,Cont, Data, Data_scadentei, Valoare, Valuta, Curs, Valoare_valuta, Decontat, Sold, Decontat_valuta, Sold_valuta, Loc_de_munca, Comanda, Data_ultimei_decontari, Explicatii
	from deconturi ft
		left join LMFiltrare l on l.utilizator=@utilizator and l.cod=ft.loc_de_munca
	where ft.data between isnull(@datajos,'1/1/1901') and isnull(@datasus,'1/1/2999') and
		ft.data_scadentei between isnull(@dDataScadJos,'1/1/1901') and isnull(@dDataScadSus ,'1/1/2999')
		and (@filtru_locm=0 or ft.loc_de_munca like @locm)
		and (dbo.f_areLMFiltru(@utilizator)=0 or l.utilizator=@utilizator)
		and (@nvaluta=0 or len(rtrim(ft.valuta))>0)
		and (@valuta is null or @valuta='' and (len(rtrim(ft.valuta))=0 and @nvaluta=0 or @nvaluta=1) or ft.valuta=@valuta)
		and (@marca is null or ft.marca=@marca)
		and (@decont is null or ft.decont=@decont)
		and (@cont is null or ft.cont=@cont)
		and (@indicator is null or substring(comanda, 21, 20) like @indicator+'%')
	
	else		--> altfel se foloseste pdeconturi:
	begin
		declare @parXML xml
		set @parXML=(select @cdata as datasus, @marca as marca, @decont decont, @ptrulaj ptrulaj, @ptfisa ptfisa, 0 as grmarca, 0 as grdec, @cont as cont, 0 as cen, @indicator as indicator for xml raw)
		create table #docdeconturi (subunitate varchar(9))
		exec CreazaDiezDeconturi @numeTabela='#docdeconturi'
		exec pDeconturi @sesiune=@sesiune, @parxml=@parXML
	
		insert into #dec(marca, valoare, valoare_valuta, achitat, achitat_valuta, decont, data, data_scadentei, cont, tip_document, numar_document, explicatii, valuta, cont_coresp, nr_ordine,
			sold_initial, sold_initial_valuta, data_decont, curs, indbug, locm)
		select ft.marca,
			ft.valoare as valoare,
			ft.valoare_valuta valoare_valuta,
			ft.achitat achitat,
			ft.achitat_valuta achitat_valuta,
			ltrim(rtrim(ft.decont)) as decont, ft.data, ft.data_scadentei, ft.cont,
			ft.tip_document, ft.numar_document, rtrim(ft.explicatii) as explicatii, ft.valuta,
			cont_coresp,
			row_number() over (order by ft.tip_document, ft.numar_document, ft.data) as nr_ordine,
			convert(decimal(20,5),0) sold_initial, convert(decimal(20,5),0) sold_initial_valuta, ft.data,
			ft.curs, ft.indbug, ft.loc_de_munca
		from #docdeconturi ft--dbo.fdeconturi('1901-1-1', @cData, @marca,@decont,@cont,@ptrulaj, @ptfisa, @parXML) ft
			left join LMFiltrare l on l.utilizator=@utilizator and l.cod=ft.loc_de_munca
		where ft.data between isnull(@datajos,'1/1/1901') and isnull(@datasus,'1/1/2999') and
			ft.data_scadentei between isnull(@dDataScadJos,'1/1/1901') and isnull(@dDataScadSus ,'1/1/2999')
			and (@filtru_locm=0 or ft.loc_de_munca like @locm)
			and (dbo.f_areLMFiltru(@utilizator)=0 or l.utilizator=@utilizator)
			and (@nvaluta=0 or len(rtrim(ft.valuta))>0)
			and (@valuta is null or @valuta='' and (len(rtrim(ft.valuta))=0 and @nvaluta=0 or @nvaluta=1) or ft.valuta=@valuta)
		
	end
	
	update d set grupare1=rtrim(case @grupare when 'S' then marca
										 when 'L' then locm
										 when 'I' then d.indbug
							end )
		from #dec d
		
	--> iau denumirile pentru grupare1:
	
		if @grupare='S'
		update d set denumiregrupare1=rtrim(p.nume) from #dec d left join personal p on d.marca=p.marca
		
		if @grupare='L'
		update d set denumiregrupare1=rtrim(lm.denumire) from #dec d left join lm on d.locm=lm.cod

		if @grupare='I'
		update d set denumiregrupare1=rtrim(i.denumire) from #dec d left join indbug i on d.indbug=i.indbug
	
	if isnull(@cDataJos,'1901-1-1')>'1901-1-1'
		begin
			insert into #dec(marca, valoare, valoare_valuta, achitat, achitat_valuta, decont, data, data_scadentei, cont, tip_document, numar_document, explicatii, valuta,
				cont_coresp, nr_ordine, sold_initial, sold_initial_valuta, data_decont, curs, indbug, locm, grupare1, denumiregrupare1)
			select max(d.marca), 0, 0, 0, 0, d.decont, @cDataJos, max(d.data_scadentei), '', 'SI', '','Sold initial', max(d.valuta), '', max(nr_ordine),
				sum(d.valoare)-sum(d.achitat), sum(d.valoare_valuta)-sum(d.achitat_valuta), min(d.data_decont),
				(case when sum(d.valoare_valuta)=0 then 0 else sum(d.valoare)/sum(d.valoare_valuta) end), max(indbug) indbug
				,max(d.locm), grupare1, max(denumiregrupare1)
			from #dec d where d.data<@cDataJos
			group by d.grupare1, d.decont
			
			delete d from #dec d where d.data<@cDataJos
		end

	select p.nume,--ft.* 
		ft.marca, ft.valoare, ft.valoare_valuta, ft.achitat, ft.achitat_valuta, ft.decont, ft.data, ft.data_scadentei, ft.cont,
		ft.tip_document, ft.numar_document, ft.explicatii, ft.valuta,
		ft.cont_coresp,
		nr_ordine,
		sold_initial, sold_initial_valuta, ft.data_decont, ft.curs, ft.indbug,
		grupare1, denumiregrupare1
	from #dec ft
		inner join (select marca,decont,sum(sold_initial+valoare-achitat) as sold,
							sum(sold_initial_valuta+valoare_valuta-achitat_valuta) as sold_valuta,
							(case when sum(abs(valoare)+abs(achitat))>0.001 then 1 else 0 end) as cu_rulaj
					from #dec
					group by decont,marca) as k on k.marca=ft.marca and k.decont=ft.decont
		left outer join personal p on ft.marca=p.marca
	where (@pe_sold=0 or abs(isnull(k.sold,0))>0.009) and  ((@plecati=1 and loc_ramas_vacant=1
				and p.Data_plec<=@datasus and p.Data_plec<>'1901-01-01' and Data_plec<>'1900-01-01')
				or (@plecati=0 and p.loc_ramas_vacant=0) or @plecati=2)
			and (@doarrulaj=0 or cu_rulaj=1)
	order by
		(case when @ordonare=0 then ft.grupare1 else ft.denumiregrupare1 end),
		(case when @grupare<>'S' then '' else ft.data_decont end),	--> acest criteriu era plasat in fata dar strica ordonarea specificata prin @ordonare; daca se muta inapoi in fata ar fi de apreciat un comentariu explicativ...
		ft.decont, ft.data,
		nr_ordine

	drop table #dec
end try
begin catch
	select @eroare=ERROR_MESSAGE()+' (rapFisaDeconturipeSalariati)'
end catch
	if object_id('tempdb..#dec') is not null drop table #dec
if len(@eroare)>0 --raiserror(@eroare,16,1)
	select @eroare as denumiregrupare1, '<EROARE>' as grupare1
