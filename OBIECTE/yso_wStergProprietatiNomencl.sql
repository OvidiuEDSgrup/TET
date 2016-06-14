drop procedure yso_wStergProprietatiNomencl 
GO
--***
CREATE procedure yso_wStergProprietatiNomencl @sesiune varchar(30), @parXML XML
as
declare @cod varchar(13), @codprop varchar(20), @cautare varchar(100)
Set @cod = @parXML.value('(/row/@cod)[1]','varchar(13)')
Set @codprop = @parXML.value('(/row/row/@codprop)[1]','varchar(20)')
set @cautare=@parXML.value('(/row/@_cautare)[1]','varchar(100)')
--set @cautare='%'+isnull(@cautare,'')+'%'

delete from proprietati where tip='NOMENCL' and cod=@cod and Cod_proprietate=@codprop


 
