declare @parxml xml=convert(xml,'<row tip="TE"/>')
exec wIaDoc null,@parxml
exec wACCom