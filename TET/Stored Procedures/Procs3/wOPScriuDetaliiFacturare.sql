--***
/**/
create procedure [dbo].[wOPScriuDetaliiFacturare](@sesiune varchar(50), @parXML xml)   
as       
begin  
declare @utilizator varchar(20),@mesaj varchar(200),@id_factura int,@factura varchar(20),@id_contract int,  
        @userASiS varchar(20),@tip char(2),@numele_delegatului varchar(30),@seria_buletin varchar(10),@numar_buletin varchar(10),  
        @eliberat varchar(30),@mijloc_de_transport varchar(30),@numarul_mijlocului varchar(13),@data_expedierii datetime,  
        @ora_expedierii varchar(6),@observatii varchar(200),@explicatii varchar(200),@sub varchar(1),@datadoc datetime,@punctlivrare varchar(20),  
        @tert varchar(20),@observatii_anexadoc varchar(200),@observatii_anexafac varchar(200),@numar varchar(20)
          
begin try  
	exec wIaUtilizator @sesiune=@sesiune, @utilizator=@utilizator output  
	  
	select @tip=isnull(@parXML.value('(/parametri/@tip)[1]','char(2)'),''),  
		@factura= isnull(@parXML.value('(/parametri/@factura)[1]','varchar(20)'),''),
		@numar= isnull(@parXML.value('(/parametri/@numar)[1]','varchar(20)'),''),
		@tert= isnull(@parXML.value('(/parametri/@tert)[1]','varchar(13)'),''),  
		@sub=isnull(@parXML.value('(/parametri/@subunitate)[1]','varchar(1)'),'1'),  
		@numele_delegatului= isnull(@parXML.value('(/parametri/@numele_delegatului)[1]','varchar(30)'),''),  
		@seria_buletin= isnull(@parXML.value('(/parametri/@seria_buletin)[1]','varchar(10)'),''),  
		@numar_buletin= isnull(@parXML.value('(/parametri/@numar_buletin)[1]','varchar(10)'),''),  
		@eliberat= isnull(@parXML.value('(/parametri/@eliberat)[1]','varchar(30)'),''),  
		@mijloc_de_transport= isnull(@parXML.value('(/parametri/@mijloc_de_transport)[1]','varchar(30)'),''),  
		@numarul_mijlocului= isnull(@parXML.value('(/parametri/@numarul_mijlocului)[1]','varchar(13)'),''),  
		@observatii_anexafac= @parXML.value('(/parametri/@explicatii_anexaf)[1]','varchar(200)'),  
		@observatii_anexadoc= @parXML.value('(/parametri/@explicatii_anexad)[1]','varchar(200)'),  
		@ora_expedierii= isnull(@parXML.value('(/parametri/@ora_expedierii)[1]','varchar(6)'),''),  
		@data_expedierii= isnull(@parXML.value('(/parametri/@data_expedierii)[1]','datetime'),'1901-1-1'),  
		@datadoc=isnull(@parXML.value('(/parametri/@datafacturii)[1]','datetime'),''),  
		@punctlivrare=isnull(@parXML.value('(/parametri/@punctlivrare)[1]','varchar(20)'),'')


	if @numele_delegatului=''  
		raiserror('wOPScriuDetaliiFacturare:Nume delegat necompletat!',16,1)  
	if @seria_buletin=''   
		set @seria_buletin=isnull((select substring(buletin,1,2) from infotert where subunitate='C'+@sub and tert=@tert and Identificator=@numele_delegatului),'')  
	if @numar_buletin=''   
		set @numar_buletin=isnull((select substring(buletin,4,6) from infotert where subunitate='C'+@sub and tert=@tert and Identificator=@numele_delegatului),'')  
	if @mijloc_de_transport=''   
		set @mijloc_de_transport=isnull((select Mijloc_tp from infotert where subunitate='C'+@sub and tert=@tert and Identificator=@numele_delegatului),'')  
	if isnull(@observatii,'')=''   
		set @observatii=isnull((select Mijloc_tp from infotert where subunitate='C'+@sub and tert=@tert and Identificator=@numele_delegatului),'')    
	if @ora_expedierii=''
		set @ora_expedierii=rtrim(replace(convert(char(5),GETDATE(),108),':',''))

	if @tip in ('AP','AS')
	begin  
		delete anexadoc where Numar=@numar and data=@datadoc  
		insert into anexadoc   
			(Subunitate,Tip,Numar,Data,Numele_delegatului,Seria_buletin,Numar_buletin,Eliberat,Mijloc_de_transport,Numarul_mijlocului,
			Data_expedierii,Ora_expedierii,Observatii,Punct_livrare,Tip_anexa)
		select @sub,@tip,@numar,@datadoc,@numele_delegatului,@seria_buletin,@numar_buletin,@eliberat,@mijloc_de_transport,@numarul_mijlocului,  
			@data_expedierii,@ora_expedierii,case when ISNULL(@observatii_anexadoc,'')='' then @observatii else @observatii_anexadoc end,@punctlivrare,1
		
	--sp_help anexadoc			
		delete anexafac where Numar_factura=@factura   
		insert into anexafac  
			(Subunitate,Numar_factura,Numele_delegatului,Seria_buletin,Numar_buletin,Eliberat,Mijloc_de_transport,Numarul_mijlocului,
			Data_expedierii,Ora_expedierii,Observatii)
		select @sub,@factura,@numele_delegatului,@seria_buletin,@numar_buletin,@eliberat,@mijloc_de_transport,@numarul_mijlocului,  
			@data_expedierii,@ora_expedierii,case when ISNULL(@observatii_anexafac,'')='' then @observatii else @observatii_anexafac end
	end  
	else   
	begin
		delete anexadoc where Numar=@numar and data=@datadoc  
		insert into anexadoc 
			(Subunitate,Tip,Numar,Data,Numele_delegatului,Seria_buletin,Numar_buletin,Eliberat,Mijloc_de_transport,Numarul_mijlocului,
			Data_expedierii,Ora_expedierii,Observatii,Punct_livrare,Tip_anexa)
		select @sub,@tip,@numar,@datadoc,@numele_delegatului,@seria_buletin,@numar_buletin,@eliberat,@mijloc_de_transport,@numarul_mijlocului,  
			@data_expedierii,@ora_expedierii,case when ISNULL(@observatii_anexadoc,'')='' then @observatii else @observatii_anexadoc end,@punctlivrare,''
	end

	select 'Detaliile pentru facturare au fost adaugate pe factura: '+rtrim(@factura) as textMesaj, 'Finalizare operatie' as titluMesaj   
	for xml raw, root('Mesaje')  
end try  
begin catch  
	set @mesaj = ERROR_MESSAGE()  
	raiserror(@mesaj, 11, 1)   
end catch		
end  
