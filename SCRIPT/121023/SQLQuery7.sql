declare @p2 xml
set @p2=convert(xml,N'<row tipMacheta="D" codMeniu="IK" Tip="IC"/>')
exec wIaConfigurareSubTipuri @sesiune='A8BF61AC12F93',@parXML=@p2