create procedure wOPModificareDateNC_p @sesiune varchar(50), @parXML xml
as
if exists (select 1 from sysobjects where [type]='P' and [name]='wOPModificareDateNC_pSP')
begin 
	declare @returnValue int -- variabila salveaza return value de la procedura specifica
	exec @returnValue = wOPModificareDateNC_pSP @sesiune, @parXML
	return @returnValue
end

begin try
	declare @numar varchar(30), @data datetime, @tip varchar(2), @sub varchar(9), @idPozncon int
	
	select @tip=@parXML.value('(/row/@tip)[1]','varchar(2)'),
		@numar=@parXML.value('(/row/@numar)[1]','varchar(30)'),
		@data=@parXML.value('(/row/@data)[1]','datetime'),
		@idPozncon=@parXML.value('(/row/row/@idpozncon)[1]','int')
	
	exec luare_date_par 'GE','SUBPRO',0,0,@sub output	

	if isnull(@numar,'')=''
		raiserror( 'Pentru modificare trebuie sa alegeti o nota contabila!',11,1)	  
	
	if isnull(@idpozncon,'')=''
		raiserror( 'Operatie de modificare date pozitie nepermisa pe antetul documentului, selectati o pozitie din document!',11,1)	  
	
	select rtrim(p.Numar) numar, convert(varchar(30),p.Data,101) data, @tip tip, 
		rtrim(p.Cont_debitor) as cont_debitor, rtrim(p.Cont_debitor)+' - '+RTRIM(cdeb.Denumire_cont) as dencont_debitor, 
		rtrim(p.Cont_creditor) as cont_creditor, rtrim(p.Cont_creditor)+' - '+RTRIM(ccre.Denumire_cont) as dencont_creditor, 
		p.loc_munca as lm, isnull(rtrim(lm.denumire), '') as denlm, 
		convert(decimal(12,2),p.suma) as suma, 
		rtrim(p.valuta) as valuta, p.curs as curs, rtrim(p.explicatii) as ex, p.Nr_pozitie nr_pozitie,	
		rtrim(left(p.comanda,20)) as comanda, isnull(rtrim(com.descriere), '') as dencomanda, 
		(case when rtrim(p.tert)<>'' then rtrim(p.tert) else rtrim(cdeb.Articol_de_calculatie) end) as tert, isnull(rtrim(t.denumire), '') as dentert, 
		p.idPozncon as idpozncon, p.detalii
	from pozncon p	
		left join conturi cdeb on cdeb.Subunitate=p.Subunitate and cdeb.Cont=p.Cont_debitor
		left join conturi ccre on ccre.Subunitate=p.Subunitate and ccre.Cont=p.Cont_creditor
		left outer join lm on lm.cod = p.loc_munca  
		left outer join comenzi com on com.subunitate = p.subunitate and com.comanda = rtrim(left(p.comanda,20)) 
		left outer join terti t on t.subunitate = p.subunitate and t.tert = p.tert  
	where p.idPozncon=@idPozncon
	for xml raw
	
	select 1 as areDetaliiXml for xml raw, root('Mesaje')
end try 

begin catch
	declare @error varchar(500)
	set @error=ERROR_MESSAGE()+ ' ('+OBJECT_NAME(@@PROCID)+')'
	select 1 as inchideFereastra for xml raw,root('Mesaje')
	raiserror(@error,16,1)
end catch
