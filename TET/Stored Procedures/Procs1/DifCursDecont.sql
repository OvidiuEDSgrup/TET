--***
create procedure DifCursDecont @paridentdoc char(5),@parmarca char(6),@parvaluta char(3),@parcontdecont varchar(40),@data datetime,@generare bit,@sterg bit
--@aninchis int,@lunainchisa int
as

if (dbo.f_arelmfiltru(dbo.fIaUtilizator(null))=1)
begin
		raiserror('Accesul este restrictionat pe anumite locuri de munca! Nu este permisa operatia in aceste conditii!',16,1)
		return
end

declare @mesaj varchar(200)
if exists(select * from sys.objects where type='P' and name='DifCursDecont_SP')
begin
	exec DifCursDecont_SP @paridentdoc,@parmarca,@parvaluta,@parcontdecont,@data,@generare,@sterg
	return
end
declare @subunitate char(13),@contcheltben varchar(40),@contvenben varchar(40),@user char(10),@maxpoz765 int,@maxpoz665 int,@cmaxnumar varchar(10),@maxnumar int,@parXML xml

set @subunitate=isnull((select max(val_alfanumerica) from par where tip_parametru='GE' and parametru='SUBPRO'), '')
set @contcheltben=isnull((select max(val_alfanumerica) from par where tip_parametru='GE' and parametru='DIFCHB'), '')
set @contvenben=isnull((select max(val_alfanumerica) from par where tip_parametru='GE' and parametru='DIFVEB'), '')
set @user = isnull(dbo.fIaUtilizator(null),'')
set @data=dbo.EOM(@data)
if isnull(@paridentdoc,'')='' set @paridentdoc='DIFCD'

if @sterg=1
begin
	delete from pozplin 
	where  subunitate=@subunitate and plata_incasare in ('PD', 'ID') and data=@data and numar like rtrim(@paridentdoc)+'%'  
	and (isnull(@parmarca,'')='' or marca=@parmarca) and (ISNULL(@parvaluta,'')='' or valuta=@parvaluta) 
	and (isnull(@parcontdecont,'')='' or cont=@parcontdecont) 
end
if @generare=1
begin
	if @parmarca is null
		set @parmarca=''
	if @parcontdecont is null
		set @parcontdecont=''		

--	iau numarul maxim deja generat (pt. cazurile in care se ruleaza operatia cu filtre) pentru a putea numerota la rand numerele de document
	select @maxpoz765=isnull(max(numar_pozitie),0) from pozplin where Data=@data and Cont=@contvenben and numar like rtrim(@paridentdoc)+'%'  
	select @maxpoz665=isnull(max(numar_pozitie),0) from pozplin where Data=@data and Cont=@contcheltben and numar like rtrim(@paridentdoc)+'%'  
	select @cmaxnumar=isnull(max(numar),'') from pozplin where Data=@data and numar like rtrim(@paridentdoc)+'%'  
	set @maxnumar=isnull(convert(int,substring(@cmaxnumar,len(rtrim(@paridentdoc))+1,10)),0)

	if OBJECT_ID('tempdb..#Difdecont') is not null drop table #Difdecont
	if OBJECT_ID('tempdb..#doc_inserate') is not null drop TABLE #doc_inserate
	if OBJECT_ID('tempdb..#pdeconturi') is not null drop table #pdeconturi
	create table #doc_inserate(numar varchar(40))

	set @parXML=(select @data as datasus, @parmarca as marca, 1 as grmarca, 1 as grdec, @parcontdecont as cont, 1 as cen for xml raw)
	create table #pdeconturi (subunitate varchar(9))
	exec CreazaDiezDeconturi @numeTabela='#pdeconturi'
	exec pDeconturi @sesiune=null, @parxml=@parXML
	
	select a.decont,a.data,a.data_scadentei,a.marca,a.cont,a.valuta,a.curs as curs_decont,a.sold_valuta,a.sold,a.loc_de_munca,b.curs as curs_la_data, 
		rtrim(@paridentdoc)+replace(str(@maxnumar+dense_rank() over (order by marca),3),' ','0') as numar, 
		(case when a.Sold_valuta*(b.curs-a.curs)<0 then @maxpoz665 else @maxpoz765 end)
			+row_number() over (partition by (case when a.Sold_valuta*(b.curs-a.curs)<0 then 1 else 2 end) order by marca, decont, data) as numar_pozitie
	into #Difdecont
	from #pdeconturi a
	--from dbo.fDeconturiCen(null, @data, @parmarca, '', 1, 1, @parcontdecont, 0, 0) a
	left outer join (select valuta,(select top 1 curs from curs where data<=@data and curs.valuta=valuta.valuta order by DATA desc) as curs from valuta where valuta<>'') b on b.Valuta=a.Valuta
	where a.valuta<>'' and abs(a.sold_valuta)>=0.01 and abs(b.curs*a.sold_valuta-a.sold)>0.01
	and (ISNULL(@parvaluta,'')='' or a.valuta=@parvaluta) 
	order by a.marca,a.data,a.decont

	insert into pozplin (Subunitate,Cont,Data,Numar,Plata_incasare,Tert,Factura,Cont_corespondent,Suma,Valuta,Curs,Suma_valuta,Curs_la_valuta_facturii,
	TVA11,TVA22,Explicatii,Loc_de_munca,Comanda,Utilizator,Data_operarii,Ora_operarii,Numar_pozitie,Cont_dif,Suma_dif,Achit_fact,Jurnal,detalii,tip_tva,marca,decont)
	OUTPUT inserted.Cont
	into #doc_inserate(numar) 
	select @subunitate,(case when Sold_valuta*(curs_la_data-curs_decont)<0 then @contcheltben else @contvenben end),@data,
	a.numar,(case when Sold_valuta*(curs_la_data-curs_decont)<0  then 'ID' else 'PD' end),
	'','',a.cont,(case when Sold_valuta*(curs_la_data-curs_decont)<0 then -1 else 1 end)*round(a.curs_la_data*Sold_valuta-sold,2),
	a.Valuta,a.curs_la_data,0,0,0,0,'Dif. curs decont '+rTrim (a.Decont),'','',@user,convert(datetime, convert(char(10), getdate(), 104), 104),
	RTrim(replace(convert(char(8), getdate(), 108), ':', '')),/*ROW_NUMBER() over (partition by a.marca order by a.decont)*/a.numar_pozitie,
	'',0,0,'',(select (case when a.Data_scadentei<>'01/01/1901' then convert(varchar(10),a.Data_scadentei,101) end) as datascad for xml raw),0 as tip_tva,a.marca,a.Decont
	from #Difdecont a
	where abs(a.sold_valuta)>0.01 and abs(a.curs_la_data*a.sold_valuta-a.sold)>0.01		

	if object_id('tempdb..#DocDeContat') is not null
		drop table #DocDeContat
	else
		create table #DocDeContat (subunitate varchar(9), tip varchar(2), numar varchar(40), data datetime)

	insert into #DocDeContat (subunitate, tip, numar, data)
	select @subunitate, 'PI', numar, @data
	from #doc_inserate

	exec fainregistraricontabile @dinTabela=2

	if OBJECT_ID('tempdb..#Difdecont') is not null drop table #Difdecont
	if OBJECT_ID('tempdb..#DocDeContat') is not null drop table #DocDeContat
	if OBJECT_ID('tempdb..#doc_inserate') is not null drop TABLE #doc_inserate
	if OBJECT_ID('tempdb..#pdeconturi') is not null drop table #pdeconturi
end
	
