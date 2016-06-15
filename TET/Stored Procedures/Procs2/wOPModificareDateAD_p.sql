create procedure wOPModificareDateAD_p @sesiune varchar(50), @parXML xml
as
if exists (select 1 from sysobjects where [type]='P' and [name]='wOPModificareDateAD_pSP')
begin 
	declare @returnValue int -- variabila salveaza return value de la procedura specifica
	exec @returnValue = wOPModificareDateAD_pSP @sesiune, @parXML
	return @returnValue
end

begin try
	declare @tip varchar(2), @numar varchar(30), @data datetime, @numar_pozitie int, @idpozadoc int
	
	select 
		@tip=@parXML.value('(/row/@tip)[1]','varchar(2)'),
		@numar=@parXML.value('(/row/@numar)[1]','varchar(30)'),
		@data=@parXML.value('(/row/@data)[1]','datetime'),
		@numar_pozitie=@parXML.value('(/row/row/@numarpozitie)[1]','int'),
		@idpozadoc=@parXML.value('(/row/row/@idpozadoc)[1]','int')

	if nullif(@numar_pozitie,0) is null
	begin
		raiserror( 'Operatie de modificare date pozitie nepermisa pe antetul documentului, selectati o pozitie din document!',11,1)
	end  

	if @idpozadoc is null
	begin
		raiserror( 'Procedura "wIaPozadoc nu returneaza "idpozadoc". Modificati procedura pentru a returna "idpozadoc"!',11,1)
	end  
	
	select p.Tip tip, rtrim(p.numar_document) numar, rtrim(p.Tert) tert, RTRIM(t.Denumire) dentert, convert(varchar(30),@data,101) data, p.numar_pozitie numarpozitie, 
		p.factura_stinga as facturastinga, p.factura_dreapta as facturadreapta, 
		p.valuta as valuta, p.curs as curs, p.suma_valuta as sumavaluta, 
		convert(decimal(12,2),p.suma) as suma, convert(decimal(12,2),p.TVA11) as cotatva, convert(decimal(12,2),p.TVA22) as sumatva, 
		rtrim(p.Cont_deb) as contdeb, rtrim(p.Cont_deb)+' - '+RTRIM(cd.Denumire_cont) as dencontdeb,
		rtrim(p.Cont_cred) as contcred, rtrim(p.Cont_cred)+' - '+RTRIM(cc.Denumire_cont) as dencontcred,
		p.Tert_beneficiar as tertbenef, p.Dif_TVA as diftva, p.Achit_fact as achitfact, 
		(case when p.valuta='' then '' else p.cont_dif end) as contdifcurs, 
		(case when p.valuta='' then 0 else convert(decimal(15, 2), p.suma_dif) end) as sumadifcurs, 
		left(p.comanda,20) as comanda, ISNULL(c.descriere, '') as dencomanda, 
		p.loc_munca as lm, ISNULL(lm.denumire, '') as denlm, 
		p.Data_fact as datafacturii, p.Data_scad as datascadentei, 
		p.explicatii as explicatii, 
		p.Stare as tiptva, p.idpozadoc, p.detalii
	from pozadoc p
		left outer join conturi cd on cd.subunitate = p.subunitate and cd.cont = p.cont_deb
		left outer join conturi cc on cc.subunitate = p.subunitate and cc.cont = p.Cont_cred
		left join terti t on t.subunitate = p.subunitate and t.Tert=p.Tert
		left outer join lm on lm.Cod=p.Loc_munca
		left outer join comenzi c on c.Subunitate=p.Subunitate and c.Comanda=rtrim(left(p.comanda,20))
	where p.idPozadoc=@idpozadoc
	for xml raw

	select 1 as areDetaliiXml for xml raw, root('Mesaje')
end try 

begin catch
	declare @error varchar(500)
	set @error='(wOPModificareDateAD_p:) '+ ERROR_MESSAGE()
	select 1 as inchideFereastra for xml raw,root('Mesaje')
	raiserror(@error,16,1)
end catch
