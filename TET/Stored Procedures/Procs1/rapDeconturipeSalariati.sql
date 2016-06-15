--***
create procedure rapDeconturipeSalariati (@sesiune varchar(50)=null, @cData datetime,@marca varchar(20)=null,
		@decont varchar(100)=null, @cont varchar(50)=null, @ptrulaj bit=0, @ptfisa bit=0,
		@datajos datetime, @datasus datetime, @dDataScadJos datetime,@dDataScadSus datetime,
		@pe_sold bit=1, @plecati int=2, @locm varchar(40)=null,
		@nvaluta bit=0,	--> in valuta: 1= se aduc valorile in valuta
		@valuta varchar(20)=null,	--> functioneaza doar daca @nvaluta=1
		@ordonare varchar(20)=0		--> 0=marca, 1=denumire
		)
as
begin
if object_id('tempdb..#dec') is not null drop table #dec
if object_id('tempdb..#docdeconturi') is not null drop table #docdeconturi
set transaction isolation level read uncommitted
declare @eroare varchar(2000)
begin try
	declare @q_sesiune varchar(50), @filtru_locm bit, @utilizator varchar(50), @parXML xml
	select @q_sesiune=@sesiune
	select @filtru_locm=(case when isnull(@locm,'')='' then 0 else 1 end), @locm=@locm+'%',
			@utilizator=dbo.fIaUtilizator(@q_sesiune)
	if len(@utilizator)=0 raiserror('Nu s-a identificat utilizatorul! Raportul "Deconturi pe salariati" nu este configurat corect!',16,1)

	set @parXML=(select @cData as datasus, @marca as marca, @decont as decont, @cont as cont, @ptrulaj as ptrulaj, @ptfisa as ptfisa for xml raw)
	create table #docdeconturi (subunitate varchar(9))
	exec CreazaDiezDeconturi @numeTabela='#docdeconturi'
	exec pDeconturi @sesiune=@sesiune, @parxml=@parXML

	select ft.marca, (case when @nvaluta=1 and @valuta<>'' then ft.valoare_valuta else ft.valoare end) as valoare,
		(case when @nvaluta=1 then ft.achitat_valuta else ft.achitat end) achitat, ltrim(rtrim(ft.decont)) as decont, ft.data, ft.data_scadentei, ft.cont,
		ft.tip_document, ft.numar_document, ft.explicatii as explicatii, ft.valuta,
		ft.cont_coresp, ft.loc_de_munca, ft.comanda, ft.cantitate, ft.debit_credit, 
		row_number() over (order by ft.tip_document, ft.numar_document, ft.data) as nr_ordine
	into #dec
	from #docdeconturi ft
	--from dbo.fdeconturi('1/1/1901', @cData, @marca,@decont,@cont,@ptrulaj, @ptfisa, @parXML) ft
		left join LMFiltrare l on l.utilizator=@utilizator and l.cod=ft.loc_de_munca
	where ft.data between isnull(@datajos,'1/1/1901') and isnull(@datasus,'1/1/2999') and
		ft.data_scadentei between isnull(@dDataScadJos,'1/1/1901')
		and isnull(@dDataScadSus ,'1/1/2999')
		and (@filtru_locm=0 or ft.loc_de_munca like @locm)
		and (dbo.f_areLMFiltru(@utilizator)=0 or l.utilizator=@utilizator)
		and (@nvaluta=0 or @valuta is null and len(rtrim(ft.valuta))>0 or ft.valuta=@valuta)

	select p.nume,--ft.* 
		ft.marca, ft.valoare, ft.achitat, ft.decont, ft.data, ft.data_scadentei, ft.cont,
		ft.tip_document, ft.numar_document, ft.explicatii, ft.valuta,
		ft.cont_coresp, ft.loc_de_munca, ft.comanda, ft.cantitate, ft.debit_credit, 
		nr_ordine
	from #dec ft
		inner join (select marca,decont,sum(valoare-achitat) as sold from #dec
					group by decont,marca) as k on k.marca=ft.marca and k.decont=ft.decont
		left outer join personal p on ft.marca=p.marca
	where (@pe_sold=0 or abs(isnull(k.sold,0))>0.009) and  ((@plecati=1 and loc_ramas_vacant=1
				and Data_plec<=@datasus and Data_plec<>'1901-01-01' and Data_plec<>'1900-01-01')
				or (@plecati=0 and loc_ramas_vacant=0) or @plecati=2)
	order by
		(case when @ordonare=0 then p.marca else p.nume end),
		ft.decont, ft.data,
		nr_ordine

	drop table #dec
end try
begin catch
	select @eroare=ERROR_MESSAGE()+' (rapDeconturipeSalariati '
						+convert(varchar(20),ERROR_LINE())+')'
end catch
	if object_id('tempdb..#dec') is not null drop table #dec
	if object_id('tempdb..#docdeconturi') is not null drop table #docdeconturi
	if len(@eroare)>0 raiserror(@eroare,16,1)
end
