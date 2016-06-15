--***
create procedure wOPGenerareNCCheltAvans @sesiune varchar(50), @parXML xml        
as
begin try
	declare @sub varchar(9),@lunabloc int, @anulbloc int, @databloc datetime, @tip varchar(2),
		@numar varchar(13),@data datetime,@datal datetime,@nrpozitie_pozdoc float,@cant float,@pret float,
		@lm varchar(9),@com varchar(20),@indbug varchar(20),@contstoc varchar(40),
		@contavans varchar(40), @nrluni int, @eroare varchar(254), @userASiS varchar(10), @input XML, @datainceput datetime, 
		@detalii xml, @explicatii varchar(50), @cod varchar(20), @nr_pozitie_pozncon int, @idpozdoc int, @fara_mesaje bit
	--exec wJurnalizareOperatie @sesiune=@sesiune, @parXML=@parXML, @obiectSql='wOPGenerareNCCheltAvans'
	
	exec luare_date_par 'GE', 'SUBPRO', 0, 0, @sub output
	set @lunabloc=isnull((select max(val_numerica) from par where tip_parametru='GE' and parametru='LUNABLOC'), 1)
	set @anulbloc=isnull((select max(val_numerica) from par where tip_parametru='GE' and parametru='ANULBLOC'), 1901)
	if @lunabloc not between 1 and 12 or @anulbloc<=1901 
		set @databloc='01/01/1901' 
	else 
		set @databloc=dbo.EOM(convert(datetime,str(@lunabloc,2)+'/01/'+str(@anulbloc,4)))

	exec wIaUtilizator @sesiune=@sesiune, @utilizator=@userASiS output

	select @tip=ISNULL(@parXML.value('(/*/@tip)[1]', 'varchar(2)'), ''),
		@numar=ISNULL(@parXML.value('(/*/@numar)[1]', 'varchar(13)'), ''),
		@fara_mesaje=ISNULL(@parXML.value('(/*/@fara_mesaje)[1]', 'bit'), 0),
		@data=ISNULL(@parXML.value('(/*/@data)[1]', 'datetime'), '01/01/1901'),
		@nrpozitie_pozdoc = ISNULL(@parXML.value('(/*/row/@numarpozitie)[1]', 'float'), 0), 
		@idpozdoc = ISNULL(@parXML.value('(/row/docInserate/row/@idPozDoc)[1]', 'int'), 0), 
		@explicatii=ISNULL(@parXML.value('(/row/row/detalii/row/@explicatii)[1]', 'varchar(50)'), ''),
		@contavans=ISNULL(@parXML.value('(/*/@contavans)[1]', 'varchar(40)'), ''),
		@nrluni=ISNULL(@parXML.value('(/*/@nrluni)[1]', 'int'), 0),
		@datainceput=ISNULL(@parXML.value('(/*/@datainceput)[1]', 'datetime'), '01/01/1901')
	
	set @nrluni=ROUND(@nrluni,0)

	if @data<=@databloc
		raiserror('Operatia nu se poate da pe o luna inchisa!',16,1)	
	
	if isnull(@idpozdoc,0)=0 and @tip in ('RM','RS','AP','AS') 
		select @idpozdoc=idpozdoc from pozdoc where subunitate=@sub and tip=@tip and Numar=@numar and data=@data and Numar_pozitie=@nrpozitie_pozdoc and Tip_miscare='V'
	
	if isnull(@idpozdoc,0)=0
		raiserror('Operatia se poate da doar dupa selectare pozitie document!',16,1)
		
	select 
		@tip=tip, @numar=numar, @data=data 
	from pozdoc 
	where isnull(@numar,'')='' and idPozDoc=@idpozdoc 

	if exists (select 1 from pozdoc where subunitate=@sub and tip=@tip and Numar=@numar and data=@data 
				and Numar_pozitie=@nrpozitie_pozdoc and (stare=2 or Cont_de_stoc=@contavans))
		raiserror('S-au generat deja notele de venituri pe aceasta pozitie de document! Daca e cazul, stergeti pozitia si adaugati-o din nou.',16,1)
		
	if not exists (select 1 from conturi where cont=@contavans and Are_analitice=0)
		raiserror('Cont inexistent sau cu analitice!' ,16,1)

	if isnull(@nrluni,0)<1
		raiserror('Trebuie sa introduceti o valoare pozitiva la nr. de luni!',16,1)

	/** De aici a fost procedura GenerareNCCheltAvans - am renuntat ca nu se putea intretine sincron cu CGplus **/
	exec luare_date_par 'DO', 'POZITIE', 0, @nr_pozitie_pozncon output, ''
	if @tip is null
		set @tip='RS' 
	if isnull(@datainceput,'01/01/1901')='01/01/1901'
		set @datainceput=@data

	select 
		@cant=cantitate, @pret= (case when @tip in ('RM','RS') then Pret_de_stoc else Pret_vanzare end), @lm=loc_de_munca, @com=LEFT(comanda,20), @cod=cod, --@detalii=detalii, 
		@indbug=SUBSTRING(comanda,21,20), @contstoc=cont_de_stoc, @explicatii=(case when @tip='RS' and @explicatii='' then numar_DVI else @explicatii end)
	from pozdoc where idPozDoc=@idpozdoc 

	/** Pentru ASiSplus, unde nu se lucreaza cu pozdoc.detalii XML si pozdoc.idpozdoc va trebui folosita o versiune mai veche a acestei proceduri  */
	if @tip in ('RM','AP','AS') and isnull(@explicatii,'')='' 
		select 
			@explicatii=detalii.value('(/row/@Explicatii)[1]', 'varchar(50)')
		from pozdoc where idPozDoc=@idpozdoc 
	if isnull(@explicatii,'')='' 
		set @explicatii=(select left(denumire,50) from nomencl where cod=@cod)

	/** Stergere dupa idpozdoc fara a mai tine cont de data**/
	delete from pozncon where subunitate=@sub and tip='NC' and Numar=@numar and detalii.value('(/row/@idpozdoc)[1]', 'int')=@idpozdoc

	declare cursorptNCcheltavans cursor for
		select distinct Data_lunii
		FROM fCalendar (@datainceput,DATEADD(MONTH,@nrluni-1,@datainceput)) 
		ORDER BY data_lunii
	
	declare @ft int
	open cursorptNCcheltavans
	fetch next from cursorptNCcheltavans into @datal
	set @ft=@@fetch_status
	while @ft = 0
	begin
		/* am skipat mai jos si am inlocuit cu insert:
		set @input=(select /*Data_lunii*/@datal as '@data', 'NC' as '@tip', @numar as '@numar',
			(select convert(decimal(17,2),(case when @datal=dbo.eom(@data) then round(@cant*@pret,2)-round(@cant*@pret/@nrluni,2)*(@nrluni-1) else round(@cant*@pret/@nrluni,2) end)) as '@suma',
					@com as '@comanda', @lm as '@lm', @indbug as '@indbug',
					(case when @tip in ('RM','RS') then @contstoc else @contavans end) as '@cont_debitor', 
					(case when @tip in ('RM','RS') then @contavans else @contstoc end) as '@cont_creditor', 
					(case when @explicatii='' then 'REPARTIZARE CH/V IN AVANS' else @explicatii end) as '@ex'
				for XML path,type)
			for xml path,type)
		exec wScriuPozNcon @sesiune,@input*/

		--Pana se va rezolva in procedura de scriere in pozncon sa pot trimite detalii xml si sa returneze pozitia generata lucrez cu "insert":
		set @nr_pozitie_pozncon=@nr_pozitie_pozncon+1
		insert into pozncon (Subunitate,Tip,Numar,Data,Cont_debitor,Cont_creditor,Suma,Valuta,Curs,Suma_valuta,Explicatii,Utilizator,
			Data_operarii,Ora_operarii,	Nr_pozitie,Loc_munca,Comanda,Tert,Jurnal,detalii) 
		values (@sub,'NC',@numar,@datal,(case when @tip in ('RM','RS') then @contstoc else @contavans end),(case when @tip in ('RM','RS') then @contavans else @contstoc end),
			convert(decimal(17,2),(case when @datal=dbo.eom(@data) then round(@cant*@pret,2)-round(@cant*@pret/@nrluni,2)*(@nrluni-1) else round(@cant*@pret/@nrluni,2) end)),  
			'',0, 0,(case when @explicatii='' then 'REPARTIZARE CH/V IN AVANS' else @explicatii end),@userASiS,
			convert(datetime, convert(char(10), getdate(), 104), 104),RTrim(replace(convert(char(8), getdate(), 108), ':', '')),@nr_pozitie_pozncon,@lm,@com+@indbug,'','',
			(select @idpozdoc idpozdoc FOR XML raw )) 

		fetch next from cursorptNCcheltavans into @datal
		set @ft=@@fetch_status
	end
	exec setare_par 'DO', 'POZITIE', null, null, @nr_pozitie_pozncon, null
	close cursorptNCcheltavans 
	deallocate cursorptNCcheltavans 
	
	if exists (select 1 from pozncon where Subunitate=@sub and tip='NC' and Numar=@numar and detalii.value('(/row/@idpozdoc)[1]', 'int')=@idpozdoc) 
	begin
		IF @fara_mesaje<>1
			select 'S-a generat nota contabila cu nr. '+rtrim(@numar)+' pe cele '+rtrim(ltrim(convert(char(10),@nrluni)))+' luni.' as textMesaj for xml raw, root('Mesaje')
	end
	else
		raiserror('Nu s-a realizat operatia!',11,1)
end try 
begin catch  
	set @eroare='wOPGenerareNCCheltAvans: '+ERROR_MESSAGE()
	raiserror(@eroare, 11, 1) 		
end catch

if isnull(@eroare,'')='' 
begin
	update pozdoc 
		set Cont_de_stoc=@contavans, Cont_venituri=(case when @tip in ('AP','AS') then @contavans else cont_venituri end)
	where idPozdoc=@idpozdoc 
end
