--***
create procedure wIaVerificareContabilitate @sesiune varchar(50), @parXML XML    
as   
if exists (select 1 from sysobjects where [type]='P' and [name]='wIaVerificareContabilitateSP')
begin 
	declare @returnValue int -- variabila salveaza return value de la procedura specifica
	exec @returnValue = wIaVerificareContabilitateSP @sesiune, @parXML output
	return @returnValue
end 
-- exec wIaVerificareContabilitate @sesiune='', @parXML='<row tip="TD" datajos="2014-04-01" datasus="2014-04-30" />'
begin try
	declare @sub varchar(9),@utilizator varchar(20),@tip varchar(2),@data_jos datetime, @data_sus datetime,
		@_refresh int,@filtruNrDoc varchar(30),@filtruContDebit varchar(4),@filtruContCredit varchar(40),
		@filtrucod varchar(100),@filtrugest varchar(13),@mesajeroare varchar(500),@dateInitializare XML,@dincgplus int,
		@filtruCont varchar(40),@CorelatiiPeContNeAtribuit int,@CorelatiiPeContAtribuit int
		
	--exec luare_date_par 'GE', 'SUBPRO', 0,0,@sub output  
	exec wIaUtilizator @sesiune=@sesiune, @utilizator=@utilizator output  	
	select @tip = isnull(@parXML.value('(/row/@tip)[1]','varchar(3)'),''),
		@data_jos = isnull(@parXML.value('(/row/@datajos)[1]','datetime'),'1901-01-01'),
		@data_sus = isnull(@parXML.value('(/row/@datasus)[1]','datetime'),'2099-01-01'),
		@_refresh = isnull(@parXML.value('(/row/@_refresh)[1]','int'),1),
		@filtruNrDoc = isnull(@parXML.value('(/row/@filtruNrDoc)[1]','varchar(30)'),''),
		@filtruContDebit = @parXML.value('(/row/@filtruContDebit)[1]','varchar(40)'),
		@filtruContCredit = isnull(@parXML.value('(/row/@filtruContCredit)[1]','varchar(40)'),''),
		@filtruCont = isnull(@parXML.value('(/row/@filtruCont)[1]','varchar(40)'), ''),
		@dincgplus = isnull(@parXML.value('(/row/@dincgplus)[1]','int'),0),
		@CorelatiiPeContNeAtribuit = isnull(@parXML.value('(/row/@contneatribuit)[1]','int'),0)
		
	set @CorelatiiPeContAtribuit=(case when @CorelatiiPeContNeAtribuit=1 then 0 else 1 end)

	if @_refresh=0
	begin
		set @dateInitializare=(select convert(char(10),@data_jos,101) as datajos, convert(char(10),@data_sus,101) as datasus--, 1 as corelatiiPeContAtribuit
				for xml raw)

		SELECT 'Populare necorelatii' nume, 'VC' codmeniu, 'D' tipmacheta,@tip tip,'PN' subtip,'O' fel,
				(SELECT @dateInitializare ) dateInitializare
			FOR XML RAW('deschideMacheta'), ROOT('Mesaje')
	end
	--select @tip, @data_jos, @data_sus, @utilizator--, @corelatiiPeContAtribuit, @filtruCont
	--if not exists(select 1 from necorelatii where tip_necorelatii=@tip and utilizator=@utilizator) or @dincgplus=1	
	--	exec populareNecorelatii @Data_jos=@data_jos, @Data_sus=@data_sus,@PretAm=0,@Tip_necorelatii=@tip,@InUM2=0,@FiltruCont='',
	--		@FiltruGest=null,@FiltruCod_intrare=null,@FiltruGrupa=null,@TipStoc=null,@FiltruCod=null,@FiltruLM=null,@FiltruComanda=null,
	--		@FiltruFurn=null,@FiltruLot=null,@FiltruLocatie=null,@CorelatiiPeContAtribuit=@CorelatiiPeContAtribuit,@FiltruContCor=null,@RulajePeLocMunca=0,@Valuta=''	

	if object_id('tempdb..#necorelatii') is not null drop table #necorelatii

	select n.tip_necorelatii,n.tip_document,n.numar,convert(char(10),n.data,101) as data,n.cont,msg_eroare,
		convert(char(10),@data_jos,101) as datajos,convert(char(10),@data_sus,101) as datasus,
		convert(decimal(17,5),n.valoare_1) as valoare_doc,convert(decimal(17,5),n.valoare_2) as valoare_inregistrari,n.utilizator, n.valuta
	into #necorelatii
	from necorelatii n
	where n.tip_necorelatii=@tip and n.utilizator=@utilizator and n.data between @data_jos and @data_sus
		and (n.numar like @filtruNrDoc + '%' or @filtruNrDoc='')
		and (n.cont like @filtruCont + '%' or @filtruCont='')

	if @dincgplus=0
		select top 100 tip_necorelatii,tip_document,numar,data,cont,msg_eroare,datajos,datasus,convert(decimal(17,2),valoare_doc) valoare_doc,convert(decimal(17,2),valoare_inregistrari) valoare_inregistrari,utilizator,valuta
		from #necorelatii n
		for xml raw 
	else
		select tip_document,numar,data,cont,valoare_doc,valoare_inregistrari
		from #necorelatii n
		order by tip_document,numar,data
end try

begin catch
	set @mesajeroare='(wIaVerificareContabilitate) '+ERROR_MESSAGE()
end catch

if LEN(@mesajeroare)>0
	raiserror(@mesajeroare, 11, 1)
