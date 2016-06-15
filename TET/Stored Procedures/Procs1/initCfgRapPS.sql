create procedure initCfgRapPS
as
begin
/**	se creeaza tabela	*/
	if not exists (select 1 from sysobjects where name='cfgRapPS' and xtype='U')
	begin
		create table cfgRapPS (raport varchar(200) default '', grup varchar(2), tip varchar(3), subtipuri varchar(200), denumire varchar(100) default '', ordine int)
		create unique clustered index index_cfgRapPS on cfgRapPS(raport, grup, tip)
	end
		
/*	-->> daca nu exista subtipuri retineri populez cu tipuri subtipurile, pentru a nu complica raportul
	if not exists (select top 1 1 from tipret)
	insert into tipret(Subtip, Denumire, Tip_retinere, Obiect_subtip_retinere)
	select Tip_retinere, Denumire_tip, Tip_retinere, '' from dbo.fTip_retineri(1)*/
/**	se populeaza cfgRapPS:	*/
--if (select count(1) from cfgRapPS c where c.grup='R')=0
	declare @maxOrdine int, @grupareRetineri int
	exec luare_date_par 'PS', 'SPWGRRET', 0, @grupareRetineri OUTPUT, ''
	/**	@maxOrdine= ultimul identificator folosit pe grupul curent 
		@grupareRetineri = parametru functie de care se face gruparea retinerilor pe stat de plata 
		@grupareRetineri = 0 pe cod beneficiar (implicit); 1->pe tip retinere; 2->ar putea fi pe subtip retinere - pt. moment tratam si pt. 1 */
	--/*	-->> insert-ul de mai jos se foloseste pentru o configurare default a retinerilor (grup='R'), pe beneficiari; campul de legatura este subtipuri
	set @maxOrdine=isnull((select max(c.ordine) from cfgRapPS c where c.grup='R'),0)
	if isnull((select val_logica from par where Tip_parametru='PS' and parametru like 'subtipret'),0)=1
		insert into cfgRapPS (grup, tip, subtipuri, ordine)
		select 'R' grup, @maxOrdine+ ROW_NUMBER() over (order by subtipuri), subtipuri, @maxOrdine+ ROW_NUMBER() over (order by subtipuri)
		from(
			select --row_number() over (order by b.tip_retinere, b.cod_beneficiar) as ordine,
					rtrim(b.tip_retinere)+'|'+rtrim(b.cod_beneficiar) as subtipuri
			from tipret t left join benret	b on b.Tip_retinere=t.subtip
			) x
		where not exists (select 1 from cfgRapPS c where c.grup='R' and charindex(','+rtrim(isnull(x.subtipuri,''))+',',','+rtrim(isnull(c.subtipuri,''))+',')>0)
			and subtipuri is not null
	else
	Begin
--	pentru fluturasi (grupare pe cod beneficiar)
		insert into cfgRapPS (raport, grup, tip, subtipuri, ordine)
		select 'rapFluturasi', 'R' grup, @maxOrdine+ ROW_NUMBER() over (order by subtipuri), subtipuri, @maxOrdine+ ROW_NUMBER() over (order by subtipuri) 
		from(
			select --row_number() over (order by b.tip_retinere, b.cod_beneficiar) as ordine,
					rtrim(b.tip_retinere)+'|'+rtrim(b.cod_beneficiar) as subtipuri
			from dbo.fTip_retineri(1) t left join benret b on b.Tip_retinere=t.Tip_retinere 
			) x
		where not exists (select 1 from cfgRapPS c where c.grup='R' and charindex(','+rtrim(isnull(x.subtipuri,''))+',',','+rtrim(isnull(c.subtipuri,''))+',')>0)
			and subtipuri is not null
--	pentru stat de plata (grupare pe cod beneficiar/tip retinere functie de parametru)
		insert into cfgRapPS (raport, grup, tip, subtipuri, ordine)
		select 'rapStatDePlata', 'R' grup, @maxOrdine+ ROW_NUMBER() over (order by subtipuri), subtipuri, @maxOrdine+ ROW_NUMBER() over (order by subtipuri) 
		from(
			select --row_number() over (order by b.tip_retinere, b.cod_beneficiar) as ordine,
					(case when @grupareRetineri=1 then rtrim(t.tip_retinere) else rtrim(isnull(b.tip_retinere,'')) end)+'|'+(case when @grupareRetineri=1 then '' else rtrim(isnull(b.cod_beneficiar,'')) end) as subtipuri
			from dbo.fTip_retineri(1) t left join benret b on b.Tip_retinere=t.Tip_retinere and @grupareRetineri=0
			) x
		where not exists (select 1 from cfgRapPS c where c.raport='rapStatDePlata' and c.grup='R' and charindex(','+rtrim(isnull(x.subtipuri,''))+',',','+rtrim(isnull(c.subtipuri,''))+',')>0)
			and subtipuri is not null
	End		
			-->> configurarea sporurilor - se iau doar cele care au definite denumiri in par; campul de legatura este tip (0=specific)
--if (select count(1) from cfgRapPS c where c.grup='SP')=0
	insert into cfgRapPS (grup, tip, subtipuri, ordine)
	select 'SP','0','SSPEC',0 from par
		where Tip_parametru='PS' and Parametru ='sspec' and Val_alfanumerica<>''
		and not exists (select 1 from cfgrapps c where c.grup='SP' and c.tip='0')
	union all	
	select 'SP',substring(parametru,6,1),rtrim(Parametru),row_number() over(order by substring(parametru,6,1)) from par
		where Tip_parametru='PS' and rtrim(Parametru) like 'SCOND%' and len(parametru)=6 and Val_alfanumerica<>''
		and not exists (select 1 from cfgrapps c where c.grup='SP' and c.tip=substring(parametru,6,1))

			-->> configurarea sporurilor standard pt flexibilizarea statului de plata; camp de legatura=subtipuri
--if (select count(1) from cfgRapPS c where c.grup='SG')=0
	set @maxOrdine=isnull((select max(c.ordine) from cfgRapPS c where c.grup='SG'),0)
	insert into cfgRapPS (raport, grup, tip, subtipuri, ordine, denumire)
	select 'rapStatDePlata','SG',tip, subtipuri, @maxOrdine+row_number() over (order by tip) ordine, denumire from
	(
	select  tip, subtipuri, --row_number() over (order by tip) ordine, 
			denumire from
			(select '1' tip,'ind cond' subtipuri, 'ind cond' denumire where not exists (select 1 from par where tip_parametru='PS' and parametru = 'INDCOND' and val_alfanumerica<>'') union all
			select '1' tip,'ind cond' subtipuri, val_alfanumerica denumire from par where tip_parametru='PS' and parametru = 'INDCOND' and val_alfanumerica<>'' union all
			select '2','spor vechime', 'sp vech' union all
			select '3','supl1', '' from par where tip_parametru='PS' and parametru = 'osupl1' and val_logica=1	union all
			select '4','supl2','' from par where tip_parametru='PS' and parametru = 'osupl2' and val_logica=1	union all
			select '5','supl3','' from par where tip_parametru='PS' and parametru = 'osupl3' and val_logica=1	union all
			select '6','supl4','' from par where tip_parametru='PS' and parametru = 'osupl4' and val_logica=1	union all
			select '7','sp100%','sp100%' union all 
			select '8','noapte','noapte' union all
			select '9','sist prg','' union all
			select '10','funct suplim','') x
	)x
	where not exists 
		(select 1 from cfgrapps c where c.grup='SG' and charindex(','+rtrim(isnull(x.subtipuri,''))+',',','+rtrim(isnull(c.subtipuri,''))+',')>0)
	--*/
			-->> configurarea corectiilor - se considera cele de tip ('M-','C-','E-','Q-','P-') ca fiind retineri
	set @maxOrdine=isnull((select max(c.ordine) from cfgRapPS c where c.grup in ('CR','CV')),0)
--if (select count(1) from cfgRapPS c where c.grup in ('CR','CV'))=0	-->> daca e fara subtipuri de corectii:
if not exists (select 1 from par where Tip_parametru='PS' and parametru='subtipcor' and Val_logica=1)
insert into cfgRapPS(grup, tip, subtipuri, ordine)
select (case when t.Tip_corectie_venit in ('M-','C-','E-','Q-','P-') then 'CR' else 'CV' end ) grup
	,@maxOrdine+row_number() over(order by t.tip_corectie_venit),t.Tip_corectie_venit,
	 @maxOrdine+row_number() over(order by t.tip_corectie_venit) from tipcor t
	where not exists
	 (select 1 from cfgrapps c where c.grup in ('CR','CV') and charindex(','+rtrim(isnull(t.Tip_corectie_venit,''))+',',','+rtrim(isnull(c.subtipuri,''))+',')>0)
else
insert into cfgRapPS(grup, tip, subtipuri, ordine)					-->> daca e pe subtipuri de corectii:
select (case when p.Tip_corectie_venit in ('M-','C-','E-','Q-','P-') then 'CR' else 'CV' end ) grup,
		@maxOrdine+row_number() over(order by t.subtip),t.subtip,
		@maxOrdine+row_number() over(order by t.subtip) from subtipcor t
	inner join tipcor p on t.Tip_corectie_venit=p.Tip_corectie_venit
	where not exists
	 (select 1 from cfgrapps c where c.grup in ('CR','CV') and charindex(','+rtrim(isnull(t.Subtip,''))+',',','+rtrim(isnull(c.subtipuri,''))+',')>0)
end
