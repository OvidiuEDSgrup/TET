--***
/* Procedura pentru configurare TB - adauga/modifica o categorie de indicatori */
CREATE procedure  wScriuCategorii  @sesiune varchar(50), @parXML XML
as
declare @cod varchar(20), @denumire varchar(50), @categtb varchar(10),@o_cod varchar(20), @modificare int, @msgEroare varchar(500),@nrordine int

begin try
	select	@cod = rtrim(isnull(@parXML.value('(/row/@codCat)[1]', 'varchar(20)'), '')),
			@o_cod = rtrim(isnull(@parXML.value('(/row/@o_codCat)[1]', 'varchar(10)'), '')),
			@denumire = rtrim(isnull(@parXML.value('(/row/@denumire)[1]', 'varchar(50)'), '')),
--			@categtb = rtrim(isnull(@parXML.value('(/row/@categtb)[1]', 'varchar(10)'), '')),
			@modificare=isnull(@parXML.value('(/row/@update)[1]', 'int'), 0),
			@nrordine=isnull(@parXML.value('(/row/@nrordine)[1]', 'int'), 0)

	if (@modificare=0 or @o_cod<>@cod) and (select COUNT(*) from categorii where Cod_categ = @cod) > 0 
	begin
			set @msgEroare = (select 'Codul: '+@cod+' este asociat deja unei categorii!')
			RAISERROR(@msgEroare,16,1)
	end	

	if len(@denumire)=0
	begin
			set @msgEroare = (select 'Codul: '+@cod+' este asociat deja unei categorii!')
			RAISERROR(@msgEroare,16,1)
	end

	--if @categtb=0	set @nrordine=0
		
	if @modificare=1
	begin
		update categorii set Cod_categ=@cod, Denumire_categ=@denumire, categ_tb=@nrordine
			where Cod_categ=@o_cod
		update compcategorii set Cod_categ=@cod
			where Cod_categ=@o_cod
	end
	else
		insert into categorii(Cod_categ, Denumire_categ, categ_tb) VALUES (@cod,@denumire,@nrordine)

end try
begin catch
	set @msgEroare=Error_message()+'(wScriuCategorii)'
	raiserror(@msgEroare, 11,1)
end catch 
