create procedure wOPModificareDatePI_p @sesiune varchar(50), @parXML xml
as
if exists (select 1 from sysobjects where [type]='P' and [name]='wOPModificareDatePI_pSP')
begin 
	declare @returnValue int -- variabila salveaza return value de la procedura specifica
	exec @returnValue = wOPModificareDatePI_pSP @sesiune, @parXML
	return @returnValue
end

begin try
	declare @numar varchar(30), @data datetime, @tip varchar(2), @numar_pozitie int, @ext_datadocument datetime, 
		@cont varchar(40), @sub varchar(9), @cotatva float, @sumatva float, @idPozPlin int, @suma float
	
	select @numar=@parXML.value('(/row/row/@numar)[1]','varchar(30)'),
		@numar_pozitie=@parXML.value('(/row/row/@numarpozitie)[1]','int'),
		@data=@parXML.value('(/row/row/@data)[1]','datetime'),
		@cont=@parXML.value('(/row/row/@cont)[1]','varchar(40)'),
		@ext_datadocument=@parXML.value('(/row/row/@ext_datadocument)[1]','datetime'),
		@cotatva=@parXML.value('(/row/row/@cotatva)[1]','float'),
		@sumatva=@parXML.value('(/row/row/@sumatva)[1]','float'),
		@tip=@parXML.value('(/row/@tip)[1]','varchar(2)'),
		@idPozPlin=@parXML.value('(/row/row/@idPozPlin)[1]','int'),
		@suma = isnull(@parXML.value('(/row/row/@suma)[1]', 'float'), 0) -- pentru deconturi
	
	--select @numar,@numar_pozitie,@data,@cont,@idPozPlin
	exec luare_date_par 'GE','SUBPRO',0,0,@sub output	

	if isnull(@numar,'')=''
		raiserror( 'wOPModificareDatePI_p: Pentru modificare trebuie sa alegeti o plata/incasare!',11,1)	  
	
	select rtrim(p.Numar) numar, convert(varchar(30),p.Data,101) data, p.Numar_pozitie numarpozitie,
		@tip tip, convert(varchar(30),@ext_datadocument,101) ext_datadocument, rtrim(p.Cont_corespondent) as contcorespondent,
		rtrim(p.Cont_corespondent)+' - '+RTRIM(c.Denumire_cont) as dencontcorespondent, convert(decimal(12,2), @suma) as suma,
		convert(varchar(5),@cotatva) cotatva, convert(decimal(12,2),@sumatva) sumatva, p.idPozPlin as idPozPlin, p.detalii
	from pozplin p	
		left join conturi c on c.Subunitate=p.Subunitate and c.Cont=p.Cont_corespondent
	where p.idPozPlin=@idPozPlin
	for xml raw
	
	select 1 as areDetaliiXml for xml raw, root('Mesaje')
end try 

begin catch
	declare @error varchar(500)
	set @error='(wOPModificareDatePI_p:) '+ ERROR_MESSAGE()
	select 1 as inchideFereastra for xml raw,root('Mesaje')
	raiserror(@error,16,1)
end catch
