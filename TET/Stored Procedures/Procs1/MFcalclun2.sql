--***
create procedure [dbo].[MFcalclun2] @datal datetime,@nrinv char(13),@categmf int,
@felop char(1), @lm char(9), @valist int
as

declare @sub char(9), @BRANTNER int, @reevcontab int, @trajvamist int, @amdegr2anicalend int, @faraamlacon int, 
	@amdedpedurinit int

exec luare_date_par 'GE', 'SUBPRO', 0, 0, @sub output
exec luare_date_par 'SP','BRANTNER', @BRANTNER output, 0, ''
exec luare_date_par 'MF','MRECONTAB', @reevcontab output, 0, ''
exec luare_date_par 'MF','TAJUSTVAI', @trajvamist output, 0, ''
set @trajvamist=1
if @BRANTNER=1
	set @trajvamist=0
exec luare_date_par 'MF','D2PEANIC', @amdegr2anicalend output, 0, ''
exec luare_date_par 'MF','CAMCONS', @faraamlacon output, 0, ''
exec luare_date_par 'MF','AMDEDDURI', @amdedpedurinit output, 0, ''

--STERG. SI SCRIERE IN FISAMF
DELETE from fisamf where subunitate=@sub and data_lunii_operatiei=@datal and felul_operatiei=@felop 
and (@nrinv='' or numar_de_inventar=@nrinv) and (@categmf=0 or categoria=@categmf) 
and (@felop='1' or fisamf.numar_de_inventar not in (select m.numar_de_inventar from mismf m where m.subunitate=@sub 
and left(m.tip_miscare,1)='I' and m.Data_lunii_de_miscare=@datal 
/*and m.numar_de_inventar= fisamf.numar_de_inventar*/))
and (@lm='' or fisaMF.Loc_de_munca like rtrim(@lm)+'%' or exists (select 1 from misMF mm where 
mm.Subunitate=fisaMF.Subunitate and mm.Data_lunii_de_miscare=fisaMF.Data_lunii_operatiei 
and mm.Tip_miscare='TSE' and mm.Numar_de_inventar=fisaMF.Numar_de_inventar 
and mm.Loc_de_munca_primitor like rtrim(@lm)+'%'))

--FEL 1 INTRATE IN LUNA CURENTA (incercam sa nu mai scriem la intrari in fisaMF pe fel operatie='1' ci doar la calcul)
INSERT into fisamf (Subunitate, Numar_de_inventar, Categoria, Data_lunii_operatiei, Felul_operatiei, Loc_de_munca, Gestiune, Comanda, Valoare_de_inventar, Valoare_amortizata, Valoare_amortizata_cont_8045, Valoare_amortizata_cont_6871, Amortizare_lunara, Amortizare_lunara_cont_8045, 
Amortizare_lunara_cont_6871, Durata, Obiect_de_inventar, Cont_mijloc_fix, Numar_de_luni_pana_la_am_int, Cantitate, Cont_amortizare, Cont_cheltuieli)
SELECT f.Subunitate, f.Numar_de_inventar, f.Categoria, convert(datetime,@datal), @felop, f.Loc_de_munca, f.Gestiune, f.Comanda, f.Valoare_de_inventar, f.Valoare_amortizata, f.Valoare_amortizata_cont_8045, f.Valoare_amortizata_cont_6871, f.Amortizare_lunara, 
f.Amortizare_lunara_cont_8045, f.Amortizare_lunara_cont_6871, f.Durata, f.Obiect_de_inventar, f.Cont_mijloc_fix, f.Numar_de_luni_pana_la_am_int, f.Cantitate, f.Cont_amortizare, f.Cont_cheltuieli
FROM fisaMF f
Left outer join mfix mf on f.subunitate= mf.subunitate and f.numar_de_inventar= mf.numar_de_inventar
Left outer join mismf mm on mm.Subunitate=f.Subunitate and mm.Data_lunii_de_miscare=f.Data_lunii_operatiei and left(mm.Tip_miscare,1)='I' and mm.Numar_de_inventar=f.Numar_de_inventar 
WHERE @felop='1' and f.subunitate=@sub and f.data_lunii_operatiei=@datal and f.felul_operatiei='3'
	and (@nrinv='' or f.numar_de_inventar=@nrinv) 
	and (@categmf=0 or f.categoria=@categmf) 
	and f.Numar_de_inventar not in (select z.Numar_de_inventar from fisamf z where z.subunitate=@sub and z.data_lunii_operatiei=@datal and z.felul_operatiei=@felop and (@nrinv='' or z.numar_de_inventar=@nrinv) and (@categmf=0 or z.categoria=@categmf)) 
	and (@lm='' or f.Loc_de_munca like rtrim(@lm)+'%')

--FEL 1 INTRATE ANTERIOR
INSERT into fisamf (Subunitate, Numar_de_inventar, Categoria, Data_lunii_operatiei, Felul_operatiei, Loc_de_munca, Gestiune, Comanda, Valoare_de_inventar, Valoare_amortizata, Valoare_amortizata_cont_8045, Valoare_amortizata_cont_6871, Amortizare_lunara, Amortizare_lunara_cont_8045, 
Amortizare_lunara_cont_6871, Durata, Obiect_de_inventar, Cont_mijloc_fix, Numar_de_luni_pana_la_am_int, Cantitate, Cont_amortizare, Cont_cheltuieli)
SELECT a.Subunitate, a.Numar_de_inventar, a.Categoria, convert(datetime,@datal), @felop, a.Loc_de_munca, a.Gestiune, a.Comanda, a.Valoare_de_inventar, a.Valoare_amortizata, a.Valoare_amortizata_cont_8045, a.Valoare_amortizata_cont_6871, a.Amortizare_lunara, 
a.Amortizare_lunara_cont_8045, a.Amortizare_lunara_cont_6871, a.Durata, a.Obiect_de_inventar, a.Cont_mijloc_fix, a.Numar_de_luni_pana_la_am_int, a.Cantitate, a.Cont_amortizare, a.Cont_cheltuieli
FROM fisamf a 
Left outer join mfix b on a.subunitate= b.subunitate and a.numar_de_inventar= b.numar_de_inventar
WHERE @felop='1' and a.subunitate=@sub and a.data_lunii_operatiei=dbo.bom(@datal)-1 and a.felul_operatiei=@felop 
	and (@nrinv='' or a.numar_de_inventar=@nrinv) 
	and (@categmf=0 or a.categoria=@categmf) 
	and a.Numar_de_inventar not in (select z.Numar_de_inventar from fisamf z where z.subunitate=@sub and z.data_lunii_operatiei=@datal and z.felul_operatiei=@felop and (@nrinv='' or z.numar_de_inventar=@nrinv) and (@categmf=0 or z.categoria=@categmf)) 
	--and a.Numar_de_inventar in (select y.Numar_de_inventar from fisamf y where y.subunitate=@sub and y.felul_operatiei between '2' and '3' and y.Data_lunii_operatiei<convert(datetime,@datal)+(case when b.tip_amortizare='6' then 1 else 0 end) and (@nrinv='' or y.numar_de_inventar=@nrinv) and (@categmf=0 or y.categoria=@categmf)) 
	and a.Numar_de_inventar not in (select x.Numar_de_inventar from mismf x where x.subunitate=@sub and x.tip_miscare between 'E' and 'Ezz' and x.Data_lunii_de_miscare<=dbo.bom(@datal)-1)
	and (@lm='' or a.Loc_de_munca like rtrim(@lm)+'%' 
		or exists (select 1 from misMF mm where mm.Subunitate=a.Subunitate and mm.Data_lunii_de_miscare=a.Data_lunii_operatiei and mm.Tip_miscare='TSE' and mm.Numar_de_inventar=a.Numar_de_inventar and mm.Loc_de_munca_primitor like rtrim(@lm)+'%')
		or exists (select 1 from misMF mml where mml.Subunitate=a.Subunitate and mml.Data_lunii_de_miscare=@datal and mml.Tip_miscare='TSE' and mml.Numar_de_inventar=a.Numar_de_inventar and mml.Loc_de_munca_primitor like rtrim(@lm)+'%'))

--FEL A
INSERT into fisamf (Subunitate, Numar_de_inventar, Categoria, Data_lunii_operatiei, Felul_operatiei, Loc_de_munca, Gestiune, Comanda, 
	Valoare_de_inventar, 
	Valoare_amortizata, 
	Valoare_amortizata_cont_8045, 
	Valoare_amortizata_cont_6871, 
	Amortizare_lunara, 
	Amortizare_lunara_cont_8045, 
	Amortizare_lunara_cont_6871, 
	Durata, 
	Obiect_de_inventar, 
	Cont_mijloc_fix, 
	Numar_de_luni_pana_la_am_int, 
	Cantitate, Cont_amortizare, Cont_cheltuieli)
SELECT a.Subunitate, a.Numar_de_inventar, d.Categoria, convert(datetime,@datal), @felop, d.Loc_de_munca, d.Gestiune, d.Comanda, 
	a.Valoare_de_inventar
		- (CASE WHEN @valist=0 then 0 else isnull((select sum(round(convert(decimal(17,5),y.diferenta_de_valoare),2)) from mismf y where /*y.subunitate=@sub and */y.numar_de_inventar=a.numar_de_inventar and y.tip_miscare='MRE' and y.data_miscarii<@datal and y.Loc_de_munca_primitor=''),0) END)
		- isnull((select sum(round(convert(decimal(17,5),y.diferenta_de_valoare),2)) from mismf y where /*y.subunitate=@sub and */y.numar_de_inventar=a.numar_de_inventar and y.tip_miscare='MRE' and y.data_miscarii<@datal and y.Loc_de_munca_primitor<>''),0), 
	(CASE WHEN isnull((case when @valist=0 then e.Valoare_amortizata_cont_8045 else e.Valoare_amortizata end),0)=0 then a.Valoare_amortizata- a.Valoare_amortizata_cont_6871- 
		(CASE WHEN @valist=0 then 0 else isnull((select sum(round(convert(decimal(17,5),y.pret),2)) from mismf y where /*y.subunitate=@sub and */y.numar_de_inventar=a.numar_de_inventar and y.tip_miscare='MRE' and y.data_miscarii<@datal and y.Loc_de_munca_primitor=''),0) END)
		- isnull((select sum(round(convert(decimal(17,5),y.pret+(case when @trajvamist=1 and left(y.tert,1)='6' then convert(float,(case when charindex(',',y.factura)>0 or ISNUMERIC(y.factura)=0 then '0' else y.factura end)) else 0 end)),2)) from mismf y where /*y.subunitate=@sub and */y.numar_de_inventar=a.numar_de_inventar and y.tip_miscare='MRE' and y.data_miscarii<@datal and y.Loc_de_munca_primitor<>''),0) else (case when @valist=0 then e.Valoare_amortizata_cont_8045 else e.Valoare_amortizata end) END), 
	round(convert(decimal(17,5), (CASE WHEN isnull(e.Valoare_amortizata_cont_8045,0)=0 then a.Valoare_amortizata- a.Valoare_amortizata_cont_6871- isnull((select sum(round(convert(decimal(17,5),y.pret+(case when @trajvamist=1 and left(y.tert,1)='6' then convert(float,(case when charindex(',',y.factura)>0 or ISNUMERIC(y.factura)=0 then '0' else y.factura end)) else 0 end)),2)) from mismf y where /*y.subunitate=@sub and */y.numar_de_inventar=a.numar_de_inventar and y.tip_miscare='MRE' and y.data_miscarii<@datal and y.Loc_de_munca_primitor<>''),0) else e.Valoare_amortizata_cont_8045 END)
		+ d.Amortizare_lunara- d.Amortizare_lunara_cont_6871+ isnull((select sum(round(convert(decimal(17,5),y.pret),2)) from mismf y where /*y.subunitate=@sub and */y.numar_de_inventar=a.numar_de_inventar and y.tip_miscare='MRE' and y.data_miscarii=@datal and y.Loc_de_munca_primitor=''),0)+ isnull((select sum(round(convert(decimal(17,5),y.pret),2)) from mismf y where y.subunitate=@sub and y.tip_miscare='MEP' and y.numar_de_inventar=a.numar_de_inventar and y.data_miscarii=@datal),0)),2), 
	isnull((select sum(round(convert(decimal(17,5),y.diferenta_de_valoare),2)) from mismf y where /*y.subunitate=@sub and */y.numar_de_inventar=a.numar_de_inventar and y.tip_miscare='MRE' and y.data_miscarii<=@datal and y.Loc_de_munca_primitor<>''),0), 
	0, 
	round(convert(decimal(17,5),d.Amortizare_lunara- d.Amortizare_lunara_cont_6871),2), 
	d.Amortizare_lunara, 
	(case when @felop<>'1' and @amdedpedurinit=1 then isnull(e.durata,a.Durata) else a.Durata end), 
	d.Obiect_de_inventar, 
	isnull((select top 1 y.cont_corespondent from mismf y where /*y.subunitate=@sub and */y.tip_miscare='MRE' and y.Data_lunii_de_miscare<=(case when @reevcontab=1 then @datal else dbo.bom(@datal)-1 end) and y.numar_de_inventar=a.numar_de_inventar order by y.Data_lunii_de_miscare desc),''), 
	(case when @felop<>'1' and @amdedpedurinit=1 then isnull(e.Numar_de_luni_pana_la_am_int,a.Numar_de_luni_pana_la_am_int) else a.Numar_de_luni_pana_la_am_int end), 
	isnull((select sum(round(convert(decimal(17,5),y.diferenta_de_valoare),2)) from mismf y where /*y.subunitate=@sub and */y.numar_de_inventar=a.numar_de_inventar and y.tip_miscare='MRE' and y.data_miscarii<=@datal and y.Loc_de_munca_primitor=''),0),
	a.Cont_amortizare, a.Cont_cheltuieli
FROM fisamf a 
/*Left outer join fisamf c on a.subunitate= c.subunitate and a.numar_de_inventar= c.numar_de_inventar 
and c.felul_operatiei='1' and c.Data_lunii_operatiei=dbo.bom(@datal)-1 */
Left outer join fisamf d on a.subunitate= d.subunitate and a.numar_de_inventar= d.numar_de_inventar 
and d.felul_operatiei='1' and d.Data_lunii_operatiei=@datal 
Left outer join fisamf e on a.subunitate= e.subunitate and a.numar_de_inventar= e.numar_de_inventar 
and e.felul_operatiei=@felop and e.Data_lunii_operatiei=dbo.bom(@datal)-1 
/*Left outer join fisamf f on a.subunitate= f.subunitate and a.numar_de_inventar= f.numar_de_inventar 
and f.felul_operatiei between '2' and '3'*/
WHERE @felop<>'1' and a.subunitate=@sub and a.data_lunii_operatiei=dbo.bom(@datal)-1 and a.felul_operatiei='1' and (@nrinv='' or a.numar_de_inventar=@nrinv) 
	and (@categmf=0 or a.categoria=@categmf) 
	and a.Numar_de_inventar not in (select z.Numar_de_inventar from fisamf z where z.subunitate=@sub and z.data_lunii_operatiei=@datal and z.felul_operatiei=@felop and (@nrinv='' or z.numar_de_inventar=@nrinv) 
	and (@categmf=0 or z.categoria=@categmf)) and a.Numar_de_inventar in (select v.Numar_de_inventar from mismf v where /*v.subunitate=@sub and */v.tip_miscare='MRE' and v.Data_lunii_de_miscare<=(case when @reevcontab=1 then @datal else dbo.bom(@datal)-1 end)) and (a.Numar_de_luni_pana_la_am_int>0 or d.Numar_de_luni_pana_la_am_int>0 or @reevcontab=1) and a.Numar_de_inventar not in (select x.Numar_de_inventar from mismf x where x.subunitate=@sub and x.tip_miscare between 'E' and 'Ezz' and x.Data_lunii_de_miscare<=dbo.bom(@datal)-1) 
	/*and a.Numar_de_inventar in (select v.Numar_de_inventar from mismf v where /*v.subunitate=@sub and */v.tip_miscare between (case when @felop<>'1' then 'MRE' else 'I' end) and (case when @felop<>'1' then 'MRE' else 'Izz' end) and v.Data_lunii_de_miscare between (case when @felop<>'1' then convert(datetime,'01/01/1901') else @datal end) and (case when @felop<>'1' then (case when @reevcontab=1 then @datal else dbo.bom(@datal)-1 end) else @datal end)) and (@felop='1' or @felop<>'1' and (c.Numar_de_luni_pana_la_am_int>0 or d.Numar_de_luni_pana_la_am_int>0 or @reevcontab=1))*/
	and (@lm='' or a.Loc_de_munca like rtrim(@lm)+'%' or exists (select 1 from misMF mm where mm.Subunitate=a.Subunitate and mm.Data_lunii_de_miscare=a.Data_lunii_operatiei and mm.Tip_miscare='TSE' and mm.Numar_de_inventar=a.Numar_de_inventar and mm.Loc_de_munca_primitor like rtrim(@lm)+'%'))

/*UPDATE fisaMF set Amortizare_lunara=0, Amortizare_lunara_cont_8045=0, Amortizare_lunara_cont_6871=0
FROM mfix 
WHERE fisamf.subunitate=@sub and fisamf.data_lunii_operatiei=@datal 
and fisamf.felul_operatiei='1' and (@nrinv='' or fisamf.numar_de_inventar=@nrinv) 
and (@categmf=0 or fisamf.categoria=@categmf) and mfix.subunitate=fisamf.subunitate 
and mfix.numar_de_inventar= fisamf.numar_de_inventar --and mfix.tip_amortizare<>'7'
and (@lm='' or fisaMF.Loc_de_munca like rtrim(@lm)+'%' or exists (select 1 from misMF mm where 
mm.Subunitate=fisaMF.Subunitate and mm.Data_lunii_de_miscare=fisaMF.Data_lunii_operatiei 
and mm.Tip_miscare='TSE' and mm.Numar_de_inventar=fisaMF.Numar_de_inventar 
and mm.Loc_de_munca_primitor like rtrim(@lm)+'%'))*/

--AM. DEGR. 1
UPDATE fisamf set fisamf.amortizare_lunara= (CASE WHEN (Valoare_de_inventar- Valoare_amortizata)*
(select col3 from coefmf where dur=durata)/100/12>(Valoare_de_inventar- Valoare_amortizata)/
Numar_de_luni_pana_la_am_int THEN (Valoare_de_inventar- Valoare_amortizata)*(select col3 from 
coefmf where dur=durata)/100/12 ELSE (Valoare_de_inventar- Valoare_amortizata)/
Numar_de_luni_pana_la_am_int END)
FROM mfix 
WHERE fisamf.subunitate=@sub and fisamf.data_lunii_operatiei=@datal 
and fisamf.felul_operatiei=@felop and (@nrinv='' or fisamf.numar_de_inventar=@nrinv) 
and (@categmf=0 or fisamf.categoria=@categmf) and fisamf.Numar_de_luni_pana_la_am_int>0 
and mfix.subunitate=fisamf.subunitate and mfix.numar_de_inventar= fisamf.numar_de_inventar and 
mfix.tip_amortizare='3' and (isnull((select sum(round(convert(decimal(17,5),c.diferenta_de_valoare),2)) 
from mismf c where c.subunitate=@sub /*'DENS'*/and c.Numar_de_inventar= fisamf.Numar_de_inventar
and c.data_lunii_de_miscare=dbo.bom(@datal)-1 and left (c.tip_miscare,1)='M' and (@felop='1' 
or @felop<>'1' and @reevcontab=1 and c.loc_de_munca_primitor<>'RC' or @felop<>'1' and @valist=1 
and c.tip_miscare<>'MRE')),0)<>0 or amortizare_lunara=0 
or (durata*12-Numar_de_luni_pana_la_am_int)%12=0) and not exists (select 1 from mismf m where 
m.subunitate=@sub and left(m.tip_miscare,1)='I' and m.Data_lunii_de_miscare=@datal 
and m.numar_de_inventar= fisamf.numar_de_inventar)
and (@lm='' or fisaMF.Loc_de_munca like rtrim(@lm)+'%' or exists (select 1 from misMF mm where 
mm.Subunitate=fisaMF.Subunitate and mm.Data_lunii_de_miscare=fisaMF.Data_lunii_operatiei 
and mm.Tip_miscare='TSE' and mm.Numar_de_inventar=fisaMF.Numar_de_inventar 
and mm.Loc_de_munca_primitor like rtrim(@lm)+'%'))

--AM. DEGR. 2
UPDATE fisamf set fisamf.amortizare_lunara= (CASE WHEN @amdegr2anicalend=0 and 
durata*12-Numar_de_luni_pana_la_am_int<(select col6 from coefmf where dur=durata)*12 THEN 
(Valoare_de_inventar- Valoare_amortizata)*(select col3 from coefmf where dur=durata)/100/12 ELSE 
(Valoare_de_inventar- Valoare_amortizata)/(Numar_de_luni_pana_la_am_int- (select col8 from coefmf where 
dur=durata)*12) END)
FROM mfix 
WHERE fisamf.subunitate=@sub and fisamf.data_lunii_operatiei=@datal 
and fisamf.felul_operatiei=@felop and (@nrinv='' or fisamf.numar_de_inventar=@nrinv) 
and (@categmf=0 or fisamf.categoria=@categmf) and fisamf.Numar_de_luni_pana_la_am_int>0 
and mfix.subunitate=fisamf.subunitate and mfix.numar_de_inventar= fisamf.numar_de_inventar and 
mfix.tip_amortizare='4' and (isnull((select sum(round(convert(decimal(17,5),c.diferenta_de_valoare),2)) from mismf c where c.subunitate=@sub /*'DENS'*/ and c.Numar_de_inventar= fisamf.Numar_de_inventar and c.data_lunii_de_miscare=dbo.bom(@datal)-1 and left (c.tip_miscare,1)='M' and (@felop='1' or @felop<>'1' and @reevcontab=1 and c.loc_de_munca_primitor<>'RC' or @felop<>'1' and @valist=1 and c.tip_miscare<>'MRE')),0)<>0 or amortizare_lunara=0 or @amdegr2anicalend=0 
and (durata*12-Numar_de_luni_pana_la_am_int)%12=0 or @amdegr2anicalend=1 and month(@datal)=1) 
and not exists (select 1 from mismf m where m.subunitate=@sub and left(m.tip_miscare,1)='I' 
and m.Data_lunii_de_miscare=@datal and m.numar_de_inventar= fisamf.numar_de_inventar) 
and (@lm='' or fisaMF.Loc_de_munca like rtrim(@lm)+'%' or exists (select 1 from misMF mm where 
mm.Subunitate=fisaMF.Subunitate and mm.Data_lunii_de_miscare=fisaMF.Data_lunii_operatiei 
and mm.Tip_miscare='TSE' and mm.Numar_de_inventar=fisaMF.Numar_de_inventar 
and mm.Loc_de_munca_primitor like rtrim(@lm)+'%'))

--AM. ACC.
UPDATE fisamf 
set fisamf.amortizare_lunara= (CASE WHEN year(@datal)*12+month(@datal)-year(data_punerii_in_functiune)*12-month(data_punerii_in_functiune)-1<12 -- primul an: valoarea/2
	THEN (CASE WHEN amortizare_lunara=0 THEN 
	((isnull((select a.valoare_de_inventar from fisamf a where a.subunitate=@sub and a.Numar_de_inventar= fisamf.Numar_de_inventar and a.felul_operatiei='1' and a.data_lunii_operatiei=(select b.data_lunii_operatiei from fisamf b where b.subunitate=@sub and b.Numar_de_inventar= fisamf.Numar_de_inventar and b.felul_operatiei between '2' and '3')),0)
		-- nu mai scad modificarile de valoare:
		-(CASE WHEN 1=0 and year(@datal)*12+month(@datal)-year(data_punerii_in_functiune)*12-month(data_punerii_in_functiune)-1=0 THEN isnull((select sum(round(convert(decimal(17,5),c.diferenta_de_valoare),2)) from mismf c where c.subunitate=@sub /*'DENS'*/and c.Numar_de_inventar= fisamf.Numar_de_inventar and c.data_lunii_de_miscare=dbo.bom(@datal)-1 and left (c.tip_miscare,1)='M' and (@felop='1' or @felop<>'1' and @reevcontab=1 and c.loc_de_munca_primitor<>'RC' or @felop<>'1' and @valist=1 and c.tip_miscare<>'MRE')),0) ELSE 0 END))/2 
	- isnull((select a.valoare_amortizata from fisamf a where a.subunitate=@sub and a.Numar_de_inventar= fisamf.Numar_de_inventar and a.felul_operatiei='1' and a.data_lunii_operatiei=(select b.data_lunii_operatiei from fisamf b where b.subunitate=@sub and b.Numar_de_inventar= fisamf.Numar_de_inventar and b.felul_operatiei between '2' and '3')),0))/ (12-(isnull((select a.durata from fisamf a where a.subunitate=@sub and a.Numar_de_inventar= fisamf.Numar_de_inventar and a.felul_operatiei='1' and a.data_lunii_operatiei=(select b.data_lunii_operatiei from fisamf b where b.subunitate=@sub and b.Numar_de_inventar= fisamf.Numar_de_inventar and b.felul_operatiei between '2' and '3')),0)*12-isnull((select a.Numar_de_luni_pana_la_am_int from fisamf a where a.subunitate=@sub and a.Numar_de_inventar= fisamf.Numar_de_inventar and a.felul_operatiei='1' and a.data_lunii_operatiei=(select b.data_lunii_operatiei from fisamf b where b.subunitate=@sub /*'DENS'*/ and b.Numar_de_inventar= fisamf.Numar_de_inventar and b.felul_operatiei between '2' and '3')),0))) ELSE amortizare_lunara END)+isnull((select sum(round(convert(decimal(17,5),c.diferenta_de_valoare),2)) from mismf c where c.subunitate=@sub and c.Numar_de_inventar= fisamf.Numar_de_inventar and c.data_lunii_de_miscare=dbo.bom(@datal)-1 and left (c.tip_miscare,1)='M' and (@felop='1' or @felop<>'1' and @reevcontab=1 and c.loc_de_munca_primitor<>'RC' or @felop<>'1' and @valist=1 and c.tip_miscare<>'MRE')),0)/2/(12-year(@datal)*12+month(@datal)-year(data_punerii_in_functiune)*12-month(data_punerii_in_functiune)-1) 
	ELSE -- urmatorii ani
	(Valoare_de_inventar- Valoare_amortizata)/Numar_de_luni_pana_la_am_int END)
FROM mfix 
WHERE fisamf.subunitate=@sub and fisamf.data_lunii_operatiei=@datal and fisamf.felul_operatiei=@felop and (@nrinv='' or fisamf.numar_de_inventar=@nrinv) and (@categmf=0 or fisamf.categoria=@categmf) and fisamf.Numar_de_luni_pana_la_am_int>0 
and mfix.subunitate=fisamf.subunitate and mfix.numar_de_inventar= fisamf.numar_de_inventar and mfix.tip_amortizare='5' and (amortizare_lunara=0 or year(@datal)*12+month(@datal)-year(data_punerii_in_functiune)*12-month(data_punerii_in_functiune)-1=12 or month(@datal)=1 
and year(@datal)=2005 or exists (select 1 from mismf m where m.subunitate=@sub and left(m.tip_miscare,1)='M' and m.Data_lunii_de_miscare=dbo.bom(@datal)-1 
and m.numar_de_inventar= fisamf.numar_de_inventar)) and not exists (select 1 from mismf m where m.subunitate=@sub and left(m.tip_miscare,1)='I' and m.Data_lunii_de_miscare=@datal and m.numar_de_inventar= fisamf.numar_de_inventar)
and (@lm='' or fisaMF.Loc_de_munca like rtrim(@lm)+'%' or exists (select 1 from misMF mm where mm.Subunitate=fisaMF.Subunitate and mm.Data_lunii_de_miscare=fisaMF.Data_lunii_operatiei and mm.Tip_miscare='TSE' and mm.Numar_de_inventar=fisaMF.Numar_de_inventar and mm.Loc_de_munca_primitor like rtrim(@lm)+'%'))

--AM. LINIARA
UPDATE fisamf 
set fisamf.amortizare_lunara= (Valoare_de_inventar- Valoare_amortizata)/Numar_de_luni_pana_la_am_int /*isnull((select (a.Valoare_de_inventar- a.Valoare_amortizata)/a.Numar_de_luni_pana_la_am_int from fisamf a where 
a.subunitate=@sub and a.Numar_de_inventar= fisamf.Numar_de_inventar
and a.data_lunii_operatiei=dbo.bom(@datal)-1 and a.felul_operatiei=@felop and a.Numar_de_luni_pana_la_am_int>0), 
isnull( (select (b.Valoare_de_inventar- b.Valoare_amortizata) /b.Numar_de_luni_pana_la_am_int from fisamf b where b.subunitate=@sub 
and b.Numar_de_inventar= fisamf.Numar_de_inventar
and b.data_lunii_operatiei=@datal and b.felul_operatiei=@felop and b.Numar_de_luni_pana_la_am_int>0), 
isnull( (select (c.Valoare_de_inventar- c.Valoare_amortizata) /c.Numar_de_luni_pana_la_am_int from fisamf c where c.subunitate=@sub 
and c.Numar_de_inventar= fisamf.Numar_de_inventar
and c.data_lunii_operatiei=@datal and c.felul_operatiei='4' and c.Numar_de_luni_pana_la_am_int>0), 
isnull( (select (d.Valoare_de_inventar- d.Valoare_amortizata) /d.Numar_de_luni_pana_la_am_int from fisamf d where d.subunitate=@sub 
and d.Numar_de_inventar= fisamf.Numar_de_inventar 
and d.data_lunii_operatiei=@datal and d.felul_operatiei='3' and d.Numar_de_luni_pana_la_am_int>0),0))))*/
FROM mfix 
WHERE fisamf.subunitate=@sub and fisamf.data_lunii_operatiei=@datal 
and fisamf.felul_operatiei=@felop and (@nrinv='' or fisamf.numar_de_inventar=@nrinv) 
and (@categmf=0 or fisamf.categoria=@categmf) and fisamf.Numar_de_luni_pana_la_am_int>0 
and mfix.subunitate=fisamf.subunitate and mfix.numar_de_inventar= fisamf.numar_de_inventar 
and (fisamf.obiect_de_inventar=1 and exists (select 1 from mismf m where m.Subunitate=mfix.Subunitate and m.Numar_de_inventar=mfix.Numar_de_inventar and m.Tip_miscare='MMF' and m.Data_miscarii<=@datal 
	and m.Data_sfarsit_conservare='01/01/1902' and m.Procent_inchiriere in ('3','6')) 
	or mfix.tip_amortizare in ('2','6')) 
and not exists (select 1 from mismf m where m.subunitate=@sub and left(m.tip_miscare,1)='I' and m.Data_lunii_de_miscare=@datal and m.numar_de_inventar= fisamf.numar_de_inventar)
and (@lm='' or fisaMF.Loc_de_munca like rtrim(@lm)+'%' or exists (select 1 from misMF mm where 
mm.Subunitate=fisaMF.Subunitate and mm.Data_lunii_de_miscare=fisaMF.Data_lunii_operatiei 
and mm.Tip_miscare='TSE' and mm.Numar_de_inventar=fisaMF.Numar_de_inventar 
and mm.Loc_de_munca_primitor like rtrim(@lm)+'%'))

/*--am. liniara sugerata
UPDATE fisamf set fisamf.amortizare_lunara= amortizare_lunara /*isnull((select a.amortizare_lunara from fisamf a where 
a.subunitate=@sub and a.Numar_de_inventar= fisamf.Numar_de_inventar
and a.data_lunii_operatiei=dbo.bom(@datal)-1 and a.felul_operatiei=@felop and a.Numar_de_luni_pana_la_am_int>0), 
isnull( (select b.amortizare_lunara from fisamf b where b.subunitate=@sub 
and b.Numar_de_inventar= fisamf.Numar_de_inventar
and b.data_lunii_operatiei=@datal and b.felul_operatiei=@felop and b.Numar_de_luni_pana_la_am_int>0), 
isnull( (select c.amortizare_lunara from fisamf c where c.subunitate=@sub 
and c.Numar_de_inventar= fisamf.Numar_de_inventar
and c.data_lunii_operatiei=@datal and c.felul_operatiei='4' and c.Numar_de_luni_pana_la_am_int>0), 
isnull( (select d.amortizare_lunara from fisamf d where d.subunitate=@sub 
and d.Numar_de_inventar= fisamf.Numar_de_inventar 
and d.data_lunii_operatiei=@datal and d.felul_operatiei='3' and d.Numar_de_luni_pana_la_am_int>0),0))))*/
FROM mfix WHERE fisamf.subunitate=@sub and fisamf.data_lunii_operatiei=@datal 
and fisamf.felul_operatiei=@felop and (@nrinv='' or fisamf.numar_de_inventar=@nrinv) 
and (@categmf=0 or fisamf.categoria=@categmf) and mfix.subunitate=fisamf.subunitate 
and mfix.numar_de_inventar= fisamf.numar_de_inventar and mfix.tip_amortizare='7' 
and not exists (select 1 from mismf m where m.subunitate=@sub and left(m.tip_miscare,1)='I' 
and m.Data_lunii_de_miscare=@datal and m.numar_de_inventar= fisamf.numar_de_inventar)
and (@lm='' or fisaMF.Loc_de_munca like rtrim(@lm)+'%' or exists (select 1 from misMF mm where 
mm.Subunitate=fisaMF.Subunitate and mm.Data_lunii_de_miscare=fisaMF.Data_lunii_operatiei 
and mm.Tip_miscare='TSE' and mm.Numar_de_inventar=fisaMF.Numar_de_inventar 
and mm.Loc_de_munca_primitor like rtrim(@lm)+'%'))
*/
--AM. PRIMA 20%
UPDATE fisamf set fisamf.VALOARE_AMORTIZATA= round(convert(decimal(17,5), fisamf.valoare_amortizata- 
fisamf.amortizare_lunara+ fisamf.Valoare_de_inventar*0.2),2), fisamf.AMORTIZARE_LUNARA= 
fisamf.Valoare_de_inventar*0.2 /*isnull((select a.Valoare_de_inventar*0.2 from fisamf a where 
a.subunitate=@sub and a.Numar_de_inventar= fisamf.Numar_de_inventar
and a.data_lunii_operatiei=dbo.bom(@datal)-1 and a.felul_operatiei=@felop and a.Numar_de_luni_pana_la_am_int>0), 
isnull( (select b.Valoare_de_inventar*0.2 from fisamf b where b.subunitate=@sub 
and b.Numar_de_inventar= fisamf.Numar_de_inventar
and b.data_lunii_operatiei=@datal and b.felul_operatiei=@felop and b.Numar_de_luni_pana_la_am_int>0), 
isnull( (select c.Valoare_de_inventar*0.2 from fisamf c where c.subunitate=@sub 
and c.Numar_de_inventar= fisamf.Numar_de_inventar
and c.data_lunii_operatiei=@datal and c.felul_operatiei='4' and c.Numar_de_luni_pana_la_am_int>0), 
isnull( (select d.Valoare_de_inventar*0.2 from fisamf d where d.subunitate=@sub 
and d.Numar_de_inventar= fisamf.Numar_de_inventar 
and d.data_lunii_operatiei=@datal and d.felul_operatiei='3' and d.Numar_de_luni_pana_la_am_int>0),0))))*/
FROM mfix, mismf WHERE fisamf.subunitate=@sub and fisamf.data_lunii_operatiei=@datal 
and fisamf.felul_operatiei=@felop and (@nrinv='' or fisamf.numar_de_inventar=@nrinv) 
and (@categmf=0 or fisamf.categoria=@categmf) and mfix.subunitate=fisamf.subunitate 
and mfix.numar_de_inventar= fisamf.numar_de_inventar and mfix.tip_amortizare='6' 
and mismf.subunitate=fisamf.subunitate and mismf.numar_de_inventar= fisamf.numar_de_inventar 
and left(tip_miscare,1)='I' and data_lunii_de_miscare=@datal 
and (@lm='' or fisaMF.Loc_de_munca like rtrim(@lm)+'%' or exists (select 1 from misMF mm where 
mm.Subunitate=fisaMF.Subunitate and mm.Data_lunii_de_miscare=fisaMF.Data_lunii_operatiei 
and mm.Tip_miscare='TSE' and mm.Numar_de_inventar=fisaMF.Numar_de_inventar 
and mm.Loc_de_munca_primitor like rtrim(@lm)+'%'))

--ULTIMA LUNA
UPDATE fisamf set amortizare_lunara= valoare_de_inventar-valoare_amortizata /*isnull((select a.valoare_de_inventar from fisamf a where a.subunitate=@sub and a.Numar_de_inventar= fisamf.Numar_de_inventar and a.data_lunii_operatiei=dbo.bom(@datal)-1 and a.felul_operatiei=@felop), (select b.valoare_de_inventar from fisamf b where b.subunitate=@sub and b.Numar_de_inventar= fisamf.Numar_de_inventar and b.data_lunii_operatiei=@datal and b.felul_operatiei between '2' and '3'))- isnull((select a.valoare_amortizata from fisamf a where a.subunitate=@sub and a.Numar_de_inventar= fisamf.Numar_de_inventar and a.data_lunii_operatiei=dbo.bom(@datal)-1 and a.felul_operatiei=@felop), (select b.valoare_amortizata from fisamf b where b.subunitate=@sub and b.Numar_de_inventar= fisamf.Numar_de_inventar and b.data_lunii_operatiei=@datal and b.felul_operatiei between '2' and '3'))*/
FROM mfix 
WHERE fisamf.subunitate=@sub and fisamf.data_lunii_operatiei=@datal 
and fisamf.felul_operatiei=@felop and (@nrinv='' or fisamf.numar_de_inventar=@nrinv) 
and (@categmf=0 or fisamf.categoria=@categmf) and mfix.subunitate=fisamf.subunitate 
and mfix.numar_de_inventar= fisamf.numar_de_inventar and (mfix.tip_amortizare<>'4' 
and Numar_de_luni_pana_la_am_int=1 or mfix.tip_amortizare='4' 
and Numar_de_luni_pana_la_am_int-durata*12 +(select col5 from coefmf where dur= durata)*12=1) 
and fisamf.numar_de_inventar not in (select m.numar_de_inventar from mismf m where 
m.subunitate=@sub and left(m.tip_miscare,1)='I' and m.Data_lunii_de_miscare=@datal 
/*and m.numar_de_inventar= fisamf.numar_de_inventar*/)
and (@lm='' or fisaMF.Loc_de_munca like rtrim(@lm)+'%' or exists (select 1 from misMF mm where 
mm.Subunitate=fisaMF.Subunitate and mm.Data_lunii_de_miscare=fisaMF.Data_lunii_operatiei 
and mm.Tip_miscare='TSE' and mm.Numar_de_inventar=fisaMF.Numar_de_inventar 
and mm.Loc_de_munca_primitor like rtrim(@lm)+'%'))

--anulare am.
UPDATE fisamf set fisamf.amortizare_lunara=0
FROM mfix 
WHERE fisamf.subunitate=@sub and fisamf.data_lunii_operatiei=@datal 
and fisamf.felul_operatiei=@felop and (@nrinv='' or fisamf.numar_de_inventar=@nrinv) 
and (@categmf=0 or fisamf.categoria=@categmf) and mfix.subunitate=fisamf.subunitate 
and mfix.numar_de_inventar= fisamf.numar_de_inventar and (mfix.tip_amortizare='1' or @faraamlacon=1 
and fisamf.data_lunii_operatiei<= isnull((select top 1 y.data_sfarsit_conservare from mismf y where 
y.subunitate=@sub and y.tip_miscare='CON' and y.Data_lunii_de_miscare<=@datal 
and y.numar_de_inventar= fisamf.numar_de_inventar order by y.Data_sfarsit_conservare desc),
fisamf.data_lunii_operatiei-1) or mfix.tip_amortizare<>'4' 
and Numar_de_luni_pana_la_am_int /*isnull((select a.Numar_de_luni_pana_la_am_int from fisamf a where 
a.subunitate=@sub and a.Numar_de_inventar= fisamf.Numar_de_inventar and a.data_lunii_operatiei=
dbo.bom(@datal)-1 and a.felul_operatiei=@felop), (select b.Numar_de_luni_pana_la_am_int from fisamf b 
where b.subunitate=@sub and b.Numar_de_inventar= fisamf.Numar_de_inventar 
and b.data_lunii_operatiei=@datal and b.felul_operatiei between '2' and '3')) */<1 
or mfix.tip_amortizare='4' and Numar_de_luni_pana_la_am_int-Durata*12+ /*isnull((select 
a.Numar_de_luni_pana_la_am_int-a.durata*12 from fisamf a where a.subunitate=@sub 
and a.Numar_de_inventar= fisamf.Numar_de_inventar and a.data_lunii_operatiei=dbo.bom(@datal)-1 
and a.felul_operatiei=@felop), (select b.Numar_de_luni_pana_la_am_int-b.durata*12 from fisamf b where 
b.subunitate=@sub and b.Numar_de_inventar= fisamf.Numar_de_inventar and b.data_lunii_operatiei=@datal 
and b.felul_operatiei between '2' and '3')) */(select col5 from coefmf where dur= durata 
/*isnull((select a.durata from fisamf a where a.subunitate=@sub 
and a.Numar_de_inventar= fisamf.Numar_de_inventar and a.data_lunii_operatiei=dbo.bom(@datal)-1 
and a.felul_operatiei=@felop), (select b.durata from fisamf b where b.subunitate=@sub 
and b.Numar_de_inventar= fisamf.Numar_de_inventar and b.data_lunii_operatiei=@datal 
and b.felul_operatiei between '2' and '3'))*/ )*12<1) and not exists (select 1 from mismf m where 
m.subunitate=@sub and left(m.tip_miscare,1)='I' and m.Data_lunii_de_miscare=@datal 
and m.numar_de_inventar= fisamf.numar_de_inventar)
and (@lm='' or fisaMF.Loc_de_munca like rtrim(@lm)+'%' or exists (select 1 from misMF mm where 
mm.Subunitate=fisaMF.Subunitate and mm.Data_lunii_de_miscare=fisaMF.Data_lunii_operatiei 
and mm.Tip_miscare='TSE' and mm.Numar_de_inventar=fisaMF.Numar_de_inventar 
and mm.Loc_de_munca_primitor like rtrim(@lm)+'%'))

--am. pt cele cu MMF cu %=3
UPDATE fisamf set amortizare_lunara=amortizare_lunara+round(convert(decimal(17,5),m.pret),2)
FROM mismf m WHERE fisamf.subunitate=@sub and fisamf.data_lunii_operatiei=@datal 
and fisamf.felul_operatiei=@felop and (@nrinv='' or fisamf.numar_de_inventar=@nrinv) 
and (@categmf=0 or fisamf.categoria=@categmf) and m.subunitate=fisamf.subunitate 
and m.numar_de_inventar= fisamf.numar_de_inventar and m.tip_miscare='MMF' 
and m.data_lunii_de_miscare=@datal and m.procent_inchiriere=3
and (@lm='' or fisaMF.Loc_de_munca like rtrim(@lm)+'%' or exists (select 1 from misMF mm where 
mm.Subunitate=fisaMF.Subunitate and mm.Data_lunii_de_miscare=fisaMF.Data_lunii_operatiei 
and mm.Tip_miscare='TSE' and mm.Numar_de_inventar=fisaMF.Numar_de_inventar 
and mm.Loc_de_munca_primitor like rtrim(@lm)+'%'))

--rotunjire am. la 2 zecimale
UPDATE fisamf set amortizare_lunara= round(convert(decimal(17,5),amortizare_lunara),2)
WHERE fisamf.subunitate=@sub and fisamf.data_lunii_operatiei=@datal 
and fisamf.felul_operatiei=@felop and (@nrinv='' or fisamf.numar_de_inventar=@nrinv) 
and (@categmf=0 or fisamf.categoria=@categmf)
and (@lm='' or fisaMF.Loc_de_munca like rtrim(@lm)+'%' or exists (select 1 from misMF mm where 
mm.Subunitate=fisaMF.Subunitate and mm.Data_lunii_de_miscare=fisaMF.Data_lunii_operatiei 
and mm.Tip_miscare='TSE' and mm.Numar_de_inventar=fisaMF.Numar_de_inventar 
and mm.Loc_de_munca_primitor like rtrim(@lm)+'%'))
