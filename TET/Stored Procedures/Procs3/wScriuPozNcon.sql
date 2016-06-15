--***
create procedure wScriuPozNcon @sesiune varchar(50), @parXML xml 
as 

declare @tip char(2), @numar char(13), @data datetime, @Bugetari int,@indbug varchar(20),@cont_debitor varchar(40), @cont_creditor varchar(40), @suma float, 
	@valuta char(3), @curs float, @suma_valuta float,@ex char(50), @utilizator char(10), @nr_pozitie int,@lm char(9),@comanda char(20), 
	@tert char(13), @jurnal char(3),@eroare xml,@sub char(9), @docXMLIaPozncon xml,@lmproprietate char(9),@comanda_bugetari char(40),@detalii xml
--
begin try
	--BEGIN TRAN
	set @eroare = dbo.wfValidareNcon(@parXML)
	if isnull(@eroare.value('(error/@coderoare)[1]', 'int'), 0)>0
		raiserror('Document invalid', 11, 1)
		
	EXEC wIaUtilizator @sesiune=@sesiune, @utilizator=@utilizator OUTPUT
		
	exec luare_date_par 'GE','BUGETARI', @Bugetari output, 0, ''

	set @lmproprietate=isnull((select MAX(l.cod) from lmfiltrare l where l.utilizator=@utilizator),'')

	/*	apelat noua procedura de scriere in pozncon prin tabela temporara */
	if exists (select * from sysobjects where name ='wScriuNcon') 
		exec wScriuNcon @sesiune, @parXML OUTPUT
	else /*Incepe Vechiul wScriuPozncon de baza*/
	begin
		declare @iDoc int
		EXEC sp_xml_preparedocument @iDoc OUTPUT, @parXML
			--
		declare crspozncon cursor for
		select 	tip, 
			upper(numar), 
			data, 
			isnull(cont_debitor, '') as cont_debitor, 
			isnull(cont_creditor, '') as cont_creditor,
			isnull(suma,0) as suma,
			upper(isnull(valuta,'')) as valuta,
			isnull(curs,0) as curs,
			isnull(suma_valuta,0) as suma_valuta,
			isnull(explicatii,'') as explicatii,
			isnull(nr_pozitie,0) as nr_pozitie,
			upper(case when isnull(loc_munca,'')='' then @lmproprietate else isnull(loc_munca,'') end) as loc_munca,
			upper(isnull(comanda,'')) as comanda,
			isnull(indbug,'') as indbug,
			upper(isnull(tert,'')) as tert,
			upper(isnull(jurnal,'')) as jurnal,
			detalii as detalii
		from OPENXML(@iDoc, '/row/row')
			WITH 
			(
				detalii xml 'detalii',
				tip char(2) '../@tip',
				numar char(13) '../@numar',
				data datetime '../@data',
				cont_debitor varchar(40) '@cont_debitor',
				cont_creditor varchar(40) '@cont_creditor', 
				suma float '@suma',
				valuta char(3) '@valuta',
				curs float '@curs',
				suma_valuta float '@suma_valuta',
				explicatii char(50) '@ex', 
				nr_pozitie int '@nr_pozitie',
				loc_munca char(9) '@lm',
				comanda char(20) '@comanda',
				indbug char(20) '@indbug',
				tert char(13) '@tert',
				jurnal char(3) '@jurnal'
			)
			--
		open crspozncon
		fetch next from crspozncon into @tip, @numar, @data, @cont_debitor, @cont_creditor, @suma, @valuta, @curs, @suma_valuta, 
			@ex, @nr_pozitie, @lm, @comanda, @indbug, @tert, @jurnal, @detalii
		while @@fetch_status = 0
		begin
			if isnull(@numar,'')=''
			begin
				declare @nr decimal(13)
				set @nr=(select max(cast(numar as decimal(13))) from pozncon where isnumeric(rtrim(numar))<>0 and rtrim(numar) not in ('.',',') 
											   and charindex('-',rtrim(numar))=0 and charindex(',',rtrim(numar))=0 
											   and charindex('.',rtrim(numar))=0 
						 group by subunitate)
				--set @nr=(select max(cast(numar as int)) from pozncon group by subunitate)
				set @nr=@nr+1
				set @numar=cast(@nr as char(13))
			end
		
			set @nr_pozitie=isnull(@nr_pozitie,0)
			--
			if @valuta<>'' and @suma=0
				set @suma=@suma_valuta*@curs
		
			-------------------Start Modificari bugetari-------------------------			
			if @Bugetari='1' and ISNULL(@indbug,'')='' and 1=0	--	scos formarea indicatorului bugetar. Indicatorul va fi completat doar in tabela conturi (detalii).
			begin
				if LEFT(ltrim(@cont_debitor),1)='6' 
					exec wFormezIndicatorBugetar @Cont=@cont_debitor,@Lm=@lm,@Indbug=@indbug output  
				else
					if LEFT(ltrim(@cont_creditor),1)='7' 
						exec wFormezIndicatorBugetar @Cont=@cont_creditor,@Lm=@lm,@Indbug=@indbug output  
					else 
						if ISNULL((select cont_strain from contcor where contCG=@cont_debitor),'')<>''			
							exec wFormezIndicatorBugetar @Cont=@cont_debitor,@Lm=@lm,@Indbug=@indbug output
						else
							exec wFormezIndicatorBugetar @Cont=@cont_creditor,@Lm=@lm,@Indbug=@indbug output  			
			            
			end 
			--------------------Stop Modificari Bugetari---------------------------
		
			set @comanda_bugetari=convert(char(20),@comanda)+isnull(@indbug,'')
		
			if not exists (select 1 from pozncon where subunitate  = '1' and tip=@tip and numar=@numar and data=@data and nr_pozitie=@nr_pozitie)
			begin
				--Adaugare pozitie noua
				exec luare_date_par 'DO', 'POZITIE', 0, @nr_pozitie output, ''
				set @nr_pozitie=@nr_pozitie+1
				exec setare_par 'DO', 'POZITIE', null, null, @nr_pozitie, null
			
				insert into pozncon (Subunitate,Tip,Numar,Data,Cont_debitor,Cont_creditor,Suma,Valuta,Curs,Suma_valuta,Explicatii,Utilizator,
					Data_operarii,Ora_operarii,
					Nr_pozitie,Loc_munca,Comanda,Tert,Jurnal, detalii) 
				values ('1',@tip,@numar,@data,@cont_debitor,@cont_creditor,@suma,@valuta,@curs,@suma_valuta,@ex,@utilizator,
					convert(datetime, convert(char(10), getdate(), 104), 104),RTrim(replace(convert(char(8), getdate(), 108), ':', '')),
					@nr_pozitie,@lm,@comanda_bugetari,@tert,@jurnal,@detalii) 
			end
			else
			begin
				--Modificare pozitie existenta
				update pozncon set cont_debitor=@cont_debitor, Cont_creditor=@cont_creditor, Suma=@suma,
					Valuta=@valuta, Curs=@curs, Suma_valuta=@suma_valuta, 
					Explicatii=@ex, Utilizator=@utilizator,
					data_operarii=convert(datetime, convert(char(10), getdate(), 104), 104), 
					ora_operarii=RTrim(replace(convert(char(8), getdate(), 108), ':', '')),
					Loc_munca=@lm, comanda=@comanda_bugetari, tert=@tert, Jurnal=@jurnal, detalii=@detalii
				where subunitate='1' and tip=@tip and numar=@numar and data=@data and nr_pozitie=@nr_pozitie
			end
		
			fetch next from crspozncon into @tip, @numar, @data, 
				@cont_debitor, @cont_creditor, @suma, @valuta, @curs, @suma_valuta, @ex, @nr_pozitie, @lm,
				@comanda, @indbug, @tert, @jurnal, @detalii
		end
		--
		exec luare_date_par 'GE', 'SUBPRO', 0, 0, @sub output
		set @docXMLIaPozNcon = '<row subunitate="' + rtrim(@sub) + '" tip="' + 'NC' + '" numar="' + rtrim(@numar) + '" data="' + convert(char(10), @data, 101) +'"/>'
		exec wIaPozNcon @sesiune=@sesiune, @parXML=@docXMLIaPozNcon
	end		
		--
	--COMMIT TRAN
end try
--
begin catch
	--ROLLBACK TRAN
	declare @mesaj varchar(255)
	if isnull(@eroare.value('(/error/@coderoare)[1]', 'int'), 0) = 0
		--set @eroare='<error coderoare="1" msgeroare="' + ERROR_MESSAGE() + '"/>'
		set @mesaj=ERROR_MESSAGE()
	raiserror(@mesaj, 11, 1)
	--select @eroare FOR XML RAW
end catch
--
declare @cursorStatus int
set @cursorStatus=(select is_open from sys.dm_exec_cursors(0) where name='crspozncon' and session_id=@@SPID )
if @cursorStatus=1 
	close crspozncon 
if @cursorStatus is not null 
	deallocate crspozncon 
--
begin try 
	exec sp_xml_removedocument @iDoc 
end try 
--
begin catch end catch

