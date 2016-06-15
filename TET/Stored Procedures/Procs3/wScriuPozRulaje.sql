create procedure wScriuPozRulaje @sesiune varchar(50), @parXML xml
as

begin try
	declare @rulajCredit float, @rulajDebit float, @cont varchar(40), @_search varchar(40), @tiprulaj varchar(20),
		@subunitate varchar(9), @lm varchar(20), @perioada datetime, @areAnalitice int, @o_cont varchar(40), @update int, @valuta varchar(3),
		@modImplementare int, @lunaImplementare varchar(30), @anImplementare varchar(40), @dataImplementare datetime, @dataSoldInitial datetime, 
		@mesaj varchar(500), @tipCont varchar(1), @contParinte varchar(40), @dataRulaj datetime, @o_lm varchar(30)
--
	select	@cont = ISNULL(@parXML.value('(/row/row/@cont)[1]','varchar(40)'),''),
		@o_cont = @parXML.value('(/row/row/@o_cont)[1]','varchar(40)'),
		@tiprulaj = @parXML.value('(/row/@tiprulaj)[1]','varchar(20)'),
		@rulajDebit = ISNULL(@parXML.value('(/row/row/@rulajDebit)[1]','float'),0),
		@rulajCredit = ISNULL(@parXML.value('(/row/row/@rulajCredit)[1]','float'),0),
		@_search = isnull(@parXML.value('(/row/@_cautare)[1]','varchar(40)'),''),
		@lm = ISNULL(@parXML.value('(/row/row/@lm)[1]','varchar(30)'),''),
		@o_lm = ISNULL(@parXML.value('(/row/row/@o_lm)[1]','varchar(30)'),''),
		@valuta = ISNULL(@parXML.value('(/row/row/@valuta)[1]','varchar(3)'),''),
		@perioada = ISNULL(@parXML.value('(/row/@perioada)[1]','datetime'),''),
		@subunitate=(select val_alfanumerica from par where tip_parametru='GE' and parametru='SUBPRO'),
		@update = ISNULL(@parXML.value('(/row/row/@update)[1]','int'),0)
	
	set @valuta=(case when @valuta='RON' then '' else @valuta end)
	select @tipCont=Tip_cont, @contParinte=Cont_parinte from conturi where Subunitate=@subunitate and Cont=@cont

	select	@modImplementare = (select Val_logica  from par where Tip_parametru='GE' and Parametru='IMPLEMENT'),
		@lunaImplementare = (select Val_numerica  from par where Tip_parametru='GE' and Parametru='LUNAIMPL'),
		@anImplementare = (select Val_numerica  from par where Tip_parametru='GE' and Parametru='ANULIMPL')
	set @dataImplementare=dbo.EOM(convert(datetime,str(@lunaImplementare,2)+'/01/'+str(@anImplementare,4),101))
	set @dataSoldInitial=(case when @dataImplementare=dbo.EOY(@dataImplementare) then DateADD(day,1,@dataImplementare) else dbo.BOY(@dataImplementare) end)
	set @dataRulaj = (case when @tiprulaj='Sold initial' then @dataSoldInitial else dbo.EOM(@perioada) end)
	
	if @modImplementare=0
		raiserror('Modificarile pot fi efectuate doar daca sunteti in mod implementare!!',11,1)	

	if @dataRulaj<=@dataImplementare and @lunaImplementare=12 and @tiprulaj='Rulaj'
	begin
		set @mesaj=' Nu se opereaza rulaje pe o luna ('+convert(char(7),+convert(varchar,month(@dataRulaj))+'/'+convert(varchar,year(@dataRulaj)))+')'+ 
					+' anterioara lunii implemenatarii ('+convert(char(7),+convert(varchar,@lunaImplementare)+'/'+convert(varchar,@anImplementare))+')!!'
		raiserror(@mesaj,11,1)
	end

	if @dataRulaj>@dataImplementare 
--	conditia de mai jos se refera la posibilitatea de operare sold inceput de an, daca luna implementarii este ultima luna din anul anterior
		and not(@dataRulaj=DateADD(day,1,@dataImplementare) and @lunaImplementare=12) and @tiprulaj='Rulaj'
	begin
		set @mesaj=' Data lunii ('+convert(char(7),+convert(varchar,month(@dataRulaj))+'/'+convert(varchar,year(@dataRulaj)))+')'+ 
					+' este mai mare decat data de implementare ('+convert(char(7),+convert(varchar,@lunaImplementare)+'/'+convert(varchar,@anImplementare))+')!!'
		raiserror(@mesaj,11,1)
	end

	if @tiprulaj='Sold initial' and @tipCont='A' and @rulajCredit<>0
		raiserror('La conturile de "Activ" trebuie completat sold initial debitor!',11,1)

	if @tiprulaj='Sold initial' and @tipCont='P' and @rulajDebit<>0
		raiserror('La conturile de "Pasiv" trebuie completat sold initial creditor!',11,1)

	if exists (select 1 from rulaje where Subunitate = @subunitate and cont = @cont and data  = @dataRulaj
								and loc_de_munca=@lm and Valuta=@valuta) and @update = 0 
		raiserror('Contul exista in tabela rulaje pe perioada selectata!',16,1)
			
	set @areAnalitice=(select are_analitice from conturi where cont=@cont)
	if @areAnalitice = 1 
		raiserror('Contul are analitice, modificare nepermisa!',16,1)

	if @update = 0 
		and not exists (select 1 from rulaje 
			where Subunitate = @subunitate and cont = @cont and data = @dataRulaj and Loc_de_munca=@lm and Valuta=@valuta)
	begin
		insert into rulaje (Subunitate,Cont,Loc_de_munca,Valuta,Data,Rulaj_debit,Rulaj_credit,Indbug)
		values (@subunitate, @cont, @lm, @valuta, @dataRulaj, @rulajDebit, @rulajCredit, '')
	end
	else 
	begin
		update rulaje set Rulaj_credit=@rulajCredit, Rulaj_debit=@rulajDebit ,Loc_de_munca=@lm
		where Subunitate=@subunitate and cont=@o_cont and data=@dataRulaj and Loc_de_munca=@o_lm and Valuta=@valuta
	end

--	chem refacere rulaje cont parinte
	declare @dataJosRefac datetime, @dataSusRefac datetime, @contParinteRefac varchar(40)
	if @contParinte<>''
		set @contParinteRefac=isnull((select top 1 Cont from Conturi where Subunitate=@subunitate and rtrim(@cont) like rtrim(cont)+'%' and Nivel=1 order by Cont),'')
	if @contParinteRefac<>''
	Begin	
		set @dataJosRefac=(case when @tiprulaj='Sold initial' then @dataSoldInitial else dbo.EOM(@dataSoldInitial) end)
		set @dataSusRefac=(case when @tiprulaj='Sold initial' then @dataSoldInitial else @dataImplementare end)
		exec RefacereRulajeParinte @dataJosRefac, @dataSusRefac, @contParinteRefac, 1, 1, '', 1
	End
	
	declare @wIaPozRulaje xml
	set @wIaPozRulaje = '<row perioada="' + convert(char(10),@dataRulaj,101) +'" _cautare="' + RTRIM(@_search) +'"/>' 
	exec wIaPozRulaje @sesiune=@sesiune, @parXML=@wIaPozRulaje
end try
begin catch
	declare @error varchar(500)
	set @error='(wScriuPozRulaje):'+ERROR_MESSAGE()
	raiserror(@error,16,1)
end catch
