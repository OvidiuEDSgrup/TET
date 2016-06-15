--***
Create procedure wOPGenReevMF @sesiune varchar(50), @parXML xml
as

declare @doccuIC int, @lunainch int, @anulinch int, @datainch datetime, 
	@stergdoc int, @gendoc int, @tip char(3), @numar char(8), @data datetime, @datasfconserv datetime, 
	@contcor varchar(40), @contgestprim varchar(40), @contcheltajust varchar(40), @contvenajust varchar(40), 
	@reevfaradifam int, @reevfaraajust int, @tippatrim char(1), 
	@categmf int, @lm varchar(9), @denlm varchar(30), @nrinv varchar(13), @denmf varchar(80), 
	@dencontcor varchar(80), @dencontgestprim varchar(80), 
	@dencontcheltajust varchar(80), @dencontvenajust varchar(80), 
	@userASiS varchar(20), @nrLMFiltru int, @LMFiltru varchar(9), @procinch float

exec wJurnalizareOperatie @sesiune=@sesiune, @parXML=@parXML, @obiectSql='wOPGenReevMF'
exec luare_date_par 'MF','INCONM', @doccuIC output, 0, ''
set @lunainch=isnull((select max(val_numerica) from par where tip_parametru='GE' and 
	parametru='LUNABLOC'), isnull((select max(val_numerica) from par where tip_parametru='GE' and 
	parametru='LUNAINC'), 1))
set @anulinch=isnull((select max(val_numerica) from par where tip_parametru='GE' and 
	parametru='ANULBLOC'), isnull((select max(val_numerica) from par where tip_parametru='GE' and 
	parametru='ANULINC'), 1901))
if @lunainch not between 1 and 12 or @anulinch<=1901 
	set @datainch='01/31/1901'
else 
	set @datainch=dbo.eom(convert(datetime,str(@lunainch,2)+'/01/'+str(@anulinch,4)))
SET @stergdoc = ISNULL(@parXML.value('(/parametri/@stergdoc)[1]', 'int'), 0)
SET @stergdoc = 0 --l-am facut 0, fiindca nu e tratat @tippatrimfiltru la stergerea din proc. MFgendoc
SET @gendoc = ISNULL(@parXML.value('(/parametri/@gendoc)[1]', 'int'), 0)
SET @gendoc=1
SET @reevfaradifam = ISNULL(@parXML.value('(/parametri/@reevfaradifam)[1]', 'int'), 0)
SET @reevfaraajust = ISNULL(@parXML.value('(/parametri/@reevfaraajust)[1]', 'int'), 0)
SET @tip = ISNULL(@parXML.value('(/parametri/@tip)[1]', 'char(3)'), 'MRE')
SET @numar = ISNULL(@parXML.value('(/parametri/@numar)[1]', 'char(8)'), '')
set @data = ISNULL(@parXML.value('(/parametri/@data)[1]', 'datetime'), '01/01/1901')
SET @datasfconserv = ISNULL(@parXML.value('(/parametri/@datasfconserv)[1]', 'datetime'), '01/01/1901')
IF @tip<>'CON' SET @datasfconserv='01/01/1902'
set @contcor = ISNULL(@parXML.value('(/parametri/@contcor)[1]', 'varchar(40)'), '')
select @dencontcor=isnull(Denumire_cont,'') from conturi where cont=@contcor
set @contgestprim = ISNULL(@parXML.value('(/parametri/@contgestprim)[1]', 'varchar(40)'), '')
select @dencontgestprim=isnull(Denumire_cont,'') from conturi where cont=@contgestprim
set @contcheltajust = ISNULL(@parXML.value('(/parametri/@contcheltajust)[1]', 'varchar(40)'), '')
select @dencontcheltajust=isnull(Denumire_cont,'') from conturi where cont=@contcheltajust
set @contvenajust = ISNULL(@parXML.value('(/parametri/@contvenajust)[1]', 'varchar(40)'), '')
select @dencontvenajust=isnull(Denumire_cont,'') from conturi where cont=@contvenajust
set @tippatrim = ISNULL(@parXML.value('(/parametri/@tippatrim)[1]', 'char(20)'), '0')
if @tippatrim='0' set @tippatrim=null
Set @categmf = ISNULL(@parXML.value('(/parametri/@categmf)[1]', 'int'), 0)
set @nrinv = ISNULL(@parXML.value('(/parametri/@nrinv)[1]', 'varchar(13)'), '')
select @denmf=isnull(Denumire,'') from mfix where Numar_de_inventar=@nrinv
exec wIaUtilizator @sesiune=@sesiune, @utilizator=@userASiS output
select @nrLMFiltru=count(1), @LMFiltru=isnull(max(Cod),'') from LMfiltrare where utilizator=@userASiS
set @lm = ISNULL(@parXML.value('(/parametri/@lm)[1]', 'varchar(9)'), '')
set @lm=(case when dbo.f_areLMFiltru(@userASiS)=1 and @nrLMFiltru=1 then @LMFiltru else @lm end)
select @denlm=isnull(Denumire,'') from lm where cod=@lm

begin try
	if @stergdoc=0 and @gendoc=0
		raiserror('Bifati macar optiunea "Generare reevaluari"!' ,16,1)
	/*if @numar=''
		raiserror('Completati nr. doc.!' ,16,1)*/
	if @data<=@datainch
		raiserror('Data doc. este intr-o luna inchisa / blocata in CG!' ,16,1)
	if @tip='MRE' and @data<>dbo.eom(@data)
		raiserror('Data doc. trebuie sa fie data ultimei zile din luna!' ,16,1)
	if not exists (select 1 from conturi where cont=@contcor and Are_analitice=0)
		raiserror('Cont rezerve din reevaluare inexistent sau cu analitice!' ,16,1)
	if not exists (select 1 from conturi where cont=@contgestprim and Are_analitice=0)
		raiserror('Cont fond bunuri inexistent sau cu analitice!' ,16,1)
	if not exists (select 1 from conturi where cont=@contcheltajust and Are_analitice=0)
		raiserror('Cont chelt. din ajustari inexistent sau cu analitice!' ,16,1)
	if not exists (select 1 from conturi where cont=@contvenajust and Are_analitice=0)
		raiserror('Cont venituri din ajustari inexistent sau cu analitice!' ,16,1)
	if @nrinv<>'' and not exists (select 1 from MFix where Numar_de_inventar=@nrinv)
		raiserror('Mijloc fix inexistent!' ,16,1)
	if dbo.f_areLMFiltru(@userASiS)=1 and @nrLMFiltru>1 and @lm=''
		raiserror('Alegeti un loc de munca!' ,16,1)
	if dbo.f_areLMFiltru(@userASiS)=1 and @nrLMFiltru>1 and @lm<>'' and not exists (select 1 from 
		LMfiltrare where utilizator=@userASiS and cod=@lm)
		raiserror('Locul de munca ales nu se regaseste in lista de locuri de munca pe care aveti acces!' ,16,1)

	set @procinch=(case when @doccuIC=0 then 9 else 6 end)
	exec MFgendoc @tip=@tip, @numar=@numar, @data=@data, @nrinvfiltru=@nrinv, @categmffiltru=@categmf, 
		@lmfiltru=@lm, @datasfconserv=@datasfconserv, @stergdoc=@stergdoc, @gendoc=@gendoc, 
		@valinvfiltru=0, @tippatrimfiltru=@tippatrim, @procinch=@procinch, @contcor=@contcor, 
		@contgestprim=@contgestprim, @contcheltajust=@contcheltajust, @contvenajust=@contvenajust, 
		@reevfaradifam=@reevfaradifam, @reevfaraajust=@reevfaraajust 

	select 'Terminat operatie '+/*rtrim(@lunaalfa)+' '+convert(char(4),year(@datas))+
	(case when @nrinv<>'' then ', pt. mijlocul fix '+rtrim(@denmf) else '' end)+
	(case when @categmf<>0 then ', pt. categoria '+ltrim(str(@categmf,2)) else '' end)+
	(case when @lm<>'' then ', pt. locul de munca '+rtrim(@denlm) else '' end)+*/'!' as textMesaj, 
	'Finalizare operatie' as titluMesaj for xml raw, root('Mesaje')
end try  

begin catch  
	declare @eroare varchar(254) 
	set @eroare=ERROR_MESSAGE()
	raiserror(@eroare, 16, 1) 
end catch
