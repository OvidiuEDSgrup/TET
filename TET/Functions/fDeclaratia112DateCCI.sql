--***
Create
function [dbo].[fDeclaratia112DateCCI] 
	(@DataJ datetime, @DataS datetime, @oMarca int, @Marca char(6), @Alfabetic int, 
	@Lm char(9), @Strict int, @unSirMarci int, @SirMarci char(200), @oCasaSan int, @CasaSan char(20), @TipD int)
returns @DeclaratieNominalaCCI table 
	(TipD int, Tip_rectificare char(1), Data datetime, Marca char(6), 
	Tip_diagnostic char(2), Data_inceput datetime, Data_sfarsit datetime, Zile_luna_anterioara int, Nume_asig char(50), 
	CNP char(13), Cnp_copil char(13), CAS_asig char(2), Total_zile_lucrate int, Serie_CCM char(5), Numar_CCM char(10), 
	Serie_CCM_initial char(5), Numar_CCM_initial char(10), Data_acordarii datetime, Cod_indemnizatie char(2), 
	Zile_prestatii_ang int, Zile_prestatii_Fnuass int, Zile_prestatii int, Loc_prescriere int, Indemnizatie_ang decimal(10), Indemnizatie_Fnuass decimal(10),
	Cod_urgenta char(3), Cod_boala_grpA char(2), Baza_calcul decimal(10), Zile_baza_calcul int, Media_zilnica decimal(10,4), 
	Nr_aviz_me char(10), P_faambp decimal(10))
as
begin
	declare @Somesana int, @Pasmatex int, @CodJudetSan char(2)
	set @Somesana=dbo.iauParL('SP','SOMESANA')
	set @Pasmatex=dbo.iauParL('SP','PASMATEX')
	set @CodJudetSan=dbo.iauParA('PS','CODJUDETA')

	insert @DeclaratieNominalaCCI
	select @TipD as TipD, (case when @TipD=1 then 'M' else '' end)  as Tip_rectif, a.Data, max(a.Marca), max(a.Tip_diagnostic), 
		a.Data_inceput, max(a.Data_sfarsit), max(a.Zile_luna_anterioara), max(p.Nume) as Nume_asig, p.Cod_numeric_personal as CNP, max(e.Cnp_copil) as CNP_copil,  
		max((case when 1=0 then rtrim(@CodJudetSan) when SUBSTRING(ADRESA,CHARINDEX(',',ADRESA)+1,2)<>'' then SUBSTRING(ADRESA,CHARINDEX(',',ADRESA)+1,2) else p.adresa end)) as CAS_Asig, 
		isnull((select sum(round((b.ore_lucrate_regim_normal+(case when @Somesana=1 and 1=0 then 0 else b.ORE_CONCEDIU_DE_ODIHNA+(case when @Pasmatex=0 then b.ORE_INTRERUPERE_TEHNOLOGICA else 0 end)+b.ORE_OBLIGATII_CETATENESTI end))/(case when b.spor_cond_10=0 then 8 else b.spor_cond_10 end),2)) from brut b where b.data between @DataJ and @DataS and b.marca=max(a.marca)),0) as Tot_zi_luc, 
		max(e.Serie_certificat_CM) as Serie_CCM, max(e.Nr_certificat_CM) as Numar_CCM, max(e.Serie_certificat_CM_initial) as Serie_CCM_, max(e.Nr_certificat_CM_initial) as Numar_CCM_, 
		max((case when e.Data_acordarii='01/01/1901' then a.Data_inceput else e.Data_acordarii end)) as Data_acord, 
		max((case when right(a.tip_diagnostic,1)='-' then '0' else '' end)+(case when right(a.tip_diagnostic,1)='-' then left(a.tip_diagnostic,1) else a.tip_diagnostic end)) as Cod_indemn, 
		max(a.Zile_cu_reducere*(case when a.Tip_diagnostic='10' then 0.25 else 1 end)) as Zi_PRE_ANG, 
		max((a.Zile_lucratoare-a.Zile_cu_reducere)*(case when a.Tip_diagnostic='10' then 0.25 else 1 end)) as Zi_FN, max(a.Zile_lucratoare*(case when a.Tip_diagnostic='10' then 0.25 else 1 end)) as Zi_PRE, 
		max(e.Loc_prescriere) as LOC_PRES, sum(a.Indemnizatie_unitate) as SUM_ANG, sum(a.Indemnizatie_CAS) as FN, 
		max(e.Cod_urgenta) as COD_URG, max(e.Cod_boala_grpA) as COD_CONTAG, 
		sum(s.Baza_stagiu) as BAZA_CALC, max(s.Zile_stagiu) as ZI_BZ_CALC, sum(round(a.Indemnizatia_zi,(case when a.data_inceput<'02/01/2011' then 4 else 2 end))) as MZBCI, 
		max(e.Nr_aviz_me) as ME_NR, 0 as P_faambp 
	from conmed a 
		left outer join personal p on p.marca=a.marca 
		left outer join infoconmed e on e.marca=a.marca and e.data=a.data and e.data_inceput=a.data_inceput
		left outer join dbo.concedii_medicale ('', 'zzz', @DataJ, @DataS, '', 'zzz', 0, '', '', 'zzz', 0, 0, '', 0, 0, '', 0, 6) s on a.Data=s.Data and a.Marca=s.Marca 
		and a.Tip_diagnostic=s.Cod_diagnostic and a.Data_inceput=s.Data_inceput
	where (a.tip_diagnostic not in ('2-','3-','4-','0-')) 
		and (@oMarca=0 or a.Marca=@Marca) and a.Marca=p.Marca and a.data_inceput between @DataJ and @DataS 
		and (p.loc_de_munca like rtrim(@Lm)+(case when @Strict=0 then '%' else '' end)) 
		and (@unSirMarci=0 or charindex(','+rtrim(ltrim(a.marca))+',',@SirMarci)>0) and (@oCasaSan=0 or p.adresa=@CasaSan) 
	group by a.Data, a.Data_inceput, p.Cod_numeric_personal
	order by max((case when @Alfabetic=0 then a.Marca else p.Nume  end))

	return
end
