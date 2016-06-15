--***
create procedure [dbo].[MFgennotaam] @gendoc int, @data datetime, @lm char(9)
as
--exec MFgennotaam @gendoc=1, @data='2012-01-31', @lm=''
declare @sub char(9), @bugetari int, @ctcls8 varchar(40), @ctrezrep varchar(40), @ctchobinv varchar(40), 
	@ctchamcorp varchar(40), @anctmfchamcorp int, @anlmchamcorp int, 
	@ctchamnecorp varchar(40), @anctmfchamnecorp int, @anlmchamnecorp int, 
	@ctchamreev varchar(40), @anctmfchamreev int, @anlmchamreev int, @ctchamned varchar(40), 
	@ctamnecorp varchar(40), @ctdon varchar(40), @ctvenamdon varchar(40), @ctvenamsubv varchar(40), 
	@urmvalist int, @urmrezreev int, @lunainch int, @anulinch int, @luna int, @anul int, 
	@numar char(8), @expl char(50), @userASiS char(20), @dataop datetime, @oraop char(6), 
	@NCrezreevCalc int	--	parametru de compatibilitate in urma pt. generare NC rezerve din reevaluare 
							--	(sa functioneze ca si pana la modificarea din 07.03.2013 functie de amortizare lunara 6871 si amortizare lunarea 8045)

exec luare_date_par 'GE', 'SUBPRO', 0, 0, @sub output
exec luare_date_par 'GE', 'BUGETARI', @bugetari output, 0, ''
exec luare_date_par 'MF', 'CTAMGRNU', 0, 0, @ctcls8 output
if @ctcls8='' set @ctcls8='8045'
exec luare_date_par 'MF', 'CTREZREP', 0, 0, @ctrezrep output
if @ctrezrep='' set @ctrezrep='1065'
exec luare_date_par 'MF', 'CA602', 0, 0, @ctchobinv output
if @ctchobinv='' set @ctchobinv='603'
exec luare_date_par 'MF', 'CA681', 0, @anlmchamcorp output, @ctchamcorp output
if @ctchamcorp='' set @ctchamcorp='6811'
--exec luare_date_par 'MF','CA681', 0, @anctmfchamcorp output, ''
if @anlmchamcorp=2 set @anctmfchamcorp=1 else set @anctmfchamcorp=0
--exec luare_date_par 'MF','CA681', 0, @anlmchamcorp output, ''
if @anlmchamcorp=3 set @anlmchamcorp=1 else set @anlmchamcorp=0
exec luare_date_par 'MF', '681NECORP', 0, @anlmchamnecorp output, @ctchamnecorp output
if @ctchamnecorp='' set @ctchamnecorp=@ctchamcorp
--exec luare_date_par 'MF','681NECORP', 0, @anctmfchamnecorp output, ''
if @anlmchamnecorp=0 set @anctmfchamnecorp=@anctmfchamcorp
if @anlmchamnecorp=2 set @anctmfchamnecorp=1 else set @anctmfchamnecorp=0
--exec luare_date_par 'MF','681NECORP', 0, @anlmchamnecorp output, ''
if @anlmchamnecorp=0 set @anlmchamnecorp=@anlmchamcorp
if @anlmchamnecorp=3 set @anlmchamnecorp=1 else set @anlmchamnecorp=0
exec luare_date_par 'MF', 'CA6871', 0, @anlmchamreev output, @ctchamreev output
if @ctchamreev='' set @ctchamreev='6811'
--exec luare_date_par 'MF','CA6871', 0, @anctmfchamreev output, ''
if @anlmchamreev=2 set @anctmfchamreev=1 else set @anctmfchamreev=0
--exec luare_date_par 'MF','CA6871', 0, @anlmchamreev output, ''
if @anlmchamreev=3 set @anlmchamreev=1 else set @anlmchamreev=0
exec luare_date_par 'MF', 'CA6871NED', 0, 0, @ctchamned output
if @ctchamned='' set @ctchamned=@ctchamreev
exec luare_date_par 'MF', 'CA280', 0, 0, @ctamnecorp output
if @ctamnecorp='' set @ctamnecorp='280'
exec luare_date_par 'MF', 'IDO', 0, 0, @ctdon output
if @ctdon='' set @ctdon='131'
exec luare_date_par 'MF', 'C7727DON', 0, 0, @ctvenamdon output
if @ctvenamdon='' set @ctvenamdon='7727'
exec luare_date_par 'MF', 'VENSUBV', 0, 0, @ctvenamsubv output
if @ctvenamsubv='' set @ctvenamsubv='7584'
exec luare_date_par 'MF','URMVALIST', @urmvalist output, 0, ''
exec luare_date_par 'MF','REZREEV', @urmrezreev output, @NCrezreevCalc output, ''
--exec luare_date_par 'MF','MRECONTAB', @reevcontab output, 0, ''
exec luare_date_par 'MF','LUNAINCH', 0, @lunainch output, ''
exec luare_date_par 'MF','ANULINCH', 0, @anulinch output, ''
if @lunainch=0 exec luare_date_par 'MF','LUNAI', 0, @lunainch output, ''
if @anulinch=0 exec luare_date_par 'MF','ANULI', 0, @anulinch output, ''
if @lunainch=0 set @lunainch=month(@data)
if @anulinch=0 set @anulinch=year(@data)
set @luna=month(@data)
set @anul=year(@data)
set @numar='MF'+(case when @luna<10 then '0' else '' end)+ltrim(str(@luna,2))+str(@anul,4)
set @expl='Nota de amortizare lunara' 
set @userASiS = isnull(dbo.fIaUtilizator(null),'')
set @dataop=convert(datetime,convert(char(10),getdate(),104),104) 
set @oraop=RTrim(replace(convert(char(8),getdate(),108),':',''))

if @anul>@anulinch or @anul=@anulinch and @luna>@lunainch 
BEGIN
	DELETE from pozncon where subunitate=@sub and tip='MA' and numar=@numar 
	and data between dbo.bom(@data) and dbo.eom(@data) and (@lm='' or Loc_munca like rtrim(@lm)+'%')

	IF @gendoc=1
	begin 
		IF exists (select 1 from sysobjects where xtype='U' and name= 'mfnotaam_old') delete 
		from mfnotaam_old where utilizator=@userASiS 
		/*IF exists (select 1 from sysobjects where xtype='U' and name= 'mfnotaam') delete 
		from mfnotaam --where utilizator=@userASiS
		IF isnull((select a.length from syscolumns a, sysobjects b where a.id=b.id and b.xtype='U' 
		and a.name= 'Utilizator' and b.name= 'mfnotaam'),20)<>20 alter table mfnotaam alter column 
		Utilizator char(20) not null 
		IF isnull((select a.length from syscolumns a, sysobjects b where a.id=b.id and b.xtype='U' 
		and a.name= 'Utilizator' and b.name= 'mfnotaam_old'),20)<>20 alter table mfnotaam_old alter column 
		Utilizator char(20) not null */
		IF not exists (select * from sysobjects where name ='mfnotaam')
		begin
			CREATE TABLE [dbo].[MFnotaam](
				[Subunitate] [char](9) NOT NULL,
				[Nr_de_inventar] [char](13) NOT NULL,
				[Tip_am_lunara] [int] NOT NULL,
				[Cont_mf] [varchar](40) NOT NULL,
				[Cont_am] [varchar](40) NOT NULL,
				[Cont_debitor] [varchar](40) NOT NULL,
				[Cont_creditor] [varchar](40) NOT NULL,
				[Loc_munca] [char](9) NOT NULL,
				[Comanda] [char](40) NOT NULL,
				[Suma] [float] NOT NULL,
				[Valuta] [char](3) NOT NULL,
				[Curs] [float] NOT NULL,
				[Suma_valuta] [float] NOT NULL,
				[Tip] [char](2) NOT NULL,
				[Numar] [char](8) NOT NULL,
				[Data] [datetime] NOT NULL,
				[Explicatii] [char](50) NOT NULL,
				[Utilizator] [char](20) NOT NULL,
				[Data_operarii] [datetime] NOT NULL,
				[Ora_operarii] [char](6) NOT NULL,
				[Tert] [char](13) NOT NULL,
				[Jurnal] [char](3) NOT NULL,
				[Alfa1] [char](20) NOT NULL,
				[Alfa2] [char](20) NOT NULL,
				[Val1] [float] NOT NULL,
				[Val2] [float] NOT NULL,
				[Data2] [datetime] NOT NULL,
				[Nr_pozitie] [float] NOT NULL)
		end
		IF not exists (select 1 from sysobjects where xtype='U' and name= 'mfnotaam_old') 
		SELECT top 0 
		Subunitate, Nr_de_inventar, Tip_am_lunara, Cont_mf, Cont_am, Cont_debitor, Cont_creditor, 
		Loc_munca, Comanda, Suma, Valuta, Curs, Suma_valuta, Tip, Numar, Data, Explicatii, Utilizator, 
		Data_operarii, Ora_operarii, Tert, Jurnal, Alfa1, Alfa2, Val1, Val2, Data2 
		into mfnotaam_old from mfnotaam
		IF isnull((select a.length from syscolumns a, sysobjects b where a.id=b.id 
			and a.name='Nr_pozitie' and b.name='MFnotaam_old'),0)=0 
		ALTER table MFnotaam_old add [Nr_pozitie] [int] identity(1,1) NOT NULL

		INSERT into mfnotaam_old (Subunitate, Nr_de_inventar, Tip_am_lunara, Cont_mf, Cont_am, Cont_debitor, Cont_creditor, Loc_munca, Comanda, Suma, Valuta, Curs, Suma_valuta, Tip, Numar, Data, Explicatii, 
			Utilizator, Data_operarii, Ora_operarii, Tert, Jurnal, Alfa1, Alfa2, Val1, Val2, Data2)
		--6811=28...
		select @sub, a.numar_de_inventar, 1, cont_mijloc_fix, isnull(a.Cont_amortizare,b.cod_de_clasificare),
		isnull(nullif(a.Cont_cheltuieli,''),(case when left (cont_mijloc_fix,3)='303' then rtrim (@ctchobinv) when 
			/*left (cont_mijloc_fix,2)='20' or */ isnull(a.Cont_amortizare,isnull((select top 1 convert(varchar(40),Subunitate_primitoare) from 
			mismf mm where mm.subunitate= a.subunitate and tip_miscare= 'MMF' 
			and data_lunii_de_miscare>= data_lunii_operatiei and mm.numar_de_inventar= a.numar_de_inventar 
			order by data_miscarii),b.cod_de_clasificare)) like rtrim(@ctamnecorp)+'%' 
			then rtrim (@ctchamnecorp)+(case when @anctmfchamnecorp=1 then rtrim(substring (cont_mijloc_fix,3,11)) 
				when @anlmchamnecorp=1 then '.'+rtrim (loc_de_munca) else '' end) 
			else rtrim (@ctchamcorp)+(case when @anctmfchamcorp=1 then rtrim(substring (cont_mijloc_fix,3,11)) 
				when @anlmchamcorp=1 then '.'+rtrim (loc_de_munca) else '' end) END)), 
		(CASE WHEN left (cont_mijloc_fix,3)='303' then (case when isnull(a.Cont_amortizare,b.cod_de_clasificare)='' then cont_mijloc_fix else isnull(a.Cont_amortizare,b.cod_de_clasificare) end) 
			else isnull(a.Cont_amortizare,isnull((select top 1 convert(varchar(40),Subunitate_primitoare) from mismf mm where 
			mm.subunitate= a.subunitate and tip_miscare= 'MMF' 
			and data_lunii_de_miscare>= data_lunii_operatiei and mm.numar_de_inventar= a.numar_de_inventar 
			order by data_miscarii),b.cod_de_clasificare)) END), 
		a.loc_de_munca, left(a.comanda,20), amortizare_lunara -amortizare_lunara_cont_6871 -amortizare_lunara_cont_8045, '',0,0, 'MA', 
		@numar, @data, @expl, @userASIS, @dataop, @oraop, '', 'MFX', '', '', 0, 0, @data 
		FROM fisamf a 
			LEFT OUTER JOIN mfix b on b.subunitate='DENS' and a.numar_de_inventar=b.numar_de_inventar
			LEFT OUTER JOIN mfix mf on mf.subunitate=@sub and a.numar_de_inventar=mf.numar_de_inventar
		WHERE a.subunitate=@sub and data_lunii_operatiei =@data and felul_operatiei='1'
			and amortizare_lunara -amortizare_lunara_cont_6871 -amortizare_lunara_cont_8045<>0 and b.serie<>'C' --and serie<>'O'
			and (@lm='' or a.Loc_de_munca like rtrim(@lm)+'%')
		union all
		--6871=28...
		select @sub, a.numar_de_inventar, 2, a.cont_mijloc_fix, isnull(a.Cont_amortizare,b.cod_de_clasificare), 
		(case when @bugetari=1 and nullif(a.Cont_cheltuieli,'') is not null then nullif(a.Cont_cheltuieli,'') 
			else (case when m.cod_de_clasificare='2.3.2.1.1.' then rtrim(@ctchamned) 
				else rtrim (@ctchamreev)+(case when @anctmfchamreev=1 then rtrim(substring (a.cont_mijloc_fix,3,11)) when @anlmchamreev=1 then '.'+rtrim (a.loc_de_munca) else '' end) end) end), 
		isnull(a.Cont_amortizare,isnull((select top 1 convert(varchar(40),Subunitate_primitoare) from mismf mm where mm.subunitate= a.subunitate and tip_miscare= 'MMF' 
			and data_lunii_de_miscare>= data_lunii_operatiei and mm.numar_de_inventar= a.numar_de_inventar order by data_miscarii),b.cod_de_clasificare)), 
		a.loc_de_munca, left(a.comanda,20), a.amortizare_lunara_cont_6871, '',0,0, 'MA', @numar, @data, @expl, 
		@userASIS, @dataop, @oraop, '', 'MFX', '', '', 0, 0, @data 
		FROM fisamf a 
			LEFT OUTER JOIN mfix b on b.subunitate='DENS' and a.numar_de_inventar=b.numar_de_inventar
			LEFT OUTER JOIN mfix m on m.subunitate=a.subunitate and m.numar_de_inventar=a.numar_de_inventar
		WHERE a.subunitate=@sub and a.data_lunii_operatiei =@data and a.felul_operatiei='1'
			and a.amortizare_lunara_cont_6871<>0 and b.serie<>'C' --and b.serie<>'O'
			and (@lm='' or a.Loc_de_munca like rtrim(@lm)+'%')
		union all
		--8045
		select @sub, a.numar_de_inventar, 3, cont_mijloc_fix, cod_de_clasificare, 
		(case when left(isnull(a.Cont_amortizare,b.cod_de_clasificare),1)='8' then isnull(a.Cont_amortizare,b.cod_de_clasificare) else @ctcls8 end), '', a.loc_de_munca, left(a.comanda,20), 
		amortizare_lunara_cont_8045, '',0,0, 'MA', @numar, @data, @expl, @userASIS, @dataop, @oraop, 
		'', 'MFX', '', '', 0, 0, @data 
		from fisamf a 
			left outer join mfix b on b.subunitate='DENS' and a.numar_de_inventar=b.numar_de_inventar
		where a.subunitate=@sub and data_lunii_operatiei =@data and felul_operatiei='1'
			and amortizare_lunara_cont_8045<>0 and serie<>'C' --and serie<>'O'
			and (@lm='' or a.Loc_de_munca like rtrim(@lm)+'%')
		union all
		--M. F. CASATE
		select @sub, a.numar_de_inventar, 4, cont_mijloc_fix, cod_de_clasificare, '6583', '471', a.loc_de_munca, left(a.comanda,20), 
		amortizare_lunara, '',0,0, 'MA', @numar, @data, @expl, @userASIS, @dataop, @oraop, 
		'', 'MFX', '', '', 0, 0, @data 
		from fisamf a 
			left outer join mfix b on b.subunitate='DENS' and a.numar_de_inventar=b.numar_de_inventar
		where a.subunitate=@sub and data_lunii_operatiei =@data and felul_operatiei='1'
			and amortizare_lunara<>0 and serie='C' 
			and (@lm='' or a.Loc_de_munca like rtrim(@lm)+'%')
		union all
		--VALORI ISTORICE (pt. cont 105)
		select @sub, a.numar_de_inventar, 5, cont_mijloc_fix, cod_de_clasificare, cont_mijloc_fix, @ctrezrep, a.loc_de_munca, left(a.comanda,20), 
		-- pt. @urmrezreev fac nota de diminuare rezerva luata din salvarea de la calcul (Ghita, 07.03.2013 - oare e bine?)
		-- a fost: amortizare_lunara_cont_6871-(case when @urmrezreev=1 then amortizare_lunara_cont_8045 else amortizare_lunara end),
		(case when @urmvalist=1 or @urmrezreev=1 and @NCrezreevCalc in (1,2) then amortizare_lunara_cont_6871-(case when @NCrezreevCalc=1 then amortizare_lunara_cont_8045 else amortizare_lunara end) else cantitate end), 
		'',0,0, 'MA', @numar, @data, 'Diferente am. lunara reeval. si istorica', @userASIS, @dataop, @oraop, 
		'', 'MFX', '', '', 0, 0, @data 
		from fisamf a 
			left outer join mfix b on b.subunitate='DENS' and a.numar_de_inventar=b.numar_de_inventar 
		where (@urmvalist=1 or @urmrezreev=1) and a.subunitate=@sub and data_lunii_operatiei =@data and felul_operatiei='A' 
		--and amortizare_lunara_cont_6871-(case when @urmrezreev=1 then amortizare_lunara_cont_8045 else amortizare_lunara end)<>0
			and (case when @urmvalist=1 or @urmrezreev=1 and @NCrezreevCalc in (1,2)
					then amortizare_lunara_cont_6871-(case when @NCrezreevCalc=1 then amortizare_lunara_cont_8045 else amortizare_lunara end) 
					else cantitate end)<>0 
			and (@lm='' or a.Loc_de_munca like rtrim(@lm)+'%')
		union all
		--PLUSURI DE INVENTAR SI SUBVENTII
		select @sub, a.numar_de_inventar, 6, a.cont_mijloc_fix, cod_de_clasificare, (case when left(n.Cont_corespondent,3)='131' then n.Cont_corespondent else m.Cont_corespondent end), @ctvenamsubv, 
		a.loc_de_munca, left(a.comanda,20), 
		(case when Left (n.Cont_corespondent,3)='131' 
			then (case when f.numar_de_luni_pana_la_am_int=1 then n.diferenta_de_valoare-round(n.diferenta_de_valoare/o.numar_de_luni_pana_la_am_int,2)*(o.numar_de_luni_pana_la_am_int-1) 
				else round (n.diferenta_de_valoare/ o.numar_de_luni_pana_la_am_int,2) end) 
			else (case when f.numar_de_luni_pana_la_am_int=1 then p.valoare_de_inventar-round(p.valoare_de_inventar/ p.numar_de_luni_pana_la_am_int,2)*(p.numar_de_luni_pana_la_am_int-1) 
				else round (p.valoare_de_inventar/p.numar_de_luni_pana_la_am_int,2) end) end), 
		'',0,0, 'MA', @numar, @data, @expl, @userASIS, @dataop, @oraop, 
		'', 'MFX', '', '', 0, 0, @data 
		from fisamf a 
			left outer join mfix b on b.subunitate='DENS' and a.numar_de_inventar=b.numar_de_inventar
			left outer join fisamf f on a.subunitate= f.subunitate and a.numar_de_inventar= f.numar_de_inventar and f.felul_operatiei='1' and f.data_lunii_operatiei=dbo.bom(@data)-1
			left outer join mismf m on a.subunitate= m.subunitate and a.numar_de_inventar= m.numar_de_inventar and m.tip_miscare='IAL'
			left outer join fisamf p on a.subunitate= p.subunitate and a.numar_de_inventar= p.numar_de_inventar and p.felul_operatiei='3' and p.data_lunii_operatiei= m.data_lunii_de_miscare
			left outer join mismf n on a.subunitate= n.subunitate and a.numar_de_inventar= n.numar_de_inventar and n.tip_miscare='MAL' and n.data_lunii_de_miscare<=dbo.bom(@data)-1 and n.Cont_corespondent like '131%'
			left outer join fisamf o on a.subunitate= o.subunitate and a.numar_de_inventar= o.numar_de_inventar and o.felul_operatiei='1' and o.data_lunii_operatiei= n.data_lunii_de_miscare
		where a.subunitate=@sub and a.data_lunii_operatiei =@data and a.felul_operatiei='1'
			and a.amortizare_lunara<>0 and serie<>'C' /*and serie<>'O' */and (Left (m.Cont_corespondent,3)='131' AND Left (m.gestiune_primitoare,4)='7584' OR Left (n.Cont_corespondent,3)='131') 
			and f.numar_de_luni_pana_la_am_int>0 and (@lm='' or a.Loc_de_munca like rtrim(@lm)+'%')
		union all
		--DONATII
		select @sub, a.numar_de_inventar, 7, cont_mijloc_fix, isnull(a.Cont_amortizare,b.cod_de_clasificare), @ctdon, @ctvenamdon, 
		a.loc_de_munca, left(a.comanda,20), amortizare_lunara -amortizare_lunara_cont_6871 -amortizare_lunara_cont_8045, 
		'',0,0, 'MA', @numar, @data, @expl, @userASIS, @dataop, @oraop, '', 'MFX', '', '', 0, 0, @data 
		from fisamf a
			left outer join mfix b on b.subunitate='DENS' and a.numar_de_inventar=b.numar_de_inventar
		--left outer join mfix c on a.subunitate=c.subunitate and a.numar_de_inventar=c.numar_de_inventar
		where a.subunitate=@sub and data_lunii_operatiei =@data and felul_operatiei='1' 
			and amortizare_lunara<>0 and b.serie<>'C' --and b.serie<>'O' 
			and b.data_punerii_in_functiune='01/01/1902' /*charindex('(DON',c.denumire)>0*/
			and (@lm='' or a.Loc_de_munca like rtrim(@lm)+'%')

		/*IF exists (select 1 from sysobjects where xtype='U' and name= 'mfnotaam') delete 
		from mfnotaam --where utilizator=@userASiS
		INSERT into mfnotaam select * from mfnotaam_old where utilizator=@userASiS*/
		IF exists (select 1 from sysobjects where name ='MFnota_am') exec MFnota_am @userASIS --@data, @lm
		--procedura MFnota_am tb. modif. a.i. sa tina ct. de utilizator si de tabela MFnotaam_old

		INSERT into pozncon (Subunitate, Tip, Numar, Data, Cont_debitor, Cont_creditor, Suma, Valuta, Curs, Suma_valuta, Explicatii, Utilizator, Data_operarii, Ora_operarii, Nr_pozitie, Loc_munca, Comanda, Tert, Jurnal) 
		SELECT Subunitate, Tip, Numar, Data, Cont_debitor, Cont_creditor, 
		sum(Suma), max(Valuta), max(Curs), sum(Suma_valuta), 
		max(Explicatii), 
		--nr_de_inventar,
		max(Utilizator), 
		max(Data_operarii), max(Ora_operarii), max(Nr_pozitie), Loc_munca, Comanda, max(Tert), 
		max(Jurnal) 
		FROM mfnotaam_old WHERE utilizator=@userASiS 
		group by Subunitate, Tip, Numar, Data, Cont_debitor, Cont_creditor, Loc_munca, Comanda, Valuta
		--, nr_de_inventar 
		having sum(suma)<>0

		exec faInregistrariContabile @dinTabela=0,@subunitate=@sub,@tip='MA',@numar=@numar,@data=@data
	end
END
