
create procedure yso_salvezExpedGenDoc @sesiune varchar(50), @parXML xml OUTPUT
as

declare
/*parametrii de expeditie:*/ 
	@utilizator varchar(20),@sub varchar(9),@tert varchar(13),
	@numarDoc varchar(13),@dataDoc datetime,@tipDoc varchar(2),
	
	@numedelegat varchar(30),@mijloctp varchar(30),@nrmijtransp varchar(20),@seriebuletin varchar(10),
	@numarbuletin varchar(10),@eliberatbuletin varchar(30),
	@iddelegat varchar(20), @prenumedelegat varchar(30), @ptupdate bit, @delegat varchar(30), 
	@data_expedierii datetime, @ora_expedierii varchar(6),@observatii varchar(200)
	, @nrformular varchar(10),@denformular varchar(50),@modPlata varchar(50),@denmodplata varchar(100)

begin try
	select
		@tert=ISNULL(@parXML.value('(/*/@tert)[1]', 'varchar(13)'), ''),
		@tipDoc=ISNULL(@parXML.value('(/*/@tipdoc)[1]', 'varchar(2)'), ''),
		@dataDoc=ISNULL(@parXML.value('(/*/@datadoc)[1]', 'datetime'), ''),
		@numarDoc=ISNULL(@parXML.value('(/*/@numardoc)[1]', 'varchar(13)'), ''),
	--date pentru expeditie	
		@iddelegat=upper(ISNULL(@parXML.value('(/*/@iddelegat)[1]', 'varchar(20)'), '')),
		@numedelegat=upper(ISNULL(@parXML.value('(/*/@numedelegat)[1]', 'varchar(20)'), '')),		
		@prenumedelegat=upper(ISNULL(@parXML.value('(/*/@prenumedelegat)[1]', 'varchar(30)'), '')),		
		@nrmijtransp=upper(ISNULL(@parXML.value('(/*/@nrmijltransp)[1]', 'varchar(10)'), '')),		
		@mijloctp=ISNULL(@parXML.value('(/*/@mijloctp)[1]', 'varchar(30)'), ''),
		@seriebuletin=upper(ISNULL(@parXML.value('(/*/@seriebuletin)[1]', 'varchar(10)'), '')),		
		@numarbuletin=upper(ISNULL(@parXML.value('(/*/@numarbuletin)[1]', 'varchar(10)'), '')),		
		@eliberatbuletin=upper(ISNULL(@parXML.value('(/*/@eliberatbuletin)[1]', 'varchar(30)'), '')),
		@ora_expedierii= replace(left(isnull(@parXML.value('(/*/@ora_expedierii)[1]','varchar(10)'),convert(varchar,getdate(),114)),8),':',''),
		@data_expedierii= isnull(@parXML.value('(/*/@data_expedierii)[1]','datetime'),GETDATE()),
		@observatii=upper(ISNULL(@parXML.value('(/*/@observatii)[1]', 'varchar(50)'), ''))
		,@modPlata=ISNULL(@parXML.value('(/*/@modPlata)[1]', 'varchar(50)'), '')
		,@denmodPlata=ISNULL(@parXML.value('(/*/@denModPlata)[1]', 'varchar(100)'), '')
		,@nrformular=upper(ISNULL(@parXML.value('(/*/@nrformular)[1]', 'varchar(10)'), ''))
		,@denformular=upper(ISNULL(@parXML.value('(/*/@denformular)[1]', 'varchar(50)'), ''))
	
	exec luare_date_par 'GE', 'SUBPRO', 0, 0, @sub output --> citire subunitate din proprietati       
  
	exec wIaUtilizator @sesiune=@sesiune, @utilizator=@utilizator output-->identificare utilizator pe baza sesiunii
	
	set @ptupdate=isnull((select 1 from infotert i	where Subunitate='C'+@sub and tert=@tert and Identificator=@iddelegat),0)		
	if @ptupdate=0 and @iddelegat<>''
	begin
		set @numedelegat=@iddelegat
		set @idDelegat= null
	end
	set @delegat=rtrim(@numeDelegat)+' '+LTRIM(@prenumedelegat)
	if @idDelegat is null
		select top 1 @idDelegat=Identificator, @ptupdate=1 from infotert i	where Subunitate='C'+@sub and tert=@tert and RTRIM(i.Descriere)=@delegat
	
	--if not exists (select top 1 Identificator from infotert i	where Subunitate='C'+@sub and tert=@tert and RTRIM(i.Descriere)=@numedelegat) 	
	declare @paramXmlString xml 
	set @paramXmlString = (select [update]=@ptupdate, identificator=@iddelegat, tert=@tert, nume=@numedelegat, prenume=@prenumedelegat
		, seriebuletin=@seriebuletin, numarbuletin=@numarbuletin,eliberatbuletin=@eliberatbuletin for xml raw, type)
	
	exec wScriuPersoaneContact @sesiune, @paramXmlString
	if isnull(@iddelegat,'')=''
		set @idDelegat= (select top 1 Identificator from infotert i	where Subunitate='C'+@sub and tert=@tert and RTRIM(i.Descriere)=@delegat)
	
	if not exists (select 1 from masinexp where Numarul_mijlocului = @nrmijtransp) and isnull(@nrmijtransp,'')<>''
		insert into masinexp(Numarul_mijlocului, Descriere, Furnizor, Delegat)
		values (@nrmijtransp, @mijloctp, @tert, @delegat)
	else
		update masinexp set Descriere=@mijloctp, Delegat=@delegat, Furnizor=@tert
		where Numarul_mijlocului=@nrmijtransp
		
	if object_id('temdb..#expeditie') is not null
		drop table #expeditie
	
	select tip='PROPUTILIZ', Cod=@Utilizator, Cod_proprietate='UltFormGenBK'+LTRIM(RTRIM(@tipDoc)), Valoare=isnull(@nrformular,''), Valoare_tupla=@denformular 
	into #expeditie where isnull(@nrformular,'')<>''
	union all
	select tip='TERT', Cod=@tert, Cod_proprietate='UltModPlataBK'+LTRIM(RTRIM(@tipDoc)), Valoare=isnull(@modPlata,''), Valoare_tupla=@denmodplata
	where isnull(@modPlata,'')<>''
	union all
	select tip='TERT', Cod=@tert, Cod_proprietate='UltMasina', Valoare=isnull(@nrmijtransp,''), Valoare_tupla=@mijloctp
	where isnull(@nrmijtransp,'')<>''
	union all
	select tip='TERT', Cod=@tert, Cod_proprietate='UltDelegat', Valoare=isnull(@idDelegat,''), Valoare_tupla=@delegat
	where isnull(@idDelegat,'')<>''
	
	delete pp
	from proprietati pp join #expeditie e  on e.tip=pp.Tip and e.Cod=pp.Cod and e.Cod_proprietate=pp.Cod_proprietate --and pp.Valoare_tupla=''
	
	insert proprietati (Tip,Cod,Cod_proprietate,Valoare,Valoare_tupla)
	select e.tip,e.Cod,e.Cod_proprietate,e.Valoare,e.Valoare_tupla 
	from #expeditie e 
		left join proprietati pp on e.tip=pp.Tip and e.Cod=pp.Cod and e.Cod_proprietate=pp.Cod_proprietate --and pp.Valoare_tupla=''
	where pp.Valoare is null
/*
	update pp
	set pp.valoare=e.valoare
	from proprietati pp 
		inner join #expeditie e on e.tip=pp.Tip and e.Cod=pp.Cod and e.Cod_proprietate=pp.Cod_proprietate and pp.Valoare_tupla=''
	where pp.valoare<>e.valoare
*/	
	if @numarDoc<>''
	begin
		if not exists (select 1 from anexadoc where Subunitate=@sub and tip=@tipDoc and numar=@numarDoc and Data=@datadoc)
			insert anexadoc
				(Subunitate, Tip, Numar, Data, Numele_delegatului, Seria_buletin, Numar_buletin, 
				Eliberat, Mijloc_de_transport, Numarul_mijlocului, Data_expedierii, Ora_expedierii, 
				Observatii, Punct_livrare, Tip_anexa)
			values (@sub, @tipDoc, @numarDoc, @datadoc, @delegat, @seriebuletin, @numarbuletin, @eliberatbuletin, 
				@mijloctp, @nrmijtransp, @data_expedierii, @ora_expedierii, @observatii, '', '')
		else--/*sp
			update anexadoc
			set Numele_delegatului=@delegat, Seria_buletin=@seriebuletin, Numar_buletin=@numarbuletin
				,Eliberat=@eliberatbuletin, Mijloc_de_transport=@mijloctp, Numarul_mijlocului=@nrmijtransp, Data_expedierii=@data_expedierii, Ora_expedierii=@ora_expedierii 
				,Observatii=@observatii, Punct_livrare=''
			where Subunitate=@sub and Tip=@tipDoc and Numar=@numarDoc and Data=@datadoc and Tip_anexa='' --sp*/

		if @tipDoc='AP' and not exists (select 1 from anexafac where Subunitate=@sub and Numar_factura=@numarDoc)
			insert anexafac
			(Subunitate,Numar_factura,Numele_delegatului,Seria_buletin,Numar_buletin,Eliberat,Mijloc_de_transport,
				Numarul_mijlocului,Data_expedierii,Ora_expedierii,Observatii)
			values (@sub, @numarDoc, @delegat, @seriebuletin, @numarbuletin, @eliberatbuletin, @mijloctp, 
					@nrmijtransp, @data_expedierii, @ora_expedierii, @observatii)   
		else --/*sp
			update anexafac
			set Numele_delegatului=@delegat,Seria_buletin=@seriebuletin,Numar_buletin=@numarbuletin,Eliberat=@eliberatbuletin
				,Mijloc_de_transport=@mijloctp,Numarul_mijlocului=@nrmijtransp,Data_expedierii=@data_expedierii,Ora_expedierii=@ora_expedierii,Observatii=@observatii
			where Subunitate=@sub and Numar_factura=@numarDoc --sp*/
	end
end try 
begin catch 
	declare @eroare varchar(250)
	set @eroare='(yso_salvezExpedGenDoc): '+ERROR_MESSAGE() 
	raiserror(@eroare, 16, 1)
end catch 