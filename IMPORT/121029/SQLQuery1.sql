declare @t table (c xml)
declare @x xml

--insert @t
select @x=
(exec wIaPozdoc @sesiune=''
, @parXML='<row subunitate="1" tip="AP" numar="9430281" data="2012-10-29"/>')

go
exec wIadoc @sesiune=''
, @parXML='<row subunitate="1" tip="AP" numar="9430281" data="2012-10-29"/>'