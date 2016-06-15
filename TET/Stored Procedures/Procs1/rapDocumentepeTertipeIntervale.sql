---***
create procedure rapDocumentepeTertipeIntervale @sesiune varchar(50) =null,
	@zile varchar(100), @cData datetime, @cFurnBenef varchar(1), @cTert varchar(100)=null, @cFactura varchar(100)=null, @cContTert varchar(100)=null,
	@Soldmin decimal(15,5)=1, @semnsold varchar(1)=0, --> daca 0 soldmin se aplica pe valoarea absoluta
	@aviz_nefac varchar(1)='0',	--> exceptie avize nefacturate (doar pentru beneficiari); 0=nu, 1=da
	@detaliat varchar(1)='0',
	@ordonare varchar(1)='0'	--> 0= den tert, 1=cod tert
as
begin

if object_id('tempdb..#tmp') is not null drop table #tmp
if object_id('tempdb..#intervale') is not null drop table #intervale

declare @eroare varchar(4000)
select @eroare=''
begin try
	declare @q_zile varchar(200), @parXML xml, @parXMLFact xml
	select @parXML=(select @sesiune as sesiune for xml raw)
	set @q_zile=@zile
	set @q_zile='0,'+@q_zile+',100000,'	-- ma asigur ca acopar toate facturile
	create table #intervale(TipInterval int,start int,sfarsit int)
	declare @zi_prec int,@nr_char varchar(10),@tipinterval1 int		set @zi_prec=-100000 set @tipinterval1=-2

	while (@q_zile<>'')
	begin
		set @nr_char=substring(@q_zile,1,charindex(',',@q_zile)-1)
		if (isnumeric(@nr_char)<>0)
		begin
			set @tipinterval1=@tipinterval1+1
			insert into #intervale select @tipinterval1,@zi_prec,@nr_char-1
			set @zi_prec=@nr_char
		end
		set @q_zile=substring(@q_zile,charindex(',',@q_zile)+1,len(@q_zile))
	end

	update #intervale set tipinterval=1000 where tipinterval=@tipinterval1

	/* se preiau datele in tabela #docfacturi prin procedura pFacturi (in locul functiei fFacturi) */
	if object_id('tempdb..#docfacturi') is not null drop table #docfacturi
	create table #docfacturi (furn_benef char(1))
	exec CreazaDiezFacturi @numeTabela='#docfacturi'
	set @parXMLFact=(select @cFurnBenef as furnbenef, convert(char(10),@cData,101) as datasus, rtrim(@cTert) as tert, rtrim(@cFactura) as factura, rtrim(@cContTert) as contfactura, 
		@Soldmin as soldmin, @semnsold as semnsold for xml raw)
	exec pFacturi @sesiune=@sesiune, @parXML=@parXMLFact

	select datediff(day,f.data_scadentei,@cData) as za,
	max(i.TipInterval) as TipInterval,max(i.start) as start,max(i.sfarsit) as sfarsit,
	ft.factura,f.data as data_facturii,f.data_scadentei,
	ft.tert,max(t.denumire) as denumire,sum(ft.valoare+ft.tva) as total,sum(ft.achitat) as achitat,max(ft.loc_de_munca) as loc_de_munca into #tmp
	from #docfacturi ft 
	--from dbo.fFacturi(@cFurnBenef,'01/01/1921',@cData,@cTert,@cFactura,@cContTert,@Soldmin,@semnsold,null, null, @parXML)  ft 
	left outer join terti t on ft.tert=t.tert and ft.subunitate=t.subunitate
	left outer join facturi f on f.tip=(case when @cFurnBenef='F' then 0x54 else 0x46 end) and f.tert=ft.tert and f.factura=ft.factura and f.subunitate=ft.subunitate
	left join #intervale i on datediff(day,isnull(f.data_scadentei,'1901-1-1'),@cData) between start and sfarsit
	where @aviz_nefac=0 or rtrim(isnull(ft.factura,''))<>''
	group by ft.tert,t.tert,ft.factura,f.factura,f.data,f.data_scadentei
	order by (case when @ordonare=0 then max(t.denumire) else ft.tert end)

	select za, TipInterval, start, sfarsit, factura, data_facturii, data_scadentei, tert, denumire, total as valoare, 'Valoare' as coloana,'' as observatii from #tmp where @detaliat=1 union all
	select za, TipInterval, start, sfarsit, factura, data_facturii, data_scadentei, tert, denumire, achitat , 'Achitat','' from #tmp where @detaliat=1 union all
	select za, TipInterval, start, sfarsit, factura, data_facturii, data_scadentei, tert, denumire, total-achitat , 'Sold','' from #tmp 

	union all
	select max(za), 1001, max(start), max(sfarsit), max(factura), max(data_facturii), max(data_scadentei), tert, max(denumire), sum(total), 'Valoare','' from #tmp where @detaliat=1
	group by tert,factura union all
	select max(za), 1001, max(start), max(sfarsit), max(factura), max(data_facturii), max(data_scadentei), tert, max(denumire), sum(achitat), 'Achitat','' from #tmp where @detaliat=1
	group by tert,factura union all
	select max(za), 1001, max(start), max(sfarsit), max(factura), max(data_facturii), max(data_scadentei), tert, max(#tmp.denumire), sum(total-achitat), 'Sold',max(lm.denumire) from #tmp
	left join lm on #tmp.loc_de_munca=lm.cod
	group by tert,factura
end try
begin catch
	select @eroare=ERROR_MESSAGE()+'(rapDocumentepeTertipeIntervale '+convert(varchar(20),ERROR_LINE())+')'
end catch

if object_id('tempdb..#tmp') is not null drop table #tmp
if object_id('tempdb..#intervale') is not null drop table #intervale

if len(@eroare)>0 raiserror(@eroare,16,1)
end
