--***
Create procedure genRevisal
	@dataJos datetime, 
	@dataSus datetime, 
	@DataRegistru datetime, -- data la care se doreste generarea registrului
	@oMarca int, @cMarca char(6), 	
	@unLm int, @Lm char(9), @Strict int, 
	@SirMarci varchar(1000),
	@fltDataAngPl int, @DataAngPlJ datetime, @DataAngPlS datetime, 
	@fltDataModif int, @DataModifJ datetime, @DataModifS datetime, 
	@oSub int, @cSub char(9), 
	@TipSocietate varchar(50), -- Tip societate (SediuSocial, Filiala, Sucursala)
	@ReprLegal varchar(100), -- reprezentant legal
	@cDirector varchar(254), -- cale generare fisier XML
	@inXML int=0,
	@genRaport int=0,	-- daca procedura este apelata dinspre raportul web
	@grupare int=1,
	@staresalariati int=0, -- 0 ->Toti salariatii, 1->Salariati activi, 2->Salariati suspendati 3->Salariati cu contract incetat
	@activitate varchar(20)=null	--> cod activitate din tabela personal
as  
Begin
	declare @HostID char(10), @utilizator varchar(20), @multiFirma int, @lmUtilizator varchar(9), @denlmUtilizator varchar(9), @ziua int, @Luna int, @An int, @LunaAlfa varchar(15), 
	@XmlRezultat xml (ASchemaRevisal), @XmlRezultatA xml , @XmlSalariati xml, 
	@numeFisier varchar(max), @cFisier varchar(254), @raspunsCmd int, @msgeroare varchar(1000),
	@vCui varchar(13), @Cui varchar(13), @CuiAng varchar(13), @CuiParinte varchar(13), @rgCom varchar(14), @caen varchar(4), @VersiuneCAEN char(1), 
	@den varchar(200), @denParinte varchar(200), @AdresaAng varchar(1000), @CodSirutaAng varchar(10), @telefon varchar(15), @fax varchar(15), @email varchar(200), @xml xml,
	@CategorieAngajator varchar(100), @ActIdentitatePF varchar(100), @NationalitatePF varchar(100), @cFormaJ varchar(100), @cFormaOrg varchar(100), @cFormaPropr varchar(100), 
	@dataJosAnt datetime, @dataSusAnt datetime, @dataJosNext datetime, @dataSusNext datetime, 
	@nLunaInch int, @LunaInchAlfa char(15), @nAnulInch int, @dDataInch datetime, @ModifDateSalAmanate int, @NrZileAmanare int, @VersiuneCOR char(1)

	set transaction isolation level read uncommitted
	if @oMarca=0 set @cMarca=''
	set @utilizator = dbo.fIaUtilizator(null)
	set @multiFirma=0
	if exists (select * from sysobjects where name ='par' and xtype='V')
		set @multiFirma=1
	if @multiFirma=1 
	begin
		select @lmUtilizator=isnull(min(Cod),'') from LMfiltrare where utilizator=@utilizator and cod in (select cod from lm where Nivel=1)
		select @denlmUtilizator=isnull(min(Denumire),'') from lm where cod=@lmUtilizator
	end

	Set @HostID=isnull((select convert(char(8),abs(convert(int,host_id())))),'')
	set @nLunaInch=isnull((select max(val_numerica) from par where tip_parametru='PS' and parametru='LUNA-INCH'), 1)
	set @nAnulInch=isnull((select max(val_numerica) from par where tip_parametru='PS' and parametru='ANUL-INCH'), 1901)
	set @dDataInch=dbo.eom(convert(datetime,str(@nLunaInch,2)+'/01/'+str(@nAnulInch,4)))
	set @dataJosAnt=dbo.bom(DateAdd(day,-1,@dataJos))
	set @dataSusAnt=DateAdd(day,-1,@dataJos)
	set @dataJosNext=DateAdd(day,1,@dataSus)
	set @dataSusNext=dbo.eom(DateAdd(day,1,@dataSus))
	set @ModifDateSalAmanate=dbo.iauParL('PS','GREVMDSAM')
	set @NrZileAmanare=dbo.iauParN('PS','GREVMDSAM')
	set @VersiuneCOR='6'

--	apelez scrierea in istoric pesonal (din istpers se iau datele pt. procedurile genRevisalContracte si genRevisalSalariati)
	if isnull((select type from sysobjects where name='istPers'),'')='U'
	Begin
		if @dataJosAnt>@dDataInch
			exec scriuistPers @dataJosAnt, @dataSusAnt, @cMarca, '', 1, 1, @ModifDateSalAmanate, @NrZileAmanare, @DataRegistru
		if @dataJos>@dDataInch
			exec scriuistPers @dataJos, @dataSus, @cMarca, '', 1, 1, @ModifDateSalAmanate, @NrZileAmanare, @DataRegistru
		if @dataJosNext>@dDataInch and exists (select Marca from personal where Data_angajarii_in_unitate>@dataSus)
			exec scriuistPers @dataJosNext, @dataSusNext, @cMarca, '', 1, 1, @ModifDateSalAmanate, @NrZileAmanare, @DataRegistru
	End		

	set @vCui=dbo.iauParA('PS','CODFISC')
	if @vCui=''
		set @vCui=dbo.iauParA('GE','CODFISC')

	select @CuiParinte=dbo.iauParA('PS','ITMCODFP'), @rgCom=dbo.iauParA('GE','ORDREG'), 
	@caen=dbo.iauParA('PS','CODCAEN'), @VersiuneCAEN='2',
	@den=dbo.iauParA('GE','NUME'), @denParinte=dbo.iauParA('PS','ITMDENPAR'), @AdresaAng=dbo.iauParA('GE','ADRESA'), @telefon=dbo.iauParA('GE','TELFAX'), 
	@fax=dbo.iauParA('GE','TELFAX'), @email=dbo.iauParA('GE','EMAIL')
	Select @Cui=ltrim(rtrim((case when left(upper(@vCui),2)='RO' then substring(@vCui,3,13)
		when left(upper(@vCui),1)='R' then substring(@vCui,2,13) else @vCui end)))
	set @CuiAng=@Cui
	select @CodSirutaAng=Cod_postal from Localitati where cod_oras=dbo.iauParA('GE','CODSIRUTA')
	if @CodSirutaAng is null
		set @CodSirutaAng=''
	set @CategorieAngajator=dbo.iauParA('GE','CATEGANG')
	set @ActIdentitatePF=dbo.iauParA('GE','ACTIDPF')
	set @NationalitatePF=dbo.iauParA('GE','NATIONPF')
	set @cFormaJ=dbo.iauParA('GE','FJURIDICA')
	set @cFormaOrg=dbo.iauParA('GE','FORGANIZ')
	set @cFormaPropr=dbo.iauParA('GE','FPROPRIET')
	select @luna=month(@dataSus), @An=year(@dataSus), @ziua=day(@DataRegistru)
--	citesc datele pt. sucursala/filiala definite ca si proprietate pe locul de munca de nivel superior
	if @unLm=1 and @TipSocietate in ('Filiala','Sucursala')
	Begin
		select @Cui=(case when parametru='CODFISCAL' then rtrim(val_alfanumerica) else @Cui end),
		@AdresaAng=(case when parametru like 'ADRESA%' then val_alfanumerica else @AdresaAng end),
		@email=(case when parametru='EMAIL' then val_alfanumerica else @email end),
		@telefon=(case when parametru='TELFAX' then val_alfanumerica else @telefon end),
		@fax=(case when parametru='TELFAX' then val_alfanumerica else @fax end),
		@TipSocietate=(case when parametru='TIPSOCIETATE' then val_alfanumerica else @TipSocietate end),
		@CodSirutaAng=(case when parametru='CODSIRUTA' then val_alfanumerica else @CodSirutaAng end),
		@CuiParinte=(case when parametru='CODFISCAL' and @CuiParinte='' then @CuiAng else @CuiParinte end)
		from fParRepUtiliz() where id=100

		select @den=(case when parametru='NUME' then val_alfanumerica else @den end),
		@denParinte=(case when parametru='NUME' and @denParinte='' then dbo.iauParA('GE','NUME') else @denParinte end)
		from fParRepUtiliz() where id=1 and parametru='NUME'
	End

	if exists (select 1 from sysobjects where [type]='P' and [name]='genRevisalSP')
		exec genRevisalSP @dataJos, @dataSus

--	creez tabela temporara ##extinfop in care pun datele din extinfop cu codurile de informatie necesare pt. generarea registrului
	if OBJECT_ID('tempdb..#extinfop') is null
	Begin
		Create table #extinfop (Marca char(6) not null) 
		Exec CreeazaDiezRevisal @numeTabela='#extinfop'
		--Exec CreeazaDiezRevisal @numeTabela='#extinfop', @data=@DataRegistru, @Marca=@cMarca

		insert into #Extinfop (Marca, Cod_inf, Val_inf, Data_inf, Procent)
		select e.Marca, e.Cod_inf, e.Val_inf, e.Data_inf, e.Procent
		from extinfop e
		where (e.Cod_inf='#CODCOR' or (isnull(@cMarca,'')='' or e.Marca=@cMarca) 
				/*and exists (select i.Marca from istPers i left outer join personal p on p.Marca=i.Marca where i.Marca=e.Marca and (Data=@dataSus or Data=@dataSusNext 
				or convert(char(1),p.loc_ramas_vacant)='1' and i.Data<@dataJos and i.Data>'08/01/2011' 
				and MONTH(i.Data)=MONTH(p.Data_plec) and year(i.Data)=year(p.Data_plec)) and i.Grupa_de_munca not in ('O','P','')) */
			and (cod_inf in ('PASAPORT','RTIPACTIDENT','RCETATENIE','RCODNATIONAL','MENTIUNI','CODSIRUTA','MMODIFCNTR',
			'RTEMEIINCET','TXTTEMEIINCET','CONTRDET','DATAINCH','DATASFCONDET','EXCEPDATASF','TIPINTREPTM','REPTIMPMUNCA',
			'MMODIFCNTR','SCDATAINC','SCDATASF','SCDATAINCET','DETDATAINC','DETNATIONAL','DETDATASF') 
			or Cod_inf in ('DATAMFCT','DATAMDCTR','CONDITIIM','SALAR','DATAMRL') and e.Data_inf<=@DataRegistru and (e.Val_inf<>'' or e.Procent<>0)))
	End	

--	creez cursor contracte pt. ca merge mai repede decat daca se apeleaza direct functia GenRevisalContracte cu filtru pt. fiecare CNP din GenRevisalSalariati
	if OBJECT_ID('tempdb..#tmpContracte') is not null drop table #tmpContracte
	if OBJECT_ID('tempdb..#tmpStareCurenta') is not null drop table #tmpStareCurenta
	if OBJECT_ID('tempdb..#tmpStarePreced') is not null drop table #tmpStarePreced

	if OBJECT_ID('tempdb..#RevisalContracte') is not null 
		drop table #RevisalContracte
	create table #RevisalContracte (NrCrt int identity (1,1))
	Exec CreeazaDiezRevisal @numeTabela='#RevisalContracte'
	exec genRevisalContracte @dataJos=@dataJos, @dataSus=@dataSus, @DataRegistru=@DataRegistru, @oMarca=@oMarca, @cMarca=@cMarca, @unLm=@unLm, @Lm=@Lm, @Strict=@Strict, @SirMarci=@SirMarci, 
		@Judet='', @fltDataAngPl=@fltDataAngPl, @DataAngPlJ=@DataAngPlJ, @DataAngPlS=@DataAngPlS, @fltDataModif=@fltDataModif, @DataModifJ=@DataModifJ, @DataModifS=@DataModifS, 
		@oSub=@oSub, @cSub=@cSub, @SiModFctCOR=0, @activitate=@activitate

	if OBJECT_ID('tempdb..#RevisalSalariati') is not null 
		drop table #RevisalSalariati
	create table #RevisalSalariati (NrCrt int identity (1,1))
	Exec CreeazaDiezRevisal @numeTabela='#RevisalSalariati'
	exec genRevisalSalariati @dataJos=@dataJos, @dataSus=@dataSus, @DataRegistru=@DataRegistru, @oMarca=@oMarca, @cMarca=@cMarca, @unLm=@unLm, @Lm=@Lm, @Strict=@Strict, @SirMarci=@SirMarci, 
		@Judet='', @fltDataAngPl=@fltDataAngPl, @DataAngPlJ=@DataAngPlJ, @DataAngPlS=@DataAngPlS, @fltDataModif=@fltDataModif, @DataModifJ=@DataModifJ, @DataModifS=@DataModifS, 
		@oSub=@oSub, @cSub=@cSub, @activitate=@activitate

if @genRaport=0
Begin
	select c.Cnp as Cnp, c.Marca as Marca, rtrim(c.CodCOR) as CodCOR, @VersiuneCOR as Versiune,
		convert(char(19),c.DataConsemnare,127)+'Z' as DataConsemnare, 
		convert(char(19),c.DataIncheiereContract,127)+'Z' as DataIncheiereContract, 
		convert(char(19),c.DataInceputContract,127)+'Z' as DataInceputContract, 
		(case when c.TipDurata='Determinata' then convert(char(19),c.DataSfarsitContract,127)+'Z' end) as DataSfarsitContract,
		NumarContract as NumarContract, NumarContractVechi as NumarContractVechi, DataContractVechi as DataContractVechi, convert(decimal(10),c.Salar) as Salar, ExceptieDataSfarsit, 
		Durata, IntervalTimp, Norma, Repartizare, TipContract, TipDurata, TipNorma,
		convert(char(19),c.DataIncetareContract,127)+'Z' as DataIncetareContract, TemeiIncetare,
		StareCurenta, convert(char(19),c.DataIncStareCurenta,127)+'Z' as DataIncStareCurenta, StarePrecedenta, DataIncetareStarePrecedenta, TemeiLegal
	into #tmpContracte
	from #RevisalContracte c
--	Create Unique Clustered Index CNP_Marca on #tmpContracte (CNP, Marca)
--	Create Index CNP on #tmpContracte (CNP)

--	creez cursor stare contracte curenta pentru toti salariatii (utilizand procedura pRevisalContracte). 
--	Asa merge mai repede decat daca se utiliza direct functia fRevisalStareContracte cu filtru pt. fiecare Marca din GenRevisalSalariati.
	create table #tmpStareCurenta
		(Data datetime, Marca char(6), StareContract char(50), DataInceput datetime, DataSfarsit datetime, DataIncetare datetime, TemeiLegal varchar(50), 
		AngajatorCui varchar(50), AngajatorNume varchar(50), Nationalitate varchar(50))
	insert into #tmpStareCurenta
	exec pRevisalStareContracte @dataJos=@dataJos, @dataSus=@dataSus, @Marca=@cMarca, @DataRegistru=@DataRegistru, @SiActiviIncetati=1, @SiUltimaStareAnt=0, @StarePrecedenta=0, @activitate=@activitate
	Create Unique Clustered Index Data_marca on #tmpStareCurenta (Data, Marca, StareContract, DataInceput)
	Create Index Marca on #tmpStareCurenta (Marca)

--	pun in tabela temporara si starea precedenta pentru a nu apela functia fRevisalStareContracte pentru fiecare marca
	create table #tmpStarePreced
		(Data datetime, Marca char(6), StareContract char(50), DataInceput datetime, DataSfarsit datetime, DataIncetare datetime, TemeiLegal varchar(50), 
		AngajatorCui varchar(50), AngajatorNume varchar(50), Nationalitate varchar(50))
	if OBJECT_ID('tempdb..#dataStare') is not null 
		drop table #dataStare
	Create table #DataStare (marca varchar(6), dataStare datetime, siUltimaStare int)
	insert into #DataStare 
	select marca, (case when StareCurenta='ContractStareSuspendare' and TemeiLegal='Art52Alin1LiteraD' then DataIncStareCurenta else DateADD(day,-1,DataIncStareCurenta) end), 0
	from #RevisalContracte
	insert into #tmpStarePreced
	exec pRevisalStareContracte @dataJos=@dataJos, @dataSus=@dataSus, @Marca=@cMarca, @DataRegistru=@DataRegistru, @SiActiviIncetati=1, @SiUltimaStareAnt=0, @StarePrecedenta=1, @activitate=@activitate
	Create Unique Clustered Index Data_marca on #tmpStarePreced (Data, Marca, StareContract, DataInceput)
	Create Index Marca on #tmpStarePreced (Marca)

	if OBJECT_ID('tempdb..#RevisalSporuri') is not null 
		drop table #RevisalSporuri
	select * into #RevisalSporuri 
	from fRevisalSporuri (@dataJos, @dataSus, '')

--	formare XML cu datele salariatilor
	set @XmlSalariati=
	(select rtrim((case when s.Cetatenie in ('UESEE','Alta') then @AdresaAng else s.Adresa end)) as Adresa, rtrim(s.CNP) as Cnp, rtrim(s.CNPVechi) as CnpVechi, 
		(select (select rtrim(c.CodCOR) as Cod, c.Versiune as Versiune for XML path('Cor'), type),
			c.DataConsemnare as DataConsemnare, c.DataIncheiereContract as DataContract, 
			c.DataInceputContract as DataInceputContract, 
			(case when c.TipDurata='Determinata' and rtrim(c.ExceptieDataSfarsit)='' then c.DataSfarsitContract end) as DataSfarsitContract,
			(case when nullif(c.DataContractVechi,'') is not null then DataContractVechi end) as DateContractVechi, 
			(case when s.Cetatenie in ('UESEE','Alta') then rtrim(s.Adresa)+(case when s.Localitate<>'' then ' loc. '+rtrim(s.Localitate) else '' end) end) as Detalii,
			(case when rtrim(c.ExceptieDataSfarsit)<>'' then rtrim(c.ExceptieDataSfarsit) end) as ExceptieDataSfarsit, 
			rtrim(c.NumarContract) as NumarContract, 
			(case when isnull(c.NumarContractVechi,'')<>'' then NumarContractVechi end) as NumereContractVechi, 
			convert(decimal(10),c.Salar) as Salariu, 
			(select rtrim(sp.IsProcent) as IsProcent, (select rtrim(sp.TipSpor) '@type', rtrim(sp.CodSpor) as Nume, 
			(case when sp.TipSpor='TipSporPredefinit' then rtrim(sp.Versiune) end) as Versiune 
			for xml path('Tip'), type, Elements), 
			rtrim(sp.ValoareSpor) as Valoare 
			from #RevisalSporuri sp where sp.Marca=c.Marca 
			--from fRevisalSporuri (@dataJos, @dataSus, c.Marca) sp 
			for xml path('Spor'), type, root('SporuriSalariu')),
			(select rtrim(c.StareCurenta) '@type', 
			(case when c.StarePrecedenta<>'' and c.StarePrecedenta='ContractStareDetasare' and c.StareCurenta='ContractStareSuspendare' 
			then (select rtrim(c.StarePrecedenta) '@type', (case when c.StarePrecedenta='ContractStareDetasare' then rtrim(isnull(sp.AngajatorCui,'')) end) as AngajatorCui, 
				(case when c.StarePrecedenta='ContractStareDetasare' then rtrim(isnull(sp.AngajatorNume,'')) end) as AngajatorNume, 
				(case when c.StarePrecedenta='ContractStareDetasare' then convert(char(19),isnull(sp.DataInceput,''),127)+'Z' end) as DataInceput, 
				(case when c.StarePrecedenta='ContractStareDetasare' and sp.DataIncetare<>'01/01/1901' then convert(char(19),isnull(sp.DataIncetare,''),127)+'Z' else Null end) as DataIncetare, 
				(case when c.StarePrecedenta='ContractStareDetasare' then convert(char(19),isnull(sp.DataSfarsit,''),127)+'Z' end) as DataSfarsit,
				(case when c.StarePrecedenta='ContractStareDetasare' then (select rtrim(isnull(sp.Nationalitate,'')) as Nume for xml path('Nationalitate'), type) end),
				(case when c.StarePrecedenta='ContractStareSuspendare' then convert(char(19),isnull(sp.DataInceput,''),127)+'Z' end) as DataInceput, 
				(case when c.StarePrecedenta='ContractStareSuspendare' and sp.DataIncetare<>'01/01/1901' then convert(char(19),isnull(sp.DataIncetare,''),127)+'Z' else Null end) as DataIncetare, 
				(case when c.StarePrecedenta='ContractStareSuspendare' then convert(char(19),isnull(sp.DataSfarsit,''),127)+'Z' end) as DataSfarsit,
				(case when c.StarePrecedenta='ContractStareSuspendare' then rtrim(sp.TemeiLegal) end) as TemeiLegal
			from #tmpStarePreced sp where sp.Marca=c.Marca 
			for xml path('StarePrecedenta'), type)	end),
			(case when c.StareCurenta='ContractStareIncetare' then convert(char(19),c.DataIncetareContract,127)+'Z' end) as DataIncetare,
			(case when c.StareCurenta='ContractStareIncetare' then rtrim(c.TemeiIncetare) end) as TemeiLegal,
			(case when c.StareCurenta='ContractStareDetasare' then rtrim(isnull(sc.AngajatorCui,'')) end) as AngajatorCui, 
			(case when c.StareCurenta='ContractStareDetasare' then rtrim(isnull(sc.AngajatorNume,'')) end) as AngajatorNume, 
			(case when c.StareCurenta='ContractStareDetasare' then convert(char(19),isnull(sc.DataInceput,''),127)+'Z' end) as DataInceput, 
			(case when c.StareCurenta='ContractStareDetasare' and sc.DataIncetare<>'01/01/1901' then convert(char(19),isnull(sc.DataIncetare,''),127)+'Z' else Null end) as DataIncetare, 
			(case when c.StareCurenta='ContractStareDetasare' then convert(char(19),isnull(sc.DataSfarsit,''),127)+'Z' end) as DataSfarsit,
			(case when c.StareCurenta='ContractStareDetasare' then (select rtrim(isnull(sc.Nationalitate,'')) as Nume for xml path('Nationalitate'), type) end),
			(case when c.StareCurenta='ContractStareSuspendare' then convert(char(19),isnull(sc.DataInceput,''),127)+'Z' end) as DataInceput, 
			(case when c.StareCurenta='ContractStareSuspendare' and sc.DataIncetare<>'01/01/1901' then convert(char(19),isnull(sc.DataIncetare,''),127)+'Z' else Null end) as DataIncetare, 
			(case when c.StareCurenta='ContractStareSuspendare' then convert(char(19),isnull(sc.DataSfarsit,''),127)+'Z' end) as DataSfarsit,
			(case when c.StareCurenta='ContractStareSuspendare' then rtrim(sc.TemeiLegal) end) as TemeiLegal,
			(case when (@multiFirma=1 or 1=1) and c.StareCurenta='ContractStareActiv' and c.StarePrecedenta='ContractStareDetasare' and c.DataIncetareStarePrecedenta<>'01/01/1901' 
				then convert(char(19),isnull(c.DataIncetareStarePrecedenta,''),127)+'Z' end) as DataIncetareDetasare,
			(case when (@multiFirma=1 or 1=1) and c.StareCurenta='ContractStareActiv' and c.StarePrecedenta='ContractStareSuspendare' and c.DataIncetareStarePrecedenta<>'01/01/1901' 
				then convert(char(19),isnull(c.DataIncetareStarePrecedenta,''),127)+'Z' end) as DataIncetareSuspendare
--			from fRevisalStareContracte (@dataJos, @dataSus, c.Marca, @DataRegistru, 1, 0) sc 
			from #tmpStareCurenta sc where sc.Marca=c.Marca
			for xml path('StareCurenta'), type),
			(select (case when c.Durata<>0 then c.Durata end) as Durata, 
			(case when c.IntervalTimp<>'' then rtrim(c.IntervalTimp) else Null end) as IntervalTimp, 
			rtrim(c.Norma) as Norma, rtrim(c.Repartizare) as Repartizare for xml path('TimpMunca'), type), 
			rtrim(c.TipContract) as TipContract, rtrim(c.TipDurata) as TipDurata, rtrim(c.TipNorma) as TipNorma
		from #tmpContracte c where c.Cnp=s.CNP for XML path('Contract'), type, root('Contracte'), Elements XSINIL),
		(case when s.Cetatenie='Alta' then (select convert(char(19),s.DataInceputAutorizatie,127)+'Z' as DataInceputAutorizatie, 
			convert(char(19),s.DataSfarsitAutorizatie,127)+'Z' as DataSfarsitAutorizatie, rtrim(s.TipAutorizatie) as TipAutorizatie for xml path('DetaliiSalariatStrain'), type) end), 
--	(case when s.Cetatenie='Romana' then (select rtrim(s.CodSiruta) as CodSiruta for xml path('Localitate'), type) end), 
--	initial, ca sa nu dea eroare, am tratat  ca la angajatii cu cetatenie alta decat cea Romana sa nu se scrie tag-ul pt. Localitate si Cod siruta
--	am intrebat la Teamnet si au spus ca solutia agreata cu reprezentantii Inspectiei Muncii este completarea Localitatii si Adresei cu datele angajatorului, iar in sectiunea Alte detalii sa se introducea datele salariatului strain ce nu are dominciliul in Romania
		(select rtrim((case when s.Cetatenie in ('UESEE','Alta') then @CodSirutaAng else s.CodSiruta end)) as CodSiruta for xml path('Localitate'), type), 
		(case when s.Mentiuni<>'' then rtrim(s.Mentiuni) end) as Mentiuni, (select rtrim(s.Nationalitate) as Nume for xml path('Nationalitate'), type), 
		rtrim(s.Nume) as Nume, rtrim(s.Prenume) as Prenume, rtrim(s.TipActIdentitate) as TipActIdentitate
	from #RevisalSalariati s 
		for XML path('Salariat'), root('Salariati'), Elements XSINIL)

--	inlocuiesc elementele de mai jos ca sa arate exact ca si in modelul de la ITM
	set @XmlSalariati=convert(xml,Replace(Convert(nvarchar(MAX), @XmlSalariati), '<Contracte xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">','<Contracte>'))
	set @XmlSalariati=convert(xml,Replace(Convert(nvarchar(MAX), @XmlSalariati), 'type','xsi:type'))
	set @XmlSalariati=convert(xml,Replace(Convert(nvarchar(MAX), @XmlSalariati), 'xsi','i'))
	
--	formare XML cu datele angajatorului
	set @XmlRezultatA=
		N'<XmlReport xmlns:i="http://www.w3.org/2001/XMLSchema-instance" > 
		<Header> <ClientApplication>ASiSplus</ClientApplication> <XmlVersion>0</XmlVersion> <UploadId i:nil="true" /> <UploadDescription i:nil="true" /> 
		<Angajator> <Adresa>'+rtrim(@AdresaAng)+'</Adresa> <Contact> <Email>'+rtrim(@email)+'</Email> 
		<Fax>'+rtrim(@fax)+'</Fax> <ReprezentantLegal>'+rtrim(@reprlegal)+'</ReprezentantLegal> 
		<Telefon>'+rtrim(@telefon)+'</Telefon> </Contact> 
		<Detalii i:type="'+(case when @CategorieAngajator='PersoanaFizica' then 'DetaliiAngajatorPersoanaFizica' else 'DetaliiAngajatorPersoanaJuridica' end)+'" >'
		+(case when @CategorieAngajator='PersoanaFizica' and @cFormaJ='ProfesieSpeciala' or @cFormaJ='OrganizatieAsociatieCuPersonalitateJuridica' and @cFormaOrg='AsociatieDeProprietari' then '' 
			else '<DomeniuActivitate> <Cod>'+rtrim(@caen)+'</Cod> <Versiune>'+rtrim(@VersiuneCAEN)+'</Versiune> </DomeniuActivitate> ' end)
		+'<Nume>'+rtrim(@den)+'</Nume> '+(case when @CategorieAngajator='PersoanaFizica' then '<ActIdentitatePF>'+rtrim(@ActIdentitatePF)+'</ActIdentitatePF> ' else '' end)
		+(case when @CategorieAngajator='PersoanaFizica' then '<Cnp>'+rtrim(@Cui)+'</Cnp> ' else '<Cui>'+rtrim(@Cui)+'</Cui> ' end)
		+(case when @CategorieAngajator='PersoanaFizica' then '' when @CuiParinte='' then '<CuiParinte i:nil="true" />' else '<CuiParinte>'+rtrim(@CuiParinte)+'</CuiParinte>' end)
		+(case when @CategorieAngajator='PersoanaFizica' then ' <FormaJuridicaPF>'+rtrim(@cFormaJ)+'</FormaJuridicaPF> ' else ' <FormaJuridicaPJ>'+rtrim(@cFormaJ)+'</FormaJuridicaPJ> ' end)
		+(case when @CategorieAngajator='PersoanaFizica' 
			then (case when @cFormaOrg<>'' then '<FormaOrganizarePF>'+rtrim(@cFormaOrg)+'</FormaOrganizarePF>' else ' <FormaOrganizarePF i:nil="true" />' end)
			when @cFormaOrg='' or @cFormaJ='AltePersoaneJuridice' then '<FormaOrganizarePJ i:nil="true" />' else '<FormaOrganizarePJ>'+rtrim(@cFormaOrg)+'</FormaOrganizarePJ> ' end)
		+(case when @CategorieAngajator='PersoanaFizica' then ' <Nationalitate> <Nume>'+rtrim(@NationalitatePF)+'</Nume> </Nationalitate> ' else '' end)
		+(case when @CategorieAngajator='PersoanaFizica' then '' else ' <FormaProprietate>'+rtrim(@cFormaPropr)+'</FormaProprietate> ' end)
		+(case when @CategorieAngajator='PersoanaFizica' then '' when @TipSocietate='' then '<NivelInfiintare i:nil="true" />' else '<NivelInfiintare>'+rtrim(@TipSocietate)+'</NivelInfiintare> ' end)
		+(case when @CategorieAngajator='PersoanaFizica' then '' when @denParinte='' then '<NumeParinte i:nil="true" />' else '<NumeParinte>'+rtrim(@denParinte)+'</NumeParinte>' end)+' </Detalii> 
		<Localitate> <CodSiruta> '+rtrim(@CodSirutaAng)+'</CodSiruta> </Localitate> </Angajator> </Header> </XmlReport>'

--	select @XmlSalariati, @XmlRezultatA
--	set @XmlRezultatA.modify('insert sql:variable("@XmlSalariati") into (/XmlReport)[1]')
--	scos modify de mai sus intrucat nu functioneaza pe SQL 2005 - inlocuit cu functia de mai jos
	set @XmlRezultatA=dbo.fInsereazaXmlInXml (@XmlRezultatA, @XmlSalariati)
	
	set @XmlRezultatA=convert(xml,Replace(Convert(nvarchar(MAX), @XmlRezultatA), '<Salariati xmlns:i="http://www.w3.org/2001/XMLSchema-instance">','<Salariati>'))
	set @XmlRezultatA = '<XmlReport xmlns:i="http://www.w3.org/2001/XMLSchema-instance" xmlns="http://schemas.datacontract.org/2004/07/Revisal.Entities" >'
		+Substring(convert(nvarchar(max),@XmlRezultatA),64,LEN(convert(nvarchar(max),@XmlRezultatA)))
	set @XmlRezultatA=convert(xml,@XmlRezultatA)
	set @XmlRezultat=@XmlRezultatA

--	salvez declaratia ca si continut in tabela declaratii
	if exists (select * from sysobjects where name ='scriuDeclaratii' and xtype='P')
		exec scriuDeclaratii @cod='REVISAL', @tip=0, @data=@datasus, @continut=@XmlRezultat

--	salvare fisier
	set @numeFisier = (case when @multiFirma=1 then rtrim(REPLACE(@denlmUtilizator,' ','_'))+'_' else '' end)
		+'Revisal_'+rtrim(@Cui)+'_'+convert(char(4),@An)+'_'+replace(str(@luna,2),' ',0)+'_'+replace(str(@ziua,2),' ',0)
		+(case when @inXML=1 then '_'+RTrim(replace(convert(char(8), getdate(), 108), ':', '')) else '' end)+'.xml' 
	set @cFisier=rtrim(@cDirector)+@numeFisier
--	creare tabela temporara pt. export date in fisier xml
	if (select count(1) from tempdb..sysobjects where name='##tmpRevisal')>0 
		drop table ##tmpRevisal
	create table ##tmpRevisal (coloana xml)
	if @inXML=1 /* daca inXML trimit fisierul pt. salvarea lui din Flex/AIR */
	begin 
		declare @XmlRezultatPtSalvare varchar(max)
		set @XmlRezultatPtSalvare=convert(varchar(max),@XmlRezultat)
		exec SalvareFisier @XmlRezultatPtSalvare, @cDirector, @numeFisier
		--	select @rezultat as document, @numeFisier as fisier, '' as nrFactura, 'wTipFormular' as numeProcedura for xml raw 
	end 
	else 
		begin /* altfel, il salvez in tabela temporara si apoi cu bcp in un fisier pe disk */
			insert into ##tmpRevisal values(convert(xml,@XmlRezultat))
			declare @nServer varchar(1000), @comandaBCP varchar(4000) /* comanda trebuie sa ramana varchar(4000) sau mai mica... */
			set @nServer=convert(varchar(1000),serverproperty('ServerName'))
	
			--set @comandaBCP='bcp "select coloana from ##tmpRevisal'+'" queryout "'+@cFisier+'" -T -c -r -t -C UTF-8 -S '+@nServer -- nu genera fisierul in format UTF8 sau 16 incat sa se poate deschide cu Revisalul
			--mitz: de testat cu aceasta comanda - cred ca tot UTF-16 scrie, dar se deschide ok in browser.
			--lucian: e ok, functioneaza.
			set @comandaBCP='bcp "select coloana from ##tmpRevisal'+'" queryout "'+@cFisier+'" -T -q -c -r\n -t -w -S '+@nServer -- -C UTF-8
			--	am scos -x intrucat la anumite versiuni de SQL 2005 nu exista aceasta optiune la bcp.
			exec @raspunsCmd = xp_cmdshell @comandaBCP
			--	select @raspunsCmd, @comandaBCP
			if @raspunsCmd != 0 /* xp_cmdshell returneaza 0 daca nu au fost erori, sau altfel, codul de eroare */
			begin
				set @msgeroare = 'Eroare la scrierea formularului pe hard-disk in locatia: '+ ( 
				case len(@cFisier) when 0 then 'NEDEFINIT' else @cFisier end )
				raiserror (@msgeroare ,11 ,1)
			end
			else	/* trimit numele fisierului generat */ 
				select @numeFisier as fisier, 'wTipFormular' as numeProcedura for xml raw
		end
end
else 
Begin
	if object_id('tempdb..#functii_lm') is not null drop table #functii_lm

--	selectez din functii_lm pozitiile valabile la data generarii raportului. 
--	functie de aceste date (functii_lm.Pozitie_stat) se va face ordonarea datelor in raport
	select * into #functii_lm from 
	(select Data, Loc_de_munca, Cod_functie, Pozitie_stat, RANK() over (partition by Loc_de_munca, Cod_functie order by Data Desc) as ordine
	from functii_lm f 
	where Data<=@DataSus and (@unLm=0 or Loc_de_munca like rtrim(@lm)+(case when @strict=0 then '%' else '' end)) 
		and not exists (select 1 from ValidCat v where v.Tip='LM' and v.Cod=f.Loc_de_munca and @DataRegistru between v.Data_jos and v.Data_sus)) a
	where Ordine=1

	select rtrim(s.Nume)+' '+rtrim(s.Prenume) as nume, c.cnp, rtrim(s.nationalitate) as nationalitate, rtrim(s.adresa)+', '+rtrim(s.localitate) as adresa, 
		rtrim(c.NumarContract)+'/'+convert(char(10),c.DataIncheiereContract,104) as numar_contract, 
		rtrim(c.TipDurata) as tip_durata, rtrim(c.Cod_functie) as Cod_functie, rtrim(c.CodCOR) as cod_cor, rtrim(c.DenumireCOR) as denumire_cor, 
		SUBSTRING(c.StareCurenta,14,10) as stare, c.salar, rtrim(c.loc_de_munca) as lm, rtrim(lm.Denumire) as den_lm
	from #RevisalContracte c
		inner join #RevisalSalariati s on s.CNP=c.Cnp
		left outer join lm on lm.Cod=c.Loc_de_munca	
		left outer join proprietati p on p.Tip='LM' and p.Cod=c.Loc_de_munca and p.Cod_proprietate='ORDINESTAT' and p.Valoare<>''
		left outer join #functii_lm fl on fl.Cod_functie=c.cod_functie and fl.Loc_de_munca=c.Loc_de_munca
	where (@staresalariati=0 or @staresalariati=1 and c.StareCurenta='ContractStareActiv' 
		or @staresalariati=2 and c.StareCurenta='ContractStareSuspendare' 
		or @staresalariati=3 and c.StareCurenta='ContractStareIncetare' 
		/*exists (select 1 from istpers i where i.Marca=c.Marca and i.data=dbo.EOM(@DataRegistru))*/)
	order by (case when @grupare=2 then isnull(replicate('0',9-len(RTRIM(p.Valoare)))+convert(varchar(10),p.Valoare),c.Loc_de_munca) else '' end), 
		(case when @grupare=2 then isnull(fl.Pozitie_stat,0) else 0 end), s.Nume 
End

	if object_id('tempdb..#tmpContracte') is not null drop table #tmpContracte
	if object_id('tempdb..#tmpStareCurenta') is not null drop table #tmpStareCurenta
	if object_id('tempdb..##tmpRevisal') is not null drop table ##tmpRevisal
	if object_id('tempdb..#functii_lm') is not null drop table #functii_lm

--	select @XmlRezultat
End

/*
	exec genRevisal '09/01/2014','09/30/2014','09/12/2014',0,'',0,'',0,'',0,'','',0,'','',0,'','SediuSocial','Pop Ionel','D:\D112\',0
	exec genRevisal '02/01/2011','02/28/2011','02/28/2011',1,'1184',0,'',0,'',0,'','',0,'','',0,'','SediuSocial','Pop Ionel','D:\Websites\asisria\formulare\',1
*/
