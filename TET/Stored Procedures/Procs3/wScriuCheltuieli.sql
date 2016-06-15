--***
create procedure [dbo].[wScriuCheltuieli] @sesiune varchar(50), @parXML xml   
as  
declare @tipDoc varchar(2),@numar varchar(20),@data varchar(10),@lm varchar(9)
declare @comanda varchar(20),@articol varchar(30),@numar_pozitie varchar(10),@explicatii varchar(200), @CI varchar (10)
declare @binar varbinary(128), @eroare xml, @userASiS varchar(20)
--
set @tipDoc=ISNULL(@parXML.value('(/row/row/@tipDoc)[1]', 'varchar(2)'), '')
set @numar=ISNULL(@parXML.value('(/row/row/@numar)[1]', 'varchar(20)'), '')
set @data=ISNULL(@parXML.value('(/row/row/@data)[1]', 'varchar(10)'), '')
set @numar_pozitie=ISNULL(@parXML.value('(/row/row/@numar_pozitie)[1]', 'varchar(20)'), '')
set @lm=ISNULL(@parXML.value('(/row/row/@lm)[1]', 'varchar(20)'), '')
set @comanda=ISNULL(@parXML.value('(/row/row/@comanda)[1]', 'varchar(20)'), '')
set @articol=ISNULL(@parXML.value('(/row/row/@articol)[1]', 'varchar(30)'), '')
set @explicatii=ISNULL(@parXML.value('(/row/@explicatii)[1]', 'varchar(200)'), '')
set @CI=ISNULL(@parXML.value('(/row/row/@CI)[1]', 'varchar(20)'), '')
EXEC wIaUtilizator @sesiune=@sesiune, @utilizator=@userASiS OUTPUT
IF @userASiS IS NULL
	RETURN -1

--
begin try  
 --BEGIN TRAN  

set @eroare = dbo.wfValidareCheltuieli(@parXML)  
if isnull(@eroare.value('(error/@coderoare)[1]', 'int'), 0)>0  
   raiserror('Document invalid', 11, 1)  
--
if @tipDoc in ('CM','AI','RS')
begin
set @binar=cast('modificarelunablocata' as varbinary(128))
set CONTEXT_INFO @binar
update pozdoc set Loc_de_munca=@lm,Comanda=@comanda,utilizator=@userASiS, data_operarii=convert(datetime, convert(char(10), getdate(), 104), 104), ora_operarii=RTrim(replace(convert(char(8), getdate(), 108), ':', '')) 
	,Barcod=@articol
	where tip=@tipDoc and Numar=@numar and Data=@data and numar_pozitie=@numar_pozitie
set CONTEXT_INFO 0x00
exec wIaPozCheltuieli @sesiune=@sesiune, @parXML=@parXML
end
--
if @tipDoc='PI' and SUBSTRING(@explicatii,1,2)='PD'
begin
set @binar=cast('modificarelunablocata' as varbinary(128))
set CONTEXT_INFO @binar
update pozplin set Loc_de_munca=@lm,Comanda=@comanda,utilizator=@userASiS, data_operarii=convert(datetime, convert(char(10), getdate(), 104), 104), ora_operarii=RTrim(replace(convert(char(8), getdate(), 108), ':', '')) 
	, factura=@articol
	where Plata_incasare='PD' and cont=@numar and Numar=@CI and Data=@data and numar_pozitie=rtrim(@numar_pozitie)
set CONTEXT_INFO 0x00
exec wIaPozCheltuieli @sesiune=@sesiune, @parXML=@parXML
end
--
if @tipDoc in ('NC')
begin
set @binar=cast('modificarelunablocata' as varbinary(128))
set CONTEXT_INFO @binar
update pozncon set Loc_munca=@lm,Comanda=@comanda,utilizator=@userASiS, data_operarii=convert(datetime, convert(char(10), getdate(), 104), 104), ora_operarii=RTrim(replace(convert(char(8), getdate(), 108), ':', '')) 
	,tert=@articol
	where tip=@tipDoc and Numar=@numar and Data=@data and nr_pozitie=@numar_pozitie
set CONTEXT_INFO 0x00
exec wIaPozCheltuieli @sesiune=@sesiune, @parXML=@parXML
end
--
if @tipDoc='FF' 
begin
set @binar=cast('modificarelunablocata' as varbinary(128))
set CONTEXT_INFO @binar
update pozadoc set Loc_munca=@lm,Comanda=@comanda,utilizator=@userASiS, data_operarii=convert(datetime, convert(char(10), getdate(), 104), 104), ora_operarii=RTrim(replace(convert(char(8), getdate(), 108), ':', '')) 
	, Factura_stinga=@articol
	where tip=@tipDoc and Numar_document=@numar and Data=@data and numar_pozitie=@numar_pozitie --and Factura_dreapta=@CI
set CONTEXT_INFO 0x00
exec wIaPozCheltuieli @sesiune=@sesiune, @parXML=@parXML
end
   
 --COMMIT TRAN  
end try  
begin catch  
 --ROLLBACK TRAN  
 declare @mesaj varchar(255)
 --if isnull(@eroare.value('(/error/@coderoare)[1]', 'int'), 0) = 0  
	set @mesaj = ERROR_MESSAGE() 
	--set @mesaj='<error coderoare="1" msgeroare="' + ERROR_MESSAGE() + '"/>' 
 raiserror(@mesaj, 11, 1)  
end catch  
