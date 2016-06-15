--***
create procedure wIaAlerteDateSalarii @sesiune varchar(50), @parXML XML, @rezultat xml=null output
as   
/*
	exec wIaAlerteDateSalarii @sesiune=null, @parXML='<row datajos="05/01/2013" datasus="05/31/2013" tipalerta="T" />'
*/
-- apelare procedura specifica daca aceasta exista.
begin try
	begin transaction alertesalarii

	set transaction isolation level read uncommitted
	declare @InstitutiiPublice int, @tip varchar(2), @dataJos datetime, @dataSus datetime, @utilizator varchar(20), @tipAlerta varchar(2), @zileref int, @inchidereluna int,
		@dataZiCrt datetime, @mesajeroare varchar(500), @filtruAlerta varchar(50), @filtruMarca varchar(50), @filtruLM varchar(30), @filtruExplicatii varchar(50)

	select @InstitutiiPublice=MAX((case when parametru='INSTPUBL' then Val_logica else @InstitutiiPublice end))
	from par where tip_parametru='PS' and parametru in ('INSTPUBL')
		
	exec wIaUtilizator @sesiune=@sesiune, @utilizator=@utilizator output

--	citire date din xml
	select 
		@tip = isnull(@parXML.value('(/row/@tip)[1]','varchar(3)'),''),
		@dataJos = isnull(@parXML.value('(/row/@datajos)[1]','datetime'),'1901-01-01'),
		@dataSus = isnull(@parXML.value('(/row/@datasus)[1]','datetime'),'2099-01-01'),
		@zileref = isnull(@parXML.value('(/row/@zileref)[1]','int'),30),
		@inchidereluna = isnull(@parXML.value('(/row/@inchidereluna)[1]','int'),0),
		@tipAlerta = isnull(@parXML.value('(/row/@tipalerta)[1]','varchar(2)'),''),
		@filtruMarca = isnull(@parXML.value('(/row/@f_marca)[1]','varchar(50)'),''),
		@filtruLM = isnull(@parXML.value('(/row/@f_lm)[1]','varchar(30)'),''),
		@filtruAlerta = isnull(@parXML.value('(/row/@f_alerta)[1]','varchar(50)'),''),
		@filtruExplicatii = isnull(@parXML.value('(/row/@f_explicatii)[1]','varchar(50)'),'')		

	if @tipAlerta='T' set @tipAlerta=''
	set @dataZiCrt=convert(datetime,convert(char(10),getdate(),103),103)
		
	IF OBJECT_ID('tempdb..#alerte') IS NOT NULL drop table #alerte
	IF OBJECT_ID('tempdb..#contracte') IS NOT NULL drop table #contracte
	IF OBJECT_ID('tempdb..#VarstePensionare') IS NOT NULL drop table #VarstePensionare
	IF OBJECT_ID('tempdb..#saveLMFiltrare') IS NOT NULL drop table #saveLMFiltrare

--	creez tabela temporara in care se poate salva in wIaAlerteSalariiSP (pozitiile din LMFiltrare pe utilizatorul curent) - Angajatorul
	select top 0 utilizator, cod into #saveLMFiltrare from LMFiltrare
	
	create table #alerte
	(
		tip_alerta varchar(2) not null,
		alerta varchar(100) not null,
		lm varchar(9) not null,
		denumire_lm varchar(50) not null,
		marca char(6) not null,
		nume varchar(50) not null,
		data_inceput datetime not null,
		data_sfarsit datetime not null,
		explicatii char(150) not null,
	) 
	CREATE UNIQUE CLUSTERED INDEX Unic ON #alerte (Tip_alerta, Data_sfarsit, Marca, Explicatii)

	if exists (select 1 from sysobjects where [type]='P' and [name]='wIaAlerteDateSalariiSP')
		exec wIaAlerteDateSalariiSP @sesiune, @parXML

--	suspendari contracte
	insert into #alerte
	select 'S', 'Incetare suspendare contract', lm, denumire_lm, s.Marca, s.Nume, s.Data_inceput, s.Data_sfarsit, 
		'Suspendarea contractului inceteaza peste '+rtrim(convert(char(4),DateDIFF(day,getdate(),s.Data_sfarsit)))+' zile!'
	from fRevisalSuspendari (@dataJos, @datasus, '') s
		left outer join personal p on p.Marca=s.Marca
	where s.Data_sfarsit<DateADD(day,@zileref,@dataZiCrt) 
		and isnull(s.Data_incetare,'01/01/1901') in ('01/01/1901','01/01/1900') 
		and (p.loc_ramas_vacant=0 or p.Data_plec>=@dataZiCrt)

	if @inchidereluna=1
		insert into #alerte
		select 'SS', 'Modificare procent '+rtrim(TipSpor), Loc_de_munca, Denumire_loc_de_munca, Marca, Nume, @datajos, @datasus, 
			'Modificare '+rtrim(TipSpor)+' de la '+rtrim(convert(char(4),SporLunaAnt))+'%'+' la '+rtrim(convert(char(4),SporLunaCrt))+'%!'
		from fModifProcentSporuri (@dataJos, @datasus, '', '', 'SP', 1, null, 0)

--	expirare tipuri autorizatii salariati straini
	insert into #alerte
	select 'A', 'Expirare autorizatie', lm, denumire_lm, a.Marca, a.Nume, DataInceput, DataSfarsit, 
		'Autorizatia salariatului expira peste '+rtrim(convert(char(4),DateDIFF(day,getdate(),DataSfarsit)))+' zile!'
	from fRevisalAutorizatii (@dataJos, @datasus, '') a
		left outer join personal p on p.Marca=a.Marca
	where DataSfarsit<DateADD(day,@zileref,getdate())
		and (p.Loc_ramas_vacant=0 or p.Data_plec>@dataJos)

	if @inchidereluna=1
		insert into #alerte
		select 'SS', 'Modificare procent '+rtrim(TipSpor), Loc_de_munca, Denumire_loc_de_munca, Marca, Nume, @datajos, @datasus, 
			'Modificare '+rtrim(TipSpor)+' de la '+rtrim(convert(char(4),SporLunaAnt))+'%'+' la '+rtrim(convert(char(4),SporLunaCrt))+'%!'
		from fModifProcentSporuri (@dataJos, @datasus, '', '', 'SP', 1, null, 0)

--	incetare contracte pe perioada determinata
	create table #contracte (marca varchar(6), nume varchar(50), cnp varchar(13), salar_de_baza float, cod_functie varchar(6), den_functie varchar(30), lm varchar(9), den_lm varchar(30), 
		numar_contract varchar(20), data_contract datetime, tip_contract varchar(30), durata_contract varchar(20), data_angajarii datetime, data_plecarii datetime, ordonare varchar(50)) 

	insert into #contracte
	exec rapAngajari '3', @dataJos, @dataSus, null, null, null, 0, null, 1, @zileref, null, null, 'Salariati', 0, @dataZiCrt

	insert into #alerte
	select 'C', 'Incetare contract pe per. determinata', lm, den_lm, marca, nume, data_angajarii, data_plecarii, 
		'Contractul de munca inceteaza peste '+rtrim(convert(char(4),DateDIFF(day,getdate(),data_plecarii)))+' zile!'
	from #contracte

--	salariati ce se pensioneaza 
	create table #VarstePensionare (sex char(1), data_nasterii datetime, data_pensionarii datetime, varsta_ani int, varsta_luni int, stagiu_complet varchar(10), stagiu_minim varchar(10))
	exec CalculVarstaPensionare @datalunii=@dataSus, @sex=null

	insert into #alerte
	select 'P', 'Salariati ce urmeaza a se pensiona', p.Loc_de_munca, lm.Denumire, p.marca, p.nume, p.data_nasterii, DateADD(month,vp.varsta_luni,DateADD(year,vp.varsta_ani,p.data_nasterii)), 
		'Salariatul urmeaza a se pensiona in luna curenta!'
	from personal p
		left outer join lm on lm.cod=p.Loc_de_munca
		inner join #VarstePensionare vp on vp.data_nasterii=dbo.EOM(p.Data_nasterii) and vp.data_pensionarii=@dataSus and vp.sex=(case when p.sex=1 then 'M' else 'F' end)
	where (p.Loc_ramas_vacant=0 or p.Data_plec>=@dataJos) 
		and coef_invalid<>5	-- nu se iau in calcul pensionarii
		and p.grupa_de_munca in ('N','D','S','C')	--	doar salariatii cu contract de munca

--	salariati a caror functii COR s-a tranformat in alte coduri COR sau au fost radiate (in baza tabelei Coresp_functii_COR cu tip_corespondenta>=11)
	insert into #alerte
	select 'FC', 'Salariati cu functii COR modificate/radiate', p.Loc_de_munca, lm.Denumire, p.marca, p.nume, p.Data_angajarii_in_unitate, Data_plec, 
		'Functia COR ('+rtrim(c.Val_inf)+') '+(case when cf.Numar_curent='' then 'a fost radiata din nomenclator' else ' ar trebui inlocuita cu '+rtrim(cf.Numar_curent) end)+'!'
	from personal p
		left outer join lm on lm.cod=p.Loc_de_munca
		left outer join extinfop c on c.Marca=p.Cod_functie and c.Cod_inf='#CODCOR'
		inner join Coresp_functii_COR cf on cf.Numar_curent_vechi=c.Val_inf and convert(int,cf.Tip_corespondenta)>=11
	where (p.Loc_ramas_vacant=0 or p.Data_plec>=@dataJos) 
		and p.grupa_de_munca in ('N','D','S','C')	--	doar salariatii cu contract de munca

--	validare salariati care vor implini 18 ani si sunt incadrati cu regim de lucru mai mic de 8 ore si norma intreaga
	insert into #alerte
	select 'M', 'Salariati ce au/vor implini(t) 18 ani', p.loc_de_munca, lm.denumire, p.marca, p.nume, p.Data_nasterii, DateADD(year,18,data_nasterii), 
		(case when DATEDIFF(day,getdate(),DateADD(year,18,data_nasterii))<0 then 'Salariatul a implinit 18 ani. Se poate incadra cu 8 ore pe zi!'
			else 'Salariatul va implimi 18 ani in '+convert(varchar(3),DATEDIFF(day,getdate(),DateADD(year,18,data_nasterii)))+' zile! Va trebui incadrat cu 8 ore pe zi!' end)
	from personal p 
		left outer join lm on lm.cod=p.Loc_de_munca
	where p.Salar_lunar_de_baza>0 and p.Salar_lunar_de_baza<8 and p.Grupa_de_munca in ('N','D','S') and (p.Loc_ramas_vacant=0 or p.Data_plec>@dataJos) 
		and abs(DATEDIFF(day,getdate(),DateADD(year,18,data_nasterii)))<30

	if @InstitutiiPublice=1
	begin
		declare @minus1 int
		set @minus1=0
		if isnull((select top 1 NrCrt from grspor a where a.Cod='Ve' order by a.Nrcrt Asc),0)=1 
			set @minus1=1
		insert into #alerte
		select 'MG', 'Salariati la care s-a modificat gradatia', p.loc_de_munca, lm.denumire, p.marca, p.nume, p.Data_angajarii_in_unitate, p.Data_plec, 
			'Gradatia s-a modificat de la '+(case when isnull(ga.gradatie_ant-@minus1,0)=0 then 'Debutant' else rtrim(convert(varchar(10),isnull(ga.gradatie_ant-@minus1,''))) end)
				+' la '+rtrim(convert(varchar(10),isnull(gc.gradatie_crt-@minus1,'')))+'!'
		from istpers i
			left outer join personal p on p.Marca=i.Marca
			left outer join istPers ia on ia.Data=DateADD(day,-1,dbo.BOM(i.Data)) and ia.Marca=i.Marca
			left outer join lm on lm.cod=p.Loc_de_munca
			outer apply (select top 1 Nrcrt as gradatie_crt from grspor v where v.Cod='Ve' 
				and v.Limita>=convert(int,(case when year(i.vechime_totala)=1899 then 1900 else year(i.vechime_totala)+(case when month(i.vechime_totala)=12 then 1 else 0 end) end)-1900)+1 order by v.Nrcrt Asc ) gc 
			outer apply (select top 1 Nrcrt as gradatie_ant from grspor v where v.Cod='Ve' 
				and v.Limita>=convert(int,(case when year(ia.vechime_totala)=1899 then 1900 else year(ia.vechime_totala)+(case when month(ia.vechime_totala)=12 then 1 else 0 end) end)-1900)+1 order by v.Nrcrt Asc ) ga 
		where i.Data=@dataSus 
			and isnull(ga.gradatie_ant,'')<>'' and p.Grupa_de_munca in ('N','D','S','C') and isnull(gc.gradatie_crt-@minus1,'')>isnull(ga.gradatie_ant-@minus1,'')
	end

--	in wIaAlerteSalariiSP1 pt. Angajatorul se pune la loc de munca, locul de munca de nivel 1 (firma) si se repun din #saveLMFiltrare in LMFiltrare, locurile de munca pe utilizator
	if exists (select 1 from sysobjects where [type]='P' and [name]='wIaAlerteDateSalariiSP1')
		exec wIaAlerteDateSalariiSP1 @sesiune, @parXML

--	returnare date
	select @rezultat=
	(select (case when Tip_alerta='S' then 'Incetare suspendare contract' 
			when Tip_alerta='C' then 'Incetare contract pe per. determinata' 
			when Tip_alerta='A' then 'Expirare autorizatie salariat strain' 
			when Tip_alerta='FC' then 'Salariati cu functii COR modif./radiate' 
			when Tip_alerta='P' then 'Salariati ce urmeaza a se pensiona' 
			when Tip_alerta='MG' then 'Salariati la care s-a modificat gradatia' 
			when Tip_alerta='M' then 'Salariati ce vor implini/au implinit 18 ani' else e.alerta end) as dentipalerta, 
		rtrim(e.lm) as lm, rtrim(e.denumire_lm) as denlm, rtrim(e.marca) as marca, rtrim(e.Nume) as densalariat, 
		rtrim(convert(char(10),data_inceput,103)) as datainceput, rtrim(convert(char(10),data_sfarsit,103)) as datasfarsit, 
		rtrim(explicatii) as explicatii
	from #alerte e
		left outer join personal p on p.Marca=e.Marca
		left outer join lm on lm.Cod=p.Loc_de_munca
	where (@filtruMarca='' or e.Marca like @filtruMarca+'%' or p.Nume like '%'+replace(@filtruMarca,' ','%')+'%')
		and (@filtruLM='' or p.Loc_de_munca like @filtruLM+'%' or lm.Denumire like '%'+replace(@filtruLM,' ','%')+'%')
		and (@tipAlerta='' or Tip_alerta=@tipAlerta)
		and (@filtruAlerta='' 
			or (case when Tip_alerta='S' then 'Incetare suspendare contract' when Tip_alerta='C' then 'Incetare contract pe per. determinata' 
				when Tip_alerta='A' then 'Expirare autorizatie salariat strain' 
				when Tip_alerta='FC' then 'Salariati cu functii COR modif./radiate' 
				when Tip_alerta='P' then 'Salariati ce urmeaza a se pensiona' 
				when Tip_alerta='MG' then 'Salariati la care s-a modificat gradatia' 
				when Tip_alerta='M' then 'Salariati ce vor implini/au implinit 18 ani' end) like '%'+REPLACE(@filtruAlerta,' ','%')+'%')
		and (@filtruExplicatii='' or e.Explicatii like '%'+replace(@filtruExplicatii,' ','%')+'%')
	order by /*Tip_alerta,*/ Data_sfarsit, Marca
	for xml raw )

	select @rezultat
	commit transaction alertesalarii
end try

begin catch
	rollback transaction alertesalarii
	set @mesajeroare='wIaAlerteDateSalarii (linia '+convert(varchar(20),ERROR_LINE())+') :'+char(10)+ERROR_MESSAGE()
	raiserror(@mesajeroare, 16, 1)
end catch

IF OBJECT_ID('tempdb..#alerte') IS NOT NULL drop table #alerte
IF OBJECT_ID('tempdb..#contracte') IS NOT NULL drop table #contracte
