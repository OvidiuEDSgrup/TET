/**
	Procedura este folosita pentru a lista Adeverinte cu date specifice Revisal. 
**/
create procedure rapAdeverintaRevisal (@sesiune varchar(50), @marca varchar(6), @datajos datetime, @datasus datetime, @dataset char(2), @parXML xml='<row/>')
AS
/*
	exec rapAdeverintaSomaj '', '1', '01/01/2012', '12/31/2012', 'P', '<row />'
*/
begin try 
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	
	DECLARE @functierepr varchar(100), @numerepr varchar(100), @numec varchar(100), @functc varchar(100), @nreprpers varchar(50), @freprpers varchar(50), 
		@tip varchar(2), @mesaj varchar(1000), @cTextSelect nvarchar(max), @debug bit, @utilizator varchar(50), @lista_lm int, @HostID char(10)
	
	if @sesiune<>''
		exec wIaUtilizator @sesiune=@sesiune, @utilizator=@utilizator output
	else 
		set @utilizator=dbo.fIaUtilizator(null)

	set @lista_lm=dbo.f_areLMFiltru(@utilizator)
	set @HostID=isnull((select convert(char(8),abs(convert(int,host_id())))),'')

	if @dataset='C' and not exists (select 1 from avnefac where Terminal=@HostID and Subunitate='1' and Tip='AD' and Numar=@marca) 
	begin
		delete from avnefac where terminal=@HostID
		insert into avnefac(Terminal, Subunitate, Tip, Numar, Cod_gestiune, Data, Cod_tert, Factura, Contractul, Data_facturii, Loc_munca, Comanda, 
			Gestiune_primitoare, Valuta, Curs, Valoare, Valoare_valuta, Tva_11, Tva_22, Cont_beneficiar, Discount) 
		values (@HostID, '1', 'AD', @marca, '', @dataSus, '', '', '', @datasus, '', '', '', '', 0, 12, 0, 0, 0, '', 0)
	end

--	Date contract
	if @dataset='C'
	begin
	/*
		Informatiile din PAR sau similare se iau o singura data, nu in selectul principal care ar cauza rularea instructiunilor de multe ori
	*/
		select	@functierepr=(case when parametru='FDIRGEN' then rtrim(val_alfanumerica) else @functierepr end),
			@numerepr=(case when parametru='DIRGEN' then rtrim(val_alfanumerica) else @numerepr end),
			@numec=(case when parametru='DIREC' then rtrim(val_alfanumerica) else @numec end),
			@functc=(case when parametru='FDIREC' then rtrim(val_alfanumerica) else @functc end),
			@nreprpers=(case when parametru='NREPRPERS' then rtrim(val_alfanumerica) else @numec end),
			@freprpers=(case when parametru='FREPRPERS' then rtrim(val_alfanumerica) else @functc end)
		from par
		where Tip_parametru='GE' and Parametru in ('NUME','CODFISC','ORDREG','ADRESA','JUDET','SEDIU','CONTBC','BANCA','FDIRGEN','DIRGEN','FDIREC','DIREC','SEFPERS','TELFAX','EMAIL') 
			or Tip_parametru='PS' and Parametru in ('CAEN','NREPRPERS','FREPRPERS')

		SELECT --top 1
			@functierepr as FUNCTIEREPR, @numerepr as NUMEREPR, @numec as NUMEC, @functc AS FUNCTC, @nreprpers as nreprpers, @freprpers as freprpers, 
			rtrim(p.Nume) as NUME, rtrim(p.localitate) as LOCALITATE, rtrim(p.judet) as JUDET, 
			(case when p.Localitate<>'' then 'loc. ' else '' end)+rtrim(p.Localitate)+(case when p.strada<>'' then ', str. ' else '' end)+rtrim(p.strada)
				+(case when p.numar<>'' then ', nr. ' else '' end)+rtrim(p.numar)+(case when p.bloc<>'' then ', bl. ' else '' end)+rtrim(p.bloc)
				+(case when p.scara<>'' then ', sc. ' else '' end)+rtrim(p.scara)+(case when p.Judet<>'' then ', jud. ' else '' end)+rtrim(p.Judet) as ADRESA,
			(case when upper(left(p.copii,2))='SX' or charindex('X',p.copii)<>0 then 'CI' else 'BI' end) as TIPACT, 
			ROW_NUMBER() OVER(ORDER BY p.Marca DESC) as nr_crt,
			rtrim(p.cod_numeric_personal) as CNP,
			CONVERT(CHAR(10),p.data_angajarii_in_unitate,103) as data_ang, 
			(case when CONVERT(CHAR(10),p.data_plec,103) not in ('01/01/1901','01/01/1900') and (p.Loc_ramas_vacant=1 or p.Mod_angajare='D') then CONVERT(CHAR(10),p.data_plec,103) else '' end) as data_pl,
			(case when dbo.iauExtinfopVal(p.Marca,'DATAINCH') in ('','ContractIndividualMunca')  then 'C.I.M.' 
				when dbo.iauExtinfopVal(p.Marca,'DATAINCH')='ContractMuncaTemporara' then 'C.M.T.'  when dbo.iauExtinfopVal(p.Marca,'DATAINCH')='ContractUcenicie' 
				then 'C.U.' else dbo.iauExtinfopVal(p.Marca,'DATAINCH') end) as tip_contract, 
			(case when p.mod_angajare='N' then 'Nedeterminata' when p.mod_angajare='D' then 'Determinata' else '' end) as durata_contract,
			isnull(rtrim(fc.cod_functie)+' - '+left(rtrim(fc.denumire),200),rtrim(f.Denumire)) as functie, lm.denumire as den_lm,
			rtrim(ip.nr_contract)+'/'+CONVERT(CHAR(10),dbo.iauExtinfopData(p.Marca,'DATAINCH'),104) as nr_contract, 
			(case when (select rtrim(val_inf) from extinfop e where e.marca=p.marca and e.cod_inf='CNTRITM')<>'' 
				then (select CONVERT(CHAR(10),(data_inf),103) from extinfop e where e.marca=p.marca and e.cod_inf='CNTRITM') 
				else (select CONVERT(CHAR(10),data_inf,103) from extinfop e where e.marca=p.marca and e.cod_inf='DATAINCH') end) as data_contract,
			dbo.iauExtinfopVal(p.Marca,'RTEMEIINCET') as temei_incetare,
			convert(char(10),convert(decimal(10),p.Salar_de_incadrare),1) as salar
		FROM personal p 
			left outer join extinfop e on e.Marca=p.Cod_functie and e.Cod_inf='#CODCOR' 
			left outer join functii_cor fc on fc.Cod_functie=e.Val_inf
			left outer join infopers ip on ip.Marca=p.Marca 
			left outer join functii f on f.Cod_functie=p.Cod_functie
			left outer join lm on lm.Cod=p.Loc_de_munca
			left outer join LMFiltrare lu on lu.utilizator=@utilizator and lu.cod=p.loc_de_munca
		where exists (select 1 from personal p1 where p1.Cod_numeric_personal=p.Cod_numeric_personal and p1.Marca=@marca)
			and (@lista_lm=0 or lu.cod is not null)
		order by p.data_angajarii_in_unitate
	end

--	Date vechimi
	if @dataset='VE'
	begin
		select v.crt as nr_crt,
			rtrim(v.nr_contract)+'/'+CONVERT(CHAR(10),v.Data_contract,104) as contract_vech,
			v.DurataContract as durata_contract,
			rtrim(v.Cod_functie)+' - '+left(rtrim(v.Denumire_functie),200) as functie,
			CONVERT(CHAR(10),v.DataJ,104)+' - '+(case when crt in (select top 1 crt from dbo.fAdevRevisalVechime() order by crt desc) and not(p.Loc_ramas_vacant=1 or p.Mod_angajare='D') 
				then 'Prezent' else CONVERT(CHAR(10),v.DataS,104) end) as perioada_vechime,
			convert(char(10),convert(decimal(10),v.Salar_de_baza),1) as salar_vech,
			(case when v.crt=1 then 'Adaugare' else 'Modificare' /*+' - '+rtrim(a.Explicatii)*/ end) as tip_act
		FROM dbo.fAdevRevisalVechime() v
			left outer join personal p on p.Marca=v.Marca
	end

--	Date suspendari
	if @dataset='SU'
	begin
		select s.NrCurent as nr_crt,
			(case when CONVERT(CHAR(10),s.Data_contract,103)<>'01/01/1901' then rtrim(s.nr_contract)+'/'+CONVERT(CHAR(10),s.Data_contract,104) else '' end) as contract_susp,
			(case when CONVERT(CHAR(10),s.DataInceput,103)<>'01/01/1901' then CONVERT(CHAR(10),s.DataInceput,103) else '' end) as data_inc_susp,
			(case when CONVERT(CHAR(10),s.DataSfarsit,103)<>'01/01/1901' then CONVERT(CHAR(10),s.DataSfarsit,103) else '' end) as data_sf_susp,
				(case when CONVERT(CHAR(10),s.DataIncetare,103) not in ('01/01/1901','01/01/1900') then CONVERT(CHAR(10),s.DataIncetare,103) else '' end) as data_incet_susp,
			rtrim(s.DescriereTemeiLegal) as temei_legal
		FROM fAdevRevisalSuspendari() s
	end

	--	Date detasari
	if @dataset='DE'
	begin
		select d.NrCurent as nr_crt, 
			(case when CONVERT(CHAR(10),d.Data_contract,103)<>'01/01/1901' then rtrim(d.nr_contract)+'/'+CONVERT(CHAR(10),d.Data_contract,104) else '' end) as contract_detas,
			(case when CONVERT(CHAR(10),d.DataInceput,103)<>'01/01/1901' then CONVERT(CHAR(10),d.DataInceput,103) else '' end) as data_inc_detas, 
			(case when CONVERT(CHAR(10),d.DataSfarsit,103)<>'01/01/1901' then CONVERT(CHAR(10),d.DataSfarsit,103) else '' end) as data_sf_detas, 
			(case when CONVERT(CHAR(10),d.DataIncetare,103) not in ('01/01/1901','01/01/1900') then CONVERT(CHAR(10),d.DataIncetare,103) else '' end) data_incet_detas,
			rtrim(d.AngajatorCui) as angajator_cui, 
			rtrim(d.AngajatorNume) as angajator_nume, 
			rtrim(d.Nationalitate) as angajator_nationalitate
		FROM fAdevRevisalDetasari() d
	end
--	Date sporuri
	if @dataset='SP'
	begin
		select sp.NrCurent as nr_crt,
			rtrim(sp.nr_contract)+'/'+CONVERT(CHAR(10),sp.Data_contract,104) as contract_spor,
			rtrim(sp.DenumireSpor) as den_spor,
			rtrim(convert(char(10),sp.ValoareSpor)) as valoare_spor,
			sp.TipSpor as tip_spor
		FROM fAdevRevisalSporuri() sp
	end
	
end try
begin catch
	set @mesaj=ERROR_MESSAGE()+ ' (rapAdeverintaRevisal)'
	raiserror(@mesaj, 11, 1)
end catch
