--***
create procedure [dbo].[MFgendoc] @tip char(3),@numar char(8),@data datetime,@nrinvfiltru char(13)='', 
	@categmffiltru int=0, @lmfiltru char(9)='', @datasfconserv datetime='01/01/1902', @stergdoc int=1, 
	@gendoc int=1, @valinvfiltru float=1800, @tippatrimfiltru char(1)=null/*tip patrim. nu e tratat la 
	sterg., fiindca e fol. doar la gen. reev., care se face fara sterg.*/, 
	@procinch float=6, @contcor varchar(40)='', @contgestprim varchar(40)='', @contcheltajust varchar(40)='', 
	@contvenajust varchar(40)='', @reevfaradifam int=0, @reevfaraajust int=0
	/*, @contlmprim varchar(40)='', @contamcomprim char(40)='', 
	@indbugprim char(30)='', @pretvaluta float=0, @valuta char(3)='', @curs float=0, 
	@cotatva float=0, @tiptva int=0, @fact char(20)='', @datafact datetime='01/01/1901', 
	@patrim char(1)='', @cod char(20)='MIJLOC_FIX_MF'*/

as
/*
exec MFgendoc @tip='MRE', @numar='', @data='02/28/2009', @nrinvfiltru='1090MF', @categmffiltru=0, 
	@lmfiltru='', @datasfconserv='01/01/1902', @stergdoc=1, @gendoc=1, @valinvfiltru=1800, 
	@tippatrimfiltru=null, @procinch=6, @contcor='1052', @contgestprim='101', @contcheltajust='6813', 
	@contvenajust='7813', @reevfaradifam=0, @reevfaraajust=0
	--alter table pozincon disable trigger inconlunai --tr_ValidPozincon
select * from mismf where tip_miscare='mre' and Numar_de_inventar='1090MF'
select * from pozdoc where tip='ai' and cod_intrare='1090MF'
*/
declare @sub char(9), @bugetari int, @doccuIC int, @lunaimpl int,@anulimpl int, @dataimpl datetime, 
	@datal datetime, @felop char(1), @tipm char(2), @subtipm char(2), 
	@nrinv char(13), @categmf int, @lm char(9), @gest char(9), @com char(20), @indbug char(30), 
	@valinv float, @valam float, @valamcls8 float, @valamneded float, @amlun float, @amluncls8 float, 
	@amlunneded float, @durata int, @tipmf int, @contmf varchar(40), @nrluni int, @rezreev float, 
	@datapf datetime, @codclasif char(20), @tipam char(1), @tippatrim char(1), 
	@contam varchar(40), @contmfm varchar(40), @contnoumf varchar(40), @contnouam varchar(40), @contcham varchar(40), @tipmfm int, 
	@pret float, @tipdocCG char(2), @iddoc int, @nrdoc char(8), @tert char(13), 
	@ajust float, @difvalinv float, @difam float, @difamneded float, @difamcls8 float, 
	@difvalinvmodifant float, @difammodifant float, @difamnededmodifant float, 
	@difamcls8modifant float, @ipc float, @soldrezreev float, @ajustreevant float, 
	@contajustreevant varchar(40), @datareevant datetime, @contgestprimm varchar(40), @binar varbinary(128)

EXEC luare_date_par 'GE', 'SUBPRO', 0, 0, @sub output
EXEC luare_date_par 'GE', 'BUGETARI', @bugetari output, 0, ''
EXEC luare_date_par 'MF','INCONM', @doccuIC output, 0, ''
set @iddoc=0
if @numar='' EXEC luare_date_par 'MF','NRDOC', 0, @iddoc output, ''
set @lunaimpl=isnull((select max(val_numerica) from par where tip_parametru='MF' and 
	parametru='LUNAI'), 1)
set @anulimpl=isnull((select max(val_numerica) from par where tip_parametru='MF' and 
	parametru='ANULI'), 1901)
if @lunaimpl not between 1 and 12 or @anulimpl<=1901 
	set @dataimpl='01/31/1901'
else 
	set @dataimpl=dbo.eom(convert(datetime,str(@lunaimpl,2)+'/01/'+str(@anulimpl,4)))
SET @felop=(case 'M'+left(@tip,1) when 'MI' then '3' when 'MM' then '4' 
	when 'ME' then '5' when 'MT' then '6' when 'MC' then '7' when 'MS' then '8' else '9' end)
Set @procinch=(case when @tip='CON' then 100 when @doccuIC=0 or @tip='MTP' then 9 else @procinch end)
Select @datal=dbo.eom(@Data), @tipm='M'+LEFT(@tip,1), @subtipm=right(@tip,2), 
	@ajust=0, @difvalinv=0, @difam=0, @difamneded=0, @difamcls8=0, 
	@difvalinvmodifant=0, @difammodifant=0, @difamnededmodifant=0, @difamcls8modifant=0

if @stergdoc=1
Begin

	if @procinch=6 set @binar=cast('modificaredocdefinitivMF' as varbinary(128))
	if @procinch=6 set CONTEXT_INFO @binar
	if @procinch=6 SET @tipdocCG=(case @tipm when 'MI' then (case @subtipm when 'AF' then 'RM' else 
		'AI' end) when 'MM' then (case @subtipm when 'EP' then 'AE' when 'FF' then 'RM' else 'AI' end) 
		when 'ME' then (case @subtipm when 'SU' then 'AI' when 'VI' then 'AP' else 'AE' end) 
		when 'MT' then (case when @procinch=6 and @subtipm='SE' then 'AI' else '' end) 
		else '' end)
	if @procinch=6 /*and @tipm in ('MI','MM','ME','MT') */DELETE pozdoc 
		FROM pozdoc p
		--Left join mfix xd on @tip='MRE' and xd.Subunitate='DENS' and xd.Numar_de_inventar=p.Cod_intrare 
		Left join mismf m on m.Subunitate=@sub and m.numar_de_inventar=p.Cod_intrare 
			and m.Data_lunii_de_miscare=@datal and m.Tip_miscare=@tip and m.Numar_document=p.Numar 
			and (@tip='CON' and m.factura='GA' or @tip<>'EVI' and Data_sfarsit_conservare='01/01/1902') 
		/*LEFT outer join mismf mtp on @tip='MRE' and mtp.subunitate=p.subunitate 
			and mtp.Numar_de_inventar=p.Cod_intrare
			and mtp.tip_miscare='MTP' AND mtp.Data_miscarii=(select max(ma.Data_miscarii) 
			from mismf ma where ma.subunitate=p.subunitate and ma.Numar_de_inventar=p.Cod_intrare 
			and ma.tip_miscare='MTP' AND ma.Data_lunii_de_miscare<=@datal) */
		Left join fisamf f on f.Subunitate=@sub and f.numar_de_inventar=p.Cod_intrare 
			and data_lunii_operatiei=@datal and felul_operatiei='1'
		WHERE p.subunitate=@sub and tip=@tipdocCG and (@numar='' or numar=@numar) and data=@Data 
		and p.factura=@tip and (@nrinvfiltru='' or Cod_intrare=@nrinvfiltru) 
		--and (@tippatrimfiltru is null or isnull(mtp.tert,xd.tip_amortizare)=@tippatrimfiltru) 
		and (@categmffiltru=0 or categoria=@categmffiltru) and isnull(m.Tip_miscare,'')=@tip 
		and Jurnal='MFX' --and Numar_pozitie=@nrpozitie
	if @procinch=6 set CONTEXT_INFO 0x00

	DELETE FROM fisamf 
		WHERE subunitate=@sub and data_lunii_operatiei=@datal and felul_operatiei=@felop 
		and (@nrinvfiltru='' or numar_de_inventar=@nrinvfiltru) 
		and (@categmffiltru=0 or categoria=@categmffiltru)
		and exists (select 1 from misMF where subunitate=@sub and Data_lunii_de_miscare=@datal 
		and Tip_miscare=@tip and mismf.numar_de_inventar=fisaMF.numar_de_inventar 
		and (@tip='CON' and factura='GA' or @tip<>'EVI' and Data_sfarsit_conservare='01/01/1902')) 
		and not exists (select 1 from misMF where subunitate=@sub and Data_lunii_de_miscare=@datal 
		and left(Tip_miscare,1)=left(@tip,1) and mismf.numar_de_inventar=fisaMF.numar_de_inventar 
		and not (@tip='CON' and factura='GA' or @tip<>'EVI' and Data_sfarsit_conservare='01/01/1902')) 

	if @tip in ('MMF','MTO') update fisaMF set Cont_mijloc_fix=cont_corespondent, 
		Obiect_de_inventar=(case when @tip='MMF' then 0 else Obiect_de_inventar end)
		FROM fisaMF f
		Left join mismf m on m.Subunitate=@sub and m.numar_de_inventar=f.numar_de_inventar 
		and Data_lunii_de_miscare=@datal and Tip_miscare=@tip 
		and (@tip='CON' and factura='GA' or @tip<>'EVI' and Data_sfarsit_conservare='01/01/1902') 
		WHERE f.subunitate = @sub and (@nrinvfiltru='' or f.numar_de_inventar=@nrinvfiltru) 
		and (@categmffiltru=0 or categoria=@categmffiltru) and isnull(Tip_miscare,'') in ('MMF','MTO')

	if @tip in ('MMF','MTO') and @procinch<>3 update mfix set cod_de_clasificare=(case when @tip='MMF' 
		then Gestiune_primitoare else cod_de_clasificare /*(case when Subunitate_primitoare='' 
		then tert else Subunitate_primitoare end)*/ end), 
		serie=(case when @tip='MTO' then '' else Serie end)
		FROM mfix xd
		Left join mismf m on m.Subunitate=@sub and m.numar_de_inventar=xd.numar_de_inventar 
		and Data_lunii_de_miscare=@datal and Tip_miscare=@tip 
		and (@tip='CON' and factura='GA' or @tip<>'EVI' and Data_sfarsit_conservare='01/01/1902') 
		Left join fisamf f on f.Subunitate=@sub and f.numar_de_inventar=xd.numar_de_inventar 
		and data_lunii_operatiei=@datal and felul_operatiei='1'
		WHERE xd.subunitate = 'DENS' and (@nrinvfiltru='' or xd.numar_de_inventar=@nrinvfiltru) 
		and (@categmffiltru=0 or categoria=@categmffiltru) and isnull(Tip_miscare,'') in ('MMF','MTO')

	DELETE FROM mismf 
		WHERE subunitate=@sub and data_lunii_de_miscare=@datal and tip_miscare=@tip 
		and (@tip='CON' and factura='GA' or @tip<>'EVI' and Data_sfarsit_conservare='01/01/1902')
		and (@nrinvfiltru='' or numar_de_inventar=@nrinvfiltru) and (@categmffiltru=0 or exists (select 
		1 from fisamf where subunitate=@sub and fisaMF.numar_de_inventar=misMF.numar_de_inventar 
		and data_lunii_operatiei=@datal and felul_operatiei='1' and categoria=@categmffiltru)) 
	
End

if @gendoc=1
Begin

	EXEC MFcalclun @datal=@datal, @nrinv=@nrinvfiltru, @categmf=@categmffiltru, @lm=@lmfiltru

	declare cursorMFgendoc cursor for select f.Numar_de_inventar,Categoria,
		Loc_de_munca,Gestiune,left(Comanda,20),substring(Comanda,21,20),Valoare_de_inventar,
		Valoare_amortizata,Valoare_amortizata_cont_8045,Valoare_amortizata_cont_6871,
		Amortizare_lunara,Amortizare_lunara_cont_8045,Amortizare_lunara_cont_6871,Durata,
		Obiect_de_inventar,Cont_mijloc_fix,Numar_de_luni_pana_la_am_int,Cantitate,
		x.Data_punerii_in_functiune,isnull(f.Cont_amortizare,xd.Cod_de_clasificare),x.tip_amortizare,
		isnull(mtp.tert,xd.tip_amortizare),--daca nu se va fol. doar la reev., se va sterge "@tip='MRE'" de la "LEFT outer join mismf mtp"
		x.Cod_de_clasificare,f.Cont_cheltuieli
		FROM fisamf f
		Left join mfix x on x.Subunitate=f.subunitate and x.Numar_de_inventar=f.Numar_de_inventar 
		Left join mfix xd on xd.Subunitate='DENS' and xd.Numar_de_inventar=f.Numar_de_inventar 
		Left outer join mismf mtp on @tip='MRE' and mtp.subunitate=f.subunitate 
			and mtp.Numar_de_inventar=f.Numar_de_inventar 
			and mtp.tip_miscare='MTP' AND mtp.Data_miscarii=(select max(ma.Data_miscarii) 
			from mismf ma where ma.subunitate=f.subunitate and ma.Numar_de_inventar=f.Numar_de_inventar 
			and ma.tip_miscare='MTP' AND ma.Data_lunii_de_miscare<=@datal)
		WHERE f.subunitate=@sub and data_lunii_operatiei=@datal and felul_operatiei='1'
		and (@nrinvfiltru='' or f.numar_de_inventar=@nrinvfiltru) 
		and (@categmffiltru=0 or categoria=@categmffiltru) 
		and (@tippatrimfiltru is null or isnull(mtp.tert,xd.tip_amortizare)=@tippatrimfiltru) 
		and not exists (select 1 from mismf m where m.subunitate=@sub and m.Tip_miscare=@tip
			and m.Data_lunii_de_miscare=@datal and m.Numar_de_inventar=f.Numar_de_inventar) 
		and (@tip<>'MTO' or isnull(xd.serie,'')='' and valoare_de_inventar<=@valinvfiltru-0.01 
			and amortizare_lunara=0 and abs(valoare_amortizata-valoare_de_inventar)<0.01)
		and (@tip<>'MMF' or Obiect_de_inventar=0 and valoare_de_inventar<=@valinvfiltru-0.01)
		and (@tip<>'MRE' or x.Data_punerii_in_functiune<dbo.BOY(@data))
		order by f.Subunitate, f.Numar_de_inventar

	open cursorMFgendoc
	fetch next from cursorMFgendoc into @nrinv, @categmf, @lm, @gest, @com, @indbug, 
		@valinv, @valam, @valamcls8, @valamneded, @amlun, @amluncls8, @amlunneded, 
		@durata, @tipmf, @contmf, @nrluni, @rezreev, @datapf, @contam, @tipam, @tippatrim, @codclasif, @contcham
	while @@fetch_status=0
	begin
	if not exists (select 1 from fisamf where subunitate=@sub 
		and data_lunii_operatiei=@datal and felul_operatiei=@felop and numar_de_inventar=@nrinv) 
		INSERT into fisamf (Subunitate,Numar_de_inventar,Categoria,Data_lunii_operatiei,
		Felul_operatiei,Loc_de_munca,Gestiune,Comanda,Valoare_de_inventar,
		Valoare_amortizata,Valoare_amortizata_cont_8045,Valoare_amortizata_cont_6871,
		Amortizare_lunara,Amortizare_lunara_cont_8045,Amortizare_lunara_cont_6871,Durata,
		Obiect_de_inventar, Cont_mijloc_fix,Numar_de_luni_pana_la_am_int,Cantitate,Cont_amortizare,Cont_cheltuieli)
		values 
		(@sub, @nrinv, @categmf, @datal, @felop, @lm, @gest, @com,
		@valinv, @valam, @valamcls8, @valamneded, @amlun, @amluncls8, @amlunneded, 
		@durata, (case when @tip='MMF' then 1 else @tipmf end), @contmf, @nrluni, @rezreev, @contam, @contcham)

	/*if @tip='MRE' 
	begin
	end
	*/
	if @tip='MTO' set @contnoumf=isnull((select max(Val_alfanumerica) from par where tip_parametru='MF' 
		and parametru='C212'+(case @categmf when 22 then '3' when 23 then '4' when 24 then '5' 
		else '6' end)+'OBI'), '8035')
	if @tip='MMF' set @contnoumf=isnull((select max(Val_alfanumerica) from par where tip_parametru='MF' 
		and parametru='C212'+(case @categmf when 1 then '1' when 21 then '2' when 22 then '3' 
		when 23 then '4' when 24 then '5' when 3 then '6' when 8 then '8' else '9' end)+'OBC'), '')
	select @contnouam=@contam
	--if @tip='MMF' select @contnoumf='205', @contnouam='2805'
	
	if @tip in ('MMF','MTO') /*and @procinch<>3 */and not exists (select 1 from misMF where Subunitate=@sub 
		and Tip_miscare=@tip and Data_lunii_de_miscare=@datal and misMF.Numar_de_inventar=@nrinv)
		Update fisaMF set Cont_mijloc_fix=@contnoumf
		FROM fisamf f
		WHERE f.subunitate = @sub and f.numar_de_inventar=@nrinv and Data_lunii_operatiei=@datal 
		and Felul_operatiei/*<>'A'*/ in ('1',@felop)
		--and isnull(Tip_miscare,'') in ('MMF','MTO')

	if @tip in ('MMF','MTO') and @procinch<>3 and not exists (select 1 from misMF where Subunitate=@sub 
		and Tip_miscare=@tip and Data_lunii_de_miscare=@datal and misMF.Numar_de_inventar=@nrinv)
		Update mfix set cod_de_clasificare=(case when @tip='MMF' 
		then @contnouam /*@contamcomprim+replace(@indbugprim,'.','')*/ else cod_de_clasificare end), 
		serie=(case when @tip='MTO' then 'O' else Serie end)
		FROM mfix xd
		/*Left join mismf m on m.Subunitate=@sub and m.numar_de_inventar=x.numar_de_inventar 
		and Data_lunii_de_miscare=@datal and Tip_miscare=@tip 
		and (@tip='CON' and factura='GA' or @tip<>'EVI' and Data_sfarsit_conservare='01/01/1902') 
		Left join fisamf f on f.Subunitate=@sub and f.numar_de_inventar=x.numar_de_inventar 
		and data_lunii_operatiei=@datal and felul_operatiei='1'*/
		WHERE xd.subunitate = 'DENS' and xd.numar_de_inventar=@nrinv 
		--and isnull(Tip_miscare,'') in ('MMF','MTO')

	if isnull(@contcor,'')='' set @contcor=(case when @tip in ('MMF','MTO') then @contmf 
		else isnull(@contnoumf,'') end)
	select @contmfm=(case when @tip in ('MMF','MTO') then @contnoumf else @contmf end), 
		@pret=(case when @tip in ('MMF'/*,'MTO'*/) then 0 else @valinv end), 
		@tipmfm=(case when @tip in ('MMF'/*,'MTO'*/) then 1 else 0 end), 
		@nrdoc=(case when isnull(@numar,'')='' then 'MF'/*right(@tip,2)*/+'0' else @numar end)
	if isnull(@numar,'')='' /*and (@tip<>'MRE' or /*La MRE pt.a nu se sari nr. de doc. ar tb. mutata 
		formarea de mai jos a @iddoc si a @nrdoc in block-ul urmator care are cond.: */@ipc<>0 and 
		(@difvalinv<>0 or @difam<>0 or @difamcls8<>0 or @difamneded<>0))*/
	begin
			set @iddoc=(case when @iddoc>=999999 then 1 else @iddoc+1 end)
			set @nrdoc='MF'/*right(@tip,2)*/+convert(char(6),@iddoc/*convert(int,substring(@nrdoc,3,6))+1*/)
			--sa ramana dupa select-ul anterior
	end
	
	if isnull(@contgestprim,'')='' set @contgestprim=@contam
	
	if @tip='MRE' and @valinv>@valam and isnull((select top 1 Data_miscarii from misMF where 
				Subunitate=@sub and Tip_miscare='SCO' and Data_lunii_de_miscare<=@datal 
				and Numar_de_inventar=@nrinv order by Data_lunii_de_miscare desc),'01/01/1901')>=
			isnull((select top 1 Data_miscarii from misMF where Subunitate=@sub and Tip_miscare='CON' 
				and Data_lunii_de_miscare<=@datal and Numar_de_inventar=@nrinv 
				order by Data_lunii_de_miscare desc),'01/01/1901') 
		and LEFT(@codclasif,1)<>'7' and not exists (select 1 from misMF where Subunitate=@sub 
			and left(Tip_miscare,1)='E' and Data_lunii_de_miscare<=@datal and Numar_de_inventar=@nrinv)
		and not exists (select 1 from misMF where Subunitate=@sub and Tip_miscare='MRE' 
			and Data_lunii_de_miscare=@datal and Numar_de_inventar=@nrinv)
	begin
		set @datareevant=isnull((select top 1 ma.Data_lunii_de_miscare
			FROM mismf ma 
			WHERE ma.subunitate=@sub and ma.Numar_de_inventar=@nrinv
			and ma.tip_miscare='MRE' AND ma.Data_lunii_de_miscare<=dbo.bom(@data)-1
			order by subunitate, Data_lunii_de_miscare desc),(case when @datapf<@dataimpl then 
			(case when dbo.EOM(@datapf)>convert(datetime,'12/31/2003') then dbo.EOM(@datapf) else 
			convert(datetime,'12/31/2003') end) else dbo.EOM(@datapf) end))
		set @ipc=isnull((select Indice_total from MF_ipc where DATA=dbo.eom(@data) 
			and an=YEAR(@datareevant) and Luna=MONTH(@datareevant)),0)
		select @difvalinv=0,@difam=0,@difamcls8=0,@difamneded=0,--@indlunaultimeireev=0,
			@difvalinvmodifant=0,@difammodifant=0,@difamcls8modifant=0,@difamnededmodifant=0,@ajust=0
		--val.din modif.ant.
		select 
			@difam=@difam+ISNULL(sum(case when Data_lunii_de_miscare>=dbo.BOY(@data) 
				then 0 else round((f1u.amortizare_lunara-
				f1.amortizare_lunara)*(f1u.Numar_de_luni_pana_la_am_int-@nrluni+1)*
				Indice_total/100,0)-(f1u.amortizare_lunara-f1.amortizare_lunara)*
				(f1u.Numar_de_luni_pana_la_am_int-@nrluni+1) end),0),
			@difamneded=@difamneded+ISNULL(sum(case when Data_lunii_de_miscare>=dbo.BOY(@data) 
				then 0 else round((f1u.Amortizare_lunara_cont_6871-
				f1.Amortizare_lunara_cont_6871)*(f1u.Numar_de_luni_pana_la_am_int-@nrluni+1)*
				Indice_total/100,0)-(f1u.Amortizare_lunara_cont_6871-f1.amortizare_lunara_cont_6871)*
				(f1u.Numar_de_luni_pana_la_am_int-@nrluni+1) end),0),
			@difamcls8=@difamcls8+ISNULL(sum(case when Data_lunii_de_miscare>=dbo.BOY(@data) 
				then 0 else round((f1u.amortizare_lunara_cont_8045-
				f1.amortizare_lunara_cont_8045)*(f1u.Numar_de_luni_pana_la_am_int-@nrluni+1)*
				Indice_total/100,0)-(f1u.amortizare_lunara_cont_8045-f1.amortizare_lunara_cont_8045)*
				(f1u.Numar_de_luni_pana_la_am_int-@nrluni+1) end),0),
			@difammodifant=@difammodifant+ISNULL(sum((f1u.amortizare_lunara-
				f1.amortizare_lunara)*(f1u.Numar_de_luni_pana_la_am_int-@nrluni+1)),0),
			@difamnededmodifant=@difamnededmodifant+ISNULL(sum((f1u.amortizare_lunara_cont_6871-
				f1.amortizare_lunara_cont_6871)*(f1u.Numar_de_luni_pana_la_am_int-@nrluni+1)),0),
			@difamcls8modifant=@difamcls8modifant+ISNULL(sum((f1u.amortizare_lunara_cont_8045-
				f1.amortizare_lunara_cont_8045)*(f1u.Numar_de_luni_pana_la_am_int-@nrluni+1)),0)
			FROM mismf m 
			Left outer join fisaMF f1 on f1.Subunitate=m.Subunitate 
				and f1.Data_lunii_operatiei=m.Data_lunii_de_miscare
				and f1.Felul_operatiei='1' and f1.Numar_de_inventar=m.Numar_de_inventar
			Left outer join fisaMF f1u on f1u.Subunitate=m.Subunitate 
				and f1u.Data_lunii_operatiei=dbo.EOM(m.Data_lunii_de_miscare+1)
				and f1u.Felul_operatiei='1' and f1u.Numar_de_inventar=m.Numar_de_inventar
			Left join MF_ipc on data=dbo.eom(@data) and an=YEAR(m.Data_lunii_de_miscare) 
				and Luna=MONTH(m.Data_lunii_de_miscare)
			WHERE /*m.subunitate=@sub and */m.Numar_de_inventar=@nrinv
				and m.tip_miscare between 'M' and 'Mzz' AND m.Data_lunii_de_miscare between 
				(case when @datareevant<'12/01/2008' then dbo.eom(@datareevant)+1 
				else dbo.BOY(@datareevant) end)	and dbo.eom(@data)
			GROUP BY m.Data_lunii_de_miscare
		
		select 
			@difvalinv=@difvalinv+ISNULL(sum(case when Data_lunii_de_miscare>=dbo.BOY(@data) 
				then 0 else round((diferenta_de_valoare+(case when @bugetari=1 and Tip_miscare='MFF' 
				then TVA else 0 end))*Indice_total/100,0)-diferenta_de_valoare-(case when @bugetari=1 
				and Tip_miscare='MFF' then TVA else 0 end) end),0), 
			@difam=@difam+ISNULL(sum(case when Data_lunii_de_miscare>=dbo.BOY(@data) or 
				Tip_miscare='MFF' then 0 else round(pret*Indice_total/100,0)-pret end),0), 
			@difamcls8=@difamcls8+ISNULL(sum(case when Data_lunii_de_miscare>=dbo.BOY(@data) or 
				Tip_miscare='MFF' then 0 else round(tva*Indice_total/100,0)-tva end),0), 
			@difvalinvmodifant=@difvalinvmodifant+ISNULL(sum(diferenta_de_valoare+(case when 
				@bugetari=1 and Tip_miscare='MFF' then TVA else 0 end)),0),
			@difammodifant=@difammodifant+ISNULL(sum(case when Tip_miscare='MFF' then 0 
				else pret end),0),
			@difamcls8modifant=@difamcls8modifant+ISNULL(sum(case when Tip_miscare='MFF' then 0 
				else tva end),0)
			FROM mismf m 
			Left join MF_ipc on data=dbo.eom(@data) and an=YEAR(m.Data_lunii_de_miscare) 
				and Luna=MONTH(m.Data_lunii_de_miscare)
			WHERE /*m.subunitate=@sub and */m.Numar_de_inventar=@nrinv
				and m.tip_miscare between 'M' and 'Mzz' AND m.Data_lunii_de_miscare between 
				(case when @datareevant<'12/01/2008' then dbo.eom(@datareevant)+1 
				else dbo.BOY(@datareevant) end)	and dbo.eom(@data)
		
		set @difvalinv=@difvalinv+ROUND((@valinv-@difvalinvmodifant)*@ipc/100,0)-@valinv+
			@difvalinvmodifant

		if @reevfaradifam=0
		begin
			set @difam=@difam+ROUND((@valam-@difammodifant)*@ipc/100,0)-@valam+@difammodifant
			set @difamcls8=@difamcls8+ROUND((@valamcls8-@difamcls8modifant)*@ipc/100,0)-@valamcls8+
				@difamcls8modifant
			set @difamneded=@difamneded+ROUND((@valamneded-@difamnededmodifant)*@ipc/100,0)-@valamneded+
				@difamnededmodifant
		end
		
		if @reevfaradifam=1
			select @difam=0,@difamcls8=0,@difamneded=0,
				@difammodifant=0,@difamcls8modifant=0,@difamnededmodifant=0
		
		if @ipc<>0 and (@difvalinv<>0 or @difam<>0 or @difamcls8<>0 or @difamneded<>0)
		begin
			/*set @tippatrim=isnull((select top 1 tert from misMF where Subunitate=@sub 
				and Tip_miscare='MTP' and Data_lunii_de_miscare<=@datal 
				and Numar_de_inventar=@nrinv order by Data_lunii_de_miscare desc),
				isnull((select tip_amortizare from mfix where subunitate='DENS' 
				and Numar_de_inventar=@nrinv),''))
			*/
			if not(@tipam='1' OR @tippatrim='1') 
				set @soldrezreev=ISNULL((select sum(a.diferenta_de_valoare-a.pret-convert(float,(case 
					when charindex(',',factura)>0 or ISNUMERIC(factura)=0 then '0.00' else factura end))+
					a.tva) 
					FROM misMF a 
					WHERE a.subunitate=@sub and a.tip_miscare='MRE' and a.numar_de_inventar=@nrinv 
						and left(a.cont_corespondent,3)='105' /*like rtrim('105')+'%'*/),0)
				
			set @contajustreevant=isnull((select top 1 tert
				FROM mismf ma 
				WHERE ma.subunitate=@sub and ma.Numar_de_inventar=@nrinv
					and ma.tip_miscare='MRE' AND ma.Data_lunii_de_miscare<=dbo.bom(@data)-1
				order by subunitate, Data_lunii_de_miscare desc),'')
			
			set @ajustreevant=isnull((select top 1 convert(float,(case when charindex(',',factura)>0 or 
				ISNUMERIC(factura)=0 then '0.00' else factura end)) from misMF where Subunitate=@sub 
				and Tip_miscare='MRE' and Data_lunii_de_miscare<=dbo.bom(@data)-1 
				and Numar_de_inventar=@nrinv order by Subunitate, Data_lunii_de_miscare desc),0.00)
			
			set @ajust=(case when @reevfaraajust=1 then 0 else (case when @difvalinv>0 and 
				@ajustreevant<0 then (case when @difvalinv>ABS(@ajustreevant) then ABS(@ajustreevant) 
				else @difvalinv end) else (case when @soldrezreev>0 then @difvalinv+@soldrezreev-@difam
				else @difvalinv end) end) end)
			
			select @tert=(case when @difvalinv>0 and @ajustreevant<0 then @contvenajust/*@contmfm*/ 
				else @contcheltajust end), 
				@contgestprimm=(case when @tipam='1' or @tippatrim='1' then @contgestprim else '' end), 
				@difvalinv=round(@difvalinv,2), @difam=round(@difam,2), @difamcls8=round(@difamcls8,2), 
				@ajust=round(@ajust,2)
			
			if @doccuIC=1 and /*@tipm in ('MI','MM','ME','MT') and */@procinch=6 
					and not exists (select 1 from misMF where Subunitate=@sub and Tip_miscare=@tip 
						and Data_lunii_de_miscare=@datal and Numar_de_inventar=@nrinv) 
				EXEC MFscriupozdoc @tip=@tipm,@subtip=@subtipm,
					@numar=@nrdoc,@data=@data,@nrinv=@nrinv,@contcor=@contcor,@contgestprim=@contgestprimm,
					@contlmprim=''/*@contlmprim*/,@contamcomprim=@contnouam/*@contamcomprim*/,
					@indbugprim=''/*@indbugprim*/,@gest=@gest,@lm=@lm,@com=@com,@indbug=@indbug,
					@contmf=@contmfm,@conttva=''/*@conttva*/,@tipmf=@tipmfm,@tert=@tert,
					@fact=''/*@fact*/,@datafact=@data/*fact*/,@datascad=@data/*scad*/,@valinv=@valinv,
					@valam=@valam,@valamcls8=@valamcls8,@valamneded=@valamneded,@rezreev=@rezreev,
					@cotatva=0/*@cotatva*/,@sumatva=@difamcls8/*@sumatva*/,@tiptva=0/*@tiptva*/,
					@difvalinv=@difvalinv,@pret=@difam/*@pret*/,@ajust=@ajust,@pretvaluta=0/*@pretvaluta*/,
					@valuta=''/*@valuta*/,@curs=0/*@curs*/,@cod='MIJLOC_FIX_MF'/*@cod*/
	
			if not exists (select 1 from misMF where Subunitate=@sub and Tip_miscare=@tip 
					and Data_lunii_de_miscare=@datal and Numar_de_inventar=@nrinv)
				INSERT into mismf (Subunitate,Data_lunii_de_miscare,
					Numar_de_inventar,Tip_miscare,Numar_document,Data_miscarii,Tert,Factura,
					Pret,TVA,Cont_corespondent,Loc_de_munca_primitor,Gestiune_primitoare,
					Diferenta_de_valoare,Data_sfarsit_conservare,Subunitate_primitoare,Procent_inchiriere)
					values 
					(@sub, @datal, @nrinv, @tip, @nrdoc, @datal, 
					(case when @tipam='1' OR @tippatrim='1' then ''/*@tert*/ else (case when @difvalinv>0 
						and @ajustreevant<0 then @contvenajust else @contcheltajust end) end), 
					(case when @tipam='1' OR @tippatrim='1' then ''/*@fact*/ 
						else ltrim(convert(char(20),1.00*@ajust)) end), 
					@difam, @difamcls8, @contcor, ''/*@contlmprim*/, 
					(case when @tipam='1' OR @tippatrim='1' then @contgestprim else '' end), 
					@difvalinv, @datasfconserv, @contam, @procinch)

			UPDATE f4 set Valoare_de_inventar=f1.Valoare_de_inventar, 
				Valoare_amortizata=f1.Valoare_amortizata/*(select f.Valoare_amortizata from fisamf f where 
				f.subunitate=@sub and f.Numar_de_inventar= @nrinv and f.data_lunii_operatiei=@datal 
				and f.felul_operatiei='1')*/, 
				Valoare_amortizata_cont_8045=f1.Valoare_amortizata_cont_8045,
				Valoare_amortizata_cont_6871=f1.Valoare_amortizata_cont_6871, Cantitate=f1.Cantitate
				FROM fisaMF f4
				left join fisaMF f1 on f1.subunitate=@sub and f1.Numar_de_inventar= @nrinv 
					and f1.data_lunii_operatiei=@datal and f1.felul_operatiei='1'
				WHERE f4.subunitate=@sub and f4.data_lunii_operatiei=@datal 
					and f4.Numar_de_inventar=@nrinv and f4.Felul_operatiei='4'
				
			--modif.in fisamf
			UPDATE fisamf set Valoare_de_inventar=Valoare_de_inventar+@difvalinv,
				Valoare_amortizata=Valoare_amortizata+@difam,
				Valoare_amortizata_cont_8045=Valoare_amortizata_cont_8045+@difamcls8,
				Valoare_amortizata_cont_6871=Valoare_amortizata_cont_6871+@difamneded,
				Cantitate=Cantitate+@difvalinv-@difam+@difamcls8-@ajust
				WHERE subunitate=@sub and data_lunii_operatiei>=@datal and Numar_de_inventar=@nrinv
		end
	end
	
	select @difvalinv=round(@difvalinv,2), @difam=round(@difam,2), @difamcls8=round(@difamcls8,2), 
		@ajust=round(@ajust,2)
			
	if @tip<>'MRE' and @doccuIC=1 and /*@tipm in ('MI','MM','ME','MT') and */@procinch=6 
				and not exists (select 1 from misMF where Subunitate=@sub and Tip_miscare=@tip 
					and Data_lunii_de_miscare=@datal and Numar_de_inventar=@nrinv) 
			EXEC MFscriupozdoc @tip=@tipm,@subtip=@subtipm,
				@numar=@nrdoc,@data=@data,@nrinv=@nrinv,@contcor=@contcor,@contgestprim=@contgestprim,
				@contlmprim=''/*@contlmprim*/,@contamcomprim=@contnouam/*@contamcomprim*/,
				@indbugprim=''/*@indbugprim*/,@gest=@gest,@lm=@lm,@com=@com,@indbug=@indbug,
				@contmf=@contmfm,@conttva=''/*@conttva*/,@tipmf=@tipmfm,@tert=''/*@tert*/,
				@fact=''/*@fact*/,@datafact=@data/*fact*/,@datascad=@data/*scad*/,@valinv=@valinv,
				@valam=@valam,@valamcls8=@valamcls8,@valamneded=@valamneded,@rezreev=@rezreev,
				@cotatva=0/*@cotatva*/,@sumatva=0/*@sumatva*/,@tiptva=0/*@tiptva*/,@difvalinv=0/*@difvalinv*/,
				@pret=@pret,@ajust=0/*@ajust*/,@pretvaluta=0/*@pretvaluta*/,@valuta=''/*@valuta*/,
				@curs=0/*@curs*/,@cod='MIJLOC_FIX_MF'/*@cod*/
	
	if @tip<>'MRE' and not exists (select 1 from misMF where Subunitate=@sub and Tip_miscare=@tip 
				and Data_lunii_de_miscare=@datal and Numar_de_inventar=@nrinv)
			INSERT into mismf (Subunitate,Data_lunii_de_miscare,
				Numar_de_inventar,Tip_miscare,Numar_document,Data_miscarii,Tert,Factura,
				Pret,TVA,Cont_corespondent,Loc_de_munca_primitor,Gestiune_primitoare,
				Diferenta_de_valoare,Data_sfarsit_conservare,Subunitate_primitoare,Procent_inchiriere)
				values 
				(@sub, @datal, @nrinv, @tip, @nrdoc, @data, 
				''/*@tert*/, (case when @tip='CON' then 'GA' else ''/*@fact*/ end), 0/*@difam*/, 
				0/*@difamcls8*/, @contcor, ''/*@contlmprim*/, @contgestprim, 0/*@difvalinv*/, 
				@datasfconserv, (case when @tip='MTO' then '' when @tip='MMF' then @contnouam 
				else @contam/*@contamcomprim+replace(@indbugprim,'.','')*/ end), @procinch)

	fetch next from cursorMFgendoc into @nrinv, @categmf, @lm, @gest, @com, @indbug, 
		@valinv, @valam, @valamcls8, @valamneded, @amlun, @amluncls8, @amlunneded, 
		@durata, @tipmf, @contmf, @nrluni, @rezreev, @datapf, @contam, @tipam, @tippatrim, @codclasif, @contcham
	end
	
	close cursorMFgendoc
	deallocate cursorMFgendoc
	if @numar='' EXEC setare_par 'MF', 'NRDOC', 'NRDOC', 0, @iddoc, ''
End

EXEC MFcalclun @datal=@datal, @nrinv=@nrinvfiltru, @categmf=@categmffiltru, @lm=@lmfiltru
