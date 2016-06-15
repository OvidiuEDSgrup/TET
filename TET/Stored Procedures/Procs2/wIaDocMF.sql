--***
CREATE procedure wIaDocMF @sesiune varchar(50), @parXML xml
as 
begin try
	set transaction isolation level READ UNCOMMITTED
	declare @sub varchar(9), @userASiS varchar(10), @lunainch int, @anulinch int, @datainch datetime, 
		@tip varchar(2), --@subtip varchar(2), @densubtip varchar(20), 
		@lista_lm int, @lista_gest int, @datal datetime, @datajos datetime, @datasus datetime, @mesaj varchar(1000)

	IF not exists (select 1 from par where Tip_parametru='MF' and Parametru='COMPLCTAM') 
	begin
		EXEC setare_par 'MF','RIA','RIA',1,0,'' --!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
		IF exists (select 1 from par where Tip_parametru='MF' and Parametru='RIA') 
			EXEC setare_par 'MF','COMPLCTAM','COMPLCTAM',1,15,'' --!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
	end

	exec wIaUtilizator @sesiune=@sesiune, @utilizator=@userASiS output
	/*set @Lunainch=isnull((select max(val_numerica) from par where tip_parametru='MF' and 
		parametru='LUNAINCH'), isnull((select max(val_numerica) from par where tip_parametru='MF' and 
		parametru='LUNAI'), 1))
	set @Anulinch=isnull((select max(val_numerica) from par where tip_parametru='MF' and 
		parametru='ANULINCH'), isnull((select max(val_numerica) from par where tip_parametru='MF' and 
		parametru='ANULI'), 1901))*/
	select @sub=(case when parametru='SUBPRO' then val_alfanumerica else @sub end)
	from par
	where tip_parametru='GE' and parametru in ('SUBPRO')
	set @lunainch=isnull((select max(val_numerica) from par where tip_parametru='GE' 
		and parametru='LUNABLOC'), isnull((select max(val_numerica) from par where tip_parametru='GE' 
		and parametru='LUNAINC'), 1))
	set @anulinch=isnull((select max(val_numerica) from par where tip_parametru='GE' 
		and parametru='ANULBLOC'), isnull((select max(val_numerica) from par where tip_parametru='GE' 
		and parametru='ANULINC'), 1901))
	set @Datainch=dbo.Eom(convert(datetime,str(@lunainch,2)+'/01/'+str(@anulinch,4)))

	select @lista_lm=dbo.f_arelmfiltru(@userASiS), @lista_gest=0
	select @lista_gest=1
		from proprietati where tip='UTILIZATOR' and cod=@userASiS and cod_proprietate='GESTIUNE'

	select @tip=xA.row.value('@tip', 'char(2)'), @datal=xA.row.value('@datal','datetime'), 
		--@subtip=xA.row.value('@subtip', 'char(2)'), @densubtip=xA.row.value('@densubtip', 'char(20)'), 
		@datajos=isnull(xA.row.value('@datajos','datetime'),dbo.BOM(isnull(@datal,'01/01/1901'))), 
		@datasus=dbo.Eom(isnull(xA.row.value('@datasus','datetime'),dbo.eOM(isnull(@datal,'01/01/2999')))) 
		from @parXML.nodes('row') as xA(row)  

	if not exists (select 1 from pozdoc where subunitate=@sub and jurnal='MFX')
	begin		
		raiserror ('Documentele de MF se vor opera prin meniul Documente imobilizari!',11,1)
	end
	
	SELECT /*isnull(*/convert(char(10),a.Data_lunii_de_miscare,101) --,convert(char(10),@datasus,101)) 
		as datal, @tip as tip, --@subtip as subtip, @densubtip as densubtip, 
		/*(case @tip when 'MI' then 'Intrari (I)' when 'MM' then 'Modificari (M)' when 'ME' then 'Iesiri (E)' 
		when 'MT' then 'Transferuri (T)' when 'MC' then 'Conservari (C)' when 'MS' then 'Iesiri din conservare (S)' 
		when 'MR' then 'Iesiri din inchiriere (R)' when 'MB' then 'Inchirieri (B)' else 'Date la implementare' */
		(case @tip when 'MI' then 'Intrari' when 'MM' then 'Modificari' when 'ME' then 'Iesiri' 
		when 'MT' then 'Transferuri' when 'MC' then 'Conservari' when 'MS' then 'Iesiri din conservare' 
		when 'MR' then 'Iesiri din inchiriere' when 'MB' then 'Inchirieri' else 'Date la implementare' 
		end)+' '+rtrim(rtrim(max(fc.LunaAlfa))+' '+convert(char(4),max(fc.An))) as luna, 
		count(1) as nrpozitii, 
		sum(convert(decimal(12,2),/*a.pret+a.Diferenta_de_valoare*/f.Valoare_de_inventar)) as valoare, 
		sum(convert(decimal(12,2),a.Diferenta_de_valoare)) as difval, 
		(case when a.Data_lunii_de_miscare<=@datainch then '#808080' else '#000000' end) as culoare
	FROM mismf a
		inner join fCalendar (@datajos, @datasus) fc on fc.Data=a.Data_miscarii 
		LEFT outer join fisamf f on f.subunitate=a.subunitate 
			and f.Numar_de_inventar=a.Numar_de_inventar and f.Data_lunii_operatiei=Data_lunii_de_miscare 
			and f.Felul_operatiei=(case @tip when 'MI' then '3' when 'MM' then '4' when 'ME' then '5' 
			when 'MT' then '6' when 'MC' then '7' when 'MS' then '8' when 'MB' then '9' else '1' end) 
		/*LEFT outer join pozdoc p on a.procent_inchiriere=6 and p.subunitate=a.subunitate 
		and p.tip=(case left(a.tip_miscare,1) 
		when 'I' then (case right(a.tip_miscare,2) when 'AF' then 'RM' else 'AI' end) 
		when 'M' then (case right(a.tip_miscare,2) when 'EP' then 'AE' when 'FF' then 'RM' else 'AI' end) 
		when 'E' then (case right(a.tip_miscare,2) when 'SU' then 'AI' when 'VI' then 'AP' else 'AE' end) 
		else '' end) and p.numar=a.Numar_document and p.Data=a.Data_miscarii 
		and p.Cod_intrare=a.Numar_de_inventar */
		LEFT outer join LMFiltrare lu on lu.utilizator=@userASiS 
			and lu.cod=f.Loc_de_munca/*isnull(p.Loc_de_munca,f.Loc_de_munca)*/
		/*LEFT outer join proprietati prop on prop.Cod_proprietate='GESTIUNE' and prop.tip='UTILIZATOR' 
		and prop.cod=@userASiS and prop.Valoare=f.gestiune*/
	WHERE left(a.Tip_miscare,1)=right(@tip,1) and a.Data_miscarii between @datajos and @datasus 
		and (@lista_lm=0 or lu.cod is not null) --and (@lista_gest=0 or prop.valoare is not null)
		and (Procent_inchiriere in (1,3,6,9) /*and Procent_inchiriere not in (7,8)*/
		or a.Tip_miscare in ('BIN','CON','RCI','SCO','TSE')) --and (a.Tip_miscare<>'ESU' or a.Tert='AE') 
		and (@datal is null or a.Data_lunii_de_miscare=@datal)
		/*and year(a.Data_lunii_de_miscare)=year(a.Data_miscarii) and day(a.Data_lunii_de_miscare)<>1*/
	GROUP BY a.Data_lunii_de_miscare
	union all
	SELECT data_lunii, @tip, --@subtip, @densubtip, 
		(case @tip when 'MI' then 'Intrari' when 'MM' then 'Modificari' when 'ME' then 'Iesiri' 
		when 'MT' then 'Transferuri' when 'MC' then 'Conservari' when 'MS' then 'Iesiri din conservare' 
		when 'MR' then 'Iesiri din inchiriere' when 'MB' then 'Inchirieri' else 'Date la implementare' 
		end)+' '+rtrim(rtrim((fc.LunaAlfa))+' '+convert(char(4),(fc.An))) as luna, 
		0 as nrpozitii, 0 as valoare, 0 as difval, 
		(case when Data_lunii<=@DataInch then '#808080' else '#000000' end) as culoare
	FROM fCalendar (@datasus, @datasus) fc 
	WHERE @datal is null
		and not exists (
			select 1 from misMF a
				LEFT outer join fisamf f on f.subunitate=a.subunitate and f.Numar_de_inventar=a.Numar_de_inventar 
					and f.Data_lunii_operatiei=Data_lunii_de_miscare 
					and f.Felul_operatiei=(case @tip when 'MI' then '3' when 'MM' then '4' when 'ME' then '5' 
					when 'MT' then '6' when 'MC' then '7' when 'MS' then '8' when 'MB' then '9' else '1' end)
				LEFT outer join LMFiltrare lu on lu.utilizator=@userASiS 
					and lu.cod=f.Loc_de_munca/*isnull(p.Loc_de_munca,f.Loc_de_munca)*/
			where left(a.Tip_miscare,1)=right(@tip,1) and a.Data_lunii_de_miscare=dbo.eom(@datasus)
				and (@lista_lm=0 or lu.cod is not null) --and (@lista_gest=0 or prop.valoare is not null)
				and (Procent_inchiriere in (1,3,6,9) /*and Procent_inchiriere not in (7,8)*/
				or a.Tip_miscare in ('BIN','CON','RCI','SCO','TSE')) --and (a.Tip_miscare<>'ESU' or a.Tert='AE') 
				and (@datal is null or a.Data_lunii_de_miscare=@datal)) 
	--GROUP BY Data_lunii
	ORDER BY datal
	for xml raw
end try
begin catch
	set @mesaj = ERROR_MESSAGE() + ' (' + OBJECT_NAME(@@PROCID) + ')'
	raiserror (@mesaj, 11, 1)
end catch
