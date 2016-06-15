--***
create procedure wACGestiuni @sesiune varchar(50), @parXML XML
as

if exists(select * from sysobjects where name='wACGestiuniSP' and type='P')      
	exec wACGestiuniSP @sesiune,@parXML      
else    
begin

	declare @subunitate varchar(9), @searchText varchar(80), @userASiS varchar(10), 
			@lista_gestiuni bit, @tip varchar(2),@subtip varchar(2),@faraRestrictiiProp int
		,@folosinta varchar(1),@raport varchar(200), @cale varchar(200), @tiprap varchar(20)
		,@cuImobilizari int	--> tip gestiune=imobilizare;
				-->	0=fara imobilizari, 1=doar imobilizari, 2=si imobilizari
		,@custodie int,@meniu varchar(2)
		,@dingestprim int --> @dingestprim=1 -> procedura este apelata din campul gestiune primitoare (permite si gestiuni de tip I).
		, @listatipuri varchar(100) 
	select @subunitate=val_alfanumerica from par where tip_parametru='GE' and parametru='SUBPRO'

	select	@tip=ISNULL(@parXML.value('(/row/@tip)[1]', 'varchar(2)'), ''), 
			@subtip=ISNULL(@parXML.value('(/row/@subtip)[1]', 'varchar(2)'), ''), 
			@searchText=ISNULL(@parXML.value('(/row/@searchText)[1]', 'varchar(80)'), ''),
			@faraRestrictiiProp=ISNULL(@parXML.value('(/row/@faraRestrictiiProp)[1]', 'int'), 0),
				-->daca se trimite =1 atunci sa se returneze toate gestiunile, netinandu-se cont de locurile de munca si gestiunile din proprietati
			
			--> parametri din Reporting
				@raport=isnull(@parXML.value('(/row/@raport)[1]','varchar(200)'),''),	--="Balanta stocuri"
				@cale=isnull(@parXML.value('(/row/@cale)[1]','varchar(200)'),''),
			@tiprap=isnull(isnull(@parXML.value('(/row/@tiprap)[1]','varchar(200)'),@parXML.value('(/row/@tipstoc)[1]','varchar(200)')),''),	--="F"
			@meniu=isnull(@parXML.value('(/row/@codMeniu)[1]','varchar(2)'),''),
			@dingestprim=isnull(@parXML.value('(/row/@dingestprim)[1]','int'),0), 
			@listatipuri=@parXML.value('(/row/@listatipuri)[1]', 'varchar(100)')
			
	select	@folosinta=(case when ( ((@raport in ('Balanta stocuri','Stocuri la data') or @raport like '%folosinta%') and @tiprap='F') or (@meniu='DO' and @tip='CI')) then 1 else 0 end),

			@custodie=(case when @raport in ('Balanta stocuri','Stocuri la data') and @tiprap='T' then 1 else 0 end),
			@cuImobilizari=(case when @tip in ('MI','MT','MF','X') or @tip='RM' and @subtip='MF' or charindex('I',@listatipuri)<>0 then 1	-->Permis pentru meniul de Documente Imobilizari.
								 when @raport <>'' and @cale<>'' and (charindex(' MF ',@cale)>0 or charindex('Imobilizari',@cale)>0
										or charindex('/MF/',@cale)>0) 		--> pentru rapoartele de Mf se iau si gestiuni de tip imobilizari
										or @dingestprim=1					--> daca procedura este apelata din campul gestiune primitoare se iau si gestiuni de imobilizari (AROBS)
										or @tip='RM' or @tip='TE' then 2	--> pentru Transferuri, permis si gestiuni de tip I (Imobilizari) - Arobs 
								else 0 end) --pt. tip=MF (mijloace fixe la impl.) permis si gestiuni de tip I (Imobilizari)

	set @searchText=REPLACE(@searchText, ' ', '%')
	/*	--	test:	<
			select @cuImobilizari, @cale, @raport,charindex('/MF/',@cale)
	--/test>	*/

	--select @userASiS=id from utilizatori where observatii=SUSER_NAME()
	/*Modificare pentru login utilizator sa */
	EXEC wIaUtilizator @sesiune=@sesiune, @utilizator=@userASiS OUTPUT

	--select @lista_gestiuni=0
	--select @lista_gestiuni=1 from proprietati where tip='UTILIZATOR' and cod=@userASiS and cod_proprietate='GESTIUNE' and valoare<>''
		/**	Pregatire filtrare pe proprietati utilizatori*/
	declare @GestUtiliz table(valoare varchar(200), cod_proprietate varchar(20))
	insert into @GestUtiliz(valoare, cod_proprietate)
	select valoare, cod_proprietate from fPropUtiliz(@sesiune) where valoare<>'' and cod_proprietate='GESTIUNE'
	set @lista_gestiuni=isnull((select max(1) from @GestUtiliz),0)

	if (@custodie=1) exec wACTerti @sesiune=@sesiune, @parXML=@parXML
	else
	select top 100 rtrim(Cod_gestiune) as cod, rtrim(Denumire_gestiune) as denumire, 
	rtrim(case when gestiuni.Cont_contabil_specific='' then 
		(case gestiuni.Tip_gestiune when 'M' then 'Materiale' when 'P' then 'Produse' when 'C' then 'Cantitativa' when 'A' then 'Amanuntul' when 'V' then 'Valorica' when 'O' then 'Obiecte' when 'F' then 'Folosinta' when 'I' then 'Imobilizari' else gestiuni.Tip_gestiune end)
		else 'Tip ' + gestiuni.Tip_gestiune + ' (Ct. ' + RTrim(gestiuni.Cont_contabil_specific) + ')' end) as info
	from gestiuni 
	--left outer join proprietati gu on gu.valoare=gestiuni.cod_gestiune and gu.tip='UTILIZATOR' and gu.cod=@userASiS and gu.cod_proprietate='GESTIUNE'
	where subunitate=@subunitate and @folosinta=0 
		and (cod_gestiune like @searchText + '%' or denumire_gestiune like '%' + @searchText + '%')
	--and (@lista_gestiuni=0 or gu.Valoare is not null) 
		and ((@lista_gestiuni=0 or exists (select 1 from @GestUtiliz u where u.valoare=Cod_gestiune))or @faraRestrictiiProp=1)
	-- mai jos am corectat in: gestiuni tip I daca intrari/transferuri de MF sau MF la implementare, in rest (deci nu MF): gestiuni tip ne I
		and (@raport<>'' or @tip='RM' or @tip='TE' and @dingestprim=0 or @dingestprim=1 
				or (@tip in ('MI','MT','MF','X') or charindex('I',@listatipuri)<>0) and Tip_gestiune='I' or @tip not in ('MI','MT','MF') and Tip_gestiune<>'I')
		and (@cuImobilizari=2 or @cuImobilizari=1 and Tip_gestiune='I' or @cuImobilizari=0 and Tip_gestiune<>'I')
		and (@listatipuri is null or charindex(tip_gestiune,@listatipuri)<>0)
	union all 
	select p.Marca as cod, RTRIM(p.Nume) as denumire,'Folosinta '+RTRIM(p.Loc_de_munca) as info 
	from personal p
		where @folosinta=1 and (p.marca like @searchText + '%' or p.nume like '%' + @searchText + '%')
			--and (@lista_gestiuni=0 or exists (select 1 from @GestUtiliz u where u.valoare=p.Marca))
			AND ((dbo.f_arelmfiltru(@userASiS)=0 OR p.Loc_de_munca IN (SELECT cod FROM dbo.LMFiltrare WHERE utilizator=@userASiS))or @faraRestrictiiProp=1)
			and (@listatipuri is null or charindex('F',@listatipuri)<>0)
	order by cod
		--order by trebuie sa ramana cod(_gestiune) pentru ca functia CautaIndexat sa functioneze
	for xml raw
end
