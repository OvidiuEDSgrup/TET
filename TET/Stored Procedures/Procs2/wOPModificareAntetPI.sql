
create procedure wOPModificareAntetPI @sesiune varchar(50), @parXML xml
as
if exists (select 1 from sysobjects where [type]='P' and [name]='wOPModificareAntetPISP')
begin 
	declare @returnValue int -- variabila salveaza return value de la procedura specifica
	exec @returnValue = wOPModificareAntetPISP @sesiune, @parXML
	return @returnValue
end

begin try
	declare 
		@data datetime, @tip varchar(2),@cont varchar(40),@sub varchar(9), @utilizator varchar(20), @o_data datetime, @o_cont varchar(40),
		@DecGrCont int, @decont varchar(500), @o_decont varchar(500), @lista_lm bit

	
	EXEC wIaUtilizator @sesiune=@sesiune, @utilizator=@utilizator OUTPUT
	select 
		@lista_lm=dbo.f_arelmfiltru(@utilizator)

	select 
		@data=@parXML.value('(/parametri/@data)[1]','datetime'),
		@o_data=@parXML.value('(/parametri/@o_data)[1]','datetime'),
		@cont=@parXML.value('(/parametri/@cont)[1]','varchar(40)'),
		@o_cont=@parXML.value('(/parametri/@o_cont)[1]','varchar(40)'),
		@decont=@parXML.value('(/parametri/@decont)[1]','varchar(50)'),
		@o_decont=@parXML.value('(/parametri/@o_decont)[1]','varchar(50)'),
		@tip=@parXML.value('(/parametri/@tip)[1]','varchar(2)')		

	exec luare_date_par 'GE','SUBPRO',0,0,@sub output
	exec luare_date_par 'GE', 'DECMARCT', @DecGrCont output, 0, ''
	
	-- la luare date, @decont se citeste din pozplin.cont cand este setarea @DecGrCont
	if @tip<>'DE' or isnull(@decont,'')<>isnull(@o_decont,'') and @DecGrCont=1
		set @decont=@o_decont
		
	if @parXML.value('(/parametri/row/@numar)[1]','varchar(10)') is not null
		raiserror('Operatie specifica datelor de antet, trebuie sa iesiti din pozitii!',11,1)
	
	/*	Update pe pozplin, plinul se modifica singur prin trigger
		Update-ul se face in conditiile filtrarii pe LM pt. ca un utilizator restrictionat sa nu modifice decat ceea ce "vede"
	*/
	update p set 
		cont=(case when @cont<> @o_cont and @o_cont=p.Cont then @cont else p.Cont end), 
		data =(case when @data<> @o_data and @o_data=p.data then @data else p.data end),
		decont = (case when @decont<>@o_decont then @decont else p.decont end)
	FROM pozplin p 
	where p.Subunitate=@sub
		and p.cont=@o_cont
		and p.data=@o_data
		and (@lista_lm=0 or exists (select * from LMFiltrare lu where lu.utilizator=@utilizator and lu.cod=p.Loc_de_munca ))
	
	if exists (select 1 from DocDeContat where Subunitate=@sub and Tip='PI' and Numar=@o_cont and Data=@o_data)
		exec faInregistrariContabile @dinTabela=0, @Subunitate=@sub,@Tip='PI',@Numar=@o_cont, @Data=@o_data

	if exists (select 1 from DocDeContat where Subunitate=@sub and Tip='PI' and Numar=@cont and Data=@data)
		exec faInregistrariContabile @dinTabela=0, @Subunitate=@sub,@Tip='PI',@Numar=@cont, @Data=@data

end try 
begin catch
	declare @error varchar(500)
	set @error='(wOPModificareAntetPI): '+ERROR_MESSAGE()
	raiserror(@error,16,1)
end catch
