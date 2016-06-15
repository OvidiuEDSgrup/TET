--***
CREATE procedure [yso].[wStergProprietatiTerti] @sesiune varchar(30), @parXML XML
as
declare @tert varchar(13), @codprop varchar(20), @cautare varchar(100)
Set @tert = @parXML.value('(/row/@tert)[1]','varchar(13)')
Set @codprop = @parXML.value('(/row/row/@codprop)[1]','varchar(20)')
set @cautare=@parXML.value('(/row/@_cautare)[1]','varchar(100)')
--set @cautare='%'+isnull(@cautare,'')+'%'

delete from proprietati where tip='TERT' and cod=@tert and Cod_proprietate=@codprop
