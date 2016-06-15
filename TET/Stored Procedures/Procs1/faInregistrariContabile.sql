--***
create procedure faInregistrariContabile 
 @dinTabela int =1,@Subunitate char(9)=null, @Tip char(2)=null, @Numar char(40)=null, @Data datetime=null,@dataSus datetime='12/31/2999', @parXML xml = null
as 
/**
	Cele 3 moduri de lucru (tipuri de apel ale procedurii sunt:
		1. Pentru documentele din DocDeContat : parametrul @dinTabela = 1 
			- se vor genera inregistrari contabile pentru toate documentele din DocDeContat.
			- exemplu apel : exec faInregistrariContabile sau exec faInregistrariContabile
		
		2. "Pentru un document" (se vor completa parametri subunitate, tip, numar data) parametrul @dinTabela = 0
			- genul acesta de apel vine din machete (ASiSplus sau ASiSria)
			- exemplu apel : exec faInregistrariContabile @dinTabela=0, @subunitate='1', @tip='RM',@numar='30',@data='01/01/2013'
		
		3. Din refacere : parametrul @dinTabela = 2
			- se bazeaza pe existenta tabelei #DocDeContat si

	Observatii:
		- indiferent de modul de lucru (1, 2 sau 3) procedurile inregDoc si inregPlin se bazeaza pe date din #DocDeContat
		- daca parametrul @data (=@datajos) nu este trimis el este contruit ca fiind prima zi de dupa luna inchisa
		
*/
begin 
	set nocount on
	/*Citire ultima luna inchisa din contabilitate.
		Daca datajos<@datainchiderii atunci datajos o vom pune egala cu datainchiderii
	*/
	declare 
		@data_inchisa datetime, @anbloc int, @lunabloc int, @datajos datetime, @compUrmaPozincon int, @DataInPozCM int, @errmsg varchar(1000)
	
	exec luare_date_par 'GE','LUNABLOC',0,@lunabloc OUTPUT,''
	exec luare_date_par 'GE','ANULBLOC',0,@anbloc OUTPUT,''
	
	select @data_inchisa=CAST(CAST(@anbloc AS varchar) + '-' + CAST(@lunabloc AS varchar) + '-' + CAST('01' AS varchar) AS DATETIME)
	select @data_inchisa=dbo.EOM(@data_inchisa)

	set @datajos=@data
	if @datajos is null or @datajos<=@data_inchisa
		set @datajos=dateadd(day,1,@data_inchisa)

	/* IN cazul in care nu se apeleaza din refacere cream tabela #DocDeContat */
	if @dintabela <> 2
		create table #DocDeContat (subunitate varchar(9), tip varchar(2), numar varchar(40), data datetime)

	/*	IN cazul in care tabela #DocDeContat s-a creat anterior lansarii procedurii, pot fi cazuri in care aceasta contine date multiplicate (acelasi tip, numar, data de mai multe ori). 
		Din acest motiv facem aici o mica corectie a datelor din #DocDeContat. Problema a aparut la ANAR la operatiuni prin 482. */	
	if @dintabela=2
	begin
		if object_id('tempdb..#DocDeContatUnic') is not null drop table #DocDeContatUnic
		select distinct subunitate, tip, numar, data into #DocDeContatUnic
		from #DocDeContat
		
		delete from #DocDeContat
		insert into #DocDeContat (subunitate, tip, numar, data)
		select subunitate, tip, numar, data from #DocDeContatUnic
	end

	/* Conventii de tipuri la apelarea strict pe un document */
	if @dinTabela=0 
	begin
		if @tip in ('DE','RE','EF')
			set @tip='PI'
	end
	else
	begin
		if @dataSus is null
			set @dataSus=convert(datetime,convert(char(10),getdate(),101))
	end
		
	if @dintabela = 1
		/* Modul 1 de lucru : Cazul in care luam tot din DocDeContat */
		insert into #DocDeContat (subunitate, tip, numar, data)
		select
			subunitate, tip, numar, data 
		from DocDeContat where data between @datajos and @datasus and data>@data_inchisa and numar is not null
	else 
	/* Modul 2 de lucru: un singur document */
		if @dintabela = 0
			insert into #DocDeContat (subunitate, tip, numar, data)
			select @subunitate, @tip, @numar, @data
			where @data>@data_inchisa
	/*Modul 3 de lucru este "implicit, cazul dintabela=2 am deja #DocDeContat populat din refacere */

	/*Apel procedura specifica, care permite populare #DocDeContat */
	if exists (select * from sysobjects where name ='faInregistrariContabileSP')	
		exec faInregistrariContabileSP @dinTabela, @Subunitate, @Tip, @Numar, @Data, @dataSus, @parXML

	/*
		Se sterg inregistrarile pentru documentele prevazute (fie ca s-au sters documente, fie ca s-au creat/modificat) 
	*/
	delete p
	from pozincon p
	inner join #DocDeContat dc on dc.subunitate=p.subunitate and dc.tip=p.Tip_document and dc.numar=p.Numar_document and dc.data = p.data
		where p.Data>@data_inchisa
	
	/*	
		Parametru de compatibilitate in urma. Plasa de siguranta doar. 
	*/
	exec luare_date_par 'GE','OLDINCON',@compUrmaPozincon OUTPUT,0,''
	begin try -- daca da eroare la generarea rapida sa stiu ce eroare 
		if @compUrmaPozincon=0 and exists(select 1 from sys.objects where name='InregDoc' and type='P')
			exec InregDoc '',''

		if @compUrmaPozincon=0 and exists(select 1 from sys.objects where name='InregPlin' and type='P')
			exec InregPlin '',''
			
		if @compUrmaPozincon=0 and exists(select 1 from sys.objects where name='InregADoc' and type='P')
			exec InregADoc '',''

		if @compUrmaPozincon=0 and exists(select 1 from sys.objects where name='inregNCon' and type='P')
			exec inregNCon '',''
	
	end try
	BEGIN catch
		set @errmsg=ERROR_MESSAGE()+' (faInregistrariContabile)'
		RAISERROR(@errmsg,16,1)
	end catch

	/*
		Ceea ce a ramas in urma inregDoc, inregPlin, etc. in #DocDeContat (aceste proceduri sterg din #DocDeContat ce reusesc sa faca)
		este tratat mai jos cu cursor si stergerea se face secvential pe masura ce se "rezolva" documente

		Se poate intampla sa fie pe un document si sa nu-l rezolve inreg-urile de mai sus si atunci trebuie conditia de mai jos
	*/

	/*
		In acest punct toate documentele ramase in #DocDeContat (din refaceri sau de pe un document) vor fi scrise in DocDeContat pt. a fi tratate in cursorul de mai jos
			(ex. Receptii cu DVI, MFixuri, etc...)
	*/
	insert into DocDeContat (subunitate, tip, numar,data)
		select dd.subunitate, dd.tip, dd.numar,dd.data 
		from #DocDeContat dd 
		left join DocDeContat dc on dc.subunitate=dd.subunitate and dc.tip=dd.tip and dd.numar=dc.numar and dd.data = dc.data
		where dc.subunitate IS NULL 


	declare @amDate int
	declare @doc table(subunitate varchar(20), tip varchar(2), numar varchar(40), data datetime)

	insert into @doc 
	select d.subunitate,d.tip,d.numar,d.data  
	from DocDeContat d
	LEFT JOIN #DocDeContat dd on dd.subunitate=d.subunitate and dd.tip=d.tip and dd.numar=d.numar and dd.data=d.data
	where 		
		(
			(@dinTabela=0 and d.subunitate=@subunitate and d.tip=@tip and d.numar=@numar and d.data=@data) OR --or @tip='CM' and @DataInPozCM=1 and d.data between dbo.BOM(@data) and dbo.EOM(@data))) OR -- un singur document
			(@dinTabela=1 and d.data<=@dataSus) OR -- toate documentele din Tabela 			
			(@dinTabela=2 and dd.subunitate is not null)-- toate documentele din #DocDeContat =  refaceri
		) 
		and d.data>@data_inchisa 	
		and d.numar is not null

	declare @nrExistente int, @nrExistenteAnterioare int, @nrcount int
	select @nrExistenteAnterioare=-1, @nrExistente=-2
	SET @amDate=1
	while @amDate=1 and @nrExistente<>@nrExistenteAnterioare	--> cu nrExistente se asigura ca bucla nu se repeta la nesfarsit (daca avem de exemplu linii cu numar=null si numar='' in docdecontat)
	begin
		set @amDate=0 --Se va opri daca nu mai sunt documente
		select top 1 @subunitate=subunitate,@tip=tip,@numar=numar,@data=data
		from @doc
		order by subunitate,data,tip,numar
		if @@ROWCOUNT>0 
			set @amDate=1 --Se va opri daca nu mai sunt documente
		if @amDate=1 /* Doar daca am date*/
		begin
			begin try
				if @tip in ('RM','RS') exec inreg_antet_receptii @nr_document=@numar, @dataj=@data, @datas=@data
				if @tip='PP' exec inregPP @dataj=@data, @datas=@data, @nrdoc=@numar
				if @tip='CM' exec inregCM @dataj=@data, @datas=@data, @nrdoc=@numar
				if @tip in ('AP','AS') exec inregAvize @dataj=@data, @datas=@data, @tipdoc=@tip, @nrdoc=@numar
				if @tip='AC' exec inregAC @dataj=@data, @datas=@data, @nrdoc=@numar
				if @tip='TE' exec inregTE @dataj=@data, @datas=@data, @nrdoc=@numar
				if @tip='DF' exec inregDF @dataj=@data, @datas=@data, @nrdoc=@numar
				if @tip='PF' exec inregPF @dataj=@data, @datas=@data, @nrdoc=@numar
				if @tip='CI' exec inregCI @dataj=@data, @datas=@data, @nrdoc=@numar
				if @tip='AF' exec inregAF @dataj=@data, @datas=@data, @nrdoc=@numar
				if @tip='AI' exec inregAI @dataj=@data, @datas=@data, @nrdoc=@numar
				if @tip='AE' exec inregAE @dataj=@data, @datas=@data, @nrdoc=@numar
				if @tip='PI' exec inregPI @dataj=@data, @datas=@data, @ctdoc=@numar
				if @tip in ('CO','C3','FF','FB','CF','CB','IF','SF') exec inregAD @dataj=@data, @datas=@data, @nrdoc=@numar
				if @tip in ('IC','MA','ME','MI','MM','NC','DP','AL','AO','PS','UA') exec inregNC @dataj=@data, @datas=@data, @nrdoc=@numar, @tipdoc=@tip

				delete from @doc
					where @subunitate=subunitate and @tip=tip and @numar=numar and @data=data
				delete from DocDeContat
					where @subunitate=subunitate and @tip=tip and @numar=numar and @data=data
				select @nrExistenteAnterioare=@nrExistente
				select @nrExistente=count(1) from @doc
			end try
			BEGIN catch
				set @amDate=0 --Se va opri dupa prima eroare				
				set @errmsg='Tip:'+@tip+',Numar:'+rtrim(@numar)+',Data:'+convert(varchar(10),@data,103)+'- '+ERROR_MESSAGE()+'(faInregistrariContabile)'
				RAISERROR(@errmsg,16,1)
			end catch
		end
	end

	if  @dinTabela=1 and @nrExistente>0-- and @nrExistente=@nrExistenteAnterioare
		raiserror('Inregistrarile contabile nu au fost generate in intregime (exista informatii eronate in docdecontat)!',16,1)
end 
