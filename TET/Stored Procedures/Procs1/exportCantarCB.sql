--***

CREATE proc [dbo].[exportCantarCB] @sesiune varchar(50), @parxml xml
as
declare @scale varchar(100)

set @scale=ISNULL(@parXML.value('(/row/@scale)[1]', 'varchar(100)'), 0)

if @scale='Mettler Toledo'
begin
	exec exportCantarV1 @sesiune,''
end
if @scale='Digi'
begin
	exec exportCantarV2 @sesiune,''
end
if @scale='Dibal'
begin
	exec exportCantarV3 @sesiune,''
end
