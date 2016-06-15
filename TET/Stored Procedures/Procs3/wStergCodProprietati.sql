--***
Create procedure wStergCodProprietati @sesiune varchar(30), @parXML XML
as
declare @cod varchar(20), @proprietate varchar(50), @cautare varchar(100)
Set @cod = @parXML.value('(/row/@cod)[1]','varchar(20)')
Set @proprietate = @parXML.value('(/row/row/@codprop)[1]','varchar(50)')
set @cautare=@parXML.value('(/row/@_cautare)[1]','varchar(100)')
set @cautare='%'+isnull(@cautare,'')+'%'

delete from proprietati where cod=@cod and Cod_proprietate=@proprietate


 
