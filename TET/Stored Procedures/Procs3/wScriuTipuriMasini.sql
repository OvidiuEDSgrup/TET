--***

CREATE procedure wScriuTipuriMasini @sesiune varchar(50), @parXML XML
as

declare @eroare varchar(1000), @utilizatorASiS varchar(50)
set @eroare=''

begin try
	exec wIaUtilizator @sesiune=@sesiune, @utilizator=@utilizatorASiS output
	
	declare @cod varchar(50), @denumire varchar(100), @tip_activitate varchar(1),
			@update varchar(1), @o_cod varchar(50), @o_tip_activitate varchar(1)
	select	@cod=isnull(@parXML.value('(row/@cod)[1]','varchar(50)'),''),
			@denumire=isnull(@parXML.value('(row/@denumire)[1]','varchar(100)'),''),
			@tip_activitate=isnull(@parXML.value('(row/@tip_activitate)[1]','varchar(1)'),''),
			@update=isnull(@parXML.value('(row/@update)[1]','varchar(1)'),'0'),
			@o_cod=isnull(@parXML.value('(row/@o_cod)[1]','varchar(50)'),''),		
			@o_tip_activitate=isnull(@parXML.value('(row/@o_tip_activitate)[1]','varchar(1)'),'')
			
	if (@update='0') 
	begin
		if exists (select 1 from tipmasini t where t.cod=@cod)
			raiserror('Tipul acesta exista deja!',16,1)
		insert into tipmasini(cod, denumire, tip_activitate)
		select @cod, @denumire, @tip_activitate
		--raiserror ('Adaugarea nu este permisa!',16,1)
	end
	if exists (select 1 from grupemasini g where g.tip_masina=@o_cod)
	begin
		if @cod<>@o_cod 
			raiserror('Exista grupe de masini pe acest tip! Nu este permisa modificarea codului!',16,1)
		if @tip_activitate<>@o_tip_activitate 
			raiserror ('Exista grupe de masini pe acest tip! Nu este permisa modificarea tipului de activitate!',16,1)
	end
	
	update t set Cod=@cod, t.Denumire=@denumire, t.Tip_activitate=@tip_activitate
		     from tipmasini t where t.Cod=@o_cod
	
end try
begin catch
	set @eroare='(wScriuTipuriMasini):'+char(10)+
		rtrim(ERROR_MESSAGE())	
end catch

if len(@eroare)>0 raiserror(@eroare,16,1)
