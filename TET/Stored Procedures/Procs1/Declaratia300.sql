--***
Create procedure Declaratia300
	(@sesiune varchar(50)='', @data datetime--, @datasus datetime
	,@nume_declar varchar(200), @prenume_declar varchar(200), @functie_declar varchar(100)
	,@bifa_interne int=0, @pro_rata int=100, @ramburstva int=0
	,@cui varchar(100)=null, @den varchar(100)=null, @adresa varchar(100)=null
	,@telefon varchar(100)=null, @fax varchar(100)=null, @mail varchar(100)=null
	,@banca varchar(100)=null, @cont_banca varchar(100)=null, @caen varchar(100)=null
	,@caleFisier varchar(300)	--> calea completa, incluzand fisierul; daca fisierul nu este dat se creeaza unul in functie de data, tip si cod fiscal firma
	,@dinRia int=1		-->	par care determina modul de scriere pe harddisk
	-->	decl300:
	,@tip_D300 varchar(1)	-->	L=lunar, T=trimestrial, S=semestrial, A=anual
	-- am pastrat tipurile de la Declaratia 394 - cele 2 merg impreuna - se depun pentru aceeasi perioada
	,@OptiuniGenerare int=0 --Generare declaratie=0 - calcul date din ASiS+generare XML, 1-Generare XML
	)
as
declare @eroare varchar(8000)
set @eroare=''
begin try
	declare @datasus datetime, @datajos datetime, @parXML xml, @an int 
	select @data=dbo.bom(@data)
	select @datajos=(case @tip_D300 when 'L' then @data
									when 'T' then dateadd(M,-(month(@data)-1) % 3,@data)
									when 'S' then dateadd(M,-(month(@data)-1) % 6,@data)
									when 'A' then dateadd(M,-month(@data)+1,@data)
									else @datajos
									end)
			,@datasus=(case @tip_D300 when 'L' then dbo.eom(@data)
									when 'T' then dbo.eom(dateadd(M,-(month(@data)-1) % 3 +2,@data))
									when 'S' then dbo.eom(dateadd(M,-(month(@data)-1) % 6 + 5,@data))
									when 'A' then dbo.eom(dateadd(M,-month(@data)+12,@data))
									else @datajos
									end)
			,@an=year(@data)
	
	declare @fisier varchar(100), @pozSeparator int, @caleCompletaFisier varchar(300)
	select	@pozSeparator=len(@caleFisier)-charindex('\',reverse(@caleFisier))
			,@caleCompletaFisier=@caleFisier
	select	@fisier=substring(@caleFisier,@pozSeparator+2,len(@caleFisier)-@pozseparator+1)
			,@caleFisier=substring(@caleFisier,1,@pozseparator)

	declare @bifa_cereale char(1), @solicit_ramb char(1), @nr_evid varchar(100), @data_scadentei datetime
	set @solicit_ramb=(case when @ramburstva=0 then 'N' else 'D' end)
	set @data_scadentei=DateAdd(day,25,@datasus)
	
	set @nr_evid='1030'+(case when @tip_D300='L' then '1' when @tip_D300='T' then '2' when @tip_D300='S' then '3' else '4' end)
		+'01'+left(convert(char(10),@datasus,101),2)+right(convert(char(10),@datasus,101),2)+rtrim(replace(CONVERT(char(10),@data_scadentei,3),'/',''))+'0000'

--	stabilesc cheia de control pentru numarul de evidenta platii
	declare @i int, @cifreCtrl int
	set @i = 1
	set @cifreCtrl=0
	while @i <= Len(RTrim(@nr_evid))
	begin
		set @cifreCtrl=@cifreCtrl + convert(int,Substring(@nr_evid, @i, 1))
		set @i = @i + 1
	end
	set @nr_evid=RTRIM(@nr_evid)+right(ltrim(rtrim(CONVERT(char(10),@cifreCtrl))),2)
			
	if object_id('tempdb.dbo.##tmpdecl') is not null drop table ##tmpdecl
	
	if (@cui is null)
		select 
			@cui=replace(replace(
				case when tip_parametru='GE' and parametru='CODFISC' then rtrim(val_alfanumerica) else @cui end,'RO',''),'R','')
			,@den=case when tip_parametru='GE' and parametru='NUME' then rtrim(val_alfanumerica) else @den end
			,@telefon=case when tip_parametru='GE' and parametru='TELFAX' then rtrim(val_alfanumerica) else @telefon end	--?
			,@fax=case when tip_parametru='GE' and parametru='FAX' then rtrim(val_alfanumerica) else @fax end	--?
			,@mail=case when tip_parametru='GE' and parametru='EMAIL' then rtrim(val_alfanumerica) else @mail end	--?
			,@banca=case when tip_parametru='GE' and parametru='BANCA' then rtrim(val_alfanumerica) else @banca end	--?
			,@cont_banca=case when tip_parametru='GE' and parametru='CONTBC' then rtrim(val_alfanumerica) else @cont_banca end	--?
			,@caen=case when tip_parametru='PS' and parametru='CODCAEN' then rtrim(val_alfanumerica) else @caen end	--?
		from par where tip_parametru='GE' and parametru in ('CODFISC','NUME', 'FAX','TELFAX','EMAIL','BANCA','CONTBC')
				or tip_parametru='PS' and parametru in ('CODCAEN')
				
	if @fax=''  -- compatibilitate in urma
		set @fax=@telefon
	
	if len(rtrim(@fisier))=0	--<<	Aici se compune numele fisierului, daca a fost omis
		select @fisier='300_'+@tip_D300+
				'_D'+rtrim(convert(varchar(2),month(@datasus)))+right(convert(varchar(4),year(@datasus)),2)+
				'_J'+rtrim(@cui)
	if left(right(@fisier,4),1)<>'.' select @fisier=@fisier+'.xml'
	
	if (@adresa is null)
		select 
		@adresa=max(case when rtrim(val_alfanumerica)<>'' and parametru='LOCALIT' then 'Localitatea '+rtrim(val_alfanumerica)+' ' else '' end)
			+max(case when rtrim(val_alfanumerica)<>'' and parametru='STRADA' then 'str '+rtrim(val_alfanumerica)+' ' else '' end)
			+max(case when rtrim(val_alfanumerica)<>'' and parametru='NUMAR' then 'nr '+rtrim(val_alfanumerica)+' ' else '' end)
			+max(case when rtrim(val_alfanumerica)<>'' and parametru='BLOC' then 'bl '+rtrim(val_alfanumerica)+' ' else '' end)
			+max(case when rtrim(val_alfanumerica)<>'' and parametru='SCARA' then 'sc '+rtrim(val_alfanumerica)+' ' else '' end)
			+max(case when rtrim(val_alfanumerica)<>'' and parametru='ETAJ' then 'etaj '+rtrim(val_alfanumerica)+' ' else '' end)
			+max(case when rtrim(val_alfanumerica)<>'' and parametru='APARTAM' then 'ap '+rtrim(val_alfanumerica)+' ' else '' end)
			+max(case when rtrim(val_alfanumerica)<>'' and parametru='JUDET' then 'jud '+rtrim(val_alfanumerica)+' ' else '' end)
			+max(case when rtrim(val_alfanumerica)<>'' and parametru='CODPOSTAL' then 'cod postal '+rtrim(val_alfanumerica)+' ' else '' end)
			+max(case when rtrim(val_alfanumerica)<>'' and parametru='SECTOR' then 'sector '+rtrim(val_alfanumerica)+' ' else '' end)
		from par where tip_parametru='PS' and parametru in 
				('LOCALIT','STRADA','NUMAR','BLOC','SCARA','ETAJ','APARTAM','JUDET','CODPOSTAL','SECTOR')

	select	@cui=(case when rtrim(@cui)='' then null else @cui end),
				@den=(case when rtrim(@den)='' then null else @den end),
				@telefon=(case when rtrim(@telefon)='' then null else @telefon end),
				@fax=(case when rtrim(@fax)='' then null else @fax end),
				@mail=(case when rtrim(@mail)='' then null else @mail end),
				@adresa=(case when rtrim(@adresa)='' then null else @adresa end)

--	stabilesc daca exista operatiuni cu cereale (doar daca se ruleaza operatia cu optiunea de calcul)
	if @OptiuniGenerare=0
	begin
		if object_id('tempdb..#D394plus') is not null drop table #D394plus
		create table #D394plus
			(codtert varchar(50), cuiP varchar(50), dentert varchar(200), tipop varchar(1), nrfacturi int, baza decimal(15), tva decimal(15), cod varchar(20), denumirecod varchar(200))
		exec Declaratia394
			@data=@data
			,@nume_declar='', @prenume_declar='', @functie_declar=''
			,@caleFisier=''
			,@dinRia=0
			,@tip_D394=@tip_D300 
			,@genRaport=1 
		set @bifa_cereale=(case when exists (select 1 from #D394plus where tipop in ('V','C') and cod<>'') then 'D' else 'N' end)
		if object_id('tempdb..#D394plus') is not null drop table #D394plus
	end

--	parametrii din macheta de generare a jurnalelor in baza carora rezulta sumele de TVA
	declare @FFTVA0 varchar(1),	--> Facturi operate pe FF:	0=nu apar fara tva, 1=cu cota<>0, 2=apar fara tva
		@FBTVA0 varchar(1),	--> Facturi operate pe FB:	0=nu apar fara tva, 1=cu cota<>0, 2=apar fara tva
		@SFTVA0 varchar(1),	--> Facturi operate pe SF:	0=nu apar fara tva, 1=cu cota<>0, 2=apar fara tva
		@IAFTVA0 int,			--> Apar si IAF fara TVA
		@CtPIScDed char(200),	--> conturi antet PI pt. scutire cu drept de deducere
		@CtVenScDed char(200),	--> conturi venituri pt. scutire cu drept de deducere
		@CtNeimpoz char(200)	--> conturi coresp. pentru neimpozabile

	select @FFTVA0=max(case when parametru='JTVAFF0' then rtrim(val_alfanumerica) else '' end)
		,@FBTVA0=(case when max(case when parametru='JTVAFB0' then convert(int,Val_logica) else '' end)=1  then '2' else '0' end)
		,@SFTVA0=max(case when parametru='JTVASF0' then rtrim(val_alfanumerica) else '' end)
		,@IAFTVA0=max(case when parametru='JTVAIAF0' then convert(int,Val_logica) else '' end)
		,@CtPIScDed=max(case when parametru='CASCDED' then rtrim(val_alfanumerica) else '' end)
		,@CtVenScDed=max(case when parametru='CSCDED' then rtrim(val_alfanumerica) else '' end)
		,@CtNeimpoz=max(case when parametru='CCNEIMPOZ' then rtrim(val_alfanumerica) else '' end)

	from par where tip_parametru='GE' and parametru in ('JTVAFF0','JTVAFB0','JTVASF0','JTVAIAF0','CASCDED','CSCDED','CCNEIMPOZ')
		
	select @FFTVA0=(case when isnull(@FFTVA0,'')='' then '2' else @FFTVA0 end), 
		@FBTVA0=(case when isnull(@FBTVA0,'')='' then '2' else @FBTVA0 end), 
		@SFTVA0=(case when isnull(@SFTVA0,'')='' then '2' else @SFTVA0 end)

	set @parXML=(select @datajos datajos, @datasus datasus, (case when @OptiuniGenerare=0 then 1 else 0 end) as calcul,
		@FFTVA0 as FFTVA0, @FBTVA0 as FBTVA0, @SFTVA0 as SFTVA0, @IAFTVA0 as IAFTVA0, 
		rtrim(@CtPIScDed) as CtPIScDed, rtrim(@CtVenScDed) as CtVenScDed, rtrim(@CtNeimpoz) as CtNeimpoz, rtrim(@nr_evid) as nr_evid, 
		@bifa_cereale as bifa_cereale, @solicit_ramb as solicit_ramb, 
		@data_scadentei as data_scadentei for xml raw)

--	apelat tot timpul procedura de calcul. Daca @OptiuniGenerare=1, in procedura se calculeaza doar totalurile.
	exec calculDecontTVA @parXML

--	formare continut XML pentru generare fisier
	declare @continutXml xml, @continutXmlChar varchar(max), @totalPlata_A decimal(15,3)
	select @totalPlata_A=SUM(convert(decimal(15),valoare)+convert(decimal(15),TVA)) from deconttva where data=@datasus and Rand_decont not in ('53','54')

--	format fisier pentru an >= 2013
	if @an>=2013
		select @continutXml=(
			select 'mfp:anaf:dgti:d300:declaratie:v3'as [@ptxmlns],
				month(@datasus) as [@luna], @an as [@an] 
				,convert(char(1),@bifa_interne) as [@bifa_interne]
				,@nume_declar [@nume_declar], @prenume_declar [@prenume_declar]
				,@functie_declar [@functie_declar]
				,@cui [@cui], @den [@den], @adresa [@adresa]
					,@telefon [@telefon], @fax [@fax], @mail [@mail]
					,@banca [@banca], @cont_banca [@cont], @caen [@caen]
					,@tip_D300 [@tip_decont], @pro_rata [@pro_rata]
					,max((case when Rand_decont='CEREALE' then RTRIM(Denumire_indicator) end)) as [@bifa_cereale]
					,@solicit_ramb as [@solicit_ramb]
					,@nr_evid [@nr_evid]
					,convert(decimal(15),@totalPlata_A) as [@totalPlata_A]
					,max((case when Rand_decont='1' then convert(decimal(15),valoare) end)) as [@R1_1]
					,max((case when Rand_decont='2' then convert(decimal(15),valoare) end)) as [@R2_1]
					,max((case when Rand_decont='3' then convert(decimal(15),valoare) end)) as [@R3_1]
					,max((case when Rand_decont='3.1' then convert(decimal(15),valoare) end)) as [@R3_1_1]
					,max((case when Rand_decont='4' then convert(decimal(15),valoare) end)) as [@R4_1]
					,max((case when Rand_decont='5' then convert(decimal(15),valoare) end)) as [@R5_1]
					,max((case when Rand_decont='5' then convert(decimal(15),tva) end)) as [@R5_2]
					,max((case when Rand_decont='5.1' then convert(decimal(15),valoare) end)) as [@R5_1_1]
					,max((case when Rand_decont='5.1' then convert(decimal(15),tva) end)) as [@R5_1_2]
					,max((case when Rand_decont='6' then convert(decimal(15),valoare) end)) as [@R6_1]
					,max((case when Rand_decont='6' then convert(decimal(15),tva) end)) as [@R6_2]
					,max((case when Rand_decont='7' then convert(decimal(15),valoare) end)) as [@R7_1]
					,max((case when Rand_decont='7' then convert(decimal(15),tva) end)) as [@R7_2]
					,max((case when Rand_decont='7.1' then convert(decimal(15),valoare) end)) as [@R7_1_1]
					,max((case when Rand_decont='7.1' then convert(decimal(15),tva) end)) as [@R7_1_2]
					,max((case when Rand_decont='8' then convert(decimal(15),valoare) end)) as [@R8_1]
					,max((case when Rand_decont='8' then convert(decimal(15),tva) end)) as [@R8_2]
					,max((case when Rand_decont='9' then convert(decimal(15),valoare) end)) as [@R9_1]
					,max((case when Rand_decont='9' then convert(decimal(15),tva) end)) as [@R9_2]
					,max((case when Rand_decont='10' then convert(decimal(15),valoare) end)) as [@R10_1]
					,max((case when Rand_decont='10' then convert(decimal(15),tva) end)) as [@R10_2]
					,max((case when Rand_decont='11' then convert(decimal(15),valoare) end)) as [@R11_1]
					,max((case when Rand_decont='11' then convert(decimal(15),tva) end)) as [@R11_2]
					,max((case when Rand_decont='12' then convert(decimal(15),valoare) end)) as [@R12_1]
					,max((case when Rand_decont='12' then convert(decimal(15),tva) end)) as [@R12_2]
					,max((case when Rand_decont='13' then convert(decimal(15),valoare) end)) as [@R13_1]
					,max((case when Rand_decont='14' then convert(decimal(15),valoare) end)) as [@R14_1]
					,max((case when Rand_decont='15' then convert(decimal(15),valoare) end)) as [@R15_1]
					,max((case when Rand_decont='16' then convert(decimal(15),valoare) end)) as [@R16_1]
					,max((case when Rand_decont='16' then convert(decimal(15),tva) end)) as [@R16_2]
					,max((case when Rand_decont='17' then convert(decimal(15),valoare) end)) as [@R17_1]
					,max((case when Rand_decont='17' then convert(decimal(15),tva) end)) as [@R17_2]
					,max((case when Rand_decont='18' then convert(decimal(15),valoare) end)) as [@R18_1]
					,max((case when Rand_decont='18' then convert(decimal(15),tva) end)) as [@R18_2]
					,max((case when Rand_decont='18.1' then convert(decimal(15),valoare) end)) as [@R18_1_1]
					,max((case when Rand_decont='18.1' then convert(decimal(15),tva) end)) as [@R18_1_2]
					,max((case when Rand_decont='19' then convert(decimal(15),valoare) end)) as [@R19_1]
					,max((case when Rand_decont='19' then convert(decimal(15),tva) end)) as [@R19_2]
					,max((case when Rand_decont='20' then convert(decimal(15),valoare) end)) as [@R20_1]
					,max((case when Rand_decont='20' then convert(decimal(15),tva) end)) as [@R20_2]
					,max((case when Rand_decont='20.1' then convert(decimal(15),valoare) end)) as [@R20_1_1]
					,max((case when Rand_decont='20.1' then convert(decimal(15),tva) end)) as [@R20_1_2]
					,max((case when Rand_decont='21' then convert(decimal(15),valoare) end)) as [@R21_1]
					,max((case when Rand_decont='21' then convert(decimal(15),tva) end)) as [@R21_2]
					,max((case when Rand_decont='22' then convert(decimal(15),valoare) end)) as [@R22_1]
					,max((case when Rand_decont='22' then convert(decimal(15),tva) end)) as [@R22_2]
					,max((case when Rand_decont='23' then convert(decimal(15),valoare) end)) as [@R23_1]
					,max((case when Rand_decont='23' then convert(decimal(15),tva) end)) as [@R23_2]
					,max((case when Rand_decont='24' then convert(decimal(15),valoare) end)) as [@R24_1]
					,max((case when Rand_decont='24' then convert(decimal(15),tva) end)) as [@R24_2]
					,max((case when Rand_decont='25' then convert(decimal(15),valoare) end)) as [@R25_1]
					,max((case when Rand_decont='25' then convert(decimal(15),tva) end)) as [@R25_2]
					,max((case when Rand_decont='26' then convert(decimal(15),valoare) end)) as [@R26_1]
					,max((case when Rand_decont='26.1' then convert(decimal(15),valoare) end)) as [@R26_1_1]
					,max((case when Rand_decont='27' then convert(decimal(15),valoare) end)) as [@R27_1]
					,max((case when Rand_decont='27' then convert(decimal(15),tva) end)) as [@R27_2]
					,max((case when Rand_decont='28' then convert(decimal(15),tva) end)) as [@R28_2]
					,max((case when Rand_decont='29' then convert(decimal(15),tva) end)) as [@R29_2]
					,max((case when Rand_decont='30' then convert(decimal(15),valoare) end)) as [@R30_1]
					,max((case when Rand_decont='30' then convert(decimal(15),tva) end)) as [@R30_2]
					,max((case when Rand_decont='31' then convert(decimal(15),tva) end)) as [@R31_2]
					,max((case when Rand_decont='32' then convert(decimal(15),tva) end)) as [@R32_2]
					,max((case when Rand_decont='33' then convert(decimal(15),tva) end)) as [@R33_2]
					,max((case when Rand_decont='34' then convert(decimal(15),tva) end)) as [@R34_2]
					,max((case when Rand_decont='35' then convert(decimal(15),tva) end)) as [@R35_2]
					,max((case when Rand_decont='36' then convert(decimal(15),tva) end)) as [@R36_2]
					,max((case when Rand_decont='37' then convert(decimal(15),tva) end)) as [@R37_2]
					,max((case when Rand_decont='38' then convert(decimal(15),tva) end)) as [@R38_2]
					,max((case when Rand_decont='39' then convert(decimal(15),tva) end)) as [@R39_2]
					,max((case when Rand_decont='40' then convert(decimal(15),tva) end)) as [@R40_2]
					,max((case when Rand_decont='41' then convert(decimal(15),tva) end)) as [@R41_2]
					,max((case when Rand_decont='42' then convert(decimal(15),tva) end)) as [@R42_2]
					,max((case when Rand_decont='50' and Valoare<>0 then convert(decimal(15),Valoare) end)) as [@nr_facturi]
					,max((case when Rand_decont='51' and Valoare<>0 then convert(decimal(15),Valoare) end)) as [@baza]
					,max((case when Rand_decont='52' and TVA<>0 then convert(decimal(15),tva) end)) as [@tva]
					,max((case when Rand_decont='53' and Valoare<>0 then convert(decimal(15),Valoare) end)) as [@valoare_a]
					,max((case when Rand_decont='53' and TVA<>0 then convert(decimal(15),tva) end)) as [@tva_a]
					,max((case when Rand_decont='54' and Valoare<>0 then convert(decimal(15),Valoare) end)) as [@valoare_b]
					,max((case when Rand_decont='54' and TVA<>0 then convert(decimal(15),tva) end)) as [@tva_b]
				from deconttva where data=@datasus
				group by Data
				for xml path('declaratie300'), type)
	else		
--	format fisier pentru an <= 2012
		select @continutXml=(
			select 'mfp:anaf:dgti:d300:declaratie:v2' as [@ptxmlns],
				month(@datasus) as [@luna], @an as [@an] 
				,convert(char(1),@bifa_interne) as [@bifa_interne]
				,@nume_declar [@nume_declar], @prenume_declar [@prenume_declar]
				,@functie_declar [@functie_declar]
				,@cui [@cui], @den [@den], @adresa [@adresa]
					,@telefon [@telefon], @fax [@fax], @mail [@mail]
					,@banca [@banca], @cont_banca [@cont], @caen [@caen]
					,@tip_D300 [@tip_decont], @pro_rata [@pro_rata]
					,max((case when Rand_decont='CEREALE' then RTRIM(Denumire_indicator) end)) as [@bifa_cereale]
					,@solicit_ramb as [@solicit_ramb]
					,@nr_evid [@nr_evid]
					,convert(decimal(15),@totalPlata_A) as [@totalPlata_A]
					,max((case when Rand_decont='1' then convert(decimal(15),valoare) end)) as [@R1_1]
					,max((case when Rand_decont='2' then convert(decimal(15),valoare) end)) as [@R2_1]
					,max((case when Rand_decont='3' then convert(decimal(15),valoare) end)) as [@R3_1]
					,max((case when Rand_decont='3.1' then convert(decimal(15),valoare) end)) as [@R3_1_1]
					,max((case when Rand_decont='4' then convert(decimal(15),valoare) end)) as [@R4_1]
					,max((case when Rand_decont='5' then convert(decimal(15),valoare) end)) as [@R5_1]
					,max((case when Rand_decont='5' then convert(decimal(15),tva) end)) as [@R5_2]
					,max((case when Rand_decont='5.1' then convert(decimal(15),valoare) end)) as [@R5_1_1]
					,max((case when Rand_decont='5.1' then convert(decimal(15),tva) end)) as [@R5_1_2]
					,max((case when Rand_decont='6' then convert(decimal(15),valoare) end)) as [@R6_1]
					,max((case when Rand_decont='6' then convert(decimal(15),tva) end)) as [@R6_2]
					,max((case when Rand_decont='7' then convert(decimal(15),valoare) end)) as [@R7_1]
					,max((case when Rand_decont='7' then convert(decimal(15),tva) end)) as [@R7_2]
					,max((case when Rand_decont='7.1' then convert(decimal(15),valoare) end)) as [@R7_1_1]
					,max((case when Rand_decont='7.1' then convert(decimal(15),tva) end)) as [@R7_1_2]
					,max((case when Rand_decont='8' then convert(decimal(15),valoare) end)) as [@R8_1]
					,max((case when Rand_decont='8' then convert(decimal(15),tva) end)) as [@R8_2]
					,max((case when Rand_decont='9' then convert(decimal(15),valoare) end)) as [@R9_1]
					,max((case when Rand_decont='9' then convert(decimal(15),tva) end)) as [@R9_2]
					,max((case when Rand_decont='10' then convert(decimal(15),valoare) end)) as [@R10_1]
					,max((case when Rand_decont='10' then convert(decimal(15),tva) end)) as [@R10_2]
					,max((case when Rand_decont='11' then convert(decimal(15),valoare) end)) as [@R11_1]
					,max((case when Rand_decont='11' then convert(decimal(15),tva) end)) as [@R11_2]
					,max((case when Rand_decont='12' then convert(decimal(15),valoare) end)) as [@R12_1]
					,max((case when Rand_decont='12' then convert(decimal(15),tva) end)) as [@R12_2]
					,max((case when Rand_decont='13' then convert(decimal(15),valoare) end)) as [@R12a_1]
					,max((case when Rand_decont='14' then convert(decimal(15),valoare) end)) as [@R13_1]
					,max((case when Rand_decont='15' then convert(decimal(15),valoare) end)) as [@R14_1]
					,max((case when Rand_decont='16' then convert(decimal(15),valoare) end)) as [@R15_1]
					,max((case when Rand_decont='16' then convert(decimal(15),tva) end)) as [@R15_2]
					,max((case when Rand_decont='17' then convert(decimal(15),valoare) end)) as [@R16_1]
					,max((case when Rand_decont='17' then convert(decimal(15),tva) end)) as [@R16_2]
					,max((case when Rand_decont='17.1' then convert(decimal(15),valoare) end)) as [@R16_1_1]
					,max((case when Rand_decont='17.1' then convert(decimal(15),tva) end)) as [@R16_1_2]
					,max((case when Rand_decont='18' then convert(decimal(15),valoare) end)) as [@R17_1]
					,max((case when Rand_decont='18' then convert(decimal(15),tva) end)) as [@R17_2]
					,max((case when Rand_decont='18.1' then convert(decimal(15),valoare) end)) as [@R17_1_1]
					,max((case when Rand_decont='18.1' then convert(decimal(15),tva) end)) as [@R17_1_2]
					,max((case when Rand_decont='19' then convert(decimal(15),valoare) end)) as [@R18_1]
					,max((case when Rand_decont='19' then convert(decimal(15),tva) end)) as [@R18_2]
					,max((case when Rand_decont='20' then convert(decimal(15),valoare) end)) as [@R19_1]
					,max((case when Rand_decont='20' then convert(decimal(15),tva) end)) as [@R19_2]
					,max((case when Rand_decont='20.1' then convert(decimal(15),valoare) end)) as [@R19_1_1]
					,max((case when Rand_decont='20.1' then convert(decimal(15),tva) end)) as [@R19_1_2]
					,max((case when Rand_decont='21' then convert(decimal(15),valoare) end)) as [@R20_1]
					,max((case when Rand_decont='21' then convert(decimal(15),tva) end)) as [@R20_2]
					,max((case when Rand_decont='22' then convert(decimal(15),valoare) end)) as [@R21_1]
					,max((case when Rand_decont='22' then convert(decimal(15),tva) end)) as [@R21_2]
					,max((case when Rand_decont='23' then convert(decimal(15),valoare) end)) as [@R22_1]
					,max((case when Rand_decont='23' then convert(decimal(15),tva) end)) as [@R22_2]
					,max((case when Rand_decont='24' then convert(decimal(15),valoare) end)) as [@R23_1]
					,max((case when Rand_decont='24' then convert(decimal(15),tva) end)) as [@R23_2]
					,max((case when Rand_decont='25' then convert(decimal(15),valoare) end)) as [@R23a_1]
					,max((case when Rand_decont='25' then convert(decimal(15),tva) end)) as [@R23a_2]
					,max((case when Rand_decont='26' then convert(decimal(15),valoare) end)) as [@R24_1]
					,max((case when Rand_decont='26.1' then convert(decimal(15),valoare) end)) as [@R24_1_1]
					,max((case when Rand_decont='27' then convert(decimal(15),valoare) end)) as [@R25_1]
					,max((case when Rand_decont='27' then convert(decimal(15),tva) end)) as [@R25_2]
					,max((case when Rand_decont='27.1' then convert(decimal(15),valoare) end)) as [@R25_1_1]
					,max((case when Rand_decont='27.1' then convert(decimal(15),tva) end)) as [@R25_1_2]
					,max((case when Rand_decont='28' then convert(decimal(15),tva) end)) as [@R26_2]
					,max((case when Rand_decont='29' then convert(decimal(15),tva) end)) as [@R27_2]
					,max((case when Rand_decont='30' then convert(decimal(15),valoare) end)) as [@R28_1]
					,max((case when Rand_decont='30' then convert(decimal(15),tva) end)) as [@R28_2]
					,max((case when Rand_decont='31' then convert(decimal(15),tva) end)) as [@R29_2]
					,max((case when Rand_decont='32' then convert(decimal(15),tva) end)) as [@R30_2]
					,max((case when Rand_decont='33' then convert(decimal(15),tva) end)) as [@R31_2]
					,max((case when Rand_decont='34' then convert(decimal(15),tva) end)) as [@R32_2]
					,max((case when Rand_decont='35' then convert(decimal(15),tva) end)) as [@R33_2]
					,max((case when Rand_decont='36' then convert(decimal(15),tva) end)) as [@R34_2]
					,max((case when Rand_decont='37' then convert(decimal(15),tva) end)) as [@R35_2]
					,max((case when Rand_decont='38' then convert(decimal(15),tva) end)) as [@R36_2]
					,max((case when Rand_decont='39' then convert(decimal(15),tva) end)) as [@R37_2]
					,max((case when Rand_decont='40' then convert(decimal(15),tva) end)) as [@R38_2]
					,max((case when Rand_decont='41' then convert(decimal(15),tva) end)) as [@R39_2]
					,max((case when Rand_decont='42' then convert(decimal(15),tva) end)) as [@R40_2]
					,max((case when Rand_decont='50' and Valoare<>0 then convert(decimal(15),Valoare) end)) as [@nr_facturi]
					,max((case when Rand_decont='51' and Valoare<>0 then convert(decimal(15),Valoare) end)) as [@baza]
					,max((case when Rand_decont='52' and TVA<>0 then convert(decimal(15),tva) end)) as [@tva]
				from deconttva where data=@datasus
				group by Data
				for xml path('declaratie300'), type)
		
	--/*--> urmeaza scrierea fizica a fisierului:
	select @continutXmlChar='<?xml version="1.0"?>'+char(10)+replace(convert(varchar(max),@continutXml),'ptxmlns','xmlns')

--	salvez declaratia ca si continut in tabela declaratii
	if exists (select * from sysobjects where name ='scriuDeclaratii' and xtype='P')
		exec scriuDeclaratii @cod='300', @tip='0', @data=@datasus, @continut=@continutXmlChar

	if (@dinRia=1)
		exec salvareFisier @codXML=@continutXmlChar, @caleFisier=@caleFisier, @numeFisier=@fisier
	else
	begin
		--insert into ##tmpdecl values(@continutXmlChar)
		select @continutXmlChar as coloana into ##tmpdecl
		declare @nServer varchar(1000), @comandaBCP varchar(4000) /* comanda trebuie sa ramana varchar(4000) sau mai mica... */
		set @nServer=convert(varchar(1000),serverproperty('ServerName'))
		set @comandaBCP='bcp "select coloana from ##tmpdecl'+'" queryout "'+@caleCompletaFisier+'" -T -c -r -t -C UTF-8 -S '+@nServer
		declare @raspunsCmd int, @msgeroare varchar(1000)
		exec @raspunsCmd = xp_cmdshell @comandaBCP
		if @raspunsCmd != 0 /* xp_cmdshell returneaza 0 daca nu au fost erori, sau altfel, codul de eroare */
		begin
			set @msgeroare = 'Eroare la scrierea formularului pe hard-disk in locatia: '+ ( 
				case len(@Fisier) when 0 then 'NEDEFINIT' else @caleCompletaFisier end )
			raiserror (@msgeroare ,11 ,1)
		end
		else	/* trimit numele fisierului generat */ 
			select @fisier as fisier, 'wTipFormular' as numeProcedura for xml raw
	end
	--*/
end try
begin catch
	set @eroare='Procedura Declaratia300 (linia '+convert(varchar(20),ERROR_LINE())+') :'+ERROR_MESSAGE()
	raiserror(@eroare, 16, 1)
end catch

if object_id('tempdb.dbo.##tmpdecl') is not null drop table ##tmpdecl
	
if len(@eroare)>0 raiserror(@eroare,16,1)

/*
	exec Declaratia300 @data='06/01/2012', @nume_declar='MIHALACHE', @prenume_declar='Lucian', @functie_declar='Dir. economic', @pro_rata=100, @bifa_interne=0, @ramburs_tva=0, 
		@caleFisier='C:\D300_0512_J3504649.xml', @dinRia=1, @tip_D300='L', @optiunigenerare=0
*/
