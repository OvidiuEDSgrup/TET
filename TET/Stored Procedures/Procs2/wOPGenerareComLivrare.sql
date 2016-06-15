--***
create procedure wOPGenerareComLivrare @sesiune varchar(50),@parXML xml
as
begin try
	declare 
		@cod varchar(20), @gestiune varchar(20), @locm varchar(20), @beneficiar varchar(20), @termen datetime, @explicatii varchar(100),
		@cantitate float, @docPozCon xml, @mesaj varchar(300)
		
	
	set @cod=@parXML.value('(/parametri/@cod)[1]','varchar(20)')	
	set @gestiune=@parXML.value('(/parametri/@gestiune)[1]','varchar(20)')
	set @beneficiar=@parXML.value('(/parametri/@beneficiar)[1]','varchar(20)')
	set @locm=@parXML.value('(/parametri/@locm)[1]','varchar(20)')
	set @termen=@parXML.value('(/parametri/@termen)[1]','datetime')
	set @explicatii=@parXML.value('(/parametri/@explicatii)[1]','varchar(100)')
	set @cantitate=@parXML.value('(/parametri/@cant)[1]','float')
	
	
	set @docPozCon=
	(
		select '' as numar,convert(varchar(10),GETDATE(),101) as data, @gestiune as gestiune, @beneficiar as tert, @locm as lm, @explicatii as explicatii,'BK' as tip,@termen as termen,
			(select 
				@cod as cod, convert(decimal(17,5),@cantitate) as cantitate, 'BK' as subtip,@termen as termen
			 for xml raw,type
			)
		for xml raw
	)	
	
		exec wScriuPozCon @sesiune=@sesiune, @parXML =@docPozCon
end try
begin catch
	set @mesaj =ERROR_MESSAGE()+' (wOPGenerareComLivrare)'
	raiserror(@mesaj, 11, 1)	
end catch 
