declare @p2 xml
set @p2=convert(xml,N'<row tip="CL" codmeniu="D_CL" tipmacheta="D"/>')
exec wIaFormulare @sesiune='6791D0E235982',@parXML=@p2