--***
create procedure [dbo].[MFcalclun3] @datal datetime,@nrinv char(13),@categmf int,
@felop char(1), @lm char(9)
as

declare @sub char(9), @PrimTim int, @RADJ int, @BRANTNER int, @trajvamist int, @urmrezreev int, --@reevcontab int, @amdegr2anicalend int, 
	@faraamlacon int, @amdedpedurinit int

exec luare_date_par 'GE', 'SUBPRO', 0, 0, @sub output
exec luare_date_par 'SP','PRIMTIM', @PrimTim output, 0, ''
exec luare_date_par 'SP','RADJ', @RADJ output, 0, ''
exec luare_date_par 'SP','BRANTNER', @BRANTNER output, 0, ''
--exec luare_date_par 'MF','MRECONTAB', @reevcontab output, 0, ''
exec luare_date_par 'MF','TAJUSTVAI', @trajvamist output, 0, ''
set @trajvamist=1
if @BRANTNER=1
	set @trajvamist=0
exec luare_date_par 'MF','REZREEV', @urmrezreev output, 0, ''
--exec luare_date_par 'MF','D2PEANIC', @amdegr2anicalend output, 0, ''
exec luare_date_par 'MF','CAMCONS', @faraamlacon output, 0, ''
exec luare_date_par 'MF','AMDEDDURI', @amdedpedurinit output, 0, ''

--VAL INV
UPDATE fisamf set fisamf.valoare_de_inventar= round(convert(decimal(17,5),fisamf.valoare_de_inventar+ 
/*isnull( (select a.valoare_de_inventar from fisamf a where a.subunitate=@sub 
and a.Numar_de_inventar= fisamf.Numar_de_inventar 
and a.data_lunii_operatiei=dbo.bom(@datal)-1 and a.felul_operatiei=@felop),0)+ isnull((select 
b.valoare_de_inventar from fisamf b where b.subunitate=@sub 
and b.Numar_de_inventar= fisamf.Numar_de_inventar 
and b.data_lunii_operatiei=@datal and b.felul_operatiei='3'),0)+ */
isnull((select sum (round(convert(decimal(17,5),c.diferenta_de_valoare),2)+ (case when @PrimTim=1 
and c.tip_miscare='MFF' then round(convert(decimal(17,5),c.tva),2) else 0 end)) from mismf c where 
c.subunitate=@sub and c.Numar_de_inventar= fisamf.Numar_de_inventar
and c.data_lunii_de_miscare=@datal and left (c.tip_miscare,1)='M'),0)- (CASE WHEN @felop='1' then 0 
else isnull((select sum(round(convert(decimal(17,5),y.diferenta_de_valoare),2)) from mismf y where 
/*y.subunitate=@sub and */y.numar_de_inventar= fisamf.numar_de_inventar and y.tip_miscare='MRE' 
and y.data_miscarii=@datal),0) END)),2)
WHERE fisamf.subunitate=@sub and fisamf.data_lunii_operatiei=@datal 
and fisamf.felul_operatiei in (@felop /*, (case when @felop='1' then '4' else '' end)*/ ) 
and (@nrinv='' or fisamf.numar_de_inventar=@nrinv) 
and (@categmf=0 or fisamf.categoria=@categmf) 
/*and fisamf.numar_de_inventar not in (select m.numar_de_inventar from mismf m where m.subunitate=@sub and left(m.tip_miscare,1)='I' 
and m.Data_lunii_de_miscare=@datal)*/
and (@lm='' or fisaMF.Loc_de_munca like rtrim(@lm)+'%' or exists (select 1 from misMF mm where 
mm.Subunitate=fisaMF.Subunitate and mm.Data_lunii_de_miscare=fisaMF.Data_lunii_operatiei 
and mm.Tip_miscare='TSE' and mm.Numar_de_inventar=fisaMF.Numar_de_inventar 
and mm.Loc_de_munca_primitor like rtrim(@lm)+'%'))

--VAL AM
UPDATE fisamf 
	set fisamf.valoare_amortizata= round(convert(decimal(17,5), fisamf.valoare_amortizata+amortizare_lunara /*isnull((select a.valoare_amortizata from fisamf a where a.subunitate=@sub and a.Numar_de_inventar= fisamf.Numar_de_inventar and a.data_lunii_operatiei=dbo.bom(@datal)-1 and a.felul_operatiei=@felop), (select b.valoare_amortizata from fisamf b where b.subunitate=@sub and b.Numar_de_inventar= fisamf.Numar_de_inventar and b.data_lunii_operatiei=@datal and b.felul_operatiei between '2' and '3'))+ */
		+ isnull((select sum(round(convert(decimal(17,5),m.pret),2)) from mismf m where m.subunitate=@sub and m.tip_miscare in ('MAL',/*'MMF',*/'MEP') and m.Data_lunii_de_miscare=@datal and m.numar_de_inventar= fisamf.numar_de_inventar),0)
		+ isnull((select round(convert(decimal(17,5),n.pret-(case when @trajvamist=1 and @felop='A' and left(n.tert,1)='6' then convert(float,(case when charindex(',',n.factura)>0 or ISNUMERIC(n.factura)=0 then '0' else n.factura end)) else 0 end)),2) from mismf n where /*n.subunitate=@sub and */n.tip_miscare='MRE' and n.Data_lunii_de_miscare=@datal and n.numar_de_inventar= fisamf.numar_de_inventar),0)
		- (CASE WHEN @felop='1' then 0 else isnull((select sum(round(convert(decimal(17,5),y.pret),2)) from mismf y where /*y.subunitate=@sub and */y.numar_de_inventar= fisamf.numar_de_inventar and y.tip_miscare='MRE' and y.data_miscarii=@datal),0) END)),2)
WHERE fisamf.subunitate=@sub and fisamf.data_lunii_operatiei=@datal 
and fisamf.felul_operatiei=@felop and (@nrinv='' or fisamf.numar_de_inventar=@nrinv) 
and (@categmf=0 or fisamf.categoria=@categmf) and fisamf.numar_de_inventar not in (select 
m.numar_de_inventar from mismf m where m.subunitate=@sub and left(m.tip_miscare,1)='I' 
and m.Data_lunii_de_miscare=@datal /*and m.numar_de_inventar= fisamf.numar_de_inventar*/)
and (@lm='' or fisaMF.Loc_de_munca like rtrim(@lm)+'%' or exists (select 1 from misMF mm where 
mm.Subunitate=fisaMF.Subunitate and mm.Data_lunii_de_miscare=fisaMF.Data_lunii_operatiei 
and mm.Tip_miscare='TSE' and mm.Numar_de_inventar=fisaMF.Numar_de_inventar 
and mm.Loc_de_munca_primitor like rtrim(@lm)+'%'))

if @felop='A' -- daca tratam valorile istorice
begin
	-- diminuare rezerva care va fi luata in calcul la nota de amortizare (Ghita, 07.03.2013 - oare e bine?)
	--if 1=0 -- asa a fost la 20.03.2013
	if @RADJ=1
	begin
		UPDATE fisamf set fisamf.cantitate= 
				round(convert(decimal(17,5),f1.Amortizare_lunara_cont_6871
					-isnull((select sum(round(convert(decimal(17,5),c.diferenta_de_valoare-c.pret+c.tva),2) - round(convert(decimal(17,5),rtrim((case when charindex(',',c.factura)>0 or ISNUMERIC(c.factura)=0 then '0' else c.factura end))),2)) 
					from mismf c where /*c.subunitate=@sub and */c.Numar_de_inventar= fisamf.Numar_de_inventar and c.data_lunii_de_miscare=@datal and c.tip_miscare='MRE' and c.Gestiune_primitoare=''),0)),2)
		from fisaMF, fisamf f1 
		WHERE f1.Subunitate=fisaMF.Subunitate and f1.Data_lunii_operatiei=fisaMF.Data_lunii_operatiei and f1.felul_operatiei='1' and f1.Numar_de_inventar=fisaMF.Numar_de_inventar
			and @urmrezreev=1 and fisamf.subunitate=@sub and fisamf.data_lunii_operatiei=@datal 
			and fisamf.felul_operatiei='A'  
			and (@nrinv='' or fisamf.numar_de_inventar=@nrinv) and (@categmf=0 or fisamf.categoria=@categmf) 
			and not exists (select 1 from mismf m where m.subunitate=@sub and left(m.tip_miscare,1)='I' and m.Data_lunii_de_miscare=@datal and m.numar_de_inventar= fisamf.numar_de_inventar)
			and (@lm='' or fisaMF.Loc_de_munca like rtrim(@lm)+'%' or exists (select 1 from misMF mm where mm.Subunitate=fisaMF.Subunitate and mm.Data_lunii_de_miscare=fisaMF.Data_lunii_operatiei and mm.Tip_miscare='TSE' and mm.Numar_de_inventar=fisaMF.Numar_de_inventar and mm.Loc_de_munca_primitor like rtrim(@lm)+'%'))
		---- zerorizare rezerva daca rezulta negativa
		--UPDATE fisamf set fisamf.cantitate=0
		--WHERE @urmrezreev=1 and fisamf.subunitate=@sub and fisamf.data_lunii_operatiei=@datal and fisamf.felul_operatiei in ('1')  and Cantitate<0 
		--and (@nrinv='' or fisamf.numar_de_inventar=@nrinv) and (@categmf=0 or fisamf.categoria=@categmf) 
		--and not exists (select 1 from mismf m where m.subunitate=@sub and left(m.tip_miscare,1)='I' and m.Data_lunii_de_miscare=@datal and m.numar_de_inventar= fisamf.numar_de_inventar)
		--and (@lm='' or fisaMF.Loc_de_munca like rtrim(@lm)+'%' or exists (select 1 from misMF mm where mm.Subunitate=fisaMF.Subunitate and mm.Data_lunii_de_miscare=fisaMF.Data_lunii_operatiei and mm.Tip_miscare='TSE' and mm.Numar_de_inventar=fisaMF.Numar_de_inventar and mm.Loc_de_munca_primitor like rtrim(@lm)+'%'))
		UPDATE fisaMF set Amortizare_lunara_cont_6871=cantitate
		WHERE Subunitate=@sub and Data_lunii_operatiei=@datal and felul_operatiei='1' 
			and @urmrezreev=1 
			and (@nrinv='' or fisamf.numar_de_inventar=@nrinv) and (@categmf=0 or fisamf.categoria=@categmf) 
			and not exists (select 1 from mismf m where m.subunitate=@sub and left(m.tip_miscare,1)='I' and m.Data_lunii_de_miscare=@datal and m.numar_de_inventar= fisamf.numar_de_inventar)
			and (@lm='' or fisaMF.Loc_de_munca like rtrim(@lm)+'%' or exists (select 1 from misMF mm where mm.Subunitate=fisaMF.Subunitate and mm.Data_lunii_de_miscare=fisaMF.Data_lunii_operatiei and mm.Tip_miscare='TSE' and mm.Numar_de_inventar=fisaMF.Numar_de_inventar and mm.Loc_de_munca_primitor like rtrim(@lm)+'%'))
	end
	else -- asa am corectat diminuare rezerva: sa ia rezerva lunii trecute si sa o imparta la luni ramase (Ghita, 20.03.2013)
	begin
		UPDATE fisamf set fisamf.cantitate= (case when f1.cantitate>0 and f1.Numar_de_luni_pana_la_am_int>0 then round(convert(decimal(17,5),f1.cantitate/f1.Numar_de_luni_pana_la_am_int),2) else 0 end)
		from fisaMF, fisamf f1 
		WHERE f1.Subunitate=fisaMF.Subunitate and f1.Data_lunii_operatiei=dateadd(DAY,-1,dbo.bom(fisaMF.Data_lunii_operatiei)) and f1.felul_operatiei='1' and f1.Numar_de_inventar=fisaMF.Numar_de_inventar
			and @urmrezreev=1 and fisamf.subunitate=@sub and fisamf.data_lunii_operatiei=@datal 
			and fisamf.felul_operatiei='A' --and f1.cantitate>0 and f1.Numar_de_luni_pana_la_am_int>0 -- tratat sa nu anuleze efectul insertului cu fel A, daca nu exista Rezerva din reev. in luna ant. (pe fel 1) Momentan ramine cum a fost.
			and (@nrinv='' or fisamf.numar_de_inventar=@nrinv) and (@categmf=0 or fisamf.categoria=@categmf) 
			and not exists (select 1 from mismf m where m.subunitate=@sub and left(m.tip_miscare,1)='I' and m.Data_lunii_de_miscare=@datal and m.numar_de_inventar= fisamf.numar_de_inventar)
			and (@lm='' or fisaMF.Loc_de_munca like rtrim(@lm)+'%' or exists (select 1 from misMF mm where mm.Subunitate=fisaMF.Subunitate and mm.Data_lunii_de_miscare=fisaMF.Data_lunii_operatiei and mm.Tip_miscare='TSE' and mm.Numar_de_inventar=fisaMF.Numar_de_inventar and mm.Loc_de_munca_primitor like rtrim(@lm)+'%'))
			and not (@faraamlacon=1 and fisamf.data_lunii_operatiei<= isnull((select top 1 y.data_sfarsit_conservare from mismf y where y.subunitate=@sub and y.tip_miscare='CON' 
				and y.Data_lunii_de_miscare<=@datal and y.numar_de_inventar=fisamf.numar_de_inventar order by y.Data_sfarsit_conservare desc),fisamf.data_lunii_operatiei-1))
		
		--	Anulare calcul diminuare rezerva pentru conservari
		UPDATE fisamf set fisamf.cantitate=0
		from fisaMF
		WHERE @urmrezreev=1 and fisamf.subunitate=@sub and fisamf.data_lunii_operatiei=@datal and fisamf.felul_operatiei='A' 
			and (@nrinv='' or fisamf.numar_de_inventar=@nrinv) and (@categmf=0 or fisamf.categoria=@categmf) 
			and not exists (select 1 from mismf m where m.subunitate=@sub and left(m.tip_miscare,1)='I' and m.Data_lunii_de_miscare=@datal and m.numar_de_inventar= fisamf.numar_de_inventar)
			and (@lm='' or fisaMF.Loc_de_munca like rtrim(@lm)+'%' or exists (select 1 from misMF mm where mm.Subunitate=fisaMF.Subunitate and mm.Data_lunii_de_miscare=fisaMF.Data_lunii_operatiei and mm.Tip_miscare='TSE' and mm.Numar_de_inventar=fisaMF.Numar_de_inventar and mm.Loc_de_munca_primitor like rtrim(@lm)+'%'))
			and @faraamlacon=1 and fisamf.data_lunii_operatiei<= isnull((select top 1 y.data_sfarsit_conservare from mismf y where y.subunitate=@sub and y.tip_miscare='CON' 
				and y.Data_lunii_de_miscare<=@datal and y.numar_de_inventar=fisamf.numar_de_inventar order by y.Data_sfarsit_conservare desc),fisamf.data_lunii_operatiei-1)
	end
	--rez. reev. cont 105
	UPDATE fisamf set cantitate=round(convert(decimal(17,5),fisamf.cantitate-fa.cantitate+isnull((select sum(round(convert(decimal(17,5),c.diferenta_de_valoare-c.pret+c.tva),2) 
				- round(convert(decimal(17,5),rtrim((case when charindex(',',c.factura)>0 or ISNUMERIC(c.factura)=0 then '0' else c.factura end))),2)) 
					from mismf c where /*c.subunitate=@sub and */c.Numar_de_inventar= fisamf.Numar_de_inventar and c.data_lunii_de_miscare=@datal and c.tip_miscare='MRE' and c.Gestiune_primitoare=''),0)),2) 
	from fisaMF, fisamf fa 
	WHERE fa.Subunitate=fisaMF.Subunitate and fa.Data_lunii_operatiei=fisaMF.Data_lunii_operatiei and fa.felul_operatiei='A' and fa.Numar_de_inventar=fisaMF.Numar_de_inventar
		and @urmrezreev=1 and fisamf.subunitate=@sub and fisamf.data_lunii_operatiei=@datal 
		and fisamf.felul_operatiei in ('1' /*, (case when @felop='1' then '4' else '' end)*/) 
		and (@nrinv='' or fisamf.numar_de_inventar=@nrinv) and (@categmf=0 or fisamf.categoria=@categmf) 
		and not exists (select 1 from mismf m where m.subunitate=@sub and left(m.tip_miscare,1)='I' and m.Data_lunii_de_miscare=@datal and m.numar_de_inventar= fisamf.numar_de_inventar)
		and (@lm='' or fisaMF.Loc_de_munca like rtrim(@lm)+'%' or exists (select 1 from misMF mm where mm.Subunitate=fisaMF.Subunitate and mm.Data_lunii_de_miscare=fisaMF.Data_lunii_operatiei and mm.Tip_miscare='TSE' and mm.Numar_de_inventar=fisaMF.Numar_de_inventar and mm.Loc_de_munca_primitor like rtrim(@lm)+'%'))

	--VAL AM 8045 FEL A
	UPDATE fisamf set valoare_amortizata_cont_8045= round(convert(decimal(17,5),
	valoare_amortizata_cont_8045-isnull((select round(convert(decimal(17,5),rtrim((case 
	when charindex(',',n.factura)>0 or ISNUMERIC(n.factura)=0 then '0' else n.factura end))),2) from 
	mismf n where /*n.subunitate=@sub and */n.tip_miscare='MRE' and n.Data_lunii_de_miscare=@datal 
	and n.numar_de_inventar= fisamf.numar_de_inventar and n.loc_de_munca_primitor<>'' 
	and left(n.tert,1)='6'),0)),2)
	WHERE @trajvamist=1 and fisamf.subunitate=@sub and fisamf.data_lunii_operatiei=@datal 
	and fisamf.felul_operatiei=@felop and (@nrinv='' or fisamf.numar_de_inventar=@nrinv) 
	and (@categmf=0 or fisamf.categoria=@categmf) /*and fisamf.numar_de_inventar not in (select 
	m.numar_de_inventar from mismf m where m.subunitate=@sub and left(m.tip_miscare,1)='I' 
	and m.Data_lunii_de_miscare=@datal)*/
	and (@lm='' or fisaMF.Loc_de_munca like rtrim(@lm)+'%' or exists (select 1 from misMF mm where 
	mm.Subunitate=fisaMF.Subunitate and mm.Data_lunii_de_miscare=fisaMF.Data_lunii_operatiei 
	and mm.Tip_miscare='TSE' and mm.Numar_de_inventar=fisaMF.Numar_de_inventar 
	and mm.Loc_de_munca_primitor like rtrim(@lm)+'%'))
end
--durata si nr. de luni
UPDATE fisamf set fisamf.durata= isnull((select a.durata from fisamf a where 
a.subunitate=@sub and a.Numar_de_inventar= fisamf.Numar_de_inventar
and a.data_lunii_operatiei=--(case when @felop<>'1' and @amdedpedurinit=1 then dbo.bom(@datal)-1 else 
@datal and a.felul_operatiei=(case when @felop='1' or @amdedpedurinit=1 and not exists 
(select 1 from mismf m where m.subunitate=@sub and m.tip_miscare='MRE' 
and m.Data_lunii_de_miscare=@datal and m.numar_de_inventar= fisamf.numar_de_inventar) then '4' 
when @felop<>'1' and @amdedpedurinit=0 then '1' else '' end)), 
isnull((select b.durata from fisamf b where 
b.subunitate=@sub and b.Numar_de_inventar= fisamf.Numar_de_inventar
and b.data_lunii_operatiei=dbo.bom(@datal)-1 and b.felul_operatiei=@felop), 
(select c.durata from fisamf c where c.subunitate=@sub 
and c.Numar_de_inventar= fisamf.Numar_de_inventar 
and c.data_lunii_operatiei=@datal and c.felul_operatiei='3')))
WHERE fisamf.subunitate=@sub and fisamf.data_lunii_operatiei=@datal 
and fisamf.felul_operatiei=@felop and (@nrinv='' or fisamf.numar_de_inventar=@nrinv) 
and (@categmf=0 or fisamf.categoria=@categmf) and (@felop<>'1' and @amdedpedurinit=0 
or exists (select 1 from mismf m where m.subunitate=@sub 
and left(m.tip_miscare,1)='M' and (@felop='1' or @amdedpedurinit=0 or m.tip_miscare<>'MRE') 
and m.Data_lunii_de_miscare=@datal and m.numar_de_inventar= fisamf.numar_de_inventar))
and (@lm='' or fisaMF.Loc_de_munca like rtrim(@lm)+'%' or exists (select 1 from misMF mm where 
mm.Subunitate=fisaMF.Subunitate and mm.Data_lunii_de_miscare=fisaMF.Data_lunii_operatiei 
and mm.Tip_miscare='TSE' and mm.Numar_de_inventar=fisaMF.Numar_de_inventar 
and mm.Loc_de_munca_primitor like rtrim(@lm)+'%'))

UPDATE fisamf set fisamf.Numar_de_luni_pana_la_am_int= 
isnull(nullif((select a.Numar_de_luni_pana_la_am_int from fisamf a where 
a.subunitate=@sub and a.Numar_de_inventar= fisamf.Numar_de_inventar
and a.data_lunii_operatiei=--(case when @felop<>'1' and @amdedpedurinit=1 then dbo.bom(@datal)-1 else 
@datal and a.felul_operatiei=(case when @felop='1' or @amdedpedurinit=1 and not exists 
(select 1 from mismf m where m.subunitate=@sub and m.tip_miscare='MRE' 
and m.Data_lunii_de_miscare=@datal and m.numar_de_inventar= fisamf.numar_de_inventar) then '4' 
when @felop<>'1' and @amdedpedurinit=0 then '1' else '' end)),0), 
isnull((select b.Numar_de_luni_pana_la_am_int/*-(case when 
b.Numar_de_luni_pana_la_am_int<1 then 0 else 1 end)*/ from fisamf b where 
b.subunitate=@sub and b.Numar_de_inventar= fisamf.Numar_de_inventar
and b.data_lunii_operatiei=dbo.bom(@datal)-1 and b.felul_operatiei=@felop), 
isnull((select c.Numar_de_luni_pana_la_am_int from fisamf c where c.subunitate=@sub 
and c.Numar_de_inventar= fisamf.Numar_de_inventar 
and c.data_lunii_operatiei=@datal and c.felul_operatiei='3'),0)))
WHERE fisamf.subunitate=@sub and fisamf.data_lunii_operatiei=@datal 
and fisamf.felul_operatiei=@felop and (@nrinv='' or fisamf.numar_de_inventar=@nrinv) 
and (@categmf=0 or fisamf.categoria=@categmf) and (@felop<>'1' and @amdedpedurinit=0 
or exists (select 1 from mismf m where m.subunitate=@sub 
and left(m.tip_miscare,1)='M' and (@felop='1' or @amdedpedurinit=0 or m.tip_miscare<>'MRE') 
and m.Data_lunii_de_miscare=@datal and m.numar_de_inventar= fisamf.numar_de_inventar))
and (@lm='' or fisaMF.Loc_de_munca like rtrim(@lm)+'%' or exists (select 1 from misMF mm where 
mm.Subunitate=fisaMF.Subunitate and mm.Data_lunii_de_miscare=fisaMF.Data_lunii_operatiei 
and mm.Tip_miscare='TSE' and mm.Numar_de_inventar=fisaMF.Numar_de_inventar 
and mm.Loc_de_munca_primitor like rtrim(@lm)+'%'))

UPDATE fisamf set fisamf.Numar_de_luni_pana_la_am_int=Numar_de_luni_pana_la_am_int-1
WHERE (@felop='1' or @amdedpedurinit=1) and fisamf.subunitate=@sub 
and fisamf.data_lunii_operatiei=@datal 
and fisamf.felul_operatiei=@felop and (@nrinv='' or fisamf.numar_de_inventar=@nrinv) 
and (@categmf=0 or fisamf.categoria=@categmf) and Numar_de_luni_pana_la_am_int>0 
and not (@faraamlacon=1 and fisamf.data_lunii_operatiei<= isnull((select top 1 
y.data_sfarsit_conservare from mismf y where y.subunitate=@sub and y.tip_miscare='CON' 
and y.Data_lunii_de_miscare<=@datal and y.numar_de_inventar= fisamf.numar_de_inventar order by 
y.Data_sfarsit_conservare desc),fisamf.data_lunii_operatiei-1)) and not exists 
(select 1 from mismf m where m.subunitate=@sub 
and left(m.tip_miscare,1)='M' and (@felop='1' or @amdedpedurinit=0 or m.tip_miscare<>'MRE') 
and m.Data_lunii_de_miscare=@datal and m.numar_de_inventar= fisamf.numar_de_inventar) 
and not exists (select 1 from mismf m where m.subunitate=@sub and left(m.tip_miscare,1)='I' 
and m.Data_lunii_de_miscare=@datal and m.numar_de_inventar= fisamf.numar_de_inventar)
and (@lm='' or fisaMF.Loc_de_munca like rtrim(@lm)+'%' or exists (select 1 from misMF mm where 
mm.Subunitate=fisaMF.Subunitate and mm.Data_lunii_de_miscare=fisaMF.Data_lunii_operatiei 
and mm.Tip_miscare='TSE' and mm.Numar_de_inventar=fisaMF.Numar_de_inventar 
and mm.Loc_de_munca_primitor like rtrim(@lm)+'%'))
