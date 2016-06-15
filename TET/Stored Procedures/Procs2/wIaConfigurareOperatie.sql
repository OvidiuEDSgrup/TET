--***
CREATE procedure wIaConfigurareOperatie @sesiune varchar(50), @tipmacheta varchar(20)
as

select titlumacheta,procedurasql,descriere from webConfigOperatii where tipmacheta = @tipmacheta
for XML RAW
