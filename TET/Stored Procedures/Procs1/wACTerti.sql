--***
CREATE procedure wACTerti @sesiune varchar(50),@parXML XML
as
if exists(select * from sysobjects where name='wACTertiSP' and type='P')
begin
	exec wACTertiSP @sesiune, @parXML
	return 0
end
begin
	set transaction isolation level read uncommitted
	declare @subunitate varchar(9), @searchText varchar(80), @tip varchar(2), @subtip varchar(2), @valuta varchar(3), 
		@caFurn int, @caBenef int, @inValuta int, @userASiS varchar(10), @lista_clienti bit,@grupa varchar(3), @CodTertCodFisc bit, @dentip varchar(1)
	declare @raport varchar(100)
	exec luare_date_par 'GE', 'SUBPRO', 0, 0, @subunitate output
	exec luare_date_par 'GE', 'CFISCSUGE', @CodTertCodFisc output, 0, ''

	select @searchText=ISNULL(@parXML.value('(/row/@searchText)[1]', 'varchar(80)'), ''), 
		@tip=ISNULL(@parXML.value('(/row/@tip)[1]', 'varchar(2)'), ''), 
		@subtip=ISNULL(@parXML.value('(/row/@subtip)[1]', 'varchar(2)'), ''), 
		@valuta=ISNULL(@parXML.value('(/row/@valuta)[1]', 'varchar(3)'), ''),
		@grupa=ISNULL(@parXML.value('(/row/@grupa)[1]', 'varchar(3)'), ''),
		@raport=ISNULL(@parXML.value('(/row/@raport)[1]', 'varchar(100)'), ''),
		@dentip=ISNULL(@parXML.value('(/row/@dentip)[1]', 'varchar(1)'), '')

	if @dentip<>'' -- inseamna ca am apelat din nomenclator
		set @grupa=''

	set @searchText=REPLACE(@searchText, ' ', '%')
	set @caFurn=(case when @tip in ('RM', 'RS') or @tip in ('RE', 'DE', 'EF','DR') and (left(@subtip, 1)='P' and @subtip<>'PS' or @subtip='IS') then 1 else 0 end)
	set @caBenef=(case when @tip in ('AP', 'AS', 'PV') or @tip in ('RE', 'DE', 'EF') and (left(@subtip, 1)='I' and @subtip<>'IS' or @subtip='PS') then 1 else 0 end)

	--ca sa nu afiseze deodata ambele solduri
	if @caBenef=1 set @caFurn=0

	set @inValuta=(case when @subtip in ('PV', 'IV') or (@tip in ('RM', 'RS', 'AP', 'AS') or @tip in ('RE', 'DE', 'EF')) and @valuta<>'' then 1 else 0 end)
	
	--select @userASiS=id from utilizatori where observatii=SUSER_NAME()
	/*Modificare pentru login utilizator sa */
	EXEC wIaUtilizator @sesiune=@sesiune, @utilizator=@userASiS OUTPUT

	
	select @lista_clienti=0
	select @lista_clienti=1 
	from proprietati 
	where @tip in ('AP', 'AS', 'PV', 'BF', 'BK', 'BP') and tip='UTILIZATOR' and cod=@userASiS and cod_proprietate='CLIENT' and valoare<>''
	declare @areLOCMUNCA int
	set @areLOCMUNCA=0

	if (rtrim(@raport)='')
		set @areLOCMUNCA=dbo.f_areLMFiltru(@userASiS)
	--if exists (select 1 from par where Tip_parametru='GE' and Parametru='FLTTRTLM' and Val_logica=1) -- o factura are un singur loc de munca 
	
	select rtrim(terti.tert) as cod, rtrim(max(rtrim(terti.denumire)+(case when terti.tert<>terti.Cod_fiscal then ' (CF/CNP: '+RTRIM(terti.Cod_fiscal)+')' else '' end))) as denumire, 
	(case when 1=1 or @areLOCMUNCA=0  then
		(case when @caFurn=1 then 'Sold furn.: ' + ltrim(convert(varchar(20), convert(money, sum(case when facturi.tip=0x54 then (case when @inValuta=1 then facturi.sold_valuta else facturi.sold end) else 0 end)), 1))+' '+(case when @inValuta=1 then @valuta else 'lei' end) else '' end)
		+(case when @caFurn=1 and @caBenef=1 then ' / ' else '' end)
		+(case when @caBenef=1 then 'Sold ben.: ' + ltrim(convert(varchar(20), convert(money, sum(case when facturi.tip=0x46 then (case when @inValuta=1 then facturi.sold_valuta else facturi.sold end) else 0 end)), 1))+' '+(case when @inValuta=1 then @valuta else 'lei' end)  else '' end)
	else '' end ) as info
	-- urmeaaza un subselect care ar putea fi inlocuit cu un #
	from (select top 100 tert, denumire, Cod_fiscal
			from terti
			left join (select cu.Valoare from proprietati cu where cu.tip='UTILIZATOR' and cu.cod=@userASiS and cu.cod_proprietate='CLIENT') cu on cu.valoare=terti.tert 
			where terti.subunitate=@subunitate 
			and (@grupa='' or terti.grupa=@grupa)
			and (terti.denumire+terti.cod_fiscal like '%'+@searchText+'%' or terti.tert like @searchText+'%' 
				or rtrim(terti.Cod_fiscal) like @searchText+'%')
			and (@lista_clienti=0 or cu.Valoare is not null)
		) terti 
	--left join facturi on facturi.subunitate=@subunitate and facturi.tert=terti.tert
	left join  -- urmeaaza un alt subselect care ar putea fi inlocuit cu un #
	(select subunitate,tert,tip,sold_valuta,sold,valuta,Loc_de_munca 
			from facturi f where @areLOCMUNCA=0 or exists (select 1 from LMFiltrare lu where lu.utilizator=@userASiS and lu.cod=f.Loc_de_munca)
			) facturi  -- sa ia din facturi doar cele de pe locurile de munca de filtrare
		on facturi.subunitate=@subunitate and facturi.tert=terti.tert
		--daca vrem sa afiseze deodata ambele solduri...
		and (@caFurn+@caBenef<>1 or facturi.Tip=(case when @caFurn=1 then 0x54 else 0x46 end))
		and (@inValuta=0 or facturi.valuta=@valuta)
	group by terti.tert
	order by patindex(@searchText+'%',terti.tert) desc, 
		patindex('%'+@searchText+'%',max(terti.Denumire)+terti.tert)--, 2
	for xml raw
	
end
