--***
create procedure wIaVerificareSinteze @sesiune varchar(50), @parXML XML    
as   

--apelare procedura specifica daca aceasta exista
if exists (select 1 from sysobjects where [type]='P' and [name]='wIaVerificareSintezeSP')
begin 
	declare @returnValue int -- variabila salveaza return value de la procedura specifica
	exec @returnValue = wIaVerificareSintezeSP @sesiune, @parXML output
	return @returnValue
end 

begin try
	declare @sub varchar(9),@utilizator varchar(20),@tip varchar(2),@data_jos datetime, @data_sus datetime,
		@_refresh int,@filtruNrDoc varchar(30),@filtruContDebit varchar(40),@filtruCont varchar(40),
		@filtruCod varchar(100),@filtruGest varchar(13), @filtruTipCont varchar(40), @filtruLM varchar(30),
		@filtruTert varchar(30),@filtruComanda varchar(20), @filtruFactura varchar(20), @mesajeroare varchar(500),
		@dateInitializare XML,@dincgplus int
		
	--exec luare_date_par 'GE', 'SUBPRO', 0,0,@sub output  
	exec wIaUtilizator @sesiune=@sesiune, @utilizator=@utilizator output  	
	
	--citire date din xml
	select 
		@tip = isnull(@parXML.value('(/row/@tip)[1]','varchar(3)'),''),
		@data_jos = isnull(@parXML.value('(/row/@datajos)[1]','datetime'),'1901-01-01'),
		@data_sus = isnull(@parXML.value('(/row/@datasus)[1]','datetime'),'2099-01-01'),
		@_refresh = isnull(@parXML.value('(/row/@_refresh)[1]','int'),1),
		@filtruNrDoc = isnull(@parXML.value('(/row/@filtruNrDoc)[1]','varchar(30)'),''),
		@filtruCod = isnull(@parXML.value('(/row/@filtruCod)[1]','varchar(100)'),''),
		@filtruCont = isnull(@parXML.value('(/row/@filtruCont)[1]','varchar(40)'),''),
		@filtruTipCont = isnull(@parXML.value('(/row/@filtruTipCont)[1]','varchar(40)'),''),
		@filtruLM = isnull(@parXML.value('(/row/@filtruLM)[1]','varchar(30)'),''),
		@filtruTert = isnull(@parXML.value('(/row/@filtruTert)[1]','varchar(30)'),''),
		@filtruComanda = isnull(@parXML.value('(/row/@filtruComanda)[1]','varchar(20)'),''),
		@filtruFactura = isnull(@parXML.value('(/row/@filtruFactura)[1]','varchar(20)'),''),
		@dincgplus = isnull(@parXML.value('(/row/@dincgplus)[1]','int'),0)
		
	if @_refresh=0 --and @tip in ('RI','SA')
	begin
		set @dateInitializare=(select convert(char(10),@data_jos,101) as datajos, convert(char(10),@data_sus,101) as datasus--, 0 as rulajePeLocMunca
				for xml raw ,root('row'))

		SELECT 'Populare necorelatii' nume, 'VS' codmeniu, 'D' tipmacheta,@tip tip,'PN' subtip,'O' fel,
				(SELECT @dateInitializare ) dateInitializare
			FOR XML RAW('deschideMacheta'), ROOT('Mesaje')
	end

	--if not exists(select 1 from necorelatii where tip_necorelatii=@tip and utilizator=@utilizator)
	--exec populareNecorelatii @Data_jos=@data_jos, @Data_sus=@data_sus,@PretAm=0,@Tip_necorelatii=@tip,@InUM2=0,@FiltruCont='',
	--		@FiltruGest=null,@FiltruCod_intrare=null,@FiltruGrupa=null,@TipStoc=null,@FiltruCod=null,@FiltruLM=null,@FiltruComanda=null,
	--		@FiltruFurn=null,@FiltruLot=null,@FiltruLocatie=null,@CorelatiiPeContAtribuit=1,@FiltruContCor=null,@RulajePeLocMunca=0,@Valuta=''	

	if @tip='RI'--necorelatii rulaje <-> inregistrari
	begin
		/*if not exists(select 1 from necorelatii where tip_necorelatii=@tip and utilizator=@utilizator)
			exec populareNecorelatii @Data_jos=@data_jos, @Data_sus=@data_sus,@PretAm=0,@Tip_necorelatii=@tip,@InUM2=0,@FiltruCont=null,
				@FiltruGest=null,@FiltruCod_intrare=null,@FiltruGrupa=null,@TipStoc=null,@FiltruCod=null,@FiltruLM=null,@FiltruComanda=null,
				@FiltruFurn=null,@FiltruLot=null,@FiltruLocatie=null,@CorelatiiPeContAtribuit=0,@FiltruContCor=null,@RulajePeLocMunca=0,@Valuta=null
		*/	
		select top 100 n.tip_necorelatii,n.tip_alte as tip_cont,n.numar,convert(char(10),n.data,101) as data,msg_eroare,convert(char(10),@data_jos,101) as datajos,
			convert(char(10),@data_sus,101) as datasus,	convert(decimal(17,5),n.valoare_3) as valoare_rulaje,rtrim(n.cont) as cont,
			convert(decimal(17,5),n.valoare_2) as valoare_inregistrari,n.utilizator,(case when n.tip_alte='D' then 'Debit' else 'Credit' end) as denTip_cont
		from necorelatii n
		where n.tip_necorelatii=@tip
			and n.utilizator=@utilizator
			and (n.cont like @filtruCont+'%' or @filtruCont='')
			and ((case when n.tip_alte='D' then 'Debit' else 'Credit' end) like @filtruTipCont+'%' or @filtruTipCont='')
			--and n.data between @data_jos and @data_sus
		order by n.cont
		for xml raw 
	end		
		
	if @tip='SA'--necorelatii conturi analitic <-> sintetic
	begin
		/*if not exists(select 1 from necorelatii where tip_necorelatii=@tip and utilizator=@utilizator)
			exec populareNecorelatii @Data_jos=@data_jos, @Data_sus=@data_sus,@PretAm=0,@Tip_necorelatii=@tip,@InUM2=0,@FiltruCont=null,
				@FiltruGest=null,@FiltruCod_intrare=null,@FiltruGrupa=null,@TipStoc=null,@FiltruCod=null,@FiltruLM=null,@FiltruComanda=null,
				@FiltruFurn=null,@FiltruLot=null,@FiltruLocatie=null,@CorelatiiPeContAtribuit=0,@FiltruContCor=null,@RulajePeLocMunca=0,@Valuta=null	
		*/	
		select top 100 n.tip_necorelatii,msg_eroare, 
			convert(char(10),data,101) as data,
			convert(char(10),@data_jos,101) as datajos,
			convert(char(10),@data_sus,101) as datasus,	
			convert(decimal(17,5),n.valoare_1) as deban,rtrim(n.cont) as cont,
			convert(decimal(17,5),n.valoare_2) as credan,convert(decimal(17,5),n.valoare_3) as rulaj_debit,convert(decimal(17,5),n.valoare_4) as rulaj_credit,
			n.utilizator,n.lm, isnull(lm.Denumire,'') as denLM
		from necorelatii n
			left outer join lm on lm.Cod=n.lm
		where n.tip_necorelatii=@tip
			and n.utilizator=@utilizator
			and (n.cont like @filtruCont+'%' or @filtruCont='')
			and (lm.denumire like @filtruLM+'%' or @filtruLM='')
			and n.data between @data_jos and @data_sus
		order by n.cont
		for xml raw 
	end

	if 90=0 and @tip='SD'
	begin
		select	rtrim(d.decont) as decont, convert(varchar(20),data,101) as data, 
				rtrim(d.Marca) as marca, isnull(rtrim(p.Nume),'') as denumireMarca
		from deconturi d
		left outer join personal p on p.marca=d.marca
		where d.tip='T'
		order by d.Cont 
		for xml raw
	end

	if 90=0 and @tip='SE'
	begin
		select	rtrim(ef.tip) as tip, rtrim(ef.tert) as tert, rtrim(t.denumire) as denTert,
				rtrim(ef.Nr_efect) as nrEfect, rtrim(ef.cont) as cont, convert(varchar(20),ef.Data,101) as data,
				convert(decimal(15,2),ef.Valoare) as valoare 
		from efecte ef 
		left outer join terti t on t.tert=ef.tert
		for xml raw
	end

	if @tip in ('FB','FF') --necorelatii doc. - facturi
	begin
		if @dincgplus=0
			select top 100 n.tip_necorelatii, n.tip_document as tipfact, n.numar as factura, convert(char(10),n.data,101) as data, 
				rtrim(n.cont) as tert, convert(decimal(17,5),n.valoare_1) as solddoc, convert(decimal(17,5),n.valoare_2) as soldfact, 
				convert(decimal(17,5),n.valoare_3) as soldvalutadoc, convert(decimal(17,5),n.valoare_4) as soldvalutafact, isnull(t.Denumire,'') as dentert
			from necorelatii n
				left outer join terti t on t.Tert=n.cont
			where n.tip_necorelatii=@tip
				and n.utilizator=@utilizator
				and (n.cont like @filtruTert+'%' or t.denumire like @filtruTert+'%' or @filtruTert='')
			order by n.data, n.numar, n.cont
			for xml raw
		else 
			select n.tip_necorelatii, n.tip_document as tipfact, 
				rtrim(n.cont) as tert, isnull(t.Denumire,'') as dentert, n.numar as factura, convert(char(10),n.data,101) as data, 
				convert(decimal(17,5),n.valoare_1) as solddoc, convert(decimal(17,5),n.valoare_2) as soldfact, 
				convert(decimal(17,5),n.valoare_3) as soldvalutadoc, convert(decimal(17,5),n.valoare_4) as soldvalutafact
			from necorelatii n
				left outer join terti t on t.Tert=n.cont
			where n.tip_necorelatii=@tip
				and n.utilizator=@utilizator
				and (n.cont like @filtruTert+'%' or t.denumire like @filtruTert+'%' or @filtruTert='')
			order by n.data, n.numar, n.cont
	end

	if @tip='SS' --necorelatii doc. - stocuri
	begin
		select top 100 n.tip_necorelatii, n.numar as cod, rtrim(n.cont) as codintrare, --convert(char(10),n.data,101) as data, 
			rtrim(n.lm) as gest, convert(decimal(17,5),n.valoare_1) as stocdoc, convert(decimal(17,5),n.valoare_2) as stoc, 
			isnull(t.Denumire,'') as den
		from necorelatii n
			left outer join nomencl t on t.Cod=n.numar
		where n.tip_necorelatii=@tip
			and n.utilizator=@utilizator
			and (n.numar like @filtruCod+'%' or t.denumire like @filtruCod+'%' or @filtruCod='')
		order by n.lm, n.numar, n.cont
		for xml raw
	end		
end try

begin catch
	set @mesajeroare='(wIaVerificareSinteze)'+ERROR_MESSAGE()
end catch

if LEN(@mesajeroare)>0
	raiserror(@mesajeroare, 11, 1)
