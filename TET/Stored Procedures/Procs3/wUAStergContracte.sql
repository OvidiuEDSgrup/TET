create procedure [dbo].[wUAStergContracte] @sesiune [varchar](50), @parXML [xml]
WITH EXECUTE AS CALLER
AS
declare @mesajeroare varchar(500),@utilizator char(10), @userASiS varchar(20),@sub char(9),@tip char(2),
	@codabonat varchar(30),@idcontract int,@contract varchar(30)

set @Utilizator=dbo.fIauUtilizatorCurent()  
set @userASiS=isnull((select max(id) from utilizatori where observatii=SUSER_name()), '')  

declare @iDoc int
EXEC sp_xml_preparedocument @iDoc OUTPUT, @parXML

begin try        
    select
         @codabonat = rtrim(ltrim(isnull(@parXML.value('(/row/@codabonat)[1]','varchar(30)'),0))),
         @idcontract = rtrim(ltrim(isnull(@parXML.value('(/row/@id_contract)[1]','int'),0))),
         @contract = rtrim(ltrim(isnull(@parXML.value('(/row/@contract)[1]','varchar(30)'),0)))
         
    
    if exists (select 1 from sys.objects where name='wScriuContracteUASP' and type='P')
		exec wScriuContracteUASP @sesiune, @parXML
	else   
	begin
		--exec wUAValidareAbonatiContr  @parXML   
		if @idcontract in (select id_contract from antetfactabon)
			begin     
				set @mesajeroare='Contractul are facturi pe el; nu se poate sterge !'  
				raiserror(@mesajeroare,11,1)  
			end
		if @idcontract in (select id_contract from uapozcon)
			begin     
				set @mesajeroare='Contractul are pozitii pe el; nu se poate sterge !'  
				raiserror(@mesajeroare,11,1)  
			end
		delete from uacon where Id_contract=@idcontract
		
	end
end try
begin catch
set @mesajeroare = ERROR_MESSAGE()
 raiserror(@mesajeroare, 11, 1)
end catch
