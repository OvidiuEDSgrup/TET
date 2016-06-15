--***
create procedure wStergPozDevizLucru @sesiune varchar(50), @parXML xml
as

declare @mesajeroare varchar(100), @iDoc int, @eroare xml, @nrdeviz varchar(20), @pozitiearticol float, 
	@cantitate float, @pretvanzare float, @discount float, @cotaTVA float, @tipresursa varchar(1), 
	@promotie char(13), @starepozitie varchar(1)

Set @nrdeviz = @parXML.value('(/row/@nrdeviz)[1]','varchar(20)')
Set @pozitiearticol = @parXML.value('(/row/row/@pozitiearticol)[1]','float')
Set @cantitate = @parXML.value('(/row/row/@cantitate)[1]','float')
Set @pretvanzare = @parXML.value('(/row/row/@pretvanzare)[1]','float')
Set @discount = @parXML.value('(/row/row/@discount)[1]','float')
Set @cotaTVA = @parXML.value('(/row/row/@cotaTVA)[1]','float')
Set @tipresursa = @parXML.value('(/row/row/@tipresursa)[1]','varchar(20)')
Set @promotie = @parXML.value('(/row/row/@promotie)[1]','varchar(20)')
Set @starepozitie = @parXML.value('(/row/row/@starepozitie)[1]','varchar(20)')

begin try
	exec sp_xml_preparedocument @iDoc output, @parXML
	--select @starepozitie, @tipresursa, @promotie
	select @mesajeroare=(case when @starepozitie<=(case when @tipresursa not in ('R','S','A') then '1' 
		else '2' end) and @promotie='' then '' 
		else 'Nu se pot sterge pozitiile cu promotie completata sau cu stare '+@starepozitie+'!' end)

	if @mesajeroare<>'' 	
		raiserror(@mesajeroare, 11, 1)
	else
	begin
	update devauto set Valoare_deviz=Valoare_deviz-isnull(convert(decimal(17,2),round(@cantitate*
		@pretvanzare*(1.00-@discount/100)*(1.00+@cotaTVA/100),3)),0) 
		where Cod_deviz=@nrdeviz
	
	delete pozdevauto
	from pozdevauto p
	where Cod_deviz=@nrdeviz and Pozitie_articol=@pozitiearticol
	end
	
	if (select count(1) from pozdevauto where Cod_deviz = @nrdeviz) = 0
	begin
		update devauto
		set Stare = '0'
		where Cod_deviz = @nrdeviz
	end

	if exists (select 1 from Programator where Deviz = @nrdeviz)
	begin
		update Programator
		set Deviz = ''
		where Deviz = @nrdeviz
	end

	exec sp_xml_removedocument @iDoc

	exec wIaPozDevizLucru @sesiune=@sesiune, @parXML=@parXML

end try
 
begin catch
	declare @mesaj varchar(255)
	if isnull(@eroare.value('(/error/@coderoare)[1]', 'int'), 0) = 0
		set @mesaj=ERROR_MESSAGE()
	raiserror(@mesaj, 11, 1)
end catch
