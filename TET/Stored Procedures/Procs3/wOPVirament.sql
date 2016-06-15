--***
create procedure wOPVirament @sesiune varchar(50), @parXML xml 
as     
-- apelare procedura specifica daca aceasta exista.
if exists (select 1 from sysobjects where [type]='P' and [name]='wOPViramentSP')
begin 
	declare @returnValue int -- variabila salveaza return value de la procedura specifica
	exec @returnValue = wOPViramentSP @sesiune, @parXML output
	return @returnValue
end

declare @mesaj varchar(500),@utilizator varchar(20),@sub varchar(9),@cont1 varchar(40),@cont2 varchar(40),
	@cont_trecere varchar(40),@numar varchar(8),@data datetime,@suma float,@valuta varchar(3),
	@suma_valuta float,@lm varchar(13),@lmp varchar(13),@explicatii varchar(80), @curs_predare float, @curs_primire float,
	@valuta1 varchar(3),@valuta2 varchar(3), @sumaDifCurs float,@expprimite varchar(30)
begin try		
	EXEC wIaUtilizator @sesiune=@sesiune, @utilizator=@Utilizator OUTPUT
	
	exec luare_date_par 'GE', 'SUBPRO', 0, 0, @sub output
	select 
		@numar=upper(ISNULL(@parXML.value('(/parametri/@numar)[1]', 'varchar(8)'), '')),
		@data=ISNULL(@parXML.value('(/parametri/@data)[1]', 'datetime'), ''),
		@cont1=rtrim(ISNULL(@parXML.value('(/parametri/@cont1)[1]', 'varchar(40)'), '')),
		@cont2=rtrim(ISNULL(@parXML.value('(/parametri/@cont2)[1]', 'varchar(40)'), '')),
		@cont_trecere=ISNULL(@parXML.value('(/parametri/@cont_trecere)[1]', 'varchar(40)'), '581'),
		@suma=ISNULL(@parXML.value('(/parametri/@suma)[1]', 'float'), 0),
		@curs_predare=ISNULL(@parXML.value('(/parametri/@curs_predare)[1]', 'float'), 0),
		@curs_primire=ISNULL(@parXML.value('(/parametri/@curs_primire)[1]', 'float'), 0),
		@lm=ISNULL(@parXML.value('(/parametri/@lm)[1]', 'varchar(13)'), ''),
		@lmp=ISNULL(@parXML.value('(/parametri/@lmp)[1]', 'varchar(13)'), ''),
		@expprimite=ISNULL(@parXML.value('(/parametri/@expprimite)[1]', 'varchar(30)'), ''),
		@valuta=ISNULL(@parXML.value('(/parametri/@valuta_virament)[1]', 'varchar(3)'), '')				
	
	set @valuta1=isnull((select rtrim(valoare) from proprietati pr where pr.Tip='CONT' AND cod=@cont1 and Cod_proprietate='INVALUTA'),'')
	set @valuta2=isnull((select rtrim(valoare) from proprietati pr where pr.Tip='CONT' AND cod=@cont2 and Cod_proprietate='INVALUTA'),'')
	
	if @valuta1='RON' set @valuta1=''
	if @valuta2='RON' set @valuta2=''
	if @valuta='RON' set @valuta=''
	
	delete from webJurnalOperatii where obiectSql='wOPVirament'
	exec wJurnalizareOperatie @sesiune=@sesiune, @parXML=@parXML, @obiectSql='wOPVirament'

	if isnull(@numar,'')=''
	begin
		declare @fXML xml, @tipPentruNr varchar(2), @NrDocPrimit varchar(20)
		set @tipPentruNr='IB' 
		set @LM = (case when @LM is null then '' else @LM end)
		set @fXML = '<row/>'
		set @fXML.modify ('insert attribute tipmacheta {"DO"} into (/row)[1]')
		set @fXML.modify ('insert attribute tip {sql:variable("@tipPentruNr")} into (/row)[1]')
		set @fXML.modify ('insert attribute utilizator {sql:variable("@utilizator")} into (/row)[1]')
		set @fXML.modify ('insert attribute lm {sql:variable("@lm")} into (/row)[1]')
			
		exec wIauNrDocFiscale @parXML=@fXML, @Numar=@NrDocPrimit output
			
		if isnull(@NrDocPrimit,0)=0
			raiserror('Eroare generare numar de document. Plaja de numere folosita pentru acest tip de document s-a epuizat, sau nu este configurata!',16,1)
		set @numar=@NrDocPrimit
	end	
	
	if @valuta1<>@valuta2
		raiserror('Conturile de virament nu au aceasi valuta atribuita!',11,1)
	
	if @valuta1<>@valuta
		raiserror('Suma introdusa trebuie sa fie in valuta atribuita conturilor de virament!',11,1)
		
	if ISNULL(@valuta,'')<>'' and (ISNULL(@curs_predare,0)=0 or ISNULL(@curs_primire,0)=0)
		raiserror('Introduceti cursurile valutare pentru virament!',11,1)	
		
	set @explicatii='Virament:'+@cont1+' - '+@cont2+@expprimite
	declare @input XMl	
	set @input=(select top 1 1 as '@fara_luare_date', rtrim(@sub) as '@subunitate','RE' as '@tip',
					rtrim(@cont1) as '@cont', convert(char(10),@data,101) as '@data',
				
			(select  rtrim(@numar) as '@numar',
					rtrim(@cont_trecere) as '@contcorespondent', 
					'PD' as '@subtip',
					case when @valuta<>'' then 0 else convert(decimal(17,2),@suma) end as '@suma',
					case when @valuta<>'' then convert(decimal(17,2),@suma) else 0 end as '@sumavaluta',
					@explicatii as '@explicatii',
					RTRIM(@lm) as '@lm',
					@valuta as '@valuta',
					case when @valuta1<>'' then convert(decimal(12,5),@curs_predare) else 0 end as '@curs'				 
					for XML path,type)
				for xml Path,type)	 
	--select @input
	exec wScriuPozplin @sesiune,@input	
	
	declare @input1 XMl	
	set @input1=(select top 1 1 as '@fara_luare_date',
					rtrim(@sub) as '@subunitate','RE' as '@tip',
					rtrim(@cont2) as '@cont', convert(char(10),@data,101) as '@data',
				
				(select  rtrim(@numar) as '@numar',
					rtrim(@cont_trecere) as '@contcorespondent', 
					'ID' as '@subtip',
					case when @valuta<>'' then 0 else convert(decimal(17,2),@suma) end as '@suma',
					case when @valuta<>'' then convert(decimal(17,2),@suma) else 0 end as '@sumavaluta',
					@explicatii as '@explicatii',
					RTRIM(isnull(nullif(@lmp,''),@lm)) as '@lm',
					@valuta as '@valuta',
					case when @valuta2<>'' then convert(decimal(12,5),@curs_primire)else 0 end as '@curs'	
					for XML path,type)
				for xml Path,type)	 
	--select @input1
	exec wScriuPozplin @sesiune,@input1
	
	--tratare diferente de curs
	if ISNULL(@valuta,'')<>'' and abs(@curs_predare-@curs_primire)>0.01
	begin
		declare @input2 XMl, @CtCheltDifcF varchar(40),@CtVenDifcF varchar(40)
		exec luare_date_par 'GE', 'DIFCH', 0, 0, @CtCheltDifcF output  
		exec luare_date_par 'GE', 'DIFVE', 0, 0, @CtVenDifcF output  
		select @sumaDifCurs=@suma*@curs_predare-@suma*@curs_primire
		
		set @input2=(select top 1 1 as '@fara_luare_date', 
						rtrim(@sub) as '@subunitate','RE' as '@tip',
						rtrim(@cont2) as '@cont', convert(char(10),@data,101) as '@data',
					
					(select  rtrim(@numar) as '@numar',
						case when @sumaDifCurs>0 then @CtCheltDifcF else @CtVenDifcF end as '@contcorespondent', 
						case when @sumaDifCurs>0 then 'PD' else 'ID' end as '@subtip',
						convert(decimal(17,2),abs(@sumaDifCurs)) as '@suma',
						@explicatii+' dif.curs' as '@explicatii',
						RTRIM(@lm) as '@lm'
						for XML path,type)
					for xml Path,type)	 
		--select @input2
		exec wScriuPozplin @sesiune,@input2
	end	
	
	exec faInregistrariContabile @dinTabela=0,@subunitate=@sub,@tip='PI',@Numar=@cont1,@data=@data
	exec faInregistrariContabile @dinTabela=0,@subunitate=@sub,@tip='PI',@Numar=@cont2,@data=@data

	if isnull(@numar,'')<>'' 
		select 'Operatie efectuata cu succes!!' as textMesaj for xml raw, root('Mesaje')
end try
begin catch
	set @mesaj='(wOPVirament): ' +ERROR_MESSAGE()
end catch

if LEN(@mesaj)>0
	raiserror(@mesaj, 11, 1)
