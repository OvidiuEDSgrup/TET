--***
/* procedura pentru populare macheta de import rectificari salarii */
Create procedure wOPImportRectificariSalarii_p @sesiune varchar(50), @parXML xml 
as  

declare @utilizator varchar(10), @bazaRectificare varchar(100)

exec wIaUtilizator @sesiune = @sesiune, @utilizator = @utilizator output

select @bazaRectificare=dbo.iauParA('PS','BDRECTIF')

select rtrim(@bazaRectificare) as bazarectificare
for xml raw
