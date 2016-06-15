--***

CREATE procedure wScriuTipAutovehicule @sesiune varchar(50), @parXML XML
as
declare @cod varchar(20), @o_cod varchar(20), @marca varchar(50), @model varchar(50), 
		@versiune varchar(50), @tipmotor varchar(50), @capacitate varchar(50), @putere varchar(50), 
	    @grupa varchar(50), @update int

set @cod= rtrim(isnull(@parXML.value('(/row/@cod)[1]', 'varchar(20)'), ''))
set @o_cod= rtrim(isnull(@parXML.value('(/row/@o_cod)[1]', 'varchar(20)'), ''))
set	@marca = rtrim(isnull(@parXML.value('(/row/@marca)[1]', 'varchar(50)'), ''))
set	@model = rtrim(isnull(@parXML.value('(/row/@model)[1]', 'varchar(50)'), ''))
set	@versiune= rtrim(isnull(@parXML.value('(/row/@versiune)[1]', 'varchar(50)'), ''))
set	@tipmotor = rtrim(isnull(@parXML.value('(/row/@tipmotor)[1]', 'varchar(50)'), ''))
set	@capacitate = rtrim(isnull(@parXML.value('(/row/@capacitate)[1]', 'varchar(50)'), ''))
set	@putere = rtrim(isnull(@parXML.value('(/row/@putere)[1]', 'varchar(50)'), ''))
set	@grupa = rtrim(isnull(@parXML.value('(/row/@grupa)[1]', 'varchar(50)'), ''))
set @update=isnull(@parXML.value('(/row/@update)[1]', 'int'), 0)

if @update=1 and isnull(@cod,'')<>@o_cod and exists (select 1 from auto where Tip_auto=@o_cod)
begin
		raiserror('Nu este permisa schimbarea codului, deoarece codul vechi este folosit in documente sau in alte cataloage!',11,1)
		return
end
	
if (@update=0 or @update=1 and isnull(@cod,'')<>@o_cod) and exists (select 1 from tipauto where cod=@cod)
begin
		raiserror('Acest cod exista deja!',11,1)
		return
end

if isnull(@cod,'')='' 
begin
		raiserror('Cod necompletat!',11,1)
		return
end

--Aici incepe partea de modificare
if @update=1
begin
	update tipauto set Cod=@cod, Marca=@marca, Model=@model, Versiune=@versiune, 
		Tip_motor=@tipmotor, Putere=@putere, Capacitate=@capacitate, Grupa=@grupa
		where Cod=@o_cod
end
--Aici incepe partea de adaugare
else
begin
		insert into tipauto(Cod, Marca, Model, Versiune, Tip_motor, Capacitate, Putere, Grupa)
			VALUES (@cod, @marca, @model, @versiune, @tipmotor, @capacitate, @putere, @grupa)
end
