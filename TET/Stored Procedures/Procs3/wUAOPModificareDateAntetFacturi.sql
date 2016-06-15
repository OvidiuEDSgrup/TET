--***
/* descriere... */
create procedure [dbo].[wUAOPModificareDateAntetFacturi](@sesiune varchar(50), @parXML xml) 
as     
begin
declare @utilizator varchar(8),@mesaj varchar(200),@id_factura int,@factura varchar(13),@id_contract int,
        @userASiS varchar(20),@tip char(2),@data datetime,@datascadentei datetime,@tip_tva smallint,@perioada_inceput datetime,
        @perioada_sfarsit datetime
begin try
exec wIaUtilizator @sesiune, @utilizator output

select	@id_factura= isnull(@parXML.value('(/parametri/@id)[1]','int'),0),
		@factura= isnull(@parXML.value('(/parametri/@factura)[1]','varchar(13)'),''),
		@tip = isnull(@parXML.value('(/parametri/@tip)[1]','varchar(2)'),''),
		
		@id_contract=isnull(@parXML.value('(/parametri/@id_contract)[1]','int'),0),
		@data=ISNULL(@parXML.value('(/parametri/@data)[1]', 'datetime'), '1901-01-01'),
		@datascadentei=ISNULL(@parXML.value('(/parametri/@datascadentei)[1]', 'datetime'), '1901-01-01'),
		@perioada_inceput=ISNULL(@parXML.value('(/parametri/@per_fact_jos)[1]', 'datetime'), '1901-01-01'),
		@perioada_sfarsit=ISNULL(@parXML.value('(/parametri/@per_fact_sus)[1]', 'datetime'), '2901-01-01')
		
		set @userASiS=isnull((select max(id) from utilizatori where observatii=SUSER_name()), '')    	
	
	if @id_contract not in(select id_contract from UAcon)
		begin
			set @mesaj='Contractul introdus nu exista in baza de date'
			raiserror(@mesaj,11,1)
		end
			
	if @id_contract<>0 and @data<>'1901-01-01' and @datascadentei<>'1901-01-01'
					   and @perioada_inceput<>'1901-01-01' and @perioada_sfarsit<>'2901-01-01'
	    begin
			update AntetFactAbon set Id_contract=@id_contract ,Data=@data,Data_scadentei=@datascadentei,Perioada_inceput=@perioada_inceput,
									 Perioada_sfarsit=@perioada_sfarsit			
			where Id_factura=@id_factura  
			select 'Antetul facturii '+rtrim(@factura)+' a fost modificat! ' as textMesaj, 'Finalizare operatie' as titluMesaj 
			for xml raw, root('Mesaje')
		end
		
    end try
begin catch
set @mesaj = ERROR_MESSAGE()
	raiserror(@mesaj, 11, 1)	
end catch	
end
--select * from antetfactabon
