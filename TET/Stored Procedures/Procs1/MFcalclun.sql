--***
create procedure [dbo].[MFcalclun] @datal datetime,@nrinv char(13),@categmf int, @lm char(9)
as
/*
	--exemplu de rulare
	exec MFcalclun @datal='2014-01-31',@nrinv='130001',@categmf=0, @lm=''
*/
declare @sub char(9), @RADJ int, @BRANTNER int, @urmvalist int, @reevcontab int, @lunainch int, @anulinch int, 
	@felop char(1), @lunaalfa char(20), @luna int, @anul int, @datalAnt datetime

exec luare_date_par 'GE', 'SUBPRO', 0, 0, @sub output
exec luare_date_par 'SP','RADJ', @RADJ output, 0, ''
exec luare_date_par 'SP','BRANTNER', @BRANTNER output, 0, ''
exec luare_date_par 'MF','URMVALIST', @urmvalist output, 0, ''
exec luare_date_par 'MF','MRECONTAB', @reevcontab output, 0, ''
exec luare_date_par 'MF','LUNAINCH', 0, @lunainch output, ''
exec luare_date_par 'MF','ANULINCH', 0, @anulinch output, ''
if @lunainch=0 exec luare_date_par 'MF','LUNAI', 0, @lunainch output, ''
if @anulinch=0 exec luare_date_par 'MF','ANULI', 0, @anulinch output, ''
if @lunainch=0 set @lunainch=month(@datal)
if @anulinch=0 set @anulinch=year(@datal)
set @lunaalfa=(select lunaalfa from dbo.fcalendar(@datal,@datal))
set @luna=month(@datal)
set @anul=year(@datal)
set @datalAnt=dbo.bom(@datal)-1

if @anul>@anulinch or @anul=@anulinch and @luna>@lunainch 
BEGIN
	exec MFimportdinCG @datal=@datal, @nrinvfiltru=@nrinv, @categmffiltru=@categmf, @lmfiltru=@lm
	--exec MFcalclun1 @datal,@nrinv,@categmf, @lm
	--stergeri din fisamf
	-- sterg cele care nu au numar de inventar in mfix
	DELETE from fisamf 
	where fisamf.subunitate=@sub and data_lunii_operatiei=@datal and felul_operatiei='1' 
		and (@nrinv='' or fisamf.numar_de_inventar=@nrinv) 
		and (@categmf=0 or categoria=@categmf) 
		and not exists (select 1 from mfix where mfix.subunitate=@sub and mfix.numar_de_inventar= fisamf.numar_de_inventar)
		and (@lm='' or fisaMF.Loc_de_munca like rtrim(@lm)+'%' or exists (select 1 from misMF mm where mm.Subunitate=fisaMF.Subunitate and mm.Data_lunii_de_miscare=fisaMF.Data_lunii_operatiei 
			and mm.Tip_miscare='TSE' and mm.Numar_de_inventar=fisaMF.Numar_de_inventar and mm.Loc_de_munca_primitor like rtrim(@lm)+'%'))
	
	DELETE from fisamf 
	where subunitate=@sub and data_lunii_operatiei=@datal and felul_operatiei='A' 
		and (@nrinv='' or numar_de_inventar=@nrinv) 
		and (@categmf=0 or categoria=@categmf) 
		and numar_de_inventar not in (select mismf.numar_de_inventar from mismf where mismf.subunitate=@sub and mismf.tip_miscare='ISU' and Data_lunii_de_miscare=@datal)
		and (@lm='' or fisaMF.Loc_de_munca like rtrim(@lm)+'%' or exists (select 1 from misMF mm where mm.Subunitate=fisaMF.Subunitate and mm.Data_lunii_de_miscare=fisaMF.Data_lunii_operatiei 
			and mm.Tip_miscare='TSE' and mm.Numar_de_inventar=fisaMF.Numar_de_inventar and mm.Loc_de_munca_primitor like rtrim(@lm)+'%'))
	
	-- sterg cele iesite deja
	DELETE from fisamf 
	where fisamf.subunitate=@sub and data_lunii_operatiei=@datal and felul_operatiei='1' 
		and (@nrinv='' or fisamf.numar_de_inventar=@nrinv) 
		and (@categmf=0 or categoria=@categmf) 
		and exists (select 1 from mismf where mismf.subunitate=@sub and left(mismf.tip_miscare,1)='E' and mismf.numar_de_inventar= fisamf.numar_de_inventar and Data_lunii_de_miscare<=@datalAnt)
		and (@lm='' or fisaMF.Loc_de_munca like rtrim(@lm)+'%' or exists (select 1 from misMF mm where mm.Subunitate=fisaMF.Subunitate and mm.Data_lunii_de_miscare=fisaMF.Data_lunii_operatiei 
			and mm.Tip_miscare='TSE' and mm.Numar_de_inventar=fisaMF.Numar_de_inventar and mm.Loc_de_munca_primitor like rtrim(@lm)+'%'))
	
	-- sterg linii de intrare care nu au corespondent in misMF
	DELETE from fisamf 
	where fisamf.subunitate=@sub and data_lunii_operatiei=@datal and felul_operatiei='3' 
		and (@nrinv='' or fisamf.numar_de_inventar=@nrinv) 
		and (@categmf=0 or categoria=@categmf) 
		and not exists (select 1 from mismf where mismf.subunitate=@sub and left(mismf.tip_miscare,1)='I' and mismf.numar_de_inventar= fisamf.numar_de_inventar)
		and (@lm='' or fisaMF.Loc_de_munca like rtrim(@lm)+'%' or exists (select 1 from misMF mm where mm.Subunitate=fisaMF.Subunitate and mm.Data_lunii_de_miscare=fisaMF.Data_lunii_operatiei 
			and mm.Tip_miscare='TSE' and mm.Numar_de_inventar=fisaMF.Numar_de_inventar and mm.Loc_de_munca_primitor like rtrim(@lm)+'%'))
	
	-- sterg linii de modificare care nu au corespondent in misMF
	DELETE from fisamf 
	where fisamf.subunitate=@sub and data_lunii_operatiei=@datal and felul_operatiei='4' 
		and (@nrinv='' or fisamf.numar_de_inventar=@nrinv) 
		and (@categmf=0 or categoria=@categmf) 
		and not exists (select 1 from mismf where mismf.subunitate=@sub and left(mismf.tip_miscare,1)='M' and mismf.numar_de_inventar= fisamf.numar_de_inventar)
		and (@lm='' or fisaMF.Loc_de_munca like rtrim(@lm)+'%' or exists (select 1 from misMF mm where mm.Subunitate=fisaMF.Subunitate and mm.Data_lunii_de_miscare=fisaMF.Data_lunii_operatiei 
			and mm.Tip_miscare='TSE' and mm.Numar_de_inventar=fisaMF.Numar_de_inventar and mm.Loc_de_munca_primitor like rtrim(@lm)+'%'))
	
	-- sterg linii de iesire care nu au corespondent in misMF
	DELETE from fisamf 
	where fisamf.subunitate=@sub and data_lunii_operatiei=@datal and felul_operatiei='5' 
		and (@nrinv='' or fisamf.numar_de_inventar=@nrinv) 
		and (@categmf=0 or categoria=@categmf) 
		and not exists (select 1 from mismf where mismf.subunitate=@sub and left(mismf.tip_miscare,1)='E' and mismf.numar_de_inventar= fisamf.numar_de_inventar)
		and (@lm='' or fisaMF.Loc_de_munca like rtrim(@lm)+'%' or exists (select 1 from misMF mm where mm.Subunitate=fisaMF.Subunitate and mm.Data_lunii_de_miscare=fisaMF.Data_lunii_operatiei 
			and mm.Tip_miscare='TSE' and mm.Numar_de_inventar=fisaMF.Numar_de_inventar and mm.Loc_de_munca_primitor like rtrim(@lm)+'%'))
	
	-- sterg linii de transfer care nu au corespondent in misMF
	DELETE from fisamf 
	where fisamf.subunitate=@sub and data_lunii_operatiei=@datal and felul_operatiei='6' 
		and (@nrinv='' or fisamf.numar_de_inventar=@nrinv) 
		and (@categmf=0 or categoria=@categmf) 
		and not exists (select 1 from mismf where mismf.subunitate=@sub and left(mismf.tip_miscare,1)='T' and mismf.numar_de_inventar= fisamf.numar_de_inventar)
		and (@lm='' or fisaMF.Loc_de_munca like rtrim(@lm)+'%' or exists (select 1 from misMF mm where mm.Subunitate=fisaMF.Subunitate and mm.Data_lunii_de_miscare=fisaMF.Data_lunii_operatiei 
			and mm.Tip_miscare='TSE' and mm.Numar_de_inventar=fisaMF.Numar_de_inventar and mm.Loc_de_munca_primitor like rtrim(@lm)+'%'))
	
	-- sterg linii de conservari/casari care nu au corespondent in misMF
	DELETE from fisamf 
	where fisamf.subunitate=@sub and data_lunii_operatiei=@datal and felul_operatiei='7' 
		and (@nrinv='' or fisamf.numar_de_inventar=@nrinv) 
		and (@categmf=0 or categoria=@categmf) 
		and not exists (select 1 from mismf where mismf.subunitate=@sub and left(mismf.tip_miscare,1)='C' and mismf.numar_de_inventar= fisamf.numar_de_inventar)
		and (@lm='' or fisaMF.Loc_de_munca like rtrim(@lm)+'%' or exists (select 1 from misMF mm where mm.Subunitate=fisaMF.Subunitate and mm.Data_lunii_de_miscare=fisaMF.Data_lunii_operatiei 
			and mm.Tip_miscare='TSE' and mm.Numar_de_inventar=fisaMF.Numar_de_inventar and mm.Loc_de_munca_primitor like rtrim(@lm)+'%'))
	
	DELETE from fisamf 
	where fisamf.subunitate=@sub and data_lunii_operatiei=@datal and felul_operatiei='8' 
		and (@nrinv='' or fisamf.numar_de_inventar=@nrinv) 
		and (@categmf=0 or categoria=@categmf) 
		and not exists (select 1 from mismf where mismf.subunitate=@sub and left(mismf.tip_miscare,1)='S' and mismf.numar_de_inventar= fisamf.numar_de_inventar)
		and (@lm='' or fisaMF.Loc_de_munca like rtrim(@lm)+'%' or exists (select 1 from misMF mm where mm.Subunitate=fisaMF.Subunitate and mm.Data_lunii_de_miscare=fisaMF.Data_lunii_operatiei 
			and mm.Tip_miscare='TSE' and mm.Numar_de_inventar=fisaMF.Numar_de_inventar and mm.Loc_de_munca_primitor like rtrim(@lm)+'%'))
	
	DELETE from fisamf 
	where fisamf.subunitate=@sub and data_lunii_operatiei=@datal and felul_operatiei='9' 
		and (@nrinv='' or fisamf.numar_de_inventar=@nrinv) 
		and (@categmf=0 or categoria=@categmf) 
		and not exists (select 1 from mismf where mismf.subunitate=@sub and left(mismf.tip_miscare,1)='B' and mismf.numar_de_inventar= fisamf.numar_de_inventar)
		and (@lm='' or fisaMF.Loc_de_munca like rtrim(@lm)+'%' or exists (select 1 from misMF mm where mm.Subunitate=fisaMF.Subunitate and mm.Data_lunii_de_miscare=fisaMF.Data_lunii_operatiei 
			and mm.Tip_miscare='TSE' and mm.Numar_de_inventar=fisaMF.Numar_de_inventar and mm.Loc_de_munca_primitor like rtrim(@lm)+'%'))

	set @felop='1'
	exec MFcalclun2 @datal,@nrinv,@categmf,@felop, @lm,0
	exec MFcalclun3 @datal,@nrinv,@categmf,@felop, @lm
	--exec MFcalclun4 @datal,@nrinv,@categmf,@felop, @lm
	--OB. INV., CONT
	UPDATE fisamf set fisamf.obiect_de_inventar=isnull( (select a.obiect_de_inventar from 
	fisamf a where a.subunitate=@sub and a.Numar_de_inventar= fisamf.Numar_de_inventar
	and a.data_lunii_operatiei=@datal and a.felul_operatiei=(case when @felop='1' then '4' else '1' end)), 
	isnull( (select b.obiect_de_inventar from fisamf b where b.subunitate=@sub 
	and b.Numar_de_inventar= fisamf.Numar_de_inventar
	and b.data_lunii_operatiei=@datalAnt and b.felul_operatiei=@felop), 
	(select c.obiect_de_inventar from fisamf c where c.subunitate=@sub 
	and c.Numar_de_inventar= fisamf.Numar_de_inventar
	and c.data_lunii_operatiei=@datal and c.felul_operatiei in ('2','3')))),
	FISAMF.CONT_MIJLOC_FIX=isnull( (select a.cont_mijloc_fix from fisamf a where 
	a.subunitate=@sub and a.Numar_de_inventar= fisamf.Numar_de_inventar
	and a.data_lunii_operatiei=@datal and a.felul_operatiei=(case when @felop='1' then '4' else '1' end)), 
	isnull( (select b.cont_mijloc_fix from fisamf b where b.subunitate=@sub 
	and b.Numar_de_inventar= fisamf.Numar_de_inventar
	and b.data_lunii_operatiei=@datalAnt and b.felul_operatiei=@felop), 
	(select c.cont_mijloc_fix from fisamf c where c.subunitate=@sub 
	and c.Numar_de_inventar= fisamf.Numar_de_inventar
	and c.data_lunii_operatiei=@datal and c.felul_operatiei in ('2','3'))))
	WHERE fisamf.subunitate=@sub and fisamf.data_lunii_operatiei=@datal 
	and fisamf.felul_operatiei=@felop and (@nrinv='' or fisamf.numar_de_inventar=@nrinv) 
	and (@categmf=0 or fisamf.categoria=@categmf) and (@felop<>'1' or fisamf.numar_de_inventar in 
	(select m.numar_de_inventar from mismf m where m.subunitate=@sub and left(m.tip_miscare,1)='M' 
	and m.Data_lunii_de_miscare=@datal /*and m.numar_de_inventar= fisamf.numar_de_inventar*/))
	and (@lm='' or fisaMF.Loc_de_munca like rtrim(@lm)+'%' or exists (select 1 from misMF mm where 
	mm.Subunitate=fisaMF.Subunitate and mm.Data_lunii_de_miscare=fisaMF.Data_lunii_operatiei 
	and mm.Tip_miscare='TSE' and mm.Numar_de_inventar=fisaMF.Numar_de_inventar 
	and mm.Loc_de_munca_primitor like rtrim(@lm)+'%'))

	UPDATE fisamf set fisamf.loc_de_munca= isnull( (select top 1 c.loc_de_munca_primitor from 
	mismf c where c.subunitate=@sub and c.Numar_de_inventar= fisamf.Numar_de_inventar 
	and c.data_lunii_de_miscare=@datal and c.tip_miscare='TSE' order by c.data_miscarii desc) 
	/*(select a.loc_de_munca from fisamf a where 
	a.subunitate=@sub and a.Numar_de_inventar= fisamf.Numar_de_inventar
	and a.data_lunii_operatiei=@datal and a.felul_operatiei='6')*/, 
	isnull( (select b.loc_de_munca from fisamf b where b.subunitate=@sub 
	and b.Numar_de_inventar= fisamf.Numar_de_inventar
	and b.data_lunii_operatiei=@datal and b.felul_operatiei in ('2','3')), 
	(select top 1 c.loc_de_munca from fisamf c where c.subunitate=@sub 
	and c.Numar_de_inventar= fisamf.Numar_de_inventar and c.data_lunii_operatiei<=@datalAnt 
	and c.felul_operatiei=@felop order by c.data_lunii_operatiei desc)))
	WHERE fisamf.subunitate=@sub and fisamf.data_lunii_operatiei=@datal 
	and fisamf.felul_operatiei in (@felop/*,'6'*/) and (@nrinv='' or fisamf.numar_de_inventar=@nrinv) 
	and (@categmf=0 or fisamf.categoria=@categmf) /*and (@felop<>'1' or fisamf.numar_de_inventar in 
	(select m.numar_de_inventar from mismf m where m.subunitate=@sub and left(m.tip_miscare,1)='T' 
	and m.Data_lunii_de_miscare=@datal /*and m.numar_de_inventar= fisamf.numar_de_inventar*/))*/
	and (@lm='' or fisaMF.Loc_de_munca like rtrim(@lm)+'%' or exists (select 1 from misMF mm where 
	mm.Subunitate=fisaMF.Subunitate and mm.Data_lunii_de_miscare=fisaMF.Data_lunii_operatiei 
	and mm.Tip_miscare='TSE' and mm.Numar_de_inventar=fisaMF.Numar_de_inventar 
	and mm.Loc_de_munca_primitor like rtrim(@lm)+'%'))

/*	S-a revenit la varianta initiala: pe pozitia cu felul operatiei=6 loc de munca=loc de munca predator (cel anterior)
	/*	pun in fisaMF pe felul operatiei=6 loc de munca=loc de munca primitor de pe TSE */
	UPDATE fisamf set fisamf.loc_de_munca= isnull( (select top 1 c.loc_de_munca_primitor from 
	mismf c where c.subunitate=@sub and c.Numar_de_inventar= fisamf.Numar_de_inventar 
	and c.data_lunii_de_miscare=@datal and c.tip_miscare='TSE' order by c.data_miscarii desc),fisaMF.Loc_de_munca)
	WHERE fisamf.subunitate=@sub and fisamf.data_lunii_operatiei=@datal 
	and fisamf.felul_operatiei in ('6') and (@nrinv='' or fisamf.numar_de_inventar=@nrinv) 
	and (@categmf=0 or fisamf.categoria=@categmf) 
	and (@lm='' or fisaMF.Loc_de_munca like rtrim(@lm)+'%' or exists (select 1 from misMF mm where 
	mm.Subunitate=fisaMF.Subunitate and mm.Data_lunii_de_miscare=fisaMF.Data_lunii_operatiei 
	and mm.Tip_miscare='TSE' and mm.Numar_de_inventar=fisaMF.Numar_de_inventar 
	and mm.Loc_de_munca_primitor like rtrim(@lm)+'%'))
*/
	UPDATE fisamf set fisamf.gestiune= isnull( (select top 1 c.gestiune_primitoare from mismf c where 
	c.subunitate=@sub and c.Numar_de_inventar= fisamf.Numar_de_inventar 
	and c.data_lunii_de_miscare=@datal and c.tip_miscare='TSE' order by c.data_miscarii desc) 
	/*(select a.gestiune from fisamf a where 
	a.subunitate=@sub and a.Numar_de_inventar= fisamf.Numar_de_inventar
	and a.data_lunii_operatiei=@datal and a.felul_operatiei='6')*/, 
	isnull( (select b.gestiune from fisamf b where b.subunitate=@sub 
	and b.Numar_de_inventar= fisamf.Numar_de_inventar
	and b.data_lunii_operatiei=@datal and b.felul_operatiei in ('2','3')), 
	(select top 1 c.gestiune from fisamf c where c.subunitate=@sub 
	and c.Numar_de_inventar= fisamf.Numar_de_inventar and c.data_lunii_operatiei<=@datalAnt 
	and c.felul_operatiei=@felop order by c.data_lunii_operatiei desc)))
	WHERE fisamf.subunitate=@sub and fisamf.data_lunii_operatiei=@datal 
	and fisamf.felul_operatiei in (@felop/*,'6'*/) and (@nrinv='' or fisamf.numar_de_inventar=@nrinv) 
	and (@categmf=0 or fisamf.categoria=@categmf) /*and (@felop<>'1' or fisamf.numar_de_inventar in 
	(select m.numar_de_inventar from mismf m where m.subunitate=@sub and left(m.tip_miscare,1)='T' 
	and m.Data_lunii_de_miscare=@datal /*and m.numar_de_inventar= fisamf.numar_de_inventar*/))*/
	and (@lm='' or fisaMF.Loc_de_munca like rtrim(@lm)+'%' or exists (select 1 from misMF mm where 
	mm.Subunitate=fisaMF.Subunitate and mm.Data_lunii_de_miscare=fisaMF.Data_lunii_operatiei 
	and mm.Tip_miscare='TSE' and mm.Numar_de_inventar=fisaMF.Numar_de_inventar 
	and mm.Loc_de_munca_primitor like rtrim(@lm)+'%'))

	UPDATE fisamf set fisamf.comanda= isnull( (select top 1 convert(char(40),c.subunitate_primitoare) 
	/*am fol. convert(char(40) pt. ca subunitate_primitoare poate sa aiba lung. mai mica decat 
	fisamf.comanda*/from mismf c where c.subunitate=@sub 
	and c.Numar_de_inventar= fisamf.Numar_de_inventar 
	and c.data_lunii_de_miscare=@datal and c.tip_miscare='TSE' order by c.data_miscarii desc) 
	/*(select a.comanda from fisamf a where 
	a.subunitate=@sub and a.Numar_de_inventar= fisamf.Numar_de_inventar
	and a.data_lunii_operatiei=@datal and a.felul_operatiei='6')*/, 
	isnull( (select b.comanda from fisamf b where b.subunitate=@sub 
	and b.Numar_de_inventar= fisamf.Numar_de_inventar
	and b.data_lunii_operatiei=@datal and b.felul_operatiei in ('2','3')), 
	(select top 1 c.comanda from fisamf c where c.subunitate=@sub 
	and c.Numar_de_inventar= fisamf.Numar_de_inventar and c.data_lunii_operatiei<=@datalAnt 
	and c.felul_operatiei=@felop order by c.data_lunii_operatiei desc)))
	WHERE fisamf.subunitate=@sub and fisamf.data_lunii_operatiei=@datal 
	and fisamf.felul_operatiei in (@felop/*,'6'*/) and (@nrinv='' or fisamf.numar_de_inventar=@nrinv) 
	and (@categmf=0 or fisamf.categoria=@categmf) /*and (@felop<>'1' or fisamf.numar_de_inventar in 
	(select m.numar_de_inventar from mismf m where m.subunitate=@sub and left(m.tip_miscare,1)='T' 
	and m.Data_lunii_de_miscare=@datal /*and m.numar_de_inventar= fisamf.numar_de_inventar*/))*/
	and (@lm='' or fisaMF.Loc_de_munca like rtrim(@lm)+'%' or exists (select 1 from misMF mm where 
	mm.Subunitate=fisaMF.Subunitate and mm.Data_lunii_de_miscare=fisaMF.Data_lunii_operatiei 
	and mm.Tip_miscare='TSE' and mm.Numar_de_inventar=fisaMF.Numar_de_inventar 
	and mm.Loc_de_munca_primitor like rtrim(@lm)+'%'))

	UPDATE fisamf set fisamf.Cont_amortizare= isnull( (select top 1 convert(char(40),c.subunitate_primitoare) 
	from mismf c where c.subunitate=@sub 
	and c.Numar_de_inventar=fisamf.Numar_de_inventar 
	and c.data_lunii_de_miscare=@datal and c.tip_miscare in ('MMF','MTP') and c.Procent_inchiriere<>3 order by c.data_miscarii desc), 
	isnull( (select b.Cont_amortizare from fisamf b where b.subunitate=@sub 
	and b.Numar_de_inventar= fisamf.Numar_de_inventar
	and b.data_lunii_operatiei=@datal and b.felul_operatiei in ('2','3')), 
	(select top 1 c.Cont_amortizare from fisamf c where c.subunitate=@sub 
	and c.Numar_de_inventar=fisamf.Numar_de_inventar and c.data_lunii_operatiei<=@datalAnt 
	and c.felul_operatiei=@felop order by c.data_lunii_operatiei desc)))
	WHERE fisamf.subunitate=@sub and fisamf.data_lunii_operatiei=@datal 
	and fisamf.felul_operatiei in (@felop) and (@nrinv='' or fisamf.numar_de_inventar=@nrinv) 
	and (@categmf=0 or fisamf.categoria=@categmf) 
	and (@lm='' or fisaMF.Loc_de_munca like rtrim(@lm)+'%' or exists (select 1 from misMF mm where 
	mm.Subunitate=fisaMF.Subunitate and mm.Data_lunii_de_miscare=fisaMF.Data_lunii_operatiei 
	and mm.Tip_miscare='TSE' and mm.Numar_de_inventar=fisaMF.Numar_de_inventar 
	and mm.Loc_de_munca_primitor like rtrim(@lm)+'%'))

	UPDATE fisamf set fisamf.Cont_cheltuieli = isnull(nullif((select top 1 convert(char(40),c.factura) 
	from mismf c where c.subunitate=@sub 
	and c.Numar_de_inventar=fisamf.Numar_de_inventar 
	and c.data_lunii_de_miscare=@datal and c.tip_miscare='MMF' and c.Procent_inchiriere<>3 order by c.data_miscarii desc),''), 
	isnull((select b.Cont_cheltuieli from fisamf b where b.subunitate=@sub 
	and b.Numar_de_inventar= fisamf.Numar_de_inventar
	and b.data_lunii_operatiei=@datal and b.felul_operatiei in ('2','3')), 
	(select top 1 c.Cont_cheltuieli from fisamf c where c.subunitate=@sub 
	and c.Numar_de_inventar=fisamf.Numar_de_inventar and c.data_lunii_operatiei<=@datalAnt 
	and c.felul_operatiei=@felop order by c.data_lunii_operatiei desc)))
	WHERE fisamf.subunitate=@sub and fisamf.data_lunii_operatiei=@datal 
	and fisamf.felul_operatiei in (@felop) and (@nrinv='' or fisamf.numar_de_inventar=@nrinv) 
	and (@categmf=0 or fisamf.categoria=@categmf) 
	and (@lm='' or fisaMF.Loc_de_munca like rtrim(@lm)+'%' or exists (select 1 from misMF mm where 
	mm.Subunitate=fisaMF.Subunitate and mm.Data_lunii_de_miscare=fisaMF.Data_lunii_operatiei 
	and mm.Tip_miscare='TSE' and mm.Numar_de_inventar=fisaMF.Numar_de_inventar 
	and mm.Loc_de_munca_primitor like rtrim(@lm)+'%'))

	if @urmvalist=1 or @reevcontab=1 set @felop='A'
	if @reevcontab=1 exec MFcalclun2 @datal,@nrinv,@categmf,@felop, @lm,0
	
	set @felop='1'
	--exec MFcalclun5 @datal,@nrinv,@categmf,@felop, @lm

	--6871 - NU AM MAI TRATAT GRADUL DE UTILIZ...
	UPDATE fisamf set Amortizare_lunara_cont_6871=0
	WHERE @felop='1' and fisamf.subunitate=@sub and fisamf.data_lunii_operatiei=@datal and fisamf.felul_operatiei=@felop 
		and (@nrinv='' or fisamf.numar_de_inventar=@nrinv) 
		and (@categmf=0 or fisamf.categoria=@categmf) 
		and fisamf.data_lunii_operatiei<= (select top 1 y.data_sfarsit_conservare from mismf y where y.subunitate=@sub and y.tip_miscare='CON' and y.Data_lunii_de_miscare<=@datal and y.numar_de_inventar= fisamf.numar_de_inventar order by y.Data_sfarsit_conservare desc) 
		and fisamf.numar_de_inventar not in (select m.numar_de_inventar from mismf m where m.subunitate=@sub and left(m.tip_miscare,1)='I' and m.Data_lunii_de_miscare=@datal /*and m.numar_de_inventar= fisamf.numar_de_inventar*/)
		and (@lm='' or fisaMF.Loc_de_munca like rtrim(@lm)+'%' 
			or exists (select 1 from misMF mm where mm.Subunitate=fisaMF.Subunitate and mm.Data_lunii_de_miscare=fisaMF.Data_lunii_operatiei and mm.Tip_miscare='TSE' and mm.Numar_de_inventar=fisaMF.Numar_de_inventar and mm.Loc_de_munca_primitor like rtrim(@lm)+'%'))

	--6871 pt. urmarire rezerva din reev.
	if @RADJ=0 and @BRANTNER=0
	UPDATE fisamf set Amortizare_lunara_cont_6871= round(convert(decimal(17,5),Amortizare_lunara 
		- isnull((select a.Amortizare_lunara from fisamf a where a.subunitate=@sub and a.Numar_de_inventar= fisamf.Numar_de_inventar and a.data_lunii_operatiei=@datal and a.felul_operatiei='A'), fisamf.Amortizare_lunara)),2)
	WHERE @reevcontab=1 and fisamf.subunitate=@sub and fisamf.data_lunii_operatiei=@datal 
		and fisamf.felul_operatiei=@felop and (@nrinv='' or fisamf.numar_de_inventar=@nrinv) 
		and (@categmf=0 or fisamf.categoria=@categmf) 
		and fisamf.numar_de_inventar not in (select m.numar_de_inventar from mismf m where m.subunitate=@sub and left(m.tip_miscare,1)='I' and m.Data_lunii_de_miscare=@datal /*and m.numar_de_inventar= fisamf.numar_de_inventar*/)
		and (@lm='' or fisaMF.Loc_de_munca like rtrim(@lm)+'%' 
			or exists (select 1 from misMF mm where mm.Subunitate=fisaMF.Subunitate and mm.Data_lunii_de_miscare=fisaMF.Data_lunii_operatiei and mm.Tip_miscare='TSE' and mm.Numar_de_inventar=fisaMF.Numar_de_inventar and mm.Loc_de_munca_primitor like rtrim(@lm)+'%'))
	
	--6871 pt. autoturisme (codcl. 2.3.2.1.1.) cu am. luna peste 1500 lei incepand cu 01.02.2013 (Ghita, 20.03.2013)
	UPDATE fisamf set Amortizare_lunara_cont_6871= (case when Amortizare_lunara>1500 then Amortizare_lunara - 1500 else 0 end)
	from fisamf, mfix m
	WHERE @datal >'2013-02-01' and fisamf.subunitate=@sub and fisamf.data_lunii_operatiei=@datal 
		and fisamf.felul_operatiei=@felop and (@nrinv='' or fisamf.numar_de_inventar=@nrinv) 
		and (@categmf=0 or fisamf.categoria=@categmf) 
		and m.subunitate=fisamf.subunitate and m.Numar_de_inventar=fisamf.numar_de_inventar 
		and m.Cod_de_clasificare='2.3.2.1.1.'  
		and (@lm='' or fisaMF.Loc_de_munca like rtrim(@lm)+'%' 
			or exists (select 1 from misMF mm where mm.Subunitate=fisaMF.Subunitate and mm.Data_lunii_de_miscare=fisaMF.Data_lunii_operatiei and mm.Tip_miscare='TSE' and mm.Numar_de_inventar=fisaMF.Numar_de_inventar and mm.Loc_de_munca_primitor like rtrim(@lm)+'%'))
	
	-- zerorizare rezerva daca rezulta negativa (Ghita, 01.03.2013 - oare e bine?)
	if @RADJ=0 and @BRANTNER=0 
	UPDATE fisamf set Amortizare_lunara_cont_6871= 0
	WHERE Amortizare_lunara_cont_6871<0
		and @reevcontab=1 and fisamf.subunitate=@sub and fisamf.data_lunii_operatiei=@datal 
		and fisamf.felul_operatiei=@felop and (@nrinv='' or fisamf.numar_de_inventar=@nrinv) 
		and (@categmf=0 or fisamf.categoria=@categmf) and fisamf.numar_de_inventar not in (select m.numar_de_inventar from mismf m where m.subunitate=@sub and left(m.tip_miscare,1)='I' 
			and m.Data_lunii_de_miscare=@datal /*and m.numar_de_inventar= fisamf.numar_de_inventar*/)
		and (@lm='' or fisaMF.Loc_de_munca like rtrim(@lm)+'%' 
			or exists (select 1 from misMF mm where mm.Subunitate=fisaMF.Subunitate and mm.Data_lunii_de_miscare=fisaMF.Data_lunii_operatiei and mm.Tip_miscare='TSE' and mm.Numar_de_inventar=fisaMF.Numar_de_inventar and mm.Loc_de_munca_primitor like rtrim(@lm)+'%'))
	
	UPDATE fisamf set Valoare_amortizata_cont_6871= round(convert(decimal(17,5),Valoare_amortizata_cont_6871+Amortizare_lunara_cont_6871),2)
	WHERE /*@felop='1' and */fisamf.subunitate=@sub and fisamf.data_lunii_operatiei=@datal 
	and fisamf.felul_operatiei=@felop and (@nrinv='' or fisamf.numar_de_inventar=@nrinv) 
	and (@categmf=0 or fisamf.categoria=@categmf) and fisamf.numar_de_inventar not in (select m.numar_de_inventar from mismf m where m.subunitate=@sub and left(m.tip_miscare,1)='I' and m.Data_lunii_de_miscare=@datal /*and m.numar_de_inventar= fisamf.numar_de_inventar*/)
	and (@lm='' or fisaMF.Loc_de_munca like rtrim(@lm)+'%' or exists (select 1 from misMF mm where mm.Subunitate=fisaMF.Subunitate and mm.Data_lunii_de_miscare=fisaMF.Data_lunii_operatiei 
		and mm.Tip_miscare='TSE' and mm.Numar_de_inventar=fisaMF.Numar_de_inventar and mm.Loc_de_munca_primitor like rtrim(@lm)+'%'))

	--8045
	UPDATE fisamf set Amortizare_lunara_cont_8045=0
	WHERE fisamf.subunitate=@sub and fisamf.data_lunii_operatiei=@datal 
	and fisamf.felul_operatiei=@felop and (@nrinv='' or fisamf.numar_de_inventar=@nrinv) 
	and (@categmf=0 or fisamf.categoria=@categmf) and fisamf.numar_de_inventar not in (select 
	m.numar_de_inventar from mismf m where m.subunitate=@sub and left(m.tip_miscare,1)='I' 
	and m.Data_lunii_de_miscare=@datal /*and m.numar_de_inventar= fisamf.numar_de_inventar*/)
	and (@lm='' or fisaMF.Loc_de_munca like rtrim(@lm)+'%' or exists (select 1 from misMF mm where 
	mm.Subunitate=fisaMF.Subunitate and mm.Data_lunii_de_miscare=fisaMF.Data_lunii_operatiei 
	and mm.Tip_miscare='TSE' and mm.Numar_de_inventar=fisaMF.Numar_de_inventar 
	and mm.Loc_de_munca_primitor like rtrim(@lm)+'%'))

	UPDATE fisamf set Amortizare_lunara_cont_8045= round(convert(decimal(17,5),amortizare_lunara),2)
	WHERE fisamf.subunitate=@sub and fisamf.data_lunii_operatiei=@datal 
	and fisamf.felul_operatiei=@felop and (@nrinv='' or fisamf.numar_de_inventar=@nrinv) 
	and (@categmf=0 or fisamf.categoria=@categmf) and (isnull((select top 1 y.tert from mismf y where 
	y.subunitate=@sub and y.tip_miscare='MTP' and y.Data_lunii_de_miscare<=@datal 
	and y.numar_de_inventar= fisamf.numar_de_inventar order by y.Data_lunii_de_miscare desc),(select 
	tip_amortizare from mfix x where x.subunitate='DENS' and x.numar_de_inventar=fisamf.numar_de_inventar))='1' 
	--daca in luna curenta este o trecere in Privat, inseamna ca anterior mijlocul fix a fost in patrimoniu public si valorile lunii curente sunt inregistrate in patrimoniu public
	or (select top 1 y.tert from mismf y where y.subunitate=@sub and y.tip_miscare='MTP' and y.Data_lunii_de_miscare=@datal 
		and y.numar_de_inventar= fisamf.numar_de_inventar order by y.Data_lunii_de_miscare desc)=''
	or fisamf.data_lunii_operatiei<=(select top 1 y.data_sfarsit_conservare from mismf y where y.subunitate=@sub and y.tip_miscare='CON' 
		and y.Data_lunii_de_miscare<=@datal and y.numar_de_inventar= fisamf.numar_de_inventar order by 
		y.Data_sfarsit_conservare desc)) and fisamf.numar_de_inventar not in (select m.numar_de_inventar 
	from mismf m where m.subunitate=@sub and left(m.tip_miscare,1)='I' 
	and m.Data_lunii_de_miscare=@datal /*and m.numar_de_inventar= fisamf.numar_de_inventar*/)
	and (@lm='' or fisaMF.Loc_de_munca like rtrim(@lm)+'%' or exists (select 1 from misMF mm where 
	mm.Subunitate=fisaMF.Subunitate and mm.Data_lunii_de_miscare=fisaMF.Data_lunii_operatiei 
	and mm.Tip_miscare='TSE' and mm.Numar_de_inventar=fisaMF.Numar_de_inventar 
	and mm.Loc_de_munca_primitor like rtrim(@lm)+'%'))

	UPDATE fisamf set valoare_amortizata_cont_8045= 
	round(convert(decimal(17,5),valoare_amortizata_cont_8045+amortizare_lunara_cont_8045 
		+ isnull((select sum(round(convert(decimal(17,5),m.tva),2)) from mismf m where m.subunitate=@sub and m.tip_miscare in ('MEP','MMA','MAL') and m.Data_lunii_de_miscare=@datal and m.numar_de_inventar=fisamf.numar_de_inventar),0)
		+ isnull((select round(convert(decimal(17,5),n.tva),2) from mismf n where /*n.subunitate=@sub and */n.tip_miscare='MRE' and n.Data_lunii_de_miscare=@datal and n.numar_de_inventar= fisamf.numar_de_inventar),0)),2)
	WHERE fisamf.subunitate=@sub and fisamf.data_lunii_operatiei=@datal 
	and fisamf.felul_operatiei=@felop and (@nrinv='' or fisamf.numar_de_inventar=@nrinv) 
	and (@categmf=0 or fisamf.categoria=@categmf) and fisamf.numar_de_inventar not in (select 
	m.numar_de_inventar from mismf m where m.subunitate=@sub and left(m.tip_miscare,1)='I' 
	and m.Data_lunii_de_miscare=@datal /*and m.numar_de_inventar= fisamf.numar_de_inventar*/)
	and (@lm='' or fisaMF.Loc_de_munca like rtrim(@lm)+'%' or exists (select 1 from misMF mm where 
	mm.Subunitate=fisaMF.Subunitate and mm.Data_lunii_de_miscare=fisaMF.Data_lunii_operatiei 
	and mm.Tip_miscare='TSE' and mm.Numar_de_inventar=fisaMF.Numar_de_inventar 
	and mm.Loc_de_munca_primitor like rtrim(@lm)+'%'))
	
	if @urmvalist=1 or @reevcontab=1 
	begin
		set @felop='A'
		exec MFcalclun2 @datal,@nrinv,@categmf,@felop, @lm,1
		exec MFcalclun3 @datal,@nrinv,@categmf,@felop, @lm
	end
	
	set @felop='1'
	--6871 pt. urmarire rezerva din reev. BRANTNER. Daca am mutat aici calculul rezervei din reevaluare a rezultat corect nota contabila 105 cu 1065.
	if @BRANTNER=1
	UPDATE fisamf set Amortizare_lunara_cont_6871= round(convert(decimal(17,5),Amortizare_lunara 
		- isnull((select a.Amortizare_lunara from fisamf a where a.subunitate=@sub and a.Numar_de_inventar= fisamf.Numar_de_inventar and a.data_lunii_operatiei=@datal and a.felul_operatiei='A'), fisamf.Amortizare_lunara)),2)
	from fisamf, mfix m
	WHERE @reevcontab=1 and fisamf.subunitate=@sub and fisamf.data_lunii_operatiei=@datal 
		and fisamf.felul_operatiei=@felop and (@nrinv='' or fisamf.numar_de_inventar=@nrinv) 
		and (@categmf=0 or fisamf.categoria=@categmf) 
		and m.subunitate=fisamf.subunitate and m.Numar_de_inventar=fisamf.numar_de_inventar and m.Cod_de_clasificare<>'2.3.2.1.1.'  
		and fisamf.numar_de_inventar not in (select m.numar_de_inventar from mismf m where m.subunitate=@sub and left(m.tip_miscare,1)='I' and m.Data_lunii_de_miscare=@datal /*and m.numar_de_inventar= fisamf.numar_de_inventar*/)
		and (@lm='' or fisaMF.Loc_de_munca like rtrim(@lm)+'%' 
			or exists (select 1 from misMF mm where mm.Subunitate=fisaMF.Subunitate and mm.Data_lunii_de_miscare=fisaMF.Data_lunii_operatiei and mm.Tip_miscare='TSE' and mm.Numar_de_inventar=fisaMF.Numar_de_inventar and mm.Loc_de_munca_primitor like rtrim(@lm)+'%'))
	--exec MFcalclun6 @datal,@nrinv,@categmf,@felop, @lm
	--AMORTIZARI IN IESIRI / TRANSFERURI
	UPDATE fisamf set Valoare_amortizata= (select a.Valoare_amortizata from fisamf a where a.subunitate=@sub and a.Numar_de_inventar= fisamf.Numar_de_inventar and a.data_lunii_operatiei=@datal and a.felul_operatiei=@felop), 
	Valoare_amortizata_cont_8045= (select a.Valoare_amortizata_cont_8045 from fisamf a where a.subunitate=@sub and a.Numar_de_inventar= fisamf.Numar_de_inventar and a.data_lunii_operatiei=@datal and a.felul_operatiei=@felop), 
	Valoare_amortizata_cont_6871= (select a.Valoare_amortizata_cont_6871 from fisamf a where a.subunitate=@sub and a.Numar_de_inventar= fisamf.Numar_de_inventar and a.data_lunii_operatiei=@datal and a.felul_operatiei=@felop), 
	Amortizare_lunara= (select a.amortizare_lunara from fisamf a where a.subunitate=@sub and a.Numar_de_inventar= fisamf.Numar_de_inventar and a.data_lunii_operatiei=@datal and a.felul_operatiei=@felop), 
	Amortizare_lunara_cont_8045= (select a.amortizare_lunara_cont_8045 from fisamf a where a.subunitate=@sub and a.Numar_de_inventar= fisamf.Numar_de_inventar and a.data_lunii_operatiei=@datal and a.felul_operatiei=@felop), 
	Amortizare_lunara_cont_6871= (select a.amortizare_lunara_cont_6871 from fisamf a where a.subunitate=@sub and a.Numar_de_inventar= fisamf.Numar_de_inventar and a.data_lunii_operatiei=@datal and a.felul_operatiei=@felop), 
	Durata= (select a.durata from fisamf a where a.subunitate=@sub and a.Numar_de_inventar= fisamf.Numar_de_inventar and a.data_lunii_operatiei=@datal and a.felul_operatiei=@felop), 
	Numar_de_luni_pana_la_am_int= (select a.Numar_de_luni_pana_la_am_int from fisamf a where a.subunitate=@sub and a.Numar_de_inventar= fisamf.Numar_de_inventar and a.data_lunii_operatiei=@datal and a.felul_operatiei=@felop)
	WHERE /*@felop='1' and */fisamf.subunitate=@sub and fisamf.data_lunii_operatiei=@datal 
	/*	Am exceptat fel operatie 6, pentru a avea pe pozitia cu fel operatie=6, valoarea de inventar de la momentul transferului (fara a fi afectata de eventualele modificari de valoare (ex. MRE) ulterioare TE-ului */
	and fisamf.felul_operatiei between '5' and '8' and fisamf.felul_operatiei<>'6'
	and (@nrinv='' or fisamf.numar_de_inventar=@nrinv) and (@categmf=0 or fisamf.categoria=@categmf) 
	and (@lm='' or fisaMF.Loc_de_munca like rtrim(@lm)+'%' or exists (select 1 from misMF mm where 
	mm.Subunitate=fisaMF.Subunitate and mm.Data_lunii_de_miscare=fisaMF.Data_lunii_operatiei 
	and mm.Tip_miscare='TSE' and mm.Numar_de_inventar=fisaMF.Numar_de_inventar 
	and mm.Loc_de_munca_primitor like rtrim(@lm)+'%'))

	UPDATE fisamf set cantitate= (select a.cantitate from fisamf a where a.subunitate=@sub and a.Numar_de_inventar= fisamf.Numar_de_inventar and a.data_lunii_operatiei=@datal and a.felul_operatiei=@felop)
	WHERE @felop='1' and fisamf.subunitate=@sub and fisamf.data_lunii_operatiei=@datal 
	and fisamf.felul_operatiei between '5' and '8' and (@nrinv='' or fisamf.numar_de_inventar=@nrinv) 
	and (@categmf=0 or fisamf.categoria=@categmf)
	and (@lm='' or fisaMF.Loc_de_munca like rtrim(@lm)+'%' or exists (select 1 from misMF mm where mm.Subunitate=fisaMF.Subunitate and mm.Data_lunii_de_miscare=fisaMF.Data_lunii_operatiei 
		and mm.Tip_miscare='TSE' and mm.Numar_de_inventar=fisaMF.Numar_de_inventar and mm.Loc_de_munca_primitor like rtrim(@lm)+'%'))

	UPDATE fisamf set Valoare_de_inventar= (select a.Valoare_de_inventar from fisamf a where a.subunitate=@sub and a.Numar_de_inventar= fisamf.Numar_de_inventar and a.data_lunii_operatiei=@datal and a.felul_operatiei=@felop)
	WHERE @felop='1' and fisamf.subunitate=@sub and fisamf.data_lunii_operatiei=@datal 
	and fisamf.felul_operatiei between '4' and '4' and (@nrinv='' or fisamf.numar_de_inventar=@nrinv) 
	and (@categmf=0 or fisamf.categoria=@categmf)
	and (@lm='' or fisaMF.Loc_de_munca like rtrim(@lm)+'%' or exists (select 1 from misMF mm where mm.Subunitate=fisaMF.Subunitate and mm.Data_lunii_de_miscare=fisaMF.Data_lunii_operatiei 
		and mm.Tip_miscare='TSE' and mm.Numar_de_inventar=fisaMF.Numar_de_inventar and mm.Loc_de_munca_primitor like rtrim(@lm)+'%'))

	UPDATE fisamf set Valoare_de_inventar=0, Valoare_amortizata=0, Valoare_amortizata_cont_8045=0, 
	Valoare_amortizata_cont_6871=0
	FROM mismf m WHERE /*@felop='1' and */fisamf.subunitate=@sub and fisamf.data_lunii_operatiei=@datal 
	and fisamf.felul_operatiei=@felop and (@nrinv='' or fisamf.numar_de_inventar=@nrinv) 
	and (@categmf=0 or fisamf.categoria=@categmf) and m.subunitate=fisamf.subunitate 
	and m.numar_de_inventar= fisamf.numar_de_inventar and left (m.tip_miscare,1)='E' 
	and m.data_lunii_de_miscare=fisamf.data_lunii_operatiei
	and (@lm='' or fisaMF.Loc_de_munca like rtrim(@lm)+'%' or exists (select 1 from misMF mm where 
	mm.Subunitate=fisaMF.Subunitate and mm.Data_lunii_de_miscare=fisaMF.Data_lunii_operatiei 
	and mm.Tip_miscare='TSE' and mm.Numar_de_inventar=fisaMF.Numar_de_inventar 
	and mm.Loc_de_munca_primitor like rtrim(@lm)+'%'))

	UPDATE fisamf set cantitate=0
	FROM mismf m WHERE @felop='1' and fisamf.subunitate=@sub and fisamf.data_lunii_operatiei=@datal 
	and fisamf.felul_operatiei=@felop and (@nrinv='' or fisamf.numar_de_inventar=@nrinv) 
	and (@categmf=0 or fisamf.categoria=@categmf) and m.subunitate=fisamf.subunitate 
	and m.numar_de_inventar= fisamf.numar_de_inventar and left (m.tip_miscare,1)='E' 
	and m.data_lunii_de_miscare=fisamf.data_lunii_operatiei
	and (@lm='' or fisaMF.Loc_de_munca like rtrim(@lm)+'%' or exists (select 1 from misMF mm where 
	mm.Subunitate=fisaMF.Subunitate and mm.Data_lunii_de_miscare=fisaMF.Data_lunii_operatiei 
	and mm.Tip_miscare='TSE' and mm.Numar_de_inventar=fisaMF.Numar_de_inventar 
	and mm.Loc_de_munca_primitor like rtrim(@lm)+'%'))

	-- procedura specifica de calcul 
	if exists (select 1 from sysobjects where name ='MFcalc_lun') 
		exec MFcalc_lun @sub,@datal,@nrinv,@categmf, @lm

	exec setare_par 'MF','LUNACAL','LUNACAL',0,@luna,@lunaalfa
	exec setare_par 'MF','ANULCAL','ANULCAL',0,@anul,''
END
