create procedure wScriuPozInventarSerii @sesiune varchar(50), @parXML xml
as
begin try
	declare @cod varchar(50), @serie varchar(20), @update int, @stocfaptic float, @sub int, @datainv datetime, @gest varchar(20),@areserii int,
		@data_operarii datetime, @ora_operarii char(6), @utilizator varchar(20), @stoccalculat float

	select @cod=ISNULL(@parXML.value('(/row/@cod)[1]', 'varchar(20)'), ''),
		@serie=ISNULL(@parXML.value('(/row/@serie)[1]', 'varchar(20)'), ''),
		@datainv=ISNULL(@parXML.value('(/row/@datainv)[1]', 'datetime'), ''),
		@gest=ISNULL(@parXML.value('(/row/@gest)[1]', 'varchar(20)'), ''),
		@update=ISNULL(@parXML.value('(/row/@update)[1]', 'int'), 0)
	set @data_operarii=convert(datetime, convert(char(10), getdate(), 104), 104)
	set @ora_operarii=RTrim(replace(convert(char(8), getdate(), 108), ':', ''))
	exec wIaUtilizator @sesiune=@sesiune, @utilizator=@utilizator output

	if (@serie='' and (select UM_2  from nomencl where cod=@cod)='Y' and @update=0)
		raiserror('wScriuPozInventarSerii:Codul introdus este setat pentru lucrul cu serii, introduceti va rog o serie corespunzatoare!',16,1)

	if @update=1
		update invserii set stoc_faptic=@stocfaptic, serie=@serie 
		where subunitate=@sub and data_inventarului=@datainv and gestiunea=@gest and cod_produs=@cod and serie=@serie
	else 
	begin
		set @stoccalculat=(select stoc_ce_se_calculeaza from stocuri where cod_gestiune=@gest and cod=@cod)
		insert into inventar (Subunitate, Data_inventarului, Gestiunea, Cod_de_bara, Cod_produs, Pret, Stoc_faptic, Utilizator, Data_operarii, Ora_operarii)
			values('1',@datainv,@gest,@stoccalculat,@cod,'',@stocfaptic,@utilizator,@data_operarii,@ora_operarii)
		insert into invserii (Subunitate, Data_inventarului, Gestiunea, Cod_de_bara, Cod_produs, Serie, Stoc_faptic)
			values('1',@datainv,@gest,'',@cod,@serie,@stocfaptic)
	end 
	declare @docXMLIaPozInventarSerii xml  
	set @docXMLIaPozInventarSerii = '<row gest="' + rtrim(@gest) + '" datainv="' + rtrim(@datainv) + '"/>'  
	select @docXMLIaPozInventarSerii
	exec wIaPozInventarSerii @sesiune=@sesiune, @parXML=@docXMLIaPozInventarSerii
end try
begin catch
	declare @eroare varchar(500)
	set @eroare=ERROR_MESSAGE()
	raiserror(@eroare, 16, 1) 
end catch  
--select * from inventar where gestiunea='kapas' and data_inventarului='2011-06-20'
--select * from invserii where gestiunea='kapas' and data_inventarului='2011-06-20' and stoc_faptic>0
