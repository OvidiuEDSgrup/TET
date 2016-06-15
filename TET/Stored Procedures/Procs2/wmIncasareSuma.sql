--***  
/* procedura care afisaza facturile neincasate pe un tert si perimite alegerea facturilor care se vor incasa. */
CREATE procedure [dbo].[wmIncasareSuma] @sesiune varchar(50), @parXML xml as  
--set transaction isolation level READ UNCOMMITTED  
if exists(select * from sysobjects where name='wmIncasareSumaSP' and type='P')
begin
	exec wmIncasareSumaSP @sesiune, @parXML 
	return 0
end

declare @utilizator varchar(100),@subunitate varchar(9),@stare varchar(10), @tert varchar(30), @raspuns varchar(max),
		@facturaDeIncasat varchar(100), @idPunctLivrare varchar(50), @serie varchar(50), @numar varchar(50), @suma decimal(12,2),
		@actiune varchar(50), @cod varchar(50), @msgEroare varchar(1000), @data datetime

begin try
	exec wIaUtilizator @sesiune=@sesiune, @utilizator=@utilizator output 

	--citesc codul ales
	select	@cod=@parXML.value('(/row/@wmIncasareSuma.cod)[1]','varchar(100)'),
			@serie=@parXML.value('(/row/@serie)[1]','varchar(100)'),
			@numar=@parXML.value('(/row/@numar)[1]','varchar(100)'),
			@suma=@parXML.value('(/row/@suma)[1]','decimal(12,2)'),
			@data=convert(datetime, @parXML.value('(/row/@data)[1]','varchar(100)'), 103) -- nu e trimisa din frame conform standardului -> se va modifica
	
	-- identificare tert din par xml
	select @tert=f.tert, @idPunctLivrare=f.idPunctLivrare
	from dbo.wmfIaDateTertDinXml(@parXML) f

	if @cod ='.OperareSuma.'
	begin -- s-a ales suma prin macheta tip form.
		set @raspuns=(select @suma suma, @serie serie, @numar numar, convert(varchar,@data,101) data for xml raw)

		delete from proprietati where Tip='U' and Cod=@utilizator and Cod_proprietate in ('IncasareSuma', 'SerieChitMobile', 'UltNumarChitMobile')
		insert proprietati(Tip, Cod, Cod_proprietate, Valoare, Valoare_tupla)
		values ('U', @utilizator, 'SerieChitMobile', @serie, '')
		insert proprietati(Tip, Cod, Cod_proprietate, Valoare, Valoare_tupla)
		values ('U', @utilizator, 'UltNumarChitMobile', @numar, '')
		insert proprietati(Tip, Cod, Cod_proprietate, Valoare, Valoare_tupla)
		values ('U', @utilizator, 'IncasareSuma', convert(varchar(200),@raspuns), '')
		
		
		set @actiune='back(1)'
	end
	else
	if @cod is null or @suma is null -- prima intrare in view, sau back din macheta tip form
	begin
		if not exists ( select 1 from proprietati where Tip='U' and Cod=@utilizator and Cod_proprietate='IncasareSuma')
		begin -- prima intrare in view
			select	@actiune='autoSelect',
					@suma=0
			
			select	@serie=(case when p.Cod_proprietate='SerieChitMobile' then rtrim(Valoare) else @serie end ),
					@numar=(case when p.Cod_proprietate='UltNumarChitMobile' then rtrim(Valoare) else @numar end )
			from proprietati p where Tip='U' and Cod=@utilizator and Cod_proprietate in ('SerieChitMobile', 'UltNumarChitMobile')
			
			-- incrementez numarul salvat cu 1. Probabil nu ar trebui salvat ultimul numar decat 
			-- la generare chitanta, nu la operare suma - de schimbat daca va trebui
			if ISNUMERIC(@numar)=1 
				set @numar=convert(varchar,CONVERT(int,@numar)+1)
			
			set @raspuns=(select @suma suma, @serie serie, @numar numar for xml raw)
			
			-- scriu in proprietati faptul ca am intrat in macheta - doar la prima intrare se face autoSelect
			insert proprietati(Tip, Cod, Cod_proprietate, Valoare, Valoare_tupla)
			values ('U', @utilizator, 'IncasareSuma', @raspuns, '')
		end
		begin	-- daca nu e prima intrare in macheta, citesc din proprietati valorile operate -> limitat la 200 caractere:( 
			select @raspuns=valoare
			from proprietati where Tip='U' and Cod=@utilizator and Cod_proprietate='IncasareSuma'
			
			select	@serie=convert(xml,@raspuns).value('(/row/@serie)[1]','varchar(100)'),
					@numar=convert(xml,@raspuns).value('(/row/@numar)[1]','varchar(100)'),
					@suma=convert(xml,@raspuns).value('(/row/@suma)[1]','decimal(12,2)'),
					@data=isnull(convert(xml,@raspuns).value('(/row/@data)[1]','datetime'),convert(datetime, convert(varchar,GETDATE(),101),101)) -- salvez in standard asisria
		end
		
	end
	if @cod ='.IncasareSuma.'
	begin -- generare incasari
		declare @factura varchar(20), @valoareFactura float, @SugerChit int, @AutoChit int, @nrChitanta int, @contPlata varchar(50), @xml xml

		select @contPlata = rtrim(dbo.wfProprietateUtilizator('CONTPLIN', @utilizator))
		if isnull(@contPlata,'')=''
		begin
			raiserror('Cont casa nu este configurat pentru utilizatorul curent!',11,1)
		end
	
		if LEN(@numar)<=1
		begin
			raiserror('Numar chitanta nu este completat.!',11,1)
		end
		
		/*
		-- iau nr. chitanta
		select	@SugerChit=(case when Parametru='SUGERCHIT' then Val_logica else @SugerChit end),
				@AutoChit=(case when Parametru='AUTCH' then Val_logica else @AutoChit end),
				@nrChitanta=(case when Parametru='ULTNRCH' then Val_numerica else @nrChitanta end)
		from par
		where Tip_parametru='GE' and Parametru in ('SUGERCHIT', 'AUTCH', 'ULTNRCH')
		
		if @SugerChit=1 and @AutoChit=1
		begin
			set @nrChitanta=@nrChitanta+1
			exec setare_par 'GE', 'ULTNRCH', null, null, @nrChitanta, null
		end
		*/
		set @raspuns=''
		
		-- formez lista facturi
		declare listaFacturi cursor for
		select rtrim(f.Factura),  f.Valoare+f.TVA_22-f.Achitat
		from facturi f
		where tip=0x46 and tert=@tert and ABS(sold)>0.05
		order by data
		
		open listaFacturi
		fetch next from listaFacturi into @factura, @valoareFactura
		
		while @@FETCH_STATUS=0 and @suma>0
		begin 
			if @valoareFactura>@suma
				set @valoareFactura=@suma
			set @suma = @suma - @valoareFactura
		
			set @raspuns=@raspuns+
				(select 'IB' '@subtip', rtrim(@factura) '@factura', @numar '@numar',
				CONVERT(decimal(12,2),@valoareFactura) '@suma', @tert '@tert'
				for xml path('row'))
			fetch next from listaFacturi into @factura, @valoareFactura
		end
		
		if @suma>0
		begin
			raiserror('Suma depaseste soldul tertului!',11,1)
			return -1
		end
		if isnull(@raspuns,'')=''
		begin 
			raiserror('Tertul nu are facturi scadente!!',11,1)
			return -1
		end
		
		set @raspuns=
			'<row tip="RE" cont="'+@contPlata+'" data="'+convert(varchar,@data,101)+'" >'+  -- linie antet
				@raspuns+ -- pozitii
			'</row>'
		
		set @xml=convert(xml,@raspuns)
		exec wScriuPozplin @sesiune=@sesiune, @parXML=@xml
		
		set @actiune='back(2)'
		
	end

	-- formez lista optiuni afisate
	set @raspuns='<Date>' +CHAR(13)+
		(select '.OperareSuma.' cod, isnull(convert(varchar, @suma)+'RON','Modific suma') denumire, 
			'Chitanta:'+@serie+' '+@numar+' din '+CONVERT(varchar, @data, 103) info, 
			@serie serie, @numar numar, @suma suma, CONVERT(varchar, @data, 103) data,
			'0x000000' as culoare, 'refresh' actiune, 'D' as tipdetalii 
		 for xml raw)+CHAR(13)

	-- daca a completat suma, afisez linie pentru incasare
	if isnull(@suma,0)>0
		set @raspuns=@raspuns+
			( select '.IncasareSuma.' cod, 'Incasare suma' denumire, 
			'assets/Imagini/Meniu/incasari.png' as poza, '0x0000ff' culoare, 'C' as tipdetalii for xml raw)+CHAR(13)

	-- inchid xml-ul generat si il trimit pe net
	set @raspuns=@raspuns+'</Date>'
	select convert(xml,@raspuns)

	select 'Incasare suma' as titlu, 'wmIncasareSuma' as detalii,0 as areSearch, @actiune actiune,
		'D' tipdetalii, dbo.f_wmIaForm('CH') form,
		@parXML 'parxmlnou'
	for xml raw,Root('Mesaje')   

	--select * from tmp_facturi_de_listat
end try
begin catch
		set @msgEroare=ERROR_MESSAGE()
		--raiserror(@msgEroare,11,1)
end catch


-- inchid cursor
begin try
declare @cursorStatus smallint
set @cursorStatus=(select is_open from sys.dm_exec_cursors(0) where name='listaFacturi' and session_id=@@SPID )
if @cursorStatus=1 
	close listaFacturi 
if @cursorStatus is not null 
	deallocate listaFacturi 
end try begin catch end catch

-- daca au fost erori, le trimit mai departe aici, dupa inchidere cursor...
if @msgEroare is not null
	raiserror(@msgEroare,11,1)
