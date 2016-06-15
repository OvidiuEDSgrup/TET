--***
create procedure [dbo].[wCalcElemActivitatiModel] @sesiune varchar(50),@document XML output, @faraValidari bit=0
as      
declare @tip varchar(2), @fisa varchar(10), @data datetime, @numar_pozitie int, @masina varchar(20), @lunaCurenta int,
		@tipAnt char(2), @fisaAnt varchar(20), @dataAnt datetime, @pozAnt int, @subtip varchar(2), @traseu varchar(50), @marca_antet varchar(50), @RestDecl float,
		@plecare varchar(50), @sosire varchar(50), @data_plecarii varchar(50), @ora_plecarii varchar(50), @data_sosirii varchar(50), @ora_sosirii varchar(50),
		@comanda_benef varchar(50), @lm_benef varchar(50),
		@KmBordAnterior float, @RestEstAnterior float, @RestEstUtilajAnterior float, @ORENOUAnterior float
,/* declaratii elemente */
/* FP */  @ConsComb float , @KmEchv float, @KmEf float, @KmBord float, @RestEst float, @AlimComb float, @Curse int, @KmEf1 float,
@KmEf2 float, @KmEf3 float, 
/* FL */ @RestEstUtilaj float, @ConsCombU float, @oreEchiv float, @OreLucruEfectiv float, @OreSchimbareLocLucru float,
@AlimComb_U float  , @ORENOU float
,/* declaratii coeficienti masina*/
@consumOra float, @Consum100 float, @capRezervor float, @coefAnotimp float, @coefVara float, @coefIarna float, @coefKm1 float, @coefKm2 float, @coefKm3 float

/* citesc valori elemente din XML */ 
select	/* antet */
		@tip = isnull(@document.value('(/row/@tip)[1]', 'char(2)'),0),
		@fisa = isnull(@document.value('(/row/@fisa)[1]', 'varchar(20)'),0),
		@data = isnull(@document.value('(/row/@data)[1]', 'datetime'),0),
		@masina = isnull(@document.value('(/row/@masina)[1]', 'varchar(20)'),''),
		@marca_antet = isnull(@document.value('(/row/@marca)[1]', 'varchar(50)'),''),
		
		/* pozitii */
		@traseu= isnull(@document.value('(/row/row/@traseu)[1]', 'varchar(50)'),0),
		@numar_pozitie = isnull(@document.value('(/row/row/@numar_pozitie)[1]', 'int'),99999999),
		@subtip = isnull(@document.value('(/row/row/@subtip)[1]', 'char(2)'),0),
		@RestDecl = isnull(@document.value('(/row/row/@RestDecl)[1]', 'float'),0),
		@plecare = isnull(@document.value('(/row/row/@plecare)[1]', 'varchar(50)'),0),
		@data_plecarii = isnull(@document.value('(/row/row/@data_plecarii)[1]', 'varchar(50)'),0),
		@ora_plecarii = isnull(@document.value('(/row/row/@ora_plecarii)[1]', 'varchar(50)'),0),
		@sosire = isnull(@document.value('(/row/row/@sosire)[1]', 'varchar(50)'),0),
		@data_sosirii = isnull(@document.value('(/row/row/@data_sosirii)[1]', 'varchar(50)'),0),
		@ora_sosirii = isnull(@document.value('(/row/row/@ora_sosirii)[1]', 'varchar(50)'),0),
		@comanda_benef = isnull(@document.value('(/row/row/@comanda_benef)[1]', 'varchar(50)'),0),
		@lm_benef = isnull(@document.value('(/row/row/@lm_benef)[1]', 'varchar(50)'),0),
		
		/* FP */
		@kmEf = isnull(@document.value('(/row/row/@KmEf)[1]', 'float'),0),
		@kmEf1 = isnull(@document.value('(/row/row/@KmEf1)[1]', 'float'),0),
		@kmEf2 = isnull(@document.value('(/row/row/@KmEf2)[1]', 'float'),0),
		@kmEf3 = isnull(@document.value('(/row/row/@KmEf3)[1]', 'float'),0),
		@AlimComb = isnull(@document.value('(/row/row/@AlimComb)[1]', 'float'),0),
		@Curse= isnull(@document.value('(/row/row/@Curse)[1]', 'float'),0),		
		
		/* FL */
		@OreLucruEfectiv = isnull(@document.value('(/row/row/@OLE)[1]', 'float'),0),
		@OreSchimbareLocLucru = isnull(@document.value('(/row/row/@OSL)[1]', 'float'),0),
		@AlimComb_U = isnull(@document.value('(/row/row/@ALIMCOMB_U)[1]', 'float'),0)
		
		
/* citesc coeficienti masina din tabela coef */
select	@consumOra = sum(case when Coeficient='CO' then Valoare else 0 end), 
		@Consum100 = sum(case when Coeficient='C100' then Valoare else 0 end), 
		@capRezervor = sum(case when Coeficient='cRezervor' then Valoare else 0 end), 
		@coefVara = sum(case when Coeficient='cVara' then Valoare else 0 end), 
		@coefIarna = sum(case when Coeficient='cIarna' then Valoare else 0 end),
		@coefKm1 = sum(case when Coeficient='cKmEf1' then Valoare else 0 end), 
		@coefKm2 = sum(case when Coeficient='cKmEf2' then Valoare else 0 end), 
		@coefKm3 = sum(case when Coeficient='cKmEf3' then Valoare else 0 end)
from coefmasini
where Masina = @masina
group by Masina

if @faraValidari=0  /* nu se fac validari pt. operatia de recalculare */
begin
	/* validare ora plecare si sosire in mai multe formate */
	if LEN(@ora_plecarii)>0 and ISNUMERIC(replace(@ora_plecarii,':',''))=0 or len(@ora_sosirii)>0 and ISNUMERIC(replace(@ora_sosirii,':',''))=0
		raiserror('Caractere ilegale in campurile ora plecare sau sosire!',11,1)

	select	@ora_plecarii=REPLACE(rtrim(@ora_plecarii),' ','0'),
			@ora_sosirii=REPLACE(rtrim(@ora_sosirii),' ','0')
	if SUBSTRING(@ora_plecarii,2,1)=':' or len(@ora_plecarii)=1 or len(@ora_plecarii)=3  set @ora_plecarii='0'+@ora_plecarii
	if SUBSTRING(@ora_sosirii,2,1)=':' or len(@ora_sosirii)=1 or len(@ora_sosirii)=3  set @ora_sosirii='0'+@ora_sosirii
	select	@ora_plecarii=SUBSTRING(REPLACE(rtrim(@ora_plecarii),':','')+'    ',1,4),
			@ora_sosirii=SUBSTRING(REPLACE(rtrim(@ora_sosirii),':','')+'    ',1,4)
	select	@ora_plecarii=REPLACE(@ora_plecarii,' ','0'),
			@ora_sosirii=REPLACE(@ora_sosirii,' ','0')

	if @document.exist('(/row/row/@ora_plecarii)[1]' ) = 1
		set @document.modify('replace value of (/row/row/@ora_plecarii)[1]	with sql:variable("@ora_plecarii")')
	else
		set @document.modify ('insert attribute ora_plecarii {sql:variable("@ora_plecarii")} as last into (/row/row)[1]') 
	if @document.exist('(/row/row/@ora_sosirii)[1]' ) = 1
		set @document.modify('replace value of (/row/row/@ora_sosirii)[1]	with sql:variable("@ora_sosirii")')
	else
		set @document.modify ('insert attribute ora_sosirii {sql:variable("@ora_sosirii")} as last into (/row/row)[1]') 
		

		/* alte validari */
	if @masina='' raiserror('Nu ati introdus in antet masina', 11, 1)
	if @marca_antet='' raiserror('Nu ati introdus in antet angajatul', 11, 1)

	if @tip = 'FP' and @subtip='CU'
	begin
		if @plecare='' raiserror('Nu ati introdus in pozitii locul de plecare', 11, 1)
		if @sosire='' raiserror('Nu ati introdus in pozitii locul de sosire', 11, 1)
	end 

	if @subtip<>'RS' /* la subtipul RS - rest, nu verific nimic */
	begin
		if convert(int,SUBSTRING(@ora_plecarii,3,2))>59 or convert(int,SUBSTRING(@ora_sosirii,3,2))>59 or 
			convert(int,SUBSTRING(@ora_plecarii,1,2))>24 or convert(int,SUBSTRING(@ora_sosirii,1,2))>24
			raiserror('Data plecarii sau ora plecarii incorect introduse', 11, 1)
		if @comanda_benef='' and @lm_benef='' raiserror('Introduceti loc de munca sau comanda beneficiar in pozitie.', 11, 1)
	end
end


/* gasesc ultima pozitie lucrata de masina */
	/* caut pozitie anterioara pe aceeasi fisa */
select @tipAnt=null, @fisaAnt=null, @dataAnt=null, @pozAnt=null
if exists (select 1 from elemactivitati ea where ea.Tip=@tip and ea.Fisa=@fisa and ea.Data=@data and ea.Numar_pozitie<@numar_pozitie)
	select top 1 @tipAnt=tip, @fisaAnt=fisa, @dataAnt=Data, @pozAnt=Numar_pozitie
	from elemactivitati ea where ea.Tip=@tip and ea.Fisa=@fisa and ea.Data=Data and ea.Numar_pozitie<@numar_pozitie
	order by Numar_pozitie desc
else /* gasesc ultima pozitie lucrata de pe fisa anterioara pt. masina */
	select top 1 @tipAnt=a.tip, @fisaAnt=a.fisa, @dataAnt=a.Data, @pozAnt=pa.Numar_pozitie
	from pozactivitati pa, activitati a where a.Tip=pa.Tip and a.Fisa=pa.Fisa and a.Data=pa.Data and 
	a.Masina=@masina and pa.Tip=@tip and pa.Data<=@data and (pa.Data<@data or pa.Fisa<@fisa)
	order by pa.Data desc, pa.fisa desc, Numar_pozitie desc

if @fisaAnt is not null /* iau valori de pe ultima pozitie lucrata de masina */
	select	@RestEstAnterior = sum(case when Element='RestEst' then Valoare else 0 end ),
			@KmBordAnterior =  sum(case when Element='KmBord' then Valoare else 0 end ),
			@RestEstUtilajAnterior =  sum(case when Element='RESTESTU' then Valoare else 0 end ),
			@ORENOUAnterior =  sum(case when Element='ORENOU' then Valoare else 0 end )
		from elemactivitati where tip=@tipAnt and fisa=@fisaAnt and Data=@dataAnt and Numar_pozitie=@pozAnt
else /* iau valori implementare daca nu am gasit fisa anterioara */
	select	@RestEstAnterior = sum(case when Element='RestEst' then Valoare else 0 end ),
			@KmBordAnterior =  sum(case when Element='KmBord' then Valoare else 0 end ),
			@RestEstUtilajAnterior =  sum(case when Element='RESTESTU' then Valoare else 0 end ),
			@ORENOUAnterior =  sum(case when Element='ORENOU' then Valoare else 0 end )
		from valelemimpl where Masina = @masina

/* pregatire elemente si coeficienti */
select	@Curse = (case when @Curse=0 then 1 else @Curse end),
		@coefKm1 = (case when @coefKm1=0 then 1 else @coefKm1 end),
		@coefKm2 = (case when @coefKm2=0 then 1 else @coefKm2 end),
		@coefKm3 = (case when @coefKm3=0 then 1 else @coefKm3 end)

select	@lunaCurenta = month(GETDATE()),
		@coefAnotimp = (CASE when @lunaCurenta between 3 and 10 then @coefVara else @coefIarna end)

	
if @subtip='TR' /* traseu */
begin
	if not exists (select 1 from trasee t where t.Cod = @traseu)
		raiserror ('Traseul ales nu poate fi gasit!',11,1)
		
		/* iau plecare si sosire din trasee si restul elementelor din dettrasee*/
	select @plecare = t.Plecare, @sosire = t.Sosire
	from trasee t where t.Cod = @traseu
	
	select	@KmEf1 = SUM(case when dt.Element = 'KmEf1' then dt.Valoare else 0 end),
			@KmEf2 = SUM(case when dt.Element = 'KmEf2' then dt.Valoare else 0 end),
			@KmEf3 = SUM(case when dt.Element = 'KmEf3' then dt.Valoare else 0 end)
	from dettrasee dt where dt.Cod = @traseu
	
	if @document.exist('(/row/row/@plecare)[1]' ) = 1
		set @document.modify('replace value of (/row/row/@plecare)[1]	with sql:variable("@plecare")')
	else
		set @document.modify ('insert attribute plecare {sql:variable("@plecare")} as last into (/row/row)[1]') 

	if @document.exist('(/row/row/@sosire)[1]' ) = 1
		set @document.modify('replace value of (/row/row/@sosire)[1]	with sql:variable("@sosire")')
	else
		set @document.modify ('insert attribute sosire {sql:variable("@sosire")} as last into (/row/row)[1]') 

	if @document.exist('(/row/row/@KmEf1)[1]' ) = 1
		set @document.modify('replace value of (/row/row/@KmEf1)[1]	with sql:variable("@KmEf1")')
	else
		set @document.modify ('insert attribute KmEf1 {sql:variable("@KmEf1")} as last into (/row/row)[1]') 

	if @document.exist('(/row/row/@KmEf2)[1]' ) = 1
		set @document.modify('replace value of (/row/row/@KmEf2)[1]	with sql:variable("@KmEf2")')
	else
		set @document.modify ('insert attribute KmEf2 {sql:variable("@KmEf2")} as last into (/row/row)[1]') 

	if @document.exist('(/row/row/@KmEf3)[1]' ) = 1
		set @document.modify('replace value of (/row/row/@KmEf3)[1]	with sql:variable("@KmEf3")')
	else
		set @document.modify ('insert attribute KmEf3 {sql:variable("@KmEf3")} as last into (/row/row)[1]') 
		
end

if @subtip = 'RS' /* Rest rezervor */
begin
		/* restul declarat se trateaza in fiecare tip de pozitie; 
			aici scriu data si ora sosirii = data si ora plecarii */
	
	if @document.exist('(/row/row/@data_sosirii)[1]' ) = 1
		set @document.modify('replace value of (/row/row/@data_sosirii)[1]	with sql:variable("@data_plecarii")')
	else
		set @document.modify ('insert attribute data_sosirii {sql:variable("@data_plecarii")} as last into (/row/row)[1]') 
	
	if @document.exist('(/row/row/@ora_sosirii)[1]' ) = 1
		set @document.modify('replace value of (/row/row/@ora_sosirii)[1]	with sql:variable("@ora_plecarii")')
	else
		set @document.modify ('insert attribute ora_sosirii {sql:variable("@ora_plecarii")} as last into (/row/row)[1]') 
end

/* *** Elemente masini (FP) *** */
if @tip='FP' 
begin
	/* @KmEchv */
	set @KmEchv = round((@KmEf + @KmEf1 * @coefKm1 + @KmEf2 * @coefKm2 + @KmEf3 * @coefKm3) * @coefAnotimp,2)

	if @document.exist('(/row/row/@KmEchv)[1]' ) = 1
		set @document.modify('replace value of (/row/row/@KmEchv)[1]	with sql:variable("@KmEchv")')
	else
		set @document.modify ('insert attribute KmEchv {sql:variable("@KmEchv")} as last into (/row/row)[1]') 

	/* @KmEf - se introduce @KmEf la Trasee si @KmEf1, 2 sau 3 pt Curse - tratat dupa KmEchv pt. a nu influenta*/
	set @KmEf = @KmEf + @KmEf1 + @KmEf2 + @KmEf3 
	
	if @document.exist('(/row/row/@KmEf)[1]' ) = 1
		set @document.modify('replace value of (/row/row/@KmEf)[1]	with sql:variable("@KmEf")')
	else 
		set @document.modify ('insert attribute KmEf {sql:variable("@KmEf")} as last into (/row/row)[1]') 

	/* ConsComb */
	set @ConsComb = round(@Consum100 * (@KmEchv / 100) * @Curse,2)
	if @document.exist('(/row/row/@ConsComb)[1]' ) = 1
		set @document.modify('replace value of (/row/row/@ConsComb)[1]	with sql:variable("@ConsComb")')
	else
		set @document.modify ('insert attribute ConsComb {sql:variable("@ConsComb")} as last into (/row/row)[1]') 

	/* KmBord */
	set @KmBord = @KmBordAnterior + @kmEf
	if @document.exist('(/row/row/@KmBord)[1]' ) = 1
		set @document.modify('replace value of (/row/row/@KmBord)[1]	with sql:variable("@KmBord")')
	else
		set @document.modify ('insert attribute KmBord {sql:variable("@KmBord")} as last into (/row/row)[1]') 

	/* RestEst - formula MM (case when {RestDecl}<>0 then {RestDecl} else round({*RestEst}+{AlimComb}-{ConsComb}+{*RestDecl}+{RESTINVA},2) end) */
	set @RestEst = (case	
		when @restDecl<>0 then @RestDecl 
		else round(@RestEstAnterior + @AlimComb - @ConsComb,2)
		end )	
		
	if @document.exist('(/row/row/@RestEst)[1]' ) = 1
		set @document.modify('replace value of (/row/row/@RestEst)[1]	with sql:variable("@RestEst")')
	else
		set @document.modify ('insert attribute RestEst {sql:variable("@RestEst")} as last into (/row/row)[1]') 
end

	/* *** Elemente utilaje (FL) *** */
if @tip='FL'
begin
	/* @OEchv */	
	set @oreEchiv = @OreLucruEfectiv + @OreSchimbareLocLucru
	if @document.exist('(/row/row/@OEchv)[1]' ) = 1
		set @document.modify('replace value of (/row/row/@OEchv)[1]	with sql:variable("@oreEchiv")')
	else
		set @document.modify ('insert attribute OEchv {sql:variable("@oreEchiv")} as last into (/row/row)[1]') 
		
	/* ConsCombU - ROUND({spAnotimp}*{CO}*{OEchv},2) */
	set @ConsCombU = round(@consumOra * @oreEchiv * @coefAnotimp,2)
	if @document.exist('(/row/row/@ConsCombU)[1]' ) = 1
		set @document.modify('replace value of (/row/row/@ConsCombU)[1]	with sql:variable("@ConsCombU")')
	else
		set @document.modify ('insert attribute ConsCombU {sql:variable("@ConsCombU")} as last into (/row/row)[1]') 

	/* RESTESTU - formula MM - nu e aplicata toata 
	(case when {RestDecl}<>0 then {RestDecl} else ROUND({*RESTESTU}+{ALIMCOMB U}-{ConsCombU}+{*RestDecl}+{RESTINVU},2) end) */
	set @RestEstUtilaj = (case	
		when @restDecl<>0 then @RestDecl 
		else round(@RestEstUtilajAnterior + @AlimComb_U - @ConsCombU,2)
		end )	
		
	if @document.exist('(/row/row/@RESTESTU)[1]' ) = 1
		set @document.modify('replace value of (/row/row/@RESTESTU)[1]	with sql:variable("@RestEstUtilaj")')
	else
		set @document.modify ('insert attribute RESTESTU {sql:variable("@RestEstUtilaj")} as last into (/row/row)[1]') 

	/* ORENOU ore lucrate utilaj*/
	set @ORENOU = @ORENOUAnterior + @OreLucruEfectiv+@OreSchimbareLocLucru
	if @document.exist('(/row/row/@ORENOU)[1]' ) = 1
		set @document.modify('replace value of (/row/row/@ORENOU)[1]	with sql:variable("@ORENOU")')
	else
		set @document.modify ('insert attribute ORENOU {sql:variable("@ORENOU")} as last into (/row/row)[1]') 

end
