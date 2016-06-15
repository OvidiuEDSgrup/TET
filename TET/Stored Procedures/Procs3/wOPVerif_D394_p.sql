
create procedure wOPVerif_D394_p @sesiune varchar(50), @parXML xml 
as

select datepart(yy,getdate()) as an, datepart(mm,getdate()) as luna
for xml raw
