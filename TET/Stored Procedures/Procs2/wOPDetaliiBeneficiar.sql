create procedure wOPDetaliiBeneficiar @sesiune varchar(50), @parXML xml
as 

declare @tert varchar(20), @modificare bit, @iban varchar(50), @banca varchar(50), @nrdoc varchar(20), @datapreluarii datetime,
		@dentert varchar(50), @ataseaza bit,@factura varchar(50),@dataFact datetime

select @tert=ISNULL(@parXML.value('(/parametri/row/@tert)[1]', 'varchar(20)'), ''),
	   @dentert=ISNULL(@parXML.value('(/parametri/@tert)[1]', 'varchar(20)'), ''),
	   @modificare=ISNULL(@parXML.value('(/parametri/@modificare)[1]', 'bit'), ''),
	   @ataseaza=ISNULL(@parXML.value('(/parametri/@ataseaza)[1]', 'bit'), ''),
	   @iban=ISNULL(@parXML.value('(/parametri/@iban)[1]', 'varchar(50)'), ''),
	   @banca=ISNULL(@parXML.value('(/parametri/@banca)[1]', 'varchar(50)'), ''),
	   @nrdoc=ISNULL(@parXML.value('(/parametri/@numar)[1]', 'varchar(20)'), ''),
	   @datapreluarii=ISNULL(@parXML.value('(/parametri/@data)[1]', 'datetime'), ''),
	   @factura=ISNULL(@parXML.value('(/parametri/row/@factura)[1]', 'varchar(20)'), ''),
	   @dataFact=ISNULL(@parXML.value('(/parametri/row/@datafacturii)[1]', 'datetime'), '')
begin try
    if @tert=''
       raiserror('wOPDetaliiBeneficiar:Selecteaza o pozitie!',16,1)
	if not exists (select 1 from bancibnr where cod=@banca)
		raiserror('wOPDetaliiBeneficiar:Banca inexistenta',16,1)
    if @modificare=1
    begin
	   update terti set Cont_in_banca=@iban where tert=@tert
	   update terti set banca=@banca where tert=@tert
	end
    update generareplati set iban_beneficiar=@iban, Banca_beneficiar=@banca where tert=@tert and Numar_document=@nrdoc 
                                                                                  and data=@datapreluarii
  
  select 'Detaliile pentru tertul: '+rtrim(@dentert)+' au fost salvate!' as textMesaj, 'Finalizare operatie' as titluMesaj   
  for xml raw, root('Mesaje')  
  declare @docXMLIaPozGP xml  
 set @docXMLIaPozGP = '<row numar="' + rtrim(@nrdoc) + '" data="' + convert(varchar(20), @datafact, 101)+'"/>'  
 select @docXMLIaPozGP
 exec wIaPozGP @sesiune=@sesiune, @parXML=@docXMLIaPozGP 
end try
begin catch
declare @mesaj varchar(50)
set @mesaj = ERROR_MESSAGE()  
 raiserror(@mesaj, 11, 1) 
end catch