
--execute AS login='tet\magazin.ag'
select SUSER_NAME()
declare @p2 xml
set @p2=convert(xml,N'<row f_cont="5311.AG" tip="RE" datajos="2013/12/20" datasus="2014/01/08"/>')
exec wIaPlin @sesiune='',@parXML=@p2
execute AS login='tet\magazin.ag'
exec wIaPlin @sesiune='',@parXML=@p2
revert