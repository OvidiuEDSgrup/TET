
CREATE procedure wmComandaAgent @sesiune varchar(50), @parXML xml  
as  
if exists(select * from sysobjects where name='wmComandaAgentSP' and type='P')
begin
	exec wmComandaAgentSP @sesiune, @parXML output
	if @parXML is null
		return 0
end

set transaction isolation level READ UNCOMMITTED  
declare @utilizator varchar(100),@subunitate varchar(9), @tert varchar(30), @gestPrim varchar(100),
		@idPunctLivrare varchar(50), @comanda varchar(20), @stare varchar(50)

begin try
	exec wIaUtilizator @sesiune=@sesiune, @utilizator=@utilizator output  

	-- citire date din par
	select	@subunitate=(case when Parametru='SUBPRO' then rtrim(Val_alfanumerica) else isnull(@subunitate,'1') end)
	from par
	where (Tip_parametru='GE' and Parametru='SUBPRO')

	select	@comanda=@parXML.value('(/row/@comanda)[1]','varchar(20)'),
			@gestPrim = dbo.wfProprietateUtilizator('GESTPV', @utilizator)
	
	if isnull(@gestPrim,'')='' 
		raiserror('Utilizatorul nu are configurata o gestiune (GESTPV).', 11, 1)

	if @parXML.value('(/row/@gestprim)[1]','varchar(20)') is null  -- inserez gestiunea primitoare - e folosita cand se creaza antetul comenzii.
			set @parXML.modify ('insert attribute gestprim {sql:variable("@gestprim")} into (/row)[1]')

	if @comanda is null 
	begin		
		select top 1 @comanda=idContract
		from (
				select
					c.idContract,jc.stare, jc.utilizator, RANK() over (order by jc.data desc, jc.idJurnal desc) rn
				from Contracte c
				JOIN JurnalContracte jc on jc.idContract=c.idContract 
				where tip='CL' and gestiune_primitoare=@gestprim
			) cst where	cst.stare='0' and cst.utilizator=@utilizator and cst.rn=1
		
		if @comanda is not null 
		begin -- daca am gasit comanda, o inserez manual -> poate e in stare definitiv, si atunci wmComandaLivrare creaza alta.
			select @comanda as '@comanda' for xml path('atribute'),root('Mesaje')
			set @parXML.modify ('insert attribute comanda {sql:variable("@comanda")} into (/row)[1]')
		end
	end
	
	exec wmComandaLivrare @sesiune=@sesiune, @parXML=@parXML
end try
begin catch
	declare @eroare varchar(500)
	set @eroare=ERROR_MESSAGE()+' (wmComandaAgent)'
	raiserror(@eroare,11,1)
end catch
