--***
create procedure wCalcElemActivitati @sesiune varchar(50),@parXML XML output, @faraValidari bit=0
as  
declare @eroare varchar(2000)
set @eroare=''
begin try
if exists(select * from sysobjects where name='wCalcElemActivitatiSP' and type='P')      
	exec wCalcElemActivitatiSP @sesiune,@parXML      
else
begin 
declare @tip varchar(2), @fisa varchar(10), @data datetime, @numar_pozitie int, @masina varchar(20), @tip_activitate varchar(1), @lunaCurenta int, @implementare bit,
		@tipAnt char(2), @fisaAnt varchar(20), @dataAnt datetime, @pozAnt int, @subtip varchar(2), @traseu varchar(50), @marca_antet varchar(50), @RestDecl float,
		@plecare varchar(50), @sosire varchar(50), @data_plecarii varchar(50), @ora_plecarii varchar(50), @data_sosirii varchar(50), @ora_sosirii varchar(50),
		@comanda_benef varchar(50), @lm_benef varchar(50),
		@KmBordAnterior float, @RestEstAnterior float, @RestEstUtilajAnterior float, @OREBORDAnterior float,@KmEfAnterior float,
		@KmEchvAnterior float,

/* declaratii elemente */
/* FP */  @ConsComb float , @KmEchv float, @KmEf float, @KmBord float, @RestEst float, @AlimComb float, @Curse int, @KmEf1 float,
@KmEf2 float, @KmEf3 float, 

/* FL */ @RestEstUtilaj float, @ConsCombU float, @oreEchiv float, @OreLucruEfectiv float, @OreSchimbareLocLucru float,
@AlimComb_U float  , 

/* declaratii coeficienti masina*/
@consumOra float, @Consum100 float, @capRezervor float, @coefAnotimp float, @coefVara float, @coefIarna float, @coefKm1 float, @coefKm2 float, @coefKm3 float, 

/* Ghita, 03.07.2012: coeficient de conditii - se poate opera */
@coefCond float

/* citesc valori elemente din XML */ 
select	/* antet */
		@tip = isnull(@parXML.value('(/row/@tip)[1]', 'char(2)'),0),
		@fisa = isnull(@parXML.value('(/row/@fisa)[1]', 'varchar(20)'),0),
		@data = isnull(@parXML.value('(/row/@data)[1]', 'datetime'),0),
		@masina = isnull(@parXML.value('(/row/@masina)[1]', 'varchar(20)'),''),
		@marca_antet = isnull(@parXML.value('(/row/@marca)[1]', 'varchar(50)'),''),
		@implementare = isnull(@parXML.value('(/row/@implementare)[1]', 'bit'),'0'),
		
		/* pozitii */
		@traseu= isnull(@parXML.value('(/row/row/@traseu)[1]', 'varchar(50)'),0),
		@numar_pozitie = isnull(@parXML.value('(/row/row/@numar_pozitie)[1]', 'int'),99999999),
		@subtip = isnull(@parXML.value('(/row/row/@subtip)[1]', 'char(2)'),0),
		@RestDecl = isnull(@parXML.value('(/row/row/@RestDecl)[1]', 'float'),0),
		@plecare = isnull(@parXML.value('(/row/row/@plecare)[1]', 'varchar(50)'),0),
		@data_plecarii = isnull(@parXML.value('(/row/row/@data_plecarii)[1]', 'varchar(50)'),'1901-1-1'),
		@ora_plecarii = isnull(@parXML.value('(/row/row/@ora_plecarii)[1]', 'varchar(50)'),0),
		@sosire = isnull(@parXML.value('(/row/row/@sosire)[1]', 'varchar(50)'),0),
		@data_sosirii = isnull(@parXML.value('(/row/row/@data_sosirii)[1]', 'varchar(50)'),0),
		@ora_sosirii = isnull(@parXML.value('(/row/row/@ora_sosirii)[1]', 'varchar(50)'),0),
		@comanda_benef = isnull(@parXML.value('(/row/row/@comanda_benef)[1]', 'varchar(50)'),''),
		@lm_benef = isnull(@parXML.value('(/row/row/@lm_benef)[1]', 'varchar(50)'),''),
		@coefCond= isnull(@parXML.value('(/row/row/@coefCond)[1]', 'float'),0),		
		@RestEstUtilaj= isnull(@parXML.value('(/row/row/@RESTESTU)[1]', 'float'),0),
		@RestEst= isnull(@parXML.value('(/row/row/@RestEst)[1]', 'float'),0),
		/* FP */
		@KmBord = isnull(@parXML.value('(/row/row/@KmBord)[1]', 'float'),0),
		@kmEf = isnull(@parXML.value('(/row/row/@KmEf)[1]', 'float'),0),
		@kmEf1 = isnull(@parXML.value('(/row/row/@KmEf1)[1]', 'float'),0),
		@kmEf2 = isnull(@parXML.value('(/row/row/@KmEf2)[1]', 'float'),0),
		@kmEf3 = isnull(@parXML.value('(/row/row/@KmEf3)[1]', 'float'),0),
		@AlimComb = isnull(@parXML.value('(/row/row/@AlimComb)[1]', 'float'),0),
		@Curse= isnull(@parXML.value('(/row/row/@Curse)[1]', 'float'),0),		
		
		/* FL */
		@OreLucruEfectiv = isnull(@parXML.value('(/row/row/@OL)[1]', 'float'),0),
		@OreSchimbareLocLucru = isnull(@parXML.value('(/row/row/@OSL)[1]', 'float'),0),
		@AlimComb_U = isnull(@parXML.value('(/row/row/@ALIMCOMB_U)[1]', 'float'),0)
		
select @tip_activitate=t.Tip_activitate 
	from masini m 
	inner join grupemasini g on m.grupa=g.Grupa
	inner join tipmasini t on g.tip_masina=t.Cod
	where m.cod_masina=@masina
if (rtrim(@masina)='')	raiserror('Masina nu a putut fi identificata!',16,1)
		
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
	/* validare ora plecare si sosire in mai multe formate 
	se va scrie in baza de date formatul corect pentru ora_plecarii si ora_sosirii*/
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

	if @parXML.exist('(/row/row/@ora_plecarii)[1]' ) = 1
		set @parXML.modify('replace value of (/row/row/@ora_plecarii)[1]	with sql:variable("@ora_plecarii")')
	else
		set @parXML.modify ('insert attribute ora_plecarii {sql:variable("@ora_plecarii")} as last into (/row/row)[1]') 
	if @parXML.exist('(/row/row/@ora_sosirii)[1]' ) = 1
		set @parXML.modify('replace value of (/row/row/@ora_sosirii)[1]	with sql:variable("@ora_sosirii")')
	else
		set @parXML.modify ('insert attribute ora_sosirii {sql:variable("@ora_sosirii")} as last into (/row/row)[1]') 

	/* alte validari */
	if @masina='' 
			   raiserror('Nu ati introdus in antet masina', 11, 1)
	
	/* Nu prea inteleg rostul acestor validari de mai jos
	if @marca_antet='' and @tip<>'FI'and @tip<>'FP' and @implementare=0
					   raiserror('Nu ati introdus in antet angajatul', 11, 1)
	if @comanda_benef='' and @lm_benef='' and @tip<>'FI' and @tip<>'FP' and @implementare=0
						 raiserror('Introduceti loc de munca sau comanda beneficiar in pozitie.', 11, 1)
	if @tip = 'FP' and @subtip='CU'
	begin
		if @plecare='' raiserror('Nu ati introdus in pozitii locul de plecare', 11, 1)
		if @sosire=''  raiserror('Nu ati introdus in pozitii locul de sosire', 11, 1)
	end 
	if @subtip<>'RS' /* la subtipul RS - rest, nu verific nimic */
	begin
		if convert(int,SUBSTRING(@ora_plecarii,3,2))>59 or convert(int,SUBSTRING(@ora_sosirii,3,2))>59 or 
		   convert(int,SUBSTRING(@ora_plecarii,1,2))>24 or convert(int,SUBSTRING(@ora_sosirii,1,2))>24
							 raiserror('Data plecarii sau ora plecarii incorect introduse', 11, 1)
	end
	*/
end

/* gasesc ultima pozitie lucrata de masina */
	/* caut pozitie anterioara pe aceeasi fisa */
select top 1 @tipAnt=a.tip, @fisaAnt=a.fisa, @dataAnt=a.Data, @pozAnt=pa.Numar_pozitie
	from pozactivitati pa 
	inner join activitati a on a.tip=pa.tip and a.Fisa=pa.Fisa and a.data=pa.data
	where a.masina=@masina --and a.Tip=@tip
		and (pa.Data<@data or pa.Data=@data and (pa.Data_plecarii<@data_plecarii or pa.Data_plecarii=@data_plecarii and pa.Ora_plecarii<@ora_plecarii))
	order by pa.data desc, pa.data_plecarii desc, pa.ora_plecarii desc, pa.numar_pozitie desc

select @RestEstAnterior = 0,
			@KmBordAnterior = 0,
			@RestEstUtilajAnterior = 0,
			@OREBORDAnterior = 0,
			@KmEfAnterior = 0,
			@KmEchvAnterior = 0
if @fisaAnt is not null /* iau valori de pe ultima pozitie lucrata de masina */
	select	@RestEstAnterior = sum(case when Element='RestEst' then Valoare else 0 end ),
			@KmBordAnterior =  sum(case when Element='KmBord' then Valoare else 0 end ),
			@RestEstUtilajAnterior =  sum(case when Element='RESTESTU' then Valoare else 0 end ),
			@OREBORDAnterior =  sum(case when Element='OREBORD' then Valoare else 0 end ),
			@KmEfAnterior = 0, --sum(case when Element='KmEf' then Valoare else 0 end ),
			@KmEchvAnterior = 0 --sum(case when Element='KmEchv' then Valoare else 0 end )
		from elemactivitati where tip=@tipAnt and fisa=@fisaAnt and Data=@dataAnt and Numar_pozitie=@pozAnt

/* pregatire elemente si coeficienti */
select	@Curse = (case when @Curse=0 then 1 else @Curse end),
		@coefCond = (case when @coefCond=0 then 1 else @coefCond end),
		@coefKm1 = (case when @coefKm1=0 then 0.9 else @coefKm1 end),
		@coefKm2 = (case when @coefKm2=0 then 1.0 else @coefKm2 end),
		@coefKm3 = (case when @coefKm3=0 then 1.1 else @coefKm3 end)

select	@lunaCurenta = month(GETDATE())
select	@coefAnotimp = (CASE when @lunaCurenta between 3 and 10 then @coefVara else @coefIarna end)
	
/* *** Elemente masini (FP) *** */
if @tip='FP'
begin
	set @KmEchv = @KmEchvAnterior+round((@KmEf1 * @coefKm1 + @KmEf2 * @coefKm2 + @KmEf3 * @coefKm3) * @coefAnotimp,2)
	if @parXML.exist('(/row/row/@KmEchv)[1]' ) = 0
		set @parXML.modify ('insert attribute KmEchv {sql:variable("@KmEchv")} as last into (/row/row)[1]') 

	set @KmEf = @KmEfAnterior + @KmEf1 + @KmEf2 + @KmEf3 
	if @parXML.exist('(/row/row/@KmEf)[1]' ) = 0
		set @parXML.modify ('insert attribute KmEf {sql:variable("@KmEf")} as last into (/row/row)[1]') 

	set @ConsComb = round(@Consum100 * (@KmEchv / 100) * @Curse * @coefCond,2)
	if @parXML.exist('(/row/row/@ConsComb)[1]' ) = 0
		set @parXML.modify ('insert attribute ConsComb {sql:variable("@ConsComb")} as last into (/row/row)[1]') 

	set @RestEst = (case when @restDecl<>0 then @RestDecl 
			else round(@RestEstAnterior + @AlimComb - @ConsComb,2)
		end)	
		
	if @parXML.exist('(/row/row/@RestEst)[1]' ) = 0
		set @parXML.modify ('insert attribute RestEst {sql:variable("@RestEst")} as last into (/row/row)[1]')
end
if @tip_activitate='P' --KMBord se trec la toate utilajele cu P
begin
	/* KmBord */
	set @KmBord = @KmBordAnterior + @Kmef
	if @parXML.exist('(/row/row/@KmBord)[1]' ) = 0
		set @parXML.modify ('insert attribute KmBord {sql:variable("@KmBord")} as last into (/row/row)[1]') 
end
	

/* *** Elemente utilaje (FL) *** */
if @tip='FL'
begin
	/* @OEchv */	
	set @oreEchiv = @OreLucruEfectiv + @OreSchimbareLocLucru
	if @parXML.exist('(/row/row/@OEchv)[1]' ) = 0
		set @parXML.modify ('insert attribute OEchv {sql:variable("@oreEchiv")} as last into (/row/row)[1]') 
		
	/* ConsCombU - ROUND({spAnotimp}*{CO}*{OEchv},2) */
	set @ConsCombU = round(@consumOra * @oreEchiv * @coefAnotimp,2)
	if @parXML.exist('(/row/row/@ConsCombU)[1]' ) = 0
		set @parXML.modify ('insert attribute ConsCombU {sql:variable("@ConsCombU")} as last into (/row/row)[1]') 

	/* RESTESTU - formula MM - nu e aplicata toata 
	(case when {RestDecl}<>0 then {RestDecl} else ROUND({*RESTESTU}+{ALIMCOMB U}-{ConsCombU}+{*RestDecl}+{RESTINVU},2) end) */
	set @RestEstUtilaj = (case when @restDecl<>0 then @RestDecl 
		else round(@RestEstUtilajAnterior + @AlimComb_U - @ConsCombU,2)
		end )	
		
	if @parXML.exist('(/row/row/@RESTESTU)[1]' ) = 0
		set @parXML.modify ('insert attribute RESTESTU {sql:variable("@RestEstUtilaj")} as last into (/row/row)[1]') 
end

declare @OREBORDpoz float
if @tip_activitate='L' and @parXML.exist('(/row/row/@OREBORD)[1]' ) = 0 and exists (select 1 from elemente where Cod='OREBORD') --nu exista calculat OREBORD
begin
	set @OREBORDpoz = isnull(@OREBORDAnterior,0) + @OreLucruEfectiv+@OreSchimbareLocLucru -- se calculeaza
	set @parXML.modify ('insert attribute OREBORD {sql:variable("@OREBORDpoz")} as last into (/row/row)[1]')  -- se insereaza in XML
end

if @tip_activitate='L' and @parXML.exist('(/row/row/@ORENOU)[1]' ) = 0 and exists (select 1 from elemente where Cod='ORENOU') --nu exista calculat ORENOU - RADJ
begin
	set @OREBORDpoz = isnull(@OREBORDAnterior,0) + @OreLucruEfectiv+@OreSchimbareLocLucru -- se calculeaza
	set @parXML.modify ('insert attribute ORENOU {sql:variable("@OREBORDpoz")} as last into (/row/row)[1]')  -- se insereaza in XML
end

end
end try
begin catch
	set @eroare=
		rtrim(ERROR_MESSAGE())+' (wCalcElemActivitati '+convert(varchar(20),ERROR_LINE())+')'
end catch

if len(@eroare)>0
	raiserror(@eroare,16,1)
