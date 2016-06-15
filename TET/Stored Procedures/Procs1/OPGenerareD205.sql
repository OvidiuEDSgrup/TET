--***
Create procedure [dbo].[OPGenerareD205]
	@DataJ datetime, 
	@DataS datetime,
	@tipdecl int, -- TipDeclaratie=0 Initiala, 1 Rectificativa
	@TipVenit char(2), -- cuprinde valori din lista prevazuta in legislatie
	@TipImpozit char(1), -- TipImpozit=1 Plata anticipata, 2 Impozit final
	@LmJos char(9),	@LmSus char(9),
	@ContImpozit char(30), @ContFactura char(30),
	@inXML int,
	@cDirector varchar(254) --cale generare fisier TXT
as  
Begin
	declare @rezultat varchar(max), @An int, 
	@numeFisier varchar(max), @cFisier varchar(254), @raspunsCmd int, @msgeroare varchar(1000),
	@vcif varchar(13), @cif varchar(13), @den varchar(200), @telSoc varchar(15), @faxSoc varchar(15), @mailSoc varchar(200),
	@TotalImpozit decimal(12)

	select @vcif=dbo.iauParA('GE','CODFISC'), @den=dbo.iauParA('GE','NUME'), 
		@telSoc=dbo.iauParA('GE','TELFAX'), @faxSoc=dbo.iauParA('GE','TELFAX'), 
		@mailSoc=dbo.iauParA('GE','EMAIL')
		
	Select @cif=ltrim(rtrim((case when left(upper(@vcif),2)='RO' then substring(@vcif,3,13)
		when left(upper(@vcif),1)='R' then substring(@vcif,2,13) else @vcif end)))
	select @An=year(@DataS)

	declare @datedecl table (Detalii varchar(max))
--	inserez datele legate de drepturi de autor si conventii civile
	insert into @datedecl
	select CampD205
	from fDeclaratia205 (@DataJ, @DataS, @tipdecl, @TipVenit, @TipImpozit, @LmJos, @LmSus, @ContImpozit, @ContFactura)
--	ar trebui sa inserez veniturile celor care au vandut deseuri (din CG)


--	salvare declaratie ca fisier TXT
	set @numeFisier = 'D205_'+convert(char(4),@An)+'_'+(case when @tipdecl=0 then 'I' else 'R' end)
		+(case when @TipImpozit=1 then 'A' else 'F' end)+'_'+@cif+'_'+rtrim(@TipVenit)+'.txt' 
	set @cFisier=rtrim(@cDirector)+@numeFisier

	if (select count(1) from tempdb..sysobjects where name='##tmpdecl')>0 
		drop table ##tmpdecl

	create table ##tmpdecl (coloana varchar(max))
	if @inXML=1 /* daca inXML trimit fisierul pt. salvarea lui din Flex/AIR */
	begin 
		set @rezultat=''
		select @rezultat=@rezultat+rtrim(Detalii)+char(10) from @datedecl
--		print @rezultat
--		select @rezultat
		exec SalvareFisier @rezultat, @cDirector, @numeFisier
		--	select @rezultat as document, @numeFisier as fisier, '' as nrFactura, 'wTipFormular' as numeProcedura for xml raw 
	end 
	else 
	begin /* altfel, il salvez in tabela temporara si apoi cu bcp in un fisier pe disk */
		insert into ##tmpdecl select * from @datedecl
		declare @nServer varchar(1000), @comandaBCP varchar(4000) /* comanda trebuie sa ramana varchar(4000) sau mai mica... */
		set @nServer=convert(varchar(1000),serverproperty('ServerName'))
		set @comandaBCP='bcp "select rtrim(coloana) from ##tmpdecl'+'" queryout "'+@cFisier+'" -T -c -C ACP -S '+@nServer
--		set @comandaBCP='bcp ##tmpdecl"'+'" out "'+@cFisier+'" -T -c -C ACP -S '+@nServer
		exec @raspunsCmd = xp_cmdshell @comandaBCP
--	select @raspunsCmd, @comandaBCP
		if @raspunsCmd != 0 /* xp_cmdshell returneaza 0 daca nu au fost erori, sau altfel, codul de eroare */
		begin
			set @msgeroare = 'Eroare la scrierea formularului pe hard-disk in locatia: '+ ( 
				case len(@cFisier) when 0 then 'NEDEFINIT' else @cFisier end )
			raiserror (@msgeroare ,11 ,1)
		end
		else	/* trimit numele fisierului generat */ 
			select @numeFisier as fisier, 'wTipFormular' as numeProcedura for xml raw
	end
	drop table ##tmpdecl
End

/*
	exec OPGenerareD205 '01/01/2011', '12/31/2011', 0, '06', 2, Null, Null, Null, Null, 0, '\\LUCIAN\ASIS\D112\'
*/
