--***  
/* adauga/sterge facturi din lista facturilor de incasat, si genereaza incasari facturi  */
CREATE procedure [dbo].[wmIncasareFacturiHandler] @sesiune varchar(50), @parXML xml as	
--set transaction isolation level READ UNCOMMITTED  

if exists(select * from sysobjects where name='wmIncasareFacturiHandlerSP' and type='P')
begin
	exec wmIncasareFacturiHandlerSP @sesiune, @parXML 
	return 0
end

declare @utilizator varchar(100), @stare varchar(10), @tert varchar(30), @xmlFinal xml, @linieXML xml, @facturaDeIncasat varchar(100), 
		@msgEroare varchar(500), @idpunctlivrare varchar(100)

begin try
	exec wIaUtilizator @sesiune=@sesiune, @utilizator=@utilizator output 
	
	-- identificare tert din par xml
	select @tert=f.tert, @idPunctLivrare=f.idPunctLivrare
	from dbo.wmfIaDateTertDinXml(@parXML) f

	select	@facturaDeIncasat=@parXML.value('(/row/@wmIncasareFacturi.cod)[1]','varchar(100)')

	-- verific selectarea unei linii din lista.
	if @facturaDeIncasat is null
	begin
		raiserror('Nu ati ales nici o factura din lista!',11,1)
		return -1
	end

	-- verific daca a ales incasare facturi
	if @facturaDeIncasat='<INCASAREFACTURI>'
	begin 
		declare @SugerChit int, @AutoChit int, @nrChitanta int, @contPlata varchar(50)

		select @contPlata = rtrim(dbo.wfProprietateUtilizator('CONTPLIN', @utilizator))
		if isnull(@contPlata,'')=''
		begin
			raiserror('Cont casa nu este configurat pentru utilizatorul curent!',11,1)
		end
		if isnull((select COUNT(1) from tmp_facturi_de_listat where utilizator=@utilizator),0)=0
		begin
			raiserror('Nu ati ales nicio factura!',11,1)
		end
		
		-- iau nr. chitanta
		select	@SugerChit=(case when Parametru='SUGERCHIT' then Val_logica else @SugerChit end),
				@AutoChit=(case when Parametru='AUTCH' then Val_logica else @AutoChit end),
				@nrChitanta=(case when Parametru='ULTNRCH' then Val_numerica else @nrChitanta end)
		from par
		where Tip_parametru='GE' and Parametru in ('SUGERCHIT', 'AUTCH', 'ULTNRCH')
		
		select	@SugerChit=ISNULL(@SugerChit,0),
				@AutoChit=ISNULL(@AutoChit,0),
				@nrChitanta=ISNULL(@nrChitanta,0)
		
		if @SugerChit=1 and @AutoChit=1
		begin
			set @nrChitanta=@nrChitanta+1
			exec setare_par 'GE', 'ULTNRCH', null, null, @nrChitanta, null
		end

		declare @xml xml
		set @xml=(
			select 'RE' '@tip', @contPlata '@cont', convert(varchar,getdate(),101) '@data', 
				(select 'IB' '@subtip', rtrim(t.factura) '@factura', @nrChitanta '@numar',
					CONVERT(decimal(12,2),f.Valoare+f.TVA_22-f.Achitat) '@suma', @tert '@tert'
					from tmp_facturi_de_listat t
					inner join facturi f on t.factura=f.Factura and f.Tip=0x46 and f.Tert=@tert
					where t.utilizator=@utilizator
					for xml path('row'),type
				)
			for xml path('row'))
		begin try
			exec wScriuPozplin @sesiune=@sesiune, @parXML=@xml
			
			delete from tmp_facturi_de_listat where utilizator=@utilizator
			
			declare @formularIncasare varchar(20)
			select @formularIncasare = rtrim(dbo.wfProprietateUtilizator('FORMPLIN', @utilizator))
		
			set @xml=convert(xml,'<row subunitate="1" tip="BK" numar="'+convert(varchar,@nrChitanta)+'" data="'+convert(char(10),GETDATE(),101)
				+'" tert="'+@tert+'" nrform="'+@formularIncasare+'" />')
			exec wTipFormular @sesiune,@xml

		end try
		begin catch
			set @msgEroare=ERROR_MESSAGE()
			raiserror(@msgEroare,11,1)
		end catch
		
		select 'Incasare facturi' as titlu, 'back(1)' as actiune,0 as areSearch  
		for xml raw,Root('Mesaje')
	end
	else
	begin
		-- adaugare factura in lista
		if exists (select 1 from tmp_facturi_de_listat tmp where tmp.utilizator=@utilizator and tmp.factura=@facturaDeIncasat)
				delete from tmp_facturi_de_listat where utilizator=@utilizator and factura=@facturaDeIncasat
			else
				insert tmp_facturi_de_listat(utilizator, factura)
				values (@utilizator, @facturaDeIncasat)	
	end

end try
begin catch
	set @msgEroare='(wmIncasareFacturiHandler)'+ERROR_MESSAGE()
	raiserror(@msgEroare,11,1)
end catch

--select 'Incasare facturi' as titlu, 'back(1)' as actiune,0 as areSearch  
--for xml raw,Root('Mesaje') 
--exec wmIncasareFacturi @sesiune=@sesiune, @parXML= @parXML
