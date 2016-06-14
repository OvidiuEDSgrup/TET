-- delete doc; select * from doc
declare @p2 xml
set @p2=(select [update]=1
,datainf=CONVERT(varchar(10),getdate(),101), datasup=CONVERT(varchar(10),getdate(),101)
,[AP]=1
,[AS]=1
,[AC]=1
,[TE]=1
,tipMacheta='O'
,codMeniu='YE'
for xml raw('parametri'))
exec wOPRefacereAntetDocumente @sesiune=null,@parXML=@p2
