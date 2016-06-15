--***
create procedure [dbo].[MFimportdinCG] @datal datetime, @nrinvfiltru char(13), @categmffiltru int, @lmfiltru char(9)
as
declare @sub char(9), @IFN int, @valminmf float, @jurnal char(20), @lungdenmf int, 
	@tip char(3), @tipdocCG char(2), @numar char(8),@data datetime, @gest char(9), @tert char(13), @fact char(20), 
	@contcor varchar(40),@contmf varchar(40), @nrinv char(13), @cant float, @valoare float, @lm char(9), @com char(40), @codcl varchar(20), @denmf char(80), 
	@seriemf char(20), @tipam char(1), @cod char(20), @durata int, @datascad datetime, @sumatva float, @val_vanz float, 
	@contven varchar(40), @contfact varchar(40), @contam varchar(40), @contcham varchar(40), 
	@categmf int, @nrluni int, @felop char(1), @areintr int, @intrinlunacrt int
	/*,@bugetari int, @Elcond int, @cttvaded varchar(40), @cttvacol varchar(40), 
	@contcls8 varchar(40), @contrezrep varchar(40), @ctchamcorp varchar(40), @anctmfchamcorp int, 
	@anlmchamcorp int, @ctchamnecorp varchar(40), @anctmfchamnecorp int, @anlmchamnecorp int, 
	@ESUnoi int, @evidmfcasate int, @urmvalist int, @urmrezreev int, @reevcontab int, @MFria int, 
	@valoarem float --@cman1 char(40)--, @nman1 float*/

exec luare_date_par 'GE', 'SUBPRO', 0, 0, @sub output
exec luare_date_par 'GE','IFN', @IFN output, 0, ''
exec luare_date_par 'GE','VALOBINV', 0, @valminmf output, ''
set @jurnal=',MFX,MFR,'
set @lungdenmf=(select a.length from syscolumns a, sysobjects b where a.id=b.id and a.name='denumire' and b.name='mfix')

/*UPDATE fisaMF set 
and (@lmfiltru='' /*or fisaMF.Loc_de_munca like rtrim(@lmfiltru)+'%' */or exists (select 1 from 
pozdoc mm where mm.Subunitate=@sub and dbo.eom(mm.Data)=@datal --fisaMF.Data_lunii_operatiei 
/*and mm.Tip_miscare='TSE' */and mm.Cod_intrare=Numar_de_inventar 
and mm.Loc_de_munca/*_primitor */like rtrim(@lmfiltru)+'%' and exists (select 1 from 
nomencl n where n.cod=mm.cod and n.Tip='F') and left(mm.cont_de_stoc, 2)<>'23' 
and not (@IFN=1 and left(mm.cont_de_stoc, 2)='43')))*/

DELETE FROM fisaMF WHERE subunitate=@sub and Data_lunii_operatiei=@datal 
and (@nrinvfiltru='' or fisaMF.numar_de_inventar=@nrinvfiltru) 
and (@categmffiltru=0 or categoria=@categmffiltru) 
/*and exists (select 1 from misMF where mismf.subunitate=@sub 
and left(Tip_miscare,1) in ('I','E','M') and mismf.Data_lunii_de_miscare=@datal 
and mismf.numar_de_inventar=fisamf.numar_de_inventar and Procent_inchiriere in (1,2)) */
AND (felul_operatiei='5' and exists (select 1 
from mismf where mismf.subunitate=@sub and data_lunii_de_miscare=@datal and left(tip_miscare,1)='E' 
and mismf.numar_de_inventar=fisaMF.numar_de_inventar and procent_inchiriere in (1,2)) or 
/*exists (select 1 from mismf where mismf.subunitate=@sub and data_lunii_de_miscare=@datal 
and left(tip_miscare,1) in ('I','M') 
and mismf.numar_de_inventar=fisaMF.numar_de_inventar and procent_inchiriere in (1,2)) and */
((felul_operatiei='1' or felul_operatiei='3') and exists (select 1 
from mismf where mismf.subunitate=@sub and data_lunii_de_miscare=@datal and left(tip_miscare,1)='I' 
and mismf.numar_de_inventar=fisaMF.numar_de_inventar and procent_inchiriere in (1,2)) 
or felul_operatiei='4' and not exists (select 1 from mismf where mismf.subunitate=@sub 
and data_lunii_de_miscare=@datal and left(tip_miscare,1)='M' 
and mismf.numar_de_inventar=fisaMF.numar_de_inventar and procent_inchiriere not in (1,2))))
AND (@lmfiltru='' /*or fisaMF.Loc_de_munca like rtrim(@lmfiltru)+'%' */or exists (select 1 from 
pozdoc mm where mm.Subunitate=@sub and dbo.eom(mm.Data)=@datal --fisaMF.Data_lunii_operatiei 
/*and mm.Tip_miscare='TSE' */and mm.Cod_intrare=Numar_de_inventar 
and mm.Loc_de_munca/*_primitor */like rtrim(@lmfiltru)+'%' and exists (select 1 from 
nomencl n where n.cod=mm.cod and n.Tip='F') and left(mm.cont_de_stoc, 2)<>'23' 
and not (@IFN=1 and left(mm.cont_de_stoc, 2)='43')))
and not exists (select 1 from 
pozdoc mr where mr.Subunitate=@sub and dbo.eom(mr.Data)=@datal --fisaMF.Data_lunii_operatiei 
and mr.Cod_intrare=Numar_de_inventar and charindex(','+rtrim(mr.jurnal)+',',@jurnal)<>0)

DELETE FROM misMF WHERE mismf.subunitate=@sub and left(Tip_miscare,1) in ('I','E','M') 
and mismf.Data_lunii_de_miscare=@datal 
and (@nrinvfiltru='' or mismf.numar_de_inventar=@nrinvfiltru) and Procent_inchiriere in (1,2) 
and (@categmffiltru=0 or (select top 1 categoria from fisamf c where c.subunitate=@sub 
and c.numar_de_inventar=mismf.numar_de_inventar and felul_operatiei='1'
and Data_lunii_operatiei<=Data_lunii_de_miscare order by Data_lunii_operatiei desc)=@categmffiltru)
and (@lmfiltru='' /*or fisaMF.Loc_de_munca like rtrim(@lmfiltru)+'%' */or exists (select 1 from 
pozdoc mm where mm.Subunitate=@sub and dbo.eom(mm.Data)=@datal --fisaMF.Data_lunii_operatiei 
/*and mm.Tip_miscare='TSE' */and mm.Cod_intrare=Numar_de_inventar 
and mm.Loc_de_munca/*_primitor */like rtrim(@lmfiltru)+'%' and exists (select 1 from 
nomencl n where n.cod=mm.cod and n.Tip='F') and left(mm.cont_de_stoc, 2)<>'23' 
and not (@IFN=1 and left(mm.cont_de_stoc, 2)='43')))
and not exists (select 1 from 
pozdoc mr where mr.Subunitate=@sub and dbo.eom(mr.Data)=@datal --fisaMF.Data_lunii_operatiei 
and mr.Cod_intrare=Numar_de_inventar and charindex(','+rtrim(mr.jurnal)+',',@jurnal)<>0)

DELETE FROM Mfix WHERE mfix.subunitate=@sub and mfix.Data_punerii_in_functiune between 
dbo.BOM(@datal) and @datal and (@nrinvfiltru='' or mfix.numar_de_inventar=@nrinvfiltru) 
and not exists (select 1 from mismf a where left(a.tip_miscare,1)='I' and a.numar_de_inventar=mfix.numar_de_inventar) 
and not exists (select 1 from mfixini b where b.numar_de_inventar=mfix.numar_de_inventar) 
and (@categmffiltru=0 or (select max(categoria) from fisamf c where c.subunitate=@sub 
and c.numar_de_inventar=mfix.numar_de_inventar and felul_operatiei='1')=@categmffiltru)
and (@lmfiltru='' /*or fisaMF.Loc_de_munca like rtrim(@lmfiltru)+'%' */or exists (select 1 from 
pozdoc mm where mm.Subunitate=@sub and dbo.eom(mm.Data)=@datal --fisaMF.Data_lunii_operatiei 
/*and mm.Tip_miscare='TSE' */and mm.Cod_intrare=Numar_de_inventar 
and mm.Loc_de_munca/*_primitor */like rtrim(@lmfiltru)+'%' and exists (select 1 from 
nomencl n where n.cod=mm.cod and n.Tip='F') and left(mm.cont_de_stoc, 2)<>'23' 
and not (@IFN=1 and left(mm.cont_de_stoc, 2)='43')))
and not exists (select 1 from 
pozdoc mr where mr.Subunitate=@sub and dbo.eom(mr.Data)=@datal --fisaMF.Data_lunii_operatiei 
and mr.Cod_intrare=Numar_de_inventar and charindex(','+rtrim(mr.jurnal)+',',@jurnal)<>0)

declare crspozdocMFdinCG cursor for
	select a.tip, a.numar, a.data, a.gestiune, a.tert, max(a.factura), max(case when a.tip='RM' then a.cont_factura else a.cont_corespondent end), a.cont_de_stoc, a.cod_intrare, sum(a.cantitate), 
		sum(round(a.cantitate*a.pret_de_stoc+(case when b.Tip='F' and Procent_vama=3 then TVA_deductibil else 0 end),2)), a.loc_de_munca, a.comanda, 
		b.furnizor, b.denumire, b.loc_de_munca, max(case when abs(b.stoc_limita) between 1 and 9 then left(convert(char(10),abs(b.stoc_limita)),1) else '2' end), b.cod, b.categorie, max(a.data_scadentei), 
		sum(case when a.numar_dvi='' or a.tip='AP' then a.tva_deductibil else 0 end), sum(a.cantitate*a.pret_vanzare), a.cont_venituri, a.cont_factura, 
		max(isnull(nullif(a.detalii.value('(/row/@contam)[1]', 'varchar(40)'),''),(case when a.tip in ('AE','AP') then a.numar_DVI else b.UM_2 end))) as contam, 
		max(case when coeficient_conversie_2=0 then (case when left(furnizor,1)='2' then convert(float,left(furnizor,3))*10 else convert(float,left(furnizor,1)) end) else coeficient_conversie_2 end)  as categmf,
		max(a.detalii.value('(/row/@contcham)[1]', 'varchar(40)')) as contcham
	FROM pozdoc a, nomencl b 
	WHERE a.subunitate=@sub and a.data between dbo.bom(@datal) and @datal 
--	Lucian: Am repus conditia din versiunea anterioara (pentru RM si AI) si am scos conditia 1=1. Am pastrat comentariile de mai jos adaugate de Ghita
		and (a.tip='RM' and (0=0 or '4'='IAF' and left(a.cont_de_stoc,3)<>'303' or '4'='IPF' and left(a.cont_de_stoc,3)='303') or a.tip='AI' and (0=0 or '4' ='IAL') or a.tip='AP' or a.tip='AE') 
		and (a.cantitate>0 or a.tip in ('AI','RM'))	-- tipurile tratate: RM, AI, AP, AE - vezi mai sus cazurile 
		and charindex(','+rtrim(a.jurnal)+',',@jurnal)=0	-- sa nu fie din cele generate din aplicatia MF
		and left(a.cont_de_stoc,2)<>'23'	-- sa nu fie imobilizari in curs (puteau sa nu fie de tip F in Nomenclator...)
		and (@nrinvfiltru='' or a.cod_intrare=@nrinvfiltru) 
		and a.cod=b.cod and b.tip='F'	 -- filtrarea esentiala: coduri de tip MFix in Nomenclator
		and (@categmffiltru=0 or (case when coeficient_conversie_2=0 then (case when left(furnizor,1)='2' then convert(float,left(furnizor,3))*10 else convert(float,left(furnizor,1)) end) 
			else coeficient_conversie_2 end)=@categmffiltru) 
		and not (@IFN=1 and left(a.cont_de_stoc, 2)='43') 
--cond. pt. a nu da duplicate index la importul RM de m.f. intracomunitare in care intra si 50 % din TVA, 
--caz in care se pun cate 3 poz. pe RM pt. fiecare nr. de inv. din care una nu tb. sa afecteze val. de inv.
		and abs(a.cantitate*(a.pret_de_stoc+(case when b.Tip='F' and Procent_vama=3 then TVA_deductibil else 0 end)))>=0.01 
		and (@lmfiltru='' or a.loc_de_munca like rtrim(@lmfiltru)+'%') 
--	Lucian: Tratat sa aduca doar documentele de MF operate prin CGplus. Cele operate prin MF (Plus\Ria) sau Ria\Receptii\Intrari MF vor avea procent inchiriere 6 si sunt scrise deja in tabelele de MF.
		and not exists (select 1 from mismf m where m.subunitate=a.subunitate and m.numar_de_inventar=a.cod_intrare and m.data_miscarii=a.data and m.numar_document=a.numar and m.Procent_inchiriere=6)
	GROUP BY a.tip, a.numar, a.data, a.gestiune, a.tert, a.cod_intrare, a.cont_de_stoc, a.loc_de_munca, a.comanda, 
		b.furnizor, b.denumire, b.loc_de_munca, b.cod, b.categorie, a.cont_venituri, a.cont_factura 
	ORDER BY b.furnizor, a.tip desc, a.data--, a.numar_pozitie

open crspozdocMFdinCG
fetch next from crspozdocMFdinCG into @tipdocCG,@numar,@data,@gest, @tert, @fact, 
	@contcor,@contmf,@nrinv, @cant, @valoare, @lm, @com, 
	@codcl,@denmf,@seriemf,@tipam,@cod,@durata,@datascad, @sumatva,@val_vanz,
	@contven,@contfact,@contam,@categmf,@contcham
	/*@datapf, @datafact, @datascad, @valuta, 
	@curs, @difvalinv, @ajust, @valoare, @cotatva, @sumatva, @tiptva, 
	@indbug, @indbugprim, --@lmprim,@comprim, @gestprim,
	@valinv, @valam, @valamcls8, @valamneded, @valamist, 
	@rezreev, @amlun, --@amluncls8, @amlunneded, 
	@tipmf, @subtipmf, @durata, @nrluni, 
	@contgestprim, @contlmprim, @conttva, --@difam, @difamcls8, 
	@cod, @procinch, @nrpozitie, @patrim, 
	@denalternmf, @prodmf, @modelmf, @nrinmatrmf, @durfunct, @staremf, @datafabr*/
while @@fetch_status = 0
	begin
		SET @areintr=(case when exists (select 1 from misMF where subunitate=@sub and 
			numar_de_inventar=@nrinv and Data_lunii_de_miscare<=@datal 
			and left(Tip_miscare,1)='I') or exists (select 1 from MFixini where Subunitatea=@sub 
			and numar_de_inventar=@nrinv) then 1 else 0 end) 
		SET @intrinlunacrt=(case when exists (select 1 from misMF where subunitate=@sub and 
			numar_de_inventar=@nrinv and Data_lunii_de_miscare=@datal 
			and left(Tip_miscare,1)='I') then 1 else 0 end) 
		SET @tip=(case @tipdocCG when 'AE' then 'EAL' when 'AP' then 'EVI' 
			when 'RM' then (case when @areintr=1 then 'MFF' else 'IAF' end) 
			else (case when @areintr=1 then 'MAL' else 'IAL' end) end)
		SET @felop=(case 'M'+left(@tip,1) when 'MI' then '3' when 'MM' then '4' when 'ME' then '5' 
			when 'MT' then '6' when 'MC' then '7' when 'MS' then '8' else '9' end)
		SET @nrluni=@durata*12
		IF exists (select 1 from fisamf where subunitate=@sub and numar_de_inventar=@nrinv 
			and data_lunii_operatiei=dbo.bom(@datal)-1 and felul_operatiei='1') --and left(@tip,1)='M' 
			SELECT @durata=(case when f.Durata=0 then @durata else f.Durata end), 
			@nrluni=(case when f.Numar_de_luni_pana_la_am_int=0 
			then @nrluni else f.Numar_de_luni_pana_la_am_int-1 end)
			FROM fisamf f WHERE f.subunitate = @sub and f.numar_de_inventar = @nrinv 
			and f.felul_operatiei='1' and f.data_lunii_operatiei = dbo.bom(@datal)-1
		IF exists (select 1 from fisamf where subunitate=@sub and numar_de_inventar=@nrinv 
			and data_lunii_operatiei=@datal and felul_operatiei='1') --and left(@tip,1)='M' 
			SELECT @durata=f.Durata, @nrluni=f.Numar_de_luni_pana_la_am_int 
			FROM fisamf f WHERE f.subunitate = @sub and f.numar_de_inventar = @nrinv 
			and f.felul_operatiei='1' and f.data_lunii_operatiei = @datal
		--select @tip
		INSERT into mismf (Subunitate,Data_lunii_de_miscare,
			Numar_de_inventar,Tip_miscare,Numar_document,Data_miscarii,Tert,Factura,
			Pret,TVA,Cont_corespondent,Loc_de_munca_primitor,Gestiune_primitoare,
			Diferenta_de_valoare,Data_sfarsit_conservare,Subunitate_primitoare,
			Procent_inchiriere)
			select @sub, @datal, @nrinv, @tip, @numar, @data, 
			(case when @tip='EAL' or @tip='IAL' or @tip='MAL' then '' else @tert end), @fact, 
			(case when @tip='EVI' then @val_vanz when @tip in ('IAF','MFF') then @valoare else 0 end), @sumatva, @contcor, (case when @tip='EVI' then @contfact else '' end), 
			(case when @tip='EVI' then @contven else '' end), 
			(case when left(@tip,1)='M' then @valoare else 0 end), @datascad, @contam, 1

		IF 0=0 --left(@tip,1)<>'E' 
		BEGIN
		/*DELETE from fisamf where subunitate=@sub and 
			numar_de_inventar=@nrinv and data_lunii_operatiei=@datal and felul_operatiei=@felop*/
		IF not exists (select 1 from fisaMF where subunitate=@sub and numar_de_inventar=@nrinv 
			and data_lunii_operatiei=@datal and felul_operatiei=@felop)
			INSERT into fisamf (Subunitate,Numar_de_inventar,Categoria,Data_lunii_operatiei,
			Felul_operatiei,Loc_de_munca,Gestiune,Comanda,Valoare_de_inventar,
			Valoare_amortizata,Valoare_amortizata_cont_8045,Valoare_amortizata_cont_6871,
			Amortizare_lunara,Amortizare_lunara_cont_8045,Amortizare_lunara_cont_6871,Durata,
			Obiect_de_inventar, Cont_mijloc_fix,Numar_de_luni_pana_la_am_int,Cantitate,Cont_amortizare,Cont_cheltuieli)
			select @sub, @nrinv, @categmf, @datal, @felop, @lm, @gest, @com, 
			@valoare, 0, 0, 0, 0, 0, 0, @durata,
			(case when @valoare<@valminmf then 1 else 0 end), @contmf, @nrluni, 0, @contam, @contcham 
			--Autoliv n-am mai tratat, fiindca au reziliat contr. cu noi
		END
		
		IF left(@tip,1)='I' 
		BEGIN
		--mfix Subunitate
		IF not exists (select 1 from MFix where subunitate=@sub and numar_de_inventar=@nrinv)
			INSERT into mfix (Subunitate,Numar_de_inventar,Denumire,Serie,
			Tip_amortizare,Cod_de_clasificare,Data_punerii_in_functiune)
			values 
			(@sub,@nrinv,left(@denmf,@lungdenmf),@seriemf,@tipam,@codcl,@data)
		UPDATE MFix set Serie=@seriemf, Tip_amortizare=(case when @tipam='' then '2' else @tipam 
			end), Cod_de_clasificare=@codcl, Data_punerii_in_functiune=@data 
			where subunitate=@sub and numar_de_inventar=@nrinv
		--mfix DENS
		IF not exists (select 1 from MFix where subunitate='DENS' and numar_de_inventar=@nrinv)
			INSERT into mfix (Subunitate,Numar_de_inventar,Denumire,Serie,
			Tip_amortizare,Cod_de_clasificare,Data_punerii_in_functiune)
			values 
			('DENS',@nrinv,'',/*(case when @evidmfcasate=1 and @tip='MI' and @subtip='AL' 
			and left(@contmf,1)='8' then 'C' else '' end)*/'',
			(case when left(@contam,1)='8' then '1' else '' end),
			@contam, --(case when @tip='MI' and @subtip='DO' then '01/01/1902' else 
			'01/01/1901')
		UPDATE MFix set Cod_de_clasificare=@contam 
			where subunitate='DENS' and @contam<>'' 
			and numar_de_inventar=@nrinv and Cod_de_clasificare<>@contam
		UPDATE MFix set Tip_amortizare=(case when left(@contam,1)='8' then '1' else '' end) 
			where subunitate='DENS' and numar_de_inventar=@nrinv
		/*DELETE from fisamf where subunitate=@sub and 
			numar_de_inventar=@nrinv and data_lunii_operatiei=@datal and felul_operatiei='1'*/
		/*IF not exists (select 1 from fisaMF where subunitate=@sub and numar_de_inventar=@nrinv 
			and data_lunii_operatiei=@datal and felul_operatiei='1')*/
		INSERT into fisamf (Subunitate,Numar_de_inventar,Categoria,Data_lunii_operatiei,
			Felul_operatiei,Loc_de_munca,Gestiune,Comanda,Valoare_de_inventar,
			Valoare_amortizata,Valoare_amortizata_cont_8045,Valoare_amortizata_cont_6871,
			Amortizare_lunara,Amortizare_lunara_cont_8045,Amortizare_lunara_cont_6871,Durata,
			Obiect_de_inventar, Cont_mijloc_fix,Numar_de_luni_pana_la_am_int,Cantitate)
			select Subunitate,Numar_de_inventar,Categoria,Data_lunii_operatiei,
			'1',@lm,@gest,@com/*Loc_de_munca,Gestiune,Comanda*/,Valoare_de_inventar,
			Valoare_amortizata,Valoare_amortizata_cont_8045,Valoare_amortizata_cont_6871,
			Amortizare_lunara,Amortizare_lunara_cont_8045,Amortizare_lunara_cont_6871,Durata,
			Obiect_de_inventar, Cont_mijloc_fix,Numar_de_luni_pana_la_am_int,Cantitate
			from fisamf where subunitate=@sub and 
			numar_de_inventar=@nrinv and data_lunii_operatiei=@datal and felul_operatiei='3'
		END
		
		if left(@tip,1)='M' and @intrinlunacrt=1 
		begin
			UPDATE fisaMF set Valoare_de_inventar=Valoare_de_inventar+@valoare
				where subunitate=@sub and numar_de_inventar=@nrinv 
				and data_lunii_operatiei=@datal and Felul_operatiei='1'
			--exec MFcalclun @Datal=@Datal, @nrinv=@nrinv, @categmf=0, @lm=''
			UPDATE fisaMF set Valoare_de_inventar=(select Valoare_de_inventar from fisaMF where 
				subunitate=@sub and numar_de_inventar=@nrinv and data_lunii_operatiei=@datal and Felul_operatiei='1')
				where subunitate=@sub and numar_de_inventar=@nrinv 
				and data_lunii_operatiei=@datal and Felul_operatiei='4'
		end
		
		--select @tipGrp=@tip, @numarGrp=@numar, @dataGrp=@datal

		fetch next from crspozdocMFdinCG into @tipdocCG,@numar,@data,@gest, @tert, @fact, 
			@contcor,@contmf,@nrinv, @cant, @valoare, @lm, @com, 
			@codcl,@denmf,@seriemf,@tipam,@cod,@durata,@datascad,@sumatva,@val_vanz,
			@contven,@contfact,@contam,@categmf,@contcham
			/*@datapf, @datafact, @datascad, @valuta, 
			@curs, @difvalinv, @ajust, @valoare, @cotatva, @sumatva, @tiptva, 
			@indbug, @indbugprim, --@lmprim,@comprim, @gestprim,
			@valinv, @valam, @valamcls8, @valamneded, @valamist, 
			@rezreev, @amlun, --@amluncls8, @amlunneded, 
			@tipmf, @subtipmf, @durata, @nrluni, 
			@contgestprim, @contlmprim, @conttva, --@difam, @difamcls8, 
			@cod, @procinch, @nrpozitie, @patrim, 
			@denalternmf, @prodmf, @modelmf, @nrinmatrmf, @durfunct, @staremf, @datafabr*/
	end
	
close crspozdocMFdinCG 
deallocate crspozdocMFdinCG 
