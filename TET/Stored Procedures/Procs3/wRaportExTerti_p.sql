--***
create procedure wRaportExTerti_p @sesiune varchar(50), @parXML XML
as
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
set nocount on

select 'TertiEXCEL' as procedura
for xml raw
