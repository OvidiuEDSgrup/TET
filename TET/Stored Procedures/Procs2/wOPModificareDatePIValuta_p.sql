create procedure wOPModificareDatePIValuta_p @sesiune varchar(50), @parXML xml
as
if exists (select 1 from sysobjects where [type]='P' and [name]='wOPModificareDatePIValuta_pSP')
begin 
	declare @returnValue int -- variabila salveaza return value de la procedura specifica
	exec @returnValue = wOPModificareDatePIValuta_pSP @sesiune, @parXML
	return @returnValue
end

begin try
	declare @numar varchar(30), @tip varchar(2), @cont varchar(40), @sub varchar(9), @idPozPlin int, @valuta varchar(3)
	
	select @numar=@parXML.value('(/row/row/@numar)[1]','varchar(30)'),
		@cont=@parXML.value('(/row/row/@cont)[1]','varchar(40)'),
		@tip=@parXML.value('(/row/@tip)[1]','varchar(2)'),
		@valuta=@parXML.value('(/row/row/@valuta)[1]','varchar(3)'),
		@idPozPlin=@parXML.value('(/row/row/@idPozPlin)[1]','int')
	
	exec luare_date_par 'GE','SUBPRO',0,0,@sub output	

	if isnull(@numar,'')=''
		raiserror( 'Pentru modificare trebuie sa alegeti o plata/incasare!',11,1)
	if isnull(@valuta,'')=''
		raiserror( 'Nu se pot modifica date referitoare la sume in valuta pe o pozitie fara valuta!',11,1)

	select rtrim(p.Numar) numar, convert(varchar(30),p.Data,101) data, p.Numar_pozitie numarpozitie, @tip tip, 
		convert(decimal(15, 2), p.suma) as suma, 
		rtrim(p.Cont_dif) as contdifcurs, rtrim(p.Cont_dif)+' - '+RTRIM(cd.Denumire_cont) as dencontdifcurs, 
		rtrim(p.valuta) as valuta, convert(decimal(10, 4), p.curs) as curs, convert(decimal(15, 2), p.suma_dif) as sumadifcurs, p.idPozPlin as idPozPlin, p.detalii
	from pozplin p	
		left join conturi cd on cd.Subunitate=p.Subunitate and cd.Cont=p.Cont_dif
	where p.idPozPlin=@idPozPlin
	for xml raw
	
	select 1 as areDetaliiXml for xml raw, root('Mesaje')
end try 

begin catch
	declare @error varchar(500)
	set @error='(wOPModificareDatePIValuta_p:) '+ ERROR_MESSAGE()
	select 1 as inchideFereastra for xml raw,root('Mesaje')
	raiserror(@error,16,1)
end catch
