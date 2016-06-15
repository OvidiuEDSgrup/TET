--***
/* descriere... */
create procedure [dbo].[wUAOPAnulareFacturi](@sesiune varchar(50), @parXML xml) 
as     
begin
declare @utilizator varchar(8),@abonat_fact varchar(13),@docXML xml,@mesaj varchar(200),@factura_sus int,@factura_jos int,
        @filtruAbonat varchar(13),@data_jos datetime,@data_sus datetime,@userASiS varchar(20)
begin try
exec wIaUtilizator @sesiune, @utilizator output

select	@data_jos=ISNULL(@parXML.value('(/parametri/@data_jos)[1]', 'datetime'), '1901-01-01'),
        @data_sus=ISNULL(@parXML.value('(/parametri/@data_sus)[1]', 'datetime'), '2901-01-01'),	
		@factura_sus = isnull(@parXML.value('(/parametri/@factura_sus)[1]','int'),0),	
		@factura_jos = isnull(@parXML.value('(/parametri/@factura_jos)[1]','int'),0),
		@filtruAbonat = isnull(@parXML.value('(/parametri/@filtruAbonat)[1]','varchar(13)'),'')	
		
		set @userASiS=isnull((select max(id) from utilizatori where observatii=SUSER_name()), '')
	
   exec UAAnulFact @factura_jos ,@factura_sus, @filtruAbonat , @data_jos,@data_sus,@userASiS,@utilizator
   
    end try
begin catch
set @mesaj = ERROR_MESSAGE()
	raiserror(@mesaj, 11, 1)	
end catch	
end
