--***
create procedure [dbo].[MFscriupozdoc] @tip char(2),@subtip char(2),@numar char(8),
@data datetime,@nrinv char(13),@contcor varchar(40)='',@contgestprim varchar(40)='',@contlmprim varchar(40)='', 
@contamcomprim varchar(40)='', @indbugprim char(30)='', @gest char(9)=null, @lm char(9)=null,
@com char(20)=null,@indbug char(30)=null,@contmf varchar(40)=null,--@contmf nu e null/'' la TSE
@conttva varchar(40)='', @tipmf int=0,@tert char(13)='',@fact char(20)='',@datafact datetime='01/01/1901',
@datascad datetime='01/01/1901',@valinv float=0,@valam float=0,@valamcls8 float=0,@valamneded float=0,
@rezreev float=0, @cotatva float=0, @sumatva float=0, @tiptva int=0, @difvalinv float=0, @pret float=0,
@ajust float=0, @pretvaluta float=0, @valuta char(3)='', @curs float=0, @cod char(20)='MIJLOC_FIX_MF', @detaliiPozdoc xml=null
as
declare @sub char(9),@bugetari int, @cttvaded varchar(40), @cttvacol varchar(40), @Elcond int, 
	@evidmfiesite int, @urmvalist int, @reevcontab int, @urmrezreev int, @ctrezrep varchar(40), @cont8045 varchar(40), @ct105 varchar(40), 
	@ESUnoi int, @ctchamcorp varchar(40), @anctmfchamcorp int, @anlmchamcorp int,
	@ctchamnecorp varchar(40),@anctmfchamnecorp int,@anlmchamnecorp int,
	@userASiS varchar(10), @stare int, @jurnal char(3), @nrpozitie int, @nrpozitiem int,
	@datal datetime,@datalantsauintr datetime,@tippatrim char(1),@tipdocCG char(2),@tipm char(2),@subtipm char(2),
	@difvalinvMRE float, @difvalamMRE float, 
	@pretm float,@ctamm varchar(40),@ctrezreev varchar(40),@amlun float,@amluncls8 float,@binar varbinary(128)

exec luare_date_par 'GE', 'SUBPRO', 0, 0, @sub output
exec luare_date_par 'GE','BUGETARI', @bugetari output, 0, ''
exec luare_date_par 'SP','ELCOND', @Elcond output, 0, ''
exec luare_date_par 'GE', 'CDTVA', 0, 0, @cttvaded output
exec luare_date_par 'GE', 'CCTVA', 0, 0, @cttvacol output
exec luare_date_par 'MF', 'CTREZREP', 0, 0, @ctrezrep output
if @ctrezrep='' set @ctrezrep='1065'
--exec luare_date_par 'MF', 'CONTMODIF', 0, 0, @ct105 output
if @ct105 is null set @ct105='105'
exec luare_date_par 'MF', 'CA681', 0, @anlmchamcorp output, @ctchamcorp output
if @ctchamcorp='' set @ctchamcorp='6811'
if @anlmchamcorp=2 set @anctmfchamcorp=1 else set @anctmfchamcorp=0
if @anlmchamcorp=3 set @anlmchamcorp=1 else set @anlmchamcorp=0
exec luare_date_par 'MF', '681NECORP', 0, @anlmchamnecorp output, @ctchamnecorp output
if @ctchamnecorp='' set @ctchamnecorp=@ctchamcorp
if @anlmchamnecorp=0 set @anctmfchamnecorp=@anctmfchamcorp
if @anlmchamnecorp=2 set @anctmfchamnecorp=1 else set @anctmfchamnecorp=0
if @anlmchamnecorp=0 set @anlmchamnecorp=@anlmchamcorp
if @anlmchamnecorp=3 set @anlmchamnecorp=1 else set @anlmchamnecorp=0
exec luare_date_par 'MF', 'CTAMGRNU', 0, 0, @cont8045 output
if @cont8045='' set @cont8045='8045'
exec luare_date_par 'MF','AENSTDESU', @ESUnoi output, 0, ''
if @ESUnoi=1 set @ESUnoi=-1
if @ESUnoi=0 exec luare_date_par 'MF','ESUNOI', @ESUnoi output, 0, ''
if @ESUnoi=-1 set @ESUnoi=0
if @tip='MT' or @tip='ME' and @subtip='SU' and @tert='AE' set @ESUnoi=1
exec luare_date_par 'MF','EVMFDCAS', @evidmfiesite output, 0, ''
exec luare_date_par 'MF','URMVALIST', @urmvalist output, 0, ''
exec luare_date_par 'MF','MRECONTAB', @reevcontab output, 0, ''
exec luare_date_par 'MF','REZREEV', @urmrezreev output, 0, ''
set @userASiS = isnull(dbo.fIaUtilizator(null),'')
select @tipm=@tip, @subtipm=@subtip, @datal=dbo.EOM(@data), @stare=2/*7*/, 
	@jurnal='MFX' /*nu schimba jurnalul!!!!!*/
set @datalantsauintr=case when exists (select 1 from misMF where Subunitate=@sub and LEFT(tip_miscare,1)='I' 
	and Data_lunii_de_miscare=@datal and Numar_de_inventar=@nrinv) then @datal else dbo.bom(@datal)-1 end

--	pun in tabela temporara conturile de amortizare citite din fisaMF (sa nu se faca selecturi din fisa de mai multe ori)
if object_id('tempdb..#fisamf_ct') is not null drop table #fisamf_ct
select m.numar_de_inventar, isnull(f.cont_amortizare,isnull((select fa.cont_amortizare ),isnull((select t.cont_amortizare ),md.cod_de_clasificare))) as contam, 
	isnull(f.cont_cheltuieli,isnull((select fa.cont_cheltuieli),isnull((select t.cont_cheltuieli),''))) as contcham
into #fisamf_ct
from mfix m 
join fisamf f on f.subunitate=m.Subunitate and f.numar_de_inventar=m.Numar_de_inventar and f.felul_operatiei='1' and f.data_lunii_operatiei=@datal
join fisamf fa on fa.subunitate=m.Subunitate and fa.numar_de_inventar=m.Numar_de_inventar and fa.felul_operatiei='1' and fa.Data_lunii_operatiei=@datalantsauintr
outer apply
(
	select top 1 * from fisamf fi where fi.subunitate=m.Subunitate and fi.numar_de_inventar=m.Numar_de_inventar and fi.felul_operatiei in ('2','3')
) t
join mfix md on md.subunitate='DENS' and md.Numar_de_inventar=f.Numar_de_inventar
where m.subunitate=@sub and f.numar_de_inventar=@nrinv 

/*	Calculez diferentele provenite din modificarile de valoare ale lunii curente. 
	Aceste sume trebuie si ele transferate impreuna cu sumele din luna anterioara, daca locul de munca predator este egal cu locul de munca al modificarilor */
IF @tip='MT' and @subtip='SE' SELECT @difvalinvMRE=sum(Diferenta_de_valoare), @difvalamMRE=sum(pret)
			from mismf m
			inner join fisamf f on f.subunitate=m.Subunitate and f.numar_de_inventar=m.Numar_de_inventar and f.felul_operatiei='4' and f.data_lunii_operatiei=@datal and f.Loc_de_munca=@lm
			where m.Subunitate=@sub and m.Numar_de_inventar=@nrinv and m.Data_lunii_de_miscare=@datal and left(m.Tip_miscare,1)='M'
			group by m.Numar_de_inventar
select @difvalinvMRE=isnull(@difvalinvMRE,0), @difvalamMRE=isnull(@difvalamMRE,0)
IF /*isnull(@contmf,'')='' and */@tip='MT' SELECT @ctamm=f.contam FROM #fisamf_ct f 
IF /*isnull(@contmf,'')='' and */@tip='MT' SELECT @valinv=f.Valoare_de_inventar+(case when @subtip='SE' then @difvalinvMRE else 0 end), 
			@valam=f.Valoare_amortizata+(case when @subtip='SE' then @difvalamMRE else 0 end), @valamcls8=f.Valoare_amortizata_cont_8045, 
			@valamneded=f.Valoare_amortizata_cont_6871, @rezreev=f.Cantitate
			FROM fisamf f 
			WHERE f.subunitate = @sub and f.numar_de_inventar = @nrinv 
			and f.felul_operatiei='1' and f.data_lunii_operatiei = @datalantsauintr	--@datal. Si totusi se pare ca trebuie transferata valoarea	din luna anterioara
					--Valoarea din luna curenta se va genera pe locul de munca primitor.
IF isnull(@contmf,'')='' and @tip='MT' SELECT @contgestprim=isnull(@contgestprim,f.gestiune), 
			@contlmprim=isnull(@contlmprim,f.loc_de_munca), 
			@contamcomprim=isnull(@contamcomprim,left(f.comanda,20)), 
			@indbugprim=replace(isnull(@indbugprim,substring(f.comanda,21,20)),'.','')
			--, @gest=f.gestiune, @lm=f.loc_de_munca, @com=left(f.comanda,20), @indbug=substring(f.comanda,21,20)
			FROM fisamf f WHERE f.subunitate = @sub and f.numar_de_inventar = @nrinv 
			and f.felul_operatiei=(select top 1 ft.Felul_operatiei from fisamf ft where 
			ft.subunitate = @sub and ft.numar_de_inventar = @nrinv and ft.felul_operatiei in 
			('1','6') and ft.data_lunii_operatiei = @datal order by ft.Felul_operatiei desc) 
			and f.data_lunii_operatiei = @datal
IF isnull(@contmf,'')='' and @tip<>'MT' SELECT @contgestprim=ISNULL(@contgestprim,''), 
			@contlmprim=ISNULL(@contlmprim,''), @contamcomprim=isnull(@contamcomprim,''), 
			@indbugprim=replace(isnull(@indbugprim, ''),'.','')
IF isnull(@contmf,'')='' and @tip<>'MI' 
			SELECT @gest=(case when isnull(@gest,'')='' then f.gestiune else @gest end), 
			@lm=(case when isnull(@lm,'')='' then f.loc_de_munca else @lm end), 
			@com=isnull(@com,left(f.comanda,20)), 
			@indbug=isnull(@indbug,substring(f.comanda,21,20)), 
			@contmf=isnull(@contmf,f.cont_mijloc_fix)
			FROM fisamf f WHERE f.subunitate = @sub and f.numar_de_inventar = @nrinv 
			and f.felul_operatiei='1' and f.data_lunii_operatiei = @datal
IF @tip='MT' SELECT @amlun=f.amortizare_lunara, @amluncls8=f.amortizare_lunara_cont_8045
			FROM fisamf f WHERE f.subunitate = @sub and f.numar_de_inventar = @nrinv 
			and f.felul_operatiei='1' and f.data_lunii_operatiei = @datal
IF @tip='MT' SELECT @ctrezreev=isnull((select fa.Cont_mijloc_fix
			FROM fisamf fa WHERE fa.subunitate = @sub and fa.numar_de_inventar = @nrinv 
			and fa.felul_operatiei='A' and fa.data_lunii_operatiei = @datal),'')
IF @tip='ME' and @subtip='CS' SELECT @tippatrim=isnull((select top 1 mtp.tert
			FROM mismf mtp WHERE mtp.subunitate = @sub and mtp.numar_de_inventar = @nrinv 
			and mtp.Tip_miscare='MTP' and mtp.Data_lunii_de_miscare <= @datal 
			order by mtp.Data_lunii_de_miscare desc), isnull((select xd.Tip_amortizare
			FROM mfix xd WHERE xd.subunitate='DENS' and xd.Numar_de_inventar=@nrinv),''))

set @binar=cast('modificaredocdefinitivMF' as varbinary(128))
set CONTEXT_INFO @binar

SET @tipdocCG=(case @tip when 'MI' then (case @subtip when 'AF' then 'RM' else 'AI' end) 
			when 'MM' then (case @subtip when 'EP' then 'AE' when 'FF' then 'RM' else 'AI' end) 
			when 'ME' then (case @subtip when 'SU' then 'AE' when 'VI' then 'AP' else 'AE' end) 
			when 'MT' then (case when 6/*@procinch*/=6 and @subtip='SE' then 'AI' else '' end) 
			else '' end)
IF @tip in ('MI','MM','ME','MT') DELETE pozdoc where subunitate=@sub and tip=@tipdocCG 
	and numar=@Numar and data=@Data /*and cod<>'TVANCN' */and Cod_intrare=@nrinv and Jurnal=@jurnal --and Numar_pozitie=@nrpozitie
IF @tip in ('MI','MM','ME','MT') and 6/*@procinch*/=6 --and @subtip='AF'
BEGIN
		IF isnull(@nrpozitie,0)=0 
		begin
			EXEC luare_date_par 'DO','POZITIE',0,@nrpozitie output,''
			SET @nrpozitie=(case when isnull(@nrpozitie,0)>=999999998 then 0 else 
				isnull(@nrpozitie,0) end)+1
			SET @nrpozitiem=@nrpozitie+(case when @tip='MT' then 1 else 0 end)
			EXEC setare_par 'DO','POZITIE',null,null,@nrpozitiem,null 
		end
		IF isnull(@numar,'')='' set @numar='IMPL'+rtrim(convert (char(4),@nrpozitie%10000))
		
		IF @tip='MT' and @subtip='SE' and 6/*@procinch*/=6 
		begin
			set @binar=cast('specificebugetari' as varbinary(128))  
			set CONTEXT_INFO @binar  
			select @tipm='MI', @subtipm='SU'
		end
 
		IF @tipm='MI' INSERT pozdoc
			(Subunitate,Tip,Numar,Cod,Data,Gestiune,Cantitate,Pret_valuta,Pret_de_stoc,Adaos,
			Pret_vanzare,Pret_cu_amanuntul,TVA_deductibil,Cota_TVA,Utilizator,Data_operarii,
			Ora_operarii,Cod_intrare,Cont_de_stoc,Cont_corespondent,TVA_neexigibil,
			Pret_amanunt_predator,Tip_miscare,Locatie,Data_expirarii,Numar_pozitie,Loc_de_munca,
			Comanda,Barcod,Cont_intermediar,Cont_venituri,Discount,Tert,Factura,
			Gestiune_primitoare,Numar_DVI,Stare,Grupa,Cont_factura,Valuta,Curs,Data_facturii,
			Data_scadentei,Procent_vama,Suprataxe_vama,Accize_cumparare,Accize_datorate,
			Contract,Jurnal)
			VALUES 
			(@sub,@tipdocCG,@Numar,@Cod,@Data,(case when @tip='MT' then @contgestprim else @Gest end),
			1,(case when @valuta='' then @pret else @Pretvaluta end),
			(case @subtipm when 'AF' then @pret else @valinv end),(case @subtipm when 'AF' then -100 else 0 end),0,
			0,@sumatva,@cotatva,@userASiS,convert(datetime,convert(char(10),getdate(),104),104), 
			RTrim(replace(convert(char(8),getdate(),108),':','')),@nrinv,@contmf,@contcor,
			(case @subtipm when 'AF' then @cotatva else 0 end),
			(case when @subtipm='SU' and @urmrezreev=1 then @valamneded else 0 end),
			'V','',@data,@nrpozitie+(case when @tip='MT' then 1 else 0 end),
			(case when @tip='MT' then @contlmprim else @lm end),
			(case when @tip='MT' then @contamcomprim+replace(@indbugprim,'.','') else 
			@com+replace(@indbug,'.','') end),(case when @valamcls8<>0 then @cont8045 else '' end),	'',	
			(case when @tip='MT' and @urmrezreev=1 and @subtipm='SU' and @ESUnoi=1 then 
			@ctrezreev /*isnull(fa.cont_mijloc_fix,'') */when @subtipm in ('AF','SU') then (case when 
			@conttva='' then @cttvaded else @conttva end) else '' end),
			0, (case when @subtipm='SU' and @urmrezreev=1 then @contcor else @tert end),
			(case @subtipm when 'AF' then @fact else right(@tip,1)+@subtip end),
			(case when @subtipm='DO' and @contgestprim<>'' then @contgestprim 
				when @subtipm<>'AF' then @contcor else '' end),'',@Stare,
			(case when @subtipm='AF' and @valuta<>'' 
				then rtrim(convert(char(20),convert(decimal(14,2),1.00*@sumatva/@curs))) else '' end), 
			(case when @subtipm='AF' then @contcor when @tip='MT' then @ctamm else @contamcomprim end),
			@Valuta,@Curs,@Datafact,@Datascad,(case when @subtipm='AF' and @tiptva<>3 then @tiptva else 0 end),	
			(case when @subtipm='SU' and @urmrezreev=1 then @rezreev else 0 end),
			round(@valamcls8-(case when 90=0 and @tip='MT' then @amluncls8 else 0 end),2),
			round(@valam-@valamcls8-(case when 90=0 and @tip='MT' then @amlun-@amluncls8 else 0 end),2),
			(case @subtipm when 'AF' then right(@tip,1)+@subtip else '' end),@Jurnal)

		IF @tip='MT' and @subtip='SE' and 6/*@procinch*/=6 
			select @tipm='ME', @subtipm='SU'

		IF @tipm='ME' INSERT pozdoc
			(Subunitate,Tip,Numar,Cod,Data,Gestiune,Cantitate,Pret_valuta,Pret_de_stoc,Adaos,
			Pret_vanzare,Pret_cu_amanuntul,TVA_deductibil,Cota_TVA,Utilizator,Data_operarii,
			Ora_operarii,Cod_intrare,Cont_de_stoc,Cont_corespondent,TVA_neexigibil,
			Pret_amanunt_predator,Tip_miscare,Locatie,Data_expirarii,Numar_pozitie,Loc_de_munca,
			Comanda,Barcod,Cont_intermediar,Cont_venituri,Discount,Tert,Factura,
			Gestiune_primitoare,Numar_DVI,Stare,Grupa,Cont_factura,Valuta,Curs,Data_facturii,
			Data_scadentei,Procent_vama,Suprataxe_vama,Accize_cumparare,Accize_datorate,
			Contract,Jurnal)
			select @sub,@tipdocCG,@Numar,@Cod,@Data,@Gest,(case @tipdocCG when 'AI' then -1 else 1 end),
			(case when @valuta='' then @pret else @Pretvaluta end), 
			(case when @tipm='ME' and @subtipm='CS' and @tippatrim='1' or @tipm='ME' and @subtipm='SU' and @tert='AE' 
				or @tipdocCG='AI' or left(f.cont_mijloc_fix,1)='8' then f.valoare_de_inventar+(case when @tip='MT' and @subtip='SE' then @difvalinvMRE else 0 end) 
				else f.valoare_de_inventar-f.valoare_amortizata+f.valoare_amortizata_cont_8045
					-(case when @urmrezreev=1 and 90=0 and @subtipm<>'SU' 
					then f.cantitate else 0 end) end)-@difvalinv,
			(case when @subtipm='VI' and @valuta='' then round((@pret/f.valoare_de_inventar-1)*100,2) else 0 end),
			(case when @subtipm='VI' then @pret else 0 end),
			(case when @subtipm='VI' then @pret+@sumatva else 0 end),@sumatva,@cotatva,@userASiS,
			convert(datetime,convert(char(10),getdate(),104),104), 
			RTrim(replace(convert(char(8),getdate(),108),':','')),@nrinv,@contmf,--f.cont_mijloc_fix,
			@contcor,@cotatva,
			(case when @urmrezreev=1 and @subtipm='SU' and @ESUnoi=1 then 
				f.valoare_amortizata_cont_6871 else 0 end),
			(case when 0=0 then 'V' when @tipdocCG='AI' then 'I' else 'E' end),
			(case when @urmrezreev=1 and (@subtipm<>'SU' or @tert='AE') or 
				@urmvalist=1 and f.Valoare_de_inventar-f.Valoare_amortizata+
				(case when @Elcond=1 then 0 else f.Valoare_amortizata_cont_8045	end)<>0 
				then isnull(fa.cont_mijloc_fix,'') else '' end),
			@data,@nrpozitie,@lm,@com+replace(@indbug,'.',''), --f.loc_de_munca,f.comanda,
			(case when f.Valoare_amortizata_cont_8045<>0 then @cont8045 else '' end),'',
			(case when @urmrezreev=1 and @subtipm='SU' and @ESUnoi=1 and @tert<>'AE' then 
			isnull(fa.cont_mijloc_fix,'') when @subtipm='VI' then @contgestprim else '' end), 0, 
			(case when @urmrezreev=1 and @subtipm='SU' and @ESUnoi=1 and @tert<>'AE' then @contcor 
				when @subtipm='VI' then @tert else '' end),
			(case @subtipm when 'VI' then @fact else right(@tip,1)+@subtip end),
			(case when @tipdocCG='AI' then @contcor when @evidmfiesite=1 
				and left(f.cont_mijloc_fix,1)='8' and @subtipm='CS' then @contgestprim 
				else fct.contam end), --md.cod_de_clasificare
			(case when @tipdocCG<>'AI' then (case when @tipm='ME' and @subtipm='CS' and @tippatrim='1' then @ctrezrep 
				when @tipm='ME' and @subtipm='SU' and @tert='AE' then @contcor 
				when @evidmfiesite=1 and left(f.cont_mijloc_fix,1)='8' 
				and @subtipm='CS' then fct.contam else f.cont_mijloc_fix end) else '' end),	--md.cod_de_clasificare
			@Stare,(case @subtipm when 'VI' then (case when @conttva='' then @cttvacol 
				else @conttva end) else '' end), 
			(case when @subtipm='SU' and @tert='AE' then '' 
				when @tipdocCG='AI' then fct.contam	--md.cod_de_clasificare 
				when @subtipm='VI' then @contlmprim else @contgestprim end),
			@Valuta,@Curs,@Datafact,@Datascad,(case @subtipm when 'VI' then @tiptva else 0 end),
			(case when @urmrezreev=1 then f.cantitate*(case when @subtipm='SU' and @ESUnoi=1 and @tert<>'AE' then -1 else 1 end) 
				when @urmvalist=1 and f.Valoare_de_inventar-f.Valoare_amortizata
					+(case when @Elcond=1 then 0 else f.Valoare_amortizata_cont_8045 end)<>0
				and isnull(fa.Cont_mijloc_fix,'')<>'' then f.Valoare_de_inventar-f.Valoare_amortizata+
				(case when @Elcond=1 then 0 else f.valoare_amortizata_cont_8045 end)-
				(case when @subtipm='CS' then @pret else 0 end)-
				isnull(fa.Valoare_de_inventar,0)+ isnull(fa.valoare_amortizata,0)+ 
				isnull(fa.amortizare_lunara,0) else 0 end), 
			round((f.Valoare_amortizata_cont_8045-(case when 90=0 and @tip='MT' then f.Amortizare_lunara_cont_8045 
				else 0 end))*(case when @subtipm='SU' and @ESUnoi=1 and @tert<>'AE' then -1 else 1 end),2),
			round((case when @evidmfiesite=1 and left(f.cont_mijloc_fix,1)='8' and @subtipm='CS' then @difvalinv 
				when left(f.cont_mijloc_fix,1)<>'8' then (f.valoare_amortizata-f.valoare_amortizata_cont_8045+(case when @tip='MT' and @subtip='SE' then @difvalamMRE else 0 end)
				-(case when 90=0 and @tip='MT' then f.Amortizare_lunara-f.Amortizare_lunara_cont_8045 else 0 end))*
				(case when @subtipm='SU' and @ESUnoi=1 and @tert<>'AE' then -1 else 1 end) else 0 end),2),
			(case when @urmrezreev=1 and (@subtipm<>'SU' or @tert='AE') or @urmvalist=1 and 
				f.Valoare_de_inventar-f.Valoare_amortizata+(case when @Elcond=1 then 0 else 
				f.Valoare_amortizata_cont_8045 end)<>0 and isnull(fa.Cont_mijloc_fix,'')<>'' 
				then (case when @subtipm='SU' and @tert='AE' then @contcor else @ctrezrep end) else '' end),
			@Jurnal
			FROM fisamf f 
				LEFT outer join fisamf fa on (@urmvalist=1 or @urmrezreev=1) and 
					fa.subunitate=@sub and fa.numar_de_inventar=@nrinv and 
					fa.data_lunii_operatiei=(case when @urmvalist=1 then @datalantsauintr else @datal 
					end) and fa.felul_operatiei='A'
				LEFT outer join mfix md on md.subunitate='DENS' and md.Numar_de_inventar=@nrinv 
				LEFT outer join #fisamf_ct fct on fct.Numar_de_inventar=@nrinv 
			WHERE f.subunitate=@sub and f.numar_de_inventar=@nrinv and 
			f.data_lunii_operatiei=(case when @tip='MT' then @datalantsauintr else @datal end) --	Si totusi se pare ca trebuie transferata valoarea din luna anterioara.
					--Valoarea din luna curenta se va genera pe locul de munca primitor.
			and f.felul_operatiei=(case when @tip='MT' then '1' else '5' end)

		IF @tip='MM' 
			set @pretm=(case 
				when @subtip in ('MF','TO','TP') then (case when @subtip='MF' and @contmf=@contcor then 0 else isnull((select f.valoare_de_inventar from fisamf f 
					where f.subunitate=@sub and f.numar_de_inventar=@nrinv and f.data_lunii_operatiei=@datal and f.felul_operatiei='1'/*'4'*/),0) end) 
				when @subtip='EP' then @difvalinv-@pret+@sumatva 
				else @difvalinv-(case when @subtip='RE' then @ajust else 0 end)-(case when @subtip='RE' and @contlmprim<>'' then @pret else 0 end) end)
		IF @tip='MM' 
			INSERT pozdoc
				(Subunitate,Tip,Numar,Cod,Data,Gestiune,Cantitate,
				Pret_valuta,Pret_de_stoc,Adaos,Pret_vanzare,Pret_cu_amanuntul,
				TVA_deductibil,Cota_TVA,Utilizator,	Data_operarii,Ora_operarii,
				Cod_intrare,Cont_de_stoc,Cont_corespondent,TVA_neexigibil,Pret_amanunt_predator,Tip_miscare,
				Locatie,Data_expirarii,Numar_pozitie,Loc_de_munca,
				Comanda,Barcod,Cont_intermediar,Cont_venituri,Discount,Tert,Factura,Gestiune_primitoare,Numar_DVI,Stare,Grupa,Cont_factura,Valuta,Curs,Data_facturii,
				Data_scadentei,Procent_vama,Suprataxe_vama,Accize_cumparare,Accize_datorate,Contract,Jurnal,detalii)
			select @sub,@tipdocCG,@Numar,@Cod,@Data,@Gest,(case when @tipdocCG<>'AE' and @pretm<0 or @tipdocCG='AE' and @pretm>0 then -1 else 1 end),
			(case when @subtip='FF' then (case when @valuta='' then abs(@difvalinv) else abs(@Pretvaluta) end) else 0 end),abs(@Pretm),0,0,0,
			(case when @subtip='FF' then @sumatva else 0 end),@cotatva,@userASiS,convert(datetime,convert(char(10),getdate(),104),104), RTrim(replace(convert(char(8),getdate(),108),':','')),
			@nrinv,@contmf,	(case when @subtip='TO' then '' else @contcor end),	0,0,'V',
			(case when @reevcontab=1 and @subtip='EP' and @tipdocCG='AE' and 1=0 then @ct105 else '' end),@data,@nrpozitie,@lm,
			(case when @bugetari=1 and @com+replace(@indbug,'.','')='' then space(20)+isnull(cc.cont_strain,'') else @com+replace(@indbug,'.','') end),
			(case when @subtip<>'FF' and @subtip<>'MF' or f.valoare_amortizata_cont_8045<>0 and @subtip='TO' then @cont8045 else '' end),'',
			(case when @subtip in ('MF','TP') then @contamcomprim when @subtip='RE' and left(@tert,1)='7' then @tert 
				when @subtip='RE' then @contmf when @subtip='FF' then (case when @conttva='' then @cttvaded else @conttva end) else '' end),0,
			(case when @subtip in ('MF','TP') then (case when left(m.cod_de_clasificare,1)='7' 
				then rtrim(@ctchamnecorp)+(case when @anctmfchamnecorp=1 then substring(@contmf,3,1) when @anlmchamnecorp=1 then '.'+@lm else '' end) 
				else rtrim(@ctchamcorp)+(case when @anctmfchamcorp=1 then substring(@contmf,3,1) when @anlmchamcorp=1 then '.'+@lm else '' end) end) 
				when @subtip='RE' and left(@tert,1)='7' then @contmf when @subtip in ('FF','RE') then @tert else '' end),
			(case @subtip when 'FF' then @fact else right(@tip,1)+@subtip end),
			(case when @subtip<>'FF' then (case when @subtip='RE' and @contlmprim<>'' 
				and @contgestprim='' or @subtip='EP' then @contamcomprim when @subtip='MF' or @subtip='TO' or @subtip='TP' 
				then @contgestprim else @contcor end) else '' end),
			(case when @tipdocCG='AE' then @contmf/*f.cont_mijloc_fix*/ else '' end),@Stare,
			(case when @subtip='FF' and @valuta<>'' 
				then rtrim(convert(char(20),convert(decimal(14,2),1.00*@sumatva/@curs))) else '' end), 
			(case when @tipdocCG<>'AE' then (case when @subtip='TO' or @subtip='FF' then @contcor 
				when @subtip='RE' and @contgestprim<>'' then @contgestprim 
				when @subtip='RE' and @contlmprim<>'' then @contmf else @contamcomprim end) else '' end),
			@Valuta,@Curs,@Datafact,@Datascad,
			(case @subtip when 'FF' then @tiptva when 'MF' then @tipmf when 'TO' then 2 else 0 end),
			(case when @subtip='RE' then (case when left(@tert,1)='6' then -1 else 1 end)*@ajust 
				when @reevcontab=1 and @subtip='EP' and @tipdocCG='AE' and 1=0 then @difvalinv
				else 0 end), 
			(case when @subtip<>'FF' and @subtip<>'MF' or 
				f.valoare_amortizata_cont_8045<>0 and @subtip='TO' then (case @subtip when 'TO' then 
				-f.valoare_amortizata_cont_8045 else @sumatva end) else 0 end),
			round((case when @subtip<>'FF' and (@subtip<>'MF' or left(@contgestprim,1)<>'8') 
				then (case when @subtip in ('TO','TP') then f.valoare_amortizata-f.valoare_amortizata_cont_8045 
					when @subtip='MA' then -@sumatva 
					when @subtip='MF' then (case when @contamcomprim=@contgestprim then 0 
						--	tratat sa duca pe noul cont de amortizare valoarea amortizata anterioara. Amortizarea din luna este contata pe noul cont de amortizare.
						else f.valoare_amortizata-f.valoare_amortizata_cont_8045-@pret-(f.Amortizare_lunara-f.Amortizare_lunara_cont_8045) end) 
					else ((case when @subtip='RE' and @contgestprim<>'' /*and (m.tip_amortizare='1' or left(@contamcomprim,1)='8') */
						then @difvalinv+@sumatva else @pret end)-@sumatva)*(case when @subtip='EP' or @subtip='RE' 
						and @contlmprim<>'' and @contgestprim='' then -1 else 1 end) end) else 0 end),2),
			(case when @subtip='FF' then right(@tip,1)+@subtip when @subtip='TO' then fct.contam	--md.cod_de_clasificare 
				when @reevcontab=1 and @subtip='EP' and @tipdocCG='AE' and 1=0 then @ctrezrep
				when @subtip='RE' then @contlmprim else '' end), @Jurnal, @detaliiPozdoc
			FROM fisamf f /*LEFT outer join fisamf fa on (@urmvalist=1 or @urmrezreev=1) and 
			fa.subunitate=@sub and fa.numar_de_inventar=@nrinv and 
			fa.data_lunii_operatiei=(case when @urmvalist=1 then @datalantsauintr else @datal 
			end) and fa.felul_operatiei='A'*/
			LEFT join contcor cc on @bugetari=1 and cc.contcg=@contcor and cc.loc_de_munca=''
			LEFT outer join mfix m on m.subunitate=@sub and m.Numar_de_inventar=@nrinv 
			LEFT outer join mfix md on md.subunitate='DENS' and md.Numar_de_inventar=@nrinv 
			LEFT outer join #fisaMF_ct fct on fct.Numar_de_inventar=@nrinv 
			WHERE f.subunitate=@sub and f.numar_de_inventar=@nrinv and 
				f.data_lunii_operatiei=@datal and f.felul_operatiei='1'/*'4'*/
END
set CONTEXT_INFO 0x00
