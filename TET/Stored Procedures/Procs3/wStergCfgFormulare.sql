--***
create procedure wStergCfgFormulare (@sesiune varchar(50), @parXML xml)
as
begin
declare @eroare varchar(2000)
begin try
	declare @utilizator varchar(20)
	exec wIaUtilizator @sesiune=@sesiune, @utilizator=@utilizator output

--	citire parametri
	declare @formular varchar(20)

	select	@formular=rtrim(isnull(@parXML.value('(row/@formular)[1]','varchar(20)'),''))

--	erori
	if (@formular='') raiserror ('Completati cu un numar de formular!',16,1)
	if not exists (select 1 from antform where Numar_formular=@formular)
		raiserror('Formularul nu exista in baza de date!',16,1)
	if exists (select 1 from WebConfigFormulare w where w.cod_formular=@formular)
		raiserror('Formularul are configurate asocieri pe machete!',16,1)
--	stergerea propriu-zisa
	delete x from xmlformular x where x.Numar_formular=@formular
	delete f from antform f where f.numar_formular=@formular

end try
begin catch
	set @eroare=ERROR_MESSAGE()+' (wStergCfgFormulare '+convert(varchar(20),ERROR_LINE())+')'
end catch
if len(@eroare)>0 raiserror(@eroare, 16,1)
end
