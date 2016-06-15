create procedure wStergPozRulaje @sesiune varchar(50), @parXML xml
as

declare @perioada datetime, @cont varchar(40), @rulajCredit float, @rulajDebit float, @areAnalitice int, @contParinte varchar(40), 
		@subunitate varchar(9), @lm varchar(20), @valuta varchar(10), @areLM int, @_search varchar(40), @utilizator varchar(20)
		
exec wIaUtilizator @sesiune=@sesiune, @utilizator=@utilizator output
select	@perioada = ISNULL(@parXML.value('(/row/@perioada)[1]','datetime'),'1900-01-01'),
		@lm = ISNULL(@parXML.value('(/row/@lm)[1]','varchar(30)'),''),
		@_search = isnull(@parXML.value('(/row/@_cautare)[1]','varchar(40)'),''),
		@subunitate = ISNULL(@parXML.value('(/row/@subunitate)[1]','varchar(9)'),0),
		@cont = ISNULL(@parXML.value('(/row/row/@cont)[1]','varchar(40)'),''),
		@rulajDebit = ISNULL(@parXML.value('(/row/row/@rulajDebit)[1]','float'),0),
		@rulajCredit = ISNULL(@parXML.value('(/row/row/@rulajCredit)[1]','float'),0),
		@areAnalitice = ISNULL(@parXML.value('(/row/row/@areAnalitice)[1]','int'),0),
		@valuta = ISNULL(@parXML.value('(/row/row/@valuta)[1]','varchar(30)'),''),
		@areLM = dbo.f_arelmfiltru(@utilizator)
				
begin try
	if @areAnalitice=1 and (@rulajDebit<>0 or @rulajCredit<>0)	-- am permis stergerea daca contul nu are rulaje. 
		raiserror('Contul are analitice, stergere nepermisa!',16,1)
	select @contParinte=Cont_parinte from conturi where Subunitate=@subunitate and Cont=@cont

	delete r from rulaje r 
		left outer join lmfiltrare l on l.utilizator=@utilizator and l.cod=r.loc_de_munca
	where r.subunitate = @subunitate 
		and (@areLM=0 or l.cod is not null) 
		and r.data=@perioada and cont=@cont 
		and r.valuta=(case when @valuta='RON' then '' else @valuta end)

--	chem refacere rulaje cont parinte
	declare @contParinteRefac varchar(40)
	if @contParinte<>''
		set @contParinteRefac=isnull((select top 1 Cont from Conturi where Subunitate=@subunitate and rtrim(@cont) like rtrim(Cont)+'%' and Nivel=1 order by Cont),'')
	if @contParinteRefac<>''
		exec RefacereRulajeParinte @perioada, @perioada, @contParinteRefac, 1, 1, '', 1

	declare @wIaPozRulaje xml
	set @wIaPozRulaje = '<row perioada="' + convert(char(10),@perioada,101) +'" _cautare="' + RTRIM(@_search) +'"/>' 
	exec wIaPozRulaje @sesiune=@sesiune, @parXML=@wIaPozRulaje
end try
begin catch
	declare @error varchar(500)
	set @error='(wStergPozRulaje):'+ERROR_MESSAGE()
	raiserror(@error,16,1)
end catch


