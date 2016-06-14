DROP procedure yso_wScriuProprietatiNomencl   
GO
--***
CREATE procedure yso_wScriuProprietatiNomencl   @sesiune varchar(30), @parXML XML as
declare @cod varchar(13), @update bit, @valoare varchar(20), @descriere varchar(200), @codprop varchar(50), @denvaloare varchar(80)
	,@o_codprop varchar(20),@o_valoare varchar(20), @o_denvaloare varchar(80)
Select  @cod = @parXML.value('(/row/@cod)[1]','varchar(13)'),
		@update = isnull(@parXML.value('(/row/row/@update)[1]','bit'),0),
		@valoare = isnull(@parXML.value('(/row/row/@valoare)[1]','varchar(50)'),''),
		@codprop = isnull(@parXML.value('(/row/row/@codprop)[1]','varchar(50)'),''),
		@denvaloare = isnull(@parXML.value('(/row/row/@denvaloare)[1]','varchar(80)'),'')
Select @o_codprop= @parXML.value('(/row/row/@o_codprop)[1]','varchar(20)'),
		@o_valoare= isnull(@parXML.value('(/row/row/@o_valoare)[1]','varchar(20)'),''),
		@o_denvaloare= isnull(@parXML.value('(/row/row/@o_valoare)[1]','varchar(20)'),'')
begin try
	if @update=1
	begin
		update proprietati set Valoare=@valoare where tip='NOMENCL' and cod=@cod and Cod_proprietate=isnull(@o_codprop,@codprop)
		if not exists (select 1 from valproprietati v where v.Cod_proprietate=isnull(@o_codprop,@codprop) and v.Valoare=@valoare)
			insert into valproprietati(cod_proprietate,valoare,descriere,valoare_proprietate_parinte) values (@codprop,@valoare,@denvaloare,'')
		end
	else
	begin
		if exists (select 1 from proprietati where tip='NOMENCL' and cod=@cod and Cod_proprietate=@codprop)
			update proprietati set Valoare=@valoare where tip='NOMENCL' and cod=@cod and Cod_proprietate=@codprop
		else
				insert into proprietati values('NOMENCL',@cod,@codprop,@valoare,'')
				
		if not exists (select 1 from valproprietati v where v.Cod_proprietate=@codprop and v.Valoare=@valoare)
			insert into valproprietati(cod_proprietate,valoare,descriere,valoare_proprietate_parinte) values (@codprop,@valoare,@denvaloare,'')
	end
	
end try
begin catch
	declare @mesaj varchar(254)
	set @mesaj = ERROR_MESSAGE()
	raiserror(@mesaj, 11, 1)
end catch


GO

