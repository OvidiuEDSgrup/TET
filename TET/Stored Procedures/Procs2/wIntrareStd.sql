--***
create procedure [dbo].[wIntrareStd] @sesiune varchar(50), @parXML xml
as 
declare @cSesiune char(20),@dData datetime, @comanda varchar(max), @proprietate varchar(100),	@id varchar(20),@nume varchar(100),@gestUser varchar(50)
declare @parola varchar(255),@utilizator varchar(255), @msgEroare varchar(max), @aplicatie varchar(50), @versiune int, @versiuneMinima int
declare @parolacit varchar(200)

select	@aplicatie = @parXML.value('(/row/@aplicatie)[1]','varchar(50)'),
		@versiune = @parXML.value('(/row/@versiune)[1]','int')
		
set @dData=getdate()  
set @cSesiune=convert(char(8),@dData,112)+convert(char(26),@dData,114)  
set @utilizator=isnull(@parXML.value('(/row/@utilizator)[1]','varchar(100)'),'')
set @parola=isnull(@parXML.value('(/row/@parola)[1]','varchar(100)'),'')

	
select @id=ID, @nume=rtrim(Nume),@parolacit=rtrim(info) from utilizatori where ID=@utilizator

if @id is null 
begin
	set @msgEroare = 'Utilizatorul windows('+@utilizator + ') nu are atasat utilizator de ASiS!'
	raiserror(@msgEroare, 11, 1)
	return -1
end
if @parolacit!=@parola
begin
	set @msgEroare = 'Eroare de autentificare!'
	raiserror(@msgEroare, 11, 1)
	return -1
end

exec intrareuser @sesiune,@parXML

select rtrim(Nume) as nume,@sesiune as sesiune from utilizatori where ID=@utilizator
for xml raw
