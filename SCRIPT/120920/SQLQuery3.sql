declare @p2 xml
set @p2=convert(xml,N'<row tipMacheta="D" codMeniu="CO" tip="BK" subtip="" update="0" numar="" data="09/20/2012" gestiune="" gestprim="" tert="" lm="" explicatii="" info1="" info2="0" denstare="" valoare="0" valtva="0" valtotala="0" contr_cadru="electr" searchText="electri"/>')
exec wACContracte @sesiune='EACAC7EAEF843',@parXML=@p2