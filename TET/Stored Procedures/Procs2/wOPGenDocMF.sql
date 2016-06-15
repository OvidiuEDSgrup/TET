--***
Create procedure wOPGenDocMF @sesiune varchar(50), @parXML xml
as

declare /*@doccuIC int, */@lunainch int, @anulinch int, @datainch datetime, 
	@stergdoc int, @gendoc int, @trvalneamlaamlun int, @tip char(3), @numar char(8), @data datetime, 
	@datasfconserv datetime, @categmf int, @lm varchar(9), @denlm varchar(30), 
	@nrinv varchar(13), @denmf varchar(80), @valinv float,
	@userASiS varchar(20), @nrLMFiltru int, @LMFiltru varchar(9), @procinch float

exec wJurnalizareOperatie @sesiune=@sesiune, @parXML=@parXML, @obiectSql='wOPGenDocMF'
--EXEC luare_date_par 'MF','INCONM', @doccuIC output, 0, ''
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
SET @gendoc = ISNULL(@parXML.value('(/parametri/@gendoc)[1]', 'int'), 0)
SET @trvalneamlaamlun = ISNULL(@parXML.value('(/parametri/@trvalneamlaamlun)[1]', 'int'), 0)
SET @tip = ISNULL(@parXML.value('(/parametri/@tip)[1]', 'char(3)'), 'CON')
SET @numar = ISNULL(@parXML.value('(/parametri/@numar)[1]', 'char(8)'), '')
set @data = ISNULL(@parXML.value('(/parametri/@data)[1]', 'datetime'), '01/01/1901')
SET @datasfconserv = ISNULL(@parXML.value('(/parametri/@datasfconserv)[1]', 'datetime'), '01/01/1901')
IF @tip<>'CON' SET @datasfconserv='01/01/1902'
Set @categmf = ISNULL(@parXML.value('(/parametri/@categmf)[1]', 'int'), 0)
set @nrinv = ISNULL(@parXML.value('(/parametri/@nrinv)[1]', 'varchar(13)'), '')
select @denmf=isnull(Denumire,'') from mfix where Numar_de_inventar=@nrinv
set @valinv = ISNULL(@parXML.value('(/parametri/@valinv)[1]', 'float'), 0)
if @valinv=0 set @valinv=isnull((select max(val_numerica) from par where tip_parametru='MF' and 
	parametru='VALOBINV'), 0)
if @valinv=0 set @valinv=1800
exec wIaUtilizator @sesiune=@sesiune, @utilizator=@userASiS output
select @nrLMFiltru=count(1), @LMFiltru=isnull(max(Cod),'') from LMfiltrare where utilizator=@userASiS
set @lm = ISNULL(@parXML.value('(/parametri/@lm)[1]', 'varchar(9)'), '')
set @lm=(case when dbo.f_areLMFiltru(@userASiS)=1 and @nrLMFiltru=1 then @LMFiltru else @lm end)
select @denlm=isnull(Denumire,'') from lm where cod=@lm

begin try
	if @stergdoc=0 and @gendoc=0
		raiserror('Bifati macar optiunea "Generare..."!' ,16,1)
	/*if @numar=''
		raiserror('Completati nr. doc.!' ,16,1)*/
	if @data<=@datainch
		raiserror('Data doc. este intr-o luna inchisa / blocata in CG!' ,16,1)
	if @tip='MRE' and @data<>dbo.eom(@data)
		raiserror('Data doc. trebuie sa fie data ultimei zile din luna!' ,16,1)
	if @tip='CON' and @datasfconserv<=@data
		raiserror('Data sfarsit conservare <= data doc.!' ,16,1)
	/*if @tip in ('MMF','MTO') and @valinv<=0
		raiserror('Completati o valoare de inventar pozitiva!' ,16,1)*/
	if @nrinv<>'' and not exists (select 1 from MFix where Numar_de_inventar=@nrinv)
		raiserror('Mijloc fix inexistent!' ,16,1)
	if dbo.f_areLMFiltru(@userASiS)=1 and @nrLMFiltru>1 and @lm=''
		raiserror('Alegeti un loc de munca!' ,16,1)
	if dbo.f_areLMFiltru(@userASiS)=1 and @nrLMFiltru>1 and @lm<>'' and not exists (select 1 from 
		LMfiltrare where utilizator=@userASiS and cod=@lm)
		raiserror('Locul de munca ales nu se regaseste in lista de locuri de munca pe care aveti acces!' ,16,1)

	set @procinch=(case --when @tip='CON' then 100 when @doccuIC=0 or @tip='MTP' then 9 
		when @trvalneamlaamlun=1 then 3 else 6 end)
	exec MFgendoc @tip=@tip, @numar=@numar, @data=@data, @nrinvfiltru=@nrinv, @categmffiltru=@categmf, 
		@lmfiltru=@lm, @datasfconserv=@datasfconserv, @stergdoc=@stergdoc, @gendoc=@gendoc, 
		@valinvfiltru=@valinv, @tippatrimfiltru=null/*sa ramana null, caci tip patrim. nu e tratat la 
		sterg. in MFgendoc, fiindca e fol. doar la gen. reev., care se face fara sterg.*/, 
		@procinch=@procinch/*, @contcor='', 
		@contgestprim='', @contcheltajust='', @contvenajust='', @reevfaradifam=0, @reevfaraajust=0*/

	select 'Terminat operatie '+/*rtrim(@lunaalfa)+' '+convert(char(4),year(@datas))+
	(case when @nrinv<>'' then ', pt. mijlocul fix '+rtrim(@denmf) else '' end)+
	(case when @categmf<>0 then ', pt. categoria '+ltrim(str(@categmf,2)) else '' end)+
	(case when @lm<>'' then ', pt. locul de munca '+rtrim(@denlm) else '' end)+*/'!' as textMesaj, 
	'Finalizare operatie' as titluMesaj for xml raw, root('Mesaje')
	--COMMIT TRAN
end try  

begin catch  
	--ROLLBACK TRAN
	declare @eroare varchar(254) 
	set @eroare=ERROR_MESSAGE()
	raiserror(@eroare, 16, 1) 
end catch
