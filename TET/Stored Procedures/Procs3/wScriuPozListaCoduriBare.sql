
create procedure wScriuPozListaCoduriBare @sesiune varchar(50), @parXML xml
as

	declare @utilizator varchar(100), @cod varchar(20), @codbara varchar(20)

	exec wIaUtilizator @sesiune=@sesiune, @utilizator=@utilizator OUTPUT
	set @cod=@parXML.value('(/*/*/@cod)[1]','varchar(20)')
	set @codbara=@parXML.value('(/*/*/@codbara)[1]','varchar(20)')

	if isnull(@cod,'')='' or isnull(@codbara,'')<>''
	select top 1 @cod =cod_produs from codbare where Cod_de_bare=@codbara
	if isnull(@cod,'')<>''
		insert into temp_ListareCodBare(utilizator, cod)
		SELECT @utilizator, @Cod


	exec wIaPozListaCoduriBare @sesiune=@sesiune, @parXML=@parXML
