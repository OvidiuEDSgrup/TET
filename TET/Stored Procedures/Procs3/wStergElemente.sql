--***
create procedure wStergElemente @sesiune varchar(50),@parXML XML
as
declare @eroare varchar(1000),@utilizatorASiS varchar(50)
set @eroare=''
begin try
	exec wIaUtilizator @sesiune=@sesiune, @utilizator=@utilizatorASiS output
	
	declare @cod varchar(20)
	select	@cod=isnull(@parXML.value('(row/@cod)[1]','varchar(20)'),'')
	
	if (@cod='')
			 raiserror('Nu s-a identificat elementul de sters! Verificati configurarea machetei si procedura!',16,1)
	begin
		if (exists (select 1 from elemactivitati a where a.Element=@cod) or
		    exists (select 1 from elemtipm t where t.Element=@cod)
			) 
			raiserror('Elementul este folosit! Nu este permisa stergerea!',16,1)
		delete e from elemente e where e.Cod=@cod
	end
end try
begin catch
	set @eroare='wStergElemente'+
		char(10)+ERROR_MESSAGE()
end catch

if len(@eroare)>0 raiserror(@eroare,16,1)
