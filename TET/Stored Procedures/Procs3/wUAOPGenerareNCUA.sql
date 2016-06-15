--***
/* descriere... */
create procedure [dbo].[wUAOPGenerareNCUA](@sesiune varchar(50), @parXML xml) 
as     
begin
declare @utilizator varchar(8),@abonat_fact varchar(13),@docXML xml,@mesaj varchar(200),@factura_sus int,@factura_jos int,
        @filtruAbonat varchar(13),@data_jos datetime,@data_sus datetime,@userASiS varchar(20),@filtruLm varchar(13)
begin try
exec wIaUtilizator @sesiune, @utilizator output

select	@data_jos=ISNULL(@parXML.value('(/parametri/@data_jos)[1]', 'datetime'), '1901-01-01'),
        @data_sus=ISNULL(@parXML.value('(/parametri/@data_sus)[1]', 'datetime'), '2901-01-01'),	
		@filtruLm = isnull(@parXML.value('(/parametri/@filtruLm)[1]','varchar(13)'),'')		
		
		set @userASiS=isnull((select max(id) from utilizatori where observatii=SUSER_name()), '')
	
  -- exec UAAnulFact @factura_jos ,@factura_sus, @filtruAbonat , @data_jos,@data_sus,@userASiS,@utilizator
     exec UAGenNC @data_jos,@data_sus,@utilizator,@filtruLm
   
    end try
begin catch
set @mesaj = ERROR_MESSAGE()
	raiserror(@mesaj, 11, 1)	
end catch	
end
