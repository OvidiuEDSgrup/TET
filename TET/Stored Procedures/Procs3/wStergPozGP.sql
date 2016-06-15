create procedure wStergPozGP @sesiune varchar(20), @parXML xml
as
declare @factura varchar(20), @datafacturii datetime, @nrdoc varchar(20), @tert varchar(20), @fdataAntet datetime
begin try
select 
      @datafacturii=ISNULL(@parXML.value('(/row/@datafacturii)[1]', 'datetime'), '2011-05-05'),
      @factura=ISNULL(@parXML.value('(/row/row/@factura)[1]', 'varchar(20)'), '2011-05-05'),
	  @fdataAntet=ISNULL(@parXML.value('(/row/row/@data)[1]', 'datetime'), '2011-05-05'),
	  @nrdoc=isnull(@parXML.value('(/row/@numar)[1]', 'varchar(20)'), ''),
	  @tert=isnull(@parXML.value('(/row/@tert)[1]', 'varchar(20)'), '')

  delete from generareplati where Factura=@factura and Data1=@datafacturii
  delete from prog_plin where Factura=@factura and Data=@datafacturii
 declare @docXMLIaPozGP xml  
 set @docXMLIaPozGP = '<row numar="' + rtrim(@nrdoc) + '" data="' + convert(varchar(20), @fdataAntet, 101)+'"/>'  
 select @docXMLIaPozGP
 exec wIaPozGP @sesiune=@sesiune, @parXML=@docXMLIaPozGP
    
 end try
 begin catch
  declare @eroare varchar(50)
   set @eroare=ERROR_MESSAGE()
    raiserror(@eroare,16,1)
 end catch