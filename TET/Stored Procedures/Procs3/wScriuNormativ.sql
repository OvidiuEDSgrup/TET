--***

CREATE procedure  wScriuNormativ  @sesiune varchar(50), @parXML XML
as
declare @mesajeroare varchar(max), @Masina varchar(20), @coeficient varchar(20), @interval float, @valoare float

set	@Masina = rtrim(isnull(@parXML.value('(/row/@codMasina)[1]', 'varchar(50)'), ''))
set	@coeficient = rtrim(isnull(@parXML.value('(/row/row/@cod)[1]', 'varchar(50)'), ''))
set	@interval = isnull(@parXML.value('(/row/row/@interval)[1]', 'float'), '9999999')
set	@valoare = isnull(@parXML.value('(/row/row/@valoare)[1]', 'float'), '9999999')

--Aici incepe partea de modificare
declare @update int
set @update=isnull(@parXML.value('(/row/@update)[1]', 'int'), 0)

if @mesajeroare<>''
	raiserror (@mesajeroare,11,1)	
if @update=1
begin   
	update coefmasini  set Masina=@Masina, Coeficient=@coeficient, Valoare=@valoare, Interval=@interval	  
		where masina =@Masina and Coeficient=@coeficient		
	return
end
	else 

--Aici incepe partea de adaugare 
if not exists(select 1 from coefmasini c 
                     WHERE  c.masina=@Masina and c.Coeficient=@coeficient)
		  begin		 
			insert into coefmasini (Masina, Coeficient, Valoare, Interval)
			VALUES (@Masina, @coeficient, @valoare, @interval)
		  end
else 

begin
	raiserror('Eroare adaugare linie - coeficientul este adaugat deja!',11,1)
end


