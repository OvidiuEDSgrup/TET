/****** Object:  StoredProcedure [dbo].[wUAOPListareFacturi]    Script Date: 01/05/2011 23:20:13 ******/
--***
/* descriere... */
create procedure  [dbo].[wUAOPStornareFacturaAbonati] (@sesiune varchar(50), @parXML xml) 
as     
begin
declare @mesaj varchar(200), @id_factura int ,@tip char(2),@data datetime,@utilizator varchar(13),
		@paridfacturastor int,@parfacturastor varchar(13),@factura varchar(13)
begin try
exec wIaUtilizator @sesiune, @utilizator output

select  @id_factura= isnull(@parXML.value('(/parametri/@id)[1]','int'),0),
		@factura= isnull(@parXML.value('(/parametri/@factura)[1]','varchar(13)'),''),
		@tip = isnull(@parXML.value('(/parametri/@tip)[1]','varchar(2)'),''),
		@data=ISNULL(@parXML.value('(/parametri/@data_storno)[1]', 'datetime'), '1901-01-01')	,		
		@paridfacturastor=0,
		@parfacturastor=''
   
  select @tip,@data ,@id_factura ,@paridfacturastor output,@parfacturastor output,@utilizator,1
   exec UAStornoFactura @tip,@data ,@id_factura ,@paridfacturastor output,@parfacturastor output,@utilizator,1
 
   select 'S-a stornat factura '+rtrim(@factura)+' prin factura storno '+rtrim(@parfacturastor)+' !' as textMesaj, 'Finalizare operatie' as titluMesaj for xml raw, root('Mesaje')

    end try
begin catch
set @mesaj = ERROR_MESSAGE()
	raiserror(@mesaj, 11, 1)	
end catch	
end
