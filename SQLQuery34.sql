declare @p2 xml
set @p2=convert(xml,N'<row codMeniu="N" tipMacheta="C" Tip="N"/>')
exec wIaConfigurareFiltre @sesiune='8BA9ADE981205',@parXML=@p2