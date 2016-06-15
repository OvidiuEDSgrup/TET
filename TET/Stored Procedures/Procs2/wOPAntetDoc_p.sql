
create procedure wOPAntetDoc_p @sesiune varchar(50), @parXML xml
as

declare @data datetime, @tert varchar(20),
		@factura varchar(20), @datafacturii datetime, @datascadentei datetime, @dentert varchar(100), @CUIfurnizor varchar(20)

set @CUIfurnizor = isnull(rtrim(@parXML.value('(/row/factura/@CUIfurnizor)[1]','varchar(20)')),'')
set @data = isnull(@parXML.value('(/row/factura/@data)[1]','datetime'),'')
set @factura = isnull(@parXML.value('(/row/factura/@factura)[1]','varchar(20)'),'')
set @datafacturii = isnull(@parXML.value('(/row/factura/@datafacturii)[1]','datetime'),'')
set @datascadentei= isnull(@parXML.value('(/row/factura/@datascadentei)[1]','datetime'),'')
set @tert = (select max(tert) from terti where Cod_fiscal=@CUIfurnizor)
set @dentert = (select Denumire from terti where Tert=@tert)

select	convert(varchar(10),@data,101) as data,
		rtrim(@tert) as tert, rtrim(@dentert) as dentert,
		rtrim(@factura) as factura,
		convert(varchar(10),@datafacturii,101) as datafacturii,
		convert(varchar(10),@datascadentei,101) as datascadentei
for xml raw
